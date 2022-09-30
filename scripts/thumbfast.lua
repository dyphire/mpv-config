-- thumbfast.lua
--
-- High-performance on-the-fly thumbnailer
--
-- Built for easy integration in third-party UIs.

local options = {
    -- Socket path (leave empty for auto)
    socket = "",

    -- Thumbnail path (leave empty for auto)
    thumbnail = "",

    -- Maximum thumbnail size in pixels (scaled down to fit)
    -- Values are scaled when hidpi is enabled
    max_height = 200,
    max_width = 200,

    -- Overlay id
    overlay_id = 42,

    -- Thumbnail interval in seconds, set to 0 to disable (warning: high cpu usage)
    -- Clamped to min_thumbnails and max_thumbnails
    interval = 6,

    -- Number of thumbnails
    min_thumbnails = 6,
    max_thumbnails = 120,

    -- Spawn thumbnailer on file load for faster initial thumbnails
    spawn_first = false,

    -- Enable on network playback
    network = false,

    -- Enable on audio playback
    audio = false
}

mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options, "thumbfast")

if options.min_thumbnails < 1 then
    options.min_thumbnails = 1
end

local os_name = ""

math.randomseed(os.time())
local unique = math.random(10000000)
local init = false

local spawned = false
local can_generate = true
local network = false
local disabled = false
local interval = 0

local x = nil
local y = nil
local last_x = x
local last_y = y

local last_index = nil
local last_request = nil
local last_request_time = nil
local last_display_time = 0

local effective_w = options.max_width
local generate_h = options.max_height
local render_h = generate_h
local thumb_size = effective_w * generate_h * 4

local filters_reset = {["lavfi-crop"]=true, crop=true}
local filters_runtime = {hflip=true, vflip=true}
local filters_all = filters_runtime
for k,v in pairs(filters_reset) do filters_all[k] = v end

local last_vf_reset = ""
local last_vf_runtime = ""

local last_rotate = 0

local par = ""
local last_par = ""

local function get_os()
    local raw_os_name = ""

    if jit and jit.os and jit.arch then
        raw_os_name = jit.os
    else
        if package.config:sub(1,1) == "\\" then
            -- Windows
            local env_OS = os.getenv("OS")
            if env_OS then
                raw_os_name = env_OS
            end
        else
            raw_os_name = mp.command_native({name = "subprocess", playback_only = false, capture_stdout = true, args = {"uname", "-s"}}).stdout
        end
    end

    raw_os_name = (raw_os_name):lower()

    local os_patterns = {
        ["windows"] = "Windows",

        -- Uses socat
        ["linux"]   = "Linux",

        ["osx"]     = "Mac",
        ["mac"]     = "Mac",
        ["darwin"]  = "Mac",

        ["^mingw"]  = "Windows",
        ["^cygwin"] = "Windows",

        -- Because they have the good netcat (with -U)
        ["bsd$"]    = "Mac",
        ["sunos"]   = "Mac"
    }

    -- Default to linux
    local str_os_name = "Linux"

    for pattern, name in pairs(os_patterns) do
        if raw_os_name:match(pattern) then
            str_os_name = name
            break
        end
    end

    return str_os_name
end

local function vf_string(filters, full)
    local vf = ""
    local vf_table = mp.get_property_native("vf")

    if #vf_table > 0 then
        for i = #vf_table, 1, -1 do
            if filters[vf_table[i].name] then
                local args = ""
                for key, value in pairs(vf_table[i].params) do
                    if args ~= "" then
                        args = args .. ":"
                    end
                    args = args .. key .. "=" .. value
                end
                vf = vf .. vf_table[i].name .. "=" .. args .. ","
            end
        end
    end

    if full then
        vf = vf.."scale=w="..effective_w..":h="..generate_h..par..",pad=w="..effective_w..":h="..generate_h..",format=bgra"
    end

    return vf
end

local function calc_dimensions()
    local width = mp.get_property_number("video-out-params/dw")
    local height = mp.get_property_number("video-out-params/dh")
    if not width or not height then return end

    local scale = mp.get_property_number("display-hidpi-scale", 1)

    if width / height > options.max_width / options.max_height then
        effective_w = math.floor(options.max_width * scale / 2) * 2
    else
        local target_h = math.floor(options.max_height * scale + 0.5)
        effective_w = math.floor(width / height * target_h / 2) * 2
    end
    generate_h = math.ceil(height / width * effective_w / 2) * 2
    render_h = math.floor(height / width * effective_w + 0.5)

    thumb_size = effective_w * generate_h * 4

    local v_par = mp.get_property_number("video-out-params/par", 1)
    if v_par == 1 then
        par = ":force_original_aspect_ratio=decrease"
    else
        par = ""
    end
end

local function info()
    local display_w, display_h = effective_w, render_h
    if mp.get_property_number("video-params/rotate", 0) % 180 == 90 then
        display_w, display_h = render_h, effective_w
    end

    local json, err = mp.utils.format_json({width=display_w, height=display_h, disabled=disabled, socket=options.socket, thumbnail=options.thumbnail, overlay_id=options.overlay_id})
    mp.commandv("script-message", "thumbfast-info", json)
