function set_osd_title()
	local name = mp.get_property("filename")
	local percent_pos = ""
	local chapter = ""
	local frames_dropped = ""

	if mp.get_property_osd("percent-pos") ~= "" then
		percent_pos = " • " .. mp.get_property_osd("percent-pos") .. "% completed"
	end
	

	if mp.get_property_osd("chapter") ~= "" then
		chapter = " • Chapter: " .. mp.get_property_osd("chapter")
	end


	if mp.get_property_osd("vo-drop-frame-count") ~= "0" then
		if mp.get_property_osd("vo-drop-frame-count") == "1" then
			frames_dropped = " • " .. mp.get_property_osd("vo-drop-frame-count") .. " dropped frame"
		else
			frames_dropped = " • " .. mp.get_property_osd("vo-drop-frame-count") .. " dropped frames"
		end
	end


	mp.set_property("force-media-title", name .. percent_pos .. chapter .. frames_dropped)
end

mp.observe_property("percent-pos", "number", set_osd_title)
mp.observe_property("chapter", "string", set_osd_title)
mp.observe_property("vo-drop-frame-count", "number", set_osd_title)