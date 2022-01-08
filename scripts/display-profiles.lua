--[[
    A script to automatically apply a profile when mpv is moved onto a new display
    Does not apply any profiles if the mpv window is sitting accross multiple displays.
    available at: https://github.com/CogentRedTester/mpv-scripts

    This script is currently in a very basic form, it only applies profiles based on the names
    that mpv's display-names property returns. It does not necessarily see the actual names of
    the displays.

    On windows this is in the generic form '\\.\DISPLAY#', where # is the display number starting from 1

    The profile name must be in the form [display/{displayname}]
    for example: [display/\\.\DISPLAY1] on windows
    You can change what the prefix is with the options
]]--

local msg = require 'mp.msg'
local opt = require 'mp.options'

local o = {
    --disables the script
    enable = true,

    --changes the profile name prefix
    prefix = 'display/'
}

function update_opts(list)
    if not o.enable then
        mp.unobserve_property(apply_profile)
    else
        mp.observe_property('display-names', 'native', apply_profile)
    end
end

opt.read_options(o, 'display_profiles', update_opts)

--applies the profile
function apply_profile(property, names)
    if names == nil then return end
    if #names ~= 1 then return end

    msg.info('applying profile ' .. o.prefix .. names[1])
    mp.commandv('apply-profile', o.prefix .. names[1])
end

mp.observe_property('display-names', 'native', apply_profile)
update_opts()