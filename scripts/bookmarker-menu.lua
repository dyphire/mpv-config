-- // Bookmarker Menu v1.3.1 for mpv \\ --
-- See README.md for instructions

-- Maximum number of characters for bookmark name
local maxChar = 100
-- Number of bookmarks to be displayed per page
local bookmarksPerPage = 10
-- Whether to close the Bookmarker menu after loading a bookmark
local closeAfterLoad = true
-- Whether to close the Bookmarker menu after replacing a bookmark
local closeAfterReplace = true
-- Whether to ask for confirmation to replace a bookmark (Uses the Typer for confirmation)
local confirmReplace = false
-- Whether to ask for confirmation to delete a bookmark (Uses the Typer for confirmation)
local confirmDelete = false
-- The rate (in seconds) at which the bookmarker needs to refresh its interface; lower is more frequent
local rate = 1.5
-- The filename for the bookmarks file
local bookmarkerName = "bookmarker.json"

-- All the "global" variables and utilities; don't touch these
local utils = require 'mp.utils'
local styleOn = mp.get_property("osd-ass-cc/0")
local styleOff = mp.get_property("osd-ass-cc/1")
local bookmarks = {}
local currentSlot = 0
local currentPage = 1
local maxPage = 1
local active = false
local mode = "none"
local bookmarkStore = {}
local oldSlot = 0

-- // Controls \\ --

-- List of custom controls and their function
local bookmarkerControls = {
  ESC = function() abort("") end,
  DOWN = function() jumpSlot(1) end,
  UP = function() jumpSlot(-1) end,
  RIGHT = function() jumpPage(1) end,
  LEFT = function() jumpPage(-1) end,
  s = function() addBookmark() end,
  S = function() mode="save" typerStart() end,
  p = function() mode="replace" typerStart() end,
  r = function() mode="rename" typerStart() end,
  f = function() mode="filepath" typerStart() end,
  m = function() mode="move" moverStart() end,
  DEL = function() mode="delete" typerStart() end,
  ENTER = function() jumpToBookmark(currentSlot) end,
  KP_ENTER = function() jumpToBookmark(currentSlot) end
}

local bookmarkerFlags = {
  DOWN = {repeatable = true},
  UP = {repeatable = true},
  RIGHT = {repeatable = true},
  LEFT = {repeatable = true}
}

-- Activate the custom controls
function activateControls(name, controls, flags)
  for key, func in pairs(controls) do
    mp.add_forced_key_binding(key, name..key, func, flags[key])
  end
end

-- Deactivate the custom controls
function deactivateControls(name, controls)
  for key, _ in pairs(controls) do
    mp.remove_key_binding(name..key)
  end
end

-- // Typer \\ --

-- Controls for the Typer
local typerControls = {
  ESC = function() typerExit() end,
  ENTER = function() typerCommit() end,
  KP_ENTER = function() typerCommit() end,
  RIGHT = function() typerCursor(1) end,
  LEFT = function() typerCursor(-1) end,
  BS = function() typer("backspace") end,
  DEL = function() typer("delete") end,
  SPACE = function() typer(" ") end,
  SHARP = function() typer("#") end,
  KP0 = function() typer("0") end,
  KP1 = function() typer("1") end,
  KP2 = function() typer("2") end,
  KP3 = function() typer("3") end,
  KP4 = function() typer("4") end,
  KP5 = function() typer("5") end,
  KP6 = function() typer("6") end,
  KP7 = function() typer("7") end,
  KP8 = function() typer("8") end,
  KP9 = function() typer("9") end,
  KP_DEC = function() typer(".") end
}

-- All standard keys for the Typer
local typerKeys = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","1","2","3","4","5","6","7","8","9","0","!","@","$","%","^","&","*","(",")","-","_","=","+","[","]","{","}","\\","|",";",":","'","\"",",",".","<",">","/","?","`","~"}
-- For some reason, semicolon is not possible, but it's listed there just in case anyway

local typerText = ""
local typerPos = 0
local typerActive = false

