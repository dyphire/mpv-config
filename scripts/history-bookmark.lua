--lite version of the code written by sorayuki
--only keep the function to record the histroy and recover it

local mp = require 'mp'
local utils = require 'mp.utils'
local options = require 'mp.options'
local msg = require 'mp.msg' -- this is for debugging

local o = {
    enabled = true,
    -- eng=English, chs=Chinese Simplified
    language = 'eng',
    timeout = 15,
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
    use_playlist = true,
    -- specifies a whitelist of files to find in a directory
    whitelist = "3gp,amr,amv,asf,avi,avi,bdmv,f4v,flv,m2ts,m4v,mkv,mov,mp4,mpeg,mpg,ogv,rm,rmvb,ts,vob,webm,wmv",
    -- excluded directories for shared, #windows: ["X:", "Z:", "F:/Download/", "Download"]
    excluded_dir = [[
        []
        ]],
    included_dir = [[
    []
    ]]
}
options.read_options(o, _, function() end)

o.excluded_dir = utils.parse_json(o.excluded_dir)
o.included_dir = utils.parse_json(o.included_dir)

local file_loaded = false

local locals = {
    ['eng'] = {
        msg1 = 'Resume successfully',
        msg2 = 'Resume the last played file in current directory',
        msg3 = 'Press 1 to confirm, 0 to cancel',
    },
    ['chs'] = {
        msg1 = '成功恢复上次播放',
        msg2 = '是否恢复当前目录的上次播放文件',
        msg3 = '按1确认，按0取消',
    }
}

-- apply lang opts
local texts = locals[o.language]

-- `pl` stands for playlist
local path = nil
local dir = nil
local fname = nil
local pl_count = 0
local pl_name = nil
local pl_path = nil
local pl_list = {}
local pl_idx = 1
local current_idx = 1
local bookmark_path = nil
local history_dir = nil
local normalize_path = nil

local wait_msg
local on_key = false

if o.history_dir:find('^/:dir%%mpvconf%%') then
    history_dir = o.history_dir:gsub('/:dir%%mpvconf%%', mp.find_config_file('.'))
elseif o.history_dir:find('^/:dir%%script%%') then
    history_dir = o.history_dir:gsub('/:dir%%script%%', mp.find_config_file('scripts'))
elseif o.history_dir:find('/:var%%(.*)%%') then
    local os_variable = o.history_dir:match('/:var%%(.*)%%')
    history_dir = o.history_dir:gsub('/:var%%(.*)%%', os.getenv(os_variable))
else
    history_dir = mp.command_native({ "expand-path", o.history_dir }) -- Expands both ~ and ~~
end

