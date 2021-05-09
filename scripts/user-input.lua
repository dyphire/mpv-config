local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require 'mp.options'

-- Default options
local opts = {
    -- All drawing is scaled by this value, including the text borders and the
    -- cursor. Change it if you have a high-DPI display.
    scale = 1,
    -- Set the font used for the REPL and the console. This probably doesn't
    -- have to be a monospaced font.
    font = "",
    -- Set the font size used for the REPL and the console. This will be
    -- multiplied by "scale."
    font_size = 16,
}

options.read_options(opts, "user_input")

local queue = {
    queue = {},
    active_ids = {}
}
local histories = {}
local request = nil

local line = ''

--[[
    sends a response to the original script in the form of a json string
    it is expected that all requests get a response, if the input is nil then err should say why
    current error codes are:
        exitted        the user closed the input instead of pressing Enter
        already_queued  a request with the specified id was already in the queue
        replaced        the request was replaced with a newer request
        cancelled       a script cancelled the request
]]--
local function send_response(send_line, err, override_response)
    mp.commandv("script-message", override_response or request.response, send_line and line or "", err or "")
end


--[[
    The below code is a modified implementation of text input from mpv's console.lua:
    https://github.com/mpv-player/mpv/blob/7ca14d646c7e405f3fb1e44600e2a67fc4607238/player/lua/console.lua

    Modifications:
        removed support for log messages, sending commands, tab complete, help commands
        removed update timer
        Changed esc key to call handle_esc function
        handle_esc and handle_enter now call the send_response() function
        all functions that send responses now call queue:pop()
        made history specific to request ids
        localised all functions - reordered some to fit
        keybindings use new names
]]--

------------------------------START ORIGINAL MPV CODE-----------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

-- Copyright (C) 2019 the mpv developers
--
-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
-- SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
-- OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
-- CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

local assdraw = require 'mp.assdraw'

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

-- Pick a better default font for Windows and macOS
local platform = detect_platform()
if platform == 'windows' then
    opts.font = 'Consolas'
elseif platform == 'macos' then
    opts.font = 'Menlo'
else
    opts.font = 'monospace'
end

local repl_active = false
local insert_mode = false
local cursor = 1
local key_bindings = {}
local global_margin_y = 0

-- Escape a string for verbatim display on the OSD
local function ass_escape(str)
    -- There is no escape for '\' in ASS (I think?) but '\' is used verbatim if
    -- it isn't followed by a recognised character, so add a zero-width
    -- non-breaking space
    str = str:gsub('\\', '\\\239\187\191')
    str = str:gsub('{', '\\{')
    str = str:gsub('}', '\\}')
    -- Precede newlines with a ZWNBSP to prevent ASS's weird collapsing of
    -- consecutive newlines
    str = str:gsub('\n', '\239\187\191\\N')
    -- Turn leading spaces into hard spaces to prevent ASS from stripping them
    str = str:gsub('\\N ', '\\N\\h')
    str = str:gsub('^ ', '\\h')
    return str
end

