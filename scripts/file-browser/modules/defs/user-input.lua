---@meta user-input-module

---@class user_input_module
local user_input_module = {}

---@class UserInputOpts
---@field id string?
---@field source string?
---@field request_text string?
---@field default_input string?
---@field cursor_pos number?
---@field queueable boolean?
---@field replace boolean?

---@class UserInputRequest
---@field callback function?
---@field passthrough_args any[]?
---@field pending boolean
---@field cancel fun(self: UserInputRequest)
---@field update fun(self: UserInputRequest, opts: UserInputOpts)

---@param fn function
---@param opts UserInputOpts
---@param ... any passthrough arguments
---@return UserInputRequest
function user_input_module.get_user_input(fn, opts, ...) end

return user_input_module
