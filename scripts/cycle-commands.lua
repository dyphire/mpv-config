--[[
    script to cycle commands with a keybind, accomplished through script messages
    available at: https://github.com/CogentRedTester/mpv-scripts

    syntax:
        script-message cycle-commands "command1 args" "command2 args" "command3 args"

    The syntax of each command is identical to the standard input.conf syntax, but each command must be
    a quoted string. Note that this may require you to nest (and potentially escape) quotes for the arguments.
    Read the mpv documentation for how to do this: https://mpv.io/manual/master/#flat-command-syntax.

    Semicolons also work exactly like they do normally, so you can easily send multiple commands each cycle.

    Here are some examples of the same command using different quotes:
        script-message cycle-commands "show-text one 1000 ; print-text two" "show-text \"three four\""
        script-message cycle-commands 'show-text one 1000 ; print-text two' 'show-text "three four"'
        script-message cycle-commands ``show-text one 1000 ; print-text two`` ``show-text "three four"``

    This would, on keypress one, print 'one' to the OSD for 1 second and 'two' to the console,
    and on keypress two 'three four' would be printed to the OSD.
    Note that single (') and backtick (`) quoting was only added in mpv v0.34.

    There are no limits to the number of commands, and the script message can be used as often as one wants.
    The script stores the current iteration position for each unique set of command strings,
    so there should be no overlap unless one binds the exact same set of strings (including spacing).

    If the first command is `!reverse`, then the commands are cycled in the opposite direction.
    If every subsequent command string is identical to a non-reversed cycle, then they share
    their iteration position, making it possible to 'seek' forwards or backwards in the cycle:
        script-message cycle-commands 'apply-profile profile1' 'apply-profile profile2' 'apply-profile profile3'
        script-message cycle-commands !reverse 'apply-profile profile1' 'apply-profile profile2' 'apply-profile profile3'

    Most commands should print messages to the OSD automatically, this can be controlled
    by adding input prefixes to the commands: https://mpv.io/manual/master/#input-command-prefixes.
    Some commands will not print an osd message even when told to, in this case you have two options:
    you can add a show-text command to the cycle, or you can use the cycle-commands/osd script message
    which will print the command string to the osd. For example:
        script-message cycle-commands 'apply-profile profile1;show-text "applying profile1"' 'apply-profile profile2;show-text "applying profile2"'
        script-message cycle-commands/osd 'apply-profile profile1' 'apply-profile profile2'

    Any osd messages printed by the command will override the message sent by cycle-commands/osd.
]]--

local mp = require 'mp'
local msg = require 'mp.msg'

--keeps track of the current position for a specific cycle
local iterators = {}

--main function to identify and run the cycles
local function main(osd, ...)
    local commands = {...}

    local reverse = commands[1] == '!reverse'
    if reverse then table.remove(commands, 1) end

    --to identify the specific cycle we'll concatenate all the strings together to use as our table key
    local str = ("%d> %s"):format(#commands, table.concat(commands, '|'))
    msg.trace('recieved:', str)

    -- we'll initialise the iterator at 0 (an invalid position) to support forward or backwards iteration
    if iterators[str] == nil then
        msg.debug('unknown cycle, creating iterator')
        iterators[str] = 0
    end

    iterators[str] = iterators[str] + (reverse and -1 or 1)
    if iterators[str] > #commands then iterators[str] = 1 end
    if iterators[str] < 1 then iterators[str] = #commands end

    --mp.command should run the commands exactly as if they were entered in input.conf.
    --This should provide universal support for all input.conf command syntax
    local cmd = commands[ iterators[str] ]
    msg.verbose('sending command:', cmd)
    if osd then mp.osd_message(cmd) end
    mp.command(cmd)
end

mp.register_script_message('cycle-commands', function(...) main(false, ...) end)
mp.register_script_message('cycle-commands/osd', function(...) main(true, ...) end)