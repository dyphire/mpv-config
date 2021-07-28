-- deus0ww - 2021-05-07

local ipairs,loadfile,pairs,pcall,tonumber,tostring = ipairs,loadfile,pairs,pcall,tonumber,tostring
local debug,io,math,os,string,table,utf8 = debug,io,math,os,string,table,utf8
local min,max,floor,ceil,huge,sqrt = math.min,math.max,math.floor,math.ceil,math.huge,math.sqrt
local mp      = require 'mp'
local msg     = require 'mp.msg'
local opt     = require 'mp.options'
local utils   = require 'mp.utils'

local script_name = mp.get_script_name()

local message = {
	worker = {
		registration  = 'tn_worker_registration',
		reset         = 'tn_worker_reset',
		queue         = 'tn_worker_queue',
		start         = 'tn_worker_start',
		progress      = 'tn_worker_progress',
		finish        = 'tn_worker_finish',
	},
	debug = 'Thumbnailer-debug',

	queued     = 1,
	processing = 2,
	ready      = 3,
	failed     = 4,
}

--------------------
-- Data Structure --
--------------------
local state

local worker_data

local worker_options

local worker_extra

local worker_stats

local work_queue

local thumbnail_map_buffer = {}
local thumbnail_map_buffer_size = 0

local function reset_all()
	state                     = nil
	worker_data               = {}
	worker_options            = {}
	worker_extra              = {}
	worker_stats              = {}
	worker_stats.name         = script_name
	worker_stats.queued       = 0
	worker_stats.existing     = 0
	worker_stats.failed       = 0
	worker_stats.success      = 0
	work_queue                = {}
	thumbnail_map_buffer      = {}
	thumbnail_map_buffer_size = 0
end
reset_all()

-----------
-- Utils --
-----------
local OS_MAC, OS_WIN, OS_NIX = 'MAC', 'WIN', 'NIX'
local function get_os()
	if jit and jit.os then
		if jit.os == 'Windows' then return OS_WIN
		elseif jit.os == 'OSX' then return OS_MAC
		else return OS_NIX end
	end
	if (package.config:sub(1,1) ~= '/') then return OS_WIN end
	local res = mp.command_native({ name = 'subprocess', args = {'uname', '-s'}, playback_only = false, capture_stdout = true, capture_stderr = true, })
	return (res and res.stdout and res.stdout:lower():find('darwin') ~= nil) and OS_MAC or OS_NIX
end
local OPERATING_SYSTEM = get_os()

local function format_json(tab)
	local json, err = utils.format_json(tab)
	if err then msg.error('Formatting JSON failed:', err) end
	if json then return json else return '' end
end

local function parse_json(json)
	local tab, err = utils.parse_json(json, true)
	if err then msg.error('Parsing JSON failed:', err) end
	if tab then return tab else return {} end
end

local function is_empty(...) -- Not for tables
	if ... == nil then return true end
	for _, v in ipairs({...}) do
		if (v == nil) or (v == '') or (v == 0) then return true end
	end
	return false
end


-------------------------------------
-- External Process and Filesystem --
-------------------------------------
local function subprocess_result(sub_success, result, mpv_error, subprocess_name, start_time)
	local cmd_status, cmd_stdout, cmd_stderr, cmd_error, cmd_killed
	if result then cmd_status, cmd_stdout, cmd_stderr, cmd_error, cmd_killed = result.status, result.stdout, result.stderr, result.error_string, result.killed_by_us end
	local cmd_status_success, cmd_status_string, cmd_err_success, cmd_err_string, success
	
	if     cmd_status == 0      then cmd_status_success, cmd_status_string = true,  'ok'
	elseif is_empty(cmd_status) then cmd_status_success, cmd_status_string = true,  '_'
	elseif cmd_status == 124 or cmd_status == 137 or cmd_status == 143 then -- timer: timed-out(124), killed(128+9), or terminated(128+15)
	                                 cmd_status_success, cmd_status_string = false, 'timed out'
	else                             cmd_status_success, cmd_status_string = false, ('%d'):format(cmd_status) end
	
	if     is_empty(cmd_error)   then cmd_err_success, cmd_err_string = true,  '_'
	elseif cmd_error == 'init'   then cmd_err_success, cmd_err_string = false, 'failed to initialize'
	elseif cmd_error == 'killed' then cmd_err_success, cmd_err_string = false, cmd_killed and 'killed by us' or 'killed, but not by us'
	else                              cmd_err_success, cmd_err_string = false, cmd_error end
	
	if is_empty(cmd_stdout) then cmd_stdout = '_' end
	if is_empty(cmd_stderr) then cmd_stderr = '_' end
	subprocess_name = subprocess_name or '_'
	start_time = start_time or os.time()
	success = (sub_success == nil or sub_success) and is_empty(mpv_error) and cmd_status_success and cmd_err_success

	if success then msg.debug('Subprocess', subprocess_name, 'succeeded. | Status:', cmd_status_string, '| Time:', ('%ds'):format(os.difftime(os.time(), start_time)))
	else            msg.error('Subprocess', subprocess_name, 'failed. | Status:', cmd_status_string, '| MPV Error:', mpv_error or 'n/a', 
	                          '| Subprocess Error:', cmd_err_string, '| Stdout:', cmd_stdout, '| Stderr:', cmd_stderr, '| Time:', ('%ds'):format(os.difftime(os.time(), start_time))) end
	return success, cmd_status_string, cmd_err_string, cmd_stdout, cmd_stderr
