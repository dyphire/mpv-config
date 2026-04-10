---@meta mp.options

---@class mp.options
local options = {}

---@param t table<string,string|number|boolean>
---@param identifier? string
---@param on_update? fun(list: table<string,true|nil>)
function options.read_options(t, identifier, on_update) end

return options
