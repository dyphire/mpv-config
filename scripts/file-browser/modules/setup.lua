local mp = require 'mp'

local o = require 'modules.options'
local g = require 'modules.globals'
local API = require 'modules.utils'

--sets up the compatible extensions list
local function setup_extensions_list()
    --setting up subtitle extensions
    for ext in API.iterate_opt(o.subtitle_extensions:lower()) do
        g.sub_extensions[ext] = true
        g.extensions[ext] = true
    end

    --setting up audio extensions
    for ext in API.iterate_opt(o.audio_extensions:lower()) do
        g.audio_extensions[ext] = true
        g.extensions[ext] = true
    end

    --adding file extensions to the set
    for _, ext in ipairs(g.compatible_file_extensions) do
        g.extensions[ext] = true
    end

    --adding extra extensions on the whitelist
    for str in API.iterate_opt(o.extension_whitelist:lower()) do
        g.extensions[str] = true
    end

    --removing extensions that are in the blacklist
    for str in API.iterate_opt(o.extension_blacklist:lower()) do
        g.extensions[str] = nil
    end
end

--splits the string into a table on the separators
local function setup_root()
    for str in API.iterate_opt(o.root) do
        local path = mp.command_native({'expand-path', str})
        path = API.fix_path(path, true)

        local temp = {name = path, type = 'dir', label = str, ass = API.ass_escape(str, true)}

        g.root[#g.root+1] = temp
    end
end

return {
    extensions_list = setup_extensions_list,
    root = setup_root,
}
