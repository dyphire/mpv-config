local msg = require 'mp.msg'

local g = require 'modules.globals'
local scanning = require 'modules.navigation.scanning'
local fb = require 'modules.apis.fb'

---@class ParserAPI: FbAPI
local parser_api = setmetatable({}, { __index = fb })

---Returns the index of the parser.
---@return number
function parser_api:get_index() return g.parsers[self].index end

---Returns the ID of the parser
---@return string
function parser_api:get_id() return g.parsers[self].id end

---A newer API for adding items to the root.
---Only adds the item if the same item does not already exist in the root.
---Wrapper around `fb.register_root_item`.
---@param item Item|string
---@param priority? number  The priority for the added item. Uses the parsers priority by default.
---@return boolean
function parser_api:register_root_item(item, priority)
    return fb.register_root_item(item, priority or g.parsers[self:get_id()].priority)
end

---Runs choose_and_parse starting from the next parser.
---@async
---@param directory string
---@return Item[]?
---@return Opts?
function parser_api:defer(directory)
    msg.trace("deferring to other parsers...")
    local list, opts = scanning.choose_and_parse(directory, self:get_index() + 1)
    fb.get_parse_state().already_deferred = true
    return list, opts
end

return parser_api
