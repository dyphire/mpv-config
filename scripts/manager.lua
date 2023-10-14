local msg = require "mp.msg"
local utils = require "mp.utils"
local legacy = mp.command_native_async == nil
local config = {}
local dir_cache = {}

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

local function build_directory_string(dir, repo)
    local str = ""
    local contents = utils.readdir(dir)
    if not contents then return msg.error("could not access local repo:", repo) end
    for _, item in ipairs(contents) do
        local path = dir..'/'..item
        if utils.file_info(path).is_dir then
            if item ~= ".git" then str = str..'/'..build_directory_string(path, repo)..'\n' end
        else
            str = str..(path:sub(repo:len()+2))..'\n'
        end
    end
    return str
end

local function get_file_list(info)
    if not info.local_repo then
        return run({"git", "-C", info.edist, "ls-tree", "-r", "--name-only", "remotes/manager/"..info.branch}).stdout
    else
        return build_directory_string(info.local_repo, info.local_repo)
    end
end

function update(info)
    info = apply_defaults(info)
    if not info then return false end

    local base = nil

    info.edist = string.match(mp.command_native({"expand-path", info.dest}), "(.-)[/\\]?$")
    mkdir(info.edist)

    local files = {}

    if info.local_repo then
        info.local_repo = mp.command_native({"expand-path", info.local_repo})
        if not utils.file_info(info.local_repo) then
            info.local_repo = false
            msg.warn("local repo not found - falling back to git")
        end
    end

    if not info.local_repo then
        run({"git", "-C", info.edist, "remote", "add", "manager", info.git})
        run({"git", "-C", info.edist, "remote", "set-url", "manager", info.git})
        run({"git", "-C", info.edist, "fetch", "manager", info.branch})
    end

    for file in string.gmatch(get_file_list(info), "[^\r\n]+") do
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
            if p_based and not info.flatten_folders then mkdir(info.edist.."/"..p_based) end

            local c = ""
            if info.local_repo then
                local source = io.open(info.local_repo..'/'..file)
                c = source:read("*a")
                source:close()
            else
                c = string.match(run({"git", "-C", info.edist, "--no-pager", "show", "remotes/manager/"..info.branch..":"..file}).stdout, "(.-)[\r\n]?$")
            end

            local f = io.open(info.edist.."/"..(info.flatten_folders and file:match("[^/]+$") or based), "w")
            f:write(c)
            f:close()
        end
    end
    return true
end

function update_all()
    local f = io.open(mp.command_native({"expand-path", "~~/manager.json"}), "r")
    if f then
        local json = f:read("*all")
        f:close()

        local props = utils.parse_json(json or "")
        if props then
            config = props
        end
    end

    for i, info in ipairs(config) do
        print("updating", (info.git:match("([^/]+)%.git$") or info.git).."...")
        if not update(info) then msg.error("FAILED") end
    end
    print("all files updated")
end

mp.add_key_binding(nil, "manager-update-all", update_all)
