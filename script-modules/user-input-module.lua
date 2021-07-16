--[[
    This is a module designed to interface with mpv-user-input
    https://github.com/CogentRedTester/mpv-user-input

    Loading this script as a module will return a table with two functions to format
    requests to get and cancel user-input requests. See the README for details.

    Alternatively, developers can just paste these functions directly into their script,
    however this is not recommended as there is no guarantee that the formatting of
    these requests will remain the same for future versions of user-input.
]]

local mp = require 'mp'
local mod = {}

local name = mp.get_script_name()
local counter = 1

-- sends a request to ask the user for input using formatted options provided
-- creates a script message to recieve the response and call fn
function mod.get_user_input(fn, options)
    options = options or {}
    local response_string = name.."/__user_input_request/"..counter
    counter = counter + 1

    -- create a callback for user-input to respond to
    mp.register_script_message(response_string, function(input, err)
        mp.unregister_script_message(response_string)
        fn(err == "" and input or nil, err)
    end)

    -- send the input command
    mp.commandv("script-message-to", "user_input", "request-user-input",
        response_string,
        name .. '/' .. (options.id or ""),      -- id code for the request
        "["..(options.source or name).."] "..(options.request_text or options.text or ("requesting user input:")),
        options.default_input or "",
        options.queueable and "1" or "",
        options.replace and "1" or ""
    )
end

-- sends a request to cancel all input requests with the given id
function mod.cancel_user_input(id)
    id = name .. '/' .. (id or "")
    mp.commandv("script-message-to", "user_input", "cancel-user-input", id)
end

return mod