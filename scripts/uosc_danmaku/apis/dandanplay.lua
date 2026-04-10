local msg = require('mp.msg')
local utils = require("mp.utils")

local function extract_url(url)
    local path = url:match("^https?://[^/]+(/[^%?]*)")
    return path
end

local function generateXSignature(url, time, appid, app_accept)
    local url_path = extract_url(url)
    if not url_path then
        return nil
    end

    local dataToHash = string.format("%s%d%s%s", AES.ECB.decrypt(KEY, Base64.decode(appid)),
    time, url_path, AES.ECB.decrypt(KEY, Base64.decode(app_accept)))
    local hash = Sha256(dataToHash)
    local base64Hash = Base64.encode(hex_to_bin(hash))
    return base64Hash
end

-- 写入history.json
-- 读取episodeId获取danmaku
function set_episode_id(input, from_menu, api_server)
    from_menu = from_menu or false
    DANMAKU.source = "dandanplay"
    local selected_server = api_server
    for url, source in pairs(DANMAKU.sources) do
        if source.from == "api_server" then
            if not source.from_history then
                DANMAKU.sources[url] = nil
            else
                DANMAKU.sources[url]["data"] = nil
            end
        end
    end

    if not api_server then
        if DANMAKU.api_server ~= nil then
            selected_server = DANMAKU.api_server
        else
            local servers = get_api_server_list(options.api_server)
            if servers and #servers > 0 then
                selected_server = servers[1]
            end
        end
    end

    DANMAKU.api_server = selected_server

    local episodeId = tonumber(input)
    write_history(episodeId, selected_server)
    set_danmaku_button()
    fetch_danmaku(episodeId, from_menu, selected_server)
end

-- 回退使用额外的弹幕获取方式
function get_danmaku_fallback(query)
    local url = options.fallback_server .. "/?ac=dm&url=" .. query
    msg.verbose("尝试获取弹幕：" .. url)

    local args = make_danmaku_request_args("GET", url)
    if not args then return end

    fetch_danmaku_data(args, function(data)
        if not data or not data["comments"] or data["count"] <= 1 then
            msg.info("备用服务器无数据或返回格式不正确")
            show_message("备用服务器无数据或返回格式不正确", 3)
            return
        end

        save_danmaku_data(data["comments"], query, "user_custom")
        load_danmaku(true)
    end)
end

-- 返回弹幕请求参数
function make_danmaku_request_args(method, url, headers, body)
    local args = {
        "curl",
        "-L",
        "-X",
        method,
        "-H",
        "Accept: application/json",
        "-H",
        "User-Agent: " .. options.user_agent,
    }

    if headers then
        for k, v in pairs(headers) do
            table.insert(args, '-H')
            table.insert(args, string.format('%s: %s', k, v))
        end
    end

    if body then
        table.insert(args, '-d')
        table.insert(args, utils.format_json(body))
        table.insert(args, '-H')
        table.insert(args, 'Content-Type: application/json')
    end

    if url:find("api%.dandanplay%.") then
        local time = os.time()
        local appid = "UgjRIH45lE1BBLNmir1WKw=="
        local app_accept = "SzuWlFZAPRMqeWf9qmfp8dcvYr3hvxuSrIRZuAeEfko="
        table.insert(args, '-H')
        table.insert(args, string.format('X-AppId: %s', AES.ECB.decrypt(KEY, Base64.decode(appid))))
        table.insert(args, '-H')
        table.insert(args, string.format('X-Signature: %s', generateXSignature(url, time, appid, app_accept)))
        table.insert(args, '-H')
        table.insert(args, string.format('X-Timestamp: %s', time))
    end

    if options.proxy ~= "" then
        table.insert(args, '-x')
        table.insert(args, options.proxy)
    end

    table.insert(args, url)

    return args
end

