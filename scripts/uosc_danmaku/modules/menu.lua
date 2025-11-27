local msg = require('mp.msg')
local utils = require("mp.utils")

input_loaded, input = pcall(require, "mp.input")
uosc_available = false

-- 打开番剧数据匹配菜单
function get_animes(query)
    local encoded_query = url_encode(query)
    local url = options.api_server .. "/api/v2/search/anime"
    local params = "keyword=" .. encoded_query
    local full_url = url .. "?" .. params
    local items = {}

    local message = "加载数据中..."
    local menu_type = "menu_anime"
    local menu_title = "在此处输入番剧名称"
    local footnote = "使用enter或ctrl+enter进行搜索"
    local menu_cmd = { "script-message-to", mp.get_script_name(), "search-anime-event" }
    if uosc_available then
        update_menu_uosc(menu_type, menu_title, message, footnote, menu_cmd, query)
    else
        show_message(message, 30)
    end
    msg.verbose("尝试获取番剧数据：" .. full_url)

    local args = make_danmaku_request_args("GET", full_url)

    if args == nil then
        return
    end

    local res = mp.command_native({ name = 'subprocess', capture_stdout = true, capture_stderr = true, args = args })

    if not res.status or res.status ~= 0 then
        local message = "获取数据失败"
        if uosc_available then
            update_menu_uosc(menu_type, menu_title, message, footnote, menu_cmd, query)
        else
            show_message(message, 3)
        end
        msg.error("HTTP 请求失败：" .. res.stderr)
    end

    local response = utils.parse_json(res.stdout)

    if not response or not response.animes then
        local message = "无结果"
        if uosc_available then
            update_menu_uosc(menu_type, menu_title, message, footnote, menu_cmd, query)
        else
            show_message(message, 3)
        end
        msg.info("无结果")
        return
    end

    for _, anime in ipairs(response.animes) do
        table.insert(items, {
            title = anime.animeTitle,
            hint = anime.typeDescription,
            value = {
                "script-message-to",
                mp.get_script_name(),
                "search-episodes-event",
                anime.animeTitle, anime.bangumiId,
            },
        })
    end

    if uosc_available then
        update_menu_uosc(menu_type, menu_title, items, footnote, menu_cmd, query)
    elseif input_loaded then
        show_message("", 0)
        mp.add_timeout(0.1, function()
            open_menu_select(items)
        end)
    end
end

function get_episodes(animeTitle, bangumiId)
    local url = options.api_server .. "/api/v2/bangumi/" .. bangumiId
    local items = {}

    local message = "加载数据中..."
    local menu_type = "menu_episodes"
    local menu_title = "剧集信息"
    local footnote = "使用 / 打开筛选"

    if uosc_available then
        update_menu_uosc(menu_type, menu_title, message, footnote)
    else
        show_message(message, 30)
    end

    local args = make_danmaku_request_args("GET", url)

    if args == nil then
        return
    end

    local res = mp.command_native({ name = 'subprocess', capture_stdout = true, capture_stderr = true, args = args })

    if not res.status or res.status ~= 0 then
        local message = "获取数据失败"
        if uosc_available then
            update_menu_uosc(menu_type, menu_title, message, footnote)
        else
            show_message(message, 3)
        end
        msg.error("HTTP 请求失败：" .. res.stderr)
    end

    local response = utils.parse_json(res.stdout)

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

    for _, episode in ipairs(response.bangumi.episodes) do
        table.insert(items, {
            title = episode.episodeTitle,
            hint = episode.episodeNumber,
            value = { "script-message-to", mp.get_script_name(), "load-danmaku",
            animeTitle, episode.episodeTitle, episode.episodeId },
            keep_open = false,
            selectable = true,
        })
    end

    if uosc_available then
        update_menu_uosc(menu_type, menu_title, items, footnote)
    elseif input_loaded then
        mp.add_timeout(0.1, function()
            open_menu_select(items)
        end)
    end
end

