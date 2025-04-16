local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = require 'modules.options'
local g = require 'modules.globals'
local fb_utils = require 'modules.utils'
local ass = require 'modules.ass'
local directory_movement = require 'modules.navigation.directory-movement'
local scanning = require 'modules.navigation.scanning'
local controls = require 'modules.controls'

---@class FbAPI: fb_utils
local fb = setmetatable({}, { __index = setmetatable({}, { __index = fb_utils }) })
package.loaded["file-browser"] = setmetatable({}, { __index = fb })

--these functions we'll provide as-is
fb.redraw = ass.update_ass
fb.browse_directory = controls.browse_directory

---Clears the directory cache.
---@return thread
function fb.rescan()
    return scanning.rescan()
end

---@async
---@return thread
function fb.rescan_await()
    local co = scanning.rescan(nil, fb_utils.coroutine.callback())
    coroutine.yield()
    return co
end

---@param directories? string[]
function fb.clear_cache(directories)
    if directories then
        mp.commandv('script-message-to', mp.get_script_name(), 'cache/clear', utils.format_json(directories))
    else
        mp.commandv('script-message-to', mp.get_script_name(), 'cache/clear')
    end
end

---A wrapper around scan_directory for addon API.
---@async
---@param directory string
---@param parse_state ParseStateTemplate
---@return Item[]|nil
---@return Opts
function fb.parse_directory(directory, parse_state)
    if not parse_state then parse_state = { source = "addon" }
    elseif not parse_state.source then parse_state.source = "addon" end
    return scanning.scan_directory(directory, parse_state)
end

---Register file extensions which can be opened by the browser.
---@param ext string
function fb.register_parseable_extension(ext)
    g.parseable_extensions[string.lower(ext)] = true
end

---Deregister file extensions which can be opened by the browser.
---@param ext string
function fb.remove_parseable_extension(ext)
    g.parseable_extensions[string.lower(ext)] = nil
end

---Add a compatible extension to show through the filter, only applies if run during the setup() method.
---@param ext string
function fb.add_default_extension(ext)
    table.insert(g.compatible_file_extensions, ext)
end

---Add item to root at position pos.
---@param item Item
---@param pos? number
function fb.insert_root_item(item, pos)
    msg.debug("adding item to root", item.label or item.name, pos)
    item.ass = item.ass or fb.ass_escape(item.label or item.name)
    item.type = "dir"
    table.insert(g.root, pos or (#g.root + 1), item)
end

---Add a new mapping to the given directory.
---@param directory string
---@param mapping string
---@param pattern? boolean
---@return string
function fb.register_directory_mapping(directory, mapping, pattern)
    if not pattern then mapping = '^'..fb_utils.pattern_escape(mapping) end
    g.directory_mappings[mapping] = directory
    msg.verbose('registering directory alias', mapping, directory)

    directory_movement.set_current_file(g.current_file.original_path)
    return mapping
end

---Remove all directory mappings that map to the given directory.
---@param directory string
---@return string[]
function fb.remove_all_mappings(directory)
    local removed = {}
    for mapping, target in pairs(g.directory_mappings) do
        if target == directory then
            g.directory_mappings[mapping] = nil
            table.insert(removed, mapping)
        end
    end
    return removed
end

---A newer API for adding items to the root.
---Only adds the item if the same item does not already exist in the root.
---@param item Item|string
---@param priority? number Specifies the insertion location, a lower priority
---                        is placed higher in the list and the default is 100.
---@return boolean
function fb.register_root_item(item, priority)
    msg.verbose('registering root item:', utils.to_string(item))
    if type(item) == 'string' then
        item = {name = item, type = 'dir'}
    end

    -- if the item is already in the list then do nothing
    if fb.list.some(g.root, function(r)
        return fb.get_full_path(r, '') == fb.get_full_path(item, '')
    end) then return false end

    ---@type table<Item,number>
    local priorities = {}

    priorities[item] = priority
    for i, v in ipairs(g.root) do
        if (priorities[v] or 100) > (priority or 100) then
            fb.insert_root_item(item, i)
            return true
        end
    end
    fb.insert_root_item(item)
    return true
end

--providing getter and setter functions so that addons can't modify things directly


---@param key string
---@return boolean|string|number
function fb.get_opt(key) return o[key] end

function fb.get_script_opts() return fb.copy_table(o) end
function fb.get_platform() return g.PLATFORM end
function fb.get_extensions() return fb.copy_table(g.extensions) end
function fb.get_sub_extensions() return fb.copy_table(g.sub_extensions) end
function fb.get_audio_extensions() return fb.copy_table(g.audio_extensions) end
function fb.get_parseable_extensions() return fb.copy_table(g.parseable_extensions) end
function fb.get_state() return fb.copy_table(g.state) end
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
function fb.get_history() return fb.copy_table(g.history.list) end
function fb.get_history_index() return g.history.position end

---@deprecated
---@return string|nil
function fb.get_dvd_device()
    local dvd_device = mp.get_property('dvd-device')
    if not dvd_device or dvd_device == '' then return nil end
    return fb_utils.fix_path(dvd_device, true)
end

---@param str string
function fb.set_empty_text(str)
    g.state.empty_text = str
    fb.redraw()
end

---@param index number
---@return number|false
function fb.set_selected_index(index)
    if type(index) ~= "number" then return false end
    if index < 1 then index = 1 end
    if index > #g.state.list then index = #g.state.list end
    g.state.selected = index
    fb.redraw()
    return index
end

fb.set_history_index = directory_movement.goto_history

return fb
