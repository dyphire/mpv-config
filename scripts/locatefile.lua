-- DEBUGGING
--
-- Debug messages will be printed to stdout with mpv command line option
-- `--msg-level='locatefile=debug'`

local msg = require('mp.msg')
local mputils = require('mp.utils')

-- for ubuntu
url_browser_linux_cmd = "xdg-open \"$url\""
file_browser_linux_cmd = "dbus-send --print-reply --dest=org.freedesktop.FileManager1 /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:\"file:$path\" string:\"\""
-- for macos
url_browser_macos_cmd = "open \"$url\""
-- file_browser_macos_cmd = "osascript -e 'tell application \"Finder\"' -e 'set frontmost to true' -e 'reveal (POSIX file \"$path\")' -e 'end tell'"
file_browser_macos_cmd = "open -a Finder -R \"$path\""
-- for windows
url_browser_windows_cmd = "explorer \"$url\""
file_browser_windows_cmd = "explorer /select,\"$path\""

--// check if it's a url/stream
function is_url(path)
  if path ~= nil and string.sub(path,1,4) == "http" then
    return true
  else
    return false
  end
end

--// check if macos
function is_macos()
  local homedir = os.getenv("HOME")
  if homedir ~= nil and string.sub(homedir,1,6) == "/Users" then
    return true
  else
    return false
  end
end

--// check if windows
function is_windows()
  local windir = os.getenv("windir")
  if windir~=nil then
    return true
  else
    return false
  end
end

--// create temporary script
function create_temp_file(content)
  local tmp_filename = os.tmpname()
  local tmp_file = io.open(tmp_filename, "wb")
  tmp_file:write(content)
  io.close(tmp_file)
  return tmp_filename
end

--// path separator stuffs
 function path_sep()
  if is_windows() then
    return "\\"
  else
    return "/"
  end
end
function split_by_separator(filepath)
  local t = {}
  local part_pattern = string.format("([^%s]+)", path_sep())
  for str in filepath:gmatch(part_pattern) do
    table.insert(t, str)
  end
  return t
end
function path_root()
  if path_sep() == "/" then
    return "/"
  else
    return ""
  end
end

--// Extract file dir from url
function normalize(relative_path, base_dir)
  base_dir = base_dir or mputils.getcwd()
  local full_path = mputils.join_path(base_dir, relative_path)

  local parts = split_by_separator(full_path)
  local idx = 1
  repeat
    if parts[idx] == ".." then
      table.remove(parts, idx)
      table.remove(parts, idx - 1)
      idx = idx - 2
    elseif parts[idx] == "." then
      table.remove(parts, idx)
      idx = idx - 1
    end
    idx = idx + 1
  until idx > #parts

  return path_root() .. table.concat(parts, path_sep())
end

--// handle "locate-current-file" function triggered by a key in "input.conf"
function locate_current_file()
  local path = mp.get_property("path")
  if path ~= nil then
    local cmd = ""
    if is_url(path) then
      msg.debug("Url detected '" .. path .. "', your OS web browser will be launched.")
      if is_windows() then
        msg.debug("Windows detected.")
        cmd = url_browser_windows_cmd
      elseif is_macos() then
        msg.debug("macOS detected.")
        cmd = url_browser_macos_cmd
      else
        msg.debug("Linux detected.")
        cmd = url_browser_linux_cmd
      end
      cmd = cmd:gsub("$url", path)
    else
      msg.debug("File detected '" .. path .. "', your OS file browser will be launched.")
      if is_windows() then
        msg.debug("Windows detected.")
        cmd = file_browser_windows_cmd
        path = path:gsub("/", "\\")
      elseif is_macos() then
        msg.debug("macOS detected.")
        cmd = file_browser_macos_cmd
      else
        msg.debug("Linux detected.")
        cmd = file_browser_linux_cmd
      end
      path = normalize(path)
      cmd = cmd:gsub("$path", path)
    end
    msg.debug("Command to be executed: '" .. cmd .. "'")
    mp.osd_message('Browse \n' .. path)
    if is_windows() then
      mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = { 'powershell', '-NoProfile', '-Command', cmd }})
    else os.execute(cmd) end
  else
    msg.debug("'path' property was empty, no media has been loaded.")
  end
end

mp.add_key_binding(nil, "locate-current-file", locate_current_file)