-- Function to activate the Typer
-- use typerStart() for custom controls around activating the Typer
function activateTyper()
  for key, func in pairs(typerControls) do
    mp.add_forced_key_binding(key, "typer"..key, func, {repeatable=true})
  end
  for i, key in ipairs(typerKeys) do
    mp.add_forced_key_binding(key, "typer"..key, function() typer(key) end, {repeatable=true})
  end
  typerText = ""
  typerActive = true
end

-- Function to deactivate the Typer
-- use typerExit() for custom controls around deactivating the Typer
function deactivateTyper()
  for key, _ in pairs(typerControls) do
    mp.remove_key_binding("typer"..key)
  end
  for i, key in ipairs(typerKeys) do
    mp.remove_key_binding("typer"..key)
  end
  typerActive = false
  return typerText
end

-- Function to move the cursor of the typer; can wrap around
function typerCursor(direction)
  typerPos = typerPos + direction
  if typerPos < 0 then typerPos = typerText:len() end
  if typerPos > typerText:len() then typerPos = 0 end
  typer("")
end

-- Function for handling the text as it is being typed
function typer(s)
  -- Don't touch this part
  if s == "backspace" then
    if typerPos > 0 then
      typerText = typerText:sub(1, typerPos - 1) .. typerText:sub(typerPos + 1)
      typerPos = typerPos - 1
    end
  elseif s == "delete" then
    if typerPos < typerText:len() then
      typerText = typerText:sub(1, typerPos) .. typerText:sub(typerPos + 2)
    end
  else
    if mode == "filepath" or typerText:len() < maxChar then
      typerText = typerText:sub(1, typerPos) .. s .. typerText:sub(typerPos + 1)
      typerPos = typerPos + s:len()
    end
  end

  -- Enter custom script and display message here
  local preMessage = "Enter a bookmark name:"
  if mode == "save" then
    preMessage = styleOn.."{\\b1}Save a new bookmark with custom name:{\\b0}"..styleOff
  elseif mode == "replace" then
    preMessage = styleOn.."{\\b1}Type \"y\" to replace the following bookmark:{\\b0}\n"..displayName(bookmarks[currentSlot]["name"])..styleOff
  elseif mode == "delete" then
    preMessage = styleOn.."{\\b1}Type \"y\" to delete the following bookmark:{\\b0}\n"..displayName(bookmarks[currentSlot]["name"])..styleOff
  elseif mode == "rename" then
    preMessage = styleOn.."{\\b1}Rename an existing bookmark:{\\b0}"..styleOff
  elseif mode == "filepath" then
    preMessage = styleOn.."{\\b1}Change the bookmark's filepath:{\\b0}"..styleOff
  end

  local postMessage = ""
  local split = typerPos + math.floor(typerPos / maxChar)
  local messageLines = math.floor((typerText:len() - 1) / maxChar) + 1
  for i = 1, messageLines do
    postMessage = postMessage .. typerText:sub((i-1) * maxChar + 1, i * maxChar) .. "\n"
  end
  postMessage = postMessage:sub(1,postMessage:len()-1)

  mp.osd_message(preMessage.."\n"..postMessage:sub(1,split)..styleOn.."{\\c&H00FFFF&}{\\b1}|{\\r}"..styleOff..postMessage:sub(split+1), 9999)
end

-- // Mover \\ --

-- Controls for the Mover
local moverControls = {
  ESC = function() moverExit() end,
  DOWN = function() jumpSlot(1) end,
  UP = function() jumpSlot(-1) end,
  RIGHT = function() jumpPage(1) end,
  LEFT = function() jumpPage(-1) end,
  s = function() addBookmark() end,
  m = function() moverCommit() end,
  ENTER = function() moverCommit() end,
  KP_ENTER = function() moverCommit() end
}

local moverFlags = {
  DOWN = {repeatable = true},
  UP = {repeatable = true},
  RIGHT = {repeatable = true},
  LEFT = {repeatable = true}
}

-- Function to activate the Mover
function moverStart()
  if bookmarkExists(currentSlot) then
    deactivateControls("bookmarker", bookmarkerControls)
    activateControls("mover", moverControls, moverFlags)
    displayBookmarks()
  else
    abort(styleOn.."{\\c&H0000FF&}{\\b1}Can't find the bookmark at slot "..currentSlot)
  end
