--[[
  * chapterskip.lua v.2025-08-25
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
    opening = "^OP/ OP$/^[Oo]pening/[Oo]pening$/^Intro%s*Start/オープニング$/^片头$/片头开始$",
    ending = "^ED/ ED$/^[Ee]nding/[Ee]nding$/エンディング$",
    credits = "^[Cc]redits/[Cc]redits$",
    preview = "[Pp]review$"
}

local o = {
    mode = "manual",
    -- eng=English, chs=Chinese Simplified
    language = 'eng',
    timeout = 15,
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
local skip_prompt_queue = {}
local confirm_timer = nil
local skip_timer = nil
local history_path = mp.command_native({ "expand-path", o.history_path })

local locals = {
    ['eng'] = {
        skip_detected = 'A skippable segment has been detected.',
        skip_confirm  = 'Do you want to skip it?',
        countdown     = 'Time remaining: %d seconds',
        auto_skip     = 'Auto-skip: %s-%s',
        chapter_mode  = 'Chapter skip mode: ',
        skipping_chapter = 'Skipping chapter: ',
        mark_fragment_empty = 'Mark fragment is empty',
        mark_start_pos = 'Marked %s as start position',
        mark_fragment = 'Mark skip fragment: %s-%s',
        no_audio = 'No audio stream detected',
        skipped_to_silence = 'Skipped to silence at %s',
        skip_cancel_min = 'Skipping Cancelled\nSilence is less than configured minimum',
        skip_cancel_max = 'Skipping Cancelled\nSilence is more than configured maximum',
        failed_timestamp = 'Failed to get timestamp'
    },
    ['chs'] = {
        skip_detected = '检测到可跳过的片段',
        skip_confirm  = '是否跳过该片段？',
        countdown     = '倒计时：%d 秒',
        auto_skip     = '自动跳过: %s-%s',
        chapter_mode  = '跳过章节模式: ',
        skipping_chapter = '跳过章节: ',
        mark_fragment_empty = '标记片段为空',
        mark_start_pos = '标记 %s 为起始位置',
        mark_fragment = '标记跳过片段: %s-%s',
        no_audio = '未检测到音频流',
        skipped_to_silence = '已跳过到静音点 %s',
        skip_cancel_min = '取消跳过\n静音时长低于最小值',
        skip_cancel_max = '取消跳过\n静音时长超过最大值',
        failed_timestamp = '获取时间戳失败'
    }
}

local texts = locals[o.language] or locals['eng']

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

local function show_message(msg, time, color)
    local text = color and format_message(msg, color) or msg
    message_timer:kill()
    message_timer.timeout = time or 1
    message_overlay.data = text
    message_overlay:update()
    message_timer:resume()
end

local function info(s)
    msg.info(s)
    show_message(s, 2)
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

function cancel_skip_prompt()
    if confirm_timer then
        confirm_timer:kill()
        confirm_timer = nil
    end
    mp.remove_key_binding("skip-confirm")
    mp.remove_key_binding("skip-cancel")
    show_message("", 0)

    if #skip_prompt_queue > 0 then
        local next_prompt = table.remove(skip_prompt_queue, 1)
        show_skip_prompt(next_prompt.action, next_prompt.skip_obj)
    end
end

function confirm_skip_prompt(action)
    cancel_skip_prompt()
    if action then action() end
end

function show_skip_prompt(action, skip_obj)
    if confirm_timer then
        table.insert(skip_prompt_queue, {action = action, skip_obj = skip_obj})
        return
    end

    local countdown = o.timeout
    local function update_msg()
        if not confirm_timer or not confirm_timer:is_enabled() then
            return
        end

        local yn_text = "{\\c&H00FFFF&}[y/n]{\\c&HFFFFFF&}"
        show_message(
            texts.skip_detected .. " " .. (skip_obj.title or "") .. "\n" ..
            texts.skip_confirm .. " " .. yn_text .. "\n" ..
            texts.countdown:format(countdown),
            1,
            "FFFF00"
        )

        countdown = countdown - 1
        if countdown < 0 then
            if skip_obj then skip_obj.cancelled = true end
            cancel_skip_prompt()
        end
    end

    update_msg()
    confirm_timer = mp.add_periodic_timer(1, update_msg)

    mp.add_forced_key_binding("y", "skip-confirm", function()
        confirm_skip_prompt(action)
    end)
    mp.add_forced_key_binding("n", "skip-cancel", function()
        if skip_obj then skip_obj.cancelled = true end
        cancel_skip_prompt()
    end)
end

local function start_skip_watcher()
    if skip_timer then return end
    skip_timer = mp.add_periodic_timer(0.5, function()
        local t = mp.get_property_number("time-pos")
        local paused = mp.get_property_native("pause")
        if not t or o.mode == "none" or paused then return end

        local i = 1
        while i <= #active_skips do
            local s = active_skips[i]
            if s.cancelled then
                table.remove(active_skips, i)
            elseif t >= s.start - 0.5 and t <= s.ended then
                if o.mode == "auto" then
                    info((texts.auto_skip):format(timestamp(s.start), timestamp(s.ended), s.title))
                    mp.set_property_number("time-pos", s.ended)
                    s.triggered = true
                    table.remove(active_skips, i)
                elseif o.mode == "manual" and not s.triggered then
                    s.triggered = true
                    show_skip_prompt(function()
                        info((texts.auto_skip):format(timestamp(s.start), timestamp(s.ended), s.title))
                        mp.set_property_number("time-pos", s.ended)
                        for j = #active_skips, 1, -1 do
                            if active_skips[j] == s then
                                table.remove(active_skips, j)
                                break
                            end
                        end
                    end, s)
                    i = i + 1
                else
                    i = i + 1
                end
            elseif t < s.start - 0.5 then
                if s.triggered then
                    s.cancelled = true
                    table.remove(active_skips, i)
                    cancel_skip_prompt()
                else
                    i = i + 1
                end
            else
                table.remove(active_skips, i)
                cancel_skip_prompt()
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
    table.insert(active_skips, { start = s.start, ended = s.ended, title = s.title, triggered = false })
    start_skip_watcher()
end

local function chapterskip(_, current)
    if o.mode == "none" then return end
    for category in string.gmatch(o.categories, "([^;]+)") do
        local name, patterns = string.match(category, " *([^+>]*[^+> ]) *[+>](.*)")
        if name then
            categories[name:lower()] = patterns
        elseif not parsed[category] then
            msg.warn("Improper category definition: " .. category)
        end
        parsed[category] = true
    end
    local chapters = mp.get_property_native("chapter-list")
    for i, chapter in ipairs(chapters) do
        if not skipped[i] and matches(i, chapter.title) then
            if i == current + 1 then
                skipped[i] = true
                local skip_time = chapters[i + 1] and chapters[i + 1].time or mp.get_property_native("duration")
                add_active_skip({
                    start = chapter.time,
                    ended = skip_time,
                    title = chapter.title,
                })
            end
        end
    end
end

local function check_skip()
    local path = mp.get_property("path")
    if not path then return end

    local chapters = mp.get_property_native("chapter-list") or {}
    local history = read_config(history_path) or {}
    local duration = mp.get_property_number("duration") or 0
    local filename = mp.get_property("filename")
    local file_ext = filename:lower():match("%.([^%.]+)$") or ""
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

    local file_history = history[dir]
    if not file_history or not file_history.chapterskip then return end

    local skip_list = file_history.chapterskip
    local fname = file_history.fname
    local fname_ext = fname:lower():match("%.([^%.]+)$") or ""

    if (not is_protocol(path) and file_ext ~= fname_ext) or
    (fname ~= filename and not compare_filenames(fname, filename)) then
        return
    end

    table.sort(skip_list, function(a, b) return a.start < b.start end)

    if next(skip_list) == nil then return end
    if next(chapters) == nil then
        for _, s in ipairs(skip_list) do
            add_active_skip(s)
        end
        return
    end

    local used_chapters = {}
    for _, s in ipairs(skip_list) do
        local matched = false
        for i, chapter in ipairs(chapters) do
            if not used_chapters[i] then
                local start_time = chapter.time
                local end_time   = chapters[i + 1] and chapters[i + 1].time or duration
                if math.abs((end_time - start_time) - (s.ended - s.start)) <= 0.05 then
                    matched = true
                    used_chapters[i] = true
                    add_active_skip({ start = start_time, ended = end_time })
                    break
                end
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
        show_message(texts.failed_timestamp, 2)
        msg.error("Failed to get timestamp: " .. err)
        return
    end
    if mark_pos then
        local shift, endpos = mark_pos, pos
        if shift > endpos then
            shift, endpos = endpos, shift
        elseif shift == endpos then
            show_message(texts.mark_fragment_empty, 2)
            return
        end
        mark_pos = nil
        state.ended = endpos
        info(string.format(texts.mark_fragment, timestamp(shift), timestamp(endpos)))
        cache_skip()
    else
        mark_pos = pos
        state.start = pos
        info(string.format(texts.mark_start_pos, timestamp(pos)))
    end
end

local function switch_chapterskip()
    if o.mode == "none" then
        o.mode = "auto"
    elseif o.mode == "auto" then
        o.mode = "manual"
    else
        o.mode = "none"
    end

    info(texts.chapter_mode .. o.mode)
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
    if timer then timer:kill() end
    skip_flag = false
end

local function handleMinMaxDuration(timepos)
    if not skip_flag then return end
    if not timepos then timepos = mp.get_property_number("time-pos") end

    skip_duration = timepos - initial_skip_time
    if o.min_skip_duration > 0 and skip_duration <= o.min_skip_duration then
        restoreProp()
        info(texts.skip_cancel_min)
        return true
    end
    if o.max_skip_duration > 0 and skip_duration >= o.max_skip_duration then
        restoreProp()
        info(texts.skip_cancel_max)
        return true
    end
    return false
end

local function skippedMessage()
    state.ended = mp.get_property_native("time-pos")
    cache_skip()
    info(string.format(texts.skipped_to_silence, mp.get_property_osd("time-pos")))
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
        info(texts.no_audio)
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
mp.register_event("file-loaded", check_skip)

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

mp.add_hook('on_unload', 10, function()
    if confirm_timer then
        cancel_skip_prompt()
    end
    if chapter_skip and next(chapter_skip) ~= nil then
        write_history(mp.get_property("path"))
    end
    skip_timer = nil
    state = {}
    parsed = {}
    skipped = {}
    chapter_skip = {}
    active_skips = {}
    skip_prompt_queue = {}
    if skip_flag then
        restoreProp()
    end
end)

mp.register_script_message("chapter-skip", switch_chapterskip)
mp.register_script_message("toggle-markskip", toggle_markskip)
mp.register_script_message("skip-to-silence", doSkip)
