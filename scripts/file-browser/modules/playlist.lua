------------------------------------------------------------------------------------------
---------------------------------File/Playlist Opening------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = require 'modules.options'
local g = require 'modules.globals'
local fb_utils = require 'modules.utils'
local ass = require 'modules.ass'
local cursor = require 'modules.navigation.cursor'
local controls = require 'modules.controls'
local scanning = require 'modules.navigation.scanning'
local movement = require 'modules.navigation.directory-movement'

local state = g.state

---@alias LoadfileFlag 'replace'|'append-play'

---@class LoadOpts
---@field directory string
---@field flag LoadfileFlag
---@field autoload boolean
---@field items_appended number
---@field co thread
---@field concurrency number

---In mpv v0.38 a new index argument was added to the loadfile command.
---For some crazy reason this new argument is placed before the existing options
---argument, breaking any scripts that used it. This function finds the correct index
---for the options argument using the `command-list` property.
---@return integer
local function get_loadfile_options_arg_index()
    ---@type table[]
    local command_list = mp.get_property_native('command-list', {})
    for _, command in ipairs(command_list) do
        if command.name == 'loadfile' then
            for i, arg in ipairs(command.args or {} --[=[@as table[]]=]) do
                if arg.name == 'options' then
                    return i
                end
            end
        end
    end

    return 3
end

local LEGACY_LOADFILE_SYNTAX = get_loadfile_options_arg_index() == 3

---A wrapper around loadfile to handle the syntax changes introduced in mpv v0.38.
---@param file string
---@param flag string
---@param options? string|table<string,unknown>
---@return boolean
local function legacy_loadfile_wrapper(file, flag, options)
    if LEGACY_LOADFILE_SYNTAX then
        return mp.command_native({"loadfile", file, flag, options}) ~= nil
    else
        return mp.command_native({"loadfile", file, flag, -1, options}) ~= nil
    end
end

---Adds a file to the playlist and changes the flag to `append-play` in preparation for future items.
---@param file string
---@param opts LoadOpts
---@param mpv_opts? string|table<string,unknown>
local function loadfile(file, opts, mpv_opts)
    if o.substitute_backslash and not fb_utils.get_protocol(file) then
        file = string.gsub(file, "/", "\\")
    end

    if opts.flag == "replace" then msg.verbose("Playling file", file)
    else msg.verbose("Appending", file, "to the playlist") end

    if mpv_opts then
        msg.debug('Settings opts on', file, ':', utils.to_string(mpv_opts))
    end

    if not legacy_loadfile_wrapper(file, opts.flag, mpv_opts) then msg.warn(file) end
    opts.flag = "append-play"
    opts.items_appended = opts.items_appended + 1
end

---@diagnostic disable-next-line no-unknown
local concurrent_loadlist_wrapper

---@alias ConcurrentRefMap table<List|Item,{directory: string?, sublist: List?, recurse: boolean?}>

---This function recursively loads directories concurrently in separate coroutines.
---Results are saved in a tree of tables that allows asynchronous access.
---@async
---@param directory string
---@param load_opts LoadOpts
---@param prev_dirs Set<string>
---@param item_t Item
---@param refs ConcurrentRefMap
---@return boolean?
local function concurrent_loadlist_parse(directory, load_opts, prev_dirs, item_t, refs)
    if not refs[item_t] then refs[item_t] = {} end

    --prevents infinite recursion from the item.path or opts.directory fields
    if prev_dirs[directory] then return end
    prev_dirs[directory] = true

    local list, list_opts = scanning.scan_directory(directory, { source = 'loadlist' })
    if list == g.root then return end

    --if we can't parse the directory then append it and hope mpv fares better
    if list == nil then
        msg.warn("Could not parse", directory, "appending to playlist anyway")
        refs[item_t].recurse = false
        return
    end

    directory = list_opts.directory or directory

    --we must declare these before we start loading sublists otherwise the append thread will
    --need to wait until the whole list is loaded (when synchronous IO is used)
    refs[item_t].sublist = list or {}
    refs[list] = {directory = directory}

    if directory == "" then return end

    --launches new parse operations for directories, each in a different coroutine
    for _, item in ipairs(list) do
        if fb_utils.parseable_item(item) then
            fb_utils.coroutine.run(concurrent_loadlist_wrapper, fb_utils.get_new_directory(item, directory), load_opts, prev_dirs, item, refs)
        end
    end
    return true
