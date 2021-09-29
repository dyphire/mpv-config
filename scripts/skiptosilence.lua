--[[
  * skiptosilence.lua v.2020-01-25
  *
  * AUTHOR: detuur
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
****************** TEMPLATE FOR skiptosilence.conf ******************
# Maximum amount of noise to trigger, in terms of dB.
# The default is -30 (yes, negative). -60 is very sensitive,
# -10 is more tolerant to noise.
quietness = -30

# Minimum duration of silence to trigger.
duration = 0.1

# The fast-forwarded audio can sound jarring. Set to 'yes'
# to mute it while skipping.
mutewhileskipping = no
************************** END OF TEMPLATE **************************
--]]

local opts = {
    quietness = -30,
    duration = 0.1,
    mutewhileskipping = false
}

local mp = require 'mp'
local msg = require 'mp.msg'
local options = require 'mp.options'

old_speed = 1
was_paused = false
was_muted = false

function doSkip()
    setAudioFilter(true)
    setVideoFilter(true, mp.get_property_native("width"), mp.get_property_native("height"))

    -- Triggers whenever the `silencedetect` filter emits output
    mp.observe_property("af-metadata/skiptosilence", "string", foundSilence)

    was_muted = mp.get_property_native("mute")
    if opts.mutewhileskipping then
        mp.set_property_bool("mute", true)
    end

    was_paused = mp.get_property_native("pause")
    mp.set_property_bool("pause", false)
    old_speed = mp.get_property_native("speed")
    mp.set_property("speed", 100)
end

function foundSilence(name, value)
    if value == "{}" or value == nil then
        return -- For some reason these are sometimes emitted. Ignore.
    end

    timecode = tonumber(string.match(value, "%d+%.?%d+"))
    time_pos = mp.get_property_native("time-pos")
    if timecode == nil or timecode < time_pos + 1 then
        return -- Ignore anything less than a second ahead.
    end

    mp.set_property_bool("mute", was_muted)
    mp.set_property_bool("pause", was_paused)
    mp.set_property("speed", old_speed)
    mp.unobserve_property(foundSilence)

    setAudioFilter(false)
    setVideoFilter(false, 0, 0)

    -- Seeking to the exact moment even though we've already
    -- fast forwarded here allows the video decoder to skip
    -- the missed video. This prevents massive A-V lag.
    mp.set_property_number("time-pos", timecode)
    -- If we don't wait at least 50ms before messaging the user, we
    -- end up displaying an old value for time-pos.
    mp.add_timeout(0.05, osdSkippedMessage)
end

function osdSkippedMessage()
    mp.osd_message("Skipped to "..mp.get_property_osd("time-pos"))
end


-- Adds the filters to the filtergraph on mpv init
-- in a disabled state.
-- Filter documentation: https://ffmpeg.org/ffmpeg-filters.html
function init()
    -- `silencedetect` is an audio filter that listens for silence
    -- and emits text output with details whenever silence is detected.
    local af_table = mp.get_property_native("af")
    af_table[#af_table + 1] = {
        enabled=false,
        label="skiptosilence",
        name="lavfi",
        params= {
            graph = "silencedetect=noise="..opts.quietness.."dB:d="..opts.duration
        }
    }
    mp.set_property_native("af", af_table)

    -- `nullsink` interrupts the video stream requests to the decoder,
    -- which stops it from bogging down the fast-forward.
    -- `color` generates a blank image, which renders very quickly and
    -- is good for fast-forwarding.
    -- The graph is not actually filled in now, but when toggled on,
    -- as it needs the resolution information.
    local vf_table = mp.get_property_native("vf")
    vf_table[#vf_table + 1] = {
        enabled=false,
        label="skiptosilence-blackout",
        name="lavfi",
        params= {
            graph = "" --"nullsink,color=c=black:s=1920x1080"
        }
    }
    mp.set_property_native("vf", vf_table)
end

function setAudioFilter(state)
    local af_table = mp.get_property_native("af")
    if #af_table > 0 then
        for i = #af_table, 1, -1 do
            if af_table[i].label == "skiptosilence" then
                af_table[i].enabled = state
                mp.set_property_native("af", af_table)
                return
            end
        end
    end
end

function setVideoFilter(state, width, height)
    local vf_table = mp.get_property_native("vf")
    if #vf_table > 0 then
        for i = #vf_table, 1, -1 do
            if vf_table[i].label == "skiptosilence-blackout" then
                vf_table[i].enabled = state
                vf_table[i].params = {
                    graph = "nullsink,color=c=black:s="..width.."x"..height
                }
                mp.set_property_native("vf", vf_table)
                return
            end
        end
    end
end

options.read_options(opts)
init()

mp.register_script_message("skip-to-silence", doSkip)