-- Render the REPL and console as an ASS OSD
local function update()
    local dpi_scale = mp.get_property_native("display-hidpi-scale", 1.0)

    dpi_scale = dpi_scale * opts.scale

    local screenx, screeny, aspect = mp.get_osd_size()
    screenx = screenx / dpi_scale
    screeny = screeny / dpi_scale

    -- Clear the OSD if the REPL is not active
    if not repl_active then
        mp.set_osd_ass(screenx, screeny, '')
        return
    end

    local ass = assdraw.ass_new()
    local style = '{\\r' ..
                  '\\1a&H00&\\3a&H00&\\4a&H99&' ..
                  '\\1c&Heeeeee&\\3c&H111111&\\4c&H000000&' ..
                  '\\fn' .. opts.font .. '\\fs' .. opts.font_size ..
                  '\\bord1\\xshad0\\yshad1\\fsp0\\q1}'
    -- Create the cursor glyph as an ASS drawing. ASS will draw the cursor
    -- inline with the surrounding text, but it sets the advance to the width
    -- of the drawing. So the cursor doesn't affect layout too much, make it as
    -- thin as possible and make it appear to be 1px wide by giving it 0.5px
    -- horizontal borders.
    local cheight = opts.font_size * 8
    local cglyph = '{\\r' ..
                   '\\1a&H44&\\3a&H44&\\4a&H99&' ..
                   '\\1c&Heeeeee&\\3c&Heeeeee&\\4c&H000000&' ..
                   '\\xbord0.5\\ybord0\\xshad0\\yshad1\\p4\\pbo24}' ..
                   'm 0 0 l 1 0 l 1 ' .. cheight .. ' l 0 ' .. cheight ..
                   '{\\p0}'
    local before_cur = ass_escape(line:sub(1, cursor - 1))
    local after_cur = ass_escape(line:sub(cursor))

    ass:new_event()
    ass:an(1)
    ass:pos(2, screeny - 2 - global_margin_y * screeny)
    ass:append(style .. request.text .. '\\N')
    ass:append('> ' .. before_cur)
    ass:append(cglyph)
    ass:append(style .. after_cur)

    -- Redraw the cursor with the REPL text invisible. This will make the
    -- cursor appear in front of the text.
    ass:new_event()
    ass:an(1)
    ass:pos(2, screeny - 2)
    ass:append(style .. '{\\alpha&HFF&}> ' .. before_cur)
    ass:append(cglyph)
    ass:append(style .. '{\\alpha&HFF&}' .. after_cur)

    mp.set_osd_ass(screenx, screeny, ass.text)
end

-- Naive helper function to find the next UTF-8 character in 'str' after 'pos'
-- by skipping continuation bytes. Assumes 'str' contains valid UTF-8.
local function next_utf8(str, pos)
    if pos > str:len() then return pos end
    repeat
        pos = pos + 1
    until pos > str:len() or str:byte(pos) < 0x80 or str:byte(pos) > 0xbf
    return pos
end

-- As above, but finds the previous UTF-8 charcter in 'str' before 'pos'
local function prev_utf8(str, pos)
    if pos <= 1 then return pos end
    repeat
        pos = pos - 1
    until pos <= 1 or str:byte(pos) < 0x80 or str:byte(pos) > 0xbf
    return pos
end

-- Insert a character at the current cursor position (any_unicode, Shift+Enter)
local function handle_char_input(c)
    if insert_mode then
        line = line:sub(1, cursor - 1) .. c .. line:sub(next_utf8(line, cursor))
    else
        line = line:sub(1, cursor - 1) .. c .. line:sub(cursor)
    end
    cursor = cursor + #c
    update()
end

-- Remove the character behind the cursor (Backspace)
local function handle_backspace()
    if cursor <= 1 then return end
    local prev = prev_utf8(line, cursor)
    line = line:sub(1, prev - 1) .. line:sub(cursor)
    cursor = prev
    update()
end

-- Remove the character in front of the cursor (Del)
local function handle_del()
    if cursor > line:len() then return end
    line = line:sub(1, cursor - 1) .. line:sub(next_utf8(line, cursor))
    update()
end

-- Toggle insert mode (Ins)
local function handle_ins()
    insert_mode = not insert_mode
end

-- Move the cursor to the next character (Right)
local function next_char(amount)
    cursor = next_utf8(line, cursor)
    update()
end

-- Move the cursor to the previous character (Left)
local function prev_char(amount)
    cursor = prev_utf8(line, cursor)
    update()
end

-- Clear the current line (Ctrl+C)
local function clear()
    line = ''
    cursor = 1
    insert_mode = false
    request.history.pos = #request.history.list + 1
    update()
end

-- Close the REPL if the current line is empty, otherwise do nothing (Ctrl+D)
local function maybe_exit()
    if line == '' then
        send_response(false, "exitted")
        queue:pop()
    end
end

local function handle_esc()
    send_response(false, "exitted")
    queue:pop()
end

