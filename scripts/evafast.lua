-- evafast.lua
--
-- Much speed.
--
-- Jumps forwards when right arrow is pressed, speeds up when it's held.
-- Inspired by bilibili.com's player. Allows you to have both seeking and fast-forwarding on the same key.
-- Also supports toggling fastforward mode with a keypress.
-- Adjust --input-ar-delay to define when to start fastforwarding.
-- Define --hr-seek if you want accurate seeking.
-- If you just want a nicer fastforward.lua without hybrid key behavior, set seek_distance to 0.

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

    -- Playback speed cap when subtitles are displayed, 'no' for same as speed_cap
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
    lookahead = false
}

mp.options = require "mp.options"
mp.options.read_options(options, "evafast")

local uosc_available = false
local repeated = false
local speed_timer = nil
local speedup = true
local no_speedup = false
local jumps_reset_speed = true
local toggle_display = false
local toggle_state = false
local freeze = false

local forced_speed_cap = nil
local use_forced_speed_cap = false

local speedup_target = nil

local function speed_transition(test_speed, target)
    local time_for_correction = 0
    if not freeze then
        while test_speed ~= target do
            time_for_correction = time_for_correction + options.speed_interval
            if test_speed <= target then
                if options.multiply_modifier then
                    test_speed = math.min(test_speed + (test_speed * options.speed_increase), target)
                else
                    test_speed = math.min(test_speed + options.speed_increase, target)
                end
            else
                if options.multiply_modifier then
                    test_speed = math.max(test_speed - (test_speed * options.speed_decrease), 1)
                else
                    test_speed = math.max(test_speed - options.speed_decrease, 1)
                end
            end
            if test_speed == 1 then break end
        end
    end
    return time_for_correction
end

local function adjust_speed()
    local no_sub_speed = not options.subs_speed_cap or mp.get_property("sub-start") == nil
    local effective_speed_cap = no_sub_speed and options.speed_cap or options.subs_speed_cap
    local speed = mp.get_property_number("speed", 1)
    local old_speed = speed

    if options.lookahead and options.subs_speed_cap and no_sub_speed and not use_forced_speed_cap then
        local sub_delay = mp.get_property_native("sub-delay")
        local sub_visible = mp.get_property_bool("sub-visibility")
        if sub_visible then
            mp.set_property_bool("sub-visibility", false)
        end
        mp.command("no-osd sub-step 1")
        local sub_next_delay = mp.get_property_native("sub-delay")
        local sub_next = sub_delay - sub_next_delay
        mp.set_property("sub-delay", sub_delay)
        if sub_visible then
            mp.set_property_bool("sub-visibility", sub_visible)
        end
        -- calculate how long it takes to get from current speed to target speed, and use that as threshold for sub_next
        local time_for_correction = speed_transition(speed, options.subs_speed_cap)
        if sub_next ~= 0 and sub_next <= (time_for_correction * speed) then
            effective_speed_cap = options.subs_speed_cap
            use_forced_speed_cap = true
            forced_speed_cap = effective_speed_cap
        end
    end

    if speedup_target ~= nil then
        local current_time = mp.get_property_number("time-pos", 0)
        if current_time >= speedup_target then
            jumps_reset_speed = true
            no_speedup = true
            repeated = false
            freeze = false
        else
            local time_for_correction = speed_transition(speed, math.max(math.min(options.speed_cap, options.subs_speed_cap and options.subs_speed_cap or options.speed_cap), 1.1)) -- not effective_speed_cap because it may lead to huge fluctuations in transition speed
            if (time_for_correction * speed + current_time) > speedup_target then
                effective_speed_cap = 1.1 -- >1 so we don't get stuck trying to catch the target
                use_forced_speed_cap = true
                forced_speed_cap = effective_speed_cap
            else
                forced_speed_cap = nil
                use_forced_speed_cap = false
            end
        end
    end

    if not freeze then
        if forced_speed_cap ~= nil then
            if speed ~= forced_speed_cap or mp.get_property_bool("pause") then
                use_forced_speed_cap = true
            end
            effective_speed_cap = forced_speed_cap
        end
        if speedup and not no_speedup and speed <= effective_speed_cap then
            if options.multiply_modifier then
                speed = math.min(speed + (speed * options.speed_increase), effective_speed_cap)
            else
                speed = math.min(speed + options.speed_increase, effective_speed_cap)
            end
        else
            if options.multiply_modifier then
                speed = math.max(speed - (speed * options.speed_decrease), 1)
            else
                speed = math.max(speed - options.speed_decrease, 1)
            end
        end
        if forced_speed_cap ~= nil and not use_forced_speed_cap then
            forced_speed_cap = nil
        end
        if speed == options.subs_speed_cap then
            if use_forced_speed_cap then
                use_forced_speed_cap = false
            end
        end
    end

    if speed ~= old_speed then
        mp.set_property("speed", speed)
        if (options.show_speed and not toggle_display) or (options.show_speed_toggled and toggle_display and speedup_target == nil) or (options.show_speed_target and speedup_target ~= nil) then
            if uosc_available then
                mp.command("script-binding uosc/flash-speed")
            else
                mp.osd_message(("▶▶ x%.1f"):format(speed))
            end
        end
    end

    if speed == 1 and effective_speed_cap ~= 1 then
        if speed_timer ~= nil and not toggle_state then
            speed_timer:kill()
            speed_timer = nil
        end
        repeated = false
        jumps_reset_speed = true
        toggle_display = false
        toggle_state = false
        speedup_target = nil
    elseif speed_timer == nil then
        speed_timer = mp.add_periodic_timer(options.speed_interval, adjust_speed)
    end
