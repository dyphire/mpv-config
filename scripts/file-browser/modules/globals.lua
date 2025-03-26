--------------------------------------------------------------------------------------------------------
------------------------------------------Variable Setup------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

local mp = require 'mp'
local o = require 'modules.options'

---@class globals
local globals = {}

--sets the version for the file-browser API
globals.API_VERSION = "1.9.0"

---gets the current platform (in mpv v0.36+)
---in earlier versions it is set to `windows`, `darwin` or `other`
---@type 'windows'|'darwin'|'linux'|'android'|'freebsd'|'other'|string|nil
globals.PLATFORM = mp.get_property_native('platform')
if not globals.PLATFORM then
    local _ = {}
    if mp.get_property_native('options/vo-mmcss-profile', _) ~= _ then
        globals.PLATFORM = 'windows'
    elseif mp.get_property_native('options/macos-force-dedicated-gpu', _) ~= _ then
        globals.PLATFORM = 'darwin'
    end
    return 'other'
end

--the osd_overlay API was not added until v0.31. The expand-path command was not added until 0.30
assert(mp.create_osd_overlay, "Script requires minimum mpv version 0.33")

globals.ass = mp.create_osd_overlay("ass-events")
globals.ass.res_y = 720 / o.scaling_factor_base

local BASE_FONT_SIZE = 25

globals.style = {
    global = o.alignment == 0 and "" or ([[{\an%d}]]):format(o.alignment),

    -- full line styles
    header = ([[{\r\q2\b%s\fs%d\fn%s\c&H%s&}]]):format((o.font_bold_header and "1" or "0"), o.scaling_factor_header*BASE_FONT_SIZE, o.font_name_header, o.font_colour_header),
    body = ([[{\r\q2\fs%d\fn%s\c&H%s&}]]):format(BASE_FONT_SIZE, o.font_name_body, o.font_colour_body),
    footer_header = ([[{\r\q2\fs%d\fn%s\c&H%s&}]]):format(o.scaling_factor_wrappers*BASE_FONT_SIZE, o.font_name_wrappers, o.font_colour_wrappers),

    --small section styles (for colours)
    multiselect = ([[{\c&H%s&}]]):format(o.font_colour_multiselect),
    selected = ([[{\c&H%s&}]]):format(o.font_colour_selected),
    playing = ([[{\c&H%s&}]]):format(o.font_colour_playing),
    playing_selected = ([[{\c&H%s&}]]):format(o.font_colour_playing_multiselected),
    warning = ([[{\c&H%s&}]]):format(o.font_colour_escape_chars),

    --icon styles
    indent = ([[{\alpha&H%s}]]):format('ff'),
    cursor = ([[{\fn%s\c&H%s&}]]):format(o.font_name_cursor, o.font_colour_cursor),
    cursor_select = ([[{\fn%s\c&H%s&}]]):format(o.font_name_cursor, o.font_colour_multiselect),
    cursor_deselect = ([[{\fn%s\c&H%s&}]]):format(o.font_name_cursor, o.font_colour_selected),
    folder = ([[{\fn%s}]]):format(o.font_name_folder),
    selection_marker = ([[{\alpha&H%s}]]):format(o.font_opacity_selection_marker),
}

---@type State
globals.state = {
    list = {},
    selected = 1,
    hidden = true,
    flag_update = false,
    keybinds = nil,

    parser = nil,
    directory = nil,
    directory_label = nil,
    prev_directory = '',
    empty_text = 'Empty Directory',
    co = nil,

    multiselect_start = nil,
    initial_selection = nil,
    selection = {}
}

---@class ParserRef
---@field id string
---@field index number?

---@type table<number,Parser>|table<string,Parser>|table<Parser,ParserRef>>
--the parser table actually contains 3 entries for each parser
--a numeric entry which represents the priority of the parsers and has the parser object as the value
--a string entry representing the id of each parser and with the parser object as the value
--and a table entry with the parser itself as the key and a table value in the form { id = %s, index = %d }
globals.parsers = {}

--this table contains the parse_state tables for every parse operation indexed with the coroutine used for the parse
--this table has weakly referenced keys, meaning that once the coroutine for a parse is no-longer used by anything that
--field in the table will be removed by the garbage collector
---@type table<thread,ParseState>
globals.parse_states = setmetatable({}, { __mode = "k"})

---@type Set<string>
globals.extensions = {}

---@type Set<string>
globals.sub_extensions = {}

---@type Set<string>
globals.audio_extensions = {}

---@type Set<string>
globals.parseable_extensions = {}

---This table contains mappings to convert external directories to cannonical
--locations within the file-browser file tree. The keys of the table are Lua
--patterns used to evaluate external directory paths. The value is the path
--that should replace the part of the path than matched the pattern.
--These mappings should only applied at the edges where external paths are
--ingested by file-browser.
---@type table<string,string>
globals.directory_mappings = {}

---@class CurrentFile
---@field directory string?
---@field name string?
---@field path string?
---@field original_path string?
globals.current_file = {
    directory = nil,
    name = nil,
    path = nil,
    original_path = nil,
}

---@type List
globals.root = {}

---@class (strict) History
---@field list string[]
---@field size number
---@field position number
globals.history = {
    list = {},
    size = 0,
    position = 0,
}

---@class (strict) DirectoryStack
---@field stack string[]
---@field position number
globals.directory_stack = {
    stack = {},
    position = 0,
}


--default list of compatible file extensions
--adding an item to this list is a valid request on github
globals.compatible_file_extensions = {
    "264","265","3g2","3ga","3ga2","3gp","3gp2","3gpp","3iv","a52","aac","adt","adts","ahn","aif","aifc","aiff","amr","ape","asf","au","avc","avi","awb","ay",
    "bmp","cue","divx","dts","dtshd","dts-hd","dv","dvr","dvr-ms","eac3","evo","evob","f4a","flac","flc","fli","flic","flv","gbs","gif","gxf","gym",
    "h264","h265","hdmov","hdv","hes","hevc","jpeg","jpg","kss","lpcm","m1a","m1v","m2a","m2t","m2ts","m2v","m3u","m3u8","m4a","m4v","mk3d","mka","mkv",
    "mlp","mod","mov","mp1","mp2","mp2v","mp3","mp4","mp4v","mp4v","mpa","mpe","mpeg","mpeg2","mpeg4","mpg","mpg4","mpv","mpv2","mts","mtv","mxf","nsf",
    "nsfe","nsv","nut","oga","ogg","ogm","ogv","ogx","opus","pcm","pls","png","qt","ra","ram","rm","rmvb","sap","snd","spc","spx","svg","thd","thd+ac3",
    "tif","tiff","tod","trp","truehd","true-hd","ts","tsa","tsv","tta","tts","vfw","vgm","vgz","vob","vro","wav","weba","webm","webp","wm","wma","wmv","wtv",
    "wv","x264","x265","xvid","y4m","yuv"
}

---@class BrowserAbortError
globals.ABORT_ERROR = {
    msg = "browser is no longer waiting for list - aborting parse"
}

return globals
