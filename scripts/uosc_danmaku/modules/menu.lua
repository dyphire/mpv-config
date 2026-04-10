local msg = require('mp.msg')
local utils = require("mp.utils")
local unpack = unpack or table.unpack

input_loaded, input = pcall(require, "mp.input")
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
            local final_items = {}
            -- 按配置的 server 顺序拼接每个 server 的结果
            for _, srv in ipairs(ctx.server_order or {}) do
                local list = ctx.server_items and ctx.server_items[srv]
                if list and type(list) == 'table' then
                    for _, v in ipairs(list) do table.insert(final_items, v) end
                end
            end
            if request_cancelled then return end
            if uosc_available then
                latest_menu_anime = update_menu_uosc(ctx.menu_type, ctx.menu_title, final_items, ctx.footnote, ctx.menu_cmd, ctx.query)
            else
                latest_menu_anime = utils.format_json(final_items)
                if input_loaded then
                    input.terminate()
                    mp.add_timeout(0.1, function()
                        open_menu_select(final_items)
                    end)
                end
            end
        end

        if err then
            msg.debug(("search anime failed for %s: %s"):format(server, tostring(err)))
            ctx.remaining.n = math.max(0, ctx.remaining.n - 1)
            if ctx.remaining.n == 0 then pcall(do_final_update) end
            return
        end
        local data = utils.parse_json(out)
        if not data or not data.animes then
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
function get_animes(query)
    local encoded_query = url_encode(query)
    local server_metas = get_api_server_list(options.api_server, true)
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

    local message = "加载数据中..."
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
        update_menu_uosc(menu_type, menu_title, initial_message, footnote, menu_cmd, query,
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
    }

    local handle_response = make_handle_response(ctx)

    local cancel_fn = parallel_requests(servers, build_args, handle_response, function()
        if request_cancelled then return end
        local final_items = {}
        for _, srv in ipairs(ctx.server_order or {}) do
            local list = ctx.server_items and ctx.server_items[srv]
            if list and type(list) == 'table' then
                for _, v in ipairs(list) do table.insert(final_items, v) end
            end
        end
        if uosc_available then
            latest_menu_anime = update_menu_uosc(ctx.menu_type, ctx.menu_title, final_items, ctx.footnote, ctx.menu_cmd, ctx.query)
        else
            latest_menu_anime = utils.format_json(final_items)
            if not ctx.first_opened.val and input_loaded and #final_items > 0 then
                ctx.first_opened.val = true
                show_message("", 0)
                input.terminate()
                mp.add_timeout(0.1, function()
                    open_menu_select(final_items)
                end)
            end
        end
    end, { concurrency = 5, per_request_timeout = 30 })
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

    if uosc_available then
        active_request_type = menu_type
        update_menu_uosc(menu_type, menu_title, message, footnote, nil, nil,
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

        if err then
            local message = "获取数据失败"
            if uosc_available then
                update_menu_uosc(menu_type, menu_title, message, footnote)
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
                update_menu_uosc(menu_type, menu_title, message, footnote)
            else
                show_message(message, 3)
            end
            msg.info("无结果")
            return
        end

        table.insert(items, {
            title = "← 返回搜索结果",
            value = { "script-message-to", mp.get_script_name(), "open-latest-menu-anime", latest_menu_anime },
            keep_open = false,
            selectable = true,
        })

        for _, episode in ipairs(response.bangumi.episodes) do
            table.insert(items, {
                title = episode.episodeTitle,
                hint = episode.episodeNumber,
                value = { "script-message-to", mp.get_script_name(), "load-danmaku",
                animeTitle, episode.episodeTitle, episode.episodeId, api_server },
                keep_open = false,
                selectable = true,
            })
        end

        if uosc_available then
            footnote = mp.get_property("filename")
            update_menu_uosc(menu_type, menu_title, items, footnote)
        elseif input_loaded then
            show_message("", 0)
            input.terminate()
            mp.add_timeout(0.1, function()
                open_menu_select(items)
            end)
        end
    end)
    active_request_type = menu_type
