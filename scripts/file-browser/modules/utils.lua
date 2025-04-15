--------------------------------------------------------------------------------------------------------
-----------------------------------------Utility Functions----------------------------------------------
---------------------------------------Part of the addon API--------------------------------------------
--------------------------------------------------------------------------------------------------------

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = require 'modules.options'
local g = require 'modules.globals'

local input_loaded, input = pcall(require, 'mp.input')
local user_input_loaded, user_input = pcall(require, 'user-input-module')

--creates a table for the API functions
--adds one metatable redirect to prevent addon authors from accidentally breaking file-browser
---@class fb_utils
local fb_utils = { API_VERSION = g.API_VERSION }

fb_utils.list = {}
fb_utils.coroutine = {}

--implements table.pack if on lua 5.1
if not table.pack then
    table.unpack = unpack  ---@diagnostic disable-line deprecated
---@diagnostic disable-next-line: duplicate-set-field
    function table.pack(...)
        local t = {n = select("#", ...), ...}
        return t
    end
end

---Returns the index of the given item in the table.
---Return -1 if item does not exist.
---@generic T
---@param t T[]
---@param item T
---@param from_index? number
---@return integer
function fb_utils.list.indexOf(t, item, from_index)
    for i = from_index or 1, #t, 1 do
        if t[i] == item then return i end
    end
    return -1
end

---Returns whether or not the given table contains an entry that
---causes the given function to evaluate to true.
---@generic T
---@param t T[]
---@param fn fun(v: T, i: number, t: T[]): boolean
---@return boolean
function fb_utils.list.some(t, fn)
    for i, v in ipairs(t --[=[@as any[]]=]) do
        if fn(v, i, t) then return true end
    end
    return false
end

---Creates a new table populated with the results of
---calling a provided function on every element in t.
---@generic T
---@generic R
---@param t T[]
---@param fn fun(v: T, i: number, t: T[]): R
---@return R[]
function fb_utils.list.map(t, fn)
    local new_t = {}
    for i, v in ipairs(t --[=[@as any[]]=]) do
        new_t[i] = fn(v, i, t) ---@diagnostic disable-line no-unknown
    end
    return new_t
end

---Prints an error message and a stack trace.
---Can be passed directly to xpcall.
---@param errmsg string
---@param co? thread A coroutine to grab the stack trace from.
function fb_utils.traceback(errmsg, co)
    if co then
        msg.warn(debug.traceback(co))
    else
        msg.warn(debug.traceback("", 2))
    end
    msg.error(errmsg)
end

---Returns a table that stores the given table t as the __index in its metatable.
---Creates a prototypally inherited table.
---@generic T: table
---@param t T
---@return T
function fb_utils.redirect_table(t)
    return setmetatable({}, { __index = t })
end

---Sets the given table `proto` as the `__index` field in table `t`s metatable.
---@generic T: table
---@param t T
---@param proto table
---@return T
function fb_utils.set_prototype(t, proto)
    return setmetatable(t, { __index = proto })
end

---Prints an error if a coroutine returns an error.
---Unlike coroutine.resume_err this still returns the results of coroutine.resume().
---@param ... any
---@return boolean
---@return ...
function fb_utils.coroutine.resume_catch(...)
    local returns = table.pack(coroutine.resume(...))
    if not returns[1] and returns[2] ~= g.ABORT_ERROR then
        fb_utils.traceback(returns[2], select(1, ...))
    end
    return table.unpack(returns, 1, returns.n)
end

---Resumes a coroutine and prints an error if it was not sucessful.
---@param ... any
---@return boolean
function fb_utils.coroutine.resume_err(...)
    local success, err = coroutine.resume(...)
    if not success and err ~= g.ABORT_ERROR then
        fb_utils.traceback(err, select(1, ...))
    end
    return success
end

