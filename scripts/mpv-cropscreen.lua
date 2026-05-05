--[[
	SOURCE_: https://github.com/WatanabeChika/mpv-lines-meme-generator
	Modify_: https://github.com/dyphire/mpv-scripts
	
	create long graph of lines with mpv
	requires ffmpeg.

	Usage: add bindings to input.conf
	-- key script-message crop-screenshot
	-- key script-message take-screenshot
	-- key script-message stitch-images
]]

require("mp.options")
local utils = require("mp.utils")
local assdraw = require 'mp.assdraw'
local msg = require 'mp.msg'

local options = {
	ffmpeg_path = "ffmpeg",
	screenshot_dir = "~~/screenshots",   -- your path to save screenshots
	lossless = false,               -- use lossless screenshots
	ffmpeg_loglevel = "error",      -- ffmpeg log level
}

read_options(options, _, function() end)

local screenshot_dir = mp.command_native({ "expand-path", options.screenshot_dir })
local screenshot_format = options.lossless and ".png" or ".jpg"
local screenshot_count = 0
local subtitle_top, subtitle_bottom = 0, 0
local screenshots = {}

-- detect path separator, detect path separator, windows uses backslashes
local is_windows = package.config:sub(1, 1) == "\\"
--create screenshot_dir if it doesn't exist
if screenshot_dir ~= '' then
	local meta = utils.file_info(screenshot_dir)
	if not meta or not meta.is_dir then
		local windows_args = { 'powershell', '-NoProfile', '-Command', 'mkdir',
			string.format("\"%s\"", screenshot_dir) }
		local unix_args = { 'mkdir', '-p', screenshot_dir }
		local args = is_windows and windows_args or unix_args
		local res = mp.command_native({
			name = "subprocess",
			capture_stdout = true,
			playback_only = false,
			args = args
		})
		if res.status ~= 0 then
			msg.error("Failed to create screenshot_dir save directory " .. screenshot_dir ..
			". Error: " .. (res.error or "unknown"))
			return
		end
	end
end

local function file_exist(path)
	local meta = utils.file_info(path)
	if not meta or not meta.is_file then
		return false
	end
	return true
end

-- helper: crop an input image file into output using mpv
local function mpv_crop_file(input_path, out_path, crop_arg)
	local ENCODER_MAP = {
		[".png"] = "png",
		[".jpg"] = "mjpeg",
	}
	local ovc = ENCODER_MAP[screenshot_format] or "png"

	local cmd = { "mpv", input_path, "--no-config" }
	if crop_arg and crop_arg ~= "" then
		table.insert(cmd, "--vf=" .. crop_arg)
	end
	table.insert(cmd, "--frames=1")
	table.insert(cmd, "--ovc=" .. ovc)
	table.insert(cmd, "-o")
	table.insert(cmd, out_path)

	local res = utils.subprocess({ args = cmd, capture_stdout = true, capture_stderr = true })
	if res and res.status ~= 0 then
		msg.error("mpv crop failed: status=" .. tostring(res.status) .. " error=" .. tostring(res.error))
		if res.stdout then msg.error("mpv stdout: " .. tostring(res.stdout)) end
		if res.stderr then msg.error("mpv stderr: " .. tostring(res.stderr)) end
	end
	return res
end

-- take and crop screenshots
local function perform_capture(idx, crop_arg_local, line)
	-- take original shots
	local screenshot_file = utils.join_path(screenshot_dir, "temp_screenshot_" .. idx .. screenshot_format)
	mp.commandv("screenshot-to-file", screenshot_file, "subtitles")

	-- crop the shots
	local processed_file = line and
		utils.join_path(screenshot_dir, string.format("line_shot_%03d" .. screenshot_format, idx)) or
		utils.join_path(screenshot_dir, string.format("crop_shot_%s%s", os.date("%Y%m%d_%H%M%S"), screenshot_format))

	-- use helper to crop/export the temporary screenshot into final output
	local result = mpv_crop_file(screenshot_file, processed_file, crop_arg_local)
	if result and result.status == 0 then
		mp.osd_message("Shot saved: " .. processed_file)
		msg.verbose("Shot saved: " .. processed_file)
		if line then
			table.insert(screenshots, processed_file)
		end
	else
		mp.osd_message("Cropping failed")
		msg.verbose("Cropping failed: " .. (result and result.error or "unknown"))
	end

	-- delete the original shots
	os.remove(screenshot_file)
