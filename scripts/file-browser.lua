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

    --filter dot directories like .config
    --most useful on linux systems
    filter_dot_dirs = false,
    filter_dot_files = false,

    --when loading a directory from the browser use the scripts
    --parsing code to load the contents of the folder (using filters and sorting)
    --this means that files will be added to the playlist identically
    --to how they appear in the browser, rather than leaving it to mpv
    custom_dir_loading = false,

    --this option reverses the behaviour of the alt+ENTER keybind
    --when disabled the keybind is required to enable autoload for the file
    --when enabled the keybind disables autoload for the file
    autoload = false,

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

    --ass tags
    ass_header = "{\\q2\\fs35\\c&00ccff&}",
    ass_body = "{\\q2\\fs25\\c&Hffffff&}",
    ass_selected = "{\\c&Hfce788&}",
    ass_multiselect = "{\\c&Hfcad88&}",
    ass_playing = "{\\c&H33ff66&}",
    ass_playingselected = [[{\c&H22b547&}]],
    ass_footerheader = "{\\c&00ccff&\\fs16}",
    ass_cursor = "{\\c&00ccff&}"
}

package.path = mp.command_native({"expand-path", o.module_directory.."/?.lua;"})..package.path
opt.read_options(o, 'file_browser')
local ass = mp.create_osd_overlay("ass-events")

