--[[
    * track-menu.lua v.2022-06-26
    *
    * AUTHORS: dyphire
    * License: MIT
    * link: https://github.com/dyphire/mpv-scripts

    This script implements an interractive track list, usage:
    -- add bindings to input.conf:
    -- key script-message-to track_menu toggle-vidtrack-browser
    -- key script-message-to track_menu toggle-audtrack-browser
    -- key script-message-to track_menu toggle-subtrack-browser

    This script needs to be used with scroll-list.lua
    https://github.com/dyphire/mpv-scroll-list
]]

local mp = require 'mp'
local opts = require("mp.options")
local propNative = mp.get_property_native

local o = {
    header = "Track List [%cursor%/%total%]\\N ------------------------------------",
    wrap = true,
    key_scroll_down = "DOWN WHEEL_DOWN",
    key_scroll_up = "UP WHEEL_UP",
    key_select_track = "ENTER MBTN_LEFT",
    key_close_browser = "ESC MBTN_RIGHT",
}

opts.read_options(o)

--adding the source directory to the package path and loading the module
local list = dofile(mp.command_native({"expand-path", "~~/script-modules/scroll-list.lua"}))

--modifying the list settings
list.header = o.header
list.wrap = o.wrap

local function esc_for_title(string)
    string = string:gsub('^%-', '')
    :gsub('^%_', '')
    :gsub('^%.', '')
    :gsub('^.*%].', '')
    :gsub('^.*%).', '')
    :gsub('%.%w+$', '')
    :gsub('^.*%s', '')
    :gsub('^.*%.', '')
    return string
end

local function trackCount(checkType)
    local tracksCount = propNative("track-list/count")
    local trackCountVal = {}

    if not (tracksCount < 1) then
        for i = 0, (tracksCount - 1), 1 do
            local trackType = propNative("track-list/" .. i .. "/type")
            if (trackType == checkType) then table.insert(trackCountVal, i) end
        end
    end

    return trackCountVal
end

local function checkTrack(trackNum)
    local trackState, trackCur = false, propNative("track-list/" .. trackNum .. "/selected")
    if (trackCur == true) then trackState = true end
    return trackState
end

--jump to the selected audio-device
local function select_track()
    if list.list[list.selected] then
        local i = list.selected
        if list.list[i].ass:match("Vid " .. string.format("%02.f", i) .. ": ") then
            mp.set_property_number('vid', list.selected)
        elseif list.list[i].ass:match("Aud " .. string.format("%02.f", i) .. ": ") then
            mp.set_property_number('aid', list.selected)
        elseif list.list[i].ass:match("Sub " .. string.format("%02.f", i) .. ": ") then
            mp.set_property_number('sid', list.selected)
        end
    end
end