end

-- Minimal DisplayState derived from mpv_crop_script's implementation
local DisplayState = {}
DisplayState.__index = DisplayState

function DisplayState.new()
	local self = setmetatable({}, DisplayState)
	self.screen = { width = 0, height = 0 }
	self.video = { width = 0, height = 0 }
	self.bounds = { left = 0, top = 0, right = 0, bottom = 0, width = 0, height = 0 }
	self.scale = { x = 1, y = 1 }
	self.current_state = nil
	self.screen_ready = false
	self.video_ready = false
	return self
end

function DisplayState:_collect_display_state()
	local screen_w, screen_h = mp.get_osd_size()
	local state = {
		screen_w = screen_w,
		screen_h = screen_h,
		video_w = mp.get_property_number("dwidth"),
		video_h = mp.get_property_number("dheight"),
		video_w_raw = mp.get_property_number("video-out-params/w"),
		video_h_raw = mp.get_property_number("video-out-params/h"),
		video_aspect_override = mp.get_property_native("video-aspect-override"),
		panscan = mp.get_property_native("panscan"),
		video_zoom = mp.get_property_native("video-zoom"),
		video_unscaled = mp.get_property_native("video-unscaled"),
		video_align_x = mp.get_property_native("video-align-x"),
		video_align_y = mp.get_property_native("video-align-y"),
		video_pan_x = mp.get_property_native("video-pan-x"),
		video_pan_y = mp.get_property_native("video-pan-y"),
		fullscreen = mp.get_property_native("fullscreen"),
		keepaspect = mp.get_property_native("keepaspect"),
		keepaspect_window = mp.get_property_native("keepaspect-window"),
		window_maximized = mp.get_property_native("window-maximized")
	}
	return state
end

function DisplayState:_aspect_calc_panscan(state)
	local f_width = state.screen_w
	local f_height = (state.screen_w / state.video_w) * state.video_h
	if f_height > state.screen_h or f_height < state.video_h_raw then
		local tmp_w = (state.screen_h / state.video_h) * state.video_w
		if tmp_w <= state.screen_w then
			f_height = state.screen_h
			f_width = tmp_w
		end
	end
	local vo_panscan_area = state.screen_h - f_height
	local f_w = f_width / f_height
	local f_h = 1
	if (vo_panscan_area == 0) then
		vo_panscan_area = state.screen_w - f_width
		f_w = 1
		f_h = f_height / f_width
	end
	if state.video_unscaled then
		vo_panscan_area = 0
		if state.video_unscaled ~= "downscale-big" or ((state.video_w <= state.screen_w)
			and (state.video_h <= state.screen_h)) then
			f_width = state.video_w
			f_height = state.video_h
		end
	end
	local scaled_w = math.floor( f_width + vo_panscan_area * state.panscan * f_w )
	local scaled_h = math.floor( f_height + vo_panscan_area * state.panscan * f_h )
	return scaled_w, scaled_h
end

function DisplayState:_split_scaling(dst_size, scaled_src_size, zoom, align, pan)
	scaled_src_size = math.floor(scaled_src_size * 2^zoom)
	align = (align + 1) / 2
	local dst_start = (dst_size - scaled_src_size) * align + pan * scaled_src_size
	local dst_end = dst_start + scaled_src_size
	return math.floor(dst_start), math.floor(dst_end)
end

