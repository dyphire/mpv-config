--[[
    * sub-fastwhisper.lua
    *
    * AUTHORS: dyphire
    * License: MIT
    * link: https://github.com/dyphire/mpv-sub-fastwhisper
]]

local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require "mp.options"

---- Script Options ----
local o = {
    -- Path to the faster-whisper executable, you can download it from here:
    -- https://github.com/Purfview/whisper-standalone-win
    -- Supports absolute and relative paths
    fast_whisper_path = "faster-whisper",
    -- Model to use, available models are: base, small，medium, large, large-v2, large-v3, turbo
    model = "base",
    -- Device to use, available devices are: cpu, cuda
    device = "cpu",
    -- Specify the language of transcription
    -- Leave it blank and it will be automatically detected
    language = "",
    -- Number of cpu threads to use
    -- Default value is 0 will auto-detect but max 4 threads
    threads = "0",
    -- The maximum number of characters in a line before breaking the line
    max_line_width = "100",
    -- Specify output path, supports absolute and relative paths
    -- Special value: "source" saves the subtitle file to the directory 
    -- where the video file is located
    output_path = "source",
    -- Specify how many subtitles are generated before updating
    -- to avoid frequent flickering of subtitles
    update_interval = 20,
    -- Uses segmentation for speech transcription, 
    -- which significantly improves the speed of subtitle initialization.
    -- but it will reduce the accuracy and overall speed of subtitle generation, 
    -- which is more suitable for long video scenarios.
    --! Depends on FFmpeg
    use_segment = false,
    -- Segment duration in seconds
    segment_duration = 10,
}

options.read_options(o, _, function() end)
------------------------

local fast_whisper_path = mp.command_native({ "expand-path", o.fast_whisper_path })
local output_path = mp.command_native({ "expand-path", o.output_path })

local subtitle_count = 1
local append_subtitle_count = 1
local subtitles_written = false
local whisper_running = false

local is_windows = package.config:sub(1, 1) == "\\"

local function is_protocol(path)
    return type(path) == 'string' and (path:find('^%a[%w.+-]-://') ~= nil or path:find('^%a[%w.+-]-:%?') ~= nil)
end

local function file_exists(path)
    if path then
        local meta = utils.file_info(path)
        return meta and meta.is_file
    end
    return false
end

local function normalize(path)
    if normalize_path ~= nil then
        if normalize_path then
            path = mp.command_native({"normalize-path", path})
        else
            local directory = mp.get_property("working-directory", "")
            path = utils.join_path(directory, path:gsub('^%.[\\/]',''))
            if is_windows then path = path:gsub("\\", "/") end
        end
        return path
    end

    normalize_path = false

    local commands = mp.get_property_native("command-list", {})
    for _, command in ipairs(commands) do
        if command.name == "normalize-path" then
            normalize_path = true
            break
        end
    end
    return normalize(path)
end

local function format_time(time_str)
    local h, m, s, ms = nil, nil, nil, nil
    if time_str:match("%d+:%d+:%d+%.%d+") then
        h, m, s, ms = time_str:match("(%d+):(%d+):(%d+)%.(%d+)")
    else
        m, s, ms = time_str:match("(%d+):(%d+)%.(%d+)")
    end

    if not h then h = 0 end

    return string.format("%02d:%02d:%02d,%03d", h, m, s, ms)
end

local function timestamp_to_seconds(timestamp)
    local h, m, s, ms = timestamp:match("(%d+):(%d+):(%d+),(%d+)")
    return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms) / 1000
end

