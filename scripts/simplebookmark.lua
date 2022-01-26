-- Copyright (c) 2021, Eisa AlAwadhi
-- License: BSD 2-Clause License
-- Creator: Eisa AlAwadhi
-- Project: SimpleBookmark
-- Version: 1.0.2

local o = {
---------------------------USER CUSTOMIZATION SETTINGS---------------------------
--These settings are for users to manually change some options.
--Changes are recommended to be made in the script-opts directory.

	-----Script Settings----
	auto_run_list_idle = 'none',  --Auto run the list when opening mpv and there is no video / file loaded. 'none' for disabled. Or choose between: 'all', 'keybinds', 'recents', 'distinct', 'protocols', 'fileonly', 'titleonly', 'timeonly', 'keywords'.
	resume_offset = -0.65, --change to 0 so item resumes from the exact position, or decrease the value so that it gives you a little preview before loading the resume point
	osd_messages = true, --true is for displaying osd messages when actions occur. Change to false will disable all osd messages generated from this script
	bookmark_loads_last_idle = true, --When attempting to bookmark, if there is no video / file loaded, it will instead jump to your last bookmarked item and resume it.
	bookmark_fileonly_loads_last_idle = true, --When attempting to bookmark fileonly, if there is no video / file loaded, it will instead jump to your last bookmarked item without resuming.
	mark_bookmark_as_chapter = false, --true is for marking the time as a chapter. false disables mark as chapter behavior.
	bookmark_save_keybind=[[
	["ctrl+b", "ctrl+B"]
	]], --Keybind that will be used to save the video and its time to log file
	bookmark_fileonly_keybind=[[
	["alt+b", "alt+B"]
	]], --Keybind that will be used to save the video without time to log file
	open_list_keybind=[[
	[ ["b", "all"], ["B", "all"], ["k", "keybinds"], ["K", "keybinds"] ]
	]], --Keybind that will be used to open the list along with the specified filter. Available filters: 'all', 'keybinds', 'recents', 'distinct', 'protocols', 'fileonly', 'titleonly', 'timeonly', 'keywords'.
	list_filter_jump_keybind=[[
	[ ["b", "all"], ["B", "all"], ["k", "keybinds"], ["K", "keybinds"], ["r", "recents"], ["R", "recents"], ["d", "distinct"], ["D", "distinct"], ["f", "fileonly"], ["F", "fileonly"] ]
	]], --Keybind that is used while the list is open to jump to the specific filter (it also enables pressing a filter keybind twice to close list). Available fitlers: 'all', 'keybinds', 'recents', 'distinct', 'protocols', 'fileonly', 'titleonly', 'timeonly', 'keywords'.
	
	-----Keybind Slots Settings----
	keybinds_quicksave_fileonly = true, --When quick saving to a keybind slot, it will not save position
	keybinds_empty_auto_create = false, --If the keybind slot is empty, this enables quick logging and adding to slot, Otherwise keybinds are assigned from the list or via quicksave.
	keybinds_empty_fileonly = true, --When auto creating keybind slot, it will not save position.
	keybinds_auto_resume = true, --When loading a keybind slot, it will auto resume to the saved time.
	keybinds_add_load_keybind=[[
	["alt+1", "alt+2", "alt+3", "alt+4", "alt+5", "alt+6", "alt+7", "alt+8", "alt+9"]
	]], --Keybind that will be used to bind list item to a key, as well as to load it. e.g.: Press alt+1 on highlighted item from the list to add it, press alt+1 while list is hidden to load item keybinded into alt+1. (A new slot is automatically created for each keybind. e.g: .."alt+9, alt+0". Where alt+0 creates a new 10th slot.)
	keybinds_quicksave_keybind=[[
	["alt+!", "alt+@", "alt+#", "alt+$", "alt+%", "alt+^", "alt+&", "alt+*", "alt+("]
	]], --To save keybind to a slot without opening the list, to load these keybinds it uses keybinds_add_load_keybind
	keybinds_remove_keybind=[[
	["alt+-", "alt+_"]
	]], --Keybind that is used when list is open to remove the keybind slot from the highlighted item

	-----Logging Settings-----
	log_path = '/:dir%mpvconf', --Change to '/:dir%script' for placing it in the same directory of script, OR change to '/:dir%mpvconf' for mpv portable_config directory. OR specify the desired path, e.g.: 'C:\Users\Eisa01\Desktop\'
	log_file = 'mpvBookmark.log', --name+extension of the file that will be used to store the log data
	date_format = '%d/%m/%y %X', --Date format in the log (see lua date formatting), e.g.:'%d/%m/%y %X' or '%d/%b/%y %X'
	file_title_logging = 'protocols', --Change between 'all', 'protocols', 'none'. This option will store the media title in log file, it is useful for websites / protocols because title cannot be parsed from links alone
	logging_protocols=[[
	["https?://", "magnet:", "rtmp:"]
	]], --add above (after a comma) any protocol you want its title to be stored in the log file. This is valid only for (file_title_logging = 'protocols' or file_title_logging = 'all')
	prefer_filename_over_title = 'local', --Prefers to log filename over filetitle. Select between 'local', 'protocols', 'all', and 'none'. 'local' prefer filenames for videos that are not protocols. 'protocols' will prefer filenames for protocols only. 'all' will prefer filename over filetitle for both protocols and not protocols videos. 'none' will always use filetitle instead of filename
	same_entry_limit = -1, --Limit saving entries with same path: -1 for unlimited, 0 will always update entries of same path, e.g. value of 3 will have the limit of 3 then it will start updating old values on the 4th entry.

	-----List Settings-----
	loop_through_list = false, --true is for going up on the first item loops towards the last item and vise-versa. false disables this behavior.
	list_middle_loader = true, --false is for more items to show, then u must reach the end. true is for new items to show after reaching the middle of list.
	show_paths = false, --Show file paths instead of media-title
	show_item_number = true, --Show the number of each item before displaying its name and values.
	slice_longfilenames = false, --Change to true or false. Slices long filenames per the amount specified below
	slice_longfilenames_amount = 55, --Amount for slicing long filenames
	list_show_amount = 10, --Change maximum number to show items at once
	quickselect_0to9_keybind = true, --Keybind entries from 0 to 9 for quick selection when list is open (list_show_amount = 10 is maximum for this feature to work)
	main_list_keybind_twice_exits = true, --Will exit the list when double tapping the main list, even if the list was accessed through a different filter.
	search_not_typing_smartly = true, --To smartly set the search as not typing (when search box is open) without needing to press ctrl+enter.

	-----Filter Settings------
	--available filters: "all" to display all the items. Or 'keybinds' to display the list filtered with keybind slots. Or "recents" to display recently added items to log without duplicate. Or "distinct" to show recent saved entries for files in different paths. Or "fileonly" to display files saved without time. Or "timeonly" to display files that have time only. Or "keywords" to display files with matching keywords specified in the configuration. Or "playing" to show list of current playing file.
	filters_and_sequence=[[
	["all", "keybinds", "protocols", "fileonly", "titleonly", "timeonly", "playing", "keywords", "recents", "distinct"]
	]], --Jump to the following filters and in the shown sequence when navigating via left and right keys. You can change the sequence and delete filters that are not needed.
	next_filter_sequence_keybind=[[
	["RIGHT", "MBTN_FORWARD"]
	]],--Keybind that will be used to go to the next available filter based on the filters_and_sequence
	previous_filter_sequence_keybind=[[
	["LEFT", "MBTN_BACK"]
	]],--Keybind that will be used to go to the previous available filter based on the filters_and_sequence
	loop_through_filters = true, --true is for bypassing the last filter to go to first filter when navigating through filters using arrow keys, and vice-versa. false disables this behavior.
	keywords_filter_list=[[
	["youtube.com", "mp4", "naruto", "c:\\users\\eisa01\\desktop"]
	]], --Create a filter out of your desired 'keywords', e.g.: youtube.com will filter out the videos from youtube. You can also insert a portion of filename or title, or extension or a full path / portion of a path.

	-----Sort Settings------
	--available sort: 'added-asc' is for the newest added items to show first. Or 'added-desc' for the newest added to show last. Or 'alphanum-asc' is for A to Z approach with filename and episode number lower first. Or 'alphanum-desc' is for its Z to A approach. Or 'time-asc', 'time-desc' to sort the list based on time. Or 'keybind-asc', 'keybind-desc' to sort based on keybinds which is execlusive to sort_keybinds_filter.
	list_default_sort = 'none', --the default sorting method for the list. select between 'added-asc', 'added-desc', 'alphanum-asc', 'alphanum-desc'. description: 'none' defaults to added-asc without requiring to sort
	sort_recents_filter = 'none',
	sort_distinct_filter = 'none',
	sort_keybinds_filter = 'keybind-asc', --Sorts the keybind slots filter. Select between 'none', 'keybind-asc', 'keybind-desc', 'added-asc', 'added-desc', 'alphanum-asc', 'alphanum-desc', 'time-asc', 'time-desc'. description: 'none' is for default ordering. 'keybind-asc' is only for slots, it uses A to Z approach but for keybinds. 'keybind-desc' is the same but for Z to A approach.
	sort_fileonly_filter = 'alphanum-asc', --Sorts the filter. Select between 'none', 'added-asc', 'added-desc', 'alphanum-asc', 'alphanum-desc', 'time-asc', 'time-desc'.
	sort_protocols_filter = 'none',
	sort_titleonly_filter = 'none',
	sort_timeonly_filter = 'none',
	sort_keywords_filter = 'none',
	sort_playing_filter = 'time-asc',
	sort_search_filter = 'alphanum-asc',

	-----List Design Settings-----
	list_alignment = 7, --The alignment for the list, uses numpad positions choose from 1-9 or 0 to disable. e,g.:7 top left alignment, 8 top middle alignment, 9 top right alignment.
	text_color = 'ffffff', --Text color for list in BGR hexadecimal
	text_scale = 50, --Font size for the text of list
	text_border = 0.7, --Black border size for the text of list
	highlight_color = 'ffbf7f', --Highlight color in BGR hexadecimal
	highlight_scale = 50, --Font size for highlighted text in list
	highlight_border = 0.7, --Black border size for highlighted text in list
	header_text = '🔖 Bookmarks [%cursor/%total] %prefilter%filter%afterfilter%presearch%search%aftersearch', --Text to be shown as header for the list. %cursor: shows the position of highlighted file. %total: shows the total amount of items. %filter: shows the filter name, %prefilter: user defined text before showing filter, %afterfilter: user defined text after showing filter, %search: shows the typed search, %presearch, %aftersearch: same concept of prefilter and afterfilter, %listduration: shows the total playback duration of displayed list. %prelistduration, %afterlistduration: same concept of prefilter and afterfilter.
	header_filter_pre_text = ' (filtered: ', --Text to be shown before filter in the header
	header_filter_after_text = ')', --Text to be shown after filter in the header (since filter is inside the header, if you need to add a variable like %%search it will need double %%)
	header_search_pre_text = '\\h\\N\\N(search=', --Text to be shown before search in the header
	header_search_after_text = '..)', --Text to be shown after search in the header
	header_list_duration_pre_text = '🕒 ', --Text to be shown before playback total duration of displayed list in the header
	header_list_duration_after_text = '', --Text to be shown after playback total duration of displayed list in the header	
	header_color = 'ffffaa', --Header color in BGR hexadecimal
	search_color_typing = '00bfff', --Search color when in typing mode
	search_color_not_typing = 'ffffaa', --Search color when not in typing mode and it is active
	header_scale = 55, --Header text size for the list
	header_border = 0.8, --Black border size for the Header of list
	time_seperator = ' 🕒 ', --Time seperator that will be used before the saved time
	keybinds_seperator = ' ⌨ ', --Keybind slots seperator that will be used before the saved keybind
	list_sliced_prefix = '...\\h\\N\\N', --The text that indicates there are more items above. \\h\\N\\N is for new line
	list_sliced_suffix = '...', --The text that indicates there are more items below

	-----List Keybind Settings-----
	--Add below (after a comma) any additional keybind you want to bind. Or change the letter inside the quotes to change the keybind
	--Example of changing and adding keybinds: --From ["b", "B"] To ["b"]. --From [""] to ["alt+b"]. --From [""] to ["a" "ctrl+a", "alt+a"]
	
	list_move_up_keybind=[[
	["UP", "WHEEL_UP"]
	]], --Keybind that will be used to navigate up on the list
	list_move_down_keybind=[[
	["DOWN", "WHEEL_DOWN"]
	]], --Keybind that will be used to navigate down on the list
	list_page_up_keybind=[[
	["PGUP"]
	]], --Keybind that will be used to go to the first item for the page shown on the list
	list_page_down_keybind=[[
	["PGDWN"]
	]], --Keybind that will be used to go to the last item for the page shown on the list
	list_move_first_keybind=[[
	["HOME"]
	]], --Keybind that will be used to navigate to the first item on the list
	list_move_last_keybind=[[
	["END"]
	]], --Keybind that will be used to navigate to the last item on the list
	list_select_keybind=[[
	["ENTER", "MBTN_MID"]
	]], --Keybind that will be used to load highlighted entry from the list
	list_add_playlist_keybind=[[
	["SHIFT+ENTER"]
	]], --Keybind that will be used to add the selected entry to playlist
	list_close_keybind=[[
	["ESC", "MBTN_RIGHT"]
	]], --Keybind that will be used to close the list (closes search first if it is open)
	list_delete_keybind=[[
	["DEL"]
	]], --Keybind that will be used to delete the highlighted entry from the list
	list_search_activate_keybind=[[
	["ctrl+f", "ctrl+F"]
	]], --Keybind that will be used to trigger search
	list_search_not_typing_mode_keybind=[[
	["CTRL+ENTER"]
	]], --Keybind that will be used to exit typing mode of search while keeping search open
	list_ignored_keybind=[[
	["h", "H", "r", "R", "c", "C"]
	]], --Keybind thats are ignored when list is open
	
---------------------------END OF USER CUSTOMIZATION SETTINGS---------------------------
}