function DisplayState:recalculate_bounds(forced)
	local new_state = self:_collect_display_state()
	if not (forced or self.current_state == nil) then
		local changed = false
		for k in pairs(new_state) do
			if new_state[k] ~= self.current_state[k] then
				changed = true
				break
			end
		end
		if not changed then return self.screen_ready end
	end
	self.current_state = new_state
	self.screen.width = new_state.screen_w
	self.screen.height = new_state.screen_h
	if new_state.video_w and new_state.video_h then
		self.video.width = new_state.video_w
		self.video.height = new_state.video_h

		-- Apply video-aspect-override when present (e.g. "16:9" or "1.7777") by adjusting raw output dims
		local vao = new_state.video_aspect_override
		if vao and vao ~= false and tostring(vao) ~= "no" then
			local s = tostring(vao)
			-- Try parse A:B style
			local na, nb = s:match("^(%d+)%s*[:xX]%s*(%d+)$")
			local ar = nil
			if na and nb then
				ar = tonumber(na) / tonumber(nb)
			else
				local f = tonumber(s)
				if f and f > 0 then ar = f end
			end
			if ar then
				-- Prefer to keep video_h_raw and compute video_w_raw to match aspect
				if new_state.video_h_raw and new_state.video_h_raw > 0 then
					new_state.video_w_raw = math.floor(new_state.video_h_raw * ar + 0.5)
				elseif new_state.video_w_raw and new_state.video_w_raw > 0 then
					new_state.video_h_raw = math.floor(new_state.video_w_raw / ar + 0.5)
				else
					-- fallback to reported dwidth/dheight
					if new_state.video_h and new_state.video_h > 0 then
						new_state.video_w_raw = math.floor(new_state.video_h * ar + 0.5)
					elseif new_state.video_w and new_state.video_w > 0 then
						new_state.video_h_raw = math.floor(new_state.video_w / ar + 0.5)
					end
				end
				-- Also update video_w/video_h (dwidth/dheight) to reflect the override so
				-- bounds calculation (which uses video_w/video_h) stays consistent with
				-- the adjusted raw output dimensions. Prefer keeping video_h and
				-- computing video_w, mirroring the logic above.
				if new_state.video_h and new_state.video_h > 0 then
					new_state.video_w = math.floor(new_state.video_h * ar + 0.5)
				elseif new_state.video_w and new_state.video_w > 0 then
					new_state.video_h = math.floor(new_state.video_w / ar + 0.5)
				end
			end
		end
		if new_state.keepaspect then
			local scaled_w, scaled_h = self:_aspect_calc_panscan(new_state)
			local video_left, video_right = self:_split_scaling(new_state.screen_w, scaled_w,
				new_state.video_zoom, new_state.video_align_x, new_state.video_pan_x)
			local video_top, video_bottom = self:_split_scaling(new_state.screen_h, scaled_h,
				new_state.video_zoom, new_state.video_align_y, new_state.video_pan_y)
			self.bounds = { left = video_left, right = video_right, top = video_top, bottom = video_bottom,
			 	width = video_right - video_left, height = video_bottom - video_top }
		else
			self.bounds = { left = 0, top = 0, right = self.screen.width, bottom = self.screen.height,
				width = self.screen.width, height = self.screen.height }
		end
		-- Use the same source for scale as was used to compute bounds (prefer dwidth/dheight)
		local basis_w = new_state.video_w or new_state.video_w_raw
		local basis_h = new_state.video_h or new_state.video_h_raw
		self.scale.x = basis_w / self.bounds.width
		self.scale.y = basis_h / self.bounds.height
		self.video_ready = true
	end
	self.screen_ready = true
	return self.screen_ready
end

function DisplayState:screen_to_video(x, y)
	local nx = (x - self.bounds.left) * self.scale.x
	local ny = (y - self.bounds.top) * self.scale.y
	return nx, ny
end

function DisplayState:video_to_screen(x, y)
	local nx = (x / self.scale.x) + self.bounds.left
	local ny = (y / self.scale.y) + self.bounds.top
	return nx, ny
end

-- create one instance for use
display_state = DisplayState.new()
-- store observer ids in a local table so we can unobserve on unload
local display_observer_ids = {}

-- Register observers for properties that affect display mapping.
-- When any of these change, recalculate the display bounds once.
local function register_display_observers()
	local props = {
		"dwidth", "dheight",
		"video-out-params/w", "video-out-params/h",
		"video-aspect-override",
		"panscan", "video-zoom", "video-unscaled",
		"video-align-x", "video-align-y",
		"video-pan-x", "video-pan-y",
		"keepaspect", "keepaspect-window",
		"fullscreen", "window-maximized"
	}

	for _, p in ipairs(props) do
		local cb = function(name, value)
			if display_state and display_state.recalculate_bounds then
				display_state:recalculate_bounds(true)
			end
		end
		local id = mp.observe_property(p, "native", cb)
		table.insert(display_observer_ids, id)
	end
end

