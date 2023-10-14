-- mediaInfo.lua v2023.04.05

--[[
    Use MediaInfo to get media info and print it on OSD.
    And shared the 'hdr-format' property by 'shared_script_properties', available for conditional profiles.
    available at: https://github.com/dyphire/mpv-scripts
]] --

local utils = require 'mp.utils'

local o = {
    mediainfo_path = "MediaInfo",
}

opt = require "mp.options"
opt.read_options(o)

utils.shared_script_property_set("hdr-format", "")
mp.set_property_native("user-data/mediainfo/hdr-format", "")

----- string
local function is_empty(input)
    if input == nil or input == "" then
        return true
    end
end

local function contains(input, find)
    if not is_empty(input) and not is_empty(find) then
        return input:find(find, 1, true)
    end
end

local function replace(str, what, with)
    if is_empty(str) then return "" end
    if is_empty(what) then return str end
    if with == nil then with = "" end
    what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1")
    with = string.gsub(with, "[%%]", "%%%%")
    return string.gsub(str, what, with)
end

----- file
local function file_exists(path)
    local file = io.open(path, "r")

    if file ~= nil then
        io.close(file)
        return true
    end
end

local function file_write(path, content)
    local file = assert(io.open(path, "w"))
    file:write(content)
    file:close()
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

o.mediainfo_path = mp.command_native({ "expand-path", o.mediainfo_path })
mediainfo_path = is_empty(o.mediainfo_path) and find_executable(o.mediainfo_path) or o.mediainfo_path

media_info_format = [[General;N: %FileNameExtension%\\nG: %Format%, %FileSize/String%, %Duration/String%, %OverallBitRate/String%, %Recorded_Date%\\n
Video;V: %Format%, %HDR_Format/String%, %Format_Profile%, %Width%x%Height%, %BitRate/String%, %FrameRate% FPS\\n
Audio;A: %Language/String%, %Format%, %Format_Profile%, %BitRate/String%, %Channel(s)% ch, %SamplingRate/String%, %Title%\\n
Text;S: %Language/String%, %Format%, %Format_Profile%, %Title%\\n]]

function show_text(text, duration, font_size)
    mp.command('show-text "${osd-ass-cc/0}{\\\\fs' .. font_size ..
        '}${osd-ass-cc/1}' .. text .. '" ' .. duration)
end

function on_print_media_info()
    local path = mp.get_property("path")

    if contains(path, "://") or not file_exists(path) then
        return
    end

    local arg2 = "--inform=" .. media_info_format

    local r = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        args = {"mediainfo", arg2, path},
    })

    if r.status == 0 then
        local output = r.stdout

        output = string.gsub(output, ", , ,", ",")
        output = string.gsub(output, ", ,", ",")
        output = string.gsub(output, ": , ", ": ")
        output = string.gsub(output, ", \\n\r*\n", "\\n")
        output = string.gsub(output, "\\n\r*\n", "\\n")
        output = string.gsub(output, ", \\n", "\\n")
        output = string.gsub(output, "%.000 FPS", " FPS")

        if contains(output, "MPEG Audio, Layer 3") then
            output = replace(output, "MPEG Audio, Layer 3", "MP3")
        end

        show_text(output, 5000, 10)
    end
end

function get_hdr_format()
    local path = mp.get_property("path")

    if contains(path, "://") or not file_exists(path) then
        return
    end

    local arg2 = "--inform=Video;%HDR_Format/String%\\n"

    local r = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        args = {mediainfo_path, arg2, path},
    })

    if r.status == 0 then
        local output = r.stdout

        output = string.gsub(output, "\r", "")
        output = string.gsub(output, "\n*$", "")
        output = string.gsub(output, "\n", "; ")

        utils.shared_script_property_set("hdr-format", output)
        mp.set_property_native("user-data/mediainfo/hdr-format", output)
    end
end

mp.register_event("start-file", get_hdr_format)
mp.register_script_message("print-media-info", on_print_media_info)
