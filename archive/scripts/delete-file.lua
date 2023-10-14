--[[

    This script can instantly deletes the file that is currently playing
    via keyboard shortcut, the file is moved to the recycle bin.

    You also can mark a file to be deleted and can unmark it if desired. 
    On Linux the app trash-cli must be installed first.

    This script needs to be used with scroll-list.lua
    https://github.com/CogentRedTester/mpv-scroll-list

    Usage:
    Add bindings to input.conf:

    # delete directly
    KP0              script-message-to delete_file delete-file
    CTRL+DEL         script-message-to delete_file delete_file
    ALT+DEL          script-message-to delete_file list_marks
    CTRL+SHIFT+DEL   script-message-to delete_file clear_list

    # delete with confirmation
    KP0 script-message-to delete_file delete-file KP1 "Press 1 to delete file"

    Press KP0 to initiate the delete operation,
    the script will ask to confirm by pressing KP1.
    You may customize the the init and confirm key and the confirm message.
    Confirm key and confirm message are optional.

    SOURCE_1: https://github.com/stax76/mpv-scripts/blob/main/delete-current-file.lua
    SOURCE_2: https://github.com/zenyd/mpv-scripts/blob/master/delete_file.lua
    Modify_: https://github.com/dyphire/mpv-scripts
]]--

local mp = require "mp"
local msg = require "mp.msg"
local utils = require "mp.utils"
local opts = require "mp.options"

local o = {
    -- header of the list
    -- %cursor% and %total% to be used to display the cursor position and the total number of lists
    header = "Delete Marks: [%cursor%/%total%]\\N ------------------------------------",
    --list ass style overrides inside curly brackets
    --these styles will be used for the whole list. so you need to reset them for every line
    --read http://docs.aegisub.org/3.2/ASS_Tags/ for reference of tags
    global_style = [[]],
    header_style = [[{\q2\fs35\c&00ccff&}]],
    list_style = [[{\q2\fs25\c&Hffffff&}]],
    wrapper_style = [[{\c&00ccff&\fs16}]],
    cursor_style = [[{\c&00ccff&}]],
    selected_style = [[{\c&Hfce788&}]],
    cursor = [[➤\h]],
    indent = [[\h\h\h\h]],
    --amount of entries to show before slicing. Optimal value depends on font/video size etc.
    num_entries = 16,
    --slice long filenames, and how many chars to show
    slice_longfilenames_amount = 100,
    -- wrap the cursor around the top and bottom of the list
    wrap = true,
    -- set dynamic keybinds to bind when the list is open
    key_move_begin = "HOME",
    key_move_end = "END",
    key_move_pageup = "PGUP",
    key_move_pagedown = "PGDWN",
    key_scroll_down = "DOWN WHEEL_DOWN",
    key_scroll_up = "UP WHEEL_UP",
    key_remove_del = "BS DEL MBTN_LEFT",
    key_close_browser = "ESC MBTN_RIGHT",
}

opts.read_options(o)

--adding the source directory to the package path and loading the module
local list = dofile(mp.command_native({ "expand-path", "~~/script-modules/scroll-list.lua" }))

--modifying the list settings
local original_open = list.open
local original_close = list.close
list.header = o.header
list.cursor = o.cursor
list.indent = o.indent
list.wrap = o.wrap
list.num_entries = o.num_entries
list.global_style = o.global_style
list.header_style = o.header_style
list.list_style = o.list_style
list.wrapper_style = o.wrapper_style
list.cursor_style = o.cursor_style
list.selected_style = o.selected_style

del_list = {}

key_bindings = {}

local list_open = false

function contains_item(l, i)
    for k, v in pairs(l) do
        if v == i then
            msg.info("undeleting current file")
            if not list_open then mp.osd_message("undeleting current file") end
            table.remove(l, k)
            return true
        end
    end
    msg.info("deleting current file")
    if not list_open then mp.osd_message("deleting current file") end
    return false
end

function is_protocol(path)
    return type(path) == 'string' and path:match('^%a[%a%d-_]+://') ~= nil
end

