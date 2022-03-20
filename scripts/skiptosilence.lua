--[[
  * skiptosilence.lua v.2022-02-27
  *
  * AUTHORS: detuur, microraptor
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

--[[
Dev note about the used filters:
- `silencedetect` is an audio filter that listens for silence and
  emits text output with details whenever silence is detected.
- `nullsink` interrupts the video stream requests to the decoder,
  which stops it from bogging down the fast-forward.
- `color` generates a blank image, which renders very quickly and is
  good for fast-forwarding.
- Filter documentation: https://ffmpeg.org/ffmpeg-filters.html
--]]

function doSkip()
    -- Get video dimensions
    local width = mp.get_property_native("width");
    local height = mp.get_property_native("height")

    -- Create audio and video filters
    mp.command(
        "no-osd af add @skiptosilence:lavfi=[silencedetect=noise=" ..
        opts.quietness .. "dB:d=" .. opts.duration .. "]"
    )
    mp.command(
        "no-osd vf add @skiptosilence-blackout:lavfi=" ..
        "[nullsink,color=c=black:s=" .. width .. "x" .. height .. "]"
    )

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

    -- Remove used audio and video filters
    mp.command("no-osd af remove @skiptosilence")
    mp.command("no-osd vf remove @skiptosilence-blackout")

    -- Seeking to the exact moment even though we've already
    -- fast forwarded here allows the video decoder to skip
    -- the missed video. This prevents massive A-V lag.
    mp.set_property_number("time-pos", timecode)

    -- If we don't wait at least 50ms before messaging the user, we
    -- end up displaying an old value for time-pos.
    mp.add_timeout(0.05, skippedMessage)
end

function skippedMessage()
    msg.info("Skipped to silence at " .. mp.get_property_osd("time-pos"))
    mp.osd_message("Skipped to silence at " .. mp.get_property_osd("time-pos"))
end

options.read_options(opts)

mp.register_script_message("skip-to-silence", doSkip)