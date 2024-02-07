-- subtitle-lines 1.1.0 - 2024-Feb-02
-- https://github.com/christoph-heinrich/mpv-subtitle-lines
--
-- List and search subtitle lines of the selected subtitle track.
--
-- Usage:
-- add bindings to input.conf:
-- Ctrl+f script-binding subtitle_lines/list_subtitles
-- Ctrl+F script-binding subtitle_lines/list_secondary_subtitles

local mp = require 'mp'
local utils = require 'mp.utils'
local script_name = mp.get_script_name()

-- https://github.com/mpv-player/mpv/blob/a5c32ea52e6f943a4221f6f18239510502d9b3e4/sub/sd.h#L13
local SUB_SEEK_OFFSET = 0.01

-- split str into a table
-- example: local t = split(s, "\n")
-- plain: whether pat is a plain string (default false - pat is a pattern)
local function split(str, pat, plain)
    local init = 1
    local r, i, find, sub = {}, 1, string.find, string.sub
    repeat
        local f0, f1 = find(str, pat, init, plain)
        r[i], i = sub(str, init, f0 and f0 - 1), i + 1
        init = f0 and f1 + 1 or 0
    until f0 == nil
    return r
end

local sub_strings_available = {
    primary = {
        text = 'sub-text',
        start = 'sub-start',
        ['end'] = 'sub-end',
        visibility = 'sub-visibility',
        delay = 'sub-delay',
        step = 'primary',
        title = 'Subtitle lines',
    },
    secondary = {
        text = 'secondary-sub-text',
        start = 'secondary-sub-start',
        ['end'] = 'secondary-sub-end',
        visibility = 'secondary-sub-visibility',
        delay = 'secondary-sub-delay',
        step = 'secondary',
        title = 'Secondary subtitle lines',
    }
}

local sub_strings = sub_strings_available.primary
local function get_current_subtitle()
    local start = mp.get_property_number(sub_strings.start)
    local stop = mp.get_property_number(sub_strings['end'])
    local text = mp.get_property(sub_strings.text)
    local lines = text and text:match('^[%s\n]*(.-)[%s\n]*$') or ''
    return start, stop, text, split(lines, '\n', true)
end

local function same_time(t1, t2)
    -- misses some merges if offset isn't doubled (0.012 already works in testing)
    return math.abs(t1 - t2) < SUB_SEEK_OFFSET * 2
end
---Merge lines with already collected subtitles
---returns lines that haven't been merged
---@param subtitles {start:number;stop:number;line:string}[]
---@param start number
---@param stop number
---@param lines string[]
---@return string[]
local function merge_subtitle_lines(subtitles, start, stop, lines)
    -- remove duplicates in the current lines
    for i = 1, #lines do
        for j = #lines, i + 1, -1 do
            if lines[i] == lines[j] then
                table.remove(lines, j)
            end
        end
    end

    -- merge identical lines that are right after each other
    for _, subtitle in ipairs(subtitles) do
        if same_time(subtitle.stop, start) then
            for i = #lines, 1, -1 do
                if lines[i] == subtitle.line then
                    table.remove(lines, i)
                    if start < subtitle.start then subtitle.start = start end
                    if stop > subtitle.stop then subtitle.stop = stop end
                end
            end
        end
    end
    return lines
end

