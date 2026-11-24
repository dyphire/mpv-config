local msg = require('mp.msg')
local utils = require("mp.utils")
local unpack = unpack or table.unpack

input_loaded, input = pcall(require, "mp.input")

local input_requested_cbs, input_live_cbs = {}, {}
local function input_open(cb)
    table.insert(input_requested_cbs, cb)
    input.get(cb)
    mp.register_script_message("input-event", function(type, args)
        local params = utils.parse_json(args or "") or {}
        local cb
        if type == "opened" then
            cb = table.remove(input_requested_cbs, 1)
            if cb then
                table.insert(input_live_cbs, cb)
            end
        elseif type == "closed" then
            cb = table.remove(input_live_cbs, 1)
            if #input_requested_cbs > 0 then
                return
            end
        else
            cb = input_live_cbs[#input_live_cbs] or input_requested_cbs[#input_requested_cbs]
        end
        if cb and cb[type] then
            local suggestions, completion_start_position = cb[type](unpack(params))
            if type == "complete" and suggestions then
                mp.commandv("script-message-to", "console", "complete",
                            utils.format_json(suggestions), completion_start_position)
            end
        end
    end)
end

uosc_available = false
latest_menu_anime = {}
local active_request_cancel = nil
local active_request_type = nil
local request_cancelled = false

-- 如果 latest_menu_anime 中存在首项为加载占位，移除它（兼容完整 menu props 或 items 数组）
local function strip_loading_from_latest_menu_anime()
    if not latest_menu_anime or #latest_menu_anime == 0 then return end
    local parsed = utils.parse_json(latest_menu_anime)
    if not parsed or type(parsed) ~= "table" then return end
    local function is_loading_item(it)
        if not it or type(it) ~= "table" then return false end
        if it.title == "加载数据中..." then return true end
        if it.italic == true and it.icon == "spinner" then return true end
        return false
    end
    if parsed.items and type(parsed.items) == "table" then
        if #parsed.items > 0 and is_loading_item(parsed.items[1]) then
            table.remove(parsed.items, 1)
            latest_menu_anime = utils.format_json(parsed)
        end
    else
        if #parsed > 0 and is_loading_item(parsed[1]) then
            table.remove(parsed, 1)
            latest_menu_anime = utils.format_json(parsed)
        end
    end
end

-- 统一取消并发请求：设置取消标志、剥离加载占位并调用实际取消函数
local function perform_cancel_active_request(expected_type)
    if expected_type and active_request_type and tostring(expected_type) ~= tostring(active_request_type) then
        return
    end
    if active_request_cancel then
        request_cancelled = true
        strip_loading_from_latest_menu_anime()
        pcall(active_request_cancel)
        active_request_cancel = nil
        active_request_type = nil
    end
end

local function make_build_args(encoded_query)
    return function(server)
        local url = server .. "/api/v2/search/anime"
        local full_url = url .. "?keyword=" .. encoded_query
        return make_danmaku_request_args("GET", full_url)
    end
end

local function make_handle_response(ctx)
    return function(server, err, out)
        if request_cancelled then
            ctx.remaining.n = math.max(0, ctx.remaining.n - 1)
            return
        end

        local function do_final_update()
            if request_cancelled then return end
            if ctx.rendered then return end
            ctx.rendered = true

            local final_items = {}
            -- 按配置的 server 顺序拼接每个 server 的结果
            for _, srv in ipairs(ctx.server_order or {}) do
                local list = ctx.server_items and ctx.server_items[srv]
                if list and type(list) == 'table' then
                    for _, v in ipairs(list) do table.insert(final_items, v) end
                end
            end

            -- result_count 用去重后的总数；total_count 缺失时退化为条目数
            local result_count = ctx.total_count or #final_items
            local summary = {
                title = string.format("搜索完成，共 %d 个结果", result_count),
                italic = true,
                keep_open = true,
                selectable = false,
                icon = "done_all",
            }
            if result_count == 0 then
                summary.title = "搜索完成，无结果"
                summary.icon = "info"
            end
            if (ctx.failed_servers or 0) > 0 then
                summary.title = summary.title .. string.format("（%d 个数据源请求失败）",ctx.failed_servers)
                summary.icon = "warning"
            end
            -- 首行插入，由于result_count需要#final_items，所以该处代码需放置结果列表后面
            table.insert(final_items, 1, summary)

            if uosc_available then
                latest_menu_anime = update_menu_uosc(ctx.menu_type, ctx.menu_title, final_items,
                                                     ctx.footnote, ctx.menu_cmd, ctx.query)
            else
                show_message("", 0)
                latest_menu_anime = utils.format_json(final_items)
                if input_loaded then
                    input.terminate()
                    mp.add_timeout(0.1, function()
                        open_menu_select(final_items)
                    end)
                end
            end
        end

        -- 挂到 ctx 上，供 get_animes 的 final_cb 兜底调用
        ctx.render_final = do_final_update
        if err then
            ctx.failed_servers = (ctx.failed_servers or 0) + 1
            msg.debug(("search anime failed for %s: %s"):format(server, tostring(err)))
            ctx.remaining.n = math.max(0, ctx.remaining.n - 1)
            if ctx.remaining.n == 0 then pcall(do_final_update) end
            return
        end
        local data = utils.parse_json(out)
        if not data or not data.animes then
            ctx.failed_servers = (ctx.failed_servers or 0) + 1
            ctx.remaining.n = math.max(0, ctx.remaining.n - 1)
            if ctx.remaining.n == 0 then pcall(do_final_update) end
            return
        end
        for _, anime in ipairs(data.animes) do
            local key = anime.bangumiId or (anime.animeTitle and anime.animeTitle:gsub("%s+", " ") or nil)
            if key and not ctx.seen[key] then
                ctx.seen[key] = true
                ctx.server_items[server] = ctx.server_items[server] or {}
                local note = (ctx.server_notes and ctx.server_notes[server]) or nil
                local hint = anime.typeDescription
                if note and note ~= "" then
                    if hint and hint ~= "" then
                        hint = hint .. "|" .. note
                    else
                        hint = note
                    end
                end
                table.insert(ctx.server_items[server], {
                    title = anime.animeTitle,
                    hint = hint,
                    value = { "script-message-to", mp.get_script_name(), "search-episodes-event", anime.animeTitle, anime.bangumiId, server },
                })
                ctx.total_count = (ctx.total_count or 0) + 1
            end
        end
        local display_items = {}
        if ctx.remaining.n > 0 then
            local progress_msg = ctx.message or ""
            if ctx.total_servers and ctx.total_servers > 1 and ctx.remaining and ctx.remaining.n then
                local completed = math.max(0, (ctx.total_servers - ctx.remaining.n) + 1)
                progress_msg = tostring(progress_msg):gsub("%.+$", "")
                progress_msg = progress_msg .. string.format("（%d/%d）...", completed, ctx.total_servers)
            end
            table.insert(display_items, {
                title = progress_msg,
                value = "",
                italic = true,
                keep_open = true,
                selectable = false,
                icon = "spinner",
            })
        end
        -- 按 server_order 拼接当前已收到的结果
        for _, srv in ipairs(ctx.server_order or {}) do
            local list = ctx.server_items and ctx.server_items[srv]
            if list and type(list) == 'table' then
                for _, v in ipairs(list) do table.insert(display_items, v) end
            end
        end

        if uosc_available then
            latest_menu_anime = update_menu_uosc(ctx.menu_type, ctx.menu_title, display_items, ctx.footnote, ctx.menu_cmd, ctx.query,
                { "script-message-to", mp.get_script_name(), "cancel-active-request", ctx.menu_type })
        else
            if not ctx.first_opened.val and input_loaded and (ctx.total_count or 0) > 0 then
                ctx.first_opened.val = true
                show_message("", 0)
                input.terminate()
                mp.add_timeout(0.1, function()
                    if ctx.rendered then return end
                    latest_menu_anime = utils.format_json(display_items)
                    open_menu_select(display_items)
                end)
            end
        end

        ctx.remaining.n = math.max(0, ctx.remaining.n - 1)
        if ctx.remaining.n == 0 then
            pcall(do_final_update)
        end
    end
end

-- 打开番剧数据匹配菜单
function get_animes(query, filter_note)
    local encoded_query = url_encode(query)
    local all_metas = get_api_server_list(options.api_server, true)
    local server_hint = ""
    local server_metas = {}
    if filter_note and filter_note ~= "" then
        local matched = {}
        for _, m in ipairs(all_metas) do
            if m.note and m.note == filter_note then
                table.insert(matched, m)
            end
        end
        if #matched > 0 then
            server_metas = { matched[1] }  -- 只取第一个匹配的
            server_note = "服务器【" .. filter_note .. "】"
        else
            show_message("未找到备注为【" .. filter_note .. "】的服务器，将使用全部服务器", 3)
            msg.info("未找到备注为【" .. filter_note .. "】的服务器，将使用全部服务器")
            server_metas = all_metas
        end
    else
        server_metas = all_metas
    end

    local servers = {}
    local server_notes = {}
    for _, m in ipairs(server_metas) do
        table.insert(servers, m.url)
        if m.note and m.note ~= '' then
            server_notes[m.url] = m.note
        end
    end

    local items = {}
    local seen = {}
    local first_opened = false
    local remaining = #servers
    local total_servers = remaining
    local server_items = {}
    local server_order = servers
    local total_count = 0
    request_cancelled = false

    local message = server_hint .. "加载数据中..."
    local menu_type = "menu_anime"
    local menu_title = "在此处输入番剧名称"
    local footnote = "使用enter或ctrl+enter进行搜索"
    local menu_cmd = { "script-message-to", mp.get_script_name(), "search-anime-event" }

    local function strip_trailing_dots(s)
        if not s then return "" end
        return tostring(s):gsub("%.+$", "")
    end

    local initial_message = message
    if total_servers and total_servers > 1 then
        initial_message = strip_trailing_dots(message) .. string.format("（%d/%d）...", 0, total_servers)
    end
    if uosc_available then
        active_request_type = menu_type
        update_menu_uosc(menu_type, menu_title, initial_message, footnote, menu_cmd, query, "spinner",
            { "script-message-to", mp.get_script_name(), "cancel-active-request", menu_type })
    else
        show_message(initial_message, 30)
    end

    msg.verbose("尝试获取番剧数据，servers: " .. table.concat(servers, ", ") .. " query: " .. query)

    local build_args = make_build_args(encoded_query)

    -- 构造 ctx，用于 handle_response 闭包访问和修改共享状态
    local ctx = {
        items = items,
        seen = seen,
        first_opened = { val = first_opened },
        remaining = { n = remaining },
        message = message,
        total_servers = total_servers,
        menu_type = menu_type,
        menu_title = menu_title,
        footnote = footnote,
        menu_cmd = menu_cmd,
        query = query,
        server_items = server_items,
        server_order = server_order,
        server_notes = server_notes,
        total_count = total_count,
        failed_servers = 0,
        rendered = false,
    }

    local handle_response = make_handle_response(ctx)

    local cancel_fn = parallel_requests(servers, build_args, handle_response, function()
        if ctx.render_final then pcall(ctx.render_final) end
    end, { concurrency = 5, per_request_timeout = 60 })
    active_request_cancel = cancel_fn
    active_request_type = menu_type
end

function get_episodes(animeTitle, bangumiId, api_server)
    local url = api_server .. "/api/v2/bangumi/" .. bangumiId
    local items = {}

    local message = "加载数据中..."
    local menu_type = "menu_episodes"
    local menu_title = "剧集信息"
    local footnote = "使用 / 打开筛选"

    -- 解析当前视频所属集数，用于菜单打开时自动定位
    local current_episode = nil
    local filename = mp.get_property("filename")
    if filename then
        current_episode = get_episode_number(filename)
    end
    if current_episode == nil then
        -- 本地文件名解析失败时（如协议流/纯标题），回退到标题解析
        local _, _, ep = parse_title()
        current_episode = tonumber(ep)
    end
    if current_episode ~= nil then
        current_episode = math.floor(current_episode)
    end

    if uosc_available then
        active_request_type = menu_type
        update_menu_uosc(menu_type, menu_title, message, footnote, nil, nil, "spinner",
            { "script-message-to", mp.get_script_name(), "cancel-active-request", menu_type })
    else
        show_message(message, 30)
    end

    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    request_cancelled = false
    active_request_type = menu_type
    active_request_cancel = call_cmd_async(args, function(err, stdout)
        active_request_cancel = nil
        if request_cancelled then
            return
        end

        table.insert(items, {
            title = "↩️ 返回搜索结果",
            value = { "script-message-to", mp.get_script_name(), "open-latest-menu-anime", latest_menu_anime },
            keep_open = false,
            selectable = true,
        })

        if err then
            local message = "获取数据失败"
            if uosc_available then
                table.insert(items, {
                    title = message,
                    value = "",
                    italic = true,
                    keep_open = true,
                    selectable = false,
                    align = "center",
                })
                update_menu_uosc(menu_type, menu_title, items, footnote)
            else
                show_message(message, 3)
            end
            msg.error("HTTP 请求失败：" .. tostring(err))
            return
        end

        local response = utils.parse_json(stdout)
        if not response or not response.bangumi or not response.bangumi.episodes then
            local message = "无结果"
            if uosc_available then
                table.insert(items, {
                    title = message,
                    value = "",
                    italic = true,
                    keep_open = true,
                    selectable = false,
                    align = "center",
                })
                update_menu_uosc(menu_type, menu_title, items, footnote)
            else
                show_message(message, 3)
            end
            msg.info(message)
            return
        end

        local episode_index = nil
        for _, episode in ipairs(response.bangumi.episodes) do
            table.insert(items, {
                title = episode.episodeTitle,
                hint = episode.episodeNumber,
                value = { "script-message-to", mp.get_script_name(), "load-danmaku",
                animeTitle, episode.episodeTitle, episode.episodeId, api_server },
                keep_open = false,
                selectable = true,
            })

            -- 标记标题推定集数：仅首个匹配项，定位索引 + hint 前缀
            if current_episode ~= nil and episode_index == nil then
                local ep_num = tonumber(episode.episodeNumber)
                    or tonumber(tostring(episode.episodeNumber):match("%d+"))
                if ep_num ~= nil and math.floor(ep_num) == current_episode then
                    items[#items].hint = "▶ " .. episode.episodeNumber
                    episode_index = #items
                end
            end
        end

        -- ====== 新增：更新 latest_menu_anime ======
        if latest_menu_anime and latest_menu_anime ~= "" then
            local menu_table = utils.parse_json(latest_menu_anime)
            if menu_table and type(menu_table.items) == "table" then
                for i, back_item in ipairs(menu_table.items) do
                    if type(back_item.value) == "table" and
                    back_item.value[5] == bangumiId and back_item.value[6] == api_server then
                        menu_table.items[i].footnote = mp.get_property("filename")
                        menu_table.items[i].items = { unpack(items, 2) }
                        break
                    end
                end
                latest_menu_anime = utils.format_json(menu_table)
            end
        end

        if uosc_available then
            footnote = mp.get_property("filename")
            update_menu_uosc(menu_type, menu_title, items, footnote,
                             nil, nil, nil, nil, episode_index)
        elseif input_loaded then
            show_message("", 0)
            input.terminate()
            mp.add_timeout(0.1, function()
                open_menu_select(items, nil, episode_index)
            end)
        end
    end)
    active_request_type = menu_type
end

function update_menu_uosc(menu_type, menu_title, menu_item, menu_footnote, menu_cmd,
                          query, message_icon, on_close, selected_index)
    local items = {}
    if type(menu_item) == "string" then
        table.insert(items, {
            title = menu_item,
            value = "",
            italic = true,
            keep_open = true,
            selectable = false,
            align = "center",
            icon = message_icon or "",
        })
    else
        items = menu_item
    end

    local menu_props = {
        type = menu_type,
        title = menu_title,
        search_style = menu_cmd and "palette" or "on_demand",
        search_debounce = menu_cmd and "submit" or 0,
        on_search = menu_cmd,
        footnote = menu_footnote,
        search_suggestion = query,
        items = items,
    }

    if on_close ~= nil then
        menu_props.on_close = on_close
    end
    
    if selected_index ~= nil then
        menu_props.selected_index = selected_index
    end

    local current_menu_type = mp.get_property_native('user-data/uosc/menu/type')
    local cmd = "open-menu"
    if not selected_index and current_menu_type and tostring(current_menu_type) == tostring(menu_type) then
        cmd = "update-menu"
    end

    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", cmd, json_props)

    return json_props
end

function open_menu_select(menu_items, is_time, default_item)
    local item_titles, item_values = {}, {}
    for i, v in ipairs(menu_items) do
        item_titles[i] = is_time and "[" .. v.hint .. "] " .. v.title or
            (v.hint and v.title .. " (" .. v.hint .. ")" or v.title)
        item_values[i] = v.value
    end
    mp.commandv('script-message-to', 'console', 'disable')
    input_open({
        prompt = is_time and '筛选:' or '选择:',
        items = item_titles,
        default_item = default_item,
        submit = function(id)
            input.terminate()
            perform_cancel_active_request()
            local v = item_values[id]
            if type(v) == 'table' then
                mp.commandv(unpack(v))
            elseif type(v) == 'string' then
                mp.command(v)
            end
        end,
        closed = function()
            show_message("", 0)
            input.terminate()
            perform_cancel_active_request()
        end,
    })
end

-- 打开弹幕输入搜索菜单
local function build_search_menu_props()
    -- 构建搜索菜单 props，供打开与删除后原地刷新复用
    local items = {}

    if DANMAKU.anime and DANMAKU.episode then
        local episode = DANMAKU.episode:gsub("%s.-$","")
        episode = episode:match("^(第.*[话回集]+)%s*") or episode
        items[#items + 1] = {
            title = string.format("已关联弹幕：%s-%s", DANMAKU.anime, episode),
            bold = true,
            italic = true,
            keep_open = true,
            selectable = false,
        }
    end

    items[#items + 1] = {
        hint = "  追加|ds或|dy或|dm可搜索电视剧|电影|国漫",
        keep_open = true,
        selectable = false,
    }

    -- 首个可选条目承载「回车即搜索识别到的名称」。uosc 打开菜单时会预选中第一个可选条目，
    -- 且回车优先激活选中项（elements/Menu.lua:1260）；若预选中的是历史条目，回车就会搜到
    -- 最新一条历史而不是输入框里的名称。输入框内容一旦变化，uosc 会自行清除选中项
    -- （elements/Menu.lua:1014-1017），因此手动改过内容后回车仍会提交改后的文本。
    local suggested_title = parse_title()
    if suggested_title and suggested_title ~= "" then
        items[#items + 1] = {
            title = "搜索：" .. suggested_title,
            value = suggested_title,
            keep_open = false,
            selectable = true,
        }
    end

    -- 追加搜索历史条目，点击直接重新搜索，条目操作提供单条删除
    for _, item in ipairs(get_search_history()) do
        items[#items + 1] = {
            title = item.keyword,
            hint = item.time > 0 and os.date("%Y/%m/%d %H:%M", item.time) or nil,
            icon = "history",
            value = item.keyword,
            actions = {{icon = "delete", name = "delete", label = "删除此记录"}},
            keep_open = false,
            selectable = true,
        }
    end

    return {
        type = "menu_danmaku",
        title = "在此处输入番剧名称",
        search_style = "palette",
        search_debounce = "submit",
        search_suggestion = parse_title(),
        on_search = { "script-message-to", mp.get_script_name(), "search-anime-event" },
        footnote = "使用enter或ctrl+enter进行搜索",
        items = items,
        -- 条目操作必须配 callback 才会派发：uosc 在未设置 callback 时忽略 event.action
        item_actions_place = "outside",
        callback = { mp.get_script_name(), 'setup-danmaku-search-history' },
    }
end

function open_input_menu_uosc()
    local json_props = utils.format_json(build_search_menu_props())
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end

function open_input_menu_get()
    mp.commandv('script-message-to', 'console', 'disable')
    local title = parse_title()
    local history_items = get_search_history()

    local function build_log(select_text)
        local log = {
            { text = "【弹幕搜索】", style = "{\\c&H00CCFF&\\b1}" },
            { text = "提示: 回车进行搜索", style = "{\\c&H999999&}" },
        }
        if #history_items > 0 then
            table.insert(log, { text = "【搜索历史】", style = "{\\c&H00CCFF&\\b1}" })
            for i, item in ipairs(history_items) do
                local text = string.format("  [%02d] %s", i, item.keyword)
                if item.time > 0 then
                    text = text .. string.format("  [%s]", os.date("%Y/%m/%d %H:%M", item.time))
                end
                local style = (tonumber(select_text) == i) and "{\\c&HFFDE7F&\\b1}" or "{\\c&HCCCCCC&}"
                table.insert(log, { text = text, style = style })
            end
            table.insert(log, { text = string.format("提示: 输入【1-%d】可快速重新搜索对应关键词", #history_items), style = "{\\c&H999999&}" })
        end
        input.set_log(log)
    end

    input_open({
        prompt = '番剧名称:',
        default_text = title,
        cursor_position = title and #title + 1,
        opened = function() build_log() end,
        edited = function(text)
            text = text:gsub("^%s*(.-)%s*$", "%1")
            build_log(text ~= "" and text or nil)
        end,
        submit = function(text)
            text = text:gsub("^%s*(.-)%s*$", "%1")

            -- 输入历史编号则替换为对应关键词重搜
            local num = tonumber(text)
            if num and history_items[num] then
                text = history_items[num].keyword
            end

            input.terminate()
            mp.commandv("script-message-to", mp.get_script_name(), "search-anime-event", text)
        end
    })
end

function open_input_menu()
    if uosc_available then
        open_input_menu_uosc()
    elseif input_loaded then
        mp.add_timeout(0.01, function()
            open_input_menu_get()
        end)
    end
end

-- 打开弹幕源添加管理菜单
function open_add_menu_get()
    local menu_log, deal_value = {}, {}

    -- 重建菜单内容函数
    local function rebuild_menu_log(select_num)
        deal_value = {}
        menu_log = {
            { text = "【既有弹幕源】", style = "{\\c&H00CCFF&\\b1}" },
            { text = "----------------------------", style = "{\\c&H888888&}" }
        }

        local serial = 0
        for url, source in pairs(DANMAKU.sources) do
            if source.data then
                if source.from == "api_server" then
                    serial = serial + 1
                    local action = source.blocked and "unblock" or "block"
                    local text = string.format("  [%02d] %s [来源：弹幕服务器%s]  ", serial, url,
                        source.blocked and "（已屏蔽）" or "（未屏蔽）")
                    local style = (tonumber(select_num) == serial) and "{\\c&HFFDE7F&\\b1}" or (action == "unblock" and "{\\c&H4C4CC3&\\b0}" or "{\\c&HCCCCCC&\\b0}")
                    deal_value[serial] = {value = url, action = action}
                    table.insert(menu_log, {text = text, style = style})
                else
                    serial = serial + 1
                    local action1 = source.blocked and "unblock" or "block"
                    local text1 = string.format("  [%02d] %s [来源：用户添加]%s  ", serial, url, source.blocked and " (已屏蔽)" or "（未屏蔽）")
                    local style1 = (tonumber(select_num) == serial) and "{\\c&HFFDE7F&\\b1}" or (action1 == "unblock" and "{\\c&H4C4CC3&\\b0}" or "{\\c&HCCCCCC&\\b0}")
                    deal_value[serial] = {value = url, action = action1}
                    table.insert(menu_log, {text = text1, style = style1})

                    serial = serial + 1
                    local action2 = "delete"
                    local text2 = string.format("  [%02d] %s [来源：用户添加] (删除)  ", serial, url)
                    local style2 = (tonumber(select_num) == serial) and "{\\c&HFFDE7F&\\b1}" or "{\\c&HCCCCCC&\\b0}"
                    deal_value[serial] = {value = url, action = action2}
                    table.insert(menu_log, {text = text2, style = style2})
                end
            end
        end

        if serial == 0 then
            table.insert(menu_log, { text = "        无", style = "" })
        end
    end

    -- 显示菜单
    local function show_menu(extra_lines, select_num)
        rebuild_menu_log(select_num)

        local display = {}
        for _, item in ipairs(menu_log) do table.insert(display, item) end
        table.insert(display, { text = "----------------------------", style = "{\\c&H888888&}" })

        if extra_lines then
            if #extra_lines < 2 then table.insert(display, { text = "\n", style = "" }) end
            for _, line in ipairs(extra_lines) do table.insert(display, line) end
        else
            table.insert(display, { text = "\n", style = "" })
            table.insert(display, {
                text = "提示: 输入【选项数字】可屏蔽或删除既有弹幕源",
                style = "{\\c&H999999&}"
            })
        end

        input.set_log(display)
    end

    -- 获取操作提示
    local function get_hint(action)
        local hints = {
            block = "按回车执行，屏蔽该弹幕源",
            unblock = "按回车执行，解除该弹幕源的屏蔽",
            delete = "按回车执行，删除该弹幕源"
        }
        return hints[action] or "按回车执行，获取输入源地址url的弹幕"
    end

    input_open({
        keep_open = true,
        prompt = "请在此输入源地址url: ",
        opened = function() show_menu() end,
        edited = function(text)
            text = text:gsub("^%s*(.-)%s*$", "%1")

            if text == "" then
                show_menu()
                return
            end

            local num = tonumber(text)
            local event = num and deal_value[num]
            local hint = get_hint(event and event.action)

            show_menu({
                { text = string.format("已输入: %s", text), style = "{\\c&HCCCCCC&}" },
                { text = hint, style = "{\\c&H999999&}" }
            }, text)
        end,
        submit = function(text)
            text = text:gsub("^%s*(.-)%s*$", "%1")
            if text == "" then return end

            local num = tonumber(text)
            local event = num and deal_value[num]

            if event then
                local args = string.format('{"type":"activate","value":"%s","action":"%s"}',
                    string.gsub(event.value, '\\', '\\\\'), event.action)
                mp.commandv("script-message-to", mp.get_script_name(), "setup-danmaku-source", args)
            else
                input.terminate()
                mp.commandv("script-message-to", mp.get_script_name(), "add-source-event", text)
            end

            mp.add_timeout(0.1, show_menu)
        end
    })
end

function open_add_menu_uosc()
    local sources = {}
    for url, source in pairs(DANMAKU.sources) do
        if source.data then
            local count = #source.data  -- 弹幕条数
            local count_text = string.format("（%d条）弹幕", count)
            local item = {title = utf8_sub(url, 1, 100), value = url, keep_open = true,}
            if source.from == "api_server" then
                if source.blocked then
                    item.hint = "来源：弹幕服务器（已屏蔽）"
                    item.actions = {{icon = "check", name = "unblock", label = "解除屏蔽" .. count_text},}
                else
                    item.hint = "来源：弹幕服务器（未屏蔽）"
                    item.actions = {{icon = "not_interested", name = "block", label = "屏蔽" .. count_text},}
                end
            else
                item.hint = "来源：用户添加"
                if source.blocked then
                    item.actions = {
                        {icon = "check", name = "unblock", label = "解除屏蔽" .. count_text},
                        {icon = "delete", name = "delete", label = "删除" .. count_text},
                    }
                else
                    item.actions = {
                        {icon = "not_interested", name = "block", label = "屏蔽" .. count_text},
                        {icon = "delete", name = "delete", label = "删除" .. count_text},
                    }
                end
            end
            table.insert(sources, item)
        end
    end
    local menu_props = {
        type = "menu_source",
        title = "在此输入源地址url",
        search_style = "palette",
        search_debounce = "submit",
        on_search = { "script-message-to", mp.get_script_name(), "add-source-event" },
        footnote = "使用enter或ctrl+enter进行添加",
        items = sources,
        item_actions_place = "outside",
        callback = {mp.get_script_name(), 'setup-danmaku-source'},
    }
    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end

function open_add_menu()
    if uosc_available then
        open_add_menu_uosc()
    elseif input_loaded then
        mp.add_timeout(0.01, function()
            open_add_menu_get()
        end)
    end
end

-- 打开弹幕内容菜单
function open_content_menu(pos)
    local items = {}
    local time_pos = pos or mp.get_property_native("time-pos")
    local duration = mp.get_property_number("duration", 0)

    if COMMENTS ~= nil then
        for _, event in ipairs(COMMENTS) do
            local text = event.clean_text:gsub("^m%s[mbl%s%-%d%.]+$", ""):gsub("^%s*(.-)%s*$", "%1")
            local delay = event.delay
            local start_time = event.start_time
            local end_time = event.end_time
            if text and text ~= "" and start_time >= 0 and start_time <= duration then
                local delay_label_suffix = nil
                local delay_num = delay and tonumber(delay)
                if delay_num and math.abs(delay_num) > 0 then
                    delay_label_suffix = string.format("已存在延迟: %+0.1fs", delay_num)
                end

                local adjust_label = '调整弹幕延迟'
                if delay_label_suffix then
                    adjust_label = adjust_label .. '（' .. delay_label_suffix .. '）'
                end

                table.insert(items, {
                    title = abbr_str(text, 60) .. (event.count_suffix or ""),
                    hint = seconds_to_time(start_time) .. "  (" .. utf8_sub(remove_query(event.source), 1, 70) .. ")",
                    actions = {
                        {
                            name = 'block_source',
                            icon = 'block',
                            label = '屏蔽对应弹幕源'
                        },
                        {
                            name = 'adjust_delay',
                            icon = 'more_time',
                            label = adjust_label,
                        },
                    },
                    value = { "seek", start_time, "absolute" },
                    active = time_pos >= start_time and time_pos <= end_time,
                })
            end
        end
    end

    local menu_props = {
        type = "menu_content",
        title = "弹幕内容",
        footnote = "使用 / 打开搜索",
        items = items,
        item_actions_place = "outside",
        callback = {mp.get_script_name(), 'handle-danmaku-content-action'},
    }
    local json_props = utils.format_json(menu_props)

    if uosc_available then
        mp.commandv("script-message-to", "uosc", "open-menu", json_props)
    elseif input_loaded then
        open_menu_select(items, true)
    end
end

local menu_items_config = {
    bold = { title = "粗体", hint = options.bold, original = options.bold,
        footnote = "true / false", },
    fontsize = { title = "大小", hint = options.fontsize, original = options.fontsize,
        scope = { min = 0, max = math.huge }, footnote = "请输入整数(>=0)", },
    outline = { title = "描边", hint = options.outline, original = options.outline,
        scope = { min = 0.0, max = 4.0 }, footnote = "输入范围：(0.0-4.0)" },
    shadow = { title = "阴影", hint = options.shadow, original = options.shadow,
        scope = { min = 0, max = math.huge }, footnote = "请输入整数(>=0)", },
    scrolltime = { title = "速度", hint = options.scrolltime, original = options.scrolltime,
        scope = { min = 1, max = math.huge }, footnote = "请输入整数(>=1)", },
    opacity = { title = "透明度", hint = options.opacity, original = options.opacity,
        scope = { min = 0, max = 1 }, footnote = "输入范围：0（完全透明）到1（不透明）", },
    displayarea = { title = "弹幕显示范围", hint = options.displayarea, original = options.displayarea,
        scope = { min = 0.0, max = 1.0 }, footnote = "显示范围(0.0-1.0)", },
}
-- 创建一个包含键顺序的表，这是样式菜单的排布顺序
local ordered_keys = {"bold", "fontsize", "outline", "shadow", "scrolltime", "opacity", "displayarea"}

-- 打开弹幕样式设置菜单
function open_style_menu_get(query, indicator)
    mp.commandv('script-message-to', 'console', 'disable')
    local menu_log = {}

    local select_num = 0
    local select_query = nil
    if query then
        if tonumber(query) ~= nil then
            select_num = tonumber(query)
        else
            for i, v in ipairs(ordered_keys) do
                if v == query then
                    select_num = i
                end
            end
        end
        select_query = ordered_keys[select_num]
    end

    local function build_menu(source)
        menu_log = {
            { text = "【弹幕样式菜单】", style = "{\\c&H00CCFF&\\b1}" },
            { text = ("-"):rep(33), style = "{\\c&H888888&}" }
        }

        local serial = 0
        for _, key in ipairs(ordered_keys) do
            serial = serial + 1
            local config = menu_items_config[key]
            local text = string.format("  [%02d] %s   [目前：%s] ", serial, config.title, config.hint)
            text = config.hint ~= config.original and text .. "⟳" or text
            local style = serial == select_num and "{\\c&HFFDE7F&}" or "{\\c&HCCCCCC&}"
            local item_config = { text = text, style = style }
            table.insert(menu_log, item_config)
        end
        table.insert(menu_log, { text = " [B] 黑名单编辑 ", style = "{\\c&HCCCCCC&}" })

        table.insert(menu_log, { text = ("-"):rep(33), style = "{\\c&H888888&}" })
        if select_num == 0 then
            table.insert(menu_log, {
                text = "注: 样式更改仅在本次播放生效",
                style = "{\\c&HFFDE7F&}"
            })
            table.insert(menu_log, {
                text = "提示: 输入【w】可上移选项，【s】可下移选项",
                style = "{\\c&H999999&}"
            })
        else
            local input_text = source and source or ""
            local config = menu_items_config[select_query]
            local suffix = ""
            if config and config.hint ~= config.original then
                suffix = "（输入\\r恢复默认配置）"
            end
            input_text = string.format("已输入%s: %s", suffix, input_text)

            local scope = config and config.footnote or ""
            local hint_text = select_query == "bold" and "提示: 输入【y】切换状态" or "提示: " .. scope
            local hint_style = "{\\c&H999999&}"
            if source and source:lower() == "\\r" then
                hint_text = string.format("提示: 回车将恢复默认配置 < %s >", config.original)
            end
            if indicator == "refresh" or indicator == "updata" then
                indicator = ""
                hint_text = "提示: 样式更改成功"
                hint_style = "{\\c&HFFDE7F&}"
                mp.add_timeout(1.5, build_menu)
            elseif indicator == "error" then
                indicator = ""
                hint_text = "提示: 输入非数字字符或范围出错"
                hint_style = "{\\c&H4C4CC3&}"
                mp.add_timeout(1.5, build_menu)
            end

            table.insert(menu_log, { text = input_text, style = "{\\c&HCCCCCC&}" })
            table.insert(menu_log, { text = hint_text, style = hint_style })
        end
        input.set_log(menu_log)
    end

    input_open({
        keep_open = true,
        prompt = "请在此输入操作（w/s|上移/下移，b|屏蔽词编辑）: ",
        opened = function() build_menu() end,
        edited = function(text)
            text = text:gsub("^%s*(.-)%s*$", "%1")

            if text == "" then
                build_menu()
                return
            end

            if text:lower() == "b" then
                input.terminate()
                mp.commandv("script-message-to", mp.get_script_name(), "open_blacklist_menu")
                return
            end

            if text:lower() == "w" or text:lower() == "s" then
                input.terminate()
                select_num = text:lower() == "w" and select_num - 1 or select_num + 1
                select_num = (select_num > #ordered_keys) and 1 or (select_num <= 0 and #ordered_keys or select_num)
                mp.add_timeout(0.01, function()
                    open_style_menu_get(select_num)
                end)
                return
            end

            build_menu(text)
        end,
        submit = function(text)
            if select_query == nil then return end
            text = text:gsub("^%s*(.-)%s*$", "%1")
            if text == "" then return end

            if text:lower() == "\\r" then
                input.terminate()
                local args = string.format('{"type":"activate","action":"%s","index":%d}', select_query, select_num)
                mp.commandv("script-message-to", mp.get_script_name(), "setup-danmaku-style", args)
            else
                if menu_items_config[select_query]["scope"] ~= nil then
                    input.terminate()
                    mp.commandv("script-message-to", mp.get_script_name(), "setup-danmaku-style", select_query, text)
                elseif text:lower() == "y" and select_query == "bold" then
                    input.terminate()
                    local args = string.format('{"type":"activate","index":%d}', select_num)
                    mp.commandv("script-message-to", mp.get_script_name(), "setup-danmaku-style", args)
                end
            end
            return
        end
    })
end

function open_style_menu_uosc(actived, status)
    local items = {}
    for _, key in ipairs(ordered_keys) do
        local config = menu_items_config[key]
        local item_config = {
            title = config.title,
            hint = "目前：" .. tostring(config.hint),
            active = key == actived,
            keep_open = true,
            selectable = true,
        }
        if config.hint ~= config.original then
            local original_str = tostring(config.original)
            item_config.actions = {{icon = "refresh", name = key, label = "恢复默认配置 < " .. original_str .. " >"}}
        end
        table.insert(items, item_config)
    end
    table.insert(items, {
        title = "弹幕屏蔽",
        hint = "屏蔽词过滤规则",
        keep_open = false,
        selectable = true,
        value = { "script-message-to", mp.get_script_name(), "open_blacklist_menu" },
    })

    local menu_props = {
        type = "menu_style",
        title = "弹幕样式",
        search_style = "disabled",
        footnote = "样式更改仅在本次播放生效",
        item_actions_place = "outside",
        items = items,
        callback = { mp.get_script_name(), 'setup-danmaku-style'},
    }

    local actions = "open-menu"
    if status ~= nil then
        -- msg.info(status)
        if status == "updata" then
            -- "updata" 模式会保留输入框文字
            menu_props.title = "  " .. menu_items_config[actived]["footnote"]
            actions = "update-menu"
        elseif status == "refresh" then
            -- "refresh" 模式会清除输入框文字
            menu_props.title = "  " .. menu_items_config[actived]["footnote"]
        elseif status == "error" then
            menu_props.title = "输入非数字字符或范围出错"
            -- 创建一个定时器，在1秒后触发回调函数，删除搜索栏错误信息
            mp.add_timeout(1.0, function() open_style_menu_uosc(actived, "updata") end)
        end
        menu_props.search_style = "palette"
        menu_props.search_debounce = "submit"
        menu_props.footnote = menu_items_config[actived]["footnote"] or ""
        menu_props.on_search = { "script-message-to", mp.get_script_name(), "setup-danmaku-style", actived }
    end

    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", actions, json_props)
end

function open_style_menu(actived, status)
    if uosc_available then
        open_style_menu_uosc(actived, status)
    elseif input_loaded then
        mp.add_timeout(0.01, function()
            open_style_menu_get(actived, status)
        end)
    else
        show_message("无支持可用的 UI框架，不支持使用该功能", 3)
    end
end

-- 打开以指定时间为起点的延迟菜单
function open_delay_from_time_get(source, time, status)
    mp.commandv('script-message-to', 'console', 'disable')
    local menu_log = {}

    local function build_menu(query, input_text)
        menu_log = {
            { text = "【从该时间起调整弹幕延迟】", style = "{\\c&H00CCFF&\\b1}" },
            { text = ("-"):rep(33), style = "{\\c&H888888&}" }
        }

        table.insert(menu_log, { text = "\n", style = "" })
        local hint_text = "提示：请输入数字，单位（秒）/ 或者按照形如\"14m15s\"的格式输入分钟数加秒数"
        local hint_style = "{\\c&H999999&}"
        if status == "error" then
            hint_text = "提示: 输入非数字字符或范围出错"
            hint_style = "{\\c&H4C4CC3&}"
        end

        table.insert(menu_log, { text = input_text and ("已输入：" .. input_text) or "", style = "{\\c&HCCCCCC&}" })
        table.insert(menu_log, { text = hint_text, style = hint_style })
        input.set_log(menu_log)
    end

    input_open({
        keep_open = true,
        prompt = "请输入要设置的延迟（秒或 XmYs）: ",
        opened = function() build_menu() end,
        edited = function(text)
            text = text:gsub("^%s*(.-)%s*$", "%1")
            if text == "" then
                build_menu()
                return
            end
            build_menu(text)
        end,
        submit = function(text)
            text = text and text:gsub("^%s*(.-)%s*$", "%1") or ""
            if text == "" then return end
            input.terminate()
            local parsed = parse_delay_input(text)
            if parsed ~= nil then
                mp.commandv("script-message", "danmaku-delay", tostring(parsed), tostring(time), tostring(source))
            else
                open_delay_from_time(time, "error")
            end
        end
    })
end

function open_delay_from_time_uosc(source, time, status)
    if not uosc_available then
        show_message("无uosc UI框架，不支持使用该功能", 2)
        return
    end

    local menu_props = {
        type = "menu_delay_from_time",
        title = "从该时间起调整弹幕延迟",
        search_style = "palette",
        search_debounce = "submit",
        footnote = "请输入数字，单位（秒）/ 或者按照形如\"14m15s\"的格式输入分钟数加秒数",
        items = {},
        on_search = { "script-message-to", mp.get_script_name(), "setup-content-delay", tostring(time), tostring(source) },
    }

    if status == "error" then
    menu_props.title = "输入非数字字符或范围出错"
    mp.add_timeout(1.0, function() open_delay_from_time_uosc(source, time) end)
    end

    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end

function open_delay_from_time(source, time, status)
    if uosc_available then
        open_delay_from_time_uosc(source, time, status)
    elseif input_loaded then
        mp.add_timeout(0.01, function()
            open_delay_from_time_get(source, time, status)
        end)
    else
        show_message("无支持可用的 UI框架，不支持使用该功能", 3)
    end
end

-- 打开弹幕源延迟设置菜单
function open_delay_menu_get(source, status)
    mp.commandv('script-message-to', 'console', 'disable')
    local menu_log = {}

    local serial = 0
    local select_num = 0
    if source and tonumber(source) ~= nil then
        select_num = tonumber(source)
    end
    local select_url = nil

    local function build_menu(query, text)
        menu_log = {
            { text = "【弹幕源延迟菜单】", style = "{\\c&H00CCFF&\\b1}" },
            { text = ("-"):rep(33), style = "{\\c&H888888&}" }
        }

        serial, select_num = 0, 0
        for url, src in pairs(DANMAKU.sources) do
            if src.data and not src.blocked then
                local delay = 0
                serial = serial + 1
                select_num = (serial == tonumber(source)) and serial or select_num
                if src.delay_segments then
                    for _, seg in ipairs(src.delay_segments) do
                        if seg.start == 0 then
                            delay = seg.delay or 0
                            break
                        end
                    end
                end
                local hint = "当前弹幕源延迟: " .. string.format("%.1f", delay + 1e-10) .. "秒"
                local text = string.format("  [%02d] %s   [%s] ", serial, url, hint)
                local style = (serial == select_num) and "{\\c&HFFDE7F&}" or "{\\c&HCCCCCC&}"
                table.insert(menu_log, { text = text, style = style })
                select_url = serial == select_num and url or select_url
            end
        end
        if serial == 0 then
            table.insert(menu_log, { text = "        无", style = "" })
        end

        table.insert(menu_log, { text = ("-"):rep(33), style = "{\\c&H888888&}" })
        if select_num == 0 then
            table.insert(menu_log, { text = "\n", style = "" })
            table.insert(menu_log, {
                text = "提示: 输入【w】可上移选项，【s】可下移选项",
                style = "{\\c&H999999&}"
            })
        else
            local input_text = "已输入：" .. (text ~= nil and text or "")

            local hint_text = "提示：请输入数字，单位（秒）/ 或者按照形如\"14m15s\"的格式输入分钟数加秒数"
            local hint_style = "{\\c&H999999&}"
            if status == "refresh" then
                status = ""
                hint_text = "提示: 样式更改成功"
                hint_style = "{\\c&HFFDE7F&}"
                mp.add_timeout(1.5, build_menu)
            elseif status == "error" then
                status = ""
                hint_text = "提示: 输入非数字字符或范围出错"
                hint_style = "{\\c&H4C4CC3&}"
                mp.add_timeout(1.5, build_menu)
            end

--            table.insert(menu_log, { text = input_text, style = "{\\c&HCCCCCC&}" })
            table.insert(menu_log, { text = input_text, style = "{\\c&HCCCCCC&}" })
            table.insert(menu_log, { text = hint_text, style = hint_style })
        end
        input.set_log(menu_log)
    end

    input_open({
        keep_open = true,
        prompt = "请在此输入操作（w/s|上移/下移）: ",
        opened = function() build_menu() end,
        edited = function(text)
            text = text:gsub("^%s*(.-)%s*$", "%1")

            if text == "" then
                build_menu()
                return
            end

            if text:lower() == "w" or text:lower() == "s" then
                input.terminate()
                select_num = text:lower() == "w" and select_num - 1 or select_num + 1
                select_num = (select_num > serial) and 1 or (select_num <= 0 and serial or select_num)
                mp.add_timeout(0.01, function()
                    open_delay_menu_get(select_num)
                end)
                return
            end

            build_menu(select_num, text)
        end,
        submit = function(text)
            if select_url == nil then return end
            text = text:gsub("^%s*(.-)%s*$", "%1")
            if text == "" then return end

            input.terminate()
            mp.commandv("script-message-to", mp.get_script_name(), "setup-source-delay", select_url, text)
            return
        end
    })
end

function open_delay_menu_uosc(source_url, status)
    if not uosc_available then
        show_message("无uosc UI框架，不支持使用该功能", 2)
        return
    end

    local sources = {}
    for url, source in pairs(DANMAKU.sources) do
        if source.data and not source.blocked then
            local delay = 0
            if source.delay_segments then
                for _, seg in ipairs(source.delay_segments) do
                    if seg.start == 0 then
                        delay = seg.delay or 0
                        break
                    end
                end
            end
            local item = {title = utf8_sub(url, 1, 100), value = url, keep_open = true,}
            item.hint = "当前弹幕源延迟:" .. string.format("%.1f", delay + 1e-10) .. "秒"
            item.active = url == source_url
            table.insert(sources, item)
        end
    end

    local menu_props = {
        type = "menu_delay",
        title = "弹幕源延迟设置",
        search_style = "disabled",
        items = sources,
        callback = {mp.get_script_name(), 'setup-source-delay'},
    }
    if source_url ~= nil then
        if status == "error" then
            menu_props.title = "输入非数字字符或范围出错"
            -- 创建一个定时器，在1秒后触发回调函数，删除搜索栏错误信息
            mp.add_timeout(1.0, function() open_delay_menu_uosc(source_url) end)
        else
            menu_props.title = "请输入数字，单位（秒）/ 或者按照形如\"14m15s\"的格式输入分钟数加秒数"
        end
        menu_props.search_style = "palette"
        menu_props.search_debounce = "submit"
        menu_props.on_search = { "script-message-to", mp.get_script_name(), "setup-source-delay", source_url }
    end

    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end

function open_delay_menu(source, status)
    if uosc_available then
        open_delay_menu_uosc(source, status)
    elseif input_loaded then
        mp.add_timeout(0.01, function()
            open_delay_menu_get(source, status)
        end)
    else
        show_message("无支持可用的 UI框架，不支持使用该功能", 3)
    end
end

-- 打开弹幕屏蔽规则设置菜单
function open_blacklist_menu_uosc(action, index)
    -- ---------- 编辑菜单：搜索框预填原文，回车提交，Esc 取消 ----------
    if action == "edit" then
        local entry = blacklist_get_state().entries[index]
        if not entry then return end
        mp.commandv("script-message-to", "uosc", "open-menu", utils.format_json({
            type = "menu_blacklist_edit",
            title = "修改规则（原样写入）",
            search_style = "palette", search_debounce = "submit",
            search_suggestion = entry.pattern,
            footnote = "在输入框中修改规则后回车提交；Esc 取消",
            items = {
                { title = "↩️ 返回黑名单（不修改）", selectable = true,
                  value = { "script-message-to", mp.get_script_name(), "open_blacklist_menu" } },
            },
            on_search = { "script-message-to", mp.get_script_name(),
                          "blacklist-deal", "edit-submit", tostring(index) },
        }))
        return
    end
    -- ------------- 主菜单 -------------
    local state = blacklist_get_state()
    local items = {}
    if not state.ext then
        items[#items + 1] = {
            title = "blacklist_path 的扩展名不受支持",
            hint = "请配置为 .txt / .xml / .json 文件",
            selectable = false, muted = true, keep_open = true,
        }
    elseif not state.exists then
        items[#items + 1] = {
            title = "新建弹幕屏蔽词文件（." .. state.ext .. "）",
            hint = abbr_str(state.path or "", 60), selectable = true,
            value = { "script-message-to", mp.get_script_name(), "blacklist-deal", "create" },
        }
    elseif state.parse_failed then
        items[#items + 1] = {
            title = "文件解析失败，可能不是标准 " .. state.ext:upper() .. " 格式",
            hint = "为避免覆盖原内容，请手动选择重置",
            selectable = false, muted = true, keep_open = true,
        }
        items[#items + 1] = {
            title = "重置为标准格式（覆盖原文件）",
            hint = "原内容将丢失，请谨慎操作", selectable = true,
            value = { "script-message-to", mp.get_script_name(), "blacklist-deal", "reset" },
        }
    else
        for i, entry in ipairs(state.entries) do
            local hint = state.ext == "txt" and ("#" .. i)
                or ((entry.enabled and "已启用" or "已停用") .. " · #" .. i)
            local actions
            if state.ext == "txt" then
                actions = { { name = "delete", icon = "delete", label = "删除此规则" } }
            else
                actions = {
                    { name = "edit",   icon = "edit", label = "修改此规则" },
                    { name = "toggle", icon = entry.enabled and "toggle_on" or "toggle_off",
                      label = entry.enabled and "停用此规则" or "启用此规则" },
                    { name = "delete", icon = "delete", label = "删除此规则" },
                }
            end
            items[#items + 1] = {
                title = abbr_str(entry.pattern, 60), hint = hint,
                muted = state.ext ~= "txt" and not entry.enabled or nil,
                actions = actions, keep_open = true,
            }
        end
        if #state.entries == 0 then
            items[#items + 1] = {
                title = "暂无屏蔽词", hint = "在输入框输入后回车添加",
                selectable = false, muted = true, italic = true, keep_open = true,
            }
        end
    end
    -- 格式提示（内联）
    local hint
    if state.ext == "txt" then
        hint = "txt：每行一条，支持 lua 正则"
    elseif state.ext == "xml" then
        hint = 'xml：<item enabled="true">t=词</item>'
    else
        hint = 'json：[{"type":0,"filter":"词","opened":true,"id":1}]'
    end
    local footnote = state.exists and not state.parse_failed
        and ("输入屏蔽词回车添加；用条目按钮修改 / 启停 / 删除 ｜ " .. hint)
        or (not state.exists and "点击“新建”创建文件；或直接输入后回车（自动创建）" or hint)
    mp.commandv("script-message-to", "uosc", "open-menu", utils.format_json({
        type = "menu_blacklist", title = "请在此输入需添加的弹幕规则",
        search_style = "palette", search_debounce = "submit",
        on_search = { "script-message-to", mp.get_script_name(), "blacklist-deal", "add" },
        footnote = footnote, items = items,
        item_actions_place = "outside",
        callback = { mp.get_script_name(), "blacklist-deal" },
    }))
end

function open_blacklist_menu_select()
    local state = blacklist_get_state()
    local titles, values = {}, {}
    local function push(t, v) titles[#titles + 1] = t; values[#values + 1] = v end
    if not state.ext then
        push("blacklist_path 的扩展名不受支持（需 .txt/.xml/.json）", nil)
    elseif not state.exists then
        push("新建黑名单文件（." .. state.ext .. "）", "create")
    elseif state.parse_failed then
        push("文件解析失败，可能不是标准 " .. state.ext:upper() .. " 格式", nil)
        push("重置为标准格式（覆盖原文件）", "reset")
    else
        push("＋ 添加屏蔽词", "add")
        for i, entry in ipairs(state.entries) do
            local status = state.ext ~= "txt" and (entry.enabled and "[启用] " or "[停用] ") or ""
            push(status .. abbr_str(entry.pattern, 50), { kind = "entry", index = i })
        end
        if #state.entries > 0 then push("－ 删除条目...", "delete_mode") end
    end
    push("↩️ 返回", "close")
    mp.commandv("script-message-to", "console", "disable")
    input.select({
        prompt = "黑名单编辑:",
        items = titles,
        submit = function(id)
            input.terminate()
            local action = values[id]
            if action == "create" or action == "reset" then
                local ok, message = blacklist_create_file()
                if message then show_message("[弹幕屏蔽规则] " .. message, ok and 2 or 3) end
                if ok then mp.add_timeout(0.05, open_blacklist_menu) end
            elseif action == "add" then
                mp.commandv("script-message-to", "console", "disable")
                input_open({
                    prompt = "输入屏蔽词（回车添加）:",
                    submit = function(text)
                        input.terminate()
                        local ok, message = blacklist_add_entry(text)
                        if message then show_message("[弹幕屏蔽规则] " .. message, ok and 2 or 3) end
                        if ok then mp.add_timeout(0.05, open_blacklist_menu) end
                    end,
                })
            elseif action == "delete_mode" then
                local d_titles, d_values = {}, {}
                for i, entry in ipairs(state.entries) do
                    d_titles[#d_titles + 1] = abbr_str(entry.pattern, 50)
                    d_values[#d_values + 1] = i
                end
                input.select({
                    prompt = "选择要删除的条目（立即生效）:",
                    items = d_titles,
                    submit = function(d_id)
                        input.terminate()
                        local i = d_values[d_id]
                        if i then
                            local ok, message = blacklist_delete_entry(i)
                            if message then show_message("[弹幕屏蔽规则] " .. message, ok and 2 or 3) end
                            if ok then mp.add_timeout(0.05, open_blacklist_menu) end
                        end
                    end,
                })
            elseif type(action) == "table" and action.kind == "entry" then
                local index = action.index
                local entry = state.entries[index]
                if not entry then return end
                local a_titles, a_values = {}, {}
                local function apush(t, v) a_titles[#a_titles + 1] = t; a_values[#a_values + 1] = v end
                if state.ext ~= "txt" then
                    apush("修改此规则", "edit")
                    apush(entry.enabled and "停用此规则" or "启用此规则", "toggle")
                end
                apush("删除此规则", "delete")
                apush("↩️ 返回", "back")
                input.select({
                    prompt = abbr_str(entry.pattern, 40),
                    items = a_titles,
                    submit = function(a_id)
                        input.terminate()
                        local op = a_values[a_id]
                        if op == "edit" then
                            mp.commandv("script-message-to", "console", "disable")
                            input_open({
                                prompt = "修改规则（原样写入）:",
                                default_text = entry.pattern,
                                submit = function(text)
                                    input.terminate()
                                    local ok, message = blacklist_edit_entry(index, text)
                                    if message then show_message("[弹幕屏蔽规则] " .. message, ok and 2 or 3) end
                                    if ok then mp.add_timeout(0.05, open_blacklist_menu) end
                                end,
                            })
                        else
                            local ok, message
                            if op == "toggle" then
                                ok, message = blacklist_toggle_entry(index)
                            elseif op == "delete" then
                                ok, message = blacklist_delete_entry(index)
                            elseif op == "back" then
                                mp.add_timeout(0.05, open_blacklist_menu)
                                return
                            end
                            if message then show_message("[弹幕屏蔽规则] " .. message, ok and 2 or 3) end
                            if ok then mp.add_timeout(0.05, open_blacklist_menu) end
                        end
                    end,
                })
            end
        end,
    })
end

function open_blacklist_menu()
    if not get_blacklist_path() then
        show_message("未配置 blacklist_path，黑名单编辑不可用", 3)
        return
    end
    blacklist_get_state(true)   -- 强制从磁盘重建，保证与文件一致
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_blacklist")
        open_blacklist_menu_uosc()
    elseif input_loaded then
        open_blacklist_menu_select()
    else
        show_message("无支持可用的 UI框架，不支持使用该功能", 3)
    end
end

-- 总集合弹幕菜单
local total_menu_items_config = {
    { title = "弹幕搜索", action = "open_search_danmaku_menu" },
    { title = "从源添加弹幕", action = "open_add_source_menu" },
    { title = "弹幕源延迟设置", action = "open_source_delay_menu" },
    { title = "弹幕样式", action = "open_danmaku_style_menu" },
    { title = "弹幕内容", action = "open_content_danmaku_menu" },
}

function open_add_total_menu_uosc()
    local items = {}

    if DANMAKU.anime and DANMAKU.episode then
        local episode = DANMAKU.episode:gsub("%s.-$","")
        episode = episode:match("^(第.*[话回集]+)%s*") or episode
        items[#items + 1] = {
            title = string.format("已关联弹幕：%s-%s", DANMAKU.anime, episode),
            bold = true,
            italic = true,
            keep_open = true,
            selectable = false,
        }
    end

    for _, config in ipairs(total_menu_items_config) do
        table.insert(items, {
            title = config.title,
            value = { "script-message-to", mp.get_script_name(), config.action },
            keep_open = false,
            selectable = true,
        })
    end

    local menu_props = {
        type = "menu_total",
        title = "弹幕设置",
        search_style = "disabled",
        items = items,
    }
    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end

function open_add_total_menu_select()
    local item_titles, item_values = {}, {}
    for i, config in ipairs(total_menu_items_config) do
        item_titles[i] = config.title
        item_values[i] = { "script-message-to", mp.get_script_name(), config.action }
    end

    mp.commandv('script-message-to', 'console', 'disable')
    input_open({
        prompt = '选择:',
        items = item_titles,
        submit = function(id)
            local cmd = item_values[id]
            mp.add_timeout(0.1, function()
                mp.commandv(unpack(cmd))
            end)
        end,
    })
end

function open_add_total_menu()
    if uosc_available then
        open_add_total_menu_uosc()
    elseif input_loaded then
        open_add_total_menu_select()
    end
end

function toggle_danmaku_switch(value)
    mp.commandv("script-message-to", "uosc", "set", "show_danmaku", value)
    mp.set_property_bool(DANMAKU_SWITCH_ON, value == "on")
end

mp.commandv(
    "script-message-to",
    "uosc",
    "set-button",
    "danmaku",
    utils.format_json({
        icon = "search",
        tooltip = "弹幕搜索",
        command = "script-message open_search_danmaku_menu",
    })
)

mp.commandv(
    "script-message-to",
    "uosc",
    "set-button",
    "danmaku_source",
    utils.format_json({
        icon = "add_box",
        tooltip = "从源添加弹幕",
        command = "script-message open_add_source_menu",
    })
)

mp.commandv(
    "script-message-to",
    "uosc",
    "set-button",
    "danmaku_styles",
    utils.format_json({
        icon = "palette",
        tooltip = "弹幕样式",
        command = "script-message open_danmaku_style_menu",
    })
)

mp.commandv(
    "script-message-to",
    "uosc",
    "set-button",
    "danmaku_delay",
    utils.format_json({
        icon = "more_time",
        tooltip = "弹幕源延迟设置",
        command = "script-message open_source_delay_menu",
    })
)

mp.commandv(
    "script-message-to",
    "uosc",
    "set-button",
    "danmaku_menu",
    utils.format_json({
        icon = "grid_view",
        tooltip = "弹幕设置",
        command = "script-message open_add_total_menu",
    })
)


mp.register_script_message('uosc-version', function()
    uosc_available = true
end)

mp.commandv("script-message-to", "uosc", "set", "show_danmaku", "off")
mp.register_script_message("set", function(prop, value)
    if prop ~= "show_danmaku" then
        return
    end

    if value == "on" then
        ENABLED = true
        if COMMENTS == nil then
            set_danmaku_visibility(true)
            local path = mp.get_property("path")
            init(path)
        else
            show_loaded()
            show_danmaku_func()
        end
    else
        show_message("关闭弹幕", 2)
        ENABLED = false
        hide_danmaku_func()
    end

    toggle_danmaku_switch(value)
end)

-- 注册函数给 uosc 按钮使用
mp.register_script_message("search-anime-event", function(query)
    record_search_history(query)
    perform_cancel_active_request()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_danmaku")
    end
    local name, class = query:match("^(.-)%s*|%s*(.-)%s*$")
    if name and class then
        query_extra(name, class)
        return
    end
    local filter_note = nil
    local search_name = query
    local at_pos = query:find("@[^@]*$")
    if at_pos then
        search_name = query:sub(1, at_pos-1):gsub("%s+$", "")
        filter_note = query:sub(at_pos+1):gsub("^%s*(.-)%s*$", "%1")
        if filter_note == "" then filter_note = nil end
    end
    get_animes(search_name, filter_note)
end)

mp.register_script_message("search-episodes-event", function(animeTitle, bangumiId, api_server)
    perform_cancel_active_request()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_anime")
    end

    get_episodes(animeTitle, bangumiId, api_server)
end)

mp.register_script_message("load-danmaku", function(animeTitle, episodeTitle, episodeId, api_server)
    ENABLED = true
    DANMAKU.anime = animeTitle
    DANMAKU.episode = episodeTitle
    set_episode_id(episodeId, true, api_server)
end)

mp.register_script_message("add-source-event", function(query)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
    end
    ENABLED = true
    add_danmaku_source(query, true)
end)

mp.register_script_message("open_danmaku_style_menu", function()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_total")
    end
    open_style_menu()
end)

mp.register_script_message("open_content_danmaku_menu", function()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_total")
    end
    open_content_menu()
end)

mp.register_script_message("open-latest-menu-anime", function ()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "open-menu", latest_menu_anime)
    elseif input_loaded then
        show_message("", 0)
        mp.add_timeout(0.1, function()
            open_menu_select(utils.parse_json(latest_menu_anime))
        end)
    end
end)

mp.register_script_message('cancel-active-request', function(menu_type)
    perform_cancel_active_request(menu_type)
end)

mp.register_script_message("setup-danmaku-style", function(query, text)
    local event = utils.parse_json(query)
    if event ~= nil then
        -- item点击 或 图标点击
        if event.type == "activate" then
            -- 非样式条目（黑名单编辑等）：关闭样式菜单并执行其 value
            if event.value then
                mp.commandv("script-message-to", "uosc", "close-menu", "menu_style")
                if type(event.value) == "table" then
                    mp.commandv(unpack(event.value))
                else
                    mp.command(event.value)
                end
                return
            end
            -- 正常执行动作
            if not event.action then
                if ordered_keys[event.index] == "bold" then
                    options.bold = not options.bold
                    menu_items_config.bold.hint = options.bold and "true" or "false"
                end
                -- "updata" 模式会保留输入框文字
                open_style_menu(ordered_keys[event.index], "updata")
                return
            else
                -- msg.info("event.action：" .. event.action)
                options[event.action] = menu_items_config[event.action]["original"]
                menu_items_config[event.action]["hint"] = options[event.action]
                open_style_menu(event.action, "updata")
                if event.action == "fontsize" or event.action == "scrolltime" then
                    load_danmaku(true)
                end
            end
        end
    else
        -- 数值输入
        if text == nil or text == "" then
            return
        end
        local newText, _ = text:gsub("%s", "") -- 移除所有空白字符
        if tonumber(newText) ~= nil and menu_items_config[query]["scope"] ~= nil then
            local num = tonumber(newText)
            local min_num = menu_items_config[query]["scope"]["min"]
            local max_num = menu_items_config[query]["scope"]["max"]
            if num and min_num <= num and num <= max_num then
                if string.match(menu_items_config[query]["footnote"], "整数") then
                    -- 输入范围为整数时向下取整
                    num = tostring(math.floor(num))
                end
                options[query] = tostring(num)
                menu_items_config[query]["hint"] = options[query]
                -- "refresh" 模式会清除输入框文字
                open_style_menu(query, "refresh")
                if query == "fontsize" or query == "scrolltime" then
                    load_danmaku(true, true)
                end
                return
            end
        end
        open_style_menu(query, "error")
    end
end)

mp.register_script_message('setup-danmaku-source', function(json)
    local event = utils.parse_json(json)
    if event.type == 'activate' then

        if event.action == "delete" then
            DANMAKU.sources[event.value] = nil
            remove_source_from_history(event.value)
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
            open_add_menu()
            load_danmaku(true)
        end

        if event.action == "block" then
            DANMAKU.sources[event.value]["blocked"] = true
            add_source_to_history(event.value, DANMAKU.sources[event.value])
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
            open_add_menu()
            load_danmaku(true)
        end

        if event.action == "unblock" then
            DANMAKU.sources[event.value]["blocked"] = false
            add_source_to_history(event.value, DANMAKU.sources[event.value])
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
            open_add_menu()
            load_danmaku(true)
        end
    end
end)

mp.register_script_message('setup-danmaku-search-history', function(json)
    -- 搜索菜单事件回调：条目激活复用原有搜索流程，删除操作移除单条历史
    local event = utils.parse_json(json)
    if event == nil or event.type ~= 'activate' then return end

    if event.action == 'delete' then
        if remove_search_history(event.value) then
            -- 原地刷新菜单，保持菜单打开以便连续删除
            local json_props = utils.format_json(build_search_menu_props())
            mp.commandv("script-message-to", "uosc", "update-menu", json_props)
        end
        return
    end

    mp.commandv("script-message-to", mp.get_script_name(), "search-anime-event", event.value)
end)

mp.register_script_message("setup-source-delay", function(query, text)
    local event = utils.parse_json(query)
    if event ~= nil then
        -- item点击
        if event.type == "activate" then
            open_delay_menu(event.value)
        end
    else
        -- 数值输入
        if text == nil or text == "" then
            return
        end
        local delay = parse_delay_input(text)
        if delay ~= nil then
            mp.commandv("script-message", "danmaku-delay", tostring(delay), "0", tostring(query))
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_delay")
            mp.add_timeout(0.1, function()
                open_delay_menu(query, "refresh")
            end)
        else
            open_delay_menu(query, "error")
        end
    end
end)

mp.register_script_message('handle-danmaku-content-action', function(json)
    local event = utils.parse_json(json)
    if not event or event.type ~= 'activate' then return end

    if event.action then
        local d = COMMENTS[event.index]
        if not d or not d.source then return end

        if event.action == "block_source" then
            DANMAKU.sources[d.source]["blocked"] = true
            add_source_to_history(d.source, DANMAKU.sources[d.source])
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_content")
            load_danmaku(true)
        elseif event.action == "adjust_delay" then
            -- 打开以该弹幕时间为起点的延迟菜单（该延迟将作用于该时间点及之后的弹幕），仅针对该条弹幕的 source
            mp.commandv("script-message", "open_content_delay_menu", d.source, tostring(d.start_time))
        end
    else
        if event.value then
            if type(event.value) == "table" then
                mp.commandv(unpack(event.value))
            else
                mp.command(event.value)
            end
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_content")
        end
    end
end)

mp.register_script_message("open_content_delay_menu", function(source, time)
    open_delay_from_time(source, tonumber(time))
end)

mp.register_script_message("setup-content-delay", function(...)
    local args = {...}
    if #args == 1 then
        return
    end
    if #args >= 2 then
        local time = tonumber(args[1])
        local source = args[2]
        local delay_str = args[3]
        local delay = parse_delay_input(delay_str)
        if delay ~= nil then
            mp.commandv("script-message", "danmaku-delay", tostring(delay), tostring(time), tostring(source))
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_delay_from_time")
        else
            open_delay_from_time(source, tonumber(time), "error")
        end
    end
end)

mp.register_script_message("open_blacklist_menu", function()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_total")
    end
    open_blacklist_menu()
end)

mp.register_script_message("blacklist-deal", function(payload, arg, extra)
    -- ① uosc 菜单回调：条目动作按钮 / 整项激活
    local event = utils.parse_json(payload or "")
    if event and event.type == "activate" then
        local index = tonumber(event.index)
        if event.action == "edit" then
            if index then open_blacklist_menu_uosc("edit", index) end
        elseif event.action == "toggle" or event.action == "delete" then
            if index then
                local ok, message
                if event.action == "toggle" then
                    ok, message = blacklist_toggle_entry(index)
                else
                    ok, message = blacklist_delete_entry(index)
                end
                if message then show_message("[弹幕屏蔽规则] " .. message, ok and 2 or 3) end
                if ok then mp.add_timeout(0.05, open_blacklist_menu) end
            end
        elseif type(event.value) == "table" then
            mp.commandv(unpack(event.value))  -- 新建 / 重置整项点击（回放 value 命令）
        end
        return
    end
    -- ② palette / value 触发的模式：先取 (ok, message)，末尾统一反馈
    local mode = tostring(payload or "")
    local index = tonumber(arg)
    local ok, message
    if mode == "create" or mode == "reset" then
        ok, message = blacklist_create_file()
    elseif mode == "add" then
        ok, message = blacklist_add_entry(arg)          -- arg = palette 输入文本
    elseif mode == "edit-submit" and index then
        ok, message = blacklist_edit_entry(index, extra)
        if not ok and not message then open_blacklist_menu() return end  -- 无变更：静默返回主菜单
    end
    if message then show_message("[弹幕屏蔽规则] " .. message, ok and 2 or 3) end
    if ok then mp.add_timeout(0.05, open_blacklist_menu) end
end)

