# How to Write an Addon - API v1.5.0

Addons provide ways for file-browser to parse non-native directory structures. This document describes how one can create their own custom addon.

If you have an independent script but want to use file-browser's parsing capabilities, perhaps to make use of existing addons, then look [here](https://github.com/CogentRedTester/mpv-file-browser#get-directory-contents).

## Terminology

For the purpose of this document addons refer to the scripts being loaded while parsers are the objects the scripts return.
An addon can return multiple parsers, but when they only returns one the terms are almost synonymous.
Additionally, `method` refers to functions called using the `object:funct()` syntax, and hence have access to the self object, whereas `function` is the standard `object.funct()` syntax.

## API Version

The API version, shown in the title of this document, allows file-browser to ensure that addons are using the correct
version of the API. It follows [semantic versioning](https://semver.org/) conventions of `MAJOR.MINOR.PATCH`.
A parser sets its version string with the `version` field, as seen [below](#overview).

Any change that breaks backwards compatability will cause the major version number to increase.
A parser MUST have the same version number as the API, otherwise an error message will be printed and the parser will
not be loaded.

A minor version number denotes a change to the API that is backwards compatible. This includes additional API functions,
or extra fields in tables that were previously unused. It may also include additional arguments to existing functions that
add additional behaviour without changing the old behaviour.
If the parser's minor version number is greater than the API_VERSION, then a warning is printed to the console.

Patch numbers denote bug fixes, and are ignored when loading an addon.
For this reason addon authors are allowed to leave the patch number out of their version tag and just use `MAJOR.MINOR`.

## Overview

File-browser automatically loads any lua files from the `~~/script-modules/file-browser-addons` directory as modules.
Each addon must return either a single parser table, or an array of parser tables. Each parser object must contain the following three members:

| key       | type   | arguments                 | returns                | description                                                                                                  |
|-----------|--------|---------------------------|------------------------|--------------------------------------------------------------------------------------------------------------|
| priority  | number | -                         | -                      | a number to determine what order parsers are tested - see [here](#priority-suggestions) for suggested values |
| version   | string | -                         | -                      | the API version the parser is using - see [API Version](#api-version)                                        |
| can_parse | method | string, parse_state_table | boolean                | returns whether or not the given path is compatible with the parser                                          |
| parse     | method | string, parse_state_table | list_table, opts_table | returns an array of item_tables, and a table of options to control how file_browser handles the list         |

Additionally, each parser can optionally contain:

| key          | type   | arguments | returns | description                                                                                                                                                     |
|--------------|--------|-----------|---------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name         | string | -         | -       | the name of the parser used for debug messages and to create a unique id - by default uses the filename with `.lua` or `-browser.lua` removed                   |
| keybind_name | string | -         | -       | the name to use when setting custom keybind filters - uses the value of name by default but can be set manually so that the same keys work with multiple addons |
| setup        | method | -         | -       | if it exists this method is automatically run after all parsers are imported and API functions are made available                                               |
| keybinds     | table  | -         | -       | an array of keybind objects for the browser to set when loading - see [#keybinds]                                                                               |

All parsers are given a unique string ID based on their name. If there are collisions then numbers are appended to the end of the name until a free name is found.
These IDs are primarily used for debug messages, though they may gain additional functionality in the future.

Here is an extremely simple example of an addon creating a parser table and returning it to file-browser.

```lua
local parser = {
    version = '1.0.0',
    priority = 100,
    name = "example"        -- this parser will have the id 'example' or 'example_#' if there are duplicates
}

function parser:can_parse(directory)
    return directory == "Example/"
end

function parser:parse(directory, state)
    local list, opts
    ------------------------------
    --- populate the list here ---
    ------------------------------
    return list, opts
end

return parser

```

## Parsing

When a directory is loaded file-browser will iterate through the list of parsers from lowest to highest priority.
The first parser for which `can_parse` returns true will be selected as the parser for that directory.

The `parse` method will then be called on the selected parser, which is expected to return either a table of list items, or nil.
If an empty table is returned then file-browser will treat the directory as empty, otherwise if the list_table is nil then file-browser will attempt to run `parse` on the next parser for which `can_parse` returns true.
This continues until a parser returns a list_table, or until there are no more parsers.

The entire parse operation is run inside of a coroutine, this allows parsers to pause execution to handle asynchronous operations.
Please read [coroutines](#coroutines) for all the details.

### Parse State Table

The `parse` and `can_parse` functions are passed a state table as its second argument, this contains the following fields.

| key                  | type    | description                                                                                                                                                                                                           |
|----------------------|---------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| source               | string  | the source of the parse request                                                                                                                                                                                       |
| directory            | string  | the directory of the parse request - for debugging purposes                                                                                                                                                           |
| already_deferred     | boolean | whether or not [defer](#advanced-functions) was called during this parse, if so then file-browser will not try to query any more parsers after receiving the result - set automatically, but can be manually disabled |
| yield                | method  | a wrapper around `coroutine.yield()` - see [coroutines](#coroutines)                                                                                                                                                  |
| is_coroutine_current | method  | returns if the browser is waiting on the current coroutine to populate the list                                                                                                                                       |

`already_deferred` is an optimisation. If a script uses defer and still returns nil, then that means that none of the remaining parsers will be able to parse the path.
Therefore, it is more efficient to just immediately jump to the root.
It is up to the addon author to manually disable this if their use of `defer` conflicts with this assumption.

Source can have the following values:

| source         | description                                                                                             |
|----------------|---------------------------------------------------------------------------------------------------------|
| browser        | triggered by the main browser window                                                                    |
| loadlist       | the browser is scanning the directory to append to the playlist                                         |
| script-message | triggered by the `get-directory-contents` script-message                                                |
| addon          | caused by an addon calling the `parse_directory` API function - note that addons can set a custom state |

Note that all calls to any `parse` function during a specific parse request will be given the same parse_state table.
This theoretically allows parsers to communicate with parsers of a lower priority (or modify how they see source information),
but no guarantees are made that specific keys will remain unused by the API.

#### Coroutines

Any calls to `parse()` (or `can_parse()`, but you should never be yielding inside there) are done in a [Lua coroutine](https://www.lua.org/manual/5.1/manual.html#2.11).
This means that you can arbitrarily pause the parse operation if you need to wait for some asynchronous operation to complete,
such as waiting for user input, or for a network request to complete.

Making these operations asynchronous has performance
advantages as well, for example recursively opening a network directory tree could cause the browser to freeze
for a long period of time. If the network query were asynchronous then the browser would only freeze during actual operations,
during network operations it would be free for the user interract with. The browser has even been designed so that
a loadfile/loadlist operation saves it's own copy of the current directory, so even if the user hops around like crazy the original
open operation will still occur in the correct order (though there's nothing stopping them starting a new operation which will cause
random ordering.)

However, there is one downside to this behaviour. If the parse operation is requested by the browser, then it is
possible for the user to change directories while the coroutine is yielded. If you were to resume the coroutine
in that situation, then any operations you do are wasted, and unexpected bahaviour could happen.
file-browser will automatically detect when it receives a list from an aborted coroutine, so there is no risk
of the current list being replaced, but any other logic in your script will continue until `parse` returns.

To fix this there are two methods available in the state table, the `yield()` method is a wrapper around `coroutine.yield()` that
detects when the browser has abandoned the parse, and automatically kills the coroutine by throwing an error.
The `is_coroutine_current()` method simply compares if the current coroutine (as returned by `coroutine.running()`) matches the
coroutine that the browser is waiting for. Remember this is only a problem when the browser is the source of the request,
if the request came from a script-message, or from a loadlist command there are no issues.

### The List Array

The list array must be made up of item_tables, which contain details about each item in the directory.
Each item has the following members:

| key         | type            | required | description                                                                                                                                       |
|-------------|-----------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| name        | string          | yes      | name of the item, and the string to append after the directory when opening a file/folder                                                         |
| type        | string          | yes      | determines whether the item is a file ("file") or directory ("dir")                                                                               |
| label       | string          | no       | an alternative string to print to the screen instead of name                                                                                      |
| ass         | string          | no       | a string to print to the screen without escaping ass styling - overrides label and name                                                           |
| path        | string          | no       | opening the item uses this full path instead of appending directory and name                                                                      |
| redirect    | bool            | no       | whether `path` should redirect the browser when opening a directory - default yes (nil counts as true)                                            |
| mpv_options | string or table | no       | a list of options to be sent to mpv when loading the file - can be in the form `opt1=value1,opt2=value2,...` or a table of string keys and values |

File-browser expects that `type` and `name` will be set for each item, so leaving these out will probably crash the script.
File-browser also assumes that all directories end in a `/` when appending name, and that there will be no backslashes.
The API function [`fix_path`](#utility-functions) can be used to ensure that paths conform to file-browser rules.

Here is an example of a static list table being returned by the `parse` method.
This would allow one to specify a custom list of items.

```lua
function parser:parse(directory, state)
    local list = {
        { name = "first/", type = "dir" },
        { name = "second/", type = "dir" },
        { name = "third/", type = "dir" },
        { name = "file%01", type = "file", label = "file1" },
        { name = "file2", type = "file", path = "https://youtube.com/video" },
    }

    return list
end
```

### The Opts Table

The options table allows scripts to better control how they are handled by file-browser.
None of these values are required, and the opts table can even left as nil when returning.

| key             | type    | description                                                                                                                  |
|-----------------|---------|------------------------------------------------------------------------------------------------------------------------------|
| filtered        | boolean | if true file-browser will not run the standard filter() function on the list                                                 |
| sorted          | boolean | if true file-browser will not sort the list                                                                                  |
| directory       | string  | changes the browser directory to this - used for redirecting to other locations                                              |
| directory_label | string  | display this label in the header instead of the actual directory - useful to display encoded paths                           |
| empty_text      | string  | display this text when the list is empty - can be used for error messages                                                    |
| selected_index  | number  | the index of the item on the list to select by default - a.k.a. the cursor position                                          |
| id              | number  | id of the parser that successfully returns a list - set automatically, but can be set manually to take ownership (see defer) |

The previous static example, but modified so that file browser does not try to filter or re-order the list:

```lua
function parser:parse(directory, state)
    local list = {
        { name = "first/", type = "dir" },
        { name = "second/", type = "dir" },
        { name = "third/", type = "dir" },
        { name = "file%01", type = "file", label = "file1" },
        { name = "file2", type = "file", path = "https://youtube.com/video" },
    }

    return list, { sorted = true, filtered = true }
end
```

`id` is used to declare ownership of a page. The name of the parser that has ownership is used for custom-keybinds parser filtering.
When using `defer` id will be the id of whichever parser first returned a list.
This is the only situation when a parser may want to set id manually.

## Priority Suggestions

Below is a table of suggested priority ranges:

| Range   | Suggested Use                                                                                  | Example parsers                                |
|---------|------------------------------------------------------------------------------------------------|------------------------------------------------|
| 0-20    | parsers that purely modify the results of other parsers                                        | [m3u-fixer](m3u-browser.lua)                   |
| 21-40   | virtual filesystems which need to link to the results of other parsers                         | [favourites](favourites.lua)                   |
| 41-50   | to support specific sites or systems which can be inferred from the path                       |                                                |
| 51-80   | limitted support for specific protocols which requires complex parsing to verify compatability | [apache](apache-browser.lua)                   |
| 81-90   | parsers that only need to modify the results of full parsers                                   | [home-label](home-label.lua)                   |
| 91-100  | use for parsers which fully support a non-native protocol with absolutely no overlap           | [ftp](ftp-browser.lua), [m3u](m3u-browser.lua) |
| 101-109 | replacements for the native file parser or fallbacks for the full parsers                      | [powershell](powershell.lua)                   |
| 110     | priority of the native file parser - don't use                                                 |                                                |
| 111+    | fallbacks for native parser - potentially alternatives to the default root                     |                                                |

## Keybinds

Addons have the ability to set custom keybinds using the `keybinds` field in the `parser` table. `keybinds` must be an array of tables, each of which may be in two forms.

Firstly, the keybind_table may be in the form
`{ "key", "name", [function], [flags] }`
where the table is an array whose four values corresond to the four arguments for the [mp.add_key_binding](https://mpv.io/manual/master/#lua-scripting-[,flags]]\)) API function.

```lua
local function main(keybind, state, co)
    -- deletes files
end

parser.keybinds = {
    { "Alt+DEL", "delete_files", main, {} },
}
```

Secondly, the keybind_table may use the same formatting as file-browser's [custom-keybinds](../custom-keybinds.md).
Using the array form is equivalent to setting `key`, `name`, `command`, and `flags` of the custom-keybind form, and leaving everything else on the defaults.

```lua
parser.keybinds = {
    {
        key = "Alt+DEL",
        name = "delete_files",
        command = {"run", "rm", "%F"},
        filter = "files"
    }
}
```

These keybinds are evaluated only once shortly after the addon is loaded, they cannot be modified dynamically during runtime.
Keybinds are applied after the default keybinds, but before the custom keybinds. This means that addons can overwrite the
default keybinds, but that users can ovewrite addon keybinds. Among addons, those with higher priority numbers have their keybinds loaded before those
with lower priority numbers.
Remember that a lower priority value is better, they will overwrite already loaded keybinds.
Keybind passthrough works the same way, though there is some custom behaviour when it comes to [raw functions](#keybind-functions).

### Keybind Names

In either form the naming of the function is different from custom keybinds. Instead of using the form `file_browser/dynamic/custom/[name]`
they use the form `file_browser/dynamic/[parser_ID]/[name]`, where `[parser_id]` is a unique string ID for the parser, which can be retrieved using the
`parser:get_id()` method.

### Native Functions vs Command Tables

There are two ways of specifying the behaviour of a keybind.
It can be in command table form, as done when using custom-keybind syntax, and it can be done in
native function form, as done when using the `mp.add_key_binding` syntax.
However, these two ways of specifying commands are independant of how the overall keybind is defined.
What this means is that the command field of the custom-keybinds syntax can be an array, and the
3rd value in the array syntax can be a table of mpv commands.

```lua
local function main(keybind, state, co)
    -- deletes files
end

-- this is a valid keybind table
parser.keybinds = {
    { "Alt+DEL", "delete_files", {"run", "rm", "%F"}, {} },

    {
        key = "Alt+DEL",
        name = "delete_files",
        command = main
    }
}
```

There are some limitations however, not all custom-keybind options are supported when using native functions.
The supported options are: `key`, `name`, `condition`, `flags`, `parser`, `passthrough`. The other options can be replicated manually (see below).

### Keybind Functions

This section details the use of keybind functions.

#### Function Call

If one uses the raw function then the functions are called directly in the form:

`fn(keybind, state, coroutine)`

Where `keybind` is the keybind_table of the key being run, `state` is a table of state values at the time of the key press, and `coroutine` is the coroutine object
that the keybind is being executed inside.

The `keybind` table uses the same fields as defined
in [custom-keybinds.md](../custom-keybinds.md). Any random extra fields placed in the original
`file-browser-keybinds.json` will likely show up as well (this is not guaranteed).
Note that even if the array form is used, the `keybind` table will still use the custom-keybind format.

The entire process of running a keybind is handled with a coroutine, so the addon can safely pause and resume the coroutine at will. The `state` table is provided to
allow addons to keep a record of important state values that may be changed during a paused coroutine.

#### State Table

The state table contains copies of the following values at the time of the key press.

| key             | description                                                                                                                                           |
|-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| directory       | the current directory                                                                                                                                 |
| directory_label | the current directory_label - can (and often will) be `nil`                                                                                           |
| list            | the current list_table                                                                                                                                |
| selected        | index of the currently selected list item                                                                                                             |
| selection       | table of currently selected items (for multi-select) - in the form { index = true, ... } - always available even if the `multiselect` flag is not set |
| parser          | a copy of the parser object that provided the current directory                                                                                       |

The following example shows the implementation of the `delete_files` keybind using the state values:

```lua
local fb = require "file-browser"       -- see #api-functions and #utility-functions

local function main(keybind, state, co)
    for index, item in state.list do
        if state.selection[index] and item.type == "file" then
            os.remove( fb.get_full_path(item, state.directory) )
        end
    end
end

parser.keybinds = {
    { "Alt+DEL", "delete_files", main, {} },
}
```

#### Passthrough

If the `passthrough` field of the keybind_table is set to `true` or `false` then file-browser will
handle everything. However, if the passthrough field is not set (meaning the bahviour should be automatic)
then it is up to the addon to ensure that they are
correctly notifying when the operation failed and a passthrough should occur.
In order to tell the keybind handler to run the next priority command, the keybind function simply needs to return the value `false`,
any other value (including `nil`) will be treated as a successful operation.

The below example only allows removing files from the `/tmp/` directory and allows other
keybinds to run in different directories:

```lua
local fb = require "file-browser"       -- see #api-functions and #utility-functions

local function main(keybind, state, co)
    if state.directory ~= "/tmp/" then return false end

    for index, item in state.list do
        if state.selection[index] and item.type == "file" then
            os.remove( fb.get_full_path(item, state.directory) )
        end
    end
end

parser.keybinds = {
    { "Alt+DEL", "delete_files", main, {} },
}
```

## The API

The API is available through a module, which can be loaded with `require "file-browser"`.
The API provides a variety of different values and functions for an addon to use
in order to make them more powerful.
Function definitions are written using Typescript-style type annotations.

```lua
local fb = require "file-browser"

local parser = {
    priority = 100,
}

function parser:setup()
    fb.register_root_item("Example/")
end

return parser
```

### Parser API

In addition to the standard API there is also an extra parser API that provides
several parser specific methods, listed below using `parser:method` instead of `fb.function`.
This API is added to the parser object after it is loaded by file-browser,
so if a script wants to call them immediately on load they must do so in the `setup` method.
All the standard API functions are also available in the parser API.

```lua
local parser = {
    priority = 100,
}

function parser:setup()
    -- same operations
    self.insert_root_item({ name = "Example/", type = "dir" })
    parser.insert_root_item({ name = "Example/", type = "dir" })
end

-- will not work since the API hasn't been added to the parser yet
parser.insert_root_item({ name = "Example/", type = "dir" })

return parser
```

### General Functions

#### `fb.API_VERSION: string`

The current API version in use by file-browser.

#### `fb.add_default_extension(ext: string): void`

Adds the given extension to the default extension filter whitelist. Can only be run inside the `setup()` method.

#### `fb.browse_directory(directory: string): void`

Clears the cache and opens the given directory in the browser. If the browser is closed then it will be opened.
This function is non-blocking, it is possible that the function will return before the directory has finished
being scanned.

This is the equivalent of calling the `browse-directory` script-message.

#### `fb.insert_root_item(item: item_table, pos?: number): void`

Add an item_table to the root list at the specified position. If `pos` is nil then append to the end of the root.
`item` must be a valid item_table of `type='dir'`.

#### `fb.register_parseable_extension(ext: string): void`

Register a file extension that the browser will attempt to open, like a directory - for addons which can parse files such
as playlist files.

#### `fb.register_root_item(item: string | item_table, priority?: number): boolean`

Registers an item to be added to the root and an optional priority value that determines the position relative to other items (default is 100).
A lower priority number is better, meaning they will be placed earlier in the list.
Only adds the item if it is not already in the root and returns a boolean that specifies whether or not the item was added.
Must be called during or after the `parser:setup()` method is run.

If `item` is a string then a new item_table is created with the values: `{ type = 'dir', name = item }`.
If `item` is an item_table then it must be a valid directory item.
Use [`fb.fix_path(name, true)`](#fbfix_pathpath-string-is_directory-boolean-string) to ensure the name field is correct.

This function should be used over the older `fb.insert_root_item`.

#### `fb.remove_parseable_extension(ext: string): void`

Remove a file extension that the browser will attempt to open like a directory.

#### `fb.parse_directory(directory: string, parse?: parse_state_table): (list_table, opts_table) | nil`

Starts a new scan for the given directory and returns a list_table and opts_table on success and `nil` on failure.
Must be called from inside a [coroutine](#coroutines).

This function allows addons to request the contents of directories from the loaded parsers. There are no protections
against infinite recursion, so be careful about calling this from within another parse.

Do not use the same `parse` table for multiple parses, state values for the two operations may intefere with each other
and cause undefined behaviour. If the `parse.source` field is not set then it will be set to `"addon"`.

Note that this function is for creating new parse operations, if you wish to create virtual directories or modify
the results of other parsers then use [`defer`](#parserdeferdirectory-string-list_table-opts_table--nil).

Also note that every parse operation is expected to have its own unique coroutine. This acts as a unique
ID that can be used internally or by other addons. This means that if multiple `parse_directory` operations
are run within a single coroutine then file-browser will automatically create a new coroutine for the scan,
which hands execution back to the original coroutine upon completion.

#### `parser:register_root_item(item: string | item_table, priority?: number): boolean`

A wrapper around [`fb.register_root_item`](#fbregister_root_itemitem-string--item_table-priority-number-boolean)
which uses the parser's priority value if `priority` is undefined.

### Advanced Functions

#### `fb.clear_cache(): void`

Clears the directory cache. Use this if you are modifying the contents of directories other
than the current one to ensure that their contents will be rescanned when next opened.

#### `fb.coroutine.assert(err?: string): coroutine`

Throws an error if it is not called from within a coroutine. Returns the currently running coroutine on success.
The string argument can be used to throw a custom error string.

#### `fb.coroutine.callback(): function`

Creates and returns a callback function that resumes the current coroutine.
This function is designed to help streamline asynchronous operations. The best way to explain is with an example:

```lua
local function execute(args)
    mp.command_native_async({
            name = "subprocess",
            playback_only = false,
            capture_stdout = true,
            capture_stderr = true,
            args = args
        }, fb.coroutine.callback())

    local _, cmd = coroutine.yield()

    return cmd.status == 0 and cmd.stdout or nil
end
```

This function uses the mpv [subprocess](https://mpv.io/manual/master/#command-interface-subprocess)
command to execute some system operation. To prevent the whole script (file-browser and all addons) from freezing
it uses the [command_native_async](https://mpv.io/manual/master/#lua-scripting-mp-command-native-async(table-[,fn])) command
to execute the operation asynchronously and takes a callback function as its second argument.

`coroutine.callback())` will automatically create a callback function to resume whatever coroutine ran the `execute` function.
Any arguments passed into the callback function (by the async function, not by you) will be passed on to the resume;
in this case `command_native_async` passes three values into the callback, of which only the second is of interest to me.

The unsaid expectation is that the programmer will yield execution before that callback returns. In this example I
yield immediately after running the async command.

If you are doing this during a parse operation you could also substitute `coroutine.yield()` with `parse_state:yield()` to abort the parse if the user changed
browser directories during the asynchronous operation.

If you have no idea what I've been talking about read the [Lua manual on coroutines](https://www.lua.org/manual/5.1/manual.html#2.11).

#### `fb.coroutine.resume_catch(co: coroutine, ...): (boolean, ...)`

Runs `coroutine.resume(co, ...)` with the given coroutine, passing through any additional arguments.
If the coroutine throws an error then an error message and stacktrace is printed to the console.
All the return values of `coroutine.resume` are caught and returned.

#### `fb.coroutine.resume_err(co: coroutine, ...): boolean`

Runs `coroutine.resume(co, ...)` with the given coroutine, passing through any additional arguments.
If the coroutine throws an error then an error message and stacktrace is printed to the console.
Returns the success boolean returned by `coroutine.resume`, but drops all other return values.

#### `fb.coroutine.run(fn: function, ...): void`

Runs the given function in a new coroutine, passing through any additional arguments.

#### `fb.rescan(): void`

Rescans the current directory. Equivalent to Ctrl+r without the cache refresh for higher level directories.

#### `fb.redraw(): void`

Forces a redraw of the browser UI.

#### `parser:defer(directory: string): (list_table, opts_table) | nil`

Forwards the given directory to the next valid parser. For use from within a parse operation.

The `defer` function is very powerful, and can be used by scripts to create virtual directories, or to modify the results of other parsers.
However, due to how much freedom Lua gives coders, it is impossible for file-browser to ensure that parsers are using defer correctly, which can cause unexpected results.
The following are a list of recommendations that will increase the compatability with other parsers:

* Always return the opts table that is returned by defer, this can contain important values for file-browser, as described [above](#the-opts-table).
  * If required modify values in the existing opts table, don't create a new one.
* Respect the `sorted` and `filtered` values in the opts table. This may mean calling `sort` or `filter` manually.
* Think about how to handle the `directory_label` field, especially how it might interract with any virtual paths the parser may be maintaining.
* Think about what to do if the `directory` field is set.
* Think if you want your parser to take full ownership of the results of `defer`, if so consider setting `opts.id = self:get_id()`.
  * Currently this only affects custom keybind filtering, though it may be changed in the future.

The [home-label](https://github.com/CogentRedTester/mpv-file-browser/blob/master/addons/home-label.lua)
addon provides a good simple example of the safe use of defer. It lets the normal file
parser load the home directory, then modifies the directory label.

```lua
local mp = require "mp"
local fb = require "file-browser"

local home = fb.fix_path(mp.command_native({"expand-path", "~/"}), true)

local home_label = {
    version = '1.0.0',
    priority = 100
}

function home_label:can_parse(directory)
    return directory:sub(1, home:len()) == home
end

function home_label:parse(directory, ...)
    local list, opts = self:defer(directory, ...)

    if (not opts.directory or opts.directory == directory) and not opts.directory_label then
        opts.directory_label = "~/"..(directory:sub(home:len()+1) or "")
    end

    return list, opts
end

return home_label
```

### Utility Functions

#### `fb.ass_escape(str: string, substitute_newline?: true | string): string`

Returns the `str` string with escaped ass styling codes.
The optional 2nd argument allows replacing newlines with the given string, or `'\\n'` if set to `true`.

#### `fb.copy_table(t: table, depth?: number): table`

Returns a copy of table `t`.
The copy is done recursively to the given `depth`, and any cyclical table references are maintained.
Both keys and values are copied. If `depth` is undefined then it defaults to `math.huge` (infinity).
Additionally, the original table is stored in the `__original` field of the copy's metatable.
The copy behaviour of the metatable itself is subject to change, but currently it is not copied.

#### `fb.filter(list: list_table): list_table`

Iterates through the given list and removes items that don't pass the user set filters
(dot files/directories and valid file extensions).
Returns the list but does not create a copy; the `list` table is filtered in-place.

#### `fb.fix_path(path: string, is_directory?: boolean): string`

Takes a path and returns a file-browser compatible path string.
The optional second argument is a boolean that tells the function to format the path to be a
directory.

#### `fb.get_extension(filename: string, def?: any): string | def`

Returns the file extension for the string `filename`, or `nil` if there is no extension.
If `def` is defined then that is returned instead of `nil`.

The full stop is not included in the extension, so `test.mkv` will return `mkv`.

#### `fb.get_full_path(item: item_table, directory?: string): string`

Takes an item table and returns the item's full path assuming it is in the given directory.
Takes into account `item.name`/`item.path` fields, etc.
If directory is nil then it uses the currently open directory.

#### `fb.get_protocol(url: string, def?: any): string | def`

Returns the protocol scheme for the string `url`, or `nil` if there is no scheme.
If `def` is defined then that is returned instead of `nil`.

The `://` is not included, so `https://example.com/test.mkv` will return `https`.

#### `fb.iterate_opt(opts: string): iterator`

Takes an options string consisting of a list of items separated by the `root_separators` defined in `file_browser.conf` and
returns an iterator function that can be used to iterate over each item in the list.

```lua
local opt = "a,b,zz z"                -- root_separators=,
for item in fb.iterate_opt(opt) do
    print(item)                       -- prints: 'a', 'b', 'zz z'
end
```

#### `fb.join_path(p1: string, p2: string): string`

A wrapper around [`mp.utils.join_path`](https://mpv.io/manual/master/#lua-scripting-utils-join-path(p1,-p2))
which treats paths with network protocols as absolute paths.

#### `fb.pattern_escape(str: string): string`

Returns `str` with Lua special pattern characters escaped.

#### `fb.sort(list: list_table): list_table`

Iterates through the given list and sorts the items using file-browser's sorting algorithm.
Returns the list but does not create a copy; the `list` table is sorted in-place.

#### `fb.valid_file(name: string): boolean`

Tests if the string `name` passes the user set filters for valid files (extensions/dot files/etc).

#### `fb.valid_dir(name: string): boolean`

Tests if the string `name` passes the user set filters for valid directories (dot folders/etc).

### Getters

These functions allow addons to safely get information from file-browser.
All tables returned by these functions are copies sent through the [`fb.copy_table`](#fbcopy_tablet-table-depth-number-table)
function to ensure addons can't accidentally break things.

#### `fb.get_audio_extensions(): table`

Returns a set of extensions like [`fb.get_extensions`](#fbget_extensions-table) but for extensions that are opened
as additional audio tracks.
All of these are included in `fb.get_extensions`.

#### `fb.get_current_file(): table`

A table containing the path of the current open file in the form:
`{directory = "/home/me/", name = "bunny.mkv", path = "/home/me/bunny.mkv"}`.

#### `fb.get_current_parser(): string`

The unique id of the parser that successfully parsed the current directory.

#### `fb.get_current_parser_keyname(): string`

The `keybind_name` of the parser that successfully parsed the current directory.
Used for custom-keybind filtering.

#### `fb.get_directory(): string`

The current directory open in the browser.

#### `fb.get_dvd_device(): string`

The current dvd-device as reported by mpv's `dvd-device` property.
Formatted to work with file-browser.

#### `fb.get_extensions(): table`

Returns the set of valid extensions after applying the user's whitelist/blacklist options.
The table is in the form `{ mkv = true, mp3 = true, ... }`.
Sub extensions, audio extensions, and parseable extensions are all included in this set.

#### `fb.get_list(): list_table`

The list_table currently open in the browser.

#### `fb.get_open_status(): boolean`

Returns true if the browser is currently open and false if not.

#### `fb.get_opt(name: string): string | number | boolean`

Returns the script-opt with the given name.

#### `fb.get_parsers(): table`

Returns a table of all the loaded parsers/addons.
The formatting of this table in undefined, but it should
always contain an array of the parsers in order of priority.

#### `fb.get_parse_state(co?: coroutine): parse_state_table`

Returns the [parse_state table](#parse-state-table) for the given coroutine.
If no coroutine is given then it uses the running coroutine.
Every parse operation is guaranteed to have a unique coroutine.

#### `fb.get_parseable_extensions(): table`

Returns a set of extensions like [`fb.get_extensions`](#fbget_extensions-table) but for extensions that are
treated as parseable by the browser.
All of these are included in `fb.get_extensions`.

#### `fb.get_root(): list_table`

Returns the root table.

#### `fb.get_script_opts(): table`

The table of script opts set by the user. This currently does not get
changed during runtime, but that is not guaranteed for future minor version increments.

#### `fb.get_selected_index(): number`

The current index of the cursor.
Note that it is possible for the cursor to be outside the bounds of the list;
for example when the list is empty this usually returns 1.

#### `fb.get_selected_item(): item_table | nil`

Returns the item_table of the currently selected item.
If no item is selected (for example an empty list) then returns nil.

#### `fb.get_state(): table`

Returns the current state values of the browser.
These are not documented and are subject to change at any time,
adding a proper getter for anything is a valid request.

#### `fb.get_sub_extensions(): table`

Returns a set of extensions like [`fb.get_extensions`](#fbget_extensions-table) but for extensions that are opened
as additional subtitle tracks.
All of these are included in `fb.get_extensions`.

#### `parser:get_id(): string`

The unique id of the parser. Used for log messages and various internal functions.

#### `parser:get_index(): number`

The index of the parser in order of preference (based on the priority value).
`defer` uses this internally.

### Setters

#### `fb.set_selected_index(pos: number): number | false`

Sets the cursor position and returns the new index.
If the input is not a number return false, if the input is out of bounds move it in bounds.

## Examples

For standard addons that add support for non-native filesystems, but otherwise don't do anything fancy, see [ftp-browser](ftp-browser.lua) and [apache-browser](apache-browser.lua).

For more simple addons that make a few small modifications to how other parsers are displayed, see [home-label](home-label.lua).

For more complex addons that maintain their own virtual directory structure, see
[favourites](favourites.lua).
