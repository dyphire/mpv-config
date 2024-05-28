-- Copyright (c) 2022-2024 dyphire <qimoge@gmail.com>
-- License: MIT
-- link: https://github.com/dyphire/mpv-scripts

--[[
The script calls up a window in mpv to quickly load the folder/files/iso/clipboard (support url)/other subtitles/other audio tracks/other video tracks.
Usage, add bindings to input.conf:
key        script-message-to open_dialog import_folder
key        script-message-to open_dialog import_files
key        script-message-to open_dialog import_files <type>      # vid, aid, sid (video/audio/subtitle track)
key        script-message-to open_dialog import_clipboard
key        script-message-to open_dialog import_clipboard <type>  # vid, aid, sid (video/audio/subtitle track)
key        script-message-to open_dialog set_clipboard <text>     # text can be mpv properties as ${path}
]]--

local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require 'mp.options'

o = {
    video_types = '3g2,3gp,asf,avi,f4v,flv,h264,h265,m2ts,m4v,mkv,mov,mp4,mp4v,mpeg,mpg,ogm,ogv,rm,rmvb,ts,vob,webm,wmv,y4m',
    audio_types = 'aac,ac3,aiff,ape,au,cue,dsf,dts,flac,m4a,mid,midi,mka,mp3,mp4a,oga,ogg,opus,spx,tak,tta,wav,weba,wma,wv',
    image_types = 'apng,avif,bmp,gif,j2k,jp2,jfif,jpeg,jpg,jxl,mj2,png,svg,tga,tif,tiff,webp',
    subtitle_types = 'aqt,ass,gsub,idx,jss,lrc,mks,pgs,pjs,psb,rt,sbv,slt,smi,sub,sup,srt,ssa,ssf,ttxt,txt,usf,vt,vtt',
    playlist_types = 'm3u,m3u8,pls,cue',
    iso_types = 'iso',
}
options.read_options(o)

local function split(input)
    local ret = {}
    for str in string.gmatch(input, "([^,]+)") do
        ret[#ret + 1] = string.format("*.%s", str)
    end
    return ret
end

-- pre-defined file types
local file_types = {
    video = table.concat(split(o.video_types), ';'),
    audio = table.concat(split(o.audio_types), ';'),
    image = table.concat(split(o.image_types), ';'),
    iso = table.concat(split(o.iso_types), ';'),
    subtitle = table.concat(split(o.subtitle_types), ';'),
    playlist = table.concat(split(o.playlist_types), ';'),
}

local powershell = nil

local function pwsh_check()
    local arg = {"cmd", "/c", "pwsh", "--version"}
    local res = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = arg})
    if res.status ~= 0 or res.stdout:match("^PowerShell") == nil then
        powershell = "powershell"
    else
        powershell = "pwsh"
    end
end

-- https://github.com/mpv-player/mpv/blob/master/etc/mpv-icon-8bit-16x16.png
local mpv_icon_base64 = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAACvklEQVQ4y3WTSWhUWRSGv/MmU1UpwYSoFbs0VXFo7IhTowgaJGrEhbYLFw44LNqFjWD3Og3dLsSFLlwILgRbXShuXPRCEcUhEUQRIyZROnGImipRkjhVXr2q9+69LrpSiMOBs7nn8t9z7v8d4esQwKqkVM4MoCtpvrz8edhL61obG+KTf3fEaReRZkFcbfRAaKKLw/6bI7dHO/OA+paAuza1YWvcTRwVpPYbnWEwBT8c23vp1b9ngBDArtSc9tT67bVu8h9BPICmWRl+Xr2YzNwMumx4P/oOQTzP9jam401PnxT6ewEtgCyZtHz2tGT6niDxmpoYew79yoK2FrTWKKXQWtN9tZcTf56mFAQYjJ/7+HLRnbc3+y3ArY817BMkDrDn8G4WtLVw8q+zvBkaRmuN1pp5rT+y8++tlbklXh9r2Ae4FjDBs712gMzsLPNXzkUpxcDdJxz57RgXTl4h8EsopfhpxRx+yKQB8GxvDeBZgGuJ1QQwc1G2+mIYhRT9IhdPXWL/joN0dz1AKcWMef8LWGJlAM+p+B0CtjGmKhCUivgln6BcxC5bRGGE1hqjqxiEgOUARhmVd8TJPu5+Wv20QlBAmYg1m1exdlsbtmujtWaw9wUAyqg8YBwgKoZ+V9KbmB3sf8b9a320rJjDzIXNbNr7C/VTJ1W76rnxiPxgDoBi6HcBkQ1YEsnrKYnUFkGcns4+UtkU63atJpaoqVrZd/M/zh08j1IKgwkejfT+8TYaGZIKTHXL6lfuTiUaD4wPmG6ezoyWNNponve8JPdsqErkq7F8x62R68eB0XGUJwBTlta17misndYhSM13UA7yhdyB26Odp4HXQGkcZQ2Uc8XnA37gX4u5cXEsJ2mJFQNUpKOhD+X3F/pGHnQ8LNy/DAwDpS+XSQAPSAITgQTgfmbZGPAB+AiUx9f6E25gOc5E3m0HAAAAAElFTkSuQmCC"

