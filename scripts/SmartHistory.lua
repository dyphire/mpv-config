-- Copyright (c) 2021, Eisa AlAwadhi
-- License: BSD 2-Clause License

-- Creator: Eisa AlAwadhi
-- Project: SmartHistory
-- Version: 1.9

local utils = require 'mp.utils'
local msg = require 'mp.msg'
local empty = false
local lastVideoTime

----------------------------USER CUSTOMIZATION SETTINGS-----------------------------------
--These settings are for users to manually change some options in the script.
--Keybinds can be defined in the bottom of the script.

local offset = -0.65 --change to 0 so that pasting resumes from the exact position, or decrease the value so that it gives you a little preview before reaching the exact pasted position

local osd_messages = true --true is for displaying osd messages when actions occur, Change to false will disable all osd messages generated from this script
---------------------------END OF USER CUSTOMIZATION SETTINGS------------------------


mp.register_event('file-loaded', function()
	filePath = mp.get_property('path')

	if (empty == true) then
		local seekTime
		if (lastVideoTime ~= nil) then
			
			seekTime = lastVideoTime + offset
			if (seekTime < 0) then
				seekTime = 0
			end
			
			mp.commandv('seek', seekTime, 'absolute', 'exact')
			
			empty = false
		end
	end
end)

mp.add_hook('on_unload', 50, function()
	empty = false
	local historyLog = mp.find_config_file(".")..'mpvHistory.log'
	local historyLogAdd = io.open(historyLog, 'a+')
	
	local seconds = math.floor(mp.get_property_number('time-pos') or 0)
	
	if (filePath ~= nil) then
		historyLogAdd:write(('[%s] %s\n'):format(os.date('%d/%b/%y %X'), filePath..' |time='..tostring(seconds)))
		historyLogAdd:close()
	end
end)

local function resume()
	local historyLog = mp.find_config_file(".")..'mpvHistory.log'
	local historyLogOpen = io.open(historyLog, 'r')
	local historyLogAdd = io.open(historyLog, 'a+')
	local filePath = mp.get_property('path')
	local linePosition
	local videoFound
	local currentVideo
	local currentVideoTime
	local seekTime
	
	if (filePath ~= nil) then
		for line in historyLogOpen:lines() do
		   
		   linePosition = line:find(']')
		   line = line:sub(linePosition + 2)
		   
			if line.match(line, '(.*) |time=') == filePath then
				videoFound = line
			end
		   
		end
		
	if (videoFound ~= nil) then
		currentVideo = string.match(videoFound, '(.*) |time=')
		currentVideoTime = string.match(videoFound, ' |time=(.*)')

		if (filePath == currentVideo) and (currentVideoTime ~= nil) then
			if (osd_messages == true) then
				mp.osd_message('Resumed To Last Logged Position')
			end
			seekTime = currentVideoTime + offset
			if (seekTime < 0) then
				seekTime = 0
			end
		
			mp.commandv('seek', seekTime, 'absolute', 'exact')
			msg.info('Resumed to the last logged position for this video')
		end
	else
		if (osd_messages == true) then
			mp.osd_message('No Resume Position Found For This Video')
		end
		msg.info('No resume position logged found for this video')
	end
	else
		empty = true
		lastPlay()
	end
	historyLogAdd:close()
	historyLogOpen:close()
end

function lastPlay()
	local historyLog = mp.find_config_file(".")..'mpvHistory.log'
	local historyLogAdd = io.open(historyLog, 'a+')
	local historyLogOpen = io.open(historyLog, 'r+')
    local linePosition
	local videoFile
	local lastVideoFound

	for line in historyLogOpen:lines() do
		lastVideoFound = line
	end
	historyLogAdd:close()
	historyLogOpen:close()

	if (lastVideoFound ~= nil) then
		linePosition = lastVideoFound:find(']')
		lastVideoFound = lastVideoFound:sub(linePosition + 2)
		
		if string.match(lastVideoFound, '(.*) |time=') then
			videoFile = string.match(lastVideoFound, '(.*) |time=')
			lastVideoTime = string.match(lastVideoFound, ' |time=(.*)')
		else
			videoFile = lastVideoFound
		end
		
		if (filePath ~= nil) then
			if (osd_messages == true) then
				mp.osd_message('Added Last Logged Item Into Playlist:\n'..videoFile)
			end
			mp.commandv('loadfile', videoFile, 'append-play')
			msg.info('Added last logged item shown below into playlist:\n'..videoFile)
		else
			if (empty == false) then
				if (osd_messages == true) then
					mp.osd_message('Loaded Last Item:\n'..videoFile)
				end
				msg.info('Loaded the last logged item shown below into mpv:\n'..videoFile)
			else
				if (osd_messages == true) then
					mp.osd_message('Resumed Last Item:\n'..videoFile)
				end
				msg.info('Resumed the last logged item shown below into mpv:\n'..videoFile)
			end
			mp.commandv('loadfile', videoFile)
		end
	else
		if (osd_messages == true) then
			mp.osd_message('History is Empty')
		end
		msg.info('History log file is empty')
	end
end

---------------------------KEYBINDS CUSTOMIZATION SETTINGS---------------------------------

mp.add_key_binding("ctrl+r", "resume", resume)
mp.add_key_binding("ctrl+R", "resumeCaps", resume)

mp.add_key_binding("ctrl+l", "lastPlay", lastPlay)
mp.add_key_binding("ctrl+L", "lastPlayCaps", lastPlay)

---------------------END OF KEYBINDS CUSTOMIZATION SETTINGS---------------------------------
