
local g = require 'modules.globals'

--parser object for the root
--not inserted to the parser list as it has special behaviour
--it does get get added to parsers under it's ID to prevent confusing duplicates
local root_parser = {
    name = "root",
    priority = math.huge,

    --if this is being called then all other parsers have failed and we've fallen back to root
    can_parse = function() return true end,

    --we return the root directory exactly as setup
    parse = function(self)
        return g.root, {
            sorted = true,
            filtered = true,
            escaped = true,
            parser = self,
            directory = "",
        }
    end
}

return root_parser
