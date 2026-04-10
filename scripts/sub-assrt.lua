--[[
    * sub-assrt.lua
    *
    * AUTHORS: dyphire
    * License: MIT
    * link: https://github.com/dyphire/mpv-sub-assrt
]]

local utils = require "mp.utils"
local msg = require "mp.msg"
local options = require("mp.options")
local input_loaded, input = pcall(require, "mp.input")
local uosc_available = false

local o = {
    -- API token, 可以在 https://assrt.net 上注册账号后在个人界面获取
    api_token = "tNjXZUnOJWcHznHDyalNMYqqP6IdDdpQ",
    -- 是否使用 https
    use_https = true,
    -- 代理设置
    proxy = "",
}

options.read_options(o, _, function() end)

local ASSRT_SEARCH_API = (o.use_https and "https" or "http") .. "://api.assrt.net/v1/sub/search"
local ASSRT_DETAIL_API = (o.use_https and "https" or "http") .. "://api.assrt.net/v1/sub/detail"

local TEMP_DIR = os.getenv("TEMP") or "/tmp"
local cache = {}

local function is_protocol(path)
    return type(path) == 'string' and (path:find('^%a[%w.+-]-://') ~= nil or path:find('^%a[%w.+-]-:%?') ~= nil)
end

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
        str = str:gsub('^%a[%a%d-_]+://', '')
              :gsub('^%a[%a%d-_]+:\\?', '')
              :gsub('%%(%x%x)', hex_to_char)
        if str:find('://localhost:?') then
            str = str:gsub('^.*/', '')
        end
        str = str:gsub('%?.+', '')
              :gsub('%+', ' ')
        return str
    else
        return
    end
end

local function is_compressed_file(filename)
    local ext_map = {
        zip = true,
        rar = true,
        ["7z"] = true,
        gz = true,
        tar = true,
        bz2 = true,
        xz = true,
        tgz = true,
        tbz2 = true,
    }

    local ext = filename:match("%.([%w]+)$"):lower()
    if ext then
        return ext_map[ext] or false
    end
    return false
end

local function http_request(url)
    local cmd = {
        "curl",
        "-s",
        "-L",
        "--max-redirs", "5",
        "--connect-timeout", "10",
        "--max-time", "30",
        "--user-agent", "mpv",
        url
    }

    if o.proxy ~= "" then
        table.insert(cmd, '-x')
        table.insert(cmd, o.proxy)
    end

    local res = mp.command_native({ name = "subprocess", capture_stdout = true, capture_stderr = true, args = cmd })
    if res.status == 0 then
        return utils.parse_json(res.stdout)
    else
        msg.error("HTTP request failed: " .. res.stderr)
        return nil
    end
end

local function file_exists(path)
    if path then
        local meta = utils.file_info(path)
        return meta and meta.is_file
    end
    return false
end

