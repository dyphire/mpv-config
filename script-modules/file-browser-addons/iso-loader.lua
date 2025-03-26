local mp = require 'mp'
local msg = require 'mp.msg'
local fb = require 'file-browser'

local isos = {
    name = 'iso-loader',
    priority = 20,
    api_version = '1.5'
}

function isos:setup()
    fb.add_default_extension('iso')
end

function isos:can_parse()
    return true
end

function isos:parse(directory, parse_state)
    local list, opts = self:defer(directory, parse_state)
    if not list or #list == 0 then return list, opts end

    for _, item in ipairs(list) do
        local path = fb.get_full_path(item, opts.directory or directory)
        if fb.get_extension(path) == 'iso' then
            item.mpv_options = { ['bluray-device'] = path, ['dvd-device'] = path }
            item.path = 'bd://'
        end
    end

    return list, opts
end

mp.add_hook('on_load_fail', 50, function()
    if mp.get_property('stream-open-filename') == 'bd://' then
        msg.info('failed to load bluray-device, attempting dvd-device')
        mp.set_property('stream-open-filename', 'dvd://')
    end
end)

return isos