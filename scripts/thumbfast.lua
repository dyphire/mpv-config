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

    -- Spawn thumbnailer on file load for faster initial thumbnails
    spawn_first = false,

    -- Enable on network playback
    network = false,

    -- Enable on audio playback
    audio = false,

    -- Windows only: don't use subprocess to communicate with socket
    use_lua_io = false
}

mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options, "thumbfast")

local winapi = {}
if options.use_lua_io then
    local ffi_loaded, ffi = pcall(require, "ffi")
    if ffi_loaded then
        winapi = {
            ffi = ffi,
            C = ffi.C,
            bit = require("bit"),

            -- WinAPI constants
            GENERIC_WRITE = 0x40000000,
            OPEN_EXISTING = 3,
            FILE_FLAG_WRITE_THROUGH = 0x80000000,
            FILE_FLAG_NO_BUFFERING = 0x20000000,
            PIPE_NOWAIT = ffi.new("unsigned long[1]", 0x00000001),

            INVALID_HANDLE_VALUE = ffi.cast("void*", -1),

            -- don't care about how many bytes WriteFile wrote, so allocate something to store the result once
            _lpNumberOfBytesWritten = ffi.new("unsigned long[1]"),
        }
		-- cache flags used in run() to avoid bor() call
        winapi._createfile_pipe_flags = winapi.bit.bor(winapi.FILE_FLAG_WRITE_THROUGH, winapi.FILE_FLAG_NO_BUFFERING)

        ffi.cdef[[
            void* __stdcall CreateFileA(const char *lpFileName, unsigned long dwDesiredAccess, unsigned long dwShareMode, void *lpSecurityAttributes, unsigned long dwCreationDisposition, unsigned long dwFlagsAndAttributes, void *hTemplateFile);
            bool __stdcall WriteFile(void *hFile, const void *lpBuffer, unsigned long nNumberOfBytesToWrite, unsigned long *lpNumberOfBytesWritten, void *lpOverlapped);
            bool __stdcall CloseHandle(void *hObject);
            bool __stdcall SetNamedPipeHandleState(void *hNamedPipe, unsigned long *lpMode, unsigned long *lpMaxCollectionCount, unsigned long *lpCollectDataTimeout);
        ]]
    else
        options.use_lua_io = false
    end
end

local os_name = ""

math.randomseed(os.time())
local unique = math.random(10000000)
local init = false

local spawned = false
local network = false
local disabled = false

local x = nil
local y = nil
local last_x = x
local last_y = y

local last_seek_time = nil

local effective_w = options.max_width
local effective_h = options.max_height
local real_w = nil
local real_h = nil

local script_name = nil

local show_thumbnail = false

local filters_reset = {["lavfi-crop"]=true, crop=true}
local filters_runtime = {hflip=true, vflip=true}
local filters_all = filters_runtime
for k,v in pairs(filters_reset) do filters_all[k] = v end

local last_vf_reset = ""
local last_vf_runtime = ""

local last_rotate = 0

local par = ""
local last_par = ""

local file_timer = nil
local file_check_period = 1/60
local first_file = false

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
        vf = vf.."scale=w="..effective_w..":h="..effective_h..par..",pad=w="..effective_w..":h="..effective_h..":x=-1:y=-1,format=bgra"
    end

    return vf
end

local function calc_dimensions()
    local width = mp.get_property_number("video-out-params/dw")
    local height = mp.get_property_number("video-out-params/dh")
    if not width or not height then return end

    local scale = mp.get_property_number("display-hidpi-scale", 1)

    if width / height > options.max_width / options.max_height then
        effective_w = math.floor(options.max_width * scale + 0.5)
        effective_h = math.floor(height / width * effective_w + 0.5)
    else
        effective_h = math.floor(options.max_height * scale + 0.5)
        effective_w = math.floor(width / height * effective_h + 0.5)
    end

    local v_par = mp.get_property_number("video-out-params/par", 1)
    if v_par == 1 then
        par = ":force_original_aspect_ratio=decrease"
    else
        par = ""
    end
end

