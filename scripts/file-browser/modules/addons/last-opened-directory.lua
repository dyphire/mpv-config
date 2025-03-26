--[[
    An addon for mpv-file-browser which stores the last opened directory and
    sets it as the opened directory the next time mpv is opened.

    Available at: https://github.com/CogentRedTester/mpv-file-browser/tree/master/addons
]]--

local mp = require 'mp'
local msg = require 'mp.msg'

local fb = require 'file-browser'

local state_file = mp.command_native({'expand-path', fb.get_opt('last_opened_directory_file')}) --[[@as string]]
msg.verbose('using', state_file)

---@param directory? string
---@return nil
local function write_directory(directory)
    if not fb.get_opt('save_last_opened_directory') then return end

    local file = io.open(state_file, 'w+')

    if not file then return msg.error('could not open', state_file, 'for writing') end

    directory = directory or fb.get_directory() or ''
    msg.verbose('writing', directory, 'to', state_file)
    file:write(directory)
    file:close()
end

---@type ParserConfig
local addon = {
    api_version = '1.7.0',
    priority = 0,
}

function addon:setup()
    if not fb.get_opt('default_to_last_opened_directory') then return end

    local file = io.open(state_file, "r")
    if not file then
        return msg.info('failed to open', state_file, 'for reading (may be due to first load)')
    end

    local dir = file:read("*a")
    msg.verbose('setting default directory to', dir)
    fb.browse_directory(dir, false)
    file:close()
end

function addon:can_parse(dir, parse_state)
    if parse_state.source == 'browser' then write_directory(dir) end
    return false
end

function addon:parse()
    return nil
end

mp.register_event('shutdown', function() write_directory() end)

return addon
