VERSION = "2.2.0"

mp.commandv('script-message', 'uosc_danmaku-version', VERSION)

local msg = require('mp.msg')
local utils = require("mp.utils")

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
require("modules/update")

require("apis/dandanplay")
require('apis/extra')

require("sites/bilibili")
require("sites/bahamut")
require("sites/iqiyi")
require("sites/mgtv")
require("sites/tencentvideo")
require("sites/youku")

DANMAKU_PATH = os.getenv("TEMP") or "/tmp/"
HISTORY_PATH = mp.command_native({"expand-path", options.history_path})
PID = utils.getpid()
DANMAKU = {sources = {}, count = 1}
ENABLED, COMMENTS, DELAY = false, nil, 0
DELAY_PROPERTY = string.format("user-data/%s/danmaku-delay", mp.get_script_name())
mp.set_property_native(DELAY_PROPERTY, 0)
HAS_DANMAKU = string.format("user-data/%s/has-danmaku", mp.get_script_name())
mp.set_property_bool(HAS_DANMAKU, false)
DANMAKU_SWITCH_ON = string.format("user-data/%s/danmaku-switch-on", mp.get_script_name())
mp.set_property_bool(DANMAKU_SWITCH_ON, false)
DANMAKU_COUNT = string.format("user-data/%s/danmaku-count", mp.get_script_name())
mp.set_property_native(DANMAKU_COUNT, 0)
KEY = table_to_zero_indexed({
    0x00,0x01,0x02,0x03,0x04,
    0x05,0x06,0x07,0x08,0x09,
    0x0a,0x0b,0x0c,0x0d,0x0e,
    0x0f,0x10,0x11,0x12,0x13,
    0x14,0x15,0x16,0x17,0x18,
    0x19,0x1a,0x1b,0x1c,0x1d,
    0x1e,0x1f
})