local state = {
    list = {},
    selected = 1,
    hidden = true,
    flag_update = false,
    cursor_style = o.ass_cursor,
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

local dvd_device = nil
local osd_font = ""
local current_file = {
    directory = nil,
    name = nil
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

--creating a set of subtitle extensions for custom subtitle loading behaviour
local subtitle_extensions = {
    "etf","etf8","utf-8","idx","sub","srt","rt","ssa","ass","mks","vtt","sup","scc","smi","lrc",'pgs'
}



--------------------------------------------------------------------------------------------------------
--------------------------------------Cache Implementation----------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--metatable of methods to manage the cache 
local __cache = {
    push = function(self)
        table.insert(self, {
            directory = state.directory,
            directory_label = state.directory_label,
            list = state.list,
            selected = state.selected,
            parser = state.parser,
            empty_text = state.empty_text
        })
    end,

    pop = function(self) table.remove(self) end,

    apply = function(self)
        for key, value in pairs(self[#self]) do
            state[key] = value
        end
    end,

    clear = function(self)
        for i = 1, #self do
            self[i] = nil
        end
    end
}

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

--returns the file extension of the given file
local function get_extension(filename)
    return filename:match("%.([^%./]+)$")
end

--returns the protocol scheme of the given url, or nil if there is none
local function get_protocol(filename)
    return filename:match("^(%a%w*)://")
end

--formats strings for ass handling
--this function is taken from https://github.com/mpv-player/mpv/blob/master/player/lua/console.lua#L110
local function ass_escape(str)
    str = str:gsub('\\', '\\\239\187\191')
    str = str:gsub('{', '\\{')
    str = str:gsub('}', '\\}')
    -- Precede newlines with a ZWNBSP to prevent ASS's weird collapsing of
    -- consecutive newlines
    str = str:gsub('\n', '\239\187\191\\N')
    -- Turn leading spaces into hard spaces to prevent ASS from stripping them
    str = str:gsub('\\N ', '\\N\\h')
    str = str:gsub('^ ', '\\h')
    return str
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
    if o.filter_files and not extensions[ get_extension(file) ] then return false end
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
local function copy_table(t)
    if not t then return nil end
    local copy = {}
    for key, value in pairs(t) do
        if type(value) == "table" then
            if value == t then copy[key] = copy
            else copy[key] = copy_table(value) end
        else copy[key] = value end
    end
    return copy
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

    --adding extra extensions on the whitelist
    for str in string.gmatch(o.extension_whitelist, "([^"..o.root_seperators.."]+)") do
        extensions[str] = true
    end

    --removing extensions that are in the blacklist
    for str in string.gmatch(o.extension_blacklist, "([^"..o.root_seperators.."]+)") do
        extensions[str] = nil
    end
end

--splits the string into a table on the semicolons
local function setup_root()
    root = {}
    for str in string.gmatch(o.root, "([^"..o.root_seperators.."]+)") do
        local path = mp.command_native({'expand-path', str})
        path = fix_path(path, true)

        local temp = {name = path, type = 'dir', label = str, ass = ass_escape(str)}

        root[#root+1] = temp
    end
end

setup_extensions_list()
setup_root()



--------------------------------------------------------------------------------------------------------
------------------------------------Parser Object Implementation----------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--chooses which parser to use for the specific path starting from index
local function choose_parser(path, index)
    for i = index or 1, #parsers, 1 do
        if parsers[i]:can_parse(path) then return parsers[i] end
    end
end

--setting up functions to provide to addons
local parser_index = {}
local parser_mt = {}
parser_mt.__index = parser_mt
parser_mt.valid_file = valid_file
parser_mt.valid_dir = valid_dir
parser_mt.filter = filter
parser_mt.sort = sort
parser_mt.ass_escape = ass_escape
parser_mt.fix_path = fix_path
parser_mt.get_extension = get_extension
parser_mt.get_protocol = get_protocol
parser_mt.join_path = join_path

--providing getter and setter functions so that addons can't modify things directly
function parser_mt.get_script_opts() return copy_table(o) end
function parser_mt.get_extensions() return copy_table(extensions) end
function parser_mt.get_sub_extensions() return copy_table(sub_extensions) end
function parser_mt.get_state() return copy_table(state) end
function parser_mt.get_dvd_device() return dvd_device end
function parser_mt.get_parsers() return copy_table(parsers) end
function parser_mt.get_root() return copy_table(root) end
function parser_mt.get_directory() return state.directory end
function parser_mt.get_current_file() return copy_table(current_file) end
function parser_mt.get_current_parser() return state.parser.name end
function parser_mt.get_selected_index() return state.selected end
function parser_mt.get_selected_item() return copy_table(state.list[state.selected]) end
function parser_mt.get_open_status() return not state.hidden end

function parser_mt:get_index() return parser_index[self] end

--add item to root at position pos
function parser_mt:insert_root_item(item, pos)
    msg.verbose(self.name..":", "adding item to root")
    item.ass = item.ass or ass_escape(item.label or item.name)
    item.type = "dir"
    table.insert(root, pos or (#root + 1), item)
end

--parses the given directory or defers to the next parser if nil is returned
local function choose_and_parse(directory, index)
    msg.debug("finding parser for", directory)
    local parser, list, opts
    while list == nil and not ( opts and opts.already_deferred ) and index <= #parsers do
        parser = parsers[index]
        if parser:can_parse(directory) then
            msg.trace("attempting parser:", parser.name)
            list, opts = parser:parse(directory)
        end
        index = index + 1
    end
    if not list then return nil, {} end

    msg.debug("list returned from:", parser.name)
    opts = opts or {}
    if list then opts.index = opts.index or parser_index[parser] end
    return list, opts
end

--runs choose_and_parse starting from the next parser
function parser_mt:defer(directory)
    local list, opts = choose_and_parse(directory, self:get_index() + 1)
    opts.already_deferred = true
    return list, opts
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

--loading external addons
if o.addons then
    local addon_dir = mp.command_native({"expand-path", o.addon_directory..'/'})
    local files = utils.readdir(addon_dir)
    if not files then error("could not read addon directory") end

    for _, file in ipairs(files) do
        if file:sub(-4) == ".lua" then
            local addon = dofile(addon_dir..file)
            local addon_parsers = {}

            --if the table contains a priority key then we assume it isn't an array of parsers
            if addon.priority then addon_parsers[1] = addon
            else addon_parsers = addon end

            for _, parser in ipairs(addon_parsers) do
                parser = setmetatable(parser, copy_table(parser_mt))
                parser.name = parser.name or file:gsub("%-browser%.lua$", ""):gsub("%.lua$", "")

                msg.verbose("imported parser", parser.name, "from", file)
                if type(parser.priority) ~= "number" then error("addon "..file.." needs a numeric priority") end

                table.insert(parsers, parser)
            end
        end
    end
    table.sort(parsers, function(a, b) return a.priority < b.priority end)
end

--we want to store the index of each parser and run the setup functions
for i = #parsers, 1, -1 do
    parser_index[ parsers[i] ] = i
    if parsers[i].setup then parsers[i]:setup() end
end



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
    if v.type == "dir" then
        return current_file.directory:find(get_full_path(v), 1, true)
    else
        return current_file.directory..current_file.name == get_full_path(v)
    end
end

--saves the directory and name of the currently playing file
local function update_current_directory(_, filepath)
    --if we're in idle mode then we want to open the working directory
    if filepath == nil then 
        current_file.directory = fix_path( mp.get_property("working-directory", ""), true)
        current_file.name = nil
        return
    elseif filepath:find("dvd://") == 1 then
        filepath = dvd_device..filepath:match("dvd://(.*)")
    end

    local workingDirectory = mp.get_property('working-directory', '')
    local exact_path = join_path(workingDirectory, filepath)
    exact_path = fix_path(exact_path, false)
    current_file.directory, current_file.name = utils.split_path(exact_path)
end

--refreshes the ass text using the contents of the list
local function update_ass()
    if state.hidden then state.flag_update = true ; return end

    ass.data = ""

    local dir_name = state.directory_label or state.directory
    if dir_name == "" then dir_name = "ROOT" end
    append(o.ass_header)
    append(ass_escape(dir_name)..'\\N ----------------------------------------------------')
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
    if start > 1 then append(o.ass_footerheader..(start-1)..' item(s) above\\N\\N') end

    for i=start, finish do
        local v = state.list[i]
        local playing_file = highlight_entry(v)
        append(o.ass_body)

        --handles custom styles for different entries
        if i == state.selected then append(state.cursor_style..o.cursor_icon.."\\h"..o.ass_body)
        else append(o.indent_icon.."\\h") end

        --sets the selection colour scheme
        local multiselected = state.selection[i]
        if multiselected then append(o.ass_multiselect)
        elseif i == state.selected then append(o.ass_selected) end

        --prints the currently-playing icon and style
        if playing_file and multiselected then append(o.ass_playingselected)
        elseif playing_file then append(o.ass_playing) end

        --sets the folder icon
        if v.type == 'dir' then append(o.folder_icon.."\\h") end

        --adds the actual name of the item
        --the osd font is explicitly set to counterract users
        --changing the font to support custom icons
        append("{\\fn"..osd_font.."}")
        append(v.ass or v.label or v.name)
        newline()
    end

    if overflow then append('\\N'..o.ass_footerheader..#state.list-finish..' item(s) remaining') end
    ass:update()
end



--------------------------------------------------------------------------------------------------------
--------------------------------Scroll/Select Implementation--------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--disables multiselect
local function disable_select_mode()
    state.cursor_style = o.ass_cursor
    state.multiselect_start = nil
    state.initial_selection = {}
end

--enables multiselect
local function enable_select_mode()
    state.multiselect_start = state.selected
    state.cursor_style = o.ass_multiselect

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
        while (state.list[i] and state.list[i].type == "dir") do
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
local function scan_directory(directory)
    if directory == "" then return root_parser:parse() end

    msg.verbose("scanning files in", directory)
    local list, opts = choose_and_parse(directory, 1)

    if list == nil then msg.debug("no successful parsers - using root"); return root_parser:parse() end
    opts.parser = parsers[opts.index]
    if not opts.filtered then filter(list) end
    if not opts.sorted then sort(list) end
    return list, opts
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
        update_ass()
        return
    end

    local list, opts = scan_directory(state.directory)
    state.list = list
    state.parser = opts.parser

    --this only matters when displaying the list on the screen, so it doesn't need to be in the scan function
    if not opts.escaped then
        for i = 1, #list do
            list[i].ass = list[i].ass or ass_escape(list[i].label or list[i].name)
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
    update_ass()
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
    update_list()
end

--loads the root list
local function goto_root()
    msg.verbose('loading root')
    state.directory = ""
    update()
end

--switches to the directory of the currently playing file
local function goto_current_dir()
    state.directory = current_file.directory
    cache:clear()
    state.selected = 1
    update()
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
    if not current or current.type ~= 'dir' then return end

    cache:push()
    state.directory = state.directory..current.name

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



------------------------------------------------------------------------------------------
---------------------------------File/Playlist Opening------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

--recursive function to load directories using the script custom parsers
local function custom_loadlist_recursive(directory, flag)
    local list, opts = scan_directory(directory)
    if not list or list == root then return end
    directory = opts.directory or directory
    if directory == "" then return end

    for _, item in ipairs(list) do
        if not sub_extensions[ get_extension(item.name) ] then
            local path = get_full_path(item, directory)
            if item.type == "dir" then
                if custom_loadlist_recursive(path, flag) then flag = "append" end
            else
                mp.commandv("loadfile", path, flag)
                flag = "append"
            end
        end
    end
    return flag == "append"
end

--a wrapper for the custom_loadlist_recursive function to handle the flags
local function custom_loadlist(directory, flag)
    flag = custom_loadlist_recursive(directory, flag)
    if not flag then msg.warn(directory, "contained no valid files") end
    return flag
end

--loads lists or defers the command to add-ons
local function loadlist(path, flag)
    local parser = choose_parser(path)
    if not o.custom_dir_loading and parser == file_parser then
        mp.commandv('loadlist', path, flag == "append-play" and "append" or flag)
        if flag == "append-play" and mp.get_property_bool("core-idle") then mp.commandv("playlist-play-index", 0) end
        return true
    else
        return custom_loadlist(path, flag)
    end
end

--load playlist entries before and after the currently playing file
local function autoload_dir(path)
    local pos = 1
    local file_count = 0
    for _,item in ipairs(state.list) do
        if item.type == "file" and not sub_extensions[ get_extension(item.name) ] then
            local p = get_full_path(item)
            if p == path then pos = file_count
            else mp.commandv("loadfile", p, "append") end
            file_count = file_count + 1
        end
    end
    mp.commandv("playlist-move", 0, pos+1)
end

--runs the loadfile or loadlist command
local function loadfile(item, flag, autoload)
    local path = get_full_path(item)
    if item.type == "dir" then return loadlist(path, flag) end

    if sub_extensions[ get_extension(item.name) ] then
        mp.commandv("sub-add", path, flag == "replace" and "select" or "auto")
    else
        mp.commandv('loadfile', path, flag)
        if autoload then autoload_dir(path) end
        return true
    end
end

--opens the selelected file(s)
local function open_file(flag, autoload)
    if not state.list[state.selected] then return end
    if flag == 'replace' then close() end

    --handles multi-selection behaviour
    if next(state.selection) then
        local selection = sort_keys(state.selection)

        --the currently selected file will be loaded according to the flag
        --the flag variable will be switched to append once a file is loaded
        for i=1, #selection do
            if loadfile(selection[i], flag) then flag = "append" end
        end

        --reset the selection after
        state.selection = {}
        disable_select_mode()
        update_ass()

    elseif flag == 'replace' then
        loadfile(state.list[state.selected], flag, autoload ~= o.autoload)
        down_dir()
        close()
    else
        loadfile(state.list[state.selected], flag)
    end
end



------------------------------------------------------------------------------------------
----------------------------------Keybind Implementation----------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

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
local function format_command_table(t, cmd, items)
    local copy = {}
    for i = 1, #t do
        copy[i] = t[i]:gsub("%%.", {
            ["%%"] = "%",
            ["%f"] = create_item_string(cmd, items, function(item) return item and get_full_path(item, cmd.directory) or "" end),
            ["%F"] = create_item_string(cmd, items, function(item) return string.format("%q", item and get_full_path(item, cmd.directory) or "") end),
            ["%n"] = create_item_string(cmd, items, function(item) return item and (item.label or item.name) or "" end),
            ["%N"] = create_item_string(cmd, items, function(item) return string.format("%q", item and (item.label or item.name) or "") end),
            ["%p"] = cmd.directory or "",
            ["%P"] = string.format("%q", cmd.directory or ""),
            ["%d"] = (cmd.directory_label or cmd.directory):match("([^/]+)/?$") or "",
            ["%D"] = string.format("%q", (cmd.directory_label or cmd.directory):match("([^/]+)/$") or ""),
            ["%r"] = state.parser.name or "",
            ["%R"] = string.format("%q", state.parser.name or "")
        })
    end
    return copy
end

--runs all of the commands in the command table
--recurses to handle nested tables of commands
--items must be an array of multiple items (when multi-type ~= concat the array will be 1 long)
local function run_custom_command(t, cmd, items)
    if type(t[1]) == "table" then
        for i = 1, #t do
            run_custom_command(t[i], cmd, items)
        end
    else
        local custom_cmd = cmd.contains_codes and format_command_table(t, cmd, items) or cmd.command
        msg.debug("running command: " .. utils.to_string(custom_cmd))
        mp.command_native(custom_cmd)
    end
end

--runs commands for multiple selected items
--this is if the repeat muti-type is used
local function recursive_multi_command(cmd, i, length)
    if i > length then return end

    --filtering commands
    if cmd.filter and cmd.selection[i].type ~= cmd.filter then
        msg.verbose("skipping command for selection ")
    else
        run_custom_command(cmd.command, cmd, { cmd.selection[i] })
    end

    --delay running the next command if the delay option is set
    if not cmd.delay then return recursive_multi_command(cmd, i+1, length)
    else mp.add_timeout(cmd.delay, function() recursive_multi_command(cmd, i+1, length) end) end
end

--runs one of the custom commands
local function custom_command(cmd)
    if cmd.parser and cmd.parser ~= state.parser.name then return false end

    --saving these values in-case the directory is changes while commands are being passed
    cmd.directory = state.directory
    cmd.directory_label = state.directory_label

    --runs the command on all multi-selected items
    if cmd.multiselect and next(state.selection) then
        cmd.selection = sort_keys(state.selection, function(item) return not cmd.filter or item.type == cmd.filter end)
        if not next(cmd.selection) then return false end

        if not cmd["multi-type"] or cmd["multi-type"] == "repeat" then
            recursive_multi_command(cmd, 1, #cmd.selection)
        elseif cmd["multi-type"] == "concat" then
            run_custom_command(cmd.command, cmd, cmd.selection)
        end
    else
        --filtering commands
        if cmd.filter and state.list[state.selected] and state.list[state.selected].type ~= cmd.filter then return false end
        run_custom_command(cmd.command, cmd, { state.list[state.selected] })
    end
end

--dynamic keybinds to set while the browser is open
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

--loading the custom keybinds
if o.custom_keybinds then
    local path = mp.command_native({"expand-path", "~~/script-opts"}).."/file-browser-keybinds.json"
    local custom_keybinds, err = assert(io.open( path ))
    if custom_keybinds then
        local json = custom_keybinds:read("*a")
        custom_keybinds:close()

        json = utils.parse_json(json)
        if not json then error("invalid json syntax for "..path) end

        local function contains_codes(command_table)
            for _, value in pairs(command_table) do
                local type = type(value)
                if type == "table" then
                    if contains_codes(value) then return true end
                elseif type == "string" then
                    if value:find("%%[fFnNpPdDrR]") then return true end
                end
            end
        end

        local latest_key = {}
        for _, keybind in ipairs(state.keybinds) do latest_key[keybind[1]] = keybind[3] end

        for i, keybind in ipairs(json) do
            keybind.contains_codes = contains_codes(keybind.command)

            --this creates a linked list of functions that call the previous if the various filters weren't met
            --multiselect commands with the same key are all run, it's up to the user to choose filters that don't overlap
            local prev_key = latest_key[keybind.key]
            local fn = function()
                if keybind.passthrough == false then
                    custom_command(keybind)
                elseif keybind.passthrough == true then
                    custom_command(keybind)
                    if prev_key then prev_key() end
                elseif keybind.passthrough == nil then
                    if custom_command(keybind) == false and prev_key then prev_key() end
                else
                    custom_command(keybind)
                end
            end
            table.insert(state.keybinds, { keybind.key, "custom/"..(keybind.name or tostring(i)), fn, {} })
            latest_key[keybind.key] = fn
        end
    end
end



------------------------------------------------------------------------------------------
--------------------------------mpv API Callbacks-----------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

--keeps track of the osd_font
mp.observe_property("osd-font", "string", function(_,font) osd_font = font end)

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

--opens a specific directory
local function browse_directory(directory)
    if not directory then return end
    directory = mp.command_native({"expand-path", directory}, "")
    if directory ~= "" then directory = fix_path(directory, true) end
    msg.verbose('recieved directory from script message: '..directory)

    if directory == "dvd://" then directory = dvd_device end
    state.directory = directory
    cache:clear()
    open()
    update()
end

--allows keybinds/other scripts to auto-open specific directories
mp.register_script_message('browse-directory', browse_directory)



------------------------------------------------------------------------------------------
----------------------------mpv-user-input Compatability----------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

local ui = nil

if pcall(function() ui = require "user-input-module" end) then
    mp.add_key_binding("Alt+o", "browse-directory/get-user-input", function()
        ui.get_user_input(browse_directory, {text = "[file-browser] open directory:"})
    end)
end
