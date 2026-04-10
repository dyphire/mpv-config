local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = require 'modules.options'
local g = require 'modules.globals'
local fb_utils = require 'modules.utils'
local scanning = require 'modules.navigation.scanning'

---@class script_messages
local script_messages = {}

---Allows other scripts to request directory contents from file-browser.
---@param directory string
---@param response_str string
function script_messages.get_directory_contents(directory, response_str)
    ---@async
    fb_utils.coroutine.run(function()
        if not directory then msg.error("did not receive a directory string"); return end
        if not response_str then msg.error("did not receive a response string"); return end

        directory = mp.command_native({"expand-path", directory}, "") --[[@as string]]
        if directory ~= "" then directory = fb_utils.fix_path(directory, true) end
        msg.verbose(("recieved %q from 'get-directory-contents' script message - returning result to %q"):format(directory, response_str))

        directory = fb_utils.resolve_directory_mapping(directory)

        ---@class OptsWithVersion: Opts
        ---@field API_VERSION string?

        ---@type List|nil, OptsWithVersion|Opts|nil
        local list, opts = scanning.scan_directory(directory, { source = "script-message" } )
        if opts then opts.API_VERSION = g.API_VERSION end

        local list_str, err = fb_utils.format_json_safe(list)
        if not list_str then msg.error(err) end

        local opts_str, err2 = fb_utils.format_json_safe(opts)
        if not opts_str then msg.error(err2) end

        mp.commandv("script-message", response_str, list_str or "", opts_str or "")
    end)
end

---A helper script message for custom keybinds.
---Substitutes any '=>' arguments for 'script-message'.
---Makes chaining script-messages much easier.
---@param ... string
function script_messages.chain(...)
    ---@type string[]
    local command = table.pack('script-message', ...)
    for i, v in ipairs(command) do
        if v == '=>' then command[i] = 'script-message' end
    end
    mp.commandv(table.unpack(command))
end

---A helper script message for custom keybinds.
---Sends a command after the specified delay.
---@param delay string
---@param ... string
---@return nil
function script_messages.delay_command(delay, ...)
    local command = table.pack(...)
    local success, err = pcall(mp.add_timeout, fb_utils.evaluate_string('return '..delay), function() mp.commandv(table.unpack(command)) end)
    if not success then return msg.error(err) end
end

---A helper script message for custom keybinds.
---Sends a command only if the given expression returns true.
---@param condition string
---@param ... string
function script_messages.conditional_command(condition, ...)
    local command = table.pack(...)
    fb_utils.coroutine.run(function()
        if fb_utils.evaluate_string('return '..condition) == true then mp.commandv(table.unpack(command)) end
    end)
end

---A helper script message for custom keybinds.
---Extracts lua expressions from the command and evaluates them.
---Expressions must be surrounded by !{}. Another ! before the { will escape the evaluation.
---@param ... string
function script_messages.evaluate_expressions(...)
    ---@type string[]
    local args = table.pack(...)
    fb_utils.coroutine.run(function()
        for i, arg in ipairs(args) do
            args[i] = arg:gsub('(!+)(%b{})', function(lead, expression)
                if #lead % 2 == 0 then return string.rep('!', #lead/2)..expression end

                ---@type any
                local eval = fb_utils.evaluate_string('return '..expression:sub(2, -2))
                return type(eval) == "table" and utils.to_string(eval) or tostring(eval)
            end)
        end

        mp.commandv(table.unpack(args))
    end)
end

---A helper function for custom-keybinds.
---Concatenates the command arguments with newlines and runs the
---string as a statement of code.
---@param ... string
function script_messages.run_statement(...)
    local statement = table.concat(table.pack(...), '\n')
    fb_utils.coroutine.run(fb_utils.evaluate_string, statement)
end

return script_messages
