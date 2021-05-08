--[[
    Copyright (C) 2017 AMM

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
]]--
--[[
    mpv_crop_script.lua 0.5.0 - commit 472281e (branch master)
    Built on 2018-09-30 14:22:46
]]--
--[[
  Assorted helper functions, from checking falsey values to path utils
  to escaping and wrapping strings.

  Does not depend on other libs.
]]--

local assdraw = require 'mp.assdraw'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

-- Determine platform --
ON_WINDOWS = (package.config:sub(1,1) ~= '/')

-- Some helper functions needed to parse the options --
function isempty(v) return (v == false) or (v == nil) or (v == "") or (v == 0) or (type(v) == "table" and next(v) == nil) end

function divmod (a, b)
  return math.floor(a / b), a % b
end

-- Better modulo
function bmod( i, N )
  return (i % N + N) % N
end


-- Path utils
local path_utils = {
  abspath    = true,
  split      = true,
  dirname    = true,
  basename   = true,

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
    local head = path:sub(0, last_index-1)
    local tail = path:sub(last_index+1)
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
    head = path:sub(0, last_index-1)
    tail = path:sub(last_index+1)
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
    return either_sep(path:sub(1,1))
  end

  path_utils.normcase = function(path)
    return path:gsub(altsep, sep):lower()
  end

  path_utils.splitdrive = function(path)
    if #path >= 2 then
      local norm = path:gsub(altsep, sep)
      if (norm:sub(1, 2) == (sep..sep)) and (norm:sub(3,3) ~= sep) then
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

        return path:sub(1, index2-1), path:sub(index2)
      elseif norm:sub(2,2) == colon then
        return path:sub(1, 2), path:sub(3)
      end
    end
    return '', path
  end

  path_utils.join = function(path, ...)
    local paths = {...}

    local result_drive, result_path = path_utils.splitdrive(path)

    function inner(p)
      local p_drive, p_path = path_utils.splitdrive(p)
      if either_sep(p_path:sub(1,1)) then
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
    if result_path ~= '' and not either_sep(result_path:sub(1,1)) and
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
        if i > 1 and comps[i-1] ~= pardir then
          table.remove(comps, i)
          table.remove(comps, i-1)
          i = i - 1
        elseif i == 1 and prefix:match('\\$') then
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

  path_utils.isabs = function(path) return path:sub(1,1) == '/' end
  path_utils.normcase = function(path) return path end
  path_utils.splitdrive = function(path) return '', path end

  path_utils.join = function(path, ...)
    local paths = {...}

    for i, p in ipairs(paths) do
      if p:sub(1,1) == sep then
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

    local initial_slashes = (path:sub(1,1) == sep) and 1
    if initial_slashes and path:sub(2,2) == sep and path:sub(3,3) ~= sep then
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
  local mult = 10^(idp or 0)
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
    cmd = { args = {'cmd', '/c', 'mkdir', path} }
  else
    cmd = { args = {'mkdir', '-p', path} }
  end
  utils.subprocess(cmd)
end

function move_file(source_path, target_path)
  local cmd
  if ON_WINDOWS then
    cmd = { cancellable=false, args = {'cmd', '/c', 'move', '/Y', source_path, target_path } }
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
    cmd = { cancellable=false, args = {
      'tasklist', '/FI', ('PID eq %d'):format(pid)
    }}
    r = utils.subprocess(cmd)
    return r.stdout:sub(1,1) == '\13'
  else
    cmd = { cancellable=false, args = {
      'sh', '-c', ('kill -0 %d 2>/dev/null'):format(pid)
    }}
    r = utils.subprocess(cmd)
    return r.status == 0
  end
end

function kill_pid(pid)
  local cmd, r
  if ON_WINDOWS then
    cmd = { cancellable=false, args = {'taskkill', '/F', '/PID', tostring(pid) } }
  else
    cmd = { cancellable=false, args = {'kill', tostring(pid) } }
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
  for path_dir in env_path:gmatch("[^"..delim.."]+") do
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
function ExecutableFinder:get_executable_path( name, raw_name )
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
  local h, s = divmod(s, 60*60)
  local m, s = divmod(s, 60)

  local second_format = string.format("%%0%d.%df", 2+(decimals > 0 and decimals+1 or 0), decimals)

  return string.format("%02d"..sep.."%02d"..sep..second_format, h, m, s)
end

-- Format seconds to 1h 2m 3.4s
function format_time_hms(seconds, sep, decimals, force_full)
  decimals = decimals == nil and 1 or decimals
  sep = sep ~= nil and sep or " "

  local s = seconds
  local h, s = divmod(s, 60*60)
  local m, s = divmod(s, 60)

  if force_full or h > 0 then
    return string.format("%dh"..sep.."%dm"..sep.."%." .. tostring(decimals) .. "fs", h, m, s)
  elseif m > 0 then
    return string.format("%dm"..sep.."%." .. tostring(decimals) .. "fs", m, s)
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
function round_rect_top( ass, x0, y0, x1, y1, r )
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
        ass:bezier_curve(x1 - rtr + rtr*c, y0, x1, y0 + rtr - rtr*c, x1, y0 + rtr) -- top right corner
    end
    ass:line_to(x1, y1 - rbr) -- right line
    if rbr > 0 then
        ass:bezier_curve(x1, y1 - rbr + rbr*c, x1 - rbr + rbr*c, y1, x1 - rbr, y1) -- bottom right corner
    end
    ass:line_to(x0 + rbl, y1) -- bottom line
    if rbl > 0 then
        ass:bezier_curve(x0 + rbl - rbl*c, y1, x0, y1 - rbl + rbl*c, x0, y1 - rbl) -- bottom left corner
    end
    ass:line_to(x0, y0 + rtl) -- left line
    if rtl > 0 then
        ass:bezier_curve(x0, y0 + rtl - rtl*c, x0 + rtl - rtl*c, y0, x0 + rtl, y0) -- top left corner
    end
end
--[[
  A slightly more advanced option parser for scripts.
  It supports documenting the options, and can export an example config.
  It also can rewrite the config file with overrides, preserving the
  original lines and appending changes to the end, along with profiles.

  Does not depend on other libs.
]]--

local OptionParser = {}
OptionParser.__index = OptionParser

setmetatable(OptionParser, {
  __call = function (cls, ...) return cls.new(...) end
})

function OptionParser.new(identifier)
  local self = setmetatable({}, OptionParser)

  self.identifier = identifier
  self.config_file = self:_get_config_file(identifier)

  self.OVERRIDE_START = "# Script-saved overrides below this line. Edits will be lost!"

  -- All the options contained, as a list
  self.options_list = {}
  -- All the options contained, as a table with keys. See add_option
  self.options = {}

  self.default_profile = {name = "default", values = {}, loaded={}, config_lines = {}}
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
    -- Handle a '--script-opts identifier-example-config=example.conf' to save an example config to a file
    local example_dump_filename = mp.get_opt(self.identifier .. "-example-config")
    if example_dump_filename then
      self:save_example_options(example_dump_filename)

    end
    local explain_config = mp.get_opt(self.identifier .. "-explain-config")
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
    new_profile = {name = profile_name, values={}, loaded={}, config_lines={}}

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
  if not self.config_file then return end
  local file = io.open(self.config_file, 'r')
  if not file then return end

  local trim = function(text)
    return (text:gsub("^%s*(.-)%s*$", "%1"))
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
            while not value:match("%]%s*$") do
              line_index = line_index + 1
              if line_index > total_lines then
                msg.error(("%s:%d non-ending %s for key '%s'"):format(self.config_file, start_index, option.type, key))
              end
              value = value .. trim(lines[line_index])
            end
          end
          local parsed_value = self:string_to_value(option.type, value)

          if parsed_value == nil then
            msg.error(("%s:%d error parsing value '%s' for key '%s' (as %s)"):format(self.config_file, line_index, value, key, option.type))
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
end


function OptionParser:save_options()
  if not self.config_file then return nil, "no configuration file found" end

  local file = io.open(self.config_file, 'w')
  if not file then return nil, "unable to open configuration file for writing" end

  local profiles = {self.default_profile}
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
      table.insert(example_config_lines, ('%s=%s'):format(option.key, self:value_to_string(option.default)) )
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
local SCRIPT_NAME = "mpv_crop_script"

local SCRIPT_KEYBIND = "c"
local SCRIPT_HANDLER = "crop-screenshot"

--------------------
-- Script options --
--------------------

local script_options = OptionParser(SCRIPT_NAME)
local option_values = script_options.values

script_options:add_options({
  {nil, nil, "mpv_crop_script.lua options and default values"},
  {nil, nil, "Output options #", true},
  {"output_template", "${filename}${!is_image: ${#pos:%02h.%02m.%06.3s}}${!full: ${crop_w}x${crop_h}} ${%unique:%03d}.${ext}",
    "Filename output template. See README.md for property expansion documentation."},
  {nil, nil, [[Script-provided properties:
  filename    - filename without extension
  file_ext    - original extension without leading dot
  path        - original file path
  pos         - playback time
  ext         - output file extension without leading dot
  crop_w      - crop width
  crop_h      - crop height
  crop_x      - left
  crop_y      - top
  crop_x2     - right
  crop_y2     - bottom
  full        - boolean denoting a full (temporary) screenshot instead of crop
  is_image    - boolean denoting the source file is likely an image (zero duration and position)
  unique      - counter that will increase per each existing filename, until a unique name is found]]},

  {"output_format", "png",
    "Format (encoder) to save final crops in. For example, png, mjpeg, targa, bmp"},
  {"output_extension", "",
    "Output extension. Leave blank to try to choose from the encoder (if supported)"},

  {"create_directories", false,
    "Whether to create the directories in the final output path (defined by output_template)"},
  {"skip_screenshot_for_images", true,
    "If the current file is an image, skip taking a temporary screenshot and crop the image directly"},
  {"keep_original", false,
    "Keep the full-sized temporary screenshot as well"},

  {nil, nil, "Crop tool options #", true},
  {"overlay_transparency", 160,
    "Transparency (0 - opaque, 255 - transparent) of the dim overlay on the non-cropped area"},
  {"overlay_lightness", 0,
    "Ligthness (0 - black, 255 - white) of the dim overlay on the non-cropped area"},
  {"draw_mouse", false,
    "Draw the crop crosshair"},
  {"guide_type", "none",
    "Crop guide type. One of: none, grid, center"},
  {"color_invert", false,
    "Use black lines instead of white for the crop frame and crosshair"},
  {"auto_invert", false,
    "Try to check if video is light or dark upon opening crop tool, and invert the colors if necessary"},

  {nil, nil, "Misc options #", true},
  {"warn_about_template", true,
    "Warn about output_template missing ${ext}, to ensure the extension is not missing"},
  {"disable_keybind", false,
    "Disable the built-in keybind"}
})

-- Read user-given options, if any
script_options:load_options()
--[[
  DisplayState keeps track of the current display state, and can
  handle mapping between video-space coords and display-space coords.
  Handles panscan and offsets and aligns and all that, following what
  mpv itself does (video/out/aspect.c).

  Does not depend on other libs.
]]--

local DisplayState = {}
DisplayState.__index = DisplayState

setmetatable(DisplayState, {
  __call = function (cls, ...) return cls.new(...) end
})

function DisplayState.new()
  local self = setmetatable({}, DisplayState)

  self:reset()

  return self
end

function DisplayState:reset()
  self.screen = {} -- Display (window, fullscreen) size
  self.video  = {} -- Video size
  self.scale  = {} -- video / screen
  self.bounds = {} -- Video rect within display

  self.screen_ready = false
  self.video_ready = false

  -- Stores internal display state (panscan, align, zoom etc)
  self.current_state = nil
end

function DisplayState:setup_events()
  mp.register_event("file-loaded", function() self:event_file_loaded() end)
end

function DisplayState:event_file_loaded()
  self:reset()
  self:recalculate_bounds(true)
end

-- Turns screen-space XY to video XY (can go negative)
function DisplayState:screen_to_video(x, y)
  local nx = (x - self.bounds.left) * self.scale.x
  local ny = (y - self.bounds.top ) * self.scale.y
  return nx, ny
end

-- Turns video-space XY to screen XY
function DisplayState:video_to_screen(x, y)
  local nx = (x / self.scale.x) + self.bounds.left
  local ny = (y / self.scale.y) + self.bounds.top
  return nx, ny
end

function DisplayState:_collect_display_state()
  local screen_w, screen_h, screen_aspect = mp.get_osd_size()

  local state = {
    screen_w = screen_w,
    screen_h = screen_h,
    screen_aspect = screen_aspect,

    video_w = mp.get_property_native("dwidth"),
    video_h = mp.get_property_native("dheight"),

    video_w_raw = mp.get_property_native("video-out-params/w"),
    video_h_raw = mp.get_property_native("video-out-params/h"),

    panscan = mp.get_property_native("panscan"),
    video_zoom = mp.get_property_native("video-zoom"),
    video_unscaled = mp.get_property_native("video-unscaled"),

    video_align_x = mp.get_property_native("video-align-x"),
    video_align_y = mp.get_property_native("video-align-y"),

    video_pan_x = mp.get_property_native("video-pan-x"),
    video_pan_y = mp.get_property_native("video-pan-y"),

    fullscreen = mp.get_property_native("fullscreen"),
    keepaspect = mp.get_property_native("keepaspect"),
    keepaspect_window = mp.get_property_native("keepaspect-window")
  }

  return state
end

function DisplayState:_state_changed(state)
  if self.current_state == nil then return true end

  for k in pairs(state) do
    if state[k] ~= self.current_state[k] then return true end
  end
  return false
end


function DisplayState:recalculate_bounds(forced)
  local new_state = self:_collect_display_state()
  if not (forced or self:_state_changed(new_state)) then
    -- Early out
    return self.screen_ready
  end
  self.current_state = new_state

  -- Store screen dimensions
  self.screen.width  = new_state.screen_w
  self.screen.height = new_state.screen_h
  self.screen.ratio  = new_state.screen_w / new_state.screen_h
  self.screen_ready = true

  -- Video dimensions
  if new_state.video_w and new_state.video_h then
    self.video.width  = new_state.video_w
    self.video.height = new_state.video_h
    self.video.ratio  = new_state.video_w / new_state.video_h

    -- This magic has been adapted from mpv's own video/out/aspect.c

    if new_state.keepaspect then
      local scaled_w, scaled_h = self:_aspect_calc_panscan(new_state)
      local video_left, video_right = self:_split_scaling(new_state.screen_w, scaled_w, new_state.video_zoom, new_state.video_align_x, new_state.video_pan_x)
      local video_top, video_bottom = self:_split_scaling(new_state.screen_h, scaled_h, new_state.video_zoom, new_state.video_align_y, new_state.video_pan_y)
      self.bounds = {
        left = video_left,
        right = video_right,

        top = video_top,
        bottom = video_bottom,

        width = video_right - video_left,
        height = video_bottom - video_top,
      }
    else
      self.bounds = {
        left = 0,
        top = 0,
        right = self.screen.width,
        bottom = self.screen.height,

        width = self.screen.width,
        height = self.screen.height,
      }
    end

    self.scale.x = new_state.video_w_raw / self.bounds.width
    self.scale.y = new_state.video_h_raw / self.bounds.height

    self.video_ready = true
  end

  return self.screen_ready
end


function DisplayState:_aspect_calc_panscan(state)
  -- From video/out/aspect.c
  local f_width = state.screen_w
  local f_height = (state.screen_w / state.video_w) * state.video_h

  if f_height > state.screen_h or f_height < state.video_h_raw then
    local tmp_w = (state.screen_h / state.video_h) * state.video_w
    if tmp_w <= state.screen_w then
      f_height = state.screen_h
      f_width = tmp_w
    end
  end

  local vo_panscan_area = state.screen_h - f_height

  local f_w = f_width / f_height
  local f_h = 1
  if (vo_panscan_area == 0) then
    vo_panscan_area = state.screen_w - f_width
    f_w = 1
    f_h = f_height / f_width
  end

  if state.video_unscaled then
    vo_panscan_area = 0
    if state.video_unscaled ~= "downscale-big" or ((state.video_w <= state.screen_w) and (state.video_h <= state.screen_h)) then
      f_width = state.video_w
      f_height = state.video_h
    end
  end

  local scaled_w = math.floor( f_width + vo_panscan_area * state.panscan * f_w )
  local scaled_h = math.floor( f_height + vo_panscan_area * state.panscan * f_h )
  return scaled_w, scaled_h
end

function DisplayState:_split_scaling(dst_size, scaled_src_size, zoom, align, pan)
  -- From video/out/aspect.c as well
  scaled_src_size = math.floor(scaled_src_size * 2^zoom)
  align = (align + 1) / 2

  local dst_start = (dst_size - scaled_src_size) * align + pan * scaled_src_size
  local dst_end = dst_start + scaled_src_size

  -- We don't actually want these - we want to go out of bounds!
  -- dst_start = math.max(0, dst_start)
  -- dst_end = math.min(dst_size, dst_end)

  return math.floor(dst_start), math.floor(dst_end)
end
--[[
  ASSCropper is a tool to get crop values with a visual tool
  that handles mouse clicks and drags to manipulate a crop box,
  with a crosshair, guides, etc.

  Indirectly depends on DisplayState (as a given instance).
]]--

local ASSCropper = {}
ASSCropper.__index = ASSCropper

setmetatable(ASSCropper, {
  __call = function (cls, ...) return cls.new(...) end
})

function ASSCropper.new(display_state)
  local self = setmetatable({}, ASSCropper)
  local script_name = mp.get_script_name()
  self.keybind_group = script_name .. "_asscropper_binds"
  self.cropdetect_label = script_name .. "_asscropper_cropdetect"
  self.blackframe_label = script_name .. "_asscropper_blackframe"
  self.crop_label = script_name .. "_asscropper_crop"

  self.display_state = display_state

  self.tick_callback = nil
  self.tick_timer = mp.add_periodic_timer(1/60, function()
    if self.tick_callback then self.tick_callback() end
  end)
  self.tick_timer:stop()

  self.text_size = 18

  self.overlay_transparency = 160
  self.overlay_lightness = 0

  self.corner_size = 40
  self.corner_required_size = self.corner_size * 3

  self.guide_type_names = {
    [0] = "No guides",
    [1] = "Grid guides",
    [2] = "Center guides"
  }
  self.guide_type_count = 3

  self.default_options = {
    even_dimensions = false,
    guide_type = 0,
    draw_mouse = false,
    draw_help = true,
    color_invert = false,
    auto_invert = false,
  }
  self.options = default_options

  self.active = false

  self.mouse_screen = {x=0, y=0}
  self.mouse_video  = {x=0, y=0}

  -- Crop in video-space
  self.current_crop = nil

  self.dragging = 0
  self.drag_start = {x=0, y=0}
  self.restrict_ratio = false

  self.testing_crop = false

  self.detecting_crop = nil
  self.cropdetect_wait = nil
  self.cropdetect_timeout = nil

  self.detecting_blackframe = nil
  self.blackframe_wait = nil
  self.blackframe_timeout = nil

  self.nudges = {
    NUDGE_LEFT  = {-1,  0, -1,  0},
    NUDGE_UP    = { 0, -1,  0, -1},
    NUDGE_RIGHT = { 1,  0,  1,  0},
    NUDGE_DOWN  = { 0,  1,  0,  1}
  }

  self.resizes = {
    SHRINK_LEFT  = { 1,  0,  0,  0},
    SHRINK_TOP   = { 0,  1,  0,  0},
    SHRINK_RIGHT = { 0,  0, -1,  0},
    SHRINK_BOT   = { 0,  0,  0, -1},

    GROW_LEFT  = {-1,  0,  0,  0},
    GROW_TOP   = { 0, -1,  0,  0},
    GROW_RIGHT = { 0,  0,  1,  0},
    GROW_BOT   = { 0,  0,  0,  1},
  }

  self._key_binds = {
    {"mouse_move", function()  self:update_mouse_position() end },
    {"mouse_btn0", function(e) self:on_mouse("mouse_btn0", e) end, {complex=true}},
    {"shift+mouse_btn0", function(e) self:on_mouse("mouse_btn0", e, true) end, {complex=true}},

    {"c", function() self:key_event("CROSSHAIR")   end },
    {"d", function() self:key_event("CROP_DETECT") end },
    {"x", function() self:key_event("GUIDES")      end },
    {"t", function() self:key_event("TEST")        end },
    {"z", function() self:key_event("INVERT")      end },

    {"shift+left",  function() self:key_event("NUDGE_LEFT")  end, {repeatable=true} },
    {"shift+up",    function() self:key_event("NUDGE_UP")    end, {repeatable=true} },
    {"shift+right", function() self:key_event("NUDGE_RIGHT") end, {repeatable=true} },
    {"shift+down",  function() self:key_event("NUDGE_DOWN")  end, {repeatable=true} },

    {"ctrl+left",  function() self:key_event("GROW_LEFT")  end, {repeatable=true} },
    {"ctrl+up",    function() self:key_event("GROW_TOP")   end, {repeatable=true} },
    {"ctrl+right", function() self:key_event("SHRINK_LEFT") end, {repeatable=true} },
    {"ctrl+down",  function() self:key_event("SHRINK_TOP")   end, {repeatable=true} },

    {"ctrl+shift+left",  function() self:key_event("SHRINK_RIGHT")  end, {repeatable=true} },
    {"ctrl+shift+up",    function() self:key_event("SHRINK_BOT")   end, {repeatable=true} },
    {"ctrl+shift+right", function() self:key_event("GROW_RIGHT") end, {repeatable=true} },
    {"ctrl+shift+down",  function() self:key_event("GROW_BOT")   end, {repeatable=true} },

    {"ENTER", function() self:key_event("ENTER") end },
    {"ESC",   function() self:key_event("ESC")   end }
  }

  self._keys_bound = false

  for k, v in pairs(self._key_binds) do
    -- Insert a key name into the tables
    table.insert(v, 2, self.keybind_group .. "_key_" .. v[1])
  end

  return self
end

function ASSCropper:enable_key_bindings()
  if not self._keys_bound then
    for k, v in pairs(self._key_binds)  do
      mp.add_forced_key_binding(unpack(v))
    end
    -- Clear "allow-vo-dragging"
    mp.input_enable_section("input_forced_" .. mp.script_name)
    self._keys_bound = true
  end
end

function ASSCropper:disable_key_bindings()
  for k, v in pairs(self._key_binds)  do
    mp.remove_key_binding(v[2]) -- remove by name
  end
  self._keys_bound = false
end


function ASSCropper:finalize_crop()
  if self.current_crop ~= nil then
    local x1, x2 = self.current_crop[1].x, self.current_crop[2].x
    local y1, y2 = self.current_crop[1].y, self.current_crop[2].y

    self.current_crop.x, self.current_crop.y = x1, y1
    self.current_crop.w, self.current_crop.h = x2 - x1, y2 - y1

    if self.options.even_dimensions then
      self.current_crop.w = self.current_crop.w - (self.current_crop.w % 2)
      self.current_crop.h = self.current_crop.h - (self.current_crop.h % 2)
    end

    self.current_crop.x1, self.current_crop.x2 = x1, x1 + self.current_crop.w
    self.current_crop.y1, self.current_crop.y2 = y1, y1 + self.current_crop.h

    self.current_crop[2].x, self.current_crop[2].y = self.current_crop.x2, self.current_crop.y2
  end
end


function ASSCropper:key_event(name)
  if name == "ENTER" then
    self:stop_crop(false)

    self:finalize_crop()

    if self.callback_on_crop == nil then
      mp.set_osd_ass(0,0, "")
    else
      self.callback_on_crop(self.current_crop)
    end

  elseif name == "ESC" then
    self:stop_crop(true)

    if self.callback_on_cancel == nil then
      mp.set_osd_ass(0,0, "")
    else
      self.callback_on_cancel()
    end

  elseif name == "TEST" then
    self:toggle_testing()

  elseif not self.testing_crop then
    if name == "CROP_DETECT" then
      self:toggle_crop_detect()

    elseif name == "CROSSHAIR" then
      self.options.draw_mouse = not self.options.draw_mouse;
    elseif name == "INVERT" then
      self.options.color_invert = not self.options.color_invert;
    elseif name == "GUIDES" then
      self.options.guide_type = (self.options.guide_type + 1) % (self.guide_type_count)
      mp.osd_message(self.guide_type_names[self.options.guide_type])
    elseif self.nudges[name] then
      self:nudge(true, unpack(self.nudges[name]))
    elseif self.resizes[name] then
      self:nudge(false, unpack(self.resizes[name]))
    end
  end
end

function ASSCropper:nudge(keep_size, left, top, right, bottom)
  if self.current_crop == nil then return end

  local x1, y1 = self.current_crop[1].x, self.current_crop[1].y
  local x2, y2 = self.current_crop[2].x, self.current_crop[2].y

  local w, h = x2 - x1, y2 - y1
  if not keep_size then
    w, h = 0, 0

    if self.options.even_dimensions then
      left = left * 2
      top = top * 2
      right = right * 2
      bottom = bottom * 2
    end

  end

  local vw, vh = self.display_state.video.width, self.display_state.video.height

  x1 = math.max(0, math.min(vw-w, x1 + left))
  y1 = math.max(0, math.min(vh-h, y1 + top))

  x2 = math.max(w, math.min(vw, x2 + right))
  y2 = math.max(h, math.min(vh, y2 + bottom))

  local x_offset = math.max(0, 0-x1) - math.max(0, x2-vw)
  local y_offset = math.max(0, 0-y1) - math.max(0, y2-vh)

  x1 = x1 + x_offset
  y1 = y1 + y_offset
  x2 = x2 + x_offset
  y2 = y2 + y_offset

  self.current_crop[1].x, self.current_crop[2].x = order_pair(x1, x2)
  self.current_crop[1].y, self.current_crop[2].y = order_pair(y1, y2)
end

function ASSCropper:blackframe_stop()
  if self.detecting_blackframe then
    self.detecting_blackframe:stop()
    self.detecting_blackframe = nil

    local filters = mp.get_property_native("vf")
    for i, filter in ipairs(filters) do
      if filter.label == self.blackframe_label then
        table.remove(filters, i)
      end
    end
    mp.set_property_native("vf", filters)
  end

end

function ASSCropper:toggle_testing()
  if self.testing_crop then
    self:stop_testing()
  else
    self:start_testing()
  end
end

function ASSCropper:start_testing()
  if not self.testing_crop then

    local cw = self.current_crop and (self.current_crop[2].x - self.current_crop[1].x) or 0
    local ch = self.current_crop and (self.current_crop[2].y - self.current_crop[1].y) or 0

    if cw == 0 or ch == 0 then
      return mp.osd_message("Can't test current crop")
    end

    self:cropdetect_stop()
    self:blackframe_stop()

    local crop_filter = ('@%s:crop=w=%d:h=%d:x=%d:y=%d'):format(
      self.crop_label, cw, ch, self.current_crop[1].x, self.current_crop[1].y
    )
    local ret = mp.commandv('vf', 'add', crop_filter)
    if ret then
      self.testing_crop = true
    end
  end
end

function ASSCropper:stop_testing()
  if self.testing_crop then
    local filters = mp.get_property_native("vf")
    for i, filter in ipairs(filters) do
      if filter.label == self.crop_label then
        table.remove(filters, i)
      end
    end
    mp.set_property_native("vf", filters)
    self.testing_crop = false
  end
end


function ASSCropper:blackframe_check()
  local blackframe_metadata = mp.get_property_native("vf-metadata/" .. self.blackframe_label)
  local black_percentage = tonumber(blackframe_metadata["lavfi.blackframe.pblack"])

  local now = mp.get_time()
  if black_percentage ~= nil and now >= self.blackframe_wait then
    self:blackframe_stop()

    self.options.color_invert = black_percentage < 50
  elseif now > self.blackframe_timeout then
    -- Couldn't get blackframe metadata in time!
    self:blackframe_stop()
  end
end

function ASSCropper:blackframe_start()
  self:blackframe_stop()
  if not self.detecting_blackframe then

    local blackframe_filter = ('@%s:blackframe=amount=%d:threshold=%d'):format(self.blackframe_label, 0, 128)

    local ret = mp.commandv('vf', 'add', blackframe_filter)
    if ret then
      self.blackframe_wait =  mp.get_time() + 0.15
      self.blackframe_timeout =  self.blackframe_wait + 1

      self.detecting_blackframe = mp.add_periodic_timer(1/10, function()
        self:blackframe_check()
      end)
    end
  end
end

function ASSCropper:cropdetect_stop()
  if self.detecting_crop then
    self.detecting_crop:stop()
    self.detecting_crop = nil
    self.cropdetect_wait = nil
    self.cropdetect_timeout = nil

    local filters = mp.get_property_native("vf")
    for i, filter in ipairs(filters) do
      if filter.label == self.cropdetect_label then
        table.remove(filters, i)
      end
    end
    mp.set_property_native("vf", filters)
  end

end

function ASSCropper:cropdetect_check()
  local cropdetect_metadata = mp.get_property_native("vf-metadata/" .. self.cropdetect_label)
  local get_n = function(s) return tonumber(cropdetect_metadata["lavfi.cropdetect." .. s]) end

  local now = mp.get_time()
  if not isempty(cropdetect_metadata) and now >= self.cropdetect_wait then
    self:cropdetect_stop()

    self.current_crop = {
      {x=get_n("x1"), y=get_n("y1")},
      {x=get_n("x2")+1, y=get_n("y2")+1},
    }

    mp.osd_message("Crop detected")
  elseif now > self.cropdetect_timeout then
    mp.osd_message("Crop detect timed out")
    self:cropdetect_stop()
  end
end

function ASSCropper:toggle_crop_detect()
  if self.detecting_crop then
    self:cropdetect_stop()
    mp.osd_message("Cancelled crop detect")

  else
    local cropdetect_filter = ('@%s:cropdetect=limit=%f:round=2:reset=0'):format(self.cropdetect_label, 30/255)

    local ret = mp.commandv('vf', 'add', cropdetect_filter)
    if not ret then
      mp.osd_message("Crop detect failed")
    else
      self.cropdetect_wait = mp.get_time() + 0.2
      self.cropdetect_timeout = self.cropdetect_wait + 1.5

      mp.osd_message("Starting automatic crop detect")
      self.detecting_crop = mp.add_periodic_timer(1/10, function()
        self:cropdetect_check()
      end)
    end
  end
end


function ASSCropper:start_crop(options, on_crop, on_cancel)
  -- Refresh display state
  self.display_state:recalculate_bounds(true)
  if self.display_state.video_ready then
    self.active = true
    self.tick_timer:resume()

    self.options = {}

    for k, v in pairs(self.default_options) do
      self.options[k] = v
    end
    for k, v in pairs(options or {}) do
      self.options[k] = v
    end

    self.callback_on_crop = on_crop
    self.callback_on_cancel = on_cancel

    self.dragging = 0

    self:enable_key_bindings()
    self:update_mouse_position()

    if self.options.auto_invert then
      self:blackframe_start()
    end
  end
end

function ASSCropper:stop_crop(clear)
  self.active = false
  self.tick_timer:stop()

  self:cropdetect_stop()
  self:blackframe_stop()
  self:stop_testing()

  self:disable_key_bindings()
  if clear then
    self.current_crop = nil
  end
end


function ASSCropper:on_tick()
  -- Unused, for debugging
  if self.active then
    self.display_state:recalculate_bounds()
    self:render()
  end
end


function ASSCropper:update_mouse_position()
  -- These are real on-screen coords.
  self.mouse_screen.x, self.mouse_screen.y = mp.get_mouse_pos()

  if self.display_state:recalculate_bounds() and self.display_state.video_ready then
    -- These are on-video coords.
    local mx, my = self.display_state:screen_to_video(self.mouse_screen.x, self.mouse_screen.y)
    self.mouse_video.x = mx
    self.mouse_video.y = my
  end

end


function ASSCropper:get_hitboxes(crop_box)
  crop_box = crop_box or self.current_crop
  if crop_box == nil then
    return nil
  end

  local x1, x2 = order_pair(crop_box[1].x, crop_box[2].x)
  local y1, y2 = order_pair(crop_box[1].y, crop_box[2].y)
  local w, h = math.abs(x2 - x1), math.abs(y2 - y1)

  -- Corner and required corner size in videospace pixels
  local mult = math.min(self.display_state.scale.x, self.display_state.scale.y)
  local videospace_corner_size = self.corner_size * mult
  local videospace_required_size = self.corner_required_size * mult

  local handles_outside = (math.min(w, h) <= videospace_required_size)

  local hitbox_bases = {
    { x1, y2, x1, y2 }, -- BL
    { x1, y2, x2, y2 }, -- B
    { x2, y2, x2, y2 }, -- BR

    { x1, y1, x1, y2 }, -- L
    { x1, y1, x2, y2 }, -- Center
    { x2, y1, x2, y2 }, -- R

    { x1, y1, x1, y1 }, -- TL
    { x1, y1, x2, y1 }, -- T
    { x2, y1, x2, y1 }  -- TR
  }

  local hitbox_mults
  if handles_outside then
    hitbox_mults = {
      {-1,  0,  0,  1},
      { 0,  0,  0,  1},
      { 0,  0,  1,  1},

      {-1,  0,  0,  0},
      { 0,  0,  0,  0},
      { 0,  0,  1,  0},

      {-1, -1,  0,  0},
      { 0, -1,  0,  0},
      { 0, -1,  1,  0}
    }

  else
    hitbox_mults = {
      { 0, -1,  1,  0},
      { 1, -1, -1,  0},
      {-1, -1,  0,  0},

      { 0,  1,  1, -1},
      { 1,  1, -1, -1},
      {-1,  1,  0, -1},

      { 0,  0,  1,  1},
      { 1,  0, -1,  1},
      {-1,  0,  0,  1}
    }
  end


  local hitboxes = {}
  for index, hitbox_base in ipairs(hitbox_bases) do
    local hitbox_mult = hitbox_mults[index]

    hitboxes[index] = {
      hitbox_base[1] + hitbox_mult[1] * videospace_corner_size,
      hitbox_base[2] + hitbox_mult[2] * videospace_corner_size,
      hitbox_base[3] + hitbox_mult[3] * videospace_corner_size,
      hitbox_base[4] + hitbox_mult[4] * videospace_corner_size
    }
  end
  -- Pseudobox to easily pass the original crop box
  hitboxes[10] = {x1, y1, x2, y2}

  return hitboxes
end


function ASSCropper:hit_test(hitboxes, position)
  if hitboxes == nil then
    return 0

  else
    local px, py = position.x, position.y

    for i = 1,9 do
      local hb = hitboxes[i]

      if (px >= hb[1] and px < hb[3]) and (py >= hb[2] and py < hb[4]) then
        return i
      end

    end
    -- No hits
    return 0
  end
end


function ASSCropper:on_mouse(button, event, shift_down)
  if not(event.event == "up" or event.event == "down") then return end
  mouse_down = event.event == "down"
  shift_down = shift_down or false

  if button == "mouse_btn0" and self.active and not self.detecting_crop and not self.testing_crop then

    local mouse_pos = {x=self.mouse_video.x, y=self.mouse_video.y}

    -- Helpers
    local xy_same = function(a, b) return a.x == b.x and a.y == b.y end
    local xy_distance = function(a, b)
      local dx = a.x - b.x
      local dy = a.y - b.y
      return math.sqrt( dx*dx + dy*dy )
    end
    --

    if mouse_down then -- Mouse pressed

      local bound_mouse_pos = {
        x = math.max(0, math.min(self.display_state.video.width, mouse_pos.x)),
        y = math.max(0, math.min(self.display_state.video.height, mouse_pos.y)),
      }

      if self.current_crop == nil then
        self.current_crop = { bound_mouse_pos, bound_mouse_pos }

        self.dragging = 3
        self.anchor_pos = {bound_mouse_pos.x, bound_mouse_pos.y}

        self.crop_ratio = 1
        self.drag_start = bound_mouse_pos

        local handle_pos = self:_get_anchor_positions()[hit]
        self.drag_offset = {0, 0}

        self.restrict_ratio = shift_down

      elseif self.dragging == 0 then
        -- Check if we drag from a handle
        local hitboxes = self:get_hitboxes()
        local hit = self:hit_test(hitboxes, mouse_pos)

        self.dragging = hit
        self.anchor_pos = self:_get_anchor_positions()[10 - hit]

        self.crop_ratio = (hitboxes[10][3] - hitboxes[10][1]) / (hitboxes[10][4] - hitboxes[10][2])
        self.drag_start = mouse_pos

        local handle_pos = self:_get_anchor_positions()[hit] or {mouse_pos.x, mouse_pos.y}
        self.drag_offset = { mouse_pos.x - handle_pos[1], mouse_pos.y - handle_pos[2]}

        self.restrict_ratio = shift_down

        -- Start a new drag if not on handle
        if self.dragging == 0 then
          self.current_crop = { bound_mouse_pos, bound_mouse_pos }
          self.crop_ratio = 1

          self.dragging = 3
          self.anchor_pos = {bound_mouse_pos.x, bound_mouse_pos.y}
          -- self.drag_start = mouse_pos
        end
      end

    else -- Mouse released

      if xy_same(self.current_crop[1], self.current_crop[2]) and xy_distance(self.current_crop[1], mouse_pos) < 5 then
        -- Mouse released after first click - ignore

      elseif self.dragging > 0 then
        -- Adjust current crop
        self.current_crop = self:offset_crop_by_drag()
        self.dragging = 0
      end
    end

  end
end


function ASSCropper:_get_anchor_positions()
  local x1, y1 = self.current_crop[1].x, self.current_crop[1].y
  local x2, y2 = self.current_crop[2].x, self.current_crop[2].y
  return {
    [1] = {x1, y2},
    [2] = {(x1+x2)/2, y2},
    [3] = {x2, y2},

    [4] = {x1, (y1+y2)/2},
    [5] = {(x1+x2)/2, (y1+y2)/2},
    [6] = {x2, (y1+y2)/2},

    [7] = {x1, y1},
    [8] = {(x1+x2)/2, y1},
    [9] = {x2, y1},
  }
end


function ASSCropper:offset_crop_by_drag()
  -- Here be dragons lol
  local vw, vh = self.display_state.video.width, self.display_state.video.height
  local mx, my = self.mouse_video.x, self.mouse_video.y

  local x1, x2 = self.current_crop[1].x, self.current_crop[2].x
  local y1, y2 = self.current_crop[1].y, self.current_crop[2].y

  local anchor_positions = self:_get_anchor_positions()

  local handle = self.dragging
  if handle > 0 then
    local ax, ay = self.anchor_pos[1], self.anchor_pos[2]

    local ox, oy = self.drag_offset[1], self.drag_offset[2]

    local dx, dy = mx - ax - ox, my - ay - oy

    -- Select active corner
    if handle % 2 == 1 and handle ~= 5 then -- Change corners 4/6, 2/8
      handle = (mx - ox < ax) and 1 or 3
      handle = handle +  ( (my - oy < ay) and 6 or 0)
    else -- Change edges 1, 3, 7, 9
      if handle == 4 and mx - ox > ax then
        handle = 6
      elseif handle == 6 and mx - ox < ax then
        handle = 4
      elseif handle == 2 and my - oy < ay then
        handle = 8
      elseif handle == 8 and my - oy > ay then
        handle = 2
      end
    end

    -- Handle booleans for logic
    local h_bot = handle >= 1 and handle <= 3
    local h_top = handle >= 7 and handle <= 9
    local h_left = (handle - 1) % 3 == 0
    local h_right = handle % 3 == 0

    local h_horiz = handle == 4 or handle == 6
    local h_vert = handle == 2 or handle == 8

    -- Keep rect aspect ratio
    if self.restrict_ratio then
      local adx, ady = math.abs(dx), math.abs(dy)

      -- Fit rect to mouse
      local tmpy = adx / self.crop_ratio
      if tmpy < ady then
        adx = ady * self.crop_ratio
      else
        ady = tmpy
      end

      -- Figure out max size for corners, limit adx/ady
      local max_w, max_h = vw, vh

      if h_bot then
        max_h = vh - ay -- Max height is from anchor to video bottom
      elseif h_top then
        max_h = ay      -- Max height is from video bottom to anchor
      elseif h_horiz then
        -- Max height is closest edge * 2
        max_h = math.min(vh - ay, ay) * 2
      end

      if h_left then
        max_w = ax
      elseif h_right then
        max_w = vw - ax
      elseif h_vert then
        max_w = math.min(vw - ax, ax) * 2
      end

      -- Limit size to corners
      if handle ~= 5 then
        -- TODO this can be done tidier?

        -- If wider than max width, scale down
        if adx > max_w then
          adx = max_w
          ady = adx / self.crop_ratio
        end
        -- If taller than max height, scale down
        if ady > max_h then
          ady = max_h
          adx = ady * self.crop_ratio
        end
      end

      -- Hacky offsets
      if handle == 1 then
        dx = -adx
        dy = ady
      elseif handle == 2 then
          dx = adx
        dy = ady
      elseif handle == 3 then
        dx = adx
        dy = ady

      elseif handle == 4 then
        dx = -adx
          dy = ady
      elseif handle == 5 then
        -- pass
      elseif handle == 6 then
        dx = adx
          dy = ady

      elseif handle == 7 then
        dy = -ady
        dx = -adx
      elseif handle == 8 then
          dx = adx
        dy = -ady
      elseif handle == 9 then
        dx = adx
        dy = -ady
      end
    end

    -- Can this be done not-manually?
    -- Re-create the rect with some corners anchored etc
    if handle == 5 then
      -- Simply move the box around
      x1, x2 = x1+dx, x2+dx
      y1, y2 = y1+dy, y2+dy

    elseif handle == 1 then
      x1, x2 = ax + dx, ax
      y1, y2 = ay, ay+dy

    elseif handle == 2 then
      y1, y2 = ay, ay + dy

      if self.restrict_ratio then
        x1, x2 = ax - dx/2, ax + dx/2
      end

    elseif handle == 3 then
      x1, x2 = ax, ax + dx
      y1, y2 = ay, ay + dy

    elseif handle == 4 then
      x1, x2 = ax + dx, ax

      if self.restrict_ratio then
        y1, y2 = ay - dy/2, ay + dy/2
      end

    elseif handle == 6 then
      x1, x2 = ax, ax + dx

      if self.restrict_ratio then
        y1, y2 = ay - dy/2, ay + dy/2
      end


    elseif handle == 7 then
      x1, x2 = ax + dx, ax
      y1, y2 = ay + dy, ay

    elseif handle == 8 then
      y1, y2 = ay + dy, ay

      if self.restrict_ratio then
        x1, x2 = ax - dx/2, ax + dx/2
      end

    elseif handle == 9 then
      x1, x2 = ax, ax + dx
      y1, y2 = ay + dy, ay
    end


    if self.dragging == 5 then
      -- On moving the entire box, we have to figure out how much to "offset" every corner if we go over the edge
      local x_min = math.max(0, 0-x1)
      local y_min = math.max(0, 0-y1)

      local x_max = math.max(0, x2-vw)
      local y_max = math.max(0, y2-vh)

      x1 = x1 + x_min - x_max
      y1 = y1 + y_min - y_max
      x2 = x2 + x_min - x_max
      y2 = y2 + y_min - y_max
    elseif not self.restrict_ratio then
      -- This is already done for restricted ratios, hence the if

      -- Constrict the crop to video space
      -- Since one corner/edge is moved at a time, we can just minmax this
      x1, x2 = math.max(0, x1), math.min(vw, x2)
      y1, y2 = math.max(0, y1), math.min(vh, y2)
    end
  end -- /drag

  if self.dragging > 0 and self.options.even_dimensions then
    local w, h = x2 - x1, y2 - y1
    local even_w = w - (w % 2)
    local even_h = h - (h % 2)

    if handle == 1 or handle == 2 or handle == 3 then
      y2 = y1 + even_h
    elseif handle == 7 or handle == 8 or handle == 9 then
      y1 = y2 - even_h
    end
    if handle == 1 or handle == 4 or handle == 7 then
      x1 = x2 - even_w
    elseif handle == 3 or handle == 6 or handle == 9 then
      x2 = x1 + even_w
    end
  end

  local fx1, fx2 = order_pair(math.floor(x1), math.floor(x2))
  local fy1, fy2 = order_pair(math.floor(y1), math.floor(y2))

  -- msg.info(fx1, fy1, fx2, fy2, handle)

  return { {x=fx1, y=fy1}, {x=fx2, y=fy2} }, handle
end


function order_pair( a, b )
  if a < b then
    return a, b
  else
    return b, a
  end
end


function ASSCropper:render()
  -- For debugging
  local ass_txt = self:get_render_ass()

  local ds = self.display_state
  mp.set_osd_ass(ds.screen.width, ds.screen.height, ass_txt)
end


function ASSCropper:get_render_ass(dim_only)
  if not self.display_state.video_ready then
    msg.info("No video info on display_state")
    return ""
  end

  line_color = self.options.color_invert and 20 or 220
  local guide_format = string.format("{\\3a&HFF&\\3a&H%02X&\\3c&H%02X%02X%02X&\\bord1\\shad0}", 128, line_color, line_color, line_color)

  ass = assdraw.ass_new()
  if self.current_crop then

    if self.testing_crop then
      -- Just draw simple help
      ass:new_event()
      ass:pos(self.display_state.screen.width - 5, 5)
      ass:append( string.format("{\\fs%d\\an%d\\bord2}", self.text_size, 9) )

      local fmt_key = function( key, text ) return string.format("[{\\c&HBEBEBE&}%s{\\c} %s]", key:upper(), text) end

      ass:append(fmt_key("ENTER", "Accept crop") .. " " .. fmt_key("ESC", "Cancel crop") .. '\\N' .. fmt_key("T", "Stop testing"))
      return ass.text
    end

    local temp_crop, drawn_handle = self:offset_crop_by_drag()
    local v_hb = self:get_hitboxes(temp_crop)
    -- Map coords to screen
    local s_hb = {}
    for index, coords in pairs(v_hb) do
      local x1, y1 = self.display_state:video_to_screen(coords[1], coords[2])
      local x2, y2 = self.display_state:video_to_screen(coords[3], coords[4])
      s_hb[index] = {x1, y1, x2, y2}
    end

    -- Full crop
    local v_crop = v_hb[10] -- Video-space
    local s_crop = s_hb[10] -- Screen-space


    -- Inverse clipping for the crop box
    ass:new_event()
    ass:append(string.format("{\\iclip(%d,%d,%d,%d)}", s_crop[1], s_crop[2], s_crop[3], s_crop[4]))

    -- Dim overlay
    local format_dim = string.format("{\\bord0\\1a&H%02X&\\1c&H%02X%02X%02X&}", self.overlay_transparency, self.overlay_lightness, self.overlay_lightness, self.overlay_lightness)
    ass:pos(0,0)
    ass:draw_start()
    ass:append(format_dim)
    ass:rect_cw(0, 0, self.display_state.screen.width, self.display_state.screen.height)
    ass:draw_stop()

    if dim_only then -- Early out with just the dim outline
      return ass.text
    end

    if draw_text then
      -- Text on end
      ass:new_event()
      ass:pos(ce_x, ce_y)
      -- Text align
      local txt_a = ((ce_x > cs_x) and 3 or 1) + ((ce_y > cs_y) and 0 or 6)
      ass:an( txt_a )
      ass:append("{\\fs20\\shad0\\be0\\bord2}")
      ass:append(string.format("%dx%d", math.abs(ce_x-cs_x), math.abs(ce_y-cs_y)) )
    end


    local box_format = string.format("{\\1a&HFF&\\3a&H%02X&\\3c&H%02X%02X%02X&\\bord1}", 0, line_color, line_color, line_color)
    local handle_hilight_format = string.format("{\\1a&H%02X&\\3a&H%02X&\\3c&H%02X%02X%02X&\\bord0}", 230, 0, line_color, line_color, line_color)
    local handle_drag_format = string.format("{\\1a&H%02X&\\3a&H%02X&\\3c&H%02X%02X%02X&\\bord1}", 200, 0, line_color, line_color, line_color)

    -- Main crop box
    ass:new_event()
    ass:pos(0,0)
    ass:append( box_format )
    ass:draw_start()
    ass:rect_cw(s_crop[1], s_crop[2], s_crop[3], s_crop[4])
    ass:draw_stop()

    -- Guide grid, 3x3
    if self.options.guide_type then
      ass:new_event()
      ass:pos(0,0)
      ass:append( guide_format )
      ass:draw_start()

      local w = (s_crop[3] - s_crop[1])
      local h = (s_crop[4] - s_crop[2])

      local w_3rd = w / 3
      local h_3rd = h / 3
      local w_2 = w / 2
      local h_2 = h / 2
      if self.options.guide_type == 1 then
        -- 3x3 grid
        ass:move_to(s_crop[1] + w_3rd, s_crop[2])
        ass:line_to(s_crop[1] + w_3rd, s_crop[4])

        ass:move_to(s_crop[1] + w_3rd*2, s_crop[2])
        ass:line_to(s_crop[1] + w_3rd*2, s_crop[4])

        ass:move_to(s_crop[1], s_crop[2] + h_3rd)
        ass:line_to(s_crop[3], s_crop[2] + h_3rd)

        ass:move_to(s_crop[1], s_crop[2] + h_3rd*2)
        ass:line_to(s_crop[3], s_crop[2] + h_3rd*2)

      elseif self.options.guide_type == 2 then
        -- Top to bottom
        ass:move_to(s_crop[1] + w_2, s_crop[2])
        ass:line_to(s_crop[1] + w_2, s_crop[4])

        -- Left to right
        ass:move_to(s_crop[1], s_crop[2] + h_2)
        ass:line_to(s_crop[3], s_crop[2] + h_2)
      end
      ass:draw_stop()
    end

    if self.dragging > 0 and drawn_handle ~= 5 then
      -- While dragging, draw only the dragging handle
      ass:new_event()
      ass:append( handle_drag_format )
      ass:pos(0,0)
      ass:draw_start()
      ass:rect_cw(s_hb[drawn_handle][1], s_hb[drawn_handle][2], s_hb[drawn_handle][3], s_hb[drawn_handle][4])
      ass:draw_stop()
    elseif self.dragging == 0 then
      local hit_index = self:hit_test(s_hb, self.mouse_screen)
      if hit_index > 0 and hit_index ~= 5 then
        -- Hilight handle
        ass:new_event()
        ass:append( handle_hilight_format )
        ass:pos(0,0)
        ass:draw_start()
        ass:rect_cw(s_hb[hit_index][1], s_hb[hit_index][2], s_hb[hit_index][3], s_hb[hit_index][4])
        ass:draw_stop()
      end

      ass:new_event()
      ass:pos(0,0)
      ass:append( box_format )
      ass:draw_start()

      -- Draw corner handles
      for k, v in pairs({1, 3, 7, 9}) do
        ass:rect_cw(s_hb[v][1], s_hb[v][2], s_hb[v][3], s_hb[v][4])
      end
      ass:draw_stop()
    end

    if true or draw_text then

      local br_pos = {s_crop[3] - 2, s_crop[4] + 2}
      local br_align = 9
      if br_pos[2] >= self.display_state.screen.height - 20 then
        br_pos[2] = br_pos[2] - 4
        br_align = 3
      end

      ass:new_event()
      ass:pos(unpack(br_pos))
      ass:an( br_align )
      ass:append("{\\fs20\\shad0\\be0\\bord2}")
      ass:append(string.format("%dx%d", v_crop[3] - v_crop[1], v_crop[4] - v_crop[2]) )

      local tl_pos = {s_crop[1] + 2, s_crop[2] - 2}
      local tl_align = 1
      if tl_pos[2] < 20 then
        tl_pos[2] = tl_pos[2] + 4
        tl_align = 7
      end

      ass:new_event()
      ass:pos(unpack(tl_pos))
      ass:an( tl_align )
      ass:append("{\\fs20\\shad0\\be0\\bord2}")
      ass:append(string.format("%d,%d", v_crop[1], v_crop[2]))
    end

    ass:draw_stop()
  end

  -- Crosshair for mouse
  if self.options.draw_mouse and not dim_only then
    ass:new_event()
    ass:pos(0,0)
    ass:append( guide_format )
    ass:draw_start()

    ass:move_to(self.mouse_screen.x, 0)
    ass:line_to(self.mouse_screen.x, self.display_state.screen.height)

    ass:move_to(0, self.mouse_screen.y)
    ass:line_to(self.display_state.screen.width, self.mouse_screen.y)

    ass:draw_stop()
  end

  if self.options.draw_help and not dim_only then
    ass:new_event()
    ass:pos(self.display_state.screen.width - 5, 5)
    local text_align = 9
    ass:append( string.format("{\\fs%d\\an%d\\bord2}", self.text_size, text_align) )

    local fmt_key = function( key, text ) return string.format("[{\\c&HBEBEBE&}%s{\\c} %s]", key:upper(), text) end

    local crosshair_txt = self.options.draw_mouse and "Hide" or "Show";
    lines = {
      fmt_key("ENTER", "Accept crop") .. " " .. fmt_key("ESC", "Cancel crop") .. " " .. fmt_key("D", "Autodetect crop") .. " " .. fmt_key("T", "Test crop"),
      fmt_key("SHIFT-Drag", "Constrain ratio") .. " " .. fmt_key("SHIFT-Arrow", "Nudge"),
      fmt_key("C", crosshair_txt .. " crosshair") .. " " .. fmt_key("X", "Cycle guides") .. " " .. fmt_key("Z", "Invert color"),
    }

    local full_line = nil
    for i, line in pairs(lines) do
      if line ~= nil then
        full_line = full_line and (full_line .. "\\N" .. line) or line
      end
    end
    ass:append(full_line)
  end

  return ass.text
end
--[[
  A tool to expand properties in template strings, mimicking mpv's
  property expansion but with a few extras (like formatting times).

  Depends on helpers.lua (isempty)
]]--

local PropertyExpander = {}
PropertyExpander.__index = PropertyExpander

setmetatable(PropertyExpander, {
  __call = function (cls, ...) return cls.new(...) end
})

function PropertyExpander.new(property_source)
  local self = setmetatable({}, PropertyExpander)
  self.sentinel = {}

  -- property_source is a table which defines the following functions:
  -- get_raw_property(name, def) - returns a raw property or def
  -- get_property(name) - returns a string
  -- get_property_osd(name) - returns an OSD formatted string (whatever that'll mean)
  self.property_source = property_source
  return self
end


-- Formats seconds to H:M:S based on a %h-%m-%s format
function PropertyExpander:_format_time(seconds, time_format)
  -- In case "seconds" is not a number, give it back
  if type(seconds) ~= "number" then
    return seconds
  end

  time_format = time_format or "%02h.%02m.%06.3s"

  local types = { h='d', m='d', s='f', S='f', M='d' }
  local values = {
    h=math.floor(seconds / 3600),
    m=math.floor((seconds % 3600) / 60),
    s=(seconds % 60),
    S=seconds,
    M=math.floor((seconds % 1)*1000)
  }

  local substitutor = function(sub_format, char)
    local v = values[char]
    local t = types[char]
    if t == nil then return nil end

    sub_format = '%' .. sub_format .. types[char]
    return v and sub_format:format(v) or nil
  end

  return time_format:gsub('%%([%-%+ #0]*%d*.?%d*)([%a%%])', substitutor)
end

-- Format a date
function PropertyExpander:_format_date(seconds, date_format)
  -- In case "seconds" is not nil or a number, give it back
  if type(seconds) ~= "number" and type(seconds) ~= "nil" then
    return seconds
  end

  --[[
    As stated by Lua docs:
    %a  abbreviated weekday name (e.g., Wed)
    %A  full weekday name (e.g., Wednesday)
    %b  abbreviated month name (e.g., Sep)
    %B  full month name (e.g., September)
    %c  date and time (e.g., 09/16/98 23:48:10)
    %d  day of the month (16) [01-31]
    %H  hour, using a 24-hour clock (23) [00-23]
    %I  hour, using a 12-hour clock (11) [01-12]
    %M  minute (48) [00-59]
    %m  month (09) [01-12]
    %p  either "am" or "pm" (pm)
    %S  second (10) [00-61]
    %w  weekday (3) [0-6 = Sunday-Saturday]
    %x  date (e.g., 09/16/98)
    %X  time (e.g., 23:48:10)
    %Y  full year (1998)
    %y  two-digit year (98) [00-99]
    %%  the character `%´
  ]]--
  date_format = date_format or "%Y-%m-%d %H-%M-%S"
  return os.date(date_format, seconds)
end


function PropertyExpander:expand(format_string)
  local comparisons = {
    {
      -- Less than or equal
      '^(..-)<=(.+)$',
      function(property_value, other_value)
        if type(property_value) ~= "number" then return nil end
        return property_value <= tonumber(other_value)
      end
    },
    {
      -- More than or equal
      '^(..-)>=(.+)$',
      function(property_value, other_value)
        if type(property_value) ~= "number" then return nil end
        return property_value >= tonumber(other_value)
      end
    },
    {
      -- Less than
      '^(..-)<(.+)$',
      function(property_value, other_value)
        if type(property_value) ~= "number" then return nil end
        return property_value < tonumber(other_value)
      end
    },
    {
      -- More than
      '^(..-)>(.+)$',
      function(property_value, other_value)
        if type(property_value) ~= "number" then return nil end
        return property_value > tonumber(other_value)
      end
    },
    {
      -- Equal
      '^(..-)==(.+)$',
      function(property_value, other_value)
        if type(property_value) == "number" then
          other_value = tonumber(other_value)
        elseif type(property_value) ~= "string" then
          -- Ignore booleans and others
          return nil
        end
        return property_value == other_value
      end
    },
    {
      -- Starts with
      '^(..-)^=(.+)$',
      function(property_value, other_value)
        if type(property_value) ~= "string" then return nil end
        return property_value:sub(1, other_value:len()) == other_value
      end
    },
    {
      -- Ends with
      '^(..-)$=(.+)$',
      function(property_value, other_value)
        if type(property_value) ~= "string" then return nil end
        return other_value == '' or property_value:sub(-other_value:len()) == other_value
      end
    },
    {
      -- Contains
      '^(..-)~=(.+)$',
      function(property_value, other_value)
        if type(property_value) ~= "string" then return nil end
        return property_value:find(other_value, nil, true) ~= nil
      end
    },
  }

  local substitutor = function(match)
    local command, inner = match:sub(3, -2):match('^([%?!~^%%#&]?)(.+)$')
    local colon_index = inner:find(':')

    local property_name = inner
    local secondary = ""
    local has_colon = colon_index and true or false

    if colon_index then
      property_name = inner:sub(1, colon_index-1)
      secondary = inner:sub(colon_index+1, -1)
    end

    local used_comparison = nil
    local comparison_value = nil
    for i, comparison in ipairs(comparisons) do
      local name, other_value = property_name:match(comparison[1])
      if name then
        property_name = name
        comparison_value = other_value
        used_comparison = comparison[2]
        break
      end
    end

    local raw_property_value = self.property_source:get_raw_property(property_name, self.sentinel)
    local property_exists = raw_property_value ~= self.sentinel

    if command == '' then
      if used_comparison then
        if used_comparison(raw_property_value, comparison_value) then return self:expand(secondary)
        else return '' end
      end

      -- Return the property value if it's not nil, else the (expanded) secondary
      return property_exists and self.property_source:get_property(property_name) or self:expand(secondary)


    elseif command == '?' then
      -- Return (expanded) secondary if property is truthy (sentinel is falsey)
      if not isempty(raw_property_value) then return self:expand(secondary) else return '' end

    elseif command == '!' then
      if used_comparison then
        if not used_comparison(raw_property_value, comparison_value) then return self:expand(secondary)
        else return '' end
      end

      -- Return (expanded) secondary if property is falsey
      if isempty(raw_property_value) then return self:expand(secondary) else return '' end


    elseif command == '^' then
      -- Return (expanded) secondary if property does not exist
      return not property_exists and self:expand(secondary) or ""


    elseif command == '%' then
      -- Return the value formatted using the secondary string
      return secondary:format(raw_property_value)

    elseif command == '#' then
      -- Format a number to HMS
      return self:_format_time(raw_property_value, has_colon and secondary or nil)

    elseif command == '&' then
      -- Format a date
      return self:_format_date(nil, has_colon and secondary or nil)


    elseif command == '@' then
      -- Format the value for OSD - mostly useful for latching onto mpv's properties
      return property_exists and self.property_source:get_property_osd(property_name) or self:expand(secondary)
    end

  end

  -- Lua patterns are generally a pain, but %b is comfy!
  local expanded = format_string:gsub('%$%b{}', substitutor)
  return expanded
end


local MPVPropertySource = {}
MPVPropertySource.__index = MPVPropertySource

setmetatable(MPVPropertySource, {
  __call = function (cls, ...) return cls.new(...) end
})

function MPVPropertySource.new(values)
  local self = setmetatable({}, MPVPropertySource)
  self.values = values

  return self
end

function MPVPropertySource:get_raw_property(name, default)
  if name:find('mpv/') ~= nil then
    return mp.get_property_native(name:sub(5), default)
  end
  local v = self.values[name]
  if v ~= nil then return v else return default end
end

function MPVPropertySource:get_property(name, default)
  if name:find('mpv/') ~= nil then
    return mp.get_property(name:sub(5), default)
  end
  local v = self.values[name]
  if v ~= nil then return tostring(v) else return default end
end

function MPVPropertySource:get_property_osd(name, default)
  if name:find('mpv/') ~= nil then
    return mp.get_property_osd(name:sub(5), default)
  end
  local v = self.values[name]
  if v ~= nil then return tostring(v) else return default end
end
function script_crop_toggle()
  if asscropper.active then
    asscropper:stop_crop(true)
  else
    local on_crop = function(crop)
      mp.set_osd_ass(0, 0, "")
      screenshot(crop)
    end
    local on_cancel = function()
      mp.osd_message("Crop canceled")
      mp.set_osd_ass(0, 0, "")
    end

    local crop_options = {
      guide_type = ({none=0, grid=1, center=2})[option_values.guide_type],
      draw_mouse = option_values.draw_mouse,
      color_invert = option_values.color_invert,
      auto_invert = option_values.auto_invert
    }
    asscropper:start_crop(crop_options, on_crop, on_cancel)
    if not asscropper.active then
      mp.osd_message("No video to crop!", 2)
    end
  end
end


local next_tick_time = nil
function on_tick_listener()
  local now = mp.get_time()
  if next_tick_time == nil or now >= next_tick_time then
    if asscropper.active and display_state:recalculate_bounds() then
      mp.set_osd_ass(display_state.screen.width, display_state.screen.height, asscropper:get_render_ass())
    end
    next_tick_time = now + (1/60)
  end
end


function expand_output_path(cropbox)
    local filename = mp.get_property_native("filename")
    local playback_time = mp.get_property_native("playback-time")
    local duration = mp.get_property_native("duration")

    local filename_without_ext, extension = filename:match("^(.+)%.(.-)$")

    local properties = {
      path = mp.get_property_native("path"), -- Original path

      filename = filename_without_ext or filename, -- Filename without extension (or filename if no dots
      file_ext = extension or "",                  -- Original extension without leading dot (or empty string)

      pos = mp.get_property_native("playback-time"),

      full = false,
      is_image = (duration == 0 and playback_time == 0),

      crop_w = cropbox.w,
      crop_h = cropbox.h,
      crop_x = cropbox.x,
      crop_y = cropbox.y,
      crop_x2 = cropbox.x2,
      crop_y2 = cropbox.y2,

      unique = 0,

      ext = option_values.output_extension
    }
    local propex = PropertyExpander(MPVPropertySource(properties))


    local test_path = propex:expand(option_values.output_template)
    -- If the paths do not change when incrementing the unique, it's not used.
    -- Return early and avoid the endless loop
    properties.unique = 1
    if propex:expand(option_values.output_template) == test_path then
      properties.full = true
      local temporary_screenshot_path = propex:expand(option_values.output_template)
      return test_path, temporary_screenshot_path

    else
      -- Figure out an unique filename
      while true do
        test_path = propex:expand(option_values.output_template)

        -- Check if filename is free
        if not path_exists(test_path) then
          properties.full = true
          local temporary_screenshot_path = propex:expand(option_values.output_template)
          return test_path, temporary_screenshot_path
        else
          -- Try the next one
          properties.unique = properties.unique + 1
        end
      end
    end
end


function screenshot(crop)
  local size = round_dec(crop.w) .. "x" .. round_dec(crop.h)

  -- Bail on bad crop sizes
  if not (crop.w > 0 and crop.h > 0) then
    mp.osd_message("Bad crop (" .. size .. ")!")
    return
  end

  local output_path, temporary_screenshot_path = expand_output_path(crop)

  -- Optionally create directories
  if option_values.create_directories then
    local paths = {}
    paths[1] = path_utils.dirname(output_path)
    paths[2] = path_utils.dirname(temporary_screenshot_path)

    -- Check if we can read the paths
    for i, path in ipairs(paths) do
      local l, err = utils.readdir(path)
      if err then
        create_directories(path)
      end
    end
  end

  local playback_time = mp.get_property_native("playback-time")
  local duration = mp.get_property_native("duration")

  local input_path = nil

  if option_values.skip_screenshot_for_images and duration == 0 and playback_time == 0 then
    -- Seems to be an image (or at least static file)
    input_path = mp.get_property_native("path")
    temporary_screenshot_path = nil
  else
    -- Not an image, take a temporary screenshot

    -- In case the full-size output path is identical to the crop path,
    -- crudely make it different
    if temporary_screenshot_path == output_path then
      temporary_screenshot_path = temporary_screenshot_path .. "_full.png"
    end

    -- Temporarily lower the PNG compression
    local previous_png_compression = mp.get_property_native("screenshot-png-compression")
    mp.set_property_native("screenshot-png-compression", 0)
    -- Take the screenshot
    mp.commandv("raw", "no-osd", "screenshot-to-file", temporary_screenshot_path)
    -- Return the previous value
    mp.set_property_native("screenshot-png-compression", previous_png_compression)

    if not path_exists(temporary_screenshot_path) then
      msg.error("Failed to take screenshot: " .. temporary_screenshot_path)
      mp.osd_message("Unable to save screenshot")
      return
    end

    input_path = temporary_screenshot_path
  end

  local crop_string = string.format("%d:%d:%d:%d", crop.w, crop.h, crop.x, crop.y)
  local cmd = {
    args = {
    "mpv", input_path,
    "--no-config",
    "--vf=crop=" .. crop_string,
    "--frames=1",
    "--ovc=" .. option_values.output_format,
    "-o", output_path
    }
  }

  msg.info("Cropping: ", crop_string, output_path)
  local ret = utils.subprocess(cmd)

  if not option_values.keep_original and temporary_screenshot_path then
    os.remove(temporary_screenshot_path)
  end

  if ret.error or ret.status ~= 0 then
    mp.osd_message("Screenshot failed, see console for details")
    msg.error("Crop failed! mpv exit code: " .. tostring(ret.status))
    msg.error("mpv stdout:")
    msg.error(ret.stdout)
  else
    msg.info("Crop finished!")
    mp.osd_message("Took screenshot (" .. size .. ")")
    end
end

----------------------
-- Instances, binds --
----------------------

-- Sanity-check output_template
if option_values.warn_about_template and not option_values.output_template:find('%${ext}') then
  msg.warn("Output template missing ${ext}! If this is desired, set warn_about_template=yes in config!")
end

-- Short list of extensions for encoders
local ENCODER_EXTENSION_MAP = {
  png      = "png",
  mjpeg    = "jpg",
  targa    = "tga",
  tiff     = "tiff",
  gif      = "gif", -- please don't
  bmp      = "bmp",
  jpegls   = "jpg",
  ljpeg    = "jpg",
  jpeg2000 = "jp2",
}
-- Pick an extension if one was not provided
if option_values.output_extension == "" then
  local extension = ENCODER_EXTENSION_MAP[option_values.output_format]
  if not extension then
    msg.error("Unrecognized output format '" .. option_values.output_format .. "', unable to pick an extension! Bailing!")
    mp.osd_message("mpv_crop_script was unable to choose an extension, check your config", 3)
  end
  option_values.output_extension = extension
end


display_state = DisplayState()
asscropper = ASSCropper(display_state)
asscropper.overlay_transparency = option_values.overlay_transparency
asscropper.overlay_lightness = option_values.overlay_lightness

asscropper.tick_callback = on_tick_listener
mp.register_event("tick", on_tick_listener)

local used_keybind = SCRIPT_KEYBIND
-- Disable the default keybind if asked to
if option_values.disable_keybind then
  used_keybind = nil
end
mp.add_key_binding(used_keybind, SCRIPT_HANDLER, script_crop_toggle)