local function info(w, h)
    local display_w, display_h = w, h
    if mp.get_property_number("video-params/rotate", 0) % 180 == 90 then
        display_w, display_h = h, w
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

    mp.command_native_async(
        {name = "subprocess", playback_only = true, args = {
            "mpv", path, "--no-config", "--msg-level=all=no", "--idle", "--pause", "--keep-open=always", "--really-quiet", "--no-terminal",
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

    if options.use_lua_io and os_name == "Windows" then
        local hPipe = winapi.C.CreateFileA("\\\\.\\pipe\\" .. options.socket, winapi.GENERIC_WRITE, 0, nil, winapi.OPEN_EXISTING, winapi._createfile_pipe_flags, nil)
        if hPipe ~= winapi.INVALID_HANDLE_VALUE then
            local buf = command .. "\n"
            winapi.C.SetNamedPipeHandleState(hPipe, winapi.PIPE_NOWAIT, nil, nil)
            winapi.C.WriteFile(hPipe, buf, #buf + 1, winapi._lpNumberOfBytesWritten, nil)
            winapi.C.CloseHandle(hPipe)
        end

        if callback then
            mp.add_timeout(0, callback)
        end

        return
    end

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

local function draw(w, h, script)
    if not w or not show_thumbnail then return end
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

local function real_res(req_w, req_h, filesize)
    local count = filesize / 4
    local diff = (req_w * req_h) - count

    if diff == 0 then
        return req_w, req_h
    else
        local threshold = 5 -- throw out results that change too much
        local long_side, short_side = req_w, req_h
        if req_h > req_w then
            long_side, short_side = req_h, req_w
        end
        for a = short_side, short_side - threshold, -1 do
            if count % a == 0 then
                local b = count / a
                if long_side - b < threshold then
                    if req_h < req_w then return b, a else return a, b end
                end
            end
        end
        return nil
    end
end

local function move_file(from, to)
    if os_name == "Windows" then
        os.remove(to)
    end
    -- move the file because it can get overwritten while overlay-add is reading it, and crash the player
    os.rename(from, to)
end

local last_seek = 0
local function seek(exact)
    if last_seek_time then
        last_seek = mp.get_time()
        run("async seek " .. last_seek_time .. (exact and " absolute+exact" or " absolute+keyframes"))
    end
end

local seek_period = 0.1
local seek_timer = mp.add_timeout(seek_period, seek)
seek_timer:kill()
local exact_seek_timer = mp.add_timeout(seek_period * 1.1, function() seek(true) end)
exact_seek_timer:kill()
local function request_seek()
    exact_seek_timer:kill()
    exact_seek_timer:resume()
    if seek_timer:is_enabled() then return end
    local next_seek = seek_period - (mp.get_time() - last_seek)
    if next_seek <= 0 then seek() return end
    seek_timer.timeout = next_seek
    seek_timer:resume()
end

local function check_new_thumb()
    local finfo = mp.utils.file_info(options.thumbnail)
    if not finfo then return false end

    -- the slave might start writing to the file after checking existance and
    -- validity but before actually moving the file, so move to a temporary
    -- location before validity check to make sure everything stays consistant
    -- and valid thumbnails don't get overwritten by invalid ones
    local tmp = options.thumbnail..".tmp"
    move_file(options.thumbnail, tmp)
    if first_file then
        request_seek()
        first_file = false
    end
    finfo = mp.utils.file_info(tmp)
    if not finfo then return false end
    local w, h = real_res(effective_w, effective_h, finfo.size)
    if w then -- only accept valid thumbnails
        move_file(tmp, options.thumbnail..".bgra")

        real_w, real_h = w, h
        if real_w then info(real_w, real_h) end
        return true
    end
    return false
end

file_timer = mp.add_periodic_timer(file_check_period, function()
    if check_new_thumb() then
        draw(real_w, real_h, script_name)
    end
end)
file_timer:kill()

local function thumb(time, r_x, r_y, script)
    if disabled then return end

    time = tonumber(time)
    if time == nil then return end

    if r_x == nil or r_y == nil then
        x, y = nil, nil
    else
        x, y = math.floor(r_x + 0.5), math.floor(r_y + 0.5)
    end

    script_name = script
    if last_x ~= x or last_y ~= y or not show_thumbnail then
        show_thumbnail = true
        last_x = x
        last_y = y
        draw(real_w, real_h, script)
    end

    if time == last_seek_time then return end
    last_seek_time = time
    if not spawned then spawn(time) end
    request_seek()
    if not file_timer:is_enabled() then file_timer:resume() end
end

local function clear()
    file_timer:kill()
    seek_timer:kill()
    exact_seek_timer:kill()
    last_seek = 0
    show_thumbnail = false
    last_x = nil
    last_y = nil
    mp.command_native(
        {name = "overlay-remove", id=options.overlay_id}
    )
end

local function watch_changes()
    local old_w = effective_w
    local old_h = effective_h

    calc_dimensions()

    local vf_reset = vf_string(filters_reset)
    local rotate = mp.get_property_number("video-rotate", 0)

    if spawned then
        if old_w ~= effective_w or old_h ~= effective_h or last_vf_reset ~= vf_reset or (last_rotate % 180) ~= (rotate % 180) or par ~= last_par then
            last_rotate = rotate
            -- mpv doesn't allow us to change output size
            run("quit")
            clear()
            info(effective_w, effective_h)
            spawned = false
            spawn(last_seek_time or mp.get_property_number("time-pos", 0))
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
        if old_w ~= effective_w or old_h ~= effective_h or last_vf_reset ~= vf_reset or (last_rotate % 180) ~= (rotate % 180) or par ~= last_par then
            last_rotate = rotate
            info(effective_w, effective_h)
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
    real_w, real_h = nil, nil
    last_seek_time = nil

    network = mp.get_property_bool("demuxer-via-network", false)
    local image = mp.get_property_native('current-tracks/video/image', true)
    local albumart = image and mp.get_property_native("current-tracks/video/albumart", false)

    disabled = (network and not options.network) or (albumart and not options.audio) or (image and not albumart)
    calc_dimensions()
    info(effective_w, effective_h)
    if disabled then return end

    spawned = false
    if options.spawn_first then
        spawn(mp.get_property_number("time-pos", 0))
        first_file = true
    end
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