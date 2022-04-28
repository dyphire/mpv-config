-- Source https://github.com/christoph-heinrich/mpv-youtube-quality/blob/master/youtube-quality.lua
-- Commit Feb 8, 2022 fab8580 

-- youtube-quality.lua
--
-- Change youtube video quality on the fly.
--
-- Usage:
-- add bindings to input.conf:
-- CTRL+f   script-message-to youtube_quality quality-menu-video
-- ALT+f    script-message-to youtube_quality quality-menu-audio
--
-- Displays a menu that lets you switch to different ytdl-format settings while
-- you're in the middle of a video (just like you were using the web player).
--
-- Bound to ctrl-f by default.

local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'
local assdraw = require 'mp.assdraw'

local opts = {
    --key bindings
    up_binding = "UP WHEEL_UP",
    down_binding = "DOWN WHEEL_DOWN",
    select_binding = "ENTER MBTN_LEFT",
    close_menu_binding = "ESC MBTN_RIGHT",

    --youtube-dl version(could be youtube-dl or yt-dlp, or something else)
    ytdl_ver = "yt-dlp",

    --formatting / cursors
    selected_and_active     = "▶  - ",
    selected_and_inactive   = "●  - ",
    unselected_and_active   = "▷ - ",
    unselected_and_inactive = "○ - ",

	--font size scales by window, if false requires larger font and padding sizes
	scale_playlist_by_window=false,

    --playlist ass style overrides inside curly brackets, \keyvalue is one field, extra \ for escape in lua
    --example {\\fnUbuntu\\fs10\\b0\\bord1} equals: font=Ubuntu, size=10, bold=no, border=1
    --read http://docs.aegisub.org/3.2/ASS_Tags/ for reference of tags
    --undeclared tags will use default osd settings
    --these styles will be used for the whole playlist. More specific styling will need to be hacked in
    --
    --(a monospaced font is recommended but not required)
    style_ass_tags = "{\\fnmonospace}",

    --paddings for top left corner
    text_padding_x = 5,
    text_padding_y = 5,

    --other
    menu_timeout = 10,

    --use youtube-dl to fetch a list of available formats (overrides quality_strings)
    fetch_formats = true,

    --default menu entries
    quality_strings=[[
    [
    {"4320p" : "bestvideo[height<=?4320p]+bestaudio/best"},
    {"2160p" : "bestvideo[height<=?2160]+bestaudio/best"},
    {"1440p" : "bestvideo[height<=?1440]+bestaudio/best"},
    {"1080p" : "bestvideo[height<=?1080]+bestaudio/best"},
    {"720p" : "bestvideo[height<=?720]+bestaudio/best"},
    {"480p" : "bestvideo[height<=?480]+bestaudio/best"},
    {"360p" : "bestvideo[height<=?360]+bestaudio/best"},
    {"240p" : "bestvideo[height<=?240]+bestaudio/best"},
    {"144p" : "bestvideo[height<=?144]+bestaudio/best"}
    ]
    ]],

    --reset youtube-dl format to the original format string when changing files (e.g. going to the next playlist entry)
    --if file was opened previously, reset to previously selected format
    reset_format = true,
}
(require 'mp.options').read_options(opts, "youtube-quality")
opts.quality_strings = utils.parse_json(opts.quality_strings)

