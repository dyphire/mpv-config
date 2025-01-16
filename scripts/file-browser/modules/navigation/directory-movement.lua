
local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = require 'modules.options'
local g = require 'modules.globals'
local ass = require 'modules.ass'
local cache = require 'modules.cache'
local scanning = require 'modules.navigation.scanning'
local fb_utils = require 'modules.utils'

local directory_movement = {}

function directory_movement.set_current_file(filepath)
    --if we're in idle mode then we want to open the working directory
    if filepath == nil then
        g.current_file.directory = fb_utils.fix_path( mp.get_property("working-directory", ""), true)
        g.current_file.name = nil
        g.current_file.path = nil
        return
    end

    local absolute_path = fb_utils.absolute_path(filepath)
    local resolved_path = fb_utils.resolve_directory_mapping(absolute_path)

    g.current_file.directory, g.current_file.name = utils.split_path(resolved_path)
    g.current_file.original_path = absolute_path
    g.current_file.path = resolved_path

    if not g.state.hidden then ass.update_ass()
    else g.state.flag_update = true end
end

--the base function for moving to a directory
function directory_movement.goto_directory(directory)
    g.state.directory = directory
    scanning.rescan(false)
end

--loads the root list
function directory_movement.goto_root()
    msg.verbose('jumping to root')
    directory_movement.goto_directory("")
end

--switches to the directory of the currently playing file
function directory_movement.goto_current_dir()
    msg.verbose('jumping to current directory')
    directory_movement.goto_directory(g.current_file.directory)
end

--moves up a directory
function directory_movement.up_dir()
    local parent_dir = g.state.directory:match("^(.-/+)[^/]+/*$") or ""

    if o.skip_protocol_schemes and parent_dir:find("^(%a[%w+-.]*)://$") then
        directory_movement.goto_root()
        return;
    end

    g.state.directory = parent_dir

    --we can make some assumptions about the next directory label when moving up or down
    if g.state.directory_label then g.state.directory_label = string.match(g.state.directory_label, "^(.-/+)[^/]+/*$") end

    scanning.rescan(true)
    cache:pop()
end

--moves down a directory
function directory_movement.down_dir()
    local current = g.state.list[g.state.selected]
    if not current or not fb_utils.parseable_item(current) then return end

    cache:push()
    local directory, redirected = fb_utils.get_new_directory(current, g.state.directory)
    g.state.directory = directory

    --we can make some assumptions about the next directory label when moving up or down
    if g.state.directory_label then g.state.directory_label = g.state.directory_label..(current.label or current.name) end
    scanning.rescan(not redirected)
end

return directory_movement
