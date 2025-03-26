local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = require 'modules.options'
local g = require 'modules.globals'
local fb_utils = require 'modules.utils'
local parser_API = require 'modules.apis.parser'

local API_MAJOR, API_MINOR, API_PATCH = g.API_VERSION:match("(%d+)%.(%d+)%.(%d+)")
API_MAJOR, API_MINOR, API_PATCH = tonumber(API_MAJOR), tonumber(API_MINOR), tonumber(API_PATCH)

---checks if the given parser has a valid version number
---@param parser Parser|Keybind
---@param id string
---@return boolean?
local function check_api_version(parser, id)
    if parser.version then
        msg.warn(('%s: use of the `version` field is deprecated - use `api_version` instead'):format(id))
        parser.api_version = parser.version
    end

    local version = parser.api_version
    if type(version) ~= 'string' then return msg.error(("%s: field `api_version` must be a string, got %s"):format(id, tostring(version))) end

    local major, minor = version:match("(%d+)%.(%d+)")
    major, minor = tonumber(major), tonumber(minor)

    if not major or not minor then
        return msg.error(("%s: invalid version number, expected v%d.%d.x, got v%s"):format(id, API_MAJOR, API_MINOR, version))
    elseif major ~= API_MAJOR then
        return msg.error(("%s has wrong major version number, expected v%d.x.x, got, v%s"):format(id, API_MAJOR, version))
    elseif minor > API_MINOR then
        msg.warn(("%s has newer minor version number than API, expected v%d.%d.x, got v%s"):format(id, API_MAJOR, API_MINOR, version))
    end
    return true
end

---create a unique id for the given parser
---@param parser Parser
local function set_parser_id(parser)
    local name = parser.name
    if g.parsers[name] then
        local n = 2
        name = parser.name.."_"..n
        while g.parsers[name] do
            n = n + 1
            name = parser.name.."_"..n
        end
    end

    g.parsers[name] = parser
    g.parsers[parser] = { id = name }
end

---runs an addon in a separate environment
---@param path string
---@return unknown
local function run_addon(path)
    local name_sqbr = string.format("[%s]", path:match("/([^/]*)%.lua$"))
    local addon_environment = fb_utils.redirect_table(_G)
    addon_environment._G = addon_environment    ---@diagnostic disable-line inject-field

    --gives each addon custom debug messages
    addon_environment.package = fb_utils.redirect_table(addon_environment.package)  ---@diagnostic disable-line inject-field
    addon_environment.package.loaded = fb_utils.redirect_table(addon_environment.package.loaded)
    local msg_module = {
        log = function(level, ...) msg.log(level, name_sqbr, ...) end,
        fatal = function(...) return msg.fatal(name_sqbr, ...) end,
        error = function(...) return msg.error(name_sqbr, ...) end,
        warn = function(...) return msg.warn(name_sqbr, ...) end,
        info = function(...) return msg.info(name_sqbr, ...) end,
        verbose = function(...) return msg.verbose(name_sqbr, ...) end,
        debug = function(...) return msg.debug(name_sqbr, ...) end,
        trace = function(...) return msg.trace(name_sqbr, ...) end,
    }
    addon_environment.print = msg_module.info   ---@diagnostic disable-line inject-field

    addon_environment.require = function(module)    ---@diagnostic disable-line inject-field
        if module == "mp.msg" then return msg_module end
        return require(module)
    end

    ---@type function?, string?
    local chunk, err
    if setfenv then ---@diagnostic disable-line deprecated
        --since I stupidly named a function loadfile I need to specify the global one
        --I've been using the name too long to want to change it now
        chunk, err = _G.loadfile(path)
        if not chunk then return msg.error(err) end
        setfenv(chunk, addon_environment)  ---@diagnostic disable-line deprecated
    else
        chunk, err = _G.loadfile(path, "bt", addon_environment) ---@diagnostic disable-line redundant-parameter
        if not chunk then return msg.error(err) end
    end

    ---@diagnostic disable-next-line no-unknown
    local success, result = xpcall(chunk, fb_utils.traceback)
    return success and result or nil
