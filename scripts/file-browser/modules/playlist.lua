------------------------------------------------------------------------------------------
---------------------------------File/Playlist Opening------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

local mp = require 'mp'
local msg = require 'mp.msg'

local o = require 'modules.options'
local g = require 'modules.globals'
local API = require 'modules.utils'
local ass = require 'modules.ass'
local cursor = require 'modules.navigation.cursor'
local controls = require 'modules.controls'
local scanning = require 'modules.navigation.scanning'
local movement = require 'modules.navigation.directory-movement'

local state = g.state

--adds a file to the playlist and changes the flag to `append-play` in preparation
--for future items
local function loadfile(file, opts)
    if o.substitute_backslash and not API.get_protocol(file) then
        file = file:gsub("/", "\\")
    end

    if opts.flag == "replace" then msg.verbose("Playling file", file)
    else msg.verbose("Appending", file, "to the playlist") end

    if not mp.commandv("loadfile", file, opts.flag) then msg.warn(file) end
    opts.flag = "append-play"
    opts.items_appended = opts.items_appended + 1
end

--this function recursively loads directories concurrently in separate coroutines
--results are saved in a tree of tables that allows asynchronous access
local function concurrent_loadlist_parse(directory, load_opts, prev_dirs, item_t)
    --prevents infinite recursion from the item.path or opts.directory fields
    if prev_dirs[directory] then return end
    prev_dirs[directory] = true

    local list, list_opts = scanning.scan_directory(directory, { source = "loadlist" })
    if list == g.root then return end

    --if we can't parse the directory then append it and hope mpv fares better
    if list == nil then
        msg.warn("Could not parse", directory, "appending to playlist anyway")
        item_t.type = "file"
        return
    end

    directory = list_opts.directory or directory
    if directory == "" then return end

    --we must declare these before we start loading sublists otherwise the append thread will
    --need to wait until the whole list is loaded (when synchronous IO is used)
    item_t._sublist = list or {}
    list._directory = directory

    --launches new parse operations for directories, each in a different coroutine
    for _, item in ipairs(list) do
        if API.parseable_item(item) then
            API.coroutine.run(concurrent_loadlist_wrapper, API.get_new_directory(item, directory), load_opts, prev_dirs, item)
        end
    end
    return true
end

--a wrapper function that ensures the concurrent_loadlist_parse is run correctly
function concurrent_loadlist_wrapper(directory, opts, prev_dirs, item)
    --ensures that only a set number of concurrent parses are operating at any one time.
    --the mpv event queue is seemingly limited to 1000 items, but only async mpv actions like
    --command_native_async should use that, events like mp.add_timeout (which coroutine.sleep() uses) should
    --be handled enturely on the Lua side with a table, which has a significantly larger maximum size.
    while (opts.concurrency > o.max_concurrency) do
        API.coroutine.sleep(0.1)
    end
    opts.concurrency = opts.concurrency + 1

    local success = concurrent_loadlist_parse(directory, opts, prev_dirs, item)
    opts.concurrency = opts.concurrency - 1
    if not success then item._sublist = {} end
    if coroutine.status(opts.co) == "suspended" then API.coroutine.resume_err(opts.co) end
end

--recursively appends items to the playlist, acts as a consumer to the previous functions producer;
--if the next directory has not been parsed this function will yield until the parse has completed
local function concurrent_loadlist_append(list, load_opts)
    local directory = list._directory

    for _, item in ipairs(list) do
        if not g.sub_extensions[ API.get_extension(item.name, "") ]
        and not g.audio_extensions[ API.get_extension(item.name, "") ]
        then
            while (not item._sublist and API.parseable_item(item)) do
                coroutine.yield()
            end

            if API.parseable_item(item) then
                concurrent_loadlist_append(item._sublist, load_opts)
            else
                loadfile(API.get_full_path(item, directory), load_opts)
            end
        end
    end
end

