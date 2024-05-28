local msg = require 'mp.msg'

local g = require 'modules.globals'
local scanning = require 'modules.navigation.scanning'
local fb = require 'modules.apis.fb'

local parser_api = setmetatable({}, { __index = fb })

function parser_api:get_index() return g.parsers[self].index end
function parser_api:get_id() return g.parsers[self].id end

--a wrapper that passes the parsers priority value if none other is specified
function parser_api:register_root_item(item, priority)
    return fb.register_root_item(item, priority or g.parsers[self:get_id()].priority)
end

--runs choose_and_parse starting from the next parser
function parser_api:defer(directory)
    msg.trace("deferring to other parsers...")
    local list, opts = scanning.choose_and_parse(directory, self:get_index() + 1)
    fb.get_parse_state().already_deferred = true
    return list, opts
end

return parser_api
