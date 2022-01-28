--[[
SOURCE_ https://github.com/dya-tel/mpv-scripts/blob/master/fuzzydir.lua
COMMIT_11 Mar 2018_722824c

Determines the max depth of recursive search, should be >= 1

 1 will disable recursion and only direct subdirectories would be found
 2 will allow single recursion and direct subdirectories would be found along with their direct subdirectories
 ...

Please be careful when setting this value too high
as it can result in awful performance or even stack overflow
]]

local msg = require 'mp.msg'
local options = require 'mp.options'
local utils = require 'mp.utils'

o = {
    max_search_depth = 3,
    excluded_dir = [[
        ["?:"]
        ]], --excluded directories for shared, #windows: ["X:", "Z:"]
    special_protocols = [[
	["https?://", "magnet:", "rtmp:", "smb://", "bd://", "dvd://", "cdda://"]
	]], --add above (after a comma) any protocol to disable
}
options.read_options(o)

o.excluded_dir = utils.parse_json(o.excluded_dir)
o.special_protocols = utils.parse_json(o.special_protocols)

local default_audio_paths = mp.get_property_native("options/audio-file-paths")
local default_sub_paths = mp.get_property_native("options/sub-file-paths")

function starts_protocol(tab, val)
	for index, value in ipairs(tab) do
		if (val:find(value) == 1) then
			return true
		end
	end
	return false
end

function starts_with(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

function ends_with(str, suffix)
    return suffix == "" or string.sub(str, -string.len(suffix)) == suffix
end

function add_all(to, from)
    for index, element in pairs(from) do
        table.insert(to, element)
    end
end

function contains(t, e)
    for index, element in pairs(t) do
        if element == e then
            return true
        end
    end
    return false
end

function normalize(path)
    if path == "." then
        return ""
    end

    if starts_with(path, "./") or starts_with(path, ".\\") then
        path = string.sub(path, 3, -1)
    end
    if ends_with(path, "/") or ends_with(path, "\\") then
        path = string.sub(path, 1, -1)
    end

    return path
end

function traverse(path, level)
    level = level or 1
    if level > o.max_search_depth then
        return {}
    end

    local found = utils.readdir(path, "dirs")
    if found == nil then
        return {}
    end

    local result = {}
    for index, file in pairs(found) do
        local full_path = utils.join_path(path, file)
        table.insert(result, full_path)
        add_all(result, traverse(full_path, level + 1))
    end

    return result
end

function explode(from, working_directory)
    local result = {}
    for index, path in pairs(from) do
        path = utils.join_path(working_directory, normalize(path))
        local parent, leftover = utils.split_path(path)
        local fpath = mp.get_property('path')

        if not starts_protocol(o.special_protocols, fpath) and not starts_protocol(o.excluded_dir, path) then
            if leftover == "**" then
                table.insert(result, parent)
                add_all(result, traverse(parent))
            else
                table.insert(result, path)
            end
        end
    end

    local normalized = {}
    for index, path in pairs(result) do
        local normalized_path = normalize(path)
        if not contains(normalized, normalized_path) then
            table.insert(normalized, normalized_path)
        end
    end

    return normalized
end

function explode_all()
    local video_path = mp.get_property("path")
    local working_directory, filename = utils.split_path(video_path)

    local audio_paths = explode(default_audio_paths, working_directory)
    mp.set_property_native("options/audio-file-paths", audio_paths)

    local sub_paths = explode(default_sub_paths, working_directory)
    mp.set_property_native("options/sub-file-paths", sub_paths)
end

mp.add_hook("on_load", 50, explode_all)