local destroyer = nil
function show_menu(isvideo)
    local selected = 1
    local active = 0
    local num_options = 0
    local options = {}
    local vfmt = nil
    local afmt = nil
    local voptions = nil
    local aoptions = nil
    local url = nil

    if destroyer ~= nil then
        destroyer()
    end

    voptions, aoptions , vfmt, afmt, url = download_formats()
    if voptions == nil then
        return
    end

    options = isvideo and voptions or aoptions

    function format_string(vfmt, afmt)
        if vfmt ~= nil and afmt ~= nil then
            return vfmt.."+"..afmt
        elseif vfmt ~= nil then
            return vfmt
        elseif afmt ~= nil then
            return afmt
        else
            return ""
        end
    end

    msg.verbose("current ytdl-format: "..format_string(vfmt, afmt))

    --set the cursor to the currently format
    for i,v in ipairs(options) do
        if v.format == (isvideo and vfmt or afmt) then
            active = i
            selected = active
            break
        end
    end

    local function table_size(t)
        s = 0
        for i,v in ipairs(t) do
            s = s+1
        end
        return s
    end

    num_options = table_size(options)

    function selected_move(amt)
        selected = selected + amt
        if selected < 1 then selected = num_options
        elseif selected > num_options then selected = 1 end
        timeout:kill()
        timeout:resume()
        draw_menu()
    end

    function choose_prefix(i)
        if     i == selected and i == active then return opts.selected_and_active
        elseif i == selected then return opts.selected_and_inactive end

        if     i ~= selected and i == active then return opts.unselected_and_active
        elseif i ~= selected then return opts.unselected_and_inactive end
        return "> " --shouldn't get here.
    end

    function draw_menu()
        local ass = assdraw.ass_new()

        ass:pos(opts.text_padding_x, opts.text_padding_y)
        ass:append(opts.style_ass_tags)

        if options[1] ~= nil then
            for i,v in ipairs(options) do
                ass:append(choose_prefix(i)..v.label.."\\N")
            end
        else
            ass:append("no formats found")
        end

		local w, h = mp.get_osd_size()
		if opts.scale_playlist_by_window then w,h = 0, 0 end
		mp.set_osd_ass(w, h, ass.text)
    end

    function bind_keys(keys, name, func, opts)
        if not keys then
          mp.add_forced_key_binding(keys, name, func, opts)
          return
        end
        local i = 1
        for key in keys:gmatch("[^%s]+") do
          local prefix = i == 1 and '' or i
          mp.add_forced_key_binding(key, name..prefix, func, opts)
          i = i + 1
        end
    end
      
    function unbind_keys(keys, name)
        if not keys then
          mp.remove_key_binding(name)
          return
        end
        local i = 1
        for key in keys:gmatch("[^%s]+") do
          local prefix = i == 1 and '' or i
          mp.remove_key_binding(name..prefix)
          i = i + 1
        end
    end
    
    function destroy()
        timeout:kill()
        mp.set_osd_ass(0,0,"")
        unbind_keys(opts.up_binding, "move_up")
        unbind_keys(opts.down_binding, "move_down")
        unbind_keys(opts.select_binding, "select")
        unbind_keys(opts.close_menu_binding, "close")
        destroyer = nil
    end

    timeout = mp.add_periodic_timer(opts.menu_timeout, destroy)
    destroyer = destroy

    bind_keys(opts.up_binding,     "move_up",   function() selected_move(-1) end, {repeatable=true})
    bind_keys(opts.down_binding,   "move_down", function() selected_move(1)  end, {repeatable=true})
    if options[1] ~= nil then
        bind_keys(opts.select_binding, "select", function()
            destroy()
            if isvideo == true then
                vfmt = options[selected].format
                url_data[url].vfmt = vfmt
            else
                afmt = options[selected].format
                url_data[url].afmt = afmt
            end
            mp.set_property("ytdl-raw-options", "")		--reset youtube-dl raw options before changing format
            mp.set_property("ytdl-format", format_string(vfmt, afmt))
            reload_resume()
        end)
    end
    bind_keys(opts.close_menu_binding, "close", destroy)	--close menu using ESC
    draw_menu()
    return
end

local ytdl = {
    path = opts.ytdl_ver,
    searched = false,
    blacklisted = {}
}