--recursive function to load directories using the script custom parsers
--returns true if any items were appended to the playlist
local function custom_loadlist_recursive(directory, load_opts, prev_dirs)
    --prevents infinite recursion from the item.path or opts.directory fields
    if prev_dirs[directory] then return end
    prev_dirs[directory] = true

    local list, opts = scanning.scan_directory(directory, { source = "loadlist" })
    if list == g.root then return end

    --if we can't parse the directory then append it and hope mpv fares better
    if list == nil then
        msg.warn("Could not parse", directory, "appending to playlist anyway")
        loadfile(directory, load_opts.flag)
        return true
    end

    directory = opts.directory or directory
    if directory == "" then return end

    for _, item in ipairs(list) do
        if not g.sub_extensions[ API.get_extension(item.name, "") ]
        and not g.audio_extensions[ API.get_extension(item.name, "") ]
        then
            if API.parseable_item(item) then
                custom_loadlist_recursive( API.get_new_directory(item, directory) , load_opts, prev_dirs)
            else
                local path = API.get_full_path(item, directory)
                loadfile(path, load_opts)
            end
        end
    end
end


--a wrapper for the custom_loadlist_recursive function
local function loadlist(item, opts)
    local dir = API.get_full_path(item, opts.directory)
    local num_items = opts.items_appended

    if o.concurrent_recursion then
        item = API.copy_table(item)
        opts.co = API.coroutine.assert()
        opts.concurrency = 0

        --we need the current coroutine to suspend before we run the first parse operation, so
        --we schedule the coroutine to run on the mpv event queue
        mp.add_timeout(0, function()
            API.coroutine.run(concurrent_loadlist_wrapper, dir, opts, {}, item)
        end)
        concurrent_loadlist_append({item, _directory = opts.directory}, opts)
    else
        custom_loadlist_recursive(dir, opts, {})
    end

    if opts.items_appended == num_items then msg.warn(dir, "contained no valid files") end
end

--load playlist entries before and after the currently playing file
local function autoload_dir(path, opts)
    if o.autoload_save_current and path == g.current_file.path then
        mp.commandv("write-watch-later-config") end

    --loads the currently selected file, clearing the playlist in the process
    loadfile(path, opts)

    local pos = 1
    local file_count = 0
    for _,item in ipairs(state.list) do
        if item.type == "file" 
        and not g.sub_extensions[ API.get_extension(item.name, "") ]
        and not g.audio_extensions[ API.get_extension(item.name, "") ]
        then
            local p = API.get_full_path(item)

            if p == path then pos = file_count
            else loadfile( p, opts) end

            file_count = file_count + 1
        end
    end
    mp.commandv("playlist-move", 0, pos+1)
end

--runs the loadfile or loadlist command
local function open_item(item, opts)
    if API.parseable_item(item) then
        return loadlist(item, opts)
    end

    local path = API.get_full_path(item, opts.directory)
    if g.sub_extensions[ API.get_extension(item.name, "") ] then
        mp.commandv("sub-add", path, opts.flag == "replace" and "select" or "auto")
    elseif g.audio_extensions[ API.get_extension(item.name, "") ] then
        mp.commandv("audio-add", path, opts.flag == "replace" and "select" or "auto")
    else
        if opts.autoload then autoload_dir(path, opts)
        else loadfile(path, opts) end
    end
end

--handles the open options as a coroutine
--once loadfile has been run we can no-longer guarantee synchronous execution - the state values may change
--therefore, we must ensure that any state values that could be used after a loadfile call are saved beforehand
local function open_file_coroutine(opts)
    if not state.list[state.selected] then return end
    if opts.flag == 'replace' then controls.close() end

    --we want to set the idle option to yes to ensure that if the first item
    --fails to load then the player has a chance to attempt to load further items (for async append operations)
    local idle = mp.get_property("idle", "once")
    mp.set_property("idle", "yes")

    --handles multi-selection behaviour
    if next(state.selection) then
        local selection = API.sort_keys(state.selection)
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
    API.coroutine.run(open_file_coroutine, {
        flag = flag,
        autoload = (autoload ~= o.autoload and flag == "replace"),
        directory = state.directory,
        items_appended = 0
    })
end

return {
    add_files = open_file,
}
