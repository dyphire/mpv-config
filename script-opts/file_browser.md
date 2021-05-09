# mpv-file-browser

![cover](https://raw.githubusercontent.com/CogentRedTester/mpv-file-browser/master/screenshots/bunny.png)

This script allows users to browse and open files and folders entirely from within mpv. The script uses nothing outside the mpv API, so should work identically on all platforms. The browser can move up and down directories, start playing files and folders, or add them to the queue.

By default only file types compatible with mpv will be shown, but this can be changed in the config file.

## Keybinds

The following keybind is set by default


| Key | Name | Description |
| - | - | - |
| MENU | browse-files | toggles the browser |

The following dynamic keybinds are only set while the browser is open:


| Key | Name | Description |
| - | - | - |
| ESC | close | closes the browser or clears the selection |
| ENTER | play | plays the currently selected file or folder |
| Shift+ENTER | play_append | appends the current file or folder to the playlist |
| Alt+ENTER | play_autoload | loads playlist entries before and after the selected file (like autoload.lua) |
| DOWN | scroll_down | move selector down the list |
| UP | scroll_up | move selector up the list |
| RIGHT | down_dir | enter the currently selected directory |
| LEFT | up_dir | move to the parent directory |
| HOME | goto_current | move to the directory of the currently playing file |
| Shift+HOME | goto_root | move to the root directory |
| Ctrl+r | reload | reload directory and reset cache |
| s | select_mode | toggles multiselect mode |
| S | select_item | toggles selection for the current item |
| Ctrl+a | select_all | select all items in the current directory |

When attempting to play or append a subtitle file the script will instead load the subtitle track into the existing video.

The behaviour of the autoload keybind can be reversed with the `autoload` script-opt.
By default the playlist will only be autoloaded if `Alt+ENTER` is used on a single file, however when the option is switched autoload will always be used on single files *unless* `Alt+ENTER` is used. Using autoload on a directory, or while appending an item, will not work.

## Root Directory

To accomodate for both windows and linux this script has its own virtual root directory where drives and file folders can be manually added. This can also be used to save favourite directories. The root directory can only contain folders.

The root directory is set using the `root` option, which is a comma separated list of directories. Entries are sent through mpv's `expand-path` command. By default the only root value is the user's home folder:

`root=~/`

It is highly recommended that this be customised for the computer being used; [file_browser.conf](file_browser.conf) contains commented out suggestions for generic linux and windows systems. For example, my windows root looks like:

`root=~/,C:/,D:/,E:/,Z:/`

## Multi-Select

By default file-browser only opens/appends the single item that the cursor has selected.
However, using the `s` keybinds specified above, it is possible to select multiple items to open all at once. Selected items are shown in a different colour to the cursor.
When in multiselect mode the cursor changes colour and scrolling up and down the list will drag the current selection. If the original item was unselected, then dragging will select items, if the original item was selected, then dragging will unselect items.

When multiple items are selected using the open or append commands all selected files will be added to the playlist in the order they appear on the screen.
The currently selected (with the cursor) file will be ignored, instead the first multi-selected item in the folder will follow replace/append behaviour as normal, and following selected items will be appended to the playlist afterwards in the order that they appear on the screen.

## Custom Keybinds

File-browser also supports custom keybinds. These keybinds send normal input commands, but the script will substitute characters in the command strings for specific values depending on the currently open directory, and currently selected item.
This allows for a wide range of customised behaviour, such as loading additional audio tracks from the browser, or copying the path of the selected item to the clipboard.

To see how to enable and use custom keybinds, see [custom-keybinds.md](custom-keybinds.md).

## Add-ons

Add-ons are ways to add extra features to file-browser, for example adding support for network file servers like ftp, or implementing virtual directories in the root like recently opened files.
They can be enabled by setting `addon` script-opt to yes, and placing the addon file into the `~~/script-modules/file-browser-addons/` directory.

For a collection of premade addons, and instructions on writing your own addon, see [here](addons/README.md).

## [mpv-user-input](https://github.com/CogentRedTester/mpv-user-input)

mpv-user-input is a script that provides an API to request text input from the user over the OSD.
It was built using `console.lua` as a base, so supports almost all the same text input commands.
If `user-input.lua` is loaded by mpv, and `user-input-module` is in the `~~/script-modules/` directory, then using `Alt+o` will open an input box that can be used to directly enter directories for file-browser to open.

## Configuration

See [file_browser.conf](file_browser.conf) for the full list of options and their default values.
