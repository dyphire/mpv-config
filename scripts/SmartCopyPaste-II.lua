-- Copyright (c) 2021, Eisa AlAwadhi
-- License: BSD 2-Clause License

-- Creator: Eisa AlAwadhi
-- Project: SmartCopyPaste-II
-- Version: 2.4.1

local utils = require 'mp.utils'
local msg = require 'mp.msg'
local protocols
local extensions
local pasted = false

----------------------------USER CUSTOMIZATION SETTINGS-----------------------------------
--These settings are for users to manually change some options in the script.
--Keybinds can be defined in the bottom of the script.

local device = nil --nil is for automatic device detection, OR manually change to: 'windows' or 'mac' or 'linux'

local linux_copy = 'xclip -silent -selection clipboard -in' --copy command that will be used in Linux. OR write a different command
local linux_paste = 'xclip -selection clipboard -o' --paste command that will be used in Linux. OR write a different command

local mac_copy = 'pbcopy' --copy command that will be used in MAC. OR write a different command
local mac_paste = 'pbpaste' --paste command that will be used in MAC. OR write a different command

local windows_copy = 'powershell' --'powershell' is for using windows powershell to copy. OR write the copy command, e.g: ' clip'
local windows_paste = 'powershell' --'powershell' is for using windows powershell to paste. OR write the paste command

local offset = -0.65 --change to 0 so that pasting resumes from the exact position, or decrease the value so that it gives you a little preview before reaching the exact pasted position

local paste_anything = false --false is for specific paste based on the specified extensions and protocols. OR change to true so paste accepts anything (not recommended to change this).

if not paste_anything then
	protocols = { --add below (after a comma) any protocol you want SmartCopyPaste to work with; e.g: ,'ftp://'
		'https?://' ,'magnet:'
	}
	extensions = { --add below (after a comma) any extension you want SmartCopyPaste to work with; e.g: ,'pdf'
		--video & audio
		'ac3', 'a52', 'eac3', 'mlp', 'dts', 'dts-hd', 'dtshd', 'true-hd', 'thd', 'truehd', 'thd+ac3', 'tta', 'pcm', 'wav', 'aiff', 'aif',  'aifc', 'amr', 'awb', 'au', 'snd', 'lpcm', 'yuv', 'y4m', 'ape', 'wv', 'shn', 'm2ts', 'm2t', 'mts', 'mtv', 'ts', 'tsv', 'tsa', 'tts', 'trp', 'adts', 'adt', 'mpa', 'm1a', 'm2a', 'mp1', 'mp2', 'mp3', 'mpeg', 'mpg', 'mpe', 'mpeg2', 'm1v', 'm2v', 'mp2v', 'mpv', 'mpv2', 'mod', 'tod', 'vob', 'vro', 'evob', 'evo', 'mpeg4', 'm4v', 'mp4', 'mp4v', 'mpg4', 'm4a', 'aac', 'h264', 'avc', 'x264', '264', 'hevc', 'h265', 'x265', '265', 'flac', 'oga', 'ogg', 'opus', 'spx', 'ogv', 'ogm', 'ogx', 'mkv', 'mk3d', 'mka', 'webm', 'weba', 'avi', 'vfw', 'divx', '3iv', 'xvid', 'nut', 'flic', 'fli', 'flc', 'nsv', 'gxf', 'mxf', 'wma', 'wm', 'wmv', 'asf', 'dvr-ms', 'dvr', 'wtv', 'dv', 'hdv', 'flv','f4v', 'f4a', 'qt', 'mov', 'hdmov', 'rm', 'rmvb', 'ra', 'ram', '3ga', '3ga2', '3gpp', '3gp', '3gp2', '3g2', 'ay', 'gbs', 'gym', 'hes', 'kss', 'nsf', 'nsfe', 'sap', 'spc', 'vgm', 'vgz', 'm3u', 'm3u8', 'pls', 'cue',
		--images
		"ase", "art", "bmp", "blp", "cd5", "cit", "cpt", "cr2", "cut", "dds", "dib", "djvu", "egt", "exif", "gif", "gpl", "grf", "icns", "ico", "iff", "jng", "jpeg", "jpg", "jfif", "jp2", "jps", "lbm", "max", "miff", "mng", "msp", "nitf", "ota", "pbm", "pc1", "pc2", "pc3", "pcf", "pcx", "pdn", "pgm", "PI1", "PI2", "PI3", "pict", "pct", "pnm", "pns", "ppm", "psb", "psd", "pdd", "psp", "px", "pxm", "pxr", "qfx", "raw", "rle", "sct", "sgi", "rgb", "int", "bw", "tga", "tiff", "tif", "vtf", "xbm", "xcf", "xpm", "3dv", "amf", "ai", "awg", "cgm", "cdr", "cmx", "dxf", "e2d", "egt", "eps", "fs", "gbr", "odg", "svg", "stl", "vrml", "x3d", "sxd", "v2d", "vnd", "wmf", "emf", "art", "xar", "png", "webp", "jxr", "hdp", "wdp", "cur", "ecw", "iff", "lbm", "liff", "nrrd", "pam", "pcx", "pgf", "sgi", "rgb", "rgba", "bw", "int", "inta", "sid", "ras", "sun", "tga",
		--other types
		'torrent'
	}