function delete_file(path)
    local is_windows = package.config:sub(1, 1) == "\\"

    if not path or is_protocol(path) then
        mp.commandv("show-text", "no file to delete")
        return
    end

    if is_windows then
        local ps_code = [[
           Add-Type -AssemblyName Microsoft.VisualBasic
           [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('__path__', 'OnlyErrorDialogs', 'SendToRecycleBin')
       ]]

        local escaped_path = string.gsub(path, "'", "''")
        escaped_path = string.gsub(escaped_path, "’", "’’")
        escaped_path = string.gsub(escaped_path, "%%", "%%%%")
        ps_code = string.gsub(ps_code, "__path__", escaped_path)

        mp.command_native({
            name = "subprocess",
            playback_only = false,
            detach = true,
            args = { 'powershell', '-NoProfile', '-Command', ps_code },
        })
    else
        mp.command_native({
            name = "subprocess",
            playback_only = false,
            detach = true,
            args = { 'trash', path },
        })
    end
end

function remove_current_file()
    local count   = mp.get_property_number("playlist-count")
    local pos     = mp.get_property_number("playlist-pos")
    local new_pos = 0

    if pos == count - 1 then
        new_pos = -1
    else
        new_pos = pos + 1
    end

    mp.set_property_number("playlist-pos", new_pos)
    if pos >= 0 then mp.command("playlist-remove " .. pos) end
end

function handle_confirm_key()
    local path = mp.get_property("path")

    if file_to_delete == path then
        mp.commandv("show-text", "")
        remove_current_file()
        delete_file(file_to_delete)
        remove_bindings()
        file_to_delete = ""
    end
end

function cleanup()
    remove_bindings()
    file_to_delete = ""
    mp.commandv("show-text", "")
end

function mark_delete()
    local work_dir = mp.get_property_native("working-directory")
    local file_path = mp.get_property_native("path")
    local s = file_path:find(work_dir, 0, true)
    local final_path
    if is_protocol(file_path) then return end
    if s and s == 0 then
        final_path = file_path
    else
        final_path = utils.join_path(work_dir, file_path)
    end
    if not contains_item(del_list, final_path) then
        table.insert(del_list, final_path)
    end
end

function delete()
    for i, v in pairs(del_list) do
        print("deleting: " .. v)
        delete_file(v)
    end
end

function get_bindings()
    return {
        { confirm_key, handle_confirm_key },
    }
end

function add_bindings()
    if #key_bindings > 0 then
        return
    end

    local script_name = mp.get_script_name()

    for _, bind in ipairs(get_bindings()) do
        local name = script_name .. "_key_" .. (#key_bindings + 1)
        key_bindings[#key_bindings + 1] = name
        mp.add_forced_key_binding(bind[1], name, bind[2])
    end
end

function remove_bindings()
    if #key_bindings == 0 then
        return
    end

    for _, name in ipairs(key_bindings) do
        mp.remove_key_binding(name)
    end

    key_bindings = {}
end

function client_message(event)
    local path = mp.get_property("path")
    if event.args[1] == "delete-file" and #event.args == 1 then
        remove_current_file()
        delete_file(path)
    elseif event.args[1] == "delete-file" and #event.args == 3 and #key_bindings == 0 then
        confirm_key = event.args[2]
        mp.add_timeout(10, cleanup)
        add_bindings()
        file_to_delete = path
        mp.commandv("show-text", event.args[3], "10000")
    end
end

function list:format_header_string(str)
    if #list.list > 0 then
        str = str:gsub("%%(%a+)%%", { cursor = list.selected, total = #list.list })
    else str = str:gsub("%[.*%]", "") end
    return str
end

function showlist()
    list.list = {}
    for i = 1, #del_list do
        local item = {}
        if del_list[i] then
            _, del_file = utils.split_path(del_list[i])
            if del_file:len() > o.slice_longfilenames_amount + 5 then
                del_file = del_file:sub(1, o.slice_longfilenames_amount) .. " ..."
            end
            item.ass = list.ass_escape(del_file)
        end
        list.list[i] = item
    end
    list:update()
end

--remove the selected dele file
local function remove_del()
    if list.list[list.selected] then
        local i = list.selected
        list_open = true
        contains_item(del_list, del_list[i])
        showlist()
    end
end

function list:open()
    list_open = true
    original_open(self)
end

function list:close()
    list_open = false
    original_close(self)
end

--dynamic keybinds to bind when the list is open
list.keybinds = {}

local function add_keys(keys, name, fn, flags)
    local i = 1
    for key in keys:gmatch("%S+") do
        table.insert(list.keybinds, { key, name .. i, fn, flags })
        i = i + 1
    end
end

add_keys(o.key_scroll_down, 'scroll_down', function() list:scroll_down() end, { repeatable = true })
add_keys(o.key_scroll_up, 'scroll_up', function() list:scroll_up() end, { repeatable = true })
add_keys(o.key_move_pageup, 'move_pageup', function() list:move_pageup() end, {})
add_keys(o.key_move_pagedown, 'move_pagedown', function() list:move_pagedown() end, {})
add_keys(o.key_move_begin, 'move_begin', function() list:move_begin() end, {})
add_keys(o.key_move_end, 'move_end', function() list:move_end() end, {})
add_keys(o.key_remove_del, 'remove_del', remove_del, {})
add_keys(o.key_close_browser, 'close_browser', function() list:close() end, {})

mp.register_script_message("list_marks", function() list:toggle() end)

mp.register_script_message("delete_file", function()
    mark_delete()
    showlist()
end)

--mp.register_script_message("list_marks", list_marks)
mp.register_script_message("clear_list", function() mp.osd_message("Undelete all"); del_list = {}; showlist(); end)
mp.register_event("client-message", client_message)
mp.register_event("shutdown", delete)
