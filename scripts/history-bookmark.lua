--lite version of the code written by sorayuki
--only keep the function to record the histroy and recover it

local mp = require 'mp'
local utils = require 'mp.utils'
local options = require 'mp.options'
local msg = require 'mp.msg'         -- this is for debugging

local M = {}

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
    -- specifies a whitelist of files to find in a directory
    whitelist="3gp,amr,amv,asf,avi,avi,bdmv,f4v,flv,m2ts,m4v,mkv,mov,mp4,mpeg,mpg,ogv,rm,rmvb,ts,vob,webm,wmv",
    -- excluded directories for shared, #windows: ["X:", "Z:", "F:\\Download\\", "Download"]
    excluded_dir = [[
        []
        ]],
    -- add above (after a comma) any protocol to disable
    special_protocols = [[
	["https?://", "^magnet:", "^rtmp:", "smb://", "bd://", "dvd://", "cdda://"]
	]],
    included_dir = [[
    []
    ]]
}
options.read_options(o)

o.excluded_dir = utils.parse_json(o.excluded_dir)
o.special_protocols = utils.parse_json(o.special_protocols)
o.included_dir = utils.parse_json(o.included_dir)

local cwd_root = utils.getcwd()

-- `pl` stands for playlist
local pl_dir
local pl_name
local pl_path
local pl_list = {}

local pl_idx = 1
local current_idx = 1

local bookmark_path

local wait_msg
local on_key = false

if o.history_dir:match('^/:dir%%mpvconf%%') then
    o.history_dir = o.history_dir:gsub('/:dir%%mpvconf%%', mp.find_config_file('.'))
elseif o.history_dir:match('^/:dir%%script%%') then
    o.history_dir = o.history_dir:gsub('/:dir%%script%%', mp.find_config_file('scripts'))
elseif o.history_dir:match('/:var%%(.*)%%') then
    local os_variable = o.history_dir:match('/:var%%(.*)%%')
    o.history_dir = o.history_dir:gsub('/:var%%(.*)%%', os.getenv(os_variable))
elseif o.history_dir:match('^~~') then
    o.history_dir = mp.command_native({ "expand-path", o.history_dir })
end

--create o.history_dir if it doesn't exist
if utils.readdir(o.history_dir) == nil then
    local is_windows = package.config:sub(1, 1) == "\\"
    local windows_args = { 'powershell', '-NoProfile', '-Command', 'mkdir', o.history_dir }
    local unix_args = { 'mkdir', '-p', o.history_dir }
    local args = is_windows and windows_args or unix_args
    local res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
    if res.status ~= 0 then
        msg.error("Failed to create history_dir save directory "..o.history_dir..". Error: "..(res.error or "unknown"))
        return
    end
end