local function alphanumsort(a, b)
    -- alphanum sorting for humans in Lua
    -- http://notebook.kulchenko.com/algorithms/alphanumeric-natural-sorting-for-humans-in-lua
    local function padnum(d)
        local dec, n = string.match(d, "(%.?)0*(.+)")
        return #dec > 0 and ("%.12f"):format(d) or ("%s%03d%s"):format(dec, #n, n)
    end
    return tostring(a):lower():gsub("%.?%d+", padnum) .. ("%3d"):format(#b)
         < tostring(b):lower():gsub("%.?%d+", padnum) .. ("%3d"):format(#a)
end

local function normalize(path)
    if normalize_path ~= nil then
        if normalize_path then
            path = mp.command_native({"normalize-path", path})
        else
            local directory = mp.get_property("working-directory", "")
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

local function check_sub(sub_file)
    local tracks = mp.get_property_native("track-list")
    local _, sub_title = utils.split_path(sub_file)
    for _, track in ipairs(tracks) do
        if track["type"] == "sub" and track["title"] == sub_title then
            return true, track["id"]
        end
    end
    return false, nil
end

local function append_sub(sub_file)
    local sub, id = check_sub(sub_file)
    if not sub then
        mp.commandv('sub-add', sub_file)
    else
        mp.commandv('sub-reload', id)
    end
end

local function clean_name(name)
    return name:gsub("^%[.-%]", " ")
           :gsub("^%(.-%)", " ")
           :gsub("[_%.%[%]]", " ")
           :gsub("^%s*(.-)%s*$", "%1")
           :gsub("[!@#%.%?%+%-%%&*_=,/~`]+$", "")
end

-- Formatters for media titles
local formatters = {
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d%d%d%d)[_%.%s]%d%d[_%.%s]%d%d%s*[_%.%s]?(.-)%s*[_%.%s]%d+[pPkKxXbBfF]",
        format = function(name, year, subtitle)
            local title = clean_name(name)
            if subtitle then
                title = title .. ": " .. subtitle:gsub("%.", " "):gsub("^%s*(.-)%s*$", "%1")
            end
            return title .. " (" .. year .. ")"
        end
    },
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d%d%d%d)%s*[_%.%s]%s*[sS](%d+)[%.%-%s:]?[eE](%d+%.?%d*)",
        format = function(name, year, season, episode)
            return clean_name(name) .. " (" .. year .. ") S" .. season .. "E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d%d%d%d)%s*[_%.%s]%s*[eEpP]+(%d+%.?%d*)",
        format = function(name, year, episode)
            return clean_name(name) .. " (" .. year .. ") E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[_%-%.%s]%s*[sS](%d+)[%.%-%s:]?[eE](%d+[%.v]?%d*)%s*[_%.%s]%s*(%d%d%d%d)[^%dhHxXvVpPkKxXbBfF]",
        format = function(name, season, episode, year)
            return clean_name(name) .. " (" .. year .. ") S" .. season .. "E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[_%-%.%s]%s*[sS](%d+)[%.%-%s:]?[eE](%d+%.?%d*)",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. season .. "E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d+)[nrdsth]+[_%.%s]%s*[sS]eason[_%.%s]%s*%[(%d+[%.v]?%d*)%]",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. season .. "E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[^dD][eEpP]+(%d+[%.v]?%d*)[_%.%s]%s*(%d%d%d%d)[^%dhHxXvVpPkKxXbBfF]",
        format = function(name, episode, year)
            return clean_name(name) .. " (" .. year .. ") E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[^dD][eEpP]+(%d+%.?%d*)",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode
        end
    },
    {
        regex = "^(.-)%s*第%s*(%d+[%.v]?%d*)%s*[话回集]",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*%[(%d+[%.v]?%d*)%]",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*%[(%d+[%.v]?%d*)%(%a+%)%]",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[%-#]%s*(%d+%.?%d*)%s*",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[%[%(]([OVADSPs]+)[%]%)]",
        format = function(name, sp)
            return clean_name(name) .. " [" .. sp .. "]"
        end
    },
    {
        regex = "^(.-)%s*[_%-%.%s]%s*(%d?%d)x(%d%d?%d?%d?)[^%dhHxXvVpPkKxXbBfF]",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. season .. "E" .. episode
        end
    },
    {
        regex = "^%((%d%d%d%d)%.?%d?%d?%.?%d?%d?%)%s*(.-)%s*[%(%[]",
        format = function(year, name)
            return clean_name(name) .. " (" .. year .. ")"
        end
    },
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d%d%d%d)[^%dhHxXvVpPkKxXbBfF]",
        format = function(name, year)
            return clean_name(name) .. " (" .. year .. ")"
        end
    },
    {
        regex = "^%[.-%]%s*%[?(.-)%]?%s*[%(%[]",
        format = function(name)
            return clean_name(name)
        end
    },
}

local function format_filename(title)
    for _, formatter in ipairs(formatters) do
        local matches = {title:match(formatter.regex)}
        if #matches > 0 then
            title = formatter.format(unpack(matches))
            return title
        end
    end
    title = title:gsub("^%[.-%]", " ")
        :gsub("^%(.-%)", " ")
        :gsub("[_%.]", " ")
        :gsub("^%s*(.-)%s*$", "%1")
        :gsub("[!@#%.%?%+%-%%&*_=,/~`]+$", "")
    return title
end

local function is_writable(path)
    local file = io.open(path, "w")
    if file then
        file:close()
        os.remove(path)
        return true
    end
    return false
end

