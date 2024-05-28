-- mpv-osc-modern by maoiscat
-- email:valarmor@163.com
-- https://github.com/maoiscat/mpv-osc-modern

-- fork by cyl0
-- https://github.com/cyl0/ModernX/

local assdraw = require 'mp.assdraw'
local msg = require 'mp.msg'
local opt = require 'mp.options'
local utils = require 'mp.utils'

--
-- Parameters
--
-- default user option values
-- may change them in osc.conf
local user_opts = {
    showwindowed = true,        -- show OSC when windowed?
    showfullscreen = true,      -- show OSC when fullscreen?
    idlescreen = true,          -- draw logo and text when idle
    scalewindowed = 1.0,        -- scaling of the controller when windowed
    scalefullscreen = 1.0,      -- scaling of the controller when fullscreen
    scaleforcedwindow = 2.0,    -- scaling when rendered on a forced window
    vidscale = true,            -- scale the controller with the video?
    hidetimeout = 1500,         -- duration in ms until the OSC hides if no
                                -- mouse movement. enforced non-negative for the
                                -- user, but internally negative is 'always-on'.
    fadeduration = 250,         -- duration of fade out in ms, 0 = no fade
    minmousemove = 1,           -- minimum amount of pixels the mouse has to
                                -- move between ticks to make the OSC show up
    iamaprogrammer = false,     -- use native mpv values and disable OSC
                                -- internal track list management (and some
                                -- functions that depend on it)
    font = 'mpv-osd-symbols',	-- default osc font
    seekbarhandlesize = 1.0,	-- size ratio of the slider handle, range 0 ~ 1
    seekrange = true,		-- show seekrange overlay
    seekrangealpha = 64,      	-- transparency of seekranges
    seekbarkeyframes = true,    -- use keyframes when dragging the seekbar
    showjump = true,            -- show "jump forward/backward 5 seconds" buttons 
                                -- shift+left-click to step 1 frame and 
                                -- right-click to jump 1 minute
    jumpamount = 5,             -- change the jump amount (in seconds by default)
    jumpiconnumber = true,      -- show different icon when jumpamount is 5, 10, or 30
    jumpmode = 'exact',         -- seek mode for jump buttons. e.g.
                                -- 'exact', 'relative+keyframes', etc.
    title = '${media-title}',   -- string compatible with property-expansion
                                -- to be shown as OSC title
    showtitle = true,		-- show title in OSC
    showonpause = true,         -- whether to disable the hide timeout on pause
    timetotal = true,          	-- display total time instead of remaining time?
    timems = false,             -- Display time down to millliseconds by default
    visibility = 'auto',        -- only used at init to set visibility_mode(...)
    windowcontrols = 'auto',    -- whether to show window controls
    greenandgrumpy = false,     -- disable santa hat
    language = 'eng',		-- eng=English, chs=Chinese
    volumecontrol = true,       -- whether to show mute button and volume slider
    keyboardnavigation = false, -- enable directional keyboard navigation
    chapter_fmt = "Chapter: %s", -- chapter print format for seekbar-hover. "no" to disable
}

-- Icons for jump button depending on jumpamount 
local jumpicons = { 
    [5] = {'\239\142\177', '\239\142\163'}, 
    [10] = {'\239\142\175', '\239\142\161'}, 
    [30] = {'\239\142\176', '\239\142\162'}, 
    default = {'\239\142\178	', '\239\142\178'}, -- second icon is mirrored in layout() 
} 

local icons = {
  previous = '\239\142\181',
  next = '\239\142\180',
  play = '\239\142\170',
  pause = '\239\142\167',
  backward = '\239\142\160',
  forward = '\239\142\159',
  audio = '\239\142\183',
  volume = '\239\142\188',
  volume_mute = '\239\142\187',
  sub = '\239\143\147',
  minimize = '\239\133\172',
  fullscreen = '\239\133\173',  
  info = '',
}

-- Localization
local language = {
	['eng'] = {
	    welcome = '{\\fs24\\1c&H0&\\1c&HFFFFFF&}Drop files or URLs to play here.',  -- this text appears when mpv starts
		off = 'OFF',
		na = 'n/a',
		none = 'none',
		video = 'Video',
		audio = 'Audio',
		subtitle = 'Subtitle',
		available = 'Available ',
		track = ' Tracks:',
		playlist = 'Playlist',
		nolist = 'Empty playlist.',
		chapter = 'Chapter',
		nochapter = 'No chapters.',
	},
	['chs'] = {
		welcome = '{\\1c&H00\\bord0\\fs30\\fn微软雅黑 light\\fscx125}MPV{\\fscx100} 播放器',  -- this text appears when mpv starts
		off = '关闭',
		na = 'n/a',
		none = '无',
		video = '视频',
		audio = '音频',
		subtitle = '字幕',
		available = '可选',
		track = '：',
		playlist = '播放列表',
		nolist = '无列表信息',
		chapter = '章节',
		nochapter = '无章节信息',
	},
	['pl'] = {
	    welcome = '{\\fs24\\1c&H0&\\1c&HFFFFFF&}Upuść plik lub łącze URL do odtworzenia.',  -- this text appears when mpv starts
		off = 'WYŁ.',
		na = 'n/a',
		none = 'nic',
		video = 'Wideo',
		audio = 'Ścieżka audio',
		subtitle = 'Napisy',
		available = 'Dostępne ',
		track = ' Ścieżki:',
		playlist = 'Lista odtwarzania',
		nolist = 'Lista odtwarzania pusta.',
		chapter = 'Rozdział',
		nochapter = 'Brak rozdziałów.',
	}
}
-- read options from config and command-line
opt.read_options(user_opts, 'osc', function(list) update_options(list) end)
-- apply lang opts
local texts = language[user_opts.language]
local osc_param = { -- calculated by osc_init()
    playresy = 0,                           -- canvas size Y
    playresx = 0,                           -- canvas size X
    display_aspect = 1,
    unscaled_y = 0,
    areas = {},
}

local osc_styles = {
    TransBg = '{\\blur100\\bord150\\1c&H000000&\\3c&H000000&}',
    SeekbarBg = '{\\blur0\\bord0\\1c&HFFFFFF&}',
    SeekbarFg = '{\\blur1\\bord1\\1c&HE39C42&}',
    VolumebarBg = '{\\blur0\\bord0\\1c&H999999&}',
    VolumebarFg = '{\\blur1\\bord1\\1c&HFFFFFF&}',
    Ctrl1 = '{\\blur0\\bord0\\1c&HFFFFFF&\\3c&HFFFFFF&\\fs36\\fnmaterial-design-iconic-font}',
    Ctrl2 = '{\\blur0\\bord0\\1c&HFFFFFF&\\3c&HFFFFFF&\\fs24\\fnmaterial-design-iconic-font}',
    Ctrl2Flip = '{\\blur0\\bord0\\1c&HFFFFFF&\\3c&HFFFFFF&\\fs24\\fnmaterial-design-iconic-font\\fry180',
    Ctrl3 = '{\\blur0\\bord0\\1c&HFFFFFF&\\3c&HFFFFFF&\\fs24\\fnmaterial-design-iconic-font}',
    Time = '{\\blur0\\bord0\\1c&HFFFFFF&\\3c&H000000&\\fs17\\fn' .. user_opts.font .. '}',
    Tooltip = '{\\blur1\\bord0.5\\1c&HFFFFFF&\\3c&H000000&\\fs18\\fn' .. user_opts.font .. '}',
    Title = '{\\blur1\\bord0.5\\1c&HFFFFFF&\\3c&H0\\fs38\\q2\\fn' .. user_opts.font .. '}',
    WinCtrl = '{\\blur1\\bord0.5\\1c&HFFFFFF&\\3c&H0\\fs20\\fnmpv-osd-symbols}',
    elementDown = '{\\1c&H999999&}',
    elementHighlight = '{\\blur1\\bord1\\1c&HFFC033&}',
}

-- internal states, do not touch
local state = {
    showtime,                               -- time of last invocation (last mouse move)
    osc_visible = false,
    anistart,                               -- time when the animation started
    anitype,                                -- current type of animation
    animation,                              -- current animation alpha
    mouse_down_counter = 0,                 -- used for softrepeat
    active_element = nil,                   -- nil = none, 0 = background, 1+ = see elements[]
    active_event_source = nil,              -- the 'button' that issued the current event
    rightTC_trem = not user_opts.timetotal, -- if the right timecode should display total or remaining time
    mp_screen_sizeX, mp_screen_sizeY,       -- last screen-resolution, to detect resolution changes to issue reINITs
    initREQ = false,                        -- is a re-init request pending?
    last_mouseX, last_mouseY,               -- last mouse position, to detect significant mouse movement
    mouse_in_window = false,
    message_text,
    message_hide_timer,
    fullscreen = false,
    tick_timer = nil,
    tick_last_time = 0,                     -- when the last tick() was run
    hide_timer = nil,
    cache_state = nil,
    idle = false,
    enabled = true,
    input_enabled = true,
    showhide_enabled = false,
    dmx_cache = 0,
    border = true,
    maximized = false,
    osd = mp.create_osd_overlay('ass-events'),
    mute = false,
    lastvisibility = user_opts.visibility,	-- save last visibility on pause if showonpause
    fulltime = user_opts.timems,
    highlight_element = 'cy_audio',
    chapter_list = {},                      -- sorted by time
}

