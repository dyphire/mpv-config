-- evafast.lua
--
-- Much speed.
--
-- Jumps forwards when right arrow is tapped, speeds up when it's held.
-- Inspired by bilibili.com's player. Allows you to have both seeking and fast-forwarding on the same key.
-- Also supports toggling fastforward mode with a keypress.
-- Adjust --input-ar-delay to define when to start fastforwarding.
-- Define --hr-seek if you want accurate seeking.
-- If you just want a nicer fastforward.lua without hybrid key behavior, set seek_distance to 0.
-- Consider setting --sub-filter-regex="\`\s*\'" (on Linux) to ignore empty lines.

local options = {
    -- How far to jump on press, set to 0 to disable seeking and force fastforward
    seek_distance = 5,

    -- Playback speed modifier, applied once every speed_interval until cap is reached
    speed_increase = 0.1,
    speed_decrease = 0.1,

    -- At what interval to apply speed modifiers
    speed_interval = 0.05,

    -- Playback speed cap
    speed_cap = 2,

    -- Playback speed cap when subtitles are displayed, ignored when equal to speed_cap
    subs_speed_cap = 1.6,

    -- Multiply current speed by modifier before adjustment (exponential speedup)
    -- Use much lower values than default e.g. speed_increase=0.05, speed_decrease=0.025
    multiply_modifier = false,

    -- Show current speed on the osd (or flash speed if using uosc)
    show_speed = true,

    -- Show current speed on the osd when toggled (or flash speed if using uosc)
    show_speed_toggled = true,

    -- Show current speed on the osd when speeding up towards a target time (or flash speed if using uosc)
    show_speed_target = false,

    -- Show seek actions on the osd (or flash timeline if using uosc)
    show_seek = true,

    -- Look ahead for smoother transition when subs_speed_cap is set
    subs_lookahead = true,

    -- Symbols prepended to the osd message
    osd_symbol = "{\\fnmpv-osd-symbols} {\\r}",
    osd_rewind = "{\\fnmpv-osd-symbols} {\\r}"
}

mp.options = require "mp.options"
mp.options.read_options(options, "evafast", function() end)

local uosc_available = false
local has_subtitle = true
local speedup_target = nil
local toggled_display = true
local toggled = false
local toggled_rewind = false
local speedup = false
local original_speed = 1
local next_sub_at = -1
local rewinding = false
local forced_slowdown = false
local file_duration = 0
local last_key_state = "up"
local was_rewinding = false

local ass_start = mp.get_property_osd("osd-ass-cc/0")
local ass_stop = mp.get_property_osd("osd-ass-cc/1")

local function speed_transition(current_speed, target_speed)
    local speed_correction = current_speed >= target_speed and -options.speed_decrease or options.speed_increase

    local time_for_correction = 0
    local adjusted_speed = current_speed

    while adjusted_speed ~= target_speed do
        time_for_correction = time_for_correction + options.speed_interval * adjusted_speed

        if options.multiply_modifier then
            adjusted_speed = adjusted_speed + adjusted_speed * speed_correction
        else
            adjusted_speed = adjusted_speed + speed_correction
        end

        if (current_speed < target_speed and adjusted_speed > target_speed) or (current_speed > target_speed and adjusted_speed < target_speed) then
            adjusted_speed = target_speed
        end
    end

    return time_for_correction
end

local function next_sub(current_time)
    local sub_delay = mp.get_property_native("sub-delay", 0)
    local sub_visible = mp.get_property_bool("sub-visibility")

    if sub_visible then
        mp.set_property_bool("sub-visibility", false)
    end

    mp.command("no-osd sub-step 1")

    local sub_next_delay = mp.get_property_native("sub-delay", 0)
    mp.set_property("sub-delay", sub_delay)

    if sub_visible then
        mp.set_property_bool("sub-visibility", sub_visible)
    end

    if sub_delay - sub_next_delay == 0 then
        return -2
    end

    local sub_next = current_time + sub_delay - sub_next_delay

    normalized = math.floor(sub_next * 1000 + 0.5) / 1000
    return normalized
