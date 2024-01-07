-- Copyright (c) 2023 tsl0922. All rights reserved.
-- SPDX-License-Identifier: GPL-2.0-only
--
-- #@keyword support for dynamic menu
--
-- supported keywords:
--   #@tracks:   video/audio/sub tracks
--   #@tracks/video:         video track list
--   #@tracks/audio:         audio track list
--   #@tracks/sub:           subtitle list
--   #@tracks/sub-secondary: subtitle list (secondary)
--   #@chapters:             chapter list
--   #@editions:             edition list
--   #@audio-devices:        audio device list

local opts = require('mp.options')

local o = {
    max_title_length = 80,        -- limit the title length, set to 0 to disable.
}
opts.read_options(o)

local menu_prop = 'user-data/menu/items'
local menu_items = mp.get_property_native(menu_prop, {})

local function escape_codec(str)
    if not str or str == '' then return '' end
    if str:find("mpeg2") then return "mpeg2"
    elseif str:find("dvvideo") then return "dv"
    elseif str:find("pcm") then return "pcm"
    elseif str:find("pgs") then return "pgs"
    elseif str:find("subrip") then return "srt"
    elseif str:find("vtt") then return "vtt"
    elseif str:find("dvd_sub") then return "vob"
    elseif str:find("dvb_sub") then return "dvb"
    elseif str:find("dvb_tele") then return "teletext"
    elseif str:find("arib") then return "arib"
    else return str end
end

local function abbr_title(str)
    if not str or str == '' then return '' end
    if o.max_title_length > 0 and str:len() > o.max_title_length then
        return str:sub(1, o.max_title_length) .. '...'
    end
    return str
end

