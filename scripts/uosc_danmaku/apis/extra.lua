local utils = require 'mp.utils'
local msg = require 'mp.msg'

local Source = {
    ["b 站"] = "bilibili1",
    ["腾讯"] = "qq",
    ["爱奇艺"] = "qiyi",
    ["优酷"] = "youku",
}

local function load_extra_danmaku(url, episode, number, class, id, site, title, year)
    local play_url = nil
    if url:match("^.-%.html") then
        play_url = url:match("^(.-%.html).*")
    else
        play_url = url:gsub("%?bsource=360ogvys$","")
    end
    ENABLED = true
    DANMAKU.anime = title .. " (" .. year .. ")"
    DANMAKU.episode = "第" .. episode .. "话"
    DANMAKU.source = site
    DANMAKU.extra = {
        id = id,
        site = site,
        year = year,
        class = class,
        title = title,
        number = tonumber(number),
        episodenum = tonumber(episode),
    }
    write_history()
    add_danmaku_source(play_url, true)
end

local function query_tmdb(title, class, menu)
    local encoded_title = url_encode(title)
    local url = string.format("https://api.themoviedb.org/3/search/%s?api_key=%s&query=%s&language=zh-CN",
    class, Base64.decode(options.tmdb_api_key), encoded_title)

    local cmd = {
        "curl",
        "-s",
        "-H", "accept: application/json",
        url
    }

    if options.proxy ~= "" then
        table.insert(cmd, '-x')
        table.insert(cmd, options.proxy)
    end

    local res = mp.command_native({
        name = "subprocess",
        args = cmd,
        capture_stdout = true,
        capture_stderr = true,
    })

    local data = utils.parse_json(res.stdout)
    if not res.status or res.status ~= 0 or not data.results or #data.results == 0 then
        local message = "获取 tmdb 中文数据失败"
        if uosc_available then
            update_menu_uosc(menu.type, menu.title, message, menu.footnote, menu.cmd, title)
        else
            show_message(message, 3)
        end
        msg.error("获取 tmdb 中文数据失败：" .. res.stdout)
    else
        if class == "tv" then
            return data.results[1].name
        else
            return data.results[1].title
        end
    end
end

local function get_number(cat, id, site)
    local url = string.format("https://api.web.360kan.com/v1/detail?cat=%s&id=%s&site=%s",
        cat, id, site)

    local cmd = { "curl", "-s", url }
    local res = mp.command_native({
        name = "subprocess",
        args = cmd,
        capture_stdout = true,
        capture_stderr = true,
    })

    if not res.status or res.status ~= 0 then
        msg.error("Failed to fetch data: " .. (res.stderr or "unknown error"))
        return nil
    end

    local result = utils.parse_json(res.stdout)
    if result and result.data and result.data.allupinfo then
        return tonumber(result.data.allupinfo[site])
    end
    return nil
end

function get_details(class, id, site, title, year, number, episodenum)
    local message = episodenum and "查询弹幕中..." or "加载数据中..."
    local menu_type = "menu_details"
    local menu_title = "剧集信息"
    local footnote = "使用 / 打开筛选"
    if uosc_available and not episodenum then
        update_menu_uosc(menu_type, menu_title, message, footnote)
    else
        show_message(message, 3)
    end

    local cat = 0
    if class == "电影" then
        cat = 1
    elseif class == "电视剧" then
        cat = 2
--  elseif class == "综艺" then
--      cat = 3
    elseif class == "动漫" then
        cat = 4
    end

    if not number and cat ~= 0 then
        number = get_number(cat, id, site)
    end
    if not number or cat == 0 then
        local message = "无结果"
        if uosc_available and not episodenum then
            update_menu_uosc(menu_type, menu_title, message, footnote)
        else
            show_message(message, 3)
        end
        msg.verbose("无结果")
        return
    end

    local url = string.format("https://api.web.360kan.com/v1/detail?cat=%s&id=%s&start=1&end=%s&site=%s",
        cat, id, number, site)

    local cmd = { "curl", "-s", url }
    local res = mp.command_native({
        name = "subprocess",
        args = cmd,
        capture_stdout = true,
        capture_stderr = true,
    })

    if not res.status or res.status ~= 0 then
        local message = "无结果"
        if uosc_available and not episodenum then
            update_menu_uosc(menu_type, menu_title, message, footnote)
        else
            show_message(message, 3)
        end
        msg.verbose("无结果")
        return
    end

    local result = utils.parse_json(res.stdout)
    local items = {}
    if result and result.data and result.data.allepidetail then
        local data = result.data.allepidetail
        local playurl, episode = nil, nil
        if episodenum then
            for _, item in ipairs(data[site]) do
                if tonumber(item.playlink_num) == tonumber(episodenum) then
                    playurl = item.url
                    episode = item.playlink_num
                    break
                end
            end
            if playurl then
                load_extra_danmaku(playurl, episode, number, class, id, site, title, year)
                return
            end
        end
        for _, item in ipairs(data[site]) do
            table.insert(items, {
                title = "第" .. item.playlink_num .. "集",
                hint = item.playlink_num,
                value = {
                    "script-message-to",
                    mp.get_script_name(),
                    "add-extra-event",
                    item.url, item.playlink_num, number, class, id, site, title, year
                },
            })
        end
    end
    if #items > 0 then
        if uosc_available and not episodenum then
            update_menu_uosc(menu_type, menu_title, items, footnote)
        elseif not episodenum then
            show_message("", 0)
            mp.add_timeout(0.1, function()
                open_menu_select(items)
            end)
        end
    else
        local message = "无结果"
        if uosc_available and not episodenum then
            update_menu_uosc(menu_type, menu_title, message, footnote)
        else
            show_message(message, 3)
        end
        msg.verbose("无结果")
    end
