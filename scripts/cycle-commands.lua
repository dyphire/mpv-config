--[=====[
    script to cycle commands with a keybind, accomplished through script messages
    available at: https://github.com/CogentRedTester/mpv-scripts

    syntax:
        script-message cycle-commands "command1" "command2" "command3"

    The syntax of each command is identical to the standard input.conf syntax, but each command must be within
    a pair of double quotes.

    Commands with mutiword arguments require you to send double quotes just like normal command syntax, however,
    you will need to escape the quotes with a backslash so that they are sent as part of the string.
    Semicolons also work exactly like they do normally, so you can easily send multiple commands each cycle.

    Here is an example of a standard input.conf entry:

        script-message cycle-commands "show-text one 1000 ; print-text two" "show-text \"three four\""

    This would, on keypress one, print 'one' to the OSD for 1 second and 'two' to the console,
    and on keypress two 'three four' would be printed to the OSD.
    Notice how the quotation marks around 'three four' are escaped using backslashes.
    All other syntax details should be exactly the same as usual input commands.

    There are no limits to the number of commands, and the script message can be used as often as one wants,
    the script stores the current iteration for each unique cycle command, so there should be no overlap
    unless one binds the exact same command string (including spacing)
]=====]--

local mp = require 'mp'
local msg = require 'mp.msg'

--keeps track of the current position for a specific cycle
local iterators = {}

--main function to identify and run the cycles
local function main(...)
    local commands = {...}

    --to identify the specific cycle we'll concatenate all the strings together to use as our table key
    local str = table.concat(commands, " | ")
    msg.trace('recieved:', str)

    if iterators[str] == nil then
        msg.debug('unknown cycle, creating iterator')
        iterators[str] = 1
    else
        iterators[str] = iterators[str] + 1
        if iterators[str] > #commands then iterators[str] = 1 end
    end

    --mp.command should run the commands exactly as if they were entered in input.conf.
    --This should provide universal support for all input.conf command syntax
    local cmd = commands[ iterators[str] ]
    msg.verbose('sending command:', cmd)
    mp.command(cmd)
end

mp.register_script_message('cycle-commands', main)
