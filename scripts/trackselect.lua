--[[
    SOURCE_: https://github.com/po5/trackselect
    Modify_: https://github.com/dyphire/mpv-scripts
    
    -- Because --slang isn't smart enough.
    --
    -- This script tries to select non-dub
    -- audio and subtitle tracks.
    -- Idea from https://github.com/siikamiika/scripts/blob/master/mpv%20scripts/dualaudiofix.lua
]]

local opt = require 'mp.options'
local utils = require 'mp.utils'

local defaults = {
    audio = {
        selected = nil,
        best = {},
        lang_score = nil,
        expected_score = nil,
        channels_score = -math.huge,
        preferred = "jpn/japanese",
        excluded = "commentary/cast/staff/dub/guide",
        expected = "",
        id = ""
    },
    video = {
        selected = nil,
        best = {},
        lang_score = nil,
        expected_score = nil,
        preferred = "",
        excluded = "",
        expected = "",
        id = ""
    },
    sub = {
        selected = nil,
        best = {},
        lang_score = nil,
        expected_score = nil,
        preferred = "eng",
        excluded = "sign/song",
        expected = "",
        id = ""
    }
}

local options = {
    enabled = true,

    -- Do track selection synchronously, plays nicer with other scripts
    hook = true,

    -- Mimic mpv's track list fingerprint to preserve user-selected tracks across files
    fingerprint = false,

    -- Override user's explicit track selection
    force = false,

    -- Try to re-select the last track if mpv cannot do it e.g. when fingerprint changes
    smart_keep = false,
}

for _type, track in pairs(defaults) do
    options["preferred_" .. _type .. "_lang"] = track.preferred
    options["excluded_" .. _type .. "_words"] = track.excluded
    options["expected_" .. _type .. "_words"] = track.expected
end

options["preferred_audio_channels"] = ""

local tracks = {}
local last = {}
local fingerprint = ""
local trackselect_ran = false

opt.read_options(options, _, function() end)

local function is_protocol(path)
    return type(path) == 'string' and (path:find('^%a[%w.+-]-://') ~= nil or path:find('^%a[%w.+-]-:%?') ~= nil)
end

local function hex_to_char(x)
    return string.char(tonumber(x, 16))
end

local function url_decode(str)
    if str ~= nil then
        str = str:gsub('^%a[%a%d-_]+://', '')
              :gsub('^%a[%a%d-_]+:\\?', '')
              :gsub('%%(%x%x)', hex_to_char)
        if str:find('://localhost:?') then
            str = str:gsub('^.*/', '')
        end
        str = str:gsub("%?.+", ""):gsub("%+", " ")
        local last_pos = str:match('.*[\\/:%?]()')
        if last_pos then
            str = str:sub(last_pos)
        end
    end
    return str
end

local function is_empty(input)
    if input == nil or input == "" then
        return true
    end
end

local function replace(str, what, with)
    if is_empty(str) then return "" end
    if is_empty(what) then return str end
    if with == nil then with = "" end
    what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1")
    with = string.gsub(with, "[%%]", "%%%%")
    return string.gsub(str, what, with)
end

local function comparison(str1, str2)
    if not str1 and not str2 then
        return true
    end
    if str1 and str2 then
        return str1:lower() == str2:lower()
    end
    return false
end

local function contains(track, words, attr)
    if not track[attr] then return false end
    local i = 0
    if track.external then
        i = 1
    end
    for word in string.gmatch(words:lower(), "([^/]+)") do
        local w = word:match("^%s*(.-)%s*$")
        i = i - 1
        if w ~= "" and string.find(tostring(track[attr] or ""):lower(), w) then
            return i
        end
    end
    return false
end

local function preferred(track, words, attr, title)
    local score = contains(track, words, attr)
    if not score then
        if tracks[track.type][title] == nil then
            tracks[track.type][title] = -math.huge
            return false
        end
        return false
    end
    if tracks[track.type][title] == nil or score > tracks[track.type][title] then
        tracks[track.type][title] = score
        return true
    end
    return false
end

local function preferred_or_equals(track, words, attr, title)
    local score = contains(track, words, attr)
    if not score then
        if tracks[track.type][title] == nil or tracks[track.type][title] == -math.huge then
            return true
        end
        return false
    end
    if tracks[track.type][title] == nil or score >= tracks[track.type][title] then
        return true
    end
    return false
end

local function copy(obj)
    if type(obj) ~= "table" then return obj end
    local res = {}
    for k, v in pairs(obj) do res[k] = copy(v) end
    return res
end

local function track_layout_hash(tracklist)
    local t = {}
    for _, track in ipairs(tracklist) do
        t[#t + 1] = string.format("%s-%d-%s-%s-%s-%s", track.type, track.id, tostring(track.default),
            tostring(track.external), track.lang or "", track.external and "" or (track.title or ""))
    end
    return table.concat(t, "\n")
end

local function sanitize_title(track, path, filename, media_title)
    if not track or not track.title then return end
    local title = filename
    if is_protocol(path) then
        title = url_decode(media_title):gsub("%.?([^%.]+)$", "")
        track.title = url_decode(track.title)
    end
    track.title = replace(track.title, title, "")
end

