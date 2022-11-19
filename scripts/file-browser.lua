--[[
    mpv-file-browser

    This script allows users to browse and open files and folders entirely from within mpv.
    The script uses nothing outside the mpv API, so should work identically on all platforms.
    The browser can move up and down directories, start playing files and folders, or add them to the queue.

    For full documentation see: https://github.com/CogentRedTester/mpv-file-browser
]]--

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'
local opt = require 'mp.options'

local o = {
    --root directories
    root = "~/",

    --characters to use as separators
    root_separators = ",;",

    --number of entries to show on the screen at once
    num_entries = 20,

    --wrap the cursor around the top and bottom of the list
    wrap = false,

    --only show files compatible with mpv
    filter_files = true,

    --experimental feature that recurses directories concurrently when
    --appending items to the playlist
    concurrent_recursion = false,

    --maximum number of recursions that can run concurrently
    max_concurrency = 16,

    --enable custom keybinds
    custom_keybinds = false,

    --blacklist compatible files, it's recommended to use this rather than to edit the
    --compatible list directly. A semicolon separated list of extensions without spaces
    extension_blacklist = "",

    --add extra file extensions
    extension_whitelist = "",

    --files with these extensions will be added as additional audio tracks for the current file instead of appended to the playlist
    audio_extensions = "mka,dts,dtshd,dts-hd,truehd,true-hd",

    --files with these extensions will be added as additional subtitle tracks instead of appended to the playlist
    subtitle_extensions = "etf,etf8,utf-8,idx,sub,srt,rt,ssa,ass,mks,vtt,sup,scc,smi,lrc,pgs",

    --filter dot directories like .config
    --most useful on linux systems
    filter_dot_dirs = false,
    filter_dot_files = false,

    --substitude forward slashes for backslashes when appending a local file to the playlist
    --potentially useful on windows systems
    substitute_backslash = false,

    --this option reverses the behaviour of the alt+ENTER keybind
    --when disabled the keybind is required to enable autoload for the file
    --when enabled the keybind disables autoload for the file
    autoload = false,

    --if autoload is triggered by selecting the currently playing file, then
    --the current file will have it's watch-later config saved before being closed
    --essentially the current file will not be restarted
    autoload_save_current = true,

    --when opening the browser in idle mode prefer the current working directory over the root
    --note that the working directory is set as the 'current' directory regardless, so `home` will
    --move the browser there even if this option is set to false
    default_to_working_directory = false,

    --allows custom icons be set to fix incompatabilities with some fonts
    --the `\h` character is a hard space to add padding between the symbol and the text
    folder_icon = "🖿",
    cursor_icon = "➤",
    indent_icon = [[\h\h\h]],

    --enable addons
    addons = false,
    addon_directory = "~~/script-modules/file-browser-addons",

    --directory to load external modules - currently just user-input-module
    module_directory = "~~/script-modules",

    --turn the OSC idle screen off and on when opening and closing the browser
    toggle_idlescreen = false,

    --force file-browser to use a specific text alignment (default: top-left)
    --uses ass tag alignment numbers: https://aegi.vmoe.info/docs/3.0/ASS_Tags/#index23h3
    --set to 0 to use the default mpv osd-align options
    alignment = 7,

    --style settings
    font_bold_header = true,
    font_opacity_selection_marker = "99",

    font_size_header = 35,
    font_size_body = 25,
    font_size_wrappers = 16,

    font_name_header = "",
    font_name_body = "",
    font_name_wrappers = "",
    font_name_folder = "",
    font_name_cursor = "",

    font_colour_header = "00ccff",
    font_colour_body = "ffffff",
    font_colour_wrappers = "00ccff",
    font_colour_cursor = "00ccff",

    font_colour_multiselect = "fcad88",
    font_colour_selected = "fce788",
    font_colour_playing = "33ff66",
    font_colour_playing_multiselected = "22b547"

}

opt.read_options(o, 'file_browser')
utils.shared_script_property_set("file_browser-open", "no")

package.path = mp.command_native({"expand-path", o.module_directory}).."/?.lua;"..package.path
local success, input = pcall(require, "user-input-module")
if not success then input = nil end



--------------------------------------------------------------------------------------------------------
-----------------------------------------Environment Setup----------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--sets the version for the file-browser API
API_VERSION = "1.4.0"

--switch the main script to a different environment so that the
--executed lua code cannot access our global variales
if setfenv then
    setfenv(1, setmetatable({}, { __index = _G }))
else
    _ENV = setmetatable({}, { __index = _G })
end

--creates a table for the API functions
--adds one metatable redirect to prevent addon authors from accidentally breaking file-browser
local API = { API_VERSION = API_VERSION }
package.loaded["file-browser"] = setmetatable({}, { __index = API })

local parser_API = setmetatable({}, { __index = package.loaded["file-browser"] })
local parse_state_API = {}

--------------------------------------------------------------------------------------------------------
------------------------------------------Variable Setup------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--the osd_overlay API was not added until v0.31. The expand-path command was not added until 0.30
local ass = mp.create_osd_overlay("ass-events")
if not ass then return msg.error("Script requires minimum mpv version 0.31") end

local style = {
    global = o.alignment == 0 and "" or ([[{\an%d}]]):format(o.alignment),

    -- full line styles
    header = ([[{\r\q2\b%s\fs%d\fn%s\c&H%s&}]]):format((o.font_bold_header and "1" or "0"), o.font_size_header, o.font_name_header, o.font_colour_header),
    body = ([[{\r\q2\fs%d\fn%s\c&H%s&}]]):format(o.font_size_body, o.font_name_body, o.font_colour_body),
    footer_header = ([[{\r\q2\fs%d\fn%s\c&H%s&}]]):format(o.font_size_wrappers, o.font_name_wrappers, o.font_colour_wrappers),

    --small section styles (for colours)
    multiselect = ([[{\c&H%s&}]]):format(o.font_colour_multiselect),
    selected = ([[{\c&H%s&}]]):format(o.font_colour_selected),
    playing = ([[{\c&H%s&}]]):format(o.font_colour_playing),
    playing_selected = ([[{\c&H%s&}]]):format(o.font_colour_playing_multiselected),

    --icon styles
    cursor = ([[{\fn%s\c&H%s&}]]):format(o.font_name_cursor, o.font_colour_cursor),
    cursor_select = ([[{\fn%s\c&H%s&}]]):format(o.font_name_cursor, o.font_colour_multiselect),
    cursor_deselect = ([[{\fn%s\c&H%s&}]]):format(o.font_name_cursor, o.font_colour_selected),
    folder = ([[{\fn%s}]]):format(o.font_name_folder),
    selection_marker = ([[{\alpha&H%s}]]):format(o.font_opacity_selection_marker),
}

local state = {
    list = {},
    selected = 1,
    hidden = true,
    flag_update = false,
    keybinds = nil,

    parser = nil,
    directory = nil,
    directory_label = nil,
    prev_directory = "",
    co = nil,

    multiselect_start = nil,
    initial_selection = nil,
    selection = {}
}

--the parser table actually contains 3 entries for each parser
--a numeric entry which represents the priority of the parsers and has the parser object as the value
--a string entry representing the id of each parser and with the parser object as the value
--and a table entry with the parser itself as the key and a table value in the form { id = %s, index = %d }
local parsers = {}

--this table contains the parse_state tables for every parse operation indexed with the coroutine used for the parse
--this table has weakly referenced keys, meaning that once the coroutine for a parse is no-longer used by anything that
--field in the table will be removed by the garbage collector
local parse_states = setmetatable({}, { __mode = "k"})

local extensions = {}
local sub_extensions = {}
local audio_extensions = {}
local parseable_extensions = {}

local dvd_device = nil
local current_file = {
    directory = nil,
    name = nil,
    path = nil
}

local root = nil

--default list of compatible file extensions
--adding an item to this list is a valid request on github
local compatible_file_extensions = {
    "264","265","3g2","3ga","3ga2","3gp","3gp2","3gpp","3iv","a52","aac","adt","adts","ahn","aif","aifc","aiff","amr","ape","asf","au","avc","avi","awb","ay",
    "bmp","cue","divx","dts","dtshd","dts-hd","dv","dvr","dvr-ms","eac3","evo","evob","f4a","flac","flc","fli","flic","flv","gbs","gif","gxf","gym",
    "h264","h265","hdmov","hdv","hes","hevc","jpeg","jpg","kss","lpcm","m1a","m1v","m2a","m2t","m2ts","m2v","m3u","m3u8","m4a","m4v","mk3d","mka","mkv",
    "mlp","mod","mov","mp1","mp2","mp2v","mp3","mp4","mp4v","mp4v","mpa","mpe","mpeg","mpeg2","mpeg4","mpg","mpg4","mpv","mpv2","mts","mtv","mxf","nsf",
    "nsfe","nsv","nut","oga","ogg","ogm","ogv","ogx","opus","pcm","pls","png","qt","ra","ram","rm","rmvb","sap","snd","spc","spx","svg","thd","thd+ac3",
    "tif","tiff","tod","trp","truehd","true-hd","ts","tsa","tsv","tta","tts","vfw","vgm","vgz","vob","vro","wav","weba","webm","webp","wm","wma","wmv","wtv",
    "wv","x264","x265","xvid","y4m","yuv"
}