end

-- Function to commit the action of the Mover
function moverCommit()
  saveBookmarks()
  moverExit()
end

-- Function to deactivate the Mover
-- If isError is set, then it'll abort
function moverExit(isError)
  deactivateControls("mover", moverControls)
  mode = "none"
  if not isError then
    loadBookmarks()
    displayBookmarks()
    activateControls("bookmarker", bookmarkerControls, bookmarkerFlags)
  end
end

-- // General utilities \\ --

-- Check if the operating system is Mac OS
function isMacOS()
  local homedir = os.getenv("HOME")
  return (homedir ~= nil and string.sub(homedir,1,6) == "/Users")
end

-- Check if the operating system is Windows
function isWindows()
  local windir = os.getenv("windir")
  return (windir~=nil)
end

-- Check whether a certain file exists
function fileExists(path)
  local f = io.open(path,"r")
  if f~=nil then
    io.close(f)
    return true
  else
    return false
  end
end

-- Get the filepath of a file from the mpv config folder
function getFilepath(filename)
  if isWindows() then
  	return os.getenv("APPDATA"):gsub("\\", "/") .. "/mpv/" .. filename
  else	
	return os.getenv("HOME") .. "/.config/mpv/" .. filename
  end
end

-- Load a table from a JSON file
-- Returns nil if the file can't be found
function loadTable(path)
  local contents = ""
  local myTable = {}
  local file = io.open( path, "r" )
  if file then
    local contents = file:read( "*a" )
    myTable = utils.parse_json(contents);
    io.close(file)
    return myTable
  end
  return nil
end

-- Save a table as a JSON file file
-- Returns true if successful
function saveTable(t, path)
  local contents = utils.format_json(t)
  local file = io.open(path .. ".tmp", "wb")
  file:write(contents)
  io.close(file)
  os.remove(path)
  os.rename(path .. ".tmp", path)
  return true
end

-- Convert a pos (seconds) to a hh:mm:ss.mmm format
function parseTime(pos)
  local hours = math.floor(pos/3600)
  local minutes = math.floor((pos % 3600)/60)
  local seconds = math.floor((pos % 60))
  local milliseconds = math.floor(pos % 1 * 1000)
  return string.format("%02d:%02d:%02d.%03d",hours,minutes,seconds,milliseconds)
end

-- // Bookmark functions \\ --