local function selected_tracks()
    if not trackselect_ran then
        return
    end
    last = {}
    local tracklist = mp.get_property_native("track-list")
    local path = mp.get_property("path")
    local filename = mp.get_property("filename/no-ext")
    local media_title = mp.get_property("media-title", "")
    for _, track in ipairs(tracklist) do
        if track.selected then
            sanitize_title(track, path, filename, media_title)
            last[track.type] = track
        end
    end
end

local function trackselect()
    if options.smart_keep then
        -- observe specific current-tracks sub-properties
        local props = { 'current-tracks/video', 'current-tracks/audio', 'current-tracks/sub' }
        for _, p in ipairs(props) do
            mp.observe_property(p, 'native', selected_tracks)
        end
    end

    trackselect_ran = true
    if not options.enabled then
        return
    end

    tracks = copy(defaults)
    local path = mp.get_property("path")
    local filename = mp.get_property("filename/no-ext")
    local media_title = mp.get_property("media-title", "")
    local tracklist = mp.get_property_native("track-list")
    local tracklist_changed = false
    local found_last = {}
    if options.fingerprint then
        local new_fingerprint = track_layout_hash(tracklist)
        if new_fingerprint == fingerprint then
            return
        end
        fingerprint = new_fingerprint
        tracklist_changed = true
    end

    for _, track in ipairs(tracklist) do
        sanitize_title(track, path, filename, media_title)
        if options.smart_keep and last[track.type] ~= nil and
            comparison(last[track.type].lang, track.lang) and
            track.codec ~= "null" and last[track.type].codec == track.codec and
            last[track.type].external == track.external and
            comparison(last[track.type].title, track.title) then
            tracks[track.type].best = track
            options["preferred_" .. track.type .. "_lang"] = ""
            options["excluded_" .. track.type .. "_words"] = ""
            options["expected_" .. track.type .. "_words"] = ""
            options["preferred_" .. track.type .. "_channels"] = ""
            found_last[track.type] = true
        elseif not options.force and (tracklist_changed or not options.fingerprint) then
            if tracks[track.type].id == "" then
                tracks[track.type].id = mp.get_property(track.type:sub(1, 1) .. "id", "auto")
            end
            if tracks[track.type].id ~= "auto" then
                options["preferred_" .. track.type .. "_lang"] = ""
                options["excluded_" .. track.type .. "_words"] = ""
                options["expected_" .. track.type .. "_words"] = ""
                options["preferred_" .. track.type .. "_channels"] = ""
            end
        end
        if track.codec ~= "null" and options["preferred_" .. track.type .. "_lang"] ~= "" or
            options["excluded_" .. track.type .. "_words"] ~= "" or
            options["expected_" .. track.type .. "_words"] ~= "" or
            (options["preferred_" .. track.type .. "_channels"] or "") ~= "" then
            local preferred_lang = options["preferred_" .. track.type .. "_lang"]
            local excluded_words = options["excluded_" .. track.type .. "_words"]
            local expected_words = options["expected_" .. track.type .. "_words"]
            local preferred_channels = options["preferred_" .. track.type .. "_channels"]
            if track.selected then
                tracks[track.type].selected = track.id
                if options.smart_keep then
                    last[track.type] = track
                end
            end

            if (next(tracks[track.type].best) == nil or not (tracks[track.type].best.external
                and tracks[track.type].best.lang ~= nil and not track.external)) then
                if excluded_words == "" or not contains(track, excluded_words, "title") then
                    local pass = true
                    local channels = false
                    local lang = false
                    if (preferred_channels or "") ~= "" and
                        preferred_or_equals(track, preferred_lang, "lang", "lang_score") then
                        channels = preferred(track, preferred_channels, "demux-channel-count", "channels_score")
                        pass = channels
                    end
                    if preferred_lang ~= "" then
                        lang = preferred(track, preferred_lang, "lang", "lang_score")
                    end

                    local exp_score = nil
                    if expected_words then
                        exp_score = contains(track, expected_words, "title")
                    end
                    if exp_score then
                        local lang_score = nil
                        local existing_lang = nil
                        local existing_exp = tracks[track.type].expected_score
                        if next(tracks[track.type].best) ~= nil and preferred_lang ~= "" then
                            existing_lang = contains(tracks[track.type].best, preferred_lang, "lang")
                            lang_score = contains(track, preferred_lang, "lang")
                        end
                        if existing_exp == nil or exp_score > existing_exp or (exp_score == existing_exp and
                            ((lang_score or -math.huge) > (existing_lang or -math.huge) or channels)) then
                            tracks[track.type].expected_score = exp_score
                            tracks[track.type].best = track
                        end
                    elseif tracks[track.type].expected_score == nil then
                        if (preferred_lang == "" and pass) or channels or lang or
                            (track.external and track.lang == nil and next(tracks[track.type].best) == nil) then
                            tracks[track.type].best = track
                        end
                    end
                end
            end
        end
    end

    for _type, track in pairs(tracks) do
        if next(track.best) ~= nil and track.best.id ~= track.selected then
            mp.set_property('file-local-options/'.. _type:sub(1, 1) .. "id", track.best.id)
            if options.smart_keep and found_last[track.best.type] then
                last[track.best.type] = track.best
            end
        end
    end
end

if options.hook then
    mp.add_hook("on_preloaded", 50, trackselect)
else
    mp.register_event("file-loaded", trackselect)
end

mp.add_hook("on_unload", 50, function()
    trackselect_ran = false
    mp.unobserve_property(selected_tracks)
end)
