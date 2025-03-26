--[[
    This file is an internal file-browser addon.
    It should not be imported like a normal module.

    Allows searching the current directory.
]]--

local msg = require "mp.msg"
local fb = require "file-browser"
local input_loaded, input = pcall(require, "mp.input")
local user_input_loaded, user_input = pcall(require, "user-input-module")

---@type ParserConfig
local find = {
    api_version = "1.3.0"
}

---@type thread|nil
local latest_coroutine = nil

---@type State
local global_fb_state = getmetatable(fb.get_state()).__original

---@param name string
---@param query string
---@return boolean
local function compare(name, query)
    if name:find(query) then return true end
    if name:lower():find(query) then return true end
    if name:upper():find(query) then return true end

    return false
end

---@async
---@param key Keybind
---@param state State
---@param co thread
---@return boolean?
local function main(key, state, co)
    if not state.list then return false end

    ---@type string
    local text
    if key.name == "find/find" then text = "Find: enter search string"
    else text = "Find: enter advanced search string" end

    if input_loaded then
        input.get({
            prompt = text .. "\n>",
            id = "file-browser/find",
            submit = fb.coroutine.callback(),
        })
    elseif user_input_loaded then
        user_input.get_user_input( fb.coroutine.callback(), { text = text, id = "find", replace = true } )
    end

    local query, error = coroutine.yield()
    if input_loaded then input.terminate() end
    if not query then return msg.debug(error) end

    -- allow the directory to be changed before this point
    local list = fb.get_list()
    local parse_id = global_fb_state.co

    if key.name == "find/find" then
        query = fb.pattern_escape(query)
    end

    local results = {}

    for index, item in ipairs(list) do
        if compare(item.label or item.name, query) then
            table.insert(results, index)
        end
    end

    if (#results < 1) then
        msg.warn("No matching items for '"..query.."'")
        return
    end

    --keep cycling through the search results if any are found
    --putting this into a separate coroutine removes any passthrough ambiguity
    --the final return statement should return to `step_find` not any other function
    ---@async
    fb.coroutine.run(function()
        latest_coroutine = coroutine.running()
        ---@type number
        local rindex = 1
        while (true) do

            if rindex == 0 then rindex = #results
            elseif rindex == #results + 1 then rindex = 1 end

            fb.set_selected_index(results[rindex])
            local direction = coroutine.yield(true) --[[@as number]]
            rindex = rindex + direction

            if parse_id ~= global_fb_state.co then
                latest_coroutine = nil
                return
            end
        end
    end)
end

local function step_find(key)
    if not latest_coroutine then return false end
    ---@type number
    local direction = 0
    if key.name == "find/next" then direction = 1
    elseif key.name == "find/prev" then direction = -1 end
    return fb.coroutine.resume_err(latest_coroutine, direction)
end

find.keybinds = {
    {"Ctrl+f", "find", main, {}},
    {"Ctrl+F", "find_advanced", main, {}},
    {"n", "next", step_find, {}},
    {"N", "prev", step_find, {}},
}

return find