end

local function flash_state(current_speed, display, forced)
    local uosc_show = uosc_available and (display == nil or display == "uosc")
    local osd_show = not uosc_available and (display == nil or display == "osd")

    local show_special = (not speedup_target and options.show_speed_toggled) or (speedup_target and options.show_speed_target)
    local show_toggled = show_special and (toggled or not speedup)
    local show_regular = not toggled and toggled_display and options.show_speed

    if current_speed and (show_regular or show_toggled or forced) then
        if uosc_show then
            mp.command("script-binding uosc/flash-speed")
        elseif osd_show then
            if current_speed == true then
                current_speed = mp.get_property_number("speed", 1)
            end
            mp.osd_message(ass_start .. (was_rewinding and options.osd_rewind or options.osd_symbol) .. ass_stop .. string.format("x%.1f", current_speed))
        end
    elseif not current_speed and options.show_seek then
        if uosc_show then
            mp.command("script-binding uosc/flash-timeline")
        elseif osd_show then
            mp.osd_message(ass_start .. (was_rewinding and options.osd_rewind or options.osd_symbol))
        end
    end
end

local function ensure_timer(reset)
    if not reset and speed_timer:is_enabled() then return end

    speed_timer.timeout = 0
    speed_timer:resume()
    speed_timer.timeout = options.speed_interval
end

local function evafast_speedup(toggle)
    if not toggled and not speedup_target and not speed_timer:is_enabled() then
        original_speed = mp.get_property_number("speed", 1)
    end

    speedup = true

    if toggle then
        toggled = true
    end

    ensure_timer()
end

local function evafast_slowdown(display)
    forced_slowdown = false
    if not display then
        toggled_display = false
    end
    toggled = false
    speedup = false

    ensure_timer()
end

local function evafast_toggle()
    if toggled_rewind then
        mp.set_property("play-dir", "+")
    end
    toggled_rewind = false
    if speedup then
        evafast_slowdown()
    else
        evafast_speedup(true)
    end
end

local function evafast_toggle_rewind()
    rewinding = not speedup
    mp.set_property("play-dir", rewinding and "-" or "+")
    evafast_toggle()
    toggled_rewind = rewinding
end

local function adjust_speed()
    local current_time = mp.get_property_number("time-pos", 0)
    local current_speed = mp.get_property_number("speed", 1)
    local target_speed = original_speed

    if speedup then
        target_speed = options.speed_cap

        if has_subtitle and target_speed ~= options.subs_speed_cap then
            local sub_displayed = mp.get_property("sub-start") ~= nil

            if sub_displayed then
                target_speed = options.subs_speed_cap
            elseif options.subs_lookahead then
                if next_sub_at < current_time and next_sub_at ~= -2 then
                    next_sub_at = next_sub(current_time)
                end
                if target_speed ~= options.subs_speed_cap and next_sub_at > current_time then
                    local time_for_correction = speed_transition(options.speed_cap, options.subs_speed_cap)
                    if current_time + time_for_correction >= next_sub_at then
                        target_speed = options.subs_speed_cap
                    end
                end
            end
        end

        if speedup_target ~= nil then
            local effective_speedup_target = speedup_target >= 0 and speedup_target or (file_duration + speedup_target)

            if current_time >= effective_speedup_target then
                evafast_slowdown()
            else
                local time_for_correction = speed_transition(current_speed, original_speed)
                if current_time + time_for_correction > effective_speedup_target or forced_slowdown then
                    forced_slowdown = true
                    speedup = false
                    target_speed = original_speed
                end
            end
        end
    end

    if math.floor(target_speed * 1000 + 0.5) == math.floor(current_speed * 1000 + 0.5) then
        if forced_slowdown or (not toggled and (not speedup or options.subs_speed_cap == options.speed_cap or (not has_subtitle and not speedup_target))) then
            speed_timer:kill()
            toggled_display = true
            if speedup_target ~= nil then
                evafast_slowdown()
            end
            speedup_target = nil
        end
        return
    end

    local new_speed = current_speed
    local speed_correction = 0

    if options.multiply_modifier then
        speed_correction = current_speed * options.speed_increase
    else
        speed_correction = options.speed_increase
    end

    if current_speed > target_speed then
        new_speed = math.max(current_speed - speed_correction, target_speed)
    else
        new_speed = math.min(current_speed + speed_correction, target_speed)
    end

    mp.set_property("speed", new_speed)

    flash_state(new_speed)
