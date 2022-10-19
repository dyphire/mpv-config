--[[
    An extremely basic script that only executes a command after a short delay
    Available at: https://github.com/CogentRedTester/mpv-scripts

    There are two possible syntaxes:

    (1)    script-message delay-command [delay] [commandstring]

    where 'delay' is a number in seconds and commandstring is a full input.conf
    line formatted as a single string. This may require special characters to be escaped.

    (2)    script-message delay-command [delay] [command] [arg1] [arg2] ...

    Here the command and each argument is a separate value sent to the script-message.
    This looks the same as a normal input.conf command, but lacks some abilities, such as
    running multiple command with semicolons.

    Note that these two different syntaxes use different mpv API calls. The 1st
    syntax uses the same call as a normal input.conf command, the 2nd uses the
    mp.commandv API call, which has slightly different behaviour. For example
    the input.conf commands always try to print messages to the OSD, but
    mp.commandv() does not.
]]

local mp = require "mp"
local msg = require "mp.msg"

local function main(delay, ...)
    local success, err = pcall(function() delay = tonumber(delay) end)

    if not success then return msg.error(err) end
    if delay == nil then return msg.error("delay was not a valid number") end

    msg.verbose("received command with delay of "..delay.." seconds")
    if delay < 0 then delay = 0 end
    local command = {...}

    mp.add_timeout(delay, function()
        if #command == 1 then
            msg.debug("running command: "..command[1])
            mp.command(command[1])
        else
            msg.debug('running command: "'..table.concat(command, '" "')..'"')
            mp.commandv(unpack(command))
        end
    end)
end

mp.register_script_message("delay-command", main)