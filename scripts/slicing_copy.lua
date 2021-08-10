local msg = require "mp.msg"
local utils = require "mp.utils"
local options = require "mp.options"

local cut_pos = nil
local copy_audio = true
local command_template = {
    ss = "$shift",
    t = "$duration",
}
local o = {
    ffmpeg_path = "ffmpeg",
    target_dir = "~~/cutfragments",
    overwrite = false, -- whether to overwrite exist files
    vcodec = "copy",
    acodec = "copy",
}

Command = { }

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
    local filename = mp.get_property('filename')
    local name = mp.get_property('filename/no-ext')
    return filename:sub(name:len() + 2)
end

local function timestamp(duration)
    local hours = math.floor(duration / 3600)
    local minutes = math.floor(duration % 3600 / 60)
    local seconds = duration % 60
    return string.format("%02d:%02d:%02.03f", hours, minutes, seconds)
end

local function osd(str)
    return mp.osd_message(str, 3)
end

local function info(s)
    msg.info(s)
    osd(s)
end

local function get_outname(shift, endpos)
    local name = mp.get_property("filename/no-ext")
    local fmt = file_format()
    name = string.format("%s_%s-%s.%s", name, timestamp(shift), timestamp(endpos), fmt)
    return name:gsub(":", "-")
end

local function cut(shift, endpos)
    local inpath = mp.get_property("stream-open-filename")
    local outpath = utils.join_path(
        o.target_dir,
        get_outname(shift, endpos)
    )
    local ua = mp.get_property('user-agent')
    local referer = mp.get_property('referrer')
    local cmds = Command:new(o.ffmpeg_path)
        :arg("-v", "warning")
        :arg(o.overwrite and "-y" or "-n")
        :arg("-stats")
    if ua and ua ~= '' and ua ~= 'libmpv' then
        cmds:arg('-user_agent', ua)
    end
    if referer and referer ~= '' then
        cmds:arg('-referer', referer)
    end
    cmds:arg("-ss", (command_template.ss:gsub("$shift", shift)))
        :arg("-i", inpath)
        :arg("-t", (command_template.t:gsub("$duration", endpos - shift)))
        :arg("-c:v", o.vcodec)
        :arg("-c:a", o.acodec)
        :arg(not copy_audio and "-an" or nil)
        :arg(outpath)
    msg.info("Run commands: " .. cmds:as_str())
    local res, err = cmds:run()
    if err then
        msg.error(utils.to_string(err))
    elseif res.stderr ~= "" or res.stdout ~= "" then
        msg.info("stderr: " .. (res.stderr:gsub("^%s*(.-)%s*$", "%1"))) -- trim stderr
        msg.info("stdout: " .. (res.stdout:gsub("^%s*(.-)%s*$", "%1"))) -- trim stdout
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

options.read_options(o)
o.target_dir = o.target_dir:gsub('"', "")
file, _ = utils.file_info(mp.command_native({ "expand-path", o.target_dir }))
if not file then
    osd("target_dir may not exist")
    msg.warn(string.format("target_dir `%s` may not exist", o.target_dir))
elseif not file.is_dir then
    osd("target_dir is a file")
    msg.warn(string.format("target_dir `%s` is a file", o.target_dir))
end
o.target_dir = mp.command_native({ "expand-path", o.target_dir })
mp.add_key_binding("c", "slicing_mark", toggle_mark)
mp.add_key_binding("a", "slicing_audio", toggle_audio)
mp.add_key_binding("CTRL+c", "clear_slicing_mark", clear_toggle_mark)