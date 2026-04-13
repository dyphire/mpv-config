-- original by Wanakachi
-- suitable for Windows operating systems

-- picture-in-picture (PiP) mode for mpv

local options = require "mp.options"

local o = {
    autofit = "25%x25%",
    autofit_restore_larger = "100%x100%",
    autofit_restore_smaller = "40%x30%",
    geometry = "100%:100%",        -- pip position, bottom-right: 100%:100%
    geometry_restore = "50%:50%",  -- restore position, center: 50%:50%
    geometry_delay = 0.02          -- delay to avoid geometry race on state change
}

options.read_options(o, _, function() end)

local pip_enabled = false
local geometry_timer = nil
local original_options = {}

-- save original window properties
local function save_original_options()
    original_options.fullscreen   = mp.get_property_bool("fullscreen")
    original_options.window_maximized = mp.get_property_bool("window-maximized")
    original_options.auto_window_resize = mp.get_property_bool("auto-window-resize")
    original_options.force_window_position = mp.get_property_bool("force-window-position")
    original_options.keepaspect_window = mp.get_property_bool("keepaspect-window")
    original_options.border        = mp.get_property_bool("border")
    original_options.ontop         = mp.get_property_bool("ontop")
    original_options.window_scale  = mp.get_property("window_scale")
    original_options.autofit       = mp.get_property("autofit")
    original_options.autofit_larger = mp.get_property("autofit-larger") ~= "" and mp.get_property("autofit-larger") or o.autofit_restore_larger
    original_options.autofit_smaller = mp.get_property("autofit-smaller") ~= "" and mp.get_property("autofit-smaller") or o.autofit_restore_smaller
    original_options.geometry    = mp.get_property("geometry") ~= "" and mp.get_property("geometry") or o.geometry_restore
end

-- restore original window properties
local function restore_original_options()
    if original_options.fullscreen    ~= nil then mp.set_property_bool("fullscreen",    original_options.fullscreen)    end
    if original_options.window_maximized ~= nil then mp.set_property_bool("window-maximized", original_options.window_maximized) end
    if original_options.auto_window_resize ~= nil then mp.set_property_bool("auto-window-resize", original_options.auto_window_resize) end
    if original_options.force_window_position ~= nil then mp.set_property_bool("force-window-position", original_options.force_window_position) end
    if original_options.border        ~= nil then mp.set_property_bool("border",        original_options.border)        end
    if original_options.ontop         ~= nil then mp.set_property_bool("ontop",         original_options.ontop)         end
    if original_options.keepaspect_window ~= nil then mp.set_property_bool("keepaspect-window", original_options.keepaspect_window) end
    if original_options.window_scale  ~= nil then mp.set_property("window_scale", original_options.window_scale) end
    if original_options.autofit       ~= nil then mp.set_property("autofit", original_options.autofit) end
    if original_options.autofit_larger ~= nil then mp.set_property("autofit-larger", original_options.autofit_larger) end
    if original_options.autofit_smaller ~= nil then mp.set_property("autofit-smaller", original_options.autofit_smaller) end
    if original_options.geometry ~= nil then mp.set_property("geometry", original_options.geometry) end
end

local function cancel_geometry_timer()
    if geometry_timer then
        geometry_timer:kill()
        geometry_timer = nil
    end
end

local function set_geometry_delay(value)
    cancel_geometry_timer()
    geometry_timer = mp.add_timeout(o.geometry_delay, function()
        geometry_timer = nil
        mp.set_property("geometry", value)
    end)
end

-- enter PiP mode
local function enable_pip()
    if pip_enabled then return end

    save_original_options()

    mp.set_property_bool("fullscreen",   false)   -- exit fullscreen if necessary
    mp.set_property_bool("window-maximized", false) -- exit window-maximized if necessary
    mp.set_property_bool("window-minimized", false)
    mp.set_property_bool("auto-window-resize", false)
    mp.set_property_bool("force-window-position", false)
    mp.set_property_bool("border",       false)   -- remove decorations
    mp.set_property_bool("ontop",        true)    -- keep above other windows
    mp.set_property_bool("keepaspect-window", true)
    mp.set_property("autofit", o.autofit)
    mp.set_property("autofit-larger", "")
    mp.set_property("autofit-smaller", "")
    mp.set_property("window_scale", "")
    set_geometry_delay(o.geometry)

    pip_enabled = true
    mp.osd_message("PiP enabled")
end

-- leave PiP mode
local function disable_pip()
    if not pip_enabled then return end

    cancel_geometry_timer()
    restore_original_options()
    pip_enabled = false
    mp.osd_message("PiP disabled")
end

-- toggle PiP on/off
local function toggle_pip()
    if pip_enabled then
        disable_pip()
    else
        enable_pip()
    end
end

-- monitor fullscreen state changes and exit PiP first
mp.observe_property("fullscreen", "bool", function(_, value)
    if value and pip_enabled then
        disable_pip()
        mp.set_property_bool("fullscreen", true)
    end
end)

-- monitor window-maximized state changes (on some systems maximize and fullscreen are separate)
mp.observe_property("window-maximized", "bool", function(_, value)
    if value and pip_enabled then
        disable_pip()
        mp.set_property_bool("window-maximized", true)
    end
end)

-- binding
mp.add_key_binding(nil, "toggle-pip", toggle_pip)