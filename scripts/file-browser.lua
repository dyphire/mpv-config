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

    --characters to use as seperators
    root_seperators = ",;",

    --number of entries to show on the screen at once
    num_entries = 20,

    --only show files compatible with mpv
    filter_files = true,

    --enable custom keybinds
    custom_keybinds = false,

    --blacklist compatible files, it's recommended to use this rather than to edit the
    --compatible list directly. A semicolon separated list of extensions without spaces
    extension_blacklist = "",

    --add extra file extensions
    extension_whitelist = "",

    --compatible list directly. A semicolon separated list of audio extensions without spaces
    audio_extension_blacklist = "",

    --add extra audio file extensions
    audio_extension_whitelist = "",

    --add extra sub file extensions
    sub_extension_whitelist = "",

    --filter dot directories like .config
    --most useful on linux systems
    filter_dot_dirs = false,
    filter_dot_files = false,

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

    --force file-browser to use a specific text alignment (default: top-left)
    --uses ass tag alignment numbers: https://aegi.vmoe.info/docs/3.0/ASS_Tags/#index23h3
    --set to 0 to use the default mpv osd-align options
    alignment = 7,

    --style settings
    font_bold_header = true,

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

--the osd_overlay API was not added until v0.31. The expand-path command was not added until 0.30
local ass = mp.create_osd_overlay("ass-events")
if not ass then return msg.error("Script requires minimum mpv version 0.31") end

package.path = mp.command_native({"expand-path", o.module_directory}).."/?.lua;"..package.path

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
    folder = ([[{\fn%s}]]):format(o.font_name_folder)
}

local state = {
    list = {},
    selected = 1,
    hidden = true,
    wrap = true,
    flag_update = false,
    keybinds = nil,

    parser = nil,
    directory = nil,
    directory_label = nil,
    prev_directory = "",

    multiselect_start = nil,
    initial_selection = {},
    selection = {}
}

local parsers = {}
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
    "264","265","3g2","3ga","3ga2","3gp","3gp2","3gpp","3iv","a52","aac","adt","adts","ahn","aif","aifc","aiff","amr","amv","ape","asf","au","avc","avi","awb","ay",
    "bdmv","bmp","cue","divx","dts","dtshd","dts-hd","dv","dvr","dvr-ms","eac3","evo","evob","f4a","flac","flc","fli","flic","flv","gbs","gif","gxf","gym",
    "h264","h265","hdmov","hdv","hes","hevc","ifo","iso","jpeg","jpg","kss","lpcm","m1a","m1v","m2a","m2t","m2ts","m2v","m3u","m3u8","m4a","m4v","mk3d","mka","mkv",
    "mlp","mod","mov","mp1","mp2","mp2v","mp3","mp4","mp4v","mp4v","mpa","mpe","mpeg","mpeg2","mpeg4","mpg","mpg4","mpv","mpv2","mts","mtv","mxf","nsf",
    "nsfe","nsv","nut","oga","ogg","ogm","ogv","ogx","opus","pcm","pls","png","qt","ra","ram","rm","rmvb","sap","snd","spc","spx","svg","thd","thd+ac3",
    "tif","tiff","tod","trp","truehd","true-hd","ts","tsa","tsv","tta","tts","vfw","vgm","vgz","vob","vro","wav","weba","webm","webp","wm","wma","wmv","wtv",
    "wv","x264","x265","xvid","y4m","yuv"
}

--creating a set of subtitle extensions for custom subtitle loading behaviour
local subtitle_extensions = {
    "etf","etf8","utf-8","idx","sub","srt","rt","ssa","ass","mks","vtt","sup","scc","smi","lrc","pgs"
}

--creating a set of audio extensions for custom audio loading behaviour
local audio_extension_list = {
    "mka","flac","dts","dtshd","dts-hd","truehd","true-hd"
}

--------------------------------------------------------------------------------------------------------
--------------------------------------Cache Implementation----------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--metatable of methods to manage the cache
local __cache = {}

