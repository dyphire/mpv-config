--------------------------------------------------------------------------------------------------------
-----------------------------------------List Formatting------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

local utils = require 'mp.utils'

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

local string_buffer = {}

--appends the entered text to the overlay
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

--detects whether or not to highlight the given entry as being played
local function highlight_entry(v)
    if g.current_file.path == nil then return false end
    local full_path = fb_utils.get_full_path(v)

    if fb_utils.parseable_item(v) then
        return string.find(g.current_file.directory, full_path, 1, true)
    else
        return g.current_file.path == full_path
    end
end

-- escape ass values and replace newlines
local function ass_escape(str)
    return fb_utils.ass_escape(str, true)
end

--refreshes the ass text using the contents of the list
local function update_ass()
    if state.hidden then state.flag_update = true ; return end

    append(style.global)

    local dir_name = state.directory_label or state.directory
    if dir_name == "" then dir_name = "ROOT" end
    append(style.header)
    append(fb_utils.substitute_codes(o.format_string_header, nil, nil, nil, ass_escape))
    newline()

    if #state.list < 1 then
        append(state.empty_text)
        flush_buffer()
        draw()
        return
    end

    local start = 1
    local finish = start+o.num_entries-1

    --handling cursor positioning
    local mid = math.ceil(o.num_entries/2)+1
    if state.selected+mid > finish then
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

    -- these are the number values to place into the wrappers
    local wrapper_overrides = {['<'] = tostring(start-1), ['>'] = tostring(#state.list-finish)}

    --adding a header to show there are items above in the list
    if o.format_string_topwrapper ~= '' and start > 1 then
        append(style.footer_header, fb_utils.substitute_codes(o.format_string_topwrapper, wrapper_overrides, nil, nil, ass_escape))
        newline()
    end

    for i=start, finish do
        local v = state.list[i]
        local playing_file = highlight_entry(v)
        append(style.body)

        --handles custom styles for different entries
        if i == state.selected or i == state.multiselect_start then
            if not (i == state.selected) then append(style.selection_marker) end

            if not state.multiselect_start then append(style.cursor)
            else
                if state.selection[state.multiselect_start] then append(style.cursor_select)
                else append(style.cursor_deselect) end
            end
            append(o.cursor_icon, "\\h", style.body)
        else
            append(g.style.indent, o.cursor_icon, "\\h", style.body)
        end

        --sets the selection colour scheme
        local multiselected = state.selection[i]

        --sets the colour for the item
        local function set_colour()
            if multiselected then append(style.multiselect)
            elseif i == state.selected then append(style.selected) end

            if playing_file then append( multiselected and style.playing_selected or style.playing) end
        end
        set_colour()

        --sets the folder icon
        if v.type == 'dir' then
            append(style.folder, o.folder_icon, "\\h", style.body)
            set_colour()
        end

        --adds the actual name of the item
        append(v.ass or ass_escape(v.label or v.name))
        newline()
    end

    if o.format_string_bottomwrapper ~= '' and overflow then
        append(style.footer_header)
        append(fb_utils.substitute_codes(o.format_string_bottomwrapper, wrapper_overrides, nil, nil, ass_escape))
    end

    flush_buffer()
    draw()
end

return {
    update_ass = update_ass,
    highlight_entry = highlight_entry,
    draw = draw,
    remove = remove,
}
