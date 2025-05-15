local msg = require "mp.msg"
local utils = require "mp.utils"

local function search_episodes(slug, season, type, id, title)
    local message = "Fetching episode information..."
    local menu_type = "trakt_episodes"
    local menu_title = "Trakt Episode Menu"
    local menu_footnote = "Use '/' to open filters"
    if uosc_available then
        update_menu_uosc(menu_type, menu_title, message, menu_footnote)
    else
        send_message(message)
    end

    local url = string.format("https://api.trakt.tv/shows/%s/seasons/%s/episodes", slug, season)
    local res = http_request("GET", url, {
            ["trakt-api-key"] = base64.decode(o.client_id),
            ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        local message = "No results found"
        if uosc_available then
            update_menu_uosc(menu_type, menu_title, message, menu_footnote)
        else
            send_message(message, 3)
            msg.info(message)
        end
        return
    end
    local items = {}
    for _, item in ipairs(res) do
        table.insert(items, {
            title = string.format("Episode %d: %s", item.number, clip_title(item.title) or "No title"),
            value = {
                "script-message-to",
                mp.get_script_name(),
                "trakt-scrobble-event",
                season, tostring(item.number), type, id, title,
            },
        })
    end

    if uosc_available then
        update_menu_uosc(menu_type, menu_title, items, menu_footnote)
    elseif input_available then
        message_timer:kill()
        message_overlay:remove()
        mp.add_timeout(0.1, function()
            open_menu_select(items)
        end)
    end
end

local function search_season(slug, type, id, title)
    local message = "Fetching season information..."
    local menu_type = "trakt_season"
    local menu_title = "Trakt Season Menu"
    local menu_footnote = "Use '/' to open filters"
    if uosc_available then
        update_menu_uosc(menu_type, menu_title, message, menu_footnote)
    else
        send_message(message)
    end

    local url = string.format("https://api.trakt.tv/shows/%s/seasons", slug)
    local res = http_request("GET", url, {
        ["trakt-api-key"] = base64.decode(o.client_id),
        ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        local message = "No results found"
        if uosc_available then
            update_menu_uosc(menu_type, menu_title, message, menu_footnote)
        else
            send_message(message, 3)
            msg.info(message)
        end
        return
    end
    if #res == 1 then
        search_episodes(slug, res[1].number, type, id, title)
    else
        local items = {}
        for _, item in ipairs(res) do
            table.insert(items, {
                title = item.number == 0 and "Specials" or "Season " .. item.number,
                value = {
                    "script-message-to",
                    mp.get_script_name(),
                    "trakt-episodes-event",
                    slug, tostring(item.number), type, id, title,
                },
            })
        end
    
        if uosc_available then
            update_menu_uosc(menu_type, menu_title, items, menu_footnote)
        elseif input_available then
            message_timer:kill()
            message_overlay:remove()
            mp.add_timeout(0.1, function()
                open_menu_select(items)
            end)
        end
    end
end

local function search_trakt(name, class, page)
    local message = "Searching..."
    local menu_type = "menu_trakt"
    local menu_title = "Search Results"
    local menu_footnote = "Use Enter or Ctrl+Enter to search"
    local menu_cmd = { "script-message-to", mp.get_script_name(), "search-event", name }
    if uosc_available then
        update_menu_uosc(menu_type, menu_title, message, menu_footnote, menu_cmd, name)
    else
        send_message(message)
    end
    local limit = 20
    local page = page or 1
    local url = string.format("https://api.trakt.tv/search/%s?query=%s&page=%d&limit=%s",
        class, url_encode(name), page, limit)
    local res = http_request("GET", url, {
        ["trakt-api-key"] = base64.decode(o.client_id),
        ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        local message = "No results found"
        if uosc_available then
            update_menu_uosc(menu_type, menu_title, message, menu_footnote)
        else
            send_message(message, 3)
            msg.info(message)
        end
        return
    end
    local items = {}
    for _, item in ipairs(res) do
        table.insert(items, {
            title = clip_title(item[class].title),
            hint = item[class].year and item.type .." ".. item[class].year or item.type,
            value = {
                "script-message-to",
                mp.get_script_name(),
                "trakt-season-event",
                class, item[class].ids.slug, item.type, tostring(item[class].ids.trakt), item[class].title,
            },
        })
    end
    if #items == limit then
        page = page + 1
        table.insert(items, {
            title = "Load next page",
            value = {
                "script-message-to",
                mp.get_script_name(),
                "trakt-search-event",
                name, class, page,
            },
            italic = true,
            bold = true,
            align = "center",
        })
    end

    if uosc_available then
        update_menu_uosc(menu_type, menu_title, items, menu_footnote)
    elseif input_available then
        message_timer:kill()
        message_overlay:remove()
        mp.add_timeout(0.1, function()
            open_menu_select(items)
        end)
    end
end

local function search(name)
    local title, class = name:match("^(.-)%s*|%s*(.-)$")
    if title then name = title end
    local name = name:gsub("%(.-%)", "")
          :gsub("[sS]%d+[%.%-%s:]?[eE]%d+$", "")
          :gsub("[eE]%d+$", "")
          :gsub("^%s*(.-)%s*$", "%1")
    if class == "mv" then
        search_trakt(name, "movie")
    else
        search_trakt(name, "show")
    end
end

----- input menu -----
function open_menu_select(menu_items)
    local item_titles, item_values = {}, {}
    for i, v in ipairs(menu_items) do
        item_titles[i] = v.hint and v.title .. " (" .. v.hint .. ")" or v.title
        item_values[i] = v.value
    end
    mp.commandv('script-message-to', 'console', 'disable')
    input.select({
        prompt = 'Filter:',
        items = item_titles,
        submit = function(id)
            mp.commandv(unpack(item_values[id]))
        end,
    })
end

function open_input_menu_get(name)
    mp.commandv('script-message-to', 'console', 'disable')
    mp.remove_key_binding("search-trakt")
    input.get({
        prompt = 'input title:',
        default_text = name,
        cursor_position = name and #name + 1,
        submit = function(text)
            input.terminate()
            search(text)
        end
    })
end
----- input menu END-----

----- uosc menu -----
function open_input_menu_uosc(name)
    local items = {}
    items[#items + 1] = {
        hint = "  append '|mv' to search movies",
        keep_open = true,
        selectable = false,
    }
    local menu_props = {
        type = "menu_trakt",
        title = "Input search content",
        search_style = "palette",
        search_debounce = "submit",
        search_suggestion = name,
        on_search = {
            "script-message-to",
            mp.get_script_name(),
            "search-event",
        },
        footnote = "Use Enter or Ctrl+Enter to search",
        items = items,
    }
    local json_props = utils.format_json(menu_props)
    mp.commandv("script-message-to", "uosc", "open-menu", json_props)
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
----- uosc menu END-----

function open_input_menu(name)
    if uosc_available then
        open_input_menu_uosc(name)
    elseif input_available then
        open_input_menu_get(name)
    else
        send_message("uosc or mp.input not available", 3)
        msg.error("uosc or mp.input not available")
    end
end

mp.register_script_message("search-event", function(name)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "open-menu", "menu_trakt")
    end
    search(name)
end)
mp.register_script_message("trakt-search-event", function(name, class, page)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "open-menu", "menu_trakt")
    end
    search_trakt(name, class, page)
end)

mp.register_script_message("trakt-season-event", function(class, slug, type, id, title)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "open-menu", "trakt_season")
    end
    if class == "mv" then
        state.type = type
        state.title = title
        state.id = id
        local progress = get_progress()
        local data = get_data(progress)
        if data then
            start_scrobble(config, data)
        end
        write_history(state.dir, state.fname)
    else
        search_season(slug, type, id, title)
    end
end)

mp.register_script_message("trakt-episodes-event", function(slug, number, type, id, title)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "open-menu", "trakt_episodes")
    end
    search_episodes(slug, number, type, id, title)
end)

mp.register_script_message("trakt-scrobble-event", function(season, number, type, id, title)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "trakt_episodes")
    end
    state.type = type
    state.title = title
    state.id = id
    state.season = season
    state.episode = tonumber(number)
    local progress = get_progress()
    local data = get_data(progress)
    if data then
        enabled = true
        start_scrobble(config, data)
    end
    write_history(state.dir, state.fname)
end)