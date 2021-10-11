local settings = {

  -- #### FUNCTIONALITY SETTINGS

  --navigation keybindings force override only while playlist is visible
  --if "no" then you can display the playlist by any of the navigation keys
  dynamic_binds = true,

  -- to bind multiple keys separate them by a space
  key_moveup = "UP",
  key_movedown = "DOWN",
  key_movepageup = "PGUP",
  key_movepagedown = "PGDWN",
  key_movebegin = "HOME",
  key_moveend = "END",
  key_selectfile = "RIGHT LEFT",
  key_unselectfile = "",
  key_playfile = "ENTER",
  key_removefile = "BS",
  key_closeplaylist = "ESC",

  --replaces matches on filenames based on extension, put as empty string to not replace anything
  --replace rules are executed in provided order
  --replace rule key is the pattern and value is the replace value
  --uses :gsub('pattern', 'replace'), read more http://lua-users.org/wiki/StringLibraryTutorial
  --'all' will match any extension or protocol if it has one
  --uses json and parses it into a lua table to be able to support .conf file

  filename_replace = "",

--[=====[ START OF SAMPLE REPLACE, to use remove start and end line
  --Sample replace: replaces underscore to space on all files
  --for mp4 and webm; remove extension, remove brackets and surrounding whitespace, change dot between alphanumeric to space
  filename_replace = [[
    [
      {
        "ext": { "all": true},
        "rules": [
          { "_" : " " }
        ]
      },{
        "ext": { "mp4": true, "mkv": true },
        "rules": [
          { "^(.+)%..+$": "%1" },
          { "%s*[%[%(].-[%]%)]%s*": "" },
          { "(%w)%.(%w)": "%1 %2" }
        ]
      },{
        "protocol": { "http": true, "https": true },
        "rules": [
          { "^%a+://w*%.?": "" }
        ]
      }
    ]
  ]],
--END OF SAMPLE REPLACE ]=====]

  --json array of filetypes to search from directory
  loadfiles_filetypes = [[
    [
      "jpg", "jpeg", "png", "tif", "tiff", "gif", "webp", "svg", "bmp",
      "mp3", "wav", "ogm", "flac", "m4a", "wma", "ogg", "opus",
      "mkv", "avi", "mp4", "ogv", "webm", "rmvb", "flv", "wmv", "mpeg", "mpg", "m4v", "3gp"
    ]
  ]],

  --loadfiles at startup if there is 0 or 1 items in playlist, if 0 uses worḱing dir for files
  loadfiles_on_start = false,

  --sort playlist on mpv start
  sortplaylist_on_start = false,

  --sort playlist when files are added to playlist
  sortplaylist_on_file_add = false,

  --use alphanumerical sort
  alphanumsort = true,

  --"linux | windows | auto"
  system = "auto",

  --Use ~ for home directory. Leave as empty to use mpv/playlists
  playlist_savepath = "",

  --save playlist automatically after current file was unloaded
  save_playlist_on_file_end = false,


  --show playlist or filename every time a new file is loaded
  --2 shows playlist, 1 shows current file(filename strip applied) as osd text, 0 shows nothing
  --instead of using this you can also call script-message playlistmanager show playlist/filename
  --ex. KEY playlist-next ; script-message playlistmanager show playlist
  show_playlist_on_fileload = 0,

  --sync cursor when file is loaded from outside reasons(file-ending, playlist-next shortcut etc.)
  --has the sideeffect of moving cursor if file happens to change when navigating
  --good side is cursor always following current file when going back and forth files with playlist-next/prev
  sync_cursor_on_load = true,

  --playlist open key will toggle visibility instead of refresh, best used with long timeout
  open_toggles = true,

  --allow the playlist cursor to loop from end to start and vice versa
  loop_cursor = true,


  --####  VISUAL SETTINGS

  --prefer to display titles for following files: "all", "url", "none". Sorting still uses filename.
  prefer_titles = "url",

  --call youtube-dl to resolve the titles of urls in the playlist
  resolve_titles = false,

  --osd timeout on inactivity, with high value on this open_toggles is good to be true
  playlist_display_timeout = 5,

  --amount of entries to show before slicing. Optimal value depends on font/video size etc.
  showamount = 16,

  --font size scales by window, if false requires larger font and padding sizes
  scale_playlist_by_window=true,
  --playlist ass style overrides inside curly brackets, \keyvalue is one field, extra \ for escape in lua
  --example {\\fnUbuntu\\fs10\\b0\\bord1} equals: font=Ubuntu, size=10, bold=no, border=1
  --read http://docs.aegisub.org/3.2/ASS_Tags/ for reference of tags
  --undeclared tags will use default osd settings
  --these styles will be used for the whole playlist
  style_ass_tags = "{}",
  --paddings from top left corner
  text_padding_x = 10,
  text_padding_y = 30,

  --set title of window with stripped name
  set_title_stripped = false,
  title_prefix = "",
  title_suffix = " - mpv",

  --slice long filenames, and how many chars to show
  slice_longfilenames = false,
  slice_longfilenames_amount = 70,

  --Playlist header template
  --%mediatitle or %filename = title or name of playing file
  --%pos = position of playing file
  --%cursor = position of navigation
  --%plen = playlist length
  --%N = newline
  playlist_header = "[%cursor/%plen]",

  --Playlist file templates
  --%pos = position of file with leading zeros
  --%name = title or name of file
  --%N = newline
  --you can also use the ass tags mentioned above. For example:
  --  selected_file="{\\c&HFF00FF&}➔ %name"   | to add a color for selected file. However, if you
  --  use ass tags you need to reset them for every line (see https://github.com/jonniek/mpv-playlistmanager/issues/20)
  normal_file = "○ %name",
  hovered_file = "● %name",
  selected_file = "➔ %name",
  playing_file = "▷ %name",
  playing_hovered_file = "▶ %name",
  playing_selected_file = "➤ %name",


  -- what to show when playlist is truncated
  playlist_sliced_prefix = "...",
  playlist_sliced_suffix = "..."

}
local opts = require("mp.options")
opts.read_options(settings, "playlistmanager", function(list) update_opts(list) end)

local utils = require("mp.utils")
local msg = require("mp.msg")
local assdraw = require("mp.assdraw")


--check os
if settings.system=="auto" then
  local o = {}
  if mp.get_property_native('options/vo-mmcss-profile', o) ~= o then
    settings.system = "windows"
  else
    settings.system = "linux"
  end
end

--global variables
local playlist_visible = false
local strippedname = nil
local path = nil
local directory = nil
local filename = nil
local pos = 0
local plen = 0
local cursor = 0
--table for saved media titles for later if we prefer them
local url_table = {}
-- table for urls that we have request to be resolved to titles
local requested_urls = {}
--state for if we sort on playlist size change
local sort_watching = false

local filetype_lookup = {}

function update_opts(changelog)
  msg.verbose('updating options')

  --parse filename json
  if changelog.filename_replace then
    if(settings.filename_replace~="") then
      settings.filename_replace = utils.parse_json(settings.filename_replace)
    else
      settings.filename_replace = false
    end
  end

  --parse loadfiles json
  if changelog.loadfiles_filetypes then
    settings.loadfiles_filetypes = utils.parse_json(settings.loadfiles_filetypes)

    filetype_lookup = {}
    --create loadfiles set
    for _, ext in ipairs(settings.loadfiles_filetypes) do
      filetype_lookup[ext] = true
    end
  end

  if changelog.resolve_titles then
    resolve_titles()
  end

  if changelog.playlist_display_timeout then
    keybindstimer = mp.add_periodic_timer(settings.playlist_display_timeout, remove_keybinds)
    keybindstimer:kill()
  end

  if playlist_visible then showplaylist() end
end

update_opts({filename_replace = true, loadfiles_filetypes = true})

function on_loaded()
  filename = mp.get_property("filename")
  path = mp.get_property('path')
  --if not a url then join path with working directory
  if not path:match("^%a%a+:%/%/") then
    path = utils.join_path(mp.get_property('working-directory'), path)
    directory = utils.split_path(path)
  else
    directory = nil
  end

  refresh_globals()
  if settings.sync_cursor_on_load then
    cursor=pos
    --refresh playlist if cursor moved
    if playlist_visible then draw_playlist() end
  end

  local media_title = mp.get_property("media-title")
  if path:match('^https?://') and not url_table[path] and path ~= media_title then
    url_table[path] = media_title
  end

  strippedname = stripfilename(mp.get_property('media-title'))
  if settings.show_playlist_on_fileload == 2 then
    showplaylist()
  elseif settings.show_playlist_on_fileload == 1 then
    mp.commandv('show-text', strippedname)
  end
  if settings.set_title_stripped then
    mp.set_property("title", settings.title_prefix..strippedname..settings.title_suffix)
  end

  local didload = false
  if settings.loadfiles_on_start and plen == 1 then
    didload = true --save reference for sorting
    msg.info("Loading files from playing files directory")
    playlist()
  end

  --if we promised to sort files on launch do it
  if promised_sort then
    promised_sort = false
    msg.info("Your playlist is sorted before starting playback")
    if didload then sortplaylist() else sortplaylist(true) end
  end

  --if we promised to listen and sort on playlist size increase do it
  if promised_sort_watch then
    promised_sort_watch = false
    sort_watching = true
    msg.info("Added files will be automatically sorted")
    mp.observe_property('playlist-count', "number", autosort)
  end
end

function on_closed()
  if settings.save_playlist_on_file_end then save_playlist() end
  strippedname = nil
  path = nil
  directory = nil
  filename = nil
  if playlist_visible then showplaylist() end
end

function refresh_globals()
  pos = mp.get_property_number('playlist-pos', 0)
  plen = mp.get_property_number('playlist-count', 0)
end

function escapepath(dir, escapechar)
  return string.gsub(dir, escapechar, '\\'..escapechar)
end

--strip a filename based on its extension or protocol according to rules in settings
function stripfilename(pathfile, media_title)
  if pathfile == nil then return '' end
  local ext = pathfile:match("^.+%.(.+)$")
  local protocol = pathfile:match("^(%a%a+)://")
  if not ext then ext = "" end
  local tmp = pathfile
  if settings.filename_replace and not media_title then
    for k,v in ipairs(settings.filename_replace) do
      if ( v['ext'] and (v['ext'][ext] or (ext and not protocol and v['ext']['all'])) )
      or ( v['protocol'] and (v['protocol'][protocol] or (protocol and not ext and v['protocol']['all'])) ) then
        for ruleindex, indexrules in ipairs(v['rules']) do
          for rule, override in pairs(indexrules) do
            tmp = tmp:gsub(rule, override)
          end
        end
      end
    end
  end
  if settings.slice_longfilenames and tmp:len()>settings.slice_longfilenames_amount+5 then
    tmp = tmp:sub(1, settings.slice_longfilenames_amount).." ..."
  end
  return tmp
end

--gets a nicename of playlist entry at 0-based position i
function get_name_from_index(i, notitle)
  refresh_globals()
  if plen <= i then msg.error("no index in playlist", i, "length", plen); return nil end
  local _, name = nil
  local title = mp.get_property('playlist/'..i..'/title')
  local name = mp.get_property('playlist/'..i..'/filename')

  local should_use_title = settings.prefer_titles == 'all' or name:match('^https?://') and settings.prefer_titles == 'url'
  --check if file has a media title stored or as property
  if not title and should_use_title then
    local mtitle = mp.get_property('media-title')
    if i == pos and mp.get_property('filename') ~= mtitle then
      if not url_table[name] then
        url_table[name] = mtitle
      end
      title = mtitle
    elseif url_table[name] then
      title = url_table[name]
    end
  end

  --if we have media title use a more conservative strip
  if title and not notitle and should_use_title then return stripfilename(title, true) end

  --remove paths if they exist, keeping protocols for stripping
  if string.sub(name, 1, 1) == '/' or name:match("^%a:[/\\]") then
    _, name = utils.split_path(name)
  end
  return stripfilename(name)
end

function parse_header(string)
  local esc_title = stripfilename(mp.get_property("media-title"), true):gsub("%%", "%%%%")
  local esc_file = stripfilename(mp.get_property("filename")):gsub("%%", "%%%%")
  return string:gsub("%%N", "\\N")
               :gsub("%%pos", mp.get_property_number("playlist-pos",0)+1)
               :gsub("%%plen", mp.get_property("playlist-count"))
               :gsub("%%cursor", cursor+1)
               :gsub("%%mediatitle", esc_title)
               :gsub("%%filename", esc_file)
               -- undo name escape
               :gsub("%%%%", "%%")
end

function parse_filename(string, name, index)
  local base = tostring(plen):len()
  local esc_name = stripfilename(name):gsub("%%", "%%%%")
  return string:gsub("%%N", "\\N")
               :gsub("%%pos", string.format("%0"..base.."d", index+1))
               :gsub("%%name", esc_name)
               -- undo name escape
               :gsub("%%%%", "%%")
end

function parse_filename_by_index(index)
  local template = settings.normal_file

  local is_idle = mp.get_property_native('idle-active')
  local position = is_idle and -1 or pos

  if index == position then
    if index == cursor then
      if selection then
        template = settings.playing_selected_file
      else
        template = settings.playing_hovered_file
      end
    else
      template = settings.playing_file
    end
  elseif index == cursor then
    if selection then
      template = settings.selected_file
    else
      template = settings.hovered_file
    end
  end

  return parse_filename(template, get_name_from_index(index), index)
end


function draw_playlist()
  refresh_globals()
  local ass = assdraw.ass_new()
  ass:pos(settings.text_padding_x, settings.text_padding_y)
  ass:new_event()
  ass:append(settings.style_ass_tags)

  if settings.playlist_header ~= "" then
    ass:append(parse_header(settings.playlist_header).."\\N")
  end
  local start = cursor - math.floor(settings.showamount/2)
  local showall = false
  local showrest = false
  if start<0 then start=0 end
  if plen <= settings.showamount then
    start=0
    showall=true
  end
  if start > math.max(plen-settings.showamount-1, 0) then
    start=plen-settings.showamount
    showrest=true
  end
  if start > 0 and not showall then ass:append(settings.playlist_sliced_prefix.."\\N") end
  for index=start,start+settings.showamount-1,1 do
    if index == plen then break end

    ass:append(parse_filename_by_index(index).."\\N")
    if index == start+settings.showamount-1 and not showall and not showrest then
      ass:append(settings.playlist_sliced_suffix)
    end
  end
  local w, h = mp.get_osd_size()
  if settings.scale_playlist_by_window then w,h = 0, 0 end
  mp.set_osd_ass(w, h, ass.text)
end

function toggle_playlist()
  if settings.open_toggles then
    if playlist_visible then
      remove_keybinds()
      return
    end
  end
  showplaylist()
end

function showplaylist(duration)
  refresh_globals()
  if plen == 0 then return end
  playlist_visible = true
  add_keybinds()

  draw_playlist()
  keybindstimer:kill()
  if duration then
    keybindstimer = mp.add_periodic_timer(duration, remove_keybinds)
  else
    keybindstimer:resume()
  end
end

selection=nil
function selectfile()
  refresh_globals()
  if plen == 0 then return end
  if not selection then
    selection=cursor
  else
    selection=nil
  end
  showplaylist()
end

function unselectfile()
  selection=nil
  showplaylist()
end

function removefile()
  refresh_globals()
  if plen == 0 then return end
  selection = nil
  if cursor==pos then mp.command("script-message unseenplaylist mark true \"playlistmanager avoid conflict when removing file\"") end
  mp.commandv("playlist-remove", cursor)
  if cursor==plen-1 then cursor = cursor - 1 end
  showplaylist()
end

function moveup()
  refresh_globals()
  if plen == 0 then return end
  if cursor~=0 then
    if selection then mp.commandv("playlist-move", cursor,cursor-1) end
    cursor = cursor-1
  elseif settings.loop_cursor then
    if selection then mp.commandv("playlist-move", cursor,plen) end
    cursor = plen-1
  end
  showplaylist()
end

function movedown()
  refresh_globals()
  if plen == 0 then return end
  if cursor ~= plen-1 then
    if selection then mp.commandv("playlist-move", cursor,cursor+2) end
    cursor = cursor + 1
  elseif settings.loop_cursor then
    if selection then mp.commandv("playlist-move", cursor,0) end
    cursor = 0
  end
  showplaylist()
end

function movepageup()
  refresh_globals()
  if plen == 0 or cursor == 0 then return end
  local prev_cursor = cursor
  cursor = cursor - settings.showamount
  if cursor < 0 then cursor = 0 end
  if selection then mp.commandv("playlist-move", prev_cursor, cursor) end
  showplaylist()
end

function movepagedown()
  refresh_globals()
  if plen == 0 or cursor == plen-1 then return end
  local prev_cursor = cursor
  cursor = cursor + settings.showamount
  if cursor >= plen then cursor = plen-1 end
  if selection then mp.commandv("playlist-move", prev_cursor, cursor+1) end
  showplaylist()
end

function movebegin()
  refresh_globals()
  if plen == 0 or cursor == 0 then return end
  local prev_cursor = cursor
  cursor = 0
  if selection then mp.commandv("playlist-move", prev_cursor, cursor) end
  showplaylist()
end

function moveend()
  refresh_globals()
  if plen == 0 or cursor == plen-1 then return end
  local prev_cursor = cursor
  cursor = plen-1
  if selection then mp.commandv("playlist-move", prev_cursor, cursor+1) end
  showplaylist()
end

function write_watch_later(force_write)
  if mp.get_property_bool("save-position-on-quit") or force_write then
    mp.command("write-watch-later-config")
  end
end

function playlist_next(force_write)
  write_watch_later(force_write)
  mp.commandv("playlist-next", "weak")
end

function playlist_prev(force_write)
  write_watch_later(force_write)
  mp.commandv("playlist-prev", "weak")
end

function playfile()
  refresh_globals()
  if plen == 0 then return end
  selection = nil
  local is_idle = mp.get_property_native('idle-active')
  if cursor ~= pos or is_idle then
    write_watch_later()
    mp.set_property("playlist-pos", cursor)
  else
    if cursor~=plen-1 then
      cursor = cursor + 1
    end
    write_watch_later()
    mp.commandv("playlist-next", "weak")
  end
  if settings.show_playlist_on_fileload ~= 2 then
    remove_keybinds()
  end
end

function get_files_windows(dir)
  local args = {
    'powershell', '-NoProfile', '-Command', [[& {
          Trap {
              Write-Error -ErrorRecord $_
              Exit 1
          }
          $path = "]]..dir..[["
          $escapedPath = [WildcardPattern]::Escape($path)
          cd $escapedPath

          $list = (Get-ChildItem -File | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(20) }) }).Name
          $string = ($list -join "/")
          $u8list = [System.Text.Encoding]::UTF8.GetBytes($string)
          [Console]::OpenStandardOutput().Write($u8list, 0, $u8list.Length)
      }]]
  }
  local process = utils.subprocess({ args = args, cancellable = false })
  return parse_files(process, '%/')
