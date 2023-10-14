-- youtube-download.lua
--
-- Download video/audio from youtube via youtube-dl and ffmpeg/avconv
-- This is forked/based on https://github.com/jgreco/mpv-youtube-quality
--
-- Video download bound to ctrl-d by default.
-- Audio download bound to ctrl-a by default.

-- Requires youtube-dl in PATH for video download
-- Requires ffmpeg or avconv in PATH for audio download

local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

local opts = {
    -- Key bindings
    -- Set to empty string "" to disable
    download_video_binding = "ctrl+d",
    download_audio_binding = "ctrl+a",
    download_subtitle_binding = "ctrl+s",
    download_video_embed_subtitle_binding = "ctrl+i",
    select_range_binding = "ctrl+r",
    download_mpv_playlist = "",

    -- Specify audio format: "best", "aac","flac", "mp3", "m4a", "opus", "vorbis", or "wav"
    audio_format = "mp3",

    -- Specify ffmpeg/avconv audio quality
    -- insert a value between 0 (better) and 9 (worse) for VBR or a specific bitrate like 128K
    audio_quality = "0",

    -- Embed the thumbnail on audio files
    embed_thumbnail = false,

    -- Add metadata to audio files
    audio_add_metadata = false,

    -- Add metadata to video files
    video_add_metadata = false,

    -- Same as youtube-dl --format FORMAT
    -- see https://github.com/ytdl-org/youtube-dl/blob/master/README.md#format-selection
    -- set to "current" to download the same quality that is currently playing
    video_format = "",

    -- Remux the video into another container if necessary: "avi", "flv",
    -- "gif", "mkv", "mov", "mp4", "webm", "aac", "aiff", "alac", "flac",
    -- "m4a", "mka", "mp3", "ogg", "opus", "vorbis", "wav"
    remux_video = "",

    -- Encode the video to another format if necessary: "mp4", "flv", "ogg", "webm", "mkv", "avi"
    recode_video = "",

    -- Restrict filenames to only ASCII characters, and avoid "&" and spaces in filenames
    restrict_filenames = true,

    -- Download the whole Youtube playlist (false) or only one video (true)
    -- Same as youtube-dl --no-playlist
    no_playlist = true,

    -- Download the whole mpv playlist (true) or only the current video (false)
    -- This is the default setting, it can be overwritten with the download_mpv_playlist key binding
    mpv_playlist = false,

    -- Use an archive file, see youtube-dl --download-archive
    -- You have these options:
    --  * Set to empty string "" to not use an archive file
    --  * Set an absolute path to use one archive for all downloads e.g. download_archive="/home/user/archive.txt"
    --  * Set a relative path/only a filename to use one archive per directory e.g. download_archive="archive.txt"
    --  * Use $PLAYLIST to create one archive per playlist e.g. download_archive="/home/user/archives/$PLAYLIST.txt"
    download_archive = "",

    -- Use a cookies file for youtube-dl
    -- Same as youtube-dl --cookies
    -- On Windows you need to use a double blackslash or a single fordwardslash
    -- For example "C:\\Users\\Username\\cookies.txt"
    -- Or "C:/Users/Username/cookies.txt"
    cookies = "",

    -- Set '/:dir%mpvconf%' to use mpv config directory to download
    -- OR change to '/:dir%script%' for placing it in the same directory of script
    -- OR change to '~~/ytdl/download' for sub-path of mpv portable_config directory
    -- OR write any variable using '/:var', such as: '/:var%APPDATA%/mpv/ytdl/download' or '/:var%HOME%/mpv/ytdl/download'
    -- OR specify the absolute path, such as: "C:\\Users\\UserName\\Downloads"
    -- OR leave empty "" to use the current working directory
    download_path = "/:dir%mpvconf%/ytdl/download",

    -- Filename format to download file
    -- see https://github.com/ytdl-org/youtube-dl/blob/master/README.md#output-template
    -- For example: "%(title)s.%(ext)s"
    filename = "%(title)s.%(ext)s",

    -- Subtitle language
    -- Same as youtube-dl --sub-lang en
    sub_lang = "en",

    -- Subtitle format
    -- Same as youtube-dl --sub-format best
    sub_format = "best",

    -- Download auto-generated subtitles
    -- Same as youtube-dl --write-auto-subs / --no-write-auto-subs
    sub_auto_generated = false,

    -- Log file for download errors
    log_file = "",

    -- Executable of youtube-dl to use, e.g. "youtube-dl", "yt-dlp" or
    -- path to the executable file
    -- Set to "" to auto-detect the executable
    youtube_dl_exe = "yt-dlp",

    -- Use a config file, see youtube-dl --config-location, instead of
    -- the usual options for this keyboard shortcut. This way you can
    -- overwrite the predefined behaviour of the keyboard shortcut and
    -- all of the above options with a custom download behaviour defined
    -- in each config file.
    -- Set to "" to retain the predefined behaviour
    download_video_config_file = "",
    download_audio_config_file = "",
    download_subtitle_config_file = "",
    download_video_embed_subtitle_config_file= "",

    -- Open a new "Windows Terminal" window/tab for download
    -- This allows you to monitor the download progress
    -- Currently only works on Windows with the new wt terminal
    -- If open_new_terminal_autoclose is true, then the terminal window
    -- will close after the download, even if there were errors
    -- If mpv_playlist is true and the whole mpv playlist should be
    -- downloaded, then all the downloads are scheduled immediately.
    -- Before each download is started, the script waits the given
    -- timeout in seconds
    open_new_terminal = false,
    open_new_terminal_autoclose = false,
    open_new_terminal_timeout = 3,

    -- Used to localize uosc-submenu content
    -- Must use json format, example for Chinese: [{"Download": "下载","Audio": "音频"}]
    locale_content = [[
        []
    ]],
}

local function table_size(t)
    local s = 0
    for _, _ in pairs(t) do
        s = s + 1
    end
    return s
end

