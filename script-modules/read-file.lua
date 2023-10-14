--[[
    An API script for reading the contents of text files over a variety of protocols
    Available at: https://github.com/CogentRedTester/mpv-read-file
]]--

local mp = require "mp"
local msg = require "mp.msg"
local utils = require "mp.utils"
local opts = require "mp.options"

local o = {
    wget_opts = ""
}

opts.read_options(o, "read_file")

local rf = {}
local temp_files = {}

--this platform test was taken from mpv's console.lua
local PLATFORM_WINDOWS = mp.get_property_native('options/vo-mmcss-profile', o) ~= o

local function async_callback(args, callback, success, cmd, error)
    if not success then return callback( nil, error ) end

    if (cmd.status == 0) then
        return callback( cmd.stdout )
    else
        local err = table.concat(args, ' ')..'\n'
            .."command exitted with status code: "..cmd.status..'\n'
            ..cmd.stderr

        return callback( nil, err )
    end
end

local function execute(args, callback)
    msg.debug("executing command:", table.concat(args, " "))
    local mpv_command = {
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = args
    }

    local cmd
    if callback then
        cmd = mp.command_native_async(mpv_command, function(...) async_callback(args, callback, ...) end)
        return cmd
    else
        cmd = mp.command_native(mpv_command)
    end

    if (cmd.status == 0) then
        return cmd.stdout
    else
        local err = table.concat(args, ' ')..'\n'
            .."command exitted with status code: "..cmd.status..'\n'
            ..cmd.stderr

        return nil, err
    end
end

--gets the path of a temporary file that can be used by the script
local function get_temp_file_name()
    local file = os.tmpname():gsub('^\\', '')
    if not PLATFORM_WINDOWS then return file
    else return utils.join_path(os.getenv("TEMP"), file) end
end

--creates a new temporary file with the given contents, and returns a file read handle for this file
local function get_temp_file_handler(contents)
    local filename = get_temp_file_name()
    table.insert(temp_files, filename)

    local tmpfile = io.open(filename, "w")
    assert(tmpfile, 'failed to open '..filename..' for writing')
    tmpfile:write(contents)
    tmpfile:close()

    return io.open(filename, "r")
end

--gets the protocol scheme for the given uri
--if there is no scheme then return nil
local function get_protocol(uri)
    return uri:match("^(%a%w*)://")
end

--returns a file handle for the given file
local function get_local(file)
    return io.open(file, "r")
end

--gets a file using the wget commandline utility
--retrieves the result as a string
local function get_wget(file)
    local args = {"wget", "-O", "-", file}
    for arg in o.wget_opts:gmatch("%S+") do
        table.insert(args, arg)
    end
    return execute(args)
end

--tracks what functions should be used for specific protocols
local protocols = {
    file = get_local,
    http = get_wget,
    https = get_wget,
}

--uses the protocol of the file uri to determine what get function to run, and converts the result into
--either a string or a file handle, depending on the second argument. If as_string is nil then return whichever
--type the get function defaults to
local function get_file(file, as_string)
    local path = file
    local protocol = get_protocol(file)
    local get_method = nil

    --determines what utility to use to read the file
    if not protocol then
        path = utils.join_path(mp.get_property("working-directory", ""), file)
        get_method = get_local
    else
        get_method = protocols[protocol] or get_wget
    end

    local contents, err = get_method(path)
    if not contents or as_string == nil then return contents, err end

    --converts the result of the get function into the correct output type - either a string or a file handle
    if as_string and io.type(contents) then
        local tmp = contents
        contents = tmp:read("*a")
        tmp:close()
    elseif not as_string and not io.type(contents) then
        contents = get_temp_file_handler(contents)
    end

    return contents, err
end

--returns a file handler for the given file
function rf.get_file_handler(file)
    return get_file(file, false)
end

--reads the contents of the file to a string and returns the result
--if the file could not be read then return nil
function rf.read_file(file)
    return get_file(file, true)
end

--returns an iterator for the lines in the file
--if the return value is a file handle then close the file once EOF is reached, like when using io.lines()
--if the return value is a string then return a string.gmatch iterator for each line
function rf.lines(file)
    local contents, err = get_file(file)
    if not contents then
        msg.error(err)
        return function() return nil end
    end

    if type(contents) == "string" then
        return string.gmatch(contents, "[^\n\r]+")
    else
        return function()
            local line = contents:read("*l")
            if not line then contents:close() end
            return line
        end
    end
end

execute({"wget", "-V"}, function(result) assert(result, "wget not available in the system PATH") end)

--removes all temporary files created by this script
mp.register_event("shutdown", function()
    for _, file in ipairs(temp_files) do
        msg.trace("removing temporary file", file)
        os.remove(file)
    end
end)

return rf