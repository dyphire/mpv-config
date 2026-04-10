--------------------------------------------------------------------------------------------------------
--------------------------------Scroll/Select Implementation--------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

local g = require 'modules.globals'
local fb_utils = require 'modules.utils'
local ass = require 'modules.ass'

---@class cursor
local cursor = {}

--disables multiselect
function cursor.disable_select_mode()
    g.state.multiselect_start = nil
    g.state.initial_selection = nil
end

--enables multiselect
function cursor.enable_select_mode()
    g.state.multiselect_start = g.state.selected
    g.state.initial_selection = fb_utils.copy_table(g.state.selection)
end

--calculates what drag behaviour is required for that specific movement
local function drag_select(original_pos, new_pos)
    if original_pos == new_pos then return end

    local setting = g.state.selection[g.state.multiselect_start or -1]
    for i = original_pos, new_pos, (new_pos > original_pos and 1 or -1) do
        --if we're moving the cursor away from the starting point then set the selection
        --otherwise restore the original selection
        if i > g.state.multiselect_start then
            if new_pos > original_pos then
                g.state.selection[i] = setting
            elseif i ~= new_pos then
                g.state.selection[i] = g.state.initial_selection[i]
            end
        elseif i < g.state.multiselect_start then
            if new_pos < original_pos then
                g.state.selection[i] = setting
            elseif i ~= new_pos then
                g.state.selection[i] = g.state.initial_selection[i]
            end
        end
    end
end

--moves the selector up and down the list by the entered amount
function cursor.scroll(n, wrap)
    local num_items = #g.state.list
    if num_items == 0 then return end

    local original_pos = g.state.selected

    if original_pos + n > num_items then
        g.state.selected = wrap and 1 or num_items
    elseif original_pos + n < 1 then
        g.state.selected = wrap and num_items or 1
    else
        g.state.selected = original_pos + n
    end

    if g.state.multiselect_start then drag_select(original_pos, g.state.selected) end
    ass.update_ass()
end

--selects the first item in the list which is highlighted as playing
function cursor.select_playing_item()
    for i,item in ipairs(g.state.list) do
        if ass.highlight_entry(item) then
            g.state.selected = i
            return
        end
    end
end

--scans the list for which item to select by default
--chooses the folder that the script just moved out of
--or, otherwise, the item highlighted as currently playing
function cursor.select_prev_directory()
    -- makes use of the directory stack to more exactly select the prev directory
    local down_stack = g.directory_stack.stack[g.directory_stack.position + 1]
    if down_stack then
        for i, item in ipairs(g.state.list) do
            if fb_utils.get_new_directory(item, g.state.directory) == down_stack then
                g.state.selected = i
                return
            end
        end
    end

    if g.state.prev_directory:find(g.state.directory, 1, true) == 1 then
        for i, item in ipairs(g.state.list) do
            if
                g.state.prev_directory:find(fb_utils.get_full_path(item), 1, true) or
                g.state.prev_directory:find(fb_utils.get_new_directory(item, g.state.directory), 1, true)
            then
                g.state.selected = i
                return
            end
        end
    end

    cursor.select_playing_item()
end

--toggles the selection
function cursor.toggle_selection()
    if not g.state.list[g.state.selected] then return end
    g.state.selection[g.state.selected] = not g.state.selection[g.state.selected] or nil
    ass.update_ass()
end

--select all items in the list
function cursor.select_all()
    for i,_ in ipairs(g.state.list) do
        g.state.selection[i] = true
    end
    ass.update_ass()
end

--toggles select mode
function cursor.toggle_select_mode()
    if g.state.multiselect_start == nil then
        cursor.enable_select_mode()
        cursor.toggle_selection()
    else
        cursor.disable_select_mode()
        ass.update_ass()
    end
end

return cursor
