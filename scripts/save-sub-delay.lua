-- This script saves the sub-delay quantity for each file.
-- When next time the file is opened, sub-delay is automatically restored.
-- Using `--sub-delay=<sec>` or `x` and `z` key-bindings both work.
-- But keep in mind that this script distinguishes different files by reading
-- their 'path' properties. If you use in command line:
--     `mpv --sub-delay=0.1 example.mkv`
-- this delay value won't be applied to the same file you open by
-- double-clicking it.

local mputils = require "mp.utils"

local JSON = (os.getenv('APPDATA') or os.getenv('HOME')..'/.config')..'/mpv/mpv_sub-delay.json'
local jsonFile = io.open(JSON, 'a+')
local sub_delay_table = mputils.parse_json(jsonFile:read("*all"))
jsonFile:close()

function read_sub_delay()
    local sub_delay = mp.get_property_native("sub-delay")
    local path = mp.get_property_native("path")
    if sub_delay_table == nil then
        sub_delay_table = {}
    end
    if sub_delay == 0 then
        if sub_delay_table[path] ~= nil then
            sub_delay = sub_delay_table[path]
            if sub_delay > 0.000999 or sub_delay < -0.000999 then
                mp.command("add sub-delay " .. sub_delay)
            end
        end
    else
        sub_delay_table[path] = sub_delay
        write_sub_delay()
    end
end

function write_sub_delay()
    local jsonFile = io.open(JSON, 'w+')
    local path = mp.get_property_native("path")
    sub_delay_table[path] = mp.get_property_native("sub-delay")
    local jsonContent, ret = mputils.format_json(sub_delay_table)
    if ret ~= error and jsonContent ~= nil then
        jsonFile:write(jsonContent)
    end
    jsonFile:close()
end

function sub_delay_pos()
    mp.command("add sub-delay 0.1")
    write_sub_delay()
end

function sub_delay_neg()
    mp.command("add sub-delay -0.1")
    write_sub_delay()
end

mp.register_event("file-loaded", read_sub_delay)

mp.add_key_binding("x", "sub-delay+", sub_delay_pos)
mp.add_key_binding("z", "sub-delay-", sub_delay_neg)