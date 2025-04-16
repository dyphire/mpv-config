--[[
    An addon for mpv-file-browser which uses the Windows dir command to parse native directories
    This behaves near identically to the native parser, but IO is done asynchronously.

    Available at: https://github.com/CogentRedTester/mpv-file-browser/tree/master/addons
]]--

local mp = require "mp"
local msg = require "mp.msg"
local fb = require "file-browser"

local PLATFORM = fb.get_platform()

---@param bytes string
---@return fun(): number, number
local function byte_iterator(bytes)
    ---@async
    ---@return number?
    local function iter()
        for i = 1, #bytes do
            coroutine.yield(bytes:byte(i), i)
        end
        error('malformed utf16le string - expected byte but found end of string')
    end

    return coroutine.wrap(iter)
end

---@param bits number
---@param by number
---@return number
local function lshift(bits, by)
    return bits * 2^by
end

---@param bits number
---@param by number
---@return integer
local function rshift(bits, by)
    return math.floor(bits / 2^by)
end

---@param bits number
---@param i number
---@return number
local function bits_below(bits, i)
    return bits % 2^i
end

---@param bits number
---@param i number exclusive
---@param j number inclusive
---@return integer
local function bits_between(bits, i, j)
    return rshift(bits_below(bits, j), i)
end

---@param bytes string
---@return number[]
local function utf16le_to_unicode(bytes)
    msg.trace('converting from utf16-le to unicode codepoints')

    ---@type number[]
    local codepoints = {}

    local get_byte = byte_iterator(bytes)

    while true do
        -- start of a char
        local success, little, i = pcall(get_byte)
        if not success then break end

        local big = get_byte()
        local codepoint = little + lshift(big, 8)

        if codepoint < 0xd800 or codepoint > 0xdfff then
            table.insert(codepoints, codepoint)
        else
            -- handling surrogate pairs
            -- grab the next two bytes to grab the low surrogate
            local high_pair = codepoint
            local low_pair = get_byte() + lshift(get_byte(), 8)

            if high_pair >= 0xdc00 then
                error(('malformed utf16le string at byte #%d (0x%04X) - high surrogate pair should be < 0xDC00'):format(i, high_pair))
            elseif low_pair < 0xdc00 then
                error(('malformed utf16le string at byte #%d (0x%04X) - low surrogate pair should be >= 0xDC00'):format(i+2, low_pair))
            end

            -- The last 10 bits of each surrogate are the two halves of the codepoint
            -- https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
            local high_bits = bits_below(high_pair, 10)
            local low_bits = bits_below(low_pair, 10)
            local surrogate_par = (low_bits + lshift(high_bits, 10)) + 0x10000

            table.insert(codepoints, surrogate_par)
        end
    end

    return codepoints
end

---@param codepoints number[]
---@return string
local function unicode_to_utf8(codepoints)
    ---@type number[]
    local bytes = {}

    -- https://en.wikipedia.org/wiki/UTF-8#Description
    for i, codepoint in ipairs(codepoints) do
        if codepoint >= 0xd800 and codepoint <= 0xdfff then
            error(('codepoint %d (U+%05X) is within the reserved surrogate pair range (U+D800-U+DFFF)'):format(i, codepoint))
        elseif codepoint <= 0x7f then
            table.insert(bytes, codepoint)
        elseif codepoint <= 0x7ff then
            table.insert(bytes, 0xC0 + rshift(codepoint, 6))
            table.insert(bytes, 0x80 + bits_below(codepoint, 6))
        elseif codepoint <= 0xffff then
            table.insert(bytes, 0xE0 + rshift(codepoint, 12))
            table.insert(bytes, 0x80 + bits_between(codepoint, 6, 12))
            table.insert(bytes, 0x80 + bits_below(codepoint, 6))
        elseif codepoint <= 0x10ffff then
            table.insert(bytes, 0xF0 + rshift(codepoint, 18))
            table.insert(bytes, 0x80 + bits_between(codepoint, 12, 18))
            table.insert(bytes, 0x80 + bits_between(codepoint, 6, 12))
            table.insert(bytes, 0x80 + bits_below(codepoint, 6))
        else
            error(('codepoint %d (U+%05X) is larger than U+10FFFF'):format(i, codepoint))
        end
    end

    return string.char(table.unpack(bytes))
end

local function utf8(text)
    return unicode_to_utf8(utf16le_to_unicode(text))
end

---@type ParserConfig
local dir = {
    priority = 109,
    api_version = "1.9.0",
    name = "cmd-dir",
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
            args = args,
        }, fb.coroutine.callback(30) )

    ---@type boolean, boolean, MPVSubprocessResult
    local completed, _, cmd = parse_state:yield()
    if not completed then
        msg.warn('read timed out for:', table.unpack(args))
        mp.abort_async_command(async)
        return nil
    end

    local success = xpcall(function()
        cmd.stdout = utf8(cmd.stdout) or ''
        cmd.stderr = utf8(cmd.stderr) or ''
    end, fb.traceback)

    if not success then return msg.error('failed to convert utf16-le string to utf8') end

    --dir returns this exact error message if the directory is empty
    if cmd.status == 1 and cmd.stderr == "File Not Found\r\n" then cmd.status = 0 end
    if cmd.status ~= 0 then return msg.error(cmd.stderr) end

    return cmd.status == 0 and cmd.stdout or nil
end

function dir:can_parse(directory)
    if not fb.get_opt('windir_parser') then return false end
    return PLATFORM == 'windows' and directory ~= '' and not fb.get_protocol(directory)
end

---@async
function dir:parse(directory, parse_state)
    local list = {}

    -- the dir command expects backslashes for our paths
    directory = string.gsub(directory, "/", "\\")

    local dirs = command({ "cmd", "/U", "/c", "dir", "/b", "/ad", directory }, parse_state)
    if not dirs then return end

    local files = command({ "cmd", "/U", "/c", "dir", "/b", "/a-d", directory }, parse_state)
    if not files then return end

    for name in dirs:gmatch("[^\n\r]+") do
        name = name.."/"
        if fb.valid_dir(name) then
            table.insert(list, { name = name, type = "dir" })
            msg.trace(name)
        end
    end

    for name in files:gmatch("[^\n\r]+") do
        if fb.valid_file(name) then
            table.insert(list, { name = name, type = "file" })
            msg.trace(name)
        end
    end

    return list, { filtered = true }
end

return dir