end

---Setup an internal or external parser.
---Note that we're somewhat bypassing the type system here as we're converting from a
---ParserConfig object to a Parser object. As such we need to make sure that the
---we're doing everything correctly. A 2.0 release of the addon API could simplify
---this by formally separating ParserConfigs from Parsers and providing an
---API to register parsers.
---@param parser ParserConfig
---@param file string
---@return nil
local function setup_parser(parser, file)
    parser = setmetatable(parser, { __index = parser_API }) --[[@as Parser]]
    parser.name = parser.name or file:gsub("%-browser%.lua$", ""):gsub("%.lua$", "")

    set_parser_id(parser)
    if not check_api_version(parser, file) then return msg.error("aborting load of parser", parser:get_id(), "from", file) end

    msg.verbose("imported parser", parser:get_id(), "from", file)

    --sets missing functions
    if not parser.can_parse then
        if parser.parse then parser.can_parse = function() return true end
        else parser.can_parse = function() return false end end
    end

    if parser.priority == nil then parser.priority = 0 end
    if type(parser.priority) ~= "number" then return msg.error("parser", parser:get_id(), "needs a numeric priority") end

    table.insert(g.parsers, parser)
end

---load an external addon
---@param file string
---@param path string
---@return nil
local function setup_addon(file, path)
    if file:sub(-4) ~= ".lua" then return msg.verbose(path, "is not a lua file - aborting addon setup") end

    local addon_parsers = run_addon(path) --[=[@as ParserConfig|ParserConfig[]]=]
    if addon_parsers and not next(addon_parsers) then return msg.verbose('addon', path, 'returned empry table - special case, ignoring') end
    if not addon_parsers or type(addon_parsers) ~= "table" then return msg.error("addon", path, "did not return a table") end

    --if the table contains a priority key then we assume it isn't an array of parsers
    if not addon_parsers[1] then addon_parsers = {addon_parsers} end

    for _, parser in ipairs(addon_parsers --[=[@as ParserConfig[]]=]) do
        setup_parser(parser, file)
    end
end

---loading external addons
---@param directory string
---@return nil
local function load_addons(directory)
    directory = fb_utils.fix_path(directory, true)

    local files = utils.readdir(directory)
    if not files then return msg.verbose('not loading external addons - could not read', o.addon_directory) end

    for _, file in ipairs(files) do
        setup_addon(file, directory..file)
    end
end

local function load_internal_addons()
    local script_dir = mp.get_script_directory()
    if not script_dir then return msg.error('script is not being run as a directory script!') end
    local internal_addon_dir = script_dir..'/modules/addons/'
    load_addons(internal_addon_dir)
end

local function load_external_addons()
    local addon_dir = mp.command_native({"expand-path", o.addon_directory..'/'}) --[[@as string|nil]]
    if not addon_dir then return msg.verbose('not loading external addons - could not resolve', o.addon_directory) end
    load_addons(addon_dir)
end

---Orders the addons by priority, sets the parser index values,
---and runs the setup methods of the addons.
local function setup_addons()
    table.sort(g.parsers, function(a, b) return a.priority < b.priority end)

    --we want to store the indexes of the parsers
    for i = #g.parsers, 1, -1 do g.parsers[ g.parsers[i] ].index = i end

    --we want to run the setup functions for each addon
    for index, parser in ipairs(g.parsers) do
        if parser.setup then
            local success = xpcall(function() parser:setup() end, fb_utils.traceback)
            if not success then
                msg.error("parser", parser:get_id(), "threw an error in the setup method - removing from list of parsers")
                table.remove(g.parsers, index)
            end
        end
    end
end

---@class addons
return {
    check_api_version = check_api_version,
    load_internal_addons = load_internal_addons,
    load_external_addons = load_external_addons,
    setup_addons = setup_addons,
}
