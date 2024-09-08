
local directory_movement = require 'modules.navigation.directory-movement'
local fb = require 'modules.apis.fb'
local fb_utils = require 'modules.utils'

local observers ={}

--saves the directory and name of the currently playing file
function observers.current_directory(_, filepath)
    directory_movement.set_current_file(filepath)
end

function observers.dvd_device(_, device)
    if not device or device == "" then device = '/dev/dvd' end
    fb.register_directory_mapping(fb_utils.absolute_path(device), '^dvd://.*', true)
end

function observers.bd_device(_, device)
    if not device or device == '' then device = '/dev/bd' end
    fb.register_directory_mapping(fb_utils.absolute_path(device), '^bd://.*', true)
end

function observers.cd_device(_, device)
    if not device or device == '' then device = '/dev/cdrom' end
    fb.register_directory_mapping(fb_utils.absolute_path(device), '^cdda://.*', true)
end

return observers
