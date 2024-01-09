local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = require 'modules.options'
local g = require 'modules.globals'
local API = require 'modules.utils'
local ass = require 'modules.ass'
local scanning = require 'modules.navigation.scanning'
local cache = require 'modules.cache'
local controls = require 'modules.controls'

local fb = setmetatable({}, { __index = setmetatable({}, { __index = API }) })

--these functions we'll provide as-is
fb.redraw = ass.update_ass
fb.rescan = scanning.rescan
fb.browse_directory = controls.browse_directory

function fb.clear_cache()
    cache:clear()
end

--a wrapper around scan_directory for addon API
function fb.parse_directory(directory, parse_state)
    if not parse_state then parse_state = { source = "addon" }
    elseif not parse_state.source then parse_state.source = "addon" end
    return scanning.scan_directory(directory, parse_state)
end

--register file extensions which can be opened by the browser
function fb.register_parseable_extension(ext)
    g.parseable_extensions[string.lower(ext)] = true
end
function fb.remove_parseable_extension(ext)
    g.parseable_extensions[string.lower(ext)] = nil
end

--add a compatible extension to show through the filter, only applies if run during the setup() method
function fb.add_default_extension(ext)
    table.insert(g.compatible_file_extensions, ext)
end

--add item to root at position pos
function fb.insert_root_item(item, pos)
    msg.debug("adding item to root", item.label or item.name, pos)
    item.ass = item.ass or fb.ass_escape(item.label or item.name)
    item.type = "dir"
    table.insert(g.root, pos or (#g.root + 1), item)
end

--a newer API for adding items to the root
--only adds the item if the same item does not already exist in the root
--the priority variable is a number that specifies the insertion location
--a lower priority is placed higher in the list and the default is 100
function fb.register_root_item(item, priority)
    msg.verbose('registering root item:', utils.to_string(item))
    if type(item) == 'string' then
        item = {name = item}
    end

    -- if the item is already in the list then do nothing
    if fb.list.some(g.root, function(r)
        return fb.get_full_path(r, '') == fb.get_full_path(item, '')
    end) then return false end

    item._priority = priority
    for i, v in ipairs(g.root) do
        if (v._priority or 100) > (priority or 100) then
            fb.insert_root_item(item, i)
            return true
        end
    end
    fb.insert_root_item(item)
    return true
end

--providing getter and setter functions so that addons can't modify things directly
function fb.get_script_opts() return fb.copy_table(o) end
function fb.get_opt(key) return o[key] end
function fb.get_extensions() return fb.copy_table(g.extensions) end
function fb.get_sub_extensions() return fb.copy_table(g.sub_extensions) end
function fb.get_audio_extensions() return fb.copy_table(g.audio_extensions) end
function fb.get_parseable_extensions() return fb.copy_table(g.parseable_extensions) end
function fb.get_state() return fb.copy_table(g.state) end
function fb.get_dvd_device() return g.dvd_device end
function fb.get_parsers() return fb.copy_table(g.parsers) end
function fb.get_root() return fb.copy_table(g.root) end
function fb.get_directory() return g.state.directory end
function fb.get_list() return fb.copy_table(g.state.list) end
function fb.get_current_file() return fb.copy_table(g.current_file) end
function fb.get_current_parser() return g.state.parser:get_id() end
function fb.get_current_parser_keyname() return g.state.parser.keybind_name or g.state.parser.name end
function fb.get_selected_index() return g.state.selected end
function fb.get_selected_item() return fb.copy_table(g.state.list[g.state.selected]) end
function fb.get_open_status() return not g.state.hidden end
function fb.get_parse_state(co) return g.parse_states[co or coroutine.running() or ""] end

function fb.set_empty_text(str)
    g.state.empty_text = str
    fb.redraw()
end

function fb.set_selected_index(index)
    if type(index) ~= "number" then return false end
    if index < 1 then index = 1 end
    if index > #g.state.list then index = #g.state.list end
    g.state.selected = index
    fb.redraw()
    return index
end

return fb
