-- Copyright (c) 2022, Eisa AlAwadhi
-- License: BSD 2-Clause License
-- Creator: Eisa AlAwadhi
-- Project: SimpleHistory
-- Version: 1.1.6

local o = {
---------------------------USER CUSTOMIZATION SETTINGS---------------------------
--These settings are for users to manually change some options.
--Changes are recommended to be made in the script-opts directory.

	-----Script Settings----
	auto_run_list_idle = 'recents', --Auto run the list when opening mpv and there is no video / file loaded. 'none' for disabled. Or choose between: 'all', 'recents', 'distinct', 'protocols', 'fileonly', 'titleonly', 'timeonly', 'keywords'.
	startup_idle_behavior = 'none', --The behavior when mpv launches and nothing is loaded. 'none' for disabled. 'resume' to automatically resume your last played item. 'resume-notime' to resume your last played item but starts from the beginning.
	toggle_idlescreen = false, --hides OSC idle screen message when opening and closing menu (could cause unexpected behavior if multiple scripts are triggering osc-idlescreen off)
	resume_offset = -0.65, --change to 0 so item resumes from the exact position, or decrease the value so that it gives you a little preview before loading the resume point
	osd_messages = true, --true is for displaying osd messages when actions occur. Change to false will disable all osd messages generated from this script
	resume_option = 'notification', --'none': for disabled. 'notification': a message to resume the previous reached time will be triggered. 'force': to forcefully resume last playback based on threshold
	resume_option_threshold = 2, --0 to always trigger the resume option when the same video has been played previously, a value such as 5 will only trigger the resume option if the last played time starts after 5% of the video and ends before completion by 5%
	mark_history_as_chapter = false, --true is for marking the time as a chapter. false disables mark as chapter behavior.
	invert_history_blacklist = false, --true so that blacklist becomes a whitelist, resulting in stuff such as paths / websites that are added to history_blacklist to be saved into history
	history_blacklist=[[
	[""]
	]], --Paths / URLs / Websites / Files / Protocols / Extensions, that wont be added to history automatically, e.g.: ["c:\\users\\eisa01\\desktop", "c:\\users\\eisa01\\desktop\\*", "c:\\temp\\naruto-01.mp4", "youtube.com", "https://dailymotion.com/", "avi", "https://www.youtube.com/watch?v=e8YBesRKq_U", ".jpeg", "magnet:", "https://", "ftp"]
	history_resume_keybind=[[
	["ctrl+r", "ctrl+R"]
	]], --Keybind that will be used to immediately load and resume last item when no video is playing. If video is playing it will resume to the last found position
	history_load_last_keybind=[[
	["alt+r", "alt+R"]
	]], --Keybind that will be used to immediately load the last item without resuming when no video is playing. If video is playing then it will add into playlist
	open_list_keybind=[[
	[ ["h", "all"], ["H", "all"], ["r", "recents"], ["R", "recents"] ]
	]], --Keybind that will be used to open the list along with the specified filter. Available filters: 'all', 'recents', 'distinct', 'protocols', 'fileonly', 'titleonly', 'timeonly', 'keywords'.
	list_filter_jump_keybind=[[
	[ ["h", "all"], ["H", "all"], ["r", "recents"], ["R", "recents"], ["d", "distinct"], ["D", "distinct"], ["f", "fileonly"], ["F", "fileonly"] ]
	]], --Keybind that is used while the list is open to jump to the specific filter (it also enables pressing a filter keybind twice to close list). Available fitlers: 'all', 'recents', 'distinct', 'protocols', 'fileonly', 'titleonly', 'timeonly', 'keywords'.
	
	-----Incognito Settings----
	auto_run_incognito_mode = false, --true to automatically start incognito mode when mpv launches, false disables this behavior
	delete_incognito_entry = true, --true so that the file that had incognito mode triggered on gets removed from history automatically, false keeps the file in history that incognito mode triggered on
	restore_incognito_entry = 'always', --'none' for disabled, 'deleted-restore' so that the the file that was removed when entering incognito automtically gets restored, 'always' so that exiting incognito_mode always immediately updates entry into history
	history_incognito_mode_keybind=[[
	["ctrl+H"]
	]], --Triggers incognito mode. When enabled files played wont be added to history until this mode is disabled.
	
	-----Logging Settings-----
	log_path = '/:dir%mpvconf%', --Change to '/:dir%script%' for placing it in the same directory of script, OR change to '/:dir%mpvconf%' for mpv portable_config directory. OR write any variable using '/:var' then the variable '/:var%APPDATA%' you can use path also, such as: '/:var%APPDATA%\\mpv' OR '/:var%HOME%/mpv' OR specify the absolute path , e.g.: 'C:\\Users\\Eisa01\\Desktop\\'
	log_file = 'mpvHistory.log', --name+extension of the file that will be used to store the log data
	date_format = '%A/%B %d/%m/%Y %X', --Date format in the log (see lua date formatting), e.g.:'%d/%m/%y %X' or '%d/%b/%y %X'
	file_title_logging = 'protocols', --Change between 'all', 'protocols', 'none'. This option will store the media title in log file, it is useful for websites / protocols because title cannot be parsed from links alone
	logging_protocols=[[
	["://", "magnet:"]
	]], --add above (after a comma) any protocol you want its title to be stored in the log file. This is valid only for (file_title_logging = 'protocols' or file_title_logging = 'all')
	prefer_filename_over_title = 'local', --Prefers to log filename over filetitle. Select between 'local', 'protocols', 'all', and 'none'. 'local' prefer filenames for videos that are not protocols. 'protocols' will prefer filenames for protocols only. 'all' will prefer filename over filetitle for both protocols and not protocols videos. 'none' will always use filetitle instead of filename
	same_entry_limit = 2, --Limit saving entries with same path: -1 for unlimited, 0 will always update entries of same path, e.g. value of 3 will have the limit of 3 then it will start updating old values on the 4th entry.

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
	search_behavior = 'any', --'specific' to find a match of either a date, title, path / url, time. 'any' to find any typed search based on combination of date, title, path / url, and time. 'any-notime' to find any typed search based on combination of date, title, and path / url, but without looking for time (this is to reduce unwanted results).
	
	-----Filter Settings------
	--available filters: "all" to display all the items. Or "recents" to display recently added items to log without duplicate. Or "distinct" to show recent saved entries for files in different paths. Or "fileonly" to display files saved without time. Or "timeonly" to display files that have time only. Or "keywords" to display files with matching keywords specified in the configuration. Or "playing" to show list of current playing file.
	filters_and_sequence=[[
	["all", "recents", "distinct", "protocols", "playing", "fileonly", "titleonly", "keywords"]
	]], --Jump to the following filters and in the shown sequence when navigating via left and right keys. You can change the sequence and delete filters that are not needed.
	next_filter_sequence_keybind=[[
	["RIGHT", "MBTN_FORWARD"]
	]], --Keybind that will be used to go to the next available filter based on the filters_and_sequence
	previous_filter_sequence_keybind=[[
	["LEFT", "MBTN_BACK"]
	]], --Keybind that will be used to go to the previous available filter based on the filters_and_sequence
	loop_through_filters = true, --true is for bypassing the last filter to go to first filter when navigating through filters using arrow keys, and vice-versa. false disables this behavior.
	keywords_filter_list=[[
	[""]
	]], --Create a filter out of your desired 'keywords', e.g.: youtube.com will filter out the videos from youtube. You can also insert a portion of filename or title, or extension or a full path / portion of a path. e.g.: ["youtube.com", "mp4", "naruto", "c:\\users\\eisa01\\desktop"]

	-----Sort Settings------
	--available sort: 'added-asc' is for the newest added item to show first. Or 'added-desc' for the newest added to show last. Or 'alphanum-asc' is for A to Z approach with filename and episode number lower first. Or 'alphanum-desc' is for its Z to A approach. Or 'time-asc', 'time-desc' to sort the list based on time.
	list_default_sort = 'added-asc', --the default sorting method for all the different filters in the list. select between 'added-asc', 'added-desc', 'time-asc', 'time-desc', 'alphanum-asc', 'alphanum-desc'
	list_filters_sort=[[
	[ ]
	]], --Default sort for specific filters, e.g.: [ ["all", "alphanum-asc"], ["playing", "added-desc"] ]
	list_cycle_sort_keybind=[[
	["alt+s", "alt+S"]
	]], --Keybind to cycle through the different available sorts when list is open

	-----List Design Settings-----
	list_alignment = 7, --The alignment for the list, uses numpad positions choose from 1-9 or 0 to disable. e,g.:7 top left alignment, 8 top middle alignment, 9 top right alignment.	
	text_time_type = 'duration', --The time type for items on the list. Select between 'duration', 'length', 'remaining'.
	time_seperator = ' 🕒 ', --Time seperator that will be used before the time
	list_sliced_prefix = '...\\h\\N\\N', --The text that indicates there are more items above. \\N is for new line. \\h is for hard space.
	list_sliced_suffix = '...', --The text that indicates there are more items below.
	quickselect_0to9_pre_text = false, --true enables pre text for showing quickselect keybinds before the list. false to disable
	text_color = 'ffffff', --Text color for list in BGR hexadecimal
	text_scale = 50, --Font size for the text of list
	text_border = 0.7, --Black border size for the text of list
	text_cursor_color = 'ffbf7f', --Text color of current cursor position in BGR hexadecimal
	text_cursor_scale = 50, --Font size for text of current cursor position in list
	text_cursor_border = 0.7, --Black border size for text of current cursor position in list
	text_highlight_pre_text = '✅ ', --Pre text for highlighted multi-select item
	search_color_typing = 'ffffaa', --Search color when in typing mode
	search_color_not_typing = '00bfff', --Search color when not in typing mode and it is active
	header_color = '00bfff', --Header color in BGR hexadecimal
	header_scale = 55, --Header text size for the list
	header_border = 0.8, --Black border size for the Header of list
	header_text = '⌛ History [%cursor%/%total%]%prehighlight%%highlight%%afterhighlight%%prelistduration%%listduration%%afterlistduration%%prefilter%%filter%%afterfilter%%presort%%sort%%aftersort%%presearch%%search%%aftersearch%', --Text to be shown as header for the list
	--Available header variables: %cursor%, %total%, %highlight%, %filter%, %search%, %listduration%, %listlength%, %listremaining%
	--User defined text that only displays if a variable is triggered: %prefilter%, %afterfilter%, %prehighlight%, %afterhighlight% %presearch%, %aftersearch%, %prelistduration%, %afterlistduration%, %prelistlength%, %afterlistlength%, %prelistremaining%, %afterlistremaining%
	--Variables explanation: %cursor: displays the number of cursor position in list. %total: total amount of items in current list. %highlight%: total number of highlighted items.  %filter: shows the filter name, %search: shows the typed search. Example of user defined text that only displays if a variable is triggered of user: %prefilter: user defined text before showing filter, %afterfilter: user defined text after showing filter.
	header_sort_hide_text = 'added-asc',--Sort method that is hidden from header when using %sort% variable
	header_sort_pre_text = ' \\{',--Text to be shown before sort in the header, when using %presort%
	header_sort_after_text = '}',--Text to be shown after sort in the header, when using %aftersort%
	header_filter_pre_text = ' [Filter: ', --Text to be shown before filter in the header, when using %prefilter%
	header_filter_after_text = ']', --Text to be shown after filter in the header, when using %afterfilter%
	header_search_pre_text = '\\h\\N\\N[Search=', --Text to be shown before search in the header, when using %presearch%
	header_search_after_text = '..]', --Text to be shown after search in the header, when using %aftersearch%
	header_highlight_pre_text = '✅', --Text to be shown before total highlighted items of displayed list in the header
	header_highlight_after_text = '', --Text to be shown after total highlighted items of displayed list in the header
	header_list_duration_pre_text = ' 🕒 ', --Text to be shown before playback total duration of displayed list in the header
	header_list_duration_after_text = '', --Text to be shown after playback total duration of displayed list in the header
	header_list_length_pre_text = ' 🕒 ', --Text to be shown before playback total duration of displayed list in the header
	header_list_length_after_text = '', --Text to be shown after playback total duration of displayed list in the header
	header_list_remaining_pre_text = ' 🕒 ', --Text to be shown before playback total duration of displayed list in the header
	header_list_remaining_after_text = '', --Text to be shown after playback total duration of displayed list in the header
	
	-----Time Format Settings-----
	--in the first parameter, you can define from the available styles: default, hms, hms-full, timestamp, timestamp-concise "default" to show in HH:MM:SS.sss format. "hms" to show in 1h 2m 3.4s format. "hms-full" is the same as hms but keeps the hours and minutes persistent when they are 0. "timestamp" to show the total time as timestamp 123456.700 format. "timestamp-concise" shows the total time in 123456.7 format (shows and hides decimals depending on availability).
	--in the second parameter, you can define whether to show milliseconds, round them or truncate them. Available options: 'truncate' to remove the milliseconds and keep the seconds. 0 to remove the milliseconds and round the seconds. 1 or above is the amount of milliseconds to display. The default value is 3 milliseconds.
	--in the third parameter you can define the seperator between hour:minute:second. "default" style is automatically set to ":", "hms", "hms-full" are automatically set to " ". You can define your own. Some examples: ["default", 3, "-"],["hms-full", 5, "."],["hms", "truncate", ":"],["timestamp-concise"],["timestamp", 0],["timestamp", "truncate"],["timestamp", 5]
	osd_time_format=[[
	["default", "truncate"]
	]],
	list_time_format=[[
	["default", "truncate"]
	]],
	header_duration_time_format=[[
	["hms", "truncate", ":"]
	]],
	header_length_time_format=[[
	["hms", "truncate", ":"]
	]],
	header_remaining_time_format=[[
	["hms", "truncate", ":"]
	]],

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
	list_highlight_move_keybind=[[
	["SHIFT"]
	]], --Keybind that will be used to highlight while pressing a navigational keybind, keep holding shift and then press any navigation keybind, such as: up, down, home, pgdwn, etc..
	list_highlight_all_keybind=[[
	["ctrl+a", "ctrl+A"]
	]], --Keybind that will be used to highlight all displayed items on the list
	list_unhighlight_all_keybind=[[
	["ctrl+d", "ctrl+D"]
	]], --Keybind that will be used to remove all currently highlighted items from the list
	list_select_keybind=[[
	["ENTER", "MBTN_MID"]
	]], --Keybind that will be used to load entry based on cursor position
	list_add_playlist_keybind=[[
	["CTRL+ENTER"]
	]], --Keybind that will be used to add entry to playlist based on cursor position
	list_add_playlist_highlighted_keybind=[[
	["SHIFT+ENTER"]
	]], --Keybind that will be used to add all highlighted entries to playlist
	list_close_keybind=[[
	["ESC", "MBTN_RIGHT"]
	]], --Keybind that will be used to close the list (closes search first if it is open)
	list_delete_keybind=[[
	["DEL"]
	]], --Keybind that will be used to delete the entry based on cursor position
	list_delete_highlighted_keybind=[[
	["SHIFT+DEL"]
	]], --Keybind that will be used to delete all highlighted entries from the list
	list_search_activate_keybind=[[
	["ctrl+f", "ctrl+F"]
	]], --Keybind that will be used to trigger search
	list_search_not_typing_mode_keybind=[[
	["ALT+ENTER"]
	]], --Keybind that will be used to exit typing mode of search while keeping search open
	list_ignored_keybind=[[
	["B", "b", "k", "K", "c", "C"]
	]], --Keybind thats are ignored when list is open

---------------------------END OF USER CUSTOMIZATION SETTINGS---------------------------
}