url_data={}
function download_formats()

    function get_url()
        local path = mp.get_property("path")
        path = string.gsub(path, "ytdl://", "") -- Strip possible ytdl:// prefix.

        function is_url(s)
            -- adapted the regex from https://stackoverflow.com/questions/3809401/what-is-a-good-regular-expression-to-match-a-url
            return nil ~= string.match(path, "^[%w]-://[-a-zA-Z0-9@:%._\\+~#=]+%.[a-zA-Z0-9()][a-zA-Z0-9()]?[a-zA-Z0-9()]?[a-zA-Z0-9()]?[a-zA-Z0-9()]?[a-zA-Z0-9()]?[-a-zA-Z0-9()@:%_\\+.~#?&/=]*")
        end

        return is_url(path) and path or nil
    end

    local url = get_url()
    if url == nil then
        return
    end

    if url_data[url] ~= nil then
        data = url_data[url]
        return data.voptions, data.aoptions, data.vfmt, data.afmt, url
    end

    local vres = {}
    local ares = {}
    local vfmt = nil
    local afmt = nil

    if opts.fetch_formats == false then
        for i,v in ipairs(opts.quality_strings) do
            for k,v2 in pairs(v) do
                vres[i] = {label = k, format=v2}
            end
        end
        url_data[url] = {voptions=vres, aoptions=ares, vfmt=nil, afmt=nil}
        return vres, ares , vfmt, afmt, url
    end

    mp.osd_message("fetching available formats with youtube-dl...", 60)

    if not (ytdl.searched) then
        local ytdl_mcd = mp.find_config_file(opts.ytdl_ver)
        if not (ytdl_mcd == nil) then
            msg.verbose("found youtube-dl at: " .. ytdl_mcd)
            ytdl.path = ytdl_mcd
        end
        ytdl.searched = true
    end

    local function exec(args)
        local ret = utils.subprocess({args = args})
        return ret.status, ret.stdout, ret
    end

	local ytdl_format = mp.get_property("ytdl-format")
	local command = nil
	if (ytdl_format == nil or ytdl_format == "") then
		command = {ytdl.path, "--no-warnings", "--no-playlist", "-j", url}
	else
		command = {ytdl.path, "--no-warnings", "--no-playlist", "-j", "-f", ytdl_format, url}
	end
	
	msg.verbose("calling youtube-dl with command: " .. table.concat(command, " "))

    local es, json, result = exec(command)

    if (es < 0) or (json == nil) or (json == "") then
        mp.osd_message("fetching formats failed...", 1)
        msg.error("failed to get format list: " .. es)
        return
    end

    local json, err = utils.parse_json(json)

    if (json == nil) then
        mp.osd_message("fetching formats failed...", 1)
        msg.error("failed to parse JSON data: " .. err)
        return
    end

    msg.verbose("youtube-dl succeeded!")

    function string_split (inputstr, sep)
        if sep == nil then
            sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
        end
        return t
    end

    local original_format=json.format_id
    local formats_split = string_split(original_format, "+")
    vfmt = formats_split[1]
    afmt = formats_split[2]

    function scale_filesize(size)
        size = tonumber(size)
        if size == nil then
            return "unknown"
        end

        counter = 0
        while size > 1024 do
            size = size / 1024
            counter = counter+1
        end

        if counter >= 3 then return string.format("%.1fGiB", size)
        elseif counter >= 2 then return string.format("%.1fMiB", size)
        elseif counter >= 1 then return string.format("%.1fKiB", size)
        else return string.format("%.1fB  ", size)
        end
    end

    function scale_bitrate(br)
        br = tonumber(br)
        if br == nil then
            return "unknown"
        end

        counter = 0
        while br > 1000 do
            br = br / 1000
            counter = counter+1
        end

        if counter >= 2 then return string.format("%.1fGbps", br)
        elseif counter >= 1 then return string.format("%.1fMbps", br)
        else return string.format("%.1fKbps", br)
        end
    end

    if json.formats ~= nil then
        for i,f in ipairs(json.formats) do
            if f.vcodec ~= "none" then
                local fps = f.fps and f.fps.."fps" or ""
                local resolution = string.format("%sx%s", f.width, f.height)
                local size = nil
                if f.filesize == nil and f.filesize_approx then
                    size = "~"..scale_filesize(f.filesize_approx)
                else
                    size = scale_filesize(f.filesize)
                end
                local tbr = scale_bitrate(f.tbr)
                local vcodec = f.vcodec == nil and "unknown" or f.vcodec
                local acodec = f.acodec == nil and " + unknown" or f.acodec ~= "none" and " + "..f.acodec or ""
                local l = string.format("%-9s %-5s %9s %9s (%-4s / %s%s)", resolution, fps, tbr, size, f.ext, vcodec, acodec)
                table.insert(vres, {label=l, format=f.format_id, width=f.width, size=f.filesize, fps=f.fps, tbr=f.tbr })
            elseif f.acodec ~= "none" then
                local size = scale_filesize(f.filesize)
                local tbr = scale_bitrate(f.tbr)
                local l = string.format("%6sHz %9s %9s (%-4s / %s)", f.asr, tbr, size, f.ext, f.acodec)
                table.insert(ares, {label=l, format=f.format_id, size=f.filesize, asr=f.asr, tbr=f.tbr })
            end
        end

        table.sort(vres,
        function(a, b)
            if a.width ~= nil and b.width ~= nil and a.width ~= b.width then
                return a.width > b.width
            elseif a.fps ~= nil and b.fps ~= nil and a.fps ~= b.fps then
                return a.fps > b.fps
            elseif a.tbr ~= nil and b.tbr ~= nil and a.tbr ~= b.tbr then
                return a.tbr > b.tbr
            elseif a.size ~= nil and b.size ~= nil and a.size ~= b.size then
                return a.size > b.size
            elseif a.format ~= nil and b.format ~= nil and a.format ~= b.format then
                return a.format > b.format
            end
        end)
        table.sort(ares,
        function(a, b)
            if a.asr ~= nil and b.asr ~= nil and a.asr ~= b.asr then
                return a.asr > b.asr
            elseif a.tbr ~= nil and b.tbr ~= nil and a.tbr ~= b.tbr then
                return a.tbr > b.tbr
            elseif a.size ~= nil and b.size ~= nil and a.size ~= b.size then
                return a.size > b.size
            elseif a.format ~= nil and b.format ~= nil and a.format ~= b.format then
                return a.format > b.format
            end
        end)
    end

    mp.osd_message("", 0)
    url_data[url] = {voptions=vres, aoptions=ares, vfmt=vfmt, afmt=afmt}
    return vres, ares , vfmt, afmt, url
