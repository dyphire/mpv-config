--[[
    ModernX by zydezu
    (https://github.com/zydezu/ModernX)

    This script is a result of the original mpv-osc-modern by maoiscat 
    and it's subsequent forks:
    * cyl0/ModernX
    * dexeonify/ModernX
    * Samillion/ModernZ

    Based on the osc.lua from mpv
--]]

mp.assdraw = require("mp.assdraw")
mp.msg = require("mp.msg")
mp.utils = require("mp.utils")

-- ====================
-- declarations
-- ====================

local function update_tracklist() end
local function get_tracklist() end
local function set_track() end
local function get_track() end
local function window_controls_enabled() end
local function get_chapter() end
local function render_elements() end
local function render_persistent_progressbar() end
local function limited_list() end
local function checktitle() end
local function normaliseDate(date) end
local function exec_async() end
local function is_url() end
local function check_path_url() end
local function check_comments() end
local function loadSetOfComments() end
local function process_filesize() end
local function splitUTF8(str, maxLength) end
local function process_vid_stats() end
local function process_dislikes() end
local function add_commas_to_number() end
local function addLikeCountToTitle() end
local function format_file_size(file_size) end
local function get_playlist() end
local function get_chapterlist() end
local function show_message(text, duration) end
local function bind_keys() end
local function unbind_keys() end
local function destroyscrollingkeys() end
local function check_description() end
local function show_description(text) end
local function reset_desc_timer() end
local function render_message() end
local function window_controls() end
local function validate_user_opts() end
local function update_options(list) end
local function show_osc() end
local function hide_osc() end
local function osc_visible(visible) end
local function adjustSubtitles(visible) end
local function pause_state() end
local function cache_state() end
local function process_event() end
local function tick() end
local function reset_timeout() end
local function visibility_mode(mode) end

-- ====================
-- Parameters
-- default user option values
-- change them using modernx.conf
-- ====================

local user_opts = {
    -- Language and display --
    language = "en",                        -- en:English - .json translations need implementing
    font = "mpv-osd-symbols",               -- font for the OSC (default: mpv-osd-symbols or the one set in mpv.conf)
    layout_option = "original",             -- use the original/reduced layout
    idle_screen = true,                     -- show mpv logo when idle
    key_bindings = true,                    -- register additional key bindings, such as chapter scrubbing, pinning the window
    window_top_bar = "auto",                -- show OSC window top bar: "auto", "yes", or "no" (borderless/fullscreen)
    show_windowed = true,                   -- show OSC when windowed
    show_fullscreen = true,                 -- show OSC when fullscreen
    show_on_pause = true,                   -- show OSC when paused
    keep_on_pause = false,                  -- disable OSC hide timeout when paused
    green_and_grumpy = false,               -- disable Santa hat in December
    visibility = "auto",                    -- only used at init to set visibility_mode(...)

    -- OSC behaviour and scaling
    hide_timeout = 1500,                    -- time (in ms) before OSC hides if no mouse movement
    seek_resets_hide_timeout = true,        -- if seeking should reset the hide_timeout
    fade_duration = 150,                    -- fade-out duration (in ms), set to 0 for no fade
    min_mouse_move = 0,                     -- minimum mouse movement (in pixels) required to show OSC
    bottom_hover = true,                    -- show OSC only when hovering at the bottom
    bottom_hover_zone = 200,                -- height of hover zone for bottom_hover (in pixels)
    osc_on_seek = false,                    -- show OSC when seeking
    mouse_seek_pause = true,                -- pause video while seeking with mouse move (on button hold)

    vid_scale = false,                      -- scale osc with the video
    scale_windowed = 1.0,                   -- osc scale factor when windowed
    scale_fullscreen = 1.0,                 -- osc scale factor when fullscreen
    scale_forced_window = 1.0,              -- osc scale factor when forced (no video, like music files)

    -- Time, title and description display
    show_title = true,                      -- show title in the OSC (above seekbar)
    title = "${media-title}",               -- title above seekbar format: "${media-title}" or "${filename}"
    title_font_size = 28,                   -- font size of the title text (above seekbar)
    dynamic_title = true,                   -- change title if {media-title} and {filename} differ (eg: when playing URLs or audio)

    show_chapter_title = true,              -- show chapter title alongside timestamp (below seekbar)
    chapter_fmt = "%s",                     -- format for chapter display on seekbar hover (set to "no" to disable)
    show_chapter_markers = false,           -- show chapter markers on the seekbar

    time_total = true,                      -- show total time instead of remaining time
    time_ms = false,                        -- show timecodes with milliseconds
    unicode_minus = false,                  -- use the Unicode minus sign in remaining time
    time_format = "dynamic",                -- "dynamic" or "fixed" - dynamic shows MM:SS when possible, fixed always shows HH:MM:SS
    time_font_size = 18,                    -- font size of the time display

    show_description = true,                -- show video description - description on web videos or metadata/stats on local video
    show_file_size = true,                  -- show the current file's size in the description
    description_font_size = 19,             -- font size of the description text (below title)
    description_alpha = 100,                -- alpha of the description background box
    scrolling_speed = 40,                   -- the speed of scrolling text in description/comment menus

    date_format = "%Y-%m-%d",               -- how dates should be formatted, when read from metadata (uses standard lua date formatting)

    -- Title bar settings
    window_title = true,                    -- show window title in borderless/fullscreen mode
    window_controls = true,                 -- show window controls (close, minimize, maximize) in borderless/fullscreen
    title_bar_box = false,                  -- show title bar as a box instead of a black fade
    window_controls_title = "${media-title}", -- same as title but for window_controls

    -- Subtitle display settings
    raise_subtitles = true,                 -- whether to raise subtitles above the osc when it's shown
    raise_subtitle_amount = 175,            -- how much subtitles rise when the osc is shown

    -- Buttons display and functionality
    compact_mode = true,                    -- replace the jump buttons with the seek/chapter buttons

    jump_buttons = true,                    -- show the jump backward and forward buttons
    jump_amount = 10,                       -- change the jump amount in seconds
    jump_more_amount = 60,                  -- change the jump amount in seconds when right-clicking jump buttons and shift-clicking chapter skip buttons
    jump_icon_number = true,                -- show different icon when jump_amount is set to 5, 10, or 30
    jump_mode = "relative",                 -- seek mode for jump buttons
    jump_softrepeat = true,                 -- enable continuous jumping when holding down seek buttons
    chapter_skip_buttons = true,            -- show the chapter skip backward and forward buttons
    chapter_softrepeat = false,             -- enable continuous skipping when holding down chapter skip buttons
    track_nextprev_buttons = true,          -- show next/previous playlist track buttons

    volume_control = true,                  -- show mute button and volume slider
    volume_control_type = "linear",         -- volume scale type: "linear" or "logarithmic"

    info_button = false,                    -- show info button
    ontop_button = true,                    -- show window on top button
    screenshot_button = false,              -- show screenshot button
    screenshot_flag = "subtitles",          -- flag for screenshot button: "subtitles", "video", "window", "each-frame" 
                                            -- https://mpv.io/manual/master/#command-interface-screenshot-%3Cflags%3E

    download_button = true,                 -- show download button on web videos (requires yt-dlp and ffmpeg)
    download_path = "~~desktop/mpv/downloads", -- default download directory for videos (https://mpv.io/manual/master/#paths)

    loop_button = false,                    -- show loop button
    loop_in_pause = true,                   -- enable looping by right-clicking pause

    playpause_size = 30,                    -- icon size for the play/pause button
    midbuttons_size = 24,                   -- icon size for the middle buttons
    sidebuttons_size = 24,                  -- icon size for the side buttons

    -- Colors and style
    osc_color = "#000000",                  -- accent color of the OSC and title bar
    window_title_color = "#FFFFFF",         -- color of the title in borderless/fullscreen mode
    window_controls_color = "#FFFFFF",      -- color of the window controls (close, minimize, maximize) in borderless/fullscreen mode
    window_controls_close_hover = "#E81123", -- color of close window control on hover
    window_controls_minmax_hover = "#53A4FC", -- color of min/max window controls on hover
    title_color = "#FFFFFF",                -- color of the title (above seekbar)
    seekbarfg_color = "#1D96F5",            -- color of the seekbar progress and handle, in Hex color format
    seekbarbg_color = "#FFFFFF",            -- color of the remaining seekbar, in Hex color format
    seekbar_cache_color = "#1D96F5",        -- color of the cache ranges on the seekbar
    volumebar_match_seek_color = false,     -- match volume bar color with seekbar color (ignores side_buttons_color)
    time_color = "#FFFFFF",                 -- color of the timestamps (below seekbar)
    chapter_title_color = "#FFFFFF",        -- color of the chapter title next to timestamp (below seekbar)
    side_buttons_color = "#FFFFFF",         -- color of the side buttons (audio, subtitles, playlist, etc.)
    middle_buttons_color = "#FFFFFF",       -- color of the middle buttons (skip, jump, chapter, etc.)
    playpause_color = "#FFFFFF",            -- color of the play/pause button
    held_element_color = "#999999",         -- color of the element when held down (pressed)
    hover_effect_color = "#FFFFFF",         -- color of a hovered button when hover_effect includes "color"
    thumbnail_border_color = "#FFFFFF",     -- color of the border for thumbnails (with thumbfast)
    thumbnail_border_outline = "#000000",   -- color of the border outline for thumbnails

    fade_alpha = 100,                       -- alpha of the title bar background box
    fade_blur_strength = 75,                -- blur strength for the OSC alpha fade - caution: high values can take a lot of CPU time to render
    title_bar_fade_alpha = 150,             -- alpha of the OSC background box
    title_bar_fade_blur_strength = 100,     -- blur strength for the title bar alpha fade
    window_fade_alpha = 75,                 -- alpha of the window title bar
    thumbnail_border = 3,                   -- width of the thumbnail border (for thumbfast)
    thumbnail_border_radius = 3,            -- rounded corner radius for thumbnail border (0 to disable)

    -- Button hover effects
    hover_effect = "size,glow,color",       -- active button hover effects: "glow", "size", "color"; can use multiple separated by commas
    hover_button_size = 115,                -- relative size of a hovered button if "size" effect is active
    button_glow_amount = 5,                 -- glow intensity when "glow" hover effect is active
    hover_effect_for_sliders = false,       -- apply hover effects to slider handles

    -- Progress bar settings
    seek_handle_size = 0.8,                 -- size ratio of the seekbar handle (range: 0 ~ 1)
    progress_bar_height = 16,               -- height of the progress bar
    seek_range = true,                      -- show seek range overlay
    seek_range_alpha = 175,                 -- transparency of the seek range
    seekbar_keyframes = false,              -- use keyframes when dragging the seekbar

    automatic_keyframe_mode = true,         -- automatically set keyframes for the seekbar based on video length
    automatic_keyframe_limit = 600,         -- videos longer than this (in seconds) will have keyframes on the seekbar

    persistent_progress_default = false,    -- always show a small progress line at the bottom of the screen
    persistent_progress_height = 17,        -- height of the persistent_progress bar
    persistent_buffer = false,              -- show the buffer on the persistent progress line
    persistent_progress_toggle = true,      -- enable toggling the persistent_progress bar

    -- Web videos
    title_youtube_stats = true,             -- update the window/OSC title bar with YouTube video stats (views, likes, dislikes)
    ytdl_format = "",                       -- optional parameteres for yt-dlp downloading, eg: '-f bestvideo+bestaudio/best'

    -- sponsorblock features need https://github.com/zydezu/mpvconfig/blob/main/scripts/sponsorblock.lua to work!
    show_sponsorblock_segments = true,      -- show sponsorblock segments on the progress bar
    add_sponsorblock_chapters = false,      -- add sponsorblock chapters to the chapter list
    sponsorblock_seek_range_alpha = 75,     -- transparency of sponsorblock segments
    sponsor_types = {                       -- what categories to show in the progress bar
        "sponsor",                          -- all categories: 
        "intro",                            --      sponsor, intro, outro, 
        "outro",                            --      interaction, selfpromo, preview, 
        "interaction",                      --      music_offtopic, filler
        "selfpromo",
        "preview",
        "music_offtopic",
        "filler"
    },
    sponsorblock_sponsor_color = "#00D400", -- color for sponsors
    sponsorblock_intro_color = "#00FFFF",   -- color for intermission/intro animations
    sponsorblock_outro_color = "#0202ED",   -- color for endcards/credits
    sponsorblock_interaction_color = "#CC00FF", -- color for interaction reminders (reminders to subscribe)
    sponsorblock_selfpromo_color = "#FFFF00", -- color for unpaid/self promotion
    sponsorblock_preview_color = "#008FD6", -- color for unpaid/self promotion
    sponsorblock_music_offtopic_color = "#FF9900", -- color for unpaid/self promotion
    sponsorblock_filler_color = "#7300FF",  -- color for filler tangent/jokes

    -- Experimental
    show_youtube_comments = false,          -- EXPERIMENTAL - show youtube comments
    comments_download_path = "~~desktop/mpv/downloads/comments", -- EXPERIMENTAL - the download path for the comment JSON file
    FORCE_fix_not_ontop = true,             -- EXPERIMENTAL - try and mitigate https://github.com/zydezu/ModernX/issues/30, https://github.com/akiirui/mpv-handler/issues/48
}
-- read options from config and command-line
require("mp.options").read_options(user_opts, 'modernx', function(list) update_options(list) end)

mp.observe_property("osc", "bool", function(name, value) if value == true then mp.set_property("osc", "no") end end)

local osc_param = {                         -- calculated by osc_init()
    playresy = 0,                           -- canvas size Y
    playresx = 0,                           -- canvas size X
    display_aspect = 1,
    unscaled_y = 0,
    areas = {},
}

local icons = {
    play = "\238\166\143",
    pause = "\238\163\140",
    replay = "\238\189\191",
    previous = "\239\152\167",
    next = "\239\149\168",
    rewind = "\238\168\158",
    forward = "\238\152\135",

    audio = "\238\175\139",
    subtitle = "\238\175\141",
    volume_mute = "\238\173\138",
    volume_quiet = "\238\172\184",
    volume_low = "\238\172\189",
    volume_high = "\238\173\130",

    download = "\239\133\144",
    downloading = "\239\140\174",
    loop_off = "\239\133\178",
    loop_on = "\239\133\181",
    info = "\239\146\164",
    ontop_on = "\238\165\190",
    ontop_off = "\238\166\129",
    screenshot = "\239\154\142",
    fullscreen = "\239\133\160",
    fullscreen_exit = "\239\133\166",

    jumpicons = {
        [5] = {"\238\171\186", "\238\171\187"},
        [10] = {"\238\171\188", "\238\172\129"},
        [30] = {"\238\172\133", "\238\172\134"},
        default = {"\238\172\138", "\238\172\138"}, -- second icon is mirrored in layout() 
    },

    emoticon = {
        view = "👁️",
        comment = "💬",
        like = "👍",
        dislike = "👎"
    },

    playlist = "\238\161\159", -- unused rn
}

-- Localization
local language = {
    ['en'] = {
        welcome = 'Drop files or URLs here to play',  -- this text appears when mpv starts
        off = 'OFF',
        na = 'Not available',
        none = 'None available',
        video = 'Video',
        audio = 'Audio',
        subtitle = 'Subtitle',
        nosub = 'No subtitles available',
        noaudio = 'No audio tracks available',
        track = ' tracks:',
        playlist = 'Playlist',
        nolist = 'Playlist is empty',
        chapter = 'Chapter',
        nochapter = 'No chapters available',
        ontop = 'Pin window',
        ontopdisable = 'Unpin window',
        loopenable = 'Enable loop',
        loopdisable = 'Disable loop',
        screenshot = "Screenshot",
        statsinfo = "Information",
        download = "Download",
        download_in_progress = "Download in progress",
        downloading = "Downloading",
        downloaded = "Already downloaded",
    }
}

-- apply lang opts
local texts = language[user_opts.language] or language["en"]

local function contains(list, item)
    local t = {}
    if type(list) ~= "table" then
        for str in string.gmatch(list, '([^,]+)') do
            str = str:gsub("%s+", "")
            table.insert(t, str)
        end
    else
        t = list
    end
    for _, v in ipairs(t) do
        if v == item then
            return true
        end
    end
    return false
end

local function dumptable(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dumptable(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

local thumbfast = {
    width = 0,
    height = 0,
    disabled = true,
    available = false
}

local sponsorblock_color_map = {
    sponsor = user_opts.sponsorblock_sponsor_color,
    intro = user_opts.sponsorblock_intro_color,
    outro = user_opts.sponsorblock_outro_color,
    interaction = user_opts.sponsorblock_interaction_color,
    selfpromo = user_opts.sponsorblock_selfpromo_color,
    preview = user_opts.sponsorblock_preview_color,
    music_offtopic = user_opts.sponsorblock_music_offtopic_color,
    filler = user_opts.sponsorblock_filler_color
}

local tick_delay = 1 / 60 -- 60FPS
local audio_track_count = 0 -- TODO: implement
local sub_track_count = 0 -- TODO: implement
local window_control_box_width = 138
local max_descsize = 125
local comments_per_page = 25
local is_december = os.date("*t").month == 12
local UNICODE_MINUS = string.char(0xe2, 0x88, 0x92)  -- UTF-8 for U+2212 MINUS SIGN
local iconfont = 'fluent-system-icons'

local function osc_color_convert(color)
    return color:sub(6,7) .. color:sub(4,5) ..  color:sub(2,3)
end

local playpause_size = user_opts.playpause_size or 30
local midbuttons_size = user_opts.midbuttons_size or 24
local sidebuttons_size = user_opts.sidebuttons_size or 24
local osc_styles = {
    background_bar = "{\\1c&H" .. osc_color_convert(user_opts.osc_color) .. "&}",
    box_bg = "{\\blur" .. user_opts.fade_blur_strength .. "\\bord" .. user_opts.fade_alpha .. "\\1c&H000000&\\3c&H" .. osc_color_convert(user_opts.osc_color) .. "&}",
    title_bar_box_bg = "{\\blur" .. user_opts.title_bar_fade_blur_strength .. "\\bord" .. user_opts.title_bar_fade_alpha .. "\\1c&H000000&\\3c&H" .. osc_color_convert(user_opts.osc_color) .. "&}",
    chapter_title = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(user_opts.chapter_title_color) .. "&\\3c&H000000&\\fs" .. user_opts.time_font_size .. "\\fn" .. user_opts.font .. "}",
    control_1 = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(user_opts.playpause_color) .. "&\\3c&HFFFFFF&\\fs" .. playpause_size .. "\\fn" .. iconfont .. "}",
    control_2 = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(user_opts.middle_buttons_color) .. "&\\3c&HFFFFFF&\\fs" .. midbuttons_size .. "\\fn" .. iconfont .. "}",
    control_2_flip = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(user_opts.middle_buttons_color) .. "&\\3c&HFFFFFF&\\fs" .. midbuttons_size .. "\\fn" .. iconfont .. "\\fry180}",
    control_3 = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(user_opts.side_buttons_color) .. "&\\3c&HFFFFFF&\\fs" .. sidebuttons_size .. "\\fn" .. iconfont .. "}",
    element_down = "{\\1c&H" .. osc_color_convert(user_opts.held_element_color) .. "&}",
    element_hover = "{" .. (contains(user_opts.hover_effect, "color") and "\\1c&H" .. osc_color_convert(user_opts.hover_effect_color) .. "&" or "") .."\\2c&HFFFFFF&" .. (contains(user_opts.hover_effect, "size") and string.format("\\fscx%s\\fscy%s", user_opts.hover_button_size, user_opts.hover_button_size) or "") .. "}",
    seekbar_bg = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(user_opts.seekbarbg_color) .. "&}",
    seekbar_fg = "{\\blur1\\bord1\\1c&H" .. osc_color_convert(user_opts.seekbarfg_color) .. "&}",
    thumbnail = "{\\blur0\\bord1\\1c&H" .. osc_color_convert(user_opts.thumbnail_border_color) .. "&\\3c&H" .. osc_color_convert(user_opts.thumbnail_border_outline) .. "&}",
    time = "{\\blur0\\bord0\\1c&H" .. osc_color_convert(user_opts.time_color) .. "&\\3c&H000000&\\fs" .. user_opts.time_font_size .. "\\fn" .. user_opts.font .. "}",
    title = "{\\blur1\\bord0.5\\1c&H" .. osc_color_convert(user_opts.title_color) .. "&\\3c&H0&\\fs".. user_opts.title_font_size .."\\q2\\fn" .. user_opts.font .. "}",
    tooltip = "{\\blur1\\bord0.5\\1c&HFFFFFF&\\3c&H000000&\\fs" .. user_opts.time_font_size .. "\\fn" .. user_opts.font .. "}",
    volumebar_bg = "{\\blur0\\bord0\\1c&H999999&}",
    volumebar_fg = "{\\blur1\\bord1\\1c&H" .. osc_color_convert(user_opts.side_buttons_color) .. "&}",
    window_control = "{\\blur1\\bord0.5\\1c&H" .. osc_color_convert(user_opts.window_controls_color) .. "&\\3c&H0&\\fs20\\fnmpv-osd-symbols}",
    window_title = "{\\blur1\\bord0.5\\1c&H" .. osc_color_convert(user_opts.window_title_color) .. "&\\3c&H0&\\fs20\\q2\\fn" .. user_opts.font .. "}",
    description = '{\\blur1\\bord0.5\\1c&HFFFFFF&\\3c&H000000&\\fs'.. user_opts.description_font_size ..'\\q2\\fn' .. user_opts.font .. '}',
}

-- internal states, do not touch
local state = {
    showtime = nil,                         -- time of last invocation (last mouse move)
    osc_visible = false,
    anistart = nil,                         -- time when the animation started
    anitype = nil,                          -- current type of animation
    animation = nil,                        -- current animation alpha
    mouse_down_counter = 0,                 -- used for softrepeat
    active_element = nil,                   -- nil = none, 0 = background, 1+ = see elements[]
    active_event_source = nil,              -- the "button" that issued the current event
    tc_right_rem = not user_opts.time_total, -- if the right timecode should display total or remaining time
    fulltime = user_opts.time_ms,
    mp_screen_sizeX = nil, mp_screen_sizeY = nil, -- last screen-resolution, to detect resolution changes to issue reINITs
    initREQ = false,                        -- is a re-init request pending?
    last_mouseX = nil, last_mouseY = nil,   -- last mouse position, to detect significant mouse movement
    mouse_in_window = false,
    fullscreen = false,
    tick_timer = nil,
    tick_last_time = 0,                     -- when the last tick() was run
    hide_timer = nil,
    cache_state = nil,
    buffering = false,
    idle = false,
    enabled = true,
    input_enabled = true,
    showhide_enabled = false,

    border = true,
    title_bar = true,
    maximized = false,
    osd = mp.create_osd_overlay('ass-events'),
    new_file_flag = false,                  -- flag to detect new file starts
    chapter_list = {},                      -- sorted by time
    chapter_list_pre_sponsorblock = {},
    mute = false,
    looping = false,
    sliderpos = 0,
    touchingprogressbar = false,            -- if the mouse is touching the progress bar
    initialborder = mp.get_property('border'),
    playingWhilstSeeking = false,
    playingWhilstSeekingWaitingForEnd = false,
    persistent_progresstoggle = user_opts.persistent_progress_default,

    downloaded_once = false,
    downloading = false,
    file_size_bytes = 0,
    file_size_normalized = "Approximating size...",
    is_URL = false,
    URL_path = "",                          -- used for yt-dlp downloading
    videoCantBeDownloaded = false, -- TODO: needs to be removed

    localDescription = nil,
    localDescriptionClick = nil,
    localDescriptionIsClickable = false,
    videoDescription = "",                  -- use if it is a YouTube video
    descriptionLoaded = false,
    showingDescription = false,
    scrolledlines = 25,
    youtubeuploader = "",
    jsoncomments= {},
    youtubecomments = {},
    commentsParsed = false,
    currentCommentIndex = 0,
    commentsPage = 0,
    maxCommentPages = 0,
    commentsAdditionalText = "",

    sponsor_segments = {},

    message_text = nil, -- TODO: needs to be removed
    message_hide_timer = nil, -- TODO: needs to be removed
}

local logo_lines = {
    -- White border
    "{\\c&HE5E5E5&\\p6}m 895 10 b 401 10 0 410 0 905 0 1399 401 1800 895 1800 1390 1800 1790 1399 1790 905 1790 410 1390 10 895 10 {\\p0}",
    -- Purple fill
    "{\\c&H682167&\\p6}m 925 42 b 463 42 87 418 87 880 87 1343 463 1718 925 1718 1388 1718 1763 1343 1763 880 1763 418 1388 42 925 42{\\p0}",
    -- Darker fill
    "{\\c&H430142&\\p6}m 1605 828 b 1605 1175 1324 1456 977 1456 631 1456 349 1175 349 828 349 482 631 200 977 200 1324 200 1605 482 1605 828{\\p0}",
    -- White fill
    "{\\c&HDDDBDD&\\p6}m 1296 910 b 1296 1131 1117 1310 897 1310 676 1310 497 1131 497 910 497 689 676 511 897 511 1117 511 1296 689 1296 910{\\p0}",
    -- Triangle
    "{\\c&H691F69&\\p6}m 762 1113 l 762 708 b 881 776 1000 843 1119 911 1000 978 881 1046 762 1113{\\p0}",
}

local santa_hat_lines = {
    -- Pompoms
    "{\\c&HC0C0C0&\\p6}m 500 -323 b 491 -322 481 -318 475 -311 465 -312 456 -319 446 -318 434 -314 427 -304 417 -297 410 -290 404 -282 395 -278 390 -274 387 -267 381 -265 377 -261 379 -254 384 -253 397 -244 409 -232 425 -228 437 -228 446 -218 457 -217 462 -216 466 -213 468 -209 471 -205 477 -203 482 -206 491 -211 499 -217 508 -222 532 -235 556 -249 576 -267 584 -272 584 -284 578 -290 569 -305 550 -312 533 -309 523 -310 515 -316 507 -321 505 -323 503 -323 500 -323{\\p0}",
    "{\\c&HE0E0E0&\\p6}m 315 -260 b 286 -258 259 -240 246 -215 235 -210 222 -215 211 -211 204 -188 177 -176 172 -151 170 -139 163 -128 154 -121 143 -103 141 -81 143 -60 139 -46 125 -34 129 -17 132 -1 134 16 142 30 145 56 161 80 181 96 196 114 210 133 231 144 266 153 303 138 328 115 373 79 401 28 423 -24 446 -73 465 -123 483 -174 487 -199 467 -225 442 -227 421 -232 402 -242 384 -254 364 -259 342 -250 322 -260 320 -260 317 -261 315 -260{\\p0}",
    -- Main cap
    "{\\c&H0000F0&\\p6}m 1151 -523 b 1016 -516 891 -458 769 -406 693 -369 624 -319 561 -262 526 -252 465 -235 479 -187 502 -147 551 -135 588 -111 1115 165 1379 232 1909 761 1926 800 1952 834 1987 858 2020 883 2053 912 2065 952 2088 1000 2146 962 2139 919 2162 836 2156 747 2143 662 2131 615 2116 567 2122 517 2120 410 2090 306 2089 199 2092 147 2071 99 2034 64 1987 5 1928 -41 1869 -86 1777 -157 1712 -256 1629 -337 1578 -389 1521 -436 1461 -476 1407 -509 1343 -507 1284 -515 1240 -519 1195 -521 1151 -523{\\p0}",
    -- Cap shadow
    "{\\c&H0000AA&\\p6}m 1657 248 b 1658 254 1659 261 1660 267 1669 276 1680 284 1689 293 1695 302 1700 311 1707 320 1716 325 1726 330 1735 335 1744 347 1752 360 1761 371 1753 352 1754 331 1753 311 1751 237 1751 163 1751 90 1752 64 1752 37 1767 14 1778 -3 1785 -24 1786 -45 1786 -60 1786 -77 1774 -87 1760 -96 1750 -78 1751 -65 1748 -37 1750 -8 1750 20 1734 78 1715 134 1699 192 1694 211 1689 231 1676 246 1671 251 1661 255 1657 248 m 1909 541 b 1914 542 1922 549 1917 539 1919 520 1921 502 1919 483 1918 458 1917 433 1915 407 1930 373 1942 338 1947 301 1952 270 1954 238 1951 207 1946 214 1947 229 1945 239 1939 278 1936 318 1924 356 1923 362 1913 382 1912 364 1906 301 1904 237 1891 175 1887 150 1892 126 1892 101 1892 68 1893 35 1888 2 1884 -9 1871 -20 1859 -14 1851 -6 1854 9 1854 20 1855 58 1864 95 1873 132 1883 179 1894 225 1899 273 1908 362 1910 451 1909 541{\\p0}",
    -- Brim and tip pompom
    "{\\c&HF8F8F8&\\p6}m 626 -191 b 565 -155 486 -196 428 -151 387 -115 327 -101 304 -47 273 2 267 59 249 113 219 157 217 213 215 265 217 309 260 302 285 283 373 264 465 264 555 257 608 252 655 292 709 287 759 294 816 276 863 298 903 340 972 324 1012 367 1061 394 1125 382 1167 424 1213 462 1268 482 1322 506 1385 546 1427 610 1479 662 1510 690 1534 725 1566 752 1611 796 1664 830 1703 880 1740 918 1747 986 1805 1005 1863 991 1897 932 1916 880 1914 823 1945 777 1961 725 1979 673 1957 622 1938 575 1912 534 1862 515 1836 473 1790 417 1755 351 1697 305 1658 266 1633 216 1593 176 1574 138 1539 116 1497 110 1448 101 1402 77 1371 37 1346 -16 1295 15 1254 6 1211 -27 1170 -62 1121 -86 1072 -104 1027 -128 976 -133 914 -130 851 -137 794 -162 740 -181 679 -168 626 -191 m 2051 917 b 1971 932 1929 1017 1919 1091 1912 1149 1923 1214 1970 1254 2000 1279 2027 1314 2066 1325 2139 1338 2212 1295 2254 1238 2281 1203 2287 1158 2282 1116 2292 1061 2273 1006 2229 970 2206 941 2167 938 2138 918{\\p0}",
}

--
-- Helper functions
--

local function kill_animation()
    state.anistart = nil
    state.animation = nil
    state.anitype =  nil
end

local function set_osd(res_x, res_y, text, z)
    if state.osd.res_x == res_x and
       state.osd.res_y == res_y and
       state.osd.data == text then
        return
    end
    state.osd.res_x = res_x
    state.osd.res_y = res_y
    state.osd.data = text
    state.osd.z = z
    state.osd:update()
end

-- scale factor for translating between real and virtual ASS coordinates
local function get_virt_scale_factor()
    local w, h = mp.get_osd_size()
    if w <= 0 or h <= 0 then
        return 0, 0
    end
    return osc_param.playresx / w, osc_param.playresy / h
end

-- return mouse position in virtual ASS coordinates (playresx/y)
local function get_virt_mouse_pos()
    if state.mouse_in_window then
        local sx, sy = get_virt_scale_factor()
        local x, y = mp.get_mouse_pos()
        return x * sx, y * sy
    else
        return -1, -1
    end
end

local function set_virt_mouse_area(x0, y0, x1, y1, name)
    local sx, sy = get_virt_scale_factor()
    mp.set_mouse_area(x0 / sx, y0 / sy, x1 / sx, y1 / sy, name)
end

local function scale_value(x0, x1, y0, y1, val)
    local m = (y1 - y0) / (x1 - x0)
    local b = y0 - (m * x0)
    return (m * val) + b
end

-- returns hitbox spanning coordinates (top left, bottom right corner)
-- according to alignment
local function get_hitbox_coords(x, y, an, w, h)
    local alignments = {
      [1] = function () return x, y-h, x+w, y end,
      [2] = function () return x-(w/2), y-h, x+(w/2), y end,
      [3] = function () return x-w, y-h, x, y end,

      [4] = function () return x, y-(h/2), x+w, y+(h/2) end,
      [5] = function () return x-(w/2), y-(h/2), x+(w/2), y+(h/2) end,
      [6] = function () return x-w, y-(h/2), x, y+(h/2) end,

      [7] = function () return x, y, x+w, y+h end,
      [8] = function () return x-(w/2), y, x+(w/2), y+h end,
      [9] = function () return x-w, y, x, y+h end,
    }

    return alignments[an]()
end

local function get_hitbox_coords_geo(geometry)
    return get_hitbox_coords(geometry.x, geometry.y, geometry.an,
        geometry.w, geometry.h)
end

local function get_element_hitbox(element)
    return element.hitbox.x1, element.hitbox.y1,
        element.hitbox.x2, element.hitbox.y2
end

local function mouse_hit_coords(bX1, bY1, bX2, bY2)
    local mX, mY = get_virt_mouse_pos()
    return (mX >= bX1 and mX <= bX2 and mY >= bY1 and mY <= bY2)
end

local function mouse_hit(element)
    return mouse_hit_coords(get_element_hitbox(element))
end

local function limit_range(min, max, val)
    if val > max then
        val = max
    elseif val < min then
        val = min
    end
    return val
end

-- translate value into element coordinates
local function get_slider_ele_pos_for(element, val)
    local ele_pos = scale_value(
        element.slider.min.value, element.slider.max.value,
        element.slider.min.ele_pos, element.slider.max.ele_pos,
        val)

    return limit_range(
        element.slider.min.ele_pos, element.slider.max.ele_pos,
        ele_pos)
end

-- translates global (mouse) coordinates to value
local function get_slider_value_at(element, glob_pos)
    if element then
        local val = scale_value(
            element.slider.min.glob_pos, element.slider.max.glob_pos,
            element.slider.min.value, element.slider.max.value,
            glob_pos)

        return limit_range(
            element.slider.min.value, element.slider.max.value,
            val)
    end
    -- fall back incase of loading errors
    return 0
end

-- get value at current mouse position
local function get_slider_value(element)
    return get_slider_value_at(element, get_virt_mouse_pos())
end

-- multiplies two alpha values, formular can probably be improved
local function mult_alpha(alphaA, alphaB)
    return 255 - (((1-(alphaA/255)) * (1-(alphaB/255))) * 255)
end

local function add_area(name, x1, y1, x2, y2)
    -- create area if needed
    if osc_param.areas[name] == nil then
        osc_param.areas[name] = {}
    end
    table.insert(osc_param.areas[name], {x1=x1, y1=y1, x2=x2, y2=y2})
end

local function ass_append_alpha(ass, alpha, modifier, inverse)
    local ar = {}

    for ai, av in pairs(alpha) do
        av = mult_alpha(av, modifier)
        if state.animation then
            local animpos = state.animation
            if inverse then
                animpos = 255 - animpos
            end
            av = mult_alpha(av, animpos)
        end
        ar[ai] = av
    end

    ass:append(string.format("{\\1a&H%X&\\2a&H%X&\\3a&H%X&\\4a&H%X&}",
               ar[1], ar[2], ar[3], ar[4]))
end

local function ass_draw_cir_cw(ass, x, y, r)
    ass:round_rect_cw(x-r, y-r, x+r, y+r, r)
end

local function ass_draw_rr_h_cw(ass, x0, y0, x1, y1, r1, hexagon, r2)
    if hexagon then
        ass:hexagon_cw(x0, y0, x1, y1, r1, r2)
    else
        ass:round_rect_cw(x0, y0, x1, y1, r1, r2)
    end
end

local function get_hide_timeout()
    if user_opts.visibility == "always" then
        return -1 -- disable autohide
    end
    return user_opts.hide_timeout
end

-- Request that tick() is called (which typically re-renders the OSC).
-- The tick is then either executed immediately, or rate-limited if it was
-- called a small time ago.
local function request_tick()
    if state.tick_timer == nil then
        state.tick_timer = mp.add_timeout(0, tick)
    end

    if not state.tick_timer:is_enabled() then
        local now = mp.get_time()
        local timeout = tick_delay - (now - state.tick_last_time)
        if timeout < 0 then
            timeout = 0
        end
        state.tick_timer.timeout = timeout
        state.tick_timer:resume()
    end
end

local function request_init()
    state.initREQ = true
    request_tick()
end

-- Like request_init(), but also request an immediate update
local function request_init_resize()
    request_init()
    -- ensure immediate update
    state.tick_timer:kill()
    state.tick_timer.timeout = 0
    state.tick_timer:resume()
end

local function render_wipe()
    mp.msg.trace('render_wipe()')
    state.osd.data = "" -- allows set_osd to immediately update on enable
    state.osd:remove()
end

--
-- Tracklist Management
--

local nicetypes = {video = texts.video, audio = texts.audio, sub = texts.subtitle}
local tracks_osc, tracks_mpv

-- updates the OSC internal playlists, should be run each time the track-layout changes
function update_tracklist()
    local tracktable = mp.get_property_native('track-list', {})

    -- by osc_id
    tracks_osc = {}
    tracks_osc.video, tracks_osc.audio, tracks_osc.sub = {}, {}, {}
    -- by mpv_id
    tracks_mpv = {}
    tracks_mpv.video, tracks_mpv.audio, tracks_mpv.sub = {}, {}, {}
    for n = 1, #tracktable do
        if not (tracktable[n].type == 'unknown') then
            local type = tracktable[n].type
            local mpv_id = tonumber(tracktable[n].id)

            -- by osc_id
            table.insert(tracks_osc[type], tracktable[n])

            -- by mpv_id
            tracks_mpv[type][mpv_id] = tracktable[n]
            tracks_mpv[type][mpv_id].osc_id = #tracks_osc[type]
        end
    end
end

-- return a nice list of tracks of the given type (video, audio, sub)
function get_tracklist(type)
    local message = nicetypes[type] .. texts.track
    if not tracks_osc or #tracks_osc[type] == 0 then
        message = texts.none
    else
        for n = 1, #tracks_osc[type] do
            local track = tracks_osc[type][n]
            local lang, title, selected = 'unknown', '', '○'
            if not(track.lang == nil) then lang = track.lang end
            if not(track.title == nil) then title = track.title end
            if (track.id == tonumber(mp.get_property(type))) then
                selected = '●'
            end
            message = message..'\n'..selected..' '..n..': ['..lang..'] '..title
        end
    end
    return message
end

-- relatively change the track of given <type> by <next> tracks
    --(+1 -> next, -1 -> previous)
function set_track(type, next)
    local current_track_mpv, current_track_osc
    current_track_osc = 0
    if (mp.get_property(type) == 'no') then
        current_track_osc = 0
    else
        current_track_mpv = tonumber(mp.get_property(type))
        if (tracks_mpv[type][current_track_mpv]) then
            current_track_osc = tracks_mpv[type][current_track_mpv].osc_id
        end
    end
    local new_track_osc = (current_track_osc + next) % (#tracks_osc[type] + 1)
    local new_track_mpv
    if new_track_osc == 0 then
        new_track_mpv = 'no'
    else
        new_track_mpv = tracks_osc[type][new_track_osc].id
    end

    mp.commandv('set', type, new_track_mpv)
end

-- get the currently selected track of <type>, OSC-style counted
function get_track(type)
    local track = mp.get_property(type)
    if track ~= 'no' and track ~= nil then
        local tr = tracks_mpv[type][tonumber(track)]
        if tr then
            return tr.osc_id
        end
    end
    return 0
end

-- convert slider_pos to logarithmic depending on volume_control user_opts
local function set_volume(slider_pos)
    local volume = slider_pos
    if user_opts.volume_control_type == "logarithmic" then
        volume = slider_pos^2 / 100
    end
    return math.floor(volume)
end

-- WindowControl helpers
function window_controls_enabled()
    local val = user_opts.window_top_bar
    if val == 'auto' then
        return (not state.border) or (not state.title_bar) or state.fullscreen
    else
        return val ~= 'no'
    end
end

--
-- Element Management
--
local elements = {}

local function prepare_elements()
    -- remove elements without layout or invisible
    local elements2 = {}
    for _, element in pairs(elements) do
        if element.layout ~= nil and element.visible then
            table.insert(elements2, element)
        end
    end
    elements = elements2

    local function elem_compare (a, b)
        return a.layout.layer < b.layout.layer
    end

    table.sort(elements, elem_compare)

    for _,element in pairs(elements) do

        local elem_geo = element.layout.geometry

        -- Calculate the hitbox
        local bX1, bY1, bX2, bY2 = get_hitbox_coords_geo(elem_geo)
        element.hitbox = {x1 = bX1, y1 = bY1, x2 = bX2, y2 = bY2}

        local style_ass = mp.assdraw.ass_new()

        -- prepare static elements
        style_ass:append("{}") -- hack to troll new_event into inserting a \n
        style_ass:new_event()
        style_ass:pos(elem_geo.x, elem_geo.y)
        style_ass:an(elem_geo.an)
        style_ass:append(element.layout.style)

        element.style_ass = style_ass

        local static_ass = mp.assdraw.ass_new()

        if element.type == "box" then
            --draw box
            static_ass:draw_start()
            ass_draw_rr_h_cw(static_ass, 0, 0, elem_geo.w, elem_geo.h,
                             element.layout.box.radius, element.layout.box.hexagon)
            static_ass:draw_stop()

        elseif element.type == "slider" then
            --draw static slider parts
            local slider_lo = element.layout.slider
            -- calculate positions of min and max points
            element.slider.min.ele_pos = user_opts.seek_handle_size * elem_geo.h / 2
            element.slider.max.ele_pos = elem_geo.w - element.slider.min.ele_pos
            element.slider.min.glob_pos = element.hitbox.x1 + element.slider.min.ele_pos
            element.slider.max.glob_pos = element.hitbox.x1 + element.slider.max.ele_pos

            static_ass:draw_start()

            -- a hack which prepares the whole slider area to allow center placements such like an=5
            static_ass:rect_cw(0, 0, elem_geo.w, elem_geo.h)
            static_ass:rect_ccw(0, 0, elem_geo.w, elem_geo.h)
            -- chapter marker nibbles
            if user_opts.show_chapter_markers and element.slider.markerF ~= nil and slider_lo.gap > 0 then
                local markers = element.slider.markerF()
                for _, marker in pairs(markers) do
                    if marker >= element.slider.min.value and marker <= element.slider.max.value then
                        local s = get_slider_ele_pos_for(element, marker)
                        if slider_lo.gap > 5 then -- draw triangles
                            --top
                            if slider_lo.nibbles_top then
                                static_ass:move_to(s - 3, slider_lo.gap - 5)
                                static_ass:line_to(s + 3, slider_lo.gap - 5)
                                static_ass:line_to(s, slider_lo.gap - 1)
                            end
                            --bottom
                            if slider_lo.nibbles_bottom then
                                static_ass:move_to(s - 3, elem_geo.h - slider_lo.gap + 5)
                                static_ass:line_to(s, elem_geo.h - slider_lo.gap + 1)
                                static_ass:line_to(s + 3, elem_geo.h - slider_lo.gap + 5)
                            end
                        else -- draw 2x1px nibbles
                            --top
                            if slider_lo.nibbles_top then
                                static_ass:rect_cw(s - 1, 0, s + 1, slider_lo.gap);
                            end
                            --bottom
                            if slider_lo.nibbles_bottom then
                                static_ass:rect_cw(s - 1, elem_geo.h - slider_lo.gap, s + 1, elem_geo.h);
                            end
                        end
                    end
                end
            end
        end

        element.static_ass = static_ass

        -- if the element is supposed to be disabled,
        -- style it accordingly and kill the eventresponders
        if not element.enabled then
            element.layout.alpha[1] = 215
            if not (element.name == "sub_track" or element.name == "audio_track" or element.name == "tog_playlist") then -- keep these to display tooltips
                element.eventresponder = nil
            end
        end

        -- gray out the element if it is toggled off
        if element.off then
            element.layout.alpha[1] = 100
        end
    end
end

--
-- Element Rendering
--

-- returns nil or a chapter element from the native property chapter-list
function get_chapter(possec)
    local cl = state.chapter_list  -- sorted, get latest before possec, if any

    for n=#cl,1,-1 do
        if possec >= cl[n].time then
            return cl[n]
        end
    end
end

local function draw_seekbar_handle(element, elem_ass, override_alpha)
    local pos = element.slider.posF()
    if not pos then
        return 0, 0
    end
    local display_handle = user_opts.seek_handle_size > 0
    local elem_geo = element.layout.geometry
    local rh = display_handle and (user_opts.seek_handle_size * elem_geo.h / 2) or 0 -- handle radius
    local xp = get_slider_ele_pos_for(element, pos) -- handle position
    local handle_hovered = mouse_hit_coords(element.hitbox.x1 + xp - rh, element.hitbox.y1 + elem_geo.h / 2 - rh, element.hitbox.x1 + xp + rh, element.hitbox.y1 + elem_geo.h / 2 + rh) and element.enabled

    if display_handle then
        -- Apply size hover_effect only if hovering over the handle
        if handle_hovered and user_opts.hover_effect_for_sliders then
            if contains(user_opts.hover_effect, "size") then
                rh = rh * (user_opts.hover_button_size / 100)
            end
        end

        ass_draw_cir_cw(elem_ass, xp, elem_geo.h / 2, rh)

        if user_opts.hover_effect_for_sliders then
            elem_ass:draw_stop()
            elem_ass:merge(element.style_ass)
            ass_append_alpha(elem_ass, element.layout.alpha, override_alpha or 0)
            elem_ass:merge(element.static_ass)
        end

        return xp, rh
    end
    return xp, 0
end

-- Draw seekbar progress more accurately
local function draw_seekbar_progress(element, elem_ass)
    local pos = element.slider.posF()
    if not pos then
        return
    end
    local xp = get_slider_ele_pos_for(element, pos)
    local slider_lo = element.layout.slider
    local elem_geo = element.layout.geometry
    elem_ass:rect_cw(0, slider_lo.gap, xp, elem_geo.h - slider_lo.gap)
end

-- Draws seekbar ranges according to user_opts 
local function draw_seekbar_ranges(element, elem_ass, xp, rh, override_alpha)
    local handle = xp and rh
    xp = xp or 0
    rh = rh or 0
    local slider_lo = element.layout.slider
    local elem_geo = element.layout.geometry
    local seekRanges = element.slider.seek_rangesF()
    if not seekRanges then
        return
    end
    elem_ass:draw_stop()
    elem_ass:merge(element.style_ass)
    ass_append_alpha(elem_ass, element.layout.alpha, override_alpha or user_opts.seek_range_alpha)
    elem_ass:append("{\\1cH&" .. osc_color_convert(user_opts.seekbar_cache_color) .. "&}")
    elem_ass:merge(element.static_ass)

    for _, range in pairs(seekRanges) do
        local pstart = math.max(0, get_slider_ele_pos_for(element, range["start"]) - slider_lo.gap)
        local pend = math.min(elem_geo.w, get_slider_ele_pos_for(element, range["end"]) + slider_lo.gap)

        if handle and (pstart < xp + rh and pend > xp - rh) then
            if pstart < xp - rh then
                elem_ass:rect_cw(pstart, slider_lo.gap, xp - rh, elem_geo.h - slider_lo.gap)
            end
            pstart = xp + rh
        end

        if pend > pstart then
            elem_ass:rect_cw(pstart, slider_lo.gap, pend, elem_geo.h - slider_lo.gap)
        end
    end
end

local function draw_sponsorblock_ranges(element, elem_ass, xp, rh)
    local function set_draw_color(color, value, slider_lo, elem_geo)
        elem_ass:draw_stop()
        elem_ass:merge(element.style_ass)
        ass_append_alpha(elem_ass, element.layout.alpha, user_opts.sponsorblock_seek_range_alpha)
        elem_ass:append("{\\1cH&" .. osc_color_convert(color) .. "&}")
        elem_ass:merge(element.static_ass)

        for _, range in pairs(value) do
            local pstart = get_slider_ele_pos_for(element, range["start"])
            local pend = get_slider_ele_pos_for(element, range["end"])
            elem_ass:rect_cw(pstart - rh, slider_lo.gap, pend + rh, elem_geo.h - slider_lo.gap)
        end
    end

    if not user_opts.show_sponsorblock_segments then
        return
    end

    local handle = xp and rh
    xp = xp or 0
    rh = rh or 0
    local slider_lo = element.layout.slider
    local elem_geo = element.layout.geometry

    local temp = elem_ass

    for key, value in pairs(state.sponsor_segments) do
        elem_ass = temp

        local color = sponsorblock_color_map[key]
        if color then
            set_draw_color(color, value, slider_lo, elem_geo)
        end
    end
end

function render_elements(master_ass)
    -- when the slider is dragged or hovered and we have a target chapter name
    -- then we use it instead of the normal title. we calculate it before the
    -- render iterations because the title may be rendered before the slider.
    state.forced_title = nil

    -- disable displaying chapter name in title when thumbfast is available
    -- because thumbfast will render it above the thumbnail instead
    if thumbfast.disabled then
        if user_opts.chapter_fmt ~= "no" and state.touchingprogressbar then
            local dur = mp.get_property_number("duration", 0)
            if dur > 0 then
                local ch = get_chapter(state.sliderpos * dur / 100)
                if ch and ch.title and ch.title ~= "" then
                    state.forced_title = string.format(user_opts.chapter_fmt, ch.title)
                end
            end
        end
    end
    state.touchingprogressbar = false

    for n=1, #elements do
        local element = elements[n]
        local style_ass = mp.assdraw.ass_new()
        style_ass:merge(element.style_ass)
        ass_append_alpha(style_ass, element.layout.alpha, 0)

        if element.eventresponder and (state.active_element == n) then
            -- run render event functions
            if not (element.eventresponder.render == nil) then
                element.eventresponder.render(element)
            end
            if mouse_hit(element) then
                -- mouse down styling
                if (element.styledown) then
                    style_ass:append(osc_styles.element_down)
                end
                if (element.softrepeat) and (state.mouse_down_counter >= 15
                    and state.mouse_down_counter % 5 == 0) then

                    element.eventresponder[state.active_event_source..'_down'](element)
                end
                state.mouse_down_counter = state.mouse_down_counter + 1
            end
        end

        local elem_ass = mp.assdraw.ass_new()
        elem_ass:merge(style_ass)

        if not (element.type == 'button') then
            elem_ass:merge(element.static_ass)
        end

        if element.type == "slider" then
            if element.name ~= "persistentseekbar" then
                local slider_lo = element.layout.slider
                local elem_geo = element.layout.geometry
                local s_min = element.slider.min.value
                local s_max = element.slider.max.value

                local xp, rh = draw_seekbar_handle(element, elem_ass) -- handle posistion, handle radius
                draw_seekbar_progress(element, elem_ass)
                if element.name == "seekbar" then
                    draw_seekbar_ranges(element, elem_ass, xp, rh)
                    draw_sponsorblock_ranges(element, elem_ass, xp, rh)
                end

                elem_ass:draw_stop()

                -- add tooltip
                if element.slider.tooltipF ~= nil and element.enabled then
                    if mouse_hit(element) then
                        local sliderpos = get_slider_value(element)
                        local tooltiplabel = element.slider.tooltipF(sliderpos)
                        local an = slider_lo.tooltip_an
                        local ty
                        if (an == 2) then
                            ty = element.hitbox.y1
                        else
                            ty = element.hitbox.y1 + elem_geo.h/2
                        end

                        local tx = get_virt_mouse_pos()
                        if (slider_lo.adjust_tooltip) then
                            if an == 2 then
                                if sliderpos < (s_min + 3) then
                                    an = an - 1
                                elseif sliderpos > (s_max - 3) then
                                    an = an + 1
                                end
                            elseif (sliderpos > (s_max+s_min)/2) then
                                an = an + 1
                                tx = tx - 5
                            else
                                an = an - 1
                                tx = tx + 10
                            end
                        end

                        if element.name == "seekbar" then
                            state.sliderpos = sliderpos
                        end

                        -- thumbfast
                        if element.thumbnailable and not thumbfast.disabled then
                            local osd_w = mp.get_property_number("osd-width")
                            local r_w, r_h = get_virt_scale_factor()

                            if osd_w then
                                local hover_sec = 0
                                if mp.get_property_number("duration") then hover_sec = mp.get_property_number("duration") * sliderpos / 100 end
                                local thumbPad = user_opts.thumbnail_border
                                local thumbMarginX = 18 / r_w
                                local thumbMarginY = user_opts.time_font_size + thumbPad + 2 / r_h
                                local thumbX = math.min(osd_w - thumbfast.width - thumbMarginX, math.max(thumbMarginX, tx / r_w - thumbfast.width / 2))
                                local thumbY = (ty - thumbMarginY) / r_h - thumbfast.height

                                thumbX = math.floor(thumbX + 0.5)
                                thumbY = math.floor(thumbY + 0.5)

                                if state.anitype == nil then
                                    elem_ass:new_event()
                                    elem_ass:append("{\\rDefault}")
                                    elem_ass:pos(thumbX * r_w, ty - thumbMarginY - thumbfast.height * r_h)
                                    elem_ass:an(7)
                                    elem_ass:append(osc_styles.thumbnail)
                                    elem_ass:draw_start()
                                    if user_opts.thumbnail_border_radius and user_opts.thumbnail_border_radius > 0 then
                                        elem_ass:round_rect_cw(-thumbPad * r_w, -thumbPad * r_h, (thumbfast.width + thumbPad) * r_w, (thumbfast.height + thumbPad) * r_h, user_opts.thumbnail_border_radius)
                                    else
                                        elem_ass:rect_cw(-thumbPad * r_w, -thumbPad * r_h, (thumbfast.width + thumbPad) * r_w, (thumbfast.height + thumbPad) * r_h)
                                    end
                                    elem_ass:draw_stop()

                                    -- force tooltip to be centered on the thumb, even at far left/right of screen
                                    tx = (thumbX + thumbfast.width / 2) * r_w
                                    an = 2

                                    mp.commandv("script-message-to", "thumbfast", "thumb", hover_sec, thumbX, thumbY)
                                end


                                -- chapter title
                                if user_opts.chapter_fmt ~= "no" and state.touchingprogressbar then
                                    local dur = mp.get_property_number("duration", 0)
                                    if dur > 0 then
                                        local ch = get_chapter(state.sliderpos * dur / 100)
                                        if ch and ch.title and ch.title ~= "" then
                                            elem_ass:new_event()
                                            elem_ass:pos((thumbX + thumbfast.width / 2) * r_w, thumbY * r_h - user_opts.time_font_size / 2)
                                            elem_ass:an(an)
                                            elem_ass:append(slider_lo.tooltip_style)
                                            ass_append_alpha(elem_ass, slider_lo.alpha, 0)
                                            elem_ass:append(string.format(user_opts.chapter_fmt, ch.title))
                                        end
                                    end
                                end
                            end
                        end

                        -- tooltip label
                        elem_ass:new_event()
                        elem_ass:pos(tx, ty)
                        elem_ass:an(an)
                        elem_ass:append(slider_lo.tooltip_style)
                        ass_append_alpha(elem_ass, slider_lo.alpha, 0)
                        elem_ass:append(tooltiplabel)
                    elseif element.thumbnailable and thumbfast.available then
                        mp.commandv("script-message-to", "thumbfast", "clear")
                    end
                end
            end

        elseif (element.type == "button") then
            local buttontext
            if type(element.content) == "function" then
                buttontext = element.content() -- function objects
            elseif element.content ~= nil then
                buttontext = element.content -- text objects
            end
            buttontext = buttontext:gsub(":%((.?.?.?)%) unknown ", ":%(%1%)")  --gsub('%) unknown %(\'', '')

            local maxchars = element.layout.button.maxchars
            if not (maxchars == nil) and (#buttontext > maxchars) then
                local max_ratio = 1.25  -- up to 25% more chars while shrinking
                local limit = math.max(0, math.floor(maxchars * max_ratio) - 3)
                if (#buttontext > limit) then
                    while (#buttontext > limit) do
                        buttontext = buttontext:gsub(".[\128-\191]*$", "")
                    end
                    buttontext = buttontext .. "..."
                end
                local _, nchars2 = buttontext:gsub(".[\128-\191]*", "")
                local stretch = (maxchars/#buttontext)*100
                buttontext = string.format("{\\fscx%f}",
                    (maxchars/#buttontext)*100) .. buttontext
            end

            -- add hover effects
            local button_lo = element.layout.button
            local is_clickable = element.eventresponder and (
                element.eventresponder["mbtn_left_down"] ~= nil or
                element.eventresponder["mbtn_left_up"] ~= nil
            )
            local hovered = mouse_hit(element) and is_clickable and element.enabled and state.mouse_down_counter == 0
            local hoverstyle = button_lo.hoverstyle
            if hovered and (contains(user_opts.hover_effect, "size") or contains(user_opts.hover_effect, "color")) then
                -- remove font scale tags for these elements, it looks out of place
                if element.name == "title" or element.name == "description" or element.name == "tc_left" or element.name == "tc_right" or element.name == "chapter_title" then
                    hoverstyle = hoverstyle:gsub("\\fscx%d+\\fscy%d+", "")
                end
                elem_ass:append(hoverstyle .. buttontext)
            else
                elem_ass:append(buttontext)
            end

            -- apply blur effect if "glow" is in hover effects
            if hovered and contains(user_opts.hover_effect, "glow") then
                local shadow_ass = mp.assdraw.ass_new()
                shadow_ass:merge(style_ass)
                shadow_ass:append("{\\blur" .. user_opts.button_glow_amount .. "}" .. hoverstyle .. buttontext)
                elem_ass:merge(shadow_ass)
            end

            -- add tooltip for audio and subtitle tracks
            if not (element.tooltipF == nil) then
                if mouse_hit(element) then
                    local tooltiplabel = element.tooltipF
                    local an = 1
                    local ty = element.hitbox.y1
                    local tx = get_virt_mouse_pos()

                    if ty < osc_param.playresy / 2 then
                        ty = element.hitbox.y2
                        an = 7
                    end

                    -- tooltip label
                    if element.enabled then
                        if type(element.tooltipF) == 'function' then
                            tooltiplabel = element.tooltipF()
                        else
                            tooltiplabel = element.tooltipF
                        end
                    else
                        tooltiplabel = element.nothingavailable
                    end

                    if tx > osc_param.playresx / 2 then --move tooltip to left side of mouse cursor
                        tx = tx - string.len(tooltiplabel) * 8
                    end

                    elem_ass:new_event()
                    elem_ass:pos(tx, ty)
                    elem_ass:an(an)
                    elem_ass:append(element.tooltip_style)
                    elem_ass:append(tooltiplabel)
                end
            end
        end

        master_ass:merge(elem_ass)
    end
end

function render_persistent_progressbar(master_ass)
    for n=1, #elements do
        local element = elements[n]
        if element.name == "persistentseekbar" then
            local style_ass = mp.assdraw.ass_new()
            style_ass:merge(element.style_ass)
            if state.animation or not state.osc_visible then
                ass_append_alpha(style_ass, element.layout.alpha, 0, true)

                local elem_ass = mp.assdraw.ass_new()
                elem_ass:merge(style_ass)
                if element.type ~= "button" then
                    elem_ass:merge(element.static_ass)
                end

                -- draw pos marker
                draw_seekbar_progress(element, elem_ass)

                if user_opts.persistent_buffer then
                    draw_seekbar_ranges(element, elem_ass, nil, nil)
                end

                elem_ass:draw_stop()
                master_ass:merge(elem_ass)
            end
        end
    end
end

--
-- Message display
--

-- pos is 1 based
function limited_list(prop, pos)
    local proplist = mp.get_property_native(prop, {})
    local count = #proplist
    if count == 0 then
        return count, proplist
    end

    local fs = tonumber(mp.get_property('options/osd-font-size'))
    local max = math.ceil(osc_param.unscaled_y * 1.25 / fs)
    if max % 2 == 0 then
        max = max - 1
    end
    local delta = math.ceil(max / 2) - 1
    local begi = math.max(math.min(pos - delta, count - max + 1), 1)
    local endi = math.min(begi + max - 1, count)

    local reslist = {}
    for i=begi, endi do
        local item = proplist[i]
        item.current = (i == pos) and true or nil
        table.insert(reslist, item)
    end
    return count, reslist
end

local function set_tick_delay(_, display_fps)
    -- may be nil if unavailable or 0 fps is reported
    if not display_fps then
        return
    end
    tick_delay = 1 / display_fps
end

local function newfilereset()
    request_init()
    state.downloaded_once = false
    state.videoDescription = "Loading description..."
    state.file_size_normalized = "Approximating size..."
    state.localDescription = "Loading..."
    state.localDescriptionIsClickable = false
    state.localDescriptionClick = "Loading..."
    if is_url(mp.get_property("path")) then
        mp.set_property("title", "Loading...")
    end
end

local function startupevents()
    state.new_file_flag = true
    set_tick_delay("display_fps", mp.get_property_number("display_fps"))
    state.videoDescription = "Loading description..."
    state.file_size_normalized = "Approximating size..."
    check_path_url()
    checktitle()
    if user_opts.automatic_keyframe_mode then
        if mp.get_property_number("duration", 0) > user_opts.automatic_keyframe_limit then
            user_opts.seekbar_keyframes = true
        else
            user_opts.seekbar_keyframes = false
        end
     end
    destroyscrollingkeys() -- close description

    if user_opts.FORCE_fix_not_ontop and state.is_URL then
        mp.commandv("cycle", "ontop")
        mp.commandv("cycle", "ontop")
        mp.set_property("geometry", "75%:75%")
    end
end

function checktitle()
    local mediatitle = mp.get_property("media-title")
    mp.set_property("title", mediatitle)

    if (mp.get_property("filename") ~= mediatitle) and user_opts.dynamic_title then
        user_opts.title = "${media-title}"
    end

    -- fake description using metadata
    state.localDescription = nil
    state.localDescriptionClick = nil
    local title = mp.get_property("media-title")
    local artist = mp.get_property("filtered-metadata/by-key/Album_Artist") or mp.get_property("filtered-metadata/by-key/Artist") or mp.get_property("filtered-metadata/by-key/Uploader")
    if (mp.get_property("filtered-metadata/by-key/Album_Artist") and mp.get_property("filtered-metadata/by-key/Artist")) then
        if (mp.get_property("filtered-metadata/by-key/Album_Artist") ~= mp.get_property("filtered-metadata/by-key/Artist")) then
            artist = mp.get_property("filtered-metadata/by-key/Album_Artist") .. ', ' .. mp.get_property("filtered-metadata/by-key/Artist")
        end
    end
    local album = mp.get_property("filtered-metadata/by-key/Album")
    local description = mp.get_property("filtered-metadata/by-key/Description")
    local date = mp.get_property("filtered-metadata/by-key/Date")

    state.ytdescription = ""
    state.youtubeuploader = artist

    print(dumptable(mp.get_property_native("metadata")))
    if mp.get_property_native('metadata') then
        state.ytdescription = mp.get_property_native('metadata').ytdl_description or description or ""
        state.ytdescription = state.ytdescription:gsub('\r', '\\N'):gsub('\n', '\\N'):gsub("%%", "%%%%")
    else
        print("Failed to load metadata")
    end

    if user_opts.show_description then
        if (title) then
            if (#state.ytdescription > 1) then
                state.localDescriptionClick = title .. "\\N────────────────────\\N" .. state.ytdescription .. "\\N────────────────────\\N"

                local utf8split, lastchar = splitUTF8(state.ytdescription, max_descsize)

                if #utf8split ~= #state.ytdescription then
                    local tmp = utf8split:gsub("[,%.%s]+$", "")

                    utf8split = tmp .. "..."
                end
                utf8split = utf8split:match("^(.-)%s*$")
                local artisttext = state.is_URL and "By: " or "Uploader: "
                if artist then
                    utf8split = utf8split .. " | " .. artisttext .. artist
                    state.localDescriptionClick = state.localDescriptionClick ..  artisttext .. artist
                end
                state.descriptionLoaded = true
                state.videoDescription = utf8split:gsub("\r", ""):gsub("\n", " ")
                state.localDescription = state.videoDescription
            else
                state.localDescriptionClick = title .. "\\N────────────────────\\N"
            end
        end
        if (artist ~= nil) then
            if (state.localDescription == nil) then
                state.localDescription = artist
                state.localDescriptionClick = state.localDescriptionClick .. state.localDescription
                state.localDescriptionIsClickable = true
            end
        end
        if (album ~= nil) then
            if (state.localDescription == nil) then -- only metadata
                state.localDescription = "Album: " .. album
                state.localDescriptionClick = state.localDescriptionClick .. state.localDescription
                state.localDescriptionIsClickable = true
            else -- append to other metadata
                if (state.localDescriptionClick ~= nil) then
                    state.localDescriptionClick = state.localDescriptionClick .. " | " .. album
                else
                    state.localDescriptionClick = album
                    state.localDescriptionIsClickable = true
                end
                state.localDescription = state.localDescription .. " | " .. album
            end
        end
        if (date ~= nil) then
            local datenormal = normaliseDate(date)
            local datetext = "Year"
            if (#datenormal > 4) then datetext = "Date" end
            if (state.localDescription == nil) then -- only metadata
                state.localDescription = datetext .. ": " .. datenormal
                state.localDescriptionClick = state.localDescriptionClick .. state.localDescription
                state.localDescriptionIsClickable = true
            else -- append to other metadata
                if (state.localDescriptionClick ~= nil) then
                    state.localDescriptionClick = state.localDescriptionClick .. "\\N" .. datetext .. ": " .. datenormal
                else
                    state.localDescriptionClick = datenormal
                    state.localDescriptionIsClickable = true
                end
                if (artist ~= nil and datetext == "Year") then
                    state.localDescription = state.localDescription .. " (" .. datenormal .. ")"
                end
                -- state.localDescription = state.localDescription .. " | " ..  datetext .. ": " .. datenormal
            end
        end

        if (user_opts.show_file_size) then
            local file_size = mp.get_property_native("file-size")
            if (file_size ~= nil) then
                file_size = mp.utils.format_bytes_humanized(file_size)
                if (state.localDescription == nil) then -- only metadata
                    state.localDescription = "Size: " .. file_size
                    state.localDescriptionClick = state.localDescriptionClick .. state.localDescription
                    state.localDescriptionIsClickable = true
                else
                    state.localDescriptionClick = state.localDescriptionClick .. "\\NSize: " .. file_size
                end
            end
        end
    end
end

function normaliseDate(date)
    date = string.gsub(date:gsub("/", ""), "-", "")
    if (#date > 8) then -- YYYYMMDD HHMMSS (plus a time)
        local dateTable = {year = date:sub(1,4), month = date:sub(5,6), day = date:sub(7,8)}
        return os.date(user_opts.date_format, os.time(dateTable)) .. date:sub(9)
    elseif (#date > 4) then -- YYYYMMDD
        local dateTable = {year = date:sub(1,4), month = date:sub(5,6), day = date:sub(7,8)}
        return os.date(user_opts.date_format, os.time(dateTable))
    else -- YYYY
        return date
    end
end

function exec_async(args, callback)
    local ret = mp.command_native_async({
        name = "subprocess",
        args = args,
        capture_stdout = true,
        capture_stderr = true
    }, callback)

    return ret and ret.status or nil
end

function is_url(s)
    if not s then
        user_opts.download_button = false
        return false
    end

    local url_pattern = "^[%w]+://[%w%.%-_]+%.[%a]+[-%w%.%-%_/?&=]*"
    return string.match(s, url_pattern) ~= nil
end

function check_path_url()
    state.is_URL = false
    state.downloading = false

    state.youtubecomments = {}
    state.commentsParsed = false
    state.currentCommentIndex = 0
    state.commentsPage = 0
    state.maxCommentPages = 0

    local path = mp.get_property("path")
    if not path then return nil end

    if string.find(path, "https://") then
        path = string.gsub(path, "ytdl://", "") -- Remove "ytdl://" prefix
    else
        path = string.gsub(path, "ytdl://", "https://") -- Replace "ytdl://" with "https://"
    end

    if is_url(path) and path or nil then
        state.is_URL = true
        state.url_path = path
        mp.msg.info("URL detected.")

        if user_opts.download_button then
            mp.msg.info("Fetching file size...")
            local command = {
                "yt-dlp",
                "--no-download",
                "-O",
                "%(filesize,filesize_approx)s", -- Fetch file size or approximate size
                path
            }
            exec_async(command, process_filesize)
        end

        -- Youtube Return Dislike API
        state.dislikes = ""
        if path:find('youtu%.?be') and (user_opts.show_description or user_opts.title_youtube_stats) then
            mp.msg.info("[WEB] Loading dislike count...")
            local filename = mp.get_property_osd("filename")
            local pattern = "v=([^&]+)"
            local match = string.match(filename, pattern)
            if match then
                exec_async({"curl","https://returnyoutubedislikeapi.com/votes?videoId=" .. match}, process_dislikes)
            else
                local _, _, videoID = string.find(filename, "([%w_-]+)%?si=")
                if videoID then
                    exec_async({"curl","https://returnyoutubedislikeapi.com/votes?videoId=" .. videoID}, process_dislikes)
                else
                    mp.msg.info("[WEB] Failed to fetch dislikes")
                end
            end
        end

        if user_opts.show_description then
            mp.msg.info("[WEB] Loading video description...")
            local command = {
                "yt-dlp",
                "--no-download",
                "-O Views: %(view_count)s\nComments: %(comment_count)s\nLikes: %(like_count)s",
                state.url_path
            }
            exec_async(command, process_vid_stats)
        end

        if user_opts.show_youtube_comments then
            mp.msg.info("[WEB] Downloading comments...")
            check_comments()
        end
    end
end

function check_comments()
    local function file_exists(file)
        local f = io.open(file, "rb")
        if f then f:close() end
        return f ~= nil
    end

    local function lines_from(file)
        if not file_exists(file) then return {} end
        local lines = {}
        for line in io.lines(file) do
            lines[#lines + 1] = line
        end
        return lines
    end

    mp.command_native_async({
        name = "subprocess",
        args = {
            "yt-dlp",
            "--skip-download",
            "--write-comments",
            "-o%(id)s",
            "-P " .. mp.command_native({"expand-path", user_opts.comments_download_path}),
            state.url_path
        },
        capture_stdout = true,
        capture_stderr = true
    }, function(success, result, error)
        if not success then
            print("[WEB] Couldn't write youtube comments: " .. error)
            return
        end

        local filename = ""
        if (mp.get_property("filename")) then
            mp.msg.info("[WEB] Downloaded comments")
            filename = mp.command_native({"expand-path", user_opts.comments_download_path .. '/'}) .. mp.get_property("filename"):gsub("watch%?v=", ""):match("^[^%?&]+") .. ".info.json"
        else
            mp.msg.info("[WEB] Comments failed to download...")
            return
        end

        if file_exists(filename) then
            mp.msg.info("[WEB] Reading comments file...")
            local lines = lines_from(filename)
            state.jsoncomments = mp.utils.parse_json(lines[1]).comments
        else
            mp.msg.info("[WEB] Error opening comments file")
            return
        end
        state.maxCommentPages = math.ceil(#state.jsoncomments / comments_per_page)
        if (#state.jsoncomments > 0) then
            state.commentsParsed = true
        else
            user_opts.show_youtube_comments = false -- prevent crash when viewing comments
        end
        if state.showingDescription then
            show_description(state.localDescriptionClick)
        end
        mp.msg.info("[WEB] Read and parsed comments")
    end )
end

function loadSetOfComments(startIndex)
    if (#state.jsoncomments < 1) then
        return
    end

    state.commentDescription = ""
    for i=startIndex, #state.jsoncomments do
        if i > startIndex + (comments_per_page - 1) then
            state.currentCommentIndex = i
            break
        end

        local comment = state.jsoncomments[i]
        local commentconstruction = comment.author

        local linebreak = ''
        if (i ~= startIndex) then
            linebreak = '\\N'
        end
        if (comment.parent ~= "root") then
            commentconstruction = linebreak .. "\\N | " .. commentconstruction  .. " (Replying) | "
        else
            if (linebreak == '\\N') then
                commentconstruction = linebreak .. '-----\\N' .. commentconstruction .. ' | '
            else
                commentconstruction = '\\N' .. commentconstruction .. ' | '
            end
        end

        if (comment._time_text) then
            commentconstruction = commentconstruction .. comment._time_text
        end
        if (comment.is_favorited) then
            commentconstruction = commentconstruction .. (comment.is_favorited and ' | Favorited ♡\\N')
        end
        if (comment.is_pinned) then
            commentconstruction = commentconstruction .. (comment.is_pinned and ' | Pinned 📌\\N')
        else
            commentconstruction = commentconstruction .. '\\N'
        end

        local replyPad = ""
        if (comment.parent ~= "root") then
            replyPad = " | "
            commentconstruction = commentconstruction .. replyPad .. comment.text:gsub('\n', '\\N' .. replyPad)
        else
            commentconstruction = commentconstruction .. comment.text
        end

        if (comment.like_count) then
            local likeText = " likes"
            if (comment.like_count == 1) then
                likeText = " like"
            end
            commentconstruction = commentconstruction .. '\\N' .. replyPad .. comment.like_count .. likeText
        else
            commentconstruction = commentconstruction ..  '\\N' .. replyPad ..  "0 likes"
        end
        -- print(commentconstruction)
        state.youtubecomments[i] = commentconstruction
        state.commentDescription = state.commentDescription .. commentconstruction
    end
end

function process_filesize(success, result, error)
    if not success then
        print("[WEB] Couldn't fetch video filesize: " .. error)
        return
    end

    local fileSizeString = result.stdout
    state.file_size_bytes = tonumber(fileSizeString)

    if state.file_size_bytes then
        state.file_size_normalized = mp.utils.format_bytes_humanized(state.file_size_bytes)
        mp.msg.info("[WEB] Download size: " .. state.file_size_normalized)
    else
        local fs_prop = mp.get_property_osd("file-size")
        if fs_prop and fs_prop ~= "" then
            state.file_size_normalized = fs_prop
            mp.msg.info(fs_prop)
        else
            state.file_size_normalized = "Unknown"
            mp.msg.info("Unable to retrieve file size.")
        end
    end

    request_tick()
end

local function download_done(success, result, error)
    if success then
        show_message("{\\an9}[WEB] Download saved to " .. mp.command_native({"expand-path", user_opts.download_path}))
        state.downloaded_once = true
        mp.msg.info("[WEB] Download completed")
    else
        show_message("{\\an9}[WEB] Download failed - " .. (error or "Unknown error"))
        mp.msg.info("[WEB] Download failed")
    end
    state.downloading = false
end

function splitUTF8(str, maxLength)
    local result = {}
    local currentIndex = 1
    local length = #str
    local lastchar = 0
    while currentIndex <= length do
        lastchar = lastchar + 1
        local byte = string.byte(str, currentIndex)
        local charLength
        if byte >= 0 and byte <= 127 then
            charLength = 1
        elseif byte >= 192 and byte <= 223 then
            charLength = 2
        elseif byte >= 224 and byte <= 239 then
            charLength = 3
            -- CJK
        elseif byte >= 240 and byte <= 247 then
            charLength = 4
        else
            -- Unsupported UTF-8 sequence, handle as needed
            print("Unsupported UTF-8 sequence detected.")
            break
        end
        local currentPart = string.sub(str, currentIndex, currentIndex + charLength - 1)
        if #result > 0 and #result[#result] + #currentPart <= maxLength then
            result[#result] = result[#result] .. currentPart
        else
            result[#result + 1] = currentPart
        end
        currentIndex = currentIndex + charLength
        if #result > 0 and #result[#result] >= maxLength then
            break
        end
    end
    return result[1], lastchar
end

function process_vid_stats(success, result, error)
    if not success then
        print("[WEB] Couldn't fetch video stats: " .. error)
        return
    end

    state.localDescriptionClick =
        mp.get_property("media-title", "") ..
        "\\N────────────────────\\N" ..
        string.gsub(
            string.gsub(result.stdout, '\r', '\\N') ..
            state.dislikes, '\n', '\\N'
        ) ..
        "\\N────────────────────\\N" ..
        state.ytdescription

    if (state.dislikes == "") then
        state.localDescriptionClick = state.localDescriptionClick .. string.gsub(string.gsub(result.stdout, '\r', '\\N'), '\n', '\\N')
        state.localDescriptionClick = state.localDescriptionClick:sub(1, #state.localDescriptionClick - 2)
    end
    addLikeCountToTitle()

    if (state.localDescriptionClick:match('Views: (%d+)')) then
        state.localDescriptionClick = state.localDescriptionClick:gsub(state.localDescriptionClick:match('Views: (%d+)'), add_commas_to_number(state.localDescriptionClick:match('Views: (%d+)')))
    end
    if (state.localDescriptionClick:match('Likes: (%d+)')) then
        state.localDescriptionClick = state.localDescriptionClick:gsub(state.localDescriptionClick:match('Likes: (%d+)'), add_commas_to_number(state.localDescriptionClick:match('Likes: (%d+)')))
    end
    if (state.localDescriptionClick:match('Comments: (%d+)')) then
        state.localDescriptionClick = state.localDescriptionClick:gsub(state.localDescriptionClick:match('Comments: (%d+)'), add_commas_to_number(state.localDescriptionClick:match('Comments: (%d+)')))
    end

    state.localDescriptionClick = state.localDescriptionClick:gsub("Uploader: NA\\N", "")
    state.localDescriptionClick = state.localDescriptionClick:gsub("Uploaded: NA\\N", "")
    state.localDescriptionClick = state.localDescriptionClick:gsub("Views: NA\\N", "")
    state.localDescriptionClick = state.localDescriptionClick:gsub("Comments: NA\\N", "")
    state.localDescriptionClick = state.localDescriptionClick:gsub("Likes: NA\\N", "")
    state.localDescriptionClick = state.localDescriptionClick:gsub("Likes: NA", "")
    state.localDescriptionClick = state.localDescriptionClick:gsub("Dislikes: NA\\N", "")

    if false then
        state.localDescriptionClick = state.localDescriptionClick:gsub("Views:", icons.emoticon.view):gsub("Comments:", icons.emoticon.comment):gsub("Likes:", icons.emoticon.like):gsub("Dislikes:", icons.emoticon.dislike)  -- replace with icons
    end

    if not state.ytdescription then
        if mp.get_property_number("estimated-vf-fps") then
            state.videoDescription = mp.get_property("width") .. "x" .. mp.get_property("height") .. " | FPS: " ..
            (math.floor(mp.get_property_number("estimated-vf-fps") + 0.5) or "") -- can't get a normal description, display something else    
        end
    end

    state.descriptionLoaded = true
    if state.showingDescription then
        show_description(state.localDescriptionClick)
    end
    mp.msg.info("[WEB] Loaded video description")
end

function process_dislikes(success, result, error)
    if not success then
        print("[WEB] Couldn't fetch video dislikes: " .. error)
        return
    end

    local dislikes = result.stdout
    dislikes = add_commas_to_number(dislikes:match('"dislikes":(%d+)'))
    state.dislikecount = dislikes

    if dislikes then
        state.dislikes = "Dislikes: " .. dislikes
        mp.msg.info("[WEB] Fetched dislike count")
    else
        state.dislikes = ""
    end

    if (not state.descriptionLoaded) then
        if state.localDescriptionClick then
            state.localDescriptionClick = state.localDescriptionClick .. '\\N' .. state.dislikes
        else
            state.localDescriptionClick = state.dislikes
        end
    else
        addLikeCountToTitle()
    end
end

function add_commas_to_number(number)
    if number == nil then return '' end

    return tostring(number) -- Make sure the "number" is a string
       :reverse() -- Reverse the string
       :gsub('%d%d%d', '%0,') -- insert one comma after every 3 numbers
       :gsub(',$', '') -- Remove a trailing comma if present
       :reverse() -- Reverse the string again
       :sub(1) -- a little hack to get rid of the second return value
 end

function addLikeCountToTitle()
    if (user_opts.show_description and user_opts.title_youtube_stats) then
        state.viewcount = add_commas_to_number(state.localDescriptionClick:match('Views: (%d+)'))
        state.likecount = add_commas_to_number(state.localDescriptionClick:match('Likes: (%d+)'))
        if (state.viewcount ~= '' and state.likecount ~= '' and state.dislikecount) then
            mp.set_property("title", mp.get_property("media-title") ..
            " | " .. icons.emoticon.view .. state.viewcount ..
            " | " .. icons.emoticon.like .. state.likecount ..
            " | " .. icons.emoticon.dislike .. state.dislikecount)
        elseif (state.viewcount ~= '' and state.likecount ~= '') then
            mp.set_property("title", mp.get_property("media-title") ..
            " | " .. icons.emoticon.view .. state.viewcount ..
            " | " .. icons.emoticon.like .. state.likecount)
        end
    end
end

-- playlist and chapters --
function get_playlist()
    local pos = mp.get_property_number('playlist-pos', 0) + 1
    local count, limlist = limited_list('playlist', pos)
    if count == 0 then
        return texts.nolist
    end

    local message = string.format(texts.playlist .. ' [%d/%d]:\n', pos, count)
    for i, v in ipairs(limlist) do
        local title = v.title
        local _, filename = mp.utils.split_path(v.filename)
        if title == nil then
            title = filename
        end
        message = string.format('%s %s %s\n', message,
            (v.current and '●' or '○'), title)
    end
    return message
end

function get_chapterlist()
    local pos = mp.get_property_number('chapter', 0) + 1
    local count, limlist = limited_list('chapter-list', pos)
    if count == 0 then
        return texts.nochapter
    end

    local message = string.format(texts.chapter.. ' [%d/%d]:\n', pos, count)
    for i, v in ipairs(limlist) do
        local time = mp.format_time(v.time)
        local title = v.title
        if title == nil then
            title = string.format(texts.chapter .. ' %02d', i)
        end
        message = string.format('%s[%s] %s %s\n', message, time,
            (v.current and '●' or '○'), title)
    end
    return message
end

local function make_sponsorblock_segments()
    if not user_opts.show_sponsorblock_segments then return end

    local sponsor_types = user_opts.sponsor_types

    state.sponsor_segments = {}
    local temp_segment = {}
    local is_start_added = false
    local current_category = ""

    local duration = mp.get_property_number('duration', nil)

    if duration then
        for _, chapter in ipairs(state.chapter_list_pre_sponsorblock) do
            if chapter.title then
                for _, value in ipairs(sponsor_types) do
                    if string.find(string.lower(chapter.title), value) then
                        current_category = value
                        if not temp_segment[current_category] then
                            temp_segment[current_category] = {}
                        end
                        if not state.sponsor_segments[current_category] then
                            state.sponsor_segments[current_category] = {}
                        end
                    end
                end

                if string.find(chapter.title, ("start"):gsub("[%[%]]", "%%%1")) then
                    if not is_start_added then
                        temp_segment[current_category]["start"] = chapter.time / duration * 100
                        temp_segment[current_category]["is_start_added"] = true
                    end
                end
                if string.find(chapter.title, ("end"):gsub("[%[%]]", "%%%1")) then
                    if temp_segment[current_category]["is_start_added"] then
                        temp_segment[current_category]["end"] = chapter.time / duration * 100
                        if state.sponsor_segments ~= 2 then
                            temp_segment[current_category]["is_start_added"] = nil
                            -- table.sort(temp_segment[current_category], function(a, b) return a.time < b.time end)
                            table.insert(state.sponsor_segments[current_category], temp_segment[current_category])
                        end
                        temp_segment[current_category] = {}
                        is_start_added = false
                    end
                end
            end
        end
    end

    if not user_opts.add_sponsorblock_chapters then
        -- remove [SponsorBlock] chapters
        local updated_chapters = {}
        for _, chapter in ipairs(state.chapter_list_pre_sponsorblock) do
            if not string.find(chapter.title, "%[SponsorBlock%]") then
                table.insert(updated_chapters, chapter)
            end
        end
        -- updated chapter list
        state.chapter_list = updated_chapters
        mp.set_property_native("chapter-list", updated_chapters)
    end

    print("Added SponsorBlock segments")
end

function show_message(text, duration)
    if state.showingDescription then
        destroyscrollingkeys()
    end
    if duration == nil then
        duration = tonumber(mp.get_property('options/osd-duration')) / 1000
    elseif not type(duration) == 'number' then
        print('duration: ' .. duration)
    end

    -- cut the text short, otherwise the following functions
    -- may slow down massively on huge input
    text = string.sub(text, 0, 4000)

    -- replace actual linebreaks with ASS linebreaks
    text = string.gsub(text, '\n', '\\N')
    text = "\\N" .. text
    state.message_text = text

    if not state.message_hide_timer then
        state.message_hide_timer = mp.add_timeout(0, request_tick)
    end
    state.message_hide_timer:kill()
    state.message_hide_timer.timeout = duration
    state.message_hide_timer:resume()
    request_tick()
end

function bind_keys(keys, name, func, opts)
    if not keys then
        mp.add_forced_key_binding(keys, name, func, opts)
        return
    end
    local i = 1
    for key in keys:gmatch("[^%s]+") do
        local prefix = i == 1 and '' or i
        mp.add_forced_key_binding(key, name .. prefix, func, opts)
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
        mp.remove_key_binding(name .. prefix)
        i = i + 1
    end
end

function destroyscrollingkeys()
    state.showingDescription = false
    state.scrolledlines = 25
    show_message("", 0.01) -- clear text
    unbind_keys("UP WHEEL_UP", "move_up")
    unbind_keys("DOWN WHEEL_DOWN", "move_down")
    unbind_keys("ENTER MBTN_LEFT", "select")
    unbind_keys("ESC MBTN_RIGHT", "close")
    unbind_keys("LEFT", "comments_left")
    unbind_keys("RIGHT", "comments_right")
end

function check_description()
    if not user_opts.show_description then return end
    if state.descriptionLoaded or state.localDescriptionIsClickable then
        if state.showingDescription then
            state.showingDescription = false
            destroyscrollingkeys()
        else
            state.showingDescription = true
            if state.is_URL then
                show_description(state.localDescriptionClick)
            else
                if state.localDescriptionClick == nil then
                    show_description(state.localDescription)
                else
                    show_description(state.localDescriptionClick)
                end
            end
        end
    end
end

function show_description(text)
    if state.is_URL and user_opts.show_youtube_comments then
        if state.commentsParsed and user_opts.show_youtube_comments then
            local pageText = "pages"
            if state.maxCommentPages == 1 then
                pageText = "page"
            end
            state.commentsAdditionalText = '\\N────────────────────\\NPress LEFT/RIGHT to view comments\\N' .. state.maxCommentPages .. ' ' .. pageText .. ' (' .. #state.jsoncomments .. ' comments)'
            text = text .. state.commentsAdditionalText
        else
            text = text .. '\\N────────────────────\\NComments loading...'
        end
    end
    text = string.gsub(text, '\n', '\\N')

    -- enable scrolling of menu --
    bind_keys("UP WHEEL_UP", "move_up", function()
        state.scrolledlines = state.scrolledlines + user_opts.scrolling_speed
        if (state.scrolledlines > 25) then
            state.scrolledlines = 25
        end
        reset_desc_timer()
        request_tick()
    end, { repeatable = true })
    bind_keys("DOWN WHEEL_DOWN", "move_down", function()
        state.scrolledlines = state.scrolledlines - user_opts.scrolling_speed
        reset_desc_timer()
        request_tick()
    end, { repeatable = true })
    bind_keys("ENTER", "select", destroyscrollingkeys)
    bind_keys("ESC", "close", function()
        if (state.commentsPage > 0) then
            state.commentsPage = 0
            state.message_text = state.localDescriptionClick .. state.commentsAdditionalText
            reset_desc_timer()
            request_tick()
            state.scrolledlines = 25
        else
            destroyscrollingkeys()
        end
    end) -- close menu using ESC

    local function returnMessageText()
        local totalCommentCount = #state.jsoncomments
        local firstCommentCount = (state.commentsPage - 1) * comments_per_page + 1
        local lastCommentCount = (state.commentsPage) * comments_per_page
        if lastCommentCount > totalCommentCount then
            lastCommentCount = totalCommentCount
        end
        loadSetOfComments(firstCommentCount)
        return 'Comments\\NPage ' .. state.commentsPage .. '/' .. state.maxCommentPages .. ' (' .. firstCommentCount .. '/' .. #state.jsoncomments .. ')\\N────────────────────\\N' .. state.commentDescription:gsub('\n', '\\N') ..  '\\N────────────────────\\NEnd of page\\NPage ' .. state.commentsPage .. '/' .. state.maxCommentPages .. ' (' .. lastCommentCount .. '/' .. totalCommentCount .. ')'
    end

    state.commentsPage = 0
    if (state.is_URL and user_opts.show_youtube_comments) then
        bind_keys("LEFT", "comments_left", function()
            if (state.commentsParsed) then
                state.commentsPage = state.commentsPage - 1
                if (state.commentsPage == 0) then
                    state.message_text = state.localDescriptionClick .. state.commentsAdditionalText
                elseif (state.commentsPage > 0) then
                    state.message_text = returnMessageText()
                else
                    state.commentsPage = state.maxCommentPages
                    state.message_text = returnMessageText()
                end
                state.scrolledlines = 25
            end
            reset_desc_timer()
            request_tick()
        end)
        bind_keys("RIGHT", "comments_right", function()
            if (state.commentsParsed) then
                state.commentsPage = state.commentsPage + 1
                if (state.commentsPage > state.maxCommentPages) then
                    state.commentsPage = 0
                    state.message_text = state.localDescriptionClick .. state.commentsAdditionalText
                else
                    state.message_text = returnMessageText()
                end
                state.scrolledlines = 25
            end
            reset_desc_timer()
            request_tick()
        end)
    end

    text = "\\N" .. text
    state.message_text = text

    if not state.message_hide_timer then
        state.message_hide_timer = mp.add_timeout(0, request_tick)
    end
    reset_desc_timer()
    request_tick()
end

function reset_desc_timer()
    state.message_hide_timer:kill()
    state.message_hide_timer.timeout = 10
    state.message_hide_timer:resume()
end

function render_message(ass)
    if state.message_hide_timer and state.message_hide_timer:is_enabled() and state.message_text then
        local _, lines = string.gsub(state.message_text, "\\N", "")

        local fontsize = tonumber(mp.get_property('options/osd-font-size'))
        local outline = tonumber(mp.get_property('options/osd-border-size'))
        local maxlines = math.ceil(osc_param.unscaled_y*0.75 / fontsize)
        local counterscale = osc_param.playresy / osc_param.unscaled_y

        if state.showingDescription then
            fontsize = fontsize * 0.85
            outline = outline * 0.85
        else
            fontsize = fontsize * counterscale / math.max(0.5 + math.min(lines/maxlines, 1), 1)
            outline = outline * counterscale / math.max(0.5 + math.min(lines/maxlines, 1)/2, 1)
        end

        if state.showingDescription then
            ass.text = string.format('{\\pos(0,0)\\an7\\1c&H000000&\\alpha&H%X&}', user_opts.description_alpha)
            ass:draw_start()
            ass:rect_cw(0, 0, osc_param.playresx, osc_param.playresy)
            ass:draw_stop()
            ass:new_event()
        end

        local style = '{\\bord' .. outline .. '\\fs' .. fontsize .. '}'

        ass:new_event()
        ass:append(style .. state.message_text)

        if state.showingDescription then
            ass:pos(20, state.scrolledlines)
        end
    else
        state.message_text = nil
        if state.showingDescription then destroyscrollingkeys() end
    end
end

--
-- Initialisation and Layout
--

local function new_element(name, type)
    elements[name] = {}
    elements[name].type = type
    elements[name].name = name

    -- add default stuff
    elements[name].eventresponder = {}
    elements[name].visible = true
    elements[name].enabled = true
    elements[name].softrepeat = false
    elements[name].styledown = (type == "button")
    elements[name].state = {}

    if type == "slider" then
        elements[name].slider = {min = {value = 0}, max = {value = 100}}
        elements[name].thumbnailable = false
    end

    return elements[name]
end

local function add_layout(name)
    if elements[name] ~= nil then
        -- new layout
        elements[name].layout = {}

        -- set layout defaults
        elements[name].layout.layer = 50
        elements[name].layout.alpha = {[1] = 0, [2] = 255, [3] = 255, [4] = 255}

        if elements[name].type == "button" then
            elements[name].layout.button = {
                maxchars = nil,
                hoverstyle = osc_styles.element_hover,
            }
        elseif elements[name].type == "slider" then
            -- slider defaults
            elements[name].layout.slider = {
                border = 1,
                gap = 1,
                nibbles_top = true,
                nibbles_bottom = true,
                adjust_tooltip = true,
                tooltip_style = "",
                tooltip_an = 2,
                alpha = {[1] = 0, [2] = 255, [3] = 88, [4] = 255},
                hoverstyle = osc_styles.element_hover:gsub("\\fscx%d+\\fscy%d+", ""), -- font scales messes with handle positions in werid ways
            }
        elseif elements[name].type == "box" then
            elements[name].layout.box = {radius = 0, hexagon = false}
        end

        return elements[name].layout
    else
        mp.msg.error("Can't add_layout to element '"..name.."', doesn't exist.")
    end
end

-- Window Controls
function window_controls()
    local wc_geo = {
        x = 0,
        y = 30,
        an = 1,
        w = osc_param.playresx,
        h = 30
    }

    local controlbox_w = window_control_box_width

    -- Default alignment is 'right'
    local controlbox_left = wc_geo.w - controlbox_w

    add_area('window-controls',
             get_hitbox_coords(controlbox_left, wc_geo.y, wc_geo.an,
                               controlbox_w, wc_geo.h))

    local lo, ne

    -- Background Bar
    if user_opts.title_bar_box then
        new_element("wcbar", "box")
        lo = add_layout("wcbar")
        lo.geometry = wc_geo
        lo.layer = 10
        lo.style = osc_styles.background_bar
        lo.alpha[1] = user_opts.window_fade_alpha
    end

    local button_y = wc_geo.y - (wc_geo.h / 2)
    local first_geo =
        {x = controlbox_left + 30, y = button_y, an = 5, w = 40, h = wc_geo.h}
    local second_geo =
        {x = controlbox_left + 74, y = button_y, an = 5, w = 40, h = wc_geo.h}
    local third_geo =
        {x = controlbox_left + 118, y = button_y, an = 5, w = 40, h = wc_geo.h}

    -- Window control buttons use symbols in the custom mpv osd font
    -- because the official unicode codepoints are sufficiently
    -- exotic that a system might lack an installed font with them,
    -- and libass will complain that they are not present in the
    -- default font, even if another font with them is available.

    if user_opts.window_controls then
        -- Close: 🗙
        ne = new_element('close', 'button')
        ne.content = '\238\132\149'
        ne.eventresponder['mbtn_left_up'] =
            function () mp.commandv('quit') end
        lo = add_layout('close')
        lo.geometry = third_geo
        lo.style = osc_styles.window_control
        lo.button.hoverstyle = "{\\c&H" .. osc_color_convert(user_opts.window_controls_close_hover) .. "&}"

        -- Minimize: 🗕
        ne = new_element('minimize', 'button')
        ne.content = '\238\132\146'
        ne.eventresponder['mbtn_left_up'] =
            function () mp.commandv('cycle', 'window-minimized') end
        lo = add_layout('minimize')
        lo.geometry = first_geo
        lo.style = osc_styles.window_control
        lo.button.hoverstyle = "{\\c&H" .. osc_color_convert(user_opts.window_controls_minmax_hover) .. "&}"

        -- Maximize: 🗖/🗗
        ne = new_element('maximize', 'button')
        if state.maximized or state.fullscreen then
            ne.content = '\238\132\148'
        else
            ne.content = '\238\132\147'
        end
        ne.eventresponder['mbtn_left_up'] =
            function ()
                if state.fullscreen then
                    mp.commandv('cycle', 'fullscreen')
                else
                    mp.commandv('cycle', 'window-maximized')
                end
            end
        lo = add_layout('maximize')
        lo.geometry = second_geo
        lo.style = osc_styles.window_control
        lo.button.hoverstyle = "{\\c&H" .. osc_color_convert(user_opts.window_controls_minmax_hover) .. "&}"
    end

    -- Window Title
    if user_opts.window_title then
        ne = new_element("window_title", "button")
        ne.content = function ()
            local title = mp.command_native({"expand-text", user_opts.window_controls_title})
            -- escape ASS, and strip newlines and trailing slashes
            title = title:gsub("\\n", " "):gsub("\\$", ""):gsub("{","\\{")
            local titleval = not (title == "") and title or "mpv video"
            if (mp.get_property('ontop') == 'yes') then return "📌 " .. titleval end
            return titleval
        end
        lo = add_layout('window_title')

        local geo = {x = 20, y = button_y + 14, an = 1, w = osc_param.playresx - 50, h = wc_geo.h}
        if user_opts.title_bar_box then
            geo = {x = 10, y = button_y + 10, an = 1, w = osc_param.playresx - 50, h = wc_geo.h}
        end

        lo.geometry = geo
        lo.style = osc_styles.window_title
        lo.button.maxchars = geo.w / 10
    end
end

--
-- ModernX Layout
--

local layouts = {}

-- Default layout
layouts["original"] = function ()
    local osc_geo = {
        w = osc_param.playresx,
        h = 180
    }

    -- origin of the controllers, left/bottom corner
    local posX = 0
    local posY = osc_param.playresy

    osc_param.areas = {} -- delete areas

    -- area for active mouse input
    add_area('input', get_hitbox_coords(posX, posY, 1, osc_geo.w, osc_geo.h))

    -- area for show/hide
    add_area('showhide', 0, 0, osc_param.playresx, osc_param.playresy)

    -- fetch values
    local osc_w, osc_h = osc_geo.w, osc_geo.h

    -- Controller Background
    local lo, geo

    new_element('box_bg', 'box')
    lo = add_layout('box_bg')
    lo.geometry = {x = posX, y = posY, an = 7, w = osc_w, h = 1}
    lo.style = osc_styles.box_bg
    lo.layer = 10
    lo.alpha[3] = 0

    local top_titlebar = window_controls_enabled() and (user_opts.window_title or user_opts.window_controls)

    if not user_opts.title_bar_box and (user_opts.window_top_bar == "yes" or (not state.border) or (not state.title_bar) or state.fullscreen) and top_titlebar then
        new_element("title_alpha_bg", "box")
        lo = add_layout("title_alpha_bg")
        lo.geometry = {x = posX, y = -100, an = 7, w = osc_w, h = -1}
        lo.style = osc_styles.title_bar_box_bg
        lo.layer = 10
        lo.alpha[3] = 0
    end

    -- Alignment
    local refX = osc_w / 2
    local refY = posY

    -- Seekbar
    new_element('seekbarbg', 'box')
    lo = add_layout('seekbarbg')
    lo.geometry = {x = refX , y = refY - 100, an = 5, w = osc_geo.w - 50, h = 2}
    lo.layer = 13
    lo.style = osc_styles.seekbar_bg
    lo.alpha[1] = 128
    lo.alpha[3] = 128

    lo = add_layout('seekbar')
    lo.geometry = {x = refX, y = refY - 100, an = 5, w = osc_geo.w - 50, h = user_opts.progress_bar_height}
    lo.style = osc_styles.seekbar_fg
    lo.slider.gap = 7
    lo.slider.tooltip_style = osc_styles.tooltip
    lo.slider.tooltip_an = 2
    lo.layer = 100

    if (user_opts.persistent_progress_default or user_opts.persistent_progress_toggle) then
        lo = add_layout('persistentseekbar')
        lo.geometry = {x = refX, y = refY, an = 5, w = osc_geo.w, h = user_opts.persistent_progress_height}
        lo.style = osc_styles.seekbar_fg
        lo.slider.gap = 7
        lo.slider.tooltip_an = 0
    end

    local jump_buttons = user_opts.jump_buttons
    local chapter_skip_buttons = user_opts.chapter_skip_buttons
    local track_nextprev_buttons = user_opts.track_nextprev_buttons

    local loop_button = user_opts.loop_button
    local info_button = user_opts.info_button
    local ontop_button = user_opts.ontop_button
    local screenshot_button = user_opts.screenshot_button

    if user_opts.compact_mode then
        user_opts.jump_buttons = false
        jump_buttons = false
    end
    local offset = jump_buttons and 60 or 0
    local outeroffset = (chapter_skip_buttons and 0 or 100) + (jump_buttons and 0 or 100)

    -- Title
    geo = {x = 25, y = refY - 117 + (((state.localDescription ~= nil or state.is_URL) and user_opts.show_description) and -20 or 0), an = 1, w = osc_geo.w - 50, h = 35}
    lo = add_layout("title")
    lo.geometry = geo
    lo.style = string.format("%s{\\clip(0,%f,%f,%f)}", osc_styles.title,
                             geo.y - geo.h, geo.x + geo.w, geo.y + geo.h)
    lo.alpha[3] = 0
    -- lo.button.maxchars = geo.w / 11

    -- Description
    if (state.localDescription ~= nil or state.is_URL) and user_opts.show_description then
        geo = {x = 25, y = refY - 117, an = 1, w = osc_geo.w - 50, h = 19}
        lo = add_layout("description")
        lo.geometry = geo

        lo.style = string.format("%s{\\clip(0,%f,%f,%f)}", osc_styles.description,
        geo.y - geo.h, geo.x + geo.w, geo.y + geo.h)

        lo.alpha[3] = 0
        -- lo.button.maxchars = geo.w / 7
    end

    -- Volumebar
    if user_opts.volume_control then
        lo = new_element("volumebarbg", "box")
        lo.visible = (osc_param.playresx >= 900 - outeroffset) and user_opts.volume_control
        lo = add_layout("volumebarbg")
        lo.geometry = {x = 155, y = refY - 40, an = 4, w = 80, h = 2}
        lo.layer = 13
        lo.alpha[1] = 128
        lo.style = user_opts.volumebar_match_seek_color and osc_styles.seekbar_bg or osc_styles.volumebar_bg

        lo = add_layout("volumebar")
        lo.geometry = {x = 155, y = refY - 40, an = 4, w = 80, h = 8}
        lo.style = user_opts.volumebar_match_seek_color and osc_styles.seekbar_fg or osc_styles.volumebar_fg
        lo.slider.gap = 3
        lo.slider.tooltip_style = osc_styles.tooltip
        lo.slider.tooltip_an = 2
    end

    -- buttons
    if track_nextprev_buttons then
        lo = add_layout('pl_prev')
        lo.geometry = {x = refX - (60 + (chapter_skip_buttons and 60 or 0)) - offset, y = refY - 40 , an = 5, w = 30, h = 24}
        lo.style = osc_styles.control_2
    end

    if chapter_skip_buttons then
        lo = add_layout('skipback')
        lo.geometry = {x = refX - 60 - offset, y = refY - 40 , an = 5, w = 30, h = 24}
        lo.style = osc_styles.control_2
    end

    if jump_buttons then
        lo = add_layout('jumpback')
        lo.geometry = {x = refX - 60, y = refY - 40 , an = 5, w = 30, h = 24}
        lo.style = osc_styles.control_2
    end

    lo = add_layout("play_pause")
    lo.geometry = {x = refX, y = refY - 40 , an = 5, w = 45, h = 45}
    lo.style = osc_styles.control_1

    if jump_buttons then
        lo = add_layout('jumpfrwd')
        lo.geometry = {x = refX + 60, y = refY - 40 , an = 5, w = 30, h = 24}
        -- HACK: jumpfrwd's icon must be mirrored for nonstandard # of seconds
        -- as the font only has an icon without a number for rewinding
        lo.style = (user_opts.jump_icon_number and icons.jumpicons[user_opts.jump_amount] ~= nil) and osc_styles.control_2 or osc_styles.control_2_flip
    end

    if chapter_skip_buttons then
        lo = add_layout('skipfrwd')
        lo.geometry = {x = refX + 60 + offset, y = refY - 40 , an = 5, w = 30, h = 24}
        lo.style = osc_styles.control_2
    end

    if track_nextprev_buttons then
        lo = add_layout('pl_next')
        lo.geometry = {x = refX + (60 + (chapter_skip_buttons and 60 or 0)) + offset, y = refY - 40 , an = 5, w = 30, h = 24}
        lo.style = osc_styles.control_2
    end

    -- Time
    local remsec = mp.get_property_number("playtime-remaining", 0)
    local possec = mp.get_property_number("playback-time", 0)
    local dur = mp.get_property_number("duration", 0)

    local show_hours = possec >= 3600 or user_opts.time_format ~= "dynamic"
    lo = add_layout("tc_left")
    lo.geometry = {x = 25, y = refY - 84, an = 7, w = 35 + (state.tc_ms and 30 or 0) + (show_hours and 20 or 0), h = 20}
    lo.style = osc_styles.time

    local show_remhours = (state.tc_right_rem and remsec >= 3600) or (not state.tc_right_rem and dur >= 3600) or user_opts.time_format ~= "dynamic"
    lo = add_layout("tc_right")
    lo.geometry = {x = osc_geo.w - 25 , y = refY -84, an = 9, w = 35 + (state.tc_ms and 30 or 0) + (show_remhours and 25 or 0), h = 20}
    lo.style = osc_styles.time

    -- Chapter Title (next to timestamp)
    if user_opts.show_chapter_title then
        lo = add_layout("separator")
        lo.geometry = {x = 65 + (state.tc_ms and 25 or 0) + (show_hours and 16 or 0), y = refY - 84, an = 7, w = 30, h = 20}
        lo.style = osc_styles.time

        lo = add_layout("chapter_title")
        lo.geometry = {x = 77 + (state.tc_ms and 25 or 0) + (show_hours and 16 or 0), y = refY - 84, an = 7, w = osc_geo.w - 200 - ((show_hours or state.tc_ms) and 60 or 0), h = 20}
        lo.style = osc_styles.chapter_title
    end

    -- Audio/Subtitle
    lo = add_layout('cy_audio')
    lo.geometry = {x = 37, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.control_3
    lo.visible = (osc_param.playresx >= 500 - outeroffset)

    lo = add_layout('cy_sub')
    lo.geometry = {x = 82, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.control_3
    lo.visible = (osc_param.playresx >= 600 - outeroffset)

    lo = add_layout('vol_ctrl')
    lo.geometry = {x = 127, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.control_3
    lo.visible = (osc_param.playresx >= 700 - outeroffset)

    -- Fullscreen/Loop/Info
    lo = add_layout('tog_fs')
    lo.geometry = {x = osc_geo.w - 37, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.control_3
    lo.visible = (osc_param.playresx >= 250 - outeroffset)

    if ontop_button then
        lo = add_layout('tog_ontop')
        lo.geometry = {x = osc_geo.w - 127 + (loop_button and 0 or 45), y = refY - 40, an = 5, w = 24, h = 24}
        lo.style = osc_styles.control_3
        lo.visible = (osc_param.playresx >= 700 - outeroffset)
    end

    if loop_button then
        lo = add_layout('tog_loop')
        lo.geometry = {x = osc_geo.w - 82, y = refY - 40, an = 5, w = 24, h = 24}
        lo.style = osc_styles.control_3
        lo.visible = (osc_param.playresx >= 600 - outeroffset)
    end

    if info_button then
        lo = add_layout('tog_info')
        lo.geometry = {x = osc_geo.w - 172 + (loop_button and 0 or 45) + (ontop_button and 0 or 45), y = refY - 40, an = 5, w = 24, h = 24}
        lo.style = osc_styles.control_3
        lo.visible = (osc_param.playresx >= 500 - outeroffset)
    end

    if screenshot_button then
        lo = add_layout('screenshot')
        lo.geometry = {x = osc_geo.w - 217 + (loop_button and 0 or 45) + (ontop_button and 0 or 45) + (info_button and 0 or 45), y = refY - 40, an = 5, w = 24, h = 24}
        lo.style = osc_styles.control_3
        lo.visible = (osc_param.playresx >= 300 - outeroffset)
    end

    if user_opts.download_button then
        lo = add_layout('download')
        lo.geometry = {x = osc_geo.w - 262 + (loop_button and 0 or 45) + (ontop_button and 0 or 45) + (info_button and 0 or 45) + (screenshot_button and 0 or 45), y = refY - 40, an = 5, w = 24, h = 24}
        lo.style = osc_styles.control_3
        lo.visible = (osc_param.playresx >= 400 - outeroffset)
    end
end

-- Reduced occupation layout
layouts["reduced"] = function ()
    local osc_geo = {
        w = osc_param.playresx,
        h = 180
    }

    -- origin of the controllers, left/bottom corner
    local posX = 0
    local posY = osc_param.playresy

    osc_param.areas = {} -- delete areas

    -- area for active mouse input
    add_area('input', get_hitbox_coords(posX, posY, 1, osc_geo.w, osc_geo.h))

    -- area for show/hide
    add_area('showhide', 0, 0, osc_param.playresx, osc_param.playresy)

    -- fetch values
    local osc_w, osc_h = osc_geo.w, osc_geo.h

    -- Controller Background
    local lo, geo

    new_element('box_bg', 'box')
    lo = add_layout('box_bg')
    lo.geometry = {x = posX, y = posY, an = 7, w = osc_w, h = 1}
    lo.style = osc_styles.box_bg
    lo.layer = 10
    lo.alpha[3] = 0

    local top_titlebar = window_controls_enabled() and (user_opts.window_title or user_opts.window_controls)

    if not user_opts.title_bar_box and (user_opts.window_top_bar == "yes" or (not state.border) or (not state.title_bar) or state.fullscreen) and top_titlebar then
        new_element("title_alpha_bg", "box")
        lo = add_layout("title_alpha_bg")
        lo.geometry = {x = posX, y = -100, an = 7, w = osc_w, h = -1}
        lo.style = osc_styles.box_bg
        lo.layer = 10
        lo.alpha[3] = 0
    end

    -- Alignment
    local refX = osc_w / 2
    local refY = posY

    -- Seekbar
    new_element('seekbarbg', 'box')
    lo = add_layout('seekbarbg')
    lo.geometry = {x = refX , y = refY - 75, an = 5, w = osc_geo.w - 200, h = 2}
    lo.layer = 13
    lo.style = osc_styles.seekbar_bg
    lo.alpha[1] = 128
    lo.alpha[3] = 128

    lo = add_layout('seekbar')
    lo.geometry = {x = refX, y = refY - 75, an = 5, w = osc_geo.w - 200, h = 16}
    lo.style = osc_styles.seekbar_fg
    lo.slider.gap = 7
    lo.slider.tooltip_style = osc_styles.tooltip
    lo.slider.tooltip_an = 2

    if (user_opts.persistent_progress or user_opts.persistent_progresstoggle) then
        lo = add_layout('persistentseekbar')
        lo.geometry = {x = refX, y = refY, an = 5, w = osc_geo.w, h = user_opts.persistent_progressheight}
        lo.style = osc_styles.seekbar_fg
        lo.slider.gap = 7
        lo.slider.tooltip_an = 0
    end

    local jump_buttons = user_opts.jump_buttons
    local chapter_skip_buttons = user_opts.chapter_skip_buttons
    local track_nextprev_buttons = user_opts.track_nextprev_buttons

    local loop_button = user_opts.loop_button
    local info_button = user_opts.info_button
    local ontop_button = user_opts.ontop_button
    local screenshot_button = user_opts.screenshot_button

    if user_opts.compact_mode then
        user_opts.jump_buttons = false
        jump_buttons = false
    end
    local offset = jump_buttons and 60 or 0
    local outeroffset = (chapter_skip_buttons and 0 or 100) + (jump_buttons and 0 or 100)

    -- Title
    geo = {x = 25, y = refY - 97, an = 1, w = osc_geo.w - 170, h = 35}
    lo = add_layout("title")
    lo.geometry = geo
    lo.style = string.format("%s{\\clip(0,%f,%f,%f)}", osc_styles.title,
                             geo.y - geo.h, geo.x + osc_geo.w - 170, geo.y + geo.h)
    lo.alpha[3] = 0
    lo.button.maxchars = geo.w / 5

    -- Description
    if (state.localDescription ~= nil or state.is_URL) and user_opts.show_description then
        geo = {x = osc_geo.w - 25, y = refY - 115, an = 9, w = 120, h = 19}
        lo = add_layout("description")
        lo.geometry = geo
        lo.style = string.format("%s{\\clip(0,%f,%f,%f)}", osc_styles.description,
        geo.y - geo.h, geo.x + geo.w, geo.y + geo.h)
        lo.alpha[3] = 0
        -- lo.button.maxchars = geo.w / 11
    end

    -- Volumebar
    if user_opts.volume_control then
        lo = new_element("volumebarbg", "box")
        lo.visible = (osc_param.playresx >= 900 - outeroffset) and user_opts.volume_control
        lo = add_layout("volumebarbg")
        lo.geometry = {x = 155, y = refY - 40, an = 4, w = 80, h = 2}
        lo.layer = 13
        lo.alpha[1] = 128
        lo.style = user_opts.volumebar_match_seek_color and osc_styles.seekbar_bg or osc_styles.volumebar_bg

        lo = add_layout("volumebar")
        lo.geometry = {x = 155, y = refY - 40, an = 4, w = 80, h = 8}
        lo.style = user_opts.volumebar_match_seek_color and osc_styles.seekbar_fg or osc_styles.volumebar_fg
        lo.slider.gap = 3
        lo.slider.tooltip_style = osc_styles.tooltip
        lo.slider.tooltip_an = 2
    end

    -- buttons
    if track_nextprev_buttons then
        lo = add_layout('pl_prev')
        lo.geometry = {x = refX - (60 + (chapter_skip_buttons and 60 or 0)) - offset, y = refY - 40 , an = 5, w = 30, h = 24}
        lo.style = osc_styles.control_2
    end

    if chapter_skip_buttons then
        lo = add_layout('skipback')
        lo.geometry = {x = refX - 60 - offset, y = refY - 40 , an = 5, w = 30, h = 24}
        lo.style = osc_styles.control_2
    end

    if jump_buttons then
        lo = add_layout('jumpback')
        lo.geometry = {x = refX - 60, y = refY - 40 , an = 5, w = 30, h = 24}
        lo.style = osc_styles.control_2
    end

    lo = add_layout("play_pause")
    lo.geometry = {x = refX, y = refY - 40 , an = 5, w = 45, h = 45}
    lo.style = osc_styles.control_1

    if jump_buttons then
        lo = add_layout('jumpfrwd')
        lo.geometry = {x = refX + 60, y = refY - 40 , an = 5, w = 30, h = 24}
        -- HACK: jumpfrwd's icon must be mirrored for nonstandard # of seconds
        -- as the font only has an icon without a number for rewinding
        lo.style = (user_opts.jump_icon_number and icons.jumpicons[user_opts.jump_amount] ~= nil) and osc_styles.control_2 or osc_styles.control_2_flip
    end

    if chapter_skip_buttons then
        lo = add_layout('skipfrwd')
        lo.geometry = {x = refX + 60 + offset, y = refY - 40 , an = 5, w = 30, h = 24}
        lo.style = osc_styles.control_2
    end

    if track_nextprev_buttons then
        lo = add_layout('pl_next')
        lo.geometry = {x = refX + (60 + (chapter_skip_buttons and 60 or 0)) + offset, y = refY - 40 , an = 5, w = 30, h = 24}
        lo.style = osc_styles.control_2
    end

    -- Time
    local remsec = mp.get_property_number("playtime-remaining", 0)
    local possec = mp.get_property_number("playback-time", 0)
    local dur = mp.get_property_number("duration", 0)

    local show_hours = possec >= 3600 or user_opts.time_format ~= "dynamic"
    lo = add_layout("tc_left")
    lo.geometry = {x = 25, y = refY - 84, an = 7, w = 35 + (state.tc_ms and 30 or 0) + (show_hours and 20 or 0), h = 20}
    lo.style = osc_styles.time

    local show_remhours = (state.tc_right_rem and remsec >= 3600) or (not state.tc_right_rem and dur >= 3600) or user_opts.time_format ~= "dynamic"
    lo = add_layout("tc_right")
    lo.geometry = {x = osc_geo.w - 25 , y = refY -84, an = 9, w = 35 + (state.tc_ms and 30 or 0) + (show_remhours and 25 or 0), h = 20}
    lo.style = osc_styles.time

    -- Chapter Title (next to timestamp)
    if user_opts.show_chapter_title then
        lo = add_layout("chapter_title")
        lo.geometry = {x = 25, y = refY - 125, an = 1, w = 120, h = 19}
        lo.style = osc_styles.chapter_title
    end

    -- Audio/Subtitle
    lo = add_layout('cy_audio')
    lo.geometry = {x = 37, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.control_3
    lo.visible = (osc_param.playresx >= 500 - outeroffset)

    lo = add_layout('cy_sub')
    lo.geometry = {x = 82, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.control_3
    lo.visible = (osc_param.playresx >= 600 - outeroffset)

    lo = add_layout('vol_ctrl')
    lo.geometry = {x = 127, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.control_3
    lo.visible = (osc_param.playresx >= 700 - outeroffset)

    -- Fullscreen/Loop/Info
    lo = add_layout('tog_fs')
    lo.geometry = {x = osc_geo.w - 37, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.control_3
    lo.visible = (osc_param.playresx >= 250 - outeroffset)

    if ontop_button then
        lo = add_layout('tog_ontop')
        lo.geometry = {x = osc_geo.w - 127 + (loop_button and 0 or 45), y = refY - 40, an = 5, w = 24, h = 24}
        lo.style = osc_styles.control_3
        lo.visible = (osc_param.playresx >= 700 - outeroffset)
    end

    if loop_button then
        lo = add_layout('tog_loop')
        lo.geometry = {x = osc_geo.w - 82, y = refY - 40, an = 5, w = 24, h = 24}
        lo.style = osc_styles.control_3
        lo.visible = (osc_param.playresx >= 600 - outeroffset)
    end

    if info_button then
        lo = add_layout('tog_info')
        lo.geometry = {x = osc_geo.w - 172 + (loop_button and 0 or 45) + (ontop_button and 0 or 45), y = refY - 40, an = 5, w = 24, h = 24}
        lo.style = osc_styles.control_3
        lo.visible = (osc_param.playresx >= 500 - outeroffset)
    end

    if screenshot_button then
        lo = add_layout('screenshot')
        lo.geometry = {x = osc_geo.w - 217 + (loop_button and 0 or 45) + (ontop_button and 0 or 45) + (info_button and 0 or 45), y = refY - 40, an = 5, w = 24, h = 24}
        lo.style = osc_styles.control_3
        lo.visible = (osc_param.playresx >= 300 - outeroffset)
    end

    if user_opts.download_button then
        lo = add_layout('download')
        lo.geometry = {x = osc_geo.w - 262 + (loop_button and 0 or 45) + (ontop_button and 0 or 45) + (info_button and 0 or 45) + (screenshot_button and 0 or 45), y = refY - 40, an = 5, w = 24, h = 24}
        lo.style = osc_styles.control_3
        lo.visible = (osc_param.playresx >= 400 - outeroffset)
    end
end

-- Validate string type user options
function validate_user_opts()
    if user_opts.window_top_bar ~= "auto" and
       user_opts.window_top_bar ~= "yes" and
       user_opts.window_top_bar ~= "no" then
        mp.msg.warn("window_top_bar cannot be '" .. user_opts.window_top_bar .. "'. Ignoring.")
        user_opts.window_top_bar = "auto"
    end

    if user_opts.volume_control_type ~= "linear" and
    user_opts.volume_control_type ~= "logarithmic" then
        mp.msg.warn("volume_control_type cannot be '" .. user_opts.volume_control_type .. "'. Ignoring.")
        user_opts.volume_control_type = "linear"
    end
end

function update_options(list)
    validate_user_opts()
    request_tick()
    visibility_mode("auto")
    request_init()
end

-- OSC INIT
local function osc_init()
    mp.msg.debug("osc_init")

    -- set canvas resolution according to display aspect and scaling setting
    local baseResY = 720
    local _, display_h, display_aspect = mp.get_osd_size()
    local scale

    if (mp.get_property("video") == "no") then -- dummy/forced window
        scale = user_opts.scale_forced_window
    elseif state.fullscreen then
        scale = user_opts.scale_fullscreen
    else
        scale = user_opts.scale_windowed
    end

    if user_opts.vid_scale then
        osc_param.unscaled_y = baseResY
    else
        osc_param.unscaled_y = display_h
    end
    osc_param.playresy = osc_param.unscaled_y / scale
    if display_aspect > 0 then
        osc_param.display_aspect = display_aspect
    end
    osc_param.playresx = osc_param.playresy * osc_param.display_aspect

    -- stop seeking with the slider to prevent skipping files
    state.active_element = nil

    elements = {}

    -- some often needed stuff
    local pl_count = mp.get_property_number("playlist-count", 0)
    local have_pl = pl_count > 1
    local pl_pos = mp.get_property_number("playlist-pos", 0) + 1
    local have_ch = mp.get_property_number("chapters", 0) > 0
    local loop = mp.get_property("loop-playlist", "no")

    local nojumpoffset = user_opts.jump_buttons and 0 or 100
    local noskipoffset = user_opts.chapter_skip_buttons and 0 or 100

    local compact_mode = user_opts.compact_mode
    if compact_mode then nojumpoffset = 100 end
    local outeroffset = (user_opts.chapter_skip_buttons and 0 or 140) + (user_opts.jump_buttons and 0 or 140)
    if compact_mode then outeroffset = 140 end

    local ne

    -- title
    ne = new_element("title", "button")
    ne.visible = user_opts.show_title
    ne.content = function ()
        local title = state.forced_title or
                      mp.command_native({"expand-text", user_opts.title})
        -- escape ASS, and strip newlines and trailing slashes
        title = title:gsub("\\n", " "):gsub("\\$", ""):gsub("{","\\{")
        return not (title == "") and title or "mpv video"
    end
    ne.eventresponder["mbtn_left_up"] = function ()
        local title = mp.get_property_osd("media-title")
        show_message(title)
    end
    ne.eventresponder["mbtn_right_up"] =
        function () show_message(mp.get_property_osd("filename")) end

    -- description
    ne = new_element('description', 'button')
    ne.visible = (state.localDescription ~= nil or state.is_URL) and user_opts.show_description
    ne.content = function ()
        if #state.videoDescription > 25 and user_opts.layout_option == "reduced" then
            return "View description"
        end

        if state.is_URL then
            local title = "Loading description..."
            if state.descriptionLoaded then
                title = state.videoDescription:sub(1, 300)

            end
            -- get rid of new lines
            title = string.gsub(title, '\\N', ' ')
            return not (title == "") and title or "error"
        else
            if (state.localDescription == nil) then
                return ""
            else
                return string.gsub(state.localDescription, '\\N', ' ')
            end
        end
    end
    ne.eventresponder['mbtn_left_up'] =
        function ()
            check_description()
        end

    -- playlist buttons
    -- prev
    ne = new_element('pl_prev', 'button')
    ne.visible = (osc_param.playresx >= 500 - nojumpoffset - noskipoffset*(nojumpoffset == 0 and 1 or 10))
    ne.content = icons.previous
    ne.enabled = (pl_pos > 1) or (loop ~= 'no')
    ne.eventresponder['mbtn_left_up'] =
        function ()
            mp.commandv('playlist-prev', 'weak')
            destroyscrollingkeys()
        end
    ne.eventresponder['enter'] =
        function ()
            mp.commandv('playlist-prev', 'weak')
            destroyscrollingkeys()
            show_message(get_playlist())
        end
    ne.eventresponder['mbtn_right_up'] =
        function () show_message(get_playlist()) end
    ne.eventresponder['shift+mbtn_left_down'] =
        function () show_message(get_playlist()) end

    --next
    ne = new_element('pl_next', 'button')
    ne.visible = (osc_param.playresx >= 500 - nojumpoffset - noskipoffset*(nojumpoffset == 0 and 1 or 10))
    ne.content = icons.next
    ne.enabled = (have_pl and (pl_pos < pl_count)) or (loop ~= 'no')
    ne.eventresponder['mbtn_left_up'] =
        function ()
            mp.commandv('playlist-next', 'weak')
            destroyscrollingkeys()
        end
    ne.eventresponder['enter'] =
        function ()
            mp.commandv('playlist-next', 'weak')
            destroyscrollingkeys()
            show_message(get_playlist())
        end
    ne.eventresponder['mbtn_right_up'] =
        function () show_message(get_playlist()) end
    ne.eventresponder['shift+mbtn_left_down'] =
        function () show_message(get_playlist()) end

    --play control buttons
    --playpause
    ne = new_element("play_pause", "button")
    ne.content = function ()
        if mp.get_property("eof-reached") == "yes" then
            return icons.replay
        elseif mp.get_property("pause") == "yes" and not state.playingWhilstSeeking then
            return icons.play
        else
            return icons.pause
        end
    end
    ne.eventresponder["mbtn_left_up"] = function ()
        if mp.get_property("eof-reached") == "yes" then
            mp.commandv("seek", 0, "absolute-percent")
            mp.commandv("set", "pause", "no")
        else
            mp.commandv("cycle", "pause")
        end
    end
    ne.eventresponder["mbtn_right_down"] = function ()
        if user_opts.loop_in_pause then
            mp.command("show-text '" .. (state.looping and texts.loopdisable or texts.loopenable) .. "'")
            state.looping = not state.looping
            mp.set_property_native("loop-file", state.looping)
        end
    end

    --skipback
    local jump_amount = user_opts.jump_amount
    local jump_more_amount = user_opts.jump_more_amount
    local jump_mode = user_opts.jump_mode
    local tempicons = icons.jumpicons.default

    ne = new_element('skipback', 'button')
    ne.visible = (osc_param.playresx >= 400 - nojumpoffset*10)
    ne.softrepeat = user_opts.chapter_softrepeat == true
    ne.content = icons.rewind
    ne.enabled = (have_ch) or compact_mode -- disables button when no chapters available.
    ne.eventresponder['mbtn_left_down'] =
        function ()
            if compact_mode then
                mp.commandv('seek', -jump_amount, jump_mode)
            else
                mp.commandv("add", "chapter", -1)
            end
        end
    ne.eventresponder['mbtn_right_down'] =
        function ()
            if compact_mode then
                mp.commandv("add", "chapter", -1)
                show_message(get_chapterlist())
                show_message(get_chapterlist()) -- run twice as it might show the wrong chapter without another function
            else
                show_message(get_chapterlist())
            end
        end
    ne.eventresponder['shift+mbtn_left_down'] =
        function ()
            mp.commandv('seek', -jump_more_amount, jump_mode)
        end
    ne.eventresponder['shift+mbtn_right_down'] =
        function () show_message(get_chapterlist()) end


    --skipfrwd
    ne = new_element('skipfrwd', 'button')
    ne.visible = (osc_param.playresx >= 400 - nojumpoffset*10)
    ne.softrepeat = user_opts.chapter_softrepeat == true
    ne.content = icons.forward
    ne.enabled = (have_ch) or compact_mode -- disables button when no chapters available.
    ne.eventresponder['mbtn_left_down'] =
        function ()
            if compact_mode then
                mp.commandv('seek', jump_amount, jump_mode)
            else
                mp.commandv("add", "chapter", 1)
            end
        end
    ne.eventresponder['mbtn_right_down'] =
        function ()
            if compact_mode then
                mp.commandv("add", "chapter", 1)
                show_message(get_chapterlist())
                show_message(get_chapterlist()) -- run twice as it might show the wrong chapter without another function    
            else
                show_message(get_chapterlist())
            end
        end
    ne.eventresponder['shift+mbtn_left_down'] =
        function ()
            mp.commandv('seek', jump_more_amount, jump_mode)
        end
    ne.eventresponder['shift+mbtn_right_down'] =
        function () show_message(get_chapterlist()) end

    if user_opts.jump_buttons then
        if user_opts.jump_icon_number then
            tempicons = icons.jumpicons[jump_amount] or icons.jumpicons.default
        end

        --jumpback
        ne = new_element('jumpback', 'button')

        ne.softrepeat = user_opts.jump_softrepeat == true
        ne.content = tempicons[1]
        ne.eventresponder['mbtn_left_down'] =
            function () mp.commandv('seek', -jump_amount, jump_mode) end
        ne.eventresponder['mbtn_right_down'] =
            function () mp.commandv('seek', -60, jump_mode) end
        ne.eventresponder['shift+mbtn_left_down'] =
            function () mp.commandv('frame-back-step') end


        --jumpfrwd
        ne = new_element('jumpfrwd', 'button')

        ne.softrepeat = user_opts.jump_softrepeat == true
        ne.content = tempicons[2]
        ne.eventresponder['mbtn_left_down'] =
            function () mp.commandv('seek', jump_amount, jump_mode) end
        ne.eventresponder['mbtn_right_down'] =
            function () mp.commandv('seek', 60, jump_mode) end
        ne.eventresponder['shift+mbtn_left_down'] =
            function () mp.commandv('frame-step') end
    end

    --
    update_tracklist()

    --cy_audio
    ne = new_element('cy_audio', 'button')
    ne.enabled = (#tracks_osc.audio > 0)
    ne.off = (get_track('audio') == 0)
    ne.visible = (osc_param.playresx >= 500 - outeroffset)
    ne.content = icons.audio
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        local message = texts.off
        if not (get_track('audio') == 0) then
            message = (texts.audio .. ' [' .. get_track('audio') .. ' ∕ ' .. #tracks_osc.audio .. ']')
            local prop = mp.get_property('current-tracks/audio/title')
            if not prop then
                prop = mp.get_property('current-tracks/audio/lang')
                if not prop then
                    prop = texts.na
                else
                    message = message .. ' [' .. prop .. ']'
                end
            end
            return message
        end
        if not ne.enabled then
            message = "No audio tracks"
        end
        return message
    end
    ne.nothingavailable = texts.noaudio
    ne.eventresponder['mbtn_left_up'] =
    function () set_track('audio', 1) show_message(get_tracklist('audio')) end
    ne.eventresponder['enter'] =
        function ()
            set_track('audio', 1)
            show_message(get_tracklist('audio'))
        end
    ne.eventresponder['mbtn_right_up'] =
        function () set_track('audio', -1) show_message(get_tracklist('audio')) end
    ne.eventresponder['shift+mbtn_left_down'] =
    function () set_track('audio', 1) show_message(get_tracklist('audio')) end
    ne.eventresponder['shift+mbtn_right_down'] =
        function () show_message(get_tracklist('audio')) end

    --cy_sub
    ne = new_element('cy_sub', 'button')
    ne.enabled = #tracks_osc.sub > 0
    ne.off = get_track('sub') == 0
    ne.visible = (osc_param.playresx >= 600 - outeroffset)
    ne.content = icons.subtitle
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        local message = texts.off
        if not (get_track('sub') == 0) then
            message = (texts.subtitle .. ' [' .. get_track('sub') .. ' ∕ ' .. #tracks_osc.sub .. ']')
            local prop = mp.get_property('current-tracks/sub/lang')
            if not prop then
                prop = texts.na
            else
                message = message .. ' [' .. prop .. ']'
            end
            prop = mp.get_property('current-tracks/sub/title')
            if prop then
                message = message .. ' ' .. prop
            end
            return message
        end
        return message
    end
    ne.nothingavailable = texts.nosub
    ne.eventresponder['mbtn_left_up'] =
        function ()
            mp.set_property_number("secondary-sid", 0)
            set_track('sub', 1)
            show_message(get_tracklist('sub'))
        end
    ne.eventresponder['enter'] =
        function ()
            mp.set_property_number("secondary-sid", 0)
            set_track('sub', 1)
            show_message(get_tracklist('sub'))
        end
    ne.eventresponder['mbtn_right_up'] =
        function ()
            mp.set_property_number("secondary-sid", 0)
            set_track('sub', -1)
            show_message(get_tracklist('sub'))
        end
    ne.eventresponder['shift+mbtn_left_down'] =
    function ()
        mp.set_property_number("secondary-sid", 0)
        set_track('sub', 1)
        show_message(get_tracklist('sub'))
    end
    ne.eventresponder['shift+mbtn_right_down'] =
        function () show_message(get_tracklist('sub')) end



    -- vol_ctrl
    ne = new_element("vol_ctrl", "button")
    ne.enabled = get_track("audio") > 0
    ne.off = get_track("audio") == 0
    ne.visible = (osc_param.playresx >= 700 - outeroffset) and user_opts.volume_control
    ne.content = function ()
        local volume = mp.get_property_number("volume", 0)
        if state.mute then
            return icons.volume_mute
        else
            if volume >= 75 then
                return icons.volume_high
            elseif volume >= 25 then
                return icons.volume_low
            else
                return icons.volume_quiet
            end
        end
    end
    ne.eventresponder['mbtn_left_up'] =
        function ()
            mp.commandv('cycle', 'mute')
        end
    ne.eventresponder["wheel_up_press"] =
        function ()
            if (state.mute) then mp.commandv('cycle', 'mute') end
            mp.commandv("osd-auto", "add", "volume", 5)
        end
    ne.eventresponder["wheel_down_press"] =
        function ()
            if (state.mute) then mp.commandv('cycle', 'mute') end
            mp.commandv("osd-auto", "add", "volume", -5)
        end

    --tog_fs
    ne = new_element('tog_fs', 'button')
    ne.content = function () return state.fullscreen and icons.fullscreen_exit or icons.fullscreen end
    ne.visible = (osc_param.playresx >= 250)
    ne.eventresponder['mbtn_left_up'] =
        function () mp.commandv('cycle', 'fullscreen') end

    --tog_loop
    ne = new_element('tog_loop', 'button')
    ne.content = function ()
        if (state.looping) then
            return (icons.loop_on)
        else
            return (icons.loop_off)
        end
    end
    ne.visible = (osc_param.playresx >= 600 - outeroffset)
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        local message = texts.loopenable
        if state.looping then
            message = texts.loopdisable
        end
        return message
    end
    ne.eventresponder['mbtn_left_up'] =
        function ()
            state.looping = not state.looping
            mp.set_property_native("loop-file", state.looping)
        end

    --download
    ne = new_element("download", "button")
    ne.content = function () return state.downloading and icons.downloading or icons.download end
    ne.visible = (osc_param.playresx >= 1100 - outeroffset - (user_opts.loop_button and 0 or 100) - (user_opts.ontop_button and 0 or 100) - (user_opts.info_button and 0 or 100) - (user_opts.screenshot_button and 0 or 100)) and state.is_URL
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function () return state.downloading and (texts.downloading .. "...") or (texts.download .. " (" .. state.file_size_normalized .. ")") end
    ne.eventresponder["mbtn_left_up"] = function ()
        if not state.videoCantBeDownloaded then
            local localpath = mp.command_native({"expand-path", user_opts.download_path})

            if state.downloaded_once then
                show_message("{\\an9}" .. texts.downloaded .. "...")
            elseif state.downloading then
                show_message("{\\an9}" .. texts.download_in_progress .. "...")
            else
                show_message("{\\an9}" .. texts.downloading .. "...")
                state.downloading = true

                -- use current or default ytdl-format
                local mpv_ytdl = (user_opts.ytdl_format and user_opts.ytdl_format ~= "") and user_opts.ytdl_format or  mp.get_property("file-local-options/ytdl-format") or mp.get_property("ytdl-format") or ""

                local command = {
                    "yt-dlp",
                    mpv_ytdl,
                    "--remux", "mp4",
                    "--add-metadata",
                    "--embed-subs",
                    "-o", "%(title)s.%(ext)s",
                    "-P", localpath,
                    state.url_path
                }

                exec_async(command, download_done)
            end
        else
            show_message("{\\an9}Can't be downloaded")
        end
    end

    --screenshot
    ne = new_element("screenshot", "button")
    ne.content = icons.screenshot
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = texts.screenshot
    ne.visible = (osc_param.playresx >= 900 - outeroffset - (user_opts.loop_button and 0 or 100) - (user_opts.ontop_button and 0 or 100) - (user_opts.info_button and 0 or 100))
    ne.eventresponder["mbtn_left_up"] = function ()
        local temp_sub_pos = mp.get_property("sub-pos")
        if user_opts.screenshot_flag == "subtitles" or user_opts.screenshot_flag == "subtitles+each-frame" then
            mp.commandv("set", "sub-pos", 100)
        end
        mp.commandv("osd-msg", "screenshot", user_opts.screenshot_flag)
        mp.commandv("set", "sub-pos", temp_sub_pos)
    end

    --tog_info
    ne = new_element('tog_info', 'button')
    ne.content = icons.info
    ne.visible = (osc_param.playresx >= 800 - outeroffset - (user_opts.loop_button and 0 or 100) - (user_opts.ontop_button and 0 or 100))
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = texts.statsinfo
    ne.eventresponder['mbtn_left_up'] =
        function () mp.commandv('script-binding', 'stats/display-stats-toggle') end

    --tog_ontop
    ne = new_element('tog_ontop', 'button')
    ne.content = function ()
        if mp.get_property('ontop') == 'no' then
            return (icons.ontop_on)
        else
            return (icons.ontop_off)
        end
    end
    ne.tooltip_style = osc_styles.tooltip
    ne.tooltipF = function ()
        local message = texts.ontopdisable
        if mp.get_property('ontop') == 'no' then
            message = texts.ontop
        end
        return message
    end
    ne.visible = (osc_param.playresx >= 700 - outeroffset - (user_opts.loop_button and 0 or 100))
    ne.eventresponder['mbtn_left_up'] =
        function ()
            mp.commandv("cycle", "ontop")
            if (state.initialborder == 'yes') then
                if (mp.get_property('ontop') == 'yes') then
                    mp.commandv('set', 'border', "no")

                else
                    mp.commandv('set', 'border', "yes")
                end
            end
        end

    ne.eventresponder['mbtn_right_up'] =
        function ()
            mp.commandv("cycle", "ontop")
        end

    --seekbar
    ne = new_element('seekbar', 'slider')
    ne.enabled = not (mp.get_property('percent-pos') == nil)
    ne.thumbnailable = true
    state.slider_element = ne.enabled and ne or nil  -- used for forced_title
    ne.slider.markerF = function ()
        local duration = mp.get_property_number('duration', nil)
        if duration then
            local chapters = mp.get_property_native("chapter-list", {})
            local markers = {}
            for n = 1, #chapters do
                markers[n] = (chapters[n].time / duration * 100)
            end
            return markers
        else
            return {}
        end
    end
    ne.slider.posF = function ()
            if mp.get_property_bool("eof-reached") then return 100 end
            return mp.get_property_number("percent-pos")
        end
    ne.slider.tooltipF = function (pos)
        state.touchingprogressbar = true
        local duration = mp.get_property_number("duration")
        if duration ~= nil and pos ~= nil then
            local possec = duration * (pos / 100)
            local time = mp.format_time(possec)
            -- If video is less than 1 hour, and the time format is not fixed, strip the "00:" prefix
            if possec < 3600 and user_opts.time_format ~= "fixed" then
                time = time:gsub("^00:", "")
            end
            return time
        else
            return ""
        end

    end
    ne.slider.seek_rangesF = function()
        if not user_opts.seek_range then
            return nil
        end
        local cache_state = state.cache_state
        if not cache_state then
            return nil
        end
        local duration = mp.get_property_number("duration")
        if (duration == nil) or duration <= 0 then
            return nil
        end
        local ranges = cache_state["seekable-ranges"]
        if #ranges == 0 then
            return nil
        end
        local nranges = {}
        for _, range in pairs(ranges) do
            nranges[#nranges + 1] = {
                ['start'] = 100 * range['start'] / duration,
                ['end'] = 100 * range['end'] / duration,
            }
        end
        return nranges
    end
    ne.eventresponder["mouse_move"] = --keyframe seeking when mouse is dragged
        function (element)
            if not element.state.mbtnleft then return end -- allow drag for mbtnleft only!
            -- mouse move events may pile up during seeking and may still get
            -- sent when the user is done seeking, so we need to throw away
            -- identical seeks
            if mp.get_property("pause") == "no" and user_opts.mouse_seek_pause then
                state.playingWhilstSeeking = true
                mp.commandv("cycle", "pause")
            end
            local seekto = get_slider_value(element)
            if element.state.lastseek == nil or element.state.lastseek ~= seekto then
                local flags = "absolute-percent"
                if not user_opts.seekbar_keyframes then
                    flags = flags .. "+exact"
                end
                mp.commandv("seek", seekto, flags)
                element.state.lastseek = seekto
            end

        end
    ne.eventresponder['mbtn_left_down'] = --exact seeks on left click
        function (element)
            element.state.mbtnleft = true
            mp.commandv("seek", get_slider_value(element), "absolute-percent", "exact")
        end
    ne.eventresponder["shift+mbtn_left_down"] = --keyframe seeks on shift+left click
        function (element)
            element.state.mbtnleft = true
            mp.commandv("seek", get_slider_value(element), "absolute-percent")
        end
    ne.eventresponder["mbtn_left_up"] =
        function (element)
            element.state.mbtnleft = false
        end
    ne.eventresponder["mbtn_right_down"] = function (element)
        if (mp.get_property_native("chapter-list/count") > 0) then
            local chapter
            local pos = get_slider_value(element)
            local diff = math.huge

            for i, marker in ipairs(element.slider.markerF()) do
                if math.abs(pos - marker) < diff then
                    diff = math.abs(pos - marker)
                    chapter = i
                end
            end

            if chapter then
                mp.set_property("chapter", chapter - 1)
            end
        end
    end
    ne.eventresponder["reset"] =
        function (element)
            element.state.lastseek = nil
            if (state.playingWhilstSeeking) then
                if mp.get_property("eof-reached") == "no" then
                    mp.commandv("cycle", "pause")
                end
                state.playingWhilstSeeking = false
            end
        end

    --volumebar
    if user_opts.volume_control then
        local volume_max = mp.get_property_number("volume-max") > 0 and mp.get_property_number("volume-max") or 100
        ne = new_element("volumebar", "slider")
        ne.visible = (osc_param.playresx >= 900 - outeroffset) and user_opts.volume_control
        ne.enabled = get_track('audio') > 0
        ne.slider = {min = {value = 0}, max = {value = volume_max}}
        ne.slider.markerF = function () return {} end
        ne.slider.seek_rangesF = function() return nil end
        ne.slider.posF = function ()
            local volume = mp.get_property_number("volume")
            if user_opts.volume_control_type == "logarithmic" then
                return math.sqrt(volume * 100)
            else
                return volume
            end
        end
        ne.slider.tooltipF = function (pos) return (get_track('audio') > 0) and set_volume(pos) or "" end
        ne.eventresponder["mouse_move"] = function (element)
            local pos = get_slider_value(element)
            local setvol = set_volume(pos)
            if element.state.lastseek == nil or element.state.lastseek ~= setvol then
                mp.commandv("osd-msg", "set", "volume", setvol)
                element.state.lastseek = setvol
            end
        end
        ne.eventresponder["mbtn_left_down"] = function (element)
            local pos = get_slider_value(element)
            mp.commandv("osd-msg", "set", "volume", set_volume(pos))
        end
        ne.eventresponder["reset"] = function (element) element.state.lastseek = nil end
        ne.eventresponder["wheel_up_press"] = function () mp.commandv("osd-msg", "add", "volume", 5) end
        ne.eventresponder["wheel_down_press"] = function () mp.commandv("osd-msg", "add", "volume", -5) end
    end

    --persistent seekbar
    if (user_opts.persistent_progress_default or user_opts.persistent_progress_toggle) then
        ne = new_element('persistentseekbar', 'slider')
        ne.enabled = not (mp.get_property('percent-pos') == nil)
        state.slider_element = ne.enabled and ne or nil  -- used for forced_title
        ne.slider.markerF = function ()
            return {}
        end
        ne.slider.posF = function ()
            if mp.get_property_bool("eof-reached") then return 100 end
            return mp.get_property_number('percent-pos', nil)
        end
        ne.slider.tooltipF = function()
            return ""
        end
        ne.slider.seek_rangesF = function()
            if user_opts.persistent_buffer then
                if not user_opts.seek_range then
                    return nil
                end
                local cache_state = state.cache_state
                if not cache_state then
                    return nil
                end
                local duration = mp.get_property_number('duration', nil)
                if (duration == nil) or duration <= 0 then
                    return nil
                end
                local ranges = cache_state['seekable-ranges']
                if #ranges == 0 then
                    return nil
                end
                local nranges = {}
                for _, range in pairs(ranges) do
                    nranges[#nranges + 1] = {
                        ['start'] = 100 * range['start'] / duration,
                        ['end'] = 100 * range['end'] / duration,
                    }
                end
                return nranges
            end
            return nil
        end
    end

    -- Helper function to format time
    local function format_time(seconds)
        if not seconds then return "--:--" end

        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local whole_seconds = math.floor(seconds % 60)
        local milliseconds = state.tc_ms and math.floor((seconds % 1) * 1000) or nil

        -- Always show HH:MM:SS if user_opts.time_format is "fixed"
        local force_hours = user_opts.time_format == "fixed"

        -- Format string templates
        local format_with_ms = (hours > 0 or force_hours) and "%02d:%02d:%02d.%03d" or "%02d:%02d.%03d"
        local format_without_ms = (hours > 0 or force_hours) and "%02d:%02d:%02d" or "%02d:%02d"

        if state.tc_ms then
            return string.format(format_with_ms,
                (hours > 0 or force_hours) and hours or minutes,
                (hours > 0 or force_hours) and minutes or whole_seconds,
                (hours > 0 or force_hours) and whole_seconds or milliseconds,
                (hours > 0 or force_hours) and milliseconds or nil)
        else
            return string.format(format_without_ms,
                (hours > 0 or force_hours) and hours or minutes,
                (hours > 0 or force_hours) and minutes or whole_seconds,
                (hours > 0 or force_hours) and whole_seconds or nil)
        end
    end

    -- Current position time display
    ne = new_element("tc_left", "button")
    ne.content = function()
        local playback_time = mp.get_property_number("playback-time", 0)
        return format_time(playback_time)
    end
    ne.eventresponder["mbtn_left_up"] = function()
        state.tc_ms = not state.tc_ms
        request_init()
    end

    -- Chapter title (below seekbar)
    local chapter_index = mp.get_property_number("chapter", -1)
    ne = new_element("separator", "button")
    ne.visible = true
    ne.content = function()
        if chapter_index >= 0 or state.buffering then
            return " • "
        else
            return ""
        end
    end

    ne = new_element("chapter_title", "button")
    ne.visible = true
    ne.content = function()
        if state.buffering then
            return "Buffering..." .. " " .. mp.get_property("cache-buffering-state") .. "%"
        else
            if user_opts.chapter_fmt ~= "no" and chapter_index >= 0 then
                request_init()
                local chapters = mp.get_property_native("chapter-list", {})
                local chapter_title = (chapters[chapter_index + 1] and chapters[chapter_index + 1].title ~= "") and chapters[chapter_index + 1].title
                    or chapter_index + 1 .. "/" .. #chapters
                chapter_title = mp.command_native({"escape-ass", chapter_title})
                return string.format(user_opts.chapter_fmt, chapter_title)
            end
        end
        return "" -- fallback
    end
    ne.eventresponder["mbtn_left_up"] = function() show_message(get_chapterlist()) end
    ne.eventresponder["mbtn_right_up"] = nil

    -- Total/remaining time display
    ne = new_element("tc_right", "button")
    ne.visible = (mp.get_property_number("duration", 0) > 0)
    ne.content = function()
        local duration = mp.get_property_number("duration", 0)
        if duration <= 0 then return "--:--" end

        local time_to_display = state.tc_right_rem and
            mp.get_property_number("playtime-remaining", 0) or duration

        local prefix = state.tc_right_rem and
            (user_opts.unicode_minus and UNICODE_MINUS or "-") or ""

        return prefix .. format_time(time_to_display)
    end
    ne.eventresponder["mbtn_left_up"] = function()
        state.tc_right_rem = not state.tc_right_rem
    end

    -- load layout
    layouts[user_opts.layout_option]()

    -- load window controls
    if window_controls_enabled() then
        window_controls()
    end

    --do something with the elements
    prepare_elements()
end

--
-- Other important stuff
--
function show_osc()
    -- show when disabled can happen (e.g. mouse_move) due to async/delayed unbinding
    if not state.enabled then return end

    mp.msg.trace('show_osc')
    --remember last time of invocation (mouse move)
    state.showtime = mp.get_time()

    osc_visible(true)

    if (user_opts.fade_duration > 0) then
        state.anitype = nil
    end
end

function hide_osc()
    mp.msg.trace('hide_osc')
    if not state.enabled then
        -- typically hide happens at render() from tick(), but now tick() is
        -- no-op and won't render again to remove the osc, so do that manually.
        state.osc_visible = false
        adjustSubtitles(false)
        render_wipe()
    elseif (user_opts.fade_duration > 0) then
        if not(state.osc_visible == false) then
            state.anitype = 'out'
            request_tick()
        end
    else
        osc_visible(false)
    end
    if thumbfast.available then
        mp.commandv("script-message-to", "thumbfast", "clear")
    end
end

function osc_visible(visible)
    if state.osc_visible ~= visible then
        state.osc_visible = visible
        adjustSubtitles(true)    -- raise subtitles
    end
    request_tick()
end

function adjustSubtitles(visible)
    if visible and user_opts.raise_subtitles and state.osc_visible == true and (state.fullscreen == false or user_opts.show_fullscreen) then
        local _, h = mp.get_osd_size()
        if h > 0 then
            local subpos = math.floor((osc_param.playresy - user_opts.raise_subtitle_amount)/osc_param.playresy*100)
            if subpos < 0 then
                subpos = 100 -- out of screen, default to original position
            end
            mp.commandv('set', 'sub-pos', subpos) -- percentage
        end
    elseif user_opts.raise_subtitles then
        mp.commandv('set', 'sub-pos', 100)
    end
end

function pause_state(name, enabled)
    -- fix OSC instantly hiding after scrubbing (initiates a 'fake' pause to stop issues when scrubbing to the end of files)
    if (state.playingWhilstSeeking) then state.playingWhilstSeekingWaitingForEnd = true return end
    if (state.playingWhilstSeekingWaitingForEnd) then state.playingWhilstSeekingWaitingForEnd = false return end
    state.paused = enabled
    if user_opts.show_on_pause then
        if enabled then
            visibility_mode("auto")
            show_osc()
        else
            visibility_mode("auto")
        end
    end
    request_tick()
end

function cache_state(name, st)
    state.cache_state = st
    request_tick()
end


local function mouse_leave()
    if get_hide_timeout() >= 0 then
        hide_osc()
    end
    -- reset mouse position
    state.last_mouseX, state.last_mouseY = nil, nil
    state.mouse_in_window = false
end

local function do_enable_key_bindings()
    if state.enabled then
        if not state.showhide_enabled then
            mp.enable_key_bindings('showhide', 'allow-vo-dragging+allow-hide-cursor')
            mp.enable_key_bindings('showhide_wc', 'allow-vo-dragging+allow-hide-cursor')
        end
        state.showhide_enabled = true
    end
end

local function enable_osc(enable)
    state.enabled = enable
    if enable then
        do_enable_key_bindings()
    else
        hide_osc() -- acts immediately when state.enabled == false
        if state.showhide_enabled then
            mp.disable_key_bindings('showhide')
            mp.disable_key_bindings('showhide_wc')
        end
        state.showhide_enabled = false
    end
end

local function render()
    mp.msg.trace('rendering')
    local current_screen_sizeX, current_screen_sizeY, aspect = mp.get_osd_size()
    local mouseX, mouseY = get_virt_mouse_pos()
    local now = mp.get_time()

    -- check if display changed, if so request reinit
    if not (state.mp_screen_sizeX == current_screen_sizeX
        and state.mp_screen_sizeY == current_screen_sizeY) then

        request_init_resize()

        state.mp_screen_sizeX = current_screen_sizeX
        state.mp_screen_sizeY = current_screen_sizeY
    end

    -- init management
    if state.active_element then
        -- mouse is held down on some element - keep ticking and igore initReq
        -- till it's released, or else the mouse-up (click) will misbehave or
        -- get ignored. that's because osc_init() recreates the osc elements,
        -- but mouse handling depends on the elements staying unmodified
        -- between mouse-down and mouse-up (using the index active_element).
        request_tick()
    elseif state.initREQ then
        osc_init()
        state.initREQ = false

        -- store initial mouse position
        if (state.last_mouseX == nil or state.last_mouseY == nil)
            and not (mouseX == nil or mouseY == nil) then

            state.last_mouseX, state.last_mouseY = mouseX, mouseY
        end
    end


    -- fade animation
    if not(state.anitype == nil) then

        if (state.anistart == nil) then
            state.anistart = now
        end

        if (now < state.anistart + (user_opts.fade_duration/1000)) then

            if (state.anitype == 'in') then --fade in
                osc_visible(true)
                state.animation = scale_value(state.anistart,
                    (state.anistart + (user_opts.fade_duration/1000)),
                    255, 0, now)
            elseif (state.anitype == 'out') then --fade out
                state.animation = scale_value(state.anistart,
                    (state.anistart + (user_opts.fade_duration/1000)),
                    0, 255, now)
            end

        else
            if (state.anitype == 'out') then
                osc_visible(false)
            end
            kill_animation()
        end
    else
        kill_animation()
    end

    -- mouse show/hide area
    for k,cords in pairs(osc_param.areas['showhide']) do
        set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, 'showhide')
    end
    if osc_param.areas['showhide_wc'] then
        for k,cords in pairs(osc_param.areas['showhide_wc']) do
            set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, 'showhide_wc')
        end
    else
        set_virt_mouse_area(0, 0, 0, 0, 'showhide_wc')
    end
    do_enable_key_bindings()

    -- mouse input area
    local mouse_over_osc = false

    for _,cords in ipairs(osc_param.areas['input']) do
        if state.osc_visible then -- activate only when OSC is actually visible
            set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, 'input')
        end
        if state.osc_visible ~= state.input_enabled then
            if state.osc_visible then
                mp.enable_key_bindings('input')
            else
                mp.disable_key_bindings('input')
            end
            state.input_enabled = state.osc_visible
        end

        if (mouse_hit_coords(cords.x1, cords.y1, cords.x2, cords.y2)) then
            mouse_over_osc = true
        end
    end

    if osc_param.areas['window-controls'] then
        for _,cords in ipairs(osc_param.areas['window-controls']) do
            if state.osc_visible then -- activate only when OSC is actually visible
                set_virt_mouse_area(cords.x1, cords.y1, cords.x2, cords.y2, 'window-controls')
                mp.enable_key_bindings('window-controls')
            else
                mp.disable_key_bindings('window-controls')
            end

            if (mouse_hit_coords(cords.x1, cords.y1, cords.x2, cords.y2)) then
                mouse_over_osc = true
            end
        end
    end

    if osc_param.areas['window-controls-title'] then
        for _,cords in ipairs(osc_param.areas['window-controls-title']) do
            if (mouse_hit_coords(cords.x1, cords.y1, cords.x2, cords.y2)) then
                mouse_over_osc = true
            end
        end
    end

    -- autohide
    if not (state.showtime == nil) and (get_hide_timeout() >= 0) then
        local timeout = state.showtime + (get_hide_timeout()/1000) - now
        if timeout <= 0 then
            if (state.active_element == nil) and (user_opts.bottom_hover or not (mouse_over_osc)) then
                if (not (state.paused and user_opts.keep_on_pause)) then
                    hide_osc()
                end
            end
        else
            -- the timer is only used to recheck the state and to possibly run
            -- the code above again
            if not state.hide_timer then
                state.hide_timer = mp.add_timeout(0, tick)
            end
            state.hide_timer.timeout = timeout
            -- re-arm
            state.hide_timer:kill()
            state.hide_timer:resume()
        end
    end


    -- actual rendering
    local ass = mp.assdraw.ass_new()

    -- Messages
    render_message(ass)

    -- actual OSC
    if state.osc_visible then
        render_elements(ass)
    end
    if user_opts.persistent_progress_default or state.persistent_progresstoggle then
        render_persistent_progressbar(ass)
    end

    -- submit
    set_osd(osc_param.playresy * osc_param.display_aspect, osc_param.playresy, ass.text)
end

--
-- Event handling
--

local function element_has_action(element, action)
    return element and element.eventresponder and
        element.eventresponder[action]
end

function process_event(source, what)
    local action = string.format('%s%s', source,
        what and ('_' .. what) or '')

    if what == 'down' or what == 'press' then

        reset_timeout() -- clicking resets the hideosc timer

        for n = 1, #elements do

            if mouse_hit(elements[n]) and
                elements[n].eventresponder and
                (elements[n].eventresponder[source .. '_up'] or
                    elements[n].eventresponder[action]) then

                if what == 'down' then
                    state.active_element = n
                    state.active_event_source = source
                end
                -- fire the down or press event if the element has one
                if element_has_action(elements[n], action) then
                    elements[n].eventresponder[action](elements[n])
                end

            end
        end

    elseif what == 'up' then

        if elements[state.active_element] then
            local n = state.active_element

            if n == 0 then
                --click on background (does not work)
            elseif element_has_action(elements[n], action) and
                mouse_hit(elements[n]) then

                elements[n].eventresponder[action](elements[n])
            end

            --reset active element
            if element_has_action(elements[n], 'reset') then
                elements[n].eventresponder['reset'](elements[n])
            end

        end
        state.active_element = nil
        state.mouse_down_counter = 0

    elseif source == 'mouse_move' then
        state.mouse_in_window = true

        local mouseX, mouseY = get_virt_mouse_pos()
        if (user_opts.min_mouse_move == 0) or
            (not ((state.last_mouseX == nil) or (state.last_mouseY == nil)) and
                ((math.abs(mouseX - state.last_mouseX) >= user_opts.min_mouse_move)
                    or (math.abs(mouseY - state.last_mouseY) >= user_opts.min_mouse_move)
                )
            ) then
                if user_opts.bottom_hover then -- if enabled, only show osc if mouse is hovering at the bottom of the screen (where the UI elements are)
                    local top_hover = window_controls_enabled() and (user_opts.window_title or user_opts.window_top_bar)
                    if mouseY > osc_param.playresy - (user_opts.bottom_hover_zone or 200) or
                        (user_opts.window_top_bar == "yes" or (not state.border) or (not state.title_bar) or state.fullscreen) and (mouseY < 40 and top_hover) then
                        show_osc()
                    else
                        hide_osc()
                    end
                else
                    show_osc()
                end
        end
        state.last_mouseX, state.last_mouseY = mouseX, mouseY

        local n = state.active_element
        if element_has_action(elements[n], action) then
            elements[n].eventresponder[action](elements[n])
        end
    end

    -- ensure rendering after any (mouse) event - icons could change etc
    request_tick()
end

-- called by mpv on every frame
function tick()
    if not state.enabled then return end

    if state.idle then -- this is the screen mpv opens to (not playing a file directly), or if you quit a video (idle=yes in mpv.conf)

        -- render idle message
        mp.msg.trace('idle message')
        local _, _, display_aspect = mp.get_osd_size()
        if display_aspect == 0 then
            return
        end
        local display_h = 360
        local display_w = display_h * display_aspect
        -- logo is rendered at 2^(6-1) = 32 times resolution with size 1800x1800
        local icon_x, icon_y = (display_w - 1800 / 32) / 2, 140
        local line_prefix = ('{\\rDefault\\an7\\1a&H00&\\bord0\\shad0\\pos(%f,%f)}'):format(icon_x, icon_y)

        local ass = mp.assdraw.ass_new()

        -- mpv logo
        if user_opts.idle_screen then
            for i, line in ipairs(logo_lines) do
                ass:new_event()
                ass:append(line_prefix .. line)
            end
        end

        -- Santa hat
        if is_december and user_opts.idle_screen and not user_opts.green_and_grumpy then
            for i, line in ipairs(santa_hat_lines) do
                ass:new_event()
                ass:append(line_prefix .. line)
            end
        end

        if user_opts.idle_screen then
            ass:new_event()
            ass:pos(display_w / 2, icon_y + 65)
            ass:an(8)
            ass:append("{\\fs24\\1c&H0&\\1c&HFFFFFF&}" .. texts.welcome)
        end
        set_osd(display_w, display_h, ass.text)

        if state.showhide_enabled then
            mp.disable_key_bindings('showhide')
            mp.disable_key_bindings('showhide_wc')
            state.showhide_enabled = false
        end


    elseif (state.fullscreen and user_opts.show_fullscreen)
        or (not state.fullscreen and user_opts.show_windowed) then

        -- render the OSC
        render()
    else
        -- Flush OSD
        render_wipe()
    end

    state.tick_last_time = mp.get_time()

    if state.anitype ~= nil then
        -- state.anistart can be nil - animation should now start, or it can
        -- be a timestamp when it started. state.idle has no animation.
        if not state.idle and
           (not state.anistart or
            mp.get_time() < 1 + state.anistart + user_opts.fade_duration/1000)
        then
            -- animating or starting, or still within 1s past the deadline
            request_tick()
        else
            kill_animation()
        end
    end
end

mp.register_event('start-file', newfilereset)
mp.register_event("file-loaded", startupevents)
mp.observe_property('track-list', nil, request_init)
mp.observe_property('playlist', nil, request_init)
mp.observe_property("chapter-list", "native", function(_, list) -- chapter list changes
    list = list or {}  -- safety, shouldn't return nil
    table.sort(list, function(a, b) return a.time < b.time end)
    state.chapter_list_pre_sponsorblock = list
    state.chapter_list = list
    -- make_sponsorblock_segments()
    request_init()
end)
mp.observe_property('seeking', nil, function()
    if user_opts.seek_resets_hide_timeout then
        reset_timeout()
    end
    if user_opts.osc_on_seek and not state.new_file_flag then
        show_osc()
    elseif state.new_file_flag then
        state.new_file_flag = false
    end
end)

if user_opts.key_bindings then
    local function changeChapter(number)
        mp.commandv("add", "chapter", number)
        reset_timeout()
        show_message(get_chapterlist())
    end

    -- chapter scrubbing
    mp.add_key_binding("ctrl+left", "prevfile", function()
        mp.commandv('playlist-prev', 'weak')
        destroyscrollingkeys()
    end);
    mp.add_key_binding("ctrl+right", "nextfile", function()
        mp.commandv('playlist-next', 'weak')
        destroyscrollingkeys()
    end);
    mp.add_key_binding("shift+left", "prevchapter", function()
        changeChapter(-1)
    end);
    mp.add_key_binding("shift+right", "nextchapter", function()
        changeChapter(1)
    end);

    -- extra key bindings
    mp.add_key_binding("x", "cycleaudiotracks", function()
        mp.set_property_number("secondary-sid", 0)
        set_track("audio", 1)
        show_message(get_tracklist("audio"))
    end);

    mp.add_key_binding("c", "cyclecaptions", function()
        mp.set_property_number("secondary-sid", 0)
        set_track("sub", 1)
        show_message(get_tracklist("sub"))
    end);

    if user_opts.persistent_progress_toggle then
        mp.add_key_binding("b", "persistenttoggle", function()
            if user_opts.persistent_progress_toggle then
                state.persistent_progresstoggle = not state.persistent_progresstoggle
                tick()
            end
        end);
    end

    if user_opts.show_description then
        mp.add_key_binding("d", "show_description", check_description);
    end

    mp.add_key_binding("tab", 'get_chapterlist', function() show_message(get_chapterlist()) end)

    mp.add_key_binding("p", "pinwindow", function()
        mp.commandv("cycle", "ontop")
        if state.initialborder == 'yes' then
            if mp.get_property('ontop') == 'yes' then
                show_message("Pinned window")
                mp.commandv('set', 'border', "no")
            else
                show_message("Unpinned window")
                mp.commandv('set', 'border', "yes")
            end
        end
    end);

    mp.add_key_binding(nil, 'show_osc', function() show_osc() end)
end

mp.observe_property('fullscreen', 'bool',
    function(name, val)
        state.fullscreen = val
        request_init_resize()
    end
)
mp.observe_property('mute', 'bool',
    function(name, val)
        state.mute = val
    end
)
mp.observe_property('paused-for-cache', 'bool',
    function(name, val)
        state.buffering = val
    end
)
mp.observe_property('loop-file', 'bool',
    function(name, val) -- ensure compatibility with auto looping scripts (eg: a script that sets videos under 2 seconds to loop by default)
        if (val == nil) then
            state.looping = true;
        else
            state.looping = false
        end
    end
)
mp.observe_property('border', 'bool',
    function(name, val)
        state.border = val
        request_init_resize()
    end
)
mp.observe_property('title-bar', 'bool',
    function(name, val)
        state.title_bar = val
        request_init_resize()
    end
)
mp.observe_property('window-maximized', 'bool',
    function(name, val)
        state.maximized = val
        request_init_resize()
    end
)
mp.observe_property('idle-active', 'bool',
    function(name, val)
        state.idle = val
        request_tick()
    end
)
mp.observe_property('pause', 'bool', pause_state)
mp.observe_property('demuxer-cache-state', 'native', cache_state)
mp.observe_property('vo-configured', 'bool', function(name, val)
    request_tick()
end)
mp.observe_property('playback-time', 'number', function(name, val)
    request_tick()
end)
mp.observe_property('osd-dimensions', 'native', function(name, val)
    -- (we could use the value instead of re-querying it all the time, but then
    --  we might have to worry about property update ordering)
    request_init_resize()
end)
mp.observe_property("display-fps", "number", set_tick_delay)
-- mouse show/hide bindings
mp.set_key_bindings({
    {'mouse_move',              function(e) process_event('mouse_move', nil) end},
    {'mouse_leave',             mouse_leave},
}, 'showhide', 'force')
mp.set_key_bindings({
    {'mouse_move',              function(e) process_event('mouse_move', nil) end},
    {'mouse_leave',             mouse_leave},
}, 'showhide_wc', 'force')
do_enable_key_bindings()

--mouse input bindings
mp.set_key_bindings({
    {"mbtn_left",           function(e) process_event("mbtn_left", "up") end,
                            function(e) process_event("mbtn_left", "down")  end},
    {"shift+mbtn_left",     function(e) process_event("shift+mbtn_left", "up") end,
                            function(e) process_event("shift+mbtn_left", "down")  end},
    {"shift+mbtn_right",    function(e) process_event("shift+mbtn_right", "up") end,
                            function(e) process_event("shift+mbtn_right", "down")  end},
    {"mbtn_right",          function(e) process_event("mbtn_right", "up") end,
                            function(e) process_event("mbtn_right", "down")  end},
    -- alias to shift_mbtn_left for single-handed mouse use
    {"mbtn_mid",            function(e) process_event("shift+mbtn_left", "up") end,
                            function(e) process_event("shift+mbtn_left", "down")  end},
    {"wheel_up",            function(e) process_event("wheel_up", "press") end},
    {"wheel_down",          function(e) process_event("wheel_down", "press") end},
    {"mbtn_left_dbl",       "ignore"},
    {"shift+mbtn_left_dbl", "ignore"},
    {"mbtn_right_dbl",      "ignore"},
}, "input", "force")
mp.enable_key_bindings('input')

mp.set_key_bindings({
    {'mbtn_left',           function(e) process_event('mbtn_left', 'up') end,
                            function(e) process_event('mbtn_left', 'down')  end},
}, 'window-controls', 'force')
mp.enable_key_bindings('window-controls')

function reset_timeout()
    state.showtime = mp.get_time()
end

-- mode can be auto/always/never/cycle
-- the modes only affect internal variables and not stored on its own.
function visibility_mode(mode)
    enable_osc(true)

    mp.set_property_native("user-data/osc/visibility", mode)

    -- Reset the input state on a mode change. The input state will be
    -- recalcuated on the next render cycle, except in 'never' mode where it
    -- will just stay disabled.
    mp.disable_key_bindings("input")
    mp.disable_key_bindings("window-controls")
    state.input_enabled = false
    request_tick()
end

mp.register_script_message("thumbfast-info", function(json)
    local data = mp.utils.parse_json(json)
    if type(data) ~= "table" or not data.width or not data.height then
        mp.msg.error("thumbfast-info: received json didn't produce a table with thumbnail information")
    else
        thumbfast = data
    end
end)

mp.register_script_message("sponsorblock-done", make_sponsorblock_segments)

set_virt_mouse_area(0, 0, 0, 0, 'input')
set_virt_mouse_area(0, 0, 0, 0, 'window-controls')
mp.set_property("title", "mpv")
