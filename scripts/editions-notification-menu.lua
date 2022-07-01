--[[
    SOURCE_: https://github.com/CogentRedTester/mpv-scripts
    Modify_: https://github.com/dyphire/mpv-scripts
    
    Shows a notification when the file loads if it has multiple editions
    switches the osd-playing-message to show the list of editions to allow for better edition navigation

    This script also implements an interractive track list
    Usage: add bindings to input.conf
    -- key script-message-to editions_notification_menu toggle-edition-browser

    This script needs to be used with scroll-list.lua
    https://github.com/dyphire/mpv-scroll-list
]]--

local msg = require 'mp.msg'
local mp = require 'mp'
local opts = require("mp.options")

local o = {
    -- set the delay for displaying OSD information in seconds
    timeout = 3,
    -- header of the list
    -- %cursor% and %total% to be used to display the cursor position and the total number of lists
    header = "Edition List [%cursor%/%total%]\\N ------------------------------------",
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
local list = dofile(mp.command_native({"expand-path", "~~/script-modules/scroll-list.lua"}))

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
list.wrap = o.wrap

--escape header specifies the format
--display the cursor position and the total number of lists in the header
function list:format_header_string(string)
    if #list.list > 0 then
        string = string:gsub("%%cursor%%", list.selected)
		:gsub("%%total%%", #list.list)
    else string = string:gsub("%[.*%]", "") end
    return string
end

--update the list when the current edition changes
mp.observe_property('current-edition', 'number', function(_, curr_edition)
    list.list = {}
    local edition_list = mp.get_property_native('edition-list', {})
    for i = 1, #edition_list do
        local item = {}
        if (i - 1 == curr_edition) then
            list.selected = curr_edition + 1
            item.style = [[{\c&H33ff66&}]]
            item.ass = "● " .. (edition_list[i].title and list.ass_escape(edition_list[i].title) or "Edition " .. string.format("%02.f", i))
        else
            item.ass = "○ " .. (edition_list[i].title and list.ass_escape(edition_list[i].title) or "Edition " .. string.format("%02.f", i))
        end
        list.list[i] = item
    end
    list:update()
end)

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
      table.insert(list.keybinds, {key, name..i, fn, flags})
      i = i + 1
    end
end

add_keys(o.key_scroll_down, 'scroll_down', function() list:scroll_down() end, {repeatable = true})
add_keys(o.key_scroll_up, 'scroll_up', function() list:scroll_up() end, {repeatable = true})
add_keys(o.key_move_pageup, 'move_pageup', function() list:move_pageup() end, {})
add_keys(o.key_move_pagedown, 'move_pagedown', function() list:move_pagedown() end, {})
add_keys(o.key_move_begin, 'move_begin', function() list:move_begin() end, {})
add_keys(o.key_move_end, 'move_end', function() list:move_end() end, {})
add_keys(o.key_select_edition, 'select_edition', select_edition, {})
add_keys(o.key_close_browser, 'close_browser', function() list:close() end, {})

mp.register_script_message("toggle-edition-browser", function() list:toggle() end)

mp.observe_property('current-edition', nil, editionChanged)

mp.register_event('file-loaded', main)
