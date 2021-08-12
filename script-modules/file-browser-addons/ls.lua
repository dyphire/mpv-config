--[[
    An addon for mpv-file-browser which uses the linux ls command to parse native directories

    This is mostly a proof of concept, I don't know of any cases when this would be needed.
]]--

local mp = require "mp"

local ls = {
    priority = 109,
    name = "ls",
    keybind_name = "file"
}

local function command(args)
    local cmd = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        args = args
    })

    return cmd.status == 0 and cmd.stdout or nil
end

function ls:can_parse(directory)
    return not self.get_protocol(directory)
end

function ls:parse(directory)
    local list = {}
    local files = command({"ls", "-1", "-p", "-A", "-N", directory})

    if not files then return nil end

    for str in files:gmatch("[^\n\r]+") do
        local is_dir = str:sub(-1) == "/"

        if is_dir and self.valid_dir(str) then
            table.insert(list, {name = str, type = "dir"})
        elseif self.valid_file(str) then
            table.insert(list, {name = str, type = "file"})
        end
    end

    return list, {filtered = true}
end

return ls
