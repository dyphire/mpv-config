# mpv-file-browser

![cover](screenshots/bunny.png)

This script allows users to browse and open files and folders entirely from within mpv. The script uses nothing outside the mpv API, so should work identically on all platforms. The browser can move up and down directories, start playing files and folders, or add them to the queue.

By default only file types compatible with mpv will be shown, but this can be changed in the config file.

This script requires at least mpv v0.31.

## Installation

Place the `file-browser.lua` file into the mpv `~~/scripts/` directory. `~~/` is the mpv config directory
which is typically `~/.config/mpv/` on linux and `%APPDATA%/mpv/` on windows.

Copy `file_browser.conf` into `~~/script-opts/` and customise the [`root` option](#root-directory) for your
system. The file contains all the default settings for the script, but I would recommend deleting any
options from the file that you don't understand so as to not override any future changes I make to the defaults.

To setup [custom keybinds](custom-keybinds.md) enable the `custom_keybinds` option in `file_browser.conf` and
create a `~~/script-opts/file-browser-keybinds.json` file. Do **not** copy the `file-browser-keybinds.json` file
stored in this repository, that file is a collection of random examples, many of which are for completely different
operating systems. Use them and the [docs](custom-keybinds.md) to create your own collection of keybinds.

To setup [addons](addons/README.md) enable the `addons` option in `file_browser.conf` and place the addon files
in the `~~/script-modules/file-browser-addons/` directory.

If you are not going to enable custom keybinds or addons then there is no reason to
create `file-browser-keybinds.json` or `script-modules/file-browser-addons/`.

## Keybinds

The following keybinds are set by default

| Key         | Name                             | Description                                                                   |
|-------------|----------------------------------|-------------------------------------------------------------------------------|
| MENU        | browse-files                     | toggles the browser                                                           |
| Ctrl+o      | open-browser                     | opens the browser                                                             |
| Alt+o       | browse-directory/get-user-input  | opens a dialogue box to type in a directory - requires [mpv-user-input](#mpv-user-input) |

The following dynamic keybinds are only set while the browser is open:

| Key         | Name          | Description                                                                   |
|-------------|---------------|-------------------------------------------------------------------------------|
| ESC         | close         | closes the browser or clears the selection                                    |
| ENTER       | play          | plays the currently selected file or folder                                   |
| Shift+ENTER | play_append   | appends the current file or folder to the playlist                            |
| Alt+ENTER   | play_autoload | loads playlist entries before and after the selected file (like autoload.lua) |
| RIGHT       | down_dir      | enter the currently selected directory                                        |
| LEFT        | up_dir        | move to the parent directory                                                  |
| DOWN        | scroll_down   | move selector down the list                                                   |
| UP          | scroll_up     | move selector up the list                                                     |
| PGDWN       | page_down     | move selector down the list by a page (the num_entries option)                |
| PGUP        | page_up       | move selector up the list by a page (the num_entries option)                  |
| Shift+PGDWN | list_bottom   | move selector to the bottom of the list                                       |
| Shift+PGUP  | list_top      | move selector to the top of the list                                          |
| HOME        | goto_current  | move to the directory of the currently playing file                           |
| Shift+HOME  | goto_root     | move to the root directory                                                    |
| Ctrl+r      | reload        | reload directory and reset cache                                              |
| s           | select_mode   | toggles multiselect mode                                                      |
| S           | select_item   | toggles selection for the current item                                        |
| Ctrl+a      | select_all    | select all items in the current directory                                     |

When attempting to play or append a subtitle file the script will instead load the subtitle track into the existing video.

The behaviour of the autoload keybind can be reversed with the `autoload` script-opt.
By default the playlist will only be autoloaded if `Alt+ENTER` is used on a single file, however when the option is switched autoload will always be used on single files *unless* `Alt+ENTER` is used. Using autoload on a directory, or while appending an item, will not work.

## Root Directory

To accomodate for both windows and linux this script has its own virtual root directory where drives and file folders can be manually added. The root directory can only contain folders.

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

For a list of existing addons see the [wiki](https://github.com/CogentRedTester/mpv-file-browser/wiki/Addon-List).
For instructions on writing your own addons see [addons.md](addons/addons.md).

## Script Messages

File-browser supports a small number of script messages that allow the user or other scripts to talk with the browser.

### `browse-directory`

`script-message browse-directory [directory]`

Opens the given directory in the browser. If the browser is currently closed it will be opened.

### `get-directory-contents`

`script-message get-directory-contents [directory] [response-string]`

Reads the given directory, and sends the resulting tables to the specified script-message in the format:

`script-message [response-string] [list] [opts]`

The [list](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/addons.md#the-list-array)
and [opts](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/addons.md#the-opts-table)
tables are formatted as json strings through the `mp.utils.format_json` function.
See [addons.md](addons/addons.md) for how the tables are structured, and what each field means.
The API_VERSION field of the `opts` table refers to what version of the addon API file browser is using.
The `response-string` refers to an arbitrary script-message that the tables should be sent to.

This script-message allows other scripts to utilise file-browser's directory parsing capabilities, as well as those of the file-browser addons.

## Configuration

See [file_browser.conf](file_browser.conf) for the full list of options and their default values.
The file is placed in the `~~/script-opts/` folder.

## Conditional Auto-Profiles

file-browser provides a property that can be used with [conditional auto-profiles](https://mpv.io/manual/master/#conditional-auto-profiles)
to detect when the browser is open. It can be accessed with the `shared_script_properties["file_browser-open"]` key, and it will always
evaluate to either `yes` or `no`.

Here is an example of an auto-profile that hides the OSC logo when using file-browser in an idle window:

```properties
[hide-logo]
profile-cond=shared_script_properties["file_browser-open"] == "yes" and idle_active
profile-restore=copy
osc=no
```

See [#55](https://github.com/CogentRedTester/mpv-file-browser/issues/55) for more details on this.

## [mpv-user-input](https://github.com/CogentRedTester/mpv-user-input)

mpv-user-input is a script that provides an API to request text input from the user over the OSD.
It was built using `console.lua` as a base, so supports almost all the same text input commands.
If `user-input.lua` is loaded by mpv, and `user-input-module` is in the `~~/script-modules/` directory, then using `Alt+o` will open an input box that can be used to directly enter directories for file-browser to open.