local function unregister_display_observers()
	if not display_observer_ids then return end
	for _, id in ipairs(display_observer_ids) do
		mp.unobserve_property(id)
	end
	display_observer_ids = {}
end

local function osd_to_video_coords(x, y)
	-- Use cached DisplayState
	if display_state and display_state.recalculate_bounds then
		-- Ensure display state is up-to-date and video mapping is ready
		display_state:recalculate_bounds()
		if display_state.video_ready then
			local vx, vy = display_state:screen_to_video(x, y)
			return math.floor(vx + 0.5), math.floor(vy + 0.5)
		end
	end
	return nil
end

-- Simplified interactive ASS cropper
local asscrop_active = false
local asscrop_start_pos = nil
local asscrop_end_pos = nil
local asscrop_timer = nil
local asscrop_count = 0
local asscrop_callback = nil

local function asscrop_update()
	if not asscrop_overlay then return end

	local ass = assdraw.ass_new()
	if asscrop_start_pos then
		local sx, sy = asscrop_start_pos[1], asscrop_start_pos[2]
		local mx, my = mp.get_mouse_pos()
		local ex, ey
		if asscrop_end_pos then
			ex, ey = asscrop_end_pos[1], asscrop_end_pos[2]
		else
			ex, ey = mx, my
		end

		local x0 = math.min(sx, ex)
		local y0 = math.min(sy, ey)
		local x1 = math.max(sx, ex)
		local y1 = math.max(sy, ey)

		local osd_w, osd_h = mp.get_osd_size()

		-- dim outside area using inverse clip so the interior stays untouched
		local overlay_transparency = 160 -- 0-255
		local overlay_lightness = 0
		local format_dim = string.format("{\\bord0\\1a&H%02X&\\1c&H%02X%02X%02X&}", 
			overlay_transparency,
			overlay_lightness,
			overlay_lightness,
			overlay_lightness)

		ass:new_event()
		ass:append(string.format("{\\iclip(%d,%d,%d,%d)}", x0, y0, x1, y1))
		ass:pos(0,0)
		ass:append(format_dim)
		ass:draw_start()
		ass:rect_cw(0,0, osd_w, osd_h)
		ass:draw_stop()

		-- Draw border using transparent primary (no fill) and \\3c for outline color
		local line_color = 220
		local box_format = string.format("{\\1a&HFF&\\1c&H000000&\\3c&H%02X%02X%02X&\\bord1}",
			line_color,
			line_color,
			line_color)
		ass:new_event()
		ass:pos(0,0)
		ass:append(box_format)
		ass:draw_start()
		ass:rect_cw(x0, y0, x1, y1)
		ass:draw_stop()

		-- Handles: transparent fill + white border
		local hs = 10
		local handle_format = "{\\1a&HFF&\\1c&H000000&\\3c&HFFFFFF&\\bord1}"
		ass:new_event()
		ass:pos(0,0)
		ass:append(handle_format)
		ass:draw_start()
		ass:rect_cw(x0-hs, y0-hs, x0+hs, y0+hs)
		ass:rect_cw(x1-hs, y0-hs, x1+hs, y0+hs)
		ass:rect_cw(x0-hs, y1-hs, x0+hs, y1+hs)
		ass:rect_cw(x1-hs, y1-hs, x1+hs, y1+hs)
		ass:draw_stop()

		-- Size text
		local sw = math.max(0, x1 - x0)
		local sh = math.max(0, y1 - y0)
		ass:new_event()
		ass:pos(x1 - 6, y1 + 14)
		ass:an(9)
		ass:append(string.format("{\\fs16\\bord2\\shad0} %dx%d", sw, sh))
	else
		ass:new_event()
		ass:pos(10,10)
		ass:append("{\\fs20\\bord2}Click once to set first corner, click again to set second. Enter to crop, Esc to cancel.")
	end

	local osd_w, osd_h = mp.get_osd_size()
	mp.set_osd_ass(osd_w, osd_h, ass.text)
end