function update_menu_uosc(menu_type, menu_title, menu_item, menu_footnote, menu_cmd, query)
    local items = {}
    if type(menu_item) == "string" then
        table.insert(items, {
            title = menu_item,
            value = "",
            italic = true,
            keep_open = true,
            selectable = false,
            align = "center",
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
    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
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
        prompt = '筛选:',
        items = item_titles,
        submit = function(id)
            mp.commandv(unpack(item_values[id]))
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
    mp.commandv('script-message-to', 'console', 'disable')
    input.get({
        prompt = 'Input url:',
        submit = function(text)
            input.terminate()
            mp.commandv("script-message-to", mp.get_script_name(), "add-source-event", text)
        end
    })
end

function open_add_menu_uosc()
    local sources = {}
    for url, source in pairs(DANMAKU.sources) do
        if source.fname then
            local item = {title = url, value = url, keep_open = true,}
            if source.from == "api_server" then
                if source.blocked then
                    item.hint = "来源：弹幕服务器（已屏蔽）"
                    item.actions = {{icon = "check", name = "unblock"},}
                else
                    item.hint = "来源：弹幕服务器（未屏蔽）"
                    item.actions = {{icon = "not_interested", name = "block"},}
                end
            else
                item.hint = "来源：用户添加"
                item.actions = {{icon = "delete", name = "delete"},}
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
            local delay = get_delay_for_time(DELAYS, event.start_time)
            local start_time = event.start_time + delay
            local end_time = event.end_time + delay
            if text and text ~= "" and start_time >= 0 and start_time <= duration then
                table.insert(items, {
                    title = abbr_str(text, 60),
                    hint = seconds_to_time(start_time),
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
        items = items
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
function add_danmaku_setup(actived, status)
    if not uosc_available then
        show_message("无uosc UI框架，不支持使用该功能", 2)
        return
    end

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
            mp.add_timeout(1.0, function() add_danmaku_setup(actived, "updata") end)
        end
        menu_props.search_style = "palette"
        menu_props.search_debounce = "submit"
        menu_props.footnote = menu_items_config[actived]["footnote"] or ""
        menu_props.on_search = { "script-message-to", mp.get_script_name(), "setup-danmaku-style", actived }
    end

    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", actions, json_props)
end

-- 设置弹幕源延迟菜单
function danmaku_delay_setup(source_url)
    if not uosc_available then
        show_message("无uosc UI框架，不支持使用该功能", 2)
        return
    end

    local sources = {}
    for url, source in pairs(DANMAKU.sources) do
        if source.fname and not source.blocked then
            local delay = 0
            if source.delay_segments then
                for _, seg in ipairs(source.delay_segments) do
                    if seg.start == 0 then
                        delay = seg.delay or 0
                        break
                    end
                end
            end
            local item = {title = url, value = url, keep_open = true,}
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
        menu_props.title = "请输入数字，单位（秒）/ 或者按照形如\"14m15s\"的格式输入分钟数加秒数"
        menu_props.search_style = "palette"
        menu_props.search_debounce = "submit"
        menu_props.on_search = { "script-message-to", mp.get_script_name(), "setup-source-delay", source_url }
    end

    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
end


-- 总集合弹幕菜单
function open_add_total_menu_uosc()
    local items = {}
    local total_menu_items_config = {
        { title = "弹幕搜索", action = "open_search_danmaku_menu" },
        { title = "从源添加弹幕", action = "open_add_source_menu" },
        { title = "弹幕源延迟设置", action = "open_source_delay_menu" },
        { title = "弹幕样式", action = "open_setup_danmaku_menu" },
        { title = "弹幕内容", action = "open_content_danmaku_menu" },
    }


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
    local total_menu_items_config = {
        { title = "弹幕搜索", action = "open_search_danmaku_menu" },
        { title = "从源添加弹幕", action = "open_add_source_menu" },
        { title = "弹幕内容", action = "open_content_danmaku_menu" },
    }
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
        command = "script-message open_setup_danmaku_menu",
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
mp.register_script_message("search-episodes-event", function(animeTitle, bangumiId)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_anime")
    end
    get_episodes(animeTitle, bangumiId)
end)

-- Register script message to show the input menu
mp.register_script_message("load-danmaku", function(animeTitle, episodeTitle, episodeId)
    ENABLED = true
    DANMAKU.anime = animeTitle
    DANMAKU.episode = episodeTitle
    set_episode_id(episodeId, true)
end)

mp.register_script_message("add-source-event", function(query)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
    end
    ENABLED = true
    add_danmaku_source(query, true)
end)

mp.register_script_message("open_setup_danmaku_menu", function()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_total")
    end
    add_danmaku_setup()
end)
mp.register_script_message("open_content_danmaku_menu", function()
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_total")
    end
    open_content_menu()
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
                add_danmaku_setup(ordered_keys[event.index], "updata")
                return
            else
                -- msg.info("event.action：" .. event.action)
                options[event.action] = menu_items_config[event.action]["original"]
                menu_items_config[event.action]["hint"] = options[event.action]
                add_danmaku_setup(event.action, "updata")
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
                add_danmaku_setup(query, "refresh")
                if query == "fontsize" or query == "scrolltime" then
                    load_danmaku(true, true)
                end
                return
            end
        end
        add_danmaku_setup(query, "error")
    end
end)

mp.register_script_message('setup-danmaku-source', function(json)
    local event = utils.parse_json(json)
    if event.type == 'activate' then

        if event.action == "delete" then
            local rm = DANMAKU.sources[event.value]["fname"]
            if rm and file_exists(rm) and DANMAKU.sources[event.value]["from"] ~= "user_local" then
                os.remove(rm)
            end
            DANMAKU.sources[event.value] = nil
            remove_source_from_history(event.value)
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
            open_add_menu_uosc()
            load_danmaku(true)
        end

        if event.action == "block" then
            DANMAKU.sources[event.value]["blocked"] = true
            add_source_to_history(event.value, DANMAKU.sources[event.value])
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
            open_add_menu_uosc()
            load_danmaku(true)
        end

        if event.action == "unblock" then
            DANMAKU.sources[event.value]["blocked"] = false
            add_source_to_history(event.value, DANMAKU.sources[event.value])
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_source")
            open_add_menu_uosc()
            load_danmaku(true)
        end
    end
end)

mp.register_script_message("setup-source-delay", function(query, text)
    local event = utils.parse_json(query)
    if event ~= nil then
        -- item点击
        if event.type == "activate" then
            danmaku_delay_setup(event.value)
        end
    else
        -- 数值输入
        if text == nil or text == "" then
            return
        end
        local newText, _ = text:gsub("%s", "") -- 移除所有空白字符
        local num = tonumber(newText)
        local delay_segments = shallow_copy(DANMAKU.sources[query]["delay_segments"] or {})
        for i = #delay_segments, 1, -1 do
            if delay_segments[i].start == 0 then
                table.remove(delay_segments, i)
            end
        end
        if num ~= nil then
            table.insert(delay_segments, 1, { start = 0, delay = tonumber(num) })
            DANMAKU.sources[query]["delay_segments"] = delay_segments
            add_source_to_history(query, DANMAKU.sources[query])
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_delay")
            danmaku_delay_setup(query)
            load_danmaku(true, true)
        elseif newText:match("^%-?%d+m%d+s$") then
            local minutes, seconds = string.match(newText, "^(%-?%d+)m(%d+)s$")
            minutes = tonumber(minutes)
            seconds = tonumber(seconds)
            if minutes < 0 then seconds = -seconds end
            table.insert(delay_segments, 1, { start = 0, delay = 60 * minutes + seconds })
            DANMAKU.sources[query]["delay_segments"] = delay_segments
            add_source_to_history(query, DANMAKU.sources[query])
            mp.commandv("script-message-to", "uosc", "close-menu", "menu_delay")
            danmaku_delay_setup(query)
            load_danmaku(true, true)
        end
    end
end)