---Get lines form current subtitle track
---@return {start:number;stop:number;line:string}[]
local function acquire_subtitles()
    local sub_delay = mp.get_property_number(sub_strings.delay)
    local sub_visibility = mp.get_property_bool(sub_strings.visibility)
    mp.set_property_bool(sub_strings.visibility, false)

    -- go to the first subtitle line
    mp.commandv('set', sub_strings.delay, mp.get_property_number('duration', 0) + 365 * 24 * 60 * 60)
    mp.commandv('sub-step', 1, sub_strings.step)

    -- this shouldn't be necessary, but it's kept just in case there actually
    -- are subtitles further in the past then the huge delay used above
    local retry_delay = sub_delay
    while true do
        mp.commandv('sub-step', -1, sub_strings.step)
        local delay = mp.get_property_number(sub_strings.delay)
        if retry_delay == delay then
            break
        end
        retry_delay = delay
    end

    ---@type {start:number;stop:number;line:string}[]
    local subtitles = {}
    local i = 0
    local prev_start = -1
    local prev_stop = -1
    local prev_text = nil

    retry_delay = nil
    while true do
        local start, stop, text, lines = get_current_subtitle()
        mp.commandv('sub-step', 1, sub_strings.step)
        if start and (text ~= prev_text or not same_time(start, prev_start) or not same_time(stop, prev_stop)) then
            -- remove empty lines
            for j = #lines, 1, -1 do
                if not lines[j]:find('[^%s]') then
                    table.remove(lines, j)
                end
            end
            if #lines > 0 then
                lines = merge_subtitle_lines(subtitles, start, stop, lines)
                for _, line in ipairs(lines) do
                    i = i + 1
                    subtitles[i] = { start = start, stop = stop, line = line }
                end
            end
            prev_start = start
            prev_stop = stop
            prev_text = text
        else
            local delay = mp.get_property_number(sub_strings.delay)
            if retry_delay == delay then
                break
            end
            retry_delay = delay
        end
    end

    mp.set_property_number(sub_strings.delay, sub_delay)
    mp.set_property_bool(sub_strings.visibility, sub_visibility)
    return subtitles
end

local function show_loading_indicator()
    local menu = {
        title = sub_strings.title,
        items = { {
            title = 'Loading...',
            icon = 'spinner',
            italic = true,
            muted = true,
            selectable = false,
            value = 'ignore',
        } },
        type = 'subtitle-lines-loading',
    }

    local json = utils.format_json(menu)
    mp.commandv('script-message-to', 'uosc', 'open-menu', json)
end

local menu_open = false
local function show_subtitle_list(subtitles)
    local menu = {
        title = sub_strings.title,
        items = {},
        type = 'subtitle-lines-list',
        on_close = {
            'script-message-to',
            script_name,
            'uosc-menu-closed',
        }
    }

    local last_started_index = 0
    local last_active_index = nil
    local time = mp.get_property_number('time-pos', 0) + SUB_SEEK_OFFSET
    for i, subtitle in ipairs(subtitles) do
        local has_started = subtitle.start <= time
        local has_ended = subtitle.stop < time
        local is_active = has_started and not has_ended
        menu.items[i] = {
            title = subtitle.line,
            hint = mp.format_time(subtitle.start) .. '-' .. mp.format_time(subtitle.stop),
            active = is_active,
            value = {
                'seek',
                subtitle.start,
                'absolute+exact',
            }
        }
        if has_started then
            last_started_index = i
        end
        if is_active then
            last_active_index = i
        end
    end
    menu.selected_index = last_active_index or
        last_started_index and subtitles[last_started_index + 1] and last_started_index + 1 or
        last_started_index

    local json = utils.format_json(menu)
    if menu_open then mp.commandv('script-message-to', 'uosc', 'update-menu', json)
    else mp.commandv('script-message-to', 'uosc', 'open-menu', json) end
    menu_open = true
end


---@type {start:number;stop:number;line:string}[]|nil
local subtitles = nil

local function sub_text_update()
    show_subtitle_list(subtitles)
end

mp.add_key_binding(nil, 'list_subtitles', function()
    if menu_open then
        mp.commandv('script-message-to', 'uosc', 'close-menu', 'subtitle-lines-list')
        return
    end
    sub_strings = sub_strings_available.primary
    show_loading_indicator()
    subtitles = acquire_subtitles()
    mp.observe_property(sub_strings.text, 'string', sub_text_update)
end)

mp.add_key_binding(nil, 'list_secondary_subtitles', function()
    if menu_open then
        mp.commandv('script-message-to', 'uosc', 'close-menu', 'subtitle-lines-list')
        return
    end
    sub_strings = sub_strings_available.secondary
    show_loading_indicator()
    subtitles = acquire_subtitles()
    mp.observe_property(sub_strings.text, 'string', sub_text_update)
end)

mp.register_script_message('uosc-menu-closed', function()
    subtitles = nil
    menu_open = false
    mp.unobserve_property(sub_text_update)
end)

mp.register_event('start-file', function()
    mp.commandv('script-message-to', 'uosc', 'close-menu', 'subtitle-lines-list')
end)

mp.register_event('end-file', function()
    mp.commandv('script-message-to', 'uosc', 'close-menu', 'subtitle-lines-list')
end)
