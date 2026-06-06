local msg = require('mp.msg')
local utils = require('mp.utils')
local inflate = require('modules/inflate')

local user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

local function build_curl_args(url, extra_headers)
    local args = {
        'curl', '-L', '-s', '--compressed', '--user-agent', user_agent
    }
    extra_headers = extra_headers or {}
    for _, h in ipairs(extra_headers) do
        table.insert(args, '-H')
        table.insert(args, h)
    end
    table.insert(args, url)
    if options.cookie_file and options.cookie_file ~= '' then
        table.insert(args, '-b')
        table.insert(args, mp.command_native({'expand-path', options.cookie_file}))
    end
    return args
end

local function get_tvid_from_url(url, callback)
    local id = url:match('v_(%w+)')
    if not id then
        callback(nil)
        return
    end
    local api = string.format('https://pcw-api.iq.com/api/decode/%s?platformId=3&modeCode=intl&langCode=sg', id)
    call_cmd_async(build_curl_args(api), function(err, out)
        if err or not out or out == '' then
            msg.warn('Iqiyi decode request failed: ' .. tostring(err))
            return
        end
        local data = utils.parse_json(out)
        if not data or not data['data'] then
            callback(nil)
            return
        end
        local raw = data['data']
        local tvid_str
        if type(raw) == 'number' then
            tvid_str = string.format('%.0f', raw)
        else
            tvid_str = tostring(raw)
        end
        callback(tvid_str)
    end)
end

local function get_video_info(tvid, callback)
    local api = string.format('https://pcw-api.iqiyi.com/video/video/baseinfo/%s', tvid)
    call_cmd_async(build_curl_args(api), function(err, out)
        if err or not out or out == '' then
            msg.warn('Iqiyi baseinfo request failed: ' .. tostring(err))
            return
        end
        local data = utils.parse_json(out)
        callback(data and data['data'] or nil)
    end)
end

local function extract_tags(xml, tag)
    local res = {}
    if not xml then return res end
    for v in xml:gmatch('<'..tag..'>(.-)</'..tag..'>') do
        table.insert(res, v)
    end
    return res
end

