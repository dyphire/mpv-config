--[[
    An addon for mpv-file-browser which adds support for apache http directory indexes
]]--

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'
local fb = require "file-browser"

--decodes a URL address
--this piece of code was taken from: https://stackoverflow.com/questions/20405985/lua-decodeuri-luvit/20406960#20406960
local decodeURI
do
    local char, gsub, tonumber = string.char, string.gsub, tonumber
    local function _(hex) return char(tonumber(hex, 16)) end

    function decodeURI(s)
        s = gsub(s, '%%(%x%x)', _)
        return s
    end
end

local apache = {
    priority = 80,
    version = "1.1.0"
}

function apache:can_parse(name)
    return name:find("^https?://")
end

--send curl errors through the browser empty_text
function apache:send_error(str)
    return {}, {empty_text = "curl error: "..str}
end

local function execute(args)
    msg.trace(utils.to_string(args))
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

function apache:parse(directory)
    msg.verbose(directory)

    local test = execute({"curl", "-k", "-l", "-I", directory})
    local response = test.stdout:match("(%d%d%d [^\n\r]+)")
    if test.stdout:match("Content%-Type: ([^\r\n/]+)") ~= "text" then return nil end
    if response ~= "200 OK" then return self:send_error(response) end

    local html = execute({"curl", "-k", "-l", directory})
    if html.status ~= 0 then return self:send_error(tostring(html.status))
    elseif not html.stdout:find("%[PARENTDIR%]") then return nil end

    html = html.stdout
    local list = {}
    for str in string.gmatch(html, "[^\r\n]+") do
        local valid = true
        if str:sub(1,4) ~= "<tr>" then valid = false end

        local link = str:match('href="(.-)"')
        local alt = str:match('alt="%[(.-)%]"')

        if valid and not alt or not link then valid = false end
        if valid and alt == "PARENTDIR" or alt == "ICO" then valid = false end
        if valid and link:find("[:?<>|]") then valid = false end

        local is_dir = (alt == "DIR")
        if valid and is_dir and not self.valid_dir(link) then valid = false end
        if valid and not is_dir and not self.valid_file(link) then valid = false end

        if valid then
            msg.trace(alt..": "..link)
            table.insert(list, { name = link, type = (is_dir and "dir" or "file"), label = decodeURI(link) })
        end
    end

    return list, {filtered = true, directory_label = decodeURI(directory)}
end

return apache
