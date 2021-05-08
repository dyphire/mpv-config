-- -----------------------------------------------------------
--
-- QUICK-SCALE.LUA
-- Version: 1.1
-- Author: VideoPlayerCode
-- URL: https://github.com/VideoPlayerCode/mpv-tools
--
-- Description:
--
--  Quickly scale the video player to a target size,
--  with full control over target scale and max scale.
--  Helps you effortlessly resize a video to fit on your
--  desktop, or any other video dimensions you need!
--
-- History:
--
--  1.0: Initial release.
--  1.1: Do nothing if mpv is in fullscreen mode.
--
-- -----------------------------------------------------------
--
-- Parameters:
-- targetwidth = How wide you want the target area to be.
-- targetheight = How tall you want the target area to be.
-- targetscale = If this is 1, we use your target width/height
--   as-is, but if it's another value then we scale your provided
--   target size by that amount. This parameter is great if you want
--   a video to be a certain percentage of your desktop resolution.
--   In that case, just set targetwidth/targetheight to your
--   desktop resolution, and set this targetscale to the percentage
--   of your desktop that you want to use for the video, such as
--   "0.25" to resize the video to 25% of your desktop resolution.
-- maxvideoscale = If this is a positive number (anything above 0),
--   then the final video scale cannot exceed this number.
--   This is useful if you for example set the target to 25%
--   of your desktop resolution. If the video is smaller than that,
--   then it would be scaled up (enlarged) to the size of the target.
--   To control that behavior, simply set this parameter.
--   Here are some examples:
--    -1, 0, or any other non-positive number: We'll enlarge
--      too-small videos and shrink too-large videos. Small videos
--      will be enlarged as much as needed to match target size.
--    1: Video will only be allowed to enlarge to 100% of its natural size.
--      This means that small videos won't become big and blurry.
--    1.5: Video will only be allowed to enlarge to 150% of its natural size.
function quick_scale(targetwidth, targetheight, targetscale, maxvideoscale)
    -- Don't attempt to scale the fullscreen window.
    if (mp.get_property_bool("fullscreen", false)) then
        return nil -- abort
    end

    -- Check parameter existence.
    if (targetwidth == nil or targetheight == nil
            or targetscale == nil or maxvideoscale == nil)
    then
        mp.osd_message("Quick_Scale: Missing parameters")
        return nil -- abort
    end

    -- Ensure that the incoming strings are valid numbers.
    targetwidth = tonumber(targetwidth)
    targetheight = tonumber(targetheight)
    targetscale = tonumber(targetscale)
    maxvideoscale = tonumber(maxvideoscale)
    if (targetwidth == nil or targetheight == nil
            or targetscale == nil or maxvideoscale == nil)
    then
        mp.osd_message("Quick_Scale: Non-numeric parameters")
        return nil -- abort
    end

    -- If the target scale isn't 1 (100%), we'll re-calculate target size.
    if (targetscale ~= 1) then
        targetwidth = targetwidth * targetscale
        targetheight = targetheight * targetscale
    end

    -- Find smallest video scale that fits target size in both width and height.
    -- This only looks at video and doesn't take window borders into account!
    widthscale = targetwidth / mp.get_property("width")
    heightscale = targetheight / mp.get_property("height")
    local scale = (widthscale < heightscale and widthscale or heightscale)

    -- If we arrived at a target width/height that is larger than the video's
    -- natural "100%" scale, then we may want to limit it to a maximum amount.
    if (maxvideoscale > 0 and scale > maxvideoscale) then
        scale = maxvideoscale
    end

    -- Apply the new video scale.
    mp.set_property_number("window-scale", scale)
end

-- Bind this via input.conf. Examples:
--   To fit a video to 100% of a 1680x1050 desktop size, with unlimited video enlarging:
--     Alt+9 script-message Quick_Scale "1680" "1050" "1" "-1"
--   To fit a video to 80% of a 1680x1050 desktop size, but disallowing the
--     video from becoming larger than 150% of its natural size:
--     Alt+9 script-message Quick_Scale "1680" "1050" "0.8" "1.5"
--   To fit a video to a 200x200 box, with unlimited video enlarging:
--     Alt+9 script-message Quick_Scale "200" "200" "1" "-1"
mp.register_script_message("Quick_Scale", quick_scale)