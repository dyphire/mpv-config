This page contains a list of addons available for file browser.
Some are maintained in this repository, some are maintained elsewhere,
some may have been small scripts I wrote for individual users in issue requests.

If you have written an addon please feel free to add it to this list.

## Parsers

[**apache-browser**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/apache-browser.lua)  
Implements support for http/https directory indexes that apache servers dynamically generate.
I don't know if this will work on different types of servers.
Requires `curl` in the system PATH.

[**ftp-browser**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/ftp-browser.lua)  
Implements support for ftp file servers. Requires `curl` in the system path.

[**ls**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/ls.lua)  
Implements standard directory parsing using the linux `ls` utility.
This behaves near identically to the native parser, but IO is done asynchronously.

[**m3u-browser**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/m3u-browser.lua)  
Adds limited support for m3u playlists. Requires that [mpv-read-file](https://github.com/CogentRedTester/mpv-read-file) be installed.

[**powershell**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/powershell.lua)  
Read the contents of select drives using Powershell.
This behaves near identically to the native parser, but IO is done asynchronously.

[**windir**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/windir.lua)  
Implements standard directory parsing using the windows `cmd dir` command.
This behaves near identically to the native parser, but IO is done asynchronously.
Faster than the Powershell parser.

## Custom Directories

[**favourites**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/favourites.lua)  
Implements a virtual directory of favourited files and folders.

## Wrappers

[**filter-paths**](https://github.com/CogentRedTester/mpv-file-browser/issues/52#issuecomment-1124838997)  
Hides directories or files that match the specified absolute paths.

[**filter-recyclebin**](https://github.com/CogentRedTester/mpv-file-browser/issues/52#issuecomment-1120615541)  
Hides the `$RECYCLE.BIN` directories on windows drives.

[**home-label**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/home-label.lua)  
Replaces the user's home directory in the directory header with `~/`.

[**sort-date**](https://github.com/CogentRedTester/mpv-file-browser/issues/82#issuecomment-1342220863)  
Toggles between sorting by last modified and sorting alphabetically when the `^` key is pressed.

[**url-decode**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/url-decode.lua)  
Decodes URL directories to make them more readable. Does not decode the names of items in the list.

## Other

[**dvd-browser**](https://github.com/CogentRedTester/mpv-dvd-browser)  
This script implements support for viewing DVD titles using the `lsdvd` commandline utility,
along with some other features to improve DVD playback.
Note that `lsdvd` is only available on linux, but the script has special support for WSL on windows 10.
Can be loaded as an addon by file-browser so that when playing a dvd, or when moving into the `--dvd-device` directory,
the add-on shows the DVD titles.

[**find**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/find.lua)  
Allows one to search the contents of the directory with `Ctrl+f`. Use `Ctrl+F` for Lua pattern support. Use `n` to cycle through results.
Requires [mpv-user-input](https://github.com/CogentRedTester/mpv-user-input).

[**refresh-directory**](https://github.com/CogentRedTester/mpv-file-browser/issues/61#issuecomment-1148133504)  
Creates a script-message that refreshes the specified directory.

[**root**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/root.lua)  
An addon that loads root items from a `~~/script-opts/file-browser-root.json` file.
The contents of this file will override the root script-opt.
The main purpose of this addon is to allow for users to customise the appearance of their root items
using the label or ass fields

[**winroot**](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/winroot.lua)  
Automatically populates the root with windows drives.

## Non Addon Companion Scripts

These are not addons, they are normal scripts that are placed in the `~~/scripts` directory.
However, these scripts may require that file-browser also be installed.

[**sub-loader**](https://github.com/CogentRedTester/mpv-file-browser/issues/92#issuecomment-1557065729)  
Loads external subtitles using file-browser's directory parsing. Replicates the behaviour of
mpv's [`sub-auto`](https://mpv.io/manual/master/#options-sub-auto) and
[`sub-file-paths`](https://mpv.io/manual/master/#options-sub-file-paths) options.
Can be used to add external subtitle support for FTP and Apache file servers using the
relevant addons.
