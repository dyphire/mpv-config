local opt = require("mp.options")
local options = {
    bind = "SPACE",
    action = "no-osd set speed 4; set pause no",
    invert = "",
    duration = 200
}
opt.read_options(options)

local pressed = false
local keydown_at = 0
local original = ""
local invert = ""

-- https://mpv.io/manual/master/#input-command-prefixes
local prefixes = {"osd-auto", "no-osd", "osd-bar", "osd-msg", "osd-msg-bar", "raw", "expand-properties", "repeatable",
                  "async", "sync"}

-- https://mpv.io/manual/master/#list-of-input-commands
local commands = {"set", "cycle", "add", "multiply"}

function table:has(element)
    for _, value in ipairs(self) do
        if value == element then
            return true
        end
    end
    return false
end

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c)
        fields[#fields + 1] = c
    end)
    return fields
end

function string:trim()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end

function now()
    return mp.get_time() * 1000
end

function command(command)
    return mp.command(command)
end

function get_key_binding(key)
    for _, v in ipairs(mp.get_property_native("input-bindings")) do
        if v.key == key then
            return v.cmd
        end
    end
    return "ignore"
end

function get_invert(action)
    if options.invert ~= "" then
        return options.invert
    end

    local invert = ""
    local action = action:split(";")
    for i, v in ipairs(action) do
        local subs = v:trim():split("%s*")
        local prefix = table.has(prefixes, subs[1]) and subs[1] or ""
        local command = subs[prefix == "" and 1 or 2]
        local property = subs[prefix == "" and 2 or 3]
        local value = mp.get_property(property)
        local semi = i == #action and "" or ";"

        if table.has(commands, command) then
            invert = invert .. prefix .. " " .. "set" .. " " .. property .. " " .. value .. semi
        else
            mp.msg.error(v:trim() .. "' doesn't support auto restore, please set 'options.invert' manually")
        end
    end
    return invert
end

function keydown(key_name, key_text, is_mouse)
    keydown_at = now()
    original = get_key_binding(options.bind)
    invert = get_invert(options.action)
end

function keyup(key_name, key_text, is_mouse)
    command(pressed and invert or original)
    pressed = false
    keydown_at = 0
end

function keypress(key_name, key_text, is_mouse)
end

function keyrepeat(key_name, key_text, is_mouse)
    if pressed then
        return
    end

    if now() - keydown_at < options.duration then
        return
    end

    pressed = true
    command(options.action)
end

function event_handler(event, is_mouse, key_name, key_text)
    if event == "down" then
        keydown(key_name, key_text, is_mouse)
    elseif event == "up" then
        keyup(key_name, key_text, is_mouse)
    elseif event == "press" then
        keypress(key_name, key_text, is_mouse)
    elseif event == "repeat" then
        keyrepeat(key_name, key_text, is_mouse)
    else
        print(event, key_name, key_text, is_mouse)
    end
end

mp.add_forced_key_binding(options.bind, nil, function(e)
    event_handler(e.event, e.is_mouse, e.key_name, e.key_text)
end, {
    complex = true
})
