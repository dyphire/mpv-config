local msg   = require 'mp.msg'
local utils = require 'mp.utils'
local s2t   = require("dicts/s2t_chars")
local t2s   = require("dicts/t2s_chars")

local function ass_escape(text)
    return text:gsub("\\", "\\\\")
               :gsub("{", "\\{")
               :gsub("}", "\\}")
               :gsub("\n", "\\N")
end

local function xml_unescape(str)
    return str:gsub("&quot;", "\"")
              :gsub("&apos;", "'")
              :gsub("&gt;", ">")
              :gsub("&lt;", "<")
              :gsub("&amp;", "&")
end

local function decode_html_entities(text)
    return text:gsub("&#x([%x]+);", function(hex)
        local codepoint = tonumber(hex, 16)
        return unicode_to_utf8(codepoint)
    end):gsub("&#(%d+);", function(dec)
        local codepoint = tonumber(dec, 10)
        return unicode_to_utf8(codepoint)
    end)
end

-- 加载黑名单模式
local function load_blacklist_patterns(filepath)
    local patterns = {}
    if not file_exists(filepath) then
        return patterns
    end
    local file = io.open(filepath, "r")
    if not file then
        msg.error("无法打开黑名单文件: " .. filepath)
        return patterns
    end

    for line in file:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then
            table.insert(patterns, line)
        end
    end

    file:close()
    return patterns
end

local blacklist_file = mp.command_native({ "expand-path", options.blacklist_path })
local black_patterns = load_blacklist_patterns(blacklist_file)

-- 检查字符串是否在黑名单中
function is_blacklisted(str, patterns)
    for _, pattern in ipairs(patterns) do
        local ok, result = pcall(function()
            return str:match(pattern)
        end)

        if ok and result then
            return true, pattern
        elseif not ok then
            -- msg.debug("黑名单规则错误，跳过: " .. pattern .. "，错误信息：" .. result)
        end
    end
    return false
end

-- 简繁转换
local function convert(text, dict)
    return text:gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
        return dict[c] or c
    end)
end

local function ch_convert(str)
    if options.chConvert == 1 then
        return convert(str, t2s)
    elseif options.chConvert == 2 then
        return convert(str, s2t)
    end
    return str
end

local ch_convert_cache = {}
local ch_cache_keys = {}
local ch_cache_max = 5000

