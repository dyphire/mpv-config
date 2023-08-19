--lite version of the code written by sorayuki
--only keep the function to record the histroy and recover it

local mp = require 'mp'
local utils = require 'mp.utils'
local options = require 'mp.options'
local msg = require 'mp.msg' -- this is for debugging

local o = {
    enabled = true,
    save_period = 30,
    -- Set '/:dir%mpvconf%/historybookmarks' to use mpv config directory
    -- OR change to '/:dir%script%/historybookmarks' for placing it in the same directory of script
    -- OR change to '~~/historybookmarks' for sub path of mpv portable_config directory
    -- OR write any variable using '/:var', such as: '/:var%APPDATA%/mpv/historybookmarks' or '/:var%HOME%/mpv/historybookmarks'
    -- OR specify the absolute path
    history_dir = "/:dir%mpvconf%/historybookmarks",
    -- specifies the extension of the history-bookmark file
    bookmark_ext = ".mpv.history",
    -- use hash to bookmark_name
    hash = true,
    -- set false to get playlist from directory
    use_playlist = false,
    -- specifies a whitelist of files to find in a directory
    whitelist = "3gp,amr,amv,asf,avi,avi,bdmv,f4v,flv,m2ts,m4v,mkv,mov,mp4,mpeg,mpg,ogv,rm,rmvb,ts,vob,webm,wmv",
    -- excluded directories for shared, #windows: ["X:", "Z:", "F:\\Download\\", "Download"]
    excluded_dir = [[
        []
        ]],
    included_dir = [[
    []
    ]]
}
options.read_options(o)

o.excluded_dir = utils.parse_json(o.excluded_dir)
o.included_dir = utils.parse_json(o.included_dir)

local cwd_root = utils.getcwd()

-- `pl` stands for playlist
local path = nil
local dir = nil
local fname = nil
local pl_count = 0
local pl_dir = nil
local pl_name = nil
local pl_path = nil
local pl_list = {}
local pl_idx = 1
local current_idx = 1
local bookmark_path = nil

local wait_msg
local on_key = false

if o.history_dir:find('^/:dir%%mpvconf%%') then
    o.history_dir = o.history_dir:gsub('/:dir%%mpvconf%%', mp.find_config_file('.'))
elseif o.history_dir:find('^/:dir%%script%%') then
    o.history_dir = o.history_dir:gsub('/:dir%%script%%', mp.find_config_file('scripts'))
elseif o.history_dir:find('/:var%%(.*)%%') then
    local os_variable = o.history_dir:match('/:var%%(.*)%%')
    o.history_dir = o.history_dir:gsub('/:var%%(.*)%%', os.getenv(os_variable))
elseif o.history_dir:find('^~') then
    o.history_dir = mp.command_native({ "expand-path", o.history_dir }) -- Expands both ~ and ~~
end

--create o.history_dir if it doesn't exist
if o.history_dir ~= '' then
    local meta, meta_error = utils.file_info(o.history_dir)
    if not meta or not meta.is_dir then
        local is_windows = package.config:sub(1, 1) == "\\"
        local windows_args = { 'powershell', '-NoProfile', '-Command', 'mkdir', string.format("\"%s\"", o.history_dir) }
        local unix_args = { 'mkdir', '-p', o.history_dir }
        local args = is_windows and windows_args or unix_args
        local res = mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = args })
        if res.status ~= 0 then
            msg.error("Failed to create history_dir save directory " .. o.history_dir ..
            ". Error: " .. (res.error or "unknown"))
            return
        end
    end
end