end

function get_files_linux(dir)
  local args = { 'ls', '-1pv', dir }
  local process = utils.subprocess({ args = args, cancellable = false })
  return parse_files(process, '\n')
end

function parse_files(res, delimiter)
  if not res.error and res.status == 0 then
    local valid_files = {}
    for line in res.stdout:gmatch("[^"..delimiter.."]+") do
      local ext = line:match("^.+%.(.+)$")
      if ext and filetype_lookup[ext:lower()] then
        table.insert(valid_files, line)
      end
    end
    return valid_files, nil
  else
    return nil, res.error
  end
end

--Creates a playlist of all files in directory, will keep the order and position
--For exaple, Folder has 12 files, you open the 5th file and run this, the remaining 7 are added behind the 5th file and prior 4 files before it
function playlist(force_dir)
  refresh_globals()
  if not directory and plen > 0 then return end
  local hasfile = true
  if plen == 0 then
    hasfile = false
    dir = mp.get_property('working-directory')
  else
    dir = directory
  end
  if force_dir then dir = force_dir end

  local files, error
  if settings.system == "linux" then
    files, error = get_files_linux(dir)
  else
    files, error = get_files_windows(dir)
  end

  local c, c2 = 0,0
  if files then
    local cur = false
    local filename = mp.get_property("filename")
    for _, file in ipairs(files) do
      local appendstr = "append"
      if not hasfile then
        cur = true
        appendstr = "append-play"
        hasfile = true
      end
      if cur == true then
        mp.commandv("loadfile", utils.join_path(dir, file), appendstr)
        msg.info("Appended to playlist: " .. file)
        c2 = c2 + 1
      elseif file ~= filename then
          mp.commandv("loadfile", utils.join_path(dir, file), appendstr)
          msg.info("Prepended to playlist: " .. file)
          mp.commandv("playlist-move", mp.get_property_number("playlist-count", 1)-1,  c)
          c = c + 1
      else
        cur = true
      end
    end
    if c2 > 0 or c>0 then
      mp.osd_message("Added "..c + c2.." files to playlist")
    else
      mp.osd_message("No additional files found")
    end
    cursor = mp.get_property_number('playlist-pos', 1)
  else
    msg.error("Could not scan for files: "..(error or ""))
  end
  if sort_watching then
    msg.info("Ignoring directory structure and using playlist sort")
    sortplaylist()
  end
  refresh_globals()
  if playlist_visible then showplaylist() end
  return c + c2
