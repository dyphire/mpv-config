--[[
    When switching the audio track, if there is audio filter then seek to repair the freezing of video.
    available at: https://github.com/dyphire/mpv-scripts
]]--

require "mp"

local audio_filter = mp.get_property("options/af")
local seekback = "no-osd seek -0.1 exact"
local seekfor  = "no-osd seek  0.1 exact"

function fix_af_out ()
  if audio_filter ~= nil then
    mp.command(seekback)
    mp.command(seekfor)
  end
end

mp.register_event("audio-reconfig", fix_af_out)