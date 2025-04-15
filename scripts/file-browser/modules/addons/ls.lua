--[[
    An addon for mpv-file-browser which uses the Linux ls command to parse native directories
    This behaves near identically to the native parser, but IO is done asynchronously.

    Available at: https://github.com/CogentRedTester/mpv-file-browser/tree/master/addons
]]--

local mp = require "mp"
local msg = require "mp.msg"
local fb = require "file-browser"

local PLATFORM = fb.get_platform()

---@type ParserConfig
local ls = {
    priority = 109,
    api_version = "1.9.0",
    name = "ls",
    keybind_name = "file"
}

---@async
---@param args string[]
---@param parse_state ParseState
---@return string|nil
local function command(args, parse_state)
    local async = mp.command_native_async({
            name = "subprocess",
            playback_only = false,
            capture_stdout = true,
            capture_stderr = true,
            args = args
        }, fb.coroutine.callback(30))

    ---@type boolean, boolean, MPVSubprocessResult
    local completed, _, cmd = parse_state:yield()
    if not completed then
        msg.warn('read timed out for:', table.unpack(args))
        mp.abort_async_command(async)
        return nil
    end

    return cmd.status == 0 and cmd.stdout or nil
end

function ls:can_parse(directory)
    if not fb.get_opt('ls_parser') then return false end
    return PLATFORM ~= 'windows' and directory ~= '' and not fb.get_protocol(directory)
end

---@async
function ls:parse(directory, parse_state)
    local list = {}
    local files = command({"ls", "-1", "-p", "-A", "-N", "--zero", "-L", directory}, parse_state)

    if not files then return nil end

    for str in files:gmatch("%Z+") do
        local is_dir = str:sub(-1) == "/"
        msg.trace(str)

        table.insert(list, {name = str, type = is_dir and "dir" or "file"})
    end

    return list
end

return ls
