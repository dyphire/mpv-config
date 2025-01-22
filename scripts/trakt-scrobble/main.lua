
--[[
    * trakt-scrobble.lua
    *
    * AUTHORS: dyphire
    * License: MIT
    * link: https://github.com/dyphire/trakt-scrobble
]]


local utils = require "mp.utils"
local msg = require "mp.msg"
local options = require "mp.options"
require('guess')

local o = {
    enabled = true
}

options.read_options(o, _, function() end)

local state = {}
local config_file = utils.join_path(mp.get_script_directory(), "config.json")

-- Check if the path is a protocol (e.g., http://)
local function is_protocol(path)
    return type(path) == "string" and (path:find("^%a[%w.+-]-://") ~= nil or path:find("^%a[%w.+-]-:%?") ~= nil)
end

-- URL decode function
local function hex_to_char(x)
    return string.char(tonumber(x, 16))
end

local function url_encode(str)
    if str then
        str = str:gsub("([^%w%-%.%_%~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
    end
    return str
end

local function url_decode(str)
    if str ~= nil then
        str = str:gsub("^%a[%a%d-_]+://", "")
              :gsub("^%a[%a%d-_]+:\\?", "")
              :gsub("%%(%x%x)", hex_to_char)
        if str:find("://localhost:?") then
            str = str:gsub("^.*/", "")
        end
        str = str:gsub("%?.+", "")
              :gsub("%+", " ")
        return str
    else
        return
    end
end

local function normalize(path)
    if normalize_path ~= nil then
        if normalize_path then
            path = mp.command_native({"normalize-path", path})
        else
            local directory = mp.get_property_native("working-directory", "")
            path = utils.join_path(directory, path:gsub('^%.[\\/]',''))
            if platform == "windows" then path = path:gsub("\\", "/") end
        end
        return path
    end

    normalize_path = false

    local commands = mp.get_property_native("command-list", {})
    for _, command in ipairs(commands) do
        if command.name == "normalize-path" then
            normalize_path = true
            break
        end
    end
    return normalize(path)
end

local function get_parent_dir(path)
    local dir = nil
    if path and not is_protocol(path) then
        path = normalize(path)
        dir = utils.split_path(path)
    end
    return dir
end

-- Send a message to the OSD
local function send_message(msg, color, time)
    local ass_start = mp.get_property_osd("osd-ass-cc/0")
    local ass_stop = mp.get_property_osd("osd-ass-cc/1")
    mp.osd_message(ass_start .. "{\\1c&H" .. color .. "&}" .. msg .. ass_stop, time)
end

-- Read config file
local function read_config()
    local file = io.open(config_file, "r")
    if not file then
        msg.error("Error: config.json not found")
        return nil
    end
    local content = file:read("*a")
    file:close()
    return utils.parse_json(content)
end

-- Write config file
local function write_config(config)
    local file = io.open(config_file, "w")
    if not file then
        msg.error("Error: failed to write config.json")
        return
    end
    file:write(utils.format_json(config))
    file:close()
end

-- Send HTTP request using curl
local function http_request(method, url, headers, body)
    local cmd = { "curl", "-s", "-X", method, url }
    if headers then
        for k, v in pairs(headers) do
            table.insert(cmd, "-H")
            table.insert(cmd, string.format("%s: %s", k, v))
        end
    end
    if body then
        table.insert(cmd, "-d")
        table.insert(cmd, utils.format_json(body))
    end

    local res = mp.command_native({
        name = "subprocess",
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
        args = cmd
    })

    if res.status ~= 0 then
        msg.error("HTTP request failed: " .. res.stderr)
        return nil
    end

    return utils.parse_json(res.stdout)
end

-- Initialize and check config
local function init()
    local config = read_config()
    if not config then
        return 10
    end
    if not config.client_id or not config.client_secret or #config.client_id ~= 64 or #config.client_secret ~= 64 then
        return 10
    end
    if not config.access_token or #config.access_token ~= 64 then
        return 11
    end
    return 0
end

-- Generate device code
local function device_code()
    local config = read_config()
    if not config then
        return -1
    end
    local res = http_request("POST", "https://api.trakt.tv/oauth/device/code", {
        ["Content-Type"] = "application/json"
    }, {
        client_id = config.client_id
    })
    if not res then
        return -1
    end
    config.device_code = res.device_code
    write_config(config)
    return 0, res.user_code
end

-- Authenticate with device code
local function auth()
    local config = read_config()
    if not config then
        return -1
    end
    local res = http_request("POST", "https://api.trakt.tv/oauth/device/token", {
        ["Content-Type"] = "application/json"
    }, {
        client_id = config.client_id,
        client_secret = config.client_secret,
        code = config.device_code
    })
    if not res or not res.access_token then
        return -1
    end
    config.access_token = res.access_token
    config.refresh_token = res.refresh_token
    config.device_code = nil
    config.today = os.date("%Y-%m-%d")

    -- Get user info
    local user_res = http_request("GET", "https://api.trakt.tv/users/settings", {
        ["trakt-api-key"] = config.client_id,
        ["Authorization"] = "Bearer " .. config.access_token,
        ["trakt-api-version"] = "2"
    })
    if not user_res or not user_res.user then
        return -1
    end
    config.user_slug = user_res.user.ids.slug
    write_config(config)
    return 0
end

-- Authentication activation
local function activation()
    send_message("Querying trakt.tv... Hold tight", "FFFFFF", 10)
    local status, output = device_code()

    if status == 0 then
        send_message("Open https://trakt.tv/activate and type: " .. output .. "\nPress x when done", "FF8800", 50)
        msg.info("Open https://trakt.tv/activate and type: " .. output)
        mp.remove_key_binding("auth-trakt")
        mp.add_forced_key_binding("x", "auth-trakt", function()
            local status = auth()
            if status == 0 then
                send_message("It's done. Enjoy!", "00FF00", 3)
                mp.remove_key_binding("auth-trakt")
            else
                send_message("Authentication failed. Check the console for more info.", "0000FF", 4)
                msg.error("Authentication failed")
            end
        end)
    else
        send_message("Failed to generate device code. Check the console for more info.", "0000FF", 4)
        msg.error("Failed to generate device code")
    end
end

local function get_progress()
    local time_pos = state.pos or 0
    local duration = state.duration or 0

    if duration == 0 then
        return
    end

    local progress = (tonumber(time_pos) / tonumber(duration)) * 100
    return math.floor(progress)
end

local function get_data(progress)
    if not state then return end
    if state.season and state.episode then
        data = {
            progress = tonumber(progress),
            show = {
                ids = {
                    trakt = tonumber(state.id)
                }
            },
            episode = {
                season = tonumber(state.season),
                number = tonumber(state.episode)
            }
        }
    elseif state.id then
        data = {
            progress = tonumber(progress),
            movie = {
                ids = {
                    trakt = tonumber(state.id)
                }
            }
        }
    end
    return data
end

local function start_scrobble(config, data)
    msg.info("Starting scrobbling to Trakt.tv")
    local res = http_request("POST", "https://api.trakt.tv/scrobble/start", {
        ["Content-Type"] = "application/json",
        ["trakt-api-key"] = config.client_id,
        ["Authorization"] = "Bearer " .. config.access_token,
        ["trakt-api-version"] = "2"
    }, data)
    if not res then
        send_message("Unable to scrobble ", "0000FF", 3)
        msg.error("Check-in failed")
        return
    end
    if state and state.title then
        if state.season and state.episode then
            send_message("Scrobbling on trakt.tv: " .. state.title .. " S" .. state.season .. "E" .. state.episode, "00FF00", 3)
            msg.info("Scrobbling on trakt.tv: " .. state.title .. " S" .. state.season .. "E" .. state.episode)
        else
            send_message("Scrobbling on trakt.tv: " .. state.title, "00FF00", 3)
            msg.info("Scrobbling on trakt.tv: " .. state.title)
        end
    end
end

local function stop_scrobble(config, data)
    msg.info("Stopping scrobbling to Trakt.tv")
    local res = http_request("POST", "https://api.trakt.tv/scrobble/stop", {
        ["Content-Type"] = "application/json",
        ["trakt-api-key"] = config.client_id,
        ["Authorization"] = "Bearer " .. config.access_token,
        ["trakt-api-version"] = "2"
    }, data)
    if not res then
        msg.error("Stop scrobble failed")
        return
    end
    if state and state.title then
        msg.info("Stopped scrobble on trakt.tv: " .. state.title)
    else
        msg.info("Stopped scrobble on trakt.tv")
    end
end

-- Query show
local function query_search_show(name, season, episode, config)
    local title, year = name:match("^(.-)%s*%(?(%d%d%d%d)%)?$")
    if year then name = title end
    local url = string.format("https://api.trakt.tv/search/show?query=%s", url_encode(name))
    res = http_request("GET", url, {
        ["trakt-api-key"] = config.client_id,
        ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        msg.info("No results found")
        return
    end

    if year then
        for _, item in ipairs(res) do
            if item.show.year == tonumber(year) then
                state.title = item.show.title
                state.slug = item.show.ids.slug
                state.id = item.show.ids.trakt
            end
        end
    else
        local show = res[1].show
        state.title = show.title
        state.slug = show.ids.slug
        state.id = show.ids.trakt
    end
    if not state.title then
        msg.info("No matching show found")
        return
    end

    mp.osd_message("Found on trakt.tv: " .. state.title .. " S" .. season .. "E" .. episode, 3)
    msg.info("Found on trakt.tv: " .. state.title .. " S" .. season .. "E" .. episode)

    season_res = http_request("GET", string.format("https://api.trakt.tv/shows/%s/seasons/%s",
    state.slug, season), {
            ["trakt-api-key"] = config.client_id,
            ["trakt-api-version"] = "2"
    })
    if not season_res then
        season = season - 1
    end

    ep_res = http_request("GET", string.format("https://api.trakt.tv/shows/%s/seasons/%s/episodes/%s",
        state.slug, season, episode), {
            ["trakt-api-key"] = config.client_id,
            ["trakt-api-version"] = "2"
    })
    if not ep_res then
        state.title = nil
        state.slug = nil
        state.id = nil
        msg.error("Failed to fetch episode details on trakt.tv")
        return
    end

    state.season = season
    state.episode = episode
end

-- Query movie
local function query_movie(movie, year, config)
    local url = string.format("https://api.trakt.tv/search/movie?query=%s", url_encode(movie))
    local res = http_request("GET", url, {
        ["trakt-api-key"] = config.client_id,
        ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        msg.info("No results found")
        return
    end
    for _, item in ipairs(res) do
        if item.movie.year == tonumber(year) then
            state.title = item.movie.title
            state.id = item.movie.ids.trakt
            mp.osd_message("Found: " .. state.title, 3)
            return
        end
    end
    msg.info("No matching movie found")
end

-- Query whatever
local function query_whatever(name, config)
    local url = string.format("https://api.trakt.tv/search/movie?query=%s", url_encode(name))
    local res = http_request("GET", url, {
        ["trakt-api-key"] = config.client_id,
        ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        msg.info("No results found")
        return
    end
    local movie = res[1].movie
    state.title = movie.title
    state.id = movie.ids.trakt
    mp.osd_message("Found: " .. state.title, 3)
end

-- Query media
local function query_media(config, media)
    local infos = { string.match(media, "^(.-)%s*[sS](%d+).*[eE](%d+).*") }
    if #infos == 3 then
        local name, season, episode = infos[1], infos[2], infos[3]
        query_search_show(name, season, episode, config)
    else
        infos = { string.match(media, "^(.-)%s*%(?(%d%d%d%d)%)?[^%dhHxXvVpPkKxXbBfF]") }
        if #infos == 2 then
            query_movie(infos[1], infos[2], config)
        else
            query_whatever(media, config)
        end
    end
end

-- Checkin function
local function checkin_file()
    local path = mp.get_property_native("path")
    local filename = mp.get_property_native("filename/no-ext")
    local title = mp.get_property_native("media-title"):gsub("%.[^%.]+$", "")
    local thin_space = string.char(0xE2, 0x80, 0x89)
    if not path then
        msg.info("No file loaded.")
        return
    end

    if is_protocol(path) then
        title = url_decode(title)
    elseif #title < #filename then
        title = filename
    end

    local video = mp.get_property_native("vid") and not mp.get_property_native("current-tracks/video/image") and
        not mp.get_property_native("current-tracks/video/albumart")
    if not video then return end

    state.duration = mp.get_property_number("duration", 0)

    local progress = get_progress()
    if not progress then return end

    title = title:gsub(thin_space, " ")
    title = format_filename(title)
    local media_title, season, episode = title:match("^(.-)%s*[sS](%d+)[eE](%d+)")
    if not season then
        local media_title, episode = title:match("^(.-)%s*[eE](%d+)")
        if episode then
            local dir = get_parent_dir(path)
            if dir then
                local season = dir:match("[sS](%d+)") or dir:match("[sS]eason%s*(%d+)")
                    or dir:match("(%d+)[nrdsth]+[_%.%s]%s*[sS]eason")
                if season then
                    title = media_title .. " S" .. season .. "E" .. episode
                else
                    title = media_title .. " S01" .. "E" .. episode
                end
            end
        end
    end

    local config = read_config()
    if not config then return end
    query_media(config, title)
    local data = get_data(progress)
    if data then
        mp.add_timeout(1, function()
            start_scrobble(config, data)
        end)
    end
end

-- Main function
local function on_file_start(event)
    if not o.enabled then return end

    state = {}
    local status = init()

    if status == 10 then
        send_message("[trakt] Please add your client_id and client_secret to config.json!", "0000FF", 4)
        msg.warn("Please add your client_id and client_secret to config.json!")
    elseif status == 11 then
        send_message("[trakt] Press X to authenticate with Trakt.tv", "FF8800", 4)
        mp.add_forced_key_binding("x", "auth-trakt", activation)
    elseif status == 0 then
        checkin_file()
    end
end

local function on_time_pos(_, value)
    state.pos = value
end

local function on_pause_change(paused)
    local config = read_config()
    if not config then return end
    local progress = get_progress()
    local data = get_data(progress)
    if data then
        if paused then
            stop_scrobble(config, data)
        else
            mp.add_timeout(1, function()
                start_scrobble(config, data)
            end)
        end
    end
end

local function on_pause_callback(_, paused)
    on_pause_change(paused)
end

-- Register event
mp.register_event("file-loaded", on_file_start)
mp.observe_property("pause", "bool", on_pause_callback)
mp.observe_property("time-pos", "number", on_time_pos)
mp.register_event("end-file", function()
    mp.unobserve_property(on_time_pos)
    mp.unobserve_property(on_pause_callback)
    on_pause_change(true)
    state = nil
end)