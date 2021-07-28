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

local function main()
    local path = mp.get_property('stream-open-filename')
    if path:sub(1, 6) == "edl://" then return end
    if utils.file_info(path) then return end

    path = path:gsub('\\', '/')
    local directory = path:sub(1, path:find("/[^/]*$"))
    local playlist = directory .. playlist_name

    --sets ordered chapters to use a playlist file inside the directory
    mp.set_property('file-local-options/ordered-chapters-files', playlist)
end

--we need to run the function for both in case a script has modified the path during the on_load_fail hook
mp.add_hook('on_load', 45, main)
mp.add_hook('on_load_fail', 45, main)