end

---A wrapper function that ensures the concurrent_loadlist_parse is run correctly.
---@async
---@param directory string
---@param opts LoadOpts
---@param prev_dirs Set<string>
---@param item Item
---@param refs ConcurrentRefMap
function concurrent_loadlist_wrapper(directory, opts, prev_dirs, item, refs)
    --ensures that only a set number of concurrent parses are operating at any one time.
    --the mpv event queue is seemingly limited to 1000 items, but only async mpv actions like
    --command_native_async should use that, events like mp.add_timeout (which coroutine.sleep() uses) should
    --be handled enturely on the Lua side with a table, which has a significantly larger maximum size.
    while (opts.concurrency > o.max_concurrency) do
        fb_utils.coroutine.sleep(0.1)
    end
    opts.concurrency = opts.concurrency + 1

    local success = concurrent_loadlist_parse(directory, opts, prev_dirs, item, refs)
    opts.concurrency = opts.concurrency - 1
    if not success then refs[item].sublist = {} end
    if coroutine.status(opts.co) == "suspended" then fb_utils.coroutine.resume_err(opts.co) end
end

---Recursively appends items to the playlist, acts as a consumer to the previous functions producer;
---If the next directory has not been parsed this function will yield until the parse has completed.
---@async
---@param list List
---@param load_opts LoadOpts
---@param refs ConcurrentRefMap
local function concurrent_loadlist_append(list, load_opts, refs)
    local directory = refs[list].directory

    for _, item in ipairs(list) do
        if not g.sub_extensions[ fb_utils.get_extension(item.name, "") ]
        and not g.audio_extensions[ fb_utils.get_extension(item.name, "") ]
        then
            while fb_utils.parseable_item(item) and (not refs[item] or not refs[item].sublist) do
                coroutine.yield()
            end

            if fb_utils.parseable_item(item) and refs[item] ~= false then
                concurrent_loadlist_append(refs[item].sublist, load_opts, refs)
            else
                loadfile(fb_utils.get_full_path(item, directory), load_opts, item.mpv_options)
            end
        end
    end
end

---Recursive function to load directories serially.
---Returns true if any items were appended to the playlist.
---@async
---@param directory string
---@param load_opts LoadOpts
---@param prev_dirs Set<string>
---@return true|nil
local function custom_loadlist_recursive(directory, load_opts, prev_dirs)
    --prevents infinite recursion from the item.path or opts.directory fields
    if prev_dirs[directory] then return end
    prev_dirs[directory] = true

    local list, opts = scanning.scan_directory(directory, { source = "loadlist" })
    if list == g.root then return end

    --if we can't parse the directory then append it and hope mpv fares better
    if list == nil then
        msg.warn("Could not parse", directory, "appending to playlist anyway")
        loadfile(directory, load_opts)
        return true
    end

    directory = opts.directory or directory
    if directory == "" then return end

    for _, item in ipairs(list) do
        if not g.sub_extensions[ fb_utils.get_extension(item.name, "") ]
        and not g.audio_extensions[ fb_utils.get_extension(item.name, "") ]
        then
            if fb_utils.parseable_item(item) then
                custom_loadlist_recursive( fb_utils.get_new_directory(item, directory) , load_opts, prev_dirs)
            else
                local path = fb_utils.get_full_path(item, directory)
                loadfile(path, load_opts, item.mpv_options)
            end
        end
    end
end


