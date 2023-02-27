local mp = require 'mp'
local utils = require 'mp.utils'
local opt = require 'mp.options'

local o = {
    debug = false,
    -- Path to executable (MPVMediaControl.exe)
    binary_path = "~~/bin/MPVMediaControl.exe",
    -- Path for storing temporary screenshots
    shot_path = "~~/",
    -- If you want to delay taking screenshot for videos, set this to the number of delayed seconds
    delayed_sec = 3,
    -- Name of mpv's input-ipc-server (defaults to mpvsocket_{pid}), string "{pid}" in the value will be automatically replaced with the ID of mpv process
    socket_name = "mpvsocket_{pid}",
}

opt.read_options(o, "notify_media")

o.binary_path = mp.command_native({ "expand-path", o.binary_path })

local pid = utils.getpid()
local start_of_file = true
local new_file = false
local yt_thumbnail = false
local yt_failed = false
local mpv_socket_name = o.socket_name:gsub("{pid}", tostring(pid))
local shot_dir = mp.command_native({ "expand-path", o.shot_path })

--create shot_dir if it doesn't exist
if utils.readdir(shot_dir) == nil then
    local args = { 'powershell', '-NoProfile', '-Command', 'mkdir', string.format("\"%s\"", shot_dir) }
    local res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
    if res.status ~= 0 then
        msg.error("Failed to create shot_path save directory "..shot_dir..". Error: "..(res.error or "unknown"))
        return
    end
end

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent+1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end

function debug_log(message)
    if o.debug then
        if not message then
            print("DEBUG: nil")
            return
        end
        if "table" == type(message) then
            print("DEBUG: ")
            tprint(message)
        else
            print("DEBUG: " .. message)
        end
    end
end

ipc_socket_file = "\\\\.\\pipe\\mpvmcsocket"

function write_to_socket(message)
    _, pipe = pcall(io.open, ipc_socket_file, "w")
    if pipe then
        pcall(pipe.write, pipe, message)
        pcall(pipe.flush, pipe)
        pcall(pipe.close, pipe)
        debug_log(message)
    end
end

function get_metadata(data, keys)
    for _, v in pairs(keys) do
        if data[v] and string.len(data[v]) > 0 then
            return data[v]
        end
    end
    return ""
end

function encode_element(str)
    -- return str:gsub("%(", "\\\\["):gsub("%)", "\\\\]")
    return tohex(str)
end

function tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

function save_shot(path)
    if youtube_thumbail(path) then
        local shot_path_encoded = encode_element(shot_path)
        message_content = "^[setShot](pid=" .. pid .. ")(shot_path=" .. shot_path_encoded .. ")(socket_name=" .. mpv_socket_name .. ")$"
        write_to_socket(message_content)
        return
    end
    if start_of_file and media_type() == "video" and o.delayed_sec ~= 0 then
        mp.add_timeout(o.delayed_sec, function() save_shot(path) end)
        start_of_file = false
        return
    end
    result = mp.commandv("screenshot-to-file", path)
    if not result then
        mp.add_timeout(0.5, function() save_shot(path) end)
    else
        local shot_path_encoded = encode_element(shot_path)
        message_content = "^[setShot](pid=" .. pid .. ")(shot_path=" .. shot_path_encoded .. ")(socket_name=" .. mpv_socket_name .. ")$"
        write_to_socket(message_content)
    end
end

function youtube_thumbail(path)
    if not yt_thumbnail then
        debug_log(mp.get_property("path"))
        if not yt_failed and string.find(mp.get_property("path"), "www.youtube.com") then
        	-- generate a url to the thumbnail file
        	vid_id = mp.get_property("filename")
        	vid_id = string.gsub(vid_id, "watch%?v=", "") -- Strip possible prefix.
        	vid_id = string.sub(vid_id, 1, 11) -- Strip possible suffix.
        	
        	thumb_url = "https://i.ytimg.com/vi/" .. vid_id .. "/maxresdefault.jpg"
        	
        	local dl_process = mp.command_native({
        	    name = "subprocess",
        	    playback_only = true,
        	    args = {"curl", "-L", "-s", "-o", shot_path, thumb_url},
        	})
        	
        	if dl_process.status == 0 then
        	    yt_thumbnail = true
                return true
        	end
        end
        yt_failed = true
        return false
    end
    return true
