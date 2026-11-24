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

-- 构建 per-source 的延迟查询函数
local function make_delay_lookup(source)
    local segments = nil
    local prefix = nil
    if source and source.delay_segments and #source.delay_segments > 0 then
        segments = {}
        for i, v in ipairs(source.delay_segments) do segments[i] = v end
        table.sort(segments, function(a, b) return (a.start or 0) < (b.start or 0) end)
        prefix = {}
        local s = 0
        for i, v in ipairs(segments) do
            s = s + (v.delay or 0)
            prefix[i] = s
        end
    end

    return function(t)
        local segs = segments or {}
        local pre = prefix or {}
        if #segs == 0 then return 0 end
        local idx = binary_search(segs, t, function(s) return (s and s.start) or 0 end)
        local target = idx - 1
        if target < 1 then return 0 end
        return pre[target] or 0
    end
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

-- 黑名单模式状态（惰性初始化，不依赖模块加载顺序）
local blacklist_patterns = nil

function get_blacklist_path()
    local path = options and options.blacklist_path
    -- 未指定（空/纯空白）时返回 nil —— nil 即“未配置”：
    if type(path) ~= "string" or path:match("^%s*$") then return nil end
    local ok, expanded = pcall(mp.command_native, { "expand-path", path })
    if not ok or type(expanded) ~= "string" or expanded == "" then return nil end
    return expanded
end