local function download_file(url, fname)
    local path = mp.get_property("path")
    local filename = mp.get_property("filename/no-ext")
    local ext = fname:match('%.([^%.]+)$'):lower()

    if is_protocol(path) then
        sub_path = utils.join_path(TEMP_DIR, fname)
    else
        local dir = utils.split_path(normalize(path))
        sub_path = utils.join_path(dir, filename .. ".assrt." .. ext)
        if not is_writable(sub_path) then
            sub_path = utils.join_path(TEMP_DIR, fname)
        end
    end

    local message = "正在下载字幕..."
    local type = "download_subtitle"
    local title = "字幕下载菜单"
    local footnote = "使用 / 打开筛选"
    if uosc_available then
        update_menu_uosc(type, title, message, footnote)
    else
        mp.osd_message(message)
    end

    local cmd = {"curl", "-s", "--user-agent", "mpv", "-o", sub_path, url}
    if o.proxy ~= "" then
        table.insert(cmd, '-x')
        table.insert(cmd, o.proxy)
    end
    local res = mp.command_native({ name = "subprocess", capture_stdout = true, capture_stderr = true, args = cmd })
    if res.status == 0 then
        if file_exists(sub_path) then
            append_sub(sub_path)
            local message = "字幕下载完成, 已载入"
            if uosc_available then
                update_menu_uosc(type, title, message, footnote)
                -- 下载完字幕1.5秒后关闭面板
                mp.add_timeout(1.5, function()
                    mp.commandv("script-message-to", "uosc", "close-menu", "download_subtitle")
                end)
            else
                mp.osd_message(message, 3)
            end
            msg.info("Subtitle downloaded: " .. sub_path)
        end
    else
        local message = "字幕下载失败，查看控制台获取更多信息"
        if uosc_available then
            update_menu_uosc(type, title, message, footnote)
        else
            mp.osd_message(message, 3)
        end
        msg.error("Failed to download file: " .. res.stderr)
        return nil
    end
end

local function fetch_subtitle_details(sub_id)
    local message = "正在加载字幕详细信息..."
    local type = "subtitle_details"
    local title = "字幕下载菜单"
    local footnote = "使用 / 打开筛选"
    if uosc_available then
        update_menu_uosc(type, title, message, footnote)
    else
        mp.osd_message(message)
    end

    local url = ASSRT_DETAIL_API .."?token=" .. o.api_token .. "&id=" .. (sub_id or 0)
    local res = http_request(url)
    if not res or res.status ~= 0 then
        local message = "获取字幕详细信息失败，查看控制台获取更多信息"
        if uosc_available then
            update_menu_uosc(type, title, message, footnote)
        else
            mp.osd_message(message, 3)
        end
        msg.error("Failed to fetch subtitle details: " .. (res and res.errmsg or "Unknown error"))
        return nil
    end

    local items = {}
    items[#items + 1] = {
        title = "..",
        hint = "返回搜索结果",
        value = {
            "script-message-to",
            mp.get_script_name(),
            "search-subtitles-event",
            "has_details", nil,
        },
    }
    local subs = res.sub.subs[1]
    for _, sub in ipairs(subs.filelist) do
        table.insert(items, {
            title = sub.f,
            hint = sub.s,
            value = {
                "script-message-to",
                mp.get_script_name(),
                "download-file-event",
                sub.url, sub.f,
            },
        })
    end

    if #items > 2 then
        table.sort(items, function(a, b)
            return alphanumsort(a.title, b.title)
        end)
    end

    if #items == 0 and subs.url and not is_compressed_file(subs.filename) then
        local size= subs.size / 1024
        local sub_size = size > 1024 and string.format("%.2fMB", size / 1024) or string.format("%.2fKB", size)
        table.insert(items, {
            title = subs.filename,
            hint = sub_size,
            value = {
                "script-message-to",
                mp.get_script_name(),
                "download-file-event",
                subs.url,  subs.filename,
            },
        })
    end

    if uosc_available then
        update_menu_uosc(type, title, items, footnote)
    elseif input_loaded then
        mp.osd_message("")
        mp.add_timeout(0.1, function()
            open_menu_select(items)
        end)
    end
end