(require 'mp.options').read_options(o)
local utils = require 'mp.utils'
local msg = require 'mp.msg'

o.filters_and_sequence = utils.parse_json(o.filters_and_sequence)
o.keywords_filter_list = utils.parse_json(o.keywords_filter_list)
o.logging_protocols = utils.parse_json(o.logging_protocols)
o.bookmark_save_keybind = utils.parse_json(o.bookmark_save_keybind)
o.bookmark_fileonly_keybind = utils.parse_json(o.bookmark_fileonly_keybind)
o.keybinds_add_load_keybind = utils.parse_json(o.keybinds_add_load_keybind)
o.keybinds_remove_keybind = utils.parse_json(o.keybinds_remove_keybind)
o.keybinds_quicksave_keybind = utils.parse_json(o.keybinds_quicksave_keybind)
o.list_move_up_keybind = utils.parse_json(o.list_move_up_keybind)
o.list_move_down_keybind = utils.parse_json(o.list_move_down_keybind)
o.list_page_up_keybind = utils.parse_json(o.list_page_up_keybind)
o.list_page_down_keybind = utils.parse_json(o.list_page_down_keybind)
o.list_move_first_keybind = utils.parse_json(o.list_move_first_keybind)
o.list_move_last_keybind = utils.parse_json(o.list_move_last_keybind)
o.list_select_keybind = utils.parse_json(o.list_select_keybind)
o.list_add_playlist_keybind = utils.parse_json(o.list_add_playlist_keybind)
o.list_close_keybind = utils.parse_json(o.list_close_keybind)
o.list_delete_keybind = utils.parse_json(o.list_delete_keybind)
o.list_search_activate_keybind = utils.parse_json(o.list_search_activate_keybind)
o.list_search_not_typing_mode_keybind = utils.parse_json(o.list_search_not_typing_mode_keybind)
o.next_filter_sequence_keybind = utils.parse_json(o.next_filter_sequence_keybind)
o.previous_filter_sequence_keybind = utils.parse_json(o.previous_filter_sequence_keybind)
o.open_list_keybind = utils.parse_json(o.open_list_keybind)
o.list_filter_jump_keybind = utils.parse_json(o.list_filter_jump_keybind)
o.list_ignored_keybind = utils.parse_json(o.list_ignored_keybind)

if o.log_path == '/:dir%mpvconf' then
	o.log_path = mp.find_config_file('.')
elseif o.log_path == '/:dir%script' then
	o.log_path = debug.getinfo(1).source:match('@?(.*/)')
end
local log_fullpath = utils.join_path(o.log_path, o.log_file)

local log_time_text = 'time='
local log_keybind_text = 'slot='
local protocols = {'https?://', 'magnet:', 'rtmp:'}
local available_filters = {'all', 'keybinds', 'recents', 'distinct', 'playing', 'protocols', 'fileonly', 'titleonly', 'timeonly', 'keywords'}
local search_string = ''
local search_active = false

local resume_selected = false
local list_contents = {}
local list_start = 0
local list_cursor = 1
local list_drawn = false
local list_pages = {}
local filePath, fileTitle
local seekTime = 0
local filterName = 'all'

local slotKeyIndex = 0

function starts_protocol(tab, val)
	for index, value in ipairs(tab) do
		if (val:find(value) == 1) then
			return true
		end
	end
	return false
end


function contain_value(tab, val)
	if not tab then return end
	if not val then return end
	
	for index, value in ipairs(tab) do
		if value.match(string.lower(val), string.lower(value)) then
			return true
		end
	end
	
	return false
end

