--[[
    An addon for mpv-file-browser which adds support for m3u playlists

    If the first entry of a playlist isn't working it is because some playlists are created with random invisible unicode in the first line
    Vim makes it easy to detect these
]]--

local m3u = {
    priority = 100,
    name = "m3u"
}

local full_paths = {}

function m3u:setup()
    self.register_parseable_extension("m3u")
    self.register_parseable_extension("m3u8")
end

function m3u:can_parse(directory)
    return directory:find("m3u8?/?$") and not self.get_protocol(directory)
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

return m3u
