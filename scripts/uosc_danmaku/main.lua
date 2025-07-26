local msg = require('mp.msg')
local utils = require("mp.utils")

pid = utils.getpid()
danmaku = {sources = {}, count = 1}
delay_property = string.format("user-data/%s/danmaku-delay", mp.get_script_name())

AES = require("modules/aes")
Base64 = require("modules/base64")
MD5 = require("modules/md5")
Sha256 = require("modules/hash")

require("modules/options")
require("modules/utils")
require("modules/parse")
require("modules/guess")
require('modules/render')
require('modules/menu')

require("apis/dandanplay")
require('apis/extra')

danmaku_path = os.getenv("TEMP") or "/tmp/"
history_path = mp.command_native({"expand-path", options.history_path})

KEY = table_to_zero_indexed({
    0x00,0x01,0x02,0x03,0x04,
    0x05,0x06,0x07,0x08,0x09,
    0x0a,0x0b,0x0c,0x0d,0x0e,
    0x0f,0x10,0x11,0x12,0x13,
    0x14,0x15,0x16,0x17,0x18,
    0x19,0x1a,0x1b,0x1c,0x1d,
    0x1e,0x1f
})

platform = (function()
    local platform = mp.get_property_native("platform")
    if platform then
        if itable_index_of({ "windows", "darwin" }, platform) then
            return platform
        end
    else
        if os.getenv("windir") ~= nil then
            return "windows"
        end
        local homedir = os.getenv("HOME")
        if homedir ~= nil and string.sub(homedir, 1, 6) == "/Users" then
            return "darwin"
        end
    end
    return "linux"
end)()

function get_danmaku_visibility()
    local history_json = read_file(history_path)
    local history
    if history_json ~= nil then
        history = utils.parse_json(history_json)
        local flag = history["show_danmaku"]
        if flag == nil then
            history["show_danmaku"] = false
            write_json_file(history_path, history)
        else
            return flag
        end
    else
        history = {}
        history["show_danmaku"] = false
        write_json_file(history_path, history)
    end
    return false
end

function set_danmaku_visibility(flag)
    local history = {}
    local history_json = read_file(history_path)
    if history_json ~= nil then
        history = utils.parse_json(history_json)
    end
    history["show_danmaku"] = flag
    write_json_file(history_path, history)
end

function set_danmaku_button()
    if get_danmaku_visibility() then
        mp.commandv("script-message-to", "uosc", "set", "show_danmaku", "on")
    end
end

