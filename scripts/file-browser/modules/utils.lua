--------------------------------------------------------------------------------------------------------
-----------------------------------------Utility Functions----------------------------------------------
---------------------------------------Part of the addon API--------------------------------------------
--------------------------------------------------------------------------------------------------------

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = require 'modules.options'
local g = require 'modules.globals'

local success, input = pcall(require, "user-input-module")
if not success then input = nil end

--creates a table for the API functions
--adds one metatable redirect to prevent addon authors from accidentally breaking file-browser
local fb_utils = { API_VERSION = g.API_VERSION }

fb_utils.list = {}
fb_utils.coroutine = {}

--implements table.pack if on lua 5.1
if not table.pack then
    table.unpack = unpack
---@diagnostic disable-next-line: duplicate-set-field
    function table.pack(...)
        local t = {n = select("#", ...), ...}
        return t
    end
end

-- returns the index of the given item in the table
-- return -1 if item does not exist
function fb_utils.list.indexOf(t, item, from_index)
    for i = from_index or 1, #t, 1 do
        if t[i] == item then return i end
    end
    return -1
end

--returns whether or not the given table contains an entry that
--causes the given function to evaluate to true
function fb_utils.list.some(t, fn)
    for i, v in ipairs(t) do
        if fn(v, i, t) then return true end
    end
    return false
end

--prints an error message and a stack trace
--accepts an error object and optionally a coroutine
--can be passed directly to xpcall
function fb_utils.traceback(errmsg, co)
    if co then
        msg.warn(debug.traceback(co))
    else
        msg.warn(debug.traceback("", 2))
    end
    msg.error(errmsg)
end

--returns a table that stores the given table t as the __index in its metatable
--creates a prototypally inherited table
function fb_utils.redirect_table(t)
    return setmetatable({}, { __index = t })
end

--prints an error if a coroutine returns an error
--unlike the next function this one still returns the results of coroutine.resume()
function fb_utils.coroutine.resume_catch(...)
    local returns = table.pack(coroutine.resume(...))
    if not returns[1] and returns[2] ~= g.ABORT_ERROR then
        fb_utils.traceback(returns[2], select(1, ...))
    end
    return table.unpack(returns, 1, returns.n)
end

--resumes a coroutine and prints an error if it was not sucessful
function fb_utils.coroutine.resume_err(...)
    local success, err = coroutine.resume(...)
    if not success and err ~= g.ABORT_ERROR then
        fb_utils.traceback(err, select(1, ...))
    end
    return success
end

--in lua 5.1 there is only one return value which will be nil if run from the main thread
--in lua 5.2 main will be true if running from the main thread
function fb_utils.coroutine.assert(err)
    local co, main = coroutine.running()
    assert(not main and co, err or "error - function must be executed from within a coroutine")
    return co
end

-- Creates a callback function to resume the current coroutine with the given time limit.
-- If the time limit expires the coroutine will be resumed. The first return value will be true
-- if the callback was resumed within the time limit and false otherwise.
-- If time_limit is falsy then there will be no time limit and there will be no additional return value.
function fb_utils.coroutine.callback(time_limit)
    local co = fb_utils.coroutine.assert("cannot create a coroutine callback for the main thread")
    local timer = time_limit and mp.add_timeout(time_limit, function ()
            msg.debug("time limit on callback expired")
            fb_utils.coroutine.resume_err(co, false)
        end)
    return function(...)
        if timer then
            if not timer:is_enabled() then return
            else timer:kill() end
            return fb_utils.coroutine.resume_err(co, true, ...)
        end
        return fb_utils.coroutine.resume_err(co, ...)
    end
end

--puts the current coroutine to sleep for the given number of seconds
function fb_utils.coroutine.sleep(n)
    mp.add_timeout(n, fb_utils.coroutine.callback())
    coroutine.yield()
end

--runs the given function in a coroutine, passing through any additional arguments
--this is for triggering an event in a coroutine
function fb_utils.coroutine.run(fn, ...)
    local co = coroutine.create(fn)
    fb_utils.coroutine.resume_err(co, ...)
