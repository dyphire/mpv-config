--[[
    This script implements an interractive chapter list
    Usage: add bindings to input.conf
    -- key script-message-to chapter_list toggle-chapter-browser

    This script was written as an example for the mpv-scroll-list api
    https://github.com/CogentRedTester/mpv-scroll-list
]]

local mp = require 'mp'
local opts = require("mp.options")

local o = {
    -- header of the list
    -- %cursor% and %total% to be used to display the cursor position and the total number of lists
    header = "Chapter List [%cursor%/%total%]\\N ------------------------------------",
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
    key_open_chapter = "ENTER MBTN_LEFT",
    key_close_browser = "ESC MBTN_RIGHT",
}

opts.read_options(o)

--adding the source directory to the package path and loading the module
local list = dofile(mp.command_native({"expand-path", "~~/script-modules/scroll-list.lua"}))

--modifying the list settings
local original_open = list.open
list.header = o.header
list.wrap = o.wrap

--escape header specifies the format
--display the cursor position and the total number of lists in the header
function list:format_header_string(str)
    if #list.list > 0 then
        str = str:gsub("%%(%a+)%%", { cursor = list.selected, total = #list.list })
    else str = str:gsub("%[.*%]", "") end
    return str
end

--update the list when the current chapter changes
mp.observe_property('chapter', 'number', function(_, curr_chapter)
    list.list = {}
    local chapter_list = mp.get_property_native('chapter-list', {})
    for i = 1, #chapter_list do
        local item = {}
        if (i - 1 == curr_chapter) then
            list.selected = curr_chapter + 1
            item.style = [[{\c&H33ff66&}]]
        end

        local time = chapter_list[i].time
        local title = chapter_list[i].title
        if title == "" then title = "Chapter " .. string.format("%02.f", i) end
        if time < 0 then time = 0
        else time = math.floor(time) end
        item.ass = string.format("[%02d:%02d:%02d]", math.floor(time/60/60), math.floor(time/60)%60, time%60)
        item.ass = item.ass..'\\h\\h\\h'..list.ass_escape(title)
        list.list[i] = item
    end
    list:update()
end)

--jump to the selected chapter
local function open_chapter()
    if list.list[list.selected] then
        mp.set_property_number('chapter', list.selected - 1)
    end
end

--reset cursor navigation when open the list
local function reset_cursor()
    if o.reset_cursor_on_close then
        if mp.get_property('chapter') then
            list.selected = mp.get_property_number('chapter') + 1
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
add_keys(o.key_open_chapter, 'open_chapter', open_chapter, {})
add_keys(o.key_close_browser, 'close_browser', function() list:close() end, {})

mp.register_script_message("toggle-chapter-browser", function() list:toggle() end)