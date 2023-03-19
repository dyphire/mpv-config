--[[
SOURCE_ https://github.com/sibwaf/mpv-scripts/blob/master/fuzzydir.lua
COMMIT_9 Mar 2023_3285c0b
	Allows using "**" wildcards in sub-file-paths and audio-file-paths
    so you don't have to specify all the possible directory names.

    Basically, allows you to do this and never have the need to edit any paths ever again:
    audio-file-paths = **
    sub-file-paths = **

	MIT license - do whatever you want, but I'm not responsible for any possible problems.
	Please keep the URL to the original repository. Thanks!
]]

--[[
    Configuration:

    # max_search_depth
    
    Determines the max depth of recursive search, should be >= 1

    Examples for "sub-file-paths = **":
    "max_search_depth = 1" => mpv will be able to find [xyz.ass, subs/xyz.ass]
    "max_search_depth = 2" => mpv will be able to find [xyz.ass, subs/xyz.ass, subs/moresubs/xyz.ass]

    Please be careful when setting this value too high as it can result in awful performance or even stack overflow

    
    # discovery_threshold

    fuzzydir will skip paths which contain more than discovery_threshold directories in them

    This is done to keep at least some garbage from getting into *-file-paths properties in case of big collections:
    - dir1 <- will be ignored on opening video.mp4 as it's probably unrelated to the file
    - ...
    - dir999 <- will be ignored
    - video.mp4

    Use 0 to disable this behavior completely
]]

local msg = require 'mp.msg'
local options = require 'mp.options'
local utils = require 'mp.utils'

o = {
    max_search_depth = 3,
    discovery_threshold = 10,
    excluded_dir = [[
        []
        ]], --excluded directories for cloud mount disks on Windows, example: ["X:", "Z:", "F:\\Download\\", "Download"]. !!the option only for Windows
}
options.read_options(o)

excluded_dir = utils.parse_json(o.excluded_dir)

local default_audio_paths = mp.get_property_native("options/audio-file-paths")
local default_sub_paths = mp.get_property_native("options/sub-file-paths")

function is_protocol(path)
    return type(path) == 'string' and (path:match('^%a[%a%d-_]+://') ~= nil or path:match('^%a[%a%d-_]+:\\?') ~= nil)
end

local function need_ignore(tab, val)
    for index, element in ipairs(tab) do
        if string.find(val, element) then
            return true
        end
        if (val:find(element) == 1) then
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
        path = string.sub(path, 1, -2)
    end

    return path
end

function traverse(search_path, current_path, level, cache)
    if level > o.max_search_depth then
        return {}
    end

    local full_path = utils.join_path(search_path, current_path)

    if cache[full_path] ~= nil then
        return cache[full_path]
    end

    local result = {}

    local discovered_paths = utils.readdir(full_path, "dirs")
    if discovered_paths == nil then
        -- noop
    elseif o.discovery_threshold > 0 and #discovered_paths > o.discovery_threshold then
        -- noop
    else
        for _, discovered_path in pairs(discovered_paths) do
            local new_path = utils.join_path(current_path, discovered_path)

            table.insert(result, new_path)
            add_all(result, traverse(search_path, new_path, level + 1, cache))
        end
    end

    cache[full_path] = result

    return result
end

function explode(raw_paths, search_path, cache)
    local result = {}
    for _, raw_path in pairs(raw_paths) do
        local parent, leftover = utils.split_path(raw_path)
        if leftover == "**" then
            add_all(result, traverse(search_path, parent, 1, cache))
        else
            table.insert(result, raw_path)
        end
    end

    local normalized = {}
    for index, path in pairs(result) do
        local normalized_path = normalize(path)
        if not contains(normalized, normalized_path) and normalized_path ~= "" then
            table.insert(normalized, normalized_path)
        end
    end

    return normalized
end

function explode_all()
    local video_path = mp.get_property("path")
    local search_path, _ = utils.split_path(video_path)
    local cache = {}
    if is_protocol(search_path) or need_ignore(excluded_dir, search_path) then
        return
    end

    local audio_paths = explode(default_audio_paths, search_path, cache)
    mp.set_property_native("options/audio-file-paths", audio_paths)

    local sub_paths = explode(default_sub_paths, search_path, cache)
    mp.set_property_native("options/sub-file-paths", sub_paths)
end

mp.add_hook("on_load", 50, explode_all)
