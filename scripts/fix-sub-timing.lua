--[[
How to use:

The shortcut to adjust timing is set to ctrl+w by default.

Edit your input.conf and bind "sub-step 1" and "sub-step -1" to two keys, e.g.:

ctrl+z sub-step -1
ctrl+x sub-step 1

Start the video, and manually synchronize the first subtitle to audio (waiting
for someone to speak and then selecting the right subtitle with ctrl+z/ctrl+x
works best). Then hit ctrl+w to mark the first point. Go on to a later time
where someone speaks, and synchronize the right subtitle again. Then hit ctrl+w
again to mark this as the second point. The script will choose a sub-delay
and sub-speed value that makes the two points you marked show the subtitles
as you timed them when hitting the shortcut.

Technically, this assumes:

   sub_time = (vid_time - sub_delay) / sub_speed

which is probably what mpv does internally. Using two points in time, we can
compute the required sub_delay and sub_speed to get to the two points to display
the 2 subtitle events at the marked times with the same delay.
]]

sub_time_1 = nil
vid_time_1 = nil
sub_time_2 = nil
vid_time_2 = nil

function sub_set_time()
    local sub_delay = mp.get_property_native("sub-delay")
    local vid_time = mp.get_property_native("playback-time")
    local sub_speed = mp.get_property_native("sub-speed")
    local sub_time = (vid_time - sub_delay) / sub_speed

    if sub_time_1 == nil then
        vid_time_1 = vid_time
        sub_time_1 = sub_time
        mp.osd_message("Mark time 1")
        return
    end

    if sub_time_2 ~= nil then
        sub_time_1 = sub_time_2
        vid_time_1 = vid_time_2
    end

    if sub_time_1 == sub_time or vid_time_1 == vid_time then
        return
    end

    sub_time_2 = sub_time
    vid_time_2 = vid_time

    -- sub_time_1 = (vid_time_1 - delay) / speed
    -- sub_time_2 = (vid_time_2 - delay) / speed

    local new_speed = (vid_time_2 - vid_time_1) / (sub_time_2 - sub_time_1)
    local new_delay = vid_time_2 - sub_time_2 * new_speed

    print("delay=" .. tostring(new_delay) .. " speed=" .. tostring(new_speed))

    mp.set_property_native("sub-delay", new_delay)
    mp.set_property_native("sub-speed", new_speed)
end

mp.add_key_binding("ctrl+w", "sub-set-time", sub_set_time)