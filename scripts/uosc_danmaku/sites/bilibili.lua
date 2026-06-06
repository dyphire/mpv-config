local msg = require('mp.msg')
local utils = require("mp.utils")

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
    if options.cookie_file and options.cookie_file ~= '' then
        table.insert(args, '-b')
        table.insert(args, mp.command_native({'expand-path', options.cookie_file}))
    end
    if options.proxy and options.proxy ~= '' then
        table.insert(args, '-x')
        table.insert(args, options.proxy)
    end
    table.insert(args, url)
    return args
end

local function get_cid()
    local cid, danmaku_id = nil, nil
    local tracks = mp.get_property_native("track-list")
    for _, track in ipairs(tracks) do
        if track["lang"] == "danmaku" then
            cid = track["external-filename"]:match("/(%d-)%.xml$")
            danmaku_id = track["id"]
            break
        end
    end
    return cid, danmaku_id
end

local function get_bilibili_id_and_page(path)
    local bvid, aid, page = nil, nil, nil
    if not bvid then
        bvid = path:match("/video/(BV[%w]+)")
            or path:match("[?&]bvid=(BV[%w]+)")
    end
    if not aid then
        aid = path:match("/video/av([%d]+)")
    end
    if not page then
        page = tonumber(path:match("[?&]p=(%d+)"))
    end
    return bvid, aid, page or 1
end

local function get_bilibili_pagelist_args(bvid, aid)
    local url
    if bvid ~= nil then
        url = "https://api.bilibili.com/x/player/pagelist?bvid=" .. bvid
    else
        url = "https://api.bilibili.com/x/player/pagelist?aid=" .. aid
    end
    local headers = {"Referer: https://www.bilibili.com/video/" .. (bvid or ("av" .. aid))}
    return build_curl_args(url, headers)
end

local function resolve_bilibili_cid(path, callback)
    -- 扩展支持：普通视频（BV/av）、番剧（ep）、课程（cheese）
    local api_bangumi_season = "https://api.bilibili.com/pgc/view/web/season"
    local api_cheese_season = "https://api.bilibili.com/pugv/view/web/season"

    local q = path
    -- 解析普通投稿视频
    local bvid, aid, p = get_bilibili_id_and_page(q)
    if bvid or aid then
        local args = get_bilibili_pagelist_args(bvid, aid)
        call_cmd_async(args, function(error, json)
            if error then
                msg.warn("Failed to request bilibili pagelist: " .. tostring(error))
                callback(nil)
                return
            end
            local data = utils.parse_json(json)
            local pages = data and data["data"]
            if type(pages) ~= "table" then
                callback(nil)
                return
            end
            local page_info = pages[p] or pages[1]
            local cid = page_info and page_info["cid"]
            local part = page_info and page_info["part"]
            callback(cid and tostring(cid) or nil, part and tostring(part) or nil)
        end)
        return
    end

    -- 番剧、番外等（含 ep）
    if q:find("bangumi/") and q:find("ep") then
        local epid = q:match("ep(%d+)") or q:match("ep(%d+)$")
        if not epid then
            callback(nil)
            return
        end
        local url = api_bangumi_season .. "?ep_id=" .. epid
        local arg = build_curl_args(url)
        call_cmd_async(arg, function(error, json)
            if error then
                msg.warn("Failed to request bilibili bangumi info: " .. tostring(error))
                callback(nil)
                return
            end
            local data = utils.parse_json(json)
            if not data or data.code ~= 0 or not data.result then
                msg.warn("bilibili bangumi api returned error")
                callback(nil)
                return
            end
            -- 查找正片
            local episodes = data.result.episodes or {}
            for _, ep in ipairs(episodes) do
                if tostring(ep.id) == tostring(epid) then
                    callback(tostring(ep.cid), tostring(ep.share_copy or ep.title or ""))
                    return
                end
            end
            -- 查找 section（花絮等）
            if type(data.result.section) == "table" then
                for _, sec in ipairs(data.result.section) do
                    if sec.episodes then
                        for _, ep in ipairs(sec.episodes) do
                            if tostring(ep.id) == tostring(epid) then
                                callback(tostring(ep.cid), tostring(ep.share_copy or ep.title or ""))
                                return
                            end
                        end
                    end
                end
            end
            callback(nil)
        end)
        return
    end

    -- cheese 课程
    if q:find("cheese/") and q:find("ep") then
        local epid = q:match("ep(%d+)") or q:match("ep(%d+)$")
        if not epid then
            callback(nil)
            return
        end
        local url = api_cheese_season .. "?ep_id=" .. epid
        local arg = build_curl_args(url)
        call_cmd_async(arg, function(error, json)
            if error then
                msg.warn("Failed to request bilibili cheese info: " .. tostring(error))
                callback(nil)
                return
            end
            local data = utils.parse_json(json)
            if not data or data.code ~= 0 or not data.data then
                msg.warn("bilibili cheese api returned error")
                callback(nil)
                return
            end
            local episodes = data.data.episodes or {}
            for _, ep in ipairs(episodes) do
                if tostring(ep.id) == tostring(epid) then
                    callback(tostring(ep.cid), tostring(ep.title or ""))
                    return
                end
            end
            callback(nil)
        end)
        return
    end

    -- 其它情况返回 nil
    callback(nil)
end

local function download_bilibili_danmaku(path, cid, from_menu, callback)
    local url = "https://comment.bilibili.com/" .. cid .. ".xml"
    local args = build_curl_args(url)

    call_cmd_async(args, function(error, out)
        if error then
            show_message("HTTP request failed, see console for details", 5)
            msg.error(error)
            callback(false)
            return
        end
        if not out or out == '' then
            callback(false)
            return
        end
        save_danmaku_xml(path, out)
        load_danmaku(from_menu == nil and true or from_menu)
        callback(true)
    end)
end

-- 为 bilibli 网站的视频播放加载弹幕
function load_danmaku_for_bilibili(path, callback)
    callback = callback or function() end
    local cid, danmaku_id = get_cid()
    if danmaku_id ~= nil then
        mp.commandv('sub-remove', danmaku_id)
    end

    if cid == nil then
        cid = mp.get_opt('cid')
        if not cid then
            local patterns = {
                "bilivideo%.c[nom]+.*/resource/(%d+)%D+.*",
                "bilivideo%.c[nom]+.*/(%d+)-%d+-%d+%..*%?",
            }
            local urls = {
                path,
                mp.get_property("stream-open-filename", ''),
            }

            for _, pattern in ipairs(patterns) do
                for _, url in ipairs(urls) do
                    if url:find(pattern) then
                        cid = url:match(pattern)
                        break
                    end
                end
            end
        end
    end
    if cid == nil then
        resolve_bilibili_cid(path, function(resolved_cid)
            if resolved_cid then
                download_bilibili_danmaku(path, resolved_cid, true, callback)
            else
                show_message("获取哔哩哔哩视频cid失败", 3)
                msg.error("获取哔哩哔哩视频cid失败")
                callback(false)
            end
        end)
        return
    end
    if cid ~= nil then
        download_bilibili_danmaku(path, cid, true, callback)
    end
end
