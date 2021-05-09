--[[
    An addon for mpv-file-browser which adds support for ftp servers
]]--

local mp = require 'mp'
local msg = require 'mp.msg'

local ftp = {
    priority = 100
}

function ftp:can_parse(directory)
    return directory:sub(1, 6) == "ftp://"
end

--in my experience curl has been somewhat unreliable when it comes to ftp requests
--this fuction retries the request a few times just in case
local function execute(args)
    local req = {status = 28}
    local attempts = 0
    req = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = args
    })
    attempts = attempts + 1
    return req
end

function ftp:parse(directory)
    msg.verbose(directory)
    msg.debug("curl -k -g "..string.format("%q", directory))

    local ftp = execute({"curl", "-k", "-g", "--retry", "4", directory})

    local entries = execute({"curl", "-k", "-g", "-l", "--retry", "4", directory})

    if entries.status == 28 then
        msg.error(entries.stderr)
    elseif entries.status ~= 0 or ftp.status ~= 0 then
        msg.error(entries.stderr)
        return
    end

    local response = {}
    for str in string.gmatch(ftp.stdout, "[^\r\n]+") do
        table.insert(response, str)
    end

    local list = {}
    local i = 1
    for str in string.gmatch(entries.stdout, "[^\r\n]+") do
        if str and response[i] then
            msg.trace(str .. ' | ' .. response[i])

            if response[i]:sub(1,1) == "d" then
                table.insert(list, { name = str..'/', type = "dir" })
            else
                table.insert(list, { name = str, type = "file" })
            end

            i = i+1
        end
    end

    return list
end

return ftp
