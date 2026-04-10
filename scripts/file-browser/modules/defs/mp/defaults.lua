---@meta mp

---@class mp
local mp = {}

---@class AsyncReturn

---@class MPTimer
---@field stop fun(self: MPTimer)
---@field kill fun(self: MPTimer)
---@field resume fun(self: MPTimer)
---@field is_enabled fun(self: MPTimer): boolean
---@field timeout number
---@field oneshot boolean

---@class OSDOverlay
---@field data string
---@field res_x number
---@field res_y number
---@field z number
---@field update fun(self:OSDOverlay)
---@field remove fun(self: OSDOverlay)

---@class MPVSubprocessResult
---@field status number
---@field stdout string
---@field stderr string
---@field error_string ''|'killed'|'init'
---@field killed_by_us boolean

---@param key string
---@param name_or_fn string|function
---@param fn? async fun()
---@param flags? KeybindFlags
function mp.add_key_binding(key, name_or_fn, fn, flags) end

---@param key string
---@param name_or_fn string|function
---@param fn? async fun()
---@param flags? KeybindFlags
function mp.add_forced_key_binding(key, name_or_fn, fn, flags) end

---@param seconds number
---@param fn function
---@param disabled? boolean
---@return MPTimer
function mp.add_timeout(seconds, fn, disabled) end

---@param format 'ass-events'
---@return OSDOverlay
function mp.create_osd_overlay(format) end

---@param ... string
function mp.commandv(...) end

---@generic T
---@param t table
---@param def? T
---@return unknown|T result
---@return string? error
---@overload fun(t: table): (unknown|nil, string?)
function mp.command_native(t, def) end

---@nodiscard
---@param t table
---@param cb fun(success: boolean, result: unknown, error: string?)
---@return AsyncReturn
function mp.command_native_async(t, cb) end

---@param t AsyncReturn
function mp.abort_async_command(t) end

---@generic T
---@param name string
---@param def? T
---@return string|T
---@overload fun(name: string): string|nil
function mp.get_property(name, def) end

---@generic T
---@param name string
---@param def? T
---@return boolean|T
---@overload fun(name: string): boolean|nil
function mp.get_property_bool(name, def) end

---@generic T
---@param name string
---@param def? T
---@return number|T
---@overload fun(name: string): number|nil
function mp.get_property_number(name, def) end

---@generic T
---@param name string
---@param def? T
---@return unknown|T
---@overload fun(name: string): unknown|nil
function mp.get_property_native(name, def) end

---@return string|nil
function mp.get_script_directory() end

---@return string
function mp.get_script_name() end

---@param name string
---@param type 'native'|'bool'|'string'|'number'
---@param fn fun(name: string, v: unknown)
function mp.observe_property(name, type, fn) end

---@param name string
---@param fn function
---@return boolean
function mp.register_event(name, fn) end

---@param name string
---@param fn fun(...: string)
function mp.register_script_message(name, fn) end

---@param name string
function mp.remove_key_binding(name) end

---@param name string
---@param value string
---@return true? success # nil if error
---@return string? err
function mp.set_property(name, value) end

---@param name string
---@param value boolean
---@return true? success # nil if error
---@return string? err
function mp.set_property_bool(name, value) end

---@param name string
---@param value number
---@return true? success # nil if error
---@return string? err
function mp.set_property_number(name, value) end

---@param name string
---@param value any
---@return true? success # nil if error
---@return string? err
function mp.set_property_native(name, value) end

return mp