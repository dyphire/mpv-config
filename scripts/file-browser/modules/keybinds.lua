------------------------------------------------------------------------------------------
----------------------------------Keybind Implementation----------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = require 'modules.options'
local g = require 'modules.globals'
local fb_utils = require 'modules.utils'
local addons = require 'modules.addons'
local playlist = require 'modules.playlist'
local controls = require 'modules.controls'
local movement = require 'modules.navigation.directory-movement'
local scanning = require 'modules.navigation.scanning'
local cursor = require 'modules.navigation.cursor'

g.state.keybinds = {
    {'ENTER',       'play',             function() playlist.add_files('replace', false) end},
    {'Shift+ENTER', 'play_append',      function() playlist.add_files('append-play', false) end},
    {'Alt+ENTER',   'play_autoload',    function() playlist.add_files('replace', true) end},
    {'ESC',         'close',            controls.escape},
    {'RIGHT',       'down_dir',         movement.down_dir},
    {'LEFT',        'up_dir',           movement.up_dir},
    {'Alt+RIGHT',   'history_forward',  movement.forwards_history},
    {'Alt+LEFT',    'history_back',     movement.back_history},
    {'DOWN',        'scroll_down',      function() cursor.scroll(1, o.wrap) end,           {repeatable = true}},
    {'UP',          'scroll_up',        function() cursor.scroll(-1, o.wrap) end,          {repeatable = true}},
    {'PGDWN',       'page_down',        function() cursor.scroll(o.num_entries) end,       {repeatable = true}},
    {'PGUP',        'page_up',          function() cursor.scroll(-o.num_entries) end,      {repeatable = true}},
    {'Shift+PGDWN', 'list_bottom',      function() cursor.scroll(math.huge) end},
    {'Shift+PGUP',  'list_top',         function() cursor.scroll(-math.huge) end},
    {'HOME',        'goto_current',     movement.goto_current_dir},
    {'Shift+HOME',  'goto_root',        movement.goto_root},
    {'Ctrl+r',      'reload',           function() scanning.rescan() end},
    {'s',           'select_mode',      cursor.toggle_select_mode},
    {'S',           'select_item',      cursor.toggle_selection},
    {'Ctrl+a',      'select_all',       cursor.select_all}
}

---a map of key-keybinds - only saves the latest keybind if multiple have the same key code
---@type KeybindList
local top_level_keys = {}

---Format the item string for either single or multiple items.
---@param base_code_fn Replacer
---@param items Item[]
---@param state State
---@param cmd Keybind
---@param quoted? boolean
---@return string|nil
local function create_item_string(base_code_fn, items, state, cmd, quoted)
    if not items[1] then return end
    local func = quoted and function(...) return ("%q"):format(base_code_fn(...)) end or base_code_fn

    local out = {}
    for _, item in ipairs(items) do
        table.insert(out, func(item, state))
    end

    return table.concat(out, cmd['concat-string'] or ' ')
end

local KEYBIND_CODE_PATTERN = fb_utils.get_code_pattern(fb_utils.code_fns)
local item_specific_codes = 'fnij'

---Replaces codes in the given string using the replacers.
---@param str string
---@param cmd Keybind
---@param items Item[]
---@param state State
---@return string
local function substitute_codes(str, cmd, items, state)
    ---@type ReplacerTable
    local overrides = {}

    for code in item_specific_codes:gmatch('.') do
        overrides[code] = function(_,s) return create_item_string(fb_utils.code_fns[code], items, s, cmd) end
        overrides[code:upper()] = function(_,s) return create_item_string(fb_utils.code_fns[code], items, s, cmd, true) end
    end

    return fb_utils.substitute_codes(str, overrides, items[1], state)
end

---Iterates through the command table and substitutes special
---character codes for the correct strings used for custom functions.
---@param cmd Keybind
---@param items Item[]
---@param state State
---@return KeybindCommand
local function format_command_table(cmd, items, state)
    local command = cmd.command
    if type(command) == 'function' then return command end
    ---@type string[][]
    local copy = {}
    for i = 1, #command do
        ---@type string[]
        copy[i] = {}

        for j = 1, #command[i] do
            copy[i][j] = substitute_codes(cmd.command[i][j], cmd, items, state)
        end
    end
    return copy
end

