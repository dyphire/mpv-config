-- modified from https://github.com/rkscv/danmaku/blob/main/danmaku.lua
local msg = require('mp.msg')
local utils = require("mp.utils")
local unpack = unpack or table.unpack

local INTERVAL = options.vf_fps and 0.01 or 0.001
local osd_width, osd_height, pause = 0, 0, true

local overlay = mp.create_osd_overlay('ass-events')

local function realtime_position_text(event, pos, height, delay)
    local displayarea = tonumber(height * options.displayarea)
    if not event.move then
        local _, current_y = unpack(event.pos)
        if not current_y or tonumber(current_y) > displayarea then return end
        if event.style ~= "SP" and event.style ~= "MSG" then
            return string.format("{\\an8}%s", event.text)
        else
            return string.format("{\\an7}%s", event.text)
        end
    end

    local x1, y1, x2, y2 = unpack(event.move)
    -- 计算移动的时间范围
    local duration = event.end_time - event.start_time  --mean: options.scrolltime
    local progress = (pos - event.start_time - delay) / duration  -- 移动进度 [0, 1]

    -- 计算当前坐标
    local current_x = tonumber(x1 + (x2 - x1) * progress)
    local current_y = tonumber(y1 + (y2 - y1) * progress)

    -- 移除 \move 标签并应用当前坐标
    local clean_text = event.text:gsub("\\move%(.-%)", "")
    if current_y > displayarea then return end
    if event.style ~= "SP" and event.style ~= "MSG" then
        return string.format("{\\pos(%.1f,%.1f)\\an8}%s", current_x, current_y, clean_text)
    else
        return string.format("{\\pos(%.1f,%.1f)\\an7}%s", current_x, current_y, clean_text)
    end
end

function render()
    if COMMENTS == nil then return end

    local pos, err = mp.get_property_number('time-pos')
    if err ~= nil then
        return msg.error(err)
    end

    local delay = get_delay_for_time(DELAYS, pos)

    local fontname = options.fontname
    local fontsize = options.fontsize
    local alpha = string.format("%02X", (1 - tonumber(options.opacity)) * 255)

    local width, height = 1920, 1080
    local ratio = osd_width / osd_height
    if width / height < ratio then
        height = width / ratio
        fontsize = options.fontsize - ratio * 2
    end

    local ass_events = {}

    for _, event in ipairs(COMMENTS) do
        if pos >= event.start_time + delay and pos <= event.end_time + delay then
            local text = realtime_position_text(event, pos, height, delay)
            if text then
                text = text:gsub("&#%d+;","")
            end

            if text and text:match("\\fs%d+") then
                text = text:gsub("\\fs(%d+)", function(size)
                    return string.format("\\fs%d", size * 1.5)
                end)
            end

            -- 构建 ASS 字符串
            local ass_text = text and string.format("{\\rDefault\\fn%s\\fs%d\\c&HFFFFFF&\\alpha&H%s\\bord%s\\shad%s\\b%s\\q2}%s",
                fontname, fontsize, alpha, options.outline, options.shadow, options.bold and "1" or "0", text)

            table.insert(ass_events, ass_text)
        end
    end

    overlay.res_x = width
    overlay.res_y = height
    overlay.data = table.concat(ass_events, '\n')
    overlay:update()
end

local timer = mp.add_periodic_timer(INTERVAL, render, true)

function render_danmaku(from_menu, no_osd)
    if ENABLED and (from_menu or get_danmaku_visibility()) then
        if not no_osd then
            show_loaded(true)
        end
        mp.commandv("script-message-to", "uosc", "set", "show_danmaku", "on")
        show_danmaku_func()
    else
        show_message("")
        hide_danmaku_func()
    end
end

local function filter_state(label, name)
    local filters = mp.get_property_native("vf")
    for _, filter in pairs(filters) do
        if filter.label == label or filter.name == name
        or filter.params[name] ~= nil then
            return true
        end
    end
    return false
end

function show_danmaku_func()
    mp.set_property_bool(HAS_DANMAKU, true)
    set_danmaku_visibility(true)
    render()
    if not pause then
        timer:resume()
    end
    if options.vf_fps then
        local display_fps = mp.get_property_number('display-fps')
        local video_fps = mp.get_property_number('estimated-vf-fps')
        if (display_fps and display_fps < 58) or (video_fps and video_fps > 58) then
            return
        end
        if not filter_state("danmaku", "fps") then
            mp.commandv("vf", "append", string.format("@danmaku:fps=fps=%s", options.fps))
        end
    end
end

function hide_danmaku_func()
    timer:kill()
    mp.set_property_bool(HAS_DANMAKU, false)
    set_danmaku_visibility(false)
    overlay:remove()
    if filter_state("danmaku") then
        mp.commandv("vf", "remove", "@danmaku")
    end
end

local message_overlay = mp.create_osd_overlay('ass-events')
local message_timer = mp.add_timeout(3, function()
    message_overlay:remove()
end, true)

function show_message(text, time)
    message_timer.timeout = time or 3
    message_timer:kill()
    message_overlay:remove()
    local message = string.format("{\\an%d\\pos(%d,%d)}%s", options.message_anlignment,
       options.message_x, options.message_y, text)
    local width, height = 1920, 1080
    local ratio = osd_width / osd_height
    if width / height < ratio then
        height = width / ratio
    end
    message_overlay.res_x = width
    message_overlay.res_y = height
    message_overlay.data = message
    message_overlay:update()
    message_timer:resume()
end

mp.observe_property('osd-width', 'number', function(_, value) osd_width = value or osd_width end)
mp.observe_property('osd-height', 'number', function(_, value) osd_height = value or osd_height end)
mp.observe_property('display-fps', 'number', function(_, value)
    if value ~= nil then
        local interval = 1 / value / 10
        if interval > INTERVAL then
            timer:kill()
            timer = mp.add_periodic_timer(interval, render, true)
            if ENABLED then
                timer:resume()
            end
        else
            timer:kill()
            timer = mp.add_periodic_timer(INTERVAL, render, true)
            if ENABLED then
                timer:resume()
            end
        end
    end
end)
mp.observe_property('pause', 'bool', function(_, value)
    if value ~= nil then
        pause = value
    end
    if ENABLED then
        if pause then
            timer:kill()
        elseif COMMENTS ~= nil then
            timer:resume()
        end
    end
end)

mp.register_event('playback-restart', function(event)
    if event.error then
        return msg.error(event.error)
    end
    if ENABLED and COMMENTS ~= nil then
        render()
    end
end)

mp.add_hook("on_unload", 50, function()
    COMMENTS, DELAY = nil, 0
    timer:kill()
    overlay:remove()
    mp.set_property_native(DELAY_PROPERTY, 0)
    if filter_state("danmaku") then
        mp.commandv("vf", "remove", "@danmaku")
    end

    local files_to_remove = {
        file1 = utils.join_path(DANMAKU_PATH, "temp-" .. PID .. ".mp4"),
    }

    if options.save_danmaku then
        save_danmaku(true)
    end

    for _, file in pairs(files_to_remove) do
        if file_exists(file) then
            os.remove(file)
        end
    end

    DANMAKU = {sources = {}, count = 1}
end)
