--[[
    SOURCE_: https://github.com/CogentRedTester/mpv-scripts
    Modify_: https://github.com/dyphire/mpv-scripts
    
    Shows a notification when the file loads if it has multiple editions
    switches the osd-playing-message to show the list of editions to allow for better edition navigation

    This script also implements an interractive track list
    Usage: add bindings to input.conf
    -- key script-message-to edition_list toggle-edition-browser

    This script needs to be used with scroll-list.lua
    https://github.com/CogentRedTester/mpv-scroll-list
]] --

local msg = require 'mp.msg'
local mp = require 'mp'
local opts = require("mp.options")

local o = {
    -- set the delay for displaying OSD information in seconds
    timeout = 3,
    -- header of the list
    -- %cursor% and %total% to be used to display the cursor position and the total number of lists
    header = "Edition List [%cursor%/%total%]\\N ------------------------------------",
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
    --slice long filenames, and how many chars to show
    slice_longfilenames_amount = 100,
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
    key_select_edition = "ENTER MBTN_LEFT",
    key_close_browser = "ESC MBTN_RIGHT",
}

opts.read_options(o)

--adding the source directory to the package path and loading the module
package.path = mp.command_native({"expand-path", "~~/script-modules/?.lua;"}) .. package.path
local list = require "scroll-list"

playingMessage = mp.get_property('options/osd-playing-msg')
editionSwitching = false
lastFilename = ""

--shows a message on the OSD if the file has editions
function showNotification()
    local editions = mp.get_property_number('editions', 0)

    --if there are no editions (or 1 dummy edition) then exit the function
    if editions < 2 then return end

    local time = mp.get_time()
    while (mp.get_time() - time < 1) do

    end
    mp.add_timeout(o.timeout, function()
        mp.osd_message('file has ' .. editions .. ' editions', '2')
    end)
end

--The script remembers the first time the edition is switched using mp.observe_property, and afterwards always displays the edition-list on each file-loaded
--event, instead of the default osd-playting-msg. The script needs to compare the filenames each time in order to test when a new file has been loaded.
--When this happens it resets the editionSwitching boolean and displays the original osd-playing-message.
--This process is necessary because there seems to be no way to differentiate between a new file being loaded and a new edition being loaded
function main()
    local edition = mp.get_property_number('current-edition')

    --resets editionSwitching boolean and sets the new filename
    if lastFilename ~= mp.get_property('filename') then
        changedFile()
        lastFilename = mp.get_property('filename')

        --if the file is new then it runs then notification function
        showNotification()
    end

    if (editionSwitching == false or edition == nil) then
        mp.set_property('options/osd-playing-msg', playingMessage)
    else
        mp.set_property('options/osd-playing-msg', '${edition-list}')
    end
end

--logs when the edition is changed
function editionChanged()
    msg.log('v', 'edition changed')
    editionSwitching = true
end

--resets the edition switch boolean on a file change
function changedFile()
    msg.log('v', 'switched file')
    editionSwitching = false
end

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

--update the list when the current edition changes
function edition_list(curr_edition)
    list.list = {}
    local edition_list = mp.get_property_native('edition-list', {})
    for i = 1, #edition_list do
        local item = {}
        local title = edition_list[i].title
        if not title then title = "Edition " .. string.format("%02.f", i) end
        if title and title:len() > o.slice_longfilenames_amount + 5 then
            title = title:sub(1, o.slice_longfilenames_amount) .. " ..."
        end
        if (i - 1 == curr_edition) then
            list.selected = curr_edition + 1
            item.style = o.active_style
            item.ass = "● " .. list.ass_escape(title)
        else
            item.ass = "○ " .. list.ass_escape(title)
        end
        list.list[i] = item
    end
    list:update()
end

--jump to the selected edition
local function select_edition()
    if list.list[list.selected] then
        mp.set_property_number('edition', list.selected - 1)
    end
end

--reset cursor navigation when open the list
local function reset_cursor()
    if o.reset_cursor_on_close then
        if mp.get_property('editions') then
            list.selected = mp.get_property_number('current-edition') + 1
            list:update()
        end
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
add_keys(o.key_select_edition, 'select_edition', select_edition, {})
add_keys(o.key_close_browser, 'close_browser', function() list:close() end, {})

mp.register_script_message("toggle-edition-browser", function() list:toggle() end)

mp.observe_property('current-edition', 'number', function(_, curr_edition)
    editionChanged()
    edition_list(curr_edition)
end)

mp.observe_property('edition-list', 'native', function()
    local curr_edition = mp.get_property_number("current-edition")
    if curr_edition then edition_list(curr_edition) end
end)

mp.register_event('file-loaded', main)