PLATFORM = (function()
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

local rebuild_convert_timer = nil

function get_danmaku_visibility()
    local history_json = read_file(HISTORY_PATH)
    local history
    if history_json ~= nil then
        history = utils.parse_json(history_json) or {}
        local flag = history["show_danmaku"]
        if flag == nil then
            history["show_danmaku"] = false
            write_json_file(HISTORY_PATH, history)
        else
            return flag
        end
    else
        history = {}
        history["show_danmaku"] = false
        write_json_file(HISTORY_PATH, history)
    end
    return false
end

function set_danmaku_visibility(flag)
    local history = {}
    local history_json = read_file(HISTORY_PATH)
    if history_json ~= nil then
        history = utils.parse_json(history_json) or {}
    end
    history["show_danmaku"] = flag
    write_json_file(HISTORY_PATH, history)
end

function set_danmaku_button()
    if get_danmaku_visibility() then
        toggle_danmaku_switch("on")
    end
end

function show_loaded(init)
    if DANMAKU.anime and DANMAKU.episode then
        show_message("匹配内容：" .. DANMAKU.anime .. "-" .. DANMAKU.episode .. "\\N弹幕加载成功，共计" .. #COMMENTS .. "条弹幕", 3)
        if init then
            msg.info(DANMAKU.anime .. "-" .. DANMAKU.episode .. " 弹幕加载成功，共计" .. #COMMENTS .. "条弹幕")
        end
    else
        show_message("弹幕加载成功，共计" .. #COMMENTS .. "条弹幕", 3)
    end
    mp.set_property_native(DANMAKU_COUNT, #COMMENTS)
end

-- 获取指定时间的延迟
-- 返回该时间点之前所有延迟段的总和
function get_delay_for_time(delay_segments, time)
    if not delay_segments or #delay_segments == 0 then return 0 end

    local segs = {}
    for i = 1, #delay_segments do segs[i] = delay_segments[i] end
    table.sort(segs, function(a, b) return a.start < b.start end)

    local applied_delay = 0
    for i = 1, #segs do
        local seg = segs[i]
        local delay = tonumber(seg.delay)
        if time >= seg.start and delay then
            applied_delay = applied_delay + delay
        else
            break
        end
    end
    return applied_delay
end

local function merge_delay_segments(segments)
    if not segments or #segments == 0 then return {} end

    local NEAREST_THRESHOLD = 10  -- 最邻近段合并阈值
    local MERGE_THRESHOLD = 30    -- 跨段合并阈值
    local EPSILON = 1e-6          -- 判断接近 0 的阈值

    table.sort(segments, function(a, b) return a.start < b.start end)

    local partially_merged = {}
    local i = 1
    while i <= #segments do
        local cur = segments[i]
        local next_seg = segments[i + 1]

        if next_seg and (next_seg.start - cur.start) <= NEAREST_THRESHOLD then
            local combined_delay = tonumber(cur.delay) + tonumber(next_seg.delay)
            if math.abs(combined_delay) > EPSILON then
                table.insert(partially_merged, {
                    start = cur.start,
                    delay = combined_delay
                })
            end
            i = i + 2
        else
            if math.abs(tonumber(cur.delay)) > EPSILON then
                table.insert(partially_merged, cur)
            end
            i = i + 1
        end
    end

    local merged = {}
    for _, seg in ipairs(partially_merged) do
        local merged_flag = false
        for idx, m in ipairs(merged) do
            if math.abs(seg.start - m.start) <= MERGE_THRESHOLD then
                m.delay = tonumber(m.delay) + tonumber(seg.delay)
                if math.abs(m.delay) <= EPSILON then
                    table.remove(merged, idx)
                end
                merged_flag = true
                break
            end
        end
        if not merged_flag then
            if math.abs(tonumber(seg.delay)) > EPSILON then
                table.insert(merged, {
                    start = seg.start,
                    delay = seg.delay
                })
            end
        end
    end

    table.sort(merged, function(a, b) return a.start < b.start end)
    return merged
end

function parse_delay_input(text)
    if not text then return nil end
    local s = tostring(text):gsub("%s+", "")
    if s == "" then return nil end
    -- XmYs 格式，允许负号在分钟部分
    local m, sec = string.match(s, "^(%-?%d+)m(%d+)s$")
    if m and sec then
        m = tonumber(m)
        sec = tonumber(sec)
        if not m or not sec then return nil end
        if m < 0 then sec = -sec end
        return m * 60 + sec
    end
    -- 普通数字（整数或小数），支持负数
    local n = tonumber(s)
    if n ~= nil then return n end
    return nil
end

local function set_danmaku_delay(dly, time, specific_source)
    if specific_source then
        local source = DANMAKU.sources[specific_source]
        if source and source.data and not source.blocked then
            source.delay_segments = source.delay_segments or {}
            if dly == 0 then
                source.delay_segments = {}
            elseif time then
                table.insert(source.delay_segments, {start = time, delay = dly})
            else
                table.insert(source.delay_segments, {start = 0, delay = dly})
            end
            source.delay = nil
            source.delay_segments = merge_delay_segments(source.delay_segments)
            add_source_to_history(specific_source, source)
        end
    else
        for url, source in pairs(DANMAKU.sources) do
            if source.data and not source.blocked then
                source.delay_segments = source.delay_segments or {}
                if dly == 0 then
                    source.delay_segments = {}
                elseif time then
                    table.insert(source.delay_segments, {start = time, delay = dly})
                else
                    table.insert(source.delay_segments, {start = 0, delay = dly})
                end

                source.delay = nil
                source.delay_segments = merge_delay_segments(source.delay_segments)
                add_source_to_history(url, source)
            end
        end
    end

    if dly == 0 then
        DELAY = 0
    else
        DELAY = DELAY + dly
    end

    if ENABLED and COMMENTS ~= nil then
        render()
    end

    -- 防抖：批量重建 ASS 事件并渲染，避免频繁变更导致重复重建
    if rebuild_convert_timer then
        rebuild_convert_timer:kill()
        rebuild_convert_timer = nil
    end
    rebuild_convert_timer = mp.add_timeout(0.1, function()
        if convert_danmaku_to_ass_events then
            convert_danmaku_to_ass_events(true)
        end
        render()
        rebuild_convert_timer = nil
    end)

    show_message('设置弹幕延迟: ' .. string.format("%.1f", DELAY + 1e-10) .. ' s')
    mp.set_property_native(DELAY_PROPERTY, DELAY)
end

local function clear_source()
    local path = mp.get_property("path")
    local history_json = read_file(HISTORY_PATH)

    if not path or not history_json then return end

    local history = utils.parse_json(history_json) or {}
    if history[path] == nil then return end

    history[path] = nil
    write_json_file(HISTORY_PATH, history)

    for url, source in pairs(DANMAKU.sources) do
        if source.from == "user_custom" then
            DANMAKU.sources[url] = nil
        end
    end

    load_danmaku(false)

    show_message("已重置当前视频所有弹幕源更改", 3)
    msg.verbose("已重置当前视频所有弹幕源更改")
end

function write_history(episodeid, api_server)
    local history = {}
    local path = mp.get_property("path")
    local dir = get_parent_directory(path)
    local fname = mp.get_property('filename/no-ext')
    local episodeNumber = 0
    if episodeid then
        episodeNumber = tonumber(episodeid) % 1000
    elseif DANMAKU.extra then
        episodeNumber = DANMAKU.extra.episodenum
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
        local history_json = read_file(HISTORY_PATH)
        if history_json ~= nil then
            history = utils.parse_json(history_json) or {}
        end
        history[dir] = {}
        history[dir].fname = fname
        history[dir].source = DANMAKU.source
        history[dir].animeTitle = DANMAKU.anime
        history[dir].episodeTitle = DANMAKU.episode
        history[dir].episodeNumber = episodeNumber
        if episodeid then
            history[dir].episodeId = episodeid
        elseif DANMAKU.extra then
            history[dir].extra = DANMAKU.extra
        end
        if api_server then
            history[dir].api_server = api_server
        end
        write_json_file(HISTORY_PATH, history)
    end
end

function remove_source_from_history(rm_source)
    local history_json = read_file(HISTORY_PATH)
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

        write_json_file(HISTORY_PATH, history)
    end
end

function add_source_to_history(add_url, add_source)
    local history_json = read_file(HISTORY_PATH)
    local path = mp.get_property("path")

    if is_protocol(path) then
        path = remove_query(path)
    end

    local history = {}
    if history_json then
        history = utils.parse_json(history_json) or {}
    end

    history[path] = history[path] or {}
    history[path]["sources"] = history[path]["sources"] or {}
    history[path]["sources"][add_url] = history[path]["sources"][add_url] or {}

    local record = history[path]["sources"][add_url]
    record.from = add_source.from or "user_custom"
    record.blocked = add_source.blocked or false

   local delay_segments = shallow_copy(add_source.delay_segments or {})
    if #delay_segments > 0 then
        record.delay_segments = merge_delay_segments(delay_segments)
        if #record.delay_segments == 0 then
            record.delay_segments = nil
        end
    else
        record.delay_segments = nil
    end

    record.delay = nil
    write_json_file(HISTORY_PATH, history)
end

function read_danmaku_source_record(path)
    if is_protocol(path) then
        path = remove_query(path)
    end

    local history_json = read_file(HISTORY_PATH)
    if not history_json then return end

    local history = utils.parse_json(history_json) or {}
    local record = history[path]

    if not record or not record.sources then return end

    local sources = record.sources
    local upgraded_sources = {}

    if is_nested_table(sources) then
        for source, data in pairs(sources) do
            local from = data.from or "user_custom"
            local blocked = data.blocked or false
            local delay_segments = shallow_copy(data.delay_segments or {})
            if data.delay ~= nil then
                for i = #delay_segments, 1, -1 do
                    if delay_segments[i].start == 0 then
                        table.remove(delay_segments, i)
                    end
                end
                table.insert(delay_segments, 1, { start = 0, delay = tonumber(data.delay) })
            end
            if #delay_segments > 0 then
                delay_segments = merge_delay_segments(delay_segments)
            else
                delay_segments = nil
            end

            DANMAKU.sources[source] = {
                from = from,
                blocked = blocked,
                delay_segments = delay_segments,
                from_history = true,
            }
        end
    else
        for _, raw in ipairs(sources) do
            local source = raw
            local blocked = false
            local from = raw:match("<(.-)>")
            local delay = raw:match("{{(.-)}}")

            source = source:gsub("<.->", ""):gsub("{{.-}}", "")

            if source:match("^%-") then
                source = source:sub(2)
                blocked = true
                from = from or "api_server"
            end

            local delay_segments = nil
            if delay ~= nil then
                delay_segments = {
                    { start = 0, delay = tonumber(delay) }
                }
            end

            DANMAKU.sources[source] = {
                from = from or "user_custom",
                blocked = blocked,
                delay_segments = delay_segments,
                from_history = true,
            }

            upgraded_sources[source] = shallow_copy(DANMAKU.sources[source])
        end

        if next(upgraded_sources) then
            record.sources = upgraded_sources
            write_json_file(HISTORY_PATH, history)
        end
    end
end

-- 视频播放时保存弹幕
function save_danmaku(not_forced)
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
            convert_danmaku_to_xml(danmaku_out)
        end
    end
end

-- 加载弹幕
function load_danmaku(from_menu, no_osd)
    if not ENABLED then return end
    convert_danmaku_to_ass_events()
    render_danmaku(from_menu, no_osd)
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
        local history_json = read_file(HISTORY_PATH)
        if history_json ~= nil then
            local history = utils.parse_json(history_json) or {}
            -- 1.判断父文件名是否存在
            local history_dir = history[dir]
            if history_dir ~= nil then
                --2.如果存在，则获取number和id
                DANMAKU.anime = history_dir.animeTitle
                local episode_number = history_dir.episodeTitle and history_dir.episodeTitle:match("%d+")
                local history_number = history_dir.episodeNumber
                local history_id = history_dir.episodeId
                local history_fname = history_dir.fname
                local history_extra = history_dir.extra
                local history_api_server = history_dir.api_server
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
                    DANMAKU.episode = episode_number and string.format("第%s话", episode_number + x) or history_dir.episodeTitle
                    DANMAKU.api_server = history_api_server or nil
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
        ENABLED = true
        load_danmaku_for_url(path)
    end

    if filename == nil or dir == nil then
        return
    end
    local danmaku_xml = utils.join_path(dir, filename .. ".xml")
    if options.autoload_local_danmaku then
        if file_exists(danmaku_xml) then
            ENABLED = true
            add_danmaku_source_local(danmaku_xml)
            return
        end
    end

    if options.auto_load then
        ENABLED = true
        auto_load_danmaku(path, dir, filename)
        addon_danmaku(dir, false)
        return
    end

    if ENABLED and COMMENTS == nil and not is_async_running() then
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

mp.register_script_message("danmaku-delay", function(...)
    local commands = {...}
    local delay_str, time_str = commands[1], commands[2]
    local source_arg = commands[3]
    local dly = parse_delay_input(delay_str)
    local time = time_str and tonumber(time_str)
    if type(dly) ~= "number" then
        show_message("参数错误：缺少有效的延迟秒数", 3)
        return
    end
    if source_arg and source_arg ~= "nil" then
        set_danmaku_delay(dly, time, source_arg)
    else
        set_danmaku_delay(dly, time)
    end
end)

mp.register_script_message("show_danmaku_keyboard", function()
    ENABLED = not ENABLED
    if ENABLED then
        toggle_danmaku_switch("on")

        if COMMENTS == nil then
            show_message("加载弹幕初始化...", 3)
            set_danmaku_visibility(true)
            local path = mp.get_property("path")
            init(path)
        else
            show_loaded()
            show_danmaku_func()
        end
    else
        show_message("关闭弹幕", 2)
        toggle_danmaku_switch("off")
        hide_danmaku_func()
    end
end)

mp.register_script_message("check-update", check_for_update)
mp.register_script_message("clear-source", clear_source)
mp.register_script_message("immediately_save_danmaku", save_danmaku)
mp.register_script_message("open_source_delay_menu", open_delay_menu)
mp.register_script_message("open_search_danmaku_menu", open_input_menu)
mp.register_script_message("open_add_source_menu", open_add_menu)
mp.register_script_message("open_add_total_menu", open_add_total_menu)