---A wrapper for the custom_loadlist_recursive function.
---@async
---@param item Item
---@param opts LoadOpts
local function loadlist(item, opts)
    local dir = fb_utils.get_full_path(item, opts.directory)
    local num_items = opts.items_appended

    if o.concurrent_recursion then
        item = fb_utils.copy_table(item)
        opts.co = fb_utils.coroutine.assert()
        opts.concurrency = 0

        ---@type List
        local v_list = {item}
        ---@type ConcurrentRefMap
        local refs = setmetatable({[v_list] = {directory = opts.directory}}, {__mode = 'k'})

        --we need the current coroutine to suspend before we run the first parse operation, so
        --we schedule the coroutine to run on the mpv event queue
        fb_utils.coroutine.queue(concurrent_loadlist_wrapper, dir, opts, {}, item, refs)
        concurrent_loadlist_append(v_list, opts, refs)
    else
        custom_loadlist_recursive(dir, opts, {})
    end

    if opts.items_appended == num_items then msg.warn(dir, "contained no valid files") end
end

---Load playlist entries before and after the currently playing file.
---@param path string
---@param opts LoadOpts
local function autoload_dir(path, opts)
    if o.autoload_save_current and path == g.current_file.path then
        mp.commandv("write-watch-later-config") end

    --loads the currently selected file, clearing the playlist in the process
    loadfile(path, opts)

    local pos = 1
    local file_count = 0
    for _,item in ipairs(state.list) do
        if item.type == "file" 
        and not g.sub_extensions[ fb_utils.get_extension(item.name, "") ]
        and not g.audio_extensions[ fb_utils.get_extension(item.name, "") ]
        then
            local p = fb_utils.get_full_path(item)

            if p == path then pos = file_count
            else loadfile( p, opts, item.mpv_options) end

            file_count = file_count + 1
        end
    end
    mp.commandv("playlist-move", 0, pos+1)
end

---Runs the loadfile or loadlist command.
---@async
---@param item Item
---@param opts LoadOpts
---@return nil
local function open_item(item, opts)
    if fb_utils.parseable_item(item) then
        return loadlist(item, opts)
    end

    local path = fb_utils.get_full_path(item, opts.directory)
    if g.sub_extensions[ fb_utils.get_extension(item.name, "") ] then
        mp.commandv("sub-add", path, opts.flag == "replace" and "select" or "auto")
    elseif g.audio_extensions[ fb_utils.get_extension(item.name, "") ] then
        mp.commandv("audio-add", path, opts.flag == "replace" and "select" or "auto")
    else
        if opts.autoload then autoload_dir(path, opts)
        else loadfile(path, opts, item.mpv_options) end
    end
end

---Handles the open options as a coroutine.
---Once loadfile has been run we can no-longer guarantee synchronous execution - the state values may change
---therefore, we must ensure that any state values that could be used after a loadfile call are saved beforehand.
---@async
---@param opts LoadOpts
---@return nil
local function open_file_coroutine(opts)
    if not state.list[state.selected] then return end
    if opts.flag == 'replace' then controls.close() end

    --we want to set the idle option to yes to ensure that if the first item
    --fails to load then the player has a chance to attempt to load further items (for async append operations)
    local idle = mp.get_property("idle", "once")
    mp.set_property("idle", "yes")

    --handles multi-selection behaviour
    if next(state.selection) then
        local selection = fb_utils.sort_keys(state.selection)
        --reset the selection after
        state.selection = {}

        cursor.disable_select_mode()
        ass.update_ass()

        --the currently selected file will be loaded according to the flag
        --the flag variable will be switched to append once a file is loaded
        for i=1, #selection do
            open_item(selection[i], opts)
        end

    else
        local item = state.list[state.selected]
        if opts.flag == "replace" then movement.down_dir() end
        open_item(item, opts)
    end

    if mp.get_property("idle") == "yes" then mp.set_property("idle", idle) end
end

--opens the selelected file(s)
local function open_file(flag, autoload)
    ---@type LoadOpts
    local opts = {
        flag = flag,
        autoload = (autoload ~= o.autoload and flag == "replace"),
        directory = state.directory,
        items_appended = 0,
        concurrency = 0,
        co = coroutine.create(open_file_coroutine)
    }
    fb_utils.coroutine.resume_err(opts.co, opts)
end

---@class playlist
return {
    add_files = open_file,
}