local function end_file(event)
    mp.unregister_event(end_file)
    if event["reason"] == "eof" or event["reason"] == "stop" or event["reason"] == "error" then
        local bd_device = mp.get_property_native("bluray-device")
        local dvd_device = mp.get_property_native("dvd-device")
        if event["reason"] == "error" and bd_device and bd_device ~= "" then
            loaded_fail = true
        else
            loaded_fail = false
        end
        if bd_device then mp.set_property("bluray-device", "") end
        if dvd_device then mp.set_property("dvd-device", "") end
    end
end

-- open bluray iso or dir
local function open_bluray(path)
    mp.set_property('bluray-device', path)
    mp.commandv('loadfile', 'bd://')
end

-- open dvd iso or dir
local function open_dvd(path)
    mp.set_property('dvd-device', path)
    mp.commandv('loadfile', 'dvd://')
end

-- open folder
local function open_folder(path, i)
    local fpath, dir = utils.split_path(path)
    if utils.file_info(utils.join_path(path, "BDMV")) then
        open_bluray(path)
    elseif utils.file_info(utils.join_path(path, "VIDEO_TS")) then
        open_dvd(path)
    elseif dir:upper() == "BDMV" then
        open_bluray(fpath)
    elseif dir:upper() == "VIDEO_TS" then
        open_dvd(fpath)
    else
        mp.commandv('loadfile', path, i == 1 and 'replace' or 'append')
    end
end

-- open files
local function open_files(path, type, i, is_clip)
    local ext = string.match(path, "%.([^%.]+)$"):lower()
    if file_types['subtitle']:match(ext) then
        mp.commandv('sub-add', path, 'cached')
    elseif type == 'vid' and (not is_clip or (file_types['video']:match(ext) or file_types['image']:match(ext))) then
        mp.commandv('video-add', path, 'cached')
    elseif type == 'aid' and (not is_clip or file_types['audio']:match(ext)) then
        mp.commandv('audio-add', path, 'cached')
    elseif file_types['iso']:match(ext) then
        local idle = mp.get_property('idle')
        if idle ~= 'yes' then mp.set_property('idle', 'yes') end
        mp.register_event("end-file", end_file)
        open_bluray(path)
        mp.add_timeout(1.0, function()
            if idle ~= 'yes' then mp.set_property('idle', idle) end
            if loaded_fail then
                loaded_fail = false
                open_dvd(path)
            end
        end)
    else
        mp.commandv('loadfile', path, i == 1 and 'replace' or 'append')
    end
end

-- import folder
local function import_folder()
    if not powershell then pwsh_check() end
    local was_ontop = mp.get_property_native("ontop")
    if was_ontop then mp.set_property_native("ontop", false) end
    local powershell_script = string.format([[
        Add-Type -AssemblyName System.Windows.Forms
        $u8 = [System.Text.Encoding]::UTF8
        $out = [Console]::OpenStandardOutput()
        $TopForm = New-Object System.Windows.Forms.Form
        $TopForm.TopMost = $true
        $TopForm.ShowInTaskbar = $false
        $TopForm.Visible = $false
        $IconBytes = [Convert]::FromBase64String("%s")
        $IconStream = New-Object IO.MemoryStream($IconBytes, 0, $IconBytes.Length)
        $IconStream.Write($IconBytes, 0, $IconBytes.Length);
        $TopForm.Icon = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $IconStream).GetHIcon())
        $folderBrowser = New-Object -TypeName System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.RootFolder = "Desktop"
        $folderBrowser.ShowNewFolderButton = $true
        $result = $folderBrowser.ShowDialog($TopForm)
        if ($result -eq "OK") {
            $selectedFolder = $folderBrowser.SelectedPath
            $u8selectedFolder = $u8.GetBytes("$selectedFolder`n")
            $out.Write($u8selectedFolder, 0, $u8selectedFolder.Length)
        }
        $TopForm.Dispose()
    ]], mpv_icon_base64)

    local res = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        capture_stdout = true,
        args = { powershell, '-NoProfile', '-Command', powershell_script },
    })

    if was_ontop then mp.set_property_native("ontop", true) end
    if (res.status ~= 0) then
        mp.osd_message("Failed to open folder dialog.")
    elseif res.stdout and res.stdout ~= "" then
        local folder_path = res.stdout:match("(.-)[\r\n]?$") -- Trim any trailing newline
        open_folder(folder_path, 1)
    end
end