function has_value(tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	
	return false
end

function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then io.close(f) return true else return false end
end

function format_time(duration)
	local total_seconds = math.floor(duration)
	local hours = (math.floor(total_seconds / 3600))
	total_seconds = (total_seconds % 3600)
	local minutes = (math.floor(total_seconds / 60))
	local seconds = (total_seconds % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function get_path()
	local path = mp.get_property('path')
	if not path then return end
	
	local title = mp.get_property('media-title'):gsub("\"", "")
	
	if starts_protocol(o.logging_protocols, path) and o.prefer_filename_over_title == 'protocols' then
		title = mp.get_property('filename'):gsub("\"", "")
	elseif not starts_protocol(o.logging_protocols, path) and o.prefer_filename_over_title == 'local' then
		title = mp.get_property('filename'):gsub("\"", "")
	elseif o.prefer_filename_over_title == 'all' then
		title = mp.get_property('filename'):gsub("\"", "")
	end
	
	return path, title
end

function get_slot_keybind(keyindex)
	local keybind_return
	
	if o.keybinds_add_load_keybind[keyindex] then
		keybind_return = o.keybinds_add_load_keybind[keyindex]
	else
		keybind_return = log_keybind_text .. keyindex .. ' is NA'
	end
	
	return keybind_return
end

function bind_keys(keys, name, func, opts)
	if not keys then
		mp.add_forced_key_binding(keys, name, func, opts)
		return
	end
	
	for i = 1, #keys do
		if i == 1 then 
			mp.add_forced_key_binding(keys[i], name, func, opts)
		else
			mp.add_forced_key_binding(keys[i], name .. i, func, opts)
		end
	end
end

function unbind_keys(keys, name)
	if not keys then
		mp.remove_key_binding(name)
		return
	end
	
	for i = 1, #keys do
		if i == 1 then
			mp.remove_key_binding(name)
		else
			mp.remove_key_binding(name .. i)
		end
	end
end

function esc_string(str)
	return str:gsub("([%p])", "%%%1")
end

---------Start of LogReaderManager---------
--LogReaderManager (Read and Format the List from Log)--
function read_log(func)
	local f = io.open(log_fullpath, "r")
	if not f then return end
	list_contents = {}
	for line in f:lines() do
		table.insert(list_contents, (func(line)))
	end
	f:close()
	return list_contents
end

function read_log_table()
	local line_pos = 0
	return read_log(function(line)
		local tt, p, t, s, d, n, e, l
		if line:match('^.-\"(.-)\"') then
			tt = line:match('^.-\"(.-)\"')
			n, p = line:match('^.-\"(.-)\" | (.*) | ' .. esc_string(log_time_text) .. '(.*)')
		else
			p = line:match('[(.*)%]]%s(.*) | ' .. esc_string(log_time_text) .. '(.*)')
			d, n, e = p:match('^(.-)([^\\/]-)%.([^\\/%.]-)%.?$')
		end
		t = line:match(' | ' .. esc_string(log_time_text) .. '(%d*%.?%d*)(.*)$')
		s = line:match(' | .* | ' .. esc_string(log_keybind_text) .. '(.*)$')
		l = line
		line_pos = line_pos + 1
		return {found_path = p, found_time = t, found_name = n, found_slot = s, found_title = tt, found_line = l, found_sequence = line_pos}
	end)
end

function list_sort(tab, sort)
	if sort == 'added-asc' then
		table.sort(tab, function(a, b) return a['found_sequence'] < b['found_sequence'] end)
	elseif sort == 'added-desc' then
		table.sort(tab, function(a, b) return a['found_sequence'] > b['found_sequence'] end)
	elseif sort == 'keybind-asc' and filterName == 'keybinds' then
		table.sort(tab, function(a, b) return a['found_slot'] > b['found_slot'] end)
	elseif sort == 'keybind-desc' and filterName == 'keybinds' then
		table.sort(tab, function(a, b) return a['found_slot'] < b['found_slot'] end)
	elseif sort == 'time-asc' then
		table.sort(tab, function(a, b) return tonumber(a['found_time']) > tonumber(b['found_time']) end)
	elseif sort == 'time-desc' then
		table.sort(tab, function(a, b) return tonumber(a['found_time']) < tonumber(b['found_time']) end)
	elseif sort == 'alphanum-asc' or sort == 'alphanum-desc' then
		local function padnum(d) local dec, n = string.match(d, "(%.?)0*(.+)")
			return #dec > 0 and ("%.12f"):format(d) or ("%s%03d%s"):format(dec, #n, n) end
		if sort == 'alphanum-asc' then
			table.sort(tab, function(a, b) return tostring(a['found_path']):gsub("%.?%d+", padnum) .. ("%3d"):format(#b) > tostring(b['found_path']):gsub("%.?%d+", padnum) .. ("%3d"):format(#a) end)
		elseif sort == 'alphanum-desc' then
			table.sort(tab, function(a, b) return tostring(a['found_path']):gsub("%.?%d+", padnum) .. ("%3d"):format(#b) < tostring(b['found_path']):gsub("%.?%d+", padnum) .. ("%3d"):format(#a) end)
		end
	end
	
	return tab
end

function parse_header(string)
	local osd_header_color = string.format("{\\1c&H%s}", o.header_color)
	local osd_search_color = osd_header_color
	if search_active == 'typing' then
		osd_search_color = string.format("{\\1c&H%s}", o.search_color_typing)
	elseif search_active == 'not_typing' then
		osd_search_color = string.format("{\\1c&H%s}", o.search_color_not_typing)
	end
	local osd_msg_end = "{\\1c&HFFFFFF}"
	
	string = string:gsub("%%total", #list_contents)
		:gsub("%%cursor", list_cursor)

	if filterName ~= 'all' then
		string = string:gsub("%%filter", filterName)
		:gsub("%%prefilter", o.header_filter_pre_text)
		:gsub("%%afterfilter", o.header_filter_after_text)
	else
		string = string:gsub("%%filter", '')
		:gsub("%%prefilter", '')
		:gsub("%%afterfilter", '')
	end
	
	local list_total_duration = 0
	if string:match('%listduration') then
		list_total_duration = get_total_duration()
		if list_total_duration > 0 then
			string = string:gsub("%%listduration", format_time(list_total_duration))
		else
			string = string:gsub("%%listduration", '')
		end
	end	
	if list_total_duration > 0 then
		string = string:gsub("%%prelistduration", o.header_list_duration_pre_text)
		:gsub("%%afterlistduration", o.header_list_duration_after_text)
	else
		string = string:gsub("%%prelistduration", '')
		:gsub("%%afterlistduration", '')
	end
	
	if search_active then
		local search_string_osd = search_string
		if search_string_osd ~= '' then
			search_string_osd = search_string:gsub('%%', '%%%%%%%%'):gsub('\\', '\\​'):gsub('{', '\\{')
		end
	
		string = string:gsub("%%search", osd_search_color..search_string_osd..osd_header_color)
		:gsub("%%presearch", o.header_search_pre_text)	
		:gsub("%%aftersearch", o.header_search_after_text)
	else
		string = string:gsub("%%search", '')
		:gsub("%%presearch", '')
		:gsub("%%aftersearch", '')
	end
	string = string:gsub("%%%%", "%%")
	return string
end

function get_list_contents(filter, sort, ignore_search)
	if not filter then filter = filterName end
	
	local active_sort = sort
	local filtered_table = {}
	
	list_contents = read_log_table()
	if not list_contents and not search_active or not list_contents[1] and not search_active then return end
	
	if not sort then active_sort = o.list_default_sort end
	if active_sort ~= 'none' or active_sort ~= '' then
		list_sort(list_contents, active_sort)
	end
	
	if filter == 'keybinds' then
		for i = 1, #list_contents do
			if list_contents[i].found_slot then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		if not sort then active_sort = o.sort_keybinds_filter end
		if active_sort ~= 'none' or active_sort ~= '' then
			list_sort(filtered_table, active_sort)
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'recents' then
		table.sort(list_contents, function(a, b) return a['found_sequence'] < b['found_sequence'] end)
		local unique_values = {}
		local list_total = #list_contents
		
		if filePath == list_contents[#list_contents].found_path and tonumber(list_contents[#list_contents].found_time) == 0 then
			list_total = list_total -1
		end
	
		for i = list_total, 1, -1 do
			if not has_value(unique_values, list_contents[i].found_path) then
				table.insert(unique_values, list_contents[i].found_path)
				table.insert(filtered_table, list_contents[i])
			end
		end
		table.sort(filtered_table, function(a, b) return a['found_sequence'] < b['found_sequence'] end)
		
		if not sort then active_sort = o.sort_recents_filter end
		if active_sort ~= 'none' or active_sort ~= '' then
			list_sort(filtered_table, active_sort)
		end
		
		list_contents = filtered_table
	
	end
	
	if filter == 'distinct' then
		table.sort(list_contents, function(a, b) return a['found_sequence'] < b['found_sequence'] end)
		local unique_values = {}
		local list_total = #list_contents
		
		if filePath == list_contents[#list_contents].found_path and tonumber(list_contents[#list_contents].found_time) == 0 then
			list_total = list_total -1
		end
	
		for i = list_total, 1, -1 do
			if not has_value(unique_values, list_contents[i].found_directory) and not starts_protocol(protocols, list_contents[i].found_path) then
				table.insert(unique_values, list_contents[i].found_directory)
				table.insert(filtered_table, list_contents[i])
			end
		end
		table.sort(filtered_table, function(a, b) return a['found_sequence'] < b['found_sequence'] end)
		
		if not sort then active_sort = o.sort_distinct_filter end
		if active_sort ~= 'none' or active_sort ~= '' then
			list_sort(filtered_table, active_sort)
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'fileonly' then
		for i = 1, #list_contents do
			if tonumber(list_contents[i].found_time) == 0 then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		if not sort then active_sort = o.sort_fileonly_filter end
		if active_sort ~= 'none' or active_sort ~= '' then
			list_sort(filtered_table, active_sort)
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'timeonly' then
		for i = 1, #list_contents do
			if tonumber(list_contents[i].found_time) > 0 then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		if not sort then active_sort = o.sort_timeonly_filter end
		if active_sort ~= 'none' or active_sort ~= '' then
			list_sort(filtered_table, active_sort)
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'titleonly' then
		for i = 1, #list_contents do
			if list_contents[i].found_title then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		if not sort then active_sort = o.sort_titleonly_filter end
		if active_sort ~= 'none' or active_sort ~= '' then
			list_sort(filtered_table, active_sort)
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'protocols' then
		for i = 1, #list_contents do
			if starts_protocol(o.logging_protocols, list_contents[i].found_path) then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		if not sort then active_sort = o.sort_protocols_filter end
		if active_sort ~= 'none' or active_sort ~= '' then
			list_sort(filtered_table, active_sort)
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'keywords' then
		for i = 1, #list_contents do
			if contain_value(o.keywords_filter_list, list_contents[i].found_line) then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		if not sort then active_sort = o.sort_keywords_filter end
		if active_sort ~= 'none' or active_sort ~= '' then
			list_sort(filtered_table, active_sort)
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'playing' then
		for i = 1, #list_contents do
			if list_contents[i].found_path == filePath then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		if not sort then active_sort = o.sort_playing_filter end
		if active_sort ~= 'none' or active_sort ~= '' then
			list_sort(filtered_table, active_sort)
		end
		
		list_contents = filtered_table
	end
	
	if search_active and search_string ~= '' and not ignore_search then
		filtered_table = {}
		for i = 1, #list_contents do
			if string.lower(list_contents[i].found_path):match(string.lower(esc_string(search_string))) then
				table.insert(filtered_table, list_contents[i])
			elseif list_contents[i].found_title and string.lower(list_contents[i].found_title):match(string.lower(esc_string(search_string))) then
				table.insert(filtered_table, list_contents[i])
			elseif tonumber(list_contents[i].found_time) > 0 and format_time(list_contents[i].found_time):match(esc_string(search_string)) then
				table.insert(filtered_table, list_contents[i])
			elseif list_contents[i].found_slot and string.lower(get_slot_keybind(tonumber(list_contents[i].found_slot))):match(string.lower(esc_string(search_string))) then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		if not sort then active_sort = o.sort_search_filter end
		if active_sort ~= 'none' or active_sort ~= '' then
			list_sort(filtered_table, active_sort)
		end
		
		list_contents = filtered_table
	end
	
	if not list_contents and not search_active or not list_contents[1] and not search_active then return end
	
end

function draw_list()
	local osd_msg = ''
	local osd_index = ''
	local osd_key = ''
	local key = 0
	local osd_text = string.format("{\\an%f{\\fscx%f}{\\fscy%f}{\\bord%f}{\\1c&H%s}", o.list_alignment, o.text_scale, o.text_scale, o.text_border, o.text_color)
	local osd_highlight = string.format("{\\an%f}{\\fscx%f}{\\fscy%f}{\\bord%f}{\\1c&H%s}", o.list_alignment, o.highlight_scale, o.highlight_scale, o.highlight_border, o.highlight_color)
	local osd_header = string.format("{\\an%f}{\\fscx%f}{\\fscy%f}{\\bord%f}{\\1c&H%s}", o.list_alignment, o.header_scale, o.header_scale, o.header_border, o.header_color)
	local osd_msg_end = "{\\1c&HFFFFFF}"
	
	if o.header_text ~= '' then
		osd_msg = osd_msg .. osd_header .. parse_header(o.header_text)
		osd_msg = osd_msg .. "\\h\\N\\N" .. osd_msg_end
	end
	
	if search_active and not list_contents[1] then
		osd_msg = osd_msg .. 'No search results found' .. osd_msg_end
	end
	
	if o.list_middle_loader then
		list_start = list_cursor - math.floor(o.list_show_amount / 2)
	else
		list_start = list_cursor - o.list_show_amount
	end
	
	local showall = false
	local showrest = false
	if list_start < 0 then list_start = 0 end
	if #list_contents <= o.list_show_amount then
		list_start = 0
		showall = true
	end
	if list_start > math.max(#list_contents - o.list_show_amount - 1, 0) then
		list_start = #list_contents - o.list_show_amount
		showrest = true
	end
	if list_start > 0 and not showall then
		osd_msg = osd_msg .. o.list_sliced_prefix .. osd_msg_end
	end
	for i = list_start, list_start + o.list_show_amount - 1, 1 do
		if i == #list_contents then break end
		
		if o.show_paths then
			p = list_contents[#list_contents - i].found_path or list_contents[#list_contents - i].found_name or ""
		else
			p = list_contents[#list_contents - i].found_name or list_contents[#list_contents - i].found_path or ""
		end
		
		if o.slice_longfilenames and p:len() > o.slice_longfilenames_amount then
			p = p:sub(1, o.slice_longfilenames_amount) .. "..."
		end
		
		if o.quickselect_0to9_keybind and o.list_show_amount <= 10 then
			key = 1 + key
			if key == 10 then key = 0 end
			osd_key = '(' .. key .. ')  '
		end
		
		if o.show_item_number then
			osd_index = (i + 1) .. '. '
		end
		
		if i + 1 == list_cursor then
			osd_msg = osd_msg .. osd_highlight .. osd_key .. osd_index .. p
		else
			osd_msg = osd_msg .. osd_text .. osd_key .. osd_index .. p
		end
		
		if list_contents[#list_contents - i].found_time and tonumber(list_contents[#list_contents - i].found_time) > 0 then
			osd_msg = osd_msg .. o.time_seperator .. format_time(list_contents[#list_contents - i].found_time)
		end
		
		if list_contents[#list_contents - i].found_slot then
			osd_msg = osd_msg .. o.keybinds_seperator .. get_slot_keybind(tonumber(list_contents[#list_contents - i].found_slot))
		end
		
		osd_msg = osd_msg .. '\\h\\N\\N' .. osd_msg_end
		
		if i == list_start + o.list_show_amount - 1 and not showall and not showrest then
			osd_msg = osd_msg .. o.list_sliced_suffix
		end
	
	end
	mp.set_osd_ass(0, 0, osd_msg)
end

function list_empty_error_msg()
	if list_contents ~= nil and list_contents[1] then return end
	local msg_text
	if filterName ~= 'all' then
		msg_text = filterName .. " filter in Bookmark Empty"
	else
		msg_text = "Bookmark Empty"
	end
	msg.info(msg_text)
	if o.osd_messages == true and not list_drawn then
		mp.osd_message(msg_text)
	end
end

function display_list(filter, osd_hide)
	if not filter or not has_value(available_filters, filter) then filter = 'all' end
	
	local prev_filter = filterName
	filterName = filter
	
	get_list_contents(filter)
	if not osd_hide then
		list_empty_error_msg()
	end
	if not list_contents and not search_active or not list_contents[1] and not search_active then return end
	
	if not has_value(o.filters_and_sequence, filter) then
		table.insert(o.filters_and_sequence, filter)
	end
	
	local insert_new = false
	
	local trigger_close_list = false
	local trigger_initial_list = false
	
	
	if not list_pages or not list_pages[1] then
		table.insert(list_pages, {filter, 1, 1})
	else
		for i = 1, #list_pages do
			if list_pages[i][1] == filter then
				list_pages[i][3] = list_pages[i][3]+1
				insert_new = false
				break
			else
				insert_new = true
			end
		end
	end
	
	if insert_new then table.insert(list_pages, {filter, 1, 1}) end
	
	for i = 1, #list_pages do
		if not search_active and list_pages[i][1] == prev_filter then
			list_pages[i][2] = list_cursor
		end
		if list_pages[i][1] ~= filter then
			list_pages[i][3] = 0
		end
		if list_pages[i][3] == 2 and filter == 'all' and o.main_list_keybind_twice_exits then
			trigger_close_list = true
		elseif list_pages[i][3] == 2 and list_pages[1][1] == filter then
			trigger_close_list = true		
		elseif list_pages[i][3] == 2 then
			trigger_initial_list = true
		end
	end
	
	if trigger_initial_list then
		display_list(list_pages[1][1], true)
		return
	end
	
	if trigger_close_list then
		list_close_and_trash_collection()
		return
	end
	
	if not search_active then get_filter_cursor(filter) else update_search_results('','') end
	draw_list()
	list_drawn = true
	if not search_active then get_list_keybinds() end
end
--End of LogReaderManager (Read and Format the List from Log)--

--LogReaderManager Navigation--
function select(pos)
	if not search_active then
		if not list_contents or not list_contents[1] then
			list_close_and_trash_collection()
			return
		end
	end
	
	local list_cursor_temp = list_cursor + pos
	if list_cursor_temp > 0 and list_cursor_temp <= #list_contents then
		list_cursor = list_cursor_temp
	end
	
	if o.loop_through_list then
		if list_cursor_temp > #list_contents then
			list_cursor = 1
		elseif list_cursor_temp < 1 then
			list_cursor = #list_contents
		end
	end
	
	draw_list()
end

function list_move_up()
	select(-1)
end

function list_move_down()
	select(1)
end

function list_move_first()
	select(1 - list_cursor)
end

function list_move_last()
	select(#list_contents - list_cursor)
end

function list_page_up()
	select(list_start + 1 - list_cursor)
end

function list_page_down()
	if o.list_middle_loader then
		if #list_contents < o.list_show_amount then
			select(#list_contents - list_cursor)
		else
			select(o.list_show_amount + list_start - list_cursor)
		end
	else
		if o.list_show_amount > list_cursor then
			select(o.list_show_amount - list_cursor)
		elseif #list_contents - list_cursor >= o.list_show_amount then
			select(o.list_show_amount)
		else
			select(#list_contents - list_cursor)
		end
	end
end
--End of LogReaderManager Navigation--

--LogReaderManager Actions--
function load(list_cursor, add_playlist, target_time)
	if not list_contents or not list_contents[1] then return end
	if not target_time then
		seekTime = tonumber(list_contents[#list_contents - list_cursor + 1].found_time) + o.resume_offset
		if (seekTime < 0) then
			seekTime = 0
		end
	else
		seekTime = target_time
	end
	
	if file_exists(list_contents[#list_contents - list_cursor + 1].found_path) or starts_protocol(protocols, list_contents[#list_contents - list_cursor + 1].found_path) then
		if not add_playlist then
			if filePath ~= list_contents[#list_contents - list_cursor + 1].found_path then
				mp.commandv('loadfile', list_contents[#list_contents - list_cursor + 1].found_path)
				resume_selected = true
			else
				mp.commandv('seek', seekTime, 'absolute', 'exact')
				list_close_and_trash_collection()
			end
			if o.osd_messages == true then
				mp.osd_message('Loaded:\n' .. list_contents[#list_contents - list_cursor + 1].found_name.. o.time_seperator .. format_time(seekTime))
			end
			msg.info('Loaded the below file:\n' .. list_contents[#list_contents - list_cursor + 1].found_name  .. ' | '.. format_time(seekTime))
		else
			mp.commandv('loadfile', list_contents[#list_contents - list_cursor + 1].found_path, 'append-play')
			if o.osd_messages == true then
				mp.osd_message('Added into Playlist:\n'..list_contents[#list_contents - list_cursor + 1].found_name..' ')
			end
			msg.info('Added the below file into playlist:\n' .. list_contents[#list_contents - list_cursor + 1].found_path)
		end
	else
		if o.osd_messages == true then
			mp.osd_message('File Doesn\'t Exist:\n' .. list_contents[#list_contents - list_cursor + 1].found_path)
		end
		msg.info('The file below doesn\'t seem to exist:\n' .. list_contents[#list_contents - list_cursor + 1].found_path)
		return
	end
end

function list_select()
	load(list_cursor)
end

function list_add_playlist()
	load(list_cursor, true)
end

function delete_log_entry(multiple, round, target_path, target_time, entry_limit)
	if not target_path then target_path = filePath end
	if not target_time then target_time = seekTime end
	get_list_contents('all','added-asc', true)
	if not list_contents or not list_contents[1] then return end
	
	if not multiple then
		for i = #list_contents, 1, -1 do
			if not round then
				if list_contents[i].found_path == target_path and tonumber(list_contents[i].found_time) == target_time then
					table.remove(list_contents, i)
					break
				end
			else
				if list_contents[i].found_path == target_path and math.floor(tonumber(list_contents[i].found_time)) == target_time then
					table.remove(list_contents, i)
					break
				end
			end
		end
	else
		for i = #list_contents, 1, -1 do
			if not round then
				if list_contents[i].found_path == target_path and tonumber(list_contents[i].found_time) == target_time then
					table.remove(list_contents, i)
				end
			else
				if list_contents[i].found_path == target_path and math.floor(tonumber(list_contents[i].found_time)) == target_time then
					table.remove(list_contents, i)
				end
			end
		end
	end
	
	if entry_limit and entry_limit > -1 then
		local entries_found = 0
		for i = #list_contents, 1, -1 do
			if list_contents[i].found_path == target_path and entries_found < entry_limit then
				print(format_time(tonumber(list_contents[i].found_time))..'should not be removed')
				entries_found = entries_found + 1
			elseif list_contents[i].found_path == target_path and entries_found >= entry_limit then
				print(format_time(tonumber(list_contents[i].found_time))..'should be removed')
				table.remove(list_contents,i)
			end
		end
	end
	
	f = io.open(log_fullpath, "w+")
	if list_contents ~= nil and list_contents[1] then
		for i = 1, #list_contents do
			f:write(("%s\n"):format(list_contents[i].found_line))
		end
	end
	f:close()
end

function delete_highlighted()
	filePath = list_contents[#list_contents - list_cursor + 1].found_path
	fileTitle = list_contents[#list_contents - list_cursor + 1].found_name
	seekTime = tonumber(list_contents[#list_contents - list_cursor + 1].found_time)
	if not filePath and not seekTime then
		msg.info("Failed to delete")
		return
	end
	delete_log_entry()
	msg.info("Deleted \"" .. filePath .. "\" | " .. format_time(seekTime))
	filePath, fileTitle = get_path()
end

function list_delete()
	delete_highlighted()
	get_list_contents()
	if not list_contents or not list_contents[1] then
		list_close_and_trash_collection()
		return
	end
	if list_cursor ~= #list_contents + 1 then
		select(0)
	else
		select(-1)
	end
end

function get_total_duration()
	if not list_contents or not list_contents[1] then return 0 end
	local list_total_duration = 0
	for i = #list_contents, 1, -1 do
		if tonumber(list_contents[i].found_time) > 0 then
			list_total_duration = list_total_duration + list_contents[i].found_time
		end
	end
	return list_total_duration
end
--End of LogReaderManager Actions--

--LogReaderManager Filter Functions--
function get_filter_cursor(filter)
	if not filter then return end
	for i=1, #list_pages do
		if list_pages[i][1] == filter then  
			list_cursor = list_pages[i][2]
		end
	end
end

function select_filter_sequence(pos)
	if not list_drawn then return end
	local curr_pos
	local target_pos
	
	for i = 1, #o.filters_and_sequence do
		if filterName == o.filters_and_sequence[i] then
			curr_pos = i
		end
	end
	
	if curr_pos and pos > -1 then
		for i = curr_pos, #o.filters_and_sequence do
			get_list_contents(o.filters_and_sequence[i + pos])
			if list_contents[1] then
				target_pos = i + pos
				break
			end
		end
	elseif curr_pos and pos < 0 then
		for i = curr_pos, 0, -1 do
			get_list_contents(o.filters_and_sequence[i + pos])
			if list_contents[1] then
				target_pos = i + pos
				break
			end
		end
	end
	
	if target_pos then
		if not o.loop_through_filters then
			if target_pos > #o.filters_and_sequence then return end
			if target_pos < 1 then return end
		else
			if target_pos < 1 then
				for i = #o.filters_and_sequence, 1, -1 do 
					get_list_contents(o.filters_and_sequence[i])
					if list_contents[1] then
						target_pos = i
						break
					end		
				end
			end
		end
		display_list(o.filters_and_sequence[target_pos], true)
	end
end

function list_filter_next()
	select_filter_sequence(1)
end
function list_filter_previous()
	select_filter_sequence(-1)
end
--End of LogReaderManager Filter Functions--

--LogReaderManager (List Bind and Unbind)--
function get_list_keybinds()
	bind_keys(o.list_ignored_keybind, 'ignore')
	bind_keys(o.list_move_up_keybind, 'move-up', list_move_up, 'repeatable')
	bind_keys(o.list_move_down_keybind, 'move-down', list_move_down, 'repeatable')
	bind_keys(o.list_move_first_keybind, 'move-first', list_move_first, 'repeatable')
	bind_keys(o.list_move_last_keybind, 'move-last', list_move_last, 'repeatable')
	bind_keys(o.list_page_up_keybind, 'page-up', list_page_up, 'repeatable')
	bind_keys(o.list_page_down_keybind, 'page-down', list_page_down, 'repeatable')
	bind_keys(o.list_select_keybind, 'list-select', list_select)
	bind_keys(o.list_add_playlist_keybind, 'list-add-playlist', list_add_playlist)
	bind_keys(o.list_delete_keybind, 'list-delete', list_delete)
	bind_keys(o.keybinds_remove_keybind, 'keybind-slot-remove', slot_remove)
	bind_keys(o.next_filter_sequence_keybind, 'list-filter-next', list_filter_next)
	bind_keys(o.previous_filter_sequence_keybind, 'list-filter-previous', list_filter_previous)
	bind_keys(o.list_search_activate_keybind, 'list-search-activate', list_search_activate)
	
	if not search_active then
		bind_keys(o.list_close_keybind, 'list-close', list_close_and_trash_collection)
	end
	
	for i = 1, #o.list_filter_jump_keybind do
		mp.add_forced_key_binding(o.list_filter_jump_keybind[i][1], 'list-filter-jump'..i, function()display_list(o.list_filter_jump_keybind[i][2]) end)
	end

	for i = 1, #o.open_list_keybind do
		if i == 1 then
			mp.remove_key_binding('open-list')
		else
			mp.remove_key_binding('open-list'..i)
		end
	end
	
	if o.quickselect_0to9_keybind and o.list_show_amount <= 10 then
		mp.add_forced_key_binding("1", "recent-1", function()load(list_start + 1) end)
		mp.add_forced_key_binding("2", "recent-2", function()load(list_start + 2) end)
		mp.add_forced_key_binding("3", "recent-3", function()load(list_start + 3) end)
		mp.add_forced_key_binding("4", "recent-4", function()load(list_start + 4) end)
		mp.add_forced_key_binding("5", "recent-5", function()load(list_start + 5) end)
		mp.add_forced_key_binding("6", "recent-6", function()load(list_start + 6) end)
		mp.add_forced_key_binding("7", "recent-7", function()load(list_start + 7) end)
		mp.add_forced_key_binding("8", "recent-8", function()load(list_start + 8) end)
		mp.add_forced_key_binding("9", "recent-9", function()load(list_start + 9) end)
		mp.add_forced_key_binding("0", "recent-0", function()load(list_start + 10) end)
	end
end

function unbind_list_keys()
	unbind_keys(o.list_ignored_keybind, 'ignore')
	unbind_keys(o.list_move_up_keybind, 'move-up')
	unbind_keys(o.list_move_down_keybind, 'move-down')
	unbind_keys(o.list_move_first_keybind, 'move-first')
	unbind_keys(o.list_move_last_keybind, 'move-last')
	unbind_keys(o.list_page_up_keybind, 'page-up')
	unbind_keys(o.list_page_down_keybind, 'page-down')
	unbind_keys(o.list_select_keybind, 'list-select')
	unbind_keys(o.list_add_playlist_keybind, 'list-add-playlist')
	unbind_keys(o.list_delete_keybind, 'list-delete')
	unbind_keys(o.list_close_keybind, 'list-close')
	unbind_keys(o.keybinds_remove_keybind, 'keybind-slot-remove')
	unbind_keys(o.next_filter_sequence_keybind, 'list-filter-next')
	unbind_keys(o.previous_filter_sequence_keybind, 'list-filter-previous')
	
	for i = 1, #o.list_filter_jump_keybind do
		mp.remove_key_binding('list-filter-jump'..i)
	end

	for i = 1, #o.open_list_keybind do
		if i == 1 then
			mp.add_forced_key_binding(o.open_list_keybind[i][1], 'open-list', function()display_list(o.open_list_keybind[i][2]) end)
		else
			mp.add_forced_key_binding(o.open_list_keybind[i][1], 'open-list'..i, function()display_list(o.open_list_keybind[i][2]) end)
		end
	end
	
	if o.quickselect_0to9_keybind and o.list_show_amount <= 10 then
		mp.remove_key_binding("recent-1")
		mp.remove_key_binding("recent-2")
		mp.remove_key_binding("recent-3")
		mp.remove_key_binding("recent-4")
		mp.remove_key_binding("recent-5")
		mp.remove_key_binding("recent-6")
		mp.remove_key_binding("recent-7")
		mp.remove_key_binding("recent-8")
		mp.remove_key_binding("recent-9")
		mp.remove_key_binding("recent-0")
	end
end

function list_close_and_trash_collection()
	unbind_list_keys()
	unbind_search_keys()
	mp.set_osd_ass(0, 0, "")
	list_drawn = false
	list_cursor = 1
	list_start = 0
	filterName = 'all'
	list_pages = {}
	search_string = ''
	search_active = false
end
--End of LogReaderManager (List Bind and Unbind)--

--LogReaderManager Search Feature--
function list_search_exit()
	search_active = false
	get_list_contents(filterName)
	get_filter_cursor(filterName)
	select(0)
	unbind_search_keys()
	get_list_keybinds()
end

function list_search_not_typing_mode(auto_triggered)
	if auto_triggered then
		if search_string ~= '' and list_contents[1] then 
			search_active = 'not_typing'
		elseif not list_contents[1] then
			return
		else
			search_active = false
		end
	else
		if search_string ~= '' then
			search_active = 'not_typing' 
		else 
			search_active = false
		end
	end
	get_list_contents(filterName)
	select(0)
	unbind_search_keys()
	get_list_keybinds()
end

function list_search_activate()
	if not list_drawn then return end
	if search_active == 'typing' then list_search_exit() return end
	search_active = 'typing'
	
	for i = 1, #list_pages do
		if list_pages[i][1] == filterName then
			list_pages[i][2] = list_cursor
		end
	end
	
	update_search_results('','')
	bind_search_keys()
end

function update_search_results(character, action)
	if not character then character = '' end
	if action == 'string_del' then
		search_string = search_string:sub(1, -2) 
	end
	search_string = search_string..character
	
	get_list_contents(filterName)
	if character ~= '' and #list_contents > 0 or action ~= nil and #list_contents > 0 then
		select(1-list_cursor)
	elseif #list_contents == 0 then
		list_cursor = 0
		select(list_cursor)
	else
		select(0)
	end
end

function bind_search_keys()
	mp.add_forced_key_binding('a', 'search_string_a', function() update_search_results('a') end, 'repeatable')
	mp.add_forced_key_binding('b', 'search_string_b', function() update_search_results('b') end, 'repeatable')
	mp.add_forced_key_binding('c', 'search_string_c', function() update_search_results('c') end, 'repeatable')
	mp.add_forced_key_binding('d', 'search_string_d', function() update_search_results('d') end, 'repeatable')
	mp.add_forced_key_binding('e', 'search_string_e', function() update_search_results('e') end, 'repeatable')
	mp.add_forced_key_binding('f', 'search_string_f', function() update_search_results('f') end, 'repeatable')
	mp.add_forced_key_binding('g', 'search_string_g', function() update_search_results('g') end, 'repeatable')
	mp.add_forced_key_binding('h', 'search_string_h', function() update_search_results('h') end, 'repeatable')
	mp.add_forced_key_binding('i', 'search_string_i', function() update_search_results('i') end, 'repeatable')
	mp.add_forced_key_binding('j', 'search_string_j', function() update_search_results('j') end, 'repeatable')
	mp.add_forced_key_binding('k', 'search_string_k', function() update_search_results('k') end, 'repeatable')
	mp.add_forced_key_binding('l', 'search_string_l', function() update_search_results('l') end, 'repeatable')
	mp.add_forced_key_binding('m', 'search_string_m', function() update_search_results('m') end, 'repeatable')
	mp.add_forced_key_binding('n', 'search_string_n', function() update_search_results('n') end, 'repeatable')
	mp.add_forced_key_binding('o', 'search_string_o', function() update_search_results('o') end, 'repeatable')
	mp.add_forced_key_binding('p', 'search_string_p', function() update_search_results('p') end, 'repeatable')
	mp.add_forced_key_binding('q', 'search_string_q', function() update_search_results('q') end, 'repeatable')
	mp.add_forced_key_binding('r', 'search_string_r', function() update_search_results('r') end, 'repeatable')
	mp.add_forced_key_binding('s', 'search_string_s', function() update_search_results('s') end, 'repeatable')
	mp.add_forced_key_binding('t', 'search_string_t', function() update_search_results('t') end, 'repeatable')
	mp.add_forced_key_binding('u', 'search_string_u', function() update_search_results('u') end, 'repeatable')
	mp.add_forced_key_binding('v', 'search_string_v', function() update_search_results('v') end, 'repeatable')
	mp.add_forced_key_binding('w', 'search_string_w', function() update_search_results('w') end, 'repeatable')
	mp.add_forced_key_binding('x', 'search_string_x', function() update_search_results('x') end, 'repeatable')
	mp.add_forced_key_binding('y', 'search_string_y', function() update_search_results('y') end, 'repeatable')
	mp.add_forced_key_binding('z', 'search_string_z', function() update_search_results('z') end, 'repeatable')

	mp.add_forced_key_binding('A', 'search_string_A', function() update_search_results('A') end, 'repeatable')
	mp.add_forced_key_binding('B', 'search_string_B', function() update_search_results('B') end, 'repeatable')
	mp.add_forced_key_binding('C', 'search_string_C', function() update_search_results('C') end, 'repeatable')
	mp.add_forced_key_binding('D', 'search_string_D', function() update_search_results('D') end, 'repeatable')
	mp.add_forced_key_binding('E', 'search_string_E', function() update_search_results('E') end, 'repeatable')
	mp.add_forced_key_binding('F', 'search_string_F', function() update_search_results('F') end, 'repeatable')
	mp.add_forced_key_binding('G', 'search_string_G', function() update_search_results('G') end, 'repeatable')
	mp.add_forced_key_binding('H', 'search_string_H', function() update_search_results('H') end, 'repeatable')
	mp.add_forced_key_binding('I', 'search_string_I', function() update_search_results('I') end, 'repeatable')
	mp.add_forced_key_binding('J', 'search_string_J', function() update_search_results('J') end, 'repeatable')
	mp.add_forced_key_binding('K', 'search_string_K', function() update_search_results('K') end, 'repeatable')
	mp.add_forced_key_binding('L', 'search_string_L', function() update_search_results('L') end, 'repeatable')
	mp.add_forced_key_binding('M', 'search_string_M', function() update_search_results('M') end, 'repeatable')
	mp.add_forced_key_binding('N', 'search_string_N', function() update_search_results('N') end, 'repeatable')
	mp.add_forced_key_binding('O', 'search_string_O', function() update_search_results('O') end, 'repeatable')
	mp.add_forced_key_binding('P', 'search_string_P', function() update_search_results('P') end, 'repeatable')
	mp.add_forced_key_binding('Q', 'search_string_Q', function() update_search_results('Q') end, 'repeatable')
	mp.add_forced_key_binding('R', 'search_string_R', function() update_search_results('R') end, 'repeatable')
	mp.add_forced_key_binding('S', 'search_string_S', function() update_search_results('S') end, 'repeatable')
	mp.add_forced_key_binding('T', 'search_string_T', function() update_search_results('T') end, 'repeatable')
	mp.add_forced_key_binding('U', 'search_string_U', function() update_search_results('U') end, 'repeatable')
	mp.add_forced_key_binding('V', 'search_string_V', function() update_search_results('V') end, 'repeatable')
	mp.add_forced_key_binding('W', 'search_string_W', function() update_search_results('W') end, 'repeatable')
	mp.add_forced_key_binding('X', 'search_string_X', function() update_search_results('X') end, 'repeatable')
	mp.add_forced_key_binding('Y', 'search_string_Y', function() update_search_results('Y') end, 'repeatable')
	mp.add_forced_key_binding('Z', 'search_string_Z', function() update_search_results('Z') end, 'repeatable')

	mp.add_forced_key_binding('1', 'search_string_1', function() update_search_results('1') end, 'repeatable')
	mp.add_forced_key_binding('2', 'search_string_2', function() update_search_results('2') end, 'repeatable')
	mp.add_forced_key_binding('3', 'search_string_3', function() update_search_results('3') end, 'repeatable')
	mp.add_forced_key_binding('4', 'search_string_4', function() update_search_results('4') end, 'repeatable')
	mp.add_forced_key_binding('5', 'search_string_5', function() update_search_results('5') end, 'repeatable')
	mp.add_forced_key_binding('6', 'search_string_6', function() update_search_results('6') end, 'repeatable')
	mp.add_forced_key_binding('7', 'search_string_7', function() update_search_results('7') end, 'repeatable')
	mp.add_forced_key_binding('8', 'search_string_8', function() update_search_results('8') end, 'repeatable')
	mp.add_forced_key_binding('9', 'search_string_9', function() update_search_results('9') end, 'repeatable')
	mp.add_forced_key_binding('0', 'search_string_0', function() update_search_results('0') end, 'repeatable')

	mp.add_forced_key_binding('SPACE', 'search_string_space', function() update_search_results(' ') end, 'repeatable')
	mp.add_forced_key_binding('`', 'search_string_`', function() update_search_results('`') end, 'repeatable')
	mp.add_forced_key_binding('~', 'search_string_~', function() update_search_results('~') end, 'repeatable')
	mp.add_forced_key_binding('!', 'search_string_!', function() update_search_results('!') end, 'repeatable')
	mp.add_forced_key_binding('@', 'search_string_@', function() update_search_results('@') end, 'repeatable')
	mp.add_forced_key_binding('SHARP', 'search_string_sharp', function() update_search_results('#') end, 'repeatable')
	mp.add_forced_key_binding('$', 'search_string_$', function() update_search_results('$') end, 'repeatable')
	mp.add_forced_key_binding('%', 'search_string_percentage', function() update_search_results('%') end, 'repeatable')
	mp.add_forced_key_binding('^', 'search_string_^', function() update_search_results('^') end, 'repeatable')
	mp.add_forced_key_binding('&', 'search_string_&', function() update_search_results('&') end, 'repeatable')
	mp.add_forced_key_binding('*', 'search_string_*', function() update_search_results('*') end, 'repeatable')
	mp.add_forced_key_binding('(', 'search_string_(', function() update_search_results('(') end, 'repeatable')
	mp.add_forced_key_binding(')', 'search_string_)', function() update_search_results(')') end, 'repeatable')
	mp.add_forced_key_binding('-', 'search_string_-', function() update_search_results('-') end, 'repeatable')
	mp.add_forced_key_binding('_', 'search_string__', function() update_search_results('_') end, 'repeatable')
	mp.add_forced_key_binding('=', 'search_string_=', function() update_search_results('=') end, 'repeatable')
	mp.add_forced_key_binding('+', 'search_string_+', function() update_search_results('+') end, 'repeatable')
	mp.add_forced_key_binding('\\', 'search_string_\\', function() update_search_results('\\') end, 'repeatable')
	mp.add_forced_key_binding('|', 'search_string_|', function() update_search_results('|') end, 'repeatable')
	mp.add_forced_key_binding(']', 'search_string_]', function() update_search_results(']') end, 'repeatable')
	mp.add_forced_key_binding('}', 'search_string_rightcurly', function() update_search_results('}') end, 'repeatable')
	mp.add_forced_key_binding('[', 'search_string_[', function() update_search_results('[') end, 'repeatable')
	mp.add_forced_key_binding('{', 'search_string_leftcurly', function() update_search_results('{') end, 'repeatable')
	mp.add_forced_key_binding('\'', 'search_string_\'', function() update_search_results('\'') end, 'repeatable')
	mp.add_forced_key_binding('\"', 'search_string_\"', function() update_search_results('\"') end, 'repeatable')
	mp.add_forced_key_binding(';', 'search_string_semicolon', function() update_search_results(';') end, 'repeatable')
	mp.add_forced_key_binding(':', 'search_string_:', function() update_search_results(':') end, 'repeatable')
	mp.add_forced_key_binding('/', 'search_string_/', function() update_search_results('/') end, 'repeatable')
	mp.add_forced_key_binding('?', 'search_string_?', function() update_search_results('?') end, 'repeatable')
	mp.add_forced_key_binding('.', 'search_string_.', function() update_search_results('.') end, 'repeatable')
	mp.add_forced_key_binding('>', 'search_string_>', function() update_search_results('>') end, 'repeatable')
	mp.add_forced_key_binding(',', 'search_string_,', function() update_search_results(',') end, 'repeatable')
	mp.add_forced_key_binding('<', 'search_string_<', function() update_search_results('<') end, 'repeatable')

	mp.add_forced_key_binding('bs', 'search_string_del', function() update_search_results('', 'string_del') end, 'repeatable')
	bind_keys(o.list_close_keybind, 'search_exit', function() list_search_exit() end)
	bind_keys(o.list_search_not_typing_mode_keybind, 'search_string_not_typing', function()list_search_not_typing_mode(false) end)

	if o.search_not_typing_smartly then
		bind_keys(o.list_move_up_keybind, 'move-up', function() list_move_up() list_search_not_typing_mode(true) end)
		bind_keys(o.list_move_down_keybind, 'move-down', function() list_move_down() list_search_not_typing_mode(true) end)
		bind_keys(o.list_move_first_keybind, 'move-first', function() list_move_first() list_search_not_typing_mode(true) end)
		bind_keys(o.list_move_last_keybind, 'move-last', function() list_move_last() list_search_not_typing_mode(true) end)
		bind_keys(o.list_page_up_keybind, 'page-up', function() list_page_up() list_search_not_typing_mode(true) end)
		bind_keys(o.list_page_down_keybind, 'page-down', function() list_page_down() list_search_not_typing_mode(true) end)
		bind_keys(o.next_filter_sequence_keybind, 'list-filter-next', function() list_filter_next() list_search_not_typing_mode(true) end)
		bind_keys(o.previous_filter_sequence_keybind, 'list-filter-previous', function() list_filter_previous() list_search_not_typing_mode(true) end)
		bind_keys(o.list_delete_keybind, 'list-delete', function() list_delete() list_search_not_typing_mode(true) end)
		bind_keys(o.keybinds_remove_keybind, 'keybind-slot-remove', function() slot_remove()  list_search_not_typing_mode(true) end)
	end
end

function unbind_search_keys()
	mp.remove_key_binding('search_string_a')
	mp.remove_key_binding('search_string_b')
	mp.remove_key_binding('search_string_c')
	mp.remove_key_binding('search_string_d')
	mp.remove_key_binding('search_string_e')
	mp.remove_key_binding('search_string_f')
	mp.remove_key_binding('search_string_g')
	mp.remove_key_binding('search_string_h')
	mp.remove_key_binding('search_string_i')
	mp.remove_key_binding('search_string_j')
	mp.remove_key_binding('search_string_k')
	mp.remove_key_binding('search_string_l')
	mp.remove_key_binding('search_string_m')
	mp.remove_key_binding('search_string_n')
	mp.remove_key_binding('search_string_o')
	mp.remove_key_binding('search_string_p')
	mp.remove_key_binding('search_string_q')
	mp.remove_key_binding('search_string_r')
	mp.remove_key_binding('search_string_s')
	mp.remove_key_binding('search_string_t')
	mp.remove_key_binding('search_string_u')
	mp.remove_key_binding('search_string_v')
	mp.remove_key_binding('search_string_w')
	mp.remove_key_binding('search_string_x')
	mp.remove_key_binding('search_string_y')
	mp.remove_key_binding('search_string_z')
	
	mp.remove_key_binding('search_string_A')
	mp.remove_key_binding('search_string_B')
	mp.remove_key_binding('search_string_C')
	mp.remove_key_binding('search_string_D')
	mp.remove_key_binding('search_string_E')
	mp.remove_key_binding('search_string_F')
	mp.remove_key_binding('search_string_G')
	mp.remove_key_binding('search_string_H')
	mp.remove_key_binding('search_string_I')
	mp.remove_key_binding('search_string_J')
	mp.remove_key_binding('search_string_K')
	mp.remove_key_binding('search_string_L')
	mp.remove_key_binding('search_string_M')
	mp.remove_key_binding('search_string_N')
	mp.remove_key_binding('search_string_O')
	mp.remove_key_binding('search_string_P')
	mp.remove_key_binding('search_string_Q')
	mp.remove_key_binding('search_string_R')
	mp.remove_key_binding('search_string_S')
	mp.remove_key_binding('search_string_T')
	mp.remove_key_binding('search_string_U')
	mp.remove_key_binding('search_string_V')
	mp.remove_key_binding('search_string_W')
	mp.remove_key_binding('search_string_X')
	mp.remove_key_binding('search_string_Y')
	mp.remove_key_binding('search_string_Z')
	
	mp.remove_key_binding('search_string_1')
	mp.remove_key_binding('search_string_2')
	mp.remove_key_binding('search_string_3')
	mp.remove_key_binding('search_string_4')
	mp.remove_key_binding('search_string_5')
	mp.remove_key_binding('search_string_6')
	mp.remove_key_binding('search_string_7')
	mp.remove_key_binding('search_string_8')
	mp.remove_key_binding('search_string_9')
	mp.remove_key_binding('search_string_0')
	
	mp.remove_key_binding('search_string_space')
	mp.remove_key_binding('search_string_`')
	mp.remove_key_binding('search_string_~')
	mp.remove_key_binding('search_string_!')
	mp.remove_key_binding('search_string_@')
	mp.remove_key_binding('search_string_sharp')
	mp.remove_key_binding('search_string_$')
	mp.remove_key_binding('search_string_percentage')
	mp.remove_key_binding('search_string_^')
	mp.remove_key_binding('search_string_&')
	mp.remove_key_binding('search_string_*')
	mp.remove_key_binding('search_string_(')
	mp.remove_key_binding('search_string_)')
	mp.remove_key_binding('search_string_-')
	mp.remove_key_binding('search_string__')
	mp.remove_key_binding('search_string_=')
	mp.remove_key_binding('search_string_+')
	mp.remove_key_binding('search_string_\\')
	mp.remove_key_binding('search_string_|')
	mp.remove_key_binding('search_string_]')
	mp.remove_key_binding('search_string_rightcurly')
	mp.remove_key_binding('search_string_[')
	mp.remove_key_binding('search_string_leftcurly')
	mp.remove_key_binding('search_string_\'')
	mp.remove_key_binding('search_string_\"')
	mp.remove_key_binding('search_string_semicolon')
	mp.remove_key_binding('search_string_:')
	mp.remove_key_binding('search_string_/')
	mp.remove_key_binding('search_string_?')
	mp.remove_key_binding('search_string_.')
	mp.remove_key_binding('search_string_>')
	mp.remove_key_binding('search_string_,')
	mp.remove_key_binding('search_string_<')
	
	mp.remove_key_binding('search_string_del')
	if not search_active then
		unbind_keys(o.list_close_keybind, 'search_exit')
	end
end
--End of LogReaderManager Search Feature--
---------End of LogReaderManager---------

--Keybind Slot Feature--
function remove_slot_log_entry()
	local content = read_log(function(line)
		if line:match(' | .* | ' .. esc_string(log_keybind_text) .. slotKeyIndex) then
			return line:match('(.* | ' .. esc_string(log_time_text) .. '%d*%.?%d*)(.*)$')
		else
			return line
		end
	end)
	
	f = io.open(log_fullpath, "w+")
	if content then
		for i = 1, #content do
			f:write(("%s\n"):format(content[i]))
		end
	end
	f:close()
end

function add_slot_log_entry()
	get_list_contents('all','added-asc', true)
	if not list_contents or not list_contents[1] then return end	

	for i = #list_contents, 1, -1 do
		if list_contents[i].found_path == filePath and tonumber(list_contents[i].found_time) == seekTime then
			list_contents[i].found_line = list_contents[i].found_line:match('(.* | ' .. esc_string(log_time_text) .. '%d*%.?%d*)(.*)$')..' | '.. log_keybind_text .. slotKeyIndex
			break
		end
	end
	
	f = io.open(log_fullpath, "w+")
	if list_contents ~= nil and list_contents[1] then
		for i = 1, #list_contents do
			f:write(("%s\n"):format(list_contents[i].found_line))
		end
	end
	f:close()
end

function list_slot_remove()
	if not list_drawn then return end
	slotKeyIndex = tonumber(list_contents[#list_contents - list_cursor + 1].found_slot)
	if not slotKeyIndex then
		msg.info("Failed to remove")
		return
	end
	remove_slot_log_entry()
	msg.info('Removed Keybind: ' .. get_slot_keybind(slotKeyIndex))
end

function list_slot_add()
	if not list_drawn then return end
	filePath = list_contents[#list_contents - list_cursor + 1].found_path
	fileTitle = list_contents[#list_contents - list_cursor + 1].found_name
	seekTime = tonumber(list_contents[#list_contents - list_cursor + 1].found_time)
	if not filePath or not fileTitle or not seekTime then
		msg.info("Failed to add slot")
		return
	end
	remove_slot_log_entry()
	add_slot_log_entry()
	msg.info('Added Keybind:\n' .. fileTitle .. o.time_seperator .. format_time(seekTime) .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex))
	filePath, fileTitle = get_path()
end

function slot_remove()
	list_slot_remove()
	get_list_contents()
	if #list_contents == 0 then
		list_cursor = 0
		select(list_cursor)
	elseif list_cursor ~= #list_contents + 1 then
		select(0) 
	else 
		select(-1) 
	end
end

function slot_add()
	list_slot_add()
	get_list_contents()
	if #list_contents == 0 then
		list_cursor = 0
		select(list_cursor)
	elseif list_cursor ~= #list_contents + 1 then
		select(0) 
	else 
		select(-1) 
	end
end
--End of Keybind Slot Feature--

function mark_chapter()
	if not o.mark_bookmark_as_chapter then return end
	
	local all_chapters = mp.get_property_native("chapter-list")
	local chapter_index = 0
	local chapters_time = {}
	
	get_list_contents()
	for i = 1, #list_contents do
		if list_contents[i].found_path == filePath and tonumber(list_contents[i].found_time) > 0 then
			table.insert(chapters_time, tonumber(list_contents[i].found_time))
		end
	end
	if not chapters_time[1] then return end
	
	table.sort(chapters_time, function(a, b) return a < b end)
	
	for i = 1, #chapters_time do
		chapter_index = chapter_index + 1
		
		all_chapters[chapter_index] = {
			title = 'SimpleBookmark ' .. chapter_index,
			time = chapters_time[i]
		}
	end
	
	table.sort(all_chapters, function(a, b) return a['time'] < b['time'] end)
	
	mp.set_property_native("chapter-list", all_chapters)
end

function write_log(target_time, keybind_slot, update_seekTime, entry_limit)
	if not filePath then return end
	local prev_seekTime = seekTime

	seekTime = (mp.get_property_number('time-pos') or 0)
	if target_time then
		seekTime = target_time
	end
	if seekTime < 0 then seekTime = 0 end
	
	delete_log_entry(false, true, filePath, math.floor(seekTime), entry_limit)
	if keybind_slot then
		remove_slot_log_entry()
	end
	f = io.open(log_fullpath, "a+")
	if o.file_title_logging == 'all' then
		f:write(("[%s] \"%s\" | %s | %s"):format(os.date(o.date_format), fileTitle, filePath, log_time_text .. tostring(seekTime)))
	elseif o.file_title_logging == 'protocols' and (starts_protocol(o.logging_protocols, filePath)) then
		f:write(("[%s] \"%s\" | %s | %s"):format(os.date(o.date_format), fileTitle, filePath, log_time_text .. tostring(seekTime)))
	elseif o.file_title_logging == 'protocols' and not (starts_protocol(o.logging_protocols, filePath)) then
		f:write(("[%s] %s | %s"):format(os.date(o.date_format), filePath, log_time_text .. tostring(seekTime)))
	else
		f:write(("[%s] %s | %s"):format(os.date(o.date_format), filePath, log_time_text .. tostring(seekTime)))
	end
	if keybind_slot then
		f:write(' | ' .. log_keybind_text .. slotKeyIndex)
	end
	f:write('\n')
	f:close()
	
	if not update_seekTime then
		seekTime = prev_seekTime
	end
end

function add_load_slot(key_index)
	if not key_index then return end
	slotKeyIndex = key_index
	local current_filePath = mp.get_property('path')
	
	if list_drawn then
		slot_add()
	else
		local slot_taken = false
		get_list_contents()
		if list_contents ~= nil and list_contents[1] then
			for i = 1, #list_contents do
				if tonumber(list_contents[i].found_slot) == slotKeyIndex then
					filePath = list_contents[i].found_path
					fileTitle = list_contents[i].found_name
					seekTime = tonumber(list_contents[i].found_time)
					slot_taken = true
					break
				end
			end
			if slot_taken then
				if file_exists(filePath) or starts_protocol(protocols, filePath) then
					if filePath ~= current_filePath then
						mp.commandv('loadfile', filePath)
						if o.keybinds_auto_resume then
							resume_selected = true
						end
					elseif filePath == current_filePath and o.keybinds_auto_resume then
						mp.commandv('seek', seekTime, 'absolute', 'exact')
						list_close_and_trash_collection()
					elseif filePath == current_filePath and not o.keybinds_auto_resume then
						mp.commandv('seek', 0, 'absolute', 'exact')
						list_close_and_trash_collection()
					end
					if o.keybinds_auto_resume then
						if o.osd_messages == true then
							mp.osd_message('Loaded slot:' .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex) .. '\n' .. fileTitle .. o.time_seperator .. format_time(seekTime))
						end
						msg.info('Loaded slot:' .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex) .. '\n' .. fileTitle .. o.time_seperator .. format_time(seekTime))						
					else
						if o.osd_messages == true then
							mp.osd_message('Loaded slot:' .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex) .. '\n' .. fileTitle)
						end
						msg.info('Loaded slot:' .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex) .. '\n' .. fileTitle)																	
					end
				else
					if o.osd_messages == true then
						mp.osd_message('File Doesn\'t Exist:\n' .. filePath)
					end
					msg.info('The file below doesn\'t seem to exist:\n' .. filePath)
					return
				end
			else
				if o.keybinds_empty_auto_create then
					if filePath ~= nil then
						if o.keybinds_empty_fileonly then
							write_log(0, true)
						else
							write_log(false, true)
						end
						if o.osd_messages == true then
							mp.osd_message('Bookmarked & Added Keybind:\n' .. fileTitle .. o.time_seperator .. format_time(seekTime) .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex))
						end
						msg.info('Bookmarked the below & added keybind:\n' .. fileTitle .. o.time_seperator .. format_time(seekTime) .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex))
					else
						if o.osd_messages == true then
							mp.osd_message('Failed to Bookmark & Auto Create Keybind\nNo Video Found')
						end
						msg.info("Failed to bookmark & auto create keybind, no video found")
					end
				else
					if o.osd_messages == true then
						mp.osd_message('No Bookmark Slot For' .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex) .. ' Yet')
					end
					msg.info('No bookmark slot has been assigned for' .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex) .. ' keybind yet')
				end
			end
		else
			if o.osd_messages == true then
				mp.osd_message('No Bookmark Slot For' .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex) .. ' Yet')
			end
			msg.info('No bookmark slot has been assigned for' .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex) .. ' keybind yet')
		end
	end
	slotKeyIndex = 0
end

function quicksave_slot(key_index)
	if not key_index then return end
	slotKeyIndex = key_index
	
	if list_drawn then
		slot_add()
	else
		if filePath ~= nil then
			if o.keybinds_quicksave_fileonly then
				write_log(0, true)
				if o.osd_messages == true then
					mp.osd_message('Bookmarked Fileonly & Added Keybind:\n' .. fileTitle .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex))
				end
				msg.info('Bookmarked the below & added keybind:\n' .. fileTitle .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex))
			else
				write_log(false, true, true)
				if o.osd_messages == true then
					mp.osd_message('Bookmarked & Added Keybind:\n' .. fileTitle .. o.time_seperator .. format_time(seekTime) .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex))
				end
				msg.info('Bookmarked the below & added keybind:\n' .. fileTitle .. o.time_seperator .. format_time(seekTime) .. o.keybinds_seperator .. get_slot_keybind(slotKeyIndex))
			end
		else
			if o.osd_messages == true then
				mp.osd_message('Failed to Bookmark & Auto Create Keybind\nNo Video Found')
			end
			msg.info("Failed to bookmark & auto create keybind, no video found")
		end
	end
	slotKeyIndex = 0
end

function bookmark_save()
	if filePath ~= nil then
		write_log(false, false, true, o.same_entry_limit)
		if list_drawn then
			get_list_contents()
			select(0)
		end
		if o.osd_messages == true then
			mp.osd_message('Bookmarked:\n' .. fileTitle .. o.time_seperator .. format_time(seekTime))
		end
		msg.info('Added the below to bookmarks\n' .. fileTitle .. o.time_seperator .. format_time(seekTime))
	elseif filePath == nil and o.bookmark_loads_last_idle then
		get_list_contents('all', 'added-asc')
		load(1)
	else
		if o.osd_messages == true then
			mp.osd_message('Failed to Bookmark\nNo Video Found')
		end
		msg.info("Failed to bookmark, no video found")
	end
end

function bookmark_fileonly_save()
	if filePath ~= nil then
		write_log(0, false, false, o.same_entry_limit)
		if list_drawn then
			get_list_contents()
			select(0)
		end
		if o.osd_messages == true then
			mp.osd_message('Bookmarked File Only:\n' .. fileTitle)
		end
		msg.info('Added the below to bookmarks\n' .. fileTitle)
	elseif filePath == nil and o.bookmark_fileonly_loads_last_idle then
		get_list_contents('all', 'added-asc')
		load(1, false, 0)
	else
		if o.osd_messages == true then
			mp.osd_message('Failed to Bookmark\nNo Video Found')
		end
		msg.info("Failed to bookmark, no video found")
	end
end

mp.register_event('file-loaded', function()
	list_close_and_trash_collection()
	filePath, fileTitle = get_path()
	if (resume_selected == true and seekTime ~= nil) then
		mp.commandv('seek', seekTime, 'absolute', 'exact')
		resume_selected = false
	end
	mark_chapter()
end)

if has_value(available_filters, o.auto_run_list_idle) then
	mp.observe_property("idle-active", "bool", function(_, v)
		if v then display_list(o.auto_run_list_idle, true) end
	end)
end

bind_keys(o.bookmark_save_keybind, 'bookmark-save', bookmark_save)
bind_keys(o.bookmark_fileonly_keybind, 'bookmark-fileonly', bookmark_fileonly_save)

for i = 1, #o.open_list_keybind do
	if i == 1 then
		mp.add_forced_key_binding(o.open_list_keybind[i][1], 'open-list', function()display_list(o.open_list_keybind[i][2]) end)
	else
		mp.add_forced_key_binding(o.open_list_keybind[i][1], 'open-list'..i, function()display_list(o.open_list_keybind[i][2]) end)
	end
end

for i = 1, #o.keybinds_add_load_keybind do
	mp.add_forced_key_binding(o.keybinds_add_load_keybind[i], 'keybind-slot-' .. i, function()add_load_slot(i) end)
end

for i = 1, #o.keybinds_quicksave_keybind do
	mp.add_forced_key_binding(o.keybinds_quicksave_keybind[i], 'keybind-slot-save-' .. i, function()quicksave_slot(i) end)
end
