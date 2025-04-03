local utils = require 'mp.utils'
local opt = require 'mp.options'

---@class options
local o = {
    --root directories
    root = "~/",

    --automatically detect windows drives and adds them to the root.
    auto_detect_windows_drives = true,

    --characters to use as separators
    root_separators = ",",

    --number of entries to show on the screen at once
    num_entries = 20,

    --number of directories to keep in the history
    history_size = 100,

    --wrap the cursor around the top and bottom of the list
    wrap = false,

    --only show files compatible with mpv
    filter_files = true,

    --recurses directories concurrently when appending items to the playlist
    concurrent_recursion = true,

    --maximum number of recursions that can run concurrently
    max_concurrency = 16,

    --enable custom keybinds
    custom_keybinds = true,
    custom_keybinds_file = "~~/script-opts/file-browser-keybinds.json",

    --blacklist compatible files, it's recommended to use this rather than to edit the
    --compatible list directly. A comma separated list of extensions without spaces
    extension_blacklist = "",

    --add extra file extensions
    extension_whitelist = "",

    --files with these extensions will be added as additional audio tracks for the current file instead of appended to the playlist
    audio_extensions = "mka,dts,dtshd,dts-hd,truehd,true-hd",

    --files with these extensions will be added as additional subtitle tracks instead of appended to the playlist
    subtitle_extensions = "etf,etf8,utf-8,idx,sub,srt,rt,ssa,ass,mks,vtt,sup,scc,smi,lrc,pgs",

    --filter dot directories like .config
    --most useful on linux systems
    ---@type 'auto'|'yes'|'no'
    filter_dot_dirs = 'auto',
    ---@type 'auto'|'yes'|'no'
    filter_dot_files = 'auto',

    --substitute forward slashes for backslashes when appending a local file to the playlist
    --potentially useful on windows systems
    substitute_backslash = false,

    --interpret backslashes `\` in paths as forward slashes `/`
    --this is useful on Windows, which natively uses backslashes.
    --As backslashes are valid filename characters in Unix systems this could
    --cause mangled paths, though such filenames are rare.
    --Use `yes` and `no` to enable/disable. `auto` tries to use the mpv `platform`
    --property (mpv v0.36+) to decide. If the property is unavailable it defaults to `yes`.
    ---@type 'auto'|'yes'|'no'
    normalise_backslash = 'auto',

    --a directory cache to improve directory reading time,
    --enable if it takes a long time to load directories.
    --may cause 'ghost' files to be shown that no-longer exist or
    --fail to show files that have recently been created.
    cache = false,

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

    --When opening the browser prefer the directory last opened by a previous mpv instance of file-browser.
    --Overrides the `default_to_working_directory` option.
    --Requires `save_last_opened_directory` to be true.
    --Uses the internal `last-opened-directory` addon.
    default_to_last_opened_directory = false,

    --Whether to save the last opened directory and the file to save this value in.
    save_last_opened_directory = false,
    last_opened_directory_file = '~~state/file_browser-last_opened_directory',

    --when moving up a directory do not stop on empty protocol schemes like `ftp://`
    --e.g. moving up from `ftp://localhost/` will move straight to the root instead of `ftp://`
    skip_protocol_schemes = true,

    --move the cursor to the currently playing item (if available) when the playing file changes
    cursor_follows_playing_item = false,

    --Replace the user's home directory with `~/` in the header.
    --Uses the internal home-label addon.
    home_label = true,

    --map optical device paths to their respective file paths,
    --e.g. mapping bd:// to the value of the bluray-device property
    map_bd_device = true,
    map_dvd_device = true,
    map_cdda_device = true,

    --allows custom icons be set for the folder and cursor
    --the `\h` character is a hard space to add padding between the symbol and the text
    folder_icon = [[{\p1}m 6.52 0 l 1.63 0 b 0.73 0 0.01 0.73 0.01 1.63 l 0 11.41 b 0 12.32 0.73 13.05 1.63 13.05 l 14.68 13.05 b 15.58 13.05 16.31 12.32 16.31 11.41 l 16.31 3.26 b 16.31 2.36 15.58 1.63 14.68 1.63 l 8.15 1.63{\p0}\h]],
    cursor_icon = [[{\p1}m 14.11 6.86 l 0.34 0.02 b 0.25 -0.02 0.13 -0 0.06 0.08 b -0.01 0.16 -0.02 0.28 0.04 0.36 l 3.38 5.55 l 3.38 5.55 3.67 6.15 3.81 6.79 3.79 7.45 3.61 8.08 3.39 8.5l 0.04 13.77 b -0.02 13.86 -0.01 13.98 0.06 14.06 b 0.11 14.11 0.17 14.13 0.24 14.13 b 0.27 14.13 0.31 14.13 0.34 14.11 l 14.11 7.28 b 14.2 7.24 14.25 7.16 14.25 7.07 b 14.25 6.98 14.2 6.9 14.11 6.86{\p0}\h]],

    --enable addons
    addons = true,
    addon_directory = "~~/script-modules/file-browser-addons",

    --Enables the internal `ls` addon that parses directories using the `ls` commandline tool.
    --Allows directory parsing to run concurrently, which prevents the browser from locking up.
    --Automatically disables itself on Windows systems.
    ls_parser = true,

    --Enables the internal `windir` addon that parses directories using the `dir` command in cmd.exe.
    --Allows directory parsing to run concurrently, which prevents the browser from locking up.
    --Automatically disables itself on non-Windows systems.
    windir_parser = true,

    --directory to load external modules - currently just user-input-module
    module_directory = "~~/script-modules",

    --turn the OSC idle screen off and on when opening and closing the browser
    toggle_idlescreen = false,

    --Set the current open status of the browser in the `file_browser/open` field of the `user-data` property.
    --This property is only available in mpv v0.36+.
    set_user_data = true,

    --Set the current open status of the browser in the `file_browser-open` field of the `shared-script-properties` property.
    --This property is deprecated. When it is removed in mpv v0.37 file-browser will automatically ignore this option.
    set_shared_script_properties = false,

    --force file-browser to use a specific text alignment (default: top-left)
    --uses ass tag alignment numbers: https://aegi.vmoe.info/docs/3.0/ASS_Tags/#index23h3
    --set to 0 to use the default mpv osd-align options
    alignment = 7,

    --style settings
    format_string_header = [[{\fnMonospace}[%i/%x]%^ %q\N------------------------------------------------------------------]],
    format_string_topwrapper = '...',
    format_string_bottomwrapper = '...',

    font_bold_header = true,
    font_opacity_selection_marker = "99",

    scaling_factor_base = 1,
    scaling_factor_header = 1.4,
    scaling_factor_wrappers = 1,

    font_name_header = "",
    font_name_body = "",
    font_name_wrappers = "",
    font_name_folder = "",
    font_name_cursor = "",

    font_colour_header = "00ccff",
    font_colour_body = "ffffff",
    font_colour_wrappers = "00ccff",
    font_colour_cursor = "00ccff",
    font_colour_escape_chars = "413eff",

    font_colour_multiselect = "fcad88",
    font_colour_selected = "fce788",
    font_colour_playing = "33ff66",
    font_colour_playing_multiselected = "22b547"

}

opt.read_options(o, 'file_browser')

---@diagnostic disable-next-line deprecated
o.set_shared_script_properties = o.set_shared_script_properties and utils.shared_script_property_set

return o
