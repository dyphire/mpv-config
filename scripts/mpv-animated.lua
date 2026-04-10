-- Original by Scheliux, Dragoner7 which was ported from Ruin0x11
-- Adapted to webp by DonCanjas
-- Modify_: https://github.com/dyphire/mpv-scripts

-- Create animated webps or gifs with mpv
-- Requires ffmpeg.
-- Adapted from https://github.com/Scheliux/mpv-gif-generator
-- Usage: "w" to set start frame, "W" to set end frame, "Ctrl+w" to create.

--  Note:
--     Requires FFmpeg in PATH environment variable or edit ffmpeg_path in the script options,
--  Note: 
--     A small circle at the top-right corner is a sign that creat is happenning now.

require 'mp.options'
local msg = require 'mp.msg'
local utils = require "mp.utils"

local options = {
    type = "gif",   -- gif or webp
    ffmpeg_path = "ffmpeg",
    dir = "~~desktop/",
    rez = 600,
    fps = 15,
    lossless = 0,
    quality = 90,
    compression_level = 6,
    loop = 0,
}

read_options(options)


local fps
local ext
local text

if options.type == "webp" then 
    ext = "webp"
    text = "webP"
else
    ext = "gif"
    text = "GIF"
end

-- Check for invalid fps values
-- Can you believe Lua doesn't have a proper ternary operator in the year of our lord 2020?
if options.fps ~= nil and options.fps >= 1 and options.fps < 30 then
    fps = options.fps
else
    fps = 15
end

-- Set this to the filters to pass into ffmpeg's -vf option.
-- filters="fps=24,scale=320:-1:flags=spline"
filters=string.format("fps=%s,scale='trunc(ih*dar/2)*2:trunc(ih/2)*2',setsar=1/1,scale=%s:-1:flags=lanczos", fps, options.rez)  

local is_windows = package.config:sub(1, 1) == "\\" -- detect path separator, windows uses backslashes
-- Setup output directory
local output_directory = mp.command_native({ "expand-path", options.dir })
--create output_directory if it doesn't exist
if output_directory ~= '' then
    local meta, meta_error = utils.file_info(output_directory)
    if not meta or not meta.is_dir then
        local windows_args = { 'powershell', '-NoProfile', '-Command', 'mkdir', string.format("\"%s\"", output_directory) }
        local unix_args = { 'mkdir', '-p', output_directory }
        local args = is_windows and windows_args or unix_args
        local res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
        if res.status ~= 0 then
            msg.error("Failed to create animated_dir save directory "..output_directory..". Error: "..(res.error or "unknown"))
            return
        end
    end
end

start_time = -1
end_time = -1

local function is_protocol(path)
    return type(path) == 'string' and (path:find('^%a[%w.+-]-://') ~= nil or path:find('^%a[%w.+-]-:%?') ~= nil)
end


function make_animated_with_subtitles()
    make_animated_internal(true)
end

function make_animated()
    make_animated_internal(false)
end    