local function build_track_title(track, prefix, filename)
    local title = track.title or ''
    local codec = escape_codec(track.codec)
    local type = track.type

    if track.external and title ~= '' then
        if filename ~= '' then title = title:gsub(filename .. '%.?', '') end
        if title:lower() == codec:lower() then title = '' end
    end
    if title ~= '' then
        title = abbr_title(title)
    else
        local name = type:sub(1, 1):upper() .. type:sub(2, #type)
        title = string.format('%s %02.f', name, track.id)
    end

    local hints = {}
    local function h(value) hints[#hints + 1] = value end
    if codec ~= '' then h(codec) end
    if track['demux-h'] then
        h(track['demux-w'] and (track['demux-w'] .. 'x' .. track['demux-h'] or track['demux-h'] .. 'p'))
    end
    if track['demux-fps'] then h(string.format('%.3g fps', track['demux-fps'])) end
    if track['audio-channels'] then h(track['audio-channels'] .. ' ch') end
    if track['demux-samplerate'] then h(string.format('%.3g kHz', track['demux-samplerate'] / 1000)) end
    if track['demux-bitrate'] then h(string.format('%.3g kbps', track['demux-bitrate'] / 1000)) end
    if #hints > 0 then title = string.format('%s [%s]', title, table.concat(hints, ', ')) end

    if track.forced then title = title .. ' (Forced)' end
    if track.external then title = title .. ' (External)' end
    if track.default then title = title .. ' (*)' end

    if track.lang then title = string.format('%s\t%s', title, track.lang:upper()) end
    if prefix then title = string.format('%s: %s', type:sub(1, 1):upper(), title) end
    return title
end

local function build_track_items(list, type, prop, prefix)
    local items = {}

    local filename = mp.get_property('filename/no-ext', ''):gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
    local pos = mp.get_property_number(prop, -1)
    for _, track in ipairs(list) do
        if track.type == type then
            local state = {}
            if track.selected then
                table.insert(state, 'checked')
                if track.id ~= pos then table.insert(state, 'disabled') end
            end

            items[#items + 1] = {
                title = build_track_title(track, prefix, filename),
                cmd = string.format('set %s %d', prop, track.id),
                state = state,
            }
        end
    end

    if #items > 0 then
        local title = pos > 0 and 'Off' or 'Auto'
        local value = pos > 0 and 'no' or 'auto'
        if prefix then title = string.format('%s: %s', type:sub(1, 1):upper(), title) end

        items[#items + 1] = {
            title = title,
            cmd = string.format('set %s %s', prop, value),
        }
    end

    return items
end

local function update_tracks_menu(submenu)
    mp.observe_property('track-list', 'native', function(_, track_list)
        if not track_list then return end
        for i = #submenu, 1, -1 do table.remove(submenu, i) end

        local items_v = build_track_items(track_list, 'video', 'vid', true)
        local items_a = build_track_items(track_list, 'audio', 'aid', true)
        local items_s = build_track_items(track_list, 'sub', 'sid', true)

        for _, item in ipairs(items_v) do table.insert(submenu, item) end
        if #submenu > 0 and #items_a > 0 then table.insert(submenu, { type = 'separator' }) end
        for _, item in ipairs(items_a) do table.insert(submenu, item) end
        if #submenu > 0 and #items_s > 0 then table.insert(submenu, { type = 'separator' }) end
        for _, item in ipairs(items_s) do table.insert(submenu, item) end

        mp.set_property_native(menu_prop, menu_items)
    end)
end

local function update_track_menu(submenu, type, prop)
    mp.observe_property('track-list', 'native', function(_, track_list)
        if not track_list then return end
        for i = #submenu, 1, -1 do table.remove(submenu, i) end

        local items = build_track_items(track_list, type, prop, false)
        for _, item in ipairs(items) do table.insert(submenu, item) end

        mp.set_property_native(menu_prop, menu_items)
    end)
end

local function update_chapters_menu(submenu)
    mp.observe_property('chapter-list', 'native', function(_, chapter_list)
        if not chapter_list then return end
        for i = #submenu, 1, -1 do table.remove(submenu, i) end

        local pos = mp.get_property_number('chapter', -1)
        for id, chapter in ipairs(chapter_list) do
            local title = abbr_title(chapter.title)
            if title == '' then title = 'Chapter ' .. string.format('%02.f', id) end
            local time = string.format('%02d:%02d:%02d', chapter.time / 3600, chapter.time / 60 % 60, chapter.time % 60)

            submenu[#submenu + 1] = {
                title = string.format('%s\t[%s]', title, time),
                cmd = string.format('seek %f absolute', chapter.time),
                state = id == pos + 1 and { 'checked' } or {},
            }
        end

        mp.set_property_native(menu_prop, menu_items)
    end)

    mp.observe_property('chapter', 'number', function(_, pos)
        if not pos then pos = -1 end
        for id, item in ipairs(submenu) do
            item.state = id == pos + 1 and { 'checked' } or {}
        end
        mp.set_property_native(menu_prop, menu_items)
    end)
end

local function update_editions_menu(submenu)
    mp.observe_property('edition-list', 'native', function(_, edition_list)
        if not edition_list then return end
        for i = #submenu, 1, -1 do table.remove(submenu, i) end

        local current = mp.get_property_number('current-edition', -1)
        for id, edition in ipairs(edition_list) do
            local title = abbr_title(edition.title)
            if title == '' then title = 'Edition ' .. string.format('%02.f', id) end
            if edition.default then title = title .. ' [default]' end
            submenu[#submenu + 1] = {
                title = title,
                cmd = string.format('set edition %d', id - 1),
                state = id == current + 1 and { 'checked' } or {},
            }
        end

        mp.set_property_native(menu_prop, menu_items)
    end)

    mp.observe_property('current-edition', 'number', function(_, pos)
        if not pos then pos = -1 end
        for id, item in ipairs(submenu) do
            item.state = id == pos + 1 and { 'checked' } or {}
        end
        mp.set_property_native(menu_prop, menu_items)
    end)
end

local function update_audio_devices_menu(submenu)
    mp.observe_property('audio-device-list', 'native', function(_, device_list)
        if not device_list then return end
        for i = #submenu, 1, -1 do table.remove(submenu, i) end

        local current = mp.get_property('audio-device', '')
        for _, device in ipairs(device_list) do
            submenu[#submenu + 1] = {
                title = device.description or device.name,
                cmd = string.format('set audio-device %s', device.name),
                state = device.name == current and { 'checked' } or {},
            }
        end

        mp.set_property_native(menu_prop, menu_items)
    end)

    mp.observe_property('audio-device', 'string', function(_, name)
        if not name then name = '' end
        for _, item in ipairs(submenu) do
            item.state = item.cmd:match('%s*set audio%-device%s+(%S+)%s*$') == name and { 'checked' } or {}
        end
        mp.set_property_native(menu_prop, menu_items)
    end)
end

local file_scope_dyn_menus = {}

local function dyn_menu_update(item, keyword)
    item.type = 'submenu'
    item.submenu = {}
    item.cmd = nil

    if keyword == 'tracks' then
        update_tracks_menu(item.submenu)
    elseif keyword == 'tracks/video' then
        update_track_menu(item.submenu, "video", "vid")
    elseif keyword == 'tracks/audio' then
        update_track_menu(item.submenu, "audio", "aid")
    elseif keyword == 'tracks/sub' then
        update_track_menu(item.submenu, "sub", "sid")
    elseif keyword == 'tracks/sub-secondary' then
        update_track_menu(item.submenu, "sub", "secondary-sid")
    elseif keyword == 'chapters' then
        update_chapters_menu(item.submenu)
    elseif keyword == 'editions' then
        update_editions_menu(item.submenu)
    elseif keyword == 'audio-devices' then
        update_audio_devices_menu(item.submenu)
    end

    if keyword ~= 'audio-devices' then
        file_scope_dyn_menus[#file_scope_dyn_menus + 1] = item.submenu
    end
end

local function dyn_menu_check(items)
    if not items then return end
    for _, item in ipairs(items) do
        if item.type == 'submenu' then
            dyn_menu_check(item.submenu)
        else
            if item.type ~= 'separator' and item.cmd then
                local keyword = item.cmd:match('%s*#@([%S]+).-%s*$') or ''
                if keyword ~= '' then dyn_menu_update(item, keyword) end
            end
        end
    end
end

local function dyn_menu_init()
    dyn_menu_check(menu_items)

    if #file_scope_dyn_menus > 0 then
        mp.register_event('end-file', function()
            for _, submenu in ipairs(file_scope_dyn_menus) do
                for i = #submenu, 1, -1 do table.remove(submenu, i) end
            end
            mp.set_property_native(menu_prop, menu_items)
        end)
    end

    mp.set_property_native(menu_prop, menu_items)
end

local function update_menu(name, items)
    if not items or #items == 0 then return end
    mp.unobserve_property(update_menu)

    menu_items = items
    dyn_menu_init()
end

if #menu_items > 0 then
    dyn_menu_init()
else
    mp.observe_property(menu_prop, 'native', update_menu)
end
