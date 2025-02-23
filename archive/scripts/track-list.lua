--[[
    * track-list.lua v.2024-11-11
    *
    * AUTHORS: dyphire
    * License: MIT
    * link: https://github.com/dyphire/mpv-scripts

    This script implements an interractive track list
    Usage: add bindings to input.conf
    -- key script-message-to track_list toggle-vidtrack-browser
    -- key script-message-to track_list toggle-audtrack-browser
    -- key script-message-to track_list toggle-subtrack-browser
    -- key script-message-to track_list toggle-secondary-subtrack-browser

    This script needs to be used with scroll-list.lua
    https://github.com/CogentRedTester/mpv-scroll-list
]]

local mp = require 'mp'
local opts = require("mp.options")
local propNative = mp.get_property_native

local o = {
    -- header of the list
    -- %cursor% and %total% to be used to display the cursor position and the total number of lists
    header = "Track List [%cursor%/%total%]\\N ------------------------------------",
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
    key_select_track = "ENTER MBTN_LEFT",
    key_reload_track = "F5 MBTN_MID",
    key_remove_track = "DEL BS",
    key_close_browser = "ESC MBTN_RIGHT",
}

opts.read_options(o)

--adding the source directory to the package path and loading the module
package.path = mp.command_native({"expand-path", "~~/script-modules/?.lua;"}) .. package.path
local list = require "scroll-list"
local list_type = nil

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
    if #list.list > 1 then
        str = str:gsub("%%(%a+)%%", { cursor = list.selected - 1, total = #list.list - 1 })
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

local function escape_codec(str)
    if not str or str == '' then return '' end

    local codec_map = {
        mpeg2 = "mpeg2",
        dvvideo = "dv",
        pcm = "pcm",
        pgs = "pgs",
        subrip = "srt",
        vtt = "vtt",
        dvd_sub = "vob",
        dvb_sub = "dvb",
        dvb_tele = "teletext",
        arib = "arib"
    }

    for key, value in pairs(codec_map) do
        if str:find(key) then
            return value
        end
    end

    return str
end

local function isTrackSelected(index, type)
    local selectedId = propNative("current-tracks/" .. type .. "/id")
    return selectedId == index
end

local function isTrackDisabled(index, type)
    return (type == "sub2" and isTrackSelected(index, "sub"))
    or (type == "sub" and isTrackSelected(index, "sub2"))
end

local function get_track_title(track, type, filename)
    local title = track.title or ''
    local codec = escape_codec(track.codec)

    if track.external and title ~= '' then
        local extension = title:match('%.([^%.]+)$')
        if filename ~= '' and extension then
            title = title:gsub(filename .. '%.?', ''):gsub('%.?([^%.]+)$', '')
        end
        if track.lang and title:lower() == track.lang:lower() then
            title = ''
        end
    end
    local title_clip = utf8_sub(title, 1, o.max_title_length)
    if title ~= title_clip then
        title = title_clip .. "..."
    end
    if title == '' then
        local name = type:sub(1, 1):upper() .. type:sub(2, #type)
        title = string.format('%s %02.f', name, track.id)
    end

    local hints = {}
    local function h(value) hints[#hints + 1] = value end
    if codec ~= '' then h(codec) end
    if track['demux-h'] then
        h(track['demux-w'] and (track['demux-w'] .. 'x' .. track['demux-h'] or track['demux-h'] .. 'p'))
    end
    if track['demux-fps'] then h(string.format('%.5g fps', track['demux-fps'])) end
    if track['audio-channels'] then h(track['audio-channels'] .. ' ch') end
    if track['demux-samplerate'] then h(string.format('%.3g kHz', track['demux-samplerate'] / 1000)) end
    if track['demux-bitrate'] then h(string.format('%.0f kbps', track['demux-bitrate'] / 1000)) end
    if track.lang then title = string.format('%s, %s', title, track.lang) end
    if #hints > 0 then title = string.format('%s\t[%s]', title, table.concat(hints, ', ')) end
    if track.forced then title = title .. ' Forced' end
    if track.external then title = title .. ' External' end
    if track.default then title = title .. ' (Default)' end

    return list.ass_escape(title)
end

local function updateTrackList(title, type, prop)
    list.header = title .. ": " .. o.header

    local filename = propNative('filename/no-ext', ''):gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
    local track_type = type == 'sub2' and 'sub' or type
    mp.observe_property("track-list", "native", function(_, track_list)
        mp.observe_property(prop, "native", function()
            list.list = {}
            list.list = {
                {
                    id = nil,
                    index = nil,
                    disabled = false,
                    ass = "○ None"
                }
            }

            if isTrackSelected(nil, type) then
                list.selected = 1
                list[1].ass = "● None"
                list[1].style = o.active_style
            end

            if not track_list then return end
            for _, track in ipairs(track_list) do
                if track.type == track_type then
                    local title = get_track_title(track, type, filename)
                    local isDisabled = isTrackDisabled(track.id, type)

                    local listItem = {
                        id = track.id,
                        disabled = isDisabled
                    }
                    if isTrackSelected(track.id, type) then
                        list.selected = track.id + 1
                        listItem.style = o.active_style
                        listItem.ass = "● " .. title
                    elseif isDisabled then
                        listItem.style = [[{\c&Hff6666&}]]
                        listItem.ass = "○ " .. title
                    else
                        listItem.ass = "○ " .. title
                    end
                    table.insert(list.list, listItem)
                end
            end
        
            list:update()
        end)
    end)
end

local function selectTrack()
    local selected = list.list[list.selected]
    if selected then
        if selected.disabled then return end
        if selected.id == nil then selected.id = "no" end
        mp.commandv('set', list_prop, selected.id)
    end
end

local function reloadTrack()
    local selected = list.list[list.selected]
    local track_type = list_type == 'sub2' and 'sub' or list_type
    if selected then
        if selected.id == nil then return end
        mp.commandv(track_type .. "-reload", selected.id)
    end
end

local function removeTrack()
    local selected = list.list[list.selected]
    local track_type = list_type == 'sub2' and 'sub' or list_type
    if selected then
        if selected.id == nil then return end
        mp.commandv(track_type .. "-remove", selected.id)
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
add_keys(o.key_select_track, 'select_track', selectTrack, {})
add_keys(o.key_reload_track, 'reload_track', reloadTrack, {})
add_keys(o.key_remove_track, 'remove_track', removeTrack, {})
add_keys(o.key_close_browser, 'close_browser', function() list:close() end, {})

function list:open()
    video_menu = (list_type == "video")
    audio_menu = (list_type == "audio")
    sub_menu = (list_type == "sub")
    sub2_menu = (list_type == "sub2")

    original_open(self)
end

local function toggleListDelayed()
    mp.add_timeout(0.1, function()
        list:toggle()
    end)
end

local function toggleList(type, prop)
    list_type = type
    list_prop = prop

    local function toggleMenu(menu)
        if _G[menu] then
            _G[menu] = false
        else
            toggleListDelayed()
        end
    end

    if type == "video" then
        toggleMenu("video_menu")
    elseif type == "audio" then
        toggleMenu("audio_menu")
    elseif type == "sub" then
        toggleMenu("sub_menu")
    elseif type == "sub2" then
        toggleMenu("sub2_menu")
    end
end

local function openTrackList(title, type, prop)
    list:close()
    updateTrackList(title, type, prop)
    toggleList(type, prop)
end

mp.register_script_message("toggle-vidtrack-browser", function()
    openTrackList("Video", "video", "vid")
end)
mp.register_script_message("toggle-audtrack-browser", function()
    openTrackList("Audio", "audio", "aid")
end)
mp.register_script_message("toggle-subtrack-browser", function()
    openTrackList("Subtitle", "sub", "sid")
end)
mp.register_script_message("toggle-secondary-subtrack-browser", function()
    openTrackList("Secondary Subtitle", "sub2", "secondary-sid")
end)

mp.register_event('end-file', function()
    list:close()
    mp.unobserve_property(updateTrackList)
end)
