--[[
    This is a module designed to interface with mpv-user-input
    https://github.com/CogentRedTester/mpv-user-input

    Loading this script as a module will return a table with two functions to format
    requests to get and cancel user-input requests. See the README for details.

    Alternatively, developers can just paste these functions directly into their script,
    however this is not recommended as there is no guarantee that the formatting of
    these requests will remain the same for future versions of user-input.
]]

local API_VERSION = "0.1.0"

local mp = require 'mp'
local msg = require "mp.msg"
local utils = require 'mp.utils'
local mod = {}

local name = mp.get_script_name()
local counter = 1

local function pack(...)
    local t = {...}
    t.n = select("#", ...)
    return t
end

local request_mt = {}

-- ensures the option tables are correctly formatted based on the input
local function format_options(options, response_string)
    return {
        response = response_string,
        version = API_VERSION,
        id = name..'/'..(options.id or ""),
        source = name,
        request_text = ("[%s] %s"):format(options.source or name, options.request_text or options.text or "requesting user input:"),
        default_input = options.default_input,
        cursor_pos = options.cursor_pos,
        queueable = options.queueable and true,
        replace = options.replace and true
    }
end

-- cancels the request
function request_mt:cancel()
    assert(self.uid, "request object missing UID")
    mp.commandv("script-message-to", "user_input", "cancel-user-input/uid", self.uid)
end

-- updates the options for the request
function request_mt:update(options)
    assert(self.uid, "request object missing UID")
    options = utils.format_json( format_options(options) )
    mp.commandv("script-message-to", "user_input", "update-user-input/uid", self.uid, options)
end

-- sends a request to ask the user for input using formatted options provided
-- creates a script message to recieve the response and call fn
function mod.get_user_input(fn, options, ...)
    options = options or {}
    local response_string = name.."/__user_input_request/"..counter
    counter = counter + 1

    local request = {
        uid = response_string,
        passthrough_args = pack(...),
        callback = fn,
        pending = true
    }

    -- create a callback for user-input to respond to
    mp.register_script_message(response_string, function(response)
        mp.unregister_script_message(response_string)
        request.pending = false

        response = utils.parse_json(response)
        request.callback(response.line, response.err, unpack(request.passthrough_args, 1, request.passthrough_args.n))
    end)

    -- send the input command
    options = utils.format_json( format_options(options, response_string) )
    mp.commandv("script-message-to", "user_input", "request-user-input", options)

    return setmetatable(request, { __index = request_mt })
end

-- runs the request synchronously using coroutines
-- takes the option table and an optional coroutine resume function
function mod.get_user_input_co(options, co_resume)
    local co, main = coroutine.running()
    assert(not main and co, "get_user_input_co must be run from within a coroutine")

    local uid = {}
    local request = mod.get_user_input(function(line, err)
        if co_resume then
            co_resume(uid, line, err)
        else
            local success, er = coroutine.resume(co, uid, line, err)
            if not success then
                msg.warn(debug.traceback(co))
                msg.error(er)
            end
        end
    end, options)

    -- if the uid was not sent then the coroutine was resumed by the user.
    -- we will treat this as a cancellation request
    local success, line, err = coroutine.yield(request)
    if success ~= uid then
        request:cancel()
        request.callback = function() end
        return nil, "cancelled"
    end

    return line, err
end

-- sends a request to cancel all input requests with the given id
function mod.cancel_user_input(id)
    id = name .. '/' .. (id or "")
    mp.commandv("script-message-to", "user_input", "cancel-user-input/id", id)
end

return mod