local function parse_xml_and_append(xml, contents, total_files)
    local danmaku = extract_tags(xml, 'content')
    local showTime = extract_tags(xml, 'showTime')
    local color = extract_tags(xml, 'color')

    if #danmaku == 0 then return end
    local step = math.ceil(#danmaku * (total_files or 1) / 10000)
    if step < 1 then step = 1 end

    for i = 1, #danmaku, step do
        local content = {}
        local timepoint = tonumber(showTime[i]) or 0
        local col = tonumber((color[i] or ''), 16) or 16777215
        local txt = danmaku[i] or ''
        content.c = string.format('%s,%s,%s,25,,,', timepoint, col, 1)
        content.m = txt
        table.insert(contents, content)
    end
end

local function try_decompress_file(path)
    local f, err = io.open(path, 'rb')
    if not f then return nil, err end
    local data = f:read('*a')
    f:close()
    if not data or #data == 0 then return nil, 'empty' end
    local b1,b2 = data:byte(1,2)
    -- zip archive (PK..)
    if b1 == 0x50 and b2 == 0x4b then
        local bs = inflate.new(data)
        if bs then
            local it = bs:files()
            local name = it()
            if name then
                local res = bs:unzip(name, true)
                if res then return res end
            end
        end
    end
    -- gzip
    if b1 == 0x1f and b2 == 0x8b then
        local function parse_gzip_start(d)
            local flg = d:byte(4) or 0
            local pos = 11
            if (flg % 8) >= 4 then
                local xlen = (d:byte(11) or 0) + ((d:byte(12) or 0) * 256)
                pos = pos + 2 + xlen
            end
            if (flg % 16) >= 8 then
                while d:byte(pos) and d:byte(pos) ~= 0 do pos = pos + 1 end
                pos = pos + 1
            end
            if (flg % 32) >= 16 then
                while d:byte(pos) and d:byte(pos) ~= 0 do pos = pos + 1 end
                pos = pos + 1
            end
            if (flg % 4) >= 2 then
                pos = pos + 2
            end
            return pos
        end
        local start = parse_gzip_start(data)
        if start and start < #data - 8 then
            local deflated = data:sub(start, #data - 8)
            local bs = inflate.new(deflated)
            if bs then
                local res = bs:inflate(1)
                if res then return res end
            end
        end
    end
    -- zlib (check header checksum mod31)
    if ((b1*256 + (b2 or 0)) % 31) == 0 and #data > 6 then
        local deflated = data:sub(3, #data - 4)
        local bs = inflate.new(deflated)
        if bs then
            local res = bs:inflate(1)
            if res then return res end
        end
    end
    -- fallback: return raw data
    return data
end

local function save_output_and_load(output_table, source_url)
    if #output_table == 0 then
        show_message('未获取到任何弹幕', 3)
        return
    end
    local final_json_str = utils.format_json(output_table)
    save_danmaku_json(source_url, final_json_str)
    load_danmaku(true)
end

-- 辅助函数：构造 curl 参数
local function build_args_for_server(server, referer)
    local headers = {
        'Referer: ' .. (referer or ''),
        'Accept: */*',
    }
    local args = build_curl_args(server.url, headers)
    local last = args[#args]
    args[#args] = '--output'
    table.insert(args, server.zfile)
    table.insert(args, last)
    return args
end

-- 辅助函数：处理单个分段的响应并解压解析
local function handle_server_response(server, err, out, output_table, servers, referer)
    if err then
        msg.warn('请求弹幕段失败: ' .. tostring(server) .. ' 错误: ' .. tostring(err))
        return
    end

    if type(out) == 'string' and out:find('<') then
        parse_xml_and_append(out, output_table, #servers)
        return
    end

    if type(server) == 'table' and server.zfile and utils.file_info(server.zfile) then
        local content, derr = try_decompress_file(server.zfile)
        if not content then
            msg.warn('文件解压失败: ' .. tostring(server.url) .. ' 错误: ' .. tostring(derr))
            os.remove(server.zfile)
            return
        end
        if not content or content == '' then
            msg.warn('文件解压后为空: ' .. tostring(server.url))
            os.remove(server.zfile)
            return
        end
        if type(content) == 'string' and content:find('<') then
            parse_xml_and_append(content, output_table, #servers)
        else
            msg.warn('无法解析弹幕段内容: ' .. tostring(server.url))
        end
        os.remove(server.zfile)
        return
    end
    msg.warn('无法处理弹幕段响应: ' .. tostring(server))
end

-- 辅助函数：处理已知 tvid 的主流程
local function process_iqiyi_with_tvid(tvid, url, callback)
    get_video_info(tvid, function(videoInfo)
        if not videoInfo then
            show_message('获取爱奇艺视频信息失败', 3)
            callback(false)
            return
        end

        local title = videoInfo['name'] or videoInfo['tvName'] or ''
        local duration = tonumber(videoInfo['durationSec']) or 0
        local albumid = videoInfo['albumId']
        local categoryid = videoInfo['channelId'] or videoInfo['categoryId']
        if title and title ~= '' then
            DANMAKU.title = title
        end

        local page = math.ceil(duration / (60 * 5))
        if page < 1 then page = 1 end
        msg.verbose(string.format('tvid: %s duration: %s pages: %d', tvid, tostring(duration), page))

        local servers = {}
        for i = 0, page - 1 do
            local part1 = tvid:sub(-4, -3) or ''
            local part2 = tvid:sub(-2) or ''
            local api_url = string.format('https://cmts.iqiyi.com/bullet/%s/%s/%s_300_%d.z', part1, part2, tvid, i + 1)
            local qs = '?rn=0.0123456789123456&business=danmu&is_iqiyi=true&is_video_page=true&tvid='..url_encode(tvid)
            if albumid then qs = qs .. '&albumid=' .. url_encode(tostring(albumid)) end
            if categoryid then qs = qs .. '&categoryid=' .. url_encode(tostring(categoryid)) end
            qs = qs .. '&qypid=01010021010000000000'
            local full = api_url .. qs
            local tmp_file = 'iqiyi_' .. PID .. '_' .. tostring(os.time()) .. '_' .. tostring(i) .. '.z'
            local tmp_path = utils.join_path(DANMAKU_PATH, tmp_file)
            table.insert(servers, { url = full, zfile = tmp_path, idx = i + 1 })
        end

        local output_table = {}

        local function build_args_fn(server)
            return build_args_for_server(server, url)
        end

        local function per_response_cb(server, err, out)
            return handle_server_response(server, err, out, output_table, servers, url)
        end

        local function final_cb()
            local ok = #output_table > 0
            save_output_and_load(output_table, url)
            callback(ok)
        end

        parallel_requests(servers, build_args_fn, per_response_cb, final_cb, {concurrency = 6, per_request_timeout = 15})
    end)
end

-- 为爱奇艺加载弹幕
function load_danmaku_for_iqiyi(path, callback)
    callback = callback or function() end
    local url = path or mp.get_property('stream-open-filename', '')
    if not url or url == '' then
        msg.error('无有效 URL')
        callback(false)
        return
    end

    get_tvid_from_url(url, function(tvid)
        if not tvid then
            show_message('获取爱奇艺 tvid 失败', 3)
            callback(false)
            return
        end
        process_iqiyi_with_tvid(tvid, url, callback)
    end)
end
