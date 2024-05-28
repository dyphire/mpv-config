--[[
    This script is for playing files with ordered chapters on filesystems which cannot
    be scanned directly by mpv.

    The script sets the 'ordered-chapters-files' option to direct mpv to a playlist
    file containing the external ordered chapter files. The playlist should use
    relative paths in order to work across file systems.

    The `playlist_name` variable can be changed to modify what the name of the playlist file should be.

    available at: https://github.com/CogentRedTester/mpv-scripts
]]--

local playlist_name = ".ordered-chapters.m3u"

local mp = require 'mp'
local utils = require 'mp.utils'

local is_windows = package.config:sub(1, 1) == "\\" -- detect path separator, windows uses backslashes

--returns the file extension of the given file
function get_extension(filename, def)
    return string.lower(filename):match("%.([^%./\\]+)$") or def
end

--returns the protocol scheme of the given url, or nil if there is none
function get_protocol(filename, def)
    return string.lower(filename):match("^(%a[%w+-.]*)://") or def
end

local function main()
    local path = mp.get_property('stream-open-filename')
    if get_protocol(path) == "edl" then return end
    if get_extension(path) ~= "mkv" then return end
    if utils.file_info(path) then return end

    if is_windows then path = path:gsub("\\", "/") end
    local directory = path:sub(1, path:find("/[^/]*$"))
    local playlist = directory .. playlist_name

    --sets ordered chapters to use a playlist file inside the directory
    mp.set_property('file-local-options/ordered-chapters-files', playlist)
end

--we need to run the function for both in case a script has modified the path during the on_load_fail hook
mp.add_hook('on_load', 45, main)
mp.add_hook('on_load_fail', 45, main)