local function exec(args, capture_stdout, capture_stderr)
    local ret = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = capture_stdout,
        capture_stderr = capture_stderr,
        args = args,
    })
    return ret.status, ret.stdout, ret.stderr, ret
end

local function exec_async(args, capture_stdout, capture_stderr, callback)
    return mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        capture_stdout = capture_stdout,
        capture_stderr = capture_stderr,
        args = args,
    }, callback)
end

local function trim(str)
    return str:gsub("^%s+", ""):gsub("%s+$", "")
end

local function not_empty(str)
    if str == nil or str == "" then
        return false
    end
    return trim(str) ~= ""
end

local function path_separator()
    return package.config:sub(1,1)
end

local function path_join(...)
    return table.concat({...}, path_separator())
end

local function get_current_format()
    -- get the current youtube-dl format or the default value
    local ytdl_format = mp.get_property("options/ytdl-format")
    if not_empty(ytdl_format) then
        return ytdl_format
    end
    ytdl_format = mp.get_property("ytdl-format")
    if not_empty(ytdl_format) then
        return ytdl_format
    end
    return "bestvideo+bestaudio/best"
end


--Read configuration file
(require 'mp.options').read_options(opts, "youtube-download")

--Read text string
local locale_content = utils.parse_json(opts.locale_content)

local function locale(str)
    if str and locale_content then
        for k, v in ipairs(locale_content) do
            return v[str] or str
        end
    end
    return str
end

--Read command line arguments
local ytdl_raw_options = mp.get_property("ytdl-raw-options")
if ytdl_raw_options ~= nil and ytdl_raw_options:find("cookies=") ~= nil then
    local cookie_file = ytdl_raw_options:match("cookies=([^,]+)")
    if cookie_file ~= nil then
        opts.cookies = cookie_file
    end
end

--Try to detect youtube-dl/yt-dlp executable
local executables = {"yt-dlp", "youtube-dl", "yt-dlp_x86", "yt-dlp_macos", "yt-dlp_min", "yt-dlc"}
local function detect_executable()
    local function detect_executable_callback(success, ret, _)
        if not success or ret.status ~= 0 then
            detect_executable()
        else
            msg.debug("Found working executable " .. opts.youtube_dl_exe)
        end
    end
    opts.youtube_dl_exe = table.remove(executables, 1)
    if opts.youtube_dl_exe ~= nil then
        msg.debug("Trying executable '" .. opts.youtube_dl_exe .. "' ...")
        exec_async({opts.youtube_dl_exe, "--version"}, false, false, detect_executable_callback)
    else
        msg.error("No working executable found, using fallback 'youtube-dl'")
        opts.youtube_dl_exe = "youtube-dl"
    end
end

if not not_empty(opts.youtube_dl_exe) then
    msg.debug("Trying to detect executable...")
    detect_executable()
end

if opts.download_path:match('^/:dir%%mpvconf%%') then
    opts.download_path = opts.download_path:gsub('/:dir%%mpvconf%%', mp.find_config_file('.'))
elseif opts.download_path:match('^/:dir%%script%%') then
    opts.download_path = opts.download_path:gsub('/:dir%%script%%', mp.find_config_file('scripts'))
elseif opts.download_path:match('^/:var%%(.*)%%') then
    local os_variable = opts.download_path:match('/:var%%(.*)%%')
    opts.download_path = opts.download_path:gsub('/:var%%(.*)%%', os.getenv(os_variable))
elseif opts.download_path:match('^~') then
    opts.download_path = mp.command_native({ "expand-path", opts.download_path })  -- Expands both ~ and ~~
end

--create opts.download_path if it doesn't exist
if not_empty(opts.download_path) and utils.readdir(opts.download_path) == nil then
    local is_windows = package.config:sub(1, 1) == "\\"
    local windows_args = { 'powershell', '-NoProfile', '-Command', 'mkdir', string.format("\"%s\"", opts.download_path) }
    local unix_args = { 'mkdir', '-p', opts.download_path }
    local args = is_windows and windows_args or unix_args
    local res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
    if res.status ~= 0 then
        msg.error("Failed to create youtube-download save directory "..opts.download_path..". Error: "..(res.error or "unknown"))
        return
    end
end

local DOWNLOAD = {
    VIDEO=1,
    AUDIO=2,
    SUBTITLE=3,
    VIDEO_EMBED_SUBTITLE=4,
    CONFIG_FILE=5
}
local select_range_mode = 0
local start_time_seconds = nil
local start_time_formated = nil
local end_time_seconds = nil
local end_time_formated = nil

local switches = {
    mpv_playlist_toggle = opts.mpv_playlist,
}
local mpv_playlist_status = nil
local is_downloading = false
local process_id = nil
local should_cancel = false
local was_cancelled = false

local script_name = mp.get_script_name()

local function disable_select_range()
    -- Disable range mode
    select_range_mode = 0
    -- Remove the arrow key key bindings
    mp.remove_key_binding("select-range-set-up")
    mp.remove_key_binding("select-range-set-down")
    mp.remove_key_binding("select-range-set-left")
    mp.remove_key_binding("select-range-set-right")
end