end

local function evafast(keypress)
    if jumps_reset_speed and not toggle_state and (keypress["event"] == "up" or keypress["event"] == "press") then
        speedup = false
        speedup_target = nil
    end

    if options.seek_distance == 0 then
        if keypress["event"] == "up" or keypress["event"] == "press" then
            speedup = false
            no_speedup = true
            repeated = false
            speedup_target = nil
        end
        if keypress["event"] == "down" then
            keypress["event"] = "repeat"
        end
    end

    if keypress["event"] == "up" or keypress["event"] == "press" then
        toggle_display = toggle_state
        if toggle_state and jumps_reset_speed then
            speedup = false
            speedup_target = nil
        end
        if speed_timer ~= nil and not toggle_state and mp.get_property_number("speed") == 1 and ((not options.subs_speed_cap or mp.get_property("sub-start") == nil) and options.speed_cap or options.subs_speed_cap) ~= 1 then
            speed_timer:kill()
            speed_timer = nil
            jumps_reset_speed = true
            toggle_display = false
            toggle_state = false
            speedup_target = nil
        end
        freeze = false
    end

    if keypress["event"] == "down" then
        repeated = false
        speedup = true
        freeze = true
        toggle_display = false
        if options.show_seek and not repeated and not uosc_available then
            mp.osd_message("▶▶")
        end
    elseif (keypress["event"] == "up" and (not repeated or speedup_target)) or keypress["event"] == "press" then
        if options.seek_distance ~= 0 then
            mp.commandv("seek", options.seek_distance)
            if options.show_seek and uosc_available then
                mp.command("script-binding uosc/flash-timeline")
            end
        end
        repeated = false
        if jumps_reset_speed and not toggle_state then
            no_speedup = true
        end
    elseif keypress["event"] == "repeat" then
        freeze = false
        speedup = true
        no_speedup = false
        if not repeated then
            adjust_speed()
        end
        repeated = true
    end
end

local function evafast_speedup()
    no_speedup = false
    speedup = true
    jumps_reset_speed = false
    toggle_display = true
    toggle_state = true
    evafast({event = "repeat"})
end

local function evafast_slowdown()
    jumps_reset_speed = true
    no_speedup = true
    repeated = false
    freeze = false
    speedup_target = nil
end

local function evafast_toggle()
    if (repeated or not jumps_reset_speed) and speedup then
        evafast_slowdown()
    else
        evafast_speedup()
    end
end

mp.register_script_message("uosc-version", function(version)
    uosc_available = true
end)

mp.register_script_message("speedup-target", function(time)
    time = tonumber(time) or 0
    if mp.get_property_number("time-pos", 0) >= time then
        if speedup_target ~= nil then
            use_forced_speed_cap = false
            forced_speed_cap = nil
            speedup_target = nil
            evafast_slowdown()
        end
        return
    end
    speedup_target = time
    evafast_speedup()
end)

mp.register_script_message("get-version", function(script)
    mp.commandv("script-message-to", script, "evafast-version", "1.0")
end)

mp.add_key_binding("RIGHT", "evafast", evafast, {repeatable = true, complex = true})
mp.add_key_binding(nil, "speedup", evafast_speedup)
mp.add_key_binding(nil, "slowdown", evafast_slowdown)
mp.add_key_binding(nil, "toggle", evafast_toggle)

mp.commandv("script-message-to", "uosc", "get-version", mp.get_script_name())
