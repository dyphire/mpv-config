
local msg = require 'mp.msg'

local o = require 'modules.options'
local g = require 'modules.globals'
local cache = require 'modules.cache'
local scanning = require 'modules.navigation.scanning'
local fb_utils = require 'modules.utils'

local directory_movement = {}

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
