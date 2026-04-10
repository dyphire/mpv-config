-- This script automatically loads playlist entries before and after the
-- the currently played file. It does so by scanning the directory a file is
-- located in when starting playback. It sorts the directory entries
-- alphabetically, and adds entries before and after the current file to
-- the internal playlist. (It stops if it would add an already existing
-- playlist entry at the same position - this makes it "stable".)
-- Add at most 5000 * 2 files when starting a file (before + after).

--[[
To configure this script use file autoload.conf in directory script-opts (the "script-opts"
directory must be in the mpv configuration directory, typically ~/.config/mpv/).

Option `ignore_patterns` is a comma-separated list of patterns (see lua.org/pil/20.2.html).
Additionally to the standard lua patterns, you can also escape commas with `%`,
for example, the option `bak%,x%,,another` will be resolved as patterns `bak,x,` and `another`.
But it does not mean you need to escape all lua patterns twice,
so the option `bak%%,%。mp4,` will be resolved as two patterns `bak%%` and `%.mp4`.

Example configuration would be:

disabled=no
images=no
videos=yes
audio=yes
additional_image_exts=list,of,ext
additional_video_exts=list,of,ext
additional_audio_exts=list,of,ext
ignore_hidden=yes
same_type=yes
same_series=yes
directory_mode=recursive
ignore_patterns=^~,^bak-,%.bak$

--]]

MAXENTRIES = 5000
MAXDIRSTACK = 20

local msg = require 'mp.msg'
local options = require 'mp.options'
local utils = require 'mp.utils'

o = {
    disabled = false,
    images = true,
    videos = true,
    audio = true,
    additional_image_exts = "",
    additional_video_exts = "",
    additional_audio_exts = "",
    ignore_hidden = true,
    same_type = false,
    same_series = false,
    directory_mode = "ignore",
    ignore_patterns = ""
}
options.read_options(o, nil, function(list)
    split_option_exts(list.additional_video_exts, list.additional_audio_exts, list.additional_image_exts)
    if list.videos or list.additional_video_exts or
        list.audio or list.additional_audio_exts or
        list.images or list.additional_image_exts then
        create_extensions()
    end
    if list.directory_mode then
        validate_directory_mode()
    end
end)

function Set (t)
    local set = {}
    for _, v in pairs(t) do set[v] = true end
    return set
end

function SetUnion (a,b)
    for k in pairs(b) do a[k] = true end
    return a
end

-- Returns first and last positions in string or past-to-end indices
function FindOrPastTheEnd (string, pattern, start_at)
    local pos1, pos2 = string.find(string, pattern, start_at)
    return pos1 or #string + 1,
           pos2 or #string + 1
end

function Split (list)
    local set = {}

    local item_pos = 1
    local item = ""

    while item_pos <= #list do
        local pos1, pos2 = FindOrPastTheEnd(list, "%%*,", item_pos)

        local pattern_length = pos2 - pos1
        local is_comma_escaped = pattern_length % 2

        local pos_before_escape = pos1 - 1
        local item_escape_count = pattern_length - is_comma_escaped

        item = item .. string.sub(list, item_pos, pos_before_escape + item_escape_count)

        if is_comma_escaped == 1 then
            item = item .. ","
        else
            set[item] = true
            item = ""
        end

        item_pos = pos2 + 1
    end

    set[item] = true

    -- exclude empty items
    set[""] = nil

    return set
end

EXTENSIONS_VIDEO_DEFAULT = Set {
    '3g2', '3gp', 'avi', 'flv', 'm2ts', 'm4v', 'mj2', 'mkv', 'mov',
    'mp4', 'mpeg', 'mpg', 'ogv', 'rmvb', 'webm', 'wmv', 'y4m'
}

EXTENSIONS_AUDIO_DEFAULT = Set {
    'aiff', 'ape', 'au', 'flac', 'm4a', 'mka', 'mp3', 'oga', 'ogg',
    'ogm', 'opus', 'wav', 'wma'
}

EXTENSIONS_IMAGES_DEFAULT = Set {
    'avif', 'bmp', 'gif', 'j2k', 'jp2', 'jpeg', 'jpg', 'jxl', 'png',
    'svg', 'tga', 'tif', 'tiff', 'webp'
}

function split_option_exts(video, audio, image)
    if video then o.additional_video_exts = Split(o.additional_video_exts) end
    if audio then o.additional_audio_exts = Split(o.additional_audio_exts) end
    if image then o.additional_image_exts = Split(o.additional_image_exts) end
end
split_option_exts(true, true, true)