local thumbfast = {
    width = 0,
    height = 0,
    disabled = true,
    available = false
}

local window_control_box_width = 138
local tick_delay = 0.03

local is_december = os.date("*t").month == 12

--- Automatically disable OSC
local builtin_osc_enabled = mp.get_property_native('osc')
if builtin_osc_enabled then
    mp.set_property_native('osc', false)
end

--


-- WindowControl helpers
function window_controls_enabled()
    val = user_opts.windowcontrols
    if val == 'auto' then
        return (not state.border) or state.fullscreen
    else
        return val ~= 'no'
    end
end



function build_keyboard_controls()

    -- prepare the main button row
    local bottom_button_line = {}
    table.insert(bottom_button_line, 'cy_audio')
    table.insert(bottom_button_line, 'cy_sub')
    table.insert(bottom_button_line, 'pl_prev')
    table.insert(bottom_button_line, 'skipback')
    if user_opts.showjump then
        table.insert(bottom_button_line, 'jumpback')
    end
    table.insert(bottom_button_line, 'playpause')
    if user_opts.showjump then
        table.insert(bottom_button_line, 'jumpfrwd')
    end
    table.insert(bottom_button_line, 'skipfrwd')
    table.insert(bottom_button_line, 'pl_next')
    table.insert(bottom_button_line, 'tog_info')
    table.insert(bottom_button_line, 'tog_fs')

    -- build up the main mapping object
    local mapping = {}
    if window_controls_enabled() then
        table.insert(mapping, {
            'minimize',
            'maximize',
            'close'
        })
    end
    table.insert(mapping, {
        'seekbar'
    })
    table.insert(mapping, bottom_button_line)

    return mapping
end


--
-- Helperfunctions
--

function set_osd(res_x, res_y, text)
    if state.osd.res_x == res_x and
       state.osd.res_y == res_y and
       state.osd.data == text then
        return
    end
    state.osd.res_x = res_x
    state.osd.res_y = res_y
    state.osd.data = text
    state.osd.z = 1000
    state.osd:update()
end

-- scale factor for translating between real and virtual ASS coordinates
function get_virt_scale_factor()
    local w, h = mp.get_osd_size()
    if w <= 0 or h <= 0 then
        return 0, 0
    end
    return osc_param.playresx / w, osc_param.playresy / h
end

-- return mouse position in virtual ASS coordinates (playresx/y)
function get_virt_mouse_pos()
    if state.mouse_in_window then
        local sx, sy = get_virt_scale_factor()
        local x, y = mp.get_mouse_pos()
        return x * sx, y * sy
    else
        return -1, -1
    end
end

function set_virt_mouse_area(x0, y0, x1, y1, name)
    local sx, sy = get_virt_scale_factor()
    mp.set_mouse_area(x0 / sx, y0 / sy, x1 / sx, y1 / sy, name)
end

function scale_value(x0, x1, y0, y1, val)
    local m = (y1 - y0) / (x1 - x0)
    local b = y0 - (m * x0)
    return (m * val) + b
end

-- returns hitbox spanning coordinates (top left, bottom right corner)
-- according to alignment
function get_hitbox_coords(x, y, an, w, h)

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

function get_hitbox_coords_geo(geometry)
    return get_hitbox_coords(geometry.x, geometry.y, geometry.an,
        geometry.w, geometry.h)
end

function get_element_hitbox(element)
    return element.hitbox.x1, element.hitbox.y1,
        element.hitbox.x2, element.hitbox.y2
end

function mouse_hit(element)
    return mouse_hit_coords(get_element_hitbox(element))
end

function mouse_hit_coords(bX1, bY1, bX2, bY2)
    local mX, mY = get_virt_mouse_pos()
    return (mX >= bX1 and mX <= bX2 and mY >= bY1 and mY <= bY2)
end

function limit_range(min, max, val)
    if val > max then
        val = max
    elseif val < min then
        val = min
    end
    return val
end

-- translate value into element coordinates
function get_slider_ele_pos_for(element, val)

    local ele_pos = scale_value(
        element.slider.min.value, element.slider.max.value,
        element.slider.min.ele_pos, element.slider.max.ele_pos,
        val)

    return limit_range(
        element.slider.min.ele_pos, element.slider.max.ele_pos,
        ele_pos)
end

-- translates global (mouse) coordinates to value
function get_slider_value_at(element, glob_pos)

    local val = scale_value(
        element.slider.min.glob_pos, element.slider.max.glob_pos,
        element.slider.min.value, element.slider.max.value,
        glob_pos)

    return limit_range(
        element.slider.min.value, element.slider.max.value,
        val)
end

-- get value at current mouse position
function get_slider_value(element)
    return get_slider_value_at(element, get_virt_mouse_pos())
end

function countone(val)
    if not (user_opts.iamaprogrammer) then
        val = val + 1
    end
    return val
end

-- multiplies two alpha values, formular can probably be improved
function mult_alpha(alphaA, alphaB)
    return 255 - (((1-(alphaA/255)) * (1-(alphaB/255))) * 255)
end

function add_area(name, x1, y1, x2, y2)
    -- create area if needed
    if (osc_param.areas[name] == nil) then
        osc_param.areas[name] = {}
    end
    table.insert(osc_param.areas[name], {x1=x1, y1=y1, x2=x2, y2=y2})
end

function ass_append_alpha(ass, alpha, modifier)
    local ar = {}

    for ai, av in pairs(alpha) do
        av = mult_alpha(av, modifier)
        if state.animation then
            av = mult_alpha(av, state.animation)
        end
        ar[ai] = av
    end

    ass:append(string.format('{\\1a&H%X&\\2a&H%X&\\3a&H%X&\\4a&H%X&}',
               ar[1], ar[2], ar[3], ar[4]))
end

function ass_draw_cir_cw(ass, x, y, r)
	ass:round_rect_cw(x-r, y-r, x+r, y+r, r)
end

function ass_draw_rr_h_cw(ass, x0, y0, x1, y1, r1, hexagon, r2)
    if hexagon then
        ass:hexagon_cw(x0, y0, x1, y1, r1, r2)
    else
        ass:round_rect_cw(x0, y0, x1, y1, r1, r2)
    end
end

function ass_draw_rr_h_ccw(ass, x0, y0, x1, y1, r1, hexagon, r2)
    if hexagon then
        ass:hexagon_ccw(x0, y0, x1, y1, r1, r2)
    else
        ass:round_rect_ccw(x0, y0, x1, y1, r1, r2)
    end
end


--
-- Tracklist Management
--

local nicetypes = {video = texts.video, audio = texts.audio, sub = texts.subtitle}

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
    local msg = texts.available .. nicetypes[type] .. texts.track
    if #tracks_osc[type] == 0 then
        msg = msg .. texts.none
    else
        for n = 1, #tracks_osc[type] do
            local track = tracks_osc[type][n]
            local lang, title, selected = 'unknown', '', '○'
            if not(track.lang == nil) then lang = track.lang end
            if not(track.title == nil) then title = track.title end
            if (track.id == tonumber(mp.get_property(type))) then
                selected = '●'
            end
            msg = msg..'\n'..selected..' '..n..': ['..lang..'] '..title
        end
    end
    return msg
end

-- relatively change the track of given <type> by <next> tracks
    --(+1 -> next, -1 -> previous)