end

local function remove_thumbnail_files()
    os.remove(options.thumbnail)
    os.remove(options.thumbnail..".bgra")
end

local function spawn(time)
    if disabled then return end

    local path = mp.get_property("path")
    if path == nil then return end

    spawned = true

    local open_filename = mp.get_property("stream-open-filename")
    local ytdl = open_filename and network and path ~= open_filename
    if ytdl then
        path = open_filename
    end

    if os_name == "" then
        os_name = get_os()
    end

    if options.socket == "" then
        if os_name == "Windows" then
            options.socket = "thumbfast"
        elseif os_name == "Mac" then
            options.socket = "/tmp/thumbfast"
        else
            options.socket = "/tmp/thumbfast"
        end
    end

    if options.thumbnail == "" then
        if os_name == "Windows" then
            options.thumbnail = os.getenv("TEMP").."\\thumbfast.out"
        elseif os_name == "Mac" then
            options.thumbnail = "/tmp/thumbfast.out"
        else
            options.thumbnail = "/tmp/thumbfast.out"
        end
    end

    if not init then
        -- ensure uniqueness
        options.socket = options.socket .. unique
        options.thumbnail = options.thumbnail .. unique
        init = true
    end

    remove_thumbnail_files()

    calc_dimensions()

    info()

    mp.command_native_async(
        {name = "subprocess", playback_only = true, args = {
            "mpv", path, "--no-config", "--msg-level=all=no", "--idle", "--pause", "--keep-open=always",
            "--edition="..(mp.get_property_number("edition") or "auto"), "--vid="..(mp.get_property_number("vid") or "auto"), "--no-sub", "--no-audio",
            "--input-ipc-server="..options.socket,
            "--start="..time, "--hr-seek=no",
            "--ytdl-format=worst", "--demuxer-readahead-secs=0", "--demuxer-max-bytes=128KiB",
            "--vd-lavc-skiploopfilter=all", "--vd-lavc-software-fallback=1", "--vd-lavc-fast",
            "--vf="..vf_string(filters_all, true),
            "--sws-allow-zimg=no", "--sws-fast=yes", "--sws-scaler=fast-bilinear",
            "--video-rotate="..last_rotate,
            "--ovc=rawvideo", "--of=image2", "--ofopts=update=1", "--o="..options.thumbnail
        }},
        function() end
    )
end

local function run(command, callback)
    if not spawned then return end

    callback = callback or function() end

    local seek_command
    if os_name == "Windows" then
        seek_command = {"cmd", "/c", "echo "..command.." > \\\\.\\pipe\\" .. options.socket}
    elseif os_name == "Mac" then
        -- this doesn't work, on my system. not sure why.
        seek_command = {"/usr/bin/env", "sh", "-c", "echo '"..command.."' | nc -w0 -U " .. options.socket}
    else
        seek_command = {"/usr/bin/env", "sh", "-c", "echo '" .. command .. "' | socat - " .. options.socket}
    end

    mp.command_native_async(
        {name = "subprocess", playback_only = true, capture_stdout = true, args = seek_command},
        callback
    )
end

local function thumb_index(thumbtime)
    return math.floor(thumbtime / interval)
end

local function index_time(index, thumbtime)
    if interval > 0 then
        local time = index * interval
        return time + interval / 3
    else
        return thumbtime
    end
end

local function draw(w, h, thumbtime, display_time, script)
    local display_w, display_h = w, h
    if mp.get_property_number("video-params/rotate", 0) % 180 == 90 then
        display_w, display_h = h, w
    end

    if x ~= nil then
        mp.command_native(
            {name = "overlay-add", id=options.overlay_id, x=x, y=y, file=options.thumbnail..".bgra", offset=0, fmt="bgra", w=display_w, h=display_h, stride=(4*display_w)}
        )
    elseif script then
        local json, err = mp.utils.format_json({width=display_w, height=display_h, x=x, y=y, socket=options.socket, thumbnail=options.thumbnail, overlay_id=options.overlay_id})
        mp.commandv("script-message-to", script, "thumbfast-render", json)
    end
end

