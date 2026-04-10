-- Usage:
--  default keybinding: n
--  add the following to your input.conf to change the default keybinding:
--  keyname script_binding autosubsync-menu

local mp = require('mp')
local utils = require('mp.utils')
local mpopt = require('mp.options')
local menu = require('menu')
local sub = require('subtitle')
local ref_selector
local engine_selector
local track_selector

-- Config
-- Options can be changed here or in a separate config file.
-- Config path: ~/.config/mpv/script-opts/autosubsync.conf
local config = {
    -- Change the following lines if the locations of executables differ from the defaults
    -- If set to empty, the path will be guessed.
    ffmpeg_path = "",
    ffsubsync_path = "",
    alass_path = "",

    -- Choose what tool to use. Allowed options: ffsubsync, alass, ask.
    -- If set to ask, the add-on will ask to choose the tool every time.
    audio_subsync_tool = "ask",
    altsub_subsync_tool = "ask",

    -- After retiming, tell mpv to forget the original subtitle track.
    unload_old_sub = true,
}
mpopt.read_options(config, 'autosubsync')

local function is_empty(var)
    return var == nil or var == '' or (type(var) == 'table' and next(var) == nil)
end

----- string
local function replace(str, what, with)
    if is_empty(str) then return "" end
    if is_empty(what) then return str end
    if with == nil then with = "" end
    what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1")
    with = string.gsub(with, "[%%]", "%%%%")
    return string.gsub(str, what, with)
end

local function esc_for_title(string)
    string = string:gsub('^[%._%-%s]*', '')
            :gsub('%.%w+$', '')
    return string
end

local function esc_for_code(trackCode)
    if trackCode:find("PGS") then trackCode = "PGS"
    elseif trackCode:find("SUBRIP") then trackCode = "SRT"
    elseif trackCode:find("VTT") then trackCode = "VTT"
    elseif trackCode:find("DVD_SUB") then trackCode = "VOB_SUB"
    elseif trackCode:find("DVB_SUB") then trackCode = "DVB_SUB"
    elseif trackCode:find("DVB_TELE") then trackCode = "TELETEXT"
    elseif trackCode:find("ARIB") then trackCode = "ARIB"
    end
    return trackCode
end

-- Snippet borrowed from stackoverflow to get the operating system
-- originally found at: https://stackoverflow.com/a/30960054
local os_name = (function()
    if os.getenv("HOME") == nil then
        return function()
            return "Windows"
        end
    else
        return function()
            return "*nix"
        end
    end
end)()

local os_temp = (function()
    if os_name() == "Windows" then
        return function()
            return os.getenv('TEMP')
        end
    else
        return function()
            return '/tmp/'
        end
    end
end)()