end

function parse_home(path)
  if not path:find("^~") then
    return path
  end
  local home_dir = os.getenv("HOME") or os.getenv("USERPROFILE")
  if not home_dir then
    local drive = os.getenv("HOMEDRIVE")
    local path = os.getenv("HOMEPATH")
    if drive and path then
      home_dir = utils.join_path(drive, path)
    else
      msg.error("Couldn't find home dir.")
      return nil
    end
  end
  local result = path:gsub("^~", home_dir)
  return result
end

--saves the current playlist into a m3u file
function save_playlist()
  local length = mp.get_property_number('playlist-count', 0)
  if length == 0 then return end

  --get playlist save path
  local savepath
  if settings.playlist_savepath == nil or settings.playlist_savepath == "" then
    savepath = mp.command_native({"expand-path", "~~home/"}).."/playlists"
  else
    savepath = parse_home(settings.playlist_savepath)
    if savepath == nil then return end
  end

  --create savepath if it doesn't exist
  if utils.readdir(savepath) == nil then
    local windows_args = {'powershell', '-NoProfile', '-Command', 'mkdir', savepath}
    local unix_args = { 'mkdir', savepath }
    local args = settings.system == 'windows' and windows_args or unix_args
    local res = utils.subprocess({ args = args, cancellable = false })
    if res.status ~= 0 then
      msg.error("Failed to create playlist save directory "..savepath..". Error: "..(res.error or "unknown"))
      return
    end
  end

  local date = os.date("*t")
  local datestring = ("%02d-%02d-%02d_%02d-%02d-%02d"):format(date.year, date.month, date.day, date.hour, date.min, date.sec)

  local savepath = utils.join_path(savepath, datestring.."_playlist-size_"..length..".m3u")
  local file, err = io.open(savepath, "w")
  if not file then
    msg.error("Error in creating playlist file, check permissions. Error: "..(err or "unknown"))
  else
    local i=0
    while i < length do
      local pwd = mp.get_property("working-directory")
      local filename = mp.get_property('playlist/'..i..'/filename')
      local fullpath = filename
      if not filename:match("^%a%a+:%/%/") then
        fullpath = utils.join_path(pwd, filename)
      end
      local title = mp.get_property('playlist/'..i..'/title')
      if title then file:write("#EXTINF:,"..title.."\n") end
      file:write(fullpath, "\n")
      i=i+1
    end
    msg.info("Playlist written to: "..savepath)
    file:close()
  end