function split_patterns()
    o.ignore_patterns = Split(o.ignore_patterns)
end
split_patterns()

function create_extensions()
    EXTENSIONS = {}
    EXTENSIONS_VIDEO = {}
    EXTENSIONS_AUDIO = {}
    EXTENSIONS_IMAGES = {}
    if o.videos then
        SetUnion(SetUnion(EXTENSIONS_VIDEO, EXTENSIONS_VIDEO_DEFAULT), o.additional_video_exts)
        SetUnion(EXTENSIONS, EXTENSIONS_VIDEO)
    end
    if o.audio then
        SetUnion(SetUnion(EXTENSIONS_AUDIO, EXTENSIONS_AUDIO_DEFAULT), o.additional_audio_exts)
        SetUnion(EXTENSIONS, EXTENSIONS_AUDIO)
    end
    if o.images then
        SetUnion(SetUnion(EXTENSIONS_IMAGES, EXTENSIONS_IMAGES_DEFAULT), o.additional_image_exts)
        SetUnion(EXTENSIONS, EXTENSIONS_IMAGES)
    end
end
create_extensions()

function validate_directory_mode()
    if o.directory_mode ~= "recursive" and o.directory_mode ~= "lazy" and o.directory_mode ~= "ignore" then
        o.directory_mode = nil
    end
end
validate_directory_mode()

function add_files(files)
    local oldcount = mp.get_property_number("playlist-count", 1)
    for i = 1, #files do
        mp.commandv("loadfile", files[i][1], "append")
        mp.commandv("playlist-move", oldcount + i - 1, files[i][2])
    end
end

function get_extension(path)
    match = string.match(path, "%.([^%.]+)$" )
    if match == nil then
        return "nomatch"
    else
        return match
    end
end

function get_filename_without_ext(filename)
    local idx = filename:match(".+()%.%w+$")
    if idx then
        filename = filename:sub(1, idx - 1)
    end
    return filename
end

function utf8_char_bytes(str, i)
    local char_byte = str:byte(i)
    if char_byte < 0xC0 then
        return 1
    elseif char_byte < 0xE0 then
        return 2
    elseif char_byte < 0xF0 then
        return 3
    elseif char_byte < 0xF8 then
        return 4
    else
        return 1
    end
end

function utf8_iter(str)
    local byte_start = 1
    return function()
        local start = byte_start
        if #str < start then return nil end
        local byte_count = utf8_char_bytes(str, start)
        byte_start = start + byte_count
        return start, str:sub(start, start + byte_count - 1)
    end
end

