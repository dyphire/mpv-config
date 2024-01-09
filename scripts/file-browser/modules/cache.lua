--------------------------------------------------------------------------------------------------------
--------------------------------------Cache Implementation----------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

local g = require 'modules.globals'

--metatable of methods to manage the cache
local __cache = {}

__cache.cached_values = {
    "directory", "directory_label", "list", "selected", "selection", "parser", "empty_text", "co"
}

--inserts latest state values onto the cache stack
function __cache:push()
    local t = {}
    for _, value in ipairs(self.cached_values) do
        t[value] = g.state[value]
    end
    table.insert(self, t)
end

function __cache:pop()
    table.remove(self)
end

function __cache:apply()
    local t = self[#self]
    for _, value in ipairs(self.cached_values) do
        g.state[value] = t[value]
    end
end

function __cache:clear()
    for i = 1, #self do
        self[i] = nil
    end
end

local cache = setmetatable({}, { __index = __cache })

return cache
