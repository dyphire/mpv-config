--[[
    An addon for mpv-file-browser which uses the Windows dir command to parse native directories
    This behaves near identically to the native parser, but IO is done asynchronously.

    Available at: https://github.com/CogentRedTester/mpv-file-browser/tree/master/addons
]]--

local mp = require "mp"
local msg = require "mp.msg"
local fb = require "file-browser"

--this is a LuaJit module this addon will not load if not using LuaJit
local ffi = require 'ffi'
ffi.cdef([[
    int __stdcall WideCharToMultiByte(unsigned int CodePage, unsigned int dwFlags, const wchar_t *lpWideCharStr, int cchWideChar, char *lpMultiByteStr, int cbMultiByte, const char *lpDefaultChar, bool *lpUsedDefaultChar);
]])

--converts a UTF16 string to a UTF8 string
--this function was adapted from https://github.com/mpv-player/mpv/issues/10139#issuecomment-1117954648
local function utf8(WideCharStr)
    WideCharStr = ffi.cast("wchar_t*", WideCharStr)
    if not WideCharStr then return nil end

    local utf8_size = ffi.C.WideCharToMultiByte(65001, 0, WideCharStr, -1, nil, 0, nil, nil) --CP_UTF8
    if utf8_size > 0 then
        local utf8_path = ffi.new("char[?]", utf8_size)
        local utf8_size = ffi.C.WideCharToMultiByte(65001, 0, WideCharStr, -1, utf8_path, utf8_size, nil, nil)
        if utf8_size > 0 then
            --removes the trailing `\0` character which can break things
            return ffi.string(utf8_path, utf8_size):sub(1, -2)
        end
    end
end

local dir = {
    priority = 109,
    version = "1.1.0",
    name = "cmd-dir",
    keybind_name = "file"
}

local function command(args, parse_state)
    local _, cmd = parse_state:yield(
        mp.command_native_async({
            name = "subprocess",
            playback_only = false,
            capture_stdout = true,
            capture_stderr = true,
            args = args,
        }, fb.coroutine.callback() )
    )
    cmd.stdout = utf8(cmd.stdout)
    cmd.stderr = utf8(cmd.stderr)

    --dir returns this exact error message if the directory is empty
    if cmd.status == 1 and cmd.stderr == "File Not Found\r\n" then cmd.status = 0 end

    return cmd.status == 0 and cmd.stdout or nil, cmd.stderr
end

function dir:can_parse(directory)
    if directory == "" then return end
    return not fb.get_protocol(directory)
end

function dir:parse(directory, parse_state)
    local list = {}
    local files, dirs, err

    -- the dir command expects backslashes for our paths
    directory = directory:gsub("/", "\\")

    dirs, err = command({ "cmd", "/U", "/c", "dir", "/b", "/ad", directory }, parse_state)
    if not dirs then return msg.error(err) end

    files, err = command({ "cmd", "/U", "/c", "dir", "/b", "/a-d", directory }, parse_state)
    if not files then return msg.error(err) end

    for name in dirs:gmatch("[^\n\r]+") do
        name = name.."/"
        if fb.valid_dir(name) then
            table.insert(list, { name = name, type = "dir" })
        end
    end

    for name in files:gmatch("[^\n\r]+") do
        if fb.valid_file(name) then
            table.insert(list, { name = name, type = "file" })
        end
    end

    return list, { filtered = true }
end

return dir