end

--get the full path for the current file
function fb_utils.get_full_path(item, dir)
    if item.path then return item.path end
    return (dir or g.state.directory)..item.name
end

--gets the path for a new subdirectory, redirects if the path field is set
--returns the new directory path and a boolean specifying if a redirect happened
function fb_utils.get_new_directory(item, directory)
    if item.path and item.redirect ~= false then return item.path, true end
    if directory == "" then return item.name end
    if string.sub(directory, -1) == "/" then return directory..item.name end
    return directory.."/"..item.name
end

--returns the file extension of the given file
function fb_utils.get_extension(filename, def)
    return string.lower(filename):match("%.([^%./]+)$") or def
end

--returns the protocol scheme of the given url, or nil if there is none
function fb_utils.get_protocol(filename, def)
    return string.lower(filename):match("^(%a[%w+-.]*)://") or def
end

--formats strings for ass handling
--this function is based on a similar function from https://github.com/mpv-player/mpv/blob/master/player/lua/console.lua#L110
function fb_utils.ass_escape(str, replace_newline)
    if replace_newline == true then replace_newline = "\\\239\187\191n" end

    --escape the invalid single characters
    str = string.gsub(str, '[\\{}\n]', {
        -- There is no escape for '\' in ASS (I think?) but '\' is used verbatim if
        -- it isn't followed by a recognised character, so add a zero-width
        -- non-breaking space
        ['\\'] = '\\\239\187\191',
        ['{'] = '\\{',
        ['}'] = '\\}',
        -- Precede newlines with a ZWNBSP to prevent ASS's weird collapsing of
        -- consecutive newlines
        ['\n'] = '\239\187\191\\N',
    })

    -- Turn leading spaces into hard spaces to prevent ASS from stripping them
    str = str:gsub('\\N ', '\\N\\h')
    str = str:gsub('^ ', '\\h')

    if replace_newline then
        str = str:gsub("\\N", replace_newline)
    end
    return str
end

--escape lua pattern characters
function fb_utils.pattern_escape(str)
    return string.gsub(str, "([%^%$%(%)%%%.%[%]%*%+%-])", "%%%1")
end

--standardises filepaths across systems
function fb_utils.fix_path(str, is_directory)
    if str == '' then return str end
    if o.normalise_backslash == 'yes' or (o.normalise_backslash == 'auto' and g.PLATFORM == 'windows') then
        str = string.gsub(str, [[\]],[[/]])
    end
    str = str:gsub([[/%./]], [[/]])
    if is_directory and str:sub(-1) ~= '/' then str = str..'/' end
    return str
end

--wrapper for utils.join_path to handle protocols
function fb_utils.join_path(working, relative)
    return fb_utils.get_protocol(relative) and relative or utils.join_path(working, relative)
end

--converts the given path into an absolute path and normalises it using fb_utils.fix_path
function fb_utils.absolute_path(path)
    local absolute_path = fb_utils.join_path(mp.get_property('working-directory', ''), path)
    return fb_utils.fix_path(absolute_path)
end

