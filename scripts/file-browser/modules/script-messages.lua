local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = require 'modules.options'
local g = require 'modules.globals'
local fb_utils = require 'modules.utils'
local scanning = require 'modules.navigation.scanning'

local script_messages = {}

--allows other scripts to request directory contents from file-browser
function script_messages.get_directory_contents(directory, response_str)
    fb_utils.coroutine.run(function()
        if not directory then msg.error("did not receive a directory string"); return end
        if not response_str then msg.error("did not receive a response string"); return end

        directory = mp.command_native({"expand-path", directory}, "")
        if directory ~= "" then directory = fb_utils.fix_path(directory, true) end
        msg.verbose(("recieved %q from 'get-directory-contents' script message - returning result to %q"):format(directory, response_str))

        local list, opts = scanning.scan_directory(directory, { source = "script-message" } )
        if opts then opts.API_VERSION = g.API_VERSION end

        local err
        list, err = fb_utils.format_json_safe(list)
        if not list then msg.error(err) end

        opts, err = fb_utils.format_json_safe(opts)
        if not opts then msg.error(err) end

        mp.commandv("script-message", response_str, list or "", opts or "")
    end)
end

--a helper script message for custom keybinds
--substitutes any '=>' arguments for 'script-message'
--makes chaining script-messages much easier
function script_messages.chain(...)
    local command = table.pack('script-message', ...)
    for i, v in ipairs(command) do
        if v == '=>' then command[i] = 'script-message' end
    end
    mp.commandv(table.unpack(command))
end

--a helper script message for custom keybinds
--sends a command after the specified delay
function script_messages.delay_command(delay, ...)
    local command = table.pack(...)
    local success, err = pcall(mp.add_timeout, fb_utils.evaluate_string('return '..delay), function() mp.commandv(table.unpack(command)) end)
    if not success then return msg.error(err) end
end

--a helper script message for custom keybinds
--sends a command only if the given expression returns true
function script_messages.conditional_command(condition, ...)
    local command = table.pack(...)
    fb_utils.coroutine.run(function()
        if fb_utils.evaluate_string('return '..condition) == true then mp.commandv(table.unpack(command)) end
    end)
end

--a helper script message for custom keybinds
--extracts lua expressions from the command and evaluates them
--expressions must be surrounded by !{}. Another ! before the { will escape the evaluation
function script_messages.evaluate_expressions(...)
    local args = table.pack(...)
    fb_utils.coroutine.run(function()
        for i, arg in ipairs(args) do
            args[i] = arg:gsub('(!+)(%b{})', function(lead, expression)
                if #lead % 2 == 0 then return string.rep('!', #lead/2)..expression end

                local eval = fb_utils.evaluate_string('return '..expression:sub(2, -2))
                return type(eval) == "table" and utils.to_string(eval) or tostring(eval)
            end)
        end

        mp.commandv(table.unpack(args))
    end)
end

--a helper function for custom-keybinds
--concatenates the command arguments with newlines and runs the
--string as a statement of code
function script_messages.run_statement(...)
    local statement = table.concat(table.pack(...), '\n')
    fb_utils.coroutine.run(fb_utils.evaluate_string, statement)
end

return script_messages
