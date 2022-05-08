--[[
    An addon for mpv-file-browser which adds a Favourites path that can be loaded from the ROOT
]]--

local mp = require "mp"
local msg = require "mp.msg"
local utils = require "mp.utils"
local save_path = mp.command_native({"expand-path", "~~/script-opts/file_browser_favourites.txt"})
do
    local file = io.open(save_path, "a+")
    if not file then
        msg.error("cannot access file", ("%q"):format(save_path), "make sure that the directory exists")
        return {}
    end
    file:close()
end

local favourites = nil
local favs = {
    version = "1.0.0",
    priority = 30,
    cursor = 1
}

local use_virtual_directory = true
local full_paths = {}

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

function favs:setup()
    local root = self.get_root()
    local fav_exists = false
    for _, item in ipairs(root) do
        if item.name:find("Favourites/?$") then fav_exists = true end
    end
    if not fav_exists then self.insert_root_item({name = "Favourites/", label = "Favourites"}, 1) end
end

local function update_favourites()
    favourites = {}

    local file = io.open(save_path, "r")
    if not file then return end

    for str in file:lines() do
        table.insert(favourites, create_favourite_object(str))
    end
    file:close()
end

function favs:can_parse(directory)
    return directory:find("Favourites/") == 1
end

function favs:parse(directory)
    if not favourites then update_favourites() end
    if directory == "Favourites/" then
        local opts = {
            filtered = true,
            sorted = true
        }
        if self.cursor ~= 1 then opts.selected_index = self.cursor ; self.cursor = 1 end
        return favourites, opts
    end

    if use_virtual_directory then
        -- converts the relative favourite path into a full path
        local name = directory:match("Favourites/([^/]+)/?")

        local _, finish = directory:find("Favourites/([^/]+/?)")
        local full_path = (full_paths[name] or "")..directory:sub(finish+1)
        local list, opts = self:defer(full_path or "")

        if not list then return nil end
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
    opts.directory = opts.directory or path
    return list, opts
end

local function get_favourite(path)
    for index, value in ipairs(favourites) do
        if value.path == path then return index, value end
    end
end

--update the browser with new contents of the file
local function update_browser()
    if favs.get_directory():find("[fF]avourites/") then
        if favs.get_directory():find("[fF]avourites/$") then
            local cursor = favs.get_selected_index()
            favs.rescan_directory()
            favs.set_selected_index(cursor)
            favs.update_ass()
        else
            favs.clear_cache()
        end
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

local function toggle_favourite(cmd, state, co)
    local path = favs.get_full_path(state.list[state.selected], state.directory)

    if state.directory:find("[fF]avourites/$") then remove_favourite(path)
    else add_favourite(path) end
    update_browser()
end

local function move_key(cmd, state, co)
    if not state.directory:find("[fF]avourites/") then return false end
    local path = favs.get_full_path(state.list[state.selected], state.directory)

    local cursor = favs.get_selected_index()
    if cmd.name == favs:get_id().."/move_up" then
        move_favourite(path, -1)
        favs.set_selected_index(cursor-1)
    else
        move_favourite(path, 1)
        favs.set_selected_index(cursor+1)
    end
    update_browser()
end

update_favourites()
mp.register_script_message("favourites/add_favourite", add_favourite)
mp.register_script_message("favourites/remove_favourite", remove_favourite)
mp.register_script_message("favourites/move_up", function(path) move_favourite(path, -1) end)
mp.register_script_message("favourites/move_down", function(path) move_favourite(path, 1) end)

favs.keybinds = {
    { "F", "toggle_favourite", toggle_favourite, {}, },
    { "Ctrl+UP", "move_up", move_key, {repeatable = true} },
    { "Ctrl+DOWN", "move_down", move_key, {repeatable = true} },
}

return favs
