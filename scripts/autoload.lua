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

Example configuration would be:

disabled=no
images=no
videos=yes
audio=yes
directories=no
sameseries=yes
ignore_hidden=yes

--]]


local msg = require 'mp.msg'
local options = require 'mp.options'
local utils = require 'mp.utils'

o = {
    disabled = false,
    images = true,
    videos = true,
    audio = true,
    directories = false,
    sameseries = false,
    max_entries = 5000,
    ignore_hidden = true
}
options.read_options(o)

function Set (t)
    local set = {}
    for _, v in pairs(t) do set[v] = true end
    return set
end

function SetUnion (a,b)
    local res = {}
    for k in pairs(a) do res[k] = true end
    for k in pairs(b) do res[k] = true end
    return res
end

EXTENSIONS_VIDEO = Set {
    '3g2', '3gp', 'avi', 'asf', 'f4v', 'flv', 'm2ts', 'm4v', 'mj2', 'mkv', 'mov',
    'mp4', 'mpeg', 'mpg', 'ogv', 'rm', 'rmvb', 'ts', 'vob', 'webm', 'wmv', 'y4m'
}

EXTENSIONS_AUDIO = Set {
    'aiff', 'ape', 'au', 'dsf', 'flac', 'm4a', 'mka', 'mp3', 'oga', 'ogg',
    'ogm', 'opus', 'spx', 'wav', 'wma'
}

EXTENSIONS_IMAGES = Set {
    'avif', 'bmp', 'gif', 'j2k', 'jfif', 'jp2', 'jpeg', 'jpg', 'jxl', 'png',
    'svg', 'tga', 'tif', 'tiff', 'webp'
}

EXTENSIONS = Set {}
if o.videos then EXTENSIONS = SetUnion(EXTENSIONS, EXTENSIONS_VIDEO) end
if o.audio then EXTENSIONS = SetUnion(EXTENSIONS, EXTENSIONS_AUDIO) end
if o.images then EXTENSIONS = SetUnion(EXTENSIONS, EXTENSIONS_IMAGES) end

function add_files_at(index, files)
    index = index - 1
    local oldcount = mp.get_property_number("playlist-count", 1)
    for i = 1, #files do
        mp.commandv("loadfile", files[i], "append")
        mp.commandv("playlist-move", oldcount + i - 1, index + i - 1)
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
    return t1
end

-- alphanum sorting for humans in Lua
-- http://notebook.kulchenko.com/algorithms/alphanumeric-natural-sorting-for-humans-in-lua

function alphanumsort(filenames)
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

local autoloaded = nil
local added_entries = {}

function find_and_add_entries()
    local path = mp.get_property("path", "")
    local dir, filename = utils.split_path(path)
    msg.trace(("dir: %s, filename: %s"):format(dir, filename))
    if o.disabled then
        msg.verbose("stopping: autoload disabled")
        return
    elseif #dir == 0 then
        msg.verbose("stopping: not a local path")
        return
    end

    local pl_count = mp.get_property_number("playlist-count", 1)
    -- check if this is a manually made playlist
    if (pl_count > 1 and autoloaded == nil) or
       (pl_count == 1 and EXTENSIONS[string.lower(get_extension(filename))] == nil) then
        msg.verbose("stopping: manually made playlist")
        return
    else
        if pl_count == 1 then
            autoloaded = true
            added_entries = {}
        end
    end

    local pl = mp.get_property_native("playlist", {})
    local pl_current = mp.get_property_number("playlist-pos-1", 1)
    msg.trace(("playlist-pos-1: %s, playlist: %s"):format(pl_current,
        utils.to_string(pl)))

    local files = utils.readdir(dir, "files")
    local dirs = o.directories and utils.readdir(dir, "dirs") or nil
    if files == nil and dirs == nil then
        msg.verbose("no other files or directories in directory")
        return
    end
    files, dirs = files or {}, dirs or {}
    table.filter(files, function (v, k)
        -- The current file could be a hidden file, ignoring it doesn't load other
        -- files from the current directory.
        if (o.ignore_hidden and not (v == filename) and string.match(v, "^%.")) then
            return false
        end
        local ext = get_extension(v)
        if ext == nil then
            return false
        end
        if o.sameseries then
            local name = mp.get_property("filename")
            local namepre = string.sub(name, 1, 6)
            local namepre0 = string.gsub(namepre, "%p", "%%%1")
            for vidext, _ in pairs(EXTENSIONS_VIDEO) do
                if string.match(name, vidext.."$") ~= nil then
                    if string.match(v, "^"..namepre0) == nil then
                        return false
                    end
                end
            end
        end
        return EXTENSIONS[string.lower(ext)]
    end)
    table.filter(dirs, function(d)
        return not ((o.ignore_hidden and string.match(d, "^%.")))
    end)
    alphanumsort(table.append(files, dirs))

    if dir == "." then
        dir = ""
    end

    -- Find the current pl entry (dir+"/"+filename) in the sorted dir list
    local current
    for i = 1, #files do
        if files[i] == filename then
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
    local playlist = mp.get_property_native("playlist", {})
    for _, entry in ipairs(playlist) do
        added_entries[entry.filename] = true
    end

    local append = {[-1] = {}, [1] = {}}
    for direction = -1, 1, 2 do -- 2 iterations, with direction = -1 and +1
        for i = 1, o.max_entries do
            local file = files[current + i * direction]
            if file == nil or file[1] == "." then
                break
            end

            local filepath = dir .. file
            -- skip files that are/were already in the playlist
            if added_entries[filepath] then break end

            if direction == -1 then
                msg.info("Prepending " .. filepath)
                table.insert(append[-1], 1, filepath)
            else
                msg.info("Adding " .. filepath)
                table.insert(append[1], filepath)
            end
            added_entries[filepath] = true
        end
    end

    add_files_at(pl_current + 1, append[1])
    add_files_at(pl_current, append[-1])
end

mp.register_event("start-file", find_and_add_entries)
