cmCenter = 1
local defCenter = 1
cmFront = 0.707
local defFront = 0.707
cmSide = 0.707
local defSide = 0.707
cmBack = 0.707
local defBack = 0.707
cmLFE = 0
local defLFE = 0

local function mix(channel, adjustment)
	if channel == "reset" then
		cmCenter = defCenter
		cmFront = defFront
		cmSide = defSide
		cmBack = defBack
		cmLFE = defLFE
	else
		_G[channel] = _G[channel] + adjustment
		if _G[channel] < 0.001 then _G[channel] = 0 end
	end
	mp.set_property("af", "lavfi=[pan=stereo|FL="..cmCenter.."FC+"..cmFront.."FL+"..cmSide.."SL+"..cmBack.."BL+"..cmLFE.."LFE|FR="..cmCenter.."FC+"..cmFront.."FR+"..cmSide.."SR+"..cmBack.."BR+"..cmLFE.."LFE]")
	mp.osd_message("lavfi=[pan=stereo|\nFL="..cmCenter.."FC+"..cmFront.."FL+"..cmSide.."SL+"..cmBack.."BL+"..cmLFE.."LFE|\nFR="..cmCenter.."FC+"..cmFront.."FR+"..cmSide.."SR+"..cmBack.."BR+"..cmLFE.."LFE]", 5)
end

mp.add_key_binding("Ctrl+Shift+F8", "mReset", function() mix("reset") end)

mp.add_key_binding("Shift+F6", "cUp", function() mix("cmCenter",0.1) end)
mp.add_key_binding("Ctrl+F6", "cDown", function() mix("cmCenter",-0.1) end)

mp.add_key_binding("Shift+F7", "fUp", function() mix("cmFront",0.1) end)
mp.add_key_binding("Ctrl+F7", "fDown", function() mix("cmFront",-0.1) end)

mp.add_key_binding("Shift+F8", "sUp", function() mix("cmSide",0.1) end)
mp.add_key_binding("Ctrl+F8", "sDown", function() mix("cmSide",-0.1) end)

mp.add_key_binding("Shift+F9", "bUp", function() mix("cmBack",0.1) end)
mp.add_key_binding("Ctrl+F9", "bDown", function() mix("cmBack",-0.1) end)

mp.add_key_binding("Shift+F11", "lUp", function() mix("cmLFE",0.1) end)
mp.add_key_binding("Ctrl+F11", "lDown", function() mix("cmLFE",-0.1) end)