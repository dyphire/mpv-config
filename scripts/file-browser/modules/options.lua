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

    --allows custom icons be set for the folder and cursor
    --the `\h` character is a hard space to add padding between the symbol and the text
    folder_icon = [[{\p1}m 6.52 0 l 1.63 0 b 0.73 0 0.01 0.73 0.01 1.63 l 0 11.41 b 0 12.32 0.73 13.05 1.63 13.05 l 14.68 13.05 b 15.58 13.05 16.31 12.32 16.31 11.41 l 16.31 3.26 b 16.31 2.36 15.58 1.63 14.68 1.63 l 8.15 1.63{\p0}\h]],
    cursor_icon = [[{\p1}m 14.11 6.86 l 0.34 0.02 b 0.25 -0.02 0.13 -0 0.06 0.08 b -0.01 0.16 -0.02 0.28 0.04 0.36 l 3.38 5.55 l 3.38 5.55 3.67 6.15 3.81 6.79 3.79 7.45 3.61 8.08 3.39 8.5l 0.04 13.77 b -0.02 13.86 -0.01 13.98 0.06 14.06 b 0.11 14.11 0.17 14.13 0.24 14.13 b 0.27 14.13 0.31 14.13 0.34 14.11 l 14.11 7.28 b 14.2 7.24 14.25 7.16 14.25 7.07 b 14.25 6.98 14.2 6.9 14.11 6.86{\p0}\h]],

    --enable addons
    addons = false,
    addon_directory = "~~/script-modules/file-browser-addons",

    --directory to load external modules - currently just user-input-module
    module_directory = "~~/script-modules",

    --turn the OSC idle screen off and on when opening and closing the browser
    toggle_idlescreen = false,

    --Set the current open status of the browser in the `file_browser/open` field of the `user-data` property.
    --This property is only available in mpv v0.36+.
    set_user_data = true,

    --Set the current open status of the browser in the `file_browser-open` field of the `shared-script-properties` property.
    --This property is deprecated. When it is removed in mpv v0.37 file-browser will automatically ignore this option.
    set_shared_script_properties = true,

    --force file-browser to use a specific text alignment (default: top-left)
    --uses ass tag alignment numbers: https://aegi.vmoe.info/docs/3.0/ASS_Tags/#index23h3
    --set to 0 to use the default mpv osd-align options
    alignment = 7,

    --style settings
    format_string_header = '%q\\N----------------------------------------------------',
    format_string_topwrapper = '%< item(s) above\\N',
    format_string_bottomwrapper = '\\N%> item(s) remaining',

    font_bold_header = true,
    font_opacity_selection_marker = "99",

    scaling_factor_base = 1,
    scaling_factor_header = 1.4,
    scaling_factor_wrappers = 0.64,

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

o.set_shared_script_properties = o.set_shared_script_properties and utils.shared_script_property_set

return o