end

speed_timer = mp.add_periodic_timer(100, adjust_speed)
speed_timer:kill()

local function evafast(keypress, rewind)
    was_rewinding = false
    if rewinding and not toggled_rewind and (not rewind or (keypress["event"] == "up" and last_key_state ~= "down")) then
        rewinding = false
        was_rewinding = true
        mp.set_property("play-dir", "+")
    end
    if rewind then
        was_rewinding = true
    end

    if keypress["event"] == "down" then
        if not speed_timer:is_enabled() then
            if not toggled and not speedup_target then
                original_speed = mp.get_property_number("speed", 1)
            end
            flash_state(nil, "osd")
            flash_state(1, "uosc", true)
        end
        toggled_display = true
        speed_timer:stop()
        if options.seek_distance == 0 then
            keypress["event"] = "repeat"
        end
    end

    if keypress["event"] == "press" or keypress["event"] == "up" and last_key_state ~= "repeat" then
        if not toggled and not speedup_target then
            speed_timer:kill()
            mp.set_property("speed", original_speed)
        end
        flash_state()
        ensure_timer()
        if rewind then
            if not toggled_rewind then
                rewinding = false
                mp.set_property("play-dir", "+") -- unnecessary in some cases
            end
            mp.commandv("seek", -options.seek_distance)
        else
            mp.commandv("seek", options.seek_distance)
        end
    elseif keypress["event"] == "repeat" and last_key_state ~= "repeat" then
        speedup = true
        ensure_timer()
        if rewind then
            mp.set_property("play-dir", "-")
            rewinding = true
        end
    elseif keypress["event"] == "up" and not toggled and not speedup_target then
        evafast_slowdown(true)
        ensure_timer(true)
    end

    last_key_state = keypress["event"]
end

local function evafast_rewind(keypress)
    evafast(keypress, true)
end

mp.observe_property("duration", "native", function(prop, val)
    file_duration = val or 0
end)

mp.observe_property("sid", "native", function(prop, val)
    has_subtitle = (val or 0) ~= 0
    next_sub_at = -1
end)

mp.observe_property("sub-start", "native", function(prop, val)
    next_sub_at = -1
end)

mp.register_event("file-loaded", function()
    next_sub_at = -1
end)

mp.register_event("seek", function()
    next_sub_at = -1
end)

mp.register_script_message("uosc-version", function(version)
    uosc_available = true
end)

mp.register_script_message("speedup-target", function(time)
    local current_time = mp.get_property_number("time-pos", 0)
    sign = string.sub(time, 1, 1)
    time = tonumber(time) or 0

    if sign == "+" then
        time = current_time + time
    end

    if current_time >= time and time >= 0 then
        speedup_target = nil
        evafast_slowdown()
        return
    end
    speedup_target = time
    evafast_speedup()
end)

mp.register_script_message("get-version", function(script)
    mp.commandv("script-message-to", script, "evafast-version", "2.0")
end)

mp.add_key_binding("RIGHT", "evafast", evafast, {repeatable = true, complex = true})
mp.add_key_binding(nil, "evafast-rewind", evafast_rewind, {repeatable = true, complex = true})
mp.add_key_binding(nil, "flash-speed", function() flash_state(true, nil, true) end)
mp.add_key_binding(nil, "speedup", evafast_speedup)
mp.add_key_binding(nil, "slowdown", evafast_slowdown)
mp.add_key_binding(nil, "toggle", evafast_toggle)
mp.add_key_binding(nil, "toggle-rewind", evafast_toggle_rewind)

mp.commandv("script-message-to", "uosc", "get-version", mp.get_script_name())