end

-- keybind to launch menu
mp.register_script_message("quality-menu-video", function() show_menu(true) end)
mp.register_script_message("quality-menu-audio", function() show_menu(false) end)

-- special thanks to reload.lua (https://github.com/4e6/mpv-reload/)
function reload_resume()
    local playlist_pos = mp.get_property_number("playlist-pos")
    local reload_duration = mp.get_property_native("duration")
    local time_pos = mp.get_property("time-pos")

    mp.set_property_number("playlist-pos", playlist_pos)

    -- Tries to determine live stream vs. pre-recorded VOD. VOD has non-zero
    -- duration property. When reloading VOD, to keep the current time position
    -- we should provide offset from the start. Stream doesn't have fixed start.
    -- Decent choice would be to reload stream from it's current 'live' position.
    -- That's the reason we don't pass the offset when reloading streams.
    if reload_duration and reload_duration > 0 then
        local function seeker()
            mp.commandv("seek", time_pos, "absolute")
            mp.unregister_event(seeker)
        end
        mp.register_event("file-loaded", seeker)
    end
end

local original_format = mp.get_property("ytdl-format")
local path = nil
function file_start()
    local new_path = mp.get_property("path")
    if opts.reset_format and path ~= nil and new_path ~= path then
        local data = url_data[new_path]
        if data ~= nil then
            msg.verbose("setting previously set format")
            mp.set_property("ytdl-format", format_string(data.vfmt, data.afmt))
        else
            msg.verbose("setting original format")
            mp.set_property("ytdl-format", original_format)
        end
    end
    path = new_path
    download_formats()
end
mp.register_event("start-file", file_start)