local function search_subtitles(pos, query)
    local items = {}
    local type = "menu_subtitle"
    local title = "输入搜索内容"
    local footnote = "使用enter或ctrl+enter进行搜索"
    if pos ~= "has_details" and (query ~= cache.query or tonumber(pos) > 0) then
        local pos = tonumber(pos)
        local message = "正在搜索字幕..."
        local cmd = { "script-message-to", mp.get_script_name(), "search-subtitles-event", tostring(pos) }
        if uosc_available then
            update_menu_uosc(type, title, message, footnote, cmd, query)
        else
            mp.osd_message(message)
        end

        local url = ASSRT_SEARCH_API .. "?token=" .. o.api_token .. "&q=" .. url_encode(query) .. "&no_muxer=1&pos=" .. pos
        local res = http_request(url)
        if not res or res.status ~= 0 then
            local message = "搜索字幕失败，查看控制台获取更多信息"
            if uosc_available then
                update_menu_uosc(type, title, message, footnote, cmd, query)
            else
                mp.osd_message(message, 3)
            end
            msg.error("Failed to search subtitles: " .. (res and res.errmsg or "Unknown error"))
            return nil
        end

        local sub = res.sub
        local subs = {}
        if sub then subs = res.sub.subs end
        if #subs == 0 then
            local message = "未找到字幕，建议更改关键字尝试重新搜索"
            if uosc_available then
                update_menu_uosc(type, title, message, footnote, cmd, query)
            else
                mp.osd_message(message, 3)
            end
            msg.info("No subtitles found.")
            return nil
        end

        table.insert(items, {
            title = "..",
            hint = "返回搜索菜单",
            value = {
                "script-message-to",
                mp.get_script_name(),
                "open-search-menu",
                0, query,
            },
        })

        for _, sub in ipairs(subs) do
            table.insert(items, {
                title = sub.video_chinese_name and sub.video_chinese_name ~= '' and sub.video_chinese_name
                    or sub.native_name and sub.native_name ~= '' and sub.native_name or sub.videoname,
                hint = sub.lang and sub.lang.desc ~= '' and sub.lang.desc
                    or sub.m_lang and sub.m_lang ~= '' and sub.m_lang:gsub("&nbsp;", " "),
                value = {
                    "script-message-to",
                    mp.get_script_name(),
                    "fetch-details-event",
                    sub.id or sub.fileid,
                },
            })
        end

        if #items == 16 then
            pos = pos + 15
            table.insert(items, {
                title = "加载下一页",
                value = {
                    "script-message-to",
                    mp.get_script_name(),
                    "search-subtitles-event",
                    tostring(pos), query,
                },
                italic = true,
                bold = true,
                align = "center",
            })
        end
        cache.query = query
        cache.items = items
    else
        items = cache.items
    end

    if uosc_available then
        update_menu_uosc(type, title, items, footnote)
    elseif input_loaded then
        mp.osd_message("")
        mp.add_timeout(0.1, function()
            open_menu_select(items)
        end)
    end
end

function open_menu_select(menu_items)
    local item_titles, item_values = {}, {}
    for i, v in ipairs(menu_items) do
        item_titles[i] = v.hint and v.title .. " (" .. v.hint .. ")" or v.title
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

function open_input_menu_get(pos, query)
    mp.commandv('script-message-to', 'console', 'disable')
    input.get({
        prompt = '搜索字幕:',
        default_text = query,
        cursor_position = query and #query + 1,
        submit = function(text)
            input.terminate()
            search_subtitles(pos, text)
        end
    })
end

function open_input_menu_uosc(pos, query)
    local menu_props = {
        type = "menu_subtitle",
        title = "输入搜索内容",
        search_style = "palette",
        search_debounce = "submit",
        search_suggestion = query,
        on_search = {
            "script-message-to",
            mp.get_script_name(),
            "search-subtitles-event",
            tostring(pos),
        },
        footnote = "使用enter或ctrl+enter进行搜索",
        items = {},
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

local function sub_assrt()
    local path = mp.get_property("path")
    local filename = mp.get_property("filename/no-ext")
    local title = mp.get_property("media-title")
    local thin_space = string.char(0xE2, 0x80, 0x89)
    if not path then
        msg.error("No file loaded.")
        return
    end

    if is_protocol(path) then
        title = url_decode(title:gsub('%.[^%.]+$', ''))
    elseif #title < #filename then
        title = filename
    end

    local pos = 0
    local title = title:gsub(thin_space, " ")
    local query = format_filename(title):gsub("%s*E%d+$", "")

    if cache.title and cache.title == query
    and cache.items and #cache.items > 0 then
        search_subtitles("has_details")
        return
    end

    cache.title = query

    if uosc_available then
        open_input_menu_uosc(pos, query)
    elseif input_loaded then
        open_input_menu_get(pos, query)
    end
end

mp.register_script_message('uosc-version', function()
    uosc_available = true
    mp.commandv('script-message-to', 'uosc', 'overwrite-binding', 'download-subtitles',
    'script-message-to  sub_assrt sub-assrt')
end)

mp.register_script_message("open-search-menu", function(pos, query)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "open-menu", "menu_subtitle")
    end
    if uosc_available then
        open_input_menu_uosc(pos, query)
    elseif input_loaded then
        open_input_menu_get(pos, query)
    end
end)

mp.register_script_message("search-subtitles-event", function(pos, query)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "open-menu", "menu_subtitle")
    end
    search_subtitles(pos, query)
end)
mp.register_script_message("fetch-details-event", function(query)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "open-menu", "subtitle_details")
    end
    fetch_subtitle_details(query)
end)
mp.register_script_message("download-file-event", function(url, filename)
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "open-menu", "download_subtitle")
    end
    download_file(url, filename)
end)

mp.register_script_message("sub-assrt", sub_assrt)