end

local function run_subprocess(command, name)
	if not command then return false end
	local subprocess_name, start_time = name or command[1], os.time()
	msg.debug('Subprocess', subprocess_name, 'Starting...', utils.to_string(command))
	local result, mpv_error = mp.command_native( {name='subprocess', args=command, playback_only=false} )
	local success, _, _, _ = subprocess_result(nil, result, mpv_error, subprocess_name, start_time)
	return success
end

local function run_subprocess_async(command, name)
	if not command then return false end
	local subprocess_name, start_time = name or command[1], os.time()
	msg.debug('Subprocess', subprocess_name, 'Starting (async)...')
	mp.command_native_async( {name='subprocess', args=command, playback_only=false}, function(s, r, e) subprocess_result(s, r, e, subprocess_name, start_time) end )
	return nil
end

local function join_paths(...)
	local sep = OPERATING_SYSTEM == OS_WIN and '\\' or '/'
	local result = ''
	for _, p in ipairs({...}) do
		result = (result == '') and p or result .. sep .. p
	end
	return result
end

local function clean_path(path)
	if OPERATING_SYSTEM == OS_WIN and utf8 ~= nil then
		for uchar in string.gmatch(path, '\\u([0-9a-f][0-9a-f][0-9a-f][0-9a-f])') do
			path = path:gsub('\\u' .. uchar, utf8.char('0x' .. uchar))
		end
		path =  path:gsub('[\\/]', '\\\\')
	end
	return path
end


------------
-- Worker --
------------
mp.command_native({'script-message', message.worker.registration, format_json({name = script_name, script_path = debug.getinfo(1).source})})

local function stop_file_exist()
	local file = io.open(join_paths(state.cache_dir, 'stop'), 'r')
	if not file then return false end
	file:close()
	return true
end

local function check_existing(thumbnail_path)
	local thumbnail_file = io.open(thumbnail_path, 'rb')
	if thumbnail_file and thumbnail_file:seek('end') >= worker_extra.filesize then
		thumbnail_file:close()
		return true
	end
	return false
end

local function pad_file(thumbnail_path)
	local thumbnail_file = io.open(thumbnail_path, 'rb')
	if thumbnail_file then
		-- Check the size of the generated file
		local thumbnail_file_size = thumbnail_file:seek('end')
		thumbnail_file:close()

		-- Check if the file is big enough
		local missing_bytes = max(0, worker_extra.filesize - thumbnail_file_size)
		if thumbnail_file_size ~= 0 and missing_bytes > 0 then
			msg.warn(('Thumbnail missing %d bytes (expected %d, had %d), padding %s'):format(missing_bytes, worker_extra.filesize, thumbnail_file_size, thumbnail_path))
			thumbnail_file = io.open(thumbnail_path, 'ab')
			thumbnail_file:write(string.rep(string.char(0), missing_bytes))
			thumbnail_file:close()
		end
	end
end