local function asscrop_cancel(msg)
	asscrop_start_pos = nil
	asscrop_end_pos = nil
	asscrop_callback = nil
	if asscrop_timer then asscrop_timer:kill() asscrop_timer = nil end
	mp.set_osd_ass(0,0, "")
	mp.remove_key_binding("lines_asscrop_mouse")
	mp.remove_key_binding("lines_asscrop_enter")
	mp.remove_key_binding("lines_asscrop_esc")
	asscrop_active = false
	if msg then
		mp.osd_message("Crop canceled")
	end
	mp.commandv('script-message-to', 'uosc', 'disable-elements', mp.get_script_name(), '')
end

local function asscrop_finish()
	if not (asscrop_start_pos and asscrop_end_pos) then
		mp.osd_message("No crop area set")
		msg.info("No crop area set")
		return
	end

	-- compute video-space crop
	local x1s, y1s = asscrop_start_pos[1], asscrop_start_pos[2]
	local x2s, y2s = asscrop_end_pos[1], asscrop_end_pos[2]
	local x0 = math.min(x1s, x2s)
	local y0 = math.min(y1s, y2s)
	local x1 = math.max(x1s, x2s)
	local y1 = math.max(y1s, y2s)

	local vx0, vy0
	local vw, vh
	do
		local tx0, ty0 = osd_to_video_coords(x0, y0)
		local tx1, ty1 = osd_to_video_coords(x1, y1)
		if not tx0 or not tx1 then
			mp.osd_message("Unable to determine video coordinates")
			msg.warn("Unable to determine video coordinates")
			return
		end
		vx0, vy0 = tx0, ty0
		vw = math.abs(tx1 - tx0)
		vh = math.abs(ty1 - ty0)
	end

	if vw <= 0 or vh <= 0 then
		mp.osd_message("Bad crop size")
		msg.warn("Bad crop size")
		return
	end

	-- If a callback is registered (used by take_screenshot first-shot flow),
	-- call it with crop and skip mpv crop
	if asscrop_callback then
		local cb = asscrop_callback
		asscrop_callback = nil
		cb({ x = vx0, y = vy0, w = vw, h = vh })
		asscrop_cancel(false)
		return
	end

	local crop_arg = string.format("crop=%d:%d:%d:%d", vw, vh, vx0, vy0)

	asscrop_count = asscrop_count + 1
	perform_capture(asscrop_count, crop_arg)
	asscrop_cancel(false)
end

local function asscrop_mouse(e)
	if not e or not e.event then return end
	if e.event == "down" then
		local mx, my = mp.get_mouse_pos()
		if not asscrop_start_pos then
			asscrop_start_pos = {mx, my}
			if not asscrop_timer then asscrop_timer = mp.add_periodic_timer(1/60, asscrop_update) end
			-- immediate update so rectangle follows cursor
			asscrop_update()
		else
			asscrop_end_pos = {mx, my}
			asscrop_update()
		end
	end
end

local function asscrop_begin()
	local path = mp.get_property("path")
	if not path then
		return
	end

	if asscrop_active then
		asscrop_cancel(true)
		return
	end

	asscrop_active = true
	asscrop_start_pos = nil
	asscrop_end_pos = nil
	asscrop_overlay = mp.create_osd_overlay("ass-events")
	asscrop_timer = nil

	-- disable certain uosc UI elements
	mp.commandv('script-message-to', 'uosc', 'disable-elements', mp.get_script_name(),
		'top_bar,timeline,controls,volume,idle_indicator,audio_indicator,buffering_indicator,pause_indicator')

	-- forced mouse binding to capture clicks
	mp.add_forced_key_binding("MBTN_LEFT", "lines_asscrop_mouse", asscrop_mouse, {complex=true})
	mp.add_forced_key_binding("ENTER", "lines_asscrop_enter", function() asscrop_finish() end)
	mp.add_forced_key_binding("ESC", "lines_asscrop_esc", function() asscrop_cancel(true) end)
	mp.osd_message("Crop: Click first corner, then second. Enter to confirm, Esc to cancel.")
end

