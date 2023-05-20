-- Runs write-watch-later-config periodically

local options = require 'mp.options'
local o = { save_interval = 60 }
options.read_options(o)

local can_delete = true

local function save()
    local demuxer_secs = mp.get_property("demuxer-hysteresis-secs")
    local watch_later_list = mp.get_property("watch-later-options", {})
    if mp.get_property_bool("save-position-on-quit") then
        if demuxer_secs and watch_later_list:find("start") == nil then
            mp.commandv("change-list", "watch-later-options", "append", "start")
        end
        mp.command("write-watch-later-config")
    end
end

local function save_if_pause(_, pause)
    if pause then save() end
end

local function pause_timer_while_paused(_, pause)
    if pause then timer:stop() else timer:resume() end
end

-- This function runs on file-loaded, registers two callback functions, and
-- then they run delete-watch-later-config when appropriate.
local function delete_watch_later(event)
    local path = mp.get_property("path")
    local demuxer_secs = mp.get_property("demuxer-hysteresis-secs")

    -- Temporarily disables save-position-on-quit while eof-reached is true, so
    -- state isn't saved at EOF when keep-open=yes
    local function eof_reached(_, eof)
        if not can_delete then
            return
        elseif eof then
            print("Deleting state (eof-reached)")
            if demuxer_secs then
                mp.commandv("change-list", "watch-later-options", "remove", "start")
            else
                mp.commandv("delete-watch-later-config", path)
            end
        end
    end

    local function end_file(event)
        mp.unregister_event(end_file)
        mp.unobserve_property(eof_reached)

        if not can_delete then
            can_delete = true
        elseif event["reason"] == "eof" then
            print("Deleting state (end-file " .. event["reason"] .. ")")
            mp.commandv("delete-watch-later-config", path)
        end
    end

    mp.observe_property("eof-reached", "bool", eof_reached)
    mp.register_event("end-file", end_file)
end

mp.register_script_message("skip-delete-state", function() can_delete = false end)

timer = mp.add_periodic_timer(o.save_interval, save)
mp.observe_property("pause", "bool", pause_timer_while_paused)

mp.observe_property("pause", "bool", save_if_pause)
mp.register_event("file-loaded", delete_watch_later)
