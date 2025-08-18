--[[
  * chapterskip.lua v.2025-08-19
  *
  * AUTHORS: detuur, microraptor, Eisa01, dyphire
  * License: MIT
  * link: https://github.com/detuur/mpv-scripts
  * 
  * This script skips to the next silence in the file. The
  * intended use for this is to skip until the end of an
  * opening sequence, at which point there's often a short
  * period of silence.
  *
  * The default keybind is F3. You can change this by adding
  * the following line to your input.conf:
  *     KEY script-binding skip-to-silence
  * 
  * In order to tweak the script parameters, you can place the
  * text below, between the template markers, in a new file at
  * script-opts/chapterskip.conf in mpv's user folder. The
  * parameters will be automatically loaded on start.
  *
  * Dev note about the used filters:
  * - `silencedetect` is an audio filter that listens for silence and
  * emits text output with details whenever silence is detected.
  * Filter documentation: https://ffmpeg.org/ffmpeg-filters.html
****************** TEMPLATE FOR chapterskip.conf ******************
#--(#number). Maximum amount of noise to trigger, in terms of dB. Lower is more sensitive.
silence_audio_level=-40

#--(#number). Duration of the silence that will be detected to trigger skipping.
silence_duration=0.7

#--(0/#number). The first detcted silence_duration will be ignored for the defined seconds in this option, and it will continue skipping until the next silence_duration.
# (0 for disabled, or specify seconds).
ignore_silence_duration=1

#--(0/#number). Minimum amount of seconds accepted to skip until the configured silence_duration.
# (0 for disabled, or specify seconds)
min_skip_duration=0

#--(0/#number). Maximum amount of seconds accepted to skip until the configured silence_duration.
# (0 for disabled, or specify seconds)
max_skip_duration=120

#--(yes/no). Default is muted, however if audio was enabled due to custom mpv settings, the fast-forwarded audio can sound jarring.
force_mute_on_skip=no

************************** END OF TEMPLATE **************************
--]]

local msg = require 'mp.msg'
local options = require "mp.options"
local utils = require 'mp.utils'

local categories = {
    prologue = "^[Pp]rologue/^[Ii]ntro",
    opening = "^OP/ OP$/^[Oo]pening/[Oo]pening$",
    ending = "^ED/ ED$/^[Ee]nding/[Ee]nding$",
    credits = "^[Cc]redits/[Cc]redits$",
    preview = "[Pp]review$"
}

local o = {
    enabled = false,
    skip_once = true,
    categories = "",
    skip = "",
    silence_audio_level = -40,
    silence_duration = 0.7,
    ignore_silence_duration=1,
    min_skip_duration = 0,
    max_skip_duration = 120,
    force_mute_on_skip = false,
    history_path = "~~/chapterskip_history.json",
}

options.read_options(o, _, function() end)

local speed_state = 1
local pause_state = false
local mute_state = false
local sub_state = nil
local secondary_sub_state = nil
local vid_state = nil
local geometry_state = nil
local skip_flag = false
local initial_skip_time = 0
local state = {}
local skipped = {}
local parsed = {}
local chapter_skip = {}
local active_skips = {}
local skip_timer = nil
local history_path = mp.command_native({ "expand-path", o.history_path })

local function is_protocol(path)
    return type(path) == "string" and (path:find("^%a[%w.+-]-://") ~= nil or path:find("^%a[%w.+-]-:%?") ~= nil)
end

local function hex_to_char(x)
    return string.char(tonumber(x, 16))
end

local function url_decode(str)
    if str ~= nil then
        str = str:gsub("^%a[%a%d-_]+://", "")
              :gsub("^%a[%a%d-_]+:\\?", "")
              :gsub("%%(%x%x)", hex_to_char)
        if str:find("://localhost:?") then
            str = str:gsub("^.*/", "")
        end
        str = str:gsub("%?.+", "")
              :gsub("%+", " ")
        return str
    else
        return
    end
end

local function timestamp(duration)
    local hours = math.floor(duration / 3600)
    local minutes = math.floor(duration % 3600 / 60)
    local seconds = duration % 60
    return string.format("%02d:%02d:%06.3f", hours, minutes, seconds)
end

local function normalize(path)
    if normalize_path ~= nil then
        if normalize_path then
            path = mp.command_native({"normalize-path", path})
        else
            local directory = mp.get_property_native("working-directory", "")
            path = utils.join_path(directory, path:gsub('^%.[\\/]',''))
            if platform == "windows" then path = path:gsub("\\", "/") end
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

local function get_parent_dir(path)
    local dir = nil
    if path and not is_protocol(path) then
        path = normalize(path)
        dir = utils.split_path(path)
    end
    return dir
