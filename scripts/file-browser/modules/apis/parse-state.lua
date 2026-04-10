
local msg = require 'mp.msg'

local g = require 'modules.globals'

---@class ParseStateAPI
local parse_state_API = {}

---A wrapper around coroutine.yield that aborts the coroutine if
--the parse request was cancelled by the user.
--the coroutine is
---@async
---@param self ParseState
---@param ... any
---@return unknown ...
function parse_state_API:yield(...)
    local co = coroutine.running()
    local is_browser = co == g.state.co

    local result = table.pack(coroutine.yield(...))
    if is_browser and co ~= g.state.co then
        msg.verbose("browser no longer waiting for list - aborting parse for", self.directory)
        error(g.ABORT_ERROR)
    end
    return table.unpack(result, 1, result.n)
end

---Checks if the current coroutine is the one handling the browser's request.
---@return boolean
function parse_state_API:is_coroutine_current()
    return coroutine.running() == g.state.co
end

return parse_state_API