__cache.cached_values = {
    "directory", "directory_label", "list", "selected", "selection", "parser", "empty_text"
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
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--get the full path for the current file
local function get_full_path(item, dir)
    if item.path then return item.path end
    return (dir or state.directory)..item.name
end

local function concatenate_path(item, directory)
    if directory == "" then return item.name end
    if directory:sub(-1) == "/" then return directory..item.name end
    return directory.."/"..item.name
end

--returns the file extension of the given file
local function get_extension(filename, def)
    return filename:lower():match("%.([^%./]+)$") or def
end

--returns the protocol scheme of the given url, or nil if there is none
local function get_protocol(filename, def)
    return filename:lower():match("^(%a%w*)://") or def
end

--formats strings for ass handling
--this function is based on a similar function from https://github.com/mpv-player/mpv/blob/master/player/lua/console.lua#L110
local function ass_escape(str, replace_newline)
    if replace_newline == true then replace_newline = "\\\239\187\191n" end

    --escape the invalid single characters
    str = str:gsub('[\\{}\n]', {
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
local function pattern_escape(str)
    return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-])", "%%%1")
end

--standardises filepaths across systems
local function fix_path(str, is_directory)
    str = str:gsub([[\]],[[/]])
    str = str:gsub([[/./]], [[/]])
    if is_directory and str:sub(-1) ~= '/' then str = str..'/' end
    return str
end

--wrapper for utils.join_path to handle protocols
local function join_path(working, relative)
    return get_protocol(relative) and relative or utils.join_path(working, relative)
end

--sorts the table lexicographically ignoring case and accounting for leading/non-leading zeroes
--the number format functionality was proposed by github user twophyro, and was presumably taken
--from here: http://notebook.kulchenko.com/algorithms/alphanumeric-natural-sorting-for-humans-in-lua
local function sort(t)
    local function padnum(d)
        local r = string.match(d, "0*(.+)")
        return ("%03d%s"):format(#r, r)
    end

    --appends the letter d or f to the start of the comparison to sort directories and folders as well
    table.sort(t, function(a,b) return a.type:sub(1,1)..(a.label or a.name):lower():gsub("%d+",padnum) < b.type:sub(1,1)..(b.label or b.name):lower():gsub("%d+",padnum) end)
    return t
end

local function valid_dir(dir)
    if o.filter_dot_dirs and dir:sub(1,1) == "." then return false end
    return true
end

local function valid_file(file)
    if o.filter_dot_files and (file:sub(1,1) == ".") then return false end
    if o.filter_files and not extensions[ get_extension(file, "") ] then return false end
    return true
end

--removes items and folders from the list
--this is for addons which can't filter things during their normal processing
local function filter(t)
    local max = #t
    local top = 1
    for i = 1, max do
        local temp = t[i]
        t[i] = nil

        if  ( temp.type == "dir" and valid_dir(temp.label or temp.name) ) or
            ( temp.type == "file" and valid_file(temp.label or temp.name) )
        then
            t[top] = temp
            top = top+1
        end
    end
    return t
end

--sorts a table into an array of selected items in the correct order
--if a predicate function is passed, then the item will only be added to
--the table if the function returns true
local function sort_keys(t, include_item)
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

--copies a table without leaving any references to the original
--uses a structured clone algorithm to maintain cyclic references
local function copy_table_recursive(t, references)
    if not t then return nil end
    local copy = {}
    references[t] = copy

    for key, value in pairs(t) do
        if type(value) == "table" then
            if references[value] then copy[key] = references[value]
            else copy[key] = copy_table_recursive(value, references) end
        else
            copy[key] = value end
    end
    return copy
end

--a wrapper around copy_table to provide the reference table
local function copy_table(t)
    --this is to handle cyclic table references
    return copy_table_recursive(t, {})
end



--------------------------------------------------------------------------------------------------------
------------------------------------Parser Object Implementation----------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------


--setting up functions to provide to addons
local parser_index = {}
local parser_ids = {}

--setting up the modules and metatables
local API_mt = {}
local parser_mt = {}
package.loaded["file-browser"] = API_mt
setmetatable(parser_mt, {__index = API_mt})
parser_mt.__index = parser_mt

--create a unique id for the given parser
local existing_ids = {}
local function set_parser_id(parser)
    if not existing_ids[parser.name] then
        existing_ids[parser.name] = true
        parser_ids[parser] = parser.name
        return
    end

    local n = 2
    while existing_ids[parser.name..n] do n = n + 1 end
    existing_ids[parser.name..n] = true
    parser_ids[parser] = parser.name..n
end

API_mt.valid_file = valid_file
API_mt.valid_dir = valid_dir
API_mt.filter = filter
API_mt.sort = sort
API_mt.ass_escape = ass_escape
API_mt.pattern_escape = pattern_escape
API_mt.fix_path = fix_path
API_mt.get_full_path = get_full_path
API_mt.get_extension = get_extension
API_mt.get_protocol = get_protocol
API_mt.join_path = join_path
API_mt.copy_table = copy_table

function API_mt.clear_cache() cache:clear() end

--we will set these functions once they are declared later in the script
API_mt.update_ass = nil
API_mt.scan_directory = nil
API_mt.rescan_directory = nil
API_mt.browse_directory = nil

--providing getter and setter functions so that addons can't modify things directly
function API_mt.get_script_opts() return copy_table(o) end
function API_mt.get_extensions() return copy_table(extensions) end
function API_mt.get_sub_extensions() return copy_table(sub_extensions) end
function API_mt.get_audio_extensions() return copy_table(audio_extensions) end
function API_mt.get_parseable_extensions() return copy_table(parseable_extensions) end
function API_mt.get_state() return copy_table(state) end
function API_mt.get_dvd_device() return dvd_device end
function API_mt.get_parsers() return copy_table(parsers) end
function API_mt.get_root() return copy_table(root) end
function API_mt.get_directory() return state.directory end
function API_mt.get_list() return copy_table(state.list) end
function API_mt.get_current_file() return copy_table(current_file) end
function API_mt.get_current_parser() return state.parser:get_id() end
function API_mt.get_current_parser_keyname() return state.parser.keybind_name or state.parser.name end
function API_mt.get_selected_index() return state.selected end
function API_mt.get_selected_item() return copy_table(state.list[state.selected]) end
function API_mt.get_open_status() return not state.hidden end

function API_mt.set_empty_text(str)
    state.empty_text = str
    API_mt.update_ass()
end

function API_mt.set_selected_index(index)
    if type(index) ~= "number" then return false end
    if index < 1 then index = 1 end
    if index > #state.list then index = #state.list end
    state.selected = index
    API_mt.update_ass()
    return index
end

function parser_mt:get_index() return parser_index[self] end
function parser_mt:get_id() return parser_ids[self] end

--register file extensions which can be opened by the browser
function API_mt.register_parseable_extension(ext) parseable_extensions[ext:lower()] = true end
function API_mt.remove_parseable_extension(ext) parseable_extensions[ext:lower()] = nil end

--add a compatible extension to show through the filter, only applies if run during the setup() method
function API_mt.add_default_extension(ext) table.insert(compatible_file_extensions, ext) end

--add item to root at position pos
function API_mt.insert_root_item(item, pos)
    msg.verbose("adding item to root", item.label or item.name)
    item.ass = item.ass or ass_escape(item.label or item.name)
    item.type = "dir"
    table.insert(root, pos or (#root + 1), item)
end

--parses the given directory or defers to the next parser if nil is returned
local function choose_and_parse(directory, index, state)
    msg.debug("finding parser for", directory)
    local parser, list, opts
    while list == nil and not ( opts and opts.already_deferred ) and index <= #parsers do
        parser = parsers[index]
        if parser:can_parse(directory) then
            msg.debug("attempting parser:", parser:get_id())
            list, opts = parser:parse(directory, state)
        end
        index = index + 1
    end
    if not list then return nil, {} end

    msg.debug("list returned from:", parser:get_id())
    opts = opts or {}
    if list then opts.index = opts.index or parser_index[parser] end
    return list, opts
end

--runs choose_and_parse starting from the next parser
function parser_mt:defer(directory, state)
    msg.trace("deferring to other parsers...")
    local list, opts = choose_and_parse(directory, self:get_index() + 1, state)
    opts.already_deferred = true
    return list, opts
end

--load an external addon
local function setup_addon(file, path)
    if file:sub(-4) ~= ".lua" then return msg.verbose(path, "is not a lua file - aborting addon setup") end

    local addon_parsers = dofile(path)
    if not addon_parsers then return msg.error("addon", path, "did not return a table") end

    --if the table contains a priority key then we assume it isn't an array of parsers
    if not addon_parsers[1] then addon_parsers = {addon_parsers} end

    for _, parser in ipairs(addon_parsers) do
        parser = setmetatable(parser, parser_mt)
        parser.name = parser.name or file:gsub("%-browser%.lua$", ""):gsub("%.lua$", "")
        set_parser_id(parser)

        msg.verbose("imported parser", parser:get_id(), "from", file)

        --sets missing functions
        if not parser.can_parse then
            if parser.parse then parser.can_parse = function() return true end
            else parser.can_parse = function() return false end end
        end

        if parser.priority == nil then parser.priority = 0 end
        if type(parser.priority) ~= "number" then return msg.error("parser", parser:get_id(), "needs a numeric priority") end

        table.insert(parsers, parser)
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
    for i = #parsers, 1, -1 do parser_index[ parsers[i] ] = i end
end

--parser object for the root
--this object is not added to the parsers table so that scripts cannot get access to
--the root table, which is returned directly by parse()
local root_parser = {
    name = "root",

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
        return sort(new_list), {filtered = true, sorted = true}
    end
}

parsers[1] = setmetatable(file_parser, parser_mt)
setmetatable(root_parser, parser_mt)
set_parser_id(file_parser)
set_parser_id(root_parser)



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
    if v.type == "dir" or parseable_extensions[get_extension(v.name, "")] then
        return current_file.directory:find(get_full_path(v), 1, true)
    else
        return current_file.path == get_full_path(v)
    end
end

--saves the directory and name of the currently playing file
local function update_current_directory(_, filepath)
    --if we're in idle mode then we want to open the working directory
    if filepath == nil then 
        current_file.directory = fix_path( mp.get_property("working-directory", ""), true)
        current_file.name = nil
        current_file.path = nil
        return
    elseif filepath:find("dvd://") == 1 then
        filepath = dvd_device..filepath:match("dvd://(.*)")
    end

    local workingDirectory = mp.get_property('working-directory', '')
    local exact_path = join_path(workingDirectory, filepath)
    exact_path = fix_path(exact_path, false)
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
    append(ass_escape(dir_name, style.cursor.."\\\239\187\191n"..style.header))
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
        if i == state.selected then
            append(style.cursor)
            append((state.multiselect_start and style.multiselect or "")..o.cursor_icon)
            append("\\h"..style.body)
        else
            append(o.indent_icon.."\\h"..style.body)
        end

        --sets the selection colour scheme
        local multiselected = state.selection[i]
        if multiselected then append(style.multiselect)
        elseif i == state.selected then append(style.selected) end

        --prints the currently-playing icon and style
        if playing_file and multiselected then append(style.playing_selected)
        elseif playing_file then append(style.playing) end

        --sets the folder icon
        if v.type == 'dir' then append(style.folder..o.folder_icon.."\\h"..style.body) end

        --adds the actual name of the item
        append(v.ass or ass_escape(v.label or v.name, true))
        newline()
    end

    if overflow then append('\\N'..style.footer_header..#state.list-finish..' item(s) remaining') end
    ass:update()
end
API_mt.update_ass = update_ass



--------------------------------------------------------------------------------------------------------
--------------------------------Scroll/Select Implementation--------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--disables multiselect
local function disable_select_mode()
    state.multiselect_start = nil
    state.initial_selection = {}
end

--enables multiselect
local function enable_select_mode()
    state.multiselect_start = state.selected

    --saving a copy of the original state
    for key, value in pairs(state.selection) do
        state.initial_selection[key] = value
    end
end

--calculates what drag behaviour is required for that specific movement
local function drag_select(direction)
    local setting = state.selection[state.multiselect_start]
    local offset = state.multiselect_start - state.selected
    local below = offset < 0

    if below == (direction == 1) and offset ~= 0 then
        state.selection[state.selected] = setting
    else
        state.selection[state.selected - direction] = state.initial_selection[state.selected-direction]
    end
    update_ass()
end

--moves the selector down the list
local function scroll_down()
    if state.selected < #state.list then
        state.selected = state.selected + 1
        update_ass()
    elseif state.wrap then
        state.selected = 1
        update_ass()
    end
    if state.multiselect_start then drag_select(1) end
end

--moves the selector up the list
local function scroll_up()
    if state.selected > 1 then
        state.selected = state.selected - 1
        update_ass()
    elseif state.wrap then
        state.selected = #state.list
        update_ass()
    end
    if state.multiselect_start then drag_select(-1) end
end

--toggles the selection
local function toggle_selection()
    if state.list[state.selected] then
        state.selection[state.selected] = not state.selection[state.selected] or nil
    end
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

--scans the list for which item to select by default
--chooses the folder that the script just moved out of
--or, otherwise, the item highlighted as currently playing
local function select_prev_directory()
    if state.prev_directory:find(state.directory, 1, true) == 1 then
        local i = 1
        while (state.list[i] and (state.list[i].type == "dir" or parseable_extensions[get_extension(state.list[i].name, "")])) do
            if state.prev_directory:find(get_full_path(state.list[i]), 1, true) then
                state.selected = i
                return
            end
            i = i+1
        end
    end

    for i,item in ipairs(state.list) do
        if highlight_entry(item) then
            state.selected = i
            return
        end
    end
end

--moves through valid parsers until a one returns a list
local function scan_directory(directory, state)
    if directory == "" then return root_parser:parse() end

    msg.verbose("scanning files in", directory)
    state.co = coroutine.running()
    if not state.co then msg.error("scan_directory should be executed from within a coroutine - aborting scan") ; return end

    local list, opts = choose_and_parse(directory, 1, state)

    if list == nil then msg.debug("no successful parsers found"); return nil end
    opts.parser = parsers[opts.index]
    if not opts.filtered then filter(list) end
    if not opts.sorted then sort(list) end
    return list, opts
end

--a wrapper around scan_directory for addon API
function API_mt.scan_directory(directory, state)
    if not state then state = { source = "addon" }
    elseif not state.source then state.source = "addon" end
    return scan_directory(directory, state)
end

--sends update requests to the different parsers
local function update_list()
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

    local list, opts = scan_directory(state.directory, { source = "browser" })

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
            list[i].ass = list[i].ass or ass_escape(list[i].label or list[i].name, true)
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

    select_prev_directory()
    state.prev_directory = state.directory
end

--rescans the folder and updates the list
local function update(moving_adjacent)
    --we can only make assumptions about the directory label when moving from adjacent directories
    if not moving_adjacent then state.directory_label = nil end

    state.empty_text = "~"
    state.list = {}
    disable_select_mode()
    update_ass()
    state.empty_text = "empty directory"

    --if opening a new directory we want to clear the previous coroutine if it is still running
    --it is up to addon authors to be able to handle this forced resumption
    while (state.co and coroutine.status(state.co) ~= "dead") do
        local success, err = coroutine.resume(state.co)
        if not success then msg.error(err) end
    end
    state.co = coroutine.create(function() update_list(); update_ass() end)
    local success, err = coroutine.resume(state.co)
    if not success then msg.error(err) end
end
API_mt.rescan_directory = update

--the base function for moving to a directory
local function goto_directory(directory)
    state.directory = directory
    cache:clear()
    update()
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
    if not current or current.type ~= 'dir' and not parseable_extensions[get_extension(current.name, "")] then return end

    cache:push()
    state.directory = concatenate_path(current, state.directory)

    --we can make some assumptions about the next directory label when moving up or down
    if state.directory_label then state.directory_label = state.directory_label..(current.label or current.name) end
    update(true)
end



------------------------------------------------------------------------------------------
------------------------------------Browser Controls--------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

--opens the browser
local function open()
    for _,v in ipairs(state.keybinds) do
        mp.add_forced_key_binding(v[1], 'dynamic/'..v[2], v[3], v[4])
    end

    state.hidden = false
    if state.directory == nil then
        local path = mp.get_property('path')
        update_current_directory(nil, path)
        if path or o.default_to_working_directory then goto_current_dir() else goto_root() end
        return
    end

    if state.flag_update then update_current_directory(nil, mp.get_property('path')) end
    state.hidden = false
    if not state.flag_update then ass:update()
    else state.flag_update = false ; update_ass() end
end

--closes the list and sets the hidden flag
local function close()
    for _,v in ipairs(state.keybinds) do
        mp.remove_key_binding('dynamic/'..v[2])
    end

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

    if directory ~= "" then directory = fix_path(directory, true) end
    msg.verbose('recieved directory from script message: '..directory)

    if directory == "dvd://" then directory = dvd_device end
    goto_directory(directory)
    open()
end
API_mt.browse_directory = browse_directory



------------------------------------------------------------------------------------------
---------------------------------File/Playlist Opening------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

--recursive function to load directories using the script custom parsers
local function custom_loadlist_recursive(directory, flag)
    local list, opts = scan_directory(directory, { source = "loadlist" })
    if list == root then return end

    --if we can't parse the directory then append it and hope mpv fares better
    if list == nil then
        msg.warn("Could not parse", directory, "appending to playlist anyway")
        mp.commandv("loadfile", directory, flag)
        flag = "append"
        return true
    end

    directory = opts.directory or directory
    if directory == "" then return end

    for _, item in ipairs(list) do
        if not sub_extensions[ get_extension(item.name, "") ]
        and not audio_extensions[ get_extension(item.name, "") ]
        then
            if item.type == "dir" or parseable_extensions[get_extension(item.name, "")] then
                if custom_loadlist_recursive( concatenate_path(item, directory) , flag) then flag = "append" end
            else
                local path = get_full_path(item, directory)

                msg.verbose("Appending", path, "to the playlist")
                mp.commandv("loadfile", path, flag)
                flag = "append"
            end
        end
    end
    return flag == "append"
end

--a wrapper for the custom_loadlist_recursive function to handle the flags
local function loadlist(directory, flag)
    flag = custom_loadlist_recursive(directory, flag)
    if not flag then msg.warn(directory, "contained no valid files") end
    return flag
end

--load playlist entries before and after the currently playing file
local function autoload_dir(path)
    if o.autoload_save_current and path == current_file.path then
        mp.commandv("write-watch-later-config") end

    --loads the currently selected file, clearing the playlist in the process
    mp.commandv("loadfile", path)

    local pos = 1
    local file_count = 0
    for _,item in ipairs(state.list) do
        if item.type == "file" 
        and not sub_extensions[ get_extension(item.name, "") ]
        and not audio_extensions[ get_extension(item.name, "") ]
        then
            local p = get_full_path(item)

            if p == path then pos = file_count
            else mp.commandv("loadfile", p, "append") end

            file_count = file_count + 1
        end
    end
    mp.commandv("playlist-move", 0, pos+1)
end

--runs the loadfile or loadlist command
local function loadfile(item, flag, autoload, directory)
    local path = get_full_path(item, directory)
    if item.type == "dir" or parseable_extensions[ get_extension(item.name, "") ] then
        return loadlist(path, flag) end

    if sub_extensions[ get_extension(item.name, "") ] then
        mp.commandv("sub-add", path, flag == "replace" and "cached" or "select" or "auto")
    elseif audio_extensions[ get_extension(item.name, "") ] then
        mp.commandv("audio-add", path, flag == "replace" and "auto" or "cached" or "select")
    else
        if autoload then autoload_dir(path)
        else mp.commandv('loadfile', path, flag) end
        return true
    end
end

--handles the open options as a coroutine
--once loadfile has been run we can no-longer guarantee synchronous execution - the state values may change
--therefore, we must ensure that any state values that could be used after a loadfile call are saved beforehand
local function open_file_coroutine(flag, autoload)
    if not state.list[state.selected] then return end
    if flag == 'replace' then close() end
    local directory = state.directory

    --handles multi-selection behaviour
    if next(state.selection) then
        local selection = sort_keys(state.selection)
        --reset the selection after
        state.selection = {}

        --the currently selected file will be loaded according to the flag
        --the flag variable will be switched to append once a file is loaded
        for i=1, #selection do
            if loadfile(selection[i], flag, autoload, directory) then flag = "append" end
        end

        disable_select_mode()
        update_ass()

    elseif flag == 'replace' then
        loadfile(state.list[state.selected], flag, autoload ~= o.autoload, directory)
        down_dir()
        close()
    else
        loadfile(state.list[state.selected], flag, false, directory)
    end
end

--opens the selelected file(s)
local function open_file(flag, autoload_dir)
    local co = coroutine.create(open_file_coroutine)

    local success, err = coroutine.resume(co, flag, autoload_dir)
    if not success then
        msg.error(err)
    end
end



------------------------------------------------------------------------------------------
----------------------------------Keybind Implementation----------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

state.keybinds = {
    {'ENTER', 'play', function() open_file('replace', false) end, {}},
    {'Shift+ENTER', 'play_append', function() open_file('append-play', false) end, {}},
    {'Alt+ENTER', 'play_autoload', function() open_file('replace', true) end, {}},
    {'ESC', 'close', escape, {}},
    {'RIGHT', 'down_dir', down_dir, {}},
    {'LEFT', 'up_dir', up_dir, {}},
    {'DOWN', 'scroll_down', scroll_down, {repeatable = true}},
    {'UP', 'scroll_up', scroll_up, {repeatable = true}},
    {'HOME', 'goto_current', goto_current_dir, {}},
    {'Shift+HOME', 'goto_root', goto_root, {}},
    {'Ctrl+r', 'reload', function() cache:clear(); update() end, {}},
    {'s', 'select_mode', toggle_select_mode, {}},
    {'S', 'select', toggle_selection, {}},
    {'Ctrl+a', 'select_all', select_all, {}}
}

--characters used for custom keybind codes
local CUSTOM_KEYBIND_CODES = "%fFnNpPdDrR"

--a map of key-keybinds - only saves the latest keybind if multiple have the same key code
local top_level_keys = {}

--format the item string for either single or multiple items
local function create_item_string(cmd, items, funct)
    if not items[1] then return end

    local str = funct(items[1])
    for i = 2, #items do
        str = str .. ( cmd["concat-string"] or " " ) .. funct(items[i])
    end
    return str
end

--iterates through the command table and substitutes special
--character codes for the correct strings used for custom functions
local function format_command_table(cmd, items, state)
    local copy = {}
    for i = 1, #cmd.command do
        copy[i] = {}

        for j = 1, #cmd.command[i] do
            copy[i][j] = cmd.command[i][j]:gsub("%%["..CUSTOM_KEYBIND_CODES.."]", {
                ["%%"] = "%",
                ["%f"] = create_item_string(cmd, items, function(item) return item and get_full_path(item, state.directory) or "" end),
                ["%F"] = create_item_string(cmd, items, function(item) return string.format("%q", item and get_full_path(item, state.directory) or "") end),
                ["%n"] = create_item_string(cmd, items, function(item) return item and (item.label or item.name) or "" end),
                ["%N"] = create_item_string(cmd, items, function(item) return string.format("%q", item and (item.label or item.name) or "") end),
                ["%p"] = state.directory or "",
                ["%P"] = string.format("%q", state.directory or ""),
                ["%d"] = (state.directory_label or state.directory):match("([^/]+)/?$") or "",
                ["%D"] = string.format("%q", (state.directory_label or state.directory):match("([^/]+)/$") or ""),
                ["%r"] = state.parser.keybind_name or state.parser.name or "",
                ["%R"] = string.format("%q", state.parser.keybind_name or state.parser.name or "")
            })
        end
    end
    return copy
end

--runs all of the commands in the command table
--key.command must be an array of command tables compatible with mp.command_native
--items must be an array of multiple items (when multi-type ~= concat the array will be 1 long)
local function run_custom_command(cmd, items, state)
    local custom_cmds = cmd.codes and format_command_table(cmd, items, state) or cmd.command

    for _, cmd in ipairs(custom_cmds) do
        msg.debug("running command:", utils.to_string(cmd))
        mp.command_native(cmd)
    end
end

--runs one of the custom commands
local function custom_command(cmd, state, co)
    if cmd.parser and cmd.parser ~= (state.parser.keybind_name or state.parser.name) then return false end

    --the function terminates here if we are running the command on a single item
    if not (cmd.multiselect and next(state.selection)) then
        if cmd.filter then
            if not state.list[state.selected] then return false end
            if state.list[state.selected].type ~= cmd.filter then return false end
        end

        --if the directory is empty, and this command needs to work on an item, then abort and fallback to the next command
        if cmd.codes and not state.list[state.selected] then
            if cmd.codes["%f"] or cmd.codes["%F"] or cmd.codes["%n"] or cmd.codes["%N"] then return false end
        end

        run_custom_command(cmd, { state.list[state.selected] }, state)
        return true
    end

    --runs the command on all multi-selected items
    local selection = sort_keys(state.selection, function(item) return not cmd.filter or item.type == cmd.filter end)
    if not next(selection) then return false end

    if cmd["multi-type"] == "concat" then
        run_custom_command(cmd, selection, state)

    elseif cmd["multi-type"] == "repeat" then
        for i,_ in ipairs(selection) do
            run_custom_command(cmd, {selection[i]}, state)

            if cmd.delay then
                mp.add_timeout(cmd.delay, function() coroutine.resume(co) end)
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

    --these are for the default keybinds, or from addons which use direct functions
    local addon_fn = type(keybind.command) == "function"
    local fn = addon_fn and keybind.command or custom_command

    if keybind.passthrough ~= nil then
        fn(keybind, addon_fn and copy_table(state) or state, co)
        if keybind.passthrough == true and keybind.prev_key then
            run_keybind_recursive(keybind.prev_key, state, co)
        end
    else
        if fn(keybind, state, co) == false and keybind.prev_key then
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
        selection = copy_table(state.selection),
        parser = state.parser,
    }
    local success, err = coroutine.resume(co, key, state_copy, co)
    if not success then
        msg.error("error running keybind:", utils.to_string(key))
        msg.error(err)
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
            value:gsub("%%["..CUSTOM_KEYBIND_CODES.."]", function(code) codes[code] = true end)
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
                    else keybind = copy_table(keybind) end

                    keybind.name = parser_ids[parser].."/"..(keybind.name or tostring(i))
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
-----------------------------------------Setup Functions------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--sets up the compatible extensions list
local function setup_extensions_list()
    if not o.filter_files then return end

    --adding file extensions to the set
    for i=1, #compatible_file_extensions do
        extensions[compatible_file_extensions[i]] = true
    end

    --setting up subtitle extensions
    for i = 1, #subtitle_extensions do
        extensions[subtitle_extensions[i]] = true
        sub_extensions[subtitle_extensions[i]] = true
    end

    --setting up audio extensions
    for i = 1, #audio_extension_list do
        extensions[audio_extension_list[i]] = true
        audio_extensions[audio_extension_list[i]] = true
    end

    --adding extra extensions on the whitelist
    for str in string.gmatch(o.extension_whitelist:lower(), "([^"..pattern_escape(o.root_seperators).."]+)") do
        extensions[str] = true
    end

    --removing extensions that are in the blacklist
    for str in string.gmatch(o.extension_blacklist:lower(), "([^"..pattern_escape(o.root_seperators).."]+)") do
        extensions[str] = nil
    end

    --adding extra audio extensions on the whitelist
    for str in string.gmatch(o.audio_extension_whitelist:lower(), "([^"..pattern_escape(o.root_seperators).."]+)") do
        audio_extensions[str] = true
    end

    --removing audio extensions that are in the blacklist
    for str in string.gmatch(o.audio_extension_blacklist:lower(), "([^"..pattern_escape(o.root_seperators).."]+)") do
        audio_extensions[str] = nil
    end

    --adding extra sub extensions on the whitelist
    for str in string.gmatch(o.sub_extension_whitelist:lower(), "([^"..pattern_escape(o.root_seperators).."]+)") do
        sub_extensions[str] = true
    end
end

--splits the string into a table on the semicolons
local function setup_root()
    root = {}
    for str in string.gmatch(o.root, "([^"..pattern_escape(o.root_seperators).."]+)") do
        local path = mp.command_native({'expand-path', str})
        path = fix_path(path, true)

        local temp = {name = path, type = 'dir', label = str, ass = ass_escape(str, true)}

        root[#root+1] = temp
    end
end

setup_root()
if o.addons then
    --all of the API functions need to be defined before this point for the addons to be able to access them safely
    setup_addons()

    --we want to store the index of each parser and run the setup functions
    for i = #parsers, 1, -1 do
        if parsers[i].setup then parsers[i]:setup() end
    end
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
    if directory ~= "" then directory = fix_path(directory, true) end
    msg.verbose(("recieved %q from 'get-directory-contents' script message - returning result to %q"):format(directory, response_str))

    local list, opts = scan_directory(directory, { source = "script-message" } )

    --removes invalid json types from the parser object
    if opts.parser then
        opts.parser = copy_table(opts.parser)
        for key, value in pairs(opts.parser) do
            if type(value) == "function" then
                opts.parser[key] = nil
            end
        end
    end

    local err, err2
    list, err = utils.format_json(list)
    if not list then msg.error(err) end

    opts, err2 = utils.format_json(opts)
    if not opts then msg.error(err2) end

    mp.commandv("script-message", response_str, list or "", opts or "")
end

local input = nil

if pcall(function() input = require "user-input-module" end) then
    mp.add_key_binding("Alt+o", "browse-directory/get-user-input", function()
        input.get_user_input(browse_directory, {request_text = "open directory:"})
    end)
end




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
    dvd_device = fix_path(device, true)
end)

--declares the keybind to open the browser
mp.add_key_binding('MENU','browse-files', toggle)
mp.add_key_binding('Ctrl+o','open-browser', open)

--allows keybinds/other scripts to auto-open specific directories
mp.register_script_message('browse-directory', browse_directory)

--allows other scripts to request directory contents from file-browser
mp.register_script_message("get-directory-contents", function(directory, response_str)
    local co = coroutine.create(scan_directory_json)
    local success, err = coroutine.resume(co, directory, response_str)
    if not success then msg.error(err) end
end)