-- Checks whether the specified bookmark exists
function bookmarkExists(slot)
  return (slot >= 1 and slot <= #bookmarks)
end

-- Calculates the current page and the total number of pages
function calcPages()
  currentPage = math.floor((currentSlot - 1) / bookmarksPerPage) + 1
  if currentPage == 0 then currentPage = 1 end
  maxPage = math.floor((#bookmarks - 1) / bookmarksPerPage) + 1
  if maxPage == 0 then maxPage = 1 end
end

-- Get the amount of bookmarks on the specified page
function getAmountBookmarksOnPage(page)
  local n = bookmarksPerPage
  if page == maxPage then n = #bookmarks % bookmarksPerPage end
  if n == 0 then n = bookmarksPerPage end
  if #bookmarks == 0 then n = 0 end
  return n
end

-- Get the index of the first slot on the specified page
function getFirstSlotOnPage(page)
  return (page - 1) * bookmarksPerPage + 1
end

-- Get the index of the last slot on the specified page
function getLastSlotOnPage(page)
  local endSlot = getFirstSlotOnPage(page) + getAmountBookmarksOnPage(page) - 1
  if endSlot > #bookmarks then endSlot = #bookmarks end
  return endSlot
end

-- Jumps a certain amount of slots forward or backwards in the bookmarks list
-- Keeps in mind if the current mode is to move bookmarks
function jumpSlot(i)
  if mode == "move" then
    oldSlot = currentSlot
    bookmarkStore = bookmarks[oldSlot]
  end

  currentSlot = currentSlot + i
  local startSlot = getFirstSlotOnPage(currentPage)
  local endSlot = getLastSlotOnPage(currentPage)

  if currentSlot < startSlot then currentSlot = endSlot end
  if currentSlot > endSlot then currentSlot = startSlot end

  if mode == "move" then
    table.remove(bookmarks, oldSlot)
    table.insert(bookmarks, currentSlot, bookmarkStore)
  end

  displayBookmarks()
end

-- Jumps a certain amount of pages forward or backwards in the bookmarks list
-- Keeps in mind if the current mode is to move bookmarks
function jumpPage(i)
  if mode == "move" then
    oldSlot = currentSlot
    bookmarkStore = bookmarks[oldSlot]
  end

  local oldPos = currentSlot - getFirstSlotOnPage(currentPage) + 1
  currentPage = currentPage + i
  if currentPage < 1 then currentPage = maxPage + currentPage end
  if currentPage > maxPage then currentPage = currentPage - maxPage end

  local bookmarksOnPage = getAmountBookmarksOnPage(currentPage)
  if oldPos > bookmarksOnPage then oldPos = bookmarksOnPage end
  currentSlot = getFirstSlotOnPage(currentPage) + oldPos - 1

  if mode == "move" then
    table.remove(bookmarks, oldSlot)
    table.insert(bookmarks, currentSlot, bookmarkStore)
  end

  displayBookmarks()
end

-- Parses a bookmark name for storing, also trimming it
-- Replaces %t with the timestamp of the bookmark
-- Replaces %p with the time position of the bookmark
function parseName(name)
  local pos = 0
  if mode == "rename" then pos = bookmarks[currentSlot]["pos"] else pos = mp.get_property_number("time-pos") end
  name, _ = name:gsub("%%t", parseTime(pos))
  name, _ = name:gsub("%%p", pos)
  name = trimName(name)
  return name
end

-- Parses a bookmark name for displaying, also trimming it
-- Replaces all { with an escaped { so it won't be interpreted as a tag
function displayName(name)
  name, _ = name:gsub("{", "\\{")
  name = trimName(name)
  return name
end

-- Trims a name to the max number of characters
function trimName(name)
  if name:len() > maxChar then name = name:sub(1,maxChar) end
  return name
end

-- Parses a Windows path with backslashes to one with normal slashes
function parsePath(path)
  if type(path) == "string" then path, _ = path:gsub("\\", "/") end
  return path
end

-- Loads all the bookmarks in the global table and sets the current page and total number of pages
-- Also checks for older versions of bookmarks and "updates" them
-- Also checks for bookmarks made by "mpv-bookmarker" and converts them
-- Also removes anything it doesn't recognize as a bookmark
function loadBookmarks()
  bookmarks = loadTable(getFilepath(bookmarkerName))
  if bookmarks == nil then bookmarks = {} end

  local doSave = false
  local doEject = false
  local doReplace = false
  local ejects = {}
  local newmarks = {}

  for key, bookmark in pairs(bookmarks) do
    if type(key) == "number" then
      if bookmark.version == nil or bookmark.version == 1 then
        if bookmark.name ~= nil and bookmark.path ~= nil and bookmark.pos ~= nil then
          bookmark.path = parsePath(bookmark.path)
          bookmark.version = 2
          doSave = true
        else
          table.insert(ejects, key)
          doEject = true
        end
      end
    else
      if bookmark.filename ~= nil and bookmark.pos ~= nil and bookmark.filepath ~= nil then
        local newmark = {
          name = trimName(""..bookmark.filename.." @ "..parseTime(bookmark.pos)),
          pos = bookmark.pos,
          path = parsePath(bookmark.filepath),
          version = 2
        }
        table.insert(newmarks, newmark)
      end
      doReplace = true
      doSave = true
    end
  end

  if doEject then
    for i = #ejects, 1, -1 do table.remove(bookmarks, ejects[i]) end
    doSave = true
  end

  if doReplace then bookmarks = newmarks end
  if doSave then saveBookmarks() end

  if #bookmarks > 0 and currentSlot == 0 then currentSlot = 1 end
  calcPages()
end

-- Save the globally loaded bookmarks to the JSON file
function saveBookmarks()
  saveTable(bookmarks, getFilepath(bookmarkerName))
end

-- Make a bookmark of the current media file, position and name
-- Name can be specified or left blank to automake a name
-- Returns the bookmark if successful or nil if it can't make a bookmark
function makeBookmark(bname)
  if mp.get_property("path") ~= nil then
    if bname == nil then bname = mp.get_property("media-title").." @ %t" end
    local bookmark = {
      name = parseName(bname),
      pos = mp.get_property_number("time-pos"),
      path = parsePath(mp.get_property("path")),
      version = 2
    }
    return bookmark
  else
    return nil
  end
end

-- Add the current position as a bookmark to the global table and then saves it
-- Returns the slot of the newly added bookmark
-- Returns -1 if there's an error
function addBookmark(name)
  local bookmark = makeBookmark(name)
  if bookmark == nil then
    abort(styleOn.."{\\c&H0000FF&}{\\b1}Can't find the media file to create the bookmark for")
    return -1
  end
  table.insert(bookmarks, bookmark)

  if #bookmarks == 1 then currentSlot = 1 end

  calcPages()
  saveBookmarks()
  displayBookmarks()
  return #bookmarks
end

-- Edit a property of a bookmark at the specified slot
-- Returns -1 if there's an error
function editBookmark(slot, property, value)
  if bookmarkExists(slot) then
    if property == "name" then value = parseName(value) end
    bookmarks[slot][property] = value
    saveBookmarks()
  else
    abort(styleOn.."{\\c&H0000FF&}{\\b1}Can't find the bookmark at slot "..slot)
    return -1
  end
end

-- Replaces the bookmark at the specified slot with a provided bookmark
-- Keeps the name and its position in the list
-- If the slot is not specified, picks the currently selected bookmark to replace
-- If a bookmark is not provided, generates a new bookmark
function replaceBookmark(slot)
  if slot == nil then slot = currentSlot end
  if bookmarkExists(slot) then
    local bookmark = makeBookmark(bookmarks[slot]["name"])
    if bookmark == nil then
      abort(styleOn.."{\\c&H0000FF&}{\\b1}Can't find the media file to create the bookmark for")
      return -1
    end
    bookmarks[slot] = bookmark
    saveBookmarks()
    if closeAfterReplace then
      abort(styleOn.."{\\c&H00FF00&}{\\b1}Successfully replaced bookmark:{\\r}\n"..displayName(bookmark["name"]))
      return -1
    end
    return 1
  else
    abort(styleOn.."{\\c&H0000FF&}{\\b1}Can't find the bookmark at slot "..slot)
    return -1
  end
end

-- Quickly saves a bookmark without bringing up the menu
function quickSave()
  if not active then
    loadBookmarks()
    local slot = addBookmark()
    if slot > 0 then mp.osd_message("Saved new bookmark at slot " .. slot) end
  end
end

-- Quickly loads the last bookmark without bringing up the menu
function quickLoad()
  if not active then
    loadBookmarks()
    local slot = #bookmarks
    if slot > 0 then mp.osd_message("Loaded bookmark at slot " .. slot) end
    jumpToBookmark(slot)
  end
end

-- Deletes the bookmark in the specified slot from the global table and then saves it
function deleteBookmark(slot)
  table.remove(bookmarks, slot)
  if currentSlot > #bookmarks then currentSlot = #bookmarks end

  calcPages()
  saveBookmarks()
  displayBookmarks()
end

-- Jump to the specified bookmark
-- This means loading it, reading it, and jumping to the file + position in the bookmark
function jumpToBookmark(slot)
  if bookmarkExists(slot) then
    local bookmark = bookmarks[slot]
    if string.sub(bookmark["path"], 1, 4) == "http" or fileExists(bookmark["path"]) then
      if parsePath(mp.get_property("path")) == bookmark["path"] then
        mp.set_property_number("time-pos", bookmark["pos"])
      else
        mp.commandv("loadfile", parsePath(bookmark["path"]), "replace", "start="..bookmark["pos"])
      end
      if closeAfterLoad then abort(styleOn.."{\\c&H00FF00&}{\\b1}Successfully found file for bookmark:{\\r}\n"..displayName(bookmark["name"])) end
    else
      abort(styleOn.."{\\c&H0000FF&}{\\b1}Can't find file for bookmark:\n" .. displayName(bookmark["name"]))
    end
  else
    abort(styleOn.."{\\c&H0000FF&}{\\b1}Can't find the bookmark at slot " .. slot)
  end
end

-- Displays the current page of bookmarks
function displayBookmarks()
  -- Determine which slot is the first and last on the current page
  local startSlot = getFirstSlotOnPage(currentPage)
  local endSlot = getLastSlotOnPage(currentPage)

  -- Prepare the text to display and display it
  local display = styleOn .. "{\\b1}Bookmarks page " .. currentPage .. "/" .. maxPage .. ":{\\b0}"
  for i = startSlot, endSlot do
    local btext = displayName(bookmarks[i]["name"])
    local selection = ""
    if i == currentSlot then
      selection = "{\\b1}{\\c&H00FFFF&}>"
      if mode == "move" then btext = "----------------" end
      btext = btext
    end
    display = display .. "\n" .. selection .. i .. ": " .. btext .. "{\\r}"
  end
  mp.osd_message(display, rate)
end

local timer = mp.add_periodic_timer(rate * 0.95, displayBookmarks)
timer:kill()

-- Commits the message entered with the Typer with custom scripts preceding it
-- Should typically end with typerExit()
function typerCommit()
  local status = 0
  if mode == "save" then
    status = addBookmark(typerText)
  elseif mode == "replace" and typerText == "y" then
    status = replaceBookmark(currentSlot, makeBookmark(bookmarks[currentSlot]["name"]))
  elseif mode == "delete" and typerText == "y" then
    deleteBookmark(currentSlot)
  elseif mode == "rename" then
    editBookmark(currentSlot, "name", typerText)
  elseif mode == "filepath" then
    editBookmark(currentSlot, "path", typerText)
  end
  if status >= 0 then typerExit() end
end

-- Exits the Typer without committing with custom scripts preceding it
function typerExit()
  deactivateTyper()
  displayBookmarks()
  timer:resume()
  mode = "none"
  activateControls("bookmarker", bookmarkerControls, bookmarkerFlags)
end

-- Starts the Typer with custom scripts preceding it
function typerStart()
  if (mode == "save" or mode=="replace") and mp.get_property("path") == nil then
    abort(styleOn.."{\\c&H0000FF&}{\\b1}Can't find the media file to create the bookmark for")
    return -1
  end
  if (mode == "replace" or mode == "rename" or mode == "filepath" or mode == "delete") and not bookmarkExists(currentSlot) then
    abort(styleOn.."{\\c&H0000FF&}{\\b1}Can't find the bookmark at slot "..currentSlot)
    return -1
  end
  if (mode == "replace" and not confirmReplace) or (mode == "delete" and not confirmDelete) then
    typerText = "y"
    typerCommit()
    return
  end

  deactivateControls("bookmarker", bookmarkerControls)
  timer:kill()
  activateTyper()
  if mode == "rename" then typerText = bookmarks[currentSlot]["name"] end
  if mode == "filepath" then typerText = bookmarks[currentSlot]["path"] end
  typerPos = typerText:len()
  typer("")
end

-- Aborts the program with an optional error message
function abort(message)
  mode = "none"
  moverExit(true)
  deactivateTyper()
  deactivateControls("bookmarker", bookmarkerControls)
  timer:kill()
  mp.osd_message(message)
  active = false
end

-- Handles the state of the bookmarker
function handler()
  if active then
    abort("")
  else
    activateControls("bookmarker", bookmarkerControls, bookmarkerFlags)
    loadBookmarks()
    displayBookmarks()
    timer:resume()
    active = true
  end
end

mp.register_script_message("bookmarker-menu", handler)
mp.register_script_message("bookmarker-quick-save", quickSave)
mp.register_script_message("bookmarker-quick-load", quickLoad)
