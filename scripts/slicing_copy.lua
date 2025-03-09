local msg = require "mp.msg"
local utils = require "mp.utils"
local options = require "mp.options"

local cut_pos = nil
local copy_audio = true
local ext_map = {
    ["mpegts"] = "ts",
}
local o = {
    ffmpeg_path = "ffmpeg",
    target_dir = "~~/cutfragments",
    overwrite = false, -- whether to overwrite exist files
    vcodec = "copy",
    acodec = "copy",
    debug = false,
}

options.read_options(o)

Command = {}

local function is_protocol(path)
    return type(path) == 'string' and (path:find('^%a[%w.+-]-://') ~= nil or path:find('^%a[%w.+-]-:%?') ~= nil)
end

function Command:new(name)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.name = ""
    o.args = { "" }
    if name then
        o.name = name
        o.args[1] = name
    end
    return o
end
function Command:arg(...)
    for _, v in ipairs({...}) do
        self.args[#self.args + 1] = v
    end
    return self
end
function Command:as_str()
    return table.concat(self.args, " ")
end
function Command:run()
    local res, err = mp.command_native({
        name = "subprocess",
        args = self.args,
        capture_stdout = true,
        capture_stderr = true,
    })
    return res, err
end

local function file_format()
    local fmt = mp.get_property("file-format")
    if not fmt:find(',') then
        return fmt
    end
    local path = mp.get_property('path')
    if is_protocol(path) then
        return nil
    end
    local filename = mp.get_property('filename')
    return filename:match('%.([^.]+)$')
end

local function get_ext()
    local fmt = file_format()
    if fmt and ext_map[fmt] ~= nil then
        return ext_map[fmt]
    else
        return fmt
    end
end

local function timestamp(duration)
    local hours = math.floor(duration / 3600)
    local minutes = math.floor(duration % 3600 / 60)
    local seconds = duration % 60
    return string.format("%02d:%02d:%06.3f", hours, minutes, seconds)
end

local function osd(str)
    return mp.osd_message(str, 3)
end

local function info(s)
    msg.info(s)
    osd(s)
end

local function get_outname(path, shift, endpos)
    local name = mp.get_property("filename/no-ext")
    if is_protocol(path) then
        name = mp.get_property("media-title")
    end
    local ext = get_ext() or "mkv"
    name = string.format("%s_%s-%s.%s", name, timestamp(shift), timestamp(endpos), ext)
    return name:gsub(":", "-")
end

local function cut(shift, endpos)
    local duration = endpos - shift
    local path = mp.get_property("path")
    local inpath = mp.get_property("stream-open-filename")
    local outpath = utils.join_path(
        o.target_dir,
        get_outname(path, shift, endpos)
    )

    local cache = mp.get_property_native("cache")
    local cache_state = mp.get_property_native("demuxer-cache-state")
    local cache_ranges = cache_state and cache_state["seekable-ranges"] or {}
    if path and is_protocol(path) or cache == "auto" and #cache_ranges > 0 then
        local pid = mp.get_property_native('pid')
        local temp_path = os.getenv("TEMP") or "/tmp/"
        local temp_video_file = utils.join_path(temp_path, "mpv_dump_" .. pid .. ".mkv")
        mp.commandv("dump-cache", shift, endpos, temp_video_file)
        shift = 0
        inpath = temp_video_file
    end

    local cmds = Command:new(o.ffmpeg_path)
        :arg("-v", "warning")
        :arg(o.overwrite and "-y" or "-n")
        :arg("-stats")
    cmds:arg("-ss", tostring(shift))
    cmds:arg("-accurate_seek")
    cmds:arg("-i", inpath)
    cmds:arg("-t", tostring(duration))
    cmds:arg("-c:v", o.vcodec)
    cmds:arg("-c:a", o.acodec)
    cmds:arg("-c:s", "copy")
    cmds:arg("-map", string.format("v:%s?", math.max(mp.get_property_number("current-tracks/video/id", 0) - 1, 0)))
    cmds:arg("-map", string.format("a:%s?", math.max(mp.get_property_number("current-tracks/audio/id", 0) - 1, 0)))
    cmds:arg("-map", string.format("s:%s?", math.max(mp.get_property_number("current-tracks/sub/id", 0) - 1, 0)))
    cmds:arg(not copy_audio and "-an" or nil)
    cmds:arg("-avoid_negative_ts", "make_zero")
    cmds:arg("-async", "1")
    cmds:arg(outpath)
    msg.info("Run commands: " .. cmds:as_str())
    local screenx, screeny, aspect = mp.get_osd_size()
    mp.set_osd_ass(screenx, screeny, "{\\an9}● ")
    local res, err = cmds:run()
    mp.set_osd_ass(screenx, screeny, "")
    if err then
        msg.error(utils.to_string(err))
        mp.osd_message("Failed. Refer console for details.")
    elseif res.status ~= 0 then
        if res.stderr ~= "" or res.stdout ~= "" then
            msg.info("stderr: " .. (res.stderr:gsub("^%s*(.-)%s*$", "%1"))) -- trim stderr
            msg.info("stdout: " .. (res.stdout:gsub("^%s*(.-)%s*$", "%1"))) -- trim stdout
            mp.osd_message("Failed. Refer console for details.")
        end
    elseif res.status == 0 then
        if o.debug and (res.stderr ~= "" or res.stdout ~= "") then
            msg.info("stderr: " .. (res.stderr:gsub("^%s*(.-)%s*$", "%1"))) -- trim stderr
            msg.info("stdout: " .. (res.stdout:gsub("^%s*(.-)%s*$", "%1"))) -- trim stdout
        end
        msg.info("Trim file successfully created: " .. outpath)
        mp.add_timeout(1, function()
            mp.osd_message("Trim file successfully created!")
        end)
    end
end

local function toggle_mark()
    local pos, err = mp.get_property_number("time-pos")
    if not pos then
        osd("Failed to get timestamp")
        msg.error("Failed to get timestamp: " .. err)
        return
    end
    if cut_pos then
        local shift, endpos = cut_pos, pos
        if shift > endpos then
            shift, endpos = endpos, shift
        elseif shift == endpos then
            osd("Cut fragment is empty")
            return
        end
        cut_pos = nil
        info(string.format("Cut fragment: %s-%s", timestamp(shift), timestamp(endpos)))
        cut(shift, endpos)
    else
        cut_pos = pos
        info(string.format("Marked %s as start position", timestamp(pos)))
    end    
end

local function toggle_audio()
    copy_audio = not copy_audio
    info("Audio capturing is " .. (copy_audio and "enabled" or "disabled"))
end

local function clear_toggle_mark()
    cut_pos = nil
    info("Cleared cut fragment")
end

o.target_dir = o.target_dir:gsub('"', "")
local file, _ = utils.file_info(mp.command_native({ "expand-path", o.target_dir }))
if not file then
    --create target_dir if it doesn't exist
    local savepath = mp.command_native({ "expand-path", o.target_dir })
    local is_windows = package.config:sub(1, 1) == "\\"
    local windows_args = { 'powershell', '-NoProfile', '-Command', 'mkdir', string.format("\"%s\"", savepath) }
    local unix_args = { 'mkdir', '-p', savepath }
    local args = is_windows and windows_args or unix_args
    local res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
    if res.status ~= 0 then
      msg.error("Failed to create target_dir save directory "..savepath..". Error: "..(res.error or "unknown"))
      return
    end
elseif not file.is_dir then
    osd("target_dir is a file")
    msg.warn(string.format("target_dir `%s` is a file", o.target_dir))
end
o.target_dir = mp.command_native({ "expand-path", o.target_dir })

mp.add_key_binding("c", "slicing_mark", toggle_mark)
mp.add_key_binding("a", "slicing_audio", toggle_audio)
mp.add_key_binding("C", "clear_slicing_mark", clear_toggle_mark)
