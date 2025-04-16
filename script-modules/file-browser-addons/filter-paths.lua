local fb = require "file-browser"
local opt = require "mp.options"

local o = {
    --list of absolute paths separated by the root separators
    paths = ""
}

--config file stored in ~~/script-opts/file-browser/filter.conf
opt.read_options(o, "file-browser/filter")

local parser = {
    priority = 10,
    api_version = "1.3.0"
}

local paths = {}
for str in fb.iterate_opt(o.paths) do
    paths[str] = true
end

local function filter(path)
    return paths[path]
end

function parser:can_parse()
    return true
end

function parser:parse(directory)
    local list, opts = self:defer(directory)
    if not list then return list, opts end

    directory = opts.directory or directory

    for i=#list, 1, -1 do
        if filter( fb.get_full_path(list[i], directory) ) then
            table.remove(list, i)
        end
   end

    return list, opts
end

return parser