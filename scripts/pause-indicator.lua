--[[
    Prints a pause icon in the middle of the screen when mpv is paused
    available at: https://github.com/CogentRedTester/mpv-scripts
]]--

local mp = require 'mp'
local ov = mp.create_osd_overlay('ass-events')
ov.data = [[{\an5\p1\alpha&H79\1c&H0000&\3a&Hff}]] ..
          [[m30 15 b37 8 112 8 117 15 b125 22 125 75 118 82 b112 89 38 89 30 82 b23 75 23 22 30 15 m76 108]] ..
          [[{\alpha&H10\1c&Hffffff&\3a&Hff} m-45 -25 l 2 2 l -45 28{\p0}]]

mp.observe_property('pause', 'bool', function(_, paused)
    mp.add_timeout(0.1, function()
        if paused then ov:update()
        else ov:remove() end
    end)
end)