local function split(input)
    local ret = {}
    for str in string.gmatch(input, "([^,]+)") do
        ret[#ret + 1] = str
    end
    return ret
end

ext_whitelist = split(o.whitelist)

local function exclude(extension)
    if #ext_whitelist > 0 then
        for _, ext in pairs(ext_whitelist) do
            if extension == ext then
                return true
            end
        end
    else
        return
    end
end

local function is_protocol(path)
    return type(path) == 'string' and (path:find('^%a[%w.+-]-://') ~= nil or path:find('^%a[%w.+-]-:%?') ~= nil)
end

local function need_ignore(tab, val)
    for index, element in ipairs(tab) do
        if string.find(val, element) then
            return true
        end
    end
    return false
end

local function tablelength(tab, val)
    local count = 0
    for index, element in ipairs(tab) do
        count = count + 1
    end
    return count
end

local function prompt_msg(msg, ms)
    mp.commandv("show-text", msg, ms)
end

function refresh_globals()
    path = mp.get_property("path")
    fname = mp.get_property("filename")
    pl_count = mp.get_property_number('playlist-count', 0)
    if path and not is_protocol(path) then
        path = utils.join_path(mp.get_property('working-directory'), path):gsub("/", "\\")
        dir = utils.split_path(path)
    else
        dir = nil
    end
end

-- returns md5 hash of the full path of the current media file
local function hash(path)
    if path == nil then
        msg.debug("something is wrong with the path, can't get full_path, can't hash it")
        return
    end

    msg.debug("hashing:", path)

    local cmd = {
        name = 'subprocess',
        capture_stdout = true,
        playback_only = false,
    }
    local args = nil

    local is_unix = package.config:sub(1,1) == "/"
    if is_unix then
        local md5 = command_exists("md5sum") or command_exists("md5") or command_exists("openssl", "md5 | cut -d ' ' -f 2")
        if md5 == nil then
            msg.warn("no md5 command found, can't generate hash")
            return
        end
        md5 = table.concat(md5, " ")
        cmd["stdin_data"] = path
        args = {"sh", "-c", md5 .. " | cut -d ' ' -f 1 | tr '[:lower:]' '[:upper:]'" }
    else --windows
        -- https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash?view=powershell-7.3
        local hash_command ="$s = [System.IO.MemoryStream]::new(); $w = [System.IO.StreamWriter]::new($s); $w.write(\"" .. path .. "\"); $w.Flush(); $s.Position = 0; Get-FileHash -Algorithm MD5 -InputStream $s | Select-Object -ExpandProperty Hash"
        args = {"powershell", "-NoProfile", "-Command", hash_command}
    end
    cmd["args"] = args
    msg.debug("hash cmd:", utils.to_string(cmd))
    local process = mp.command_native(cmd)

    if process.status == 0 then
        local hash = process.stdout:gsub("%s+", "")
        msg.debug("hash:", hash)
        return hash
    else
        msg.warn("hash function failed")
        return
    end
end

local function get_bookmark_path(dir)
    local fpath = string.sub(dir, 1, -2)
    local _, name = utils.split_path(fpath)
    if o.hash then
        history_name = hash(dir)
        if history_name == nil then
            msg.warn("hash function failed, fallback to dirname")
            history_name = name
        end
    else
        history_name = name
    end
    local bookmark_name = history_name .. o.bookmark_ext
    bookmark_path = utils.join_path(o.history_dir, bookmark_name)
end

local function is_bookmark_exist(bookmark_path)
    local file = io.open(bookmark_path, "r")
    if file == nil then
        msg.info('No bookmark file is found.')
        return false
    end
    return true
end

-- get the content of the bookmark
-- Arg: bookmark_file (path)
-- Return: nil / content of the bookmark
local function get_record(bookmark_path)
    local file = io.open(bookmark_path, 'r')
    local record = file:read()
    if record == nil then
        msg.info('No history record is found in the bookmark file.')
        return nil
    end
    msg.info('last play: ' .. record)
    file:close()
    return record
end

local function alphanumsort(filenames)
    local function padnum(d)
        local dec, n = string.match(d, "(%.?)0*(.+)")
        return #dec > 0 and ("%.12f"):format(d) or ("%03d%s"):format(#n, n)
    end

    local tuples = {}
    for i, f in ipairs(filenames) do
        tuples[i] = { f:lower():gsub("%.?%d+", padnum), f }
    end
    table.sort(tuples, function(a, b)
        return a[1] == b[1] and #b[2] < #a[2] or a[1] < b[1]
    end)
    for i, tuple in ipairs(tuples) do filenames[i] = tuple[2] end
    return filenames
end

local function create_playlist(dir)
    local pl_list = {}
    local file_list = {}
    local file_list = utils.readdir(dir, 'files')
    for i = 1, #file_list do
        local file = file_list[i]
        local ext = file:match('%.([^./]+)$')
        if ext and exclude(ext:lower()) then
            table.insert(pl_list, file)
        end
    end
    alphanumsort(pl_list)
    return pl_list
end

local function get_playlist()
    local pl_list = {}
    local playlist = mp.get_property_native("playlist")
    for i = 0, #playlist - 1 do
        local filename = mp.get_property("playlist/" .. i .. "/filename")
        local _, file = utils.split_path(filename)
        table.insert(pl_list, file)
    end
    return pl_list
end

-- get the index of the wanted file playlist
-- if there is no playlist, return nil
local function get_playlist_idx(dst_file)
    if (dst_file == nil) then
        return nil
    end

    local idx = nil
    for i = 1, #pl_list do
        if (dst_file == pl_list[i]) then
            idx = i
            return idx
        end
    end
    return idx
end

local function unbind_key()
    msg.info('Unbinding keys')
    mp.remove_key_binding('resume_yes')
    mp.remove_key_binding('resume_not')
end

local function jump_resume()
    mp.unregister_event(jump_resume)
    prompt_msg("resume successfully", 1500)
end

local function key_jump()
    unbind_key()
    on_key = true
    wait_jump_timer:kill()
    current_idx = pl_idx
    mp.register_event('file-loaded', jump_resume)
    msg.info('Jumping to ' .. pl_path)
    mp.commandv('loadfile', pl_path)
end

local function bind_key()
    mp.register_script_message('resume_yes', key_jump)
    mp.register_script_message('resume_not', function()
        unbind_key()
        on_key = true
        wait_jump_timer:kill()
    end)
end

-- creat a .history file
local function record_history()
    refresh_globals()
    if not path or is_protocol(path) then return end
    get_bookmark_path(dir)
    if not (fname == nil) then
        local file = io.open(bookmark_path, "w")
        file:write(fname .. "\n")
        file:close()
    end
end

local timeout = 15
local function wait4jumping()
    timeout = timeout - 1
    if (timeout >= 0) then
        if (timeout < 1) then
            wait_jump_timer:kill()
            unbind_key()
        end
        local msg = ""
        if timeout < 10 then
            msg = "0"
        end
        if not on_key then
            msg = wait_msg .. " -- continue? " .. timeout .. " [EN/IG]"
            prompt_msg(msg, 1000)
        end
    end
end

-- record the file name when video is paused
-- and stop the timer
local function pause(name, paused)
    if paused then
        timer4saving_history:stop()
        record_history()
    else
        timer4saving_history:resume()
    end
end

-- main function of the file
local function record()
    if not o.enabled then return end
    refresh_globals()
    if pl_count and pl_count < 1 then return end
    if not path or is_protocol(path) then return end
    if not dir or not fname then return end
    get_bookmark_path(dir)
    included_dir_count = tablelength(o.included_dir)
    if included_dir_count > 0 then
        if not need_ignore(o.included_dir, dir) then return end
    end
    if need_ignore(o.excluded_dir, dir) then return end

    msg.info('folder -- ' .. dir)
    msg.info('playing -- ' .. fname)
    msg.info('bookmark path -- ' .. bookmark_path)

    if (not is_bookmark_exist(bookmark_path)) then
        pl_name = nil
    else
        pl_name = get_record(bookmark_path)
        pl_path = utils.join_path(dir, pl_name)
    end

    if o.use_playlist or pl_count > 1 then
        pl_list = get_playlist()
    else
        pl_list = create_playlist(dir)
    end

    pl_idx = get_playlist_idx(pl_name)
    if (pl_idx == nil) then
        msg.info('Playlist not found. Creating a new one...')
    else
        msg.info('playlist index --' .. pl_idx)
    end

    current_idx = get_playlist_idx(fname)
    if current_idx then msg.info('current index -- ' .. current_idx) end

    if current_idx and (pl_idx == nil) then
        pl_idx = current_idx
        pl_name = fname
        pl_path = path
    elseif current_idx and (pl_idx ~= current_idx) then
        wait_msg = pl_idx
        msg.info('Last watched episode -- ' .. wait_msg)
        wait_jump_timer = mp.add_periodic_timer(1, wait4jumping)
        bind_key()
    end
    timer4saving_history = mp.add_periodic_timer(o.save_period, record_history)
    mp.observe_property("pause", "bool", pause)
end

mp.register_event('file-loaded', function()
    local path = mp.get_property("path")
    if not is_protocol(path) then
        path = utils.join_path(mp.get_property('working-directory'), path):gsub("/", "\\")
        directory = utils.split_path(path)
    else
        directory = nil
    end
    if directory ~= nil and directory ~= dir then
        mp.add_timeout(0.5, record)
    end
end)

mp.add_hook("on_unload", 50, function()
    mp.unobserve_property(pause)
    record_history()
end)
