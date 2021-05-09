# mpv-search-page

![image](https://raw.githubusercontent.com/CogentRedTester/mpv-search-page/master/screenshots/front.png)

This script allows you to search for keybinds, properties, options and commands and have matching entries display on the OSD.
The search is case insensitive by default, and the script sends the filter directly to a lua string match function, so you can use patterns to get more complex filtering. For options and limitations see the [Queries](#queries) and [Flags](#flags) sections.

This script requires [mpv-scroll-list](https://github.com/CogentRedTester/mpv-scroll-list) and [mpv-user-input](https://github.com/CogentRedTester/mpv-user-input) to work.
Simply place `scroll-list.lua` and `user-input-module.lua` into the `~~/script-modules` folder, and `user-input.lua` into the `~~/scripts` folder.

## Pages

The search pages will remain open until the esc key is pressed. When the page is open the up and down arrow can be used to scroll through the results, and the left and right arrows can be used to pan horizontally to see any cut off values.

There are 4 main search pages, each page has its own independant state, and while open one can cycle between them in the below order:

### Keybinds

![keybinds_page](https://raw.githubusercontent.com/CogentRedTester/mpv-search-page/master/screenshots/keybinds_page.png)

The keybind page is for searching keybindings. By default the script searches the name of the key; the command the key runs; the input section the key is part of; the owner of the key (typically the script that creates it); and any comments on the same line as the key in input.conf.

The search page shows the key name in lavendar on the left, then the command in cyan, and finally the comment in green, preceeded by a `#`. In addition, if the keybinding is part of a section other than the default, the section will be printed in yellow brackets between the key name and the command.

Keybinds which are disabled or overridden will be shown at 50% opacity.

Pressing ENTER on an entry will run the command for that entry.

### Commands

![commands_page](https://raw.githubusercontent.com/CogentRedTester/mpv-search-page/master/screenshots/command_page.png)

The command page displays input commands that can be used in input.conf or the console, as well as their arguments. The script only searches the name of the commands.

The search page shows all of the command names in lavendar on the left. The following words are arguments that the command takes, green arguments are compulsory, while cyan are optional. Each argument contains its type in small yellow brackets. Note that the type, and colour-coding is taken straight from the lua API, so it may not always be correct.

Pressing ENTER on an entry will load the command into console.lua, and print the arguments and their types to the console for reference.

### Options

![option_page](https://raw.githubusercontent.com/CogentRedTester/mpv-search-page/master/screenshots/option_page.png)

The options page is for searching options that can be set on the commandline or through mpv.conf. Most of these options have matching properties. The script searches the option name, as well as any choices that are available.

The option page contains the option name in lavendar, directly followed by the option type in yellow. The cyan entry is the current value of the option, if available, and the yellow is the default option value. The green value shows different information depending on the option type; if the option is a float, integer, double, aspect, or bytesize, then the valid option range is displayed; if the option is a choice, then the valid choices are listed.

### Properties

![property_page](https://raw.githubusercontent.com/CogentRedTester/mpv-search-page/master/screenshots/property_page.png)

The properties page shows all of the properties, and their current values, for the current file. Only the property name is included in the search. Note that the property list contains most options as well.

The search page simply contains the property name on the left, followed by it's current value (if it has one).

## Default Keybinds

The default keybinds are listed below, these can be overwritten using input.conf:

f12         script-binding open-search-page
Shift+f12   script-binding open-search-page/advanced
            script-message open-page [page]
            script-message open-page/advanced [page]
The default `f12` bindings open the last open page. The advanced commands open a second input to add search flags.
The script messages allow you to specify which page to open, valid values are `keybinds`, `commands`, `options`, and `properties`.

### Dynamic Keybinds

In addition the following keybinds are dynamically created when the search page is open, these cannot currently be changed:

f12             opens search input
Shift+f12       opens advanced search input
esc             closes the search page
down            scrolls the page down
up              scrolls the page up
left            pans the whole search page left
right           pans the whole search page right
Shift+left      open prev page
Shift+right     open next page
Ctrl+left       open prev page and run latest search
Ctrl+right      open next page and run latest search
Ctrl+enter      re-run latest search on current page
enter           perform action (see pages for details)
## Queries

![query_example](https://raw.githubusercontent.com/CogentRedTester/mpv-search-page/master/screenshots/search_input.png)

Search Queries are done through `mpv-user-input`. A search input will be opened automatically the first time a specific page is opened, and can be opened again at any time using one of the `f12` keybinds.

Advanced searches will open a second input after the main search query where you can enter a series of search [flags](#flags).

Sending a query with an empty string (pressing ENTER with nothing in the input) will show all results for the selected category.

## Flags

By default the script will convert both the search query, and all the strings it scans into lower case to maximise the number of results, as well as escaping special pattern characters. It returns any result that contains the full query somewhere in its values. Flags can be used to modify this behaviour. Flags are values you can enter into the advanced search input, currently there are 3:

wrap        search for a whole word only (may not work with some symbols)
pattern     don't convert the query to lowercase and don't escape pattern characters
exact       don't convert anything into lowercase
Multiple flags can be used at once by separating them with spaces.

## Lua Patterns

This script sends queries into the Lua string find function, the find function supports something called [patterns](http://lua-users.org/wiki/PatternsTutorial) to help make more complex searches. In order to facilitate this there are a number of symbols (`^$()%.[]*+-?`), which are reserved for pattern creation.
By default the script will escape these special characters to make searches more convenient, however this can be disabled with the `pattern` [flag](#flags).

## Configuration

The full list of options, and their defaults are shown in [search_page.conf](search_page.conf).

## Future Plans

Some ideas for future functionality:

* ~~Implement scrolling~~
* Json options file to configure jumplist behaviour/commands
  * ~~Add jumplists for properties and options~~
  * Add multiple commands for each item using Ctrl,Alt, etc
  * ~~Implement a cursor to select items for commands (same as jumplist)~~
* Search multiple queries at once (may already be possible with lua patterns)
