--[[
    This file is an internal file-browser addon.
    It should not be imported like a normal module.

    Automatically populates the root with windows drives on startup.
    Ctrl+r will add new drives mounted since startup.

    Drives will only be added if they are not already present in the root.
]]

local mp = require 'mp'
local msg = require 'mp.msg'
local fb = require 'file-browser'

local PLATFORM = fb.get_platform()

---returns a list of windows drives
---@return string[]?
local function get_drives()
    ---@type MPVSubprocessResult?, string?
    local result, err = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        capture_stdout = true,
        args = {'fsutil', 'fsinfo', 'drives'}
    })
    if not result then return msg.error(err) end
    if result.status ~= 0 then return msg.error('could not read windows root') end

    local root = {}
    for drive in result.stdout:gmatch("(%a:)\\") do
        table.insert(root, drive..'/')
    end
    return root
end

-- adds windows drives to the root if they are not already present
local function import_drives()
    if fb.get_opt('auto_detect_windows_drives') and PLATFORM ~= 'windows' then return end

    local drives = get_drives()
    if not drives then return end

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

---@type ParserConfig
return {
    api_version = '1.9.0',
    setup = import_drives,
    keybinds = { keybind }
}
