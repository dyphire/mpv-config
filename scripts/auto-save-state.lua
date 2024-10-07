-- Runs write-watch-later-config periodically

local options = require 'mp.options'
local msg = require 'mp.msg'

o = {
    save_interval = 60,
    percent_pos = 99,
}
options.read_options(o)

local can_delete = true
local can_save = true
local path = nil -- only set after file success load, reset to nil when file unload.

local function reset()
    path = nil
end

-- set vars when file success load
local function init()
    path = mp.get_property("path")
end

local function save()
    if not can_save then return end
    local watch_later_list = mp.get_property("watch-later-options", {})
    if mp.get_property_bool("save-position-on-quit") then
        msg.debug("saving state")
        if not watch_later_list:find("start") then
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

-- save watch-later-config when file unloading
local function save_or_delete()
    if not can_delete then return end
    local eof = mp.get_property_bool("eof-reached")
    local percent_pos = mp.get_property_number("percent-pos")
    if eof or percent_pos and (percent_pos == 0 or percent_pos >= o.percent_pos) then
        can_delete = true
        if path ~= nil then
            msg.debug("deleting state: percent_pos=0 or eof")
            mp.commandv("delete-watch-later-config", path)
        end
    elseif path ~= nil then
        save()
    end
    reset()
end

mp.register_script_message("skip-delete-state", function() can_delete = false end)

timer = mp.add_periodic_timer(o.save_interval, save)
mp.observe_property("pause", "bool", pause_timer_while_paused)

mp.observe_property("pause", "bool", save_if_pause)

mp.register_event("file-loaded", init)
mp.add_hook("on_unload", 50, save_or_delete) -- after mpv saving state