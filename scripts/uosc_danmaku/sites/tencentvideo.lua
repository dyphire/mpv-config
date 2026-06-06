local msg = require('mp.msg')
local utils = require('mp.utils')

local user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

-- 将 URL 中的百分号编码解码为字符
local function normalize_url(path)
    if not path then return '' end
    return (path:gsub('%%(%x%x)', hex_to_char))
end

-- 从 URL 提取 vid
local function extract_vid(url)
    if not url then return nil end
    local vid = url:match('[?&]vid=([^&?#]+)')
    if not vid then
        local last = nil
        for seg in url:gmatch('/([^/?#]+)') do
            last = seg
        end
        if last then
            vid = last:match('([^%.]+)')
        end
    end
    return vid
end

-- 构造 curl 请求参数（通用）
local function build_curl_args(target_url)
    local args = {
        'curl',
        '-L',
        '-s',
        '--compressed',
        '--user-agent',
        user_agent,
        target_url,
    }

    if options.cookie_file and options.cookie_file ~= '' then
        table.insert(args, '-b')
        table.insert(args, mp.command_native({'expand-path', options.cookie_file}))
    end
    return args
end

-- 解析单个 segment 返回并把弹幕追加到 output_table
local function parse_segment_to_output(seg_json, output_table)
    if not seg_json or not seg_json['barrage_list'] then return end
    for _, item in ipairs(seg_json['barrage_list']) do
        local time = tonumber(item['time_offset']) and tonumber(item['time_offset']) / 1000 or 0
        local color = 16777215
        if item['content_style'] and item['content_style']['color'] then
            local col = item['content_style']['color']
            if type(col) == 'string' and col:match('^#') then
                color = hex_to_int_color(col)
            end
        end
        local mode = 1
        local c_param = string.format('%s,%s,%s,25,,,', time, color, mode)
        table.insert(output_table, {c = c_param, m = item['content'] or ''})
    end
end

-- 保存并加载最终弹幕 JSON
local function save_output_and_load(output_table, source_url)
    if #output_table == 0 then
        show_message('未获取到任何弹幕', 3)
        return
    end
    local final_json_str = utils.format_json(output_table)
    save_danmaku_json(source_url, final_json_str)
    load_danmaku(true)
end

-- 为 腾讯视频 加载弹幕
function load_danmaku_for_tencent(path, callback)
    callback = callback or function() end
    local url = normalize_url(path)
    if not url or url == '' then
        url = mp.get_property('stream-open-filename', '')
    end

    local vid = extract_vid(url)
    if not vid then
        msg.error('无法从 URL 中解析 vid: ' .. tostring(url))
        callback(false)
        return
    end

    local api_base = 'https://dm.video.qq.com/barrage/base/' .. vid
    local api_segment_base = 'https://dm.video.qq.com/barrage/segment/' .. vid .. '/'

    local base_args = build_curl_args(api_base)

    call_cmd_async(base_args, function(err, out)
        if err then
            msg.error('请求腾讯弹幕 base 失败: ' .. tostring(err))
            callback(false)
            return
        end

        local base_json = utils.parse_json(out)
        if not base_json or not base_json['segment_index'] then
            show_message('好像没有弹幕哦', 3)
            callback(false)
            return
        end

        -- 构造 segment 请求列表
        local segments = {}
        local seg_index = base_json['segment_index']
        if type(seg_index) == 'table' then
            for k, v in pairs(seg_index) do
                local seg_name = nil
                if type(v) == 'table' and v['segment_name'] then
                    seg_name = v['segment_name']
                elseif type(k) == 'string' then
                    seg_name = k
                end
                if seg_name then
                    table.insert(segments, api_segment_base .. seg_name)
                end
            end
        end

        if #segments == 0 then
            show_message('没有找到弹幕分段', 3)
            callback(false)
            return
        end

        local output_table = {}

        local function build_args_fn(server)
            return build_curl_args(server)
        end

        local function per_response_cb(server, err, out)
            if err then
                msg.warn('请求段失败: ' .. tostring(server) .. ' 错误: ' .. tostring(err))
                return
            end
            local seg_json = utils.parse_json(out)
            parse_segment_to_output(seg_json, output_table)
        end

        local function final_cb()
            local ok = #output_table > 0
            save_output_and_load(output_table, url)
            callback(ok)
        end

        -- 并行请求 segments
        parallel_requests(segments, build_args_fn, per_response_cb, final_cb, {concurrency = 6, per_request_timeout = 15})
    end)
end