end

function alphanumsort(a, b)
  local function padnum(d)
    local dec, n = string.match(d, "(%.?)0*(.+)")
    return #dec > 0 and ("%.12f"):format(d) or ("%s%03d%s"):format(dec, #n, n)
  end
  return tostring(a):lower():gsub("%.?%d+",padnum)..("%3d"):format(#b)
       < tostring(b):lower():gsub("%.?%d+",padnum)..("%3d"):format(#a)
end

function dosort(a,b)
  if settings.alphanumsort then
    return alphanumsort(a,b)
  else
    return a < b
  end
end

function sortplaylist(startover)
  local length = mp.get_property_number('playlist-count', 0)
  if length < 2 then return end
  --use insertion sort on playlist to make it easy to order files with playlist-move
  for outer=1, length-1, 1 do
    local outerfile = get_name_from_index(outer, true)
    local inner = outer - 1
    while inner >= 0 and dosort(outerfile, get_name_from_index(inner, true)) do
      inner = inner - 1
    end
    inner = inner + 1
    if outer ~= inner then
      mp.commandv('playlist-move', outer, inner)
    end
  end
  cursor = mp.get_property_number('playlist-pos', 0)
  if startover then
    mp.set_property('playlist-pos', 0)
  end
  if playlist_visible then showplaylist() end
end

function autosort(name, param)
  if param == 0 then return end
  if plen < param then
    msg.info("Playlistmanager autosorting playlist")
    refresh_globals()
    sortplaylist()
  end
end

function reverseplaylist()
  local length = mp.get_property_number('playlist-count', 0)
  if length < 2 then return end
  for outer=1, length-1, 1 do
    mp.commandv('playlist-move', outer, 0)
  end
  if playlist_visible then showplaylist() end
end

function shuffleplaylist()
  refresh_globals()
  if plen < 2 then return end
  mp.command("playlist-shuffle")
  math.randomseed(os.time())
  mp.commandv("playlist-move", pos, math.random(0, plen-1))
  mp.set_property('playlist-pos', 0)
  refresh_globals()
  if playlist_visible then showplaylist() end
end

function bind_keys(keys, name, func, opts)
  if not keys then
    mp.add_forced_key_binding(keys, name, func, opts)
    return
  end
  local i = 1
  for key in keys:gmatch("[^%s]+") do
    local prefix = i == 1 and '' or i
    mp.add_forced_key_binding(key, name..prefix, func, opts)
    i = i + 1
  end
end

function unbind_keys(keys, name)
  if not keys then
    mp.remove_key_binding(name)
    return
  end
  local i = 1
  for key in keys:gmatch("[^%s]+") do
    local prefix = i == 1 and '' or i
    mp.remove_key_binding(name..prefix)
    i = i + 1
  end
end

function add_keybinds()
  bind_keys(settings.key_moveup, 'moveup', moveup, "repeatable")
  bind_keys(settings.key_movedown, 'movedown', movedown, "repeatable")
  bind_keys(settings.key_movepageup, 'movepageup', movepageup, "repeatable")
  bind_keys(settings.key_movepagedown, 'movepagedown', movepagedown, "repeatable")
  bind_keys(settings.key_movebegin, 'movebegin', movebegin, "repeatable")
  bind_keys(settings.key_moveend, 'moveend', moveend, "repeatable")
  bind_keys(settings.key_selectfile, 'selectfile', selectfile)
  bind_keys(settings.key_unselectfile, 'unselectfile', unselectfile)
  bind_keys(settings.key_playfile, 'playfile', playfile)
  bind_keys(settings.key_removefile, 'removefile', removefile, "repeatable")
  bind_keys(settings.key_closeplaylist, 'closeplaylist', remove_keybinds)
end

function remove_keybinds()
  keybindstimer:kill()
  keybindstimer = mp.add_periodic_timer(settings.playlist_display_timeout, remove_keybinds)
  keybindstimer:kill()
  mp.set_osd_ass(0, 0, "")
  playlist_visible = false
  if settings.dynamic_binds then
    unbind_keys(settings.key_moveup, 'moveup')
    unbind_keys(settings.key_movedown, 'movedown')
    unbind_keys(settings.key_movepageup, 'movepageup')
    unbind_keys(settings.key_movepagedown, 'movepagedown')
    unbind_keys(settings.key_movebegin, 'movebegin')
    unbind_keys(settings.key_moveend, 'moveend')
    unbind_keys(settings.key_selectfile, 'selectfile')
    unbind_keys(settings.key_unselectfile, 'unselectfile')
    unbind_keys(settings.key_playfile, 'playfile')
    unbind_keys(settings.key_removefile, 'removefile')
    unbind_keys(settings.key_closeplaylist, 'closeplaylist')
  end
end

keybindstimer = mp.add_periodic_timer(settings.playlist_display_timeout, remove_keybinds)
keybindstimer:kill()

if not settings.dynamic_binds then
  add_keybinds()
end

if settings.loadfiles_on_start and mp.get_property_number('playlist-count', 0) == 0 then
  playlist()
end

promised_sort_watch = false
if settings.sortplaylist_on_file_add then
  promised_sort_watch = true
end

promised_sort = false
if settings.sortplaylist_on_start then
  promised_sort = true
end

mp.observe_property('playlist-count', "number", function()
  if playlist_visible then showplaylist() end
  if settings.prefer_titles == 'none' then return end
  -- resolve titles
  resolve_titles()
end)

--resolves url titles by calling youtube-dl
function resolve_titles()
  if not settings.resolve_titles then return end
  local length = mp.get_property_number('playlist-count', 0)
  if length < 2 then return end
  local i=0
  -- loop all items in playlist because we can't predict how it has changed
  while i < length do
    local filename = mp.get_property('playlist/'..i..'/filename')
    local title = mp.get_property('playlist/'..i..'/title')
    if i ~= pos
      and filename
      and filename:match('^https?://')
      and not title
      and not url_table[filename]
      and not requested_urls[filename]
    then
      requested_urls[filename] = true

      local args = { 'youtube-dl', '--no-playlist', '--flat-playlist', '-sJ', filename }
      local req = mp.command_native_async(
        {
          name = "subprocess",
          args = args,
          playback_only = false,
          capture_stdout = true
        }, function (success, res)
            if res.killed_by_us then
              msg.verbose('Request to resolve url title ' .. filename .. ' timed out')
              return
            end
            if res.status == 0 then
              local json, err = utils.parse_json(res.stdout)
              if not err then
                local is_playlist = json['_type'] and json['_type'] == 'playlist'
                local title = (is_playlist and '[playlist]: ' or '') .. json['title']
                msg.verbose(filename .. " resolved to '" .. title .. "'")
                url_table[filename] = title
                refresh_globals()
                if playlist_visible then showplaylist() end
                return
              else
                msg.error("Failed parsing json, reason: "..(err or "unknown"))
              end
            else
              msg.error("Failed to resolve url title "..filename.." Error: "..(res.error or "unknown"))
            end
          end)

      mp.add_timeout(5, function()
        mp.abort_async_command(req)
      end)

    end
    i=i+1
  end
end

--script message handler
function handlemessage(msg, value, value2)
  if msg == "show" and value == "playlist" then
    if value2 ~= "toggle" then
      showplaylist(value2)
      return
    else
      toggle_playlist()
      return
    end
  end
  if msg == "show" and value == "filename" and strippedname and value2 then
    mp.commandv('show-text', strippedname, tonumber(value2)*1000 ) ; return
  end
  if msg == "show" and value == "filename" and strippedname then
    mp.commandv('show-text', strippedname ) ; return
  end
  if msg == "sort" then sortplaylist(value) ; return end
  if msg == "shuffle" then shuffleplaylist() ; return end
  if msg == "reverse" then reverseplaylist() ; return end
  if msg == "loadfiles" then playlist(value) ; return end
  if msg == "save" then save_playlist() ; return end
  if msg == "playlist-next" then playlist_next(true) ; return end
  if msg == "playlist-prev" then playlist_prev(true) ; return end
end

mp.register_script_message("playlistmanager", handlemessage)

mp.add_key_binding("CTRL+p", "sortplaylist", sortplaylist)
mp.add_key_binding("CTRL+P", "shuffleplaylist", shuffleplaylist)
mp.add_key_binding("CTRL+R", "reverseplaylist", reverseplaylist)
mp.add_key_binding("P", "loadfiles", playlist)
mp.add_key_binding("p", "saveplaylist", save_playlist)
mp.add_key_binding("SHIFT+ENTER", "showplaylist", toggle_playlist)

mp.register_event("file-loaded", on_loaded)
mp.register_event("end-file", on_closed)
