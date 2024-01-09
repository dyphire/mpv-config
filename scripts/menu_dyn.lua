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
--   #@profiles:             profile list

local opts = require('mp.options')

-- user options
local o = {
    max_title_length = 80,        -- limit the title length, set to 0 to disable.
}
opts.read_options(o)

local menu_prop = 'user-data/menu/items'
local menu_items = mp.get_property_native(menu_prop, {})
local menu_items_dirty = false

-- escape codec name to make it more readable
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

-- abbreviate title if it's too long
local function abbr_title(str)
    if not str or str == '' then return '' end
    if o.max_title_length > 0 and str:len() > o.max_title_length then
        return str:sub(1, o.max_title_length) .. '...'
    end
    return str
end

-- build track title from track metadata
--
-- example:
--        V: Video 1 [h264, 1920x1080, 23.976 fps] (*)        JPN
--        |     |               |                   |          |
--       type  title          hints               default     lang
local function build_track_title(track, prefix, filename)
    local type = track.type
    local title = track.title or ''
    local lang = track.lang or ''
    local codec = escape_codec(track.codec)

    -- remove filename from title if it's external track
    if track.external and title ~= '' then
        if filename ~= '' then title = title:gsub(filename .. '%.?', '') end
        if title:lower() == codec:lower() then title = '' end
    end
    -- set a default title if it's empty
    if title == '' then
        local name = type:sub(1, 1):upper() .. type:sub(2, #type)
        title = string.format('%s %02.f', name, track.id)
    else
        title = abbr_title(title)
    end

    -- build hints from track metadata
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

    -- put some important info at the end
    if track.forced then title = title .. ' (Forced)' end
    if track.external then title = title .. ' (External)' end
    if track.default then title = title .. ' (*)' end

    -- show language at right side (\t is used to right align the text)
    if lang ~= '' then title = string.format('%s\t%s', title, lang:upper()) end
    -- prepend a 1-letter type prefix, used when displaying multiple track types
    if prefix then title = string.format('%s: %s', type:sub(1, 1):upper(), title) end
    return title
end

-- build track menu items from track list for given type
local function build_track_items(list, type, prop, prefix)
    local items = {}

    -- filename without extension, escaped for pattern matching
    local filename = mp.get_property('filename/no-ext', ''):gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
    local pos = mp.get_property_number(prop, -1)
    for _, track in ipairs(list) do
        if track.type == type then
            local state = {}
            -- there may be 2 tracks selected at the same time, for example: subtitle
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

    -- add an extra item to disable or re-enable the track
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

-- handle #@tracks menu update
local function update_tracks_menu(submenu)
    mp.observe_property('track-list', 'native', function(_, track_list)
        for i = #submenu, 1, -1 do table.remove(submenu, i) end
        menu_items_dirty = true
        if not track_list or #track_list == 0 then return end

        local items_v = build_track_items(track_list, 'video', 'vid', true)
        local items_a = build_track_items(track_list, 'audio', 'aid', true)
        local items_s = build_track_items(track_list, 'sub', 'sid', true)

        -- append video/audio/sub tracks into one submenu, separated by a separator
        for _, item in ipairs(items_v) do table.insert(submenu, item) end
        if #submenu > 0 and #items_a > 0 then table.insert(submenu, { type = 'separator' }) end
        for _, item in ipairs(items_a) do table.insert(submenu, item) end
        if #submenu > 0 and #items_s > 0 then table.insert(submenu, { type = 'separator' }) end
        for _, item in ipairs(items_s) do table.insert(submenu, item) end
    end)
end

-- handle #@tracks/<type> menu update for given type
local function update_track_menu(submenu, type, prop)
    mp.observe_property('track-list', 'native', function(_, track_list)
        for i = #submenu, 1, -1 do table.remove(submenu, i) end
        menu_items_dirty = true
        if not track_list or #track_list == 0 then return end

        local items = build_track_items(track_list, type, prop, false)
        for _, item in ipairs(items) do table.insert(submenu, item) end
    end)
end

-- handle #@chapters menu update
local function update_chapters_menu(submenu)
    mp.observe_property('chapter-list', 'native', function(_, chapter_list)
        for i = #submenu, 1, -1 do table.remove(submenu, i) end
        menu_items_dirty = true
        if not chapter_list or #chapter_list == 0 then return end

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
    end)

    mp.observe_property('chapter', 'number', function(_, pos)
        if not pos then pos = -1 end
        for id, item in ipairs(submenu) do
            item.state = id == pos + 1 and { 'checked' } or {}
        end
        menu_items_dirty = true
    end)
end

-- handle #@edition menu update
local function update_editions_menu(submenu)
    mp.observe_property('edition-list', 'native', function(_, edition_list)
        for i = #submenu, 1, -1 do table.remove(submenu, i) end
        menu_items_dirty = true
        if not edition_list or #edition_list == 0 then return end

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
    end)

    mp.observe_property('current-edition', 'number', function(_, pos)
        if not pos then pos = -1 end
        for id, item in ipairs(submenu) do
            item.state = id == pos + 1 and { 'checked' } or {}
        end
        menu_items_dirty = true
    end)
end

-- handle #@audio-devices menu update
local function update_audio_devices_menu(submenu)
    mp.observe_property('audio-device-list', 'native', function(_, device_list)
        for i = #submenu, 1, -1 do table.remove(submenu, i) end
        menu_items_dirty = true
        if not device_list or #device_list == 0 then return end

        local current = mp.get_property('audio-device', '')
        for _, device in ipairs(device_list) do
            submenu[#submenu + 1] = {
                title = device.description or device.name,
                cmd = string.format('set audio-device %s', device.name),
                state = device.name == current and { 'checked' } or {},
            }
        end
    end)

    mp.observe_property('audio-device', 'string', function(_, name)
        if not name then name = '' end
        for _, item in ipairs(submenu) do
            item.state = item.cmd:match('%s*set audio%-device%s+(%S+)%s*$') == name and { 'checked' } or {}
        end
        menu_items_dirty = true
    end)
end

-- handle #@profiles menu update
local function update_profiles_menu(submenu)
    mp.observe_property('profile-list', 'native', function(_, profile_list)
        for i = #submenu, 1, -1 do table.remove(submenu, i) end
        menu_items_dirty = true
        if not profile_list or #profile_list == 0 then return end

        for _, profile in ipairs(profile_list) do
            if not (profile.name == 'default' or profile.name:find('gui') or
                    profile.name == 'encoding' or profile.name == 'libmpv') then
                submenu[#submenu + 1] = {
                    title = profile.name,
                    cmd = string.format('show-text %s; apply-profile %s', profile.name, profile.name),
                }
            end
        end
    end)
end

-- update dynamic menu item and handle submenu update
local function dyn_menu_update(item, keyword)
    item.type = 'submenu'
    item.submenu = {}
    item.cmd = nil
    menu_items_dirty = true

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
    elseif keyword == 'profiles' then
        update_profiles_menu(item.submenu)
    end
end

-- find #@keyword for dynamic menu and handle updates
--
-- cplugin will keep the trailing comments in the cmd field, so we can
-- parse the keyword from it.
--
-- example: ignore        #menu: Chapters #@chapters    # extra comment
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

-- menu data update callback
local function update_menu(name, items)
    if not items or #items == 0 then return end
    mp.unobserve_property(update_menu)

    menu_items = items
    dyn_menu_check(menu_items)
end

-- commit menu items if changed
local function update_menu_items()
    if menu_items_dirty then
        mp.set_property_native(menu_prop, menu_items)
        menu_items_dirty = false
    end
end

-- update menu items when idle, this reduces the update frequency
mp.register_idle(update_menu_items)

-- parse menu data when menu items ready
--
-- NOTE: to simplify the code, we only procss the first valid update
--       event and ignore the rest, this make it conflict with other
--       scripts that also update the menu data property.
if #menu_items > 0 then
    dyn_menu_check(menu_items)
else
    mp.observe_property(menu_prop, 'native', update_menu)
end