local function ch_convert_cached(text)
    if type(text) ~= "string" or text == "" then return text end
    local cached = ch_convert_cache[text]
    if cached ~= nil then return cached end

    local converted = ch_convert(text)
    ch_convert_cache[text] = converted
    ch_cache_keys[#ch_cache_keys+1] = text

    if #ch_cache_keys > ch_cache_max then
        local old_key = table.remove(ch_cache_keys, 1)
        ch_convert_cache[old_key] = nil
    end

    return converted
end

-- 合并重复弹幕
local function merge_duplicate_danmaku(danmakus, threshold)
    if not threshold or tonumber(threshold) < 0 then return danmakus end

    local groups = {}

    for _, d in ipairs(danmakus) do
        local key = d.type .. "|" .. d.color .. "|" .. d.text
        if not groups[key] then groups[key] = {} end
        table.insert(groups[key], d)
    end

    local merged = {}

    for _, group in pairs(groups) do
        table.sort(group, function(a, b) return a.time < b.time end)

        local i = 1
        while i <= #group do
            local base = group[i]
            local times = { base.time }
            local count = 1
            local j = i + 1

            while j <= #group and math.abs(group[j].time - base.time) <= threshold do
                table.insert(times, group[j].time)
                count = count + 1
                j = j + 1
            end

            local same_time = true
            for k = 2, #times do
                if times[k] ~= times[1] then
                    same_time = false
                    break
                end
            end

            local danmaku = {
                time = base.time,
                type = base.type,
                size = base.size,
                color = base.color,
                text = base.text,
            }
            if count > 2 or not same_time then
                danmaku.text = danmaku.text .. string.format("x%d", count)
            end

            table.insert(merged, danmaku)
            i = j
        end
    end

    table.sort(merged, function(a, b) return a.time < b.time end)
    return merged
end

-- 限制每屏弹幕条数
local function limit_danmaku(danmakus, limit)
    if not limit or limit <= 0 then
        return danmakus
    end

    local window = {}
    for _, d in ipairs(danmakus) do
        for i = #window, 1, -1 do
            if window[i].end_time <= d.start_time then
                table.remove(window, i)
            end
        end

        if #window < limit then
            table.insert(window, d)
        else
            local max_idx = 1
            for i = 2, #window do
                if window[i].end_time > window[max_idx].end_time then
                    max_idx = i
                end
            end
            if window[max_idx].end_time > d.end_time then
                window[max_idx].drop = true
                window[max_idx] = d
            else
                d.drop = true
            end
        end
    end

    local result = {}
    for _, d in ipairs(danmakus) do
        if not d.drop then
            table.insert(result, d)
        end
    end
    return result
end

-- 解析 XML 弹幕
local function parse_xml_danmaku(xml_string, delay_segments)
    local danmakus = {}
    -- [^>]* 匹配其他 attributes
    -- %f[^%s] 确保 p= 前面是空白字符
    for p_attr, text in xml_string:gmatch('<d%s+[^>]*%f[^%s]p="([^"]+)"[^>]*>([^<]+)</d>') do
        local params = {}
        local i = 1
        for val in p_attr:gmatch("([^,]+)") do
            params[i] = tonumber(val)
            i = i + 1
        end

        if params[1] and params[2]  and params[3] and params[4] then
            local base_time = params[1]
            local delay = get_delay_for_time(delay_segments, base_time)
            table.insert(danmakus, {
                time = base_time + delay,
                type = params[2] or 1,
                size = params[3] or 25,
                color = params[4] or 0xFFFFFF,
                text = xml_unescape(text)
            })
        end
    end

    table.sort(danmakus, function(a, b) return a.time < b.time end)
    return danmakus
end

-- 解析 JSON 弹幕
local function parse_json_danmaku(json_string, delay_segments)
    local danmakus = {}
    if json_string:sub(1, 3) == "\239\187\191" then
        json_string = json_string:sub(4)
    end

    local json = utils.parse_json(json_string)
    if not json or type(json) ~= "table" then
        msg.info("JSON 解析失败")
        return danmakus
    end

    for _, entry in ipairs(json) do
        local c = entry.c
        local text = entry.m or ""
        if type(c) == "string" then
            local params = {}
            local i = 1
            for val in c:gmatch("([^,]+)") do
                params[i] = tonumber(val)
                i = i + 1
            end

            if params[1] and params[2] and params[3] and params[4] then
                local base_time = params[1]
                local delay = get_delay_for_time(delay_segments, base_time)
                table.insert(danmakus, {
                    time = base_time + delay,
                    color = params[2] or 0xFFFFFF,
                    type = params[3] or 1,
                    size = params[4] or 25,
                    text = text
                })
            end
        end
    end

    table.sort(danmakus, function(a, b) return a.time < b.time end)
    return danmakus
end

-- 解析弹幕文件
function parse_danmaku_files(danmaku_input, delays)
    local DANMAKU_PATHs = {}
    if type(danmaku_input) == "string" then
        DANMAKU_PATHs = { danmaku_input }
    else
        for i, input in ipairs(danmaku_input) do
            DANMAKU_PATHs[#DANMAKU_PATHs + 1] = input
        end
    end

    local all_danmaku = {}

    for i, DANMAKU_PATH in ipairs(DANMAKU_PATHs) do
        if file_exists(DANMAKU_PATH) then
            local content = read_file(DANMAKU_PATH)
            if content then
                local parsed = {}
                local delay_segments = delays and delays[i] or {}
                if DANMAKU_PATH:match("%.xml$") then
                    parsed = parse_xml_danmaku(content, delay_segments)
                elseif DANMAKU_PATH:match("%.json$") then
                    parsed = parse_json_danmaku(content, delay_segments)
                end

                for _, d in ipairs(parsed) do
                    local matched, pattern = is_blacklisted(d.text, black_patterns)
                    if not matched then
                        d.text = ch_convert_cached(d.text)
                        table.insert(all_danmaku, d)
                    else
                        -- msg.debug("命中黑名单: " .. pattern)
                    end
                end
            else
                msg.info("无法读取文件内容: " .. DANMAKU_PATH)
            end
        else
            msg.info("文件不存在: " .. DANMAKU_PATH)
        end
    end

    if #all_danmaku == 0 then
        msg.info("未能解析任何弹幕")
        return nil
    end

    if options.max_screen_danmaku > 0 and options.merge_tolerance <= 0 then
        options.merge_tolerance = options.scrolltime
    end

    -- 按时间排序
    table.sort(all_danmaku, function(a, b)
        return a.time < b.time
    end)

    all_danmaku = merge_duplicate_danmaku(all_danmaku, options.merge_tolerance)

    return all_danmaku
end

--# 弹幕数组与布局算法 (Danmaku Array & Layout Algorithms)
local DanmakuArray = {}
DanmakuArray.__index = DanmakuArray

function DanmakuArray:new(res_x, res_y, font_size)
    local obj = {
        solution_y = res_y,
        font_size = font_size,
        rows = math.floor(res_y / font_size),
        time_length_array = {}
    }
    for i = 1, obj.rows do
        obj.time_length_array[i] = { time = -1, length = 0 }
    end
    setmetatable(obj, self)
    return obj
end

function DanmakuArray:set_time_length(row, time, length)
    if row > 0 and row <= self.rows then
        self.time_length_array[row] = { time = time, length = length }
    end
end

function DanmakuArray:get_time(row)
    if row > 0 and row <= self.rows then
        return self.time_length_array[row].time
    end
    return -1
end

function DanmakuArray:get_length(row)
    if row > 0 and row <= self.rows then
        return self.time_length_array[row].length
    end
    return 0
end

-- 滚动弹幕 Y 坐标算法
function get_position_y(font_size, appear_time, text_length, resolution_x, roll_time, array)
    local velocity = (text_length + resolution_x) / roll_time

    for i = 1, array.rows do
        local previous_appear_time = array:get_time(i)
        if array:get_time(i) < 0 then
            array:set_time_length(i, appear_time, text_length)
            return 1 + (i - 1) * font_size
        end

        local previous_length = array:get_length(i)
        local previous_velocity = (previous_length + resolution_x) / roll_time
        local delta_velocity = velocity - previous_velocity
        local delta_x = (appear_time - previous_appear_time) * previous_velocity - previous_length

        if delta_x >= 0 then
            if delta_velocity <= 0 then
                array:set_time_length(i, appear_time, text_length)
                return 1 + (i - 1) * font_size
            end

            local delta_time = delta_x / delta_velocity
            if delta_time >= roll_time then
                array:set_time_length(i, appear_time, text_length)
                return 1 + (i - 1) * font_size
            end
        end
    end
    -- 所有行都被占用，放弃渲染
    return nil
end

-- 固定弹幕 Y 坐标算法
function get_fixed_y(font_size, appear_time, fixtime, array, from_top)
    local row_start, row_end, row_step
    if from_top then
        row_start, row_end, row_step = 1, array.rows, 1
    else
        row_start, row_end, row_step = array.rows, 1, -1
    end

    for i = row_start, row_end, row_step do
        local previous_appear_time = array:get_time(i)
        if previous_appear_time < 0 then
            array:set_time_length(i, appear_time, 0)
            return (i - 1) * font_size + 1
        else
            local delta_time = appear_time - previous_appear_time
            if delta_time > fixtime then
                array:set_time_length(i, appear_time, 0)
                return (i - 1) * font_size + 1
            end
        end
    end
    -- 所有行都被占用，放弃渲染
    return nil
end

-- 将弹幕转换为 ASS 格式
function convert_danmaku_to_ass(all_danmaku, danmaku_file)
    if #all_danmaku == 0 then
        msg.info("弹幕文件为空或解析失败")
        return false
    end
    msg.info("已解析 " .. #all_danmaku .. " 条弹幕")

    local alpha = string.format("%02X", (1 - tonumber(options.opacity)) * 255)
    local bold = options.bold and "1" or "0"
    local fontsize = tonumber(options.fontsize) or 50
    local scrolltime = tonumber(options.scrolltime) or 15
    local fixtime = tonumber(options.fixtime) or 5
    local outline = tonumber(options.outline) or 1.0
    local shadow = tonumber(options.shadow) or 0.0

    local res_x = 1920
    local res_y = 1080

    local roll_array = DanmakuArray:new(res_x, res_y, fontsize)
    local top_array = DanmakuArray:new(res_x, res_y, fontsize)

    local ass_header = string.format([[
[Script Info]
Title: DanmakuConvert for mpv
ScriptType: v4.00+
Collisions: Normal
PlayResX: %d
PlayResY: %d
Timer: 100.0000
WrapStyle: 2
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: R2L,%s,%d,&H%sFFFFFF,&H00FFFFFF,&H00000000,&H%s000000,%d,0,0,0,100,100,0,0,1,%.1f,%.1f,7,0,0,0,1
Style: TOP,%s,%d,&H%sFFFFFF,&H00FFFFFF,&H00000000,&H%s000000,%d,0,0,0,100,100,0,0,1,%.1f,%.1f,8,0,0,0,1
Style: BTM,%s,%d,&H%sFFFFFF,&H00FFFFFF,&H00000000,&H%s000000,%d,0,0,0,100,100,0,0,1,%.1f,%.1f,2,0,0,0,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
]], res_x, res_y, options.fontname, fontsize, alpha, alpha, bold, outline, shadow,
    options.fontname, fontsize, alpha, alpha, bold, outline, shadow,
    options.fontname, fontsize, alpha, alpha, bold, outline, shadow)

    -- 预处理弹幕，先计算时间段以便进行数量限制
    local pre_events = {}
    for _, d in ipairs(all_danmaku) do
        local time = d.type == 1 and math.floor(d.time + 0.5) or d.time
        local appear_time = time
        local danmaku_type = d.type

        local end_time = nil
        if danmaku_type >= 1 and danmaku_type <= 3 then
            end_time = appear_time + scrolltime
        elseif danmaku_type == 5 or danmaku_type == 4 then
            end_time = appear_time + fixtime
        end

        if end_time then
            table.insert(pre_events, {start_time = appear_time, end_time = end_time, danmaku = d})
        end
    end

    if options.max_screen_danmaku > 0 then
        pre_events = limit_danmaku(pre_events, options.max_screen_danmaku)
    end

    local ass_events = {}
    for _, ev in ipairs(pre_events) do
        local d = ev.danmaku
        local appear_time = ev.start_time
        local danmaku_type = d.type
        local text = ass_escape(decode_html_entities(d.text))
                    :gsub("x(%d+)$", "{\\b1\\i1}x%1")

        -- 颜色从十进制转为 BGR Hex
        local color = math.max(0, math.min(d.color or 0xFFFFFF, 0xFFFFFF))
        local color_hex = string.format("%06X", color)
        local r = string.sub(color_hex, 1, 2)
        local g = string.sub(color_hex, 3, 4)
        local b = string.sub(color_hex, 5, 6)
        local color_text = string.format("{\\c&H%s%s%s&}", b, g, r)

        local start_time_str = seconds_to_time(appear_time)
        local layer, end_time_str, style, effect

        -- 滚动弹幕 (类型 1, 2, 3)
        if danmaku_type >= 1 and danmaku_type <= 3 then
            layer = 0
            end_time_str = seconds_to_time(ev.end_time)
            style = "R2L"
            local text_length = get_str_width(text, fontsize)
            local x1 = res_x + text_length / 2
            local x2 = -text_length / 2
            local y = get_position_y(fontsize, appear_time, text_length, res_x, scrolltime, roll_array)
            if y then
                effect = string.format("{\\move(%d, %d, %d, %d)}", x1, y, x2, y)
            end

        -- 顶部弹幕 (类型 5)
        elseif danmaku_type == 5 then
            layer = 1
            end_time_str = seconds_to_time(ev.end_time)
            style = "TOP"
            local x = res_x / 2
            local y = get_fixed_y(fontsize, appear_time, fixtime, top_array, true)
            if y then
                effect = string.format("{\\pos(%d, %d)}", x, y)
            end

        -- 底部弹幕 (类型 4)
        elseif danmaku_type == 4 then
            layer = 1
            end_time_str = seconds_to_time(ev.end_time)
            style = "BTM"
            local x = res_x / 2
            local y = get_fixed_y(fontsize, appear_time, fixtime, top_array, false)
            if y then
                effect = string.format("{\\pos(%d, %d)}", x, y)
            end
        end

        if style then
            local line = nil
            if effect then
               line = string.format("Dialogue: %d,%s,%s,%s,,0,0,0,,%s%s%s", layer, start_time_str, end_time_str, style, effect, color_text, text)
            else
               line = string.format("Comment: %d,%s,%s,%s,,0,0,0,,%s%s", layer, start_time_str, end_time_str, style, color_text, text)
            end
            table.insert(ass_events, line)
        end
    end

    local final_ass = ass_header .. table.concat(ass_events, "\n")

    local ass_file = io.open(danmaku_file, "w")
    if not ass_file then
        msg.info("错误: 无法写入 ASS 弹幕文件")
        return false
    end
    ass_file:write(final_ass)
    ass_file:close()

    msg.debug("已成功转换并写入 ASS：" .. danmaku_file)
    return true
end

-- 将弹幕转换为 XML 格式
function convert_danmaku_to_xml(danmaku_input, danmaku_out, delays)
   local all_danmaku = parse_danmaku_files(danmaku_input, delays)
   if not all_danmaku then
        show_message("转换 XML 弹幕失败", 3)
        msg.info("转换 XML 弹幕失败")
        return
   end

    -- 拼接为 XML 内容
    local xml = { '<?xml version="1.0" encoding="UTF-8"?><i>\n' }
    for _, d in ipairs(all_danmaku) do
        local time = d.time
        local type = d.type or 1
        local size = d.size or 25
        local color = d.color or 0xFFFFFF
        local text = d.text or ""

        text = text:gsub("&", "&amp;")
                   :gsub("<", "&lt;")
                   :gsub(">", "&gt;")
                   :gsub("\"", "&quot;")
                   :gsub("'", "&apos;")

        table.insert(xml, string.format('<d p="%s,%s,%s,%s">%s</d>\n', time, type, size, color, text))
    end
    table.insert(xml, '</i>')

    -- 写入 XML 文件
    local file = io.open(danmaku_out, "w")
    if not file then
        show_message("无法写入目标 XML 文件", 3)
        msg.info("无法写入目标 XML 文件: " .. danmaku_out)
        return false
    end
    file:write(table.concat(xml))
    file:close()
    show_message("转换 XML 弹幕成功： " .. danmaku_out, 3)
    msg.info("转换 XML 弹幕成功： " .. danmaku_out)
    return true
end

-- 解析和转换弹幕
function convert_danmaku_format(danmaku_input, danmaku_file, delays)
    local all_danmaku = parse_danmaku_files(danmaku_input, delays)
    if all_danmaku then
        convert_danmaku_to_ass(all_danmaku, danmaku_file)
    else
        msg.info("未能解析对应的 .xml 或 .json 弹幕文件")
        return false
    end
end
