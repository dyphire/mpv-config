--[[
    When switching the audio track, if there is audio filter then repair the freezing of video by frame step-back.
    At the same time, fix the compatibility problem between speed and audio filter.
    available at: https://github.com/dyphire/mpv-scripts
]] --

local mp = require "mp"
local msg = require "mp.msg"

local function fix_avsync()
    local paused = mp.get_property_native("pause")
    local muted = mp.get_property_native("mute")
    msg.info("fix A/V sync.")
    mp.commandv("frame-step")
    mp.set_property_native("mute", true)
    mp.add_timeout(0.1, function()
        mp.commandv("frame-back-step")
        if paused then return
        else mp.set_property_native("pause", false) end
    end)
    mp.add_timeout(0.5, function()
        if muted then return
        else mp.set_property_native("mute", false) end
    end)
end

local function fix_speedout()
    local afs = mp.get_property_native("af")
    for _, af in pairs(afs) do
        if af["name"] ~= nil and af["name"] ~= "" then
            msg.info("fix A/V sync.")
            mp.set_property_native("af", "")
        end
    end
end

mp.register_event("file-loaded", function()
    mp.observe_property("aid", "string", fix_avsync)
    mp.observe_property("speed", "number", fix_speedout)
end)

mp.register_event("end-file", function()
    mp.unobserve_property(fix_avsync)
    mp.unobserve_property(fix_speedout)
end)
