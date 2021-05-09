-- trackselect.lua
--
-- Because --slang isn't smart enough.
--
-- This script tries to select non-dub
-- audio and subtitle tracks.
-- Idea from https://github.com/siikamiika/scripts/blob/master/mpv%20scripts/dualaudiofix.lua

local defaults = {
    audio = {
        selected = nil,
        best = {},
        lang_score = nil,
        channels_score = -math.huge,
        preferred = "jpn/japanese",
        excluded = "",
        expected = "",
        id = ""
    },
    video = {
        selected = nil,
        best = {},
        lang_score = nil,
        preferred = "",
        excluded = "",
        expected = "",
        id = ""
    },
    sub = {
        selected = nil,
        best = {},
        lang_score = nil,
        preferred = "eng",
        excluded = "sign",
        expected = "",
        id = ""
    }
}

local options = {
    enabled = true,

    -- Do track selection synchronously, plays nicer with other scripts
    hook = true,

    -- Mimic mpv's track list fingerprint to preserve user-selected tracks across files
    fingerprint = true,

    -- Override user's explicit track selection
    force = false,

    -- Try to re-select the last track if mpv cannot do it e.g. when fingerprint changes
    smart_keep = false
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

mp.options = require "mp.options"

function contains(track, words, attr)
    if not track[attr] then return false end
    local i = 0
    if track.external then
        i = 1
    end
    for word in string.gmatch(words:lower(), "([^/]+)") do
        i = i - 1
        if string.match(tostring(track[attr] or ""):lower(), word) then
            return i
        end
    end
    return false
end

function preferred(track, words, attr, title)
    local score = contains(track, words, attr)
    if not score then
        if tracks[track.type][title] == nil then
            tracks[track.type][title] = -math.huge
            return true
        end
        return false
    end
    if tracks[track.type][title] == nil or score > tracks[track.type][title] then
        tracks[track.type][title] = score
        return true
    end
    return false
end

function preferred_or_equals(track, words, attr, title)
    local score = contains(track, words, attr)
    if not score then
        if tracks[track.type][title] == nil then
            return true
        end
        return false
    end
    if tracks[track.type][title] == nil or score >= tracks[track.type][title] then
        return true
    end
    return false
end

function copy(obj)
    if type(obj) ~= "table" then return obj end
    local res = {}
    for k, v in pairs(obj) do res[k] = copy(v) end
    return res
end

function track_layout_hash(tracklist)
    local t = {}
    for _, track in ipairs(tracklist) do
        t[#t+1] = string.format("%s-%d-%s-%s-%s-%s", track.type, track.id, tostring(track.default), tostring(track.external), track.lang or "", track.external and "" or (track.title or ""))
    end
    return table.concat(t, "\n")
end

function trackselect()
    mp.options.read_options(options, "trackselect")
    if not options.enabled then return end
    tracks = copy(defaults)
    local filename = mp.get_property("filename/no-ext")
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
        if options.smart_keep and last[track.type] ~= nil and last[track.type].lang == track.lang and last[track.type].codec == track.codec and last[track.type].external == track.external and last[track.type].title == track.title then
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
        if options["preferred_" .. track.type .. "_lang"] ~= "" or options["excluded_" .. track.type .. "_words"] ~= "" or options["expected_" .. track.type .. "_words"] ~= "" or (options["preferred_" .. track.type .. "_channels"] or "") ~= "" then
            if track.selected then
                tracks[track.type].selected = track.id
                if options.smart_keep then
                    last[track.type] = track
                end
            end
            if track.external then
                track.title = string.gsub(string.gsub(track.title, "%W", "%%%1"), filename, "")
            end
            if next(tracks[track.type].best) == nil or not (tracks[track.type].best.external and tracks[track.type].best.lang ~= nil) then
                if options["excluded_" .. track.type .. "_words"] == "" or not contains(track, options["excluded_" .. track.type .. "_words"], "title") then
                    if options["expected_" .. track.type .. "_words"] == "" or contains(track, options["expected_" .. track.type .. "_words"], "title") then
                        local pass = true
                        local channels = false
                        local lang = false
                        if (options["preferred_" .. track.type .. "_channels"] or "") ~= "" and preferred_or_equals(track, options["preferred_" .. track.type .. "_lang"], "lang", "lang_score") then
                            channels = preferred(track, options["preferred_" .. track.type .. "_channels"], "demux-channel-count", "channels_score")
                            pass = channels
                        end
                        if options["preferred_" .. track.type .. "_lang"] ~= "" then
                            lang = preferred(track, options["preferred_" .. track.type .. "_lang"], "lang", "lang_score")
                        end
                        if (options["preferred_" .. track.type .. "_lang"] == "" and pass) or channels or lang or (track.external and track.lang == nil and (not tracks[track.type].best.external or tracks[track.type].best.lang == nil)) then
                            tracks[track.type].best = track
                        end
                    end
                end
            end
        end
    end
    for _type, track in pairs(tracks) do
        if next(track.best) ~= nil and track.best.id ~= track.selected then
            mp.set_property(_type:sub(1, 1) .. "id", track.best.id)
            if options.smart_keep and found_last[track.best.type] then
                last[track.best.type] = track.best
            end
        end
    end
end

function selected_tracks()
    local tracklist = mp.get_property_native("track-list")
    last = {}
    for _, track in ipairs(tracklist) do
        if track.selected then
            last[track.type] = track
        end
    end
end

if options.hook then
    mp.add_hook("on_preloaded", 50, trackselect)
else
    mp.register_event("file-loaded", trackselect)
end

if options.smart_keep then
    mp.register_event("track-switched", selected_tracks)
end