-- Courtesy of https://stackoverflow.com/questions/4990990/check-if-a-file-exists-with-lua
local function file_exists(filepath)
    if not filepath then
        return false
    end
    local f = io.open(filepath, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

local function find_executable(name)
    local os_path = os.getenv("PATH") or ""
    local fallback_path = utils.join_path("/usr/bin", name)
    local exec_path
    for path in os_path:gmatch("[^:]+") do
        exec_path = utils.join_path(path, name)
        if file_exists(exec_path) then
            return exec_path
        end
    end
    return fallback_path
end

local function notify(message, level, duration)
    level = level or 'info'
    duration = duration or 1
    mp.msg[level](message)
    mp.osd_message(message, duration)
end

local function subprocess(args)
    return mp.command_native {
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        args = args
    }
end

local url_decode = function(url)
    local function hex_to_char(x)
        return string.char(tonumber(x, 16))
    end
    if url ~= nil then
        url = url:gsub("^file://", "")
        url = url:gsub("+", " ")
        url = url:gsub("%%(%x%x)", hex_to_char)
        return url
    else
        return
    end
end

local function get_loaded_tracks(track_type)
    local result = {}
    local track_list = mp.get_property_native('track-list')
    for _, track in pairs(track_list) do
        if track.type == track_type then
            track['external-filename'] = track.external and url_decode(track['external-filename'])
            table.insert(result, track)
        end
    end
    return result
end

local function get_active_track(track_type)
    local track_list = mp.get_property_native('track-list')
    for num, track in ipairs(track_list) do
        if track.type == track_type and track.selected == true then
            if track.external then
                track['external-filename'] = url_decode(track['external-filename'])
            end
            if not (track_type == 'sub' and track.id == mp.get_property_native('secondary-sid')) then
                return num, track
            end
        end
    end
    return notify(string.format("错误: 没有选择类型为 '%s' 的轨道", track_type), "error", 3)
end

local function remove_extension(filename)
    return filename:gsub('%.%w+$', '')
end

local function get_extension(filename)
    return filename:match("^.+(%.%w+)$")
end

local function startswith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

local function mkfp_retimed(sub_path)
    if not startswith(sub_path, os_temp()) then
        return table.concat { remove_extension(sub_path), '_retimed', get_extension(sub_path) }
    else
        return table.concat { remove_extension(mp.get_property("path")), '_retimed', get_extension(sub_path) }
    end
end

local function engine_is_set()
    local subsync_tool = ref_selector:get_subsync_tool()
    if is_empty(subsync_tool) or subsync_tool == "ask" then
        return false
    else
        return true
    end
end

local function extract_to_file(subtitle_track)
    local codec_ext_map = { subrip = "srt", ass = "ass" }
    local ext = codec_ext_map[subtitle_track['codec']]
    if ext == nil then
        return notify(string.format("错误: 不支持的格式: %s", subtitle_track['codec']), "error", 3)
    end
    local temp_sub_fp = utils.join_path(os_temp(), 'autosubsync_extracted.' .. ext)
    notify("提取内封字幕...", nil, 3)
    local screenx, screeny, aspect = mp.get_osd_size()
    mp.set_osd_ass(screenx, screeny, "{\\an9}● ")
    local ret = subprocess {
        config.ffmpeg_path,
        "-hide_banner",
        "-nostdin",
        "-y",
        "-loglevel", "quiet",
        "-an",
        "-vn",
        "-i", mp.get_property("path"),
        "-map", "0:" .. (subtitle_track and subtitle_track['ff-index'] or 's'),
        "-f", ext,
        temp_sub_fp
    }
    mp.set_osd_ass(screenx, screeny, "")
    if ret == nil or ret.status ~= 0 then
        return notify("无法提取内封字幕.\n请先确保在脚本配置文件中为 ffmpeg 指定了正确的路径\n并确保视频有内封字幕.", "error", 7)
    end
    return temp_sub_fp
end

local function sync_subtitles(ref_sub_path)
    local reference_file_path = ref_sub_path or mp.get_property("path")
    local _, sub_track = get_active_track('sub')
    if sub_track == nil then
        return
    end
    local subtitle_path = sub_track.external and sub_track['external-filename'] or extract_to_file(sub_track)
    local engine_name = engine_selector:get_engine_name()
    local engine_path = config[engine_name .. '_path']

    if not file_exists(subtitle_path) then
        return notify(
                table.concat {
                    "字幕同步失败:\n无法找到 ",
                    subtitle_path or "外部字幕文件."
                },
                "error",
                3
        )
    end

    local retimed_subtitle_path = mkfp_retimed(subtitle_path)

    notify(string.format("开始 %s...", engine_name), nil, 2)

    local ret
    local screenx, screeny, aspect = mp.get_osd_size()
    if engine_name == "ffsubsync" then
        local args = { config.ffsubsync_path, reference_file_path, "-i", subtitle_path, "-o", retimed_subtitle_path }
        if not ref_sub_path then
            table.insert(args, '--reference-stream')
            table.insert(args, '0:' .. get_active_track('audio'))
        end
        mp.set_osd_ass(screenx, screeny, "{\\an9}● ")
        ret = subprocess(args)
        mp.set_osd_ass(screenx, screeny, "")
    else
        mp.set_osd_ass(screenx, screeny, "{\\an9}● ")
        ret = subprocess { config.alass_path, reference_file_path, subtitle_path, retimed_subtitle_path }
        mp.set_osd_ass(screenx, screeny, "")
    end

    if ret == nil then
        return notify("解析失败或没有传递参数.", "fatal", 3)
    end

    if ret.status == 0 then
        local old_sid = mp.get_property("sid")
        if mp.commandv("sub_add", retimed_subtitle_path) then
            notify("字幕同步.", nil, 2)
            mp.set_property("sub-delay", 0)
            if config.unload_old_sub then
                mp.commandv("sub_remove", old_sid)
            end
        else
            notify("错误: 不能添加同步字幕.", "error", 3)
        end
    else
        notify(string.format("字幕同步失败.\n请确保在脚本配置文件中为 %s 指定了正确的路径.\n或音轨提取失败", engine_name), "error", 3)
    end
end

local function sync_to_subtitle()
    local selected_track = track_selector:get_selected_track()

    if selected_track and selected_track.external then
        sync_subtitles(selected_track['external-filename'])
    else
        local temp_sub_fp = extract_to_file(selected_track)
        if temp_sub_fp then
            sync_subtitles(temp_sub_fp)
            os.remove(temp_sub_fp)
        end
    end
end

local function sync_to_manual_offset()
    local _, track = get_active_track('sub')
    local sub_delay = tonumber(mp.get_property("sub-delay"))
    if tonumber(sub_delay) == 0 then
        return notify("没有手动调整时轴，什么都做不了！", "error", 7)
    end
    local file_path = track.external and track['external-filename'] or extract_to_file(track)
    if file_path == nil then
        return
    end

    local ext = get_extension(file_path)
    local codec_parser_map = { ass = sub.ASS, subrip = sub.SRT }
    local parser = codec_parser_map[track['codec']]
    if parser == nil then
        return notify(string.format("错误: 不支持的格式: %s", track['codec']), "error", 3)
    end
    local s = parser:populate(file_path)
    s:shift_timing(sub_delay)
    if track.external == false then
        os.remove(file_path)
        s.filename = mp.get_property("filename/no-ext") .. "_manual_timing" .. ext
    else
        s.filename = remove_extension(s.filename) .. '_manual_timing' .. ext
    end
    s:save()
    mp.commandv("sub_add", s.filename)
    if config.unload_old_sub then
        mp.commandv("sub_remove", track.id)
    end
    mp.set_property("sub-delay", 0)
    return notify(string.format("手动同步保存，加载 '%s'", s.filename), "info", 7)
end

------------------------------------------------------------
-- Menu actions & bindings

ref_selector = menu:new {
    items = { '与音频同步', '与其他字幕同步', '保存当前时轴', '退出' },
    last_choice = 'audio',
    pos_x = 50,
    pos_y = 50,
    rect_width = 400,
    text_color = 'fff5da',
    border_color = '2f1728',
    active_color = 'ff6b71',
    inactive_color = 'fff5da',
}

function ref_selector:get_keybindings()
    return {
        { key = 'h', fn = function() self:close() end },
        { key = 'j', fn = function() self:down() end },
        { key = 'k', fn = function() self:up() end },
        { key = 'l', fn = function() self:act() end },
        { key = 'down', fn = function() self:down() end },
        { key = 'up', fn = function() self:up() end },
        { key = 'Enter', fn = function() self:act() end },
        { key = 'ESC', fn = function() self:close() end },
        { key = 'n', fn = function() self:close() end },
        { key = 'WHEEL_DOWN', fn = function() self:down() end },
        { key = 'WHEEL_UP', fn = function() self:up() end },
        { key = 'MBTN_LEFT', fn = function() self:act() end },
        { key = 'MBTN_RIGHT', fn = function() self:close() end },
    }
end

function ref_selector:new(o)
    self.__index = self
    o = o or {}
    return setmetatable(o, self)
end

function ref_selector:get_ref()
    if self.selected == 1 then
        return 'audio'
    elseif self.selected == 2 then
        return 'sub'
    else
        return nil
    end
end

function ref_selector:get_subsync_tool()
    if self.selected == 1 then
        return config.audio_subsync_tool
    elseif self.selected == 2 then
        return config.altsub_subsync_tool
    end
end

function ref_selector:act()
    self:close()

    if self.selected == 3 then
        return sync_to_manual_offset()
    end
    if self.selected == 4 then
        return
    end

    engine_selector:init()
end

function ref_selector:call_subsync()
    if self.selected == 1 then
        sync_subtitles()
    elseif self.selected == 2 then
        sync_to_subtitle()
    elseif self.selected == 3 then
        sync_to_manual_offset()
    end
end

function ref_selector:open()
    self.selected = 1
    for _, val in pairs(self:get_keybindings()) do
        mp.add_forced_key_binding(val.key, val.key, val.fn)
    end
    self:draw()
end

function ref_selector:close()
    for _, val in pairs(self:get_keybindings()) do
        mp.remove_key_binding(val.key)
    end
    self:erase()
end


------------------------------------------------------------
-- Engine selector

engine_selector = ref_selector:new {
    items = { 'ffsubsync', 'alass', '退出' },
    last_choice = 'ffsubsync',
}

function engine_selector:init()
    if not engine_is_set() then
        engine_selector:open()
    else
        track_selector:init()
    end
end

function engine_selector:get_engine_name()
    return engine_is_set() and ref_selector:get_subsync_tool() or self.last_choice
end

function engine_selector:act()
    self:close()

    if self.selected == 1 then
        self.last_choice = 'ffsubsync'
    elseif self.selected == 2 then
        self.last_choice = 'alass'
    elseif self.selected == 3 then
        return
    end

    track_selector:init()
end

------------------------------------------------------------
-- Track selector

track_selector = ref_selector:new { }

function track_selector:init()
    self.selected = 0

    if ref_selector:get_ref() == 'audio' then
        return ref_selector:call_subsync()
    end

    self.all_sub_tracks = get_loaded_tracks(ref_selector:get_ref())
    self.tracks = {}
    self.items = {}

    local filename = mp.get_property_native('filename/no-ext')
    for _, track in ipairs(self.all_sub_tracks) do
        local supported_format = true
        if track.external then
            local ext = get_extension(track['external-filename'])
            if ext ~= '.srt' and ext ~= '.ass' then
                supported_format = false
            end
        end

        if not track.selected and supported_format then
            table.insert(self.tracks, track)
            table.insert(
                    self.items,
                    string.format(
                            "%s #%s - %s%s%s",
                            (track.external and 'External' or 'Internal'),
                            track['id'],
                            (track.lang or (track.title and
                            esc_for_title(replace(track.title, filename, '')) or 'unknown')),
                            (track.codec and '[' .. esc_for_code(track.codec:upper()) .. ']' or ''),
                            (track.selected and ' (active)' or '')
                    )
            )
        end
    end

    if #self.items == 0 then
        notify("没有找到受支持的字幕轨道.", "warn", 5)
        return
    end

    table.insert(self.items, "退出")
    self:open()
end

function track_selector:get_selected_track()
    if self.selected < 1 then
        return nil
    end
    return self.tracks[self.selected]
end

function track_selector:act()
    self:close()

    if self.selected == #self.items then
        return
    end

    ref_selector:call_subsync()
end

------------------------------------------------------------
-- Initialize the addon

local function init()
    for _, executable in pairs { 'ffmpeg', 'ffsubsync', 'alass' } do
        local config_key = executable .. '_path'
        config[config_key] = is_empty(config[config_key]) and find_executable(executable) or config[config_key]
    end
end

------------------------------------------------------------
-- Entry point

init()
mp.add_key_binding("n", "autosubsync-menu", function() ref_selector:open() end)