local function download(download_type, config_file, overwrite_opts)
    if switches.mpv_playlist_toggle and mpv_playlist_status == nil then
        -- Start downloading the whole mpv playlist
        local playlist_length = mp.get_property_number('playlist-count', 0)
        if playlist_length == 0 then
            mpv_playlist_status = nil
            mp.osd_message("Download failed: mpv playlist is empty", 5)
            return
        end

        -- Store current playlist
        mpv_playlist_status = {}
        local i = 0
        while i < playlist_length do
          local url = mp.get_property('playlist/'..i..'/filename')
          if url ~= nil and (url:find("ytdl://") == 1 or url:find("https?://") == 1) then
            mpv_playlist_status[url] = false
          end
          i = i + 1
        end
    end

    local video_format = opts.video_format
    if overwrite_opts ~= nil then
        if overwrite_opts.video_format ~= nil  then
            video_format = overwrite_opts.video_format
        end
    end

    local start_time = os.date("%c")
    if is_downloading then
        if process_id ~= nil and should_cancel then
            -- cancel here
            mp.osd_message("Canceling download ...", 3)
            was_cancelled = true
            mp.abort_async_command(process_id)
            should_cancel = false
        elseif process_id ~= nil then
            should_cancel = true
            mp.osd_message("Download in progress. Press again to cancel download", 5)
        end
        return
    end
    is_downloading = true
    should_cancel = false
    was_cancelled = false

    local ass0 = mp.get_property("osd-ass-cc/0")
    local ass1 =  mp.get_property("osd-ass-cc/1")

    local mpv_playlist_i = 0
    local mpv_playlist_n = 0
    local url = nil
    if mpv_playlist_status ~= nil then
        for key, value in pairs(mpv_playlist_status) do
            if not value then
                if url == nil then
                    url = key
                end
            else
                mpv_playlist_i = mpv_playlist_i + 1
            end
            mpv_playlist_n = mpv_playlist_n + 1
        end

        if url == nil then
            local n = table_size(mpv_playlist_status)
            mpv_playlist_status = nil
            mp.osd_message("Finished downloading mpv playlist (".. tostring(n) .. " entries)", 5)
            return
        end
    else
        url = mp.get_property("path")
    end

    if url:find("ytdl://") ~= 1 and url:find("https?://") ~= 1
    then
        mp.osd_message("Not a youtube URL: " .. tostring(url), 10)
        is_downloading = false
        return
    end

    url = string.gsub(url, "ytdl://", "") -- Strip possible ytdl:// prefix.

    local list_match = url:match("list=(%w+)")
    local download_archive = opts.download_archive
    if list_match ~= nil and opts.download_archive ~= nil and opts.download_archive:find("$PLAYLIST", 1, true) then
        download_archive = opts.download_archive:gsub("$PLAYLIST", list_match)
    end

    if download_type == DOWNLOAD.CONFIG_FILE then
        mp.osd_message("Download started\n" .. ass0 .. "{\\fs8}--config-location:\n'" .. config_file .. "'" .. ass1, 2)
    elseif download_type == DOWNLOAD.AUDIO then
        mp.osd_message("Audio download started", 2)
    elseif download_type == DOWNLOAD.SUBTITLE then
        mp.osd_message("Subtitle download started", 2)
    elseif download_type == DOWNLOAD.VIDEO_EMBED_SUBTITLE then
        mp.osd_message("Video w/ subtitle download started", 2)
    else
        mp.osd_message("Video download started", 2)
    end

    local filepath = opts.filename
    if not_empty(opts.download_path) then
        filepath = opts.download_path .. "/" .. filepath
    end

    -- Compose command line arguments
    local command = {}

    local range_mode_file_name = nil
    local range_mode_subtitle_file_name = nil
    local start_time_offset = 0

    if download_type == DOWNLOAD.CONFIG_FILE then
        table.insert(command, opts.youtube_dl_exe)
        table.insert(command, "--config-location")
        table.insert(command, config_file)
        table.insert(command, url)
    elseif select_range_mode == 0 or (select_range_mode > 0 and (download_type == DOWNLOAD.AUDIO or download_type == DOWNLOAD.SUBTITLE)) then
        table.insert(command, opts.youtube_dl_exe)
        table.insert(command, "--no-overwrites")
        if opts.restrict_filenames then
          table.insert(command, "--restrict-filenames")
        end
        if not_empty(filepath) then
            table.insert(command, "-o")
            table.insert(command, filepath)
        end
        if opts.no_playlist then
            table.insert(command, "--no-playlist")
        end
        if not_empty(download_archive) then
            table.insert(command, "--download-archive")
            table.insert(command, download_archive)
        end

        if download_type == DOWNLOAD.SUBTITLE then
            table.insert(command, "--sub-lang")
            table.insert(command, opts.sub_lang)
            table.insert(command, "--write-sub")
            table.insert(command, "--skip-download")
            if not_empty(opts.sub_format) then
                table.insert(command, "--sub-format")
                table.insert(command, opts.sub_format)
            end
            if opts.sub_auto_generated then
                table.insert(command, "--write-auto-subs")
            else
                table.insert(command, "--no-write-auto-subs")
            end
            if select_range_mode > 0 then
                mp.osd_message("Range mode is not available for subtitle-only download", 10)
                is_downloading = false
                return
            end
        elseif download_type == DOWNLOAD.AUDIO then
            table.insert(command, "--extract-audio")
            if not_empty(opts.audio_format) then
              table.insert(command, "--audio-format")
              table.insert(command, opts.audio_format)
            end
            if not_empty(opts.audio_quality) then
              table.insert(command, "--audio-quality")
              table.insert(command, opts.audio_quality)
            end
            if opts.embed_thumbnail then
              table.insert(command, "--embed-thumbnail")
            end
            if opts.audio_add_metadata then
              table.insert(command, "--add-metadata")
            end
            if  select_range_mode > 0 then
                local start_time_str = tostring(start_time_seconds)
                local end_time_str = tostring(end_time_seconds)
                table.insert(command, "--external-downloader")
                table.insert(command, "ffmpeg")
                table.insert(command, "--external-downloader-args")
                table.insert(command, "-loglevel warning -nostats -hide_banner -ss ".. start_time_str .. " -to " .. end_time_str .. " -avoid_negative_ts make_zero")
            end
        else --DOWNLOAD.VIDEO or DOWNLOAD.VIDEO_EMBED_SUBTITLE
            if download_type == DOWNLOAD.VIDEO_EMBED_SUBTITLE then
                table.insert(command, "--embed-subs")
                table.insert(command, "--sub-lang")
                table.insert(command, opts.sub_lang)
                if not_empty(opts.sub_format) then
                    table.insert(command, "--sub-format")
                    table.insert(command, opts.sub_format)
                end
                if opts.sub_auto_generated then
                    table.insert(command, "--write-auto-subs")
                else
                    table.insert(command, "--no-write-auto-subs")
                end
            end
            if not_empty(video_format) then
              table.insert(command, "--format")
              if video_format == "current" then
                table.insert(command, get_current_format())
              else
                table.insert(command, video_format)
              end
            end
            if not_empty(opts.remux_video) then
              table.insert(command, "--remux-video")
              table.insert(command, opts.remux_video)
            end
            if not_empty(opts.recode_video) then
              table.insert(command, "--recode-video")
              table.insert(command, opts.recode_video)
            end
            if opts.video_add_metadata then
              table.insert(command, "--add-metadata")
            end
        end
        if not_empty(opts.cookies) then
            table.insert(command, "--cookies")
            table.insert(command, opts.cookies)
        end
        table.insert(command, url)

    elseif select_range_mode > 0 and
        (download_type == DOWNLOAD.VIDEO or download_type == DOWNLOAD.VIDEO_EMBED_SUBTITLE) then

        -- Show download indicator
        mp.set_osd_ass(0, 0, "{\\an9}{\\fs12}⌛🔗")

        start_time_seconds = math.floor(start_time_seconds)
        end_time_seconds = math.ceil(end_time_seconds)

        local start_time_str = tostring(start_time_seconds)
        local end_time_str = tostring(end_time_seconds)

        -- Add time to the file name of the video
        local filename_format
        -- Insert start time/end time
        if not_empty(filepath) then
            if filepath:find("%%%(start_time%)") ~= nil then
                -- Found "start_time" -> replace it
                filename_format = tostring(filepath:
                    gsub("%%%(start_time%)[^diouxXeEfFgGcrs]*[diouxXeEfFgGcrs]", start_time_str):
                    gsub("%%%(end_time%)[^diouxXeEfFgGcrs]*[diouxXeEfFgGcrs]", end_time_str))
            else
                local ext_pattern = "%(ext)s"
                if filepath:sub(-#ext_pattern) == ext_pattern then
                    -- Insert before ext
                    filename_format = filepath:sub(1, #(filepath) - #ext_pattern) ..
                        start_time_str .. "-" ..
                        end_time_str .. ".%(ext)s"
                else
                    -- append at end
                    filename_format = filepath .. start_time_str .. "-" .. end_time_str
                end
            end
        else
            -- default youtube-dl filename pattern
            filename_format = "%(title)s-%(id)s." .. start_time_str .. "-" .. end_time_str .. ".%(ext)s"
        end

        -- Find a suitable format
        local format = "bestvideo[ext*=mp4]+bestaudio/best[ext*=mp4]/best"
        local requested_format = video_format
        if requested_format == "current" then
            requested_format = get_current_format()
        end
        if requested_format == nil or requested_format == "" then
            format = format
        elseif requested_format == "best" then
            -- "best" works, because its a single file stream
            format = "best"
        elseif requested_format:find("mp4") ~= nil then
            -- probably a mp4 format, so use it
            format = requested_format
        else
            -- custom format, no "mp4" found -> use default
            msg.warn("Select range mode requires a .mp4 format or \"best\", found "  ..
            requested_format .. "\n(" .. video_format .. ")" ..
                    "\nUsing default format instead: " .. format)
        end

        -- Get the download url of the video file
        -- e.g.: youtube-dl -g -f bestvideo[ext*=mp4]+bestaudio/best[ext*=mp4]/best -s --get-filename https://www.youtube.com/watch?v=abcdefg
        command = {opts.youtube_dl_exe}
        if opts.restrict_filenames then
            table.insert(command, "--restrict-filenames")
        end
        if not_empty(opts.cookies) then
            table.insert(command, "--cookies")
            table.insert(command, opts.cookies)
        end
        table.insert(command, "-g")
        table.insert(command, "--no-playlist")
        table.insert(command, "-f")
        table.insert(command, format)
        table.insert(command, "-o")
        table.insert(command, filename_format)
        table.insert(command, "-s")
        table.insert(command, "--get-filename")
        table.insert(command, url)

        msg.debug("info exec: " .. table.concat(command, " "))
        local info_status, info_stdout, info_stderr = exec(command, true, true)
        if info_status ~= 0 then
            mp.set_osd_ass(0, 0, "")
            mp.osd_message("Could not retieve download stream url: status=" .. tostring(info_status) .. "\n" ..
                ass0 .. "{\\fs8} " .. info_stdout:gsub("\r", "") .."\n" .. info_stderr:gsub("\r", "") .. ass1, 20)
            msg.debug("info_stdout:\n" .. info_stdout)
            msg.debug("info_stderr:\n" .. info_stderr)
            mp.set_osd_ass(0, 0, "")
            is_downloading = false
            return
        end

        -- Split result into lines
        local info_lines = {}
        local last_index = 0
        local info_lines_N = 0
        while true do
            local start_i, end_i = info_stdout:find("\n", last_index, true)
            if start_i then
                local line = tostring(trim(info_stdout:sub(last_index, start_i)))
                if line ~= "" then
                    table.insert(info_lines, line)
                    info_lines_N = info_lines_N + 1
                end
            else
                break
            end
            last_index = end_i + 1
        end

        if info_lines_N < 2 then
            mp.set_osd_ass(0, 0, "")
            mp.osd_message("Could not extract download stream urls and filename from output\n" ..
                ass0 .. "{\\fs8} " .. info_stdout:gsub("\r", "") .."\n" .. info_stderr:gsub("\r", "") .. ass1, 20)
            msg.debug("info_stdout:\n" .. info_stdout)
            msg.debug("info_stderr:\n" .. info_stderr)
            mp.set_osd_ass(0, 0, "")
            is_downloading = false
            return
        end
        range_mode_file_name = info_lines[info_lines_N]
        table.remove(info_lines)

        if download_type == DOWNLOAD.VIDEO_EMBED_SUBTITLE then
            -- youtube-dl --write-sub --skip-download  https://www.youtube.com/watch?v=abcdefg -o "temp.%(ext)s"
            command = {opts.youtube_dl_exe, "--write-sub", "--skip-download", "--sub-lang", opts.sub_lang}
            if not_empty(opts.sub_format) then
                table.insert(command, "--sub-format")
                table.insert(command, opts.sub_format)
            end
            if opts.sub_auto_generated then
                table.insert(command, "--write-auto-subs")
            else
                table.insert(command, "--no-write-auto-subs")
            end
            local randomName = "tmp_" .. tostring(math.random())
            table.insert(command, "-o")
            table.insert(command, randomName .. ".%(ext)s")
            table.insert(command, url)

            -- Start subtitle download
            msg.debug("exec: " .. table.concat(command, " "))
            local subtitle_status, subtitle_stdout, subtitle_stderr = exec(command, true, true)
            if subtitle_status == 0 and subtitle_stdout:find(randomName) then
                local i, j = subtitle_stdout:find(randomName .. "[^\n]+")
                range_mode_subtitle_file_name = trim(subtitle_stdout:sub(i, j))
                if range_mode_subtitle_file_name ~= "" then
                    if range_mode_file_name:sub(-4) ~= ".mkv" then
                        -- Only mkv supports all kinds of subtitle formats
                        range_mode_file_name = range_mode_file_name:sub(1,-4) .. "mkv"
                    end
                end
            else
                mp.osd_message("Could not find a suitable subtitle")
                msg.debug("subtitle_stdout:\n" .. subtitle_stdout)
                msg.debug("subtitle_stderr:\n" .. subtitle_stderr)
            end

        end

        -- Download earlier (cut off afterwards)
        start_time_offset = math.min(15, start_time_seconds)
        start_time_seconds = start_time_seconds - start_time_offset

        start_time_str = tostring(start_time_seconds)
        end_time_str = tostring(end_time_seconds)

        command = {"ffmpeg", "-loglevel", "warning", "-nostats", "-hide_banner", "-y"}
        for _, value in ipairs(info_lines) do
            table.insert(command, "-ss")
            table.insert(command, start_time_str)
            table.insert(command, "-to")
            table.insert(command, end_time_str)
            table.insert(command, "-i")
            table.insert(command, value)
        end
        if not_empty(range_mode_subtitle_file_name) then
            table.insert(command, "-ss")
            table.insert(command, start_time_str)
            table.insert(command, "-i")
            table.insert(command, range_mode_subtitle_file_name)
            table.insert(command, "-to") -- To must be after input for subtitle
            table.insert(command, end_time_str)
        end
        table.insert(command, "-c")
        table.insert(command, "copy")
        table.insert(command, range_mode_file_name)

        disable_select_range()
    end

    -- Show download indicator
    if mpv_playlist_n > 0 then
        mp.set_osd_ass(0, 0, "{\\an9}{\\fs12}" .. tostring(mpv_playlist_i) .."/" .. tostring(mpv_playlist_n) .. "⌛💾")
    else
      mp.set_osd_ass(0, 0, "{\\an9}{\\fs12}⌛💾")
    end

    -- Callback
    local function download_ended(success, ret, error)
        if mpv_playlist_status ~= nil then
            mpv_playlist_status[url] = true
        end

        local playlist_finished = -1
        if mpv_playlist_status ~= nil then
            local to_do = false
            for _, value in pairs(mpv_playlist_status) do
                if not value then
                    to_do = true
                    break
                end
            end
            if not to_do then
                playlist_finished = table_size(mpv_playlist_status)
                mpv_playlist_status = nil
            end
        end

        process_id = nil
        if opts.open_new_terminal then
            is_downloading = false
            -- Hide download indicator
            mp.set_osd_ass(0, 0, "")

            -- Start next download if downloading whole mpv playlist
            if playlist_finished ~= -1 then
                mp.osd_message("Started last download of mpv playlist (".. tostring(playlist_finished) .. " entries)", 5)
            elseif mpv_playlist_status ~= nil then
                -- Wait a short time starting the next download
                -- otherwise wt.exe will stop the previous command and not open a new tab
                local n = opts.open_new_terminal_timeout
                if n == nil or n < 1 then
                    n = 1
                end
                exec({"ping", "-n", tostring(n), "localhost"}, false, false)
                download(download_type, config_file, overwrite_opts)
            end
            return
        end

        local stdout = ret.stdout
        local stderr = ret.stderr
        local status = ret.status

        if status == 0 and range_mode_file_name ~= nil then
            mp.set_osd_ass(0, 0, "{\\an9}{\\fs12}⌛🔨")

            -- Cut first few seconds to fix errors
            local start_time_offset_str = tostring(start_time_offset)
            if #start_time_offset_str == 1 then
                start_time_offset_str = "0" .. start_time_offset_str
            end
            local max_length = end_time_seconds - start_time_seconds + start_time_offset + 12
            local tmp_file_name = range_mode_file_name .. ".tmp." .. range_mode_file_name:sub(-3)
            command = {"ffmpeg", "-loglevel", "warning", "-nostats", "-hide_banner", "-y",
                "-i", range_mode_file_name, "-ss", "00:00:" .. start_time_offset_str,
                "-c", "copy", "-avoid_negative_ts", "make_zero", "-t", tostring(max_length), tmp_file_name}
            msg.debug("mux exec: " .. table.concat(command, " "))
            local muxstatus, muxstdout, muxstderr = exec(command, true, true)
            if muxstatus ~= 0 and not_empty(muxstderr) then
                msg.warn("Remux log:" .. tostring(muxstdout))
                msg.warn("Remux errorlog:" .. tostring(muxstderr))
            end
            if muxstatus == 0 then
                os.remove(range_mode_file_name)
                os.rename(tmp_file_name, range_mode_file_name)
                if not_empty(range_mode_subtitle_file_name) then
                    os.remove(range_mode_subtitle_file_name)
                end
            end

        end


        is_downloading = false

        -- Hide download indicator
        mp.set_osd_ass(0, 0, "")

        local wrote_error_log = false
        if stderr ~= nil and not_empty(opts.log_file) and not_empty(stderr) then
            -- Write stderr to log file
            local title = mp.get_property("media-title")
            local file = io.open (opts.log_file , "a+")
            file:write("\n[")
            file:write(start_time)
            file:write("] ")
            file:write(url)
            file:write("\n[\"")
            file:write(title)
            file:write("\"]\n")
            file:write(stderr)
            file:close()
            wrote_error_log = true
        end

        -- Retrieve the file name
        local filename = nil
        if range_mode_file_name == nil and stdout then
            local i, j, last_i, start_index = 0
            while i ~= nil do
                last_i, start_index = i, j
                i, j = stdout:find ("Destination: ",j, true)
            end

            if last_i ~= nil then
              local end_index = stdout:find ("\n", start_index, true)
              if end_index ~= nil and start_index ~= nil then
                filename = trim(stdout:sub(start_index, end_index))
               end
            end
        elseif not_empty(range_mode_file_name) then
            filename = range_mode_file_name
        end

        if (status ~= 0) then
            if was_cancelled then
                mp.osd_message("Download cancelled!", 2)
                if filename ~= nil then
                    os.remove(filename .. '.part')
                end
            elseif download_type == DOWNLOAD.CONFIG_FILE and stderr:find("config") ~= nil then
                local start_index = stderr:find("config")
                local end_index = stderr:find ("\n", start_index, true)
                local osd_text = ass0 .. "{\\fs12} " .. stderr:sub(start_index - 7, end_index) .. ass1
                mp.osd_message("Config file problem:\n" .. osd_text, 10)
            else
                mp.osd_message("download failed:\n" .. tostring(stderr), 10)
            end
            msg.error("URL: " .. tostring(url))
            msg.error("Return status code: " .. tostring(status))
            msg.debug(tostring(stdout))
            msg.warn(tostring(stderr))
            return
        end

        if string.find(stdout, "has already been recorded in archive") ~=nil then
            mp.osd_message("Has already been recorded in archive", 5)
            return
        end

        local osd_text = "Download succeeded\n"
        local osd_time = 5
        -- Find filename or directory
        if filename then
            local filepath_display
            local basepath
            if filename:find("/") == nil and filename:find("\\") == nil then
              basepath = utils.getcwd()
              filepath_display = path_join(utils.getcwd(), filename)
            else
              basepath = ""
              filepath_display = filename
            end

            if filepath_display:len() < 100 then
                osd_text = osd_text .. ass0 .. "{\\fs12} " .. filepath_display .. " {\\fs20}" .. ass1
            elseif basepath == "" then
                osd_text = osd_text .. ass0 .. "{\\fs8} " .. filepath_display .. " {\\fs20}" .. ass1
            else
                osd_text = osd_text .. ass0 .. "{\\fs11} " .. basepath .. "\n" .. filename .. " {\\fs20}" ..  ass1
            end
            if wrote_error_log then
                -- Write filename and end time to log file
                local file = io.open (opts.log_file , "a+")
                file:write("[" .. filepath_display .. "]\n")
                file:write(os.date("[end %c]\n"))
                file:close()
            end
        else
            if wrote_error_log then
                -- Write directory and end time to log file
                local file = io.open (opts.log_file , "a+")
                file:write("[" .. utils.getcwd() .. "]\n")
                file:write(os.date("[end %c]\n"))
                file:close()
            end
            osd_text = osd_text .. utils.getcwd()
        end

        -- Show warnings
        if not_empty(stderr) then
            msg.warn("Errorlog:" .. tostring(stderr))
            if stderr:find("incompatible for merge") == nil then
                local i = stderr:find("Input #")
                if i ~= nil then
                    stderr = stderr:sub(i)
                end
                osd_text = osd_text .. "\n" .. ass0 .. "{\\fs8} " .. stderr:gsub("\r", "") .. ass1
                osd_time = osd_time + 5
            end
        end

        if playlist_finished ~= -1 then
            osd_text = osd_text .. "\nFinished downloading mpv playlist (".. tostring(playlist_finished) .. " entries)"
        elseif mpv_playlist_status ~= nil then
            download(download_type, config_file, overwrite_opts)
        end

        mp.osd_message(osd_text, osd_time)
    end

    -- Start download
    msg.debug("exec (async): " .. table.concat(command, " "))

    if opts.open_new_terminal then
        mp.osd_message(table.concat(command, " "), 3)

        -- Check working directory is writable (in case the filename does not specify a directory)
        local cwd = utils.getcwd()
        local win_programs = "C:\\Program Files"
        local win_win = "C:\\Windows"
        if cwd:lower():sub(1, #win_programs) == win_programs:lower() or cwd:lower():sub(1, #win_win) == win_win:lower() then
           msg.debug("The mpv working directory ('" ..cwd .."') is probably not writable. Trying %USERPROFILE%...")
           local user_profile = os.getenv("USERPROFILE")
           if  user_profile ~= nil then
                cwd = user_profile
           else
                msg.warn("open_new_terminal is enabled, but %USERPROFILE% is not defined")
                mp.osd_message("open_new_terminal is enabled, but %USERPROFILE% is not defined", 3)
           end
        end

        -- Escape restricted characters on Windows
        local restricted = "&<>|"
        for key, value in ipairs(command) do
            command[key] = value:gsub("["..  restricted .. "]", "^%0")
        end

        -- Prepend command with wt.exe
        table.insert(command, 1, "wt")
        table.insert(command, 2, "-w")
        table.insert(command, 3, "ytdlp")
        table.insert(command, 4, "new-tab")
        table.insert(command, 5, "-d")
        table.insert(command, 6, cwd)
        table.insert(command, 7, "cmd")
        if opts.open_new_terminal_autoclose then
            table.insert(command, 8, "/C")
        else
            table.insert(command, 8, "/K")
        end
        msg.debug("exec (async): " .. table.concat(command, " "))
    end

    process_id = exec_async(command, true, true, download_ended)

end

local function select_range_show()
    local status
    if select_range_mode > 0 then
        if select_range_mode == 2 then
            status = "Download range: Fine tune\n← → start time\n↓ ↑ end time\n" ..
                tostring(opts.select_range_binding) .. " next mode"
        elseif select_range_mode == 1 then
            status = "Download range: Select interval\n← start here\n→ end here\n↓from beginning\n↑til end\n" ..
                tostring(opts.select_range_binding) .. " next mode"
        end
        mp.osd_message("Start: " .. start_time_formated .. "\nEnd:  " .. end_time_formated .. "\n" .. status, 30)
    else
        status = "Download range: Disabled (download full length)"
        mp.osd_message(status, 3)
    end
end

local function select_range_set_left()
    if select_range_mode == 2 then
        start_time_seconds = math.max(0, start_time_seconds - 1)
        if start_time_seconds < 86400 then
            start_time_formated = os.date("!%H:%M:%S", start_time_seconds)
        else
            start_time_formated = tostring(start_time_seconds) .. "s"
        end
    elseif select_range_mode == 1 then
        start_time_seconds = mp.get_property_number("time-pos")
        start_time_formated = mp.command_native({"expand-text","${time-pos}"})
    end
    select_range_show()
end

local function select_range_set_start()
    if select_range_mode == 2 then
        end_time_seconds = math.max(1, end_time_seconds - 1)
        if end_time_seconds < 86400 then
            end_time_formated = os.date("!%H:%M:%S", end_time_seconds)
        else
            end_time_formated = tostring(end_time_seconds) .. "s"
        end
    elseif select_range_mode == 1 then
        start_time_seconds = 0
        start_time_formated = "00:00:00"
    end
    select_range_show()
end

local function select_range_set_end()
    if select_range_mode == 2 then
        end_time_seconds = math.min(mp.get_property_number("duration"), end_time_seconds + 1)
        if end_time_seconds < 86400 then
            end_time_formated = os.date("!%H:%M:%S", end_time_seconds)
        else
            end_time_formated = tostring(end_time_seconds) .. "s"
        end
    elseif select_range_mode == 1 then
        end_time_seconds = mp.get_property_number("duration")
        end_time_formated =  mp.command_native({"expand-text","${duration}"})
    end
    select_range_show()
end

local function select_range_set_right()
    if select_range_mode == 2 then
        start_time_seconds = math.min(mp.get_property_number("duration") - 1, start_time_seconds + 1)
        if start_time_seconds < 86400 then
            start_time_formated = os.date("!%H:%M:%S", start_time_seconds)
        else
            start_time_formated = tostring(start_time_seconds) .. "s"
        end
    elseif select_range_mode == 1 then
        end_time_seconds = mp.get_property_number("time-pos")
        end_time_formated = mp.command_native({"expand-text","${time-pos}"})
    end
    select_range_show()
end


local function select_range()
    -- Cycle through modes
    if select_range_mode == 2 then
        -- Disable range mode
        disable_select_range()
    elseif select_range_mode == 1 then
        -- Switch to "fine tune" mode
        select_range_mode = 2
    else
        select_range_mode = 1
        -- Add keybinds for arrow keys
        mp.add_key_binding("up", "select-range-set-up", select_range_set_end)
        mp.add_key_binding("down", "select-range-set-down", select_range_set_start)
        mp.add_key_binding("left", "select-range-set-left", select_range_set_left)
        mp.add_key_binding("right", "select-range-set-right", select_range_set_right)

        -- Defaults
        if start_time_seconds == nil then
            start_time_seconds = mp.get_property_number("time-pos")
            start_time_formated = mp.command_native({"expand-text","${time-pos}"})
            end_time_seconds = mp.get_property_number("duration")
            end_time_formated =  mp.command_native({"expand-text","${duration}"})
        end
    end
    select_range_show()
end

local function download_mpv_playlist()
    -- Toggle for downloading the whole mpv-playlist
    switches.mpv_playlist_toggle = not switches.mpv_playlist_toggle
    if switches.mpv_playlist_toggle then
        mp.osd_message("Download whole mpv playlist: Enabled", 3)
    else
        mp.osd_message("Download whole mpv playlist: Disabled", 3)
    end
end

local function menu_command(str)
    return string.format('script-message-to %s %s', script_name, str)
end

local function create_menu_data()
    -- uosc menu

    local current_format = get_current_format()

    local video_format = ""
    if not_empty(opts.video_format) then
      video_format = opts.video_format
    end

    if not_empty(opts.remux_video) then
        video_format = video_format .. "/" .. tostring(opts.remux_video)
    end

    if not_empty(opts.recode_video) then
        video_format = video_format .. "/" .. tostring(opts.recode_video)
    end

    local audio_format = ""
    if not_empty(opts.audio_format) then
      audio_format = opts.audio_format
    end

    local sub_format = ""
    if not_empty(opts.sub_format) then
        sub_format = opts.sub_format
    end
    if not_empty(opts.sub_lang) then
        sub_format = sub_format .. " [" .. opts.sub_lang .. "]"
    end

    local url = mp.get_property("path")
    local not_youtube = url == nil or (url:find("ytdl://") ~= 1 and url:find("https?://") ~= 1)

    local items = {
      {
        title = locale('Audio'),
        hint = tostring(audio_format),
        icon = 'audiotrack',
        value = menu_command('audio_default_quality'),
        keep_open = false
      },
      {
        title = locale('Video (Current quality)'),
        hint = tostring(current_format),
        icon = 'play_circle_filled',
        value = menu_command('video_current_quality'),
        keep_open = false
      },
      {
        title = locale('Video (Default quality)'),
        hint = tostring(video_format),
        icon = 'download',
        value = menu_command('video_default_quality'),
        keep_open = false
      },
      {
        title = locale('Video with subtitles'),
        icon = 'hearing_disabled',
        value = menu_command('embed_subtitle_default_quality'),
        keep_open = false
      },
      {
        title = locale('Subtitles'),
        hint = tostring(sub_format),
        icon = 'subtitles',
        value = menu_command('subtitle'),
        keep_open = false
      },
      {
        title = locale('Select range'),
        icon = 'content_cut',
        value = menu_command('cut'),
        keep_open = false
      },
      {
        title = locale('Download whole mpv playlist'),
        icon = switches.mpv_playlist_toggle and 'check_box' or 'check_box_outline_blank',
        value = menu_command('set-state-bool mpv_playlist_toggle ' .. (switches.mpv_playlist_toggle and 'no' or 'yes'))
      },
    }

    if not_empty(opts.download_video_config_file) then
        table.insert(items, {
            title = locale('Video (Config file)'),
            icon = 'build',
            value = menu_command('video_config_file'),
            keep_open = false
        })
    end
    if not_empty(opts.download_audio_config_file) then
        table.insert(items, {
            title = locale('Audio (Config file)'),
            icon = 'build',
            value = menu_command('audio_config_file'),
            keep_open = false
        })
    end
    if not_empty(opts.download_subtitle_config_file) then
        table.insert(items, {
            title = locale('Subtitle (Config file)'),
            icon = 'build',
            value = menu_command('subtitle_config_file'),
            keep_open = false
        })
    end
    if not_empty(opts.download_video_embed_subtitle_config_file) then
        table.insert(items, {
            title = locale('Video with subtitles (Config file)'),
            icon = 'build',
            value = menu_command('video_embed_subtitle_config_file'),
            keep_open = false
        })
    end
    if not_youtube then
        table.insert(items, 1, {
            title = locale('Current file is not a youtube video'),
            icon = 'warning',
            value = menu_command(''),
            bold = true,
            active = 1,
            keep_open = false,
        })
    end

    return {
      type = 'yt_download_menu',
      title = locale('Download'),
      keep_open = true,
      items = items
    }
end

local function download_video()
    if not_empty(opts.download_video_config_file) then
        return download(DOWNLOAD.CONFIG_FILE, opts.download_video_config_file)
    else
        return download(DOWNLOAD.VIDEO)
    end
end

local function download_audio()
    if not_empty(opts.download_audio_config_file) then
        return download(DOWNLOAD.CONFIG_FILE, opts.download_audio_config_file)
    else
        return download(DOWNLOAD.AUDIO)
    end
end

local function download_subtitle()
    if not_empty(opts.download_subtitle_config_file) then
        return download(DOWNLOAD.CONFIG_FILE, opts.download_subtitle_config_file)
    else
        return download(DOWNLOAD.SUBTITLE)
    end
end

local function download_embed_subtitle()
    if not_empty(opts.download_video_embed_subtitle_config_file) then
        return download(DOWNLOAD.CONFIG_FILE, opts.download_video_embed_subtitle_config_file)
    else
        return download(DOWNLOAD.VIDEO_EMBED_SUBTITLE)
    end
end

-- keybind
if not_empty(opts.download_video_binding) then
    mp.add_key_binding(opts.download_video_binding, "download-video", download_video)
end
if not_empty(opts.download_audio_binding) then
    mp.add_key_binding(opts.download_audio_binding, "download-audio", download_audio)
end
if not_empty(opts.download_subtitle_binding) then
    mp.add_key_binding(opts.download_subtitle_binding, "download-subtitle", download_subtitle)
end
if not_empty(opts.download_video_embed_subtitle_binding) then
    mp.add_key_binding(opts.download_video_embed_subtitle_binding, "download-embed-subtitle", download_embed_subtitle)
end
if not_empty(opts.select_range_binding) then
    mp.add_key_binding(opts.select_range_binding, "select-range-start", select_range)
end
if not_empty(opts.download_mpv_playlist) then
    mp.add_key_binding(opts.download_mpv_playlist, "download-mpv-playlist", download_mpv_playlist)
end


-- Open the uosc menu:

mp.register_script_message('set-state-bool', function(prop, value)
    switches[prop] = value == 'yes'
    -- Update currently opened menu
    local json = utils.format_json(create_menu_data())
    mp.commandv('script-message-to', 'uosc', 'update-menu', json)
  end)

mp.register_script_message('menu', function()
    local json = utils.format_json(create_menu_data())
    mp.commandv('script-message-to', 'uosc', 'open-menu', json)
end)

-- Messages from uosc menu entries:

mp.register_script_message('audio_default_quality', function()
    download(DOWNLOAD.AUDIO)
end)

mp.register_script_message('video_current_quality', function()
  download(DOWNLOAD.VIDEO, nil, {video_format = "current"})
end)

mp.register_script_message('video_default_quality', function()
    download(DOWNLOAD.VIDEO)
end)

mp.register_script_message('embed_subtitle_default_quality', function()
    download(DOWNLOAD.VIDEO_EMBED_SUBTITLE)
end)

mp.register_script_message('subtitle', function()
    download(DOWNLOAD.SUBTITLE)
end)

mp.register_script_message('cut', function()
    select_range()
end)

mp.register_script_message('toggle_download_mpv_playlist', function()
    download_mpv_playlist()
end)

mp.register_script_message('video_config_file', function()
    download(DOWNLOAD.CONFIG_FILE, opts.download_video_config_file)
end)

mp.register_script_message('audio_config_file', function()
    download(DOWNLOAD.CONFIG_FILE, opts.download_audio_config_file)
end)

mp.register_script_message('subtitle_config_file', function()
    download(DOWNLOAD.CONFIG_FILE, opts.download_subtitle_config_file)
end)

mp.register_script_message('video_embed_subtitle_config_file', function()
    download(DOWNLOAD.CONFIG_FILE, opts.download_video_embed_subtitle_config_file)
end)