-- Video track-list menu
local function vidtrack_list()
    list.header = "Video: " .. o.header
    list.list = {}
    local vidTrackCount = trackCount("video")
    if not (#vidTrackCount == 0) then
        for i = 1, #vidTrackCount, 1 do
            local item = {}
            local vidTrackNum = vidTrackCount[i]
            local vidTrackTitle = propNative("track-list/" .. vidTrackNum .. "/title")
            local vidTrackCodec = propNative("track-list/" .. vidTrackNum .. "/codec"):upper()
            local vidTrackImage = propNative("track-list/" .. vidTrackNum .. "/image")
            local vidTrackwh = propNative("track-list/" .. vidTrackNum .. "/demux-w") .. "x" .. propNative("track-list/" .. vidTrackNum .. "/demux-h") 
            local vidTrackFps = string.format("%.3f", propNative("track-list/" .. vidTrackNum .. "/demux-fps"))
            local vidTrackDefault = propNative("track-list/" .. vidTrackNum .. "/default")
            local vidTrackForced = propNative("track-list/" .. vidTrackNum .. "/forced")
            local vidTrackExternal = propNative("track-list/" .. vidTrackNum .. "/external")
            local filename = propNative("filename/no-ext")

            if vidTrackTitle then vidTrackTitle = vidTrackTitle:gsub(filename, '') end
            if vidTrackExternal then vidTrackTitle = esc_for_title(vidTrackTitle) end
            if vidTrackCodec:match("MPEG2") then vidTrackCodec = "MPEG2"
            elseif vidTrackCodec:match("DVVIDEO") then vidTrackCodec = "DV"
            end

            if vidTrackTitle and not vidTrackImage then vidTrackTitle = vidTrackTitle .. "[" .. vidTrackCodec .. "]" .. ", " .. vidTrackwh .. ", " .. vidTrackFps .. " FPS"
            elseif vidTrackTitle then vidTrackTitle = vidTrackTitle .. "[" .. vidTrackCodec .. "]" .. ", " .. vidTrackwh
            elseif vidTrackImage then vidTrackTitle = "[" .. vidTrackCodec .. "]" .. ", " .. vidTrackwh
            elseif vidTrackFps then vidTrackTitle = "[" .. vidTrackCodec .. "]" .. ", " .. vidTrackwh .. ", " .. vidTrackFps .. " FPS"
            end

            if vidTrackForced then  vidTrackTitle = vidTrackTitle .. ", " .. "Forced" end
            if vidTrackDefault then  vidTrackTitle = vidTrackTitle .. ", " .. "Default" end
            if vidTrackExternal then  vidTrackTitle = vidTrackTitle .. ", " .. "External" end
            
            if checkTrack(vidTrackNum) then
                list.selected = i
                item.style = [[{\c&H33ff66&}]]
                item.ass = "● " .. "Vid " .. string.format("%02.f", i) .. ": " .. list.ass_escape(vidTrackTitle)
            else
                item.ass = "○ " .. "Vid " .. string.format("%02.f", i) .. ": " .. list.ass_escape(vidTrackTitle)
            end
            list.list[i] = item
        end
    end
    list:update()
end

-- Audio track-list menu
local function audtrack_list()
    list.header = "Audio: " .. o.header
    list.list = {}
    local audTrackCount = trackCount("audio")
    if not (#audTrackCount == 0) then
        for i = 1, (#audTrackCount), 1 do
            local item = {}
            local audTrackNum = audTrackCount[i]
            local audTrackTitle = propNative("track-list/" .. audTrackNum .. "/title")
            local audTrackLang = propNative("track-list/" .. audTrackNum .. "/lang")
            local audTrackCodec = propNative("track-list/" .. audTrackNum .. "/codec"):upper()
            -- local audTrackBitrate = propNative("track-list/" .. audTrackNum .. "/demux-bitrate") / 1000
            local audTrackSamplerate = propNative("track-list/" .. audTrackNum .. "/demux-samplerate") / 1000
            local audTrackChannels = propNative("track-list/" .. audTrackNum .. "/demux-channel-count")
            local audTrackDefault = propNative("track-list/" .. audTrackNum .. "/default")
            local audTrackForced = propNative("track-list/" .. audTrackNum .. "/forced")
            local audTrackExternal = propNative("track-list/" .. audTrackNum .. "/external")
            local filename = propNative("filename/no-ext")

            if audTrackTitle then audTrackTitle = audTrackTitle:gsub(filename, '') end
            if audTrackExternal then audTrackTitle = esc_for_title(audTrackTitle) end
            if audTrackCodec:match("PCM") then audTrackCodec = "PCM" end

            if audTrackTitle and audTrackLang then audTrackTitle = audTrackTitle .. ", " .. audTrackLang .. "[" .. audTrackCodec .. "]" .. ", " .. audTrackChannels .. " ch" .. ", " .. audTrackSamplerate .. " kHz"
            elseif audTrackTitle then audTrackTitle = audTrackTitle .. "[" .. audTrackCodec .. "]" .. ", " .. audTrackChannels .. " ch" .. ", " .. audTrackSamplerate .. " kHz"
            elseif audTrackLang then audTrackTitle = audTrackLang .. "[" .. audTrackCodec .. "]" .. ", " .. audTrackChannels .. " ch" .. ", " .. audTrackSamplerate .. " kHz"
            elseif audTrackChannels then audTrackTitle = "[" .. audTrackCodec .. "]" .. ", " .. audTrackChannels .. " ch" .. ", " .. audTrackSamplerate .. " kHz"
            end

            if audTrackForced then  audTrackTitle = audTrackTitle .. ", " .. "Forced" end
            if audTrackDefault then  audTrackTitle = audTrackTitle .. ", " .. "Default" end
            if audTrackExternal then  audTrackTitle = audTrackTitle .. ", " .. "External" end
            
            if checkTrack(audTrackNum) then
                list.selected = i
                item.style = [[{\c&H33ff66&}]]
                item.ass = "● " .. "Aud " .. string.format("%02.f", i) .. ": " .. list.ass_escape(audTrackTitle)
            else
                item.ass = "○ " .. "Aud " .. string.format("%02.f", i) .. ": " .. list.ass_escape(audTrackTitle)
            end
            list.list[i] = item
        end
    end
    list:update()
end

-- Subtitle track-list menu
local function subtrack_list()
    list.header = "Subtitle: " .. o.header
    list.list = {}
    local subTrackCount = trackCount("sub")
    if not (#subTrackCount == 0) then
        for i = 1, (#subTrackCount), 1 do
            local item = {}
            local subTrackNum = subTrackCount[i]
            local subTrackTitle = propNative("track-list/" .. subTrackNum .. "/title")
            local subTrackLang = propNative("track-list/" .. subTrackNum .. "/lang")
            local subTrackCodec = propNative("track-list/" .. subTrackNum .. "/codec"):upper()
            local subTrackDefault = propNative("track-list/" .. subTrackNum .. "/default")
            local subTrackForced = propNative("track-list/" .. subTrackNum .. "/forced")
            local subTrackExternal = propNative("track-list/" .. subTrackNum .. "/external")
            local filename = propNative("filename/no-ext")
                
            if subTrackTitle then subTrackTitle = subTrackTitle:gsub(filename, '') end
            if subTrackExternal then subTrackTitle = esc_for_title(subTrackTitle) end
            if subTrackCodec:match("PGS") then subTrackCodec = "PGS"
            elseif subTrackCodec:match("SUBRIP") then subTrackCodec = "SRT"
            elseif subTrackCodec:match("VTT") then subTrackCodec = "VTT"
            elseif subTrackCodec:match("DVB_SUB") then subTrackCodec = "DVB"
            elseif subTrackCodec:match("DVD_SUB") then subTrackCodec = "VOB"
            end
    
            if subTrackTitle and subTrackLang then subTrackTitle = subTrackTitle .. ", " .. subTrackLang .. "[" .. subTrackCodec .. "]" 
            elseif subTrackTitle then subTrackTitle = subTrackTitle .. "[" .. subTrackCodec .. "]"
            elseif subTrackLang then subTrackTitle = subTrackLang .. "[" .. subTrackCodec .. "]"
            elseif subTrackCodec then subTrackTitle = "[" .. subTrackCodec .. "]"
            end

            if subTrackForced then  subTrackTitle = subTrackTitle .. ", " .. "Forced" end
            if subTrackDefault then  subTrackTitle = subTrackTitle .. ", " .. "Default" end
            if subTrackExternal then  subTrackTitle = subTrackTitle .. ", " .. "External" end
            
            if checkTrack(subTrackNum) then
                list.selected = i
                item.style = [[{\c&H33ff66&}]]
                item.ass = "● " .. "Sub " .. string.format("%02.f", i) .. ": " .. list.ass_escape(subTrackTitle)
            else
                item.ass = "○ " .. "Sub " .. string.format("%02.f", i) .. ": " .. list.ass_escape(subTrackTitle)
            end
            list.list[i] = item
        end
    end
    list:update()
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
add_keys(o.key_select_track, 'select_track', select_track, {})
add_keys(o.key_close_browser, 'close_browser', function() list:close() end, {})

local function vid_tracklist()
    list:close()
    mp.unobserve_property(audtrack_list)
    mp.unobserve_property(subtrack_list)
    mp.observe_property("track-list/count", "number", vidtrack_list)
    mp.observe_property("vid", "string", vidtrack_list)
end

local function aud_tracklist()
    list:close()
    mp.unobserve_property(vidtrack_list)
    mp.unobserve_property(subtrack_list)
    mp.observe_property("track-list/count", "number", audtrack_list)
    mp.observe_property("aid", "string", audtrack_list)
end

local function sub_tracklist()
    list:close()
    mp.unobserve_property(vidtrack_list)
    mp.unobserve_property(audtrack_list)
    mp.observe_property("track-list/count", "number", subtrack_list)
    mp.observe_property("sid", "string", subtrack_list)
end

mp.register_event("end-file", function()
    mp.unobserve_property(vidtrack_list)
    mp.unobserve_property(audtrack_list)
    mp.unobserve_property(subtrack_list)
end)

mp.register_script_message("toggle-vidtrack-browser", function()
    vid_tracklist()
    mp.add_timeout(0.1, function()
        list:toggle()
    end)
end)

mp.register_script_message("toggle-audtrack-browser", function()
    aud_tracklist()
    mp.add_timeout(0.1, function()
        list:toggle()
    end)
end)

mp.register_script_message("toggle-subtrack-browser", function()
    sub_tracklist()
    mp.add_timeout(0.1, function()
        list:toggle()
    end)
end)