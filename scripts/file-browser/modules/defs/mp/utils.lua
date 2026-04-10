---@meta mp.utils

---@class mp.utils
local utils = {}

---@param v string|boolean|number|table|nil
---@return string? json # nil on error
---@return string? err # error
function utils.format_json(v) end

---@param p1 string
---@param p2 string
---@return string
function utils.join_path(p1, p2) end

---@param str string
---@param trail? boolean
---@return (table|unknown[])? t
---@return string? err # error
---@return string trail # trailing characters
function utils.parse_json(str, trail) end

---@param path string
---@param filter ('files'|'dirs'|'normal'|'all')?
---@return string[]? # nil on error
---@return string? err # error
function utils.readdir(path, filter) end

---@deprecated
---@param name string
---@param value string
function utils.shared_script_property_set(name, value) end

---@param path string
---@return string directory
---@return string filename
function utils.split_path(path) end

---@param v any
---@return string
function utils.to_string(v) end

return utils
