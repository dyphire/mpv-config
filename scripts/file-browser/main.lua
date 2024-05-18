--[[
    mpv-file-browser

    This script allows users to browse and open files and folders entirely from within mpv.
    The script uses nothing outside the mpv API, so should work identically on all platforms.
    The browser can move up and down directories, start playing files and folders, or add them to the queue.

    For full documentation see: https://github.com/CogentRedTester/mpv-file-browser
]]--

local mp = require 'mp'

local o = require 'modules.options'
local addons = require 'modules.addons'
local keybinds = require 'modules.keybinds'
local setup = require 'modules.setup'
local controls = require 'modules.controls'
local observers = require 'modules.observers'
local script_messages = require 'modules.script-messages'

-- setting the package paths
package.path = mp.command_native({"expand-path", o.module_directory}).."/?.lua;"..package.path
local user_input_loaded, input = pcall(require, "user-input-module")

-- root and addon setup
setup.root()
addons.load_internal_parsers()
if o.addons then addons.load_external_addons() end

--these need to be below the addon setup in case any parsers add custom entries
setup.extensions_list()
keybinds.setup_keybinds()

-- property observers
mp.observe_property('path', 'string', observers.current_directory)
mp.observe_property('dvd-device', 'string', observers.dvd_device)

-- scripts messages
mp.register_script_message('=>', script_messages.chain)
mp.register_script_message('delay-command', script_messages.delay_command)
mp.register_script_message('conditional-command', script_messages.conditional_command)
mp.register_script_message('evaluate-expressions', script_messages.evaluate_expressions)
mp.register_script_message('run-statement', script_messages.run_statement)

mp.register_script_message('browse-directory', controls.browse_directory)
mp.register_script_message("get-directory-contents", script_messages.get_directory_contents)

--declares the keybind to open the browser
mp.add_key_binding('MENU','browse-files', controls.toggle)
mp.add_key_binding('Ctrl+o','open-browser', controls.open)

if user_input_loaded then
    mp.add_key_binding("Alt+o", "browse-directory/get-user-input", function()
        input.get_user_input(controls.browse_directory, {request_text = "open directory:"})
    end)
end
