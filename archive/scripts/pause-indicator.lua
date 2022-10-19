--[[
    Prints a pause icon in the middle of the screen when mpv is paused
]]--

local mp = require "mp"

local ov = mp.create_osd_overlay('ass-events')

ov.data = "{\\a7\\fs26}⏸"

mp.observe_property('pause', 'bool', function(_, paused)
    idle = mp.get_property_native("idle-active")
    mp.add_timeout(0.1, function()
        if paused and not idle then ov:update()
        else ov:remove() end
    end)
end)