---Throws an error if not run from within a coroutine.
---In lua 5.1 there is only one return value which will be nil if run from the main thread.
---In lua 5.2 main will be true if running from the main thread.
---@param err any
---@return thread
function fb_utils.coroutine.assert(err)
    local co, main = coroutine.running()
    assert(not main and co, err or "error - function must be executed from within a coroutine")
    return co
end

---Creates a callback function to resume the current coroutine with the given time limit.
---If the time limit expires the coroutine will be resumed. The first return value will be true
---if the callback was resumed within the time limit and false otherwise.
---If time_limit is falsy then there will be no time limit and there will be no additional return value.
---@param time_limit? number seconds
---@return fun(...)
function fb_utils.coroutine.callback(time_limit)
    local co = fb_utils.coroutine.assert("cannot create a coroutine callback for the main thread")
    local timer = time_limit and mp.add_timeout(time_limit, function ()
            msg.debug("time limit on callback expired")
            fb_utils.coroutine.resume_err(co, false)
        end)

    local function fn(...)
        if timer then
            if not timer:is_enabled() then return
            else timer:kill() end
            return fb_utils.coroutine.resume_err(co, true, ...)
        end
        return fb_utils.coroutine.resume_err(co, ...)
    end
    return fn
end

---Puts the current coroutine to sleep for the given number of seconds.
---@async
---@param n number
---@return nil
function fb_utils.coroutine.sleep(n)
    mp.add_timeout(n, fb_utils.coroutine.callback())
    coroutine.yield()
end

---Runs the given function in a coroutine, passing through any additional arguments.
---Does not run the coroutine immediately, instead it queues the coroutine to run when the thread is next idle.
---Returns the coroutine object so that the caller can act on it before it is run.
---@param fn async fun()
---@param ... any
---@return thread
function fb_utils.coroutine.queue(fn, ...)
    local co = coroutine.create(fn)
    local args = table.pack(...)
    mp.add_timeout(0, function() fb_utils.coroutine.resume_err(co, table.unpack(args, 1, args.n)) end)
    return co
end

---Runs the given function in a coroutine, passing through any additional arguments.
---This is for triggering an event in a coroutine.
---@param fn async fun()
---@param ... any
function fb_utils.coroutine.run(fn, ...)
    local co = coroutine.create(fn)
    fb_utils.coroutine.resume_err(co, ...)
end

---Get the full path for the current file.
---@param item Item
---@param dir? string
---@return string
function fb_utils.get_full_path(item, dir)
    if item.path then return item.path end
    return (dir or g.state.directory)..item.name
end

---Gets the path for a new subdirectory, redirects if the path field is set.
---Returns the new directory path and a boolean specifying if a redirect happened.
---@param item Item
---@param directory string
---@return string new_directory
---@return boolean? redirected `true` if the path was redirected
function fb_utils.get_new_directory(item, directory)
    if item.path and item.redirect ~= false then return item.path, true end
    if directory == "" then return item.name end
    if string.sub(directory, -1) == "/" then return directory..item.name end
    return directory.."/"..item.name
end

---Returns the file extension of the given file, or def if there is none.
---@generic T
---@param filename string
---@param def? T 
---@return string|T
---@overload fun(filename: string): string|nil
function fb_utils.get_extension(filename, def)
    return string.lower(filename):match("%.([^%./]+)$") or def
end

---Returns the protocol scheme of the given url, or def if there is none.
---@generic T
---@param filename string
---@param def T
---@return string|T
---@overload fun(filename: string): string|nil
function fb_utils.get_protocol(filename, def)
    return string.lower(filename):match("^(%a[%w+-.]*)://") or def
end

---Formats strings for ass handling.
---This function is based on a similar function from
---https://github.com/mpv-player/mpv/blob/master/player/lua/console.lua#L110.
---@param str string
---@param replace_newline? true|string
---@return string
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
        str = string.gsub(str, "\\N", replace_newline)
    end
    return str
end

---Escape lua pattern characters.
---@param str string
---@return string
function fb_utils.pattern_escape(str)
    return (string.gsub(str, "([%^%$%(%)%%%.%[%]%*%+%-])", "%%%1"))
