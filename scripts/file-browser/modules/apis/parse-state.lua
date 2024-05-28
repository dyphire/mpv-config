
local msg = require 'mp.msg'

local g = require 'modules.globals'

local parse_state_API = {}

--a wrapper around coroutine.yield that aborts the coroutine if
--the parse request was cancelled by the user
--the coroutine is 
function parse_state_API:yield(...)
    local co = coroutine.running()
    local is_browser = co == g.state.co
    if self.source == "browser" and not is_browser then
        msg.error("current coroutine does not match browser's expected coroutine - did you unsafely yield before this?")
        error("current coroutine does not match browser's expected coroutine - aborting the parse")
    end

    local result = table.pack(coroutine.yield(...))
    if is_browser and co ~= g.state.co then
        msg.verbose("browser no longer waiting for list - aborting parse for", self.directory)
        error(g.ABORT_ERROR)
    end
    return unpack(result, 1, result.n)
end

--checks if the current coroutine is the one handling the browser's request
function parse_state_API:is_coroutine_current()
    return coroutine.running() == g.state.co
end

return parse_state_API