local function display_img(w, h, thumbtime, display_time, script, redraw)
    if last_display_time > display_time or disabled then return end

    if not redraw then
        can_generate = false

        local info = mp.utils.file_info(options.thumbnail)
        if not info or info.size ~= thumb_size then
            if thumbtime == -1 then
                can_generate = true
                return
            end

            if thumbtime < 0 then
                thumbtime = thumbtime + 1
            end

            -- display last successful thumbnail if one exists
            local info2 = mp.utils.file_info(options.thumbnail..".bgra")
            if info2 and info2.size == thumb_size then
                draw(w, h, thumbtime, display_time, script)
            end

            -- retry up to 5 times
            return mp.add_timeout(0.05, function() display_img(w, h, thumbtime < 0 and thumbtime or -5, display_time, script) end)
        end

        if last_display_time > display_time then return end

        -- os.rename can't replace files on windows
        if os_name == "Windows" then
            os.remove(options.thumbnail..".bgra")
        end
        -- move the file because it can get overwritten while overlay-add is reading it, and crash the player
        os.rename(options.thumbnail, options.thumbnail..".bgra")

        last_display_time = display_time
    else
        local info = mp.utils.file_info(options.thumbnail..".bgra")
        if not info or info.size ~= thumb_size then
            -- still waiting on intial thumbnail
            return mp.add_timeout(0.05, function() display_img(w, h, thumbtime, display_time, script) end)
        end
        if not can_generate then
            return draw(w, h, thumbtime, display_time, script)
        end
    end

    draw(w, h, thumbtime, display_time, script)

    can_generate = true

    if not redraw then
        -- often, the file we read will be the last requested thumbnail
        -- retry after a small delay to ensure we got the latest image
        if thumbtime ~= -1 then
            mp.add_timeout(0.05, function() display_img(w, h, -1, display_time, script) end)
            mp.add_timeout(0.1, function() display_img(w, h, -1, display_time, script) end)
        end
    end
end

local function thumb(time, r_x, r_y, script)
    if disabled then return end

    time = tonumber(time)
    if time == nil then return end

    if r_x == nil or r_y == nil then
        x, y = nil, nil
    else
        x, y = math.floor(r_x + 0.5), math.floor(r_y + 0.5)
    end

    local index = thumb_index(time)
    local seek_time = index_time(index, time)

    if last_request == seek_time or (interval > 0 and index == last_index) then
        last_index = index
        if x ~= last_x or y ~= last_y then
            last_x, last_y = x, y
            display_img(effective_w, render_h, time, mp.get_time(), script, true)
        end
        return
    end

    local cur_request_time = mp.get_time()

    last_index = index
    last_request_time = cur_request_time
    last_request = seek_time

    if not spawned then
        spawn(seek_time)
        if can_generate then
            display_img(effective_w, render_h, time, cur_request_time, script)
            mp.add_timeout(0.15, function() display_img(effective_w, render_h, time, cur_request_time, script) end)
            end
        return
    end

    run("async seek "..seek_time.." absolute+keyframes", function() if can_generate then display_img(effective_w, render_h, time, cur_request_time, script) end end)
end

local function clear()
    last_display_time = mp.get_time()
    can_generate = true
    last_x = nil
    last_y = nil
    mp.command_native(
        {name = "overlay-remove", id=options.overlay_id}
    )
end

local function watch_changes()
    local old_w = effective_w
    local old_h = generate_h

    calc_dimensions()

    local vf_reset = vf_string(filters_reset)
    local rotate = mp.get_property_number("video-rotate", 0)

    if spawned then
        if old_w ~= effective_w or old_h ~= generate_h or last_vf_reset ~= vf_reset or (last_rotate % 180) ~= (rotate % 180) or par ~= last_par then
            last_rotate = rotate
            -- mpv doesn't allow us to change output size
            run("quit")
            clear()
            info()
            spawned = false
            spawn(last_request or mp.get_property_number("time-pos", 0))
        else
            if rotate ~= last_rotate then
                run("set video-rotate "..rotate)
            end
            local vf_runtime = vf_string(filters_runtime)
            if vf_runtime ~= last_vf_runtime then
                run("vf set "..vf_string(filters_all, true))
                last_vf_runtime = vf_runtime
            end
        end
    else
        if old_w ~= effective_w or old_h ~= generate_h or last_vf_reset ~= vf_reset or (last_rotate % 180) ~= (rotate % 180) or par ~= last_par then
            last_rotate = rotate
            info()
        end
        last_vf_runtime = vf_string(filters_runtime)
    end

    last_vf_reset = vf_reset
    last_rotate = rotate
    last_par = par
end

local function sync_changes(prop, val)
    if spawned and val then
        run("set "..prop.." "..val)
    end
end

local function file_load()
    clear()

    network = mp.get_property_bool("demuxer-via-network", false)
    local image = mp.get_property_native('current-tracks/video/image', true)
    local albumart = image and mp.get_property_native("current-tracks/video/albumart", false)

    disabled = (network and not options.network) or (albumart and not options.audio) or (image and not albumart)
    info()
    if disabled then return end

    interval = math.min(math.max(mp.get_property_number("duration", 1) / options.max_thumbnails, options.interval), mp.get_property_number("duration", options.interval * options.min_thumbnails) / options.min_thumbnails)

    spawned = false
    if options.spawn_first then spawn(mp.get_property_number("time-pos", 0)) end
end

local function shutdown()
    run("quit")
    remove_thumbnail_files()
    os.remove(options.socket)
end

mp.observe_property("display-hidpi-scale", "native", watch_changes)
mp.observe_property("video-out-params", "native", watch_changes)
mp.observe_property("vf", "native", watch_changes)
mp.observe_property("vid", "native", sync_changes)
mp.observe_property("edition", "native", sync_changes)

mp.register_script_message("thumb", thumb)
mp.register_script_message("clear", clear)

mp.register_event("file-loaded", file_load)
mp.register_event("shutdown", shutdown)