end

local function split_by_numbers(filename)
    local parts = {}
    local pattern = "([^%d]*)(%d+)([^%d]*)"
    for pre, num, post in string.gmatch(filename, pattern) do
        table.insert(parts, {pre = pre, num = tonumber(num), post = post})
    end
    return parts
end

local function compare_filenames(fname1, fname2)
    local parts1 = split_by_numbers(fname1)
    local parts2 = split_by_numbers(fname2)

    local min_len = math.min(#parts1, #parts2)

    for i = 1, min_len do
        local part1 = parts1[i]
        local part2 = parts2[i]

        if part1.pre ~= part2.pre then
            return false
        end

        if part1.num ~= part2.num then
            return part1.num, part2.num
        end

        if part1.post ~= part2.post then
            return false
        end
    end

    return false
end

-- Read config file
local function read_config(file_path)
    local file = io.open(file_path, "r")
    if not file then
        return {}
    end
    local content = file:read("*a")
    file:close()
    return utils.parse_json(content)
end

-- Write config file
local function write_config(file_path, data)
    local file = io.open(file_path, "w")
    if not file then
        return
    end
    file:write(utils.format_json(data))
    file:close()
end

-- Write history file
local function write_history(path)
    local dir = get_parent_dir(path)
    local fname = mp.get_property("filename")
    local title = mp.get_property_native("media-title"):gsub("%.[^%.]+$", "")
    local duration = mp.get_property_native("duration")
    if is_protocol(fname) then
        title = url_decode(title)
        fname = title
    end

    if not dir then
        local media_title, season, episode = title:match("^(.-)%s*[sS](%d+).-[eE](%d+)")
        if season then
            dir = (media_title ~= "" and media_title or title) .. " S" .. season
        else
            dir = media_title ~= "" and media_title or title
        end
    end

    local history = read_config(history_path) or {}
    history[dir] = {}
    history[dir].fname = fname
    history[dir].chapterskip = chapter_skip
    history[dir].duration = duration
    write_config(history_path, history)
end

local function format_message(msg, color)
    return string.format("{\\1c&H%s&}%s", color, msg)
end

-- Send a message to the OSD
message_overlay = mp.create_osd_overlay('ass-events')
message_timer = mp.add_timeout(1, function ()
    message_overlay:remove()
end, true)

local function send_message(msg, time, color)
    local text = color and format_message(msg, color) or msg
    message_timer:kill()
    message_timer.timeout = time or 1
    message_overlay.data = text
    message_overlay:update()
    message_timer:resume()
end

local function info(s)
    msg.info(s)
    send_message(s, 2)
end

local function matches(i, title)
    for category in string.gmatch(o.skip, " *([^;]*[^; ]) *") do
        if categories[category:lower()] then
            if string.find(category:lower(), "^idx%-") == nil then
                if title then
                    for pattern in string.gmatch(categories[category:lower()], "([^/]+)") do
                        if string.match(title, pattern) then
                            return true
                        end
                    end
                end
            else
                for pattern in string.gmatch(categories[category:lower()], "([^/]+)") do
                    if tonumber(pattern) == i then
                        return true
                    end
                end
            end
        end
    end
end

local function toggle_chapterskip()
    o.enabled = not o.enabled
end

local function chapterskip(_, current)
    if not o.enabled then return end
    for category in string.gmatch(o.categories, "([^;]+)") do
        local name, patterns = string.match(category, " *([^+>]*[^+> ]) *[+>](.*)")
        if name then
            categories[name:lower()] = patterns
        elseif not parsed[category] then
            mp.msg.warn("Improper category definition: " .. category)
        end
        parsed[category] = true
    end
    local chapters = mp.get_property_native("chapter-list")
    local skip = false
    for i, chapter in ipairs(chapters) do
        if (not o.skip_once or not skipped[i]) and matches(i, chapter.title) then
            if i == current + 1 or skip == i - 1 then
                if skip then
                    skipped[skip] = true
                end
                skip = i
            end
        elseif skip then
            mp.set_property("time-pos", chapter.time)
            skipped[skip] = true
            return
        end
    end
    if skip then
        if mp.get_property_native("playlist-count") == mp.get_property_native("playlist-pos-1") then
            return mp.set_property("time-pos", mp.get_property_native("duration"))
        end
        mp.commandv("playlist-next")
    end
end

local function add_chapter_skip(s)
    for _, exist in ipairs(chapter_skip) do
        if math.abs(exist.start - s.start) <= 0.5 and math.abs(exist.ended - s.ended) <= 0.5 then
            return
        end
    end
    table.insert(chapter_skip, s)
end

local function cache_skip()
    local chapters = mp.get_property_native("chapter-list") or {}
    local matched = false

    for i, chapter in ipairs(chapters) do
        local start_time = chapters[i - 1] and chapters[i - 1].time or 0
        local duration = chapter.time - start_time
        if math.abs(chapter.time - state.ended) <= 10 and duration <= 120 then
            matched = true
            msg.verbose("Chapter skip found: " .. (chapter.title or ("Chapter "..i)))
            add_chapter_skip({
                start = start_time,
                ended = chapter.time,
            })
        end
    end

    if not matched then
        if state.start >= 90 or state.ended - state.start > 120 then
            return
        elseif state.start <= 30 then
            state.start = 0
        end
        add_chapter_skip({
            start = state.start,
            ended = state.ended,
        })
    end
end

local function start_skip_watcher()
    if skip_timer or not o.enabled then return end
    skip_timer = mp.add_periodic_timer(0.5, function()
        local t = mp.get_property_number("time-pos")
        if not t then return end

        for i = #active_skips, 1, -1 do
            local s = active_skips[i]
            if (t >= s.start - 0.5 and t < s.ended) then
                send_message(("Auto-skip: %s-%s"):format(timestamp(s.start), timestamp(s.ended)), 2)
                msg.info(("Auto-skip: %s-%s"):format(timestamp(s.start), timestamp(s.ended)))
                mp.set_property_number("time-pos", s.ended)
                table.remove(active_skips, i)
            elseif t >= s.ended then
                table.remove(active_skips, i)
            end
        end

        if #active_skips == 0 then
            skip_timer:kill()
            skip_timer = nil
        end
    end)
end

local function add_active_skip(s)
    for _, exist in ipairs(active_skips) do
        if math.abs(exist.start - s.start) <= 0.5 and math.abs(exist.ended - s.ended) <= 0.5 then
            return
        end
    end
    table.insert(active_skips, { start = s.start, ended = s.ended })
    start_skip_watcher()
end

local function check_skip()
    local path = mp.get_property("path")
    if not path then return end

    local chapters = mp.get_property_native("chapter-list") or {}
    local history = read_config(history_path) or {}
    local filename = mp.get_property("filename")
    local title = mp.get_property_native("media-title"):gsub("%.[^%.]+$", "")
    local dir = get_parent_dir(path)

    if is_protocol(filename) then
        title = url_decode(title)
        filename = title
    end

    if not dir then
        local media_title, season, episode = title:match("^(.-)%s*[sS](%d+).-[eE](%d+)")
        if season then
            dir = (media_title ~= "" and media_title or title) .. " S" .. string.format("%02d", tonumber(season))
        else
            dir = media_title ~= "" and media_title or title
        end
    end

    if not history[dir] or not history[dir].chapterskip then
        return
    end

    local fname = history[dir].fname
    local skip = history[dir].chapterskip
    if fname ~= filename and not compare_filenames(fname, filename) then
        return
    end

    if next(skip) == nil then return end

    if next(chapters) == nil then
        for _, s in ipairs(skip) do
            add_active_skip(s)
        end
        return
    end

    for _, s in ipairs(skip) do
        local matched = false
        for i, chapter in ipairs(chapters) do
            local start_time = chapters[i - 1] and chapters[i - 1].time or 0
            local end_time   = chapter.time
            if math.abs(end_time - start_time - (s.ended - s.start)) <= 0.1 then
                matched = true
                add_active_skip({ start = start_time, ended = end_time })
                break
            end
        end
        if not matched then
            add_active_skip(s)
        end
    end
end

local function toggle_markskip()
    local pos, err = mp.get_property_number("time-pos")
    if not pos then
        send_message("Failed to get timestamp", 2)
        msg.error("Failed to get timestamp: " .. err)
        return
    end
    if mark_pos then
        local shift, endpos = mark_pos, pos
        if shift > endpos then
            shift, endpos = endpos, shift
        elseif shift == endpos then
            send_message("Mark fragment is empty", 2)
            return
        end
        mark_pos = nil
        state.ended = endpos
        info(string.format("Mark skip fragment: %s-%s", timestamp(shift), timestamp(endpos)))
        cache_skip()
    else
        mark_pos = pos
        state.start = pos
        info(string.format("Marked %s as start position", timestamp(pos)))
    end
end

local function restoreProp(pause)
    if not pause then pause = pause_state end
    local fullscreen = mp.get_property("fullscreen")

    mp.set_property("vid", vid_state)
    if not fullscreen then
        mp.set_property("geometry", geometry_state)
    end
    mp.set_property_bool("mute", mute_state)
    mp.set_property("speed", speed_state)
    mp.unobserve_property(foundSilence)
    mp.command("no-osd af remove @skiptosilence")
    mp.set_property_bool("pause", pause)
    mp.set_property("sub-visibility", sub_state)
    mp.set_property("secondary-sub-visibility", secondary_sub_state)
    timer:kill()
    skip_flag = false
end

local function handleMinMaxDuration(timepos)
    if not skip_flag then return end
    if not timepos then timepos = mp.get_property_number("time-pos") end

    skip_duration = timepos - initial_skip_time
    if o.min_skip_duration > 0 and skip_duration <= o.min_skip_duration then
        restoreProp()
        mp.osd_message('Skipping Cancelled\nSilence is less than configured minimum')
        msg.info('Skipping Cancelled\nSilence is less than configured minimum')
        return true
    end
    if o.max_skip_duration > 0 and skip_duration >= o.max_skip_duration then
        restoreProp()
        mp.osd_message('Skipping Cancelled\nSilence is more than configured maximum')
        msg.info('Skipping Cancelled\nSilence is more than configured maximum')
        return true
    end
    return false
end

local function skippedMessage()
    state.ended = mp.get_property_native("time-pos")
    cache_skip()
    mp.osd_message("Skipped to silence at " .. mp.get_property_osd("time-pos"))
    msg.info("Skipped to silence at " .. mp.get_property_osd("time-pos"))
end

function foundSilence(name, value)
    if value == "{}" or value == nil then
        return
    end

    timecode = tonumber(string.match(value, "%d+%.?%d+"))
    if timecode == nil or timecode < initial_skip_time + o.ignore_silence_duration then
        return
    end

    if handleMinMaxDuration(timecode) then return end

    restoreProp()

    mp.add_timeout(0.05, skippedMessage)
    skip_flag = false
end

local function doSkip()
    state.start = mp.get_property_native("time-pos") or 0
    local audio = mp.get_property_number("aid") or 0
    if audio == 0 then
        mp.osd_message("No audio stream detected")
        msg.info("No audio stream detected")
        return
    end
    if skip_flag then return end
    initial_skip_time = state.start
    if math.floor(initial_skip_time) == math.floor(mp.get_property_native('duration') or 0) then return end

    local width = mp.get_property_native("osd-width")
    local height = mp.get_property_native("osd-height")
    local fullscreen = mp.get_property_native("fullscreen")
    geometry_state = mp.get_property("geometry")
    if not fullscreen then
        mp.set_property_native("geometry", ("%dx%d"):format(width, height))
    end

    mp.command(
        "no-osd af add @skiptosilence:lavfi=[silencedetect=noise=" ..
        o.silence_audio_level .. "dB:d=" .. o.silence_duration .. "]"
    )

    mp.observe_property("af-metadata/skiptosilence", "string", foundSilence)

    sub_state = mp.get_property("sub-visibility")
    mp.set_property("sub-visibility", "no")
    secondary_sub_state = mp.get_property("secondary-sub-visibility")
    mp.set_property("secondary-sub-visibility", "no")
    vid_state = mp.get_property("vid")
    mp.set_property("vid", "no")
    mute_state = mp.get_property_native("mute")
    if o.force_mute_on_skip then
        mp.set_property_bool("mute", true)
    end
    pause_state = mp.get_property_native("pause")
    mp.set_property_bool("pause", false)
    speed_state = mp.get_property_native("speed")
    mp.set_property("speed", 100)
    skip_flag = true

    timer = mp.add_periodic_timer(0.5, function()
        local video_time = (mp.get_property_native("time-pos") or 0)
        handleMinMaxDuration(video_time)
    end)
end


mp.observe_property("chapter", "number", chapterskip)
mp.register_event("file-loaded", function()
    state = {}
    skipped = {}
    chapter_skip = {}
    check_skip()
end)

mp.observe_property('pause', 'bool', function(_, value)
    if value and skip_flag then
        restoreProp(true)
    end
end)

mp.observe_property('percent-pos', 'number', function(_, value)
    if skip_flag and value and value > 99 then
        local fullscreen = mp.get_property("fullscreen")
        mp.set_property("vid", vid_state)
        if not fullscreen then
            mp.set_property("geometry", geometry_state)
        end
    end
end)

mp.add_hook('on_unload', 9, function()
    if next(chapter_skip) ~= nil then
        write_history(mp.get_property("path"))
    end
    state = nil
    skipped = nil
    chapter_skip = nil
    if skip_flag then
        restoreProp()
    end
end)

mp.register_script_message("chapter-skip", toggle_chapterskip)
mp.register_script_message("toggle-markskip", toggle_markskip)
mp.register_script_message("skip-to-silence", doSkip)