-- 加载黑名单模式
function get_blacklist_patterns(force)
    if blacklist_patterns == nil or force then
        blacklist_patterns = {}
        local path = get_blacklist_path()
        local content = path and file_exists(path) and read_file(path)
        if content then
            local ext = path:lower():match("%.([a-z]+)$")
            if ext == "xml" then
                -- xml文件格式示例
                --<?xml version="1.0" encoding="utf-8"?>
                --<filters>
                --  <item enabled="true">t=卡在</item>
                --  <item enabled="true">t=进度条</item>
                --</filters>
                for _, line in ipairs(split_lines(content)) do
                    local enabled, pattern =
                        line:match('<item%s+enabled="([^"]*)"%s*>t=(.-)</item>')
                    if enabled == "true" and pattern then
                        blacklist_patterns[#blacklist_patterns + 1] = pattern
                    end
                end
            elseif ext == "json" then
                -- json文件格式示例
                -- [{"type":0,"filter":"开门","opened":true,"id":15628936}
                -- ,{"type":0,"filter":"tony","opened":true,"id":15628939}
                -- ,{"type":1,"filter":"0+.1","opened":true,"id":15628951}]
                local data = utils.parse_json(content)
                if type(data) == "table" then
                    for _, e in ipairs(data) do
                        if e.type == 0 and e.opened and e.filter then
                            blacklist_patterns[#blacklist_patterns + 1] = e.filter
                        end
                    end
                end
            elseif ext == "txt" then
                -- 文本文件格式示例
                -- 卡在
                -- 进度条
                for _, line in ipairs(split_lines(content)) do
                    line = line:match("^%s*(.-)%s*$")
                    if line ~= "" then
                        blacklist_patterns[#blacklist_patterns + 1] = line
                    end
                end
            end
        end
    end
    return blacklist_patterns
end

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

-- 比较前先统一文字写法, 例如把全角的 Ａ 转成 A. 显示时保留第一条的原文
local function merge_key(text, reaction_window)
    local key = decode_html_entities(xml_unescape(text))
    key = key:gsub("　", " "):gsub("\194\160", " ") -- 全角空格及不换行空格
    key = key:gsub("\239[\188\189][\128-\191]", function(c)
        local offset = (c:byte(2) - 188) * 64 + c:byte(3) - 128
        if offset >= 1 and offset <= 94 then return string.char(32 + offset) end
        return c
    end)
    key = key:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    if reaction_window >= 0 then
        if key:match("^666+$") then return "666", reaction_window end
        if key:match("^233+$") then return "233", reaction_window end
        if key:match("^哈哈哈") and key:gsub("哈", "") == "" then return "哈哈哈", reaction_window end
    end
    return key
end

-- 文字和类型相同时, 颜色接近的弹幕归到同一组. 再遇到相同颜色就直接用之前的分组
local function merge_color_group(bucket, color)
    if options.merge_without_style then return bucket end
    local group = bucket.colors[color]
    if group then return group end
    for _, candidate in ipairs(bucket) do
        if color_dist(candidate.color, color) <= 15 then
            bucket.colors[color] = candidate
            return candidate
        end
    end
    group = {color = color}
    bucket.colors[color] = group
    bucket[#bucket + 1] = group
    return group
end

local function merge_duplicate_danmaku(danmakus, threshold)
    if threshold < 0 then return danmakus end

    local groups, merged = {}, {}
    -- 已经按调整后的播放时间排好顺序, 每组都从第一条弹幕出现时开始计时
    for _, d in ipairs(danmakus) do
        local key, window = merge_key(d.text or "", options.merge_reaction_tolerance)
        local types = groups[key]
        if not types then
            types = {}
            groups[key] = types
        end
        local mode = options.merge_without_style and "any" or (d.type or "")
        local bucket = types[mode]
        if not bucket then
            bucket = {colors = {}}
            types[mode] = bucket
        end
        local group = merge_color_group(bucket, d.color or 0xffffff)
        local first = group.first
        if first and d.time <= first.time + (window or threshold) then
            first.merge_count = (first.merge_count or 1) + 1
        else
            group.first = d
            merged[#merged + 1] = d
        end
    end
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
function parse_xml_danmaku(xml_string)
    local danmakus = {}
    if not xml_string then
        return danmakus
    end
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
            table.insert(danmakus, {
                time = params[1],
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
function parse_json_danmaku(json_string)
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
                table.insert(danmakus, {
                    time = params[1],
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
function parse_danmaku_file(danmaku_input)
    local danmakus = {}

    if file_exists(danmaku_input) then
        local content = read_file(danmaku_input)
        if content then
            local parsed = {}
            if danmaku_input:match("%.xml$") then
                parsed = parse_xml_danmaku(content)
            elseif danmaku_input:match("%.json$") then
                parsed = parse_json_danmaku(content)
            end

            for _, d in ipairs(parsed) do
                table.insert(danmakus, d)
            end
        else
            msg.info("无法读取文件内容: " .. danmaku_input)
        end
    else
        msg.info("文件不存在: " .. danmaku_input)
    end

    for _, d in ipairs(danmakus) do
        if d.orig_time == nil then d.orig_time = d.time end
    end

    if #danmakus == 0 then
        msg.info("未能解析任何弹幕")
        return nil
    end

    return danmakus
end

--# 弹幕数组与布局算法 (Danmaku Array & Layout Algorithms)
local DanmakuArray = {}
DanmakuArray.__index = DanmakuArray

-- 取整前的对数映射严格递增且严格凹。
-- 取整后的整数字号单调不减，最大字号用于避免合并数量过大时字号失控。
function DanmakuArray.get_merged_font_size(base_size, count, growth, max_size)
    local base = positive_integer(base_size, 1)
    local n = positive_integer(count, 1)
    local scale = positive_integer(growth, 8)
    local maximum = math.max(base, positive_integer(max_size, base))
    local size = base + math.floor(scale * math.log(n) + 0.5)
    return math.min(maximum, size)
end

function DanmakuArray:new(max_y)
    local obj = {
        max_y = positive_integer(max_y, 1),
        danmakus = {},
    }
    setmetatable(obj, self)
    return obj
end

-- 弹幕按出现时间递增的顺序处理。滚动弹幕完全移出屏幕后，或固定弹幕的
-- 显示时间结束后，它便不可能与当前及之后的弹幕碰撞，因此可以安全删除。
function DanmakuArray:remove_expired(now)
    for i = #self.danmakus, 1, -1 do
        if self.danmakus[i].end_time <= now then
            table.remove(self.danmakus, i)
        end
    end
end

local function y_intersects(y1, height1, y2, height2)
    return y1 < y2 + height2 and y2 < y1 + height1
end

local function rolling_danmaku_collides(previous, start_time, velocity)
    local delta_velocity = velocity - previous.velocity
    local delta_x = (start_time - previous.start_time) * previous.velocity - previous.length

    -- delta_x 小于 0 表示旧弹幕尾部尚未进入屏幕，新弹幕出现时会直接重叠。
    if delta_x < 0 then
        return true
    end

    -- 新弹幕速度不大于旧弹幕时，不会缩短已有的 delta_x 间距。
    if delta_velocity <= 0 then
        return false
    end

    -- 比较从新弹幕出现开始的追尾时间与旧弹幕的剩余显示时间；
    -- 只有在旧弹幕离屏前追上它，才会发生碰撞。
    local delta_time = delta_x / delta_velocity
    local remaining_time = previous.end_time - start_time
    return delta_time < remaining_time
end

local function crowd_settings()
    local medium_scale, high_scale = options.crowd_shrink_scale_medium, options.crowd_shrink_scale_high
    local medium_threshold, high_threshold = options.crowd_shrink_threshold_medium, options.crowd_shrink_threshold_high
    if not (0 < high_scale and high_scale <= medium_scale and medium_scale <= 1) then
        msg.warn("自动缩字的字号比例无效，使用 0.90 / 0.80")
        medium_scale, high_scale = 0.90, 0.80
    end
    if not (0 < medium_threshold and medium_threshold < high_threshold and high_threshold <= 1) then
        msg.warn("自动缩字的轨道占用阈值无效，使用 0.60 / 0.80")
        medium_threshold, high_threshold = 0.60, 0.80
    end
    return {medium_scale = medium_scale, high_scale = high_scale,
        medium_threshold = medium_threshold, high_threshold = high_threshold}
end

-- 找出新弹幕会撞上哪些弹幕, 再看它们一共占了多少行. 两条弹幕占了同一行, 那一行只算一次
function DanmakuArray:crowded_size(time, length, size, width, duration, settings)
    local velocity = (width + length) / duration
    local blocked = {}
    for _, previous in ipairs(self.danmakus) do
        if previous.end_time > time and rolling_danmaku_collides(previous, time, velocity) then
            blocked[#blocked + 1] = previous
        end
    end
    if #blocked == 0 then return size end
    table.sort(blocked, function(a, b) return a.y < b.y end)
    local occupied, bottom = 0, 1
    for _, previous in ipairs(blocked) do
        local edge = previous.y + previous.height
        occupied = occupied + math.max(0, edge - math.max(bottom, previous.y))
        bottom = math.max(bottom, edge)
    end
    local fill = (occupied + size) / self.max_y
    if fill >= settings.high_threshold then
        return math.max(1, math.floor(size * settings.high_scale + 0.5))
    elseif fill >= settings.medium_threshold then
        return math.max(1, math.floor(size * settings.medium_scale + 0.5))
    end
    return size
end

-- 从 y 轴顶部开始寻找可插入位置。对于每个候选位置，只检查 y 轴区间
-- 与新弹幕相交的已有弹幕；若其中存在碰撞，则跳到碰撞区间下方继续寻找。
local function find_y_from_top(array, height, collides)
    local y = 1
    while y + height - 1 <= array.max_y do
        local next_y = nil
        for _, danmaku in ipairs(array.danmakus) do
            if y_intersects(y, height, danmaku.y, danmaku.height) and collides(danmaku) then
                local below = danmaku.y + danmaku.height
                next_y = next_y and math.max(next_y, below) or below
            end
        end
        if not next_y then return y end
        y = next_y
    end
    return nil
end

-- 从 y 轴顶部开始寻找滚动弹幕的位置，并记录成功插入的弹幕所占区间。
function DanmakuArray:get_position_y(start_time, length, height, resolution_x, duration)
    height = positive_integer(height, 1)
    length = math.max(0, tonumber(length) or 0)
    resolution_x = math.max(1, tonumber(resolution_x) or 1)
    duration = math.max(0.001, tonumber(duration) or 0.001)
    self:remove_expired(start_time)

    local velocity = (length + resolution_x) / duration
    local y = find_y_from_top(self, height, function(previous)
        return rolling_danmaku_collides(previous, start_time, velocity)
    end)
    if not y then return nil end

    self.danmakus[#self.danmakus + 1] = {
        y = y,
        height = height,
        start_time = start_time,
        end_time = start_time + duration,
        length = length,
        velocity = velocity,
    }
    return y
end

-- 顶部固定弹幕自上而下寻找位置，底部固定弹幕则自下而上寻找位置。
function DanmakuArray:get_fixed_y(start_time, height, duration, from_top)
    height = positive_integer(height, 1)
    duration = math.max(0.001, tonumber(duration) or 0.001)
    self:remove_expired(start_time)

    local y
    if from_top then
        y = find_y_from_top(self, height, function() return true end)
    else
        y = self.max_y - height + 1
        while y >= 1 do
            local next_y = nil
            for _, danmaku in ipairs(self.danmakus) do
                if y_intersects(y, height, danmaku.y, danmaku.height) then
                    local above = danmaku.y - height
                    next_y = next_y and math.min(next_y, above) or above
                end
            end
            if not next_y then break end
            y = next_y
        end
        if y < 1 then y = nil end
    end

    if not y then return nil end
    self.danmakus[#self.danmakus + 1] = {
        y = y,
        height = height,
        start_time = start_time,
        end_time = start_time + duration,
    }
    return y
end

-- 将弹幕转换为 XML 格式
function convert_danmaku_to_xml(danmaku_out)
    local danmakus = {}
    for url, source in pairs(DANMAKU.sources) do
        if not source.blocked and source.data then
            local get_cached_delay = make_delay_lookup(source)

            for _, d in ipairs(source.data) do
                local base_time = d.orig_time or d.time
                local adjusted_time = base_time + get_cached_delay(base_time)
                table.insert(danmakus, {
                    orig_time = d.orig_time,
                    time = adjusted_time,
                    type = d.type,
                    size = d.size,
                    color = d.color,
                    text = d.text,
                    source = url,
                })
            end
        end
    end

    if #danmakus == 0 then
        show_message("弹幕内容为空，无法保存", 3)
        msg.verbose("弹幕内容为空，无法保存")
        COMMENTS = {}
        return false
    end

    -- 拼接为 XML 内容
    local xml = { '<?xml version="1.0" encoding="UTF-8"?><i>\n' }
    for _, d in ipairs(danmakus) do
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

function convert_danmaku_to_ass_events(force)
    local per_source_lists = {}
    for url, source in pairs(DANMAKU.sources) do
        if not source.blocked and source.data then
            local get_cached_delay = make_delay_lookup(source)

            local list = {}
            for index, d in ipairs(source.data) do
                local base_time = d.orig_time or d.time
                if d.orig_time == nil then d.orig_time = base_time end
                local adjusted_time = base_time + get_cached_delay(base_time)
                local entry = {
                    orig_time = d.orig_time,
                    time = adjusted_time,
                    type = d.type,
                    size = d.size,
                    color = d.color,
                    text = d.text,
                    source = url,
                    source_index = index,
                }
                if not is_blacklisted(d.text, get_blacklist_patterns()) then
                    table.insert(list, entry)
                end
            end

            if #list > 0 then
                table.sort(list, function(a, b)
                    if a.time == b.time then return a.source_index < b.source_index end
                    return a.time < b.time
                end)
                per_source_lists[#per_source_lists + 1] = list
            end
        end
    end

    local danmakus = {}

    table.sort(per_source_lists, function(a, b) return a[1].source < b[1].source end)
    local heap = new_min_heap()
    for li = 1, #per_source_lists do
        local lst = per_source_lists[li]
        if lst and #lst > 0 then
            heap.push({ time = lst[1].time, list_idx = li, pos = 1, entry = lst[1] })
        end
    end

    while true do
        local node = heap.pop()
        if not node then break end
        table.insert(danmakus, node.entry)
        local li = node.list_idx
        local next_pos = node.pos + 1
        local lst = per_source_lists[li]
        if lst and lst[next_pos] then
            heap.push({ time = lst[next_pos].time, list_idx = li, pos = next_pos, entry = lst[next_pos] })
        end
    end

    danmakus = merge_duplicate_danmaku(danmakus, options.merge_tolerance)

    if #danmakus == 0 then
        if not force then
            show_message("该集弹幕内容为空，结束加载", 3)
            msg.verbose("该集弹幕内容为空，结束加载")
        end
        COMMENTS = {}
        return
    end

    if not force then
        msg.info("已解析 " .. #danmakus .. " 条弹幕")
    end

    local fontsize = tonumber(options.fontsize) or 50
    local fontsize_growth = tonumber(options.merge_fontsize_growth) or 8
    local fontsize_max = tonumber(options.merge_fontsize_max) or 100
    local scrolltime = tonumber(options.scrolltime) or 15
    local fixtime = tonumber(options.fixtime) or 5

    local res_x = 1920
    local res_y = 1080

    local display_height = math.max(1, math.floor(res_y * (tonumber(options.displayarea) or 1)))
    local crowd, rolling_font, rolling_height
    if options.crowd_shrink then
        crowd = crowd_settings()
        local height, font = danmaku_geometry()
        rolling_font = font
        rolling_height = math.floor(height * options.displayarea)
    end
    local roll_array = DanmakuArray:new(rolling_height or display_height)
    local fixed_array = DanmakuArray:new(display_height)

    -- 预处理弹幕，先计算时间段以便进行数量限制
    local pre_events = {}
    for _, d in ipairs(danmakus) do
        local time = d.type == 1 and math.floor(d.time + 0.5) or d.time
        local orig_time = d.type == 1 and math.floor(d.orig_time + 0.5) or d.orig_time
        local appear_time = time
        local danmaku_type = d.type

        local end_time = nil
        if danmaku_type >= 1 and danmaku_type <= 3 then
            end_time = appear_time + scrolltime
        elseif danmaku_type == 5 or danmaku_type == 4 then
            end_time = appear_time + fixtime
        end

        if end_time then
            table.insert(pre_events, {orig_time = orig_time, start_time = appear_time, end_time = end_time, danmaku = d})
        end
    end

    -- 普通滚动弹幕的出现时间会四舍五入到整秒. 和其他弹幕一起排位置前, 先按实际出现时间排序
    for index, event in ipairs(pre_events) do event.order = index end
    table.sort(pre_events, function(a, b)
        if a.start_time == b.start_time then return a.order < b.order end
        return a.start_time < b.start_time
    end)
    if options.max_screen_danmaku > 0 then
        pre_events = limit_danmaku(pre_events, options.max_screen_danmaku)
    end

    local ass_events = {}
    if crowd then
        ass_events.layout_font = rolling_font
        ass_events.visible_height = rolling_height
    end
    local count_threshold = options.merge_count_threshold
    if count_threshold < 2 or count_threshold % 1 ~= 0 then
        msg.warn("merge_count_threshold 需要至少为 2 的整数，使用默认值 3")
        count_threshold = 3
    end
    for _, ev in ipairs(pre_events) do
        local d = ev.danmaku
        local appear_time = ev.start_time
        local danmaku_type = d.type
        local clean_text = ch_convert_cached(decode_html_entities(d.text))
        local text = ass_escape(clean_text)
        local visible_text = clean_text
        local suffix
        if d.merge_count and d.merge_count >= count_threshold then
            suffix = " ×" .. d.merge_count
            text = text .. "{\\b1\\i1}" .. suffix
            visible_text = visible_text .. suffix
        end

        local event_fontsize = DanmakuArray.get_merged_font_size(
            fontsize, d.merge_count or 1, fontsize_growth, fontsize_max
        )

        -- 颜色从十进制转为 BGR Hex
        local color = math.max(0, math.min(d.color or 0xFFFFFF, 0xFFFFFF))
        local color_hex = string.format("%06X", color)
        local r = string.sub(color_hex, 1, 2)
        local g = string.sub(color_hex, 3, 4)
        local b = string.sub(color_hex, 5, 6)
        local color_text = string.format("{\\c&H%s%s%s&}", b, g, r)

        local style, effect
        local pos, move = nil, nil

        -- 滚动弹幕 (类型 1, 2, 3)
        if danmaku_type >= 1 and danmaku_type <= 3 then
            style = "R2L"
            if crowd then
                event_fontsize = math.max(1, event_fontsize + rolling_font - fontsize)
            end
            local text_length = get_str_width(visible_text, event_fontsize)
            if crowd then
                local size = roll_array:crowded_size(appear_time, text_length, event_fontsize, res_x, scrolltime, crowd)
                text_length = text_length * size / event_fontsize
                event_fontsize = size
            end
            local x1 = res_x + text_length / 2
            local x2 = -text_length / 2
            local y = roll_array:get_position_y(appear_time, text_length, event_fontsize, res_x, scrolltime)
            if y then
                effect = string.format("{\\move(%d, %d, %d, %d)}", x1, y, x2, y)
                move = {x1, y, x2, y}
            end

        -- 顶部弹幕 (类型 5)
        elseif danmaku_type == 5 then
            style = "TOP"
            local x = res_x / 2
            local y = fixed_array:get_fixed_y(appear_time, event_fontsize, fixtime, true)
            if y then
                effect = string.format("{\\pos(%d, %d)}", x, y)
                pos = {x, y}
            end

        -- 底部弹幕 (类型 4)
        elseif danmaku_type == 4 then
            style = "BTM"
            local x = res_x / 2
            local y = fixed_array:get_fixed_y(appear_time, event_fontsize, fixtime, false)
            if y then
                effect = string.format("{\\pos(%d, %d)}", x, y)
                pos = {x, y}
            end
        end

        if style and effect then
            text = effect .. color_text .. text
            local event = {
                orig_time = ev.orig_time,
                start_time = ev.start_time,
                end_time = ev.end_time,
                delay = ev.start_time - (ev.orig_time or ev.start_time),
                style = style,
                text = text,
                clean_text = clean_text,
                count_suffix = suffix,
                pos = pos,
                move = move,
                layer = (style == "R2L") and 0 or 1,
                source = d.source,
                font_size = event_fontsize,
                merge_count = d.merge_count or 1,
            }
            table.insert(ass_events, event)
        end
    end
    COMMENTS = ass_events
end
