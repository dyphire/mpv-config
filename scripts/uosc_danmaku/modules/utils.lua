local utils = require("mp.utils")

-- from http://lua-users.org/wiki/LuaUnicode
local UTF8_PATTERN = '[%z\1-\127\194-\244][\128-\191]*'

-- return a substring based on utf8 characters
-- like string.sub, but negative index is not supported
function utf8_sub(s, i, j)
    if i > j then
        return s
    end
    local t, idx = {}, 1
    for char in s:gmatch(UTF8_PATTERN) do
        if idx >= i and idx <= j then
            t[#t + 1] = char
        end
        idx = idx + 1
    end
    return table.concat(t)
end

function utf8_len(s)
    local count = 0
    for _ in s:gmatch(UTF8_PATTERN) do
        count = count + 1
    end
    return count
end

function utf8_iter(s)
    local iter = s:gmatch(UTF8_PATTERN)
    return function()
        return iter()
    end
end

function utf8_to_table(s)
    local t = {}
    for ch in utf8_iter(s) do
        t[#t + 1] = ch
    end
    return t
end

-- abbreviate string if it's too long
function abbr_str(str, length)
    if not str or str == '' then return '' end
    local str_clip = utf8_sub(str, 1, length)
    if str ~= str_clip then
        return str_clip .. '...'
    end
    return str
end

function get_str_width(text, font_size)
    local width = 0
    for i = 1, #text do
        local byte = string.byte(text, i)
        if byte > 127 then
            width = width + 2
        else
            width = width + 1
        end
    end

    local unicode_width = 0
    local i = 1
    while i <= #text do
        local byte = string.byte(text, i)
        local char_len
        if byte < 128 then char_len = 1; unicode_width = unicode_width + 1
        elseif byte >= 192 and byte < 224 then char_len = 2; unicode_width = unicode_width + 2
        elseif byte >= 224 and byte < 240 then char_len = 3; unicode_width = unicode_width + 2
        elseif byte >= 240 and byte < 248 then char_len = 4; unicode_width = unicode_width + 2
        else char_len = 1; unicode_width = unicode_width + 1
        end
        i = i + char_len
    end
    return unicode_width * (font_size / 2)
end

function unicode_to_utf8(unicode)
    if unicode < 0x80 then
        return string.char(unicode)
    else
        local byte_count
        if unicode < 0x800 then
            byte_count = 2
        elseif unicode < 0x10000 then
            byte_count = 3
        elseif unicode < 0x110000 then
            byte_count = 4
        else
            return
        end

        local res = {}
        local shift = 2 ^ 6
        local after_shift = unicode
        for _ = byte_count, 2, -1 do
            local before_shift = after_shift
            after_shift = math.floor(before_shift / shift)
            table.insert(res, 1, before_shift - after_shift * shift + 0x80)
        end
        shift = 2 ^ (8 - byte_count)
        table.insert(res, 1, after_shift + math.floor(0xFF / shift) * shift)
        ---@diagnostic disable-next-line: deprecated
        return string.char(unpack(res))
    end
end

function jaro(s1, s2)
    local match_window = math.floor(math.max(#s1, #s2) / 2.0) - 1
    local matches1 = {}
    local matches2 = {}

    local m = 0;
    local t = 0;

    for i = 0, #s1, 1 do
        local start = math.max(0, i - match_window)
        local final = math.min(i + match_window + 1, #s2)

        for k = start, final, 1 do
            if not (matches2[k] or s1[i] ~= s2[k]) then
                matches1[i] = true
                matches2[k] = true
                m = m + 1
                break
            end
        end
    end

    if m == 0 then
        return 0.0
    end

    local k = 0
    for i = 0, #s1, 1 do
        if matches1[i] then
            while not matches2[k] do
                k = k + 1
            end

            if s1[i] ~= s2[k] then
                t = t + 1
            end

            k = k + 1
        end
    end

    t = t / 2.0

    return (m / #s1 + m / #s2 + (m - t) / m) / 3.0
end

function jaro_winkler(s1, s2)
    if #s1 + #s2 == 0 then
        return 0.0
    end

    if s1 == s2 then
        return 1.0
    end

    s1 = utf8_to_table(s1)
    s2 = utf8_to_table(s2)

    local d = jaro(s1, s2)
    local p = 0.1
    local l = 0;
    while (s1[l] == s2[l] and l < 4) do
        l = l + 1
    end

    return d + l * p * (1 - d)
end

-- 从时间字符串转换为秒数
function time_to_seconds(time_str)
    local h, m, s = time_str:match("(%d+):(%d+):([%d%.]+)")
    return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
end

-- 从秒数转换为时间字符串
function seconds_to_time(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    local centiseconds = math.floor((seconds - math.floor(seconds)) * 100)
    return string.format("%d:%02d:%02d.%02d", hours, minutes, secs, centiseconds)
end

function is_chinese(str)
    return string.match(str, "[\228-\233][\128-\191]") ~= nil
end

function is_protocol(path)
    return type(path) == 'string' and (path:find('^%a[%w.+-]-://') ~= nil or path:find('^%a[%w.+-]-:%?') ~= nil)
end

function hex_to_bin(hexstr)
    return (hexstr:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

function hex_to_char(x)
    return string.char(tonumber(x, 16))
end

-- url编码转换
function url_encode(str)
    -- 将非安全字符转换为百分号编码
    if str then
        str = str:gsub("([^%w%-%.%_%~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
    end
    return str
end

-- url解码转换
function url_decode(str)
    if str ~= nil then
        str = str:gsub('^%a[%a%d-_]+://', '')
              :gsub('^%a[%a%d-_]+:\\?', '')
              :gsub('%%(%x%x)', hex_to_char)
        if str:find('://localhost:?') then
            str = str:gsub('^.*/', '')
        end
        str = str:gsub('%?.+', '')
              :gsub('%+', ' ')
        return str
    end
end

-- Utility function to split a string by a delimiter
function split(str, delim)
    local result = {}
    for match in (str .. delim):gmatch("(.-)" .. delim) do
        table.insert(result, match)
    end
    return result
end

function table_to_zero_indexed(tbl)
    for i = #tbl, 1, -1 do
        tbl[i - 1] = tbl[i]
    end
    tbl[#tbl] = nil
    return tbl
end

function itable_index_of(itable, value)
    for index = 1, #itable do
        if itable[index] == value then
            return index
        end
    end
end

function is_nested_table(t)
    if type(t) ~= "table" then
        return false
    end
    for _, v in pairs(t) do
        if type(v) == "table" then
            return true
        end
    end
    return false
end

function shallow_copy(original)
    if type(original) ~= "table" then
        return original
    end
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end
    return copy
end

function deep_copy(obj, seen)
    if type(obj) ~= "table" then
        return obj
    end
    if seen and seen[obj] then
        return seen[obj]
    end
    local s = seen or {}
    local copy = {}
    s[obj] = copy
    for k, v in pairs(obj) do
        copy[deep_copy(k, s)] = deep_copy(v, s)
    end
    setmetatable(copy, getmetatable(obj))
    return copy
end

function remove_query(url)
    local qpos = string.find(url, "?", 1, true)
    if qpos then
        return string.sub(url, 1, qpos - 1)
    else
        return url
    end
end

function file_exists(path)
    if path then
        local meta = utils.file_info(path)
        return meta and meta.is_file
    end
    return false
end

function is_writable(path)
    local file = io.open(path, "w")
    if file then
        file:close()
        os.remove(path)
        return true
    end
    return false
end

function contains_any(tab, val)
    for _, element in pairs(tab) do
        if string.find(val, element) then
            return true
        end
    end
    return false
end

--读history 和 写history
function read_file(file_path)
    local file = io.open(file_path, "r") -- 打开文件，"r"表示只读模式
    if not file then
        return nil
    end
    local content = file:read("*all") -- 读取文件所有内容
    file:close()                      -- 关闭文件
    return content
end

-- 应用额外的自定义标题替换规则
function title_replace(title)
    local title_replace = utils.parse_json(options.title_replace)
    if not title_replace then
        return title
    end
    for _, v in pairs(title_replace) do
        for _, indexrules in pairs(v['rules']) do
            for rule, override in pairs(indexrules) do
                title = title:gsub(rule, override)
                        :gsub("[_%.]", " ")
                        :gsub("^%s*(.-)%s*$", "%1")
                        :gsub("[@#%.%+%-%%&*_=,/~`]+$", "")
            end
        end
    end
    return title
end

function write_json_file(file_path, data)
    local file = io.open(file_path, "w")
    if not file then
        return
    end
    file:write(utils.format_json(data)) -- 将 Lua 表转换为 JSON 并写入
    file:close()
end

-- 拆分字符串中的字符和数字
local function split_by_numbers(filename)
    local parts = {}
    local pattern = "([^%d]*)(%d+)([^%d]*)"
    for pre, num, post in string.gmatch(filename, pattern) do
        table.insert(parts, {pre = pre, num = tonumber(num), post = post})
    end
    return parts
end

-- 识别匹配前后剧集并提取集数
local function get_series_episodes(fname1, fname2)
    local parts1 = split_by_numbers(fname1)
    local parts2 = split_by_numbers(fname2)
    local title1 = format_filename(fname1)
    local title2 = format_filename(fname2)
    if title1 and title2 then
        local media_title1, season1, episode1 = title1:match("^(.-)%s*[sS](%d+)[eE](%d+)")
        local media_title2, season2, episode2 = title2:match("^(.-)%s*[sS](%d+)[eE](%d+)")
        if season1 and season2 and season1 ~= season2 then
            return nil, nil
        end
    end

    local min_len = math.min(#parts1, #parts2)

    -- 逐个部分进行比较
    for i = 1, min_len do
        local part1 = parts1[i]
        local part2 = parts2[i]

        -- 比较数字前的字符是否相同
        if part1.pre ~= part2.pre then
            return nil, nil
        end

        -- 比较数字部分
        if part1.num ~= part2.num then
            return part1.num, part2.num
        end

        -- 比较数字后的字符是否相同
        if part1.post ~= part2.post then
            return nil, nil
        end
    end

    return nil, nil
end

-- 获取当前文件名所包含的集数
function get_episode_number(filename, fname)
    -- 尝试对比记录文件名来获取当前集数
    if fname then
        return get_series_episodes(fname, filename)
    end

    local thin_space = string.char(0xE2, 0x80, 0x89)
    filename = filename:gsub(thin_space, " ")

    local title = format_filename(filename)
    if title then
        local media_title, season, episode = title:match("^(.-)%s*[sS](%d+)[eE](%d+)")
        if season then
            return tonumber(episode)
        else
            local media_title, episode = title:match("^(.-)%s*[eE](%d+)")
            if episode then
                return tonumber(episode)
            end
        end
    end
    return nil
end

-- 规范化路径
function normalize(path)
    if normalize_path ~= nil then
        if normalize_path then
            path = mp.command_native({"normalize-path", path})
        else
            local directory = mp.get_property("working-directory", "")
            path = utils.join_path(directory, path:gsub('^%.[\\/]',''))
            if PLATFORM == "windows" then path = path:gsub("\\", "/") end
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

-- 获取父目录路径
function get_parent_directory(path)
    local dir = nil
    if path and not is_protocol(path) then
        path = normalize(path)
        dir = utils.split_path(path)
    end
    return dir
end

-- 获取播放文件标题信息
function parse_title()
    local path = mp.get_property("path")
    local filename = mp.get_property("filename/no-ext")

    if not filename then
        return
    end
    local thin_space = string.char(0xE2, 0x80, 0x89)
    filename = filename:gsub(thin_space, " ")
    local media_title, season, episode = nil, nil, nil
    if path and not is_protocol(path) then
        local title = format_filename(filename)
        if title then
            media_title, season, episode = title:match("^(.-)%s*[sS](%d+)[eE](%d+)")
            if season then
                return title_replace(media_title), season, episode
            else
                media_title, episode = title:match("^(.-)%s*[eE](%d+)")
                if episode then
                    return title_replace(media_title), season, episode
                end
            end
            return title_replace(title)
        end

        local directory = get_parent_directory(path)
        local dir, title = utils.split_path(directory:sub(1, -2))
        if title:lower():match("^%s*seasons?%s*%d+%s*$") or title:lower():match("^%s*specials?%s*$") or title:match("^%s*SPs?%s*$")
        or title:match("^%s*O[VAD]+s?%s*$") or title:match("^%s*第.-[季部]+%s*$") then
            directory, title = utils.split_path(dir:sub(1, -2))
        end
        title = title
                :gsub(thin_space, " ")
                :gsub("%[.-%]", "")
                :gsub("^%s*%(%d+.?%d*.?%d*%)", "")
                :gsub("%(%d+.?%d*.?%d*%)%s*$", "")
                :gsub("[%._]", " ")
                :gsub("^%s*(.-)%s*$", "%1")
        return title_replace(title)
    end

    local title = mp.get_property("media-title")
    if title then
        title = title:gsub(thin_space, " ")
        local ftitle = url_decode(title)
        local name, class = ftitle:match("^(.-)%s*|%s*(.-)%s*$")
        if name then ftitle = name end
        local format_title = format_filename(ftitle)
        if format_title then
            media_title, season, episode = format_title:match("^(.-)%s*[sS](%d+)[eE](%d+)")
            if season then
                title = media_title
            else
                media_title, episode = format_title:match("^(.-)%s*[eE](%d+)")
                if episode then
                    season = 1
                    title = media_title
                else
                    title = format_title
                end
            end
        end
    end

    return title_replace(title), season, episode
end

local CHINESE_NUM_MAP = {
    ["零"] = 0, ["一"] = 1, ["二"] = 2, ["三"] = 3, ["四"] = 4,
    ["五"] = 5, ["六"] = 6, ["七"] = 7, ["八"] = 8, ["九"] = 9,
    ["十"] = 10, ["百"] = 100, ["千"] = 1000, ["万"] = 10000,
}

function chinese_to_number(cn)
    local total = 0
    local num = 0
    local unit = 1

    local chars = {}
    for uchar in cn:gmatch(UTF8_PATTERN) do
        table.insert(chars, 1, uchar)
    end

    for _, char in ipairs(chars) do
        local val = CHINESE_NUM_MAP[char]
        if val then
            if val >= 10 then
                if num == 0 then
                    num = 1
                end
                unit = val
            else
                total = total + val * unit
                unit = 1
                num = 0
            end
        end
    end

    if unit > 1 then
        total = total + num * unit
    end

    if total > 0 then
        return total
    else
        return num
    end
end

local CHINESE_NUM = {"零", "一", "二", "三", "四", "五", "六", "七", "八", "九"}
local CHINESE_UNIT = {"", "十", "百", "千"}
local CHINESE_BIG_UNIT = {"", "万", "亿"}

function number_to_chinese(num)
    if num == 0 then return "零" end

    local str = tostring(num)
    local len = #str
    local result = ""
    local zero_flag = false

    for i = 1, len do
        local digit = tonumber(str:sub(i, i))
        local pos = len - i + 1
        local small_unit_index = (pos - 1) % 4 + 1
        local small_unit = CHINESE_UNIT[small_unit_index]

        if digit == 0 then
            zero_flag = true
        else
            if zero_flag then
                result = result .. "零"
                zero_flag = false
            end
            if digit == 1 and small_unit_index == 2 and i == 1 then
                result = result .. small_unit
            else
                result = result .. CHINESE_NUM[digit + 1] .. small_unit
            end
        end

        if pos % 4 == 1 and pos > 1 then
            local big_unit_index = math.floor((pos - 1) / 4)
            result = result .. CHINESE_BIG_UNIT[big_unit_index + 1]
        end
    end

    result = result:gsub("零+$", "")

    return result
end

-- 异步执行命令
-- 同时返回 abort 函数，用于取消异步命令
function call_cmd_async(args, callback)
    async_running = true
    local abort_signal = mp.command_native_async({
        name = 'subprocess',
        capture_stderr = true,
        capture_stdout = true,
        playback_only = false,
        args = args,
    }, function(success, result, error)
        if not success or not result or result.status ~= 0 then
            local exit_code = (result and result.status or 'unknown')
            local message = error or (result and result.stdout .. result.stderr) or ''
            callback('Calling failed. Exit code: ' .. exit_code .. ' Error: ' .. message, {})
            return
        end

        local json = result and type(result.stdout) == 'string' and result.stdout or ''
        return callback(nil, json)
    end)

    return function()
        mp.abort_async_command(abort_signal)
    end
end