local msg = require 'mp.msg'
local utils = require 'mp.utils'
local fb = require 'file-browser'

local parser = {
    priority = 105,
    api_version = '1.2.0'
}

-- stores a table of the parsers loaded by file-browser
-- we will use this to check if a parser is for a local file system
local parsers

local sort_mode = 0

function parser:setup()
    parsers = fb.get_parsers()
end

function parser:parse(directory)
    if sort_mode == 0 or fb.get_protocol(directory) then return end
    local list, opts = self:defer(directory)
    if not list then return list, opts end

    -- Only run this on parsers that are for the local filesystem.
    -- We assume that custom addons for the local filesystem are setting the keybind_name field to 'file'
    -- for compatability.
    if parsers[opts.id] then
        if parsers[opts.id].keybind_name ~= 'file' and parsers[opts.id].name ~= 'file' then
            return list, opts
        end
    end

    directory = opts.directory or directory
    local cache = {}

    -- gets the file info of an item
    -- uses memoisation to speed things up 
    function get_file_info(item)
        if cache[item] then return cache[item] end

        local path = fb.get_full_path(item, directory)
        local file_info = utils.file_info(path)
        if not file_info then
            msg.warn('failed to read file info for', path)
            return {}
        end

        cache[item] = file_info
        return file_info
    end

    -- sorts the items based on the latest modification time
    -- if mtime is undefined due to a file read failure then use 0
    table.sort(list, function(a, b)
        -- `dir` will compare as less than `file`
        if a.type ~= b.type then return a.type < b.type end
        if sort_mode == 1 then
            return (get_file_info(a).mtime or 0) < (get_file_info(b).mtime or 0)
        elseif sort_mode == 2 then
            return (get_file_info(a).mtime or 0) > (get_file_info(b).mtime or 0)
        elseif sort_mode == 3 then
            return (get_file_info(a).size or 0) < (get_file_info(b).size or 0)
        elseif sort_mode == 4 then
            return (get_file_info(a).size or 0) > (get_file_info(b).size or 0)
        end
    end)

    opts.sorted = true
    return list, opts
end

-- adds the keybind to toggle sorting
parser.keybinds = {
    {
        key = '^',
        name = 'toggle_sort',
        command = function()
            sort_mode = sort_mode + 1
            if sort_mode > 4 then sort_mode = 0 end
            fb.rescan()
        end
    }
}

return parser
