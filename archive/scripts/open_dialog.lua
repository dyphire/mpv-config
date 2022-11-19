--[[
SOURCE_ https://github.com/rossy/mpv-open-file-dialog
COMMIT_ 20160310 04fe818
To the extent possible under law, the author(s) have dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty. See
<https://creativecommons.org/publicdomain/zero/1.0/> for a copy of the CC0
Public Domain Dedication, which applies to this software.

The script calls up a window in mpv to quickly load the file/url/other subtitles/other audio tracks/advanced subtitle filter.
Usage, add bindings to input.conf:
key        script-message-to open_dialog import_files
key        script-message-to open_dialog import_url
key        script-message-to open_dialog append_aid
key        script-message-to open_dialog append_sid
key        script-message-to open_dialog append_vfSub
key        script-message-to open_dialog toggle_vfSub
key        script-message-to open_dialog remove_vfSub
]] --

utils = require 'mp.utils'

local function import_files()
    local was_ontop = mp.get_property_native("ontop")
    if was_ontop then mp.set_property_native("ontop", false) end
    local res = utils.subprocess({
        args = { 'powershell', '-NoProfile', '-Command', [[& {
			Trap {
				Write-Error -ErrorRecord $_
				Exit 1
			}
			Add-Type -AssemblyName PresentationFramework
			$u8 = [System.Text.Encoding]::UTF8
			$out = [Console]::OpenStandardOutput()
			$ofd = New-Object -TypeName Microsoft.Win32.OpenFileDialog
			$ofd.Multiselect = $true
			If ($ofd.ShowDialog() -eq $true) {
				ForEach ($filename in $ofd.FileNames) {
					$u8filename = $u8.GetBytes("$filename`n")
					$out.Write($u8filename, 0, $u8filename.Length)
				}
			}
		}]]    },
        cancellable = false,
    })
    if was_ontop then mp.set_property_native("ontop", true) end
    if (res.status ~= 0) then return end
    local first_file = true
    for filename in string.gmatch(res.stdout, '[^\n]+') do
        mp.commandv('loadfile', filename, first_file and 'replace' or 'append')
        first_file = false
    end
end

local function import_url()
    local was_ontop = mp.get_property_native("ontop")
    if was_ontop then mp.set_property_native("ontop", false) end
    local res = utils.subprocess({
        args = { 'powershell', '-NoProfile', '-Command', [[& {
			Trap {
				Write-Error -ErrorRecord $_
				Exit 1
			}
			Add-Type -AssemblyName Microsoft.VisualBasic
			$u8 = [System.Text.Encoding]::UTF8
			$out = [Console]::OpenStandardOutput()
            $urlname = [Microsoft.VisualBasic.Interaction]::InputBox("Address", "Open", "https://")
            $u8urlname = $u8.GetBytes("$urlname")
            $out.Write($u8urlname, 0, $u8urlname.Length)
		}]]    },
        cancellable = false,
    })
    if was_ontop then mp.set_property_native("ontop", true) end
    if (res.status ~= 0) then return end
    mp.commandv('loadfile', res.stdout)
end

local function append_aid()
    local was_ontop = mp.get_property_native("ontop")
    if was_ontop then mp.set_property_native("ontop", false) end
    local res = utils.subprocess({
        args = { 'powershell', '-NoProfile', '-Command', [[& {
			Trap {
				Write-Error -ErrorRecord $_
				Exit 1
			}
			Add-Type -AssemblyName PresentationFramework
			$u8 = [System.Text.Encoding]::UTF8
			$out = [Console]::OpenStandardOutput()
			$ofd = New-Object -TypeName Microsoft.Win32.OpenFileDialog
			$ofd.Multiselect = $false
			If ($ofd.ShowDialog() -eq $true) {
				ForEach ($filename in $ofd.FileNames) {
					$u8filename = $u8.GetBytes("$filename")
					$out.Write($u8filename, 0, $u8filename.Length)
				}
			}
		}]]    },
        cancellable = false,
    })
    if was_ontop then mp.set_property_native("ontop", true) end
    if (res.status ~= 0) then return end
    for filename in string.gmatch(res.stdout, '[^\n]+') do
        mp.commandv('audio-add', filename, 'cached')
    end
end

local function append_sid()
    local was_ontop = mp.get_property_native("ontop")
    if was_ontop then mp.set_property_native("ontop", false) end
    local res = utils.subprocess({
        args = { 'powershell', '-NoProfile', '-Command', [[& {
			Trap {
				Write-Error -ErrorRecord $_
				Exit 1
			}
			Add-Type -AssemblyName PresentationFramework
			$u8 = [System.Text.Encoding]::UTF8
			$out = [Console]::OpenStandardOutput()
			$ofd = New-Object -TypeName Microsoft.Win32.OpenFileDialog
			$ofd.Multiselect = $false
			If ($ofd.ShowDialog() -eq $true) {
				ForEach ($filename in $ofd.FileNames) {
					$u8filename = $u8.GetBytes("$filename")
					$out.Write($u8filename, 0, $u8filename.Length)
				}
			}
		}]]    },
        cancellable = false,
    })
    if was_ontop then mp.set_property_native("ontop", true) end
    if (res.status ~= 0) then return end
    for filename in string.gmatch(res.stdout, '[^\n]+') do
        mp.commandv('sub-add', filename, 'cached')
    end
end

local function append_vfSub()
    local was_ontop = mp.get_property_native("ontop")
    if was_ontop then mp.set_property_native("ontop", false) end
    local res = utils.subprocess({
        args = { 'powershell', '-NoProfile', '-Command', [[& {
			Trap {
				Write-Error -ErrorRecord $_
				Exit 1
			}
			Add-Type -AssemblyName PresentationFramework
			$u8 = [System.Text.Encoding]::UTF8
			$out = [Console]::OpenStandardOutput()
			$ofd = New-Object -TypeName Microsoft.Win32.OpenFileDialog
			$ofd.Multiselect = $false
			If ($ofd.ShowDialog() -eq $true) {
				ForEach ($filename in $ofd.FileNames) {
					$u8filename = $u8.GetBytes("$filename")
					$out.Write($u8filename, 0, $u8filename.Length)
				}
			}
		}]]    },
        cancellable = false,
    })
    if was_ontop then mp.set_property_native("ontop", true) end
    if (res.status ~= 0) then return end
    for filename in string.gmatch(res.stdout, '[^\n]+') do
        local vfSub = "vf append ``@open_dialog-sub:subtitles=filename=\"" .. res.stdout .. "\"``"
        mp.command(vfSub)
    end
end

local function filter_state(label, key, value)
    local filters = mp.get_property_native("vf")
    for _, filter in pairs(filters) do
        if filter["label"] == label and (not key or key and filter[key] == value) then return true end
    end
    return false
end

local function toggle_vfSub()
    local vfSub = "vf toggle @open_dialog-sub"
    if filter_state("open_dialog-sub") then mp.command(vfSub) end
end

local function remove_vfSub()
    local vfSub = "vf remove @open_dialog-sub"
    if filter_state("open_dialog-sub") then
        mp.msg.info("Cleanup @open_dialog-sub.")
        mp.command(vfSub)
        mp.msg.info("Done.")
    end
end

mp.register_event("end-file", remove_vfSub)

mp.register_script_message('import_files', import_files)
mp.register_script_message('import_url', import_url)
mp.register_script_message('append_aid', append_aid)
mp.register_script_message('append_sid', append_sid)
mp.register_script_message('append_vfSub', append_vfSub)
mp.register_script_message('toggle_vfSub', toggle_vfSub)
mp.register_script_message('remove_vfSub', remove_vfSub)