function table_length(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end


function make_animated_internal(burn_subtitles)
    local start_time_l = start_time
    local end_time_l = end_time
    if start_time_l == -1 or end_time_l == -1 or start_time_l >= end_time_l then
        mp.osd_message("Invalid start/end time.")
        return
    end

    local trim_filters = filters
    local position = start_time_l
    local duration = end_time_l - start_time_l
    local filename = mp.get_property("filename/no-ext")

    msg.info("Creating " .. text)
    mp.osd_message("Creating " .. text)

    -- shell escape
    function esc_for_sub(s)
        s = string.gsub(s, "\\", "/")
        s = string.gsub(s, '"', '\\"')
        s = string.gsub(s, ":", "\\:")
        s = string.gsub(s, "'", "\\'")
        s = string.gsub(s, "%[", "\\%[")
        s = string.gsub(s, "%]", "\\%]")
        return s
    end

    local pathname = mp.get_property("path", "")
    local path =  mp.get_property_native("path")
    local cache = mp.get_property_native("cache")
    local cache_state = mp.get_property_native("demuxer-cache-state")
    local cache_ranges = cache_state and cache_state["seekable-ranges"] or {}
    if path and is_protocol(path) or cache == "auto" and #cache_ranges > 0 then
        local pid = mp.get_property_native('pid')
        local temp_path = os.getenv("TEMP") or "/tmp/"
        local temp_video_file = utils.join_path(temp_path, "mpv_dump_" .. pid .. ".mkv")
        mp.commandv("dump-cache", start_time_l, end_time_l, temp_video_file)
        position = 0
        filename = mp.get_property("media-title")
        pathname = temp_video_file
    end

    if burn_subtitles then
        -- Determine currently active sub track

        local i = 0
        local tracks_count = mp.get_property_number("track-list/count")
        local subs_array = {}
        
        -- check for subtitle tracks

        while i < tracks_count do
            local type = mp.get_property(string.format("track-list/%d/type", i))
            local selected = mp.get_property(string.format("track-list/%d/selected", i))
            local external = mp.get_property(string.format("track-list/%d/external", i))

            -- if it's a sub track, save it

            if type == "sub" then
                local length = table_length(subs_array)
                if selected == "yes" and external == "yes" then
                    msg.info("Error: external subtitles have been selected")
                    mp.osd_message("Error: external subtitles have been selected", 2)
                    return
                else
                    subs_array[length] = selected == "yes"
                end
            end
            i = i + 1
        end

        if table_length(subs_array) > 0 then

            local correct_track = 0

            -- iterate through saved subtitle tracks until the correct one is found

            for index, is_selected in pairs(subs_array) do
                if (is_selected) then
                    correct_track = index
                end
            end

            trim_filters = trim_filters .. string.format(",subtitles='%s':si=%s", esc_for_sub(pathname), correct_track)

        end

    end

    -- make the animated
    local file_path = utils.join_path(output_directory, filename)

    -- increment filename
    for i = 0, 999 do
        local fn = string.format('%s_%03d.%s', file_path, i, ext)
        if not file_exists(fn) then
            animated_name = fn
            break
        end
    end
    if not animated_name then
        mp.osd_message('No available filenames!')
        return
    end

    local copyts = ""

    if burn_subtitles then
        copyts = "-copyts"
    end

    if options.type == "webp" then
        arg = string.format("%s -y -hide_banner -loglevel error -ss %s %s -t %s -i '%s' -lavfi %s -lossless %s -q:v %s -compression_level %s -loop %s '%s'", options.ffmpeg_path, position, copyts, duration, pathname, trim_filters, options.lossless, options.quality, options.compression_level, options.loop, animated_name)
    else
        arg = string.format("%s -y -hide_banner -loglevel error -ss %s %s -t %s -i '%s' -lavfi %s,'split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse' -loop %s '%s'", options.ffmpeg_path, position, copyts, duration, pathname, trim_filters, options.loop, animated_name)
    end
    local windows_args = { 'powershell', '-NoProfile', '-Command', arg }
    local unix_args = { '/bin/bash', '-c', arg }
    local args = is_windows and windows_args or unix_args
    local screenx, screeny, aspect = mp.get_osd_size()
    mp.set_osd_ass(screenx, screeny, "{\\an9}● ")
    local res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
    mp.set_osd_ass(screenx, screeny, "")
    if res.status ~= 0 then
        msg.info("Failed to creat " .. animated_name)
        mp.osd_message("Error creating " .. text .. ", check console for more info.")
        return
    end
    msg.info(animated_name .. " created.")
    mp.osd_message(text .. " created.")
end

function set_animated_start()
    start_time = mp.get_property_number("time-pos", -1)
    mp.osd_message(text .. " Start: " .. start_time)
end

function set_animated_end()
    end_time = mp.get_property_number("time-pos", -1)
    mp.osd_message(text .. " End: " .. end_time)
end

function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then io.close(f) return true else return false end
end

mp.add_key_binding("w", "set_animated_start", set_animated_start)
mp.add_key_binding("W", "set_animated_end", set_animated_end)
mp.add_key_binding("Ctrl+w", "make_animated", make_animated)
mp.add_key_binding("Ctrl+W", "make_animated_with_subtitles", make_animated_with_subtitles) --only works with srt for now
