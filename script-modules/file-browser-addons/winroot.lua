--[[
    Automatically populates the root with windows drives on startup.
    Ctrl+r will add new drives mounted since startup.

    Drives will only be added if they are not already present in the root.

    Available at: https://github.com/CogentRedTester/mpv-file-browser/tree/master/addons
]]

local mp = require 'mp'
local msg = require 'mp.msg'
local fb = require 'file-browser'

-- returns a list of windows drives
local function get_drives()
    local result = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        capture_stdout = true,
        args = {'wmic', 'logicaldisk', 'get', 'caption'}
    })
    if result.status ~= 0 then return msg.error('could not read windows root') end

    local root = {}
    for drive in result.stdout:gmatch("%a:") do
        table.insert(root, drive..'/')
    end
    return root
end

-- adds windows drives to the root if they are not already present
local function import_drives()
    local drives = get_drives()

    for _, drive in ipairs(drives) do
        fb.register_root_item(drive)
    end
end

local keybind = {
    key = 'Ctrl+r',
    name = 'import_root_drives',
    command = import_drives,
    parser = 'root',
    passthrough = true
}

return {
    version = '1.4.0',
    setup = import_drives,
    keybinds = { keybind }
}
