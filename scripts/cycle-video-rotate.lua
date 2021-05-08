-- -----------------------------------------------------------
--
-- CYCLE-VIDEO-ROTATE.LUA
-- Version: 1.0
-- Author: VideoPlayerCode
-- URL: https://github.com/VideoPlayerCode/mpv-tools
--
-- Description:
--
--  Allows you to perform video rotation which perfectly
--  cycles through all 360 degrees without any glitches.
--
-- -----------------------------------------------------------

function cycle_video_rotate(amt)
    -- Ensure that amount is a base 10 integer.
    amt = tonumber(amt, 10)
    if amt == nil then
        mp.osd_message("Rotate: Invalid rotation amount")
        return nil -- abort
    end

    -- Calculate what the next rotation value should be,
    -- and wrap value to correct range (0 (aka 360) to 359).
    local newrotate = mp.get_property_number("video-rotate")
    newrotate = ( newrotate + amt ) % 360

    -- Change rotation and tell the user.
    mp.set_property_number("video-rotate", newrotate)
    mp.osd_message("Rotate: " .. newrotate)
end

-- Bind this via input.conf. Example:
--   Alt+LEFT script-message Cycle_Video_Rotate -90
--   Alt+RIGHT script-message Cycle_Video_Rotate 90
mp.register_script_message("Cycle_Video_Rotate", cycle_video_rotate)