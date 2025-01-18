--[[
    An addon for mpv-file-browser for searching the current directory
    Available at: https://github.com/CogentRedTester/mpv-file-browser/tree/master/addons

    Requires mpv-user-input: https://github.com/CogentRedTester/mpv-user-input

    Keybinds:
        Ctrl+f  open search box
        Ctrl+F  open advanced search box (supports Lua patterns)
        n       cycle to next valid item
]]--

local msg = require "mp.msg"
local fb = require "file-browser"
local input_loaded, input = pcall(require, "mp.input")
local user_input_loaded, user_input = pcall(require, "user-input-module")

local find = {
    version = "1.3.0"
}
local latest_coroutine = nil
local global_fb_state = getmetatable(fb.get_state()).__original

local function compare(name, query)
    if name:find(query) then return true end
    if name:lower():find(query) then return true end
    if name:upper():find(query) then return true end

    return false
end

local function main(key, state, co)
    if not state.list then return false end

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
    fb.coroutine.run(function()
        latest_coroutine = coroutine.running()
        while (true) do
            for _, index in ipairs(results) do
                fb.set_selected_index(index)
                coroutine.yield(true)

                if parse_id ~= global_fb_state.co then
                    latest_coroutine = nil
                    return false
                end
            end
        end
    end)
end

local function step_find()
    if not latest_coroutine then return false end
    return fb.coroutine.resume_err(latest_coroutine)
end

find.keybinds = {
    {"Ctrl+f", "find", main, {}},
    {"Ctrl+F", "find_advanced", main, {}},
    {"n", "next", step_find, {}},
}

return find