local function seconds_to_timestamp(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor(seconds / 60) % 60
    local s = math.floor(seconds % 60)
    local ms = math.floor((seconds - math.floor(seconds)) * 1000)
    return string.format("%02d:%02d:%02d,%03d", h, m, s, ms)
end

local function check_sub(sub_file)
    local tracks = mp.get_property_native("track-list")
    local _, sub_title = utils.split_path(sub_file)
    for _, track in ipairs(tracks) do
        if track["type"] == "sub" and track["title"] == sub_title then
            return true, track["id"]
        end
    end
    return false, nil
end

local function append_sub(sub_file)
    local sub, id = check_sub(sub_file)
    if not sub then
        mp.commandv('sub-add', sub_file)
    else
        mp.commandv('sub-reload', id)
    end
end

local function fastwhisper_cmd(file_path, sub_path)
    local args = {
        fast_whisper_path,
        file_path,
        "--beep_off",
        "--model", o.model,
        "--device", o.device,
        "--max_line_width", o.max_line_width,
        "--threads", o.threads,
        "--output_dir", sub_path,
    }

    if o.language ~= "" then
        table.insert(args, "--language")
        table.insert(args, o.language)
    end

    return args
end

local function fastwhisper()
    if whisper_running then return end
    local path = mp.get_property("path")
    local fname = mp.get_property("filename/no-ext")
    if not path or is_protocol(path) then return end
    if path then
        path = normalize(path)
        dir = utils.split_path(path)
    end

    if output_path ~= "source" then
        subtitles_file = utils.join_path(output_path, fname .. ".srt")
    else
        subtitles_file = utils.join_path(dir, fname .. ".srt")
    end

    if file_exists(subtitles_file) then return end

    local screenx, screeny, aspect = mp.get_osd_size()
    mp.set_osd_ass(screenx, screeny, "{\\an9}● ")
    mp.osd_message("AI subtitle generation in progress", 9)
    msg.info("AI subtitle generation in progress")

    subtitle_count = 1
    append_subtitle_count = 1
    subtitles_written = false
    whisper_running = true

    local args = fastwhisper_cmd(path, output_path)
    mp.command_native_async({ name = "subprocess", capture_stderr = true, args = args }, function(success, res)
        whisper_running = false
        mp.set_osd_ass(screenx, screeny, "")
        if res.status ~= 0 then
            if file_exists(subtitles_file) then
                local file = io.open(subtitles_file, "r")
                if file then
                    local content = file:read("*all")
                    file:close()
        
                    if content == "" then
                        os.remove(subtitles_file)
                    else
                        mp.osd_message("AI subtitles successfully generated", 5)
                        msg.info("AI subtitles successfully generated")
                        append_sub(subtitles_file)
                    end
                end
            end
        else
            mp.osd_message("AI subtitle generation failed, check console for more info.")
            msg.info("AI subtitle generation failed")
        end
    end)
end

mp.enable_messages('info')

mp.register_event('log-message', function(e)
    if e.prefix ~= mp.get_script_name() then return end

    local file = io.open(subtitles_file, "a")
    if file and e.text and e.text ~= '' then
        local text_pattern = "%[([%d+:]?%d+:%d+%.%d+)%D+([%d+:]?%d+:%d+%.%d+)%]%s*(.*)"
        local start_time_srt, end_time_srt, subtitle_text = e.text:match(text_pattern)
        if start_time_srt and end_time_srt and subtitle_text then
            local start_time = format_time(start_time_srt)
            local end_time = format_time(end_time_srt)

            file:write(subtitle_count .. "\n")
            file:write(start_time .. " --> " .. end_time.. "\n")
            file:write(subtitle_text .. "\n")
            file:close()

            subtitle_count = subtitle_count + 1
            subtitles_written = true
        end
        if subtitle_count % o.update_interval == 1 and subtitles_written then
            if append_subtitle_count == 1 then
                mp.osd_message("AI subtitles are loaded and updated in real time", 5)
                msg.info("AI subtitles are loaded and updated in real time")
            end
            append_sub(subtitles_file)
            subtitles_written = false
            append_subtitle_count = append_subtitle_count + 1
        end
    end
end)

------------------------
local function extract_audio_segment(video_path, segment_audio_file, start_time, duration)
    local args = {
        "ffmpeg",
        "-hide_banner",
        "-nostdin",
        "-y",
        "-loglevel", "quiet",
        "-i", video_path,
        "-ss", tostring(start_time),
        "-t", tostring(duration),
        "-map", string.format("a:%s?", mp.get_property_number("current-tracks/audio/id", 0) - 1),
        "-vn",
        "-sn",
        "-c:a", "copy",
        segment_audio_file
    }

    local res = mp.command_native({ name = "subprocess", capture_stdout = true, capture_stderr = true, args = args })

    if res and res.status ~= 0 then
        msg.error("Error extracting audio segment: " .. segment_audio_file .. "\n" .. res.stderr)
        return false
    end
    msg.verbose("Successfully extracted: " .. segment_audio_file)
    return true
end


local function process_audio_segment(segment_audio_file, srt_file, subtitle_count, start_time)
    local temp_srt_path = utils.split_path(segment_audio_file)
    local temp_srt = segment_audio_file:gsub("%.wav$", ".srt")

    local args = fastwhisper_cmd(segment_audio_file, temp_srt_path)
    local res = mp.command_native({ name = "subprocess", capture_stdout = true, capture_stderr = true, args = args })

    if res and res.status ~= 0 then
        msg.error("faster-whisper failed for: " .. segment_audio_file .. "\n" .. res.stderr)
        return subtitle_count
    end

    if not file_exists(temp_srt) then
        msg.error("Temporary SRT file not found: " .. temp_srt)
        return subtitle_count
    end

    local temp_file = io.open(temp_srt, "r")
    local main_file = io.open(srt_file, "a")

    if not temp_file or not main_file then
        msg.error("Failed to open temporary or main SRT file.")
        return subtitle_count
    end

    local subtitle_number = subtitle_count
    if subtitle_number == 1 then
        mp.osd_message("AI subtitles are loaded and updated in real time", 5)
        msg.info("AI subtitles are loaded and updated in real time")
    end
    for line in temp_file:lines() do
        if line:match("%d+:%d+:%d+,%d+%D+%d+:%d+:%d+,%d+") then
            local start_ts, end_ts = line:match("(%d+:%d+:%d+,%d+)%D+(%d+:%d+:%d+,%d+)")
            if start_ts and end_ts then
                local start_seconds = timestamp_to_seconds(start_ts) + start_time
                local end_seconds = timestamp_to_seconds(end_ts) + start_time
                main_file:write(subtitle_number .. "\n")
                main_file:write(seconds_to_timestamp(start_seconds) .. " --> " .. seconds_to_timestamp(end_seconds) .. "\n")
                subtitle_number = subtitle_number + 1
            end
        elseif line ~= "" and not tonumber(line) then
            main_file:write(line .. "\n")
        end
    end

    temp_file:close()
    main_file:close()

    os.remove(temp_srt)

    return subtitle_number
end

local function process_video_incrementally(video_path, srt_file, segment_duration)
    local start_time = 0
    local subtitle_count = 1
    local segment_index = 1
    local temp_path = os.getenv("TEMP") or "/tmp/"
    local file_duration = mp.get_property_number('duration')

    while true do
        if start_time >= file_duration then
            break
        end
        if start_time + segment_duration > file_duration then
            segment_duration = file_duration - start_time
        end

        local segment_audio_file = utils.join_path(temp_path, "temp.wav")
        local temp_srt_file = utils.join_path(temp_path, "temp.srt")
        if file_exists(segment_audio_file) then
            os.remove(segment_audio_file)
        end
        if file_exists(temp_srt_file) then
            os.remove(temp_srt_file)
        end

        local start_time_str = string.format("%02d:%02d:%02d", math.floor(start_time / 3600), math.floor(start_time / 60) % 60, start_time % 60)
        msg.verbose(string.format("Extracting segment: %d, Start Time: %s", segment_index, start_time_str))

        local success = extract_audio_segment(video_path, segment_audio_file, start_time_str, segment_duration)
        if not success or not file_exists(segment_audio_file) then
            msg.verbose("Audio extraction completed or failed.")
            break
        end

        msg.verbose("Processing segment: " .. segment_audio_file)
        subtitle_count = process_audio_segment(segment_audio_file, srt_file, subtitle_count, start_time)

        append_sub(srt_file)

        start_time = start_time + segment_duration
        segment_index = segment_index + 1
    end
end

local function fastwhisper_segment()
    if whisper_running then return end
    local path = mp.get_property("path")
    local fname = mp.get_property("filename/no-ext")
    if not path or is_protocol(path) then return end
    if path then
        path = normalize(path)
        dir = utils.split_path(path)
    end

    if output_path ~= "source" then
        subtitles_file = utils.join_path(output_path, fname .. ".fastwhisper.srt")
    else
        subtitles_file = utils.join_path(dir, fname .. ".fastwhisper.srt")
    end

    if file_exists(subtitles_file) then
        msg.info("Subtitles file already exists: " .. subtitles_file)
        return
    end

    mp.osd_message("AI subtitle generation in progress", 9)
    msg.info("AI subtitle generation in progress")

    whisper_running = true
    process_video_incrementally(path, subtitles_file, o.segment_duration)
    whisper_running = false

    if file_exists(subtitles_file) then
        mp.osd_message("AI subtitles successfully generated", 5)
        msg.info("Subtitles generation completed: " .. subtitles_file)
    end
end
------------------------

local function whisper()
    if o.use_segment then
        fastwhisper_segment()
    else
        fastwhisper()
    end
end

mp.add_hook("on_unload", 50, function()
    local temp_path = os.getenv("TEMP") or "/tmp/"
    local segment_audio_file = utils.join_path(temp_path, "temp.wav")
    local temp_srt_file = utils.join_path(temp_path, "temp.srt")
    if file_exists(segment_audio_file) then
        os.remove(segment_audio_file)
    end
    if file_exists(temp_srt_file) then
        os.remove(temp_srt_file)
    end

    if file_exists(subtitles_file) then
        local file = io.open(subtitles_file, "r")
        if file then
            local content = file:read("*all")
            file:close()
            if content == "" then
                os.remove(subtitles_file)
            end
        end
    end
end)

mp.register_script_message("sub-fastwhisper", whisper)
