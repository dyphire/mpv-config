local utils = require("mp.utils")

-- from http://lua-users.org/wiki/LuaUnicode
local UTF8_PATTERN = '[%z\1-\127\194-\244][\128-\191]*'

-- return a substring based on utf8 characters
-- like string.sub, but negative index is not supported
function utf8_sub(s, i, j)
    if i > j then
        return s
    end

    local t = {}
    local idx = 1
    for char in s:gmatch(UTF8_PATTERN) do
        if i <= idx and idx <= j then
            local width = #char > 2 and 2 or 1
            idx = idx + width
            t[#t + 1] = char
        end
    end
    return table.concat(t)
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
 
-- 识别并匹配前后剧集
local function compare_filenames(fname1, fname2)
    local parts1 = split_by_numbers(fname1)
    local parts2 = split_by_numbers(fname2)

    local min_len = math.min(#parts1, #parts2)

    -- 逐个部分进行比较
    for i = 1, min_len do
        local part1 = parts1[i]
        local part2 = parts2[i]

        -- 比较数字前的字符是否相同
        if part1.pre ~= part2.pre then
            return false
        end

        -- 比较数字部分
        if part1.num ~= part2.num then
            return part1.num, part2.num
        end

        -- 比较数字后的字符是否相同
        if part1.post ~= part2.post then
            return false
        end
    end

    return false
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
    if path and not is_protocol(path) then
        local title = format_filename(filename)
        if title then
            local media_title, season, episode = title:match("^(.-)%s*[sS](%d+)[eE](%d+)")
            if season then
                return title_replace(media_title), season, episode
            else
                local media_title, episode = title:match("^(.-)%s*[eE](%d+)")
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
    local media_title, season, episode = nil, nil, nil
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

-- 获取当前文件名所包含的集数
function get_episode_number(filename, fname)
    -- 尝试对比记录文件名来获取当前集数
    if fname then
        local episode_num1, episode_num2 = compare_filenames(fname, filename)
        if episode_num1 and episode_num2 then
            return episode_num1, episode_num2
        else
            return nil, nil
        end
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