end

local function search_query(query, class, menu)
    local url = string.format("https://api.so.360kan.com/index?force_v=1&kw=%s", query)
    if class ~= nil then
        url = url .. "&type=" .. class
    end
    local cmd = { "curl", "-s", url }

    local res = mp.command_native({
        name = "subprocess",
        args = cmd,
        capture_stdout = true,
        capture_stderr = true,
    })

    if not res.status or res.status ~= 0 then
        local message = "无结果"
        if uosc_available then
            update_menu_uosc(menu.type, menu.title, message, menu.footnote, menu.cmd, query)
        else
            show_message(message, 3)
        end
        msg.verbose("无结果")
        return
    end

    local result = utils.parse_json(res.stdout)
    local items = {}
    if result and result.data.longData and result.data.longData.rows then
        for _, item in ipairs(result.data.longData.rows) do
            if item.playlinks then
                for source_name, source_id in pairs(Source) do
                    if item.playlinks[source_id] then
                        table.insert(items, {
                            title = item.titleTxt,
                            hint = item.cat_name .. " | " .. item.year .. " | 来源：" .. source_name,
                            value = {
                                "script-message-to",
                                mp.get_script_name(),
                                "get-extra-event",
                                item.cat_name, item.en_id, item.playlinks[source_id], source_id,
                                item.titleTxt, item.year,
                            },
                        })
                    end
                end
            end
        end
    end
    if #items > 0 then
        if uosc_available then
            update_menu_uosc(menu.type, menu.title, items, menu.footnote, menu.cmd, query)
        else
            show_message("", 0)
            mp.add_timeout(0.1, function()
                open_menu_select(items)
            end)
        end
    else
        local message = "无结果"
        if uosc_available then
            update_menu_uosc(menu.type, menu.title, message, menu.footnote, menu.cmd, query)
        else
            show_message(message, 3)
        end
        msg.verbose("无结果")
    end
end

function query_extra(name, class)
    local name = name:gsub("%s*%(%d-%)%s*$", "")
    local title = nil
    local class = class and class:lower()
    local message = "加载数据中..."
    local menu = {
        type = "menu_anime",
        title = "在此处输入番剧名称",
        footnote = "使用enter或ctrl+enter进行搜索"
    }
    menu.cmd = { "script-message-to", mp.get_script_name(), "search-anime-event" }
    if uosc_available then
        update_menu_uosc(menu.type, menu.title, message, menu.footnote, menu.cmd, name)
    else
        show_message(message, 30)
    end

    if is_chinese(name) then
        search_query(name, class, menu)
        return
    end


    if options.tmdb_api_key == "" or #Base64.decode(options.tmdb_api_key) < 32 then
        local message = "请正确设置 tmdb_api_key 或尝试使用中文搜索"
        if uosc_available then
            update_menu_uosc(menu.type, menu.title, message, menu.footnote, menu.cmd, name)
        else
            show_message(message, 3)
        end
        return
    end

    if class == "dy" then
        title = query_tmdb(name, "movie", menu)
    else
        title = query_tmdb(name, "tv", menu)
    end

    if title then
        search_query(title, class, menu)
    end
end

mp.register_script_message("get-extra-event", function(cat, id, playlink, source_id, title, year)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_anime")
    end
    if cat == "电影" then
        if playlink:match("^.-%.html") then
            playlink = playlink:match("^(.-%.html).*")
        else
            playlink = playlink:gsub("%?bsource=360ogvys$","")
        end
        DANMAKU.anime = title .. " (" .. year .. ")"
        DANMAKU.episode = "电影"
        DANMAKU.source = source_id
        write_history()
        add_danmaku_source(playlink, true)
    else
        get_details(cat, id, source_id, title, year)
    end
end)

mp.register_script_message("add-extra-event", function(url, episode, number, class, id, site, title, year)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "menu_details")
    end
    load_extra_danmaku(url, episode, number, class, id, site, title, year)
end)
