
--[[
    * trakt-scrobble.lua
    *
    * AUTHORS: dyphire
    * License: MIT
    * link: https://github.com/dyphire/trakt-scrobble
]]


local msg = require "mp.msg"
local utils = require "mp.utils"
local options = require "mp.options"
input_available, input = pcall(require, "mp.input")
uosc_available = false

o = {
    enabled = true,
    -- Set to '~~/trakt_config.json' for sub path of mpv portable_config directory
    -- OR change to '/:dir%script%/trakt_config.json' for placing it in the same directory of script
    -- OR write any variable using '/:var',
    -- such as: '/:var%APPDATA%/mpv/trakt_config.json' or '/:var%HOME%/mpv/trakt_config.json'
    congfig_path = "~~/trakt_config.json",
    history_path = "~~/trakt_history.json",
    --slice long filenames, and how many chars to show
    max_title_length = 100,
    -- https://trakt.tv/oauth/applications
    client_id = "MmU5ZDg5MDcyYmIxNThlZWZhZmNlNTA5ZjZiMWJmMzM3MzcwMTQwMDU4ODFlZGZiYjgzZWI3ZGRkMWMwNGY1YQ==",
    client_secret = "MDcxYTUzZTVkZDhkODA1NTM2MTU2YWNlZTJjYjU5Njc5YjUwOTAwZWU3YmZkYmVmMTZiNGZmODdkMzQ2NGFiNg=="
}

options.read_options(o, _, function() end)

state = {}
enabled = o.enabled
local scrobble = false

base64 = require("modules/base64")
require('modules/guess')
require('modules/menu')

local function expand_path(path)
    if path:find('^/:dir%%script%%') then
        path = path:gsub('/:dir%%script%%', mp.get_script_directory())
    elseif path:find('/:var%%(.*)%%') then
        local os_variable = path:match('/:var%%(.*)%%')
        path = path:gsub('/:var%%(.*)%%', os.getenv(os_variable))
    else
        path = mp.command_native({ "expand-path", path }) -- Expands both ~ and ~~
    end
    return path
end

local config_file = expand_path(o.congfig_path)
local history_path = expand_path(o.history_path)