-- import files
local function import_files(type)
    if not powershell then pwsh_check() end
    local filter = ''
    local was_ontop = mp.get_property_native("ontop")
    if was_ontop then mp.set_property_native("ontop", false) end

    if type == 'vid' then
        filter = string.format("Video Files|%s|Image Files|%s", file_types['video'], file_types['image'])
    elseif type == 'aid' then
        filter = string.format("Audio Files|%s", file_types['audio'])
    elseif type == 'sid' then
        filter = string.format("Subtitle Files|%s", file_types['subtitle'])
    else
        filter = string.format("All Files (*.*)|*.*|Video Files|%s|Audio Files|%s|Image Files|%s|ISO Files|%s|Subtitle Files|%s|Playlist Files|%s",
            file_types['video'], file_types['audio'], file_types['image'], file_types['iso'], file_types['subtitle'], file_types['playlist'])
    end

    local res = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        capture_stdout = true,
        args = { powershell, '-NoProfile', '-Command', string.format([[& {
            Trap {
                Write-Error -ErrorRecord $_
                Exit 1
            }
            Add-Type -AssemblyName System.Windows.Forms
            $u8 = [System.Text.Encoding]::UTF8
            $out = [Console]::OpenStandardOutput()
            $TopForm = New-Object System.Windows.Forms.Form
            $TopForm.TopMost = $true
            $TopForm.ShowInTaskbar = $false
            $TopForm.Visible = $false
            $IconBytes = [Convert]::FromBase64String("%s")
            $IconStream = New-Object IO.MemoryStream($IconBytes, 0, $IconBytes.Length)
            $IconStream.Write($IconBytes, 0, $IconBytes.Length);
            $TopForm.Icon = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $IconStream).GetHIcon())
            $ofd = New-Object System.Windows.Forms.OpenFileDialog
            $ofd.Multiselect = $true
            $ofd.Filter = "%s"
            If ($ofd.ShowDialog($TopForm) -eq $true) {
                ForEach ($filename in $ofd.FileNames) {
                    $u8filename = $u8.GetBytes("$filename`n")
                    $out.Write($u8filename, 0, $u8filename.Length)
                }
            }
            $TopForm.Dispose()
        }]], mpv_icon_base64, filter) }
    })
    if was_ontop then mp.set_property_native("ontop", true) end
    if (res.status ~= 0) then return end
    local i = 0
    for path in string.gmatch(res.stdout, '[^\r\n]+') do
        i = i + 1
        open_files(path, type, i, false)
    end
end

-- Returns a string of UTF-8 text from the clipboard
local function get_clipboard()
    local res = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        capture_stdout = true,
        args = { 'powershell', '-NoProfile', '-Command', [[& {
            Trap {
                Write-Error -ErrorRecord $_
                Exit 1
            }
            $clip = Get-Clipboard -Raw -Format Text -TextFormatType UnicodeText
            if (-not $clip) {
                $clip = Get-Clipboard -Raw -Format FileDropList
            }
            $u8clip = [System.Text.Encoding]::UTF8.GetBytes($clip)
            [Console]::OpenStandardOutput().Write($u8clip, 0, $u8clip.Length)
        }]] }
    })
    if not res.error then
        return res.stdout
    end
    return ''
end

-- open files from clipboard
local function open_clipboard(path, type, i)
    local path = path:gsub("^[\'\"]", ""):gsub("[\'\"]$", ""):gsub('^%s+', ''):gsub('%s+$', '')
    if path:find('^%a[%w.+-]-://') then
        mp.commandv('loadfile', path, i == 1 and 'replace' or 'append')
    else
        local meta = utils.file_info(path)
        if not meta then
            mp.osd_message('Clipboard path is invalid')
            msg.warn('Clipboard path is invalid')
        elseif meta.is_dir then
            open_folder(path, i)
        elseif meta.is_file then
            open_files(path, type, i, true)
        else
            mp.osd_message('Clipboard path is invalid')
            msg.warn('Clipboard path is invalid')
        end
    end
end

-- import clipboard
local function import_clipboard(type)
    local clip = get_clipboard()
    if clip ~= '' then
        local i = 0
        for path in string.gmatch(clip, '[^\r\n]+') do
            i = i + 1
            open_clipboard(path, type, i)
        end
    else
        mp.osd_message('Clipboard is empty')
        msg.warn('Clipboard is empty')
    end
end

-- escapes a string so that it can be inserted into powershell as a string literal
local function escape_powershell(str)
    return '"'..string.gsub(str, '[$"`]', '`%1')..'"'
end

-- sets the contents of the clipboard to the given string
local function set_clipboard(text)
    msg.verbose('setting clipboard text:', text)
    mp.commandv('run', 'powershell', '-NoProfile', '-command', 'set-clipboard', escape_powershell(text))
end

mp.register_script_message('import_folder', import_folder)
mp.register_script_message('import_files', import_files)
mp.register_script_message('import_clipboard', import_clipboard)
mp.register_script_message('set_clipboard', set_clipboard)
