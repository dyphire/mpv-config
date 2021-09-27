-- autosave.lua
--
-- Periodically saves "watch later" data during playback, rather than only saving on quit.
-- This lets you easily recover your position in the case of an ungraceful shutdown of mpv (crash, power failure, etc.).
--
-- You can configure the save period by creating a "lua-settings" directory inside your mpv configuration directory.
-- Inside the "lua-settings" directory, create a file named "autosave.conf".
-- The save period can be set like so:
--
-- save_period=60
--
-- This will set the save period to once every 60 seconds of playback, time while paused is not counted towards the save period timer.
-- The default save period is 30 seconds.
local options = require 'mp.options'

local o = {
	save_period = 30
}

options.read_options(o)

local mp = require 'mp'

local function save()
	mp.commandv("set", "msg-level", "cplayer=warn")
	mp.command("write-watch-later-config")
	mp.commandv("set", "msg-level", "cplayer=status")
end

local save_period_timer = mp.add_periodic_timer(o.save_period, save)

local function pause(name, paused)
	save()
	if paused then
		save_period_timer:stop()
	else
		save_period_timer:resume()
	end
end

mp.observe_property("pause", "bool", pause)
mp.register_event("file-loaded", save)

local function end_file(data)
	if data.reason == 'eof' or data.reason == 'stop' then
		local playlist = mp.get_property_native('playlist')
		for i, entry in pairs(playlist) do
			if entry.id == data.playlist_entry_id then
				mp.commandv("delete-watch-later-config", entry.filename)
				return
			end
		end
	end
end
mp.register_event("end-file", end_file)
