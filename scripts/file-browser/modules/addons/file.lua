-- This file is an internal file-browser addon.
-- It should not be imported like a normal module.

local msg = require 'mp.msg'
local utils = require 'mp.utils'

---Parser for native filesystems
---@type ParserConfig
local file_parser = {
    name = "file",
    priority = 110,
    api_version = '1.0.0',
}

--try to parse any directory except for the root
function file_parser:can_parse(directory)
    return directory ~= ''
end

--scans the given directory using the mp.utils.readdir function
function file_parser:parse(directory)
    local new_list = {}
    local list1 = utils.readdir(directory, 'dirs')
    if list1 == nil then return nil end

    --sorts folders and formats them into the list of directories
    for i=1, #list1 do
        local item = list1[i]

        msg.trace(item..'/')
        table.insert(new_list, {name = item..'/', type = 'dir'})
    end

    --appends files to the list of directory items
    local list2 = utils.readdir(directory, 'files')
    if list2 == nil then return nil end
    for i=1, #list2 do
        local item = list2[i]

        msg.trace(item)
        table.insert(new_list, {name = item, type = 'file'})
    end
    return new_list
end

return file_parser
