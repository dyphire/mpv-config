--[[
    This file is an internal file-browser addon.
    It should not be imported like a normal module.

    Maintains a cache of the accessed directories to improve
    parsing speed. Disabled by default.
]]

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local fb = require 'file-browser'

---@type ParserConfig
local cacheParser = {
    name = 'cache',
    priority = 0,
    api_version = '1.9',
}

---@class CacheEntry
---@field list List
---@field opts Opts?
---@field timeout MPTimer

---@type table<string,CacheEntry>
local cache = {}

---@type table<string,(async fun(list: List?, opts: Opts?))[]>
local pending_parses = {}

---@param directories? string[]
local function clear_cache(directories)
    if directories then
        msg.debug('clearing cache for', #directories, 'directorie(s)')
        for _, dir in ipairs(directories) do
            if cache[dir] then
                msg.trace('clearing cache for', dir)
                cache[dir].timeout:kill()
                cache[dir] = nil
            end
        end
    else
        msg.debug('clearing cache')
        for _, entry in pairs(cache) do
            entry.timeout:kill()
        end
        cache = {}
    end
end

---@type string
local prev_directory = ''

function cacheParser:can_parse(directory, parse_state)
    -- allows the cache to be forcibly used or bypassed with the
    -- cache/use parse property.
    if parse_state.properties.cache and parse_state.properties.cache.use ~= nil then
        if parse_state.source == 'browser' then prev_directory = directory end
        return parse_state.properties.cache.use
    end

    -- the script message is guaranteed to always bypass the cache
    if parse_state.source == 'script-message' then return false end
    if not fb.get_opt('cache') or directory == '' then return false end

    -- clear the cache if reloading the current directory in the browser
    -- this means that fb.rescan() should maintain expected behaviour
    if parse_state.source == 'browser' then
        if prev_directory == directory then clear_cache({directory}) end
        prev_directory = directory
    end

    return true
end

---@async
function cacheParser:parse(directory)
    if cache[directory] then
        msg.verbose('fetching', directory, 'contents from cache')
        cache[directory].timeout:kill()
        cache[directory].timeout:resume()
        return cache[directory].list, cache[directory].opts
    end

    ---@type List?, Opts?
    local list, opts

    -- if another parse is already running on the same directory, then wait and use the same result
    if not pending_parses[directory] then
        pending_parses[directory] = {}
        list, opts = self:defer(directory)
    else
        msg.debug('parse for', directory, 'already running - waiting for other parse to finish...')
        table.insert(pending_parses[directory], fb.coroutine.callback(30))
        list, opts = coroutine.yield()
    end

    local pending = pending_parses[directory]
    -- need to clear the pending parses before resuming them or they will also attempt to resume the parses
    pending_parses[directory] = nil
    if pending and #pending > 0 then
        msg.debug('resuming', #pending, 'pending parses for', directory)
        for _, cb in ipairs(pending) do
            cb(list, opts)
        end
    end

    if not list then return end

    -- pending will be truthy for the original parse and falsy for any parses that were pending
    if pending then
        msg.debug('storing', directory, 'contents in cache')
        cache[directory] = {
            list = list,
            opts = opts,
            timeout = mp.add_timeout(120, function() cache[directory] = nil end),
        }
    end

    return list, opts
end

cacheParser.keybinds = {
    {
        key = 'Ctrl+Shift+r',
        name = 'clear',
        command = function() clear_cache() ; fb.rescan() end,
    }
}

-- provide method of clearing the cache through script messages
mp.register_script_message('cache/clear', function(dirs)
    if not dirs then
        return clear_cache()
    end

    ---@type string[]?
    local directories = utils.parse_json(dirs)
    if not directories then msg.error('unable to parse', dirs) end

    clear_cache(directories)
end)

return cacheParser
