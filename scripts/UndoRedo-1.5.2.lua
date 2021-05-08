-- Copyright (c) 2020, Eisa AlAwadhi
-- License: BSD 2-Clause License

-- Creator: Eisa AlAwadhi
-- Project: UndoRedo
-- Version: 1.5.2

local utils = require 'mp.utils'
local seconds = 0
local countTimer = 0
local seekTime = 0

local seekNumber = 0
local currentIndex = 0
local seekTable = {}
local seeking = 0

local undoRedo = 0

local pause = false

seekTable[0] = 0

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
		
			if (seeking == 0) then
				
				if (pause == true) then
					seconds = seconds
				else
					seconds = seconds - 0.7
				end
				
					seekTable[currentIndex] = seekTable[currentIndex] + seconds 	
					seconds = 0	
					
					seekNumber = currentIndex + 1
					currentIndex = seekNumber
					seekTime = math.floor(mp.get_property_number('time-pos'))
					table.insert(seekTable, seekNumber, seekTime)
					
					undoRedo = 0
			
			elseif (seeking == 1) then
				seeking = 0
			end
			
		end

	end)
	
	timer2:stop()
end)


mp.register_event('seek', function()
	timer2:resume()
	countTimer = 0
end)

mp.register_event('pause', function() 
	timer:stop()
	pause = true
end)

mp.register_event('unpause', function()
	timer:resume()
	pause = false
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
	countTimer = 0
	seekTable[0] = 0
end)

local function undo()
	if (filePath ~= nil) and (currentIndex > 0) and (seeking == 0) then
		
		if (pause == true) then
			seconds = seconds
		else
			seconds = seconds - 0.7
		end
		
		seekTable[currentIndex] = seekTable[currentIndex] + seconds
		seconds=0
		
		currentIndex = currentIndex - 1
		
		if (seekTable[currentIndex] < 0) then
			seekTable[currentIndex] = 0
		end
		
		mp.commandv('seek', seekTable[currentIndex], 'absolute', 'exact')
		
		seeking = 1
		undoRedo = 1
		
		mp.osd_message('Undo')
	elseif (filePath ~= nil) and (countTimer > 0) and (countTimer < 0.6) then 
		mp.osd_message('Seeking Still Running')
	elseif (filePath ~= nil) and (currentIndex == 0) then
		mp.osd_message('No Undo Found')
	end
end

local function redo()
	if (filePath ~= nil) and (currentIndex < seekNumber) and (seeking == 0) then
	
		if (pause == true) then
			seconds = seconds
		else
			seconds = seconds - 0.7
		end
		
		seekTable[currentIndex] = seekTable[currentIndex] + seconds
		seconds = 0
		
		currentIndex = currentIndex + 1
		
		if (seekTable[currentIndex] < 0) then
			seekTable[currentIndex] = 0
		end
		
		mp.commandv('seek', seekTable[currentIndex], 'absolute', 'exact')

		seeking = 1
		undoRedo = 0
		
		mp.osd_message('Redo')
	elseif (filePath ~= nil) and (countTimer > 0) and (countTimer < 0.6) then
		mp.osd_message('Seeking Still Running')
	elseif (filePath ~= nil) and (currentIndex == seekNumber) then
		mp.osd_message('No Redo Found')
	end
end

local function undoRedo()
	if (filePath ~= nil) and (countTimer > 0.5) and (undoRedo == 0) then
		
		if (pause == true) then
			seconds = seconds
		else
			seconds = seconds - 0.7
		end
		
		seekTable[currentIndex] = seekTable[currentIndex] + seconds
		seconds = 0
		
		currentIndex = currentIndex - 1
		
		if (seekTable[currentIndex] < 0) then
			seekTable[currentIndex] = 0
		end
		
		mp.commandv('seek', seekTable[currentIndex], 'absolute', 'exact')
		mp.osd_message('Undo')
		seeking = 1
		undoRedo = 1
	elseif (filePath ~= nil) and (countTimer > 0.5) and (undoRedo == 1) then
		
		if (pause == true) then
			seconds = seconds
		else
			seconds = seconds - 0.7
		end
		
		seekTable[currentIndex] = seekTable[currentIndex] + seconds
		seconds = 0
		
		currentIndex = currentIndex + 1
		
		if (seekTable[currentIndex] < 0) then
			seekTable[currentIndex] = 0
		end
		
		mp.commandv('seek', seekTable[currentIndex], 'absolute', 'exact')
		mp.osd_message('Redo')
		seeking = 1
		undoRedo = 0
	elseif (filePath ~= nil) and (countTimer > 0) and (countTimer < 0.6) then
		mp.osd_message('Seeking Still Running')
	elseif (filePath ~= nil) and (countTimer == 0) then
		mp.osd_message('No Undo Found')
	end
end


mp.add_key_binding("ctrl+z", "undo", undo)
mp.add_key_binding("ctrl+Z", "undoCaps", undo)

mp.add_key_binding("ctrl+y", "redo", redo)
mp.add_key_binding("ctrl+Y", "redoCaps", redo)

mp.add_key_binding("ctrl+alt+z", "undoRedo", undoRedo)
mp.add_key_binding("ctrl+alt+Z", "undoRedoCaps", undoRedo)
