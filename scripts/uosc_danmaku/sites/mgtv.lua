local msg = require('mp.msg')
local utils = require('mp.utils')

local user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

-- 解析多种 time 表示为秒数（支持数字、带小数、HH:MM:SS、MM:SS）
local function parse_mgtv_time(time_str)
    if time_str == nil then return 0 end
    if type(time_str) == 'number' then return time_str end
    local s = tostring(time_str):gsub('^%s*(.-)%s*$', '%1')
    local n = tonumber(s)
    if n then return n end
    local h, m, sec = s:match('^(%d+):(%d+):([%d%.]+)$')
    if h and m and sec then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(sec)
    end
    local mm, ss = s:match('^(%d+):([%d%.]+)$')
    if mm and ss then
        return tonumber(mm) * 60 + tonumber(ss)
    end
    return 0
end

-- 生成分段请求列表（每段以 ms 为单位的起点）
local function generate_mgtv_segments(api_base, total_seconds, step_ms)
    local segments = {}
    local end_time_ms = math.floor(total_seconds * 1000)
    for i = 0, math.max(0, end_time_ms - 1), step_ms do
        table.insert(segments, api_base .. tostring(i))
    end
    return segments
end

-- 构建通用 curl 请求参数
local function build_mgtv_curl_args(target_url)
    local args = {
        'curl', '-s', '-L', '--compressed',
        '--user-agent', user_agent,
        '-H', 'Accept: application/json',
        target_url,
    }
    return args
end

-- 解析单个分段返回并把弹幕追加到 output_table
local function parse_mgtv_segment(out, output_table)
    if not out then return end
    local j = utils.parse_json(out)
    if not j or not j.data or not j.data.items then return end
    for _, item in ipairs(j.data.items) do
        local t_ms = tonumber(item.time) or 0
        local time_s = t_ms / 1000
        local content = item.content or ''
        local mode = 1
        local color = 16777215
        local c_param = string.format('%.2f,%d,%d,25,,,', time_s, color, mode)
        table.insert(output_table, { c = c_param, m = content })
    end
end

local function extract_mgtv_ids(path)
    if not path then return nil, nil end
    -- 常见格式: /b/<cid>/<vid>.html
    local cid, vid = path:match('/b/(%d+)/([%w%._-]+)%.html')
    if cid and vid then
        vid = vid:match('([^.]+)') or vid
        return cid, vid
    end

    -- 回退：取最后两个 path segment
    local segs = {}
    for seg in path:gmatch('/([^/]+)') do table.insert(segs, seg) end
    if #segs >= 2 then
        cid = segs[#segs - 1]
        vid = segs[#segs]
        vid = vid and vid:match('([^.]+)') or nil
        return cid, vid
    end
    return nil, nil
end

-- 为 芒果TV 加载弹幕
function load_danmaku_for_mgtv(path, callback)
    callback = callback or function() end
    local url = path or mp.get_property('stream-open-filename', '')
    if not url or url == '' then
        msg.error('mgtv: 无效的 url')
        return
    end

    local cid, vid = extract_mgtv_ids(url)
    if not cid or not vid then
        msg.error('mgtv: 无法解析 cid/vid: ' .. tostring(url))
        return
    end

    local info_api = 'https://pcweb.api.mgtv.com/video/info?cid=' .. cid .. '&vid=' .. vid
    local api_danmaku_base = 'https://galaxy.bz.mgtv.com/rdbarrage?vid=' .. vid .. '&cid=' .. cid .. '&time='

    local args = build_mgtv_curl_args(info_api)

    call_cmd_async(args, function(err, out)
        if err then
            msg.error('mgtv: 请求 video/info 失败: ' .. tostring(err))
            callback(false)
            return
        end
        local data = utils.parse_json(out)
        if not data or data.code ~= 200 or not data.data or not data.data.info then
            msg.info('mgtv: video/info 返回无效')
            callback(false)
            return
        end
        local time_str = data.data.info.time
        local total_seconds = parse_mgtv_time(time_str)

        local step = 60 * 1000
        local segments = generate_mgtv_segments(api_danmaku_base, total_seconds, step)

        if #segments == 0 then
            msg.info('mgtv: 未生成任何弹幕分段请求')
            callback(false)
            return
        end

        local output_table = {}

        local function per_response_cb(server, err, out)
            if err then
                msg.debug('mgtv segment request failed: ' .. tostring(server) .. ' err: ' .. tostring(err))
                return
            end
            parse_mgtv_segment(out, output_table)
        end

        local function final_cb()
            local ok = #output_table > 0
            local final_json_str = utils.format_json(output_table)
            save_danmaku_json(url, final_json_str)
            load_danmaku(true)
            callback(ok)
        end

        parallel_requests(segments, build_mgtv_curl_args, per_response_cb, final_cb, { concurrency = 6, per_request_timeout = 10 })
    end)
end
