local msg = require('mp.msg')
local utils = require('mp.utils')

local user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

local function build_curl_args(url, extra_headers)
    local args = {'curl', '-L', '-s', '--compressed', '--user-agent', user_agent}
    extra_headers = extra_headers or {}
    for _, h in ipairs(extra_headers) do
        table.insert(args, '-H')
        table.insert(args, h)
    end
    if options.cookie_file and options.cookie_file ~= '' then
        table.insert(args, '-b')
        table.insert(args, mp.command_native({'expand-path', options.cookie_file}))
    end
    table.insert(args, url)
    return args
end

local function parse_set_cookie_headers(text)
    local cookies = {}
    if not text or text == '' then return cookies end
    for line in text:gmatch('[^\r\n]+') do
        local low = line:lower()
        if low:find('set%-cookie:') then
            local cookie_str = line:match(':%s*(.*)') or ''
            for kv in cookie_str:gmatch('([^;]+)') do
                local k, v = kv:match('^%s*(.-)%s*=%s*(.*)')
                if k and v then
                    cookies[k] = v
                end
            end
        end
    end
    return cookies
end

local function get_cna(callback)
    local api = 'https://log.mmstat.com/eg.js'
    local args = build_curl_args(api)
    table.insert(args, #args, '-i')
    call_cmd_async(args, function(err, out)
        if err or not out or out == '' then
            msg.warn('get_cna failed: ' .. tostring(err))
            callback(nil)
            return
        end
        local cookies = parse_set_cookie_headers(out)
        callback(cookies['cna'])
    end)
end

local function get_tk_enc(callback)
    local api_url = 'https://acs.youku.com/h5/mtop.com.youku.aplatform.weakget/1.0/?jsv=2.5.1&appKey=24679788'
    local args = build_curl_args(api_url)
    table.insert(args, #args, '-i')
    call_cmd_async(args, function(err, out)
        if err or not out or out == '' then
            msg.warn('get_tk_enc failed: ' .. tostring(err))
            callback(nil)
            return
        end
        local cookies = parse_set_cookie_headers(out)
        callback(cookies)
    end)
end

local function yk_msg_sign(msg)
    return MD5.sum(msg .. 'MkmC9SoIw6xCkSKHhJ7b5D2r51kBiREr')
end

local function yk_t_sign(token, t, appkey, data)
    local text = table.concat({token, tostring(t), appkey, data}, '&')
    return MD5.sum(text)
end

local function get_vinfos_by_video_id(url, callback)
    local vid = url:match('/v_show/id_([%w=]+)') or url:match('id_([%w=]+)') or url:match("[?&]vid=([^&]+)")
    if not vid then
        callback(nil)
        return
    end
    local api_url = 'https://openapi.youku.com/v2/videos/show.json'
    local params = '?client_id=53e6cc67237fc59a&video_id=' .. url_encode(vid) .. '&package=com.huawei.hwvplayer.youku&ext=show'
    local args = build_curl_args(api_url .. params)
    call_cmd_async(args, function(err, out)
        if err or not out or out == '' then
            msg.warn('youku show.json failed: ' .. tostring(err))
            callback(nil)
            return
        end
        local data = utils.parse_json(out)
        if not data then
            callback(nil)
            return
        end
        local duration = tonumber(data.duration) or 0
        local title = data.title or ''
        if title and title ~= '' then DANMAKU.title = title end
        callback(vid, duration)
    end)
end

local function build_query_string(params)
    local parts = {}
    for k, v in pairs(params) do
        table.insert(parts, k .. '=' .. url_encode(tostring(v)))
    end
    return table.concat(parts, '&')
end

-- Helper: 构造 curl 参数（POST form data）
local function youku_build_curl_args_for_server(server)
    local headers = { 
        'Content-Type: application/x-www-form-urlencoded',
        'Referer: https://v.youku.com',
        'User-Agent: ' .. user_agent,
        'Cookie: ' .. server.cookie
    }
    local args = build_curl_args(server.url, headers)
    table.insert(args, '--data-urlencode')
    table.insert(args, 'data=' .. server.data)
    msg.info('youku build args mat=' .. tostring(server.mat) .. ' sign=' .. tostring(server.sign) .. ' msg_b64_prefix=' .. string.sub(server.msg_b64 or '', 1, 16))
    msg.verbose('youku curl args: ' .. table.concat(args, ' '))
    return args
end

-- Helper: 解析单个 youku 响应并把 danmu 加入 output_table
local function youku_parse_response(out, server, output_table)
    if not out or out == '' then return 0 end

    -- 优先解析外层 JSON，再解析内层被转义的 result
    local parsed = nil
    local outer = utils.parse_json(out)
    if outer and type(outer) == 'table' then
        if outer.data then
            if type(outer.data) == 'string' then
                local inner = utils.parse_json(outer.data)
                if inner and type(inner) == 'table' then parsed = inner end
            elseif type(outer.data) == 'table' then
                if type(outer.data.result) == 'string' then
                    local inner = utils.parse_json(outer.data.result)
                    if inner and type(inner) == 'table' then parsed = inner end
                elseif type(outer.data.result) == 'table' then
                    parsed = outer.data
                end
            end
        elseif type(outer.result) == 'string' then
            local inner = utils.parse_json(outer.result)
            if inner and type(inner) == 'table' then parsed = inner end
        elseif type(outer.result) == 'table' then
            parsed = outer
        end
    end

    if not parsed then
        local s, e = out:find('%b{}')
        if s and e then
            local snippet = out:sub(s, e)
            local sn = utils.parse_json(snippet)
            if sn and type(sn) == 'table' then parsed = sn end
        end
    end

    if not parsed then
        msg.warn('youku parse failed for response; skipping')
        return 0
    end

    if tostring(parsed.code) == '-1' then return 0 end
    local danmus = parsed.data and parsed.data.result or parsed.result
    if not danmus then return 0 end

    local added = 0
    for _, d in ipairs(danmus) do
        local content = {}
        local timepoint = tonumber(d.playat) and tonumber(d.playat)/1000 or 0
        local properties = {}
        if d.propertis then
            local ps = utils.parse_json(d.propertis)
            if ps then properties = ps end
        end
        local color = tonumber(properties.color) or 16777215
        content.c = string.format('%s,%s,%s,25,,,', timepoint, color, 1)
        content.m = d.content or ''
        table.insert(output_table, content)
        added = added + 1
    end

    return added
end

-- Helper: 最终保存并加载弹幕
local function youku_final_save(output_table, url, callback)
    local ok = #output_table > 0
    local final_json_str = utils.format_json(output_table)
    save_danmaku_json(url, final_json_str)
    load_danmaku(true)
    callback(ok)
end

-- Helper: 根据 mat/guid/tk/vid 构造单个 server 条目
local function youku_make_server_entry(mat, guid, tk, vid)
    local api_url = 'https://acs.youku.com/h5/mopen.youku.danmu.list/1.0/'
    local msg_obj = {
        ctime = os.time() * 1000,
        ctype = 10004,
        cver = 'v1.0',
        guid = guid,
        mat = mat,
        mcount = 1,
        pid = 0,
        sver = '3.1.0',
        type = 1,
        vid = vid
    }
    local data_json = utils.format_json(msg_obj)
    local msg_b64 = Base64.encode(data_json)
    msg_obj.msg = msg_b64
    msg_obj.sign = yk_msg_sign(msg_b64)
    local data_wrapper = utils.format_json(msg_obj)
    local t = tostring(os.time() * 1000)
    local token_raw = tk['_m_h5_tk'] or ''
    local token = token_raw:sub(1, 32)
    local params = {
        jsv = '2.5.6',
        appKey = '24679788',
        t = t,
        sign = yk_t_sign(token, t, '24679788', data_wrapper),
        api = 'mopen.youku.danmu.list',
        v = '1.0',
        type = 'originaljson',
        dataType = 'jsonp',
        timeout = '20000',
        jsonpIncPrefix = 'utility'
    }
    local qs = build_query_string(params)
    local full_url = api_url .. '?' .. qs
    local cookie_header = '_m_h5_tk=' .. (tk['_m_h5_tk'] or '') .. ';_m_h5_tk_enc=' .. (tk['_m_h5_tk_enc'] or '') .. ';'
    return {url = full_url, data = data_wrapper, cookie = cookie_header, mat = mat, sign = msg_obj.sign, msg_b64 = msg_b64}
end

-- Helper: 并行获取 cna 和 tk，然后调用回调 cb({cna=..., tk=...})
local function gather_cna_and_tk(cb)
    local res = {}
    local remaining = 2
    local function maybe_done()
        remaining = remaining - 1
        if remaining == 0 then cb(res) end
    end
    get_cna(function(cna)
        res.cna = cna
        maybe_done()
    end)
    get_tk_enc(function(tk)
        res.tk = tk
        maybe_done()
    end)
end

-- Helper: 从已知参数发起 youku 弹幕请求并处理结果
local function start_youku_requests(source_url, vid, duration, cna, tk, callback)
    local max_mat = math.floor(duration / 60) + 1
    if max_mat < 1 then max_mat = 1 end
    msg.verbose(string.format('vid: %s duration: %s mats: %d', vid, tostring(duration), max_mat))

    local servers = {}
    for mat = 0, max_mat - 1 do
        table.insert(servers, youku_make_server_entry(mat, cna, tk, vid))
    end

    local output_table = {}

    local function per_response_cb(server, err, out)
        if err then
            msg.warn('youku request failed: ' .. tostring(err))
            return
        end
        if not out or out == '' then return end
        youku_parse_response(out, server, output_table)
    end

    local function final_cb()
        youku_final_save(output_table, source_url, callback)
    end

    parallel_requests(servers, youku_build_curl_args_for_server, per_response_cb, final_cb, {concurrency = 6, per_request_timeout = 20})
end

function load_danmaku_for_youku(path, callback)
    callback = callback or function() end
    local url = path or mp.get_property('stream-open-filename', '')
    if not url or url == '' then
        msg.error('无有效 URL')
        callback(false)
        return
    end

    get_vinfos_by_video_id(url, function(vid, duration)
        if not vid then
            show_message('获取优酷 video_id 失败', 3)
            callback(false)
            return
        end

        gather_cna_and_tk(function(res)
            local cna = res.cna
            local tk = res.tk
            if not cna then
                show_message('获取优酷 cna 失败', 3)
                callback(false)
                return
            end
            if not tk then
                show_message('获取优酷 tk_enc 失败', 3)
                callback(false)
                return
            end
            start_youku_requests(url, vid, duration, cna, tk, callback)
        end)
    end)
end
