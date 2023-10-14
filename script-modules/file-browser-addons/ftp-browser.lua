--[[
    An addon for mpv-file-browser which adds support for ftp servers
]]--

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'
local fb = require 'file-browser'

local ftp = {
    priority = 100,
    version = "1.1.0"
}

function ftp:can_parse(directory)
    return directory:sub(1, 6) == "ftp://"
end

--in my experience curl has been somewhat unreliable when it comes to ftp requests
--this fuction retries the request a few times just in case
local function execute(args)
    msg.debug(utils.to_string(args))
    local _, cmd = fb.get_parse_state():yield(
        mp.command_native_async({
            name = "subprocess",
            playback_only = false,
            capture_stdout = true,
            capture_stderr = true,
            args = args
        }, fb.coroutine.callback())
    )
    return cmd
end

-- encodes special characters using the URL percent encoding format
function urlEncode(url)
    local domain, path = string.match(url, '(ftp://[^/]-/)(.*)')
    if not path then return url end

    -- these are the unreserved URI characters according to RFC 3986
    -- https://www.rfc-editor.org/rfc/rfc3986#section-2.3
    path = string.gsub(path, '[^%w.~_%-]', function(c)
        return ('%%%x'):format(string.byte(c))
    end)
    return domain..path
end

function ftp:parse(directory)
    msg.verbose(directory)

    local ftp = execute({"curl", "-k", "-g", "--retry", "4", urlEncode(directory)})

    local entries = execute({"curl", "-k", "-g", "-l", "--retry", "4", urlEncode(directory)})

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
