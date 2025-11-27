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
function set_episode_id(input, from_menu)
    from_menu = from_menu or false
    DANMAKU.source = "dandanplay"
    for url, source in pairs(DANMAKU.sources) do
        if source.from == "api_server" then
            if source.fname and file_exists(source.fname) then
                os.remove(source.fname)
            end

            if not source.from_history then
                DANMAKU.sources[url] = nil
            else
                DANMAKU.sources[url]["fname"] = nil
            end
        end
    end
    local episodeId = tonumber(input)
    write_history(episodeId)
    set_danmaku_button()
    if options.load_more_danmaku and options.api_server:find("api%.dandanplay%.") then
        fetch_danmaku_all(episodeId, from_menu)
    else
        fetch_danmaku(episodeId, from_menu)
    end
end

-- 回退使用额外的弹幕获取方式
function get_danmaku_fallback(query)
    local url = options.fallback_server .. "/?url=" .. query
    msg.verbose("尝试获取弹幕：" .. url)
    local temp_file = "danmaku-" .. PID .. DANMAKU.count .. ".xml"
    local danmaku_xml = utils.join_path(DANMAKU_PATH, temp_file)
    DANMAKU.count = DANMAKU.count + 1
    local arg = {
        "curl",
        "-L",
        "-s",
        "--compressed",
        "--user-agent",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0",
        "--output",
        danmaku_xml,
        url,
    }

    if options.proxy ~= "" then
        table.insert(arg, '-x')
        table.insert(arg, options.proxy)
    end

    call_cmd_async(arg, function(error)
        async_running = false
        if error then
            show_message("HTTP 请求失败，打开控制台查看详情", 5)
            msg.error(error)
            return
        end
        if file_exists(danmaku_xml) then
            save_danmaku_downloaded(query, danmaku_xml)
            load_danmaku(true)
        end
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

-- 尝试通过解析文件名匹配剧集
local function match_episode(animeTitle, bangumiId, episode_num)
    local url = options.api_server .. "/api/v2/bangumi/" .. bangumiId
    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    call_cmd_async(args, function(error, json)
        async_running = false
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
                set_episode_id(episode.episodeId)
                break
            end
        end
    end)
end

local function match_anime()
    local animes = {}
    local anime_type = "tvseries"
    local type_count = 0
    local title, season_num, episode_num = parse_title()
    if not episode_num then
        msg.info("无法解析剧集信息")
        return
    end

    if title:match("OVA") or title:match("OAD") then
        anime_type = "ova"
    end

    local encoded_query = url_encode(title)
    local url = options.api_server .. "/api/v2/search/anime"
    local params = "keyword=" .. encoded_query
    local full_url = url .. "?" .. params
    local args = make_danmaku_request_args("GET", full_url)

    if not args then return end

    call_cmd_async(args, function(error, json)
        async_running = false
        if error then
            show_message("HTTP 请求失败，打开控制台查看详情", 5)
            msg.error(error)
            return
        end

        local data = utils.parse_json(json)
        if not data or not data.animes then
            msg.info("无结果")
            return
        end

        for _, anime in ipairs(data.animes) do
            if anime.type == anime_type then
                type_count = type_count + 1
                table.insert(animes, anime)
            end
        end

        if type_count == 1 then
            match_episode(animes[1].animeTitle, animes[1].bangumiId, episode_num)
        elseif type_count > 1 and season_num then
            local best_match, best_score = nil, -1
            local target_title = title
            if tonumber(season_num) > 1 then
                target_title = title .. " 第" .. number_to_chinese(season_num) .. "季"
            end
            for _, anime in ipairs(animes) do
                if anime.animeTitle:match("第一[季部]") and tonumber(season_num) == 1 then
                    target_title = title .. " 第一季"
                end
                local score = jaro_winkler(target_title, anime.animeTitle)
                msg.debug(("候选: %s -> 相似度 %.3f"):format(anime.animeTitle, score))
                if score > best_score then
                    best_score = score
                    best_match = anime
                end
            end

            if best_match and best_score >= 0.75 then
                msg.info(("模糊匹配选中: %s (score=%.2f)"):format(best_match.animeTitle, best_score))
                match_episode(best_match.animeTitle, best_match.bangumiId, episode_num)
            else
                msg.info("匹配到多个结果，但相似度不足，请手动搜索")
            end
        else
            msg.info("没有找到合适的匹配结果")
        end
    end)
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

    local url = options.api_server .. "/api/v2/match"
    local args = make_danmaku_request_args("POST", url, {
            ["Content-Type"] = "application/json"
        }, {
            fileName = file_name,
            fileHash = hash or "a1b2c3d4e5f67890abcd1234ef567890",
            matchMode = "hashAndFileName"
        }
    )

    if not args then return end

    call_cmd_async(args, function(error, json)
        async_running = false
        if error then
            show_message("HTTP 请求失败，打开控制台查看详情", 5)
            callback(error)
            return
        end
        local data = utils.parse_json(json)
        if not data or not data.isMatched or #data.matches > 1 then
            callback("没有匹配的剧集")
            return
        end

        DANMAKU.anime = data.matches[1].animeTitle
        DANMAKU.episode = data.matches[1].episodeTitle

        -- 获取并加载弹幕数据
        set_episode_id(data.matches[1].episodeId)
    end)
end

-- 异步获取弹幕数据
function fetch_danmaku_data(args, callback)
    call_cmd_async(args, function(error, json)
        async_running = false
        if error then
            show_message("获取数据失败", 3)
            msg.error("HTTP 请求失败：" .. error)
            return
        end
        local data = utils.parse_json(json)
        callback(data)
    end)
end

-- 保存弹幕数据
function save_danmaku_data(comments, query, danmaku_source)
    local temp_file = "danmaku-" .. PID .. DANMAKU.count .. ".json"
    local danmaku_file = utils.join_path(DANMAKU_PATH, temp_file)
    DANMAKU.count = DANMAKU.count + 1
    local success = save_danmaku_json(comments, danmaku_file)

    if success then
        if DANMAKU.sources[query] ~= nil then
            if DANMAKU.sources[query].fname and file_exists(DANMAKU.sources[query].fname) then
                os.remove(DANMAKU.sources[query].fname)
            end
            DANMAKU.sources[query]["fname"] = danmaku_file
        else
            DANMAKU.sources[query] = {from = danmaku_source, fname = danmaku_file}
        end
    end
end

function save_danmaku_downloaded(url, downloaded_file)
    if DANMAKU.sources[url] ~= nil then
        if DANMAKU.sources[url].fname and file_exists(DANMAKU.sources[url].fname) then
            os.remove(DANMAKU.sources[url].fname)
        end
        DANMAKU.sources[url]["fname"] = downloaded_file
    else
        DANMAKU.sources[url] = {from = "user_custom", fname = downloaded_file}
    end
end

-- 处理弹幕数据
function handle_danmaku_data(query, data, from_menu)
    local comments = data["comments"]
    local count = data["count"]

    -- 如果没有数据，进行重试
    if count == 0 then
        show_message("服务器无缓存数据，再次尝试请求", 30)
        msg.verbose("服务器无缓存数据，再次尝试请求")
        -- 等待 2 秒后重试
        local start = os.time()
        while os.time() - start < 2 do
            -- 空循环，等待 2 秒
        end
        -- 重新发起请求
        local url = options.api_server .. "/api/v2/extcomment?url=" .. url_encode(query)
        local args = make_danmaku_request_args("GET", url)

        if args == nil then
            return
        end

        fetch_danmaku_data(args, function(retry_data)
            if not retry_data or not retry_data["comments"] or retry_data["count"] == 0 then
                get_danmaku_fallback(query)
                return
            end
            save_danmaku_data(retry_data["comments"], query, "user_custom")
            load_danmaku(from_menu)
        end)
    else
        save_danmaku_data(comments, query, "user_custom")
        load_danmaku(from_menu)
    end
end

-- 处理第三方弹幕数据
function handle_related_danmaku(index, relateds, related, shift, callback)
    local url = options.api_server .. "/api/v2/extcomment?url=" .. url_encode(related["url"])
    show_message(string.format("正在从第三方库装填弹幕 [%d/%d]", index, #relateds), 30)
    msg.verbose("正在从第三方库装填弹幕：" .. url)

    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    fetch_danmaku_data(args, function(data)
        local comments = {}
        if data and data["comments"] then
            if data["count"] == 0 then
                -- 如果没有数据，稍等 2 秒重试
                local start = os.time()
                while os.time() - start < 2 do
                    -- 空循环，等待 2 秒
                end
                fetch_danmaku_data(args, function(data)
                    for _, comment in ipairs(data["comments"]) do
                        comment["shift"] = shift
                        table.insert(comments, comment)
                    end
                    callback(comments)
                end)
            else
                for _, comment in ipairs(data["comments"]) do
                    comment["shift"] = shift
                    table.insert(comments, comment)
                end
                callback(comments)
            end
        else
            show_message("无数据", 3)
            msg.info("无数据")
            callback(comments)
        end
    end)
end

-- 处理dandan库的弹幕数据
function handle_main_danmaku(url, from_menu)
    show_message("正在从弹弹Play库装填弹幕", 30)
    msg.verbose("尝试获取弹幕：" .. url)
    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    fetch_danmaku_data(args, function(data)
        if not data or not data["comments"] then
            show_message("无数据", 3)
            msg.info("无数据")
            return
        end

        local comments = data["comments"]
        local count = data["count"]

        if count == 0 then
            if DANMAKU.sources[url] == nil then
                DANMAKU.sources[url] = {from = "api_server"}
            end
            load_danmaku(from_menu)
            return
        end

        save_danmaku_data(comments, url, "api_server")
        load_danmaku(from_menu)
    end)
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

-- 过滤被排除的平台
function filter_excluded_platforms(relateds)
    -- 解析排除的平台列表
    local excluded_list = {}
    local excluded_json = options.excluded_platforms
    if excluded_json and excluded_json ~= "" and excluded_json ~= "[]" then
        local success, parsed = pcall(utils.parse_json, excluded_json)
        if success and parsed and type(parsed) == "table" then
            excluded_list = parsed
        end
    end

    -- 如果没有排除列表，直接返回原列表
    if #excluded_list == 0 then
        return relateds
    end

    -- 过滤弹幕源
    local filtered = {}
    for _, related in ipairs(relateds) do
        local url = related["url"]
        local should_exclude = false

        -- 检查URL是否包含任何被排除的平台关键词
        for _, platform in ipairs(excluded_list) do
            if url:find(platform, 1, true) then
                should_exclude = true
                msg.info(string.format("已排除平台 [%s] 的弹幕源: %s", platform, url))
                break
            end
        end

        if not should_exclude then
            table.insert(filtered, related)
        end
    end

    msg.info(string.format("原始弹幕源: %d 个, 过滤后: %d 个", #relateds, #filtered))
    return filtered
end

-- 匹配弹幕库 comment, 仅匹配dandan本身弹幕库
-- 通过danmaku api（url）+id获取弹幕
function fetch_danmaku(episodeId, from_menu)
    local url = options.api_server .. "/api/v2/comment/" .. episodeId .. "?withRelated=true&chConvert=0"
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

-- 主函数：获取所有相关弹幕
function fetch_danmaku_all(episodeId, from_menu)
    local url = options.api_server .. "/api/v2/related/" .. episodeId
    show_message("弹幕加载中...", 30)
    msg.verbose("尝试获取弹幕：" .. url)
    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    fetch_danmaku_data(args, function(data)
        if not data or not data["relateds"] then
            show_message("无数据", 3)
            msg.info("无数据")
            return
        end

        -- 处理所有的相关弹幕，过滤掉被排除的平台
        local relateds = data["relateds"]
        local filtered_relateds = filter_excluded_platforms(relateds)
        local function process_related(index)
            if index > #filtered_relateds then
                -- 所有相关弹幕加载完成后，开始加载主库弹幕
                url = options.api_server .. "/api/v2/comment/" .. episodeId .. "?withRelated=false&chConvert=0"
                handle_main_danmaku(url, from_menu)
                return
            end

            local related = filtered_relateds[index]
            local shift = related["shift"]

            -- 处理当前的相关弹幕
            handle_related_danmaku(index, filtered_relateds, related, shift, function(comments)
                if #comments == 0 then
                    if DANMAKU.sources[related["url"]] == nil then
                        DANMAKU.sources[related["url"]] = {from = "api_server"}
                    end
                else
                    save_danmaku_data(comments, related["url"], "api_server")
                end

                -- 继续处理下一个相关弹幕
                process_related(index + 1)
            end)
        end

        -- 从第一个相关库开始请求
        process_related(1)
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
    if not (string.match(path, "%.xml$") or string.match(path, "%.json$") or string.match(path, "%.ass$")) then
        msg.warn("仅支持弹幕文件")
        return
    end

    if DANMAKU.sources[query] ~= nil then
        if DANMAKU.sources[query].fname and file_exists(DANMAKU.sources[query].fname) then
            os.remove(DANMAKU.sources[query].fname)
        end
        DANMAKU.sources[query]["from"] = "user_local"
        DANMAKU.sources[query]["fname"] = path
    else
        DANMAKU.sources[query] = {from = "user_local", fname = path}
    end

    set_danmaku_button()
    load_danmaku(from_menu)
end

--通过输入源url获取弹幕库
function add_danmaku_source_online(query, from_menu)
    set_danmaku_button()
    local url = options.api_server .. "/api/v2/extcomment?url=" .. url_encode(query)
    show_message("弹幕加载中...", 30)
    msg.verbose("尝试获取弹幕：" .. url)
    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    fetch_danmaku_data(args, function(data)
        if not data or not data["comments"] then
            show_message("此源弹幕无法加载", 3)
            msg.verbose("此源弹幕无法加载")
            return
        end
        handle_danmaku_data(query, data, from_menu)
    end)
end

-- 将弹幕转换为factory可读的json格式
function save_danmaku_json(comments, json_filename)
    local temp_file = "danmaku-" .. PID .. ".json"
    json_filename = json_filename or utils.join_path(DANMAKU_PATH, temp_file)
    local json_file = io.open(json_filename, "w")

    if json_file then
        json_file:write("[\n")
        for _, comment in ipairs(comments) do
            local p = comment["p"]
            local shift = comment["shift"]
            if p then
                local fields = split(p, ",")
                if shift ~= nil then
                    fields[1] = tonumber(fields[1]) + tonumber(shift)
                end
                local c_value = string.format(
                    "%s,%s,%s,25,,,",
                    tostring(fields[1]), -- first field of p to first field of c
                    fields[3], -- third field of p to second field of c
                    fields[2]  -- second field of p to third field of c
                )
                local m_value = comment["m"]
                                :gsub("[%z\1-\31]", "")
                                :gsub("\\", "")
                                :gsub("\"", "")

                -- Write the JSON object as a single line, no spaces or extra formatting
                local json_entry = string.format('{"c":"%s","m":"%s"},\n', c_value, m_value)
                json_file:write(json_entry)
            end
        end
        json_file:write("]")
        json_file:close()
        return true
    end

    return false
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
            async_running = false

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