function set_track(type, next)
    local current_track_mpv, current_track_osc
    if (mp.get_property(type) == 'no') then
        current_track_osc = 0
    else
        current_track_mpv = tonumber(mp.get_property(type))
        current_track_osc = tracks_mpv[type][current_track_mpv].osc_id
    end
    local new_track_osc = (current_track_osc + next) % (#tracks_osc[type] + 1)
    local new_track_mpv
    if new_track_osc == 0 then
        new_track_mpv = 'no'
    else
        new_track_mpv = tracks_osc[type][new_track_osc].id
    end

    mp.commandv('set', type, new_track_mpv)

--	if (new_track_osc == 0) then
--        show_message(nicetypes[type] .. ' Track: none')
--    else
--        show_message(nicetypes[type]  .. ' Track: '
--            .. new_track_osc .. '/' .. #tracks_osc[type]
--            .. ' ['.. (tracks_osc[type][new_track_osc].lang or 'unknown') ..'] '
--            .. (tracks_osc[type][new_track_osc].title or ''))
--    end
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

--
-- Element Management
--

local elements = {}

function prepare_elements()

    -- remove elements without layout or invisble
    local elements2 = {}
    for n, element in pairs(elements) do
        if not (element.layout == nil) and (element.visible) then
            table.insert(elements2, element)
        end
    end
    elements = elements2

    function elem_compare (a, b)
        return a.layout.layer < b.layout.layer
    end

    table.sort(elements, elem_compare)


    for _,element in pairs(elements) do

        local elem_geo = element.layout.geometry

        -- Calculate the hitbox
        local bX1, bY1, bX2, bY2 = get_hitbox_coords_geo(elem_geo)
        element.hitbox = {x1 = bX1, y1 = bY1, x2 = bX2, y2 = bY2}

        local style_ass = assdraw.ass_new()

        -- prepare static elements
        style_ass:append('{}') -- hack to troll new_event into inserting a \n
        style_ass:new_event()
        style_ass:pos(elem_geo.x, elem_geo.y)
        style_ass:an(elem_geo.an)
        style_ass:append(element.layout.style)

        element.style_ass = style_ass

        local static_ass = assdraw.ass_new()


        if (element.type == 'box') then
            --draw box
            static_ass:draw_start()
            ass_draw_rr_h_cw(static_ass, 0, 0, elem_geo.w, elem_geo.h,
                             element.layout.box.radius, element.layout.box.hexagon)
            static_ass:draw_stop()

        elseif (element.type == 'slider') then
            --draw static slider parts
            local slider_lo = element.layout.slider
            -- calculate positions of min and max points
			element.slider.min.ele_pos = user_opts.seekbarhandlesize * elem_geo.h / 2
			element.slider.max.ele_pos = elem_geo.w - element.slider.min.ele_pos
            element.slider.min.glob_pos = element.hitbox.x1 + element.slider.min.ele_pos
            element.slider.max.glob_pos = element.hitbox.x1 + element.slider.max.ele_pos

            static_ass:draw_start()
			-- a hack which prepares the whole slider area to allow center placements such like an=5
			static_ass:rect_cw(0, 0, elem_geo.w, elem_geo.h)
			static_ass:rect_ccw(0, 0, elem_geo.w, elem_geo.h)
            -- marker nibbles
            if not (element.slider.markerF == nil) and (slider_lo.gap > 0) then
                local markers = element.slider.markerF()
                for _,marker in pairs(markers) do
                    if (marker >= element.slider.min.value) and (marker <= element.slider.max.value) then
                        local s = get_slider_ele_pos_for(element, marker)
                        if (slider_lo.gap > 5) then -- draw triangles
                            --top
                            if (slider_lo.nibbles_top) then
                                static_ass:move_to(s - 3, slider_lo.gap - 5)
                                static_ass:line_to(s + 3, slider_lo.gap - 5)
                                static_ass:line_to(s, slider_lo.gap - 1)
                            end
                            --bottom
                            if (slider_lo.nibbles_bottom) then
                                static_ass:move_to(s - 3, elem_geo.h - slider_lo.gap + 5)
								static_ass:line_to(s, elem_geo.h - slider_lo.gap + 1)
                                static_ass:line_to(s + 3, elem_geo.h - slider_lo.gap + 5)
                            end
                        else -- draw 2x1px nibbles
                            --top
                            if (slider_lo.nibbles_top) then
                                static_ass:rect_cw(s - 1, 0, s + 1, slider_lo.gap);
                            end
                            --bottom
                            if (slider_lo.nibbles_bottom) then
                                static_ass:rect_cw(s - 1, elem_geo.h-slider_lo.gap, s + 1, elem_geo.h);
                            end
                        end
                    end
                end
            end
        end

        element.static_ass = static_ass

        -- if the element is supposed to be disabled,
        -- style it accordingly and kill the eventresponders
        if not (element.enabled) then
            element.layout.alpha[1] = 136
            element.eventresponder = nil
        end
        -- gray out the element if it is toggled off
        if (element.off) then
            element.layout.alpha[1] = 136
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

function render_elements(master_ass)
    -- when the slider is dragged or hovered and we have a target chapter name
    -- then we use it instead of the normal title. we calculate it before the
    -- render iterations because the title may be rendered before the slider.
    state.forced_title = nil
    if thumbfast.disabled then
        local se, ae = state.slider_element, elements[state.active_element]
        if user_opts.chapter_fmt ~= "no" and se and (ae == se or (not ae and mouse_hit(se))) then
            local dur = mp.get_property_number("duration", 0)
            if dur > 0 then
                local possec = get_slider_value(se) * dur / 100 -- of mouse pos
                local ch = get_chapter(possec)
                if ch and ch.title and ch.title ~= "" then
                    state.forced_title = string.format(user_opts.chapter_fmt, ch.title)
                end
            end
        end
    end

    for n=1, #elements do
        local element = elements[n]
        local style_ass = assdraw.ass_new()
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
                    style_ass:append(osc_styles.elementDown)
                end
                if (element.softrepeat) and (state.mouse_down_counter >= 15
                    and state.mouse_down_counter % 5 == 0) then

                    element.eventresponder[state.active_event_source..'_down'](element)
                end
                state.mouse_down_counter = state.mouse_down_counter + 1
            end
        end

        if user_opts.keyboardnavigation and state.highlight_element == element.name then
            style_ass:append(osc_styles.elementHighlight)
        end
        
        local elem_ass = assdraw.ass_new()
        elem_ass:merge(style_ass)
        
        if not (element.type == 'button') then
            elem_ass:merge(element.static_ass)
        end

        if (element.type == 'slider') then

            local slider_lo = element.layout.slider
            local elem_geo = element.layout.geometry
            local s_min = element.slider.min.value
            local s_max = element.slider.max.value
            -- draw pos marker
            local pos = element.slider.posF()
            local seekRanges = element.slider.seekRangesF()
			local rh = user_opts.seekbarhandlesize * elem_geo.h / 2 -- Handle radius
            local xp
            
            if pos then
                xp = get_slider_ele_pos_for(element, pos)
				ass_draw_cir_cw(elem_ass, xp, elem_geo.h/2, rh)
				elem_ass:rect_cw(0, slider_lo.gap, xp, elem_geo.h - slider_lo.gap)
            end

            if seekRanges then
				elem_ass:draw_stop()
				elem_ass:merge(element.style_ass)
				ass_append_alpha(elem_ass, element.layout.alpha, user_opts.seekrangealpha)
				elem_ass:merge(element.static_ass)

                for _,range in pairs(seekRanges) do
                    local pstart = get_slider_ele_pos_for(element, range['start'])
                    local pend = get_slider_ele_pos_for(element, range['end'])
					elem_ass:rect_cw(pstart - rh, slider_lo.gap, pend + rh, elem_geo.h - slider_lo.gap)
                end
            end

            elem_ass:draw_stop()
            
            -- add tooltip
            if not (element.slider.tooltipF == nil) then
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
                        if (an == 2) then
                            if (sliderpos < (s_min + 3)) then
                                an = an - 1
                            elseif (sliderpos > (s_max - 3)) then
                                an = an + 1
                            end
                        elseif (sliderpos > (s_max-s_min)/2) then
                            an = an + 1
                            tx = tx - 5
                        else
                            an = an - 1
                            tx = tx + 10
                        end
                    end

                    -- tooltip label
                    elem_ass:new_event()
                    elem_ass:pos(tx, ty)
                    elem_ass:an(an)
                    elem_ass:append(slider_lo.tooltip_style)
                    ass_append_alpha(elem_ass, slider_lo.alpha, 0)
                    elem_ass:append(tooltiplabel)
                    
                    -- thumbnail
                    if not thumbfast.disabled then
                        local osd_w = mp.get_property_number("osd-width")
                        if osd_w then
                            local r_w, r_h = get_virt_scale_factor()

                            local tooltip_font_size = 18
                            local thumbPad = 4
                            local thumbMarginX = 18 / r_w
                            local thumbMarginY = tooltip_font_size + thumbPad + 2 / r_h
                            local tooltipBgColor = "FFFFFF"
                            local tooltipBgAlpha = 80
                            local thumbX = math.min(osd_w - thumbfast.width - thumbMarginX, math.max(thumbMarginX, tx / r_w - thumbfast.width / 2))
                            local thumbY = (ty - thumbMarginY) / r_h - thumbfast.height

                            thumbX = math.floor(thumbX + 0.5)
                            thumbY = math.floor(thumbY + 0.5)

                            elem_ass:new_event()
                            elem_ass:pos(thumbX * r_w, ty - thumbMarginY - thumbfast.height * r_h)
                            elem_ass:an(7)
                            elem_ass:append(osc_styles.Tooltip)
                            elem_ass:draw_start()
                            elem_ass:rect_cw(-thumbPad * r_w, -thumbPad * r_h, (thumbfast.width + thumbPad) * r_w, (thumbfast.height + thumbPad) * r_h)
                            elem_ass:draw_stop()

                            mp.commandv("script-message-to", "thumbfast", "thumb",
                                mp.get_property_number("duration", 0) * (sliderpos / 100),
                                thumbX,
                                thumbY
                            )

                            local se, ae = state.slider_element, elements[state.active_element]
                            if user_opts.chapter_fmt ~= "no" and se and (ae == se or (not ae and mouse_hit(se))) then
                                local dur = mp.get_property_number("duration", 0)
                                if dur > 0 then
                                    local possec = get_slider_value(se) * dur / 100 -- of mouse pos
                                    local ch = get_chapter(possec)
                                    if ch and ch.title and ch.title ~= "" then
                                        elem_ass:new_event()
                                        elem_ass:pos((thumbX + thumbfast.width / 2) * r_w, thumbY * r_h - tooltip_font_size)
                                        elem_ass:an(an)
                                        elem_ass:append(slider_lo.tooltip_style)
                                        ass_append_alpha(elem_ass, slider_lo.alpha, 0)
                                        elem_ass:append(string.format(user_opts.chapter_fmt, ch.title))
                                    end
                                end
                            end
                        end
                    end
                else
                    if thumbfast.available then
                        mp.commandv("script-message-to", "thumbfast", "clear")
                    end
                end
            end

        elseif (element.type == 'button') then

            local buttontext
            if type(element.content) == 'function' then
                buttontext = element.content() -- function objects
            elseif not (element.content == nil) then
                buttontext = element.content -- text objects
            end
			
			buttontext = buttontext:gsub(':%((.?.?.?)%) unknown ', ':%(%1%)')  --gsub('%) unknown %(\'', '')

            local maxchars = element.layout.button.maxchars
            -- 认为1个中文字符约等于1.5个英文字符
            -- local charcount = buttontext:len()-  (buttontext:len()-select(2, buttontext:gsub('[^\128-\193]', '')))/1.5
            local charcount = (buttontext:len() + select(2, buttontext:gsub('[^\128-\193]', ''))*2) / 3
            if not (maxchars == nil) and (charcount > maxchars) then
                local limit = math.max(0, maxchars - 3)
                if (charcount > limit) then
                    while (charcount > limit) do
                        buttontext = buttontext:gsub('.[\128-\191]*$', '')
						charcount = (buttontext:len() + select(2, buttontext:gsub('[^\128-\193]', ''))*2) / 3
                    end
                    buttontext = buttontext .. '...'
                end
            end

            elem_ass:append(buttontext)
            
            -- add tooltip
			if not (element.tooltipF == nil) and element.enabled then
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
                    if type(element.tooltipF) == 'function' then
						tooltiplabel = element.tooltipF()
					else
						tooltiplabel = element.tooltipF
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
    local max = math.ceil(osc_param.unscaled_y*0.75 / fs)
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

function get_playlist()
    local pos = mp.get_property_number('playlist-pos', 0) + 1
    local count, limlist = limited_list('playlist', pos)
    if count == 0 then
        return texts.nolist
    end

    local message = string.format(texts.playlist .. ' [%d/%d]:\n', pos, count)
    for i, v in ipairs(limlist) do
        local title = v.title
        local _, filename = utils.split_path(v.filename)
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

function show_message(text, duration)

    --print('text: '..text..'   duration: ' .. duration)
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

    state.message_text = text

    if not state.message_hide_timer then
        state.message_hide_timer = mp.add_timeout(0, request_tick)
    end
    state.message_hide_timer:kill()
    state.message_hide_timer.timeout = duration
    state.message_hide_timer:resume()
    request_tick()
end

function render_message(ass)
    if state.message_hide_timer and state.message_hide_timer:is_enabled() and
       state.message_text
    then
        local _, lines = string.gsub(state.message_text, '\\N', '')

        local fontsize = tonumber(mp.get_property('options/osd-font-size'))
        local outline = tonumber(mp.get_property('options/osd-border-size'))
        local maxlines = math.ceil(osc_param.unscaled_y*0.75 / fontsize)
        local counterscale = osc_param.playresy / osc_param.unscaled_y

        fontsize = fontsize * counterscale / math.max(0.65 + math.min(lines/maxlines, 1), 1)
        outline = outline * counterscale / math.max(0.75 + math.min(lines/maxlines, 1)/2, 1)

        local style = '{\\bord' .. outline .. '\\fs' .. fontsize .. '}'


        ass:new_event()
        ass:append(style .. state.message_text)
    else
        state.message_text = nil
    end
end

--
-- Initialisation and Layout
--

function new_element(name, type)
    elements[name] = {}
    elements[name].type = type
    elements[name].name = name

    -- add default stuff
    elements[name].eventresponder = {}
    elements[name].visible = true
    elements[name].enabled = true
    elements[name].softrepeat = false
    elements[name].styledown = (type == 'button')
    elements[name].state = {}

    if (type == 'slider') then
        elements[name].slider = {min = {value = 0}, max = {value = 100}}
    end


    return elements[name]
end

function add_layout(name)
    if not (elements[name] == nil) then
        -- new layout
        elements[name].layout = {}

        -- set layout defaults
        elements[name].layout.layer = 50
        elements[name].layout.alpha = {[1] = 0, [2] = 255, [3] = 255, [4] = 255}

        if (elements[name].type == 'button') then
            elements[name].layout.button = {
                maxchars = nil,
            }
        elseif (elements[name].type == 'slider') then
            -- slider defaults
            elements[name].layout.slider = {
                border = 1,
                gap = 1,
                nibbles_top = true,
                nibbles_bottom = true,
                adjust_tooltip = true,
                tooltip_style = '',
                tooltip_an = 2,
                alpha = {[1] = 0, [2] = 255, [3] = 88, [4] = 255},
            }
        elseif (elements[name].type == 'box') then
            elements[name].layout.box = {radius = 0, hexagon = false}
        end

        return elements[name].layout
    else
        msg.error('Can\'t add_layout to element \''..name..'\', doesn\'t exist.')
    end
end

-- Window Controls
function window_controls()
    local wc_geo = {
        x = 0,
        y = 32,
        an = 1,
        w = osc_param.playresx,
        h = 32,
    }

    local controlbox_w = window_control_box_width
    local titlebox_w = wc_geo.w - controlbox_w

    -- Default alignment is 'right'
    local controlbox_left = wc_geo.w - controlbox_w
    local titlebox_left = wc_geo.x
    local titlebox_right = wc_geo.w - controlbox_w

    add_area('window-controls',
             get_hitbox_coords(controlbox_left, wc_geo.y, wc_geo.an,
                               controlbox_w, wc_geo.h))

    local lo

    local button_y = wc_geo.y - (wc_geo.h / 2)
    local first_geo =
        {x = controlbox_left + 27, y = button_y, an = 5, w = 40, h = wc_geo.h}
    local second_geo =
        {x = controlbox_left + 69, y = button_y, an = 5, w = 40, h = wc_geo.h}
    local third_geo =
        {x = controlbox_left + 115, y = button_y, an = 5, w = 40, h = wc_geo.h}

    -- Window control buttons use symbols in the custom mpv osd font
    -- because the official unicode codepoints are sufficiently
    -- exotic that a system might lack an installed font with them,
    -- and libass will complain that they are not present in the
    -- default font, even if another font with them is available.

    -- Close: ??
    ne = new_element('close', 'button')
    ne.content = '\238\132\149'
    ne.eventresponder['mbtn_left_up'] =
        function () mp.commandv('quit') end
    lo = add_layout('close')
    lo.geometry = third_geo
    lo.style = osc_styles.WinCtrl
    lo.alpha[3] = 0

    -- Minimize: ??
    ne = new_element('minimize', 'button')
    ne.content = '\\n\238\132\146'
    ne.eventresponder['mbtn_left_up'] =
        function () mp.commandv('cycle', 'window-minimized') end
    lo = add_layout('minimize')
    lo.geometry = first_geo
    lo.style = osc_styles.WinCtrl
    lo.alpha[3] = 0
    
    -- Maximize: ?? /??
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
    lo.style = osc_styles.WinCtrl
    lo.alpha[3] = 0
end

--
-- Layouts
--

local layouts = {}

-- Default layout
layouts = function ()

    local osc_geo = {w, h}

	osc_geo.w = osc_param.playresx
	osc_geo.h = 180

    -- origin of the controllers, left/bottom corner
    local posX = 0
    local posY = osc_param.playresy

    osc_param.areas = {} -- delete areas

    -- area for active mouse input
    add_area('input', get_hitbox_coords(posX, posY, 1, osc_geo.w, 104))

    -- area for show/hide
    add_area('showhide', 0, 0, osc_param.playresx, osc_param.playresy)

    -- fetch values
    local osc_w, osc_h=
        osc_geo.w, osc_geo.h

	--
    -- Controller Background
    --
	local lo

	new_element('TransBg', 'box')
	lo = add_layout('TransBg')
	lo.geometry = {x = posX, y = posY, an = 7, w = osc_w, h = 1}
	lo.style = osc_styles.TransBg
	lo.layer = 10
	lo.alpha[3] = 0
	
    --
    -- Alignment
    --
	local refX = osc_w / 2
	local refY = posY
	local geo
	
    --
    -- Seekbar
    --
    new_element('seekbarbg', 'box')
    lo = add_layout('seekbarbg')
    lo.geometry = {x = refX , y = refY - 96 , an = 5, w = osc_geo.w - 50, h = 2}
    lo.layer = 13
    lo.style = osc_styles.SeekbarBg
    lo.alpha[1] = 128
    lo.alpha[3] = 128

    lo = add_layout('seekbar')
    lo.geometry = {x = refX, y = refY - 96 , an = 5, w = osc_geo.w - 50, h = 16}
	lo.style = osc_styles.SeekbarFg
    lo.slider.gap = 7
    lo.slider.tooltip_style = osc_styles.Tooltip
    lo.slider.tooltip_an = 2

    local showjump = user_opts.showjump
    local offset = showjump and 60 or 0
    
    --
    -- Volumebar
    --
    lo = new_element('volumebarbg', 'box')
    lo.visible = (osc_param.playresx >= 750) and user_opts.volumecontrol
    lo = add_layout('volumebarbg')
    lo.geometry = {x = 155, y = refY - 40, an = 4, w = 80, h = 2}
    lo.layer = 13
    lo.style = osc_styles.VolumebarBg

    
    lo = add_layout('volumebar')
    lo.geometry = {x = 155, y = refY - 40, an = 4, w = 80, h = 8}
    lo.style = osc_styles.VolumebarFg
    lo.slider.gap = 3
    lo.slider.tooltip_style = osc_styles.Tooltip
    lo.slider.tooltip_an = 2

	-- buttons
    lo = add_layout('pl_prev')
    lo.geometry = {x = refX - 120 - offset, y = refY - 40 , an = 5, w = 30, h = 24}
    lo.style = osc_styles.Ctrl2

	lo = add_layout('skipback')
    lo.geometry = {x = refX - 60 - offset, y = refY - 40 , an = 5, w = 30, h = 24}
    lo.style = osc_styles.Ctrl2


    if showjump then
        lo = add_layout('jumpback')
        lo.geometry = {x = refX - 60, y = refY - 40 , an = 5, w = 30, h = 24}
        lo.style = osc_styles.Ctrl2
    end
			
    lo = add_layout('playpause')
    lo.geometry = {x = refX, y = refY - 40 , an = 5, w = 45, h = 45}
    lo.style = osc_styles.Ctrl1	

    if showjump then
        lo = add_layout('jumpfrwd')
        lo.geometry = {x = refX + 60, y = refY - 40 , an = 5, w = 30, h = 24}

        -- HACK: jumpfrwd's icon must be mirrored for nonstandard # of seconds
        -- as the font only has an icon without a number for rewinding
        lo.style = (user_opts.jumpiconnumber and jumpicons[user_opts.jumpamount] ~= nil) and osc_styles.Ctrl2 or osc_styles.Ctrl2Flip
    end

    lo = add_layout('skipfrwd')
    lo.geometry = {x = refX + 60 + offset, y = refY - 40 , an = 5, w = 30, h = 24}
    lo.style = osc_styles.Ctrl2	

    lo = add_layout('pl_next')
    lo.geometry = {x = refX + 120 + offset, y = refY - 40 , an = 5, w = 30, h = 24}
    lo.style = osc_styles.Ctrl2


	-- Time
    lo = add_layout('tc_left')
    lo.geometry = {x = 25, y = refY - 84, an = 7, w = 64, h = 20}
    lo.style = osc_styles.Time	
	

    lo = add_layout('tc_right')
    lo.geometry = {x = osc_geo.w - 25 , y = refY -84, an = 9, w = 64, h = 20}
    lo.style = osc_styles.Time	

    lo = add_layout('cy_audio')
	lo.geometry = {x = 37, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.Ctrl3
    lo.visible = (osc_param.playresx >= 540)
	
    lo = add_layout('cy_sub')
    lo.geometry = {x = 87, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.Ctrl3
    lo.visible = (osc_param.playresx >= 600)

    lo = add_layout('vol_ctrl')
    lo.geometry = {x = 137, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.Ctrl3
    lo.visible = (osc_param.playresx >= 650)

	lo = add_layout('tog_fs')
    lo.geometry = {x = osc_geo.w - 37, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.Ctrl3
    lo.visible = (osc_param.playresx >= 540)    

	lo = add_layout('tog_info')
    lo.geometry = {x = osc_geo.w - 87, y = refY - 40, an = 5, w = 24, h = 24}
    lo.style = osc_styles.Ctrl3
    lo.visible = (osc_param.playresx >= 600)
    
    geo = { x = 25, y = refY - 132, an = 1, w = osc_geo.w - 50, h = 48 }
    lo = add_layout('title')
    lo.geometry = geo
    lo.style = string.format('%s{\\clip(%f,%f,%f,%f)}', osc_styles.Title,
								geo.x, geo.y - geo.h, geo.x + geo.w , geo.y + 5)
	lo.alpha[3] = 0
    lo.button.maxchars = geo.w / 23
end

-- Validate string type user options
function validate_user_opts()
    if user_opts.windowcontrols ~= 'auto' and
       user_opts.windowcontrols ~= 'yes' and
       user_opts.windowcontrols ~= 'no' then
        msg.warn('windowcontrols cannot be \'' ..
                user_opts.windowcontrols .. '\'. Ignoring.')
        user_opts.windowcontrols = 'auto'
    end
end

function update_options(list)
    validate_user_opts()
    request_tick()
    visibility_mode(user_opts.visibility, true)
    update_duration_watch()
    request_init()
end

-- OSC INIT
function osc_init()
    msg.debug('osc_init')

    -- set canvas resolution according to display aspect and scaling setting
    local baseResY = 720
    local display_w, display_h, display_aspect = mp.get_osd_size()
    local scale = 1

    if (mp.get_property('video') == 'no') then -- dummy/forced window
        scale = user_opts.scaleforcedwindow
    elseif state.fullscreen then
        scale = user_opts.scalefullscreen
    else
        scale = user_opts.scalewindowed
    end

    if user_opts.vidscale then
        osc_param.unscaled_y = baseResY
    else
        osc_param.unscaled_y = display_h
    end
    osc_param.playresy = osc_param.unscaled_y / scale
    if (display_aspect > 0) then
        osc_param.display_aspect = display_aspect
    end
    osc_param.playresx = osc_param.playresy * osc_param.display_aspect

    -- stop seeking with the slider to prevent skipping files
    state.active_element = nil

    elements = {}

    -- some often needed stuff
    local pl_count = mp.get_property_number('playlist-count', 0)
    local have_pl = (pl_count > 1)
    local pl_pos = mp.get_property_number('playlist-pos', 0) + 1
    local have_ch = (mp.get_property_number('chapters', 0) > 0)
    local loop = mp.get_property('loop-playlist', 'no')

    local ne

    -- playlist buttons
    -- prev
    ne = new_element('pl_prev', 'button')

    ne.content = icons.previous
    ne.enabled = (pl_pos > 1) or (loop ~= 'no')
    ne.eventresponder['mbtn_left_up'] =
        function ()
            mp.commandv('playlist-prev', 'weak')
        end
    ne.eventresponder['mbtn_right_up'] =
        function () show_message(get_playlist()) end

    --next
    ne = new_element('pl_next', 'button')

    ne.content = icons.next
    ne.enabled = (have_pl and (pl_pos < pl_count)) or (loop ~= 'no')
    ne.eventresponder['mbtn_left_up'] =
        function ()
            mp.commandv('playlist-next', 'weak')
        end
    ne.eventresponder['mbtn_right_up'] =
        function () show_message(get_playlist()) end


    --play control buttons
    --playpause
    ne = new_element('playpause', 'button')

    ne.content = function ()
        if mp.get_property('pause') == 'yes' then
            return (icons.play)
        else
            return (icons.pause)
        end
    end
    ne.eventresponder['mbtn_left_up'] =
        function () mp.commandv('cycle', 'pause') end
    --ne.eventresponder['mbtn_right_up'] =
    --    function () mp.commandv('script-binding', 'open-file-dialog') end

    if user_opts.showjump then
        local jumpamount = user_opts.jumpamount
        local jumpmode = user_opts.jumpmode
        local icons = jumpicons.default
        if user_opts.jumpiconnumber then
            icons = jumpicons[jumpamount] or jumpicons.default
        end

        --jumpback
        ne = new_element('jumpback', 'button')

        ne.softrepeat = true
        ne.content = icons[1]
        ne.eventresponder['mbtn_left_down'] =
            --function () mp.command('seek -5') end
            function () mp.commandv('seek', -jumpamount, jumpmode) end
        ne.eventresponder['shift+mbtn_left_down'] =
            function () mp.commandv('frame-back-step') end
        ne.eventresponder['mbtn_right_down'] =
            --function () mp.command('seek -60') end
            function () mp.commandv('seek', -60, jumpmode) end
        ne.eventresponder['enter'] =
            --function () mp.command('seek -5') end
            function () mp.commandv('seek', -jumpamount, jumpmode) end


        --jumpfrwd
        ne = new_element('jumpfrwd', 'button')

        ne.softrepeat = true
        ne.content = icons[2]
        ne.eventresponder['mbtn_left_down'] =
            --function () mp.command('seek +5') end
            function () mp.commandv('seek', jumpamount, jumpmode) end
        ne.eventresponder['shift+mbtn_left_down'] =
            function () mp.commandv('frame-step') end
        ne.eventresponder['mbtn_right_down'] =
            --function () mp.command('seek +60') end
            function () mp.commandv('seek', 60, jumpmode) end
        ne.eventresponder['enter'] =
            --function () mp.command('seek +5') end
            function () mp.commandv('seek', jumpamount, jumpmode) end
    end
    

    --skipback
    ne = new_element('skipback', 'button')

    ne.softrepeat = true
    ne.content = icons.backward
    ne.enabled = (have_ch) -- disables button when no chapters available.
    ne.eventresponder['mbtn_left_down'] =
        --function () mp.command('seek -5') end
        --function () mp.commandv('seek', -5, 'relative', 'keyframes') end
        function () mp.commandv("add", "chapter", -1) end
    --ne.eventresponder['shift+mbtn_left_down'] =
        --function () mp.commandv('frame-back-step') end
    ne.eventresponder['mbtn_right_down'] =
        function () show_message(get_chapterlist()) end
        --function () mp.command('seek -60') end
        --function () mp.commandv('seek', -60, 'relative', 'keyframes') end
    ne.eventresponder['enter'] =
        --function () mp.command('seek -5') end
        --function () mp.commandv('seek', -5, 'relative', 'keyframes') end
        function () mp.commandv("add", "chapter", -1) end

    --skipfrwd
    ne = new_element('skipfrwd', 'button')

    ne.softrepeat = true
    ne.content = icons.forward
    ne.enabled = (have_ch) -- disables button when no chapters available.
    ne.eventresponder['mbtn_left_down'] =
        --function () mp.command('seek +5') end
        --function () mp.commandv('seek', 5, 'relative', 'keyframes') end
        function () mp.commandv("add", "chapter", 1) end
    --ne.eventresponder['shift+mbtn_left_down'] =
        --function () mp.commandv('frame-step') end
    ne.eventresponder['mbtn_right_down'] =
        function () show_message(get_chapterlist()) end
        --function () mp.command('seek +60') end
        --function () mp.commandv('seek', 60, 'relative', 'keyframes') end
    ne.eventresponder['enter'] =
        --function () mp.command('seek +5') end
        --function () mp.commandv('seek', 5, 'relative', 'keyframes') end
        function () mp.commandv("add", "chapter", 1) end

    --
    update_tracklist()
    
    --cy_audio
    ne = new_element('cy_audio', 'button')
    ne.enabled = (#tracks_osc.audio > 0)
    ne.off = (get_track('audio') == 0)
    ne.visible = (osc_param.playresx >= 540)
    ne.content = icons.audio
    ne.tooltip_style = osc_styles.Tooltip
    ne.tooltipF = function ()
		local msg = texts.off
        if not (get_track('audio') == 0) then
            msg = (texts.audio .. ' [' .. get_track('audio') .. ' ∕ ' .. #tracks_osc.audio .. '] ')
            local prop = mp.get_property('current-tracks/audio/title') --('current-tracks/audio/lang')
            if not prop then
				prop = texts.na
			end
			msg = msg .. '[' .. prop .. ']'
			prop = mp.get_property('current-tracks/audio/lang') --('current-tracks/audio/title')
			if prop then
				msg = msg .. ' ' .. prop
			end
			return msg
        end
        return msg
    end
    ne.eventresponder['mbtn_left_up'] =
        function () set_track('audio', 1) end
    ne.eventresponder['mbtn_right_up'] =
        function () set_track('audio', -1) end
    ne.eventresponder['shift+mbtn_left_down'] =
        function () show_message(get_tracklist('audio')) end
    ne.eventresponder['enter'] =
        function () set_track('audio', 1); show_message(get_tracklist('audio')) end
                
    --cy_sub
    ne = new_element('cy_sub', 'button')
    ne.enabled = (#tracks_osc.sub > 0)
    ne.off = (get_track('sub') == 0)
    ne.visible = (osc_param.playresx >= 600)
    ne.content = icons.sub
    ne.tooltip_style = osc_styles.Tooltip
    ne.tooltipF = function ()
		local msg = texts.off
        if not (get_track('sub') == 0) then
            msg = (texts.subtitle .. ' [' .. get_track('sub') .. ' ∕ ' .. #tracks_osc.sub .. '] ')
            local prop = mp.get_property('current-tracks/sub/lang')
            if not prop then
				prop = texts.na
			end
			msg = msg .. '[' .. prop .. ']'
			prop = mp.get_property('current-tracks/sub/title')
			if prop then
				msg = msg .. ' ' .. prop
			end
			return msg
        end
        return msg
    end
    ne.eventresponder['mbtn_left_up'] =
        function () set_track('sub', 1) end
    ne.eventresponder['mbtn_right_up'] =
        function () set_track('sub', -1) end
    ne.eventresponder['shift+mbtn_left_down'] =
        function () show_message(get_tracklist('sub')) end
    ne.eventresponder['enter'] =
        function () set_track('sub', 1); show_message(get_tracklist('sub')) end
    
    -- vol_ctrl
    ne = new_element('vol_ctrl', 'button')
    ne.enabled = (get_track('audio')>0)
    ne.visible = (osc_param.playresx >= 650) and user_opts.volumecontrol
    ne.content = function ()
        if (state.mute) then
            return (icons.volume_mute)
        else
            return (icons.volume)
        end
    end
    ne.eventresponder['mbtn_left_up'] =
        function () mp.commandv('cycle', 'mute') end
    ne.eventresponder["wheel_up_press"] =
        function () mp.commandv("osd-auto", "add", "volume", 5) end
    ne.eventresponder["wheel_down_press"] =
        function () mp.commandv("osd-auto", "add", "volume", -5) end
    
    --tog_fs
    ne = new_element('tog_fs', 'button')
    ne.content = function ()
        if (state.fullscreen) then
            return (icons.minimize)
        else
            return (icons.fullscreen)
        end
    end
    ne.visible = (osc_param.playresx >= 540)
    ne.eventresponder['mbtn_left_up'] =
        function () mp.commandv('cycle', 'fullscreen') end

    --tog_info
    ne = new_element('tog_info', 'button')
    ne.content = icons.info
    ne.visible = (osc_param.playresx >= 600)
    ne.eventresponder['mbtn_left_up'] =
        function () mp.commandv('script-binding', 'stats/display-stats-toggle') end

    -- title
    ne = new_element('title', 'button')
    ne.content = function ()
        local title = state.forced_title or
                      mp.command_native({"expand-text", user_opts.title})
        if state.paused then
			title = title:gsub('\\n', ' '):gsub('\\$', ''):gsub('{','\\{')
		else
			title = title:gsub('\\n', ' '):gsub('\\$', ''):gsub('{','\\{') --title = ' '
		end
        return not (title == '') and title or ' '
    end
    ne.visible = osc_param.playresy >= 320 and user_opts.showtitle
    
    --seekbar
    ne = new_element('seekbar', 'slider')

    ne.enabled = not (mp.get_property('percent-pos') == nil)
    state.slider_element = ne.enabled and ne or nil  -- used for forced_title
    ne.slider.markerF = function ()
        local duration = mp.get_property_number('duration', nil)
        if not (duration == nil) then
            local chapters = mp.get_property_native('chapter-list', {})
            local markers = {}
            for n = 1, #chapters do
                markers[n] = (chapters[n].time / duration * 100)
            end
            return markers
        else
            return {}
        end
    end
    ne.slider.posF =
        function () return mp.get_property_number('percent-pos', nil) end
    ne.slider.tooltipF = function (pos)
        local duration = mp.get_property_number('duration', nil)
        if not ((duration == nil) or (pos == nil)) then
            possec = duration * (pos / 100)
            return mp.format_time(possec)
        else
            return ''
        end
    end
    ne.slider.seekRangesF = function()
        if not user_opts.seekrange then
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
    ne.eventresponder['mouse_move'] = --keyframe seeking when mouse is dragged
        function (element)
			if not element.state.mbtnleft then return end -- allow drag for mbtnleft only!
            -- mouse move events may pile up during seeking and may still get
            -- sent when the user is done seeking, so we need to throw away
            -- identical seeks
            local seekto = get_slider_value(element)
            if (element.state.lastseek == nil) or
                (not (element.state.lastseek == seekto)) then
                    local flags = 'absolute-percent'
                    if not user_opts.seekbarkeyframes then
                        flags = flags .. '+exact'
                    end
                    mp.commandv('seek', seekto, flags)
                    element.state.lastseek = seekto
            end

        end
    ne.eventresponder['mbtn_left_down'] = --exact seeks on single clicks
        function (element)
			mp.commandv('seek', get_slider_value(element), 'absolute-percent', 'exact')
			element.state.mbtnleft = true
		end
	ne.eventresponder['mbtn_left_up'] =
		function (element) element.state.mbtnleft = false end
    ne.eventresponder['mbtn_right_down'] = --seeks to chapter start
        function (element)
			local duration = mp.get_property_number('duration', nil)
			if not (duration == nil) then
				local chapters = mp.get_property_native('chapter-list', {})
				if #chapters > 0 then
					local pos = get_slider_value(element)
					local ch = #chapters
					for n = 1, ch do
						if chapters[n].time / duration * 100 >= pos then
							ch = n - 1
							break
						end
					end
					mp.commandv('set', 'chapter', ch - 1)
					--if chapters[ch].title then show_message(chapters[ch].time) end
				end
			end
		end
    ne.eventresponder['reset'] =
        function (element) element.state.lastseek = nil end

    --volumebar
    ne = new_element('volumebar', 'slider')
    ne.visible = (osc_param.playresx >= 700) and user_opts.volumecontrol
    ne.enabled = (get_track('audio')>0)
    ne.slider.markerF = function ()
        return {}
    end
    ne.slider.seekRangesF = function()
      return nil
    end
    ne.slider.posF =
        function ()
            local val = mp.get_property_number('volume', nil)
            return val*val/100
        end
    ne.eventresponder['mouse_move'] =
        function (element)
            if not element.state.mbtnleft then return end -- allow drag for mbtnleft only!
            local seekto = get_slider_value(element)
            if (element.state.lastseek == nil) or
                (not (element.state.lastseek == seekto)) then
                    mp.commandv('set', 'volume', 10*math.sqrt(seekto))
                    element.state.lastseek = seekto
            end
        end
    ne.eventresponder['mbtn_left_down'] = --exact seeks on single clicks
        function (element)
            local seekto = get_slider_value(element)
            mp.commandv('set', 'volume', 10*math.sqrt(seekto))
            element.state.mbtnleft = true
        end
    ne.eventresponder['mbtn_left_up'] =
        function (element) element.state.mbtnleft = false end
    ne.eventresponder['reset'] =
        function (element) element.state.lastseek = nil end
    ne.eventresponder["wheel_up_press"] =
        function () mp.commandv("osd-auto", "add", "volume", 5) end
    ne.eventresponder["wheel_down_press"] =
        function () mp.commandv("osd-auto", "add", "volume", -5) end
    
    -- tc_left (current pos)
    ne = new_element('tc_left', 'button')
    ne.content = function ()
	if (state.fulltime) then
		return (mp.get_property_osd('playback-time/full'))
	else
		return (mp.get_property_osd('playback-time'))
	end
    end
    ne.eventresponder["mbtn_left_up"] = function ()
        state.fulltime = not state.fulltime
        request_init()
    end
    -- tc_right (total/remaining time)
    ne = new_element('tc_right', 'button')
    ne.content = function ()
        if (mp.get_property_number('duration', 0) <= 0) then return '--:--:--' end
        if (state.rightTC_trem) then
		if (state.fulltime) then
			return ('-'..mp.get_property_osd('playtime-remaining/full'))
		else
			return ('-'..mp.get_property_osd('playtime-remaining'))
		end
        else
		if (state.fulltime) then
			return (mp.get_property_osd('duration/full'))
		else
			return (mp.get_property_osd('duration'))
		end
			
        end
    end
    ne.eventresponder['mbtn_left_up'] =
        function () state.rightTC_trem = not state.rightTC_trem end

    -- load layout
    layouts()

    -- load window controls
    if window_controls_enabled() then
        window_controls()
    end

    --do something with the elements
    prepare_elements()
end

function shutdown()
    
end

--
-- Other important stuff
--


function show_osc()
    -- show when disabled can happen (e.g. mouse_move) due to async/delayed unbinding
    if not state.enabled then return end

    msg.trace('show_osc')
    --remember last time of invocation (mouse move)
    state.showtime = mp.get_time()

    osc_visible(true)
    
    if user_opts.keyboardnavigation == true then
        osc_enable_key_bindings()
    end

    if (user_opts.fadeduration > 0) then
        state.anitype = nil
    end
end

function hide_osc()
    msg.trace('hide_osc')
    if not state.enabled then
        -- typically hide happens at render() from tick(), but now tick() is
        -- no-op and won't render again to remove the osc, so do that manually.
        state.osc_visible = false
        render_wipe()
        if user_opts.keyboardnavigation == true then
            osc_disable_key_bindings()
        end
    elseif (user_opts.fadeduration > 0) then
        if not(state.osc_visible == false) then
            state.anitype = 'out'
            request_tick()
        end
    else
        osc_visible(false)
    end
end

function osc_visible(visible)
    if state.osc_visible ~= visible then
        state.osc_visible = visible
    end
    request_tick()
end

function pause_state(name, enabled)
    state.paused = enabled
    mp.add_timeout(0.1, function() state.osd:update() end) 
    if user_opts.showonpause then
		if enabled then
			state.lastvisibility = user_opts.visibility
			visibility_mode("always", true)
			show_osc()
		else
			visibility_mode(state.lastvisibility, true)
		end
	end
    request_tick()
end

function cache_state(name, st)
    state.cache_state = st
    request_tick()
end

-- Request that tick() is called (which typically re-renders the OSC).
-- The tick is then either executed immediately, or rate-limited if it was
-- called a small time ago.
function request_tick()
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

function mouse_leave()
    if get_hidetimeout() >= 0 then
        hide_osc()
    end
    -- reset mouse position
    state.last_mouseX, state.last_mouseY = nil, nil
    state.mouse_in_window = false
end

function request_init()
    state.initREQ = true
    request_tick()
end

-- Like request_init(), but also request an immediate update
function request_init_resize()
    request_init()
    -- ensure immediate update
    state.tick_timer:kill()
    state.tick_timer.timeout = 0
    state.tick_timer:resume()
end

function render_wipe()
    msg.trace('render_wipe()')
    state.osd:remove()
end

function render()
    msg.trace('rendering')
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

        if (now < state.anistart + (user_opts.fadeduration/1000)) then

            if (state.anitype == 'in') then --fade in
                osc_visible(true)
                state.animation = scale_value(state.anistart,
                    (state.anistart + (user_opts.fadeduration/1000)),
                    255, 0, now)
            elseif (state.anitype == 'out') then --fade out
                state.animation = scale_value(state.anistart,
                    (state.anistart + (user_opts.fadeduration/1000)),
                    0, 255, now)
            end

        else
            if (state.anitype == 'out') then
                osc_visible(false)
            end
            state.anistart = nil
            state.animation = nil
            state.anitype =  nil
        end
    else
        state.anistart = nil
        state.animation = nil
        state.anitype =  nil
    end

    --mouse show/hide area
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
    do_enable_keybindings()

    --mouse input area
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
    if not (state.showtime == nil) and (get_hidetimeout() >= 0) then
        local timeout = state.showtime + (get_hidetimeout()/1000) - now
        if timeout <= 0 then
            if (state.active_element == nil) and not (mouse_over_osc) then
                hide_osc()
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
    local ass = assdraw.ass_new()

    -- Messages
    render_message(ass)

    -- actual OSC
    if state.osc_visible then
        render_elements(ass)
    end

    -- submit
    set_osd(osc_param.playresy * osc_param.display_aspect,
            osc_param.playresy, ass.text)
end

--
-- Eventhandling
--

local function element_has_action(element, action)
    return element and element.eventresponder and
        element.eventresponder[action]
end

function process_event(source, what)
    local action = string.format('%s%s', source,
        what and ('_' .. what) or '')

    if what == 'down' or what == 'press' then

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
        if (user_opts.minmousemove == 0) or
            (not ((state.last_mouseX == nil) or (state.last_mouseY == nil)) and
                ((math.abs(mouseX - state.last_mouseX) >= user_opts.minmousemove)
                    or (math.abs(mouseY - state.last_mouseY) >= user_opts.minmousemove)
                )
            ) then
            show_osc()
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

-- called by mpv on every frame
function tick()
    if (not state.enabled) then return end

    if (state.idle) then
	   
        -- render idle message
        msg.trace('idle message')
        local _, _, display_aspect = mp.get_osd_size()
        local display_h = 360
        local display_w = display_h * display_aspect
        -- logo is rendered at 2^(6-1) = 32 times resolution with size 1800x1800
        local icon_x, icon_y = (display_w - 1800 / 32) / 2, 140
        local line_prefix = ('{\\rDefault\\an7\\1a&H00&\\bord0\\shad0\\pos(%f,%f)}'):format(icon_x, icon_y)

        local ass = assdraw.ass_new()
        -- mpv logo
        if user_opts.idlescreen then
            for i, line in ipairs(logo_lines) do
                ass:new_event()
                ass:append(line_prefix .. line)
            end
        end

        -- Santa hat
        if is_december and user_opts.idlescreen and not user_opts.greenandgrumpy then
            for i, line in ipairs(santa_hat_lines) do
                ass:new_event()
                ass:append(line_prefix .. line)
            end
        end
   
        if user_opts.idlescreen then
            ass:new_event()
            ass:pos(display_w / 2, icon_y + 65)
            ass:an(8)
            ass:append(texts.welcome)
        end
        set_osd(display_w, display_h, ass.text)

        if state.showhide_enabled then
            mp.disable_key_bindings('showhide')
            mp.disable_key_bindings('showhide_wc')
            state.showhide_enabled = false
        end


    elseif (state.fullscreen and user_opts.showfullscreen)
        or (not state.fullscreen and user_opts.showwindowed) then

        -- render the OSC
        render()
    else
        -- Flush OSD
        set_osd(osc_param.playresy, osc_param.playresy, '')
    end

    state.tick_last_time = mp.get_time()

    if state.anitype ~= nil then
        -- state.anistart can be nil - animation should now start, or it can
        -- be a timestamp when it started. state.idle has no animation.
        if not state.idle and
           (not state.anistart or
            mp.get_time() < 1 + state.anistart + user_opts.fadeduration/1000)
        then
            -- animating or starting, or still within 1s past the deadline
            request_tick()
        else
            kill_animation()
        end
    end
end

function do_enable_keybindings()
    if state.enabled then
        if not state.showhide_enabled then
            mp.enable_key_bindings('showhide', 'allow-vo-dragging+allow-hide-cursor')
            mp.enable_key_bindings('showhide_wc', 'allow-vo-dragging+allow-hide-cursor')
        end
        state.showhide_enabled = true
    end
end

function enable_osc(enable)
    state.enabled = enable
    if enable then
        do_enable_keybindings()
    else
        hide_osc() -- acts immediately when state.enabled == false
        if state.showhide_enabled then
            mp.disable_key_bindings('showhide')
            mp.disable_key_bindings('showhide_wc')
        end
        state.showhide_enabled = false
    end
end

-- duration is observed for the sole purpose of updating chapter markers
-- positions. live streams with chapters are very rare, and the update is also
-- expensive (with request_init), so it's only observed when we have chapters
-- and the user didn't disable the livemarkers option (update_duration_watch).
function on_duration() request_init() end

local duration_watched = false
function update_duration_watch()
    local want_watch = user_opts.livemarkers and
                       (mp.get_property_number("chapters", 0) or 0) > 0 and
                       true or false  -- ensure it's a boolean

    if (want_watch ~= duration_watched) then
        if want_watch then
            mp.observe_property("duration", nil, on_duration)
        else
            mp.unobserve_property(on_duration)
        end
        duration_watched = want_watch
    end
end

validate_user_opts()
update_duration_watch()

mp.register_event('shutdown', shutdown)
mp.register_event('start-file', request_init)
mp.observe_property('track-list', nil, request_init)
mp.observe_property('playlist', nil, request_init)
mp.observe_property("chapter-list", "native", function(_, list)
    list = list or {}  -- safety, shouldn't return nil
    table.sort(list, function(a, b) return a.time < b.time end)
    state.chapter_list = list
    update_duration_watch()
    request_init()
end)

mp.register_script_message('osc-message', show_message)
mp.register_script_message('osc-chapterlist', function(dur)
    show_message(get_chapterlist(), dur)
end)
mp.register_script_message('osc-playlist', function(dur)
    show_message(get_playlist(), dur)
end)
mp.register_script_message('osc-tracklist', function(dur)
    local msg = {}
    for k,v in pairs(nicetypes) do
        table.insert(msg, get_tracklist(k))
    end
    show_message(table.concat(msg, '\n\n'), dur)
end)

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
mp.observe_property('border', 'bool',
    function(name, val)
        state.border = val
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

-- mouse show/hide bindings
mp.set_key_bindings({
    {'mouse_move',              function(e) process_event('mouse_move', nil) end},
    {'mouse_leave',             mouse_leave},
}, 'showhide', 'force')
mp.set_key_bindings({
    {'mouse_move',              function(e) process_event('mouse_move', nil) end},
    {'mouse_leave',             mouse_leave},
}, 'showhide_wc', 'force')
do_enable_keybindings()

--mouse input bindings
mp.set_key_bindings({
    {"mbtn_left",           function(e) process_event("mbtn_left", "up") end,
                            function(e) process_event("mbtn_left", "down")  end},
    {"shift+mbtn_left",     function(e) process_event("shift+mbtn_left", "up") end,
                            function(e) process_event("shift+mbtn_left", "down")  end},
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

function get_hidetimeout()
    if user_opts.visibility == 'always' then
        return -1 -- disable autohide
    end
    return user_opts.hidetimeout
end

function always_on(val)
    if state.enabled then
        if val then
            show_osc()
        else
            hide_osc()
        end
    end
end

-- mode can be auto/always/never/cycle
-- the modes only affect internal variables and not stored on its own.
function visibility_mode(mode, no_osd)
    if mode == "cycle" then
        if not state.enabled then
            mode = "auto"
        elseif user_opts.visibility ~= "always" then
            mode = "always"
        else
            mode = "never"
        end
    end

    if mode == 'auto' then
        always_on(false)
        enable_osc(true)
    elseif mode == 'always' then
        enable_osc(true)
        always_on(true)
    elseif mode == 'never' then
        enable_osc(false)
    else
        msg.warn('Ignoring unknown visibility mode \"' .. mode .. '\"')
        return
    end

    user_opts.visibility = mode
    mp.set_property_native("user-data/osc/visibility", user_opts.visibility)

    if not no_osd and tonumber(mp.get_property('osd-level')) >= 1 then
        mp.osd_message('OSC visibility: ' .. mode)
    end

    -- Reset the input state on a mode change. The input state will be
    -- recalcuated on the next render cycle, except in 'never' mode where it
    -- will just stay disabled.
    mp.disable_key_bindings('input')
    mp.disable_key_bindings('window-controls')
    state.input_enabled = false
    request_tick()
end


-- KeyboardControl
--

local osc_key_bindings = {}

function osc_kb_control_up()
    visibility_mode('always', true)
    local keyboard_controls = build_keyboard_controls()
    local rows = {}
    local active_row_index = 0
    local active_row_name = nil

    local row_index = -1
    for row_name, row_controls in pairs(keyboard_controls) do
        row_index = row_index + 1
        rows[row_index] = row_name
        for i, control in pairs(row_controls) do
            if control == state.highlight_element then
                active_row_index = row_index
                active_row_name = row_name
            end
        end
    end

    if active_row_index - 1 < 0 then
        return
    end

    local next_row_index = active_row_index - 1

    local new_active_row_name = rows[next_row_index]
    local new_active_row = keyboard_controls[new_active_row_name]

    for i, control in pairs(new_active_row) do
        state.highlight_element = control
        return
    end
end

function osc_kb_control_down()
    visibility_mode('always', true)
    local keyboard_controls = build_keyboard_controls()
    local rows = {}
    local active_row_index = 0
    local active_row_name = nil

    local row_index = -1
    for row_name, row_controls in pairs(keyboard_controls) do
        row_index = row_index + 1
        rows[row_index] = row_name
        for i, control in pairs(row_controls) do
            if control == state.highlight_element then
                active_row_index = row_index
                active_row_name = row_name
            end
        end
    end

    if active_row_index + 1 > #rows then
        return
    end

    local next_row_index = active_row_index + 1

    local new_active_row_name = rows[next_row_index]
    local new_active_row = keyboard_controls[new_active_row_name]

    for i, control in pairs(new_active_row) do
        state.highlight_element = control
        return
    end

end

function osc_kb_control_left()
    visibility_mode('always', true)
    local keyboard_controls = build_keyboard_controls()
    
    local active_control_name = nil
    for row_name, row_controls in pairs(keyboard_controls) do
        local controls = {}
        local controls_index = -1
        for i, control in pairs(row_controls) do
            controls_index = controls_index + 1
            controls[controls_index] = control
            if control == state.highlight_element then
                active_control_index = controls_index
                active_control_name = control
            end
        end

        if active_control_name == 'seekbar' then
            mp.commandv('seek', -5, 'exact', 'keyframes')
            return
        end

        if active_control_name then
            if active_control_index - 1 < 0 then
                return
            end
        
            local next_control_index = active_control_index - 1
            state.highlight_element = controls[next_control_index]
            return
        end
    end

end

function osc_kb_control_right()
    visibility_mode('always', true)
    local keyboard_controls = build_keyboard_controls()
    
    local active_control_name = nil
    for row_name, row_controls in pairs(keyboard_controls) do
        local controls = {}
        local controls_index = -1
        for i, control in pairs(row_controls) do
            controls_index = controls_index + 1
            controls[controls_index] = control
            if control == state.highlight_element then
                active_control_index = controls_index
                active_control_name = control
            end
        end

        if active_control_name == 'seekbar' then
            mp.commandv('seek', 5, 'exact', 'keyframes')
            return
        end

        if active_control_name then
            if active_control_index + 1 > #controls then
                return
            end
        
            local next_control_index = active_control_index + 1
            state.highlight_element = controls[next_control_index]
            return
        end
    end

end

function osc_kb_control_back()
    visibility_mode('auto', true)
end

function osc_kb_control_enter()
    visibility_mode('always', true)
    for n = 1, #elements do
        if elements[n].name == state.highlight_element then
            
            local action = 'enter'
            if element_has_action(elements[n], action) then
                elements[n].eventresponder[action](elements[n])
                return
            end

            local action = 'mbtn_left_up'
            if element_has_action(elements[n], action) then
                elements[n].eventresponder[action](elements[n])
                return
            end
        end
    end

end

function osc_add_key_binding(key, name, fn, flags)
	osc_key_bindings[#osc_key_bindings + 1] = name
	mp.add_forced_key_binding(key, name, fn, flags)
end

-- This is based on code from https://github.com/darsain/uosc
function osc_enable_key_bindings()
	osc_key_bindings = {}
	-- The `mp.set_key_bindings()` method would be easier here, but that
	-- doesn't support 'repeatable' flag, so we are stuck with this monster.
	osc_add_key_binding('up',              'osc-kb-control-prev1',        osc_kb_control_up, 'repeatable')
	osc_add_key_binding('down',            'osc-kb-control-next1',        osc_kb_control_down, 'repeatable')
	osc_add_key_binding('left',            'osc-kb-control-left1',        osc_kb_control_left, 'repeatable')
	osc_add_key_binding('right',           'osc-kb-control-right1',      osc_kb_control_right, 'repeatable')
	osc_add_key_binding('enter',      'osc-kb-control-select-alt3', osc_kb_control_enter, 'repeatable')
	osc_add_key_binding('esc',        'osc-kb-control-close',       osc_kb_control_back, 'repeatable')
end

function osc_disable_key_bindings()
	for _, name in ipairs(osc_key_bindings) do mp.remove_key_binding(name) end
	osc_key_bindings = {}
end



visibility_mode(user_opts.visibility, true)
mp.register_script_message('osc-visibility', visibility_mode)
mp.add_key_binding(nil, 'visibility', function() visibility_mode('cycle') end)

mp.register_script_message("thumbfast-info", function(json)
    local data = utils.parse_json(json)
    if type(data) ~= "table" or not data.width or not data.height then
        msg.error("thumbfast-info: received json didn't produce a table with thumbnail information")
    else
        thumbfast = data
    end
end)

set_virt_mouse_area(0, 0, 0, 0, 'input')
set_virt_mouse_area(0, 0, 0, 0, 'window-controls')
