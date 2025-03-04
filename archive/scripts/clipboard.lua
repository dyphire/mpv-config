--[[
    A simple script that provides some extremely low-level clipboard commands for users and other script writers.
    Available at: https://github.com/CogentRedTester/mpv-clipboard

    `script-message set-clipboard <text>`
        
        saves the given string in the clipboard

    `script-message get-clipboard <script-message>`

        sends the contents of the clipboard to the given script-message

    `script-message clipboard-command <command> <arg1> <arg2> ...`

        Runs the given command substituting %clip% for the contents of the clipboard.
        `%%` will be escaped into a single `%` character.
]]

local mp = require 'mp'
local msg = require 'mp.msg'

-- this code was taken from mpv's console.lua:
-- https://github.com/mpv-player/mpv/blob/master/player/lua/console.lua
local function detect_platform()
    local o = {}
    -- Kind of a dumb way of detecting the platform but whatever
    if mp.get_property_native('options/vo-mmcss-profile', o) ~= o then
        return 'windows'
    elseif mp.get_property_native('options/macos-force-dedicated-gpu', o) ~= o then
        return 'macos'
    elseif os.getenv('WAYLAND_DISPLAY') then
        return 'wayland'
    end
    return 'x11'
end

local platform = detect_platform()

local function make_raw(s)
	if not s then return end
	s = string.gsub(s, '^[\'\"]', '')
	s = string.gsub(s, '[\'\"]$', '')
	s = string.gsub(s, '^%s+', '')
	s = string.gsub(s, '%s+$', '')
	return s
end

-- this is based on mpv-copyTime:
-- https://github.com/Arieleg/mpv-copyTime/blob/master/copyTime.lua
local function get_command()
    if platform == 'x11' then return 'xclip -silent -selection clipboard -in' end
    if platform == 'wayland' then return 'wl-copy' end
    if platform == 'macos' then return 'pbcopy' end
end

-- an error handler to pass to xpcall
local function error_handler(err)
    msg.warn(debug.traceback("", 2))
    msg.error(err)
end

--resumes a coroutine and prints an error if it was not sucessful
local function co_resume_err(...)
    local success, err = coroutine.resume(...)
    if not success then
        msg.warn(debug.traceback( (select(1, ...)) ))
        msg.error(err)
    end
    return success
end

-- run the given function in a coroutine
local function co_run(fn, ...)
    local co = coroutine.create(fn)
    co_resume_err(co, ...)
end

-- escapes a string so that it can be inserted into powershell as a string literal
local function escape_powershell(str)
    return '"'..string.gsub(str, '[$"`]', '`%1')..'"'
end

-- runs the given command.
-- if run in a coroutine then yield, otherwise block
local function subprocess(args)
    local cmd = {
        name = 'subprocess',
        args = args,
        playback_only = false,
        capture_stdout = true
    }

    local success, res, err
    local co, main = coroutine.running()

    if main or not co then
        res, err = mp.command_native(cmd)
        success = res
    else
        mp.command_native_async(cmd, function(...) return co_resume_err(co, ...) end)
        success, res, err = coroutine.yield()
    end

    -- something pretty drastic has to happen for this to error
    if not success then error(err) end
    res.error = res.error_string ~= '' and res.error_string or nil
    return res
end

-- Returns a string of UTF-8 text from the clipboard
local function get_clipboard()
    if platform == 'x11' then
        local res = subprocess({ 'xclip', '-selection', 'clipboard', '-out' })
        if not res.error then
            return res.stdout
        end
    elseif platform == 'wayland' then
        local res = subprocess({ 'wl-paste', '-n' })
        if not res.error then
            return res.stdout
        end
    elseif platform == 'windows' then
        local res = subprocess({ 'powershell', '-NoProfile', '-Command', [[& {
            Trap {
                Write-Error -ErrorRecord $_
                Exit 1
            }
            $clip = Get-Clipboard -Raw -Format Text -TextFormatType UnicodeText
            if (-not $clip) {
                $clip = Get-Clipboard -Raw -Format FileDropList
            }
            $u8clip = [System.Text.Encoding]::UTF8.GetBytes($clip)
            [Console]::OpenStandardOutput().Write($u8clip, 0, $u8clip.Length)
            }]]
        })
        if not res.error then
            return res.stdout
        end
    elseif platform == 'macos' then
        local res = subprocess({ 'pbpaste' })
        if not res.error then
            return res.stdout
        end
    end
    return ''
end

local function substitute(str, clip)
    return string.gsub(str, '%b%%', function(text)
        if text == '%clip%' then return make_raw(clip) end
        if text == '%%' then return '%' end
    end)
end

-- sets the contents of the clipboard to the given string
local function set_clipboard(text)
    msg.verbose('setting clipboard text:', text)

    if platform == 'windows' then
        mp.commandv('run', 'powershell', '-NoProfile', '-command', 'set-clipboard', escape_powershell(text))

    -- this is based on mpv-copyTime:
    -- https://github.com/Arieleg/mpv-copyTime/blob/master/copyTime.lua
    else
        local pipe = io.popen(get_command(), 'w')
        if not pipe then return msg.error('could not open unix pipe') end
        pipe:write(text)
        pipe:close()
    end
end

--runs the given mpv command, substituting %clip% for the contents of the clipboard
local function clipboard_command(...)
    msg.verbose('received clipboard command:', ...)

    local args = {'osd-auto', ...}
    local function command()
        local clip = get_clipboard()
        for i, str in ipairs(args) do
            args[i] = substitute(str, clip)
        end
        mp.command_native(args)
    end

    -- if the first command prefix is sync then run synchronously, otherwise run
    -- in a corooutine which allows the get_clipboard command to yield.
    if select(1, ...) == 'sync' then xpcall(command, error_handler)
    else co_run(command) end
end

-- sends the contents of the clipboard to any script that requests it
-- sends the response to the given response string
local function clipboard_request(response)
    msg.verbose('received clipboard request - sending response to:', response)
    co_run(function()
        mp.commandv('script-message', response, get_clipboard())
    end)
end

mp.register_script_message('set-clipboard', set_clipboard)
mp.register_script_message('get-clipboard', clipboard_request)
mp.register_script_message('clipboard-command', clipboard_command)
