local opt = require('mp.options')
local options = {
    bind = 'SPACE',
    action = 'set speed 3; set pause no',
    invert = 'set speed 1',
    duration = 200
}
opt.read_options(options)

local pressed = false
local keydown_at = 0

local original = 'ignore'
for i, v in ipairs(mp.get_property_native('input-bindings')) do
    if v.key == options.bind then
        original = v.cmd
    end
end

function now()
    return mp.get_time() * 1000
end

function command(command)
    return mp.command(command .. '; show-text ""')
end

function keydown(key_name, key_text, is_mouse)
    keydown_at = now()
end

function keyup(key_name, key_text, is_mouse)
    if pressed then
        command(options.invert)
    else
        command(original)
    end

    pressed = false
    keydown_at = 0
end

function keypress(key_name, key_text, is_mouse)
end

function keyrepeat(key_name, key_text, is_mouse)
    local trigger = now() - keydown_at > options.duration
    if not pressed and trigger then
        pressed = true
        command(options.action)
    end
end

function event_handler(event, is_mouse, key_name, key_text)
    if event == 'down' then
        keydown(key_name, key_text, is_mouse)
    elseif event == 'up' then
        keyup(key_name, key_text, is_mouse)
    elseif event == 'press' then
        keypress(key_name, key_text, is_mouse)
    elseif event == 'repeat' then
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
