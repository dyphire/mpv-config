--[[
SOURCE_ https://github.com/sibwaf/mpv-scripts/blob/master/fuzzydir.lua
COMMIT_26 Mar 2023_2ba3e26
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

    # enabled

    Determines whether the script is enabled or not

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

    # excluded_dir

    fuzzydir will ignore paths which in excluded_dir

    This supports absolute and relative paths
    example on Windows: ["Z:", "Z:/Cloud/", "/Cloud/"]
]]

local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require 'mp.options'

o = {
    enabled = true,
    max_search_depth = 1,
    discovery_threshold = 10,
    excluded_dir = [[
        []
    ]],
}
options.read_options(o, _, function() end)

----------
local is_windows = package.config:sub(1, 1) == "\\" -- detect path separator, windows uses backslashes
excluded_dir = utils.parse_json(o.excluded_dir)

local default_audio_paths = mp.get_property_native("options/audio-file-paths")
local default_sub_paths = mp.get_property_native("options/sub-file-paths")

function foreach(list, action)
    for _, item in pairs(list) do
        action(item)
    end
end

function is_protocol(path)
    return type(path) == 'string' and path:find('^%a[%a%d-_]+://') ~= nil
end

function need_ignore(tab, val)
    for index, element in ipairs(tab) do
        if string.find(val, element) then
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

function call_command(command)
    local command_string = ""
    for _, part in pairs(command) do
        command_string = command_string .. part .. " "
    end

    msg.trace("Calling external command:", command_string)

    local process = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = command,
    })

    if process.status ~= 0 then
        msg.verbose("External command failed with status " .. process.status .. ": " .. command_string)
        if process.stderr ~= "" then
            msg.debug(process.stderr)
        end

        return nil
    end

    local result = {}
    for line in string.gmatch(process.stdout, "([^\r\n]+)") do
        table.insert(result, line)
    end
    return result
end

-- Platform-dependent optimization

local powershell_version = call_command({
    "powershell",
    "-NoProfile",
    "-Command",
    "$Host.Version.Major",
})
if powershell_version ~= nil then
    powershell_version = tonumber(powershell_version[1])
end
if powershell_version == nil then
    powershell_version = -1
end
msg.debug("PowerShell version", powershell_version)

function fast_readdir(path)
    local is_windows = package.config:sub(1,1) == "\\"
    if is_windows then
        if powershell_version >= 3 then
            msg.trace("Scanning", path, "with PowerShell")
            return call_command({
                "powershell",
                "-NoProfile",
                "-Command",
                [[
                $dirs = Get-ChildItem -LiteralPath ]] .. string.format("%q", path) .. [[ -Directory
                foreach($dir in $dirs) {
                    $u8clip = [System.Text.Encoding]::UTF8.GetBytes($dir.Name)
                    [Console]::OpenStandardOutput().Write($u8clip, 0, $u8clip.Length)
                    Write-Host ""
                } ]],
            })
        else
            msg.trace("Scanning", path, "with default readdir")
            return utils.readdir(path, "dirs")
        end
    else
        msg.trace("Scanning", path, "with ls")
        return call_command({ "ls", "-1", "-d", path })
    end
end

-- Platform-dependent optimization end

function traverse(search_path, current_path, level, cache)
    local full_path = utils.join_path(search_path, current_path)

    if level > o.max_search_depth then
        msg.trace("Traversed too deep, skipping scan for", full_path)
        return {}
    end

    if cache[full_path] ~= nil then
        msg.trace("Returning from cache for", full_path)
        return cache[full_path]
    end

    local result = {}

    local discovered_paths = fast_readdir(full_path)
    if discovered_paths == nil then
        -- noop
        msg.debug("Unable to scan " .. full_path .. ", skipping")
    elseif o.discovery_threshold > 0 and #discovered_paths > o.discovery_threshold then
        -- noop
        msg.debug("Too many directories in " .. full_path .. ", skipping")
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
            msg.trace("Expanding wildcard for", raw_path)
            table.insert(result, parent)
            add_all(result, traverse(search_path, parent, 1, cache))
        else
            msg.trace("Path", raw_path, "doesn't have a wildcard, keeping as-is")
            table.insert(result, raw_path)
        end
    end

    local normalized = {}
    for index, path in pairs(result) do
        if is_windows then
            path = path:lower()
        end
        local normalized_path = normalize(path)
        if not contains(normalized, normalized_path) and normalized_path ~= "" then
            table.insert(normalized, normalized_path)
        end
    end

    return normalized
end

function explode_all()
    if not o.enabled then return end
    msg.debug("max_search_depth = ".. o.max_search_depth .. ", discovery_threshold = " .. o.discovery_threshold)

    local video_path = mp.get_property("path")
    local search_path, _ = utils.split_path(video_path)
    if is_windows then search_path = search_path:gsub("\\", "/") end
    msg.debug("search_path = " .. search_path)

    local cache = {}
    if is_protocol(video_path) or need_ignore(excluded_dir, search_path) then
        return
    end

    foreach(default_audio_paths, function(it) msg.debug("audio-file-paths:", it) end)
    local audio_paths = explode(default_audio_paths, search_path, cache)
    foreach(audio_paths, function(it) msg.debug("Adding to audio-file-paths:", it) end)
    mp.set_property_native("options/audio-file-paths", audio_paths)

    foreach(default_sub_paths, function(it) msg.debug("sub-file-paths:", it) end)
    local sub_paths = explode(default_sub_paths, search_path, cache)
    foreach(sub_paths, function(it) msg.debug("Adding to sub-file-paths:", it) end)
    mp.set_property_native("options/sub-file-paths", sub_paths)
end

mp.add_hook("on_load", 50, explode_all)