function split(input)
    local ret = {}
    for str in string.gmatch(input, "([^,]+)") do
        ret[#ret + 1] = str
    end
    return ret
end

o.whitelist = split(o.whitelist)

local exclude
if #o.whitelist > 0 then
    exclude = function(extension)
        for _, ext in pairs(o.whitelist) do
            if extension == ext then
                return false
            end
        end
        return true
    end
else
    return
end

function should_remove(filename)
    if string.find(filename, "://") then
        return false
    end
    local extension = string.match(filename, "%.([^./]+)$")
    if not extension then
        return true
    end
    if extension and exclude(string.lower(extension)) then
        return true
    end
    return false
end

local function need_ignore(tab, val)
	for index, element in ipairs(tab) do
        if string.find(val, element) then
            return true
        end
		if (val:find(element) == 1) then
			return true
		end
	end
	return false
end

function tablelength(tab,val)
  local count = 0
  for index, element in ipairs(tab) do
      count = count + 1
    end
  return count
end

function M.prompt_msg(msg, ms)
    mp.commandv("show-text", msg, ms)
end

function M.is_bookmark_exist(bookmark_path)
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
function M.get_record(bookmark_path)
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

function alphanumsort(a, b)
  local function padnum(d)
    local dec, n = string.match(d, "(%.?)0*(.+)")
    return #dec > 0 and ("%.12f"):format(d) or ("%s%03d%s"):format(dec, #n, n)
  end
  return tostring(a):lower():gsub("%.?%d+",padnum)..("%3d"):format(#b)
       < tostring(b):lower():gsub("%.?%d+",padnum)..("%3d"):format(#a)
end

function M.create_playlist(dir)
    local file_list = utils.readdir(dir, 'files')
    table.sort(file_list, alphanumsort)
    for i = 1, #file_list do
        local file = file_list[i]
        if not should_remove(file) then
           table.insert(pl_list, file)
        end 
    end
end


-- get the index of the wanted file playlist
-- if there is no playlist, return nil
function M.get_playlist_idx(dst_file)
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


-- creat a .history file
function M.record_history()
    local name = mp.get_property('filename')
    if not(name == nil) then
        local file = io.open(bookmark_path, "w")
        file:write(name.."\n")
        file:close()
    end
end

-- record the file name when video is paused
-- and stop the timer
function M.pause(name, paused)
    if paused then
        M.timer4saving_history:stop()
        M.record_history()
    else
        M.timer4saving_history:resume()
    end
end

local timeout = 45
function M.wait4jumping()
    timeout = timeout - 1
    if (timeout >= 0) then
        if(timeout < 1) then
            M.wait_jump_timer:kill()
            M.unbind_key()
        end
        local msg = ""
        if timeout < 10 then
            msg = "0"
        end
        if not on_key then
            msg = wait_msg.." -- continue? ".. string.format("%d", timeout/2) .." [EN/IG]"
            M.prompt_msg(msg, 1000)
        end
    end
end

function M.bind_key()
    mp.register_script_message('resume_yes', M.key_jump)
    mp.register_script_message('resume_not', function()
        M.unbind_key()
        on_key = true
        M.wait_jump_timer:kill()
    end)
end

function M.unbind_key()
    msg.info('Unbinding keys')
    mp.remove_key_binding('resume_yes')
    mp.remove_key_binding('resume_not')
end

function M.key_jump()
    M.unbind_key()
    on_key = true
    M.wait_jump_timer:kill()
    current_idx = pl_idx
    mp.register_event('file-loaded', M.jump_resume)
    msg.info('Jumping to ' .. pl_path)
    mp.commandv('loadfile', pl_path)
end

function M.jump_resume()
    mp.unregister_event(M.jump_resume)
    M.prompt_msg("resume successfully", 1500)
end

-- main function of the file
function M.exe()
    mp.unregister_event(M.exe)
    local path = mp.get_property('path')
    local dir, fname = utils.split_path(path)
    local fpath = dir:gsub("\\", "/")
    local playlist_count = mp.get_property_number('playlist-count')
    fpath = string.sub(fpath, 1, -2)
    history_name = fpath:gsub("^.*%/", "")
    bookmark_name = history_name .. o.bookmark_ext
    bookmark_path = o.history_dir .. "/" .. bookmark_name

    if not o.enabled then return end
    included_dir_count = tablelength(o.included_dir)
    if included_dir_count > 0 then  
        if not need_ignore(o.included_dir, dir) then return end
    end
  
    if need_ignore(o.special_protocols, path) then return end
    if need_ignore(o.excluded_dir, dir) then return end

    if playlist_count ~= nil and playlist_count == 1 then return end

    msg.info('folder -- ' .. dir)
    msg.info('playing -- ' .. fname)
    msg.info('bookmark path -- ' .. bookmark_path)

    if(not M.is_bookmark_exist(bookmark_path)) then
        pl_name = nil
    else
        pl_name = M.get_record(bookmark_path)
        pl_path = utils.join_path(dir, pl_name)
    end

    M.create_playlist(dir)

    pl_idx = M.get_playlist_idx(pl_name)
    if (pl_idx == nil) then
        msg.info('Playlist not found. Creating a new one...')
    else
        msg.info('playlist index --' .. pl_idx)
    end

    current_idx = M.get_playlist_idx(fname)
    msg.info('current index -- ' .. current_idx)

    if (pl_idx == nil) then
        pl_idx = current_idx
        pl_name = fname
        pl_path = path
    elseif (pl_idx ~= current_idx) then
        wait_msg = pl_idx
        msg.info('Last watched episode -- ' .. wait_msg)
        M.wait_jump_timer = mp.add_periodic_timer(1, M.wait4jumping)
        M.bind_key()
    end
    M.timer4saving_history = mp.add_periodic_timer(o.save_period, M.record_history)
    mp.add_hook("on_unload", 50, M.record_history)
    mp.observe_property("pause", "bool", M.pause)
end

mp.observe_property('playlist-count', "number", function(_, counts)
    if counts > 1 then M.exe() end
end)