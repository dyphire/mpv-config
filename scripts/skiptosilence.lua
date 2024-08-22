--[[
  * skiptosilence.lua v.2024-08-22
  *
  * AUTHORS: detuur, microraptor, Eisa01, dyphire
  * License: MIT
  * link: https://github.com/detuur/mpv-scripts
  * 
  * This script skips to the next silence in the file. The
  * intended use for this is to skip until the end of an
  * opening sequence, at which point there's often a short
  * period of silence.
  *
  * The default keybind is F3. You can change this by adding
  * the following line to your input.conf:
  *     KEY script-binding skip-to-silence
  * 
  * In order to tweak the script parameters, you can place the
  * text below, between the template markers, in a new file at
  * script-opts/skiptosilence.conf in mpv's user folder. The
  * parameters will be automatically loaded on start.
  *
  * Dev note about the used filters:
  * - `silencedetect` is an audio filter that listens for silence and
  * emits text output with details whenever silence is detected.
  * Filter documentation: https://ffmpeg.org/ffmpeg-filters.html
****************** TEMPLATE FOR skiptosilence.conf ******************
#--(#number). Maximum amount of noise to trigger, in terms of dB. Lower is more sensitive.
silence_audio_level=-40

#--(#number). Duration of the silence that will be detected to trigger skipping.
silence_duration=0.7

#--(0/#number). The first detcted silence_duration will be ignored for the defined seconds in this option, and it will continue skipping until the next silence_duration.
# (0 for disabled, or specify seconds).
ignore_silence_duration=1

#--(0/#number). Minimum amount of seconds accepted to skip until the configured silence_duration.
# (0 for disabled, or specify seconds)
min_skip_duration=0

#--(0/#number). Maximum amount of seconds accepted to skip until the configured silence_duration.
# (0 for disabled, or specify seconds)
max_skip_duration=120

#--(yes/no). Default is muted, however if audio was enabled due to custom mpv settings, the fast-forwarded audio can sound jarring.
force_mute_on_skip=no

************************** END OF TEMPLATE **************************
--]]

local o = {
    silence_audio_level = -40,
    silence_duration = 0.7,
    ignore_silence_duration=1,
    min_skip_duration = 0,
    max_skip_duration = 120,
    force_mute_on_skip = false,
}

(require 'mp.options').read_options(o)
local mp = require 'mp'
local msg = require 'mp.msg'

speed_state = 1
pause_state = false
mute_state = false
sub_state = nil
secondary_sub_state = nil
vid_state = nil
geometry_state = nil
skip_flag = false
initial_skip_time = 0

local function restoreProp(pause)
    if not pause then pause = pause_state end
    local fullscreen = mp.get_property("fullscreen")

    mp.set_property("vid", vid_state)
    if not fullscreen then
        mp.set_property("geometry", geometry_state)
    end
    mp.set_property_bool("mute", mute_state)
    mp.set_property("speed", speed_state)
    mp.unobserve_property(foundSilence)
    mp.command("no-osd af remove @skiptosilence")
    mp.set_property_bool("pause", pause)
    mp.set_property("sub-visibility", sub_state)
    mp.set_property("secondary-sub-visibility", secondary_sub_state)
    timer:kill()
    skip_flag = false
end

local function handleMinMaxDuration(timepos)
    if not skip_flag then return end
    if not timepos then timepos = mp.get_property_number("time-pos") end

    skip_duration = timepos - initial_skip_time
    if o.min_skip_duration > 0 and skip_duration <= o.min_skip_duration then
        restoreProp()
        mp.osd_message('Skipping Cancelled\nSilence is less than configured minimum')
        msg.info('Skipping Cancelled\nSilence is less than configured minimum')
        return true
    end
    if o.max_skip_duration > 0 and skip_duration >= o.max_skip_duration then
        restoreProp()
        mp.osd_message('Skipping Cancelled\nSilence is more than configured maximum')
        msg.info('Skipping Cancelled\nSilence is more than configured maximum')
        return true
    end
    return false
end

local function skippedMessage()
    mp.osd_message("Skipped to silence at " .. mp.get_property_osd("time-pos"))
    msg.info("Skipped to silence at " .. mp.get_property_osd("time-pos"))
end

function foundSilence(name, value)
    if value == "{}" or value == nil then
        return
    end

    timecode = tonumber(string.match(value, "%d+%.?%d+"))
    if timecode == nil or timecode < initial_skip_time + o.ignore_silence_duration then
        return
    end

    if handleMinMaxDuration(timecode) then return end

    restoreProp()

    mp.add_timeout(0.05, skippedMessage)
    skip_flag = false
end

local function doSkip()
    local audio = mp.get_property_number("aid") or 0
    if audio == 0 then
        mp.osd_message("No audio stream detected")
        msg.info("No audio stream detected")
        return
    end
    if skip_flag then return end
    initial_skip_time = (mp.get_property_native("time-pos") or 0)
    if math.floor(initial_skip_time) == math.floor(mp.get_property_native('duration') or 0) then return end

    local width = mp.get_property_native("osd-width")
    local height = mp.get_property_native("osd-height")
    local fullscreen = mp.get_property_native("fullscreen")
    geometry_state = mp.get_property("geometry")
    if not fullscreen then
        mp.set_property_native("geometry", ("%dx%d"):format(width, height))
    end

    mp.command(
        "no-osd af add @skiptosilence:lavfi=[silencedetect=noise=" ..
        o.silence_audio_level .. "dB:d=" .. o.silence_duration .. "]"
    )

    mp.observe_property("af-metadata/skiptosilence", "string", foundSilence)

    sub_state = mp.get_property("sub-visibility")
    mp.set_property("sub-visibility", "no")
    secondary_sub_state = mp.get_property("secondary-sub-visibility")
    mp.set_property("secondary-sub-visibility", "no")
    vid_state = mp.get_property("vid")
    mp.set_property("vid", "no")
    mute_state = mp.get_property_native("mute")
    if o.force_mute_on_skip then
        mp.set_property_bool("mute", true)
    end
    pause_state = mp.get_property_native("pause")
    mp.set_property_bool("pause", false)
    speed_state = mp.get_property_native("speed")
    mp.set_property("speed", 100)
    skip_flag = true

    timer = mp.add_periodic_timer(0.5, function()
        local video_time = (mp.get_property_native("time-pos") or 0)
        handleMinMaxDuration(video_time)
    end)
end


mp.observe_property('pause', 'bool', function(_, value)
    if value and skip_flag then
        restoreProp(true)
    end
end)

mp.observe_property('percent-pos', 'number', function(_, value)
    if skip_flag and value and value > 99 then
        local fullscreen = mp.get_property("fullscreen")
        mp.set_property("vid", vid_state)
        if not fullscreen then
            mp.set_property("geometry", geometry_state)
        end
    end
end)

mp.add_hook('on_unload', 9, function()
    if skip_flag then
        restoreProp()
    end
end)

mp.add_key_binding(nil, "skip-to-silence", doSkip)