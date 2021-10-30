--[[
    An addon for mpv-file-browser which displays ~/ for the home directory instead of the full path
]]--

local mp = require "mp"
local home = mp.command_native({"expand-path", "~/"})
local home_label = {
    priority = 100
}

function home_label:setup()
    home = self.fix_path(home, true)
end

function home_label:can_parse(directory)
    return directory:sub(1, home:len()) == home
end

function home_label:parse(directory, ...)
    local list, opts = self:defer(directory, ...)
    if (not opts.directory or opts.directory == directory) and not opts.directory_label then
        opts.directory_label = "~/"..(directory:sub(home:len()+1) or "")
    end
    return list, opts
end

return home_label