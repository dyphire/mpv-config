--[[
    An addon for mpv-file-browser which adds a Favourites path that can be loaded from the ROOT


    Designed to work with the following custom keybinds:
    {
        "key": "F",
        "command": ["script-message", "favourites/add_favourite", "%f"]
    },
    {
        "key": "F",
        "command": ["script-message", "favourites/remove_favourite", "%f"],
        "parser": "favourites"
    },
    {
        "key": "Ctrl+UP",
        "command": [
            ["script-binding", "file_browser/dynamic/scroll_up"],
            ["script-message", "favourites/move_up", "%f"]
        ],
        "parser": "favourites"
    },
    {
        "key": "Ctrl+DOWN",
        "command": [
            ["script-binding", "file_browser/dynamic/scroll_down"],
            ["script-message", "favourites/move_down", "%f"]
        ],
        "parser": "favourites"
    }
]]--

local mp = require "mp"
local msg = require "mp.msg"
local utils = require "mp.utils"
local save_path = mp.command_native({"expand-path", "~~/script-opts/file_browser_favourites"})

local favourites = nil
local favs = {
    priority = 30,
    cursor = 1
}

local use_virtual_directory = true
local full_paths = {}

local function create_favourite_object(str)
    local item = {
        type = str:sub(-1) == "/" and "dir" or "file",
        path = str,
        name = str:match("([^/]+/?)$")
    }
    full_paths[str:match("([^/]+)/?$")] = str
    return item
end

function favs:setup()
    self:insert_root_item({name = "Favourites/", label = "Favourites"}, 1)
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
        opts.index = self:get_index()
        if opts.directory_label then
            opts.directory_label = opts.directory_label:gsub(full_paths[name], "Favourites/"..name..'/')
            if opts.directory_label:find("Favourites/") ~= 1 then opts.directory_label = nil end
        end

        for _, item in ipairs(list) do
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

local function write_to_file()
    local file = io.open(save_path, "w+")
    for _, item in ipairs(favourites) do
        file:write(string.format("%s\n", item.path))
    end
    file:close()
    if favs.get_directory() == "Favourites/" then
        favs.cursor = favs.get_selected_index()
        mp.commandv("script-binding", "file_browser/dynamic/reload")
    end
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

mp.register_script_message("favourites/add_favourite", add_favourite)
mp.register_script_message("favourites/remove_favourite", remove_favourite)
mp.register_script_message("favourites/move_up", function(path) move_favourite(path, -1) end)
mp.register_script_message("favourites/move_down", function(path) move_favourite(path, 1) end)

return favs
