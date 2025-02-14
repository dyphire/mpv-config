local msg = require "mp.msg"

local function search_episodes(slug, season, type, id, title, config)
    local url = string.format("https://api.trakt.tv/shows/%s/seasons/%s/episodes", slug, season)
    local res = http_request("GET", url, {
            ["trakt-api-key"] = base64.decode(config.client_id),
            ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        msg.info("No results found")
        return
    end
    local items = {}
    for _, item in ipairs(res) do
        table.insert(items, {
            title = string.format("Episode %d: %s", item.number, item.title or "No title"),
            value = function()
                state.type = type
                state.title = title
                state.id = id
                state.season = season
                state.episode = item.number
                local progress = get_progress()
                local data = get_data(progress)
                if data then
                    start_scrobble(config, data)
                end
                write_history(state.dir, state.fname)
            end
        })
    end
    mp.add_timeout(0.1, function()
        open_menu_select(items)
    end)
end

local function search_season(slug, type, id, title, config)
    local url = string.format("https://api.trakt.tv/shows/%s/seasons", slug)
    local res = http_request("GET", url, {
        ["trakt-api-key"] = base64.decode(config.client_id),
        ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        msg.info("No results found")
        return
    end
    if #res == 1 then
        search_episodes(slug, res[1].number, type, id, title, config)
    else
        local items = {}
        for _, item in ipairs(res) do
            table.insert(items, {
                title = item.number == 0 and "Specials" or "Season " .. item.number,
                value = function()
                    search_episodes(slug, item.number, type, id, title, config)
                end
            })
        end
        mp.add_timeout(0.1, function()
            open_menu_select(items)
        end)
    end
end

local function search_trakt(name, class, config, page)
    local limit = 20
    local page = page or 1
    local url = string.format("https://api.trakt.tv/search/%s?query=%s&page=%d&limit=%s",
        class, url_encode(name), page, limit)
    local res = http_request("GET", url, {
        ["trakt-api-key"] = base64.decode(config.client_id),
        ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        msg.info("No results found")
        return
    end
    local items = {}
    for _, item in ipairs(res) do
        table.insert(items, {
            title = item[class].title,
            hint = item[class].year and item.type .." ".. item[class].year or item.type,
            value = function()
                if class == "movie" then
                    state.type = item.type
                    state.title = item[class].title
                    state.id = item[class].ids.trakt
                    local progress = get_progress()
                    local data = get_data(progress)
                    if data then
                        start_scrobble(config, data)
                    end
                    write_history(state.dir, state.fname)
                else
                    search_season(item[class].ids.slug, item.type, item[class].ids.trakt, item[class].title, config)
                end
            end
        })
    end
    if #items == limit then
        page = page + 1
        table.insert(items, {
            title = "Load next page",
            value = function()
                search_trakt(name, class, config, page)
            end
        })
    else
        msg.info("No more pages available.")
    end
    mp.add_timeout(0.1, function()
        open_menu_select(items)
    end)
end

local function search(name, config)
    local title, type = name:match("^(.-)%s*|%s*(.-)$")
    if title then name = title end
    local name = name:gsub("%(.-%)", "")
          :gsub("[sS]%d+[%.%-%s:]?[eE]%d+$", "")
          :gsub("[eE]%d+$", "")
          :gsub("^%s*(.-)%s*$", "%1")
    if type == "movie" then
        search_trakt(name, "movie", config)
    else
        search_trakt(name, "show", config)
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
            item_values[id]()
        end,
    })
end

function open_input_menu_get(name, config)
    mp.commandv('script-message-to', 'console', 'disable')
    mp.remove_key_binding("search-trakt")
    input.get({
        prompt = 'input title:',
        default_text = name,
        cursor_position = name and #name + 1,
        submit = function(text)
            input.terminate()
            search(text, config)
        end
    })
end
----- input menu END-----