--------------------------------------------------------------------------------------------------------
--------------------------------------Cache Implementation----------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--metatable of methods to manage the cache
local __cache = {}

__cache.cached_values = {
    "directory", "directory_label", "list", "selected", "selection", "parser", "empty_text", "co"
}

--inserts latest state values onto the cache stack
function __cache:push()
    local t = {}
    for _, value in ipairs(self.cached_values) do
        t[value] = state[value]
    end
    table.insert(self, t)
end

function __cache:pop()
    table.remove(self)
end

function __cache:apply()
    local t = self[#self]
    for _, value in ipairs(self.cached_values) do
        state[value] = t[value]
    end
end

function __cache:clear()
    for i = 1, #self do
        self[i] = nil
    end
end

local cache = setmetatable({}, { __index = __cache })



--------------------------------------------------------------------------------------------------------
-----------------------------------------Utility Functions----------------------------------------------
---------------------------------------Part of the addon API--------------------------------------------
--------------------------------------------------------------------------------------------------------

API.list = {}
API.coroutine = {}
local ABORT_ERROR = {
    msg = "browser is no longer waiting for list - aborting parse"
}

--implements table.pack if on lua 5.1
if not table.pack then
    table.unpack = unpack
    function table.pack(...)
        local t = {...}
        t.n = select("#", ...)
        return t
    end
end

-- returns true if the given item exists inside the given table
function API.list.indexOf(t, item, from_index)
    for i = from_index or 1, #t, 1 do
        if t[i] == item then return i end
    end
    return -1
end

--returns whether or not the given table contains an entry that
--causes the given function to evaluate to true
function API.list.some(t, fn)
    for i, v in ipairs(t) do
        if fn(v, i, t) then return true end
    end
    return false
end

--prints an error message and a stack trace
--accepts an error object and optionally a coroutine
--can be passed directly to xpcall
function API.traceback(errmsg, co)
    if co then
        msg.warn(debug.traceback(co))
    else
        msg.warn(debug.traceback("", 2))
    end
    msg.error(errmsg)
end

--returns a table that stores the given table t as the __index in its metatable
--creates a prototypally inherited table
function API.redirect_table(t)
    return setmetatable({}, { __index = t })
end

--prints an error if a coroutine returns an error
--unlike the next function this one still returns the results of coroutine.resume()
function API.coroutine.resume_catch(...)
    local returns = table.pack(coroutine.resume(...))
    if not returns[1] and returns[2] ~= ABORT_ERROR then
        API.traceback(returns[2], select(1, ...))
    end
    return table.unpack(returns, 1, returns.n)
end

--resumes a coroutine and prints an error if it was not sucessful
function API.coroutine.resume_err(...)
    local success, err = coroutine.resume(...)
    if not success and err ~= ABORT_ERROR then
        API.traceback(err, select(1, ...))
    end
    return success
end

--in lua 5.1 there is only one return value which will be nil if run from the main thread
--in lua 5.2 main will be true if running from the main thread
function API.coroutine.assert(err)
    local co, main = coroutine.running()
    assert(not main and co, err or "error - function must be executed from within a coroutine")
    return co
end

--creates a callback fuction to resume the current coroutine
function API.coroutine.callback()
    local co = API.coroutine.assert("cannot create a coroutine callback for the main thread")
    return function(...)
        return API.coroutine.resume_err(co, ...)
    end
end

--puts the current coroutine to sleep for the given number of seconds
function API.coroutine.sleep(n)
    mp.add_timeout(n, API.coroutine.callback())
    coroutine.yield()
end

--runs the given function in a coroutine, passing through any additional arguments
--this is for triggering an event in a coroutine
function API.coroutine.run(fn, ...)
    local co = coroutine.create(fn)
    API.coroutine.resume_err(co, ...)
end

--get the full path for the current file
function API.get_full_path(item, dir)
    if item.path then return item.path end
    return (dir or state.directory)..item.name
end

--gets the path for a new subdirectory, redirects if the path field is set
--returns the new directory path and a boolean specifying if a redirect happened
function API.get_new_directory(item, directory)
    if item.path and item.redirect ~= false then return item.path, true end
    if directory == "" then return item.name end
    if string.sub(directory, -1) == "/" then return directory..item.name end
    return directory.."/"..item.name
end

--returns the file extension of the given file
function API.get_extension(filename, def)
    return string.lower(filename):match("%.([^%./]+)$") or def
end

--returns the protocol scheme of the given url, or nil if there is none
function API.get_protocol(filename, def)
    return string.lower(filename):match("^(%a[%w+-.]*)://") or def
end

--formats strings for ass handling
--this function is based on a similar function from https://github.com/mpv-player/mpv/blob/master/player/lua/console.lua#L110
function API.ass_escape(str, replace_newline)
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
function API.pattern_escape(str)
    return string.gsub(str, "([%^%$%(%)%%%.%[%]%*%+%-])", "%%%1")
end

--standardises filepaths across systems
function API.fix_path(str, is_directory)
    str = string.gsub(str, [[\]],[[/]])
    str = str:gsub([[/%./]], [[/]])
    if is_directory and str:sub(-1) ~= '/' then str = str..'/' end
    return str
end

--wrapper for utils.join_path to handle protocols
function API.join_path(working, relative)
    return API.get_protocol(relative) and relative or utils.join_path(working, relative)
end

--sorts the table lexicographically ignoring case and accounting for leading/non-leading zeroes
--the number format functionality was proposed by github user twophyro, and was presumably taken
--from here: http://notebook.kulchenko.com/algorithms/alphanumeric-natural-sorting-for-humans-in-lua
function API.sort(t)
    local function padnum(d)
        local r = string.match(d, "0*(.+)")
        return ("%03d%s"):format(#r, r)
    end

    --appends the letter d or f to the start of the comparison to sort directories and folders as well
    table.sort(t, function(a,b) return a.type:sub(1,1)..(a.label or a.name):lower():gsub("%d+",padnum) < b.type:sub(1,1)..(b.label or b.name):lower():gsub("%d+",padnum) end)
    return t
end

function API.valid_dir(dir)
    if o.filter_dot_dirs and string.sub(dir, 1, 1) == "." then return false end
    return true
end

function API.valid_file(file)
    if o.filter_dot_files and (string.sub(file, 1, 1) == ".") then return false end
    if o.filter_files and not extensions[ API.get_extension(file, "") ] then return false end
    return true
end

--returns whether or not the item can be parsed
function API.parseable_item(item)
    return item.type == "dir" or parseable_extensions[API.get_extension(item.name, "")]
end

--removes items and folders from the list
--this is for addons which can't filter things during their normal processing
function API.filter(t)
    local max = #t
    local top = 1
    for i = 1, max do
        local temp = t[i]
        t[i] = nil

        if  ( temp.type == "dir" and API.valid_dir(temp.label or temp.name) ) or
            ( temp.type == "file" and API.valid_file(temp.label or temp.name) )
        then
            t[top] = temp
            top = top+1
        end
    end
    return t
end

--returns a string iterator that uses the root separators
function API.iterate_opt(str)
    return string.gmatch(str, "([^"..API.pattern_escape(o.root_separators).."]+)")
end

--sorts a table into an array of selected items in the correct order
--if a predicate function is passed, then the item will only be added to
--the table if the function returns true
function API.sort_keys(t, include_item)
    local keys = {}
    for k in pairs(t) do
        local item = state.list[k]
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
function API.format_json_safe(t)
    --operate on a copy of the table to prevent any data loss in the original table
    t = json_safe_recursive(API.copy_table(t))
    local success, result, err = pcall(utils.format_json, t)
    if success then return result, err
    else return nil, result end
end

--evaluates and runs the given string in both Lua 5.1 and 5.2
--the name argument is used for error reporting
--provides the mpv modules and the fb module to the string
function API.evaluate_string(str, name)
    local env = API.redirect_table(_G)
    env.mp = API.redirect_table(mp)
    env.msg = API.redirect_table(msg)
    env.utils = API.redirect_table(utils)
    env.fb = API.redirect_table(API)
    env.input = input and API.redirect_table(input)

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
function API.copy_table(t, depth)
    --this is to handle cyclic table references
    return copy_table_recursive(t, {}, depth or math.huge)
end



--------------------------------------------------------------------------------------------------------
------------------------------------Parser Object Implementation----------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--parser object for the root
--not inserted to the parser list as it has special behaviour
--it does get get added to parsers under it's ID to prevent confusing duplicates
local root_parser = {
    name = "root",
    priority = math.huge,

    --if this is being called then all other parsers have failed and we've fallen back to root
    can_parse = function() return true end,

    --we return the root directory exactly as setup
    parse = function(self)
        return root, {
            sorted = true,
            filtered = true,
            escaped = true,
            parser = self,
            directory = "",
        }
    end
}

--parser ofject for native filesystems
local file_parser = {
    name = "file",
    priority = 110,

    --as the default parser we'll always attempt to use it if all others fail
    can_parse = function(_, directory) return true end,

    --scans the given directory using the mp.utils.readdir function
    parse = function(self, directory)
        local new_list = {}
        local list1 = utils.readdir(directory, 'dirs')
        if list1 == nil then return nil end

        --sorts folders and formats them into the list of directories
        for i=1, #list1 do
            local item = list1[i]

            --filters hidden dot directories for linux
            if self.valid_dir(item) then
                msg.trace(item..'/')
                table.insert(new_list, {name = item..'/', type = 'dir'})
            end
        end

        --appends files to the list of directory items
        local list2 = utils.readdir(directory, 'files')
        for i=1, #list2 do
            local item = list2[i]

            --only adds whitelisted files to the browser
            if self.valid_file(item) then
                msg.trace(item)
                table.insert(new_list, {name = item, type = 'file'})
            end
        end
        return API.sort(new_list), {filtered = true, sorted = true}
    end
}



--------------------------------------------------------------------------------------------------------
-----------------------------------------List Formatting------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--appends the entered text to the overlay
local function append(text)
    if text == nil then return end
    ass.data = ass.data .. text
end

--appends a newline character to the osd
local function newline()
ass.data = ass.data .. '\\N'
end

--detects whether or not to highlight the given entry as being played
local function highlight_entry(v)
    if current_file.name == nil then return false end
    if API.parseable_item(v) then
        return current_file.directory:find(API.get_full_path(v), 1, true)
    else
        return current_file.path == API.get_full_path(v)
    end
end

--saves the directory and name of the currently playing file
local function update_current_directory(_, filepath)
    --if we're in idle mode then we want to open the working directory
    if filepath == nil then 
        current_file.directory = API.fix_path( mp.get_property("working-directory", ""), true)
        current_file.name = nil
        current_file.path = nil
        return
    elseif filepath:find("dvd://") == 1 then
        filepath = dvd_device..filepath:match("dvd://(.*)")
    end

    local workingDirectory = mp.get_property('working-directory', '')
    local exact_path = API.join_path(workingDirectory, filepath)
    exact_path = API.fix_path(exact_path, false)
    current_file.directory, current_file.name = utils.split_path(exact_path)
    current_file.path = exact_path
end

--refreshes the ass text using the contents of the list
local function update_ass()
    if state.hidden then state.flag_update = true ; return end

    ass.data = style.global

    local dir_name = state.directory_label or state.directory
    if dir_name == "" then dir_name = "ROOT" end
    append(style.header)
    append(API.ass_escape(dir_name, style.cursor.."\\\239\187\191n"..style.header))
    append('\\N ----------------------------------------------------')
    newline()

    if #state.list < 1 then
        append(state.empty_text)
        ass:update()
        return
    end

    local start = 1
    local finish = start+o.num_entries-1

    --handling cursor positioning
    local mid = math.ceil(o.num_entries/2)+1
    if state.selected+mid > finish then
        local offset = state.selected - finish + mid

        --if we've overshot the end of the list then undo some of the offset
        if finish + offset > #state.list then
            offset = offset - ((finish+offset) - #state.list)
        end

        start = start + offset
        finish = finish + offset
    end

    --making sure that we don't overstep the boundaries
    if start < 1 then start = 1 end
    local overflow = finish < #state.list
    --this is necessary when the number of items in the dir is less than the max
    if not overflow then finish = #state.list end

    --adding a header to show there are items above in the list
    if start > 1 then append(style.footer_header..(start-1)..' item(s) above\\N\\N') end

    for i=start, finish do
        local v = state.list[i]
        local playing_file = highlight_entry(v)
        append(style.body)

        --handles custom styles for different entries
        if i == state.selected or i == state.multiselect_start then
            if not (i == state.selected) then append(style.selection_marker) end

            if not state.multiselect_start then append(style.cursor)
            else
                if state.selection[state.multiselect_start] then append(style.cursor_select)
                else append(style.cursor_deselect) end
            end
            append(o.cursor_icon.."\\h"..style.body)
        else
            append(o.indent_icon.."\\h"..style.body)
        end

        --sets the selection colour scheme
        local multiselected = state.selection[i]

        --sets the colour for the item
        local function set_colour()
            if multiselected then append(style.multiselect)
            elseif i == state.selected then append(style.selected) end

            if playing_file then append( multiselected and style.playing_selected or style.playing) end
        end
        set_colour()

        --sets the folder icon
        if v.type == 'dir' then
            append(style.folder..o.folder_icon.."\\h"..style.body)
            set_colour()
        end

        --adds the actual name of the item
        append(v.ass or API.ass_escape(v.label or v.name, true))
        newline()
    end

    if overflow then append('\\N'..style.footer_header..#state.list-finish..' item(s) remaining') end
    ass:update()
end



--------------------------------------------------------------------------------------------------------
--------------------------------Scroll/Select Implementation--------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--disables multiselect
local function disable_select_mode()
    state.multiselect_start = nil
    state.initial_selection = nil
end

--enables multiselect
local function enable_select_mode()
    state.multiselect_start = state.selected
    state.initial_selection = API.copy_table(state.selection)
end

--calculates what drag behaviour is required for that specific movement
local function drag_select(original_pos, new_pos)
    if original_pos == new_pos then return end

    local setting = state.selection[state.multiselect_start]
    for i = original_pos, new_pos, (new_pos > original_pos and 1 or -1) do
        --if we're moving the cursor away from the starting point then set the selection
        --otherwise restore the original selection
        if i > state.multiselect_start then
            if new_pos > original_pos then
                state.selection[i] = setting
            elseif i ~= new_pos then
                state.selection[i] = state.initial_selection[i]
            end
        elseif i < state.multiselect_start then
            if new_pos < original_pos then
                state.selection[i] = setting
            elseif i ~= new_pos then
                state.selection[i] = state.initial_selection[i]
            end
        end
    end
end

--moves the selector up and down the list by the entered amount
local function scroll(n, wrap)
    local num_items = #state.list
    if num_items == 0 then return end

    local original_pos = state.selected

    if original_pos + n > num_items then
        state.selected = wrap and 1 or num_items
    elseif original_pos + n < 1 then
        state.selected = wrap and num_items or 1
    else
        state.selected = original_pos + n
    end

    if state.multiselect_start then drag_select(original_pos, state.selected) end
    update_ass()
end

--toggles the selection
local function toggle_selection()
    if not state.list[state.selected] then return end
    state.selection[state.selected] = not state.selection[state.selected] or nil
    update_ass()
end

--select all items in the list
local function select_all()
    for i,_ in ipairs(state.list) do
        state.selection[i] = true
    end
    update_ass()
end

--toggles select mode
local function toggle_select_mode()
    if state.multiselect_start == nil then
        enable_select_mode()
        toggle_selection()
    else
        disable_select_mode()
        update_ass()
    end
end



--------------------------------------------------------------------------------------------------------
-----------------------------------------Directory Movement---------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--selects the first item in the list which is highlighted as playing
local function select_playing_item()
    for i,item in ipairs(state.list) do
        if highlight_entry(item) then
            state.selected = i
            return
        end
    end
end

--scans the list for which item to select by default
--chooses the folder that the script just moved out of
--or, otherwise, the item highlighted as currently playing
local function select_prev_directory()
    if state.prev_directory:find(state.directory, 1, true) == 1 then
        local i = 1
        while (state.list[i] and API.parseable_item(state.list[i])) do
            if state.prev_directory:find(API.get_full_path(state.list[i]), 1, true) then
                state.selected = i
                return
            end
            i = i+1
        end
    end

    select_playing_item()
end

--parses the given directory or defers to the next parser if nil is returned
local function choose_and_parse(directory, index)
    msg.debug("finding parser for", directory)
    local parser, list, opts
    local parse_state = API.get_parse_state()
    while list == nil and not parse_state.already_deferred and index <= #parsers do
        parser = parsers[index]
        if parser:can_parse(directory, parse_state) then
            msg.debug("attempting parser:", parser:get_id())
            list, opts = parser:parse(directory, parse_state)
        end
        index = index + 1
    end
    if not list then return nil, {} end

    msg.debug("list returned from:", parser:get_id())
    opts = opts or {}
    if list then opts.id = opts.id or parser:get_id() end
    return list, opts
end

--sets up the parse_state table and runs the parse operation
local function run_parse(directory, parse_state)
    msg.verbose("scanning files in", directory)
    parse_state.directory = directory

    local co = coroutine.running()
    parse_states[co] = setmetatable(parse_state, { __index = parse_state_API })

    if directory == "" then return root_parser:parse() end
    local list, opts = choose_and_parse(directory, 1)

    if list == nil then return msg.debug("no successful parsers found") end
    opts.parser = parsers[opts.id]

    if not opts.filtered then API.filter(list) end
    if not opts.sorted then API.sort(list) end
    return list, opts
end

--returns the contents of the given directory using the given parse state
--if a coroutine has already been used for a parse then create a new coroutine so that
--the every parse operation has a unique thread ID
local function parse_directory(directory, parse_state)
    local co = API.coroutine.assert("scan_directory must be executed from within a coroutine - aborting scan "..utils.to_string(parse_state))
    if not parse_states[co] then return run_parse(directory, parse_state) end

    --if this coroutine is already is use by another parse operation then we create a new
    --one and hand execution over to that
    local new_co = coroutine.create(function()
        API.coroutine.resume_err(co, run_parse(directory, parse_state))
    end)

    --queue the new coroutine on the mpv event queue
    mp.add_timeout(0, function()
        local success, err = coroutine.resume(new_co)
        if not success then
            API.traceback(err, new_co)
            API.coroutine.resume_err(co)
        end
    end)
    return parse_states[co]:yield()
end

--sends update requests to the different parsers
local function update_list(moving_adjacent)
    msg.verbose('opening directory: ' .. state.directory)

    state.selected = 1
    state.selection = {}

    --loads the current directry from the cache to save loading time
    --there will be a way to forcibly reload the current directory at some point
    --the cache is in the form of a stack, items are taken off the stack when the dir moves up
    if cache[1] and cache[#cache].directory == state.directory then
        msg.verbose('found directory in cache')
        cache:apply()
        state.prev_directory = state.directory
        return
    end
    local directory = state.directory
    local list, opts = parse_directory(state.directory, { source = "browser" })

    --if the running coroutine isn't the one stored in the state variable, then the user
    --changed directories while the coroutine was paused, and this operation should be aborted
    if coroutine.running() ~= state.co then
        msg.verbose(ABORT_ERROR.msg)
        msg.debug("expected:", state.directory, "received:", directory)
        return
    end

    --apply fallbacks if the scan failed
    if not list and cache[1] then
        --switches settings back to the previously opened directory
        --to the user it will be like the directory never changed
        msg.warn("could not read directory", state.directory)
        cache:apply()
        return
    elseif not list then
        msg.warn("could not read directory", state.directory)
        list, opts = root_parser:parse()
    end

    state.list = list
    state.parser = opts.parser

    --this only matters when displaying the list on the screen, so it doesn't need to be in the scan function
    if not opts.escaped then
        for i = 1, #list do
            list[i].ass = list[i].ass or API.ass_escape(list[i].label or list[i].name, true)
        end
    end

    --setting custom options from parsers
    state.directory_label = opts.directory_label
    state.empty_text = opts.empty_text or state.empty_text

    --we assume that directory is only changed when redirecting to a different location
    --therefore, the cache should be wiped
    if opts.directory then
        state.directory = opts.directory
        cache:clear()
    end

    if opts.selected_index then
        state.selected = opts.selected_index or state.selected
        if state.selected > #state.list then state.selected = #state.list
        elseif state.selected < 1 then state.selected = 1 end
    end

    if moving_adjacent then select_prev_directory()
    else select_playing_item() end
    state.prev_directory = state.directory
end

--rescans the folder and updates the list
local function update(moving_adjacent)
    --we can only make assumptions about the directory label when moving from adjacent directories
    if not moving_adjacent then
        state.directory_label = nil
        cache:clear()
    end

    state.empty_text = "~"
    state.list = {}
    disable_select_mode()
    update_ass()

    --the directory is always handled within a coroutine to allow addons to
    --pause execution for asynchronous operations
    API.coroutine.run(function()
        state.co = coroutine.running()
        update_list(moving_adjacent)
        state.empty_text = "empty directory"
        update_ass()
    end)
end

--the base function for moving to a directory
local function goto_directory(directory)
    state.directory = directory
    update(false)
end

--loads the root list
local function goto_root()
    msg.verbose('jumping to root')
    goto_directory("")
end

--switches to the directory of the currently playing file
local function goto_current_dir()
    msg.verbose('jumping to current directory')
    goto_directory(current_file.directory)
end

--moves up a directory
local function up_dir()
    local dir = state.directory:reverse()
    local index = dir:find("[/\\]")

    while index == 1 do
        dir = dir:sub(2)
        index = dir:find("[/\\]")
    end

    if index == nil then state.directory = ""
    else state.directory = dir:sub(index):reverse() end

    --we can make some assumptions about the next directory label when moving up or down
    if state.directory_label then state.directory_label = state.directory_label:match("^(.+/)[^/]+/$") end

    update(true)
    cache:pop()
end

--moves down a directory
local function down_dir()
    local current = state.list[state.selected]
    if not current or not API.parseable_item(current) then return end

    cache:push()
    local directory, redirected = API.get_new_directory(current, state.directory)
    state.directory = directory

    --we can make some assumptions about the next directory label when moving up or down
    if state.directory_label then state.directory_label = state.directory_label..(current.label or current.name) end
    update(not redirected)
end



------------------------------------------------------------------------------------------
------------------------------------Browser Controls--------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

--opens the browser
local function open()
    if not state.hidden then return end

    for _,v in ipairs(state.keybinds) do
        mp.add_forced_key_binding(v[1], 'dynamic/'..v[2], v[3], v[4])
    end

    utils.shared_script_property_set("file_browser-open", "yes")
    if o.toggle_idlescreen then mp.commandv('script-message', 'osc-idlescreen', 'no', 'no_osd') end
    state.hidden = false
    if state.directory == nil then
        local path = mp.get_property('path')
        update_current_directory(nil, path)
        if path or o.default_to_working_directory then goto_current_dir() else goto_root() end
        return
    end

    if state.flag_update then update_current_directory(nil, mp.get_property('path')) end
    if not state.flag_update then ass:update()
    else state.flag_update = false ; update_ass() end
end

--closes the list and sets the hidden flag
local function close()
    if state.hidden then return end

    for _,v in ipairs(state.keybinds) do
        mp.remove_key_binding('dynamic/'..v[2])
    end

    utils.shared_script_property_set("file_browser-open", "no")
    if o.toggle_idlescreen then mp.commandv('script-message', 'osc-idlescreen', 'yes', 'no_osd') end
    state.hidden = true
    ass:remove()
end

--toggles the list
local function toggle()
    if state.hidden then open()
    else close() end
end

--run when the escape key is used
local function escape()
    --if multiple items are selection cancel the
    --selection instead of closing the browser
    if next(state.selection) or state.multiselect_start then
        state.selection = {}
        disable_select_mode()
        update_ass()
        return
    end
    close()
end

--opens a specific directory
local function browse_directory(directory)
    if not directory then return end
    directory = mp.command_native({"expand-path", directory}, "")
    -- directory = join_path( mp.get_property("working-directory", ""), directory )

    if directory ~= "" then directory = API.fix_path(directory, true) end
    msg.verbose('recieved directory from script message: '..directory)

    if directory == "dvd://" then directory = dvd_device end
    goto_directory(directory)
    open()
end



------------------------------------------------------------------------------------------
---------------------------------File/Playlist Opening------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

--adds a file to the playlist and changes the flag to `append-play` in preparation
--for future items
local function loadfile(file, opts)
    if o.substitute_backslash and not API.get_protocol(file) then
        file = file:gsub("/", "\\")
    end

    if opts.flag == "replace" then msg.verbose("Playling file", file)
    else msg.verbose("Appending", file, "to the playlist") end

    if not mp.commandv("loadfile", file, opts.flag) then msg.warn(file) end
    opts.flag = "append-play"
    opts.items_appended = opts.items_appended + 1
end

--this function recursively loads directories concurrently in separate coroutines
--results are saved in a tree of tables that allows asynchronous access
local function concurrent_loadlist_parse(directory, load_opts, prev_dirs, item_t)
    --prevents infinite recursion from the item.path or opts.directory fields
    if prev_dirs[directory] then return end
    prev_dirs[directory] = true

    local list, list_opts = parse_directory(directory, { source = "loadlist" })
    if list == root then return end

    --if we can't parse the directory then append it and hope mpv fares better
    if list == nil then
        msg.warn("Could not parse", directory, "appending to playlist anyway")
        item_t.type = "file"
        return
    end

    directory = list_opts.directory or directory
    if directory == "" then return end

    --we must declare these before we start loading sublists otherwise the append thread will
    --need to wait until the whole list is loaded (when synchronous IO is used)
    item_t._sublist = list or {}
    list._directory = directory

    --launches new parse operations for directories, each in a different coroutine
    for _, item in ipairs(list) do
        if API.parseable_item(item) then
            API.coroutine.run(concurrent_loadlist_wrapper, API.get_new_directory(item, directory), load_opts, prev_dirs, item)
        end
    end
    return true
end

--a wrapper function that ensures the concurrent_loadlist_parse is run correctly
function concurrent_loadlist_wrapper(directory, opts, prev_dirs, item)
    --ensures that only a set number of concurrent parses are operating at any one time.
    --the mpv event queue is seemingly limited to 1000 items, but only async mpv actions like
    --command_native_async should use that, events like mp.add_timeout (which coroutine.sleep() uses) should
    --be handled enturely on the Lua side with a table, which has a significantly larger maximum size.
    while (opts.concurrency > o.max_concurrency) do
        API.coroutine.sleep(0.1)
    end
    opts.concurrency = opts.concurrency + 1

    local success = concurrent_loadlist_parse(directory, opts, prev_dirs, item)
    opts.concurrency = opts.concurrency - 1
    if not success then item._sublist = {} end
    if coroutine.status(opts.co) == "suspended" then API.coroutine.resume_err(opts.co) end
end

--recursively appends items to the playlist, acts as a consumer to the previous functions producer;
--if the next directory has not been parsed this function will yield until the parse has completed
local function concurrent_loadlist_append(list, load_opts)
    local directory = list._directory

    for _, item in ipairs(list) do
        if not sub_extensions[ API.get_extension(item.name, "") ]
        and not audio_extensions[ API.get_extension(item.name, "") ]
        then
            while (not item._sublist and API.parseable_item(item)) do
                coroutine.yield()
            end

            if API.parseable_item(item) then
                concurrent_loadlist_append(item._sublist, load_opts)
            else
                loadfile(API.get_full_path(item, directory), load_opts)
            end
        end
    end
end

--recursive function to load directories using the script custom parsers
--returns true if any items were appended to the playlist
local function custom_loadlist_recursive(directory, load_opts, prev_dirs)
    --prevents infinite recursion from the item.path or opts.directory fields
    if prev_dirs[directory] then return end
    prev_dirs[directory] = true

    local list, opts = parse_directory(directory, { source = "loadlist" })
    if list == root then return end

    --if we can't parse the directory then append it and hope mpv fares better
    if list == nil then
        msg.warn("Could not parse", directory, "appending to playlist anyway")
        loadfile(directory, load_opts.flag)
        return true
    end

    directory = opts.directory or directory
    if directory == "" then return end

    for _, item in ipairs(list) do
        if not sub_extensions[ API.get_extension(item.name, "") ]
        and not audio_extensions[ API.get_extension(item.name, "") ]
        then
            if API.parseable_item(item) then
                custom_loadlist_recursive( API.get_new_directory(item, directory) , load_opts, prev_dirs)
            else
                local path = API.get_full_path(item, directory)
                loadfile(path, load_opts)
            end
        end
    end
end


--a wrapper for the custom_loadlist_recursive function
local function loadlist(item, opts)
    local dir = API.get_full_path(item, opts.directory)
    local num_items = opts.items_appended

    if o.concurrent_recursion then
        item = API.copy_table(item)
        opts.co = API.coroutine.assert()
        opts.concurrency = 0

        --we need the current coroutine to suspend before we run the first parse operation, so
        --we schedule the coroutine to run on the mpv event queue
        mp.add_timeout(0, function()
            API.coroutine.run(concurrent_loadlist_wrapper, dir, opts, {}, item)
        end)
        concurrent_loadlist_append({item, _directory = opts.directory}, opts)
    else
        custom_loadlist_recursive(dir, opts, {})
    end

    if opts.items_appended == num_items then msg.warn(dir, "contained no valid files") end
end

--load playlist entries before and after the currently playing file
local function autoload_dir(path, opts)
    if o.autoload_save_current and path == current_file.path then
        mp.commandv("write-watch-later-config") end

    --loads the currently selected file, clearing the playlist in the process
    loadfile(path, opts)

    local pos = 1
    local file_count = 0
    for _,item in ipairs(state.list) do
        if item.type == "file" 
        and not sub_extensions[ API.get_extension(item.name, "") ]
        and not audio_extensions[ API.get_extension(item.name, "") ]
        then
            local p = API.get_full_path(item)

            if p == path then pos = file_count
            else loadfile( p, opts) end

            file_count = file_count + 1
        end
    end
    mp.commandv("playlist-move", 0, pos+1)
end

--runs the loadfile or loadlist command
local function open_item(item, opts)
    if API.parseable_item(item) then
        return loadlist(item, opts)
    end

    local path = API.get_full_path(item, opts.directory)
    if sub_extensions[ API.get_extension(item.name, "") ] then
        mp.commandv("sub-add", path, opts.flag == "replace" and "select" or "auto")
    elseif audio_extensions[ API.get_extension(item.name, "") ] then
        mp.commandv("audio-add", path, opts.flag == "replace" and "select" or "auto")
    else
        if opts.autoload then autoload_dir(path, opts)
        else loadfile(path, opts) end
    end
end

--handles the open options as a coroutine
--once loadfile has been run we can no-longer guarantee synchronous execution - the state values may change
--therefore, we must ensure that any state values that could be used after a loadfile call are saved beforehand
local function open_file_coroutine(opts)
    if not state.list[state.selected] then return end
    if opts.flag == 'replace' then close() end

    --we want to set the idle option to yes to ensure that if the first item
    --fails to load then the player has a chance to attempt to load further items (for async append operations)
    local idle = mp.get_property("idle", "once")
    mp.set_property("idle", "yes")

    --handles multi-selection behaviour
    if next(state.selection) then
        local selection = API.sort_keys(state.selection)
        --reset the selection after
        state.selection = {}

        disable_select_mode()
        update_ass()

        --the currently selected file will be loaded according to the flag
        --the flag variable will be switched to append once a file is loaded
        for i=1, #selection do
            open_item(selection[i], opts)
        end

    else
        local item = state.list[state.selected]
        if opts.flag == "replace" then down_dir() end
        open_item(item, opts)
    end

    if mp.get_property("idle") == "yes" then mp.set_property("idle", idle) end
end

--opens the selelected file(s)
local function open_file(flag, autoload)
    API.coroutine.run(open_file_coroutine, {
        flag = flag,
        autoload = (autoload ~= o.autoload and flag == "replace"),
        directory = state.directory,
        items_appended = 0
    })
end



------------------------------------------------------------------------------------------
----------------------------------Keybind Implementation----------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

state.keybinds = {
    {'ENTER',       'play',         function() open_file('replace', false) end},
    {'Shift+ENTER', 'play_append',  function() open_file('append-play', false) end},
    {'Alt+ENTER',   'play_autoload',function() open_file('replace', true) end},
    {'ESC',         'close',        escape},
    {'RIGHT',       'down_dir',     down_dir},
    {'LEFT',        'up_dir',       up_dir},
    {'DOWN',        'scroll_down',  function() scroll(1, o.wrap) end,           {repeatable = true}},
    {'UP',          'scroll_up',    function() scroll(-1, o.wrap) end,          {repeatable = true}},
    {'PGDWN',       'page_down',    function() scroll(o.num_entries) end,       {repeatable = true}},
    {'PGUP',        'page_up',      function() scroll(-o.num_entries) end,      {repeatable = true}},
    {'Shift+PGDWN', 'list_bottom',  function() scroll(math.huge) end},
    {'Shift+PGUP',  'list_top',     function() scroll(-math.huge) end},
    {'HOME',        'goto_current', goto_current_dir},
    {'Shift+HOME',  'goto_root',    goto_root},
    {'Ctrl+r',      'reload',       function() cache:clear(); update() end},
    {'s',           'select_mode',  toggle_select_mode},
    {'S',           'select_item',  toggle_selection},
    {'Ctrl+a',      'select_all',   select_all}
}

--a map of key-keybinds - only saves the latest keybind if multiple have the same key code
local top_level_keys = {}

--format the item string for either single or multiple items
local function create_item_string(fn)
    local quoted_fn = function(...) return ("%q"):format(fn(...)) end
    return function(cmd, items, state, code)
        if not items[1] then return end
        local func = code == code:upper() and quoted_fn or fn

        local str = func(cmd, items[1], state, code)
        for i = 2, #items, 1 do
            str = str .. ( cmd["concat-string"] or " " ) .. func(cmd, items[i], state, code)
        end
        return str
    end
end

--functions to replace custom-keybind codes
local code_fns
code_fns = {
    ["%"] = "%",

    f = create_item_string(function(_, item, s) return item and API.get_full_path(item, s.directory) or "" end),
    n = create_item_string(function(_, item, _) return item and (item.label or item.name) or "" end),
    i = create_item_string(function(_, item, s) return API.list.indexOf(s.list, item) end),
    j = create_item_string(function(_, item, s) return math.abs(API.list.indexOf( API.sort_keys(s.selection) , item)) end),

    p = function(_, _, s) return s.directory or "" end,
    d = function(_, _, s) return (s.directory_label or s.directory):match("([^/]+)/?$") or "" end,
    r = function(_, _, s) return s.parser.keybind_name or s.parser.name or "" end,
}

--codes that are specific to individual items require custom encapsulation behaviour
--hence we need to manually specify the uppercase codes in the table
code_fns.F = code_fns.f
code_fns.N = code_fns.n
code_fns.I = code_fns.i
code_fns.J = code_fns.j

--programatically creates a pattern that matches any key code
--this will result in some duplicates but that shouldn't really matter
local CUSTOM_KEYBIND_CODES = ""
for key in pairs(code_fns) do CUSTOM_KEYBIND_CODES = CUSTOM_KEYBIND_CODES..key:lower()..key:upper() end
local KEYBIND_CODE_PATTERN = ('%%%%([%s])'):format(API.ass_escape(CUSTOM_KEYBIND_CODES))

--substitutes the key codes for the 
local function substitute_codes(str, cmd, items, state)
    return string.gsub(str, KEYBIND_CODE_PATTERN, function(code)
        if type(code_fns[code]) == "string" then return code_fns[code] end

        --encapsulates the string if using an uppercase code
        if not code_fns[code] then
            local lower = code_fns[code:lower()]
            if not lower then return end
            return string.format("%q", lower(cmd, items, state, code))
        end

        return code_fns[code](cmd, items, state, code)
    end)
end

--iterates through the command table and substitutes special
--character codes for the correct strings used for custom functions
local function format_command_table(cmd, items, state)
    local copy = {}
    for i = 1, #cmd.command do
        copy[i] = {}

        for j = 1, #cmd.command[i] do
            copy[i][j] = substitute_codes(cmd.command[i][j], cmd, items, state)
        end
    end
    return copy
end

--runs all of the commands in the command table
--key.command must be an array of command tables compatible with mp.command_native
--items must be an array of multiple items (when multi-type ~= concat the array will be 1 long)
local function run_custom_command(cmd, items, state)
    local custom_cmds = cmd.codes and format_command_table(cmd, items, state) or cmd.command

    for _, custom_cmd in ipairs(custom_cmds) do
        msg.debug("running command:", utils.to_string(custom_cmd))
        mp.command_native(custom_cmd)
    end
end

--returns true if the given code set has item specific codes (%f, %i, etc)
local function has_item_codes(codes)
    for code in pairs(codes) do
        if code_fns[code:upper()] then return true end
    end
    return false
end

--runs one of the custom commands
local function run_custom_keybind(cmd, state, co)
    --evaluates a condition and passes through the correct values
    local function evaluate_condition(condition, items)
        local cond = substitute_codes(condition, cmd, items, state)
        return API.evaluate_string('return '..cond) == true
    end

    -- evaluates the string condition to decide if the keybind should be run
    local do_item_condition
    if cmd.condition then
        if has_item_codes(cmd.condition_codes) then
            do_item_condition = true
        elseif not evaluate_condition(cmd.condition, {}) then
            return false
        end
    end

    if cmd.parser then
       local parser_str = ' '..cmd.parser..' '
       if not parser_str:find( '%W'..(state.parser.keybind_name or state.parser.name)..'%W' ) then return false end
    end

    --these are for the default keybinds, or from addons which use direct functions
    if type(cmd.command) == 'function' then return cmd.command(cmd, cmd.addon and API.copy_table(state) or state, co) end

    --the function terminates here if we are running the command on a single item
    if not (cmd.multiselect and next(state.selection)) then
        if cmd.filter then
            if not state.list[state.selected] then return false end
            if state.list[state.selected].type ~= cmd.filter then return false end
        end

        if cmd.codes then
            --if the directory is empty, and this command needs to work on an item, then abort and fallback to the next command
            if not state.list[state.selected] and has_item_codes(cmd.codes) then return false end
        end

        if do_item_condition and not evaluate_condition(cmd.condition, { state.list[state.selected] }) then
            return false
        end
        run_custom_command(cmd, { state.list[state.selected] }, state)
        return true
    end

    --runs the command on all multi-selected items
    local selection = API.sort_keys(state.selection, function(item)
        if do_item_condition and not evaluate_condition(cmd.condition, { item }) then return false end
        return not cmd.filter or item.type == cmd.filter
    end)
    if not next(selection) then return false end

    if cmd["multi-type"] == "concat" then
        run_custom_command(cmd, selection, state)

    elseif cmd["multi-type"] == "repeat" or cmd["multi-type"] == nil then
        for i,_ in ipairs(selection) do
            run_custom_command(cmd, {selection[i]}, state)

            if cmd.delay then
                mp.add_timeout(cmd.delay, function() API.coroutine.resume_err(co) end)
                coroutine.yield()
            end
        end
    end

    --we passthrough by default if the command is not run on every selected item
    if cmd.passthrough ~= nil then return end

    local num_selection = 0
    for _ in pairs(state.selection) do num_selection = num_selection+1 end
    return #selection == num_selection
end

--recursively runs the keybind functions, passing down through the chain
--of keybinds with the same key value
local function run_keybind_recursive(keybind, state, co)
    msg.trace("Attempting custom command:", utils.to_string(keybind))

    if keybind.passthrough ~= nil then
        run_custom_keybind(keybind, state, co)
        if keybind.passthrough == true and keybind.prev_key then
            run_keybind_recursive(keybind.prev_key, state, co)
        end
    else
        if run_custom_keybind(keybind, state, co) == false and keybind.prev_key then
            run_keybind_recursive(keybind.prev_key, state, co)
        end
    end
end

--a wrapper to run a custom keybind as a lua coroutine
local function run_keybind_coroutine(key)
    msg.debug("Received custom keybind "..key.key)
    local co = coroutine.create(run_keybind_recursive)

    local state_copy = {
        directory = state.directory,
        directory_label = state.directory_label,
        list = state.list,                      --the list should remain unchanged once it has been saved to the global state, new directories get new tables
        selected = state.selected,
        selection = API.copy_table(state.selection),
        parser = state.parser,
    }
    local success, err = coroutine.resume(co, key, state_copy, co)
    if not success then
        msg.error("error running keybind:", utils.to_string(key))
        API.traceback(err, co)
    end
end

--scans the given command table to identify if they contain any custom keybind codes
local function scan_for_codes(command_table, codes)
    if type(command_table) ~= "table" then return codes end
    for _, value in pairs(command_table) do
        local type = type(value)
        if type == "table" then
            scan_for_codes(value, codes)
        elseif type == "string" then
            value:gsub(KEYBIND_CODE_PATTERN, function(code) codes[code] = true end)
        end
    end
    return codes
end

--inserting the custom keybind into the keybind array for declaration when file-browser is opened
--custom keybinds with matching names will overwrite eachother
local function insert_custom_keybind(keybind)
    --we'll always save the keybinds as either an array of command arrays or a function
    if type(keybind.command) == "table" and type(keybind.command[1]) ~= "table" then
        keybind.command = {keybind.command}
    end

    keybind.codes = scan_for_codes(keybind.command, {})
    if not next(keybind.codes) then keybind.codes = nil end
    keybind.prev_key = top_level_keys[keybind.key]

    if keybind.condition then
        keybind.condition_codes = {}
        for code in string.gmatch(keybind.condition, KEYBIND_CODE_PATTERN) do keybind.condition_codes[code] = true end
    end

    table.insert(state.keybinds, {keybind.key, keybind.name, function() run_keybind_coroutine(keybind) end, keybind.flags or {}})
    top_level_keys[keybind.key] = keybind
end

--loading the custom keybinds
--can either load keybinds from the config file, from addons, or from both
local function setup_keybinds()
    if not o.custom_keybinds and not o.addons then return end

    --this is to make the default keybinds compatible with passthrough from custom keybinds
    for _, keybind in ipairs(state.keybinds) do
        top_level_keys[keybind[1]] = { key = keybind[1], name = keybind[2], command = keybind[3], flags = keybind[4] }
    end

    --this loads keybinds from addons
    if o.addons then
        for i = #parsers, 1, -1 do
            local parser = parsers[i]
            if parser.keybinds then
                for i, keybind in ipairs(parser.keybinds) do
                    --if addons use the native array command format, then we need to convert them over to the custom command format
                    if not keybind.key then keybind = { key = keybind[1], name = keybind[2], command = keybind[3], flags = keybind[4] }
                    else keybind = API.copy_table(keybind) end

                    keybind.name = parsers[parser].id.."/"..(keybind.name or tostring(i))
                    keybind.addon = true
                    insert_custom_keybind(keybind)
                end
            end
        end
    end

    --loads custom keybinds from file-browser-keybinds.json
    if o.custom_keybinds then
        local path = mp.command_native({"expand-path", "~~/script-opts"}).."/file-browser-keybinds.json"
        local custom_keybinds, err = io.open( path )
        if not custom_keybinds then return error(err) end

        local json = custom_keybinds:read("*a")
        custom_keybinds:close()

        json = utils.parse_json(json)
        if not json then return error("invalid json syntax for "..path) end

        for i, keybind in ipairs(json) do
            keybind.name = "custom/"..(keybind.name or tostring(i))
            insert_custom_keybind(keybind)
        end
    end
end



--------------------------------------------------------------------------------------------------------
-------------------------------------------API Functions------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--these functions we'll provide as-is
API.redraw = update_ass
API.rescan = update
API.browse_directory = browse_directory

function API.clear_cache()
    cache:clear()
end

--a wrapper around scan_directory for addon API
function API.parse_directory(directory, parse_state)
    if not parse_state then parse_state = { source = "addon" }
    elseif not parse_state.source then parse_state.source = "addon" end
    return parse_directory(directory, parse_state)
end

--register file extensions which can be opened by the browser
function API.register_parseable_extension(ext)
    parseable_extensions[string.lower(ext)] = true
end
function API.remove_parseable_extension(ext)
    parseable_extensions[string.lower(ext)] = nil
end

--add a compatible extension to show through the filter, only applies if run during the setup() method
function API.add_default_extension(ext)
    table.insert(compatible_file_extensions, ext)
end

--add item to root at position pos
function API.insert_root_item(item, pos)
    msg.debug("adding item to root", item.label or item.name, pos)
    item.ass = item.ass or API.ass_escape(item.label or item.name)
    item.type = "dir"
    table.insert(root, pos or (#root + 1), item)
end

--a newer API for adding items to the root
--only adds the item if the same item does not already exist in the root
--the priority variable is a number that specifies the insertion location
--a lower priority is placed higher in the list and the default is 100
function API.register_root_item(item, priority)
    msg.verbose('registering root item:', utils.to_string(item))
    if type(item) == 'string' then
        item = {name = item}
    end

    -- if the item is already in the list then do nothing
    if API.list.some(root, function(r)
        return API.get_full_path(r, '') == API.get_full_path(item, '')
    end) then return false end

    item._priority = priority
    for i, v in ipairs(root) do
        if (v._priority or 100) > (priority or 100) then
            API.insert_root_item(item, i)
            return true
        end
    end
    API.insert_root_item(item)
    return true
end

--providing getter and setter functions so that addons can't modify things directly
function API.get_script_opts() return API.copy_table(o) end
function API.get_opt(key) return o[key] end
function API.get_extensions() return API.copy_table(extensions) end
function API.get_sub_extensions() return API.copy_table(sub_extensions) end
function API.get_audio_extensions() return API.copy_table(audio_extensions) end
function API.get_parseable_extensions() return API.copy_table(parseable_extensions) end
function API.get_state() return API.copy_table(state) end
function API.get_dvd_device() return dvd_device end
function API.get_parsers() return API.copy_table(parsers) end
function API.get_root() return API.copy_table(root) end
function API.get_directory() return state.directory end
function API.get_list() return API.copy_table(state.list) end
function API.get_current_file() return API.copy_table(current_file) end
function API.get_current_parser() return state.parser:get_id() end
function API.get_current_parser_keyname() return state.parser.keybind_name or state.parser.name end
function API.get_selected_index() return state.selected end
function API.get_selected_item() return API.copy_table(state.list[state.selected]) end
function API.get_open_status() return not state.hidden end
function API.get_parse_state(co) return parse_states[co or coroutine.running() or ""] end

function API.set_empty_text(str)
    state.empty_text = str
    API.redraw()
end

function API.set_selected_index(index)
    if type(index) ~= "number" then return false end
    if index < 1 then index = 1 end
    if index > #state.list then index = #state.list end
    state.selected = index
    API.redraw()
    return index
end

function parser_API:get_index() return parsers[self].index end
function parser_API:get_id() return parsers[self].id end

--a wrapper that passes the parsers priority value if none other is specified
function parser_API:register_root_item(item, priority)
    return API.register_root_item(item, priority or parsers[self:get_id()].priority)
end

--runs choose_and_parse starting from the next parser
function parser_API:defer(directory)
    msg.trace("deferring to other parsers...")
    local list, opts = choose_and_parse(directory, self:get_index() + 1)
    API.get_parse_state().already_deferred = true
    return list, opts
end

--a wrapper around coroutine.yield that aborts the coroutine if
--the parse request was cancelled by the user
--the coroutine is 
function parse_state_API:yield(...)
    local co = coroutine.running()
    local is_browser = co == state.co
    if self.source == "browser" and not is_browser then
        msg.error("current coroutine does not match browser's expected coroutine - did you unsafely yield before this?")
        error("current coroutine does not match browser's expected coroutine - aborting the parse")
    end

    local result = table.pack(coroutine.yield(...))
    if is_browser and co ~= state.co then
        msg.verbose("browser no longer waiting for list - aborting parse for", self.directory)
        error(ABORT_ERROR)
    end
    return unpack(result, 1, result.n)
end

--checks if the current coroutine is the one handling the browser's request
function parse_state_API:is_coroutine_current()
    return coroutine.running() == state.co
end



--------------------------------------------------------------------------------------------------------
-----------------------------------------Setup Functions------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

local API_MAJOR, API_MINOR, API_PATCH = API_VERSION:match("(%d+)%.(%d+)%.(%d+)")

--checks if the given parser has a valid version number
local function check_api_version(parser)
    local version = parser.version or "1.0.0"

    local major, minor = version:match("(%d+)%.(%d+)")

    if not major or not minor then
        return msg.error("Invalid version number")
    elseif major ~= API_MAJOR then
        return msg.error("parser", parser.name, "has wrong major version number, expected", ("v%d.x.x"):format(API_MAJOR), "got", 'v'..version)
    elseif minor > API_MINOR then
        msg.warn("parser", parser.name, "has newer minor version number than API, expected", ("v%d.%d.x"):format(API_MAJOR, API_MINOR), "got", 'v'..version)
    end
    return true
end

--create a unique id for the given parser
local function set_parser_id(parser)
    local name = parser.name
    if parsers[name] then
        local n = 2
        name = parser.name.."_"..n
        while parsers[name] do
            n = n + 1
            name = parser.name.."_"..n
        end
    end

    parsers[name] = parser
    parsers[parser] = { id = name }
end

--loads an addon in a separate environment
local function load_addon(path)
    local name_sqbr = string.format("[%s]", path:match("/([^/]*)%.lua$"))
    local addon_environment = API.redirect_table(_G)
    addon_environment._G = addon_environment

    --gives each addon custom debug messages
    addon_environment.package = API.redirect_table(addon_environment.package)
    addon_environment.package.loaded = API.redirect_table(addon_environment.package.loaded)
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
    addon_environment.print = msg_module.info

    addon_environment.require = function(module)
        if module == "mp.msg" then return msg_module end
        return require(module)
    end

    local chunk, err
    if setfenv then
        --since I stupidly named a function loadfile I need to specify the global one
        --I've been using the name too long to want to change it now
        chunk, err = _G.loadfile(path)
        if not chunk then return msg.error(err) end
        setfenv(chunk, addon_environment)
    else
        chunk, err = _G.loadfile(path, "bt", addon_environment)
        if not chunk then return msg.error(err) end
    end

    local success, result = xpcall(chunk, API.traceback)
    return success and result or nil
end

--setup an internal or external parser
local function setup_parser(parser, file)
    parser = setmetatable(parser, { __index = parser_API })
    parser.name = parser.name or file:gsub("%-browser%.lua$", ""):gsub("%.lua$", "")

    set_parser_id(parser)
    if not check_api_version(parser) then return msg.error("aborting load of parser", parser:get_id(), "from", file) end

    msg.verbose("imported parser", parser:get_id(), "from", file)

    --sets missing functions
    if not parser.can_parse then
        if parser.parse then parser.can_parse = function() return true end
        else parser.can_parse = function() return false end end
    end

    if parser.priority == nil then parser.priority = 0 end
    if type(parser.priority) ~= "number" then return msg.error("parser", parser:get_id(), "needs a numeric priority") end

    --the root parser has special behaviour, so it should not be in the list of parsers
    if parser == root_parser then return end
    table.insert(parsers, parser)
end

--load an external addon
local function setup_addon(file, path)
    if file:sub(-4) ~= ".lua" then return msg.verbose(path, "is not a lua file - aborting addon setup") end

    local addon_parsers = load_addon(path)
    if not addon_parsers or type(addon_parsers) ~= "table" then return msg.error("addon", path, "did not return a table") end

    --if the table contains a priority key then we assume it isn't an array of parsers
    if not addon_parsers[1] then addon_parsers = {addon_parsers} end

    for _, parser in ipairs(addon_parsers) do
        setup_parser(parser, file)
    end
end

--loading external addons
local function setup_addons()
    local addon_dir = mp.command_native({"expand-path", o.addon_directory..'/'})
    local files = utils.readdir(addon_dir)
    if not files then error("could not read addon directory") end

    for _, file in ipairs(files) do
        setup_addon(file, addon_dir..file)
    end
    table.sort(parsers, function(a, b) return a.priority < b.priority end)

    --we want to store the indexes of the parsers
    for i = #parsers, 1, -1 do parsers[ parsers[i] ].index = i end

    --we want to run the setup functions for each addon
    for index, parser in ipairs(parsers) do
        if parser.setup then
            local success = xpcall(function() parser:setup() end, API.traceback)
            if not success then
                msg.error("parser", parser:get_id(), "threw an error in the setup method - removing from list of parsers")
                table.remove(parsers, index)
            end
        end
    end
end

--sets up the compatible extensions list
local function setup_extensions_list()
    --setting up subtitle extensions
    for ext in API.iterate_opt(o.subtitle_extensions:lower()) do
        sub_extensions[ext] = true
        extensions[ext] = true
    end

    --setting up audio extensions
    for ext in API.iterate_opt(o.audio_extensions:lower()) do
        audio_extensions[ext] = true
        extensions[ext] = true
    end

    --adding file extensions to the set
    for _, ext in ipairs(compatible_file_extensions) do
        extensions[ext] = true
    end

    --adding extra extensions on the whitelist
    for str in API.iterate_opt(o.extension_whitelist:lower()) do
        extensions[str] = true
    end

    --removing extensions that are in the blacklist
    for str in API.iterate_opt(o.extension_blacklist:lower()) do
        extensions[str] = nil
    end
end

--splits the string into a table on the semicolons
local function setup_root()
    root = {}
    for str in API.iterate_opt(o.root) do
        local path = mp.command_native({'expand-path', str})
        path = API.fix_path(path, true)

        local temp = {name = path, type = 'dir', label = str, ass = API.ass_escape(str, true)}

        root[#root+1] = temp
    end
end

setup_root()

setup_parser(file_parser, "file-browser.lua")
setup_parser(root_parser, 'file-browser.lua')
if o.addons then
    --all of the API functions need to be defined before this point for the addons to be able to access them safely
    setup_addons()
end

--these need to be below the addon setup in case any parsers add custom entries
setup_extensions_list()
setup_keybinds()



------------------------------------------------------------------------------------------
------------------------------Other Script Compatability----------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

local function scan_directory_json(directory, response_str)
    if not directory then msg.error("did not receive a directory string"); return end
    if not response_str then msg.error("did not receive a response string"); return end

    directory = mp.command_native({"expand-path", directory}, "")
    if directory ~= "" then directory = API.fix_path(directory, true) end
    msg.verbose(("recieved %q from 'get-directory-contents' script message - returning result to %q"):format(directory, response_str))

    local list, opts = parse_directory(directory, { source = "script-message" } )
    opts.API_VERSION = API_VERSION

    local err
    list, err = API.format_json_safe(list)
    if not list then msg.error(err) end

    opts, err = API.format_json_safe(opts)
    if not opts then msg.error(err) end

    mp.commandv("script-message", response_str, list or "", opts or "")
end

if input then
    mp.add_key_binding("Alt+o", "browse-directory/get-user-input", function()
        input.get_user_input(browse_directory, {request_text = "open directory:"})
    end)
end



------------------------------------------------------------------------------------------
----------------------------------Script Messages-----------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

--a helper script message for custom keybinds
--substitutes any '=>' arguments for 'script-message'
--makes chaining script-messages much easier
mp.register_script_message('=>', function(...)
    local command = table.pack('script-message', ...)
    for i, v in ipairs(command) do
        if v == '=>' then command[i] = 'script-message' end
    end
    mp.commandv(table.unpack(command))
end)

--a helper script message for custom keybinds
--sends a command after the specified delay
mp.register_script_message('delay-command', function(delay, ...)
    local command = table.pack(...)
    local success, err = pcall(mp.add_timeout, API.evaluate_string('return '..delay), function() mp.commandv(table.unpack(command)) end)
    if not success then return msg.error(err) end
end)

--a helper script message for custom keybinds
--sends a command only if the given expression returns true
mp.register_script_message('conditional-command', function(condition, ...)
    local command = table.pack(...)
    API.coroutine.run(function()
        if API.evaluate_string('return '..condition) == true then mp.commandv(table.unpack(command)) end
    end)
end)

--a helper script message for custom keybinds
--extracts lua expressions from the command and evaluates them
--expressions must be surrounded by !{}. Another ! before the { will escape the evaluation
mp.register_script_message('evaluate-expressions', function(...)
    local args = table.pack(...)
    API.coroutine.run(function()
        for i, arg in ipairs(args) do
            args[i] = arg:gsub('(!+)(%b{})', function(lead, expression)
                if #lead % 2 == 0 then return string.rep('!', #lead/2)..expression end

                local eval = API.evaluate_string('return '..expression:sub(2, -2))
                return type(eval) == "table" and utils.to_string(eval) or tostring(eval)
            end)
        end

        mp.commandv(table.unpack(args))
    end)
end)

--a helper function for custom-keybinds
--concatenates the command arguments with newlines and runs the
--string as a statement of code
mp.register_script_message('run-statement', function(...)
    local statement = table.concat(table.pack(...), '\n')
    API.coroutine.run(API.evaluate_string, statement)
end)

--allows keybinds/other scripts to auto-open specific directories
mp.register_script_message('browse-directory', browse_directory)

--allows other scripts to request directory contents from file-browser
mp.register_script_message("get-directory-contents", function(directory, response_str)
    API.coroutine.run(scan_directory_json, directory, response_str)
end)



------------------------------------------------------------------------------------------
--------------------------------mpv API Callbacks-----------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

--we don't want to add any overhead when the browser isn't open
mp.observe_property('path', 'string', function(_,path)
    if not state.hidden then 
        update_current_directory(_,path)
        update_ass()
    else state.flag_update = true end
end)

--updates the dvd_device
mp.observe_property('dvd-device', 'string', function(_, device)
    if not device or device == "" then device = "/dev/dvd/" end
    dvd_device = API.fix_path(device, true)
end)

--declares the keybind to open the browser
mp.add_key_binding('MENU','browse-files', toggle)
mp.add_key_binding('Ctrl+o','open-browser', open)