-- Check if the path is a protocol (e.g., http://)
local function is_protocol(path)
    return type(path) == "string" and (path:find("^%a[%w.+-]-://") ~= nil or path:find("^%a[%w.+-]-:%?") ~= nil)
end

-- URL decode function
local function hex_to_char(x)
    return string.char(tonumber(x, 16))
end

function url_encode(str)
    if str then
        str = str:gsub("([^%w%-%.%_%~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
    end
    return str
end

function url_decode(str)
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

-- from http://lua-users.org/wiki/LuaUnicode
local UTF8_PATTERN = '[%z\1-\127\194-\244][\128-\191]*'

-- return a substring based on utf8 characters
-- like string.sub, but negative index is not supported
local function utf8_sub(s, i, j)
    if i > j then
        return s
    end

    local t = {}
    local idx = 1
    for char in s:gmatch(UTF8_PATTERN) do
        if i <= idx and idx <= j then
            local width = #char > 2 and 2 or 1
            idx = idx + width
            t[#t + 1] = char
        end
    end
    return table.concat(t)
end

function clip_title(title)
    if not title then
        return title
    end
    local title_clip = utf8_sub(title, 1, o.max_title_length)
    if title ~= title_clip then
        title = title_clip .. "..."
    end
    return title
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

local function split_by_numbers(filename)
    local parts = {}
    local pattern = "([^%d]*)(%d+)([^%d]*)"
    for pre, num, post in string.gmatch(filename, pattern) do
        table.insert(parts, {pre = pre, num = tonumber(num), post = post})
    end
    return parts
end

local function compare_filenames(fname1, fname2)
    local parts1 = split_by_numbers(fname1)
    local parts2 = split_by_numbers(fname2)

    local min_len = math.min(#parts1, #parts2)

    for i = 1, min_len do
        local part1 = parts1[i]
        local part2 = parts2[i]

        if part1.pre ~= part2.pre then
            return false
        end

        if part1.num ~= part2.num then
            return part1.num, part2.num
        end

        if part1.post ~= part2.post then
            return false
        end
    end

    return false
end

local function get_episode_number(fname, filename)
    local episode_num1, episode_num2 = compare_filenames(fname, filename)
    if episode_num1 and episode_num2 then
        return tonumber(episode_num1), tonumber(episode_num2)
    else
        return nil, nil
    end
end

local function parse_title(path)
    local dir = get_parent_dir(path)
    local filename = mp.get_property_native("filename/no-ext")
    local title = mp.get_property_native("media-title"):gsub("%.[^%.]+$", "")
    local thin_space = string.char(0xE2, 0x80, 0x89)
    local fname = filename

    if is_protocol(path) then
        title = url_decode(title)
        fname = title
    elseif #title < #filename then
        title = filename
    end

    title = title:gsub(thin_space, " ")
    title = format_filename(title)
    local media_title, season, episode = title:match("^(.-)%s*[sS](%d+)[eE](%d+)")
    if not season then
        local media_title, episode = title:match("^(.-)%s*[eE](%d+)")
        if episode and dir then
            local season = dir:match("[sS](%d+)") or dir:match("[sS]eason%s*(%d+)")
                or dir:match("(%d+)[nrdsth]+[_%.%s]%s*[sS]eason")
            if season then
                title = media_title .. " S" .. season .. "E" .. episode
            else
                title = media_title .. " S01" .. "E" .. episode
            end
        end
    end

    if not dir then
        if season then
            dir = title .. " S" .. season
        else
            dir = title
        end
    end

    return dir, fname, title
end

local function format_message(msg, color)
    local ass_start = mp.get_property_osd("osd-ass-cc/0")
    local ass_stop = mp.get_property_osd("osd-ass-cc/1")
    return ass_start .. "{\\1c&H" .. color .. "&}" .. msg .. ass_stop
end

-- Send a message to the OSD
local function send_message(msg, color, time)
    local msg = format_message(msg, color)
    mp.osd_message(msg, time)
end

-- Read config file
local function read_config(file_path)
    local file = io.open(file_path, "r")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return utils.parse_json(content)
end

config = read_config(config_file)

-- Write config file
local function write_config(file_path, data)
    local file = io.open(file_path, "w")
    if not file then
        return
    end
    file:write(utils.format_json(data))
    file:close()
end

-- Write history file
function write_history(dir, fname)
    local history = read_config(history_path) or {}
    if not state.id then return end
    history[dir] = {}
    history[dir].fname = fname
    history[dir].type = state.type
    history[dir].title = state.title
    history[dir].id = state.id
    if state.season and state.episode then
        history[dir].season = state.season
        history[dir].episode = state.episode
    end
    write_config(history_path, history)
end

-- Send HTTP request using curl
function http_request(method, url, headers, body)
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
    config = read_config(config_file)
    if not config then
        return 10
    end
    if not o.client_id or not o.client_secret
    or #base64.decode(o.client_id) ~= 64 or #base64.decode(o.client_secret) ~= 64 then
        return 10
    end
    if not config.access_token or #base64.decode(config.access_token) ~= 64 then
        return 11
    end
    return 0
end

-- Generate device code
local function device_code()
    config = read_config(config_file)
    if not config then
        return -1
    end
    local res = http_request("POST", "https://api.trakt.tv/oauth/device/code", {
        ["Content-Type"] = "application/json"
    }, {
        client_id = base64.decode(o.client_id)
    })
    if not res then
        return -1
    end
    config.device_code = res.device_code
    write_config(config_file, config)
    return 0, res.user_code
end

-- Authenticate with device code
local function auth()
    config = read_config(config_file)
    if not config then
        return -1
    end
    local res = http_request("POST", "https://api.trakt.tv/oauth/device/token", {
        ["Content-Type"] = "application/json"
    }, {
        client_id = base64.decode(o.client_id),
        client_secret = base64.decode(o.client_secret),
        code = config.device_code
    })
    if not res or not res.access_token then
        return -1
    end
    config.access_token = base64.encode(res.access_token)
    config.refresh_token  = base64.encode(res.refresh_token)
    config.device_code = nil
    config.today = os.date("%Y-%m-%d")

    -- Get user info
    local user_res = http_request("GET", "https://api.trakt.tv/users/settings", {
        ["trakt-api-key"] = base64.decode(o.client_id),
        ["Authorization"] = "Bearer " .. base64.decode(config.access_token),
        ["trakt-api-version"] = "2"
    })
    if not user_res or not user_res.user then
        return -1
    end
    config.user_slug = user_res.user.ids.slug
    write_config(config_file, config)
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

-- Refresh access_token with refresh_token
local function refresh_token(config)
    local res = http_request("POST", "https://api.trakt.tv/oauth/token", {
        ["Content-Type"] = "application/json"
    }, {
        client_id = base64.decode(o.client_id),
        client_secret = base64.decode(o.client_secret),
        refresh_token = base64.decode(config.refresh_token),
        grant_type = "refresh_token"
    })

    if not res or not res.access_token then
        msg.error("Failed to refresh access token.")
        return -1
    end

    config.access_token = base64.encode(res.access_token)
    config.refresh_token = base64.encode(res.refresh_token)
    config.today = os.date("%Y-%m-%d")

    write_config(config_file, config)

    msg.info("Successfully refreshed access token.")
    return 0
end

-- Check if access_token is expired
local function check_access_token(config)
    if not config or not config.access_token or not config.refresh_token then
        return -1
    end

    local res = http_request("GET", "https://api.trakt.tv/users/settings", {
        ["trakt-api-key"] = base64.decode(o.client_id),
        ["Authorization"] = "Bearer " .. base64.decode(config.access_token),
        ["trakt-api-version"] = "2"
    })

    if not res then
        msg.warn("Access token might be expired, attempting to refresh.")
        return refresh_token(config)
    end

    return 0
end

function get_progress()
    if not state then return end
    local time_pos = state.pos or 0
    local duration = state.duration or 0

    if duration == 0 then
        return
    end

    local progress = (tonumber(time_pos) / tonumber(duration)) * 100
    return math.floor(progress)
end

function get_data(progress)
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

function start_scrobble(config, data, no_osd)
    msg.info("Starting scrobbling to Trakt.tv")
    local res = http_request("POST", "https://api.trakt.tv/scrobble/start", {
        ["Content-Type"] = "application/json",
        ["trakt-api-key"] = base64.decode(o.client_id),
        ["Authorization"] = "Bearer " .. config.access_token and base64.decode(config.access_token),
        ["trakt-api-version"] = "2"
    }, data)
    if not res then
        send_message("Unable to scrobble ", "0000FF", 3)
        msg.error("Check-in failed")
        return
    end
    local message = nil
    if state and state.title then
        if state.season and state.episode then
            message = "Scrobbling on trakt.tv: " .. state.title .. " S" .. state.season .. "E" .. state.episode
        else
            message = "Scrobbling on trakt.tv: " .. state.title
        end
        if (input_available or uosc_available) and not no_osd then
            mp.add_forced_key_binding("x", "search-trakt", function()
                mp.osd_message("")
                open_input_menu(state.filename)
                stop_scrobble(config, data)
            end)
            local message1 = format_message(message, "00FF00")
            local message2 = format_message("Incorrect scrobble? Press x to open the search menu", "FF8800")
            mp.osd_message(message1 .. "\n" .. message2, 9)
            msg.info(message)
        elseif not no_osd then
            send_message(message, "00FF00", 3)
            msg.info(message)
        else
            msg.info(message)
        end
        scrobble = true
    end
end

function stop_scrobble(config, data)
    msg.info("Stopping scrobbling to Trakt.tv")
    local res = http_request("POST", "https://api.trakt.tv/scrobble/stop", {
        ["Content-Type"] = "application/json",
        ["trakt-api-key"] = base64.decode(o.client_id),
        ["Authorization"] = "Bearer " .. config.access_token and base64.decode(config.access_token),
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
    scrobble = false
end

-- Query show
local function query_search_show(name, season, episode)
    local title, year = name:match("^(.-)%s*%(?(%d%d%d%d)%)?$")
    if year then name = title end
    local url = string.format("https://api.trakt.tv/search/show?query=%s", url_encode(name))
    res = http_request("GET", url, {
        ["trakt-api-key"] = base64.decode(o.client_id),
        ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        msg.info("No results found")
        return
    end

    if year then
        for _, item in ipairs(res) do
            if item.show.year == tonumber(year) or item.show.year == tonumber(year) + 1
            or item.show.year == tonumber(year) - 1 then
                state.type = "show"
                state.title = item.show.title
                state.slug = item.show.ids.slug
                state.id = item.show.ids.trakt
            end
        end
    else
        local show = res[1].show
        state.type = "show"
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
            ["trakt-api-key"] = base64.decode(o.client_id),
            ["trakt-api-version"] = "2"
    })
    if not season_res then
        season = season - 1
    end

    ep_res = http_request("GET", string.format("https://api.trakt.tv/shows/%s/seasons/%s/episodes/%s",
        state.slug, season, episode), {
            ["trakt-api-key"] = base64.decode(o.client_id),
            ["trakt-api-version"] = "2"
    })
    if not ep_res then
        state.type = nil
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
local function query_movie(movie, year)
    local url = string.format("https://api.trakt.tv/search/movie?query=%s", url_encode(movie))
    local res = http_request("GET", url, {
        ["trakt-api-key"] = base64.decode(o.client_id),
        ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        msg.info("No results found")
        return
    end
    for _, item in ipairs(res) do
        if item.movie.year == tonumber(year) or item.movie.year == tonumber(year) + 1
            or item.movie.year == tonumber(year) - 1 then
            state.type = "movie"
            state.title = item.movie.title
            state.id = item.movie.ids.trakt
            mp.osd_message("Found: " .. state.title, 3)
            return
        end
    end
    msg.info("No matching movie found")
end

-- Query whatever
local function query_whatever(name)
    local url = string.format("https://api.trakt.tv/search/movie?query=%s", url_encode(name))
    local res = http_request("GET", url, {
        ["trakt-api-key"] = base64.decode(o.client_id),
        ["trakt-api-version"] = "2"
    })
    if not res or #res == 0 then
        msg.info("No results found")
        return
    end
    local movie = res[1].movie
    state.type = "movie"
    state.title = movie.title
    state.id = movie.ids.trakt
    mp.osd_message("Found: " .. state.title, 3)
end

-- Query media
local function query_media(config, media)
    local infos = { string.match(media, "^(.-)%s*[sS](%d+).*[eE](%d+).*") }
    if #infos == 3 then
        local name, season, episode = infos[1], infos[2], infos[3]
        query_search_show(name, season, episode)
    else
        infos = { string.match(media, "^(.-)%s*%(?(%d%d%d%d)%)?[^%dhHxXvVpPkKxXbBfF]") }
        if #infos == 2 then
            query_movie(infos[1], infos[2])
        else
            query_whatever(media)
        end
    end
end

-- Checkin function
local function checkin_file(path)
    config = read_config(config_file)
    if not config then return end

    state.duration = mp.get_property_number("duration", 0)
    local progress = get_progress()
    if not progress then return end

    local dir, fname, title  = parse_title(path)
    state.dir = dir
    state.fname = fname
    state.filename = title

    local history = read_config(history_path) or {}
    if history[dir] then
        local old_fname = history[dir].fname
        local old_type = history[dir].type
        local old_title = history[dir].title
        local old_id = history[dir].id
        local old_season = history[dir].season
        local old_episode = history[dir].episode
        local episode_num1, episode_num2 = get_episode_number(old_fname, fname)
        if fname == old_fname then
            episode_num1, episode_num2 = 0, 0
        end
        if episode_num1 and episode_num2 then
            if old_type == "show" and old_season and old_episode then
                state.type = old_type
                state.title = old_title
                state.id = old_id
                state.season = old_season
                state.episode = old_episode + episode_num2 - episode_num1
                mp.osd_message("Found on trakt.tv: " .. state.title .. " S" .. state.season .. "E" .. state.episode, 3)
                msg.info("Found on trakt.tv: " .. state.title .. " S" .. state.season .. "E" .. state.episode)
            end
        end
    end

    if not state.id then
        query_media(config, title)
    end
    local data = get_data(progress)
    if data then
        mp.add_timeout(1, function()
            start_scrobble(config, data)
        end)
    elseif (input_available or uosc_available) then
        local message = format_message("Automatic parsing of media titles failed.\n Press x to open the search menu", "FF8800")
        mp.osd_message(message, 5)
        mp.add_forced_key_binding("x", "search-trakt", function()
            mp.osd_message("")
            open_input_menu(state.filename)
            stop_scrobble(config, data)
        end)
    end
    write_history(dir, fname)
end

-- Main function
local function trackt_scrobble(force)
    if not o.enabled and not force then
        return
    end

    local path = mp.get_property_native("path")
    if not path then
        return
    end

    local video = mp.get_property_native("current-tracks/video")
    local fps = mp.get_property_number("container-fps", 0)
    local duration = mp.get_property_number("duration", 0)
    if not video or video["image"] or video["albumart"] or fps < 23 or duration < 60 then
        return
    end

    local status = init()
    config = read_config(config_file)

    if status == 10 then
        send_message("[trakt] Please make sure you have set client_id and client_secret correctly!", "0000FF", 4)
        msg.warn("Please make sure you have set client_id and client_secret correctly!")
    elseif status == 11 then
        send_message("[trakt] Press X to authenticate with Trakt.tv", "FF8800", 4)
        mp.add_forced_key_binding("x", "auth-trakt", activation)
    elseif status == 0 then
        msg.info("Checking Trakt.tv authentication status.")
        if check_access_token(config) ~= 0 then
            send_message("Authentication failed. Please re-login.", "FF0000", 5)
            return
        end
        checkin_file(path)
    end
end

function on_time_pos(_, value)
    state.pos = value
end

function on_pause_change(paused)
    if not enabled then return end
    if not config then return end
    local progress = get_progress()
    local data = get_data(progress)
    if data then
        if paused then
            stop_scrobble(config, data)
        else
            mp.add_timeout(1, function()
                start_scrobble(config, data, true)
            end)
        end
    end
end

function on_pause_callback(_, paused)
    on_pause_change(paused)
end

-- Register event
mp.register_script_message('uosc-version', function()
    uosc_available = true
end)

mp.register_event("file-loaded", function()
    state = {}
    mp.observe_property("pause", "bool", on_pause_callback)
    mp.observe_property("time-pos", "number", on_time_pos)
    trackt_scrobble(enabled)
end)

mp.register_event("end-file", function()
    mp.unobserve_property(on_time_pos)
    mp.unobserve_property(on_pause_callback)
    on_pause_change(true)
    state = nil
end)

mp.register_script_message("search-menu", function()
    config = read_config(config_file)
    if not config then
        mp.osd_message("Failed to read config file", 3)
        msg.error("Failed to read config file")
        return
    end

    local path = mp.get_property_native("path")
    if not state.dir or not state.fname or not state.filename then
        local dir, fname, title  = parse_title(path)
        state.dir = dir
        state.fname = fname
        state.filename = title
    end
    local title = state.filename or ""
    open_input_menu(title)
end)

mp.register_script_message("toggle-scrobble", function()
    if scrobble then
        mp.osd_message("Trakt scrobbling disabled", 3)
        msg.info("Trakt scrobbling disabled")
        on_pause_change(true)
        enabled = false
    else
        enabled = true
        trackt_scrobble(enabled)
    end
end)