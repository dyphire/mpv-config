--[[
    Fixed A/V sync when switching the audio output device with using audio filters
    available at: https://github.com/dyphire/mpv-scripts
]]--

local msg = require "mp.msg"

local function fix_avsync()
    local paused = mp.get_property_bool("pause")
    msg.info("fix A/V sync.")
    mp.commandv("frame-back-step")
    if paused then
        return
    else
        mp.set_property_bool("pause", false)
    end
end

mp.observe_property("current-ao", "native", function(_, device)
    local aid = mp.get_property_number("aid")
    local has_af = mp.get_property("af", "") ~= ""
    if device and aid and has_af then
        fix_avsync()
    end
end)