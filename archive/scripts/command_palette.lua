
-- https://github.com/stax76/mpv-scripts

----- options

local o = {
    font_size = 16,
    scale_by_window = false,
    lines_to_show = 12,
    pause_on_open = false, -- does not work on my system when enabled, menu won't show
    resume_on_exit = "only-if-was-paused",

    -- styles
    line_bottom_margin = 1,
    menu_x_padding = 5,
    menu_y_padding = 2,

    use_mediainfo = false, -- # true requires the MediaInfo CLI app being installed
    stream_quality_options = "2160,1440,1080,720,480",
    aspect_ratios = "4:3,16:9,2.35:1,1.36,1.82,0,-1",
}

local opt = require "mp.options"
opt.read_options(o)

----- string

function is_empty(input)
    if input == nil or input == "" then
        return true
    end
end

function contains(input, find)
    if not is_empty(input) and not is_empty(find) then
        return input:find(find, 1, true)
    end
end

function starts_with(str, start)
    return str:sub(1, #start) == start
end

function split(input, sep)
    assert(#sep == 1) -- supports only single character separator
    local tbl = {}

    if input ~= nil then
        for str in string.gmatch(input, "([^" .. sep .. "]+)") do
            table.insert(tbl, str)
        end
    end

    return tbl
end

function replace(str, what, with)
    what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1")
    with = string.gsub(with, "[%%]", "%%%%")
    return string.gsub(str, what, with)
end

function first_to_upper(str)
    return (str:gsub("^%l", string.upper))
end

----- list

function list_contains(list, value)
    for _, v in pairs(list) do
        if v == value then
            return true
        end
    end
end

----- path

function get_temp_dir()
    local is_windows = package.config:sub(1,1) == "\\"

    if is_windows then
        return os.getenv("TEMP") .. "\\"
    else
        return "/tmp/"
    end
end

---- file

function file_exists(path)
    if is_empty(path) then return false end
    local file = io.open(path, "r")

    if file ~= nil then
        io.close(file)
        return true
    end
end

function file_write(path, content)
    local file = assert(io.open(path, "w"))
    file:write(content)
    file:close()
end

----- mpv

local utils = require "mp.utils"
local assdraw = require 'mp.assdraw'
local msg = require "mp.msg"

----- path mpv

function file_name(value)
    local _, filename = utils.split_path(value)
    return filename
end

----- main

local command_palette_version = 1
mp.commandv('script-message', 'command-palette-version', command_palette_version)

local is_older_than_v0_36 = string.find(mp.get_property("mpv-version"), 'mpv v0%.[1-3][0-5]%.') == 1

if not is_older_than_v0_36 then
    mp.set_property_native("user-data/command-palette/version", command_palette_version)
end

local BluRayTitles = {}

mp.enable_messages("info")

mp.register_event('log-message', function(e)
    if e.prefix ~= "bd" then
        return
    end

    if contains(e.text, " 0 duration: ") then
        BluRayTitles = {}
    end

    if contains(e.text, " duration: ") then
        local match = string.match(e.text, "%d%d:%d%d:%d%d")

        if match then
            table.insert(BluRayTitles, match)
        end
    end
end)

local uosc_available = false
package.path = mp.command_native({ "expand-path", "~~/script-modules/?.lua;" }) .. package.path

local em = require "extended-menu"
local menu = em:new(o)
local menu_content = { list = {}, current_i = nil }
local media_info_cache = {}
local original_set_active_func = em.set_active
local original_get_line_func = em.get_line

function em:get_bindings()
    local bindings = {
        { 'esc',         function() self:set_active(false) end                         },
        { 'enter',       function() self:handle_enter() end                            },
        { 'bs',          function() self:handle_backspace() end                        },
        { 'del',         function() self:handle_del() end                              },
        { 'ins',         function() self:handle_ins() end                              },
        { 'left',        function() self:prev_char() end                               },
        { 'right',       function() self:next_char() end                               },
        { 'ctrl+f',      function() self:next_char() end                               },
        { 'up',          function() self:change_selected_index(-1) end                 },
        { 'down',        function() self:change_selected_index(1) end                  },
        { 'ctrl+up',     function() self:move_history(-1) end                          },
        { 'ctrl+down',   function() self:move_history(1) end                           },
        { 'ctrl+left',   function() self:prev_word() end                               },
        { 'ctrl+right',  function() self:next_word() end                               },
        { 'home',        function() self:go_home() end                                 },
        { 'end',         function() self:go_end() end                                  },
        { 'pgup',        function() self:change_selected_index(-o.lines_to_show) end   },
        { 'pgdwn',       function() self:change_selected_index(o.lines_to_show) end    },
        { 'ctrl+u',      function() self:del_to_start() end                            },
        { 'ctrl+v',      function() self:paste(true) end                               },
        { 'ctrl+bs',     function() self:del_word() end                                },
        { 'ctrl+del',    function() self:del_next_word() end                           },
        { 'kp_dec',      function() self:handle_char_input('.') end                    },
        { 'mbtn_left',   function() self:handle_enter() end                            },
        { 'mbtn_right',  function() self:set_active(false) end                         },
        { 'wheel_up',    function() self:change_selected_index(-1) end                 },
        { 'wheel_down',  function() self:change_selected_index(1) end                  },
        { 'mbtn_forward',function() self:change_selected_index(-o.lines_to_show) end   },
        { 'mbtn_back',   function() self:change_selected_index(o.lines_to_show) end    },
    }

    for i = 0, 9 do
        bindings[#bindings + 1] = {'kp' .. i, function() self:handle_char_input('' .. i) end}
    end

    return bindings
end

function em:set_active(active)
    original_set_active_func(self, active)

    if not active then
        if osc_visibility == "auto" or osc_visibility == "always" then
            mp.command("script-message osc-visibility " .. osc_visibility .. " no_osd")
            osc_visibility = nil
        elseif uosc_available then
            mp.commandv('script-message-to', 'uosc', 'disable-elements', mp.get_script_name(), '')
        end
    end
end

menu.index_field = "index"

local function format_time(t, duration)
    local h = math.floor(t / (60 * 60))
    t = t - (h * 60 * 60)
    local m = math.floor(t / 60)
    local s = t - (m * 60)

    if duration >= 60 * 60 or h > 0 then
        return string.format("%.2d:%.2d:%.2d", h, m, s)
    end

    return string.format("%.2d:%.2d", m, s)
end

function get_media_info()
    local path = mp.get_property("path")

    if contains(path, "://") or not file_exists(path) then
        return
    end

    if media_info_cache[path] then
        return media_info_cache[path]
    end

    local format_file = get_temp_dir() .. mp.get_script_name() .. " media-info-format-v1.txt"

    if not file_exists(format_file) then
        media_info_format = [[General;N: %FileNameExtension%\\nG: %Format%, %FileSize/String%, %Duration/String%, %OverallBitRate/String%, %Recorded_Date%\\n
Video;V: %Format%, %Format_Profile%, %Width%x%Height%, %BitRate/String%, %FrameRate% FPS\\n
Audio;A: %Language/String%, %Format%, %Format_Profile%, %BitRate/String%, %Channel(s)% ch, %SamplingRate/String%, %Title%\\n
Text;S: %Language/String%, %Format%, %Format_Profile%, %Title%\\n]]

        file_write(format_file, media_info_format)
    end

    local proc_result = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        args = {"mediainfo", "--inform=file://" .. format_file, path},
    })

    if proc_result.status == 0 then
        local output = proc_result.stdout

        output = string.gsub(output, ", , ,", ",")
        output = string.gsub(output, ", ,", ",")
        output = string.gsub(output, ": , ", ": ")
        output = string.gsub(output, ", \\n\r*\n", "\\n")
        output = string.gsub(output, "\\n\r*\n", "\\n")
        output = string.gsub(output, ", \\n", "\\n")
        output = string.gsub(output, "\\n", "\n")
        output = string.gsub(output, "%.000 FPS", " FPS")
        output = string.gsub(output, "MPEG Audio, Layer 3", "MP3")

        media_info_cache[path] = output

        return output
    end
end

function binding_get_line(self, _, v)
    local ass = assdraw.ass_new()
    local cmd = self:ass_escape(v.cmd)
    local key = self:ass_escape(v.key)
    local comment = self:ass_escape(v.comment or '')

    if v.priority == -1 or v.priority == -2 then
        local why_inactive = (v.priority == -1) and 'Inactive' or 'Shadowed'
        ass:append(self:get_font_color('comment'))

        if comment ~= "" then
            ass:append(comment .. '\\h')
        end

        ass:append(key .. '\\h(' .. why_inactive .. ')' .. '\\h' .. cmd)
        return ass.text
    end

    if comment ~= "" then
        ass:append(self:get_font_color('default'))
        ass:append(comment .. '\\h')
    end

    ass:append(self:get_font_color('accent'))
    ass:append(key)
    ass:append(self:get_font_color('comment'))
    ass:append(' ' .. cmd)
    return ass.text
end

function command_palette_get_line(self, _, v)
    local ass = assdraw.ass_new()

    if v.key == "" then
        ass:append(self:get_font_color('default'))
        ass:append(self:ass_escape(v.name or ''))
    else
        ass:append(self:get_font_color('default'))
        ass:append(self:ass_escape(v.name or '') .. '\\h')

        ass:append(self:get_font_color('accent'))
        ass:append(self:ass_escape("(" .. v.key .. ")"))
    end

    return ass.text
end

local function escape_codec(str)
    if not str or str == '' then return '' end

    local codec_map = {
        mpeg2 = "mpeg2",
        dvvideo = "dv",
        pcm = "pcm",
        pgs = "pgs",
        subrip = "srt",
        vtt = "vtt",
        dvd_sub = "vob",
        dvb_sub = "dvb",
        dvb_tele = "teletext",
        arib = "arib"
    }

    for key, value in pairs(codec_map) do
        if str:find(key) then
            return value
        end
    end

    return str
end

local function format_flags(track)
    local flags = ""

    for _, flag in ipairs({
        "default", "forced", "dependent", "visual-impaired", "hearing-impaired",
        "image", "external"
    }) do
        if track[flag] then
            flags = flags .. flag .. " "
        end
    end

    if flags == "" then
        return ""
    end

    return " [" .. flags:sub(1, -2) .. "]"
end

local function format_track(track, type)
    local title = track.title or ''
    local filename = mp.get_property('filename/no-ext', ''):gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
    local codec = escape_codec(track.codec)

    if track.external and title ~= "" then
        local extension = title:match("%.([^%.]+)$")
        if filename ~= "" and extension then
            title = title:gsub(filename .. "%.?", "")
        end
        if track.lang and extension
        and title:lower() == track.lang:lower() .. "." .. extension:lower() then
            title = extension
        end
    end
    if title == '' then
        local name = type:sub(1, 1):upper() .. type:sub(2, #type)
        title = string.format('%s %02.f', name, track.id)
    end

    local hints = {}
    local function h(value) hints[#hints + 1] = value end
    if codec ~= '' then h(codec) end
    if track['demux-h'] then
        h(track['demux-w'] and (track['demux-w'] .. 'x' .. track['demux-h'] or track['demux-h'] .. 'p'))
    end
    if track['demux-fps'] then h(string.format('%.5gfps', track['demux-fps'])) end
    if track['audio-channels'] then h(track['audio-channels'] .. 'ch') end
    if track['demux-samplerate'] then h(string.format('%.3gkHz', track['demux-samplerate'] / 1000)) end
    if track['demux-bitrate'] then h(string.format('%.0fkbps', track['demux-bitrate'] / 1000)) end
    if track.selected then
        title = "● " .. title
    else
        title = "○ " .. title
    end
    if track.lang then title = string.format('%s\t(%s)', title, track.lang) end
    if #hints > 0 then title = string.format('%s\t[%s]', title, table.concat(hints, ' ')) end
    title = title .. format_flags(track)
    return title
end

local function select(conf)
    for k, v in ipairs(conf.items) do
        table.insert(menu_content.list, { index = k, content = v })
    end

    if conf.default_item then
        menu_content.current_i = conf.default_item
    end

    function menu:submit(value)
        conf.submit(value)
    end
end

local function select_track(property, type, error)
    local tracks = {}
    local items = {}
    local default_item
    local track_id = mp.get_property_native(property)

    for _, track in ipairs(mp.get_property_native("track-list")) do
        if track.type == type then
            tracks[#tracks + 1] = track
            items[#items + 1] = format_track(track, type)

            if track.id == track_id then
                default_item = #items
            end
        end
    end

    if #items == 0 then
        mp.commandv("show-text", error)
        return
    end

    select({
        items = items,
        default_item = default_item,
        submit = function (tbl)
            mp.command("set " .. property .. " " ..
                (tracks[tbl.index].selected and "no" or tracks[tbl.index].id))
        end,
    })
end

local function subtitle_line(data, codec)
    local sub_lines = {}
    local sub_times = {}
    local default_item
    local delay = mp.get_property_native("sub-delay")
    local time_pos = mp.get_property_native("time-pos") - delay
    local duration = mp.get_property_native("duration", math.huge)
    local sub_content = {}

    -- Strip HTML and ASS tags and process subtitles
    for line in data:gmatch("[^\n]+") do
        -- Clean up tags
        local sub_line = line:gsub("<.->", "")                -- Strip HTML tags
                             :gsub("\\h+", " ")               -- Replace '\h' tag
                             :gsub("{[\\=].-}", "")           -- Remove ASS formatting
                             :gsub(".-]", "", 1)              -- Remove time info prefix
                             :gsub("^%s*(.-)%s*$", "%1")      -- Strip whitespace
                             :gsub("^m%s[mbl%s%-%d%.]+$", "") -- Remove graphics code

        if codec == "subrip" or (sub_line ~= "" and sub_line:match("^%s+$") == nil) then
            local sub_time = line:match("%d+") * 60 + line:match(":([%d%.]*)")
            local time_seconds = math.floor(sub_time)
            sub_content[time_seconds] = sub_content[time_seconds] or {}
            sub_content[time_seconds][sub_line] = true
        end
    end

    -- Process all timestamps and content into selectable subtitle list
    for time_seconds, contents in pairs(sub_content) do
        for sub_line in pairs(contents) do
            sub_times[#sub_times + 1] = time_seconds
            sub_lines[#sub_lines + 1] = format_time(time_seconds, duration) .. " " .. sub_line
        end
    end

    -- Generate time -> subtitle mapping
    local time_to_lines = {}
    for i = 1, #sub_times do
        local time = sub_times[i]
        local line = sub_lines[i]

        if not time_to_lines[time] then
            time_to_lines[time] = {}
        end
        table.insert(time_to_lines[time], line)
    end

    -- Sort by timestamp
    local sorted_sub_times = {}
    for i = 1, #sub_times do
        sorted_sub_times[i] = sub_times[i]
    end
    table.sort(sorted_sub_times)

    -- Use a helper table to avoid duplicates
    local added_times = {}

    -- Rebuild sub_lines and sub_times based on the sorted timestamps
    local sorted_sub_lines = {}
    for _, sub_time in ipairs(sorted_sub_times) do
        -- Iterate over all subtitle content for this timestamp
        if not added_times[sub_time] then
            added_times[sub_time] = true
            for _, line in ipairs(time_to_lines[sub_time]) do
                table.insert(sorted_sub_lines, line)
            end
        end
    end

    -- Use the sorted subtitle list
    sub_lines = sorted_sub_lines
    sub_times = sorted_sub_times

    -- Get the default item (last subtitle before current time position)
    for i, sub_time in ipairs(sub_times) do
        if sub_time <= time_pos then
            default_item = i
        end
    end

    return sub_lines, sub_times, default_item
end

function hide_osc()
    if is_empty(mp.get_property("path")) and not is_older_than_v0_36 then
        osc_visibility = mp.get_property_native("user-data/osc/visibility")

        if osc_visibility == "auto" or osc_visibility == "always" then
            mp.command("script-message osc-visibility never no_osd")
        end
    end

    if uosc_available then
        local disable_elements = "window_border, top_bar, timeline, controls, volume, idle_indicator, audio_indicator, buffering_indicator, pause_indicator"
        mp.commandv('script-message-to', 'uosc', 'disable-elements', mp.get_script_name(), disable_elements)
    end
end

mp.register_script_message("show-command-palette", function (name)
    menu_content.list = {}
    menu_content.current_i = 1
    menu.search_heading = name
    menu.filter_by_fields = { "content" }
    em.get_line = original_get_line_func

    if menu.is_active then
        menu:set_active(false)
        return
    end

    if name == "Command Palette" then
        local menu_items = {}
        local bindings = utils.parse_json(mp.get_property("input-bindings"))

        local items = {
            "Playlist",
            "Tracks",
            "Video Tracks",
            "Audio Tracks",
            "Subtitle Tracks",
            "Secondary Subtitle",
            "Subtitle Line",
            "Chapters",
            "Editions",
            "Profiles",
            "Bindings",
            "Commands",
            "Properties",
            "Options",
            "Audio Devices",
            "Blu-ray Titles",
            "Stream Quality",
            "Aspect Ratio",
            "Command Palette",
            "Recent Files",
        }

        for _, item in ipairs(items) do
            local found = false

            for _, binding in ipairs(bindings) do
                if contains(binding.cmd, "show-command-palette") and
                    (contains(binding.cmd, '"' .. item .. '"') or
                    contains(binding.cmd, "'" .. item .. "'")) then

                    table.insert(menu_items, { name = item, key = binding.key, cmd = binding.cmd })
                    found = true
                    break
                end
            end

            if not found then
                local cmd = "script-message-to command_palette show-command-palette '" .. item .. "'"
                table.insert(menu_items, { name = item, key = "", cmd = cmd })
            end
        end

        menu_content.list = menu_items

        function menu:submit(tbl)
            mp.command(tbl.cmd)
        end

        menu.filter_by_fields = {'name', 'key'}
        em.get_line = command_palette_get_line
    elseif name == "Bindings" then
        local bindings = utils.parse_json(mp.get_property("input-bindings"))

        for _, v in ipairs(bindings) do
            v.key = "(" .. v.key .. ")"

            if not is_empty(v.comment) then
                if contains(v.comment, "custom-menu: ") then
                    v.comment = replace(v.comment, "custom-menu: ", "")
                end

                if contains(v.comment, "menu: ") then
                    v.comment = replace(v.comment, "menu: ", "")
                end

                v.comment = first_to_upper(v.comment)
            end
        end

        for _, v in ipairs(bindings) do
            for _, v2 in ipairs(bindings) do
                if v.key == v2.key and v.priority < v2.priority then
                    v.priority = -2
                    break
                end
            end
        end

        table.sort(bindings, function(i, j)
            return i.priority > j.priority
        end)

        menu_content.list = bindings

        function menu:submit(tbl)
            mp.command(tbl.cmd)
        end

        menu.filter_by_fields = {'cmd', 'key', 'comment'}
        em.get_line = binding_get_line
    elseif name == "Chapters" then
        local default_index = mp.get_property_native("chapter")

        if not default_index then
            mp.commandv("show-text", "Chapter: (unavailable)")
            return
        end

        local duration = mp.get_property_native("duration", math.huge)

        for i, chapter in ipairs(mp.get_property_native("chapter-list")) do
            table.insert(menu_content.list, { index = i, content = format_time(chapter.time, duration) .. " "
            .. chapter.title or ("Chapter " .. string.format("%02.f", i))})
        end

        menu_content.current_i = default_index + 1

        function menu:submit(tbl)
            mp.set_property_number("chapter", tbl.index - 1)
        end
    elseif name == "Editions" then
        local default_index = mp.get_property_native("current-edition")

        if not default_index then
            mp.commandv("show-text", "Edition: (unavailable)")
            return
        end

        for i, edition in ipairs(mp.get_property_native("edition-list")) do
            table.insert(menu_content.list, { index = i, content = edition.title or
                ("Edition " .. string.format("%02.f", i))})
        end

        menu_content.current_i = default_index + 1

        function menu:submit(tbl)
            mp.set_property_number("edition", tbl.index - 1)
        end
    elseif name == "Playlist" then
        local count = mp.get_property_number("playlist-count")
        local show = mp.get_property_native("osd-playlist-entry")
        if count == 0 then return end

        for i = 0, (count - 1) do
            local text = mp.get_property("playlist/" .. i .. "/title")

            if not text or show ~= "title" then
                text = file_name(mp.get_property("playlist/" .. i .. "/filename"))
            end

            table.insert(menu_content.list, { index = i + 1, content = text })
        end

        menu_content.current_i = mp.get_property_number("playlist-pos") + 1

        function menu:submit(tbl)
            mp.set_property_number("playlist-pos", tbl.index - 1)
        end
    elseif name == "Commands" then
        local commands = utils.parse_json(mp.get_property("command-list"))

        for k, v in ipairs(commands) do
            local text = v.name

            for _, arg in ipairs(v.args) do
                if arg.optional then
                    text = text .. " [<" .. arg.name .. ">]"
                else
                    text = text .. " <" .. arg.name .. ">"
                end
            end

            table.insert(menu_content.list, { index = k, content = text })
        end

        function menu:submit(tbl)
            print(tbl.content)
            local cmd = string.match(tbl.content, '%S+')
            mp.commandv("script-message-to", "console", "type", cmd .. " ")
        end
    elseif name == "Properties" then
        local properties = split(mp.get_property("property-list"), ",")

        for k, v in ipairs(properties) do
            table.insert(menu_content.list, { index = k, content = v })
        end

        function menu:submit(tbl)
            mp.commandv('script-message-to', 'console', 'type', "print-text ${" .. tbl.content .. "}")
        end
    elseif name == "Options" then
        local options = split(mp.get_property("options"), ",")

        for k, v in ipairs(options) do
            local type = mp.get_property_osd("option-info/" .. v .. "/type", "")
            local default =mp.get_property_osd("option-info/" .. v .. "/default-value", "")
            v = v .. "   (type: " .. type .. ", default: " .. default .. ")"
            table.insert(menu_content.list, { index = k, content = v })
        end

        function menu:submit(tbl)
            print(tbl.content)
            local prop = string.match(tbl.content, '%S+')
            mp.commandv("script-message-to", "console", "type", "set " .. prop .. " ")
        end
    elseif name == "Profiles" then
        local profiles = utils.parse_json(mp.get_property("profile-list"))
        local ignore_list = {"builtin-pseudo-gui", "encoding", "libmpv", "pseudo-gui", "default"}

        for k, v in ipairs(profiles) do
            if not list_contains(ignore_list, v.name) then
                table.insert(menu_content.list, { index = k, content = v.name })
            end
        end

        function menu:submit(tbl)
            mp.command("show-text " .. tbl.content);
            mp.command("apply-profile " .. tbl.content);
        end
    elseif name == "Audio Devices" then
        local devices = utils.parse_json(mp.get_property("audio-device-list"))
        local current_name = mp.get_property("audio-device")

        for k, v in ipairs(devices) do
            table.insert(menu_content.list, { index = k, name = v.name, content = v.description })

            if v.name == current_name then
                menu_content.current_i = k
            end
        end

        function menu:submit(tbl)
            mp.commandv("set", "audio-device", tbl.name)
            mp.commandv("show-text", "audio-device: " .. tbl.content)
        end
    elseif name == "Aspect Ratio" then
        local current_ar = mp.get_property_number("video-aspect-override")

        for k, v in ipairs(split(o.aspect_ratios, ",")) do
            local display_name = v

            if display_name == "0"  then display_name = "0 (square pixels)" end
            if display_name == "-1" then display_name = "-1 (original)" end

            table.insert(menu_content.list, { index = k, content = display_name, value = v })

            local w, h = string.match(v, "^([0-9.]+):([0-9.]+)$")

            if w and h then
                local current_ar_truncated = tonumber(string.format("%.3f", current_ar))
                local ar_truncated = tonumber(string.format("%.3f", w / h))

                if current_ar_truncated == ar_truncated then
                    menu_content.current_i = k
                end
            elseif v == tostring(current_ar) then
                menu_content.current_i = k
            end
        end

        function menu:submit(tbl)
            mp.command("set video-aspect-override " .. tbl.value)
        end
    elseif name == "Stream Quality" then
        local ytdl_format = mp.get_property_native('ytdl-format')

        for k, v in ipairs(split(o.stream_quality_options, ",")) do
            local format = 'bestvideo[height<=?' .. v .. ']+bestaudio/best[height<=?' .. v .. ']'
            table.insert(menu_content.list, { index = k, content = v .. 'p', value = format })

            if format == ytdl_format then
                menu_content.current_i = k
            end
        end

        function menu:submit(tbl)
            mp.set_property('ytdl-format', tbl.value)
            mp.commandv("show-text", "Stream Quality: " .. tbl.content)

            local duration = mp.get_property_native('duration')
            local time_pos = mp.get_property('time-pos')

            mp.command('playlist-play-index current')

            if duration and duration > 0 then
                local function seeker()
                    mp.commandv('seek', time_pos, 'absolute')
                    mp.unregister_event(seeker)
                end

                mp.register_event('file-loaded', seeker)
            end
        end
    elseif name == "Tracks" then
        local tracks = {}

        for i, track in ipairs(mp.get_property_native("track-list")) do
            local type = track.image and "I" or track.type

            if type == "video" then track_type = "V" end
            if type == "audio" then track_type = "A" end
            if type == "sub" then track_type = "S" end

            tracks[i] = track_type .. ": " .. format_track(track, type)
        end

        if #tracks == 0 then
            mp.commandv("show-text", "No available tracks")
            return
        end

        select({
            items = tracks,
            submit = function (tbl)
                local track = mp.get_property_native("track-list/" .. tbl.index - 1)

                if track then
                    mp.command("set " .. track.type .. " " .. (track.selected and "no" or track.id))
                end
            end,
        })
    elseif name == "Audio Tracks" then
        if o.use_mediainfo then
            local mi = get_media_info()
            if mi == nil then return end
            local tracks = split(mi .. "\nA: None", "\n")
            local id = 0

            for _, v in ipairs(tracks) do
                if starts_with(v, "A: ") then
                    id = id + 1
                    table.insert(menu_content.list, { index = id, content = string.sub(v, 4) })
                end
            end

            menu_content.current_i = mp.get_property_number("aid") or id

            function menu:submit(tbl)
                mp.command("set aid " .. ((tbl.index == id) and 'no' or tbl.index))
            end
        else
            select_track("aid", "audio", "No available audio tracks")
        end
    elseif name == "Subtitle Tracks" then
        if o.use_mediainfo then
            local mi = get_media_info()
            if mi == nil then return end
            local tracks = split(mi .. "\nS: None", "\n")
            local id = 0

            for _, v in ipairs(tracks) do
                if starts_with(v, "S: ") then
                    id = id + 1
                    table.insert(menu_content.list, { index = id, content = string.sub(v, 4) })
                end
            end

            menu_content.current_i = mp.get_property_number("sid") or id

            function menu:submit(tbl)
                mp.command("set sid " .. ((tbl.index == id) and 'no' or tbl.index))
            end
        else
            select_track("sid", "sub", "No available subtitle tracks")
        end
    elseif name == "Secondary Subtitle" then
        select_track("secondary-sid", "sub", "No available subtitle tracks")
    elseif name == "Recent Files" then
        mp.command("script-message open-recent-menu command-palette")
        return
    elseif name == "Video Tracks" then
        if o.use_mediainfo then
            local mi = get_media_info()
            if mi == nil then return end
            local tracks = split(mi .. "\nV: None", "\n")
            local id = 0

            for _, v in ipairs(tracks) do
                if starts_with(v, "V: ") then
                    id = id + 1
                    table.insert(menu_content.list, { index = id, content = string.sub(v, 4) })
                end
            end

            menu_content.current_i = mp.get_property_number("vid") or id

            function menu:submit(tbl)
                mp.command("set vid " .. ((tbl.index == id) and 'no' or tbl.index))
            end
        else
            select_track("vid", "video", "No available video tracks")
        end
    elseif name == "Blu-ray Titles" then
        if #BluRayTitles == 0 then
            return
        end

        local items = {}

        for k, v in ipairs(BluRayTitles) do
            table.insert(items, "Title " .. k .. "   " .. v)
        end

        select({
            items = items,
            submit = function (tbl)
                mp.commandv("loadfile", "bd://" .. (tbl.index - 1))
            end,
        })
    elseif name == "Subtitle Line" then
        local sub = mp.get_property_native("current-tracks/sub")

        if sub == nil then
            mp.commandv("show-text", "No subtitle is loaded")
            return
        end

        if sub.external and sub["external-filename"]:find("^edl://") then
            sub["external-filename"] = sub["external-filename"]:match('https?://.*')
                                       or sub["external-filename"]
        end

        local r = mp.command_native({
            name = "subprocess",
            capture_stdout = true,
            args = sub.external
                and {"ffmpeg", "-loglevel", "error", "-i", sub["external-filename"],
                     "-f", "lrc", "-map_metadata", "-1", "-fflags", "+bitexact", "-"}
                or {"ffmpeg", "-loglevel", "error", "-i", mp.get_property("path"),
                    "-map", "s:" .. sub["id"] - 1, "-f", "lrc", "-map_metadata",
                    "-1", "-fflags", "+bitexact", "-"}
        })

        if r.error_string == "init" then
            mp.commandv("show-text", "Failed to extract subtitles: ffmpeg not found")
            return
        elseif r.status ~= 0 then
            mp.commandv("show-text", "Failed to extract subtitles")
            return
        end
        
        local delay = mp.get_property_native("sub-delay")

        local sub_lines, sub_times, default_item = subtitle_line(r.stdout, sub.codec)

        select({
            items = sub_lines,
            default_item = default_item,
            submit = function (tbl)
                -- Add an offset to seek to the correct line while paused without a video track.
                if mp.get_property_native("current-tracks/video/image") ~= false then
                    delay = delay + 0.1
                end

                mp.commandv("seek", sub_times[tbl.index] + delay, "absolute")
            end,
        })
    else
        if name == nil then
            msg.error("Unknown mode")
        else
            msg.error("Unknown mode: " .. name)
        end

        return
    end

    hide_osc()
    menu:init(menu_content)
end)

mp.register_script_message('uosc-version', function(version)
    local major, minor = version:match('^(%d+)%.(%d+)')
    if major and minor and tonumber(major) >= 5 and tonumber(minor) >= 0 then
        uosc_available = true
    end
end)

mp.register_script_message("show-command-palette-json", function (json)
    local menu_data = utils.parse_json(json)
    menu_content.list = {}
    menu_content.current_i = 1
    menu.search_heading = menu_data.title
    menu.filter_by_fields = { "content", "hint", "value_hint" }
    em.get_line = original_get_line_func

    for k, v in ipairs(menu_data.items) do
        local values = v.value

        if type(values) == "string" then
            values = { values }
        end

        table.insert(menu_content.list, {
            index = k,
            content = v.title,
            hint = v.hint,
            values = values,
            value_hint = table.concat(values, " "),
        })

        if menu_data.selected_index then
            menu_content.current_i = menu_data.selected_index
        end
    end

    function menu:submit(tbl)
        mp.command_native(tbl.values)
    end

    hide_osc()
    menu:init(menu_content)
end)
