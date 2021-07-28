local utils = require "mp.utils"
local legacy = mp.command_native_async == nil
local config = {}
local dir_cache = {}

local f = io.open(mp.command_native({"expand-path", "~~/manager.json"}), "r")
if f then
    local json = f:read("*all")
    f:close()

    local props = utils.parse_json(json or "")
    if props then
        config = props
    end
end

function run(args)
    if legacy then
        return utils.subprocess({args = args})
    end
    return mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
end

function parent(path)
    return string.match(path, "(.*)[/\\]")
end

function cache(path)
    local p_path = parent(path)
    if p_path == nil or p_path == "" or dir_cache[p_path] then return end
    cache(p_path)
    dir_cache[path] = 1
end

function mkdir(path)
    if dir_cache[path] then return end
    cache(path)
    run({"git", "init", path})
end

function match(str, patterns)
    for pattern in string.gmatch(patterns, "[^|]+") do
        if string.match(str, pattern) then
            return true
        end
    end
end

function apply_defaults(info)
    if info.git == nil then return false end
    if info.whitelist == nil then info.whitelist = "" end
    if info.blacklist == nil then info.blacklist = "" end
    if info.dest == nil then info.dest = "~~/scripts" end
    if info.branch == nil then info.branch = "master" end
    return info
end

function update(info)
    info = apply_defaults(info)
    if not info then return false end

    local base = nil
    
    local e_dest = string.match(mp.command_native({"expand-path", info.dest}), "(.-)[/\\]?$")
    mkdir(e_dest)
    
    local files = {}
    
    run({"git", "-C", e_dest, "remote", "add", "manager", info.git})
    run({"git", "-C", e_dest, "remote", "set-url", "manager", info.git})
    run({"git", "-C", e_dest, "fetch", "manager", info.branch})
    
    for file in string.gmatch(run({"git", "-C", e_dest, "ls-tree", "-r", "--name-only", "remotes/manager/"..info.branch}).stdout, "[^\r\n]+") do
        local l_file = string.lower(file)
        if info.whitelist == "" or match(l_file, info.whitelist) then
            if info.blacklist == "" or not match(l_file, info.blacklist) then
                table.insert(files, file)
                if base == nil then base = parent(l_file) or "" end
                while string.match(base, l_file) == nil do
                    if l_file == "" then break end
                    l_file = parent(l_file) or ""
                end
                base = l_file
            end
        end
    end
    
    if base == nil then return false end
    
    if base ~= "" then base = base.."/" end
    
    if next(files) == nil then
        print("no files matching patterns")
    else
        for _, file in ipairs(files) do
            local based = string.sub(file, string.len(base)+1)
            local p_based = parent(based)
            if p_based and not info.flatten_folders then mkdir(e_dest.."/"..p_based) end
            local c = string.match(run({"git", "-C", e_dest, "--no-pager", "show", "remotes/manager/"..info.branch..":"..file}).stdout, "(.-)[\r\n]?$")
            local f = io.open(e_dest.."/"..(info.flatten_folders and file:match("[^/]+$") or based), "w")
            f:write(c)
            f:close()
        end
    end
    return true
end

function update_all()
    for i, info in ipairs(config) do
        print("update"..i, update(info))
    end
end

mp.add_key_binding(nil, "manager-update-all", update_all)