---Runs all of the commands in the command table.
---@param cmd Keybind key.command must be an array of command tables compatible with mp.command_native
---@param items Item[] must be an array of multiple items (when multi-type ~= concat the array will be 1 long).
---@param state State
local function run_custom_command(cmd, items, state)
    local custom_cmds = cmd.codes and format_command_table(cmd, items, state) or cmd.command
    if type(custom_cmds) == 'function' then
        error(('attempting to run a function keybind as a command table keybind\n%s'):format(utils.to_string(cmd)))
    end

    for _, custom_cmd in ipairs(custom_cmds) do
        msg.debug("running command:", utils.to_string(custom_cmd))
        mp.command_native(custom_cmd)
    end
end

---returns true if the given code set has item specific codes (%f, %i, etc)
---@param codes Set<string>
---@return boolean
local function has_item_codes(codes)
    for code in pairs(codes) do
        if item_specific_codes:find(code:lower(), 1, true) then return true end
    end
    return false
end

---Runs one of the custom commands.
---@async
---@param cmd Keybind
---@param state State
---@param co thread
---@return boolean|nil
local function run_custom_keybind(cmd, state, co)
    --evaluates a condition and passes through the correct values
    local function evaluate_condition(condition, items)
        local cond = substitute_codes(condition, cmd, items, state)
        return fb_utils.evaluate_string('return '..cond) == true
    end

    -- evaluates the string condition to decide if the keybind should be run
    ---@type boolean
    local do_item_condition
    if cmd.condition then
        if has_item_codes(cmd.condition_codes) then
            do_item_condition = true
        elseif not evaluate_condition(cmd.condition, {}) then
            return false
        end
    end

    if cmd.parser then
       local parser_str = ' '..cmd.parser..' '
       if not parser_str:find( '%W'..(state.parser.keybind_name or state.parser.name)..'%W' ) then return false end
    end

    --these are for the default keybinds, or from addons which use direct functions
    if type(cmd.command) == 'function' then return cmd.command(cmd, cmd.addon and fb_utils.copy_table(state) or state, co) end

    --the function terminates here if we are running the command on a single item
    if not (cmd.multiselect and next(state.selection)) then
        if cmd.filter then
            if not state.list[state.selected] then return false end
            if state.list[state.selected].type ~= cmd.filter then return false end
        end

        if cmd.codes then
            --if the directory is empty, and this command needs to work on an item, then abort and fallback to the next command
            if not state.list[state.selected] and has_item_codes(cmd.codes) then return false end
        end

        if do_item_condition and not evaluate_condition(cmd.condition, { state.list[state.selected] }) then
            return false
        end
        run_custom_command(cmd, { state.list[state.selected] }, state)
        return true
    end

    --runs the command on all multi-selected items
    local selection = fb_utils.sort_keys(state.selection, function(item)
        if do_item_condition and not evaluate_condition(cmd.condition, { item }) then return false end
        return not cmd.filter or item.type == cmd.filter
    end)
    if not next(selection) then return false end

    if cmd["multi-type"] == "concat" then
        run_custom_command(cmd, selection, state)

    elseif cmd["multi-type"] == "repeat" or cmd["multi-type"] == nil then
        for i,_ in ipairs(selection) do
            run_custom_command(cmd, {selection[i]}, state)

            if cmd.delay then
                mp.add_timeout(cmd.delay, function() fb_utils.coroutine.resume_err(co) end)
                coroutine.yield()
            end
        end
    end

    --we passthrough by default if the command is not run on every selected item
    if cmd.passthrough ~= nil then return end

    local num_selection = 0
    for _ in pairs(state.selection) do num_selection = num_selection+1 end
    return #selection == num_selection
end

---Recursively runs the keybind functions, passing down through the chain
---of keybinds with the same key value.
---@async
---@param keybind Keybind
---@param state State
---@param co thread
local function run_keybind_recursive(keybind, state, co)
    msg.trace("Attempting custom command:", utils.to_string(keybind))

    if keybind.passthrough ~= nil then
        run_custom_keybind(keybind, state, co)
        if keybind.passthrough == true and keybind.prev_key then
            run_keybind_recursive(keybind.prev_key, state, co)
        end
    else
        if run_custom_keybind(keybind, state, co) == false and keybind.prev_key then
            run_keybind_recursive(keybind.prev_key, state, co)
        end
    end
