-- Script home: https://github.com/d87/mpv-persist-properties
local utils = require "mp.utils"
local msg = require "mp.msg"

local opts = {
    properties = "volume,sub-scale",
    properties_path = 'persistent_config.json'
}
(require 'mp.options').read_options(opts, "persist_properties")

local CONFIG_ROOT = mp.find_config_file(".")
if not utils.file_info(CONFIG_ROOT) then
    -- On Windows if using portable_config dir, APPDATA mpv folder isn't auto-created
    -- In more recent mpv versions there's a mp.get_script_directory function, but i'm not using it for compatiblity
    local mpv_conf_path = mp.find_config_file("scripts") -- finds where the scripts folder is located
    local mpv_conf_dir = utils.split_path(mpv_conf_path)
    CONFIG_ROOT = mpv_conf_dir
end
local PCONFIG = utils.join_path(CONFIG_ROOT, opts.properties_path);

local function split(input)
    local ret = {}
    for str in string.gmatch(input, "([^,]+)") do
        table.insert(ret, str)
    end
    return ret
end
local persisted_properties = split(opts.properties)

local print = function(...)
    -- return msg.log("info", ...)
end

-- print("Config Root is "..CONFIG_ROOT)

local isInitialized = false

local properties

local function load_config(file)
    local f = io.open(file, "r")
    if f then
        local jsonString = f:read()
        f:close()

        if jsonString == nil then
            return {}
        end

        local props = utils.parse_json(jsonString)
        if props then
            return props
        end
    end
    return {}
end

local function save_config(file, properties)
    local serialized_props = utils.format_json(properties)

    local f = io.open(file, 'w+')
    if f then
        f:write(serialized_props)
        f:close()
    else
        msg.log("error", string.format("Couldn't open file: %s", file))
    end
end

local save_timer = nil
local got_unsaved_changed = false

local function onInitialLoad()
    properties = load_config(PCONFIG)

    for i, property in ipairs(persisted_properties) do
        local name = property
        local value = properties[name]
        if value ~= nil then
            mp.set_property_native(name, value)
        end
    end

    for i, property in ipairs(persisted_properties) do
        local property_type = nil
        mp.observe_property(property, property_type, function(name)
            if isInitialized then
                local value = mp.get_property_native(name)
                -- print(string.format("%s changed to %s at %s", name, value,  os.time()))

                properties[name] = value

                if save_timer then
                    save_timer:kill()
                    save_timer:resume()
                    got_unsaved_changed = true
                else
                    save_timer = mp.add_timeout(5, function()
                        save_config(PCONFIG, properties)
                        got_unsaved_changed = false
                    end)
                end
            end
        end)
    end

    isInitialized = true
end

onInitialLoad()
mp.register_event("shutdown", function()
    if got_unsaved_changed then
        save_config(PCONFIG, properties)
    end
end)
