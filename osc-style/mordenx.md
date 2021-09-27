# mpv-osc-morden-x
An MPV OSC script, based on [mpv-osc-morden](https://github.com/maoiscat/mpv-osc-morden/), with some minor changes including making the skip_back/forward buttons go to the previous/next chapter like in MPV's default OSC and fixing the play/pause button.

![img](https://raw.githubusercontent.com/cyl0/mpv-osc-morden-x/main/preview.png)

# How to install

Locate your MPV folder. It is typically located at `\%APPDATA%\mpv\` on Windows and `~/.config/mpv/` on Linux/MacOS. See the [Files section](https://mpv.io/manual/master/#files) in mpv's manual for more info.

Put mordenx.lua into your mpv "\~\~/scripts/" folder, and remove other osc scripts,
then put `Material-Design-Iconic-Font.ttf` in the "\~\~/fonts" folder.

in mpv.conf:

```
osc = no
border = no # Optional, but recommended
```
`Material-Design-Iconic-Font.ttf` can also be downloaded from [here](https://zavoloklom.github.io/material-design-iconic-font/).

# How to config

edit osc.conf in "\~\~/script-opts/" folder, however many options are changed, so refer to the user_opts variable in the script file for details.

# Buttons

like the built-in script, some buttons may accept multiple mouse actions, here is a list:

## Seekbar
* Left mouse button: seek to chosen position.
* Right mouse button: seek to the head of chosen chapter
## Skip back/forward buttons
* Left mouse button: go to previous/next chapter.
* Right mouse button: show chapter list.
## Playlist back/forwad buttons
* Left mouse button: play previous/next file.
* Right mouse button: show playlist.
## Cycle audio/subtitle buttons
* Left mouse button/Right mouse button: cycle to next/previous track.
* Middle mouse button: show track list.
## Playback time
* Left mouse button: display time in milliseconds
## Duration
* Left mouse button: display total time instead of remaining time
