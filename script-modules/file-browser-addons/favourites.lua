--[[
    An addon for mpv-file-browser which adds a Favourites path that can be loaded from the ROOT
]]--

local mp = require "mp"
local msg = require "mp.msg"

local fb = require 'file-browser'
local save_path = mp.command_native({"expand-path", "~~/script-opts/file_browser_favourites.txt"}) --[[@as string]]
do
    local file = io.open(save_path, "a+")
    if not file then
        msg.error("cannot access file", ("%q"):format(save_path), "make sure that the directory exists")
        return {}
    end
    file:close()
end

---@type Item[]
local favourites = {}
local favourites_loaded = false

---@type ParserConfig
local favs = {
    api_version = "1.8.0",
    priority = 30,
    cursor = 1
}

local use_virtual_directory = true

---@type table<string,string>
local full_paths = {}

---@param str string
---@return Item
local function create_favourite_object(str)
    local item = {
        type = str:sub(-1) == "/" and "dir" or "file",
        path = str,
        redirect = not use_virtual_directory,
        name = str:match("([^/]+/?)$")
    }
    full_paths[str:match("([^/]+)/?$")] = str
    return item
end

---@param self Parser
function favs:setup()
    self:register_root_item('Favourites/')
end

local function update_favourites()
    local file = io.open(save_path, "r")
    if not file then return end

    favourites = {}
    for str in file:lines() do
        table.insert(favourites, create_favourite_object(str))
    end
    file:close()
    favourites_loaded = true
end

function favs:can_parse(directory)
    return directory:find("Favourites/") == 1
end

---@async
---@param self Parser
---@param directory string
---@return List?
---@return Opts?
function favs:parse(directory)
    if not favourites_loaded then update_favourites() end
    if directory == "Favourites/" then
        local opts = {
            filtered = true,
            sorted = true
        }
        return favourites, opts
    end

    if use_virtual_directory then
        -- converts the relative favourite path into a full path
        local name = directory:match("Favourites/([^/]+)/?")

        local _, finish = directory:find("Favourites/([^/]+/?)")
        local full_path = (full_paths[name] or "")..directory:sub(finish+1)
        local list, opts = self:defer(full_path or "")

        if not list then return nil end
        opts = opts or {}
        opts.id = self:get_id()
        if opts.directory_label then
            opts.directory_label = opts.directory_label:gsub(full_paths[name], "Favourites/"..name..'/')
            if opts.directory_label:find("Favourites/") ~= 1 then opts.directory_label = nil end
        end

        for _, item in ipairs(list) do
            if not item.path then item.redirect = false end
            item.path = item.path or full_path..item.name
        end

        return list, opts
    end

    local path = full_paths[ directory:match("([^/]+/?)$") or "" ]

    local list, opts = self:defer(path)
    if not list then return nil end
    opts = opts or {}
    opts.directory = opts.directory or path
    return list, opts
end

---@param path string
---@return integer?
---@return Item?
local function get_favourite(path)
    for index, value in ipairs(favourites) do
        if value.path == path then return index, value end
    end
end

--update the browser with new contents of the file
---@async
local function update_browser()
    if favs.get_directory():find("^[fF]avourites/$") then
        local cursor = favs.get_selected_index()
        fb.rescan_await()
        fb.set_selected_index(cursor)
    else
        fb.clear_cache({'favourites/', 'Favourites/'})
    end
end

--write the contents of favourites to the file
local function write_to_file()
    local file = io.open(save_path, "w+")
    if not file then return msg.error(file, "could not open favourites file") end
    for _, item in ipairs(favourites) do
        file:write(string.format("%s\n", item.path))
    end
    file:close()
end

local function add_favourite(path)
    if get_favourite(path) then return end
    update_favourites()
    table.insert(favourites, create_favourite_object(path))
    write_to_file()
end

local function remove_favourite(path)
    update_favourites()
    local index = get_favourite(path)
    if not index then return end
    table.remove(favourites, index)
    write_to_file()
end

local function move_favourite(path, direction)
    update_favourites()
    local index, item = get_favourite(path)
    if not index or not favourites[index + direction] then return end

    favourites[index] = favourites[index + direction]
    favourites[index + direction] = item
    write_to_file()
end

---@async
local function toggle_favourite(cmd, state, co)
    local path = fb.get_full_path(state.list[state.selected], state.directory)

    if state.directory:find("[fF]avourites/$") then remove_favourite(path)
    else add_favourite(path) end
    update_browser()
end

---@async
local function move_key(cmd, state, co)
    if not state.directory:find("[fF]avourites/") then return false end
    local path = fb.get_full_path(state.list[state.selected], state.directory)

    local cursor = fb.get_selected_index()
    if cmd.name == favs:get_id().."/move_up" then
        move_favourite(path, -1)
        fb.set_selected_index(cursor-1)
    else
        move_favourite(path, 1)
        fb.set_selected_index(cursor+1)
    end
    update_browser()
end

update_favourites()

favs.keybinds = {
    { "F", "toggle_favourite", toggle_favourite, {}, },
    { "Ctrl+UP", "move_up", move_key, {repeatable = true} },
    { "Ctrl+DOWN", "move_down", move_key, {repeatable = true} },
}

return favs
