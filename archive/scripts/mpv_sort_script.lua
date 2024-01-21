--[[
    Copyright (C) 2018 AMM

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]] --
--[[
    mpv_sort_script.lua 0.1.0 - commit 011dd7e (branch master)
    Built on 2018-12-30 22:53:08
]] --
--[[
  Assorted helper functions, from checking falsey values to path utils
  to escaping and wrapping strings.

  Does not depend on other libs.
]] --

local assdraw = require 'mp.assdraw'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

-- Determine platform --
ON_WINDOWS = (package.config:sub(1, 1) ~= '/')

-- Some helper functions needed to parse the options --
function isempty(v) return (v == false) or (v == nil) or (v == "") or (v == 0) or (type(v) == "table" and next(v) == nil
    ) end

function divmod(a, b)
    return math.floor(a / b), a % b
end

-- Better modulo
function bmod(i, N)
    return (i % N + N) % N
end

-- Path utils
local path_utils = {
    abspath  = true,
    split    = true,
    dirname  = true,
    basename = true,

    isabs      = true,
    normcase   = true,
    splitdrive = true,
    join       = true,
    normpath   = true,
    relpath    = true,
}

-- Helpers
path_utils._split_parts = function(path, sep)
    local path_parts = {}
    for c in path:gmatch('[^' .. sep .. ']+') do table.insert(path_parts, c) end
    return path_parts
end

-- Common functions
path_utils.abspath = function(path)
    if not path_utils.isabs(path) then
        local cwd = os.getenv("PWD") or utils.getcwd()
        path = path_utils.join(cwd, path)
    end
    return path_utils.normpath(path)
end

path_utils.split = function(path)
    local drive, path = path_utils.splitdrive(path)
    -- Technically unix path could contain a \, but meh
    local first_index, last_index = path:find('^.*[/\\]')

    if last_index == nil then
        return drive .. '', path
    else
        local head = path:sub(0, last_index - 1)
        local tail = path:sub(last_index + 1)
        if head == '' then head = sep end
        return drive .. head, tail
    end
end

path_utils.dirname = function(path)
    local head, tail = path_utils.split(path)
    return head
end

path_utils.basename = function(path)
    local head, tail = path_utils.split(path)
    return tail
end

path_utils.expanduser = function(path)
    -- Expands the following from the start of the path:
    -- ~ to HOME
    -- ~~ to mpv config directory (first result of mp.find_config_file('.'))
    -- ~~desktop to Windows desktop, otherwise HOME
    -- ~~temp to Windows temp or /tmp/

    local first_index, last_index = path:find('^.-[/\\]')
    local head = path
    local tail = ''

    local sep = ''

    if last_index then
        head = path:sub(0, last_index - 1)
        tail = path:sub(last_index + 1)
        sep  = path:sub(last_index, last_index)
    end

    if head == "~~desktop" then
        head = ON_WINDOWS and path_utils.join(os.getenv('USERPROFILE'), 'Desktop') or os.getenv('HOME')
    elseif head == "~~temp" then
        head = ON_WINDOWS and os.getenv('TEMP') or (os.getenv('TMP') or '/tmp/')
    elseif head == "~~" then
        local mpv_config_dir = mp.find_config_file('.')
        if mpv_config_dir then
            head = path_utils.dirname(mpv_config_dir)
        else
            msg.warn('Could not find mpv config directory (using mp.find_config_file), using temp instead')
            head = ON_WINDOWS and os.getenv('TEMP') or (os.getenv('TMP') or '/tmp/')
        end
    elseif head == "~" then
        head = ON_WINDOWS and os.getenv('USERPROFILE') or os.getenv('HOME')
    end

    return path_utils.normpath(path_utils.join(head .. sep, tail))
end


