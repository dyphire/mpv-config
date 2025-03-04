--[[
    This script implements an interractive chapter list
    Usage: add bindings to input.conf
    -- key script-message-to chapter_list toggle-chapter-browser

    This script was written as an example for the mpv-scroll-list api
    https://github.com/CogentRedTester/mpv-scroll-list
]]

local msg = require 'mp.msg'
local opts = require("mp.options")

local o = {
    -- header of the list
    -- %cursor% and %total% to be used to display the cursor position and the total number of lists
    header = "Chapter List [%cursor%/%total%]\\N ------------------------------------",
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
    indent = [[\h\h\h]],
    --amount of entries to show before slicing. Optimal value depends on font/video size etc.
    num_entries = 16,
    --slice long filenames, and how many chars to show
    max_title_length = 100,
    -- wrap the cursor around the top and bottom of the list
    wrap = true,
    -- set dynamic keybinds to bind when the list is open
    key_move_begin = "HOME",
    key_move_end = "END",
    key_move_pageup = "PGUP",
    key_move_pagedown = "PGDWN",
    key_scroll_down = "DOWN WHEEL_DOWN",
    key_scroll_up = "UP WHEEL_UP",
    key_open_chapter = "ENTER MBTN_LEFT",
    key_close_browser = "ESC MBTN_RIGHT",
    key_remove_chapter = "DEL BS",
    key_edit_chapter = "e E",
    -- pause the playback when editing for chapter title
    pause_on_input = true,
}

opts.read_options(o)

local reset_curr = true
local paused = false

--adding the source directory to the package path and loading the module
package.path = mp.command_native({"expand-path", "~~/script-modules/?.lua;"}) .. package.path
local list = require "scroll-list"

local input_loaded, input = pcall(require, "mp.input")
-- Requires: https://github.com/CogentRedTester/mpv-user-input
local user_input_loaded, user_input = pcall(require, "user-input-module")

--modifying the list settings
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

-- from http://lua-users.org/wiki/LuaUnicode
local UTF8_PATTERN = '[%z\1-\127\194-\244][\128-\191]*'

-- return a substring based on utf8 characters
-- like string.sub, but negative index is not supported
local function utf8_sub(s, i, j)
    if i > j then
        return s
    end

    local t = {}
    local idx = 1
    for char in s:gmatch(UTF8_PATTERN) do
        if i <= idx and idx <= j then
            local width = #char > 2 and 2 or 1
            idx = idx + width
            t[#t + 1] = char
        end
    end
    return table.concat(t)
end

--update the list when the current chapter changes
local function chapter_list()
    mp.observe_property('chapter-list', 'native', function(_, chapter_list)
        mp.observe_property('chapter', 'number', function(_, curr_chapter)
            list.list = {}
            for i = 1, #chapter_list do
                local item = {}
                if curr_chapter and i == curr_chapter + 1 then
                    if reset_curr then list.selected = i end
                    item.style = o.active_style
                end
        
                local time = chapter_list[i].time
                local title = chapter_list[i].title
                if not title or title == '(unnamed)' or title == '' then
                    title = "Chapter " .. string.format("%02.f", i)
                end
                local title_clip = utf8_sub(title, 1, o.max_title_length)
                if title ~= title_clip then
                    title = title_clip .. "..."
                end
                if time < 0 then time = 0
                else time = math.floor(time) end
                item.ass = string.format("[%02d:%02d:%02d]", math.floor(time / 60 / 60), math.floor(time / 60) % 60, time % 60)
                item.ass = item.ass .. '\\h\\h\\h' .. list.ass_escape(title)
                list.list[i] = item
            end
            list:update()
        end)
    end)
    list:toggle()
end

local function change_chapter_list(chapter_tltle, chapter_index)
    local chapter_list = mp.get_property_native("chapter-list")

    if chapter_index > mp.get_property_number("chapter-list/count") then
        msg.warn("can't set chapter title")
        return
    end

    chapter_list[chapter_index].title = chapter_tltle
    mp.set_property_native("chapter-list", chapter_list)
end

local function change_title_callback(user_input, err, chapter_index)
    if user_input == nil or err ~= nil then
        if paused then return elseif o.pause_on_input then mp.set_property_native("pause", false) end
        msg.warn("no chapter title provided:", err)
        return
    end
    change_chapter_list(user_input, chapter_index)
    if paused then return elseif o.pause_on_input then mp.set_property_native("pause", false) end
end

local function input_title(default_input, cursor_pos, chapter_index)
    input.get({
        prompt = 'Chapter title:',
        default_text = default_input,
        cursor_position = cursor_pos,
        submit = function(text)
            input.terminate()
            change_chapter_list(text, chapter_index)
        end,
        closed = function()
            if paused then return elseif o.pause_on_input then mp.set_property_native("pause", false) end
        end
    })
end

--edit the selected chapter title
local function edit_chapter()
    reset_curr = false
    local chapter_index = list.selected
    local chapter_list = mp.get_property_native("chapter-list", {})

    if #chapter_list == 0 then
        msg.verbose("no chapter selected, nothing to edit")
        return
    end

    if not input_loaded and not user_input_loaded then
        msg.error("no mpv-user-input, can't get user input, install: https://github.com/CogentRedTester/mpv-user-input")
        return
    end

    local title = chapter_list[chapter_index].title
    if input_loaded then
        input_title(title, #title + 1, chapter_index)
    elseif user_input_loaded then
        -- ask user for chapter title
        -- (+1 because mpv indexes from 0, lua from 1)
        user_input.get_user_input(change_title_callback, {
            request_text = "Chapter title:",
            default_input = title,
            cursor_pos = #title + 1,
        }, chapter_index)
    end

    if o.pause_on_input then
        paused = mp.get_property_native("pause")
        mp.set_property_bool("pause", true)
        -- FIXME: for whatever reason osd gets hidden when we pause the
        -- playback like that, workaround to make input prompt appear
        -- right away without requiring mouse or keyboard action
        mp.osd_message(" ", 0.1)
    end
end

--remove the selected chapter
local function remove_chapter()
    local chapter_list = mp.get_property_native("chapter-list")
    if list.selected > 0 then
        reset_curr = false
        table.remove(chapter_list, list.selected)
        msg.debug("removing chapter", list.selected)
        mp.set_property_native("chapter-list", chapter_list)
    end
end

--jump to the selected chapter
local function open_chapter()
    if list.list[list.selected] then
        mp.set_property_number('chapter', list.selected - 1)
    end
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
add_keys(o.key_open_chapter, 'open_chapter', open_chapter, {})
add_keys(o.key_close_browser, 'close_browser', function() list:close() end, {})
add_keys(o.key_remove_chapter, 'remove_chapter', remove_chapter, {})
add_keys(o.key_edit_chapter, 'edit_chapter', edit_chapter, {})

mp.register_script_message("toggle-chapter-browser", chapter_list)

if user_input_loaded and not input_loaded then
    mp.add_hook("on_unload", 50, function() user_input.cancel_user_input() end)
end

mp.register_event('end-file', function()
    list:close()
    mp.unobserve_property(chapter_list)
end)