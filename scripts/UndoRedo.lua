-- Copyright (c) 2021, Eisa AlAwadhi
-- License: BSD 2-Clause License

-- Creator: Eisa AlAwadhi
-- Project: UndoRedo
-- Version: 2.2

local utils = require 'mp.utils'
local msg = require 'mp.msg'
local seconds = 0
local countTimer = -1
local seekTime = 0
local seekNumber = 0
local currentIndex = 0
local seekTable = {}
local seeking = 0
local undoRedo = 0
local pause = false
seekTable[0] = 0

----------------------------USER CUSTOMIZATION SETTINGS-----------------------------------
--These settings are for users to manually change some options in the script.
--Keybinds can be defined in the bottom of the script.

local osd_messages = true --true is for displaying osd messages when actions occur, Change to false will disable all osd messages generated from this script

---------------------------END OF USER CUSTOMIZATION SETTINGS---------------------

local function prepareUndoRedo()
	if (pause == true) then
		seconds = seconds
	else
		seconds = seconds - 0.5
	end
		seekTable[currentIndex] = seekTable[currentIndex] + seconds 	
		seconds = 0	
end

local function getUndoRedo()
	if (seeking == 0) then
			prepareUndoRedo()
			
			seekNumber = currentIndex + 1
			currentIndex = seekNumber
			seekTime = math.floor(mp.get_property_number('time-pos'))
			table.insert(seekTable, seekNumber, seekTime)

			undoRedo = 0

	elseif (seeking == 1) then
		seeking = 0
	end
end

mp.register_event('file-loaded', function()
	filePath = mp.get_property('path')
	
	timer = mp.add_periodic_timer(0.1, function()
		seconds = seconds + 0.1
	end)

	if (pause == true) then
		timer:stop()
	else
		timer:resume()
	end

	timer2 = mp.add_periodic_timer(0.1, function()
		countTimer = countTimer + 0.1
		
		if (countTimer == 0.6) then
			timer:resume()
			getUndoRedo()
		end

	end)

	timer2:stop()
end)


mp.register_event('seek', function()
	countTimer = 0
	timer2:resume()
	timer:stop()
end)

mp.observe_property('pause', 'bool', function(name, value)
	if value then
		if timer ~= nil then
			timer:stop()
		end
		pause = true
	else
		if timer ~= nil then
			timer:resume()
		end
		pause = false
	end
end)

mp.register_event('end-file', function()
	if timer ~= nil then
		timer:kill()
	end
	if timer2 ~= nil then
		timer2:kill()
	end
	seekNumber = 0
	currentIndex = 0
	undoRedo = 0
	seconds = 0
	countTimer = -1
	seekTable[0] = 0
end)

local function undo()
	if (filePath ~= nil) and (countTimer >= 0) and (countTimer < 0.6) and (seeking == 0) then
		timer2:stop()

		getUndoRedo()

		currentIndex = currentIndex - 1
		if (currentIndex < 0) then
			if (osd_messages == true) then
				mp.osd_message('No Undo Found')
			end
			currentIndex = 0
			msg.info('No undo found')
		else
			if (seekTable[currentIndex] < 0) then
				seekTable[currentIndex] = 0
			end

			seeking = 1

			mp.commandv('seek', seekTable[currentIndex], 'absolute', 'exact')

			undoRedo = 1
			if (osd_messages == true) then
				mp.osd_message('Undo')
			end
			msg.info('Seeked using undo')
		end
	elseif (filePath ~= nil) and (currentIndex > 0) then

		prepareUndoRedo()
		currentIndex = currentIndex - 1

		if (seekTable[currentIndex] < 0) then
			seekTable[currentIndex] = 0
		end

		seeking = 1
		mp.commandv('seek', seekTable[currentIndex], 'absolute', 'exact')

		undoRedo = 1
		if (osd_messages == true) then
			mp.osd_message('Undo')
		end
		msg.info('Seeked using undo')
	elseif (filePath ~= nil) and (currentIndex == 0) then
		if (osd_messages == true) then
			mp.osd_message('No Undo Found')
		end
		msg.info('No undo found')
	end
end

local function redo()
	if (filePath ~= nil) and (currentIndex < seekNumber) then

		prepareUndoRedo()
		currentIndex = currentIndex + 1

		if (seekTable[currentIndex] < 0) then
			seekTable[currentIndex] = 0
		end

	    seeking = 1
		mp.commandv('seek', seekTable[currentIndex], 'absolute', 'exact')

		undoRedo = 0
		
		if (osd_messages == true) then
			mp.osd_message('Redo')
		end
		msg.info('Seeked using redo')
	elseif (filePath ~= nil) and (currentIndex == seekNumber) then
		if (osd_messages == true) then
			mp.osd_message('No Redo Found')
		end
		msg.info('No redo found')
	end
end

local function undoLoop()
	if (filePath ~= nil) and (undoRedo == 0) then
		undo()
	elseif (filePath ~= nil) and (undoRedo == 1) then
		redo()
	elseif (filePath ~= nil) and (countTimer == -1) then
		if (osd_messages == true) then
			mp.osd_message('No Undo Found')
		end
		msg.info('No undo found')
	end
end


mp.add_key_binding("ctrl+z", "undo", undo)
mp.add_key_binding("ctrl+Z", "undoCaps", undo)

mp.add_key_binding("ctrl+y", "redo", redo)
mp.add_key_binding("ctrl+Y", "redoCaps", redo)

mp.add_key_binding("ctrl+alt+z", "undoLoop", undoLoop)
mp.add_key_binding("ctrl+alt+Z", "undoLoopCaps", undoLoop)