local function take_screenshot()
	local crop_arg = ""
	local path = mp.get_property("path")
	if not path then
		return
	end
	local v_w = mp.get_property_number("dwidth") or mp.get_property_number("width", 0)
	local v_h = mp.get_property_number("dheight") or mp.get_property_number("height", 0)

	screenshot_count = screenshot_count + 1
	if subtitle_top == 0 then
		screenshot_count = 1
	end

	-- If first shot (or subtitle not set), defer actual capture until after ASS cropper callback
	if screenshot_count == 1 then
		asscrop_callback = function(crop)
			-- crop is video-space x,y,w,h
			subtitle_top = crop.y / v_h
			subtitle_bottom = (v_h - (crop.y + crop.h)) / v_h
			if subtitle_top < 0 or subtitle_bottom < 0 then
				subtitle_top = 0
				subtitle_bottom = 0
				mp.osd_message("Invalid subtitle margins\nplease make sure the subtitles are within the video frame")
				msg.warn("Invalid subtitle margins, please make sure the subtitles are within the video frame")
				return
			end
			mp.osd_message(string.format("Subtitle region set: top=%.3f bottom=%.3f", subtitle_top, subtitle_bottom))
			msg.verbose(string.format("Subtitle region set: top=%.3f bottom=%.3f", subtitle_top, subtitle_bottom))
			-- now perform the actual capture using the newly set margins
			local effective_subtitle_top = 1 - subtitle_bottom
			local crop_h = math.max(1, math.floor(v_h * effective_subtitle_top + 0.5))
			local crop_w = v_w
			local crop_x = 0
			local crop_y = 0
			crop_arg = string.format("crop=%d:%d:%d:%d", crop_w, crop_h, crop_x, crop_y)
			perform_capture(screenshot_count, crop_arg, true)
		end
		-- Launch the ASS cropper UI and wait for callback to do the capture
		asscrop_begin()
	else
		local crop_height_frac = 1 - subtitle_top - subtitle_bottom
		if crop_height_frac <= 0 then
			screenshots = {}
			screenshot_count = 0
			subtitle_top = 0
			subtitle_bottom = 0
			mp.osd_message("Invalid subtitle margins, skipping crop")
			msg.warn("Invalid subtitle margins, skipping crop")
		else
			local crop_h = math.max(1, math.floor(v_h * crop_height_frac + 0.5))
			local crop_w = v_w
			local crop_x = 0
			local crop_y = math.max(0, math.floor(v_h * subtitle_top + 0.5))
			crop_arg = string.format("crop=%d:%d:%d:%d", crop_w, crop_h, crop_x, crop_y)
			perform_capture(screenshot_count, crop_arg, true)
		end
	end
end

-- stitch the cropped screenshots together
local function stitch_images()
	if #screenshots <= 1 then
		mp.osd_message("No shots to stitch!")
		return
	end

	-- remove entries that no longer exist on disk
	for i = #screenshots, 1, -1 do
		if not file_exist(screenshots[i]) then
			table.remove(screenshots, i)
		end
	end

	local command = { options.ffmpeg_path, "-loglevel", options.ffmpeg_loglevel, "-y" }
	local output_file = utils.join_path(screenshot_dir, "stitched_screenshot_" ..
		os.date("%Y%m%d_%H%M%S") .. screenshot_format)
	local filter_expr = "vstack=" .. #screenshots

	-- add input files, filter, output filename, one by one
	for i = 1, #screenshots do
		table.insert(command, "-i")
		table.insert(command, screenshots[i])
	end
	table.insert(command, "-filter_complex")
	table.insert(command, filter_expr)
	table.insert(command, output_file)

	-- run the command
	local result = utils.subprocess({ args = command })

	if result.status == 0 then
		mp.osd_message("Stitched shot saved: " .. output_file)
		msg.verbose("Stitched shot saved: " .. output_file)
	else
		mp.osd_message("Stitching failed")
		msg.verbose("Stitching failed: " .. (result and result.error or "unknown"))
		return
	end

	-- delete the cropped shots and reset the counter
	for _, img in ipairs(screenshots) do
		os.remove(img)
	end

	screenshots = {}
	screenshot_count = 0
	subtitle_top = 0
	subtitle_bottom = 0
end

mp.register_event("file-loaded", function()
	if display_state then
		display_state:recalculate_bounds(true)
	end
	register_display_observers()
end)

mp.add_hook("on_unload", 50, function()
	unregister_display_observers()
end)

-- bindings
mp.add_key_binding(nil, "take-screenshot", take_screenshot)
mp.add_key_binding(nil, "stitch-images", stitch_images)
mp.add_key_binding(nil, "crop-screenshot", asscrop_begin)