---------------------------END OF USER CUSTOMIZATION SETTINGS------------------------
else
	protocols = {''}
	extensions = {''}
end

if not device then
	if os.getenv('windir') ~= nil then
		device = 'windows'
	elseif os.execute '[ -d "/Applications" ]' == 0 and os.execute '[ -d "/Library" ]' == 0 or os.execute '[ -d "/Applications" ]' == true and os.execute '[ -d "/Library" ]' == true then
		device = 'mac'
	else
		device = 'linux'
  end
end

function handleres(res, args)
  if not res.error and res.status == 0 then
	return res.stdout
  else
    msg.error("There was an error getting "..device.." clipboard: ")
    msg.error("  Status: "..(res.status or ""))
    msg.error("  Error: "..(res.error or ""))
    msg.error("  stdout: "..(res.stdout or ""))
    msg.error("args: "..utils.to_string(args))
    return ''
  end
end

function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

local function get_extension(path)
    match = string.match(path, '%.([^%.]+)$' )
    if match == nil then
        return 'nomatch'
    else
        return match
    end
end

local function get_extentionpath(path)
    match = string.match(path,'(.*)%.([^%.]+)$')
    if match == nil then
        return 'nomatch'
    else
        return match
    end
end

local function has_extension (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function starts_protocol (tab, val)
    for index, value in ipairs(tab) do
        if (val:find(value) == 1) then
            return true
        end
	end
    return false
end


function get_clipboard()
local clip
  if device == 'linux' then
	clip = os.capture(linux_paste, false)
	return clip
  elseif device == 'windows' then
	if windows_paste == 'powershell' then
		local args = {
		  'powershell', '-NoProfile', '-Command', [[& {
				Trap {
					Write-Error -ErrorRecord $_
					Exit 1
				}
				$clip = Get-Clipboard -Raw -Format Text -TextFormatType UnicodeText
				if ($clip) {
					$clip = $clip
					}
				else {
					$clip = Get-Clipboard -Raw -Format FileDropList
				}
				$u8clip = [System.Text.Encoding]::UTF8.GetBytes($clip)
				[Console]::OpenStandardOutput().Write($u8clip, 0, $u8clip.Length)
			}]]
		}
		return handleres(utils.subprocess({ args =  args, cancellable = false }), args)
	else
		clip = os.capture(windows_paste, false)
		return clip
	end
  elseif device == 'mac' then
	clip = os.capture(mac_paste, false)
	return clip
  end
  return ''
end


function set_clipboard(text)
	local pipe
	if device == 'linux' then
		pipe = io.popen(linux_copy, 'w')
		pipe:write(text)
		pipe:close()
	elseif device == 'windows' then
		if windows_copy == 'powershell' then
			local res = utils.subprocess({ args = {
				'powershell', '-NoProfile', '-Command', string.format([[& {
					Trap {
						Write-Error -ErrorRecord $_
						Exit 1
					}
					Add-Type -AssemblyName PresentationCore
					[System.Windows.Clipboard]::SetText('%s')
				}]], text)
			} })
		else
			pipe = io.popen(windows_copy,'w')
			pipe:write(text)
			pipe:close()
		end
	elseif device == 'mac' then
		pipe = io.popen(mac_copy,'w')
		pipe:write(text)
		pipe:close()
	  end
  return ''
end


local function copy()
    local filePath = mp.get_property_native('path')
	
	if (filePath ~= nil) then
		local time = math.floor(mp.get_property_number('time-pos'))	

		mp.osd_message('Copied & Bookmarked:\n'..filePath..' |time='..tostring(time))
		set_clipboard(filePath..' |time='..tostring(time))
		
		local copyLog = (os.getenv('APPDATA') or os.getenv('HOME')..'/.config')..'/mpv/mpvClipboard.log'
		local copyLogAdd = io.open(copyLog, 'a+')
		
		copyLogAdd:write(('[%s] %s\n'):format(os.date('%d/%b/%y %X'), filePath..' |time='..tostring(time)))
		copyLogAdd:close()
	else
		mp.osd_message('Failed to Copy\nNo Video Found')
	end
end


local function copy_path()
	local filePath = mp.get_property_native('path')

	if (filePath ~= nil) then
		mp.osd_message('Copied & Bookmarked Video Only:\n'..filePath)

		set_clipboard(filePath)
		
		local copyLog = (os.getenv('APPDATA') or os.getenv('HOME')..'/.config')..'/mpv/mpvClipboard.log'
		local copyLogAdd = io.open(copyLog, 'a+')
		
		copyLogAdd:write(('[%s] %s\n'):format(os.date('%d/%b/%y %X'), filePath))    
		copyLogAdd:close()
	else
		return false
	end
end


function paste()
	mp.osd_message("Pasting...")
	local clip = get_clipboard()
	clip = string.gsub(clip, "[\r\n]" , "")
	
	local filePath = mp.get_property_native('path')
	local time

	if string.match(clip, '(.*) |time=') then
		videoFile = string.match(clip, '(.*) |time=')
		time = string.match(clip, ' |time=(.*)')
	elseif string.match(clip, '^\"(.*)\"$') then
		videoFile = string.match(clip, '^\"(.*)\"$')
	else
		videoFile = clip
	end
	
	local currentVideoExtension = string.lower(get_extension(videoFile))
	local currentVideoExtensionPath = (get_extentionpath(videoFile))
	
	local copyLog = (os.getenv('APPDATA') or os.getenv('HOME')..'/.config')..'/mpv/mpvClipboard.log'
	local copyLogAdd = io.open(copyLog, 'a+')
	local copyLogOpen = io.open(copyLog, 'r+')

	local linePosition
	local videoFound = ''
	local logVideo
	local logVideoTime
	
	local seekTime
	local seekLogVideoTime
	
	for line in copyLogOpen:lines() do
	
		linePosition = line:find(']')
		line = line:sub(linePosition + 2)
	   
		if line.match(line, '(.*) |time=') == filePath then
			videoFound = line
		end
	end


	logVideo = string.match(videoFound, '(.*) |time=')
	logVideoTime = string.match(videoFound, ' |time=(.*)')
	
	if (filePath == videoFile) and (time ~= nil) then
		mp.osd_message('Pasted Copied Time')

		seekTime = time + offset
		if (seekTime < 0) then
			seekTime = 0
		end
	
		mp.commandv('seek', seekTime, 'absolute', 'exact')
	elseif (filePath == logVideo) and (logVideoTime ~= nil) then
		mp.osd_message('Pasted Last Logged Time')

		seekLogVideoTime = logVideoTime + offset
		if (seekLogVideoTime < 0) then
			seekLogVideoTime = 0
		end
		
		mp.commandv('seek', seekLogVideoTime, 'absolute', 'exact')
	elseif (filePath ~= nil) and (logVideoTime == nil) then
		mp.osd_message('No Copied Time Found')
	elseif (filePath == nil) and has_extension(extensions, currentVideoExtension) and (currentVideoExtensionPath~= '') then
		mp.osd_message('Pasted:\n'..videoFile)

		mp.commandv('loadfile', videoFile)
		
		if (time ~= nil) then
			copyLogAdd:write(('[%s] %s\n'):format(os.date('%d/%b/%y %X'), videoFile..' |time='..tostring(time)))
		else
			copyLogAdd:write(('[%s] %s\n'):format(os.date('%d/%b/%y %X'), videoFile))
		end
	elseif (filePath == nil) and (starts_protocol(protocols, videoFile)) then
		mp.osd_message('Pasted:\n'..videoFile)
		
		mp.commandv('loadfile', videoFile)
		
		if (time ~= nil) then
			copyLogAdd:write(('[%s] %s\n'):format(os.date('%d/%b/%y %X'), videoFile..' |time='..tostring(time)))
		else
			copyLogAdd:write(('[%s] %s\n'):format(os.date('%d/%b/%y %X'), videoFile))
		end
    elseif (filePath == nil) and not has_extension(extensions, currentVideoExtension) and not (starts_protocol(protocols, videoFile)) then
		copyLogLastOpen = io.open(copyLog, 'r+')

		for line in copyLogLastOpen:lines() do
			lastVideoFound = line
		end
	
		if (lastVideoFound ~= nil) then
			linePosition = lastVideoFound:find(']')
			lastVideoFound = lastVideoFound:sub(linePosition + 2)
			
			if string.match(lastVideoFound, '(.*) |time=') then
				videoFile = string.match(lastVideoFound, '(.*) |time=')
			else
				videoFile = lastVideoFound
			end
			
			mp.osd_message('Pasted Last Logged Item:\n'..videoFile)
			
			mp.commandv('loadfile', videoFile)
		else 
			mp.osd_message('Failed to Paste\nPasted Unsupported Item:\n'..clip)
		end
		copyLogLastOpen:close()
	end
	
	pasted = true
	copyLogAdd:close()
	copyLogOpen:close()
end

function paste_playlist()
	mp.osd_message("Pasting...")
	local clip = get_clipboard()
	clip = string.gsub(clip, "[\r\n]" , "")

	local filePath = mp.get_property_native('path')
	local time
	
	if string.match(clip, '(.*) |time=') then
		videoFile = string.match(clip, '(.*) |time=')
		time = string.match(clip, ' |time=(.*)')
	elseif string.match(clip, '^\"(.*)\"$') then
		videoFile = string.match(clip, '^\"(.*)\"$')
	else
		videoFile = clip
	end
	
	local copyLog = (os.getenv('APPDATA') or os.getenv('HOME')..'/.config')..'/mpv/mpvClipboard.log'
	local copyLogAdd = io.open(copyLog, 'a+')
	local copyLogOpen = io.open(copyLog, 'r+')
	
	local currentVideoExtension = string.lower(get_extension(videoFile))
	local currentVideoExtensionPath = (get_extentionpath(videoFile))
	
	if has_extension(extensions, currentVideoExtension) and (currentVideoExtensionPath~= '') or (starts_protocol(protocols, videoFile)) then
		mp.osd_message('Pasted Into Playlist:\n'..videoFile)
				
		mp.commandv('loadfile', videoFile, 'append-play')
		
		if (time ~= nil) then
			copyLogAdd:write(('[%s] %s\n'):format(os.date('%d/%b/%y %X'), videoFile..' |time='..tostring(time)))
		else
			copyLogAdd:write(('[%s] %s\n'):format(os.date('%d/%b/%y %X'), videoFile))
		end
	else
		mp.osd_message('Failed to Add Into Playlist\nPasted Unsupported Item:\n'..clip)
	end
	
	pasted = true
	copyLogAdd:close()
	copyLogOpen:close()
end

mp.register_event('end-file', function()
	pasted = false
end)

mp.register_event('file-loaded', function()
	if (pasted == true) then
		local clip = get_clipboard()
		local time = string.match(clip, ' |time=(.*)')
		local videoFile = string.match(clip, '(.*) |time=')
		local filePath = mp.get_property_native('path')
		
		local seekTime

		if (filePath == videoFile) and (time ~= nil) then
		
			seekTime = time + offset
			if (seekTime < 0) then
				seekTime = 0
			end
		
			mp.commandv('seek', seekTime, 'absolute', 'exact')
		end	
	else
		return false
	end
end)

---------------------------KEYBINDS CUSTOMIZATION SETTINGS---------------------------------
if device == 'mac' then --MAC OS Keybinds
	mp.add_key_binding('Meta+c', 'copy', copy)
	mp.add_key_binding('Meta+C', 'copyCaps', copy)
	mp.add_key_binding('Meta+v', 'paste', paste)
	mp.add_key_binding('Meta+V', 'pasteCaps', paste)

	mp.add_key_binding('Meta+alt+c', 'copy-path', copy_path)
	mp.add_key_binding('Meta+alt+C', 'copy-pathCaps', copy_path)
	mp.add_key_binding('Meta+alt+v', 'paste-playlist', paste_playlist)
	mp.add_key_binding('Meta+alt+V', 'paste-playlistCaps', paste_playlist)
else --Windows and Linux Keybinds
	mp.add_key_binding('ctrl+c', 'copy', copy)
	mp.add_key_binding('ctrl+C', 'copyCaps', copy)
	mp.add_key_binding('ctrl+v', 'paste', paste)
	mp.add_key_binding('ctrl+V', 'pasteCaps', paste)

	mp.add_key_binding('ctrl+alt+c', 'copy-path', copy_path)
	mp.add_key_binding('ctrl+alt+C', 'copy-pathCaps', copy_path)
	mp.add_key_binding('ctrl+alt+v', 'paste-playlist', paste_playlist)
	mp.add_key_binding('ctrl+alt+V', 'paste-playlistCaps', paste_playlist)
end
---------------------END OF KEYBINDS CUSTOMIZATION SETTINGS---------------------------------
