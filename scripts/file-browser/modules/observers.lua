
local mp = require 'mp'
local utils = require 'mp.utils'

local g = require 'modules.globals'
local API = require 'modules.utils'
local ass = require 'modules.ass'

local observers ={}

--saves the directory and name of the currently playing file
function observers.current_directory(_, filepath)
    --if we're in idle mode then we want to open the working directory
    if filepath == nil then
        g.current_file.directory = API.fix_path( mp.get_property("working-directory", ""), true)
        g.current_file.name = nil
        g.current_file.path = nil
        return
    elseif filepath:find("dvd://") == 1 then
        filepath = g.dvd_device..filepath:match("dvd://(.*)")
    end

    local workingDirectory = mp.get_property('working-directory', '')
    local exact_path = API.join_path(workingDirectory, filepath)
    exact_path = API.fix_path(exact_path, false)
    g.current_file.directory, g.current_file.name = utils.split_path(exact_path)
    g.current_file.path = exact_path

    if not g.state.hidden then ass.update_ass()
    else g.state.flag_update = true end
end

function observers.dvd_device(_, device)
    if not device or device == "" then device = "/dev/dvd/" end
    g.dvd_device = API.fix_path(device, true)
end

return observers
