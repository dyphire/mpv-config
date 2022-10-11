# addons

Add-ons are ways to add extra features to file-browser, for example adding support for network file servers like ftp, or implementing virtual directories in the root like recently opened files.
They can be enabled by setting `addon` script-opt to yes, and placing the addon file into the `~~/script-modules/file-browser-addons/` directory.

Browsing filesystems provided by add-ons should feel identical to the normal handling of the script,
but they may require extra commandline tools be installed.

Since addons are loaded programatically from the addon directory it is possible for anyone to write their own addon.
Instructions on how to do this are available [here](addons.md).

## Examples

[This directory](https://github.com/CogentRedTester/mpv-file-browser/tree/master/addons) contains a number of pre-written addons that can be used as examples of the addon API, though each could still prove useful for everyday use.
Any improvements on these addons are welcome.

## Addon List

The following is a list of addons I have written.

*Warning: many of these addons exist as a proof-of-concept, they are not as stable or well supported as the default file-browser script.*

**ls**  
Implements standard directory parsing using the linux `ls` utility.
This behaves near identically to the native parser, but IO is done asynchronously.

**windir**  
Implements standard directory parsing using the windows `cmd dir` command.
This behaves near identically to the native parser, but IO is done asynchronously.

**apache-browser**  
Implements support for http/https directory indexes that apache servers dynamically generate.
I don't know if this will work on different types of servers.
Requires `curl` in the system PATH.

**ftp-browser**  
Implements support for ftp file servers. Requires `curl` in the system path.

**home-label**  
Replaces the user's home directory in the directory header with `~/`.

**win-root**  
Automatically populates the root with windows drives.

**url-decode**  
Decodes URL directories to make them more readable. Does not decode the names of items in the list.

**m3u-browser**  
Adds limitted support for m3u playlists. Requires that [mpv-read-file](https://github.com/CogentRedTester/mpv-read-file) be installed.

**favourites**  
Implements a virtual directory of favourited files and folders.

**powershell**  
Read the contents of select drives using powershell instead of the inbuilt mpv API.

**find**  
Allows one to search the contents of the directory with `Ctrl+f`. Use `Ctrl+F` for Lua pattern support. Use `n` to cycle through results.
Requires [mpv-user-input](https://github.com/CogentRedTester/mpv-user-input).

**[dvd-browser](https://github.com/CogentRedTester/mpv-dvd-browser)**  
This script implements support for DVD titles using the `lsdvd` commandline utility.
When playing a dvd, or when moving into the `--dvd-device` directory, the add-on loads up the DVD titles.
Note that `lsdvd` is only available on linux, but the script has special support for WSL on windows 10.
