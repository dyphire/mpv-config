--[[
SOURCE_ https://github.com/rossy/mpv-open-file-dialog
COMMIT_ 20160310 04fe818
To the extent possible under law, the author(s) have dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty. See
<https://creativecommons.org/publicdomain/zero/1.0/> for a copy of the CC0
Public Domain Dedication, which applies to this software.
自定义快捷键 在mpv中唤起一个打开文件的窗口用于快速加载文件/网址
示例：在 input.conf 中另起写入下列内容
w        script-binding    open_dialog/import_files   # 打开文件
W        script-binding    open_dialog/import_url     # 载入网址
CTRL+w   script-binding    open_dialog/append_aid     # 加载其它音轨（不切换）
ALT+w    script-binding    open_dialog/append_sid     # 加载其它字幕（切换
e        script-binding    open_dialog/append_vfSub   # 装载次字幕（滤镜型）
E        script-binding    open_dialog/toggle_vfSub   # 隐藏/显示 当前的次字幕
CTRL+e   script-binding    open_dialog/remove_vfSub   # 移除次字幕
]]--

utils = require 'mp.utils'

function import_files()
	local was_ontop = mp.get_property_native("ontop")
	if was_ontop then mp.set_property_native("ontop", false) end
	local res = utils.subprocess({
		args = {'powershell', '-NoProfile', '-Command', [[& {
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
		}]]},
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


function import_url()
	local was_ontop = mp.get_property_native("ontop")
	if was_ontop then mp.set_property_native("ontop", false) end
	local res = utils.subprocess({
		args = {'powershell', '-NoProfile', '-Command', [[& {
			Trap {
				Write-Error -ErrorRecord $_
				Exit 1
			}
			Add-Type -AssemblyName Microsoft.VisualBasic
			$u8 = [System.Text.Encoding]::UTF8
			$out = [Console]::OpenStandardOutput()
            $urlname = [Microsoft.VisualBasic.Interaction]::InputBox("输入地址", "打开", "https://")
            $u8urlname = $u8.GetBytes("$urlname")
            $out.Write($u8urlname, 0, $u8urlname.Length)
		}]]},
		cancellable = false,
	})
	if was_ontop then mp.set_property_native("ontop", true) end
	if (res.status ~= 0) then return end
	mp.commandv('loadfile', res.stdout)
end


function append_aid()
	local was_ontop = mp.get_property_native("ontop")
	if was_ontop then mp.set_property_native("ontop", false) end
	local res = utils.subprocess({
		args = {'powershell', '-NoProfile', '-Command', [[& {
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
		}]]},
		cancellable = false,
	})
	if was_ontop then mp.set_property_native("ontop", true) end
	if (res.status ~= 0) then return end
	for filename in string.gmatch(res.stdout, '[^\n]+') do
		mp.commandv('audio-add', filename, 'auto')
	end
end


function append_sid()
	local was_ontop = mp.get_property_native("ontop")
	if was_ontop then mp.set_property_native("ontop", false) end
	local res = utils.subprocess({
		args = {'powershell', '-NoProfile', '-Command', [[& {
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
		}]]},
		cancellable = false,
	})
	if was_ontop then mp.set_property_native("ontop", true) end
	if (res.status ~= 0) then return end
	for filename in string.gmatch(res.stdout, '[^\n]+') do
		mp.commandv('sub-add', filename, 'cached')
	end
end


function append_vfSub()
	local was_ontop = mp.get_property_native("ontop")
	if was_ontop then mp.set_property_native("ontop", false) end
	local res = utils.subprocess({
		args = {'powershell', '-NoProfile', '-Command', [[& {
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
		}]]},
		cancellable = false,
	})
	if was_ontop then mp.set_property_native("ontop", true) end
	if (res.status ~= 0) then return end
	for filename in string.gmatch(res.stdout, '[^\n]+') do
		local vfSub = "vf append ``@LUA-open_dialog:subtitles=filename=\"" .. res.stdout .. "\"``"
		mp.command(vfSub)
	end
end
function toggle_vfSub()
	local vfSub = "vf toggle @LUA-open_dialog"
	mp.command(vfSub)
end
function remove_vfSub()
	local vfSub = "vf remove @LUA-open_dialog"
	mp.command(vfSub)
end



mp.add_key_binding(nil, 'import_files', import_files)
mp.add_key_binding(nil, 'import_url', import_url)
mp.add_key_binding(nil, 'append_aid', append_aid)
mp.add_key_binding(nil, 'append_sid', append_sid)
mp.add_key_binding(nil, 'append_vfSub', append_vfSub)
mp.add_key_binding(nil, 'toggle_vfSub', toggle_vfSub)
mp.add_key_binding(nil, 'remove_vfSub', remove_vfSub)