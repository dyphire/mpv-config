-- Copyright (c) 2023 tsl0922. All rights reserved.
-- SPDX-License-Identifier: GPL-2.0-only

local opts = require('mp.options')
local utils = require('mp.utils')
local msg = require('mp.msg')

-- user options
local o = {
    max_title_length = 80,        -- limit the title length, set to 0 to disable.
}
opts.read_options(o)

local menu_prop = 'user-data/menu/items'
local menu_items = mp.get_property_native(menu_prop, {})
local menu_items_dirty = false
local dyn_menus = {}

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

-- from http://lua-users.org/wiki/LuaUnicode
local UTF8_PATTERN = '[%z\1-\127\194-\244][\128-\191]*'

-- return a substring based on utf8 characters
-- like string.sub, but negative index is not supported
local function utf8_sub(s, i, j)
    local t = {}
    local idx = 1
    for match in s:gmatch(UTF8_PATTERN) do
        if j and idx > j then break end
        if idx >= i then t[#t + 1] = match end
        idx = idx + 1
    end
    return table.concat(t)
end

-- abbreviate title if it's too long
local function abbr_title(str)
    if not str or str == '' then return '' end
    if o.max_title_length > 0 and str:len() > o.max_title_length then
        return utf8_sub(str, 1, o.max_title_length) .. '...'
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

-- update menu item to a submenu
local function to_submenu(item)
    item.type = 'submenu'
    item.submenu = {}
    item.cmd = nil

    menu_items_dirty = true

    return item.submenu
end

local function observe_property(menu, prop, type, fn)
    mp.observe_property(prop, type, fn)
    menu.fns[#menu.fns + 1] = fn
end

-- handle #@tracks menu update
local function update_tracks_menu(menu)
    local submenu = to_submenu(menu.item)

    local function track_list_cb(_, track_list)
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
    end

    observe_property(menu, 'track-list', 'native', track_list_cb)
end

-- handle #@tracks/<type> menu update for given type
local function update_track_menu(menu, type, prop)
    local submenu = to_submenu(menu.item)

    local function track_list_cb(_, track_list)
        for i = #submenu, 1, -1 do table.remove(submenu, i) end
        menu_items_dirty = true
        if not track_list or #track_list == 0 then return end

        local items = build_track_items(track_list, type, prop, false)
        for _, item in ipairs(items) do table.insert(submenu, item) end
    end

    observe_property(menu, 'track-list', 'native', track_list_cb)
end

-- handle #@chapters menu update
local function update_chapters_menu(menu)
    local submenu = to_submenu(menu.item)

    local function chapter_list_cb(_, chapter_list)
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
    end

    local function chapter_cb(_, pos)
        if not pos then pos = -1 end
        for id, item in ipairs(submenu) do
            item.state = id == pos + 1 and { 'checked' } or {}
        end
        menu_items_dirty = true
    end

    observe_property(menu, 'chapter-list', 'native', chapter_list_cb)
    observe_property(menu, 'chapter', 'number', chapter_cb)
end

-- handle #@edition menu update
local function update_editions_menu(menu)
    local submenu = to_submenu(menu.item)

    local function edition_list_cb(_, edition_list)
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
    end

    local function edition_cb(_, pos)
        if not pos then pos = -1 end
        for id, item in ipairs(submenu) do
            item.state = id == pos + 1 and { 'checked' } or {}
        end
        menu_items_dirty = true
    end

    observe_property(menu, 'edition-list', 'native', edition_list_cb)
    observe_property(menu, 'current-edition', 'number', edition_cb)
end

-- handle #@audio-devices menu update
local function update_audio_devices_menu(menu)
    local submenu = to_submenu(menu.item)

    local function device_list_cb(_, device_list)
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
    end

    local function device_cb(_, device)
        if not device then device = '' end
        for _, item in ipairs(submenu) do
            item.state = item.cmd:match('%s*set audio%-device%s+(%S+)%s*$') == device and { 'checked' } or {}
        end
        menu_items_dirty = true
    end

    observe_property(menu, 'audio-device-list', 'native', device_list_cb)
    observe_property(menu, 'audio-device', 'string', device_cb)
end

-- build playlist item title
local function build_playlist_title(item, id)
    local title = item.title or ''
    local ext = ''
    if item.filename and item.filename ~= '' then
        local _, filename = utils.split_path(item.filename)
        local n, e = filename:match('^(.+)%.([%w-_]+)$')
        if title == '' then title = n and n or filename end
        if e then ext = e end
    end
    title = title ~= '' and abbr_title(title) or 'Item ' .. id
    return ext ~= '' and title .. "\t" .. ext:upper() or title
end

-- handle #@playlist menu update
local function update_playlist_menu(menu)
    local submenu = to_submenu(menu.item)

    local function playlist_cb(_, playlist)
        for i = #submenu, 1, -1 do table.remove(submenu, i) end
        menu_items_dirty = true
        if not playlist or #playlist == 0 then return end

        for id, item in ipairs(playlist) do
            submenu[#submenu + 1] = {
                title = build_playlist_title(item, id - 1),
                cmd = string.format('playlist-play-index %d', id - 1),
                state = item.current and { 'checked' } or {},
            }
        end
    end

    observe_property(menu, 'playlist', 'native', playlist_cb)
end

-- handle #@profiles menu update
local function update_profiles_menu(menu)
    local submenu = to_submenu(menu.item)

    local function profile_list_cb(_, profile_list)
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
    end

    observe_property(menu, 'profile-list', 'native', profile_list_cb)
end

-- handle #@prop:check
function update_check_status(menu, prop, reverse)
    local item = menu.item

    local function check(v)
        local tp = type(v)
        if tp == 'boolean' then return v end
        if tp == 'string' then return v ~= '' end
        if tp == 'number' then return v ~= 0 end
        if tp == 'table' then return next(v) ~= nil end
        return v ~= nil
    end

    local function prop_cb(_, value)
        local ok = check(value)
        if reverse then ok = not ok end
        item.state = ok and { 'checked' } or {}
        menu_items_dirty = true
    end

    observe_property(menu, prop, 'native', prop_cb)
end

-- dynamic menu providers
local dyn_providers = {
    ['tracks'] = update_tracks_menu,
    ['tracks/video'] = function(menu) update_track_menu(menu, 'video', 'vid') end,
    ['tracks/audio'] = function(menu) update_track_menu(menu, 'audio', 'aid') end,
    ['tracks/sub'] = function(menu) update_track_menu(menu, 'sub', 'sid') end,
    ['tracks/sub-secondary'] = function(menu) update_track_menu(menu, 'sub', 'secondary-sid') end,
    ['chapters'] = update_chapters_menu,
    ['editions'] = update_editions_menu,
    ['audio-devices'] = update_audio_devices_menu,
    ['playlist'] = update_playlist_menu,
    ['profiles'] = update_profiles_menu,
}

-- update dynamic menu item and handle update
local function dyn_menu_update(item, keyword)
    local menu = {
        item = item,
        fns = {},
    }
    dyn_menus[keyword] = menu

    local prop, e = keyword:match('^([%w-]+):check(!?)$')
    if prop then
        update_check_status(menu, prop, e == '!')
    else
        local provider = dyn_providers[keyword]
        if provider then provider(menu) end
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

-- broadcast menu ready message
local function send_ready_message()
    mp.commandv('script-message', 'menu-ready')
end

-- menu data update callback
local function menu_data_cb(name, items)
    if not items or #items == 0 then return end
    mp.unobserve_property(menu_data_cb)

    menu_items = items
    dyn_menu_check(menu_items)
    send_ready_message()
end

-- script message: get <keyword> <src>
mp.register_script_message('get', function(keyword, src)
    if not src or src == '' then
        msg.warn('get: ignored message with empty src')
        return
    end

    local menu = dyn_menus[keyword]
    local reply = { keyword = keyword }
    if menu then reply.item = menu.item else reply.error = 'keyword not found' end
    mp.commandv('script-message-to', src, 'menu-get-reply', utils.format_json(reply))
end)

-- script message: update <keyword> <json>
mp.register_script_message('update', function(keyword, json)
    local menu = dyn_menus[keyword]
    if not menu then
        msg.warn('update: ignored message with invalid keyword:', keyword)
        return
    end

    local data, err = utils.parse_json(json)
    if err then msg.error('update: failed to parse json:', err) end
    if not data or next(data) == nil then
        msg.warn('update: ignored message with invalid json:', json)
        return
    end

    local item = menu.item
    if not data.title or data.title == '' then data.title = item.title end
    if not data.type or data.type == '' then data.type = item.type end

    -- remove old property observers to avoid conflicts
    if #menu.fns > 0 then
        for _, fn in ipairs(menu.fns) do mp.unobserve_property(fn) end
        menu.fns = {}
    end

    for k, _ in pairs(item) do item[k] = nil end
    for k, v in pairs(data) do item[k] = v end

    menu_items_dirty = true
end)

-- commit menu items when idle, this reduces the update frequency
mp.register_idle(function()
    if menu_items_dirty then
        mp.set_property_native(menu_prop, menu_items)
        menu_items_dirty = false
    end
end)

-- parse menu data when menu items ready
--
-- NOTE: to simplify the code, we only procss the first valid update
--       event and ignore the rest, this make it conflict with other
--       scripts that also update the menu data property.
if #menu_items > 0 then
    dyn_menu_check(menu_items)
    send_ready_message()
else
    mp.observe_property(menu_prop, 'native', menu_data_cb)
end