function utf8_to_table(str)
    local t = {}
    for _, ch in utf8_iter(str) do
        t[#t + 1] = ch
    end
    return t
end

function jaro(s1, s2)
    local match_window = math.floor(math.max(#s1, #s2) / 2.0) - 1
    local matches1 = {}
    local matches2 = {}

    local m = 0;
    local t = 0;

    for i = 0, #s1, 1 do
        local start = math.max(0, i - match_window)
        local final = math.min(i + match_window + 1, #s2)

        for k = start, final, 1 do
            if not (matches2[k] or s1[i] ~= s2[k]) then
                matches1[i] = true
                matches2[k] = true
                m = m + 1
                break
            end
        end
    end

    if m == 0 then
        return 0.0
    end

    local k = 0
    for i = 0, #s1, 1 do
        if matches1[i] then
            while not matches2[k] do
                k = k + 1
            end

            if s1[i] ~= s2[k] then
                t = t + 1
            end

            k = k + 1
        end
    end

    t = t / 2.0

    return (m / #s1 + m / #s2 + (m - t) / m) / 3.0
end

function jaro_winkler_distance(s1, s2)
    if #s1 + #s2 == 0 then
        return 0.0
    end

    if s1 == s2 then
        return 1.0
    end

    s1 = utf8_to_table(s1)
    s2 = utf8_to_table(s2)

    local d = jaro(s1, s2)
    local p = 0.1
    local l = 0;
    while (s1[l] == s2[l] and l < 4) do
        l = l + 1
    end

    return d + l * p * (1 - d)
end

function is_same_series(f1, f2)
    local f1, f2 = get_filename_without_ext(f1), get_filename_without_ext(f2)
    if f1 ~= f2 then
        -- by episode
        local sub1 = f1:gsub("^[%[%(]+.-[%]%)]+[%s%[]*", ""):match("(.-%D+)0*%d+")
        local sub2 = f2:gsub("^[%[%(]+.-[%]%)]+[%s%[]*", ""):match("(.-%D+)0*%d+")
        if sub1 and sub2 and sub1 == sub2 then
            return true
        end

        -- by similarity
        local threshold = 0.8
        local similarity = jaro_winkler_distance(f1, f2)
        if similarity > threshold then
            return true
        end
    end

    return false
end

function is_ignored(file)
    for pattern, _ in pairs(o.ignore_patterns) do
        if string.match(file, pattern) then
            return true
        end
    end
    return false
end

table.filter = function(t, iter)
    for i = #t, 1, -1 do
        if not iter(t[i]) then
            table.remove(t, i)
        end
    end
end

table.append = function(t1, t2)
    local t1_size = #t1
    for i = 1, #t2 do
        t1[t1_size + i] = t2[i]
    end
end

----- winapi start -----
-- in windows system, we can use the sorting function provided by the win32 API
-- see https://learn.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-strcmplogicalw
-- this function was taken from https://github.com/mpvnet-player/mpv.net/issues/575#issuecomment-1817413401
local winapi = {}
local is_windows = mp.get_property_native("platform") == "windows"

if is_windows then
    -- is_ffi_loaded is false usually means the mpv builds without luajit
    local is_ffi_loaded, ffi = pcall(require, "ffi")

    if is_ffi_loaded then
        winapi = {
            ffi = ffi,
            C = ffi.C,
            CP_UTF8 = 65001,
            shlwapi = ffi.load("shlwapi"),
        }

        -- ffi code from https://github.com/po5/thumbfast, Mozilla Public License Version 2.0
        ffi.cdef[[
            int __stdcall MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags, const char *lpMultiByteStr,
            int cbMultiByte, wchar_t *lpWideCharStr, int cchWideChar);
            int __stdcall StrCmpLogicalW(wchar_t *psz1, wchar_t *psz2);
        ]]

        winapi.utf8_to_wide = function(utf8_str)
            if utf8_str then
                local utf16_len = winapi.C.MultiByteToWideChar(winapi.CP_UTF8, 0, utf8_str, -1, nil, 0)

                if utf16_len > 0 then
                    local utf16_str = winapi.ffi.new("wchar_t[?]", utf16_len)

                    if winapi.C.MultiByteToWideChar(winapi.CP_UTF8, 0, utf8_str, -1, utf16_str, utf16_len) > 0 then
                        return utf16_str
                    end
                end
            end

            return ""
        end
    end
end
----- winapi end -----

function alphanumsort_windows(filenames)
    table.sort(filenames, function(a, b)
        local a_wide = winapi.utf8_to_wide(a)
        local b_wide = winapi.utf8_to_wide(b)
        return winapi.shlwapi.StrCmpLogicalW(a_wide, b_wide) == -1
    end)

    return filenames
end

-- alphanum sorting for humans in Lua
-- http://notebook.kulchenko.com/algorithms/alphanumeric-natural-sorting-for-humans-in-lua
function alphanumsort_lua(filenames)
    local function padnum(n, d)
        return #d > 0 and ("%03d%s%.12f"):format(#n, n, tonumber(d) / (10 ^ #d))
            or ("%03d%s"):format(#n, n)
    end

    local tuples = {}
    for i, f in ipairs(filenames) do
        tuples[i] = {f:lower():gsub("0*(%d+)%.?(%d*)", padnum), f}
    end
    table.sort(tuples, function(a, b)
        return a[1] == b[1] and #b[2] < #a[2] or a[1] < b[1]
    end)
    for i, tuple in ipairs(tuples) do filenames[i] = tuple[2] end
    return filenames
end

function alphanumsort(filenames)
    local is_ffi_loaded = pcall(require, "ffi")
    if is_windows and is_ffi_loaded then
        alphanumsort_windows(filenames)
    else
        alphanumsort_lua(filenames)
    end
end

local autoloaded = nil
local added_entries = {}
local autoloaded_dir = nil

function scan_dir(path, current_file, dir_mode, separator, dir_depth, total_files, extensions)
    if dir_depth == MAXDIRSTACK then
        return
    end
    msg.trace("scanning: " .. path)
    local files = utils.readdir(path, "files") or {}
    local dirs = dir_mode ~= "ignore" and utils.readdir(path, "dirs") or {}
    local prefix = path == "." and "" or path
    table.filter(files, function (v)
        -- The current file could be a hidden file, ignoring it doesn't load other
        -- files from the current directory.
        local current = prefix .. v == current_file
        if o.ignore_hidden and not current and string.match(v, "^%.") then
            return false
        end
        if not current and is_ignored(v) then
            return false
        end

        local ext = get_extension(v)
        if ext == nil then
            return false
        end
        local name = mp.get_property("filename")
        if o.same_series then
            local name = mp.get_property("filename")
            for ext, _ in pairs(extensions) do
                if name:match(ext .. "$") ~= nil and v ~= name and
                    not is_same_series(name, v)
                then
                    return false
                end
            end
        end
        return extensions[string.lower(ext)]
    end)
    table.filter(dirs, function(d)
        return not ((o.ignore_hidden and string.match(d, "^%.")))
    end)
    alphanumsort(files)
    alphanumsort(dirs)

    for i, file in ipairs(files) do
        files[i] = prefix .. file
    end

    table.append(total_files, files)
    if dir_mode == "recursive" then
        for _, dir in ipairs(dirs) do
            scan_dir(prefix .. dir .. separator, current_file, dir_mode,
                     separator, dir_depth + 1, total_files, extensions)
        end
    else
        for i, dir in ipairs(dirs) do
            dirs[i] = prefix .. dir
        end
        table.append(total_files, dirs)
    end
end

function find_and_add_entries()
    local path = mp.get_property("path", "")
    local dir, filename = utils.split_path(path)
    msg.trace(("dir: %s, filename: %s"):format(dir, filename))
    if o.disabled then
        msg.debug("stopping: autoload disabled")
        return
    elseif #dir == 0 then
        msg.debug("stopping: not a local path")
        return
    end

    local pl_count = mp.get_property_number("playlist-count", 1)
    this_ext = get_extension(filename)
    -- check if this is a manually made playlist
    if (pl_count > 1 and autoloaded == nil) or
       (pl_count == 1 and EXTENSIONS[string.lower(this_ext)] == nil) then
        msg.debug("stopping: manually made playlist")
        return
    else
        if pl_count == 1 then
            autoloaded = true
            autoloaded_dir = dir
            added_entries = {}
        end
    end

    local extensions = {}
    if o.same_type then
        if EXTENSIONS_VIDEO[string.lower(this_ext)] ~= nil then
            extensions = EXTENSIONS_VIDEO
        elseif EXTENSIONS_AUDIO[string.lower(this_ext)] ~= nil then
            extensions = EXTENSIONS_AUDIO
        else
            extensions = EXTENSIONS_IMAGES
        end
    else
        extensions = EXTENSIONS
    end

    local pl = mp.get_property_native("playlist", {})
    local pl_current = mp.get_property_number("playlist-pos-1", 1)
    msg.trace(("playlist-pos-1: %s, playlist: %s"):format(pl_current,
        utils.to_string(pl)))

    local files = {}
    do
        local dir_mode = o.directory_mode or mp.get_property("directory-mode", "lazy")
        local separator = mp.get_property_native("platform") == "windows" and "\\" or "/"
        scan_dir(autoloaded_dir, path, dir_mode, separator, 0, files, extensions)
    end

    if next(files) == nil then
        msg.debug("no other files or directories in directory")
        return
    end

    -- Find the current pl entry (dir+"/"+filename) in the sorted dir list
    local current
    for i = 1, #files do
        if files[i] == path then
            current = i
            break
        end
    end
    if current == nil then
        return
    end
    msg.trace("current file position in files: "..current)

    -- treat already existing playlist entries, independent of how they got added
    -- as if they got added by autoload
    for _, entry in ipairs(pl) do
        added_entries[entry.filename] = true
    end

    -- stop initial file from being added twice
    added_entries[path] = true

    local append = {[-1] = {}, [1] = {}}
    for direction = -1, 1, 2 do -- 2 iterations, with direction = -1 and +1
        for i = 1, MAXENTRIES do
            local pos = current + i * direction
            local file = files[pos]
            if file == nil or file[1] == "." then
                break
            end

            -- skip files that are/were already in the playlist
            if not added_entries[file] then
                if direction == -1 then
                    msg.verbose("Prepending " .. file)
                    table.insert(append[-1], 1, {file, pl_current + i * direction + 1})
                else
                    msg.verbose("Adding " .. file)
                    if pl_count > 1 then
                        table.insert(append[1], {file, pl_current + i * direction - 1})
                    else
                        mp.commandv("loadfile", file, "append")
                    end
                end
            end
            added_entries[file] = true
        end
        if pl_count == 1 and direction == -1 and #append[-1] > 0 then
            for i = 1, #append[-1] do
                mp.commandv("loadfile", append[-1][i][1], "append")
            end
            mp.commandv("playlist-move", 0, current)
        end
    end

    if pl_count > 1 then
        add_files(append[1])
        add_files(append[-1])
    end
end

mp.register_event("start-file", find_and_add_entries)