if ON_WINDOWS then
    local sep = '\\'
    local altsep = '/'
    local curdir = '.'
    local pardir = '..'
    local colon = ':'

    local either_sep = function(c) return c == sep or c == altsep end

    path_utils.isabs = function(path)
        local prefix, path = path_utils.splitdrive(path)
        return either_sep(path:sub(1, 1))
    end

    path_utils.normcase = function(path)
        return path:gsub(altsep, sep):lower()
    end

    path_utils.splitdrive = function(path)
        if #path >= 2 then
            local norm = path:gsub(altsep, sep)
            if (norm:sub(1, 2) == (sep .. sep)) and (norm:sub(3, 3) ~= sep) then
                -- UNC path
                local index = norm:find(sep, 3)
                if not index then
                    return '', path
                end

                local index2 = norm:find(sep, index + 1)
                if index2 == index + 1 then
                    return '', path
                elseif not index2 then
                    index2 = path:len()
                end

                return path:sub(1, index2 - 1), path:sub(index2)
            elseif norm:sub(2, 2) == colon then
                return path:sub(1, 2), path:sub(3)
            end
        end
        return '', path
    end

    path_utils.join = function(path, ...)
        local paths = { ... }

        local result_drive, result_path = path_utils.splitdrive(path)

        function inner(p)
            local p_drive, p_path = path_utils.splitdrive(p)
            if either_sep(p_path:sub(1, 1)) then
                -- Path is absolute
                if p_drive ~= '' or result_drive == '' then
                    result_drive = p_drive
                end
                result_path = p_path
                return
            elseif p_drive ~= '' and p_drive ~= result_drive then
                if p_drive:lower() ~= result_drive:lower() then
                    -- Different paths, ignore first
                    result_drive = p_drive
                    result_path = p_path
                    return
                end
            end

            if result_path ~= '' and not either_sep(result_path:sub(-1)) then
                result_path = result_path .. sep
            end
            result_path = result_path .. p_path
        end

        for i, p in ipairs(paths) do inner(p) end

        -- add separator between UNC and non-absolute path
        if result_path ~= '' and not either_sep(result_path:sub(1, 1)) and
            result_drive ~= '' and result_drive:sub(-1) ~= colon then
            return result_drive .. sep .. result_path
        end
        return result_drive .. result_path
    end

    path_utils.normpath = function(path)
        if path:find('\\\\.\\', nil, true) == 1 or path:find('\\\\?\\', nil, true) == 1 then
            -- Device names and literal paths - return as-is
            return path
        end

        path = path:gsub(altsep, sep)
        local prefix, path = path_utils.splitdrive(path)

        if path:find(sep) == 1 then
            prefix = prefix .. sep
            path = path:gsub('^[\\]+', '')
        end

        local comps = path_utils._split_parts(path, sep)

        local i = 1
        while i <= #comps do
            if comps[i] == curdir then
                table.remove(comps, i)
            elseif comps[i] == pardir then
                if i > 1 and comps[i - 1] ~= pardir then
                    table.remove(comps, i)
                    table.remove(comps, i - 1)
                    i = i - 1
                elseif i == 1 and prefix:find('\\$') then
                    table.remove(comps, i)
                else
                    i = i + 1
                end
            else
                i = i + 1
            end
        end

        if prefix == '' and #comps == 0 then
            comps[1] = curdir
        end

        return prefix .. table.concat(comps, sep)
    end

    path_utils.relpath = function(path, start)
        start = start or curdir

        local start_abs = path_utils.abspath(path_utils.normpath(start))
        local path_abs = path_utils.abspath(path_utils.normpath(path))

        local start_drive, start_rest = path_utils.splitdrive(start_abs)
        local path_drive, path_rest = path_utils.splitdrive(path_abs)

        if path_utils.normcase(start_drive) ~= path_utils.normcase(path_drive) then
            -- Different drives
            return nil
        end

        local start_list = path_utils._split_parts(start_rest, sep)
        local path_list = path_utils._split_parts(path_rest, sep)

        local i = 1
        for j = 1, math.min(#start_list, #path_list) do
            if path_utils.normcase(start_list[j]) ~= path_utils.normcase(path_list[j]) then
                break
            end
            i = j + 1
        end

        local rel_list = {}
        for j = 1, (#start_list - i + 1) do rel_list[j] = pardir end
        for j = i, #path_list do table.insert(rel_list, path_list[j]) end

        if #rel_list == 0 then
            return curdir
        end

        return path_utils.join(unpack(rel_list))
    end

else
    -- LINUX
    local sep = '/'
    local curdir = '.'
    local pardir = '..'

    path_utils.isabs = function(path) return path:sub(1, 1) == '/' end
    path_utils.normcase = function(path) return path end
    path_utils.splitdrive = function(path) return '', path end

    path_utils.join = function(path, ...)
        local paths = { ... }

        for i, p in ipairs(paths) do
            if p:sub(1, 1) == sep then
                path = p
            elseif path == '' or path:sub(-1) == sep then
                path = path .. p
            else
                path = path .. sep .. p
            end
        end

        return path
    end

    path_utils.normpath = function(path)
        if path == '' then return curdir end

        local initial_slashes = (path:sub(1, 1) == sep) and 1
        if initial_slashes and path:sub(2, 2) == sep and path:sub(3, 3) ~= sep then
            initial_slashes = 2
        end

        local comps = path_utils._split_parts(path, sep)
        local new_comps = {}

        for i, comp in ipairs(comps) do
            if comp == '' or comp == curdir then
                -- pass
            elseif (comp ~= pardir or (not initial_slashes and #new_comps == 0) or
                (#new_comps > 0 and new_comps[#new_comps] == pardir)) then
                table.insert(new_comps, comp)
            elseif #new_comps > 0 then
                table.remove(new_comps)
            end
        end

        comps = new_comps
        path = table.concat(comps, sep)
        if initial_slashes then
            path = sep:rep(initial_slashes) .. path
        end

        return (path ~= '') and path or curdir
    end

    path_utils.relpath = function(path, start)
        start = start or curdir

        local start_abs = path_utils.abspath(path_utils.normpath(start))
        local path_abs = path_utils.abspath(path_utils.normpath(path))

        local start_list = path_utils._split_parts(start_abs, sep)
        local path_list = path_utils._split_parts(path_abs, sep)

        local i = 1
        for j = 1, math.min(#start_list, #path_list) do
            if start_list[j] ~= path_list[j] then break
            end
            i = j + 1
        end

        local rel_list = {}
        for j = 1, (#start_list - i + 1) do rel_list[j] = pardir end
        for j = i, #path_list do table.insert(rel_list, path_list[j]) end

        if #rel_list == 0 then
            return curdir
        end

        return path_utils.join(unpack(rel_list))
    end

end
-- Path utils end

-- Check if path is local (by looking if it's prefixed by a proto://)
local path_is_local = function(path)
    local proto = path:match('(..-)://')
    return proto == nil
end


function Set(source)
    local set = {}
    for _, l in ipairs(source) do set[l] = true end
    return set
end

---------------------------
-- More helper functions --
---------------------------

function busy_wait(seconds)
    local target = mp.get_time() + seconds
    local cycles = 0
    while target > mp.get_time() do
        cycles = cycles + 1
    end
    return cycles
end

-- Removes all keys from a table, without destroying the reference to it
function clear_table(target)
    for key, value in pairs(target) do
        target[key] = nil
    end
end

function shallow_copy(target)
    if type(target) == "table" then
        local copy = {}
        for k, v in pairs(target) do
            copy[k] = v
        end
        return copy
    else
        return target
    end
end

function deep_copy(target)
    local copy = {}
    for k, v in pairs(target) do
        if type(v) == "table" then
            copy[k] = deep_copy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Rounds to given decimals. eg. round_dec(3.145, 0) => 3
function round_dec(num, idp)
    local mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function file_exists(name)
    local f = io.open(name, "rb")
    if f ~= nil then
        local ok, err, code = f:read(1)
        io.close(f)
        return code == nil
    else
        return false
    end
end

function path_exists(name)
    local f = io.open(name, "rb")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function create_directories(path)
    local cmd
    if ON_WINDOWS then
        cmd = { args = { 'cmd', '/c', 'mkdir', path } }
    else
        cmd = { args = { 'mkdir', '-p', path } }
    end
    utils.subprocess(cmd)
end

function move_file(source_path, target_path)
    local cmd
    if ON_WINDOWS then
        cmd = { cancellable = false, args = { 'cmd', '/c', 'move', '/Y', source_path, target_path } }
        utils.subprocess(cmd)
    else
        -- cmd = { cancellable=false, args = {'mv', source_path, target_path } }
        os.rename(source_path, target_path)
    end
end

function check_pid(pid)
    -- Checks if a PID exists and returns true if so
    local cmd, r
    if ON_WINDOWS then
        cmd = { cancellable = false, args = {
            'tasklist', '/FI', ('PID eq %d'):format(pid)
        } }
        r = utils.subprocess(cmd)
        return r.stdout:sub(1, 1) == '\13'
    else
        cmd = { cancellable = false, args = {
            'sh', '-c', ('kill -0 %d 2>/dev/null'):format(pid)
        } }
        r = utils.subprocess(cmd)
        return r.status == 0
    end
end

function kill_pid(pid)
    local cmd, r
    if ON_WINDOWS then
        cmd = { cancellable = false, args = { 'taskkill', '/F', '/PID', tostring(pid) } }
    else
        cmd = { cancellable = false, args = { 'kill', tostring(pid) } }
    end
    r = utils.subprocess(cmd)
    return r.status == 0, r
end

-- Find an executable in PATH or CWD with the given name
function find_executable(name)
    local delim = ON_WINDOWS and ";" or ":"

    local pwd = os.getenv("PWD") or utils.getcwd()
    local path = os.getenv("PATH")

    local env_path = pwd .. delim .. path -- Check CWD first

    local result, filename
    for path_dir in env_path:gmatch("[^" .. delim .. "]+") do
        filename = path_utils.join(path_dir, name)
        if file_exists(filename) then
            result = filename
            break
        end
    end

    return result
end

local ExecutableFinder = { path_cache = {} }
-- Searches for an executable and caches the result if any
function ExecutableFinder:get_executable_path(name, raw_name)
    name = ON_WINDOWS and not raw_name and (name .. ".exe") or name

    if self.path_cache[name] == nil then
        self.path_cache[name] = find_executable(name) or false
    end
    return self.path_cache[name]
end

-- Format seconds to HH.MM.SS.sss
function format_time(seconds, sep, decimals)
    decimals = decimals == nil and 3 or decimals
    sep = sep and sep or ":"
    local s = seconds
    local h, s = divmod(s, 60 * 60)
    local m, s = divmod(s, 60)

    local second_format = string.format("%%0%d.%df", 2 + (decimals > 0 and decimals + 1 or 0), decimals)

    return string.format("%02d" .. sep .. "%02d" .. sep .. second_format, h, m, s)
end

-- Format seconds to 1h 2m 3.4s
function format_time_hms(seconds, sep, decimals, force_full)
    decimals = decimals == nil and 1 or decimals
    sep = sep ~= nil and sep or " "

    local s = seconds
    local h, s = divmod(s, 60 * 60)
    local m, s = divmod(s, 60)

    if force_full or h > 0 then
        return string.format("%dh" .. sep .. "%dm" .. sep .. "%." .. tostring(decimals) .. "fs", h, m, s)
    elseif m > 0 then
        return string.format("%dm" .. sep .. "%." .. tostring(decimals) .. "fs", m, s)
    else
        return string.format("%." .. tostring(decimals) .. "fs", s)
    end
end

-- Writes text on OSD and console
function log_info(txt, timeout)
    timeout = timeout or 1.5
    msg.info(txt)
    mp.osd_message(txt, timeout)
end

-- Join table items, ala ({"a", "b", "c"}, "=", "-", ", ") => "=a-, =b-, =c-"
function join_table(source, before, after, sep)
    before = before or ""
    after = after or ""
    sep = sep or ", "
    local result = ""
    for i, v in pairs(source) do
        if not isempty(v) then
            local part = before .. v .. after
            if i == 1 then
                result = part
            else
                result = result .. sep .. part
            end
        end
    end
    return result
end

function wrap(s, char)
    char = char or "'"
    return char .. s .. char
end

-- Wraps given string into 'string' and escapes any 's in it
function escape_and_wrap(s, char, replacement)
    char = char or "'"
    replacement = replacement or "\\" .. char
    return wrap(string.gsub(s, char, replacement), char)
end

-- Escapes single quotes in a string and wraps the input in single quotes
function escape_single_bash(s)
    return escape_and_wrap(s, "'", "'\\''")
end

-- Returns (a .. b) if b is not empty or nil
function joined_or_nil(a, b)
    return not isempty(b) and (a .. b) or nil
end

-- Put items from one table into another
function extend_table(target, source)
    for i, v in pairs(source) do
        table.insert(target, v)
    end
end

-- Creates a handle and filename for a temporary random file (in current directory)
function create_temporary_file(base, mode, suffix)
    local handle, filename
    suffix = suffix or ""
    while true do
        filename = base .. tostring(math.random(1, 5000)) .. suffix
        handle = io.open(filename, "r")
        if not handle then
            handle = io.open(filename, mode)
            break
        end
        io.close(handle)
    end
    return handle, filename
end

function get_processor_count()
    local proc_count

    if ON_WINDOWS then
        proc_count = tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
    else
        local cpuinfo_handle = io.open("/proc/cpuinfo")
        if cpuinfo_handle ~= nil then
            local cpuinfo_contents = cpuinfo_handle:read("*a")
            local _, replace_count = cpuinfo_contents:gsub('processor', '')
            proc_count = replace_count
        end
    end

    if proc_count and proc_count > 0 then
        return proc_count
    else
        return nil
    end
end

function substitute_values(string, values)
    local substitutor = function(match)
        if match == "%" then
            return "%"
        else
            -- nil is discarded by gsub
            return values[match]
        end
    end

    local substituted = string:gsub('%%(.)', substitutor)
    return substituted
end

-- ASS HELPERS --
function round_rect_top(ass, x0, y0, x1, y1, r)
    local c = 0.551915024494 * r -- circle approximation
    ass:move_to(x0 + r, y0)
    ass:line_to(x1 - r, y0) -- top line
    if r > 0 then
        ass:bezier_curve(x1 - r + c, y0, x1, y0 + r - c, x1, y0 + r) -- top right corner
    end
    ass:line_to(x1, y1) -- right line
    ass:line_to(x0, y1) -- bottom line
    ass:line_to(x0, y0 + r) -- left line
    if r > 0 then
        ass:bezier_curve(x0, y0 + r - c, x0 + r - c, y0, x0 + r, y0) -- top left corner
    end
end

function round_rect(ass, x0, y0, x1, y1, rtl, rtr, rbr, rbl)
    local c = 0.551915024494
    ass:move_to(x0 + rtl, y0)
    ass:line_to(x1 - rtr, y0) -- top line
    if rtr > 0 then
        ass:bezier_curve(x1 - rtr + rtr * c, y0, x1, y0 + rtr - rtr * c, x1, y0 + rtr) -- top right corner
    end
    ass:line_to(x1, y1 - rbr) -- right line
    if rbr > 0 then
        ass:bezier_curve(x1, y1 - rbr + rbr * c, x1 - rbr + rbr * c, y1, x1 - rbr, y1) -- bottom right corner
    end
    ass:line_to(x0 + rbl, y1) -- bottom line
    if rbl > 0 then
        ass:bezier_curve(x0 + rbl - rbl * c, y1, x0, y1 - rbl + rbl * c, x0, y1 - rbl) -- bottom left corner
    end
    ass:line_to(x0, y0 + rtl) -- left line
    if rtl > 0 then
        ass:bezier_curve(x0, y0 + rtl - rtl * c, x0 + rtl - rtl * c, y0, x0 + rtl, y0) -- top left corner
    end
end

--[[
  A slightly more advanced option parser for scripts.
  It supports documenting the options, and can export an example config.
  It also can rewrite the config file with overrides, preserving the
  original lines and appending changes to the end, along with profiles.

  Does not depend on other libs.
]] --

local OptionParser = {}
OptionParser.__index = OptionParser

setmetatable(OptionParser, {
    __call = function(cls, ...) return cls.new(...) end
})

function OptionParser.new(identifier, shorthand_identifier)
    local self = setmetatable({}, OptionParser)

    self.identifier = identifier
    self.shorthand_identifier = shorthand_identifier

    self.config_file = self:_get_config_file(identifier)

    self.OVERRIDE_START = "# Script-saved overrides below this line. Edits will be lost!"

    -- All the options contained, as a list
    self.options_list = {}
    -- All the options contained, as a table with keys. See add_option
    self.options = {}

    self.default_profile = { name = "default", values = {}, loaded = {}, config_lines = {} }
    self.profiles = {}

    self.active_profile = self.default_profile

    -- Recusing metatable magic to wrap self.values.key.sub_key into
    -- self.options["key.sub_key"].value, with support for assignments as well
    function get_value_or_mapper(key)
        local cur_option = self.options[key]

        if cur_option then
            -- Wrap tables
            if cur_option.type == "table" then
                return setmetatable({}, {
                    __index = function(t, sub_key)
                        return get_value_or_mapper(key .. "." .. sub_key)
                    end,
                    __newindex = function(t, sub_key, value)
                        local sub_option = self.options[key .. "." .. sub_key]
                        if sub_option and sub_option.type ~= "table" then
                            self.active_profile.values[key .. "." .. sub_key] = value
                        end
                    end
                })
            else
                return self.active_profile.values[key]
            end
        end
    end

    -- Same recusing metatable magic to get the .default
    function get_default_or_mapper(key)
        local cur_option = self.options[key]

        if cur_option then
            if cur_option.type == "table" then
                return setmetatable({}, {
                    __index = function(t, sub_key)
                        return get_default_or_mapper(key .. "." .. sub_key)
                    end,
                })
            else
                return cur_option.default
                -- return self.active_profile.values[key]
            end
        end
    end

    -- Easy lookups for values and defaults
    self.values = setmetatable({}, {
        __index = function(t, key)
            return get_value_or_mapper(key)
        end,
        __newindex = function(t, key, value)
            local option = self.options[key]
            if option then
                -- option.value = value
                self.active_profile.values[key] = value
            end
        end
    })

    self.defaults = setmetatable({}, {
        __index = function(t, key)
            return get_default_or_mapper(key)
        end
    })

    -- Hacky way to run after the script is initialized and options (hopefully) added
    mp.add_timeout(0, function()
        local get_opt_shorthand = function(key)
            return mp.get_opt(self.identifier .. "-" .. key) or
                (self.shorthand_identifier and mp.get_opt(self.shorthand_identifier .. "-" .. key))
        end

        -- Handle a '--script-opts identifier-example-config=example.conf' to save an example config to a file
        local example_dump_filename = get_opt_shorthand("example-config")
        if example_dump_filename then
            self:save_example_options(example_dump_filename)
        end

        local explain_config = get_opt_shorthand("explain-config")
        if explain_config then
            self:explain_options()
        end

        if (example_dump_filename or explain_config) and mp.get_property_native("options/idle") then
            msg.info("Exiting.")
            mp.commandv("quit")
        end
    end)

    return self
end

function OptionParser:activate_profile(profile_name)
    local chosen_profile = nil
    if profile_name then
        for i, profile in ipairs(self.profiles) do
            if profile.name == profile_name then
                chosen_profile = profile
                break
            end
        end
    else
        chosen_profile = self.default_profile
    end

    if chosen_profile then
        self.active_profile = chosen_profile
    end

end

function OptionParser:add_option(key, default, description, pad_before)
    if self.options[key] ~= nil then
        -- Already exists!
        return nil
    end

    local option_index = #self.options_list + 1
    local option_type = type(default)

    -- Check if option is an array
    if option_type == "table" then
        if default._array then
            option_type = "array"
        end
        default._array = nil
    end

    local option = {
        index = option_index,
        type = option_type,
        key = key,
        default = default,

        description = description,
        pad_before = pad_before
    }

    self.options_list[option_index] = option

    -- table-options are just containers for sub-options and have no value
    if option_type == "table" then
        option.default = nil

        -- Add sub-options
        for i, sub_option_data in ipairs(default) do
            local sub_key = sub_option_data[1]
            sub_option_data[1] = key .. "." .. sub_key
            local sub_option = self:add_option(unpack(sub_option_data))
        end
    end

    if key then
        self.options[key] = option
        self.default_profile.values[option.key] = option.default
    end

    return option
end

function OptionParser:add_options(list_of_options)
    for i, option_args in ipairs(list_of_options) do
        self:add_option(unpack(option_args))
    end
end

function OptionParser:restore_defaults()
    for key, option in pairs(self.options) do
        if option.type ~= "table" then
            self.active_profile.values[option.key] = option.default
        end
    end
end

function OptionParser:restore_loaded()
    for key, option in pairs(self.options) do
        if option.type ~= "table" then
            -- Non-default profiles will have an .loaded entry for all options
            local value = self.active_profile.loaded[option.key]
            if value == nil then value = option.default end
            self.active_profile.values[option.key] = value
        end
    end
end

function OptionParser:_get_config_file(identifier)
    local config_filename = "script-opts/" .. identifier .. ".conf"
    local config_file = mp.find_config_file(config_filename)

    if not config_file then
        config_filename = "lua-settings/" .. identifier .. ".conf"
        config_file = mp.find_config_file(config_filename)

        if config_file then
            msg.warn("lua-settings/ is deprecated, use directory script-opts/")
        end
    end

    return config_file
end

function OptionParser:value_to_string(value)
    if type(value) == "boolean" then
        if value then value = "yes" else value = "no" end
    elseif type(value) == "table" then
        return utils.format_json(value)
    end
    return tostring(value)
end

function OptionParser:string_to_value(option_type, value)
    if option_type == "boolean" then
        if value == "yes" or value == "true" then
            value = true
        elseif value == "no" or value == "false" then
            value = false
        else
            -- can't parse as boolean
            value = nil
        end
    elseif option_type == "number" then
        value = tonumber(value)
        if value == nil then
            -- Can't parse as number
        end
    elseif option_type == "array" then
        value = utils.parse_json(value)
    end
    return value
end

function OptionParser:get_profile(profile_name)
    for i, profile in ipairs(self.profiles) do
        if profile.name == profile_name then
            return profile
        end
    end
end

function OptionParser:create_profile(profile_name, base_on_original)
    if not self:get_profile(profile_name) then
        new_profile = { name = profile_name, values = {}, loaded = {}, config_lines = {} }

        if base_on_original then
            -- Copy values from default config
            for k, v in pairs(self.default_profile.values) do
                new_profile.values[k] = v
            end
            for k, v in pairs(self.default_profile.loaded) do
                new_profile.loaded[k] = v
            end
        else
            -- Copy current values, but not loaded
            for k, v in pairs(self.active_profile.values) do
                new_profile.values[k] = v
            end
        end

        table.insert(self.profiles, new_profile)
        return new_profile
    end
end

function OptionParser:load_options()

    local trim = function(text)
        return (text:gsub("^%s*(.-)%s*$", "%1"))
    end

    local script_opts_parsed = false
    -- Function to parse --script-opts with. Defined here, so we can call it at multiple possible situations
    local parse_script_opts = function()
        if script_opts_parsed then return end

        -- Checks if the given key starts with identifier or the shorthand_identifier and returns the prefix-less key
        local check_prefix = function(key)
            if key:find(self.identifier .. "-", 1, true) then
                return key:sub(self.identifier:len() + 2)
            elseif key:find(self.shorthand_identifier .. "-", 1, true) then
                return key:sub(self.shorthand_identifier:len() + 2)
            end
        end

        for key, value in pairs(mp.get_property_native("options/script-opts")) do
            key = check_prefix(key)
            if key then
                -- Handle option value, trimmed down version of the above file reading
                key = trim(key)
                value = trim(value)

                local option = self.options[key]
                if not option then
                    if not (key == 'example-config' or key == 'explain-config') then
                        msg.warn(("script-opts: ignoring unknown key '%s'"):format(key))
                    end
                elseif option.type == "table" then
                    msg.warn(("script-opts: ignoring value for table-option %s"):format(key))
                else
                    local parsed_value = self:string_to_value(option.type, value)

                    if parsed_value == nil then
                        msg.error(("script-opts: error parsing value '%s' for key '%s' (as %s)"):format(value, key,
                            option.type))
                    else
                        self.default_profile.values[option.key] = parsed_value
                        self.default_profile.loaded[option.key] = parsed_value
                    end
                end
            end
        end

        script_opts_parsed = true
    end

    local file = self.config_file and io.open(self.config_file, 'r')
    if not file then
        parse_script_opts()
        return
    end

    local current_profile = self.default_profile
    local override_reached = false
    local line_index = 1

    -- Read all lines in advance
    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()

    local total_lines = #lines

    while line_index < total_lines + 1 do
        local line = lines[line_index]

        local profile_name = line:match("^%[(..-)%]$")

        if line == self.OVERRIDE_START then
            override_reached = true

        elseif line:find("#") == 1 then
            -- Skip comments
        elseif profile_name then
            -- Profile potentially changing, parse script-opts
            parse_script_opts()
            current_profile = self:get_profile(profile_name) or self:create_profile(profile_name, true)
            override_reached = false

        else
            local key, value = line:match("^(..-)=(.+)$")
            if key then
                key = trim(key)
                value = trim(value)

                local option = self.options[key]
                if not option then
                    msg.warn(("%s:%d ignoring unknown key '%s'"):format(self.config_file, line_index, key))
                elseif option.type == "table" then
                    msg.warn(("%s:%d ignoring value for table-option %s"):format(self.config_file, line_index, key))
                else
                    -- If option is an array, make sure we read all lines
                    if option.type == "array" then
                        local start_index = line_index
                        -- Read lines until one ends with ]
                        while not value:find("%]%s*$") do
                            line_index = line_index + 1
                            if line_index > total_lines then
                                msg.error(("%s:%d non-ending %s for key '%s'"):format(self.config_file, start_index,
                                    option.type, key))
                            end
                            value = value .. trim(lines[line_index])
                        end
                    end
                    local parsed_value = self:string_to_value(option.type, value)

                    if parsed_value == nil then
                        msg.error(("%s:%d error parsing value '%s' for key '%s' (as %s)"):format(self.config_file,
                            line_index, value, key, option.type))
                    else
                        current_profile.values[option.key] = parsed_value
                        if not override_reached then
                            current_profile.loaded[option.key] = parsed_value
                        end
                    end
                end
            end
        end

        if not override_reached and not profile_name then
            table.insert(current_profile.config_lines, line)
        end

        line_index = line_index + 1
    end

    -- Parse --script-opts if they weren't already
    parse_script_opts()

end

function OptionParser:save_options()
    if not self.config_file then return nil, "no configuration file found" end

    local file = io.open(self.config_file, 'w')
    if not file then return nil, "unable to open configuration file for writing" end

    local profiles = { self.default_profile }
    for i, profile in ipairs(self.profiles) do
        table.insert(profiles, profile)
    end

    local out_lines = {}

    local add_linebreak = function()
        if out_lines[#out_lines] ~= '' then
            table.insert(out_lines, '')
        end
    end

    for profile_index, profile in ipairs(profiles) do

        local profile_override_lines = {}
        for option_index, option in ipairs(self.options_list) do
            local option_value = profile.values[option.key]
            local option_loaded = profile.loaded[option.key]

            if option_loaded == nil then
                option_loaded = self.default_profile.loaded[option.key]
            end
            if option_loaded == nil then
                option_loaded = option.default
            end

            -- If value is different from default AND loaded value, store it in array
            if option.key then
                if (option_value ~= option_loaded) then
                    table.insert(profile_override_lines, ('%s=%s'):format(option.key, self:value_to_string(option_value)))
                end
            end
        end

        if (#profile.config_lines > 0 or #profile_override_lines > 0) and profile ~= self.default_profile then
            -- Write profile name, if this is not default profile
            add_linebreak()
            table.insert(out_lines, ("[%s]"):format(profile.name))
        end

        -- Write original config lines
        for line_index, line in ipairs(profile.config_lines) do
            table.insert(out_lines, line)
        end
        -- end

        if #profile_override_lines > 0 then
            -- Add another newline before the override comment, if needed
            add_linebreak()

            table.insert(out_lines, self.OVERRIDE_START)
            for override_line_index, override_line in ipairs(profile_override_lines) do
                table.insert(out_lines, override_line)
            end
        end

    end

    -- Add a final linebreak if needed
    add_linebreak()

    file:write(table.concat(out_lines, "\n"))
    file:close()

    return true
end

function OptionParser:get_default_config_lines()
    local example_config_lines = {}

    for option_index, option in ipairs(self.options_list) do
        if option.pad_before then
            table.insert(example_config_lines, '')
        end

        if option.description then
            for description_line in option.description:gmatch('[^\r\n]+') do
                table.insert(example_config_lines, ('# ' .. description_line))
            end
        end
        if option.key and option.type ~= "table" then
            table.insert(example_config_lines, ('%s=%s'):format(option.key, self:value_to_string(option.default)))
        end
    end
    return example_config_lines
end

function OptionParser:explain_options()
    local example_config_lines = self:get_default_config_lines()
    msg.info(table.concat(example_config_lines, '\n'))
end

function OptionParser:save_example_options(filename)
    local file = io.open(filename, "w")
    if not file then
        msg.error("Unable to open file '" .. filename .. "' for writing")
    else
        local example_config_lines = self:get_default_config_lines()
        file:write(table.concat(example_config_lines, '\n'))
        file:close()
        msg.info("Wrote example config to file '" .. filename .. "'")
    end
end

local SCRIPT_NAME = "mpv_sort_script"

--------------------
-- Script options --
--------------------

local script_options = OptionParser(SCRIPT_NAME, 'sort')
local option_values = script_options.values

local BASE_EXTENSIONS = {
    'mkv', 'avi', 'mp4', 'ogv', 'webm', 'rmvb', 'flv', 'wmv', 'mpeg', 'mpg', 'm4v', '3gp', 'mov', 'ts',
    'mp3', 'wav', 'ogm', 'flac', 'm4a', 'wma', 'ogg', 'opus',
    'jpg', 'jpeg', 'png', 'bmp', 'gif', 'webp'
}

local SORT_KEY_NAMES = {
    "name", "date", "size", "random"
}
local PRECEDENCE_KEY_NAMES = {
    "files", "dirs", "mix"
}

local SORT_KEYS = Set(SORT_KEY_NAMES)
local PRECEDENCE_KEYS = Set(PRECEDENCE_KEY_NAMES)

script_options:add_options({
    { nil, nil, "mpv_sort_script.lua options and default values" },

    { "always_sort", false,
        "Whether to sort directory entries even without being explicitly told to. Not recommended unless you're sure about what you're doing",
        true },

    { "recursive_sort", false,
        "Whether to recurse into subdirectories and sort all found files and directories in one go, instead of sorting each directory when we come across it.\nNote: only applies to always_sort, since sort: and rsort: control the recursion in explicit sorting",
        true },
    { "max_recurse_depth", 10,
        "Maximum recurse depth for subdirectories. 0 means no recursion." },

    { "default_sort", "date",
        "Default sorting method, used if one is not explicitly provided. Must be one of: " ..
            table.concat(SORT_KEY_NAMES, ", "), true },
    { "default_precedence", "files",
        "Default file/directory precedence (which to sort first), used if one is not explicitly provided. Must be one of: "
            .. table.concat(PRECEDENCE_KEY_NAMES, ", ") },
    { "default_descending", false,
        "Descending sort by default" },

    { "alphanumeric_sort", true,
        "Use alphanumeric sort instead of naive character sort. Ie., sort names by taking the numerical values into account.",
        true },
    { "stable_random_sort", true,
        "Generate a random seeed from the given path, file and directory count, to randomly sort entries in a reproducible manner. This enables random sort to work with watch-later resuming." },
    { "random_seed", "seed",
        "Extra random seed to use with stable_random_sort, if you want to change the stable order." },

    { "extensions", table.concat(BASE_EXTENSIONS, ","),
        "A comma-separated list of extensions to be consired as playable files.", true },

    { "exclude", "",
        "A Lua match pattern (more or less) to exclude file and directory paths with. '*' will be automatically replaced with '.-'." },
})

-- Read user-given options, if any
script_options:load_options()

if not SORT_KEYS[option_values.default_sort] then
    msg.warn(("Resetting bad default_sort '%s' to default"):format(option_values.default_sort))
    option_values.default_sort = script_options.defaults.default_sort
end

if not PRECEDENCE_KEYS[option_values.default_precedence] then
    msg.warn(("Resetting bad default_precedence '%s' to default"):format(option_values.default_precedence))
    option_values.default_precedence = script_options.defaults.default_precedence
end

local EXTENSIONS = {}
for k in option_values.extensions:lower():gmatch('[^, ]+') do
    EXTENSIONS[k] = true
end

local EXCLUDE_PATTERN = option_values.exclude:len() > 0 and option_values.exclude:gsub('%*', '.-') or nil
-- alphanum.lua (C) Andre Bogus
--[[ based on the python version of ned batchelder
Distributed under same license as original

Released under the MIT License - https://opensource.org/licenses/MIT

Copyright 2007-2017 David Koelle

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

----- winapi start -----
-- in windows system, we can use the sorting function provided by the win32 API
-- see https://learn.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-strcmplogicalw
-- this function was taken from https://github.com/mpvnet-player/mpv.net/issues/575#issuecomment-1817413401
local winapi = {}
local is_windows = package.config:sub(1,1) == "\\"

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

function alphanumsort(a, b)
    local is_ffi_loaded = pcall(require, "ffi")
    if is_windows and is_ffi_loaded then
        local a_wide = winapi.utf8_to_wide(a)
        local b_wide = winapi.utf8_to_wide(b)
        return winapi.shlwapi.StrCmpLogicalW(a_wide, b_wide) == -1
    else
        -- alphanum sorting for humans in Lua
        -- http://notebook.kulchenko.com/algorithms/alphanumeric-natural-sorting-for-humans-in-lua
        local function padnum(d)
            local dec, n = string.match(d, "(%.?)0*(.+)")
            return #dec > 0 and ("%.12f"):format(d) or ("%s%03d%s"):format(dec, #n, n)
        end
        return tostring(a):lower():gsub("%.?%d+", padnum) .. ("%3d"):format(#b)
            < tostring(b):lower():gsub("%.?%d+", padnum) .. ("%3d"):format(#a)
    end
end

function exclude_entries(entries)
    local filtered_entries = {}
    for i, entry in ipairs(entries) do
        if not entry:find(EXCLUDE_PATTERN) then
            filtered_entries[#filtered_entries + 1] = entry
        end
        entries[i] = nil
    end
    for i, entry in ipairs(filtered_entries) do
        entries[i] = entry
    end
end

function filter_files(files)
    local filtered_files = {}
    for i, file in ipairs(files) do
        local ext = file:match('%.([^%.]+)$') or ''
        if EXTENSIONS[ext:lower()] then
            filtered_files[#filtered_files + 1] = file
        end
        files[i] = nil
    end
    for i, file in ipairs(filtered_files) do
        files[i] = file
    end
end

function get_directory_entries(directory_path)
    local files = utils.readdir(directory_path, 'files') or {}
    local dirs  = utils.readdir(directory_path, 'dirs') or {}
    filter_files(files)

    for i, v in ipairs(files) do
        files[i] = path_utils.join(directory_path, v)
    end
    for i, v in ipairs(dirs) do
        dirs[i] = path_utils.join(directory_path, v)
    end

    if EXCLUDE_PATTERN then
        exclude_entries(files)
        exclude_entries(dirs)
    end

    return files, dirs
end

function get_directory_entries_recursive(directory_path, current_depth)
    current_depth = current_depth or 0

    local files, dirs = get_directory_entries(directory_path)

    if current_depth < option_values.max_recurse_depth then
        for i, sub_directory_path in ipairs(dirs) do
            msg.verbose('Traversing into', sub_directory_path)
            local sub_files = get_directory_entries_recursive(sub_directory_path, current_depth + 1)

            for i, sub_file in ipairs(sub_files) do
                files[#files + 1] = sub_file
            end
        end
    end

    return files, {}
end

function _sort_by_infos(entries, infos, sort, descending)
    local directory_entry_counts = {}
    function count_directory_entries(entry)
        local count = directory_entry_counts[entry]
        if not count then
            count = #(utils.readdir(entry) or {})
            directory_entry_counts[entry] = count
            msg.trace('Counted entries for directory:', entry, count)
        end
        return count
    end

    local namecomp = option_values.alphanumeric_sort and function(a, b) return alphanumsort(a, b) end or
        function(a, b) return a < b end

    local compfunc = function(a, b)
        local info_a = infos[a]
        local info_b = infos[b]

        if sort == 'name' then
            return namecomp(a, b)

        elseif sort == 'size' then
            -- Comparing files and directories is weirder, so let's decide all directories are 'less' than files
            -- This only happens when precedence is 'both'

            if info_a.is_dir and info_b.is_dir then
                -- Order by directory entry count (instead of 'filesize')
                return count_directory_entries(a) < count_directory_entries(b)
            elseif info_a.is_dir then
                return true
            elseif info_b.is_dir then
                return false
            else
                if info_a.size == info_b.size then
                    return namecomp(a, b)
                else
                    return info_a.size < info_b.size
                end
            end

        elseif sort == 'date' then
            if info_a.mtime == info_b.mtime then
                return namecomp(a, b)
            else
                return info_a.mtime < info_b.mtime
            end

        end
    end

    if sort == 'random' then
        -- Simple shuffle
        for i = #entries, 2, -1 do
            local j = math.random(i)
            entries[i], entries[j] = entries[j], entries[i]
        end
    else
        local used_sort = compfunc
        if descending then
            used_sort = function(a, b) return compfunc(b, a) end
        end
        table.sort(entries, used_sort)
    end
end

function sort_entries(files, dirs, sort, precedence, descending)
    local infos = {}
    for i, file in ipairs(files) do
        infos[file] = utils.file_info(file)
    end
    for i, dir in ipairs(dirs) do
        infos[dir] = utils.file_info(dir)
    end

    local entries = nil
    if precedence == 'files' then
        -- Sort files first, then directories
        _sort_by_infos(files, infos, sort, descending)
        _sort_by_infos(dirs, infos, sort, descending)

        entries = files
        for i, v in ipairs(dirs) do entries[#entries + 1] = v end
    elseif precedence == 'dirs' then
        -- Sort directories first, then files
        _sort_by_infos(files, infos, sort, descending)
        _sort_by_infos(dirs, infos, sort, descending)

        entries = dirs
        for i, v in ipairs(files) do entries[#entries + 1] = v end
    elseif precedence == 'mix' then
        -- Sort together
        entries = files
        for i, v in ipairs(dirs) do entries[#entries + 1] = v end
        _sort_by_infos(entries, infos, sort, descending)
    end

    return entries, infos
end

mp.add_hook('on_load', 50, function()
    local path = mp.get_property_native('path')

    local sort_key        = option_values.default_sort
    local sort_precedence = option_values.default_precedence
    local sort_descending = option_values.default_descending
    local sort_recursive  = option_values.recursive_sort

    local explicit_sort, real_path = path:match('^(/?r?sort.-:)(.+)$')
    if explicit_sort then
        path = real_path

        if explicit_sort:find('/') ~= 1 then
            -- prefix the sort protocol with / because load-unsafe-playlists doesn't like URIs in playlists
            explicit_sort = '/' .. explicit_sort
        end
        -- sort - normal sort; rsort - recursive sort
        sort_recursive = explicit_sort:find('r') == 2

        local custom_key = explicit_sort:match('^/r?sort%-(.-):$')
        if custom_key then
            -- Check if we want to sort ascending or descending
            if custom_key:find('[-+]$') then
                sort_descending = custom_key:sub(custom_key:len()) == '-'
                custom_key = custom_key:sub(1, custom_key:len() - 1)
            end

            if SORT_KEYS[custom_key] then
                sort_key = custom_key
            else
                msg.warn(('Ignoring bad sort key: %s. Allowed values: %s'):format(custom_key,
                    table.concat(SORT_KEY_NAMES, ', ')))
            end
        end

    elseif option_values.always_sort then
        msg.debug('Implictly sorting path (always_sort enabled)!')
        -- Make up the sort prefix for later use
        explicit_sort = ('/%ssort-%s%s:'):format(sort_recursive and 'r' or '', sort_key, sort_descending and '-' or '+')
    else
        -- Not explicitly called or sorted by default, so exit
        return
    end

    local file_info = utils.file_info(path)
    if not file_info then
        -- Not a local file, abort
        if explicit_sort and not option_values.always_sort then
            msg.error('Unable to stat given path, aborting')
        end
        return
    end

    if file_info.is_dir then
        msg.verbose('Reading directory entries:', path)
        local files, dirs
        if sort_recursive then
            files, dirs = get_directory_entries_recursive(path)
        else
            files, dirs = get_directory_entries(path)
        end
        msg.verbose(('Got %d files, %d directories'):format(#files, #dirs))

        msg.verbose(('Sorting with: key: %s, sort_descending: %s, precedence: %s'):format(sort_key,
            sort_descending and 'true' or 'false', sort_precedence))
        if sort_precedence == 'mix' and sort_key == 'size' then
            msg.warn('Sorting both files and directories together by size may give unintuitive results')
        end

        if option_values.stable_random_sort and sort_key == 'random' then
            local seed_string = ('%s-%d-%d-%s'):format(path, #files, #dirs, option_values.random_seed)
            local seed_bytes = { seed_string:byte(1, #seed_string) }
            -- Simple djb2 hash to turn the string into a number
            local seed = 5381
            for i, b in ipairs(seed_bytes) do
                seed = seed * 33 + b
            end
            msg.verbose(('Using seed %d (%s) for stable random sort'):format(seed, seed_string))
            math.randomseed(seed)
        end

        local entries, infos = sort_entries(files, dirs, sort_key, sort_precedence, sort_descending)

        local playlist_lines = { '#EXTM3U' }
        for i, entry in ipairs(entries) do
            -- Prefix directories with our custom sort info, so we'll parse them too
            local prefix = infos[entry].is_dir and explicit_sort or ''
            playlist_lines[#playlist_lines + 1] = '#EXTINF:0,' .. path_utils.basename(entry)
            playlist_lines[#playlist_lines + 1] = prefix .. path_utils.abspath(entry)
        end

        local data = 'memory://' .. table.concat(playlist_lines, '\n')
        mp.set_property_native('stream-open-filename', data)
        mp.set_property_native('file-local-options/load-unsafe-playlists', true)

        msg.verbose(('Set sorted playlist with %d entries'):format(#entries))
    end

end)