end

---Standardises filepaths across systems.
---@param str string
---@param is_directory? boolean
---@return string
function fb_utils.fix_path(str, is_directory)
    if str == '' then return str end
    if o.normalise_backslash == 'yes' or (o.normalise_backslash == 'auto' and g.PLATFORM == 'windows') then
        str = string.gsub(str, [[\]],[[/]])
    end
    str = str:gsub([[/%./]], [[/]])
    if is_directory and str:sub(-1) ~= '/' then str = str..'/' end
    return str
end

---Wrapper for mp.utils.join_path to handle protocols.
---@param working string
---@param relative string
---@return string
function fb_utils.join_path(working, relative)
    return fb_utils.get_protocol(relative) and relative or utils.join_path(working, relative)
end

---Converts the given path into an absolute path and normalises it using fb_utils.fix_path.
---@param path string
---@return string
function fb_utils.absolute_path(path)
    local absolute_path = fb_utils.join_path(mp.get_property('working-directory', ''), path)
    return fb_utils.fix_path(absolute_path)
end

---Sorts the table lexicographically ignoring case and accounting for leading/non-leading zeroes.
---The number format functionality was proposed by github user twophyro, and was presumably taken
---from here: http://notebook.kulchenko.com/algorithms/alphanumeric-natural-sorting-for-humans-in-lua.
---@param t List
---@return List
function fb_utils.sort(t)
    local function padnum(n, d)
        return #d > 0 and ("%03d%s%.12f"):format(#n, n, tonumber(d) / (10 ^ #d))
            or ("%03d%s"):format(#n, n)
    end

    --appends the letter d or f to the start of the comparison to sort directories and folders as well
    ---@type [string,Item][]
    local tuples = {}
    for i, f in ipairs(t) do
        tuples[i] = {f.type:sub(1, 1) .. (f.label or f.name):lower():gsub("0*(%d+)%.?(%d*)", padnum), f}
    end
    table.sort(tuples, function(a, b)
        -- pretty sure that `#b[2] < #a[2]` does not do anything as they are both Item tables and not strings or arrays
        return a[1] == b[1] and #b[2] < #a[2] or a[1] < b[1]
    end)
    for i, tuple in ipairs(tuples) do t[i] = tuple[2] end
    return t
end

---@param dir string
---@return boolean
function fb_utils.valid_dir(dir)
    if o.filter_dot_dirs == 'yes' or o.filter_dot_dirs == 'auto' and g.PLATFORM ~= 'windows' then
        return string.sub(dir, 1, 1) ~= "."
    end
    return true
end

---@param file string
---@return boolean
function fb_utils.valid_file(file)
    if o.filter_dot_files == 'yes' or o.filter_dot_files == 'auto' and g.PLATFORM ~= 'windows' then
        if string.sub(file, 1, 1) == "." then return false end
    end
    if o.filter_files and not g.extensions[ fb_utils.get_extension(file, "") ] then return false end
    return true
end

---Returns whether or not the item can be parsed.
---@param item Item
---@return boolean
function fb_utils.parseable_item(item)
    return item.type == "dir" or g.parseable_extensions[fb_utils.get_extension(item.name, "")]
end

---Takes a directory string and resolves any directory mappings,
---returning the resolved directory.
---@param path string
---@return string
function fb_utils.resolve_directory_mapping(path)
    if not path then return path end

    for mapping, target in pairs(g.directory_mappings) do
        local start, finish = string.find(path, mapping)
        if start then
            msg.debug('mapping', mapping, 'found for', path, 'changing to', target)

            -- if the mapping is an exact match then return the target as is
            if finish == #path then return target end

            -- else make sure the path is correctly formatted
            target = fb_utils.fix_path(target, true)
            return (string.gsub(path, mapping, target))
        end
    end

    return path
end

---Removes items and folders from the list that fail the configured filters.
---@param t List
---@return List
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

---Returns a string iterator that uses the root separators.
---@param str any
---@param separators? string Override the root separators.
---@return fun():(string, ...)
function fb_utils.iterate_opt(str, separators)
    return string.gmatch(str, "([^"..fb_utils.pattern_escape(separators or o.root_separators).."]+)")
end

---Sorts a table into an array of selected items in the correct order.
---If a predicate function is passed, then the item will only be added to
---the table if the function returns true.
---@param t Set<number>
---@param include_item? fun(item: Item): boolean
---@return Item[]
function fb_utils.sort_keys(t, include_item)
    ---@class Ref
    ---@field item Item
    ---@field index number

    ---@type Ref[]
    local keys = {}
    for k in pairs(t) do
        local item = g.state.list[k]
        if not include_item or include_item(item) then
            keys[#keys+1] = {
                item = item,
                index = k,
            }
        end
    end

    table.sort(keys, function(a,b) return a.index < b.index end)
    return fb_utils.list.map(keys, function(ref) return ref.item end)
end

---Uses a loop to get the length of an array. The `#` operator is undefined if there
---are gaps in the array, this ensures there are none as expected by the mpv node function.
---@param t any[]
---@return integer
local function get_length(t)
    local i = 1
    while t[i] do i = i+1 end
    return i - 1
end

---Recursively removes elements of the table which would cause
---utils.format_json to throw an error.
---@generic T
---@param t T
---@return T
local function json_safe_recursive(t)
    if type(t) ~= "table" then return t end

    local array_length = get_length(t)
    local isarray = array_length > 0

    for key, value in pairs(t --[[@as table<any,any>]]) do
        local ktype = type(key)
        local vtype = type(value)

        if  vtype ~= "userdata" and vtype ~= "function" and vtype ~= "thread"
            and ((  isarray and ktype == "number" and key <= array_length)
                    or (not isarray and ktype == "string"))
        then
            ---@diagnostic disable-next-line no-unknown
            t[key] = json_safe_recursive(t[key])
        elseif key then
            ---@diagnostic disable-next-line no-unknown
            t[key] = nil
            if isarray then array_length = get_length(t) end
        end
    end
    return t
end

---Formats a table into a json string but ensures there are no invalid datatypes inside the table first.
---@param t any
---@return string|nil
---@return string|nil err
function fb_utils.format_json_safe(t)
    --operate on a copy of the table to prevent any data loss in the original table
    t = json_safe_recursive(fb_utils.copy_table(t))
    local success, result, err = pcall(utils.format_json, t)
    if success then return result, err
    else return nil, result end
end

---Evaluates and runs the given string in both Lua 5.1 and 5.2.
---Provides the mpv modules and the fb module to the string.
---@param str string
---@param chunkname? string Used for error reporting.
---@param custom_env? table A custom environment that shadows the default environment.
---@param env_defaults? boolean Load lua defaults in environment, as well as mpv and file-browser modules. Defaults to `true`.
---@return unknown
function fb_utils.evaluate_string(str, chunkname, custom_env, env_defaults)
    ---@type table
    local env
    if env_defaults ~= false then
        ---@type table
        env = fb_utils.redirect_table(_G)
        env.mp = fb_utils.redirect_table(mp)
        env.msg = fb_utils.redirect_table(msg)
        env.utils = fb_utils.redirect_table(utils)
        env.fb = fb_utils.redirect_table(require 'file-browser')
        env.input = input_loaded and fb_utils.redirect_table(input)
        env.user_input = user_input_loaded and fb_utils.redirect_table(user_input)
        env = fb_utils.set_prototype(custom_env or {}, env)
    else
        env = custom_env or {}
    end

    ---@type function, any
    local chunk, err
    if setfenv then  ---@diagnostic disable-line deprecated
        chunk, err = loadstring(str, chunkname)  ---@diagnostic disable-line deprecated
        if chunk then setfenv(chunk, env) end  ---@diagnostic disable-line deprecated
    else
        chunk, err = load(str, chunkname, 't', env) ---@diagnostic disable-line redundant-parameter
    end
    if not chunk then
        msg.warn('failed to load string:', str)
        msg.error(err)
        chunk = function() return nil end
    end

    return chunk()
end

---Copies a table without leaving any references to the original.
---Uses a structured clone algorithm to maintain cyclic references.
---@generic T
---@param t T
---@param references table<table,table>
---@param depth number
---@return T
local function copy_table_recursive(t, references, depth)
    if type(t) ~= "table" or depth == 0 then return t end
    if references[t] then return references[t] end

    local copy = setmetatable({}, { __original = t })
    references[t] = copy

    for key, value in pairs(t --[[@as table<any,any>]]) do
        key = copy_table_recursive(key, references, depth - 1)
        copy[key] = copy_table_recursive(value, references, depth - 1) ---@diagnostic disable-line no-unknown
    end
    return copy
end

---A wrapper around copy_table to provide the reference table.
---@generic T
---@param t T
---@param depth? number
---@return T
function fb_utils.copy_table(t, depth)
    --this is to handle cyclic table references
    return copy_table_recursive(t, {}, depth or math.huge)
end

---@alias Replacer fun(item: Item, s: State): (string|number|nil)
---@alias ReplacerTable table<string,Replacer>

---functions to replace custom-keybind codes
---@type ReplacerTable
fb_utils.code_fns = {
    ["%"] = function() return "%" end,

    f = function(item, s) return item and fb_utils.get_full_path(item, s.directory) or "" end,
    n = function(item, s) return item and (item.label or item.name) or "" end,
    i = function(item, s)
            local i = fb_utils.list.indexOf(s.list, item)
            if #s.list == 0 then return 0 end
            return ('%0'..math.ceil(math.log10(#s.list))..'d'):format(i ~= -1 and i or 0)  ---@diagnostic disable-line deprecated
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

---Programatically creates a pattern that matches any key code.
---This will result in some duplicates but that shouldn't really matter.
---@param codes ReplacerTable
---@return string
function fb_utils.get_code_pattern(codes)
    ---@type string
    local CUSTOM_KEYBIND_CODES = ""
    for key in pairs(codes) do CUSTOM_KEYBIND_CODES = CUSTOM_KEYBIND_CODES..key:lower()..key:upper() end
    for key in pairs((getmetatable(codes) or {}).__index or {} --[[@as ReplacerTable]]) do
        ---@type string
        CUSTOM_KEYBIND_CODES = CUSTOM_KEYBIND_CODES..key:lower()..key:upper()
    end
    return('%%%%([%s])'):format(fb_utils.pattern_escape(CUSTOM_KEYBIND_CODES))
end

---Substitutes codes in the given string for other substrings.
---@param str string
---@param overrides? ReplacerTable Replacer functions for additional characters to match to after `%` characters.
---@param item? Item Uses the currently selected item if nil.
---@param state? State Uses the global state if nil.
---@param modifier_fn? fun(new_str: string, code: string): string given the replacement substrings before they are placed in the main string
---                                                 (the return value is the new replacement string).
---@return string
function fb_utils.substitute_codes(str, overrides, item, state, modifier_fn)
    local replacers = overrides and setmetatable(fb_utils.copy_table(overrides), {__index = fb_utils.code_fns}) or fb_utils.code_fns
    item = item or g.state.list[g.state.selected]
    state = state or g.state

    return (string.gsub(str, fb_utils.get_code_pattern(replacers), function(code)
        ---@type string|number|nil
        local result
        local replacer = replacers[code]

        if type(replacer) == "string" then
            result = replacer
        --encapsulates the string if using an uppercase code
        elseif not replacer then
            local lower_fn = replacers[code:lower()]
            if not lower_fn then return end
            result = string.format("%q", lower_fn(item, state))
        else
            result = replacer(item, state)
        end

        if result and modifier_fn then return modifier_fn(tostring(result), code) end
        return result
    end))
end


return fb_utils