end

function media_type()
    fps = mp.get_property_native("estimated-vf-fps")

    if fps and fps > 1 then
        return "video"
    else
        return "music"
    end
end

function notify_metadata_updated()
    metadata = mp.get_property_native("metadata")
    debug_log(metadata)
    if not metadata then
        return
    end

    artist = get_metadata(metadata, { "artist", "ARTIST", "Artist" })
    title = get_metadata(metadata, { "title", "TITLE", "Title", "icy-title" })

    if media_type() == "music" and (not artist or artist == "" or not title or title == "") then
        chapter_metadata = mp.get_property_native("chapter-metadata")

        if chapter_metadata then
            chapter_artist = chapter_metadata["performer"]
            if not artist or artist == "" then
                artist = chapter_artist
            end

            chapter_title = chapter_metadata["title"]
            if not title or title == "" then
                title = chapter_title
            end
        end
    end

    if not title or title == "" then
        title = mp.get_property_native("media-title")
    end

    path = mp.get_property_native("path")
    if path:sub(2, 3) ~= ":\\" and path:sub(2, 3) ~= ":/" then
        dir = mp.get_property_native("working-directory")
        path = dir .. "\\" .. path
    end

    if not artist then
        artist = ""
    end

    if title then
        title = encode_element(title)
    end
    if artist then
        artist = encode_element(artist)
    end
    path = encode_element(path)

    shot_path = shot_dir .. "\\" .. pid .. ".jpg"
    if mp.get_property("video-codec") then
        save_shot(shot_path)
    end

    message_content = "^[setFile](pid=" .. pid .. ")(title=" .. title .. ")(artist=" .. artist .. ")(path=" .. path .. ")(type=" .. media_type() .. ")(socket_name=" .. mpv_socket_name .. ")$"
    write_to_socket(message_content)
end

function play_state_changed()
    idle = mp.get_property_native("core-idle")
    is_playing = not idle

    message_content = "^[setState](pid=" .. pid .. ")(playing=" .. tostring(is_playing) .. ")(socket_name=" .. mpv_socket_name .. ")$"
    write_to_socket(message_content)

    if not idle then
        mp.add_timeout(10, play_state_changed)
    end
end

function notify_current_file()
    -- Even all things are right in MPVMediaControl, there may be native crash caused by Windows itself (SHCORE.dll).
    -- This line let mpv run the program again when a new file is loaded, help mitigating the problem.
    -- It won't cost much as MPVMC will not allow multiple instances to be started. But if you don't want this, comment out the line below.
    run_mpvmc_program()
    notify_metadata_updated()
end

function run_mpvmc_program()
    mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = false,
        capture_stderr = false,
        detach = true,
        args = { o.binary_path },
    })
end

mp.set_property("options/input-ipc-server", "\\\\.\\pipe\\" .. mpv_socket_name)

function start_register_event()
    if new_file then
        notify_current_file()
        start_of_file = true
        new_file = false
        yt_thumbnail = false
        yt_failed = false
        mp.observe_property("media-title", nil, notify_metadata_updated)
        mp.observe_property("metadata", nil, notify_metadata_updated)
        mp.observe_property("chapter", nil, notify_metadata_updated)
        mp.register_event("end-file", play_state_changed)
        mp.observe_property("core-idle", nil, play_state_changed)
    end
end

mp.register_event("file-loaded", function() new_file = true end)
mp.register_event("playback-restart", start_register_event)

function on_quit()
    if shot_path then
        os.remove(shot_path)
    end
    write_to_socket("^[setQuit](pid=" .. pid .. ")(quit=true)(socket_name=" .. mpv_socket_name .. ")$")
end

mp.register_event("shutdown", on_quit)