end

---A wrapper to run a custom keybind as a lua coroutine.
---@param key Keybind
local function run_keybind_coroutine(key)
    msg.debug("Received custom keybind "..key.key)
    local co = coroutine.create(run_keybind_recursive)

    local state_copy = {
        directory = g.state.directory,
        directory_label = g.state.directory_label,
        list = g.state.list,                      --the list should remain unchanged once it has been saved to the global state, new directories get new tables
        selected = g.state.selected,
        selection = fb_utils.copy_table(g.state.selection),
        parser = g.state.parser,
    }
    local success, err = coroutine.resume(co, key, state_copy, co)
    if not success then
        msg.error("error running keybind:", utils.to_string(key))
        fb_utils.traceback(err, co)
    end
end

---Scans the given command table to identify if they contain any custom keybind codes.
---@param command_table KeybindCommand
---@param codes Set<string>
---@return Set<string>
local function scan_for_codes(command_table, codes)
    if type(command_table) ~= "table" then return codes end
    for _, value in pairs(command_table) do
        local type = type(value)
        if type == "table" then
            scan_for_codes(value, codes)
        elseif type == "string" then
            for code in value:gmatch(KEYBIND_CODE_PATTERN) do
                codes[code] = true
            end
        end
    end
    return codes
end

---Inserting the custom keybind into the keybind array for declaration when file-browser is opened.
---Custom keybinds with matching names will overwrite eachother.
---@param keybind Keybind
local function insert_custom_keybind(keybind)
    -- api checking for the keybinds is optional, so set to a valid version if it does not exist
    keybind.api_version = keybind.api_version or '1.0.0'
    if not addons.check_api_version(keybind, 'keybind '..keybind.name) then return end

    local command = keybind.command

    --we'll always save the keybinds as either an array of command arrays or a function
    if type(command) == "table" and type(command[1]) ~= "table" then
        keybind.command = {command}
    end

    keybind.codes = scan_for_codes(keybind.command, {})
    if not next(keybind.codes) then keybind.codes = nil end
    keybind.prev_key = top_level_keys[keybind.key]

    if keybind.condition then
        keybind.condition_codes = {}
        for code in string.gmatch(keybind.condition, KEYBIND_CODE_PATTERN) do keybind.condition_codes[code] = true end
    end

    table.insert(g.state.keybinds, {keybind.key, keybind.name, function() run_keybind_coroutine(keybind) end, keybind.flags or {}})
    top_level_keys[keybind.key] = keybind
end

---Loading the custom keybinds.
---Can either load keybinds from the config file, from addons, or from both.
local function setup_keybinds()
    --this is to make the default keybinds compatible with passthrough from custom keybinds
    for _, keybind in ipairs(g.state.keybinds) do
        top_level_keys[keybind[1]] = { key = keybind[1], name = keybind[2], command = keybind[3], flags = keybind[4] }
    end

    --this loads keybinds from addons
    for i = #g.parsers, 1, -1 do
        local parser = g.parsers[i]
        if parser.keybinds then
            for i, keybind in ipairs(parser.keybinds) do
                --if addons use the native array command format, then we need to convert them over to the custom command format
                if not keybind.key then keybind = { key = keybind[1], name = keybind[2], command = keybind[3], flags = keybind[4] }
                else keybind = fb_utils.copy_table(keybind) end

                keybind.name = g.parsers[parser].id.."/"..(keybind.name or tostring(i))
                keybind.addon = true
                insert_custom_keybind(keybind)
            end
        end
    end

    --loads custom keybinds from file-browser-keybinds.json
    if o.custom_keybinds then
        local path = mp.command_native({"expand-path", o.custom_keybinds_file}) --[[@as string]]
        local custom_keybinds, err = io.open( path )
        if not custom_keybinds then
            msg.debug(err)
            msg.verbose('could not read custom keybind file', path)
            return
        end

        local json = custom_keybinds:read("*a")
        custom_keybinds:close()

        json = utils.parse_json(json)
        if not json then return error("invalid json syntax for "..path) end

        for i, keybind in ipairs(json --[[@as KeybindList]]) do
            keybind.name = "custom/"..(keybind.name or tostring(i))
            insert_custom_keybind(keybind)
        end
    end
end

---@class keybinds
return {
    setup_keybinds = setup_keybinds,
}
