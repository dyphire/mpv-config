
local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = require 'modules.options'
local g = require 'modules.globals'
local API = require 'modules.utils'
local movement = require 'modules.navigation.directory-movement'
local ass = require 'modules.ass'
local cursor = require 'modules.navigation.cursor'

local controls = {}

--opens the browser
function controls.open()
    if not g.state.hidden then return end

    for _,v in ipairs(g.state.keybinds) do
        mp.add_forced_key_binding(v[1], 'dynamic/'..v[2], v[3], v[4])
    end

    if o.set_shared_script_properties then utils.shared_script_property_set('file_browser-open', 'yes') end
    if o.set_user_data then mp.set_property_bool('user-data/file_browser/open', true) end

    if o.toggle_idlescreen then mp.commandv('script-message', 'osc-idlescreen', 'no', 'no_osd') end
    g.state.hidden = false
    if g.state.directory == nil then
        local path = mp.get_property('path')
        if path or o.default_to_working_directory then movement.goto_current_dir() else movement.goto_root() end
        return
    end

    if not g.state.flag_update then ass.draw()
    else g.state.flag_update = false ; ass.update_ass() end
end

--closes the list and sets the hidden flag
function controls.close()
    if g.state.hidden then return end

    for _,v in ipairs(g.state.keybinds) do
        mp.remove_key_binding('dynamic/'..v[2])
    end

    if o.set_shared_script_properties then utils.shared_script_property_set("file_browser-open", "no") end
    if o.set_user_data then mp.set_property_bool('user-data/file_browser/open', false) end

    if o.toggle_idlescreen then mp.commandv('script-message', 'osc-idlescreen', 'yes', 'no_osd') end
    g.state.hidden = true
    ass.remove()
end

--toggles the list
function controls.toggle()
    if g.state.hidden then controls.open()
    else controls.close() end
end

--run when the escape key is used
function controls.escape()
    --if multiple items are selection cancel the
    --selection instead of closing the browser
    if next(g.state.selection) or g.state.multiselect_start then
        g.state.selection = {}
        cursor.disable_select_mode()
        ass.update_ass()
        return
    end
    controls.close()
end

--opens a specific directory
function controls.browse_directory(directory)
    if not directory then return end
    directory = mp.command_native({"expand-path", directory}) or ''
    -- directory = join_path( mp.get_property("working-directory", ""), directory )

    if directory ~= "" then directory = API.fix_path(directory, true) end
    msg.verbose('recieved directory from script message: '..directory)

    if directory == "dvd://" then directory = g.dvd_device end
    movement.goto_directory(directory)
    controls.open()
end

return controls