local function normalize_danmaku_response(d)
    if not d then return d end
    -- 已经是 comments/count 格式则直接返回
    if d.comments or d.count then return d end

    if d.danmuku and type(d.danmuku) == "table" then
        local out = {}
        for _, item in ipairs(d.danmuku) do
            -- item 预期为数组，索引: 1=time, 2=pos(right/top/bottom), 3=color(hex), 5=content
            local time = tonumber(item[1]) or 0
            local pos = item[2] or "right"
            local color = item[3] or ""
            local content = item[5] or item[4] or ""

            local mode = 1
            if pos == "right" then
                mode = 1
            elseif pos == "top" then
                mode = 4
            elseif pos == "bottom" then
                mode = 5
            end

            local colorDec = 16777215
            if type(color) == "number" then
                colorDec = color
            elseif type(color) == "string" then
                colorDec = hex_to_int_color(color)
            end

            local p = string.format("%.2f,%d,%d", time, mode, colorDec)
            table.insert(out, { p = p, m = content })
        end
        return { comments = out, count = tonumber(d.danum) or #out }
    end

    return d
end

-- 尝试通过解析文件名匹配剧集
local function match_episode(animeTitle, bangumiId, episode_num, api_server)
    local url = api_server .. "/api/v2/bangumi/" .. bangumiId
    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    call_cmd_async(args, function(error, json)
        if error then
            show_message("HTTP 请求失败，打开控制台查看详情", 5)
            msg.error(error)
            return
        end

        local data = utils.parse_json(json)
        if not data or not data.bangumi or not data.bangumi.episodes then
            msg.info("无结果")
            return
        end

        for _, episode in ipairs(data.bangumi.episodes) do
            local ep_num = tonumber(episode.episodeNumber)
            if ep_num and ep_num == tonumber(episode_num) then
                DANMAKU.anime = animeTitle
                DANMAKU.episode = episode.episodeTitle
                set_episode_id(episode.episodeId, nil, api_server)
                break
            end
        end
    end)
end

local function match_anime()
    local anime_type = "tvseries"
    local title, season_num, episode_num = parse_title()
    if not episode_num then
        msg.info("无法解析剧集信息")
        return
    end

    if title:match("OVA") or title:match("OAD") then
        anime_type = "ova"
    end

    -- 并发在多个 api_server 上搜索，遇到第一个可接受的匹配就取消其余请求
    local encoded_query = url_encode(title)
    local servers = get_api_server_list(options.api_server)

    local matched = false
    local cancel_fn = nil

    local function build_args(server)
        local url = server .. "/api/v2/search/anime"
        local full_url = url .. "?keyword=" .. encoded_query
        return make_danmaku_request_args("GET", full_url)
    end

    local function per_response(server, err, out)
        if matched then return end
        if err then
            msg.debug(("search anime failed for %s: %s"):format(server, tostring(err)))
            return
        end
        local data = utils.parse_json(out)
        if not data or not data.animes then
            return
        end
        local local_candidates = {}
        for _, anime in ipairs(data.animes) do
            if anime.type == anime_type then
                table.insert(local_candidates, anime)
            end
        end
        if #local_candidates == 1 then
            matched = true
            local a = local_candidates[1]
            match_episode(a.animeTitle, a.bangumiId, episode_num, server)
            if cancel_fn then pcall(cancel_fn) end
            return
        end
        if #local_candidates > 1 and season_num then
            local best_match, best_score = nil, -1
            local target_title = title
            if tonumber(season_num) > 1 then
                target_title = title .. " 第" .. number_to_chinese(season_num) .. "季"
            end
            for _, anime in ipairs(local_candidates) do
                local animeTitle = tostring(anime.animeTitle or "")
                animeTitle = animeTitle:gsub("^%s*(.-)%s*$", "%1")
                            :gsub("%s*%(.-%)%s*$", "")
                            :gsub("%s*【.-】.*$", "")
                if animeTitle:match("第一[季部]") and tonumber(season_num) == 1 then
                    target_title = title .. " 第一季"
                end
                local score = jaro_winkler(target_title, animeTitle)
                msg.debug(("候选: %s -> 相似度 %.3f"):format(animeTitle, score))
                if score > best_score then
                    best_score = score
                    best_match = anime
                end
            end
            if best_match and best_score >= 0.75 then
                matched = true
                msg.info(("模糊匹配选中: %s (score=%.2f)"):format(best_match.animeTitle, best_score))
                match_episode(best_match.animeTitle, best_match.bangumiId, episode_num, server)
                if cancel_fn then pcall(cancel_fn) end
                return
            end
        end
        -- 未找到可接受匹配，继续等待其他服务器的返回
    end

    local function final_cb()
        if not matched then
            msg.info("没有找到合适的匹配结果")
        end
    end

    cancel_fn = parallel_requests(servers, build_args, per_response, final_cb, { concurrency = 5, per_request_timeout = 15 })
end

-- 执行哈希匹配获取弹幕
local function match_file(file_path, file_name, callback)
    -- 计算文件哈希
    local hash = nil
    local file_info = utils.file_info(file_path)
    if file_info and file_info.size > 16 * 1024 * 1024 then
        local file, error = io.open(normalize(file_path), 'rb')
        if file and not error then
            local m = MD5.new()
            for _ = 1, 16 * 1024 do
                local content = file:read(1024)
                if not content then
                    break
                end
                m:update(content)
            end
            file:close()
            hash = m:finish()
        end
    end

    if hash then msg.info('hash:', hash) end

    local title, season_num, episode_num = parse_title()
    if title and episode_num then
        if season_num then
            file_name = title .. " S" .. season_num .. "E" .. episode_num
        else
            file_name = title .. " E" .. episode_num
        end
    else
        file_name = title
    end

    local servers = get_api_server_list(options.api_server)

    local matched = false
    local cancel_fn = nil

    local function build_args(server)
        local url = server .. "/api/v2/match"
        return make_danmaku_request_args("POST", url, { ["Content-Type"] = "application/json" }, {
            fileName = file_name,
            fileHash = hash or "a1b2c3d4e5f67890abcd1234ef567890",
            matchMode = "hashAndFileName"
        })
    end

    local function per_response(server, err, out)
        if matched then return end
        if err then
            msg.debug(("match failed for %s: %s"):format(server, tostring(err)))
            return
        end
        local data = utils.parse_json(out)
        if not data or not data.isMatched then
            return
        end
        matched = true
        DANMAKU.anime = data.matches[1].animeTitle
        DANMAKU.episode = data.matches[1].episodeTitle

        set_episode_id(data.matches[1].episodeId, nil, server)
        if cancel_fn then pcall(cancel_fn) end
        if callback then pcall(callback) end
    end

    local function final_cb()
        if not matched then
            callback("没有匹配的剧集")
        end
    end

    cancel_fn = parallel_requests(servers, build_args, per_response, final_cb, { concurrency = 5, per_request_timeout = 15 })
end

-- 异步获取弹幕数据
function fetch_danmaku_data(args, callback)
    call_cmd_async(args, function(error, json)
        if error then
            show_message("获取数据失败", 3)
            msg.error("HTTP 请求失败：" .. error)
            return
        end
        local data = utils.parse_json(json)
        data = normalize_danmaku_response(data)
        callback(data)
    end)
end

-- 保存弹幕数据
function save_danmaku_data(comments, query, danmaku_source)
    local danmaku_list = save_danmaku_to_list(comments)

    if DANMAKU.sources[query] ~= nil then
        DANMAKU.sources[query]["data"] = danmaku_list
    else
        DANMAKU.sources[query] = {from = danmaku_source, data = danmaku_list}
    end
end

function save_danmaku_downloaded(url, downloaded_file)
    local danmaku_list = parse_danmaku_file(downloaded_file)
    if file_exists(downloaded_file) then
        os.remove(downloaded_file)
    end
    if DANMAKU.sources[url] ~= nil then
        DANMAKU.sources[url]["data"] = danmaku_list
    else
        DANMAKU.sources[url] = {from = "user_custom", data = danmaku_list}
    end
end

-- 处理获取到的数据
function handle_fetched_danmaku(data, url, from_menu)
    if data and data["comments"] then
        if data["count"] == 0 then
            if DANMAKU.sources[url] == nil then
                DANMAKU.sources[url] = {from = "api_server"}
            end
            show_message("该集弹幕内容为空，结束加载", 3)
            msg.verbose("该集弹幕内容为空，结束加载")
            return
        end
        save_danmaku_data(data["comments"], url, "api_server")
        load_danmaku(from_menu)
    else
        show_message("无数据", 3)
        msg.info("无数据")
    end
end

-- 匹配弹幕库 comment, 仅匹配dandan本身弹幕库
-- 通过danmaku api（url）+id获取弹幕
function fetch_danmaku(episodeId, from_menu, api_server)
    local url = api_server .. "/api/v2/comment/" .. episodeId .. "?withRelated=true&chConvert=0"
    show_message("弹幕加载中...", 30)
    msg.verbose("尝试获取弹幕：" .. url)
    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    fetch_danmaku_data(args, function(data)
        handle_fetched_danmaku(data, url, from_menu)
    end)
end

-- 从用户添加过的弹幕源添加弹幕
function addon_danmaku(dir, from_menu)
    if dir then
        local history_json = read_file(HISTORY_PATH)
        local history = utils.parse_json(history_json) or {}
        if history[dir] and history[dir].extra ~= nil then
            return
        end
    end
    for url, source in pairs(DANMAKU.sources) do
        if source.from ~= "api_server" then
            add_danmaku_source(url, from_menu)
        end
    end
end

--通过输入源url获取弹幕库
function add_danmaku_source(query, from_menu)
    if DANMAKU.sources[query] == nil then
        DANMAKU.sources[query] = {from = "user_custom"}
    end

    from_menu = from_menu or false
    if from_menu then
        add_source_to_history(query, DANMAKU.sources[query])
    end

    if is_protocol(query) then
        add_danmaku_source_online(query, from_menu)
    else
        add_danmaku_source_local(query, from_menu)
    end
end

function add_danmaku_source_local(query, from_menu)
    local path = normalize(query)
    if not file_exists(path) then
        msg.warn("无效的文件路径")
        return
    end
    if not (string.match(path, "%.xml$") or string.match(path, "%.json$")) then
        msg.warn("仅支持弹幕文件")
        return
    end

    if DANMAKU.sources[query] ~= nil then
        DANMAKU.sources[query]["from"] = "user_local"
        DANMAKU.sources[query]["data"] = parse_danmaku_file(path)
    else
        DANMAKU.sources[query] = {from = "user_local", data = parse_danmaku_file(path)}
    end

    set_danmaku_button()
    load_danmaku(from_menu)
end

--通过输入源url获取弹幕库
function add_danmaku_source_online(query, from_menu)
    set_danmaku_button()
    show_message("弹幕加载中...", 30)
    msg.verbose("尝试获取弹幕：" .. query)

    local servers = get_api_server_list(options.api_server)

    -- 过滤掉指向 dandanplay.net 的服务器
    local filtered = {}
    for _, s in ipairs(servers) do
        if type(s) == "string" and not s:lower():find("dandanplay%.net") then
            table.insert(filtered, s)
        end
    end
    servers = filtered
    if #servers == 0 then
        get_danmaku_fallback(query)
        return
    end

    local matched = false
    local cancel_fn = nil

    local function build_args(server)
        local url = server .. "/api/v2/extcomment?url=" .. url_encode(query)
        return make_danmaku_request_args("GET", url)
    end

    local function per_response(server, err, out)
        if matched then return end
        if err then
            msg.debug(("extcomment failed for %s: %s"):format(server, tostring(err)))
            return
        end
        local data = utils.parse_json(out)
        data = normalize_danmaku_response(data)
        if not data or not data["comments"] or data["count"] <= 1 then
            return
        end
        matched = true
        -- 保存并加载弹幕
        save_danmaku_data(data["comments"], query, "user_custom")
        load_danmaku(from_menu)
        -- 取消其他未完成请求
        if cancel_fn then pcall(cancel_fn) end
    end

    local function final_cb()
        if not matched then
            -- 所有服务器都未返回有效弹幕，回退到备用服务器
            msg.info("所有服务器均无有效弹幕，尝试备用服务器")
            get_danmaku_fallback(query)
        end
    end

    cancel_fn = parallel_requests(servers, build_args, per_response, final_cb, { concurrency = 3, per_request_timeout = 30 })
end

-- 将弹幕转换为 Lua table
function save_danmaku_to_list(comments)
    local danmaku_list = {}

    for _, comment in ipairs(comments) do
        local p = comment["p"]
        local shift = comment["shift"]
        if p then
            local fields = split(p, ",")
            if shift ~= nil then
                fields[1] = tonumber(fields[1]) + tonumber(shift)
            end
            local time = tonumber(fields[1])
            local type = tonumber(fields[2])
            local color = tonumber(fields[3]) or 0xFFFFFF
            local size = 25
            local m_value = comment["m"]
                            :gsub("[%z\1-\31]", "")
                            :gsub("\\", "")
                            :gsub("\"", "")
            table.insert(danmaku_list, {
                time = time,
                type = type,
                size = size,
                color = color,
                text = m_value
            })
        end
    end

    return danmaku_list
end

-- 通过文件前 16M 的 hash 值进行弹幕匹配
function get_danmaku_with_hash(file_name, file_path)
    if type(MD5) ~= "table" or not MD5.sum then
        msg.warn("MD5 模块不支持 Lua 5.1，回退到文件名匹配")
        match_anime()
        return
    end
    if is_protocol(file_path) then
        set_danmaku_button()
        local temp_file = "temp-" .. PID .. ".mp4"
        local arg = {
            "curl",
            "--connect-timeout",
            "10",
            "--max-time",
            "30",
            "--range",
            "0-16777215",
            "--user-agent",
            options.user_agent,
            "--output",
            utils.join_path(DANMAKU_PATH, temp_file),
            "-L",
            file_path,
        }

        if options.proxy ~= "" then
            table.insert(arg, '-x')
            table.insert(arg, options.proxy)
        end

        call_cmd_async(arg, function(error)
            file_path = utils.join_path(DANMAKU_PATH, temp_file)

            match_file(file_path, file_name, function(error)
                if error then
                    msg.error(error)
                    msg.info("尝试通过解析文件名获取弹幕")
                    match_anime()
                end
            end)
        end)
    else
        local dir = get_parent_directory(file_path)
        local excluded_path = utils.parse_json(options.excluded_path)
        if PLATFORM == "windows" then
            for i, path in pairs(excluded_path) do
                excluded_path[i] = path:gsub("/", "\\")
            end
        end
        if contains_any(excluded_path, dir) then
            match_anime()
            return
        end
        match_file(file_path, file_name, function(error)
            if error then
                msg.error(error)
                msg.info("尝试通过解析文件名获取弹幕")
                match_anime()
            end
        end)
    end
end
