local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local g = require 'modules.globals'
local API = require 'modules.utils'
local root_parser = require 'modules.parsers.root'
local cache = require 'modules.cache'
local cursor = require 'modules.navigation.cursor'
local ass = require 'modules.ass'

local parse_state_API = require 'modules.apis.parse-state'

--parses the given directory or defers to the next parser if nil is returned
local function choose_and_parse(directory, index)
    msg.debug("finding parser for", directory)
    local parser, list, opts
    local parse_state = g.parse_states[coroutine.running() or ""]
    while list == nil and not parse_state.already_deferred and index <= #g.parsers do
        parser = g.parsers[index]
        if parser:can_parse(directory, parse_state) then
            msg.debug("attempting parser:", parser:get_id())
            list, opts = parser:parse(directory, parse_state)
        end
        index = index + 1
    end
    if not list then return nil, {} end

    msg.debug("list returned from:", parser:get_id())
    opts = opts or {}
    if list then opts.id = opts.id or parser:get_id() end
    return list, opts
end

--sets up the parse_state table and runs the parse operation
local function run_parse(directory, parse_state)
    msg.verbose("scanning files in", directory)
    parse_state.directory = directory

    local co = coroutine.running()
    g.parse_states[co] = setmetatable(parse_state, { __index = parse_state_API })

    if directory == "" then return root_parser:parse() end
    local list, opts = choose_and_parse(directory, 1)

    if list == nil then return msg.debug("no successful parsers found") end
    opts.parser = g.parsers[opts.id]

    if not opts.filtered then API.filter(list) end
    if not opts.sorted then API.sort(list) end
    return list, opts
end

--returns the contents of the given directory using the given parse state
--if a coroutine has already been used for a parse then create a new coroutine so that
--the every parse operation has a unique thread ID
local function parse_directory(directory, parse_state)
    local co = API.coroutine.assert("scan_directory must be executed from within a coroutine - aborting scan "..utils.to_string(parse_state))
    if not g.parse_states[co] then return run_parse(directory, parse_state) end

    --if this coroutine is already is use by another parse operation then we create a new
    --one and hand execution over to that
    local new_co = coroutine.create(function()
        API.coroutine.resume_err(co, run_parse(directory, parse_state))
    end)

    --queue the new coroutine on the mpv event queue
    mp.add_timeout(0, function()
        local success, err = coroutine.resume(new_co)
        if not success then
            API.traceback(err, new_co)
            API.coroutine.resume_err(co)
        end
    end)
    return g.parse_states[co]:yield()
end

--sends update requests to the different parsers
local function update_list(moving_adjacent)
    msg.verbose('opening directory: ' .. g.state.directory)

    g.state.selected = 1
    g.state.selection = {}

    --loads the current directry from the cache to save loading time
    --there will be a way to forcibly reload the current directory at some point
    --the cache is in the form of a stack, items are taken off the stack when the dir moves up
    if cache[1] and cache[#cache].directory == g.state.directory then
        msg.verbose('found directory in cache')
        cache:apply()
        g.state.prev_directory = g.state.directory
        return
    end
    local directory = g.state.directory
    local list, opts = parse_directory(g.state.directory, { source = "browser" })

    --if the running coroutine isn't the one stored in the state variable, then the user
    --changed directories while the coroutine was paused, and this operation should be aborted
    if coroutine.running() ~= g.state.co then
        msg.verbose(g.ABORT_ERROR.msg)
        msg.debug("expected:", g.state.directory, "received:", directory)
        return
    end

    --apply fallbacks if the scan failed
    if not list and cache[1] then
        --switches settings back to the previously opened directory
        --to the user it will be like the directory never changed
        msg.warn("could not read directory", g.state.directory)
        cache:apply()
        return
    elseif not list then
        msg.warn("could not read directory", g.state.directory)
        list, opts = root_parser:parse()
    end

    g.state.list = list
    g.state.parser = opts.parser

    --this only matters when displaying the list on the screen, so it doesn't need to be in the scan function
    if not opts.escaped then
        for i = 1, #list do
            list[i].ass = list[i].ass or API.ass_escape(list[i].label or list[i].name, true)
        end
    end

    --setting custom options from parsers
    g.state.directory_label = opts.directory_label
    g.state.empty_text = opts.empty_text or g.state.empty_text

    --we assume that directory is only changed when redirecting to a different location
    --therefore, the cache should be wiped
    if opts.directory then
        g.state.directory = opts.directory
        cache:clear()
    end

    if opts.selected_index then
        g.state.selected = opts.selected_index or g.state.selected
        if g.state.selected > #g.state.list then g.state.selected = #g.state.list
        elseif g.state.selected < 1 then g.state.selected = 1 end
    end

    if moving_adjacent then cursor.select_prev_directory()
    else cursor.select_playing_item() end
    g.state.prev_directory = g.state.directory
end

--rescans the folder and updates the list
local function update(moving_adjacent)
    --we can only make assumptions about the directory label when moving from adjacent directories
    if not moving_adjacent then
        g.state.directory_label = nil
        cache:clear()
    end

    g.state.empty_text = "~"
    g.state.list = {}
    cursor.disable_select_mode()
    ass.update_ass()

    --the directory is always handled within a coroutine to allow addons to
    --pause execution for asynchronous operations
    API.coroutine.run(function()
        g.state.co = coroutine.running()
        update_list(moving_adjacent)
        g.state.empty_text = "empty directory"
        ass.update_ass()
    end)
end

return {
    rescan = update,
    scan_directory = parse_directory,
    choose_and_parse = choose_and_parse,
}
