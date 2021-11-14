--[[
    Detects when a onedrive link is loaded and converts it to an absolute path to play the file.
    Uses powershell, so it only works on windows. Though if someone is using the cross-platform
    version of powershell, they may just need to change the first arguement from 'powershell' to 'pwsh'.

    available at: https://github.com/CogentRedTester/mpv-scripts

    Also includes script messages to add video/audio/sub tracks from onedrive:

    script-message onedrive/video-add [url] {flag}
    script-message onedrive/audio-add [url] {flag}
    script-message onedrive/sub-add [url] {flag}
]]--

local mp = require 'mp'
local msg = require 'mp.msg'

function get_link(url)
    msg.debug('expanding url ' .. url)

    local command = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        args = {
            'powershell',
            '-command',
            '([System.Net.HttpWebRequest]::Create("' .. url .. '")).GetResponse().ResponseUri.AbsoluteUri'
        }
    })

    url = command.stdout
    url = url:gsub('redir%?', 'download%?')
    msg.debug('returning url ' .. url)
    return url
end

function fix_onedrive_link()
    local path = mp.get_property('stream-open-filename', '')
    if path:find("https://1drv.ms") ~= 1 then
        return
    end
    msg.info('onedrive link detected')
    path = get_link(path)

    msg.verbose('expanded onedrive url: ' .. path)
    mp.set_property('stream-open-filename', path)
end

mp.add_hook('on_load_fail', 50, fix_onedrive_link)

mp.register_script_message('onedrive/video-add', function(url, flag)
    mp.command_native({'video-add', get_link(url), flag})
end)

mp.register_script_message('onedrive/audio-add', function(url, flag)
    mp.command_native({'audio-add', get_link(url), flag})
end)
mp.register_script_message('onedrive/sub-add', function(url, flag)
    mp.command_native({'sub-add', get_link(url), flag})
end)