-- Run the current command and clear the line (Enter)
local function handle_enter()
    if request.history.list[#request.history.list] ~= line and line ~= "" then
        request.history.list[#request.history.list + 1] = line
    end
    send_response(true)
    queue:pop()
end

-- Go to the specified position in the command history
local function go_history(new_pos)
    local old_pos = request.history.pos
    request.history.pos = new_pos

    -- Restrict the position to a legal value
    if request.history.pos > #request.history.list + 1 then
        request.history.pos = #request.history.list + 1
    elseif request.history.pos < 1 then
        request.history.pos = 1
    end

    -- Do nothing if the history position didn't actually change
    if request.history.pos == old_pos then
        return
    end

    -- If the user was editing a non-history line, save it as the last history
    -- entry. This makes it much less frustrating to accidentally hit Up/Down
    -- while editing a line.
    if old_pos == #request.history.list + 1 and line ~= '' and request.history.list[#request.history.list] ~= line then
        request.history.list[#request.history.list + 1] = line
    end

    -- Now show the history line (or a blank line for #history + 1)
    if request.history.pos <= #request.history.list then
        line = request.history.list[request.history.pos]
    else
        line = ''
    end
    cursor = line:len() + 1
    insert_mode = false
    update()
end

-- Go to the specified relative position in the command history (Up, Down)
local function move_history(amount)
    go_history(request.history.pos + amount)
end

-- Go to the first command in the command history (PgUp)
local function handle_pgup()
    go_history(1)
end

-- Stop browsing history and start editing a blank line (PgDown)
local function handle_pgdown()
    go_history(#request.history.list + 1)
end

-- Move to the start of the current word, or if already at the start, the start
-- of the previous word. (Ctrl+Left)
local function prev_word()
    -- This is basically the same as next_word() but backwards, so reverse the
    -- string in order to do a "backwards" find. This wouldn't be as annoying
    -- to do if Lua didn't insist on 1-based indexing.
    cursor = line:len() - select(2, line:reverse():find('%s*[^%s]*', line:len() - cursor + 2)) + 1
    update()
end

-- Move to the end of the current word, or if already at the end, the end of
-- the next word. (Ctrl+Right)
local function next_word()
    cursor = select(2, line:find('%s*[^%s]*', cursor)) + 1
    update()
end

-- Move the cursor to the beginning of the line (HOME)
local function go_home()
    cursor = 1
    update()
end

-- Move the cursor to the end of the line (END)
local function go_end()
    cursor = line:len() + 1
    update()
end

-- Delete from the cursor to the end of the word (Ctrl+W)
local function del_word()
    local before_cur = line:sub(1, cursor - 1)
    local after_cur = line:sub(cursor)

    before_cur = before_cur:gsub('[^%s]+%s*$', '', 1)
    line = before_cur .. after_cur
    cursor = before_cur:len() + 1
    update()
end

-- Delete from the cursor to the end of the line (Ctrl+K)
local function del_to_eol()
    line = line:sub(1, cursor - 1)
    update()
end

-- Delete from the cursor back to the start of the line (Ctrl+U)
local function del_to_start()
    line = line:sub(cursor)
    cursor = 1
    update()
end

-- Returns a string of UTF-8 text from the clipboard (or the primary selection)
local function get_clipboard(clip)
    if platform == 'x11' then
        local res = utils.subprocess({
            args = { 'xclip', '-selection', clip and 'clipboard' or 'primary', '-out' },
            playback_only = false,
        })
        if not res.error then
            return res.stdout
        end
    elseif platform == 'wayland' then
        local res = utils.subprocess({
            args = { 'wl-paste', clip and '-n' or  '-np' },
            playback_only = false,
        })
        if not res.error then
            return res.stdout
        end
    elseif platform == 'windows' then
        local res = utils.subprocess({
            args = { 'powershell', '-NoProfile', '-Command', [[& {
                Trap {
                    Write-Error -ErrorRecord $_
                    Exit 1
                }

                $clip = ""
                if (Get-Command "Get-Clipboard" -errorAction SilentlyContinue) {
                    $clip = Get-Clipboard -Raw -Format Text -TextFormatType UnicodeText
                } else {
                    Add-Type -AssemblyName PresentationCore
                    $clip = [Windows.Clipboard]::GetText()
                }

                $clip = $clip -Replace "`r",""
                $u8clip = [System.Text.Encoding]::UTF8.GetBytes($clip)
                [Console]::OpenStandardOutput().Write($u8clip, 0, $u8clip.Length)
            }]] },
            playback_only = false,
        })
        if not res.error then
            return res.stdout
        end
    elseif platform == 'macos' then
        local res = utils.subprocess({
            args = { 'pbpaste' },
            playback_only = false,
        })
        if not res.error then
            return res.stdout
        end
    end
    return ''
end

-- Paste text from the window-system's clipboard. 'clip' determines whether the
-- clipboard or the primary selection buffer is used (on X11 and Wayland only.)
local function paste(clip)
    local text = get_clipboard(clip)
    local before_cur = line:sub(1, cursor - 1)
    local after_cur = line:sub(cursor)
    line = before_cur .. text .. after_cur
    cursor = cursor + text:len()
    update()
end

-- List of input bindings. This is a weird mashup between common GUI text-input
-- bindings and readline bindings.
local function get_bindings()
    local bindings = {
        { 'esc',         handle_esc                                 },
        { 'enter',       handle_enter                               },
        { 'kp_enter',    handle_enter                               },
        { 'shift+enter', function() handle_char_input('\n') end     },
        { 'bs',          handle_backspace                           },
        { 'shift+bs',    handle_backspace                           },
        { 'del',         handle_del                                 },
        { 'shift+del',   handle_del                                 },
        { 'ins',         handle_ins                                 },
        { 'shift+ins',   function() paste(false) end                },
        { 'mbtn_mid',    function() paste(false) end                },
        { 'left',        function() prev_char() end                 },
        { 'right',       function() next_char() end                 },
        { 'up',          function() move_history(-1) end            },
        { 'wheel_up',    function() move_history(-1) end            },
        { 'down',        function() move_history(1) end             },
        { 'wheel_down',  function() move_history(1) end             },
        { 'wheel_left',  function() end                             },
        { 'wheel_right', function() end                             },
        { 'ctrl+left',   prev_word                                  },
        { 'ctrl+right',  next_word                                  },
        { 'home',        go_home                                    },
        { 'end',         go_end                                     },
        { 'pgup',        handle_pgup                                },
        { 'pgdwn',       handle_pgdown                              },
        { 'ctrl+c',      clear                                      },
        { 'ctrl+d',      maybe_exit                                 },
        { 'ctrl+k',      del_to_eol                                 },
        { 'ctrl+u',      del_to_start                               },
        { 'ctrl+v',      function() paste(true) end                 },
        { 'meta+v',      function() paste(true) end                 },
        { 'ctrl+w',      del_word                                   },
        { 'kp_dec',      function() handle_char_input('.') end      },
    }

    for i = 0, 9 do
        bindings[#bindings + 1] =
            {'kp' .. i, function() handle_char_input('' .. i) end}
    end

    return bindings
end

local function text_input(info)
    if info.key_text and (info.event == "press" or info.event == "down"
                          or info.event == "repeat")
    then
        handle_char_input(info.key_text)
    end
end

local function define_key_bindings()
    if #key_bindings > 0 then
        return
    end
    for _, bind in ipairs(get_bindings()) do
        -- Generate arbitrary name for removing the bindings later.
        local name = "_userinput_" .. bind[1]
        key_bindings[#key_bindings + 1] = name
        mp.add_forced_key_binding(bind[1], name, bind[2], {repeatable = true})
    end
    mp.add_forced_key_binding("any_unicode", "_userinput_text", text_input,
        {repeatable = true, complex = true})
    key_bindings[#key_bindings + 1] = "_userinput_text"
end

local function undefine_key_bindings()
    for _, name in ipairs(key_bindings) do
        mp.remove_key_binding(name)
    end
    key_bindings = {}
end

-- Set the REPL visibility ("enable", Esc)
local function set_active(active)
    if active == repl_active then return end
    if active then
        repl_active = true
        insert_mode = false
        define_key_bindings()
    else
        clear()
        repl_active = false
        undefine_key_bindings()
        collectgarbage()
    end
    update()
end


utils.shared_script_property_observe("osc-margins", function(_, val)
    if val then
        -- formatted as "%f,%f,%f,%f" with left, right, top, bottom, each
        -- value being the border size as ratio of the window size (0.0-1.0)
        local vals = {}
        for v in string.gmatch(val, "[^,]+") do
            vals[#vals + 1] = tonumber(v)
        end
        global_margin_y = vals[4] -- bottom
    else
        global_margin_y = 0
    end
    update()
end)

-- Redraw the REPL when the OSD size changes. This is needed because the
-- PlayRes of the OSD will need to be adjusted.
mp.observe_property('osd-width', 'native', update)
mp.observe_property('osd-height', 'native', update)
mp.observe_property('display-hidpi-scale', 'native', update)

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-------------------------------END ORIGINAL MPV CODE------------------------------------

-- push new request onto the queue
-- if a request with the same id already exists and the queueable flag is not enabled then
-- a nil result will be returned to the function
function queue:push(req)
    if self.active_ids[req.id] then

        -- replace an existing request with the new one
        if req.replace then
            for i = 1, #self.queue do
                if self.queue[i].id == req.id then
                    send_response(false, "replaced", self.queue[i].response)
                    self.queue[i] = req
                    if i == 1 then request = req ; update() end
                    return
                end
            end
        end

        --cancel the new request if it is not queueable
        if not req.queueable then send_response(false, "already_queued", req.response) ; return end
    end

    table.insert(self.queue, req)
    self.active_ids[req.id] = (self.active_ids[req.id] or 0) + 1
    if #self.queue == 1 then return self:start_queue() end
end

-- removes the first item in the queue and either continues or stops the queue
function queue:pop()
    self:remove(1)
    clear()

    if #self.queue < 1 then return self:stop_queue()
    else return self:continue_queue() end
end

-- safely removes an item from the queue and updates the set of active requests
function queue:remove(index)
    local req = table.remove(self.queue, index)
    self.active_ids[req.id] = self.active_ids[req.id] ~= 1 and self.active_ids[req.id] - 1 or nil
end

function queue:start_queue()
    request = self.queue[1]
    line = request.default_input
    set_active(true)
end

function queue:continue_queue()
    request = self.queue[1]
    line = request.default_input
    update()
end

function queue:stop_queue()
    set_active(false)
end

-- removes all requests with the specified id from the queue
mp.register_script_message("cancel-user-input", function(id)
    local i = 2
    while i <= #queue.queue do
        if queue.queue[i].id == id then
            send_response(false, "cancelled", queue.queue[i].response)
            queue:remove(i)
        else
            i = i + 1
        end
    end

    if queue.queue[1] and queue.queue[1].id == id then
        send_response(false, "cancelled")
        queue:pop()
    end
end)

-- script message to recieve input requests, get-user-input.lua acts as an interface to call this script message
-- requests are recieved as json objects
mp.register_script_message("request-user-input", function(response, id, request_text, default_input, queueable, replace)
    local req = {}

    if not response then msg.error("input requests require a response string") ; return end
    if not id then msg.error("input requests require an id string") ; return end
    req.response = response
    req.text = ass_escape(request_text or "")
    req.default_input = default_input
    req.id = id or "mpv"
    req.queueable = (queueable == "1")
    req.replace = (replace == "1")

    if not histories[id] then histories[id] = {pos = 1, list = {}} end
    req.history = histories[id]

    queue:push(req)
end)

--temporary keybind for debugging purposes
mp.add_key_binding("Ctrl+i", "user-input", function() set_active(true) end)
