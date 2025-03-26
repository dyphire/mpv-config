---@meta mp.input

---@class mp.input
local input = {}

---@class InputGetOpts
---@field prompt string?
---@field default_text string?
---@field id string?
---@field submit (fun(text: string))?
---@field opened (fun())?
---@field edited (fun(text: string))?
---@field complete (fun(text_before_cursor: string): string[], number)?
---@field closed (fun(text: string))?

---@param options InputGetOpts
function input.get(options) end

function input.terminate() end

return input