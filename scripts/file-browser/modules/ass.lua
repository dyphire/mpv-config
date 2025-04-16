--------------------------------------------------------------------------------------------------------
-----------------------------------------List Formatting------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

local g = require 'modules.globals'
local o = require 'modules.options'
local fb_utils = require 'modules.utils'

local state = g.state
local style = g.style
local ass = g.ass

local function draw()
    ass:update()
end

local function remove()
    ass:remove()
end

---@type string[]
local string_buffer = {}

---appends the entered text to the overlay
---@param ... string
local function append(...)
    for i = 1, select("#", ...) do
        table.insert(string_buffer, select(i, ...) or '' )
    end
end

--appends a newline character to the osd
local function newline()
    table.insert(string_buffer, '\\N')
end

local function flush_buffer()
    ass.data = table.concat(string_buffer, '')
    string_buffer = {}
end

---detects whether or not to highlight the given entry as being played
---@param v Item
---@return boolean
local function highlight_entry(v)
    if g.current_file.path == nil then return false end
    local full_path = fb_utils.get_full_path(v)
    local alt_path = v.name and g.state.directory..v.name or nil

    if fb_utils.parseable_item(v) then
        return (
            string.find(g.current_file.directory, full_path, 1, true)
            or (alt_path and string.find(g.current_file.directory, alt_path, 1, true))
        ) ~= nil
    else
        return g.current_file.path == full_path
            or (alt_path and g.current_file.path == alt_path)
    end
end

---escape ass values and replace newlines
---@param str string
---@param style_reset string?
---@return string
local function ass_escape(str, style_reset)
    return fb_utils.ass_escape(str, style_reset and style.warning..'␊'..style_reset or true)
end

local header_overrides = {['^'] = style.header}

---@return number start
---@return number finish
---@return boolean is_overflowing
local function calculate_view_window()
    ---@type number
    local start = 1
    ---@type number
    local finish = start+o.num_entries-1

    --handling cursor positioning
    local mid = math.ceil(o.num_entries/2)+1
    if state.selected+mid > finish then
        ---@type number
        local offset = state.selected - finish + mid

        --if we've overshot the end of the list then undo some of the offset
        if finish + offset > #state.list then
            offset = offset - ((finish+offset) - #state.list)
        end

        start = start + offset
        finish = finish + offset
    end

    --making sure that we don't overstep the boundaries
    if start < 1 then start = 1 end
    local overflow = finish < #state.list
    --this is necessary when the number of items in the dir is less than the max
    if not overflow then finish = #state.list end

    return start, finish, overflow
end

---@param i number index
---@return string
local function calculate_item_style(i)
    local is_playing_file = highlight_entry(state.list[i])

    --sets the selection colour scheme
    local multiselected = state.selection[i]

    --sets the colour for the item
    local item_style = style.body

    if multiselected then item_style = item_style..style.multiselect
    elseif i == state.selected then item_style = item_style..style.selected end

    if is_playing_file then item_style = item_style..(multiselected and style.playing_selected or style.playing) end

    return item_style
end

local function draw_header()
    append(style.header)
    append(fb_utils.substitute_codes(o.format_string_header, header_overrides, nil, nil, function(str, code)
        if code == '^' then return str end
        return ass_escape(str, style.header)
    end))
    newline()
end

---@param wrapper_overrides ReplacerTable
local function draw_top_wrapper(wrapper_overrides)
    --adding a header to show there are items above in the list
    append(style.footer_header)
    append(fb_utils.substitute_codes(o.format_string_topwrapper, wrapper_overrides, nil, nil, function(str)
        return ass_escape(str)
    end))
    newline()
end

---@param wrapper_overrides ReplacerTable
local function draw_bottom_wrapper(wrapper_overrides)
    append(style.footer_header)
    append(fb_utils.substitute_codes(o.format_string_bottomwrapper, wrapper_overrides, nil, nil, function(str)
        return ass_escape(str)
    end))
end

---@param i number index
---@param cursor string
local function draw_cursor(i, cursor)
    --handles custom styles for different entries
    if i == state.selected or i == state.multiselect_start then
        if not (i == state.selected) then append(style.selection_marker) end

        if not state.multiselect_start then append(style.cursor)
        else
            if state.selection[state.multiselect_start] then append(style.cursor_select)
            else append(style.cursor_deselect) end
        end
    else
        append(g.style.indent)
    end
    append(cursor, '\\h', style.body)
end

--refreshes the ass text using the contents of the list
local function update_ass()
    if state.hidden then state.flag_update = true ; return end

    append(style.global)
    draw_header()

    if #state.list < 1 then
        append(state.empty_text)
        flush_buffer()
        draw()
        return
    end

    local start, finish, overflow = calculate_view_window()

    -- these are the number values to place into the wrappers
    local wrapper_overrides = {['<'] = tostring(start-1), ['>'] = tostring(#state.list-finish)}
    if o.format_string_topwrapper ~= '' and start > 1 then
        draw_top_wrapper(wrapper_overrides)
    end

    for i=start, finish do
        local v = state.list[i]
        append(style.body)
        if g.ALIGN_X ~= 'right' then draw_cursor(i, o.cursor_icon) end

        local item_style = calculate_item_style(i)
        append(item_style)

        --sets the folder icon
        if v.type == 'dir' then
            append(style.folder, o.folder_icon, "\\h", style.body)
            append(item_style)
        end

        --adds the actual name of the item
        append(v.ass or ass_escape(v.label or v.name, item_style), '\\h')
        if g.ALIGN_X == 'right' then draw_cursor(i, o.cursor_icon_flipped) end
        newline()
    end

    if o.format_string_bottomwrapper ~= '' and overflow then
        draw_bottom_wrapper(wrapper_overrides)
    end

    flush_buffer()
    draw()
end

---@class ass
return {
    update_ass = update_ass,
    highlight_entry = highlight_entry,
    draw = draw,
    remove = remove,
}
