---@meta _

---@alias List Item[]

---Represents an item returned by the parsers.
---@class Item
---@field type 'file'|'dir'
---@field name string
---@field label string?
---@field path string?
---@field ass string?
---@field redirect boolean?
---@field mpv_options string|{[string]: unknown}?


---The Opts table returned by the parsers.
---@class Opts
---@field filtered boolean?
---@field sorted boolean?
---@field directory string?
---@field directory_label string?
---@field empty_text string?
---@field selected_index number?
---@field id string?
---@field parser Parser?