local function concat_args(args, ...)
	local arg = ''
	for _, option in ipairs({...}) do
		if is_empty(option) then return #args end
		arg = arg .. tostring(option)
	end
	if arg ~= '' then args[#args+1] = arg end
	return #args
end

local function add_args(args, ...)
	for _, option in ipairs({...}) do
		if is_empty(option) then return #args end
	end
	for _, option in ipairs({...}) do
		args[#args+1] = tostring(option)
	end
	return #args
end

local function add_timeout(args)
	local timeout = worker_options.worker_timeout and worker_options.worker_timeout or 0
	if timeout == 0 then return #args end
	if OPERATING_SYSTEM == OS_MAC then
		add_args(args, worker_options.exec_path .. 'gtimeout', ('--kill-after=%d'):format(timeout + 1), ('%d'):format(timeout + 3))
	elseif OPERATING_SYSTEM == OS_NIX then
		add_args(args, worker_options.exec_path .. 'timeout',  ('--kill-after=%d'):format(timeout + 1), ('%d'):format(timeout + 3))
	elseif OPERATING_SYSTEM == OS_WIN then
		-- unimplemented
	end
	return #args
end

local function add_nice(args)
	if OPERATING_SYSTEM == OS_MAC then
		add_args(args, worker_options.exec_path .. 'gnice', '-19')
	elseif OPERATING_SYSTEM == OS_NIX then
		add_args(args, worker_options.exec_path .. 'nice', '-n', '19')
	elseif OPERATING_SYSTEM == OS_WIN then
		-- unimplemented
	end
end

local pix_fmt   = 'bgra'
local scale_ff  = 'scale=w=%d:h=%d:sws_flags=%s:dst_format=' .. pix_fmt
local scale_mpv = 'scale=w=%d:h=%d:flags=%s'
local vf_format = ',format=fmt=' .. pix_fmt
local transpose = {	[-360] = '',
					[-270] = ',transpose=1',
					[-180] = ',transpose=2,transpose=2',
					[ -90] = ',transpose=2',
					[   0] = '',
					[  90] = ',transpose=1',
					[ 180] = ',transpose=1,transpose=1',
					[ 270] = ',transpose=2',
					[ 360] = '',
				  }

local function create_mpv_command(time, output, force_accurate_seek)
	local state, worker_extra, args = state, worker_extra, worker_extra.args
	local is_last_thumbnail = (state.duration - time) < state.delta
	local accurate_seek = force_accurate_seek or worker_options.accurate_seek or is_last_thumbnail or state.delta < 3
	if args then
		args[worker_extra.index_log]        = '--log-file=' .. output .. '.log'
		args[worker_extra.index_fastseek]   = '--demuxer-lavf-o-set=fflags=' .. (accurate_seek and '+discardcorrupt+nobuffer' or '+fastseek+discardcorrupt+nobuffer')
		args[worker_extra.index_accurate]   = '--hr-seek='                   .. (accurate_seek and 'yes' or 'no')
		args[worker_extra.index_skip_loop]  = '--vd-lavc-skiploopfilter='    .. (accurate_seek and 'nonref' or 'nonkey')
		args[worker_extra.index_skip_idct]  = '--vd-lavc-skipidct='          .. (accurate_seek and 'nonref' or 'nonkey')
		args[worker_extra.index_skip_frame] = '--vd-lavc-skipframe='         .. (accurate_seek and 'nonref' or 'nonkey')
		args[worker_extra.index_time]       = '--start=' .. tostring(is_last_thumbnail and floor(time) or time)
		args[worker_extra.index_output]     = '--o=' .. output
	else
		local width, height = state.width, state.height
		local vf_scale = (scale_mpv):format(width, height, worker_options.ffmpeg_scaler)
		local vf_transpose = state.rotate and transpose[tonumber(state.rotate % 360)] or ''
		local filter_threads = (':o="threads=%d"'):format(worker_options.ffmpeg_threads)
		local video_filters = '--vf=lavfi="' .. vf_scale .. vf_transpose .. '"' .. filter_threads .. vf_format
	
		local worker_options = worker_options
		local header_fields_arg = nil
		local header_fields = mp.get_property_native('http-header-fields', {})
		if #header_fields > 0 then
			header_fields_arg = '--http-header-fields=' .. table.concat(header_fields, ',')
		end
		worker_extra.args = {}
		args = worker_extra.args -- https://mpv.io/manual/master/
		add_timeout(args)
		add_nice(args)
		
		worker_extra.index_name = concat_args(args, worker_options.exec_path .. 'mpv')
		-- General
		concat_args(args, '--no-config')
		concat_args(args, '--msg-level=all=no')
		worker_extra.index_log = concat_args(args, '--log-file=', output .. '.log')
		concat_args(args, '--osc=no')
		concat_args(args, '--load-stats-overlay=no')
		-- Remote
		concat_args(args, (worker_extra.ytdl and '--ytdl' or '--no-ytdl'))
		concat_args(args, header_fields_arg)
		concat_args(args, '--user-agent=', mp.get_property_native('user-agent'))
		concat_args(args, '--referrer=', mp.get_property_native('referrer'))
		-- Input
		concat_args(args, '--vd-lavc-fast')
		concat_args(args, '--vd-lavc-threads=', worker_options.ffmpeg_threads)
		concat_args(args, '--demuxer-lavf-analyzeduration=0.1')
		concat_args(args, '--demuxer-lavf-probesize=500000')
		concat_args(args, '--demuxer-lavf-probe-info=nostreams')
		worker_extra.index_fastseek   = concat_args(args, '--demuxer-lavf-o-set=fflags=', accurate_seek and '+discardcorrupt+nobuffer' or '+fastseek+discardcorrupt+nobuffer')
		worker_extra.index_accurate   = concat_args(args, '--hr-seek=',                   accurate_seek and 'yes' or 'no')
		worker_extra.index_skip_loop  = concat_args(args, '--vd-lavc-skiploopfilter=',    accurate_seek and 'nonref' or 'nonkey')
		worker_extra.index_skip_idct  = concat_args(args, '--vd-lavc-skipidct=',          accurate_seek and 'nonref' or 'nonkey')
		worker_extra.index_skip_frame = concat_args(args, '--vd-lavc-skipframe=',         accurate_seek and 'nonref' or 'nonkey')
		concat_args(args, '--hwdec=no')
		concat_args(args, '--hdr-compute-peak=no')
		concat_args(args, '--vd-lavc-dr=no')
		concat_args(args, '--aid=no')
		concat_args(args, '--sid=no')
		concat_args(args, '--sub-auto=no')
		worker_extra.index_time = concat_args(args, '--start=', tostring(is_last_thumbnail and floor(time) or time))
		concat_args(args, '--frames=1')
		concat_args(args, state.input_fullpath)
		-- Filters
		concat_args(args, '--sws-scaler=', worker_options.ffmpeg_scaler)
		concat_args(args, video_filters)
		-- Output
		concat_args(args, '--of=rawvideo')
		concat_args(args, '--ovcopts=pixel_format=', pix_fmt)
		concat_args(args, '--ocopy-metadata=no')
		worker_extra.index_output = concat_args(args, '--o=' .. output)
	end
	return args, args[worker_extra.index_name]
end

local function create_ffmpeg_command(time, output, force_accurate_seek)
	local state, worker_extra, args = state, worker_extra, worker_extra.args
	local is_last_thumbnail = (state.duration - time) < state.delta
	local accurate_seek = force_accurate_seek or worker_options.accurate_seek or is_last_thumbnail or state.delta < 3
	if args then
		args[worker_extra.index_fastseek]   = accurate_seek and '+discardcorrupt+nobuffer' or '+fastseek+discardcorrupt+nobuffer'
		args[worker_extra.index_accurate]   = accurate_seek and '-accurate_seek' or '-noaccurate_seek'
		args[worker_extra.index_skip_loop]  = accurate_seek and 'noref' or 'nokey'
		args[worker_extra.index_skip_idct]  = accurate_seek and 'noref' or 'nokey'
		args[worker_extra.index_skip_frame] = accurate_seek and 'noref' or 'nokey'
		args[worker_extra.index_time]       = tostring(is_last_thumbnail and floor(time) or time)
		args[worker_extra.index_output]     = output
	else
		local width, height = state.width, state.height
		if state.meta_rotated then width, height = height, width end
		local vf_scale = (scale_ff):format(width, height, worker_options.ffmpeg_scaler)
		local vf_transpose = state.rotate and transpose[tonumber(state.rotate % 360)] or ''
		local video_filters = vf_scale .. vf_transpose
		
		local worker_options = worker_options
		worker_extra.args = {}
		args = worker_extra.args -- https://ffmpeg.org/ffmpeg.html#Main-options
		-- General
		add_timeout(args)
		add_nice(args)
		worker_extra.index_name = add_args(args, worker_options.exec_path .. 'ffmpeg')
		add_args(args, '-hide_banner')
		add_args(args, '-nostats')
		add_args(args, '-loglevel', 'warning')
		-- Input
		add_args(args, '-threads', worker_options.ffmpeg_threads)
		add_args(args, '-fflags', 'fastseek')
		add_args(args, '-flags2', 'fast')
		if OPERATING_SYSTEM ~= OS_WIN and worker_options.worker_timeout > 0 then add_args(args, '-timelimit', ceil(worker_options.worker_timeout)) end
		add_args(args, '-analyzeduration', '500000')  -- Default: 5000000
		add_args(args, '-probesize', '500000')        -- Default: 5000000
		worker_extra.index_fastseek   = add_args(args, '-fflags',           accurate_seek and '+discardcorrupt+nobuffer' or '+fastseek+discardcorrupt+nobuffer')
		worker_extra.index_accurate   = add_args(args,                      accurate_seek and '-accurate_seek' or '-noaccurate_seek')
		worker_extra.index_skip_loop  = add_args(args, '-skip_loop_filter', accurate_seek and 'noref' or 'nokey')
		worker_extra.index_skip_idct  = add_args(args, '-skip_idct',        accurate_seek and 'noref' or 'nokey')
		worker_extra.index_skip_frame = add_args(args, '-skip_frame',       accurate_seek and 'noref' or 'nokey')
		worker_extra.index_time       = add_args(args, '-ss', tostring(is_last_thumbnail and floor(time) or time))
		add_args(args, '-guess_layout_max', '0')
		add_args(args, '-an', '-sn')
		add_args(args, '-i', state.input_fullpath)
		add_args(args, '-map_metadata', '-1')
		add_args(args, '-map_chapters', '-1')
		add_args(args, '-frames:v', '1')
		-- Filters
		add_args(args, '-filter_threads', worker_options.ffmpeg_threads)
		add_args(args, '-vf', video_filters)
		add_args(args, '-sws_flags', worker_options.ffmpeg_scaler)
		add_args(args, '-pix_fmt', pix_fmt)
		-- Output
		add_args(args, '-f', 'rawvideo')
		add_args(args, '-threads', worker_options.ffmpeg_threads)
		add_args(args, '-y')
		worker_extra.index_output = add_args(args, output)
	end
	return args, args[worker_extra.index_name]
end

-- From https://github.com/TheAMM/mpv_thumbnail_script
local function hack_input()
	msg.debug('Hacking Input...')
	local file_path = mp.get_property_native('stream-path')
	local playlist_filename = join_paths(state.cache_dir, 'playlist.txt')
	worker_extra.ytdl = false
	if #file_path > 8000 then -- Path is too long for a playlist - just pass the original URL to workers and allow ytdl
		worker_extra.ytdl = true
		file_path = state.input_fullpath
		msg.warn('Falling back to original URL and ytdl due to LONG source path. This will be slow.')
	elseif #file_path > 1024 then
		local playlist_file = io.open(playlist_filename, 'wb')
		if not playlist_file then
			msg.error(('Tried to write a playlist to %s but could not!'):format(playlist_file))
			return false
		end
		playlist_file:write(file_path .. '\n')
		playlist_file:close()
		file_path = '--playlist=' .. playlist_filename
		msg.warn('Using playlist workaround due to long source path')
	end
	state.input_fullpath = file_path
end

local function report_progress_table(thumbnail_map)
	local progress_report = { name = script_name, input_filename = state.input_filename, thumbnail_map = thumbnail_map }
	mp.command_native_async({'script-message', message.worker.progress, format_json(progress_report)}, function() end)
end

local function report_progress(index, new_status)
	local index_string = index and (state.cache_format):format(index) or ''
	if index ~= nil and thumbnail_map_buffer[index_string] == nil then thumbnail_map_buffer_size = thumbnail_map_buffer_size + 1 end
	thumbnail_map_buffer[index_string] = new_status
	if index == nil or thumbnail_map_buffer_size >= state.worker_buffer then
		report_progress_table(thumbnail_map_buffer)
		thumbnail_map_buffer = {}
		thumbnail_map_buffer_size = 0
	end
end

local function set_encoder(encoder)
	if encoder == 'ffmpeg' then
		worker_extra.create_command = create_ffmpeg_command
	else
		worker_extra.create_command = create_mpv_command
		if state.is_remote then hack_input() end
	end
	worker_extra.args = nil
end


local function create_thumbnail(time, fullpath)
	return (run_subprocess(worker_extra.create_command(time, fullpath, false)) and check_existing(fullpath)) or
	       (run_subprocess(worker_extra.create_command(time, fullpath, true))  and check_existing(fullpath))
end

local function process_thumbnail()
	if #work_queue == 0 then return end
	local worker_stats = worker_stats
	local status       = message.processing
	local time         = table.remove(work_queue, 1)
	local output       = (state.cache_format):format(time)
	local fullpath     = join_paths(state.cache_dir, output) .. state.cache_extension
	report_progress (time, status)

	-- Check for existing thumbnail to avoid generation
	if check_existing(fullpath) then
		worker_stats.existing = worker_stats.existing + 1
		worker_stats.queued = worker_stats.queued - 1
		report_progress (time, message.ready)
		return
	end
	-- Generate the thumbnail
	if create_thumbnail(time, fullpath) then
		worker_stats.success = worker_stats.success + 1
		worker_stats.queued = worker_stats.queued - 1
		report_progress (time, message.ready)
		return
	end
	-- Switch to MPV when FFMPEG fails
--	if worker_options.encoder == 'ffmpeg' then
--		set_encoder('mpv')
--		if create_thumbnail(time, fullpath) then
--			worker_stats.success = worker_stats.success + 1
--			worker_stats.queued = worker_stats.queued - 1
--			report_progress (time, message.ready)
--			return
--		end
--	end
	-- If the thumbnail is incomplete, pad it
	if not check_existing(fullpath) then pad_file(fullpath) end
	-- Final check
	if check_existing(fullpath) then
		worker_stats.success = worker_stats.success + 1
		worker_stats.queued = worker_stats.queued - 1
		report_progress (time, message.ready)
	else
		worker_stats.failed = worker_stats.failed + 1
		worker_stats.queued = worker_stats.queued - 1
		report_progress (time, message.failed)
	end
end

local function process_queue()
	if not work_queue then return end
	for _ = 1, #work_queue do
		if stop_file_exist() then report_progress() break end
		process_thumbnail()
	end
	report_progress()
	if #work_queue == 0 then mp.command_native({'script-message', message.worker.finish, format_json(worker_stats)}) end
end

local function create_queue()
	set_encoder(worker_options.encoder)
	work_queue = {}
	local worker_data, work_queue, worker_stats = worker_data, work_queue, worker_stats
	local time, output, report_queue, used_frames = 0, '', {}, {}
	for x = 8, 0, -1 do
		local nth = (2^x)
		for y = 0, (ceil(state.tn_per_worker) - 1), nth do
			if not used_frames[y + 1] then
				time = (worker_data.start_time_index + y) * state.delta
				output = (state.cache_format):format(time)
				if check_existing(join_paths(state.cache_dir, output)) then
					worker_stats.existing = worker_stats.existing + 1
					report_queue[(state.cache_format):format(time)] = message.ready
				elseif time <= state.duration then
					work_queue[#work_queue + 1] = time
					worker_stats.queued = worker_stats.queued + 1
					report_queue[(state.cache_format):format(time)] = message.queued
				end
				used_frames[y + 1] = true
			end
		end
	end
	report_progress_table(report_queue)
end


---------------
-- Listeners --
---------------
mp.register_script_message(message.worker.reset, reset_all)

mp.register_script_message(message.worker.queue, function(json)
	local new_data = parse_json(json)
	if new_data.state then state = new_data.state end
	if new_data.worker_options then worker_options = new_data.worker_options end
	if new_data.start_time_index then worker_data.start_time_index = new_data.start_time_index end
	if not worker_extra.filesize then worker_extra.filesize = (state.width * state.height * 4) end
	create_queue()
end)

mp.register_script_message(message.worker.start, process_queue)

mp.register_script_message(message.debug, function()
	msg.info('Thumbnailer Worker Internal States:')
	msg.info('state:', state and utils.to_string(state) or 'nil')
	msg.info('worker_data:', worker_data and utils.to_string(worker_data) or 'nil')
	msg.info('worker_options:', worker_options and utils.to_string(worker_options) or 'nil')
	msg.info('worker_extra:', worker_extra and utils.to_string(worker_extra) or 'nil')
	msg.info('worker_stats:', worker_stats and utils.to_string(worker_stats) or 'nil')
end)