(require 'mp.options').read_options(o)
local utils = require 'mp.utils'
local msg = require 'mp.msg'

o.history_blacklist = utils.parse_json(o.history_blacklist)
o.history_incognito_mode_keybind = utils.parse_json(o.history_incognito_mode_keybind)
o.filters_and_sequence = utils.parse_json(o.filters_and_sequence)
o.keywords_filter_list = utils.parse_json(o.keywords_filter_list)
o.list_filters_sort = utils.parse_json(o.list_filters_sort)
o.logging_protocols = utils.parse_json(o.logging_protocols)
o.history_resume_keybind = utils.parse_json(o.history_resume_keybind)
o.history_load_last_keybind = utils.parse_json(o.history_load_last_keybind)
o.osd_time_format = utils.parse_json(o.osd_time_format)
o.list_time_format = utils.parse_json(o.list_time_format)
o.header_duration_time_format = utils.parse_json(o.header_duration_time_format)
o.header_length_time_format = utils.parse_json(o.header_length_time_format)
o.header_remaining_time_format = utils.parse_json(o.header_remaining_time_format)
o.list_move_up_keybind = utils.parse_json(o.list_move_up_keybind)
o.list_move_down_keybind = utils.parse_json(o.list_move_down_keybind)
o.list_page_up_keybind = utils.parse_json(o.list_page_up_keybind)
o.list_page_down_keybind = utils.parse_json(o.list_page_down_keybind)
o.list_move_first_keybind = utils.parse_json(o.list_move_first_keybind)
o.list_move_last_keybind = utils.parse_json(o.list_move_last_keybind)
o.list_highlight_move_keybind = utils.parse_json(o.list_highlight_move_keybind)
o.list_highlight_all_keybind = utils.parse_json(o.list_highlight_all_keybind)
o.list_unhighlight_all_keybind = utils.parse_json(o.list_unhighlight_all_keybind)
o.list_cycle_sort_keybind = utils.parse_json(o.list_cycle_sort_keybind)
o.list_select_keybind = utils.parse_json(o.list_select_keybind)
o.list_add_playlist_keybind = utils.parse_json(o.list_add_playlist_keybind)
o.list_add_playlist_highlighted_keybind = utils.parse_json(o.list_add_playlist_highlighted_keybind)
o.list_close_keybind = utils.parse_json(o.list_close_keybind)
o.list_delete_keybind = utils.parse_json(o.list_delete_keybind)
o.list_delete_highlighted_keybind = utils.parse_json(o.list_delete_highlighted_keybind)
o.list_search_activate_keybind = utils.parse_json(o.list_search_activate_keybind)
o.list_search_not_typing_mode_keybind = utils.parse_json(o.list_search_not_typing_mode_keybind)
o.next_filter_sequence_keybind = utils.parse_json(o.next_filter_sequence_keybind)
o.previous_filter_sequence_keybind = utils.parse_json(o.previous_filter_sequence_keybind)
o.open_list_keybind = utils.parse_json(o.open_list_keybind)
o.list_filter_jump_keybind = utils.parse_json(o.list_filter_jump_keybind)
o.list_ignored_keybind = utils.parse_json(o.list_ignored_keybind)