local is_windows = package.config:sub(1, 1) == "\\" -- detect path separator, detect path separator, windows uses backslashes
--create history_dir if it doesn't exist
if history_dir ~= '' then
    local meta = utils.file_info(history_dir)
    if not meta or not meta.is_dir then
        local windows_args = { 'powershell', '-NoProfile', '-Command', 'mkdir', string.format("\"%s\"", history_dir) }
        local unix_args = { 'mkdir', '-p', history_dir }
        local args = is_windows and windows_args or unix_args
        local res = mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = args })
        if res.status ~= 0 then
            msg.error("Failed to create history_dir save directory " .. history_dir ..
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

local ext_whitelist = split(o.whitelist)

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
    for _, element in pairs(tab) do
        if string.find(val, element) then
            return true
        end
    end
    return false
end

local function tablelength(tab)
    local count = 0
    for _, _ in pairs(tab) do
        count = count + 1
    end
    return count
end

local message_overlay = mp.create_osd_overlay('ass-events')
local message_timer = mp.add_timeout(1, function ()
    message_overlay:remove()
end, true)

function show_message(text, time)
    message_timer:kill()
    message_timer.timeout = time or 1
    message_overlay.data = text
    message_overlay:update()
    message_timer:resume()
end

local function normalize(path)
    if normalize_path ~= nil then
        if normalize_path then
            path = mp.command_native({"normalize-path", path})
        else
            local directory = mp.get_property("working-directory", "")
            path = utils.join_path(directory, path:gsub('^%.[\\/]',''))
            if is_windows then path = path:gsub("\\", "/") end
        end
        return path
    end

    normalize_path = false

    local commands = mp.get_property_native("command-list", {})
    for _, command in ipairs(commands) do
        if command.name == "normalize-path" then
            normalize_path = true
            break
        end
    end
    return normalize(path)
end

function refresh_globals()
    path = mp.get_property("path")
    fname = mp.get_property("filename")
    pl_count = mp.get_property_number('playlist-count', 0)
    if path and not is_protocol(path) then
        path = normalize(path)
        dir = utils.split_path(path)
    else
        dir = nil
    end
end

-- for unix use only
-- returns a table of command path and varargs, or nil if command was not found
local function command_exists(command, ...)
    msg.debug("looking for command:", command)
    -- msg.debug("args:", )
    local process = mp.command_native({
        name = "subprocess",
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
        args = {"sh", "-c", "command -v -- " .. command}
    })

    if process.status == 0 then
        local command_path = process.stdout:gsub("\n", "")
        msg.debug("command found:", command_path)
        return {command_path, ...}
    else
        msg.debug("command not found:", command)
        return nil
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
        local hash_command = [[
            $s = [System.IO.MemoryStream]::new();
            $w = [System.IO.StreamWriter]::new($s);
            $w.write(']] .. path .. [[');
            $w.Flush();
            $s.Position = 0;
            Get-FileHash -Algorithm MD5 -InputStream $s | Select-Object -ExpandProperty Hash
        ]]

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
    local history_name = nil
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
    bookmark_path = utils.join_path(history_dir, bookmark_name)
    if is_windows then bookmark_path = bookmark_path:gsub("\\", "/") end
end

local function file_exist(path)
    local meta = utils.file_info(path)
    if not meta or not meta.is_file then
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
        msg.verbose('No history record is found in the bookmark file.')
        return nil
    end
    msg.verbose('last play: ' .. record)
    file:close()
    return record
end

----- winapi start -----
-- in windows system, we can use the sorting function provided by the win32 API
-- see https://learn.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-strcmplogicalw
-- this function was taken from https://github.com/mpvnet-player/mpv.net/issues/575#issuecomment-1817413401
local winapi = {}
local is_windows = mp.get_property_native("platform") == "windows"

if is_windows then
    -- is_ffi_loaded is false usually means the mpv builds without luajit
    local is_ffi_loaded, ffi = pcall(require, "ffi")

    if is_ffi_loaded then
        winapi = {
            ffi = ffi,
            C = ffi.C,
            CP_UTF8 = 65001,
            shlwapi = ffi.load("shlwapi"),
        }

        -- ffi code from https://github.com/po5/thumbfast, Mozilla Public License Version 2.0
        ffi.cdef[[
            int __stdcall MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags, const char *lpMultiByteStr,
            int cbMultiByte, wchar_t *lpWideCharStr, int cchWideChar);
            int __stdcall StrCmpLogicalW(wchar_t *psz1, wchar_t *psz2);
        ]]

        winapi.utf8_to_wide = function(utf8_str)
            if utf8_str then
                local utf16_len = winapi.C.MultiByteToWideChar(winapi.CP_UTF8, 0, utf8_str, -1, nil, 0)

                if utf16_len > 0 then
                    local utf16_str = winapi.ffi.new("wchar_t[?]", utf16_len)

                    if winapi.C.MultiByteToWideChar(winapi.CP_UTF8, 0, utf8_str, -1, utf16_str, utf16_len) > 0 then
                        return utf16_str
                    end
                end
            end

            return ""
        end
    end
end
----- winapi end -----

local function alphanumsort_windows(filenames)
    table.sort(filenames, function(a, b)
        local a_wide = winapi.utf8_to_wide(a)
        local b_wide = winapi.utf8_to_wide(b)
        return winapi.shlwapi.StrCmpLogicalW(a_wide, b_wide) == -1
    end)

    return filenames
end

