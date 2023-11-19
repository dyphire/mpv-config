-- This module enables typing a name for playlists when saving them in playlistmanager
-- This module requires playlistmanager to work

local msg = require("mp.msg")

-- reference https://github.com/NurioHin/mpv-bookmarker
local controls = {
  ESC = function() deactivate() end,
  ENTER = function() commit() end,
  BS = function() typer("backspace") end,
  SPACE = function() typer(" ") end
}

local keys = {
  "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
  "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
  "1","2","3","4","5","6","7","8","9","0",
  "!","@","$","%","^","&","*","(",")","-","_","=","+","[","]","{","}","\\","|",";",":","\"",",",".","<",">","/","?","`","~"
}

local illegal_char_set = {}
for _, ch in pairs({"<",">",":","\"","/","\\","|","?","*"}) do
  illegal_char_set[ch] = true
end

local input = ""

function activate()
  for key, func in pairs(controls) do
    mp.add_forced_key_binding(key, "playlist-save-interactive-key-"..key, func, {repeatable=true})
  end
  for i, key in ipairs(keys) do
    mp.add_forced_key_binding(key, "playlist-save-interactive-key-"..key, function() typer(key) end, {repeatable=true})
  end

  local date = os.date("*t")
  input = ("%02d-%02d-%02d_%02d-%02d-%02d"):format(date.year, date.month, date.day, date.hour, date.min, date.sec)
  typer("")
end

function commit()
  deactivate()
  mp.command("script-message playlistmanager save \""..input..".m3u\" \"save playlist with a custom name\"")
end

function deactivate()
  mp.set_osd_ass(0, 0, "")
  for key, _ in pairs(controls) do
    mp.remove_key_binding("playlist-save-interactive-key-"..key)
  end
  for i, key in ipairs(keys) do
    mp.remove_key_binding("playlist-save-interactive-key-"..key)
  end
end

function typer(s)
  if s == "backspace" then
    input = input:sub(1, #input - 1)
  elseif illegal_char_set[s] then
    msg.info("Illegal filename char: "..s)
  else
    input = input..s
  end
  mp.set_osd_ass(0, 0, "Enter playlist name: "..input..".m3u")
end

-- this will be called from playlistmanager
mp.register_script_message("playlistmanager-save-interactive", activate)

-- this will enable the feature in playlistmanager
mp.command("script-message playlistmanager enable-interactive-save \"enable interactive filenaming in playlistmanager\"")
