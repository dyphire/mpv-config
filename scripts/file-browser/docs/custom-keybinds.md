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
| condition     | no       | -          | a Lua [expression](#expressions) - the keybind will only run if this evaluates to true     |
| flags         | no       | -          | flags to send to the mpv add_keybind function - see [here](https://mpv.io/manual/master/#lua-scripting-[,flags]]\)) |
| filter        | no       | -          | run the command on just a file (`file`) or folder (`dir`)                                  |
| parser        | no       | -          | run the command only in directories provided by the specified parser.                      |
| multiselect   | no       | `false`    | command is run on all selected items                                                       |
| multi-type    | no       | `repeat`   | which multiselect mode to use - `repeat` or `concat`                                       |
| delay         | no       | `0`        | time to wait between sending repeated multi commands                                       |
| concat-string | no       | `' '` (space) | string to insert between items when concatenating multi commands                        |
| passthrough   | no       | -          | force or ban passthrough behaviour - see [passthrough](#passthrough-keybinds)              |
| api_version   | no       | -          | tie the keybind to a particular [addon API version](./addons.md#api-version), printing warnings and throwing errors if the keybind is used with wrong versions |

Example:

```json
{
    "key": "KP1",
    "command": ["print-text", "example"],
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
You can set the filter to match multiple parsers by separating the names with spaces.

```json
{
    "key": "KP2",
    "command": [ ["print-text", "example3"] ],
    "parser": "ftp file"
}
```

The `flags` field is mostly only useful for addons, but can also be useful if one wants a key to be repeatable.
In this case the the keybind would look like the following:

```json
{
    "key": "p",
    "command": ["print-text", "spam-text"],
    "flags": { "repeatable": true }
}
```

## Codes

The script will scan every string in the command for the special substitution strings, they are:

| code   | description                                                         |
|--------|---------------------------------------------------------------------|
| `%%`   | escape code for `%`                                                 |
| `%f`   | filepath of the selected item                                       |
| `%n`   | filename of the selected item                                       |
| `%p`   | currently open directory                                            |
| `%q`   | currently open directory but preferring the directory label         |
| `%d`   | name of the current directory (characters between the last two '/') |
| `%r`   | name of the parser for the currently open directory                 |
| `%x`   | number of items in the currently open directory                     |
| `%i`   | the 1-based index of the selected item in the list                  |
| `%j`   | the 1-based index of the item in a multiselection - returns 1 for single selections |

Additionally, using the uppercase forms of those codes will send the substituted string through the `string.format("%q", str)` function.
This adds double quotes around the string and automatically escapes any characters which would break the string encapsulation.
This is not necessary for most mpv commands, but can be very useful when sending commands to the OS with the `run` command,
or when passing values into [expressions](#conditional-command-condition-command).

Example of a command to add an audio track:

```json
{
    "key": "Ctrl+a",
    "command": ["audio-add", "%f"],
    "filter": "file"
}
```

Any commands that contain codes representing specific items (`%f`, `%n`, `%i` etc) will
not be run if no item is selected (for example in an empty directory).
In these cases [passthrough](#passthrough-keybinds) rules will apply.

## Multiselect Commands

When multiple items are selected the command can be run for all items in the order they appear on the screen.
This can be controlled by the `multiselect` flag, which takes a boolean value.
When not set the flag defaults to `false`.

There are two different multiselect modes, controlled by the `multi-type` option. There are two options:

### `repeat`

The default mode that sends the commands once for each item that is selected.
If time is needed between running commands of multiple selected items (for example, due to file handlers) then the `delay` option can be used to set a duration (in seconds) between commands.

### `concat`

Run a single command, but replace item specific codes with a concatenated string made from each selected item.
For example `["print-text", "%n" ]` would print the name of each item selected separated by `' '` (space).
The string inserted between each item is determined by the `concat-string` option, but `' '` is the default.

## Passthrough Keybinds

When loading keybinds from the json file file-browser will move down the list and overwrite any existing bindings with the same key.
This means the lower an item on the list, the higher preference it has.
However, file-browser implements a layered passthrough system for its keybinds; if a keybind is blocked from running by user filters, then the next highest preference command will be sent, continuing until a command is sent or there are no more keybinds.
The default dynamic keybinds are considered the lowest priority.

The `filter`, `parser`, and `condition` options can all trigger passthrough, as well as some [codes](#codes).
If a multi-select command is run on multiple items then passthrough will occur if any of the selected items fail the filters.

Passthrough can be forcibly disabled or enabled using the passthrough option.
When set to `true` passthrough will always be activate regardless of the state of the filters.

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

## Expressions

Expressions are used to evaluate Lua code into a string that can be used for commands.
These behave similarly to those used for [`profile-cond`](https://mpv.io/manual/master/#conditional-auto-profiles)
values. In an expression the `mp`, `mp.msg`, and `mp.utils` modules are available as `mp`, `msg`, and `utils` respectively.
Additionally, in mpv v0.38+ the `mp.input` module is available as `input`.

The file-browser [addon API](addons/addons.md#the-api) is available as `fb` and if [mpv-user-input](https://github.com/CogentRedTester/mpv-user-input)
is installed then user-input API will be available in `user_input`.

This example only runs the keybind if the browser is in the Windows C drive or if
the selected item is a matroska file:

```json
[
    {
        "key": "KP1",
        "command": ["print-text", "in my C:/ drive!"],
        "condition": "(%P):find('C:/') == 1"
    },
    {
        "key": "KP2",
        "command": ["print-text", "Matroska File!"],
        "condition": "fb.get_extension(%N) == 'mkv'"
    }
]
```

If the `condition` expression contains any item specific codes (`%F`, `%I`, etc) then it will be
evaluated on each individual item, otherwise it will evaluated once for the whole keybind.
If a code is invalid (for example using `%i` in empty directories) then the expression returns false.

There are some utility script messages that extend the power of expressions.
[`conditional-command`](#conditional-command-condition-command) allows one to specify conditions that
can apply to individual items or commands. The tradeoff is that you lose the automated passthrough behaviour.
There is also [`evaluate-expressions`](#evaluate-expressions-command) which allows one to evaluate expressions inside commands.

## Utility Script Messages

There are a small number of custom script messages defined by file-browser to support custom keybinds.

### `=> <command...>`

A basic script message that makes it easier to chain multiple utility script messages together.
Any `=>` string will be substituted for `script-message`.

```json
{
    "key": "KP1",
    "command": ["script-message", "=>", "delay-command", "%j * 2", "=>", "evaluate-expressions", "print-text", "!{%j * 2}"],
    "multiselect": true
}
```

### `conditional-command [condition] <command...>`

Runs the following command only if the condition [expression](#expressions) is `true`.

This example command will only run if the player is currently paused:

```json
{
    "key": "KP1",
    "command": ["script-message", "conditional-command", "mp.get_property_bool('pause')", "print-text", "is paused"],
}
```

Custom keybind codes are evaluated before the expressions.

This example only runs if the currently selected item in the browser has a `.mkv` extension:

```json
{
    "key": "KP1",
    "command": ["script-message", "conditional-command", "fb.get_extension(%N) == 'mkv'", "print-text", "a matroska file"],
}
```

### `delay-command [delay] <command...>`

Delays the following command by `[delay]` seconds.
Delay is an [expression](#expressions).

The following example will send the `print-text` command after 5 seconds:

```json
{
    "key": "KP1",
    "command": ["script-message", "delay-command", "5", "print-text", "example"],
}
```

### `evaluate-expressions <command...>`

Evaluates embedded Lua expressions in the following command.
Expressions have the same behaviour as the [`conditional-command`](#conditional-command-condition-command) script-message.
Expressions must be surrounded by `!{}` characters.
Additional `!` characters can be placed at the start of the expression to
escape the evaluation.

For example the following keybind will print 3 to the console:

```json
{
    "key": "KP1",
    "command": ["script-message", "evaluate-expressions", "print-text", "!{1 + 2}"],
}
```

This example replaces all `/` characters in the path with `\`
(note that the `\` needs to be escaped twice, once for the json file, and once for the string in the lua expression):

```json
{
    "key": "KP1",
    "command": ["script-message", "evaluate-expressions", "print-text", "!{ string.gsub(%F, '/', '\\\\') }"],
}
```

### `run-statement <statement...>`

Runs the following string a as a Lua statement. This is similar to an [expression](#expressions),
but instead of the code evaluating to a value it must run a series of statements. Basically it allows
for function bodies to be embedded into custom keybinds. All the same modules are available.
If multiple strings are sent to the script-message then they will be concatenated together with newlines.

The following keybind will use [mpv-user-input](https://github.com/CogentRedTester/mpv-user-input) to
rename items in file-browser:

```json
{
    "key": "KP1",
    "command": ["script-message", "run-statement",
                    "assert(user_input, 'install mpv-user-input!')",

                    "local line, err = user_input.get_user_input_co({",
                                            "id = 'rename-file',",
                                            "source = 'custom-keybind',",
                                            "request_text = 'rename file:',",
                                            "queueable = true,",
                                            "default_input = %N,",
                                            "cursor_pos = #(%N) - #fb.get_extension(%N, '')",
                                        "})",

                    "if not line then return end",
                    "os.rename(%F, utils.join_path(%P, line))",

                    "fb.rescan()"
                ],
    "parser": "file",
    "multiselect": true
}
```

## Examples

See [here](file-browser-keybinds.json).
