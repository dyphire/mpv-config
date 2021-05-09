# Custom Keybinds

File-browser also supports custom keybinds. These keybinds send normal input commands, but the script will substitute characters in the command strings for specific values depending on the currently open directory, and currently selected item.
This allows for a wide range of customised behaviour, such as loading additional audio tracks from the browser, or copying the path of the selected item to the clipboard.

The feature is disabled by default, but is enabled with the `custom_keybinds` script-opt.
Keybinds are declared in the `~~/script-opts/file-browser-keybinds.json` file, the config takes the form of an array of json objects, with the following keys:

| option        | required | default    | description                                                                                |
|---------------|----------|------------|--------------------------------------------------------------------------------------------|
| key           | yes      | -          | the key to bind the command to - same syntax as input.conf                                 |
| command       | yes      | -          | json array of commands and arguments                                                       |
| name          | no       | numeric id | name of the script-binding - see [modifying default keybinds](#modifying-default-keybinds) |
| filter        | no       | -          | run the command on just a file (`file`) or folder (`dir`)                                  |
| parser        | no       | -          | run the command only in directories provided by the specified parser.                      |
| multiselect   | no       | `false`    | command is run on all selected items                                                       |
| multi-type    | no       | `repeat`   | which multiselect mode to use - `repeat` or `concat`                                       |
| delay         | no       | `0`        | time to wait between sending repeated multi commands                                       |
| concat-string | no       | `" "`      | string to insert between items when concatenating multi commands                           |
| passthrough   | no       | -          | force or ban passthrough behaviour - see [passthrough](#passthrough-keybinds)              |

Example:

```json
{
    "key": "KP1",
    "command": ["print-text", "example"],
    "filter": "file"
}
```

The command can also be an array of arrays, in order to send multiple commands at once:

```json
{
    "key": "KP2",
    "command": [
        ["print-text", "example2"],
        ["show-text", "example2"]
    ]
}
```

Filter should not be included unless one wants to limit what types of list entries the command should be run on.
To only run the command for directories use `dir`, to only run the command for files use `file`.

The parser filter is for filtering keybinds to only work inside directories loaded by specific parsers.
There are two parsers in the base script, the default parser for native filesystems is called `file`, while the root parser is called `root`.
Other parsers can be supplied by addons, and use the addon's filename with `-browser.lua` or just `.lua` stripped unless otherwise stated.
For example `ftp-browser.lua` would have a parser called `ftp`.

## Codes

The script will scan every string in the command for the special substitution strings, they are:

| code | description                                                         |
|------|---------------------------------------------------------------------|
| %f   | filepath of the selected item                                       |
| %n   | filename of the selected item                                       |
| %p   | currently open directory                                            |
| %d   | name of the current directory (characters between the last two '/') |
| %r   | name of the parser for the currently open directory                 |
| %%_  | escape code for `%_` where `%_` is one of the previous codes        |

Additionally, using the uppercase forms of those codes will send the substituted string through the `string.format("%q", str)` function.
This adds double quotes around the string and automatically escapes any quotation marks within the string.
This is not necessary for most mpv commands, but can be very useful when sending commands to the OS with the `run` command.

Example of a command to add an audio track:

```json
{
    "key": "Ctrl+a",
    "command": ["audio-add", "%f"],
    "filter": "file"
}
```

## Multiselect Commands

When multiple items are selected the command can be run for all items in the order they appear on the screen.
This can be controlled by the `multiselect` flag, which takes a boolean value.
When not set the flag defaults to `false`.

There are two different multiselect modes, controlled by the `multi-type` option. There are two options:

### `repeat`

The default mode that sends the commands once for each item that is selected
If time is needed between running commands of multiple selected items (for example, due to file handlers) then the `delay` option can be used to set a duration (in seconds) between commands.

### `append`

Run a single command, but replace item specific codes with the corresponding string from each selected item.
For example `["print-text", "%n" ]` would print the name of each item selected separated by `" "`.
The string appended between each character is determined by the `append-string` option, but `" "` is the default.

## Passthrough Keybinds

When loading keybinds from the json file file-browser will move down the list and overwrite any existing bindings with the same key.
This means the lower an item on the list, the higher preference it has.
However, file-browser implements a layered passthrough system for its keybinds; if a keybind is blocked from running by user filters, then the next highest preference command will be sent, continuing until a command is sent or there are no more keybinds.
The default dynamic keybinds are considered the lowest priority.

The behaviour of multi-select commands is somewhat unreliable; generally they never run the next highest preference command, unless every selected item fails the filter.

Passthrough can be forcibly disabled or enabled using the passthrough option.
When enabled passthrough will always be activate regardless of the state of the filters.

## Modifying Default Keybinds

Since the custom keybinds are applied after the default dynamic keybinds they can be used to overwrite the default bindings.
Setting new keys for the existing binds can be done with the `script-binding [binding-name]` command, where `binding-name` is the full name of the keybinding.
For this script the names of the dynamic keybinds are in the format `file_browser/dynamic/[name]` where `name` is a unique identifier documented in the [keybinds](README.md#keybinds) table.

For example to change the scroll buttons from the arrows to the scroll wheel:

```json
[
    {
        "key": "WHEEL_UP",
        "command": ["script-binding", "file_browser/dynamic/scroll_up"]
    },
    {
        "key": "WHEEL_DOWN",
        "command": ["script-binding", "file_browser/dynamic/scroll_down"]
    },
    {
        "key": "UP",
        "command": ["osd-auto", "add", "volume", "2"]
    },
    {
        "key": "DOWN",
        "command": ["osd-auto", "add", "volume", "-2"]
    }
]
```

Custom keybinds can be called using the same method, but users must set the `name` value inside the `file-browser-keybinds.json` file.
To avoid conflicts custom keybinds use the format: `file_browser/dynamic/custom/[name]`.


## Examples

See [here](file-browser-keybinds.json).
