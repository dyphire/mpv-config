--[[
    * adevice-list.lua v.2023-02-05
    *
    * AUTHORS: dyphire
    * License: MIT
    * link: https://github.com/dyphire/mpv-scripts

    This script implements an interractive audio-device list
    Usage: add bindings to input.conf
    -- key script-message-to adevice_list toggle-adevice-browser

    This script needs to be used with scroll-list.lua
    https://github.com/CogentRedTester/mpv-scroll-list
]]

local mp = require 'mp'
local opts = require("mp.options")

local o = {
    -- header of the list
    -- %cursor% and %total% to be used to display the cursor position and the total number of lists
    header = "Adevice List [%cursor%/%total%]\\N ------------------------------------",
    --list ass style overrides inside curly brackets
    --these styles will be used for the whole list. so you need to reset them for every line
    --read http://docs.aegisub.org/3.2/ASS_Tags/ for reference of tags
    global_style = [[]],
    header_style = [[{\q2\fs30\c&00ccff&}]],
    list_style = [[{\q2\fs20\c&Hffffff&}]],
    wrapper_style = [[{\c&00ccff&\fs16}]],
    cursor_style = [[{\c&00ccff&}]],
    selected_style = [[{\c&Hfce788&}]],
    active_style = [[{\c&H33ff66&}]],
    cursor = [[➤\h]],
    indent = [[\h\h\h\h]],
    --amount of entries to show before slicing. Optimal value depends on font/video size etc.
    num_entries = 16,
    -- wrap the cursor around the top and bottom of the list
    wrap = true,
    -- reset cursor navigation when open the list
    reset_cursor_on_close = true,
    -- set dynamic keybinds to bind when the list is open
    key_move_begin = "HOME",
    key_move_end = "END",
    key_move_pageup = "PGUP",
    key_move_pagedown = "PGDWN",
    key_scroll_down = "DOWN WHEEL_DOWN",
    key_scroll_up = "UP WHEEL_UP",
    key_open_adevice = "ENTER MBTN_LEFT",
    key_close_browser = "ESC MBTN_RIGHT",
}

opts.read_options(o)

--adding the source directory to the package path and loading the module
package.path = mp.command_native({"expand-path", "~~/script-modules/?.lua;"}) .. package.path
local list = require "scroll-list"

--modifying the list settings
local original_open = list.open
list.header = o.header
list.cursor = o.cursor
list.indent = o.indent
list.wrap = o.wrap
list.num_entries = o.num_entries
list.global_style = o.global_style
list.header_style = o.header_style
list.list_style = o.list_style
list.wrapper_style = o.wrapper_style
list.cursor_style = o.cursor_style
list.selected_style = o.selected_style

--escape header specifies the format
--display the cursor position and the total number of lists in the header
function list:format_header_string(str)
    if #list.list > 0 then
        str = str:gsub("%%(%a+)%%", { cursor = list.selected, total = #list.list })
    else str = str:gsub("%[.*%]", "") end
    return str
end

--update the list when the current audio-device changes
local function adevice_list()
    list.list = {}
    local adeviceList = mp.get_property_native('audio-device-list', {})
    for i = 1, #adeviceList do
        local item = {}
        if (i == list.selected) then
            current_name = adeviceList[i].name
            item.style = o.active_style
            item.ass = "■ " .. list.ass_escape(adeviceList[i].description)
        else
            item.ass = "□ " .. list.ass_escape(adeviceList[i].description)
        end
        list.list[i] = item
    end
    list:update()
end

--open to the selected audio-device
local function open_adevice()
    local adeviceList = mp.get_property_native('audio-device-list', {})
    if list.list[list.selected] then
        mp.set_property("audio-device", adeviceList[list.selected].name)
    end
end

--reset cursor navigation when open the list
local function reset_cursor()
    local adeviceList = mp.get_property_native('audio-device-list', {})
    if current_name ~= nil and list.selected > 0 then
        if string.match(adeviceList[list.selected].name, current_name) == nil then
            list.selected = 0
        end
    end
    for s = 1, #adeviceList do
        if current_name ~= nil then
            if adeviceList[s].name == current_name then list.selected = s end
        end
    end
    if o.reset_cursor_on_close and list.selected > 0 then
        list:update()
    end
end

function list:open()
    reset_cursor()
    original_open(self)
end

--dynamic keybinds to bind when the list is open
list.keybinds = {}

local function add_keys(keys, name, fn, flags)
    local i = 1
    for key in keys:gmatch("%S+") do
        table.insert(list.keybinds, { key, name .. i, fn, flags })
        i = i + 1
    end
end

add_keys(o.key_scroll_down, 'scroll_down', function() list:scroll_down() end, { repeatable = true })
add_keys(o.key_scroll_up, 'scroll_up', function() list:scroll_up() end, { repeatable = true })
add_keys(o.key_move_pageup, 'move_pageup', function() list:move_pageup() end, {})
add_keys(o.key_move_pagedown, 'move_pagedown', function() list:move_pagedown() end, {})
add_keys(o.key_move_begin, 'move_begin', function() list:move_begin() end, {})
add_keys(o.key_move_end, 'move_end', function() list:move_end() end, {})
add_keys(o.key_open_adevice, 'open_adevice', open_adevice, {})
add_keys(o.key_close_browser, 'close_browser', function() list:close() end, {})

mp.observe_property('audio-device', 'string', adevice_list)
mp.observe_property('audio-device-list', 'string', function()
    reset_cursor()
    adevice_list()
end)

mp.register_script_message("toggle-adevice-browser", function() list:toggle() end)