--sorts the table lexicographically ignoring case and accounting for leading/non-leading zeroes
--the number format functionality was proposed by github user twophyro, and was presumably taken
--from here: http://notebook.kulchenko.com/algorithms/alphanumeric-natural-sorting-for-humans-in-lua
function fb_utils.sort(t)
    local function padnum(n, d)
        return #d > 0 and ("%03d%s%.12f"):format(#n, n, tonumber(d) / (10 ^ #d))
            or ("%03d%s"):format(#n, n)
    end

    --appends the letter d or f to the start of the comparison to sort directories and folders as well
    local tuples = {}
    for i, f in ipairs(t) do
        tuples[i] = {f.type:sub(1, 1) .. (f.label or f.name):lower():gsub("0*(%d+)%.?(%d*)", padnum), f}
    end
    table.sort(tuples, function(a, b)
        return a[1] == b[1] and #b[2] < #a[2] or a[1] < b[1]
    end)
    for i, tuple in ipairs(tuples) do t[i] = tuple[2] end
    return t
end

function fb_utils.valid_dir(dir)
    if o.filter_dot_dirs and string.sub(dir, 1, 1) == "." then return false end
    return true
end

function fb_utils.valid_file(file)
    if o.filter_dot_files and (string.sub(file, 1, 1) == ".") then return false end
    if o.filter_files and not g.extensions[ fb_utils.get_extension(file, "") ] then return false end
    return true
end

--returns whether or not the item can be parsed
function fb_utils.parseable_item(item)
    return item.type == "dir" or g.parseable_extensions[fb_utils.get_extension(item.name, "")]
end

-- Takes a directory string and resolves any directory mappings,
-- returning the resolved directory.
function fb_utils.resolve_directory_mapping(directory)
    if not directory then return directory end

    for mapping, target in pairs(g.directory_mappings) do
        local start, finish  = string.find(directory, mapping)
        if start then
            msg.debug('mapping', mapping, 'found for directory', directory, 'changing to', target)

            -- if the mapping is an exact match then return the target as is
            if finish == #directory then return target end

            -- else make sure the path is correctly formatted
            target = fb_utils.fix_path(target, true)
            return string.gsub(directory, mapping, target)
        end
    end

    return directory
end

--removes items and folders from the list
--this is for addons which can't filter things during their normal processing
function fb_utils.filter(t)
    local max = #t
    local top = 1
    for i = 1, max do
        local temp = t[i]
        t[i] = nil

        if  ( temp.type == "dir" and fb_utils.valid_dir(temp.label or temp.name) ) or
            ( temp.type == "file" and fb_utils.valid_file(temp.label or temp.name) )
        then
            t[top] = temp
            top = top+1
        end
    end
    return t
end

--returns a string iterator that uses the root separators
function fb_utils.iterate_opt(str)
    return string.gmatch(str, "([^"..fb_utils.pattern_escape(o.root_separators).."]+)")
end

--sorts a table into an array of selected items in the correct order
--if a predicate function is passed, then the item will only be added to
--the table if the function returns true
function fb_utils.sort_keys(t, include_item)
    local keys = {}
    for k in pairs(t) do
        local item = g.state.list[k]
        if not include_item or include_item(item) then
            item.index = k
            keys[#keys+1] = item
        end
    end

    table.sort(keys, function(a,b) return a.index < b.index end)
    return keys
end

--Uses a loop to get the length of an array. The `#` operator is undefined if there
--are gaps in the array, this ensures there are none as expected by the mpv node function.
local function get_length(t)
    local i = 1
    while t[i] do i = i+1 end
    return i - 1
end

--recursively removes elements of the table which would cause
--utils.format_json to throw an error
local function json_safe_recursive(t)
    if type(t) ~= "table" then return t end

    local array_length = get_length(t)
    local isarray = array_length > 0

    for key, value in pairs(t) do
        local ktype = type(key)
        local vtype = type(value)

        if  vtype ~= "userdata" and vtype ~= "function" and vtype ~= "thread"
            and ((  isarray and ktype == "number" and key <= array_length)
                    or (not isarray and ktype == "string"))
        then
            t[key] = json_safe_recursive(t[key])
        elseif key then
            t[key] = nil
            if isarray then array_length = get_length(t) end
        end
    end
    return t
end

--formats a table into a json string but ensures there are no invalid datatypes inside the table first
function fb_utils.format_json_safe(t)
    --operate on a copy of the table to prevent any data loss in the original table
    t = json_safe_recursive(fb_utils.copy_table(t))
    local success, result, err = pcall(utils.format_json, t)
    if success then return result, err
    else return nil, result end
end

--evaluates and runs the given string in both Lua 5.1 and 5.2
--the name argument is used for error reporting
--provides the mpv modules and the fb module to the string
function fb_utils.evaluate_string(str, name)
    local env = fb_utils.redirect_table(_G)
    env.mp = fb_utils.redirect_table(mp)
    env.msg = fb_utils.redirect_table(msg)
    env.utils = fb_utils.redirect_table(utils)
    env.fb = fb_utils.redirect_table(fb_utils)
    env.input = input and fb_utils.redirect_table(input)

    local chunk, err
    if setfenv then
        chunk, err = loadstring(str, name)
        if chunk then setfenv(chunk, env) end
    else
        chunk, err = load(str, name, 't', env)
    end
    if not chunk then
        msg.warn('failed to load string:', str)
        msg.error(err)
        chunk = function() return nil end
    end

    return chunk()
end

--copies a table without leaving any references to the original
--uses a structured clone algorithm to maintain cyclic references
local function copy_table_recursive(t, references, depth)
    if type(t) ~= "table" or depth == 0 then return t end
    if references[t] then return references[t] end

    local copy = setmetatable({}, { __original = t })
    references[t] = copy

    for key, value in pairs(t) do
        key = copy_table_recursive(key, references, depth - 1)
        copy[key] = copy_table_recursive(value, references, depth - 1)
    end
    return copy
end

--a wrapper around copy_table to provide the reference table
function fb_utils.copy_table(t, depth)
    --this is to handle cyclic table references
    return copy_table_recursive(t, {}, depth or math.huge)
end

--functions to replace custom-keybind codes
fb_utils.code_fns = {
    ["%"] = "%",

    f = function(item, s) return item and fb_utils.get_full_path(item, s.directory) or "" end,
    n = function(item, s) return item and (item.label or item.name) or "" end,
    i = function(item, s)
            local i = fb_utils.list.indexOf(s.list, item)
            return i ~= -1 and ('%0'..math.ceil(math.log10(#s.list))..'d'):format(i) or 0
        end,
    j = function (item, s)
            return fb_utils.list.indexOf(s.list, item) ~= -1 and math.abs(fb_utils.list.indexOf( fb_utils.sort_keys(s.selection) , item)) or 0
        end,
    x = function(_, s) return #s.list or 0 end,
    p = function(_, s) return s.directory or "" end,
    q = function(_, s) return s.directory == '' and 'ROOT' or s.directory_label or s.directory or "" end,
    d = function(_, s) return (s.directory_label or s.directory):match("([^/]+)/?$") or "" end,
    r = function(_, s) return s.parser.keybind_name or s.parser.name or "" end,
}

-- programatically creates a pattern that matches any key code
-- this will result in some duplicates but that shouldn't really matter
function fb_utils.get_code_pattern(codes)
    local CUSTOM_KEYBIND_CODES = ""
    for key in pairs(codes) do CUSTOM_KEYBIND_CODES = CUSTOM_KEYBIND_CODES..key:lower()..key:upper() end
    for key in pairs((getmetatable(codes) or {}).__index or {}) do CUSTOM_KEYBIND_CODES = CUSTOM_KEYBIND_CODES..key:lower()..key:upper() end
    return('%%%%([%s])'):format(fb_utils.pattern_escape(CUSTOM_KEYBIND_CODES))
end

-- substitutes codes in the given string for other substrings
-- overrides is a map of characters->strings|functions that determines the replacement string is
-- item and state are values passed to functions in the map
-- modifier_fn is given the replacement substrings before they are placed in the main string (the return value is the new replacement string)
function fb_utils.substitute_codes(str, overrides, item, state, modifier_fn)
    local replacers = overrides and setmetatable(fb_utils.copy_table(overrides), {__index = fb_utils.code_fns}) or fb_utils.code_fns
    item = item or g.state.list[g.state.selected]
    state = state or g.state

    return (string.gsub(str, fb_utils.get_code_pattern(replacers), function(code)
        local result

        if type(replacers[code]) == "string" then
            result = replacers[code]
        --encapsulates the string if using an uppercase code
        elseif not replacers[code] then
            local lower_fn = replacers[code:lower()]
            if not lower_fn then return end
            result = string.format("%q", lower_fn(item, state))
        else
            result = replacers[code](item, state)
        end

        if modifier_fn then return modifier_fn(result) end
        return result
    end))
end


return fb_utils
