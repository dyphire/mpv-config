--[[
    * adevice-list.lua v.2022-06-25
    *
    * AUTHORS: dyphire
    * License: MIT
    * link: https://github.com/dyphire/mpv-scripts

    This script implements an interractive audio-device list

    This script needs to be used with scroll-list.lua
    https://github.com/dyphire/mpv-scroll-list
]]

local mp = require 'mp'
local opts = require("mp.options")

local o = {
    header = "Adevice List [%cursor%/%total%]\\N ------------------------------------",
    wrap = true,
    key_scroll_down = "DOWN WHEEL_DOWN",
    key_scroll_up = "UP WHEEL_UP",
    key_open_adevice = "ENTER MBTN_LEFT",
    key_close_browser = "ESC MBTN_RIGHT",
}

opts.read_options(o)

--adding the source directory to the package path and loading the module
local list = dofile(mp.command_native({"expand-path", "~~/script-modules/scroll-list.lua"}))

--modifying the list settings
list.header = o.header
list.wrap = o.wrap

--jump to the selected audio-device
local function open_adevice()
    local adeviceList = mp.get_property_native('audio-device-list', {})
    if list.list[list.selected] then
        local i = list.selected
        mp.set_property("audio-device", adeviceList[i].name)
    end
end

--update the list when the current audio-device changes
local function adevice_list()
    list.list = {}
    local adeviceList = mp.get_property_native('audio-device-list', {})
    for i = 1, #adeviceList do
        local item = {}
        if (i == list.selected) then
            current_name = adeviceList[i].name
            item.style = [[{\c&H33ff66&}]]
            item.ass = "■ " .. list.ass_escape(adeviceList[i].description)
        else
            item.ass = "□ " .. list.ass_escape(adeviceList[i].description)
        end
        list.list[i] = item
    end
    list:update()
end

--dynamic keybinds to bind when the list is open
list.keybinds = {}

local function add_keys(keys, name, fn, flags)
    local i = 1
    for key in keys:gmatch("%S+") do
      table.insert(list.keybinds, {key, name..i, fn, flags})
      i = i + 1
    end
end

add_keys(o.key_scroll_down, 'scroll_down', function() list:scroll_down() end, {repeatable = true})
add_keys(o.key_scroll_up, 'scroll_up', function() list:scroll_up() end, {repeatable = true})
add_keys(o.key_open_adevice, 'open_adevice', open_adevice, {})
add_keys(o.key_close_browser, 'close_browser', function() list:close() end, {})

mp.observe_property('audio-device', 'string', adevice_list)
mp.observe_property('audio-device-list', 'string', function()
    local adeviceList = mp.get_property_native('audio-device-list', {})
    local i = list.selected
    if string.match(adeviceList[i].name, current_name) == nil then list.selected = 0 end
    for s = 1, #adeviceList do
        if adeviceList[s].name == current_name then list.selected = s end
    end
    adevice_list()
end)

mp.register_script_message("toggle-adevice-browser", function() list:toggle() end)