local is_windows = package.config:sub(1, 1) == "\\" -- detect path separator, windows uses backslashes

if utils.shared_script_property_set then
	utils.shared_script_property_set('simplehistory-menu-open', 'no')
end
mp.set_property('user-data/simplehistory/menu-open', 'no')

if o.log_path:match('^/:dir%%mpvconf%%') then
	o.log_path = o.log_path:gsub('/:dir%%mpvconf%%', mp.find_config_file('.'))
elseif o.log_path:match('^/:dir%%script%%') then
	o.log_path = o.log_path:gsub('/:dir%%script%%', mp.find_config_file('scripts'))
elseif o.log_path:match('^/:var%%(.*)%%') then
	local os_variable = o.log_path:match('/:var%%(.*)%%')
	o.log_path = o.log_path:gsub('/:var%%(.*)%%', os.getenv(os_variable))
end
local log_fullpath = utils.join_path(o.log_path, o.log_file)

--create log_path if it doesn't exist
local log_path = utils.split_path(log_fullpath)
if utils.readdir(log_path) == nil then
	local is_windows = package.config:sub(1, 1) == "\\"
	local windows_args = { 'powershell', '-NoProfile', '-Command', 'mkdir', string.format("\"%s\"", log_path) }
	local unix_args = { 'mkdir', '-p', log_path }
	local args = is_windows and windows_args or unix_args
	local res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
	if res.status ~= 0 then
		msg.error("Failed to create log_path save directory "..log_path..". Error: "..(res.error or "unknown"))
		return
	end
end

local log_length_text = 'length='
local log_time_text = 'time='
local protocols = {'https?:', 'magnet:', 'rtmps?:', 'smb:', 'ftps?:', 'sftp:'}
local available_filters = {'all', 'recents', 'distinct', 'playing', 'protocols', 'fileonly', 'titleonly', 'timeonly', 'keywords'}
local available_sorts = {'added-asc', 'added-desc', 'time-asc', 'time-desc', 'alphanum-asc', 'alphanum-desc'}
local search_string = ''
local search_active = false

local incognito_mode = false
local autosaved_entry = false
local incognito_auto_run_triggered = false

local loadTriggered = false --1.1.5# to identify if load is triggered atleast once for idle option
local resume_selected = false
local list_contents = {}
local list_start = 0
local list_cursor = 1
local list_highlight_cursor = {}
local list_drawn = false
local list_pages = {}
local filePath, fileTitle, fileLength
local seekTime = 0
local logTime = 0 --1.3# use logTime since seekTime is used in multiple places
local filterName = 'all'
local sortName
local normalize_path = nil

function starts_protocol(tab, val)
	for index, element in ipairs(tab) do
		if string.find(val, element) then
			 		return true
		end
	end
	return false
end

function contain_value(tab, val)
	if not tab then return msg.error('check value passed') end
	if not val then return msg.error('check value passed') end
	
	for index, value in ipairs(tab) do
		if value.match(string.lower(val), string.lower(value)) then
			return true
		end
	end
	
	return false
end

function has_value(tab, val, array2d)
	if not tab then return msg.error('check value passed') end
	if not val then return msg.error('check value passed') end
	if not array2d then
		for index, value in ipairs(tab) do
			if string.lower(value) == string.lower(val) then
				return true
			end
		end
	end
	if array2d then
		for i=1, #tab do
			if tab[i] and string.lower(tab[i][array2d]) == string.lower(val) then
				return true
			end
		end
	end
	
	return false
end

function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then io.close(f) return true else return false end
end

function format_time(seconds, sep, decimals, style)
	local function divmod (a, b)
		return math.floor(a / b), a % b
	end
	decimals = decimals == nil and 3 or decimals
	
	local s = seconds
	local h, s = divmod(s, 60*60)
	local m, s = divmod(s, 60)

	if decimals == 'truncate' then
		s = math.floor(s)
		decimals = 0
		if style == 'timestamp' then
			seconds = math.floor(seconds)
		end
	end
	
	if not style or style == '' or style == 'default' then
		local second_format = string.format("%%0%d.%df", 2+(decimals > 0 and decimals+1 or 0), decimals)
		sep = sep and sep or ":"
		return string.format("%02d"..sep.."%02d"..sep..second_format, h, m, s)
	elseif style == 'hms' or style == 'hms-full' then
	  sep = sep ~= nil and sep or " "
	  if style == 'hms-full' or h > 0 then
		return string.format("%dh"..sep.."%dm"..sep.."%." .. tostring(decimals) .. "fs", h, m, s)
	  elseif m > 0 then
		return string.format("%dm"..sep.."%." .. tostring(decimals) .. "fs", m, s)
	  else
		return string.format("%." .. tostring(decimals) .. "fs", s)
	  end
	elseif style == 'timestamp' then
		return string.format("%." .. tostring(decimals) .. "f", seconds)
	elseif style == 'timestamp-concise' then
		return seconds
	end
end

function normalize(path)
    if normalize_path ~= nil then
        if normalize_path then
            path = mp.command_native({"normalize-path", path})
        else
            local directory = mp.get_property("working-directory", "")
            path = utils.join_path(directory, path:gsub('^%.[\\/]',''))
            if is_windows then path = path:gsub("\\", "/") end
        end
        return path
    end

    normalize_path = false

    local commands = mp.get_property_native("command-list", {})
    for _, command in ipairs(commands) do
        if command.name == "normalize-path" then
            normalize_path = true
            break
        end
    end
    return normalize(path)
end

function get_file()
	function hex_to_char(x)
		return string.char(tonumber(x, 16))
	end

	local path = mp.get_property('path')
	if not path then return end
	if path:match("bd://") or path:match("dvd://")  or path:match("dvb://") or path:match("cdda://") then return end
	if not path:match('^%a[%a%d-_]+://') then path = normalize(path) end
	
	local length = (mp.get_property_number('duration') or 0)
	
	local title = mp.get_property('media-title'):gsub("\"", "")
	
	
	if starts_protocol(o.logging_protocols, path) and o.prefer_filename_over_title == 'protocols' then
		title = mp.get_property('filename'):gsub("\"", "")
	elseif not starts_protocol(o.logging_protocols, path) and o.prefer_filename_over_title == 'local' then
		title = mp.get_property('filename'):gsub("\"", "")
	elseif o.prefer_filename_over_title == 'all' then
		title = mp.get_property('filename'):gsub("\"", "")
	end
	
	title = title:gsub('%%(%x%x)', hex_to_char)
	return path, title, length
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

---------Start of LogManager---------
--LogManager (Read and Format the List from Log)--
function read_log(func)
	local f = io.open(log_fullpath, "r")
	if not f then return end
	local contents = {}
	for line in f:lines() do
		table.insert(contents, (func(line)))
	end
	f:close()
	return contents
end

function read_log_table()
	local line_pos = 0
	return read_log(function(line)
		local tt, p, t, s, d, n, e, l, dt, ln, r
		if line:match('^.-\"(.-)\"') then
			tt = line:match('^.-\"(.-)\"')
			n, p = line:match('^.-\"(.-)\" | (.*) | ' .. esc_string(log_length_text) .. '(.*)')
		else
			p = line:match('[(.*)%]]%s(.*) | ' .. esc_string(log_length_text) .. '(.*)')
			d, n, e = p:match('^(.-)([^\\/]-)%.([^\\/%.]-)%.?$')
		end
		dt = line:match('%[(.-)%]')
		t = line:match(' | ' .. esc_string(log_time_text) .. '(%d*%.?%d*)(.*)$')
		ln = line:match(' | ' .. esc_string(log_length_text) .. '(%d*%.?%d*)(.*)$')
		r = tonumber(ln) - tonumber(t)
		l = line
		line_pos = line_pos + 1
		return {found_path = p, found_time = t, found_name = n, found_title = tt, found_line = l, found_sequence = line_pos, found_directory = d, found_datetime = dt, found_length = ln, found_remaining = r}
	end)
end

function list_sort(tab, sort)
	if sort == 'added-asc' then
		table.sort(tab, function(a, b) return a['found_sequence'] < b['found_sequence'] end)
	elseif sort == 'added-desc' then
		table.sort(tab, function(a, b) return a['found_sequence'] > b['found_sequence'] end)
	elseif sort == 'time-asc' then
		table.sort(tab, function(a, b) return tonumber(a['found_time']) > tonumber(b['found_time']) end)
	elseif sort == 'time-desc' then
		table.sort(tab, function(a, b) return tonumber(a['found_time']) < tonumber(b['found_time']) end)
	elseif sort == 'alphanum-asc' or sort == 'alphanum-desc' then
		local function padnum(d) local dec, n = string.match(d, "(%.?)0*(.+)")
			return #dec > 0 and ("%.12f"):format(d) or ("%s%03d%s"):format(dec, #n, n) end
		if sort == 'alphanum-asc' then
			table.sort(tab, function(a, b) return tostring(a['found_path']):lower():gsub("%.?%d+", padnum) .. ("%3d"):format(#b) > tostring(b['found_path']):lower():gsub("%.?%d+", padnum) .. ("%3d"):format(#a) end)
		elseif sort == 'alphanum-desc' then
			table.sort(tab, function(a, b) return tostring(a['found_path']):lower():gsub("%.?%d+", padnum) .. ("%3d"):format(#b) < tostring(b['found_path']):lower():gsub("%.?%d+", padnum) .. ("%3d"):format(#a) end)
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
	
	string = string:gsub("%%total%%", #list_contents)
		:gsub("%%cursor%%", list_cursor)

	if filterName ~= 'all' then
		string = string:gsub("%%filter%%", filterName)
		:gsub("%%prefilter%%", o.header_filter_pre_text)
		:gsub("%%afterfilter%%", o.header_filter_after_text)
	else
		string = string:gsub("%%filter%%", '')
		:gsub("%%prefilter%%", '')
		:gsub("%%afterfilter%%", '')
	end
	
	local list_total_duration = 0
	if string:match('%listduration%%') then
		list_total_duration = get_total_duration('found_time')
		if list_total_duration > 0 then
			string = string:gsub("%%listduration%%", format_time(list_total_duration, o.header_duration_time_format[3], o.header_duration_time_format[2], o.header_duration_time_format[1]))
		else
			string = string:gsub("%%listduration%%", '')
		end
	end	
	if list_total_duration > 0 then
		string = string:gsub("%%prelistduration%%", o.header_list_duration_pre_text)
		:gsub("%%afterlistduration%%", o.header_list_duration_after_text)
	else
		string = string:gsub("%%prelistduration%%", '')
		:gsub("%%afterlistduration%%", '')
	end
	
	local list_total_length = 0
	if string:match('%listlength%%') then
		list_total_length = get_total_duration('found_length')
		if list_total_length > 0 then
			string = string:gsub("%%listlength%%", format_time(list_total_length, o.header_length_time_format[3], o.header_length_time_format[2], o.header_length_time_format[1]))
		else
			string = string:gsub("%%listlength%%", '')
		end
	end	
	if list_total_length > 0 then
		string = string:gsub("%%prelistlength%%", o.header_list_length_pre_text)
		:gsub("%%afterlistlength%%", o.header_list_length_after_text)
	else
		string = string:gsub("%%prelistlength%%", '')
		:gsub("%%afterlistlength%%", '')
	end
	
	local list_total_remaining = 0
	if string:match('%listremaining%%') then
		list_total_remaining = get_total_duration('found_remaining')
		if list_total_remaining > 0 then
			string = string:gsub("%%listremaining%%", format_time(list_total_remaining, o.header_remaining_time_format[3], o.header_remaining_time_format[2], o.header_remaining_time_format[1]))
		else
			string = string:gsub("%%listremaining%%", '')
		end
	end	
	if list_total_remaining > 0 then
		string = string:gsub("%%prelistremaining%%", o.header_list_remaining_pre_text)
		:gsub("%%afterlistremaining%%", o.header_list_remaining_after_text)
	else
		string = string:gsub("%%prelistremaining%%", '')
		:gsub("%%afterlistremaining%%", '')
	end
	
	if #list_highlight_cursor > 0 then
		string = string:gsub("%%highlight%%", #list_highlight_cursor)
		:gsub("%%prehighlight%%", o.header_highlight_pre_text)
		:gsub("%%afterhighlight%%", o.header_highlight_after_text)
	else
		string = string:gsub("%%highlight%%", '')
		:gsub("%%prehighlight%%", '')
		:gsub("%%afterhighlight%%", '')
	end
	
	if sortName and sortName ~= o.header_sort_hide_text then
		string = string:gsub("%%sort%%", sortName)
		:gsub("%%presort%%", o.header_sort_pre_text)
		:gsub("%%aftersort%%", o.header_sort_after_text)
	else
		string = string:gsub("%%sort%%", '')
		:gsub("%%presort%%", '')
		:gsub("%%aftersort%%", '')
	end
	
	if search_active then
		local search_string_osd = search_string
		if search_string_osd ~= '' then
			search_string_osd = search_string:gsub('%%', '%%%%%%%%'):gsub('\\', '\\​'):gsub('{', '\\{')
		end
	
		string = string:gsub("%%search%%", osd_search_color..search_string_osd..osd_header_color)
		:gsub("%%presearch%%", o.header_search_pre_text)	
		:gsub("%%aftersearch%%", o.header_search_after_text)
	else
		string = string:gsub("%%search%%", '')
		:gsub("%%presearch%%", '')
		:gsub("%%aftersearch%%", '')
	end
	string = string:gsub("%%%%", "%%")
	return string
end

function get_list_contents(filter, sort)
	if not filter then filter = filterName end
	if not sort then sort = get_list_sort(filter) end
	
	local current_sort

	local filtered_table = {}

	local prev_list_contents
	if list_contents ~= nil and list_contents[1] then 
		prev_list_contents = list_contents
	else
		prev_list_contents = read_log_table()
	end
	
	list_contents = read_log_table()
	if not list_contents and not search_active or not list_contents[1] and not search_active then return end
	current_sort = 'added-asc'
	
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
			if list_contents[i].found_directory and not has_value(unique_values, list_contents[i].found_directory) and not starts_protocol(protocols, list_contents[i].found_path) then
				table.insert(unique_values, list_contents[i].found_directory)
				table.insert(filtered_table, list_contents[i])
			end
		end
		table.sort(filtered_table, function(a, b) return a['found_sequence'] < b['found_sequence'] end)
		
		list_contents = filtered_table
	end
	
	if filter == 'fileonly' then
		for i = 1, #list_contents do
			if tonumber(list_contents[i].found_time) == 0 then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'timeonly' then
		for i = 1, #list_contents do
			if tonumber(list_contents[i].found_time) > 0 then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'titleonly' then
		for i = 1, #list_contents do
			if list_contents[i].found_title then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'protocols' then
		for i = 1, #list_contents do
			if starts_protocol(o.logging_protocols, list_contents[i].found_path) then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'keywords' then
		for i = 1, #list_contents do
			if contain_value(o.keywords_filter_list, list_contents[i].found_line) then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		list_contents = filtered_table
	end
	
	if filter == 'playing' then
		for i = 1, #list_contents do
			if list_contents[i].found_path == filePath then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		list_contents = filtered_table
	end
	
	if search_active and search_string ~= '' then
		local filtered_table = {}
		
		local search_query = ''
		for search in search_string:gmatch("[^%s]+") do
			search_query = search_query..'.-'..esc_string(search)
		end
		
		local contents_string = ''
		for i = 1, #list_contents do
			
			if o.search_behavior == 'specific' then
				if string.lower(list_contents[i].found_path):match(string.lower(search_query)) then
					table.insert(filtered_table, list_contents[i])
				elseif list_contents[i].found_title and string.lower(list_contents[i].found_title):match(string.lower(search_query)) then
					table.insert(filtered_table, list_contents[i])
				elseif tonumber(list_contents[i].found_time) > 0 and format_time(list_contents[i].found_time, o.osd_time_format[3], o.osd_time_format[2], o.osd_time_format[1]):match(search_query) then
					table.insert(filtered_table, list_contents[i])
				elseif string.lower(list_contents[i].found_datetime):match(string.lower(search_query)) then
					table.insert(filtered_table, list_contents[i])
				end
			elseif o.search_behavior == 'any' then
				contents_string = list_contents[i].found_datetime..(list_contents[i].found_title or '')..list_contents[i].found_path
				if tonumber(list_contents[i].found_time) > 0 then 
					contents_string = contents_string..format_time(list_contents[i].found_time, o.osd_time_format[3], o.osd_time_format[2], o.osd_time_format[1])
				end
			elseif o.search_behavior == 'any-notime' then
				contents_string = list_contents[i].found_datetime..(list_contents[i].found_title or '')..list_contents[i].found_path
			end
			
			if string.lower(contents_string):match(string.lower(search_query)) then
				table.insert(filtered_table, list_contents[i])
			end
		end
		
		list_contents = filtered_table
		
	end
	
	if sort ~= current_sort then
		list_sort(list_contents, sort)
	end
	
	if not list_contents and not search_active or not list_contents[1] and not search_active then return end
end

function get_list_sort(filter)
	if not filter then filter = filterName end
	
	local sort
	for i=1, #o.list_filters_sort do
		if o.list_filters_sort[i][1] == filter then
			if has_value(available_sorts, o.list_filters_sort[i][2]) then sort = o.list_filters_sort[i][2] end
			break
		end
	end
	
	if not sort and has_value(available_sorts, o.list_default_sort) then sort = o.list_default_sort end
	
	if not sort then sort = 'added-asc' end
	
	return sort
end

function draw_list()
	local osd_msg = ''
	local osd_index = ''
	local osd_key = ''
	local osd_color = ''
	local key = 0
	local osd_text = string.format("{\\an%f{\\fscx%f}{\\fscy%f}{\\bord%f}{\\1c&H%s}", o.list_alignment, o.text_scale, o.text_scale, o.text_border, o.text_color)
	local osd_cursor = string.format("{\\an%f}{\\fscx%f}{\\fscy%f}{\\bord%f}{\\1c&H%s}", o.list_alignment, o.text_cursor_scale, o.text_cursor_scale, o.text_cursor_border, o.text_cursor_color)
	local osd_header = string.format("{\\an%f}{\\fscx%f}{\\fscy%f}{\\bord%f}{\\1c&H%s}", o.list_alignment, o.header_scale, o.header_scale, o.header_border, o.header_color)
	local osd_msg_end = "{\\1c&HFFFFFF}"
	local osd_time_type = 'found_time'
	
	if o.text_time_type == 'length' then
		osd_time_type = 'found_length'
	elseif o.text_time_type == 'remaining' then
		osd_time_type = 'found_remaining'
	end
	
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
		
		if o.quickselect_0to9_keybind and o.list_show_amount <= 10 and o.quickselect_0to9_pre_text then
			key = 1 + key
			if key == 10 then key = 0 end
			osd_key = '(' .. key .. ')  '
		end
		
		if o.show_item_number then
			osd_index = (i + 1) .. '. '
		end
		
		if i + 1 == list_cursor then
			osd_color = osd_cursor
		else
			osd_color = osd_text
		end
		
		for j = 1, #list_highlight_cursor do
			if list_highlight_cursor[j] and list_highlight_cursor[j][1] == i+1 then
				osd_msg = osd_msg..osd_color..esc_string(o.text_highlight_pre_text)
			end
		end

		-- example in the mpv source suggests this escape method for set_osd_ass:
		-- https://github.com/mpv-player/mpv/blob/94677723624fb84756e65c8f1377956667244bc9/player/lua/stats.lua#L145
		p = p:gsub('\\', '\\\239\187\191')
		   :gsub("{", "\\{")
		   :gsub("^ ", "\\h")
		osd_msg = osd_msg .. osd_color .. osd_key .. osd_index .. p
		
		if list_contents[#list_contents - i][osd_time_type] and tonumber(list_contents[#list_contents - i][osd_time_type]) > 0 then
			osd_msg = osd_msg .. o.time_seperator .. format_time(list_contents[#list_contents - i][osd_time_type], o.list_time_format[3], o.list_time_format[2], o.list_time_format[1])
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
		msg_text = filterName .. " filter in History Empty"
	else
		msg_text = "History Empty"
	end
	msg.info(msg_text)
	if o.osd_messages == true and not list_drawn then
		mp.osd_message(msg_text)
	end
end

function display_list(filter, sort, action)
	if not filter or not has_value(available_filters, filter) then filter = 'all' end
	if not sortName then sortName = get_list_sort(filter) end
	
	local prev_sort = sortName
	if not has_value(available_sorts, prev_sort) then prev_sort = get_list_sort() end

	if not sort then sort = get_list_sort(filter) end
	sortName = sort

	local prev_filter = filterName
	filterName = filter
	
	get_list_contents(filter, sort)
	
	if action ~= 'hide-osd' then
		if not list_contents or not list_contents[1] then
			list_empty_error_msg()
			filterName = prev_filter
			get_list_contents(filterName)
			return
		end
	end
	if not list_contents and not search_active or not list_contents[1] and not search_active then return end
	
	if not has_value(o.filters_and_sequence, filter) then
		table.insert(o.filters_and_sequence, filter)
	end
	
	local insert_new = false
	
	local trigger_close_list = false
	local trigger_initial_list = false
	
	
	if not list_pages or not list_pages[1] then
		table.insert(list_pages, {filter, 1, 1, {}, sort})
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
	
	if insert_new then table.insert(list_pages, {filter, 1, 1, {}, sort}) end
	
	for i = 1, #list_pages do
		if not search_active and list_pages[i][1] == prev_filter then
			list_pages[i][2] = list_cursor
			list_pages[i][4] = list_highlight_cursor
			list_pages[i][5] = prev_sort
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
		display_list(list_pages[1][1], nil, 'hide-osd')
		return
	end
	
	if trigger_close_list then
		list_close_and_trash_collection()
		return
	end
	
	if not search_active then get_page_properties(filter) else update_search_results('','') end
	draw_list()
	if utils.shared_script_property_set then
		utils.shared_script_property_set('simplehistory-menu-open', 'yes')
	end
	mp.set_property('user-data/simplehistory/menu-open', 'yes')
	if o.toggle_idlescreen then mp.commandv('script-message', 'osc-idlescreen', 'no', 'no_osd') end --1.1.6# fix osc-idlescreen (value was yes for some reason)
	list_drawn = true
	if not search_active then get_list_keybinds() end
end

--End of LogManager (Read and Format the List from Log)--

--LogManager Navigation--
function select(pos, action)
	if not search_active then
		if not list_contents or not list_contents[1] then
			list_close_and_trash_collection()
			return
		end
	end
	
	local list_cursor_temp = list_cursor + pos
	if list_cursor_temp > 0 and list_cursor_temp <= #list_contents then
		list_cursor = list_cursor_temp
		
		if action == 'highlight' then
			if not has_value(list_highlight_cursor, list_cursor, 1) then
				if pos > -1 then
					for i = pos, 1, -1 do
						if not has_value(list_highlight_cursor, list_cursor-i, 1) then
							table.insert(list_highlight_cursor, {list_cursor-i, list_contents[#list_contents+1+i - list_cursor]})
						end 
					end
				else
					for i = pos, -1, 1 do
						if not has_value(list_highlight_cursor, list_cursor-i, 1) then
							table.insert(list_highlight_cursor, {list_cursor-i, list_contents[#list_contents+1+i - list_cursor]})
						end 
					end
				end
				table.insert(list_highlight_cursor, {list_cursor, list_contents[#list_contents+1 - list_cursor]})
			else
				for i=1, #list_highlight_cursor do
					if list_highlight_cursor[i] and list_highlight_cursor[i][1] == list_cursor then
						table.remove(list_highlight_cursor, i)
					end
				end
				if pos > -1 then
					for i=1, #list_highlight_cursor do
						for j = pos, 1, -1 do
							if list_highlight_cursor[i] and list_highlight_cursor[i][1] == list_cursor-j then
								table.remove(list_highlight_cursor, i)
							end
						end
					end
				else
					for i=#list_highlight_cursor, 1, -1 do
						for j = pos, -1, 1 do
							if list_highlight_cursor[i] and list_highlight_cursor[i][1] == list_cursor-j then
								table.remove(list_highlight_cursor, i)
							end
						end
					end
				end
			end
		end
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

function list_move_up(action)
	select(-1, action)

	if search_active and o.search_not_typing_smartly then
		list_search_not_typing_mode(true)
	end
end

function list_move_down(action)
	select(1, action)

	if search_active and o.search_not_typing_smartly then
		list_search_not_typing_mode(true)
	end
end

function list_move_first(action)
	select(1 - list_cursor, action)

	if search_active and o.search_not_typing_smartly then
		list_search_not_typing_mode(true)
	end
end

function list_move_last(action)
	select(#list_contents - list_cursor, action)

	if search_active and o.search_not_typing_smartly then
		list_search_not_typing_mode(true)
	end
end

function list_page_up(action)
	select(list_start + 1 - list_cursor, action)

	if search_active and o.search_not_typing_smartly then
		list_search_not_typing_mode(true)
	end	
end

function list_page_down(action)
	if o.list_middle_loader then
		if #list_contents < o.list_show_amount then
			select(#list_contents - list_cursor, action)
		else
			select(o.list_show_amount + list_start - list_cursor, action)
		end
	else
		if o.list_show_amount > list_cursor then
			select(o.list_show_amount - list_cursor, action)
		elseif #list_contents - list_cursor >= o.list_show_amount then
			select(o.list_show_amount, action)
		else
			select(#list_contents - list_cursor, action)
		end
	end

	if search_active and o.search_not_typing_smartly then
		list_search_not_typing_mode(true)
	end	
end

function list_highlight_all()
	get_list_contents(filterName)
	if not list_contents or not list_contents[1] then return end
	
	if #list_highlight_cursor < #list_contents then
		for i=1, #list_contents do
			if not has_value(list_highlight_cursor, i, 1) then
				table.insert(list_highlight_cursor, {i, list_contents[#list_contents+1-i]})
			end 
		end
		select(0)
	else
		list_unhighlight_all()
	end
end

function list_unhighlight_all()
	if not list_highlight_cursor or not list_highlight_cursor[1] then return end
	list_highlight_cursor = {}
	select(0)
end
--End of LogManager Navigation--

--LogManager Actions--
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
				mp.osd_message('Loaded:\n' .. list_contents[#list_contents - list_cursor + 1].found_name.. o.time_seperator .. format_time(seekTime, o.osd_time_format[3], o.osd_time_format[2], o.osd_time_format[1]))
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

function list_add_playlist(action)
	if not action then
		load(list_cursor, true)
	elseif action == 'highlight' then
		if not list_highlight_cursor or not list_highlight_cursor[1] then return end
		local file_ignored_total = 0
		
		for i=1, #list_highlight_cursor do
			if file_exists(list_highlight_cursor[i][2].found_path) or starts_protocol(protocols, list_highlight_cursor[i][2].found_path) then
				mp.commandv("loadfile", list_highlight_cursor[i][2].found_path, "append-play")
			else
				msg.warn('The below file was not added into playlist as it does not seem to exist:\n' .. list_highlight_cursor[i][2].found_path)
				file_ignored_total = file_ignored_total + 1
			end
		end
		if o.osd_messages == true then
			if file_ignored_total > 0 then
				mp.osd_message('Added into Playlist '..#list_highlight_cursor - file_ignored_total..' Item/s\nIgnored '..file_ignored_total.. " Item/s That Do Not Exist")
			else
				mp.osd_message('Added into Playlist '..#list_highlight_cursor - file_ignored_total..' Item/s')
			end
		end
		if file_ignored_total > 0 then
			msg.warn('Ignored a total of '..file_ignored_total.. " Item/s that does not seem to exist")
		end
		msg.info('Added into playlist a total of '..#list_highlight_cursor - file_ignored_total..' item/s')
	end
end

function delete_log_entry_specific(target_index, target_path, target_time)
	local trigger_delete = false
	list_contents = read_log_table()
	if not list_contents or not list_contents[1] then return end
	if target_index == 'last' then target_index = #list_contents end
	if not target_index then return end
	
	if target_index and target_path and target_time then
		if list_contents[target_index].found_path == target_path and tonumber(list_contents[target_index].found_time) == target_time then
			table.remove(list_contents, target_index)
			trigger_delete = true
		end
	elseif target_index and target_path and not target_time then
		if list_contents[target_index].found_path == target_path then
			table.remove(list_contents, target_index)
			trigger_delete = true
		end
	elseif target_index and target_time and not target_path then
		if tonumber(list_contents[target_index].found_time) == target_time then
			table.remove(list_contents, target_index)
			trigger_delete = true
		end
	elseif target_index and not target_path and not target_time then
		table.remove(list_contents, target_index)
		trigger_delete = true
	end
	
	if not trigger_delete then return end
	local f = io.open(log_fullpath, "w+")
	if list_contents ~= nil and list_contents[1] then
		for i = 1, #list_contents do
			f:write(("%s\n"):format(list_contents[i].found_line))
		end
	end
	f:close()
end

function delete_log_entry(multiple, round, target_path, target_time, entry_limit)
	if not target_path then target_path = filePath end
	if not target_time then target_time = seekTime end
	list_contents = read_log_table()
	if not list_contents or not list_contents[1] then return end
	local trigger_delete = false
	
	if not multiple then
		for i = #list_contents, 1, -1 do
			if not round then
				if list_contents[i].found_path == target_path and tonumber(list_contents[i].found_time) == target_time then
					table.remove(list_contents, i)
					trigger_delete = true
					break
				end
			else
				if list_contents[i].found_path == target_path and math.floor(tonumber(list_contents[i].found_time)) == target_time then
					table.remove(list_contents, i)
					trigger_delete = true
					break
				end
			end
		end
	else
		for i = #list_contents, 1, -1 do
			if not round then
				if list_contents[i].found_path == target_path and tonumber(list_contents[i].found_time) == target_time then
					table.remove(list_contents, i)
					trigger_delete = true
				end
			else
				if list_contents[i].found_path == target_path and math.floor(tonumber(list_contents[i].found_time)) == target_time then
					table.remove(list_contents, i)
					trigger_delete = true
				end
			end
		end
	end
	
	if entry_limit and entry_limit > -1 then
		local entries_found = 0
		for i = #list_contents, 1, -1 do
			if list_contents[i].found_path == target_path and entries_found < entry_limit then
				entries_found = entries_found + 1
			elseif list_contents[i].found_path == target_path and entries_found >= entry_limit then
				table.remove(list_contents,i)
				trigger_delete = true
			end
		end
	end
	
	if not trigger_delete then return end
	local f = io.open(log_fullpath, "w+")
	if list_contents ~= nil and list_contents[1] then
		for i = 1, #list_contents do
			f:write(("%s\n"):format(list_contents[i].found_line))
		end
	end
	f:close()
end

function delete_log_entry_highlighted()
	if not list_highlight_cursor or not list_highlight_cursor[1] then return end
	list_contents = read_log_table()
	if not list_contents or not list_contents[1] then return end
	
	local list_contents_length = #list_contents
	
	for i = 1, list_contents_length do
		for j=1, #list_highlight_cursor do
			if list_contents[list_contents_length+1-i] then
				if list_contents[list_contents_length+1-i].found_sequence == list_highlight_cursor[j][2].found_sequence then
					table.remove(list_contents, list_contents_length+1-i)
				end
			end
		end
	end
	
	msg.info("Deleted "..#list_highlight_cursor.." Item/s")
	
	list_unhighlight_all()
	
	local f = io.open(log_fullpath, "w+")
	if list_contents ~= nil and list_contents[1] then
		for i = 1, #list_contents do
			f:write(("%s\n"):format(list_contents[i].found_line))
		end
	end
	f:close()
	
end

function delete_selected()
	filePath = list_contents[#list_contents - list_cursor + 1].found_path
	fileTitle = list_contents[#list_contents - list_cursor + 1].found_name
	seekTime = tonumber(list_contents[#list_contents - list_cursor + 1].found_time)
	if not filePath and not seekTime then
		msg.info("Failed to delete")
		return
	end
	delete_log_entry()
	msg.info("Deleted \"" .. filePath .. "\" | " .. format_time(seekTime))
	filePath, fileTitle, fileLength = get_file()
end

function list_delete(action)
	if not action then
		delete_selected()
	elseif action == 'highlight' then
		delete_log_entry_highlighted()
	end
	get_list_contents()
	if not list_contents or not list_contents[1] then
		list_close_and_trash_collection()
		return
	end
	if list_cursor < #list_contents + 1 then
		select(0)
	else
		list_move_last()
	end
end

function get_total_duration(action)
	if not list_contents or not list_contents[1] then return 0 end
	local list_total_duration = 0
	if action == 'found_time' or action == 'found_length' or action == 'found_remaining' then
		for i = #list_contents, 1, -1 do
			if tonumber(list_contents[i][action]) > 0 then
				list_total_duration = list_total_duration + list_contents[i][action]
			end
		end
	end
	return list_total_duration
end

function list_cycle_sort()
	local next_sort
	for i = 1, #available_sorts do
		if sortName == available_sorts[i] then
			if i == #available_sorts then
				next_sort = available_sorts[1]
				break
			else
				next_sort = available_sorts[i+1]
				break
			end
		end
	end
	if not next_sort then return end
	get_list_contents(filterName, next_sort)
	sortName = next_sort
	update_list_highlist_cursor()
	select(0)
end

function update_list_highlist_cursor()
	if not list_highlight_cursor or not list_highlight_cursor[1] then return end

	local temp_list_highlight_cursor = {}
	for i = 1, #list_contents do
		for j=1, #list_highlight_cursor do
			if list_contents[#list_contents+1-i].found_sequence == list_highlight_cursor[j][2].found_sequence then
				table.insert(temp_list_highlight_cursor, {i, list_highlight_cursor[j][2]})
			end
		end
	end

	list_highlight_cursor = temp_list_highlight_cursor
end

--End of LogManager Actions--

--LogManager Filter Functions--
function get_page_properties(filter)
	if not filter then return end
	for i=1, #list_pages do
		if list_pages[i][1] == filter then
			list_cursor = list_pages[i][2]
			list_highlight_cursor = list_pages[i][4]
			sortName = list_pages[i][5]
		end
	end
	if list_cursor > #list_contents then
		list_move_last()
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
			if o.filters_and_sequence[i + pos] then
				get_list_contents(o.filters_and_sequence[i + pos])
				if list_contents ~= nil and list_contents[1] then
					target_pos = i + pos
					break
				end
			end
		end
	elseif curr_pos and pos < 0 then
		for i = curr_pos, 0, -1 do
			if o.filters_and_sequence[i + pos] then
				get_list_contents(o.filters_and_sequence[i + pos])
				if list_contents ~= nil and list_contents[1] then
					target_pos = i + pos
					break
				end
			end
		end
	end
	
	if o.loop_through_filters then
		if not target_pos and pos > -1 or target_pos and target_pos > #o.filters_and_sequence then
			for i = 1, #o.filters_and_sequence do
				get_list_contents(o.filters_and_sequence[i])
				if list_contents ~= nil and list_contents[1] then
					target_pos = i
					break
				end
			end
		end
		if not target_pos and pos < 0 or target_pos and target_pos < 1 then
			for i = #o.filters_and_sequence, 1, -1 do
				get_list_contents(o.filters_and_sequence[i])
				if list_contents ~= nil and list_contents[1] then
					target_pos = i
					break
				end
			end
		end
	end

	if o.filters_and_sequence[target_pos] then
		display_list(o.filters_and_sequence[target_pos], nil, 'hide-osd')
	end
end

function list_filter_next()
	select_filter_sequence(1)
end
function list_filter_previous()
	select_filter_sequence(-1)
end
--End of LogManager Filter Functions--

--LogManager (List Bind and Unbind)--
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
	bind_keys(o.list_add_playlist_highlighted_keybind, 'list-add-playlist-highlight', function()list_add_playlist('highlight')end)
	bind_keys(o.list_delete_keybind, 'list-delete', list_delete)
	bind_keys(o.list_delete_highlighted_keybind, 'list-delete-highlight', function()list_delete('highlight')end)
	bind_keys(o.next_filter_sequence_keybind, 'list-filter-next', list_filter_next)
	bind_keys(o.previous_filter_sequence_keybind, 'list-filter-previous', list_filter_previous)
	bind_keys(o.list_search_activate_keybind, 'list-search-activate', list_search_activate)
	bind_keys(o.list_highlight_all_keybind, 'list-highlight-all', list_highlight_all)
	bind_keys(o.list_unhighlight_all_keybind, 'list-unhighlight-all', list_unhighlight_all)
	bind_keys(o.list_cycle_sort_keybind, 'list-cycle-sort', list_cycle_sort)

	for i = 1, #o.list_highlight_move_keybind do
		for j = 1, #o.list_move_up_keybind do
			mp.add_forced_key_binding(o.list_highlight_move_keybind[i]..'+'..o.list_move_up_keybind[j], 'highlight-move-up'..j, function()list_move_up('highlight') end, 'repeatable')
		end
		for j = 1, #o.list_move_down_keybind do
			mp.add_forced_key_binding(o.list_highlight_move_keybind[i]..'+'..o.list_move_down_keybind[j], 'highlight-move-down'..j, function()list_move_down('highlight') end, 'repeatable')
		end
		for j = 1, #o.list_move_first_keybind do
			mp.add_forced_key_binding(o.list_highlight_move_keybind[i]..'+'..o.list_move_first_keybind[j], 'highlight-move-first'..j, function()list_move_first('highlight') end, 'repeatable')
		end
		for j = 1, #o.list_move_last_keybind do
			mp.add_forced_key_binding(o.list_highlight_move_keybind[i]..'+'..o.list_move_last_keybind[j], 'highlight-move-last'..j, function()list_move_last('highlight') end, 'repeatable')
		end
		for j = 1, #o.list_page_up_keybind do
			mp.add_forced_key_binding(o.list_highlight_move_keybind[i]..'+'..o.list_page_up_keybind[j], 'highlight-page-up'..j, function()list_page_up('highlight') end, 'repeatable')
		end
		for j = 1, #o.list_page_down_keybind do
			mp.add_forced_key_binding(o.list_highlight_move_keybind[i]..'+'..o.list_page_down_keybind[j], 'highlight-page-down'..j, function()list_page_down('highlight') end, 'repeatable')
		end
	end
	
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
	unbind_keys(o.list_add_playlist_highlighted_keybind, 'list-add-playlist-highlight')
	unbind_keys(o.list_delete_keybind, 'list-delete')
	unbind_keys(o.list_delete_highlighted_keybind, 'list-delete-highlight')
	unbind_keys(o.list_close_keybind, 'list-close')
	unbind_keys(o.next_filter_sequence_keybind, 'list-filter-next')
	unbind_keys(o.previous_filter_sequence_keybind, 'list-filter-previous')
	unbind_keys(o.list_highlight_all_keybind, 'list-highlight-all')
	unbind_keys(o.list_highlight_all_keybind, 'list-unhighlight-all')
	unbind_keys(o.list_cycle_sort_keybind, 'list-cycle-sort')
	
	for i = 1, #o.list_move_up_keybind do
		mp.remove_key_binding('highlight-move-up'..i)
	end
	for i = 1, #o.list_move_down_keybind do
		mp.remove_key_binding('highlight-move-down'..i)
	end
	for i = 1, #o.list_move_first_keybind do
		mp.remove_key_binding('highlight-move-first'..i)
	end
	for i = 1, #o.list_move_last_keybind do
		mp.remove_key_binding('highlight-move-last'..i)
	end
	for i = 1, #o.list_page_up_keybind do
		mp.remove_key_binding('highlight-page-up'..i)
	end
	for i = 1, #o.list_page_down_keybind do
		mp.remove_key_binding('highlight-page-down'..i)
	end
	
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
	if utils.shared_script_property_set then
		utils.shared_script_property_set('simplehistory-menu-open', 'no')
	end
	mp.set_property('user-data/simplehistory/menu-open', 'no')
	if o.toggle_idlescreen then mp.commandv('script-message', 'osc-idlescreen', 'yes', 'no_osd') end
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
	list_highlight_cursor = {}
	sortName = nil
end
--End of LogManager (List Bind and Unbind)--

--LogManager Search Feature--
function list_search_exit()
	search_active = false
	get_list_contents(filterName)
	get_page_properties(filterName)
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
			list_pages[i][4] = list_highlight_cursor
			list_pages[i][5] = sortName
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
	local prev_contents_length = #list_contents
	get_list_contents(filterName)
	
	if prev_contents_length ~= #list_contents then
		list_highlight_cursor = {}
	end
	
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
		bind_keys(o.next_filter_sequence_keybind, 'list-filter-next', function() list_filter_next() list_search_not_typing_mode(true) end)
		bind_keys(o.previous_filter_sequence_keybind, 'list-filter-previous', function() list_filter_previous() list_search_not_typing_mode(true) end)
		bind_keys(o.list_delete_keybind, 'list-delete', function() list_delete() list_search_not_typing_mode(true) end)
		bind_keys(o.list_delete_highlighted_keybind, 'list-delete-highlight', function() list_delete('highlight') list_search_not_typing_mode(true) end)
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
--End of LogManager Search Feature--
---------End of LogManager---------

function history_blacklist_check()
	if not o.history_blacklist[1] or #o.history_blacklist == 1 and o.history_blacklist[1] == "" then return false end
	local invertable_return = {true, false}
	local blacklist_msg = 'File was not added to history because of blacklist'
	if o.invert_history_blacklist then 
		invertable_return = {false, true} 
		blacklist_msg = 'File was added to history because of whitelist'
	end
	
	if has_value(o.history_blacklist, filePath, nil) then
		msg.info(blacklist_msg)
		return invertable_return[1]
	elseif not starts_protocol(protocols, filePath) then
		if has_value(o.history_blacklist, filePath:match('^(.-)([^\\/]-)%.([^\\/%.]-)%.?$'), nil) or 
		has_value(o.history_blacklist, filePath:match('^(.-)([^\\/]-)%.([^\\/%.]-)%.?$'):gsub('\\$', ''), nil) then
			msg.info(blacklist_msg)
			return invertable_return[1]
		elseif has_value(o.history_blacklist, filePath:match('%.([^%.]+)$'), nil) or
		has_value(o.history_blacklist, "."..filePath:match('%.([^%.]+)$'), nil) then
			msg.info(blacklist_msg)
			return invertable_return[1]
		else --1.1.2# check to add any subfolder after /* to blacklist. issue #70
			for i=1, #o.history_blacklist do --1.1.2# loop through blacklisted items, if the blacklist ends with * and it is a match after subbing of the current filePath then log it. #and additionally if it is the exact same path then ignore it.
				if string.lower(filePath):match(string.lower(o.history_blacklist[i])) and o.history_blacklist[i]:sub(-1,#o.history_blacklist[i]) == '*' and string.lower(o.history_blacklist[i]:sub(1,-2)) ~= string.lower(filePath):match("(.*[\\/])") then
					msg.info(blacklist_msg)
					return invertable_return[1]
				end
			end
		end
	elseif starts_protocol(protocols, filePath) then
		if has_value(o.history_blacklist, filePath:match('(.-)(:)'), nil) or
		has_value(o.history_blacklist, filePath:match('(.-:)'), nil) or
		has_value(o.history_blacklist, filePath:match('(.-:/?/?)'), nil) then
			msg.info(blacklist_msg)
			return invertable_return[1]
		elseif filePath:find('https?://') == 1 then
			local difchk_1, difchk_2 = filePath:match("(https?://)w?w?w?%.?([%w%.%:]*)")
			local different_check_temp = difchk_1..difchk_2
			local different_checks = {different_check_temp, filePath:match("https?://w?w?w?%.?([%w%.%:]*)"), filePath:match("https?://([%w%.%:]*)"), filePath:match("(https?://[%w%.%:]*)") }
			for i = 1, #different_checks do
				if different_checks[i] and has_value(o.history_blacklist, different_checks[i], nil)
				or different_checks[i]..'/' and has_value(o.history_blacklist, different_checks[i]..'/', nil) then
					msg.info(blacklist_msg)
					return invertable_return[1]
				end
			end
		end
	end
	
	return invertable_return[2]
end

function mark_chapter()
	if not o.mark_history_as_chapter then return end
	
	local all_chapters = mp.get_property_native("chapter-list")
	local chapter_index = 0
	local chapters_time = {}
	
	get_list_contents()
	if not list_contents or not list_contents[1] then return end
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
			title = 'SimpleHistory ' .. chapter_index,
			time = chapters_time[i]
		}
	end
	
	table.sort(all_chapters, function(a, b) return a['time'] < b['time'] end)
	
	mp.set_property_native("chapter-list", all_chapters)
end

function write_log(target_time, update_seekTime, entry_limit)
	if not filePath then return end
	local prev_seekTime = seekTime
	seekTime = (mp.get_property_number('time-pos') or 0)
	if target_time then
		seekTime = target_time
	end
	if seekTime < 0 then seekTime = 0 end
	
	delete_log_entry(false, true, filePath, math.floor(seekTime), entry_limit)

	local f = io.open(log_fullpath, "a+")
	if o.file_title_logging == 'all' then
		f:write(("[%s] \"%s\" | %s | %s | %s"):format(os.date(o.date_format), fileTitle, filePath, log_length_text .. tostring(fileLength), log_time_text .. tostring(seekTime)))
	elseif o.file_title_logging == 'protocols' and (starts_protocol(o.logging_protocols, filePath)) then
		f:write(("[%s] \"%s\" | %s | %s | %s"):format(os.date(o.date_format), fileTitle, filePath, log_length_text .. tostring(fileLength), log_time_text .. tostring(seekTime)))
	elseif o.file_title_logging == 'protocols' and not (starts_protocol(o.logging_protocols, filePath)) then
		f:write(("[%s] %s | %s | %s"):format(os.date(o.date_format), filePath, log_length_text .. tostring(fileLength), log_time_text .. tostring(seekTime)))
	else
		f:write(("[%s] %s | %s | %s"):format(os.date(o.date_format), filePath, log_length_text .. tostring(fileLength), log_time_text .. tostring(seekTime)))
	end

	f:write('\n')
	f:close()
	
	if not update_seekTime then
		seekTime = prev_seekTime
	end
end

function history_incognito_mode()
	if not incognito_mode then
		incognito_mode = true
		if o.osd_messages == true then
			mp.osd_message('🕵 Incognito Mode Enabled')
		end
		msg.info('Incognito Mode Enabled')
		
		if o.delete_incognito_entry and autosaved_entry == true then
			delete_log_entry_specific('last', filePath, 0)
			autosaved_entry = 'autosaved-restore'
			if list_drawn then
				get_list_contents()
				select(0)
			end
		end
	else
		incognito_mode = false
		if o.osd_messages == true then
			mp.osd_message('Incognito Mode Disabled')
		end
		msg.info('Incognito Mode Disabled')
		
		if o.restore_incognito_entry == 'always' then
			history_fileonly_save()
			autosaved_entry = true
		elseif o.restore_incognito_entry == 'deleted-restore' and autosaved_entry == 'autosaved-restore' then
			history_fileonly_save()
			autosaved_entry = true
			if list_drawn then
				get_list_contents()
				select(0)
			end
		end
	end
end

function history_resume_option()
	if o.resume_option == 'notification' or o.resume_option == 'force' then
		local video_time = mp.get_property_number('time-pos')
		local video_path = mp.get_property('path') --1.1.4# local variable instead of filePath
		if video_time > 0 then return end
		local logged_time = 0
		local percentage = 0
		local video_duration = (mp.get_property_number('duration') or 0)
		list_contents = read_log_table()
		if not list_contents or not list_contents[1] then return end
		for i = #list_contents, 1, -1 do
			if list_contents[i].found_path == video_path and tonumber(list_contents[i].found_time) > 0 then --1.1.4# instead of filePath in case it is causing issue
				logged_time = tonumber(list_contents[i].found_time) + o.resume_offset
				break
			end
		end
		if logged_time > 0 then
			percentage = math.floor((logged_time / video_duration) * 100 + 0.5)
			if o.resume_option == 'notification' then
				if percentage > o.resume_option_threshold and percentage < (100-o.resume_option_threshold) or o.resume_option_threshold == 0 then
					mp.osd_message('⌨ [' .. string.upper(o.history_resume_keybind[1]) .. '] Resumes To' .. o.time_seperator .. format_time(logged_time, o.osd_time_format[3], o.osd_time_format[2], o.osd_time_format[1]),3)
				end
			elseif o.resume_option == 'force' then
				if percentage > o.resume_option_threshold and percentage < (100-o.resume_option_threshold) or o.resume_option_threshold == 0 then
					mp.commandv('seek', logged_time, 'absolute', 'exact')
					if (o.osd_messages == true) then
						mp.osd_message('Resumed To Last Played Position\n' .. o.time_seperator .. format_time(logged_time, o.osd_time_format[3], o.osd_time_format[2], o.osd_time_format[1]))
					end
					msg.info('Resumed to the last played position')
				end
			end
		end
	end
end

function history_save(target_time)
	if filePath ~= nil then
		if history_blacklist_check() then
			return
		end
		write_log(target_time, false, o.same_entry_limit)
		if list_drawn then
			get_list_contents()
			select(0)
		end
		msg.info('Added the below into history\n' .. fileTitle .. o.time_seperator .. format_time(seekTime))
	else
		msg.info("Failed to add into history")
	end
end

function history_fileonly_save()
	if filePath ~= nil then
		if history_blacklist_check() then
			return
		end
		write_log(0, false)
		if list_drawn then
			get_list_contents()
			select(0)
		end
		msg.info('Added the below into history\n' .. fileTitle .. o.time_seperator .. format_time(seekTime))
	else
		msg.info("Failed to add into history, no file found")
	end
end

function history_resume()
	if filePath == nil then
		list_contents = read_log_table()
		load(1)
	elseif filePath ~= nil then
		list_contents = read_log_table()
		if list_contents ~= nil and list_contents[1] then
			for i = #list_contents, 1, -1 do
				if list_contents[i].found_path == filePath and tonumber(list_contents[i].found_time) > 0 then
					seekTime = tonumber(list_contents[i].found_time) + o.resume_offset
					break
				end
			end
		end
		if seekTime > 0 then
			mp.commandv('seek', seekTime, 'absolute', 'exact')
			if (o.osd_messages == true) then
				mp.osd_message('Resumed To Last Played Position\n' .. o.time_seperator .. format_time(seekTime, o.osd_time_format[3], o.osd_time_format[2], o.osd_time_format[1]))
			end
			msg.info('Resumed to the last played position')
		else
			if (o.osd_messages == true) then
				mp.osd_message('No Resume Position Found For This Video')
			end
			msg.info('No resume position found for this video')
		end
	end
end

function history_load_last()
	if filePath == nil then
		list_contents = read_log_table()
		load(1, false, 0)
	elseif filePath ~= nil then
		list_contents = read_log_table()
		load(2, true)
	end
end

mp.register_event('file-loaded', function()
	list_close_and_trash_collection()
	filePath, fileTitle, fileLength = get_file()
	loadTriggered = true --1.1.5# for resume and resume-notime startup behavior (so that it only triggers if started as idle and only once)
	if (o.resume_option ~= 'none' and resume_selected == true and seekTime > 0) then
		mp.commandv('seek', seekTime, 'absolute', 'exact')
		resume_selected = false
	end
	history_resume_option() --1.1.4# remove timeout, cant remember why I put it in first place
	mark_chapter()
	if not incognito_mode then
		history_fileonly_save()
		autosaved_entry = true
	end
end)

mp.add_hook('on_unload', 9, function()--1.1.3# get the LogTime only when using on_unload because big functions do not run fully in here
	logTime = (mp.get_property_number('time-pos') or 0)
end)
mp.register_event('end-file', function()--1.1.3# use end-file instead so that it doesn't cause crash while seeking ( i am able to run big functions here)
	if not incognito_mode then
		if autosaved_entry == true then delete_log_entry_specific('last', filePath, 0) end
		history_save(logTime) --1.1.3# get the updated time from on_unload since it will still be preserved
	end
	autosaved_entry = false
	logTime = 0 --1.1.3# reset logTime to 0
end)

mp.observe_property("idle-active", "bool", function(_, v)
	if v then --1.1.2# if idle is triggered
		filePath, fileTitle, fileLength = nil --1.1.2# set it back to nil if idle is triggered for better trash collection. issue #69
	end
	
	if v and o.startup_idle_behavior == 'resume' and not loadTriggered then --1.1.5# option to resume on startup
		history_resume()
	elseif v and o.startup_idle_behavior == 'resume-notime' and not loadTriggered then --1.1.5# option to load last item on startup
		history_load_last()
	elseif v and has_value(available_filters, o.auto_run_list_idle) then
		display_list(o.auto_run_list_idle, nil, 'hide-osd')
	end
	
	if v and o.auto_run_incognito_mode and not incognito_auto_run_triggered or
	not v and o.auto_run_incognito_mode and not incognito_auto_run_triggered then
		history_incognito_mode()
		incognito_auto_run_triggered = true
	end
end)

bind_keys(o.history_resume_keybind, 'history-resume', history_resume)
bind_keys(o.history_load_last_keybind, 'history-load-last', history_load_last)
bind_keys(o.history_incognito_mode_keybind, 'history-incognito-mode', history_incognito_mode)

for i = 1, #o.open_list_keybind do
	if i == 1 then
		mp.add_forced_key_binding(o.open_list_keybind[i][1], 'open-list', function()display_list(o.open_list_keybind[i][2]) end)
	else
		mp.add_forced_key_binding(o.open_list_keybind[i][1], 'open-list'..i, function()display_list(o.open_list_keybind[i][2]) end)
	end
end