end

function update_menu_uosc(menu_type, menu_title, menu_item, menu_footnote, menu_cmd, query, on_close)
    local items = {}
    if type(menu_item) == "string" then
        table.insert(items, {
            title = menu_item,
            value = "",
            italic = true,
            keep_open = true,
            selectable = false,
            align = "center",
            icon = "spinner",
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

    local current_menu_type = mp.get_property_native('user-data/uosc/menu/type')
    local cmd = "open-menu"
    if current_menu_type and tostring(current_menu_type) == tostring(menu_type) then
        cmd = "update-menu"
    end

    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", cmd, json_props)

    return json_props
end

function open_menu_select(menu_items, is_time)
    local item_titles, item_values = {}, {}
    for i, v in ipairs(menu_items) do
        item_titles[i] = is_time and "[" .. v.hint .. "] " .. v.title or
            (v.hint and v.title .. " (" .. v.hint .. ")" or v.title)
        item_values[i] = v.value
    end
    mp.commandv('script-message-to', 'console', 'disable')
    input.select({
        prompt = is_time and '筛选:' or '选择:',
        items = item_titles,
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
function open_input_menu_get()
    mp.commandv('script-message-to', 'console', 'disable')
    local title = parse_title()
    input.get({
        prompt = '番剧名称:',
        default_text = title,
        cursor_position = title and #title + 1,
        submit = function(text)
            input.terminate()
            mp.commandv("script-message-to", mp.get_script_name(), "search-anime-event", text)
        end
    })
end

function open_input_menu_uosc()
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

    local menu_props = {
        type = "menu_danmaku",
        title = "在此处输入番剧名称",
        search_style = "palette",
        search_debounce = "submit",
        search_suggestion = parse_title(),
        on_search = { "script-message-to", mp.get_script_name(), "search-anime-event" },
        footnote = "使用enter或ctrl+enter进行搜索",
        items = items
    }
    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end

function open_input_menu()
    if uosc_available then
        open_input_menu_uosc()
    elseif input_loaded then
        open_input_menu_get()
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

    input.get({
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
            local item = {title = utf8_sub(url, 1, 100), value = url, keep_open = true,}
            if source.from == "api_server" then
                if source.blocked then
                    item.hint = "来源：弹幕服务器（已屏蔽）"
                    item.actions = {{icon = "check", name = "unblock", label = "解除屏蔽"},}
                else
                    item.hint = "来源：弹幕服务器（未屏蔽）"
                    item.actions = {{icon = "not_interested", name = "block", label = "屏蔽"},}
                end
            else
                item.hint = "来源：用户添加"
                if source.blocked then
                    item.actions = {
                        {icon = "check", name = "unblock", label = "解除屏蔽"},
                        {icon = "delete", name = "delete", label = "删除"},
                    }
                else
                    item.actions = {
                        {icon = "not_interested", name = "block", label = "屏蔽"},
                        {icon = "delete", name = "delete", label = "删除"},
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
        open_add_menu_get()
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
                    title = abbr_str(text, 60),
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

-- 设置弹幕样式菜单
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

    input.get({
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

    input.get({
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

-- 设置弹幕源延迟菜单
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
                select_num = (url == source) and serial or select_num
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

    input.get({
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
    input.select({
        prompt = '选择:',
        items = item_titles,
        submit = function(id)
            mp.commandv(unpack(item_values[id]))
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

    mp.commandv("script-message-to", "uosc", "set", "show_danmaku", value)
end)

-- 注册函数给 uosc 按钮使用
mp.register_script_message("search-anime-event", function(query)
    perform_cancel_active_request()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_danmaku")
    end
    local name, class = query:match("^(.-)%s*|%s*(.-)%s*$")
    if name and class then
        query_extra(name, class)
    else
        get_animes(query)
    end
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
