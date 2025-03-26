---@meta _

---@class KeybindFlags
---@field repeatable boolean?
---@field scalable boolean?
---@field complex boolean?


---@class KeybindCommandTable


---@class Keybind
---@field key string
---@field command KeybindCommand
---@field api_version string?
---
---@field name string?
---@field condition string?
---@field flags KeybindFlags?
---@field filter ('file'|'dir')?
---@field parser string?
---@field multiselect boolean?
---@field multi-type ('repeat'|'concat')?
---@field delay number?
---@field concat-string string?
---@field passthrough boolean?
---
---@field prev_key Keybind?     The keybind that was previously set to the same key.
---@field codes Set<string>?     Any substituation codes used by the command table.
---@field condition_codes Set<string>?   Any substitution codes used by the condition string.
---@field addon boolean?    Whether the keybind was created by an addon.


---@alias KeybindFunctionCallback async fun(keybind: Keybind, state: State, co: thread)

---@alias KeybindCommand KeybindFunctionCallback|KeybindCommandTable[]
---@alias KeybindTuple [string,string,KeybindCommand,KeybindFlags?]
---@alias KeybindTupleStrict [string,string,KeybindFunctionCallback,KeybindFlags?]
---@alias KeybindList (Keybind|KeybindTuple)[]
