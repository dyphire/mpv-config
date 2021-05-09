--[[
    An addon for mpv-file-browser which adds support for m3u playlists

    If the first entry of a playlist isn't working it is because some playlists are created with random invisible unicode in the first line
    Vim makes it easy to detect these
]]--

local utils = require "mp.utils"

local m3u = {
    priority = 100,
    name = "m3u"
}

local exts = {
    m3u = true,
    m3u8 = true
}

local full_paths = {}

function m3u:can_parse(directory)
    return directory:find("m3u8?/?$") and true
end

function m3u:parse(directory)
    directory = directory:gsub("/$", "")
    local list = {}

    local path = full_paths[ directory ] or directory
    local playlist = io.open( path )

    --if we can't read the path then stop here
    if not playlist then return {}, {sorted = true, filtered = true, empty_text = "Could not read filepath"} end

    local parent = self.fix_path(path:match("^(.+/[^/]+)/"), true)

    local lines = playlist:read("*a")

    for item in lines:gmatch("[^%c]+") do
        item = self.fix_path(item)
        local fullpath = self.join_path(parent, item)

        local name = ( self.get_protocol(item) and item or fullpath:match("([^/]+)/?$") )
        table.insert(list, {name = name, path = fullpath, type = "file"})
    end
    return list, {filtered = true, sorted = true}
end

--set m3u files as directories so that file-browser will allow the user to open them
local pl_fixer = {
    priority = 10,
    name = "m3u-fixer"
}

function pl_fixer:can_parse(directory)
    if directory == "" then return false end
    return not self.get_protocol(directory) and not exts[ self.get_extension(directory:gsub("/$", "")) ]
end

function pl_fixer:parse(directory)
    local list, opts = self:defer(directory)
    if not list then return nil end
    for _, item in ipairs(list) do
        if exts[ self.get_extension(item.name) ] then
            item.type = "dir"
            item.path = item.path or directory..item.name
            item.label = item.label or item.name
            item.name = item.name.."/"
        end
    end
    return list, opts
end

return {m3u, pl_fixer}