-- alphanum sorting for humans in Lua
-- http://notebook.kulchenko.com/algorithms/alphanumeric-natural-sorting-for-humans-in-lua
local function alphanumsort_lua(filenames)
    local function padnum(n, d)
        return #d > 0 and ("%03d%s%.12f"):format(#n, n, tonumber(d) / (10 ^ #d))
            or ("%03d%s"):format(#n, n)
    end

    local tuples = {}
    for i, f in ipairs(filenames) do
        tuples[i] = {f:lower():gsub("0*(%d+)%.?(%d*)", padnum), f}
    end
    table.sort(tuples, function(a, b)
        return a[1] == b[1] and #b[2] < #a[2] or a[1] < b[1]
    end)
    for i, tuple in ipairs(tuples) do filenames[i] = tuple[2] end
    return filenames
end

local function alphanumsort(filenames)
    local is_ffi_loaded = pcall(require, "ffi")
    if is_windows and is_ffi_loaded then
        alphanumsort_windows(filenames)
    else
        alphanumsort_lua(filenames)
    end
end

local function create_playlist(dir)
    local pl_list = {}
    local file_list = utils.readdir(dir, 'files')
    for i = 1, #file_list do
        local file = file_list[i]
        local ext = file:match('%.([^./]+)$')
        if ext and exclude(ext:lower()) then
            table.insert(pl_list, file)
            msg.verbose("Adding " .. file)
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
    if dst_file == nil or dst_file == " " then
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

local function jump_resume()
    mp.unregister_event(jump_resume)
    show_message(texts.msg1, 2)
end

local function unbind_key()
    msg.verbose('Unbinding keys')
    wait_jump_timer:kill()
    mp.remove_key_binding('key_jump')
    mp.remove_key_binding('key_cancel')
end

local function key_jump()
    on_key = true
    wait_jump_timer:kill()
    unbind_key()
    current_idx = pl_idx
    mp.register_event('file-loaded', jump_resume)
    msg.verbose('Jumping to ' .. pl_path)
    mp.commandv('loadfile', pl_path)
end

local function key_cancel()
    on_key = true
    wait_jump_timer:kill()
    unbind_key()
end

local function bind_key()
    mp.add_forced_key_binding('1', 'key_jump', key_jump)
    mp.add_forced_key_binding('0', 'key_cancel', key_cancel)
end

-- creat a .history file
local function record_history()
    if not o.enabled or not file_loaded then return end
    refresh_globals()
    if not path or is_protocol(path) then return end
    get_bookmark_path(dir)
    local eof = mp.get_property_bool("eof-reached")
    local percent_pos = mp.get_property_number("percent-pos", 0)
    if not eof and percent_pos < 90 then
        if fname ~= nil then
            local file = io.open(bookmark_path, "w")
            file:write(fname .. "\n")
            file:close()
        end
    else
        local file = io.open(bookmark_path, "w")
        file:write(" " .. "\n")
        file:close()
    end
end

local timeout = o.timeout
local function wait_jumping()
    timeout = timeout - 1
    if timeout > 0 then
        if not on_key then
            local msg = string.format("%s -- %s? (%s) %02d", wait_msg, texts.msg2, texts.msg3, timeout)
            show_message(msg, 1)
            bind_key()
        else
            timeout = 0
            wait_jump_timer:kill()
            unbind_key()
        end
    else
        wait_jump_timer:kill()
        unbind_key()
    end
end

-- record the file name when video is paused
-- and stop the timer
local function pause(_, paused)
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
    if not path or is_protocol(path) or not file_exist(path) then return end
    if not dir or not fname then return end
    get_bookmark_path(dir)
    included_dir_count = tablelength(o.included_dir)
    if included_dir_count > 0 then
        if not need_ignore(o.included_dir, dir) then return end
    end
    if need_ignore(o.excluded_dir, dir) then return end

    msg.verbose('folder -- ' .. dir)
    msg.verbose('playing -- ' .. fname)
    msg.verbose('bookmark path -- ' .. bookmark_path)

    if (not file_exist(bookmark_path)) then
        pl_name = nil
        return
    else
        pl_name = get_record(bookmark_path)
        if pl_name then
            pl_path = utils.join_path(dir, pl_name)
        else
            pl_name = fname
            pl_path = path
        end
    end

    if o.use_playlist or pl_count > 1 then
        pl_list = get_playlist()
    else
        pl_list = create_playlist(dir)
    end

    pl_idx = get_playlist_idx(pl_name)
    if (pl_idx == nil) then
        msg.verbose('Playlist not found. Creating a new one...')
    else
        msg.verbose('playlist index --' .. pl_idx)
    end

    current_idx = get_playlist_idx(fname)
    if current_idx then msg.verbose('current index -- ' .. current_idx) end

    if current_idx and (pl_idx == nil) then
        pl_idx = current_idx
        pl_name = fname
        pl_path = path
    elseif current_idx and (pl_idx ~= current_idx) then
        wait_msg = pl_idx
        msg.verbose('Last watched episode -- ' .. wait_msg)
        wait_jump_timer = mp.add_periodic_timer(1, wait_jumping)
    end
    timer4saving_history = mp.add_periodic_timer(o.save_period, record_history)
    mp.observe_property("pause", "bool", pause)
end

mp.register_event('file-loaded', function()
    file_loaded = true
    local path = mp.get_property("path")
    if not is_protocol(path) then
        path = normalize(path)
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
    file_loaded = false
end)