function show_loaded(init)
    if danmaku.anime and danmaku.episode then
        show_message("匹配内容：" .. danmaku.anime .. "-" .. danmaku.episode .. "\\N弹幕加载成功，共计" .. #comments .. "条弹幕", 3)
        if init then
            msg.info(danmaku.anime .. "-" .. danmaku.episode .. " 弹幕加载成功，共计" .. #comments .. "条弹幕")
        end
    else
        show_message("弹幕加载成功，共计" .. #comments .. "条弹幕", 3)
    end
end

local function get_cid()
    local cid, danmaku_id = nil, nil
    local tracks = mp.get_property_native("track-list")
    for _, track in ipairs(tracks) do
        if track["lang"] == "danmaku" then
            cid = track["external-filename"]:match("/(%d-)%.xml$")
            danmaku_id = track["id"]
            break
        end
    end
    return cid, danmaku_id
end

local function extract_between_colons(input_string)
    local start_index = 0
    local end_index = 0
    local count = 0
    for i = 1, #input_string do
        if input_string:sub(i, i) == ":" then
            count = count + 1
            if count == 2 then
                start_index = i
            elseif count == 3 then
                end_index = i
                break
            end
        end
    end
    if start_index > 0 and end_index > 0 then
        return input_string:sub(start_index + 1, end_index - 1)
    else
        return nil
    end
end

local function hex_to_int_color(hex_color)
    -- 移除颜色代码中的'#'字符
    hex_color = hex_color:sub(2)  -- 只保留颜色代码部分

    -- 提取R, G, B的十六进制值并转为整数
    local r = tonumber(hex_color:sub(1, 2), 16)
    local g = tonumber(hex_color:sub(3, 4), 16)
    local b = tonumber(hex_color:sub(5, 6), 16)

    -- 计算32位整数值
    local color_int = (r * 256 * 256) + (g * 256) + b

    return color_int
end

local function get_type_from_position(position)
    if position == 0 then
        return 1
    end
    if position == 1 then
        return 4
    end
    return 5
end

function write_history(episodeid)
    local history = {}
    local path = mp.get_property("path")
    local dir = get_parent_directory(path)
    local fname = mp.get_property('filename/no-ext')
    local episodeNumber = 0
    if episodeid then
        episodeNumber = tonumber(episodeid) % 1000
    elseif danmaku.extra then
        episodeNumber = danmaku.extra.episodenum
    end

    if is_protocol(path) then
        local title, season_num, episod_num = parse_title()
        if title and episod_num then
            if season_num then
                dir = title .." Season".. season_num
            else
                dir = title
            end
            fname = url_decode(mp.get_property("media-title"))
            episodeNumber = episod_num
        end
    end

    if dir ~= nil then
        local history_json = read_file(history_path)
        if history_json ~= nil then
            history = utils.parse_json(history_json) or {}
        end
        history[dir] = {}
        history[dir].fname = fname
        history[dir].source = danmaku.source
        history[dir].animeTitle = danmaku.anime
        history[dir].episodeTitle = danmaku.episode
        history[dir].episodeNumber = episodeNumber
        if episodeid then
            history[dir].episodeId = episodeid
        elseif danmaku.extra then
            history[dir].extra = danmaku.extra
        end
        write_json_file(history_path, history)
    end
end

function remove_source_from_history(rm_source)
    local history_json = read_file(history_path)
    local path = mp.get_property("path")

    if is_protocol(path) then
        path = remove_query(path)
    end

    if history_json then
        local history = utils.parse_json(history_json) or {}

        if history[path] ~= nil and history[path]["sources"] ~= nil then
            for source in pairs(history[path]["sources"]) do
                if source == rm_source then
                    history[path]["sources"][source] = nil
                    break
                end
            end
        end

        write_json_file(history_path, history)
    end
end

function add_source_to_history(add_url, add_source)
    local history_json = read_file(history_path)
    local path = mp.get_property("path")

    if is_protocol(path) then
        path = remove_query(path)
    end

    if history_json then
        local history = utils.parse_json(history_json) or {}
        history[path] = history[path] or {}

        if not history[path]["sources"] then
            history[path]["sources"] = {}
        end

        if not history[path]["sources"][add_url] then
            history[path]["sources"][add_url] = {}
        end

        history[path]["sources"][add_url].from = add_source.from or "user_custom"
        history[path]["sources"][add_url].blocked = add_source.blocked or false

        if add_source.delay then
            history[path]["sources"][add_url].delay = add_source.delay
        end

        write_json_file(history_path, history)
    end
end

function read_danmaku_source_record(path)
    if is_protocol(path) then
        path = remove_query(path)
    end

    local history_json = read_file(history_path)

    if history_json ~= nil then
        local history = utils.parse_json(history_json) or {}
        if history[path] == nil then
            return
        end
        local history_record = history[path]["sources"]
        if history_record ~= nil then
            local from = nil
            local delay = nil
            local blocked = false
            if is_nested_table(history_record) then
                for source in pairs(history_record) do
                    blocked = history_record[source].blocked or false
                    from = history_record[source].from
                    delay = history_record[source].delay

                    danmaku.sources[source] = {}
                    danmaku.sources[source]["from"] = from or "user_custom"
                    danmaku.sources[source]["blocked"] = blocked
                    if delay then
                        danmaku.sources[source]["delay"] = delay
                    end
                    danmaku.sources[source]["from_history"] = true
                end
            else
                local danmaku_sources = {}
                for _, source in ipairs(history_record) do
                    from = source:match("<(.-)>")
                    delay = source:match("{{(.-)}}")
                    source = source:gsub("<.->", ""):gsub("{{.-}}", "")

                    if source:match("^%-") then
                        source = source:sub(2)
                        blocked = true
                        from = "api_server"
                    end

                    danmaku.sources[source] = {}
                    danmaku.sources[source]["from"] = from or "user_custom"
                    danmaku.sources[source]["blocked"] = blocked
                    if delay then
                        danmaku.sources[source]["delay"] = delay
                    end
                    danmaku_sources[source] = shallow_copy(danmaku.sources[source])
                    danmaku.sources[source]["from_history"] = true
                end
                if next(danmaku_sources) ~= nil then
                    history[path]["sources"] = danmaku_sources
                    write_json_file(history_path, history)
                end
            end
        end
    end
end

-- 收集现有的弹幕文件和延迟记录
local function collect_danmaku_sources()
    local danmaku_input = {}
    local delays = {}

    for _, source in pairs(danmaku.sources) do
        if not source.blocked and source.fname then
            if not file_exists(source.fname) then
                show_message("未找到弹幕文件", 3)
                msg.info("未找到弹幕文件")
                return
            end
            table.insert(danmaku_input, source.fname)

            if source.delay then
                table.insert(delays, source.delay)
            else
                table.insert(delays, "0.0")
            end
        end
    end

    return danmaku_input, delays
end

-- 视频播放时保存弹幕
function save_danmaku(not_forced)
    local danmaku_input, delays = collect_danmaku_sources()
    if #danmaku_input == 0 then
        show_message("弹幕内容为空，无法保存", 3)
        msg.verbose("弹幕内容为空，无法保存")
        comments = {}
        return
    end

    local path = mp.get_property("path")
    local dir = get_parent_directory(path) or ""
    local filename = mp.get_property('filename/no-ext')
    local danmaku_out = utils.join_path(dir, filename .. ".xml")
    -- 排除网络播放场景
    if not path or is_protocol(path) or (not file_exists(danmaku_out)
    and not is_writable(danmaku_out)) then
        show_message("此弹幕文件不支持保存至本地")
        msg.warn("此弹幕文件不支持保存至本地")
    else
        if not_forced and file_exists(danmaku_out) then
            show_message("已存在同名弹幕文件：" .. danmaku_out)
            msg.info("已存在同名弹幕文件：" .. danmaku_out)
            return
        else
            convert_danmaku_to_xml(danmaku_input, danmaku_out, delays)
        end
    end
end

-- 加载弹幕
function load_danmaku(from_menu, no_osd)
    if not enabled then return end
    local temp_file = "danmaku-" .. pid .. ".ass"
    local danmaku_file = utils.join_path(danmaku_path, temp_file)
    local danmaku_input, delays = collect_danmaku_sources()
    -- 如果没有弹幕文件，退出加载
    if #danmaku_input == 0 then
        show_message("该集弹幕内容为空，结束加载", 3)
        msg.verbose("该集弹幕内容为空，结束加载")
        comments = {}
        return
    end

    convert_danmaku_format(danmaku_input, danmaku_file, delays)
    parse_danmaku(danmaku_file, from_menu, no_osd)
end

-- 为 bilibli 网站的视频播放加载弹幕
function load_danmaku_for_bilibili(path)
    local cid, danmaku_id = get_cid()
    if danmaku_id ~= nil then
        mp.commandv('sub-remove', danmaku_id)
    end

    if cid == nil then
        cid = mp.get_opt('cid')
        if not cid then
            local patterns = {
                "bilivideo%.c[nom]+.*/resource/(%d+)%D+.*",
                "bilivideo%.c[nom]+.*/(%d+)-%d+-%d+%..*%?",
            }
            local urls = {
                path,
                mp.get_property("stream-open-filename", ''),
            }

            for _, pattern in ipairs(patterns) do
                for _, url in ipairs(urls) do
                    if url:find(pattern) then
                        cid = url:match(pattern)
                        break
                    end
                end
            end
        end
    end
    if cid == nil and path:match("/video/BV.-") then
        if path:match("video/BV.-/.*") then
            path = path:gsub("/[^/]+$", "")
        end
        add_danmaku_source_online(path, true)
        return
    end
    if cid ~= nil then
        local url = "https://comment.bilibili.com/" .. cid .. ".xml"
        local temp_file = "danmaku-" .. pid .. danmaku.count .. ".xml"
        local danmaku_xml = utils.join_path(danmaku_path, temp_file)
        danmaku.count = danmaku.count + 1
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

        call_cmd_async(arg, function(error)
            async_running = false
            if error then
                show_message("HTTP 请求失败，打开控制台查看详情", 5)
                msg.error(error)
                return
            end
            if file_exists(danmaku_xml) then
                save_danmaku_downloaded(path, danmaku_xml)
                load_danmaku(true)
            end
        end)
    end
end

-- 为 bahamut 网站的视频播放加载弹幕
function load_danmaku_for_bahamut(path)
    local path = path:gsub('%%(%x%x)', hex_to_char)
    local sn = extract_between_colons(path)
    if sn == nil then
        return
    end
    local url = "https://ani.gamer.com.tw/ajax/danmuGet.php"
    local temp_file = "bahamut-" .. pid .. ".json"
    local danmaku_json = utils.join_path(danmaku_path, temp_file)
    local arg = {
        "curl",
        "-X",
        "POST",
        "-d",
        "sn=" .. sn,
        "-L",
        "-s",
        "--user-agent",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.83 Safari/537.36",
        "--header",
        "Origin: https://ani.gamer.com.tw",
        "--header",
        "Content-Type: application/x-www-form-urlencoded;charset=utf-8",
        "--header",
        "Accept: application/json",
        "--header",
        "Authority: ani.gamer.com.tw",
        "--output",
        danmaku_json,
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
        if not file_exists(danmaku_json) then
            url = "https://ani.gamer.com.tw/animeVideo.php?sn=" .. sn
            enabled = true
            add_danmaku_source_online(url, true)
            return
        end

        local comments_json = read_file(danmaku_json)
        local comments = utils.parse_json(comments_json)
        if not comments then
            return
        end

        temp_file = "danmaku-" .. pid .. danmaku.count .. ".json"
        local json_filename = utils.join_path(danmaku_path, temp_file)
        danmaku.count = danmaku.count + 1
        local json_file = io.open(json_filename, "w")

        if json_file then
            json_file:write("[\n")
            for _, comment in ipairs(comments) do
                local m = comment["text"]
                local color = hex_to_int_color(comment["color"])
                local mode = get_type_from_position(comment["position"])
                local time = tonumber(comment["time"]) / 10
                local c = time .. "," .. color .. "," .. mode .. ",25,,,"

                -- Write the JSON object as a single line, no spaces or extra formatting
                local json_entry = string.format('{"c":"%s","m":"%s"},\n', c, m)
                json_file:write(json_entry)
            end
            json_file:write("]")
            json_file:close()
        end

        if file_exists(json_filename) then
            save_danmaku_downloaded(
                "https://ani.gamer.com.tw/animeVideo.php?sn=" .. sn,
                json_filename)
            load_danmaku(true)
        end
    end)
end

function load_danmaku_for_url(path)
    if path:find('bilibili.com') or path:find('bilivideo.c[nom]+') then
        load_danmaku_for_bilibili(path)
        return
    end

    if path:find('bahamut.akamaized.net') then
        load_danmaku_for_bahamut(path)
        return
    end

    local title, season_num, episod_num = parse_title()
    local filename = url_decode(mp.get_property("media-title"))
    local episod_number = nil
    if title and episod_num then
        if season_num then
            dir = title .." Season".. season_num
            episod_number = episod_num
        else
            dir = title
        end
        auto_load_danmaku(path, dir, filename, episod_number)
        addon_danmaku(dir, false)
        return
    end
    get_danmaku_with_hash(filename, path)
    addon_danmaku()
end

-- 自动加载上次匹配的弹幕
function auto_load_danmaku(path, dir, filename, number)
    if dir ~= nil then
        local history_json = read_file(history_path)
        if history_json ~= nil then
            local history = utils.parse_json(history_json) or {}
            -- 1.判断父文件名是否存在
            local history_dir = history[dir]
            if history_dir ~= nil then
                --2.如果存在，则获取number和id
                danmaku.anime = history_dir.animeTitle
                local episode_number = history_dir.episodeTitle and history_dir.episodeTitle:match("%d+")
                local history_number = history_dir.episodeNumber
                local history_id = history_dir.episodeId
                local history_fname = history_dir.fname
                local history_extra = history_dir.extra
                local playing_number = nil

                if history_fname then
                    if filename ~= history_fname then
                        if number then
                            playing_number = number
                        else
                            history_number, playing_number = get_episode_number(filename, history_fname)
                        end
                    else
                        playing_number = history_number
                    end
                else
                    playing_number = get_episode_number(filename)
                end
                if playing_number ~= nil then
                    local x = playing_number - history_number --获取集数差值
                    danmaku.episode = episode_number and string.format("第%s话", episode_number + x) or history_dir.episodeTitle
                    show_message("自动加载上次匹配的弹幕", 3)
                    msg.verbose("自动加载上次匹配的弹幕")
                    if history_id then
                        local tmp_id = tostring(x + history_id)
                        set_episode_id(tmp_id)
                    elseif history_extra then
                        local episodenum = history_extra.episodenum + x
                        get_details(history_extra.class, history_extra.id, history_extra.site,
                            history_extra.title, history_extra.year, history_extra.number, episodenum)
                    end
                else
                    get_danmaku_with_hash(filename, path)
                end
            else
                get_danmaku_with_hash(filename, path)
            end
        else
            get_danmaku_with_hash(filename, path)
        end
    end
end

function init(path)
    if not path then return end
    local dir = get_parent_directory(path)
    local filename = mp.get_property('filename/no-ext')
    local video = mp.get_property_native("current-tracks/video")
    local duration = mp.get_property_number("duration", 0)
    if not video or video["image"] or video["albumart"] or duration < 60 then
        msg.info("不支持的播放内容（非视频）")
        return
    end
    if is_protocol(path) then
        load_danmaku_for_url(path)
    end
    if dir and filename then
        local danmaku_xml = utils.join_path(dir, filename .. ".xml")
        if file_exists(danmaku_xml) then
            add_danmaku_source_local(danmaku_xml, true)
        else
            auto_load_danmaku(path, dir, filename)
            addon_danmaku(dir, true)
        end
    end
end

mp.register_event("file-loaded", function()
    local path = mp.get_property("path")
    local dir = get_parent_directory(path)
    local filename = mp.get_property('filename/no-ext')
    local video = mp.get_property_native("current-tracks/video")
    local fps = mp.get_property_number("container-fps", 0)
    local duration = mp.get_property_number("duration", 0)
    if not video or video["image"] or video["albumart"] or fps < 23 or duration < 60 then
        return
    end

    read_danmaku_source_record(path)

    if not get_danmaku_visibility() then
        return
    end

    if options.autoload_for_url and is_protocol(path) then
        enabled = true
        load_danmaku_for_url(path)
    end

    if filename == nil or dir == nil then
        return
    end
    local danmaku_xml = utils.join_path(dir, filename .. ".xml")
    if options.autoload_local_danmaku then
        if file_exists(danmaku_xml) then
            enabled = true
            add_danmaku_source_local(danmaku_xml)
            return
        end
    end

    if options.auto_load then
        enabled = true
        auto_load_danmaku(path, dir, filename)
        addon_danmaku(dir, false)
        return
    end

    if enabled and comments == nil and not async_running then
        init(path)
    end
end)

-------------- 键位绑定 --------------
mp.add_key_binding(options.open_search_danmaku_menu_key, "open_search_danmaku_menu", function()
    mp.commandv("script-message", "open_search_danmaku_menu")
end)
mp.add_key_binding(options.show_danmaku_keyboard_key, "show_danmaku_keyboard", function()
    mp.commandv("script-message", "show_danmaku_keyboard")
end)

mp.register_script_message("danmaku-delay", function(number)
    local value = tonumber(number)
    if value == nil then
        return msg.error('command danmaku-delay: invalid time')
    end
    if value == 0 then
        delay = 0
    else
        delay = delay + value
    end
    if enabled and comments ~= nil then
        render()
    end
    show_message('设置弹幕延迟: ' .. string.format("%.1f", delay + 1e-10) .. ' s')
    mp.set_property_native(delay_property, delay)
end)

mp.register_script_message("clear-source", function()
    local path = mp.get_property("path")
    local history_json = read_file(history_path)

    if history_json ~= nil then
        local history = utils.parse_json(history_json) or {}
        if path and history[path] ~= nil then
            history[path] = nil
            write_json_file(history_path, history)
            for url, source in pairs(danmaku.sources) do
                if source.from == "user_custom" then
                    if source.fname and file_exists(source.fname) then
                        os.remove(source.fname)
                    end
                    danmaku.sources[url] = nil
                end
            end
            load_danmaku(false)
            show_message("已重置当前视频所有弹幕源更改", 3)
            msg.verbose("已重置当前视频所有弹幕源更改")
        end
    end
end)

mp.register_script_message("show_danmaku_keyboard", function()
    enabled = not enabled
    if enabled then
        mp.commandv("script-message-to", "uosc", "set", "show_danmaku", "on")
        set_danmaku_visibility(true)
        if comments == nil then
            show_message("加载弹幕初始化...", 3)
            local path = mp.get_property("path")
            init(path)
        else
            show_loaded()
            show_danmaku_func()
        end
    else
        show_message("关闭弹幕", 2)
        mp.commandv("script-message-to", "uosc", "set", "show_danmaku", "off")
        set_danmaku_visibility(false)
        hide_danmaku_func()
    end
end)

mp.register_script_message("immediately_save_danmaku", save_danmaku)
mp.register_script_message("open_source_delay_menu", danmaku_delay_setup)
mp.register_script_message("open_search_danmaku_menu", open_input_menu)
mp.register_script_message("open_add_source_menu", open_add_menu)
mp.register_script_message("open_add_total_menu", open_add_total_menu)
