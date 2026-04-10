# mpv-file-browser

![cover](screenshots/bunny.png)

This script allows users to browse and open files and folders entirely from within mpv. The script uses nothing outside the mpv API, so should work identically on all platforms. The browser can move up and down directories, start playing files and folders, or add them to the queue.

By default only file types compatible with mpv will be shown, but this can be changed in the config file.

This script requires at least **mpv v0.33**.

Originally, file-browser worked with versions of mpv going back to
v0.31, you can find those older versions of file-browser in the
[mpv-v0.31 branch](https://github.com/CogentRedTester/mpv-file-browser/tree/mpv-v0.31).
That branch will no longer be receiving any feature updates,
but I will try to fix any bugs that are reported on the issue
tracker.

## Installation

### Basic

Clone this git repository into the mpv `~~/scripts` directory and
change the name of the folder from `mpv-file-browser` to `file-browser`.
You can then pull to receive updates.
Alternatively, you can download the zip and extract the contents to `~~/scripts/file-browser`.
`~~/` is the mpv config directory which is typically `~/.config/mpv/` on linux and `%APPDATA%/mpv/` on windows.

### Configuration

Create a `file_browser.conf` file in the `~~/script-opts/` directory to configure the script.
See [docs/file_browser.conf](docs/file_browser.conf) for the full list of options and their default values.
The [`root` option](#root-directory) may be worth tweaking for your system.

### Addons

To use [addons](addons/README.md) place addon files in the `~~/script-modules/file-browser-addons/` directory.

### Custom Keybinds
To setup [custom keybinds](docs/custom-keybinds.md) create a `~~/script-opts/file-browser-keybinds.json` file.
Do **not** copy the `file-browser-keybinds.json` file
stored in this repository, that file is a collection of random examples, many of which are for completely different
operating systems. Use them and the [docs](docs/custom-keybinds.md) to create your own collection of keybinds.

### File Structure

<details>
<summary>Expected directory tree (basic):</summary>

```
~~/
├── script-opts
│   └── file_browser.conf
└── scripts
    └── file-browser
        ├── addons/
        ├── docs/
        ├── modules/
        ├── screenshots/
        ├── LICENSE
        ├── main.lua
        └── README.md
```
</details>

<details>
<summary>Expected directory tree (full):</summary>

```
~~/
├── script-modules
│   └── file-browser-addons
│       ├── addon1.lua
│       ├── addon2.lua
│       └── etc.lua
├── script-opts
│   ├── file_browser.conf
│   └── file-browser-keybinds.json
└── scripts
    └── file-browser
        ├── addons/
        ├── docs/
        ├── modules/
        ├── screenshots/
        ├── LICENSE
        ├── main.lua
        └── README.md
```
</details>

## Keybinds

The following keybinds are set by default

| Key         | Name                             | Description                                                                   |
|-------------|----------------------------------|-------------------------------------------------------------------------------|
| MENU        | browse-files                     | toggles the browser                                                           |
| Ctrl+o      | open-browser                     | opens the browser                                                             |
| Alt+o       | browse-directory/get-user-input  | opens a dialogue box to type in a directory - requires [mpv-user-input](#mpv-user-input) when mpv < v0.38 |

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
| Alt+LEFT    | history_back  | move to previously open directory                                             |
| Alt+RIGHT   | history_forward| move forwards again in history to the next directory                         |
| Ctrl+r      | reload        | reload current directory                                                      |
| Ctrl+Shift+r| cache/clear   | clears the directory cache (disabled by default)                              |
| s           | select_mode   | toggles multiselect mode                                                      |
| S           | select_item   | toggles selection for the current item                                        |
| Ctrl+a      | select_all    | select all items in the current directory                                     |
| Ctrl+f      | find/find     | Opens a text input to search the contents of the folder - requires [mpv-user-input](#mpv-user-input) when mpv < v0.38|
| Ctrl+F      | find/find_advanced| Allows using [Lua Patterns](https://www.lua.org/manual/5.1/manual.html#5.4.1) in the search input|
| n           | find/next     | Jumps to the next matching entry for the latest search term                   |
| N           | find/prev     | Jumps to the previous matching entry for the latest search term               |

When attempting to play or append a subtitle file the script will instead load the subtitle track into the existing video.

The behaviour of the autoload keybind can be reversed with the `autoload` script-opt.
By default the playlist will only be autoloaded if `Alt+ENTER` is used on a single file, however when the option is switched autoload will always be used on single files *unless* `Alt+ENTER` is used. Using autoload on a directory, or while appending an item, will not work.

## Root Directory

To accomodate for both windows and linux this script has its own virtual root directory where drives and file folders can be manually added. The root directory can only contain folders.

The root directory is set using the `root` option, which is a comma separated list of directories. Entries are sent through mpv's `expand-path` command. By default `~/` and `C:/` are set on Windows
and `~/` and `/` are set on non-Windows systems.
Extra locations can be added manually, for example, my Windows root looks like:

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

To see how to enable and use custom keybinds, see [custom-keybinds.md](docs/custom-keybinds.md).

## Add-ons

Add-ons are ways to add extra features to file-browser, for example adding support for network file servers like ftp, or implementing virtual directories in the root like recently opened files.
They can be enabled by setting `addon` script-opt to yes, and placing the addon file into the `~~/script-modules/file-browser-addons/` directory.

For a list of existing addons see the [wiki](https://github.com/CogentRedTester/mpv-file-browser/wiki/Addon-List).
For instructions on writing your own addons see [addons.md](docs/addons.md).

## Script Messages

File-browser supports a small number of script messages that allow the user or other scripts to talk with the browser.

### `browse-directory`

`script-message browse-directory [directory]`

Opens the given directory in the browser. If the browser is currently closed it will be opened.

### `get-directory-contents`

`script-message get-directory-contents [directory] [response-string]`

Reads the given directory, and sends the resulting tables to the specified script-message in the format:

`script-message [response-string] [list] [opts]`

The [list](docs/addons.md#the-list-array)
and [opts](docs/addons.md#the-opts-table)
tables are formatted as json strings through the `mp.utils.format_json` function.
See [addons.md](docs/addons.md) for how the tables are structured, and what each field means.
The API_VERSION field of the `opts` table refers to what version of the addon API file browser is using.
The `response-string` refers to an arbitrary script-message that the tables should be sent to.

This script-message allows other scripts to utilise file-browser's directory parsing capabilities, as well as those of the file-browser addons.

## Conditional Auto-Profiles

file-browser provides a property that can be used with [conditional auto-profiles](https://mpv.io/manual/master/#conditional-auto-profiles)
to detect when the browser is open.
On mpv v0.36+ you should use the `user-data` property with the `file_browser/open` boolean.

Here is an example of an auto-profile that hides the OSC logo when using file-browser in an idle window:

```properties
[hide-logo]
profile-cond= idle_active and user_data.file_browser.open
profile-restore=copy
osc=no
```

On older versions of mpv you can use the `file_browser-open` field of the `shared-script-properties` property:

```properties
[hide-logo]
profile-cond= idle_active and shared_script_properties["file_browser-open"] == "yes"
profile-restore=copy
osc=no
```

See [#55](https://github.com/CogentRedTester/mpv-file-browser/issues/55) for more details on this.

## [mpv-user-input](https://github.com/CogentRedTester/mpv-user-input)

mpv-user-input is a script that provides an API to request text input from the user over the OSD.
It was built using `console.lua` as a base, so supports almost all the same text input commands.
If `user-input.lua` is loaded by mpv, and `user-input-module` is in the `~~/script-modules/` directory,
then using `Alt+o` will open an input box that can be used to directly enter directories for file-browser to open.

Mpv v0.38 added the `mp.input` module, which means `mpv-user-input` is no-longer necessary from that version onwards.
