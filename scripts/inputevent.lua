-- InputEvent
-- https://github.com/Natural-Harmonia-Gropius/InputEvent

local utils = require("mp.utils")
local opt = require("mp.options")
local msg = require("mp.msg")
local next = next

local watched_properties = {}       -- indexed by property name (used as a set)
local cached_properties = {}        -- property name -> last known raw value
local o = {
    --enable external config
    enable_external_config = false,

    --external config file path
    external_config = "~~/script-opts/inputevent_key.conf",
}

opt.read_options(o, "inputevent")

local bind_map = {}

local event_pattern = {
    { to = "penta_click", from = "down,up,down,up,down,up,down,up,down,up", length = 10 },
    { to = "quatra_click", from = "down,up,down,up,down,up,down,up", length = 8 },
    { to = "triple_click", from = "down,up,down,up,down,up", length = 6 },
    { to = "double_click", from = "down,up,down,up", length = 4 },
    { to = "click", from = "down,up", length = 2 },
    { to = "press", from = "down", length = 1 },
    { to = "release", from = "up", length = 1 },
}

-- https://mpv.io/manual/master/#input-command-prefixes
local prefixes = { "osd-auto", "no-osd", "osd-bar", "osd-msg", "osd-msg-bar", "raw", "expand-properties", "repeatable",
    "async", "sync" }

-- https://mpv.io/manual/master/#list-of-input-commands
local commands = { "set", "cycle", "add", "multiply" }

function table:isEmpty()
    if next(self) == nil then
        return true
    else
        return false
    end
end

function table:push(element)
    self[#self + 1] = element
    return self
end

function table:assign(source)
    for key, value in pairs(source) do
        self[key] = value
    end
    return self
end

function table:has(element)
    for _, value in ipairs(self) do
        if value == element then
            return true
        end
    end
    return false
end

function table:filter(filter)
    local nt = {}
    for index, value in ipairs(self) do
        if (filter(index, value)) then
            nt = table.push(nt, value)
        end
    end
    return nt
end

function table:remove(element)
    return table.filter(self, function(i, v) return v ~= element end)
end

function table:join(separator)
    local result = ""
    for i, v in ipairs(self) do
        local value = type(v) == "string" and v or tostring(v)
        local semi = i == #self and "" or separator
        result = result .. value .. semi
    end
    return result
end

function string:trim()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end

function string:replace(pattern, replacement)
    local result, n = self:gsub(pattern, replacement)
    return result
end

function string:split(separator)
    local fields = {}
    local separator = separator or ":"
    local pattern = string.format("([^%s]+)", separator)
    local copy = self:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

local function debounce(func, wait)
    func = type(func) == "function" and func or function() end
    wait = type(wait) == "number" and wait / 1000 or 0

    local timer = nil
    local timer_end = function()
        timer:kill()
        timer = nil
        func()
    end

    return function()
        if timer then
            timer:kill()
        end
        timer = mp.add_timeout(wait, timer_end)
    end
end

local function now()
    return mp.get_time() * 1000
end

local function command(command)
    return mp.command(command)
end

local function command_invert(command)
    local invert = ""
    local command_list = command:split(";")
    for i, v in ipairs(command_list) do
        local trimed = v:trim()
        local subs = trimed:split("%s*")
        local prefix, command, property = "", nil, nil
        for _, s in ipairs(subs) do
            local sub = s:trim()
            if not command and table.has(prefixes, sub) then
                prefix = prefix .. " " .. sub
            elseif not command then
                if table.has(commands, sub) then
                    command = sub
                else
                    msg.warn("\"" .. trimed .. "\" doesn't support auto restore.")
                    break
                end
            elseif command and not property then
                property = sub
                break
            end
        end

        repeat -- workaround continue
            if not command or not property then
                msg.warn("\"" .. trimed .. "\" doesn't support auto restore.")
                break
            end

            local value = mp.get_property(property)
            if value then
                local semi = i == #command_list and "" or ";"
                invert = invert .. prefix:trim() .. " set " .. property .. " " .. value .. semi
            else
                msg.warn("\"" .. trimed .. "\" doesn't support auto restore.")
            end
        until true
    end
    msg.verbose("command_invert:" .. invert)
    return invert
end

-- https://github.com/mpv-player/mpv/blob/master/player/lua/auto_profiles.lua
local function on_property_change(name, val)
    cached_properties[name] = val
end

local function magic_get(name)
    -- Lua identifiers can't contain "-", so in order to match with mpv
    -- property conventions, replace "_" to "-"
    name = string.gsub(name, "_", "-")
    if not watched_properties[name] then
        watched_properties[name] = true
        local res, err = mp.get_property_native(name)
        if err == "property not found" then
            msg.error("Property '" .. name .. "' was not found.")
            return default
        end
        cached_properties[name] = res
        mp.observe_property(name, "native", on_property_change)
    end
    return cached_properties[name]
end

local evil_magic = {}
setmetatable(evil_magic, {
    __index = function(table, key)
        -- interpret everything as property, unless it already exists as
        -- a non-nil global value
        local v = _G[key]
        if type(v) ~= "nil" then
            return v
        end
        return magic_get(key)
    end,
})

p = {}
setmetatable(p, {
    __index = function(table, key)
        return magic_get(key)
    end,
})

local function compile_cond(name, s)
    local code, chunkname = "return " .. s, "Event " .. name .. " condition"
    local chunk, err
    if setfenv then -- lua 5.1
        chunk, err = loadstring(code, chunkname)
        if chunk then
            setfenv(chunk, evil_magic)
        end
    else -- lua 5.2
        chunk, err = load(code, chunkname, "t", evil_magic)
    end
    if not chunk then
        msg.error("Event '" .. name .. "' condition: " .. err)
        chunk = function() return false end
    end
    return chunk
end

local InputEvent = {}

function InputEvent:new(key, on)
    local Instance = {}
    setmetatable(Instance, self);
    self.__index = self;

    Instance.key = key
    Instance.on = table.assign({ click = {} }, on)  -- event -> actions {cmd="",cond=function}
    Instance.queue = {}
    Instance.queue_max = { length = 0 }
    Instance.duration = mp.get_property_number("input-doubleclick-time", 300)
    Instance.ignored = {}

    for _, event in ipairs(event_pattern) do
        if Instance.on[event.to] and event.length > 1 then
            Instance.queue_max = { event = event.to, length = event.length }
            break
        end
    end

    return Instance
end

function InputEvent:evaluate(event)
    msg.verbose("Evaluating event: " .. event)
    local seleted = nil
    local actions = self.on[event]
    if not actions or table.isEmpty(actions) then return end
    for _, action in ipairs(actions) do
        msg.verbose("Evaluating comand: " .. action.cmd)
        if type(action.cond) ~= "function" then
            seleted = action.cmd
            break
        else
            local status, res = pcall(action.cond)
            if not status then
                -- errors can be "normal", e.g. in case properties are unavailable
                msg.verbose("Action condition error on evaluating: " .. res)
                res = false
            end
            res = not not res
            if res then
                seleted = action.cmd
                break
            end
        end
    end

    return seleted
end

local function cmd_filter(i,v) return (v.cmd ~= nil and v.cmd ~= "ignore") end

function InputEvent:emit(event)
    if self.ignored[event] then
        if now() - self.ignored[event] < self.duration then
            return
        end

        self.ignored[event] = nil
    end

    if event == "release" and (
        self.on["release"] == nil or
        table.isEmpty(self.on["release"]) or
        table.isEmpty( table.filter(self.on["release"], cmd_filter) )
        )
    then
        event = "release-auto"
    end

    if event == "repeat" and self.on[event] == "ignore" then
        event = "click"
    end

    local cmd = self:evaluate(event)
    if not cmd or cmd == "" then
        return
    end

    if event == "press" and (
        self.on["release"] == nil or
        table.isEmpty(self.on["release"]) or
        table.isEmpty( table.filter(self.on["release"], cmd_filter) )
        )
    then
        self.on["release-auto"] = {{cmd = command_invert(cmd), cond = nil}}
    end

    local expand = mp.command_native({'expand-text', cmd})
    if #cmd:split(";") == #expand:split(";") then
        cmd = mp.command_native({'expand-text', cmd})
    else
        mp.msg.warn("Unsafe property-expansion detected.")
    end

    msg.verbose("Apply comand: " .. cmd)
    command(cmd)
end

function InputEvent:handler(event)
    if event == "press" then
        self:handler("down")
        self:handler("up")
        return
    end

    if event == "down" then
        self:ignore("repeat")
    end

    if event == "repeat" then
        self:emit(event)
        return
    end

    if event == "up" then
        if #self.queue == 0 then
            self:emit("release")
            return
        end

        if #self.queue + 1 == self.queue_max.length then
            self.queue = {}
            self:emit(self.queue_max.event)
            return
        end
    end

    self.queue = table.push(self.queue, event)
    self.exec_debounced()
end

function InputEvent:exec()
    if #self.queue == 0 then
        return
    end

    local separator = ","

    local queue_string = table.join(self.queue, separator)
    for _, v in ipairs(event_pattern) do
        if self.on[v.to] then
            queue_string = queue_string:replace(v.from, v.to)
        end
    end

    self.queue = queue_string:split(separator)
    for _, event in ipairs(self.queue) do
        self:emit(event)
    end

    self.queue = {}
end

function InputEvent:ignore(event, timeout)
    timeout = timeout or 0

    self.ignored[event] = now() + timeout
end

function InputEvent:bind()
    self.exec_debounced = debounce(function() self:exec() end, self.duration)
    mp.add_forced_key_binding(self.key, self.key, function(e) self:handler(e.event) end, { complex = true })
end

function InputEvent:unbind()
    mp.remove_key_binding(self.key)
end

function InputEvent:rebind(diff)
    if type(diff) == "table" then
        self = table.assign(self, diff)
    end

    self:unbind()
    self:bind()
end

local function bind(key, on)
    key = #key == 1 and key or key:upper()

    if type(on) == "string" then
        on = utils.parse_json(on)
    end

    if bind_map[key] then
        on = table.assign(bind_map[key].on, on)
        bind_map[key]:unbind()
    end

    bind_map[key] = InputEvent:new(key, on)
    bind_map[key]:bind()
end

local function unbind(key)
    bind_map[key]:unbind()
end

local function comment_filter(i, v) return v:match("^@") end

local function read_conf(conf_path)
    local conf_meta, meta_error = utils.file_info(conf_path)
    if not conf_meta or not conf_meta.is_file then
        msg.error("File not exist : " .. conf_path)
        return
    end -- File doesn't exist

    local parsed = {}
    for line in io.lines(conf_path) do
        line = line:trim()
        if line ~= "" and line:sub(1, 1) ~= "#" then
            local key, cmd, comments = line:match("%s*([%S]+)%s+(.-)%s+#%s*(.-)%s*$")
            if comments then
                local comment = table.filter(comments:split("#"), comment_filter)
                if comment and #comment > 0 then
                    local statement = comment[1]:match("^@(.*)"):trim()
                    if statement and statement ~= "" then
                        msg.verbose(string.format("Statement for [%s]:%s",key,statement))
                        local parts = statement:split("|")
                        local event, cond = statement ,nil
                        if #parts > 1 then
                            event, cond = statement:match("(.-)%s*|%s*(.-)$")
                        end

                        if parsed[key] == nil then
                            parsed[key] = {}
                        end
                        if parsed[key][event] == nil then
                            parsed[key][event] = {}
                        end

                        local index = table.isEmpty(parsed[key][event]) and 1 or #parsed[key][event]+1
                        local cond_name = string.format("%s-%s-%d", key, event, index)
                        table.insert(parsed[key][event], 1,{
                            cmd = cmd, 
                            cond = cond ~= nil and compile_cond(cond_name, cond) or nil
                        })
                    end
                end
            end
        end
    end
    return parsed
end

mp.observe_property("input-doubleclick-time", "native", function(_, new_duration)
    for _, binding in pairs(bind_map) do
        binding:rebind({ duration = new_duration })
    end
end)

mp.observe_property("focused", "native", function(_, focused)
    local binding = bind_map["MBTN_LEFT"]
    if not binding or not focused then return end
    binding:ignore("click", 100)
end)

mp.register_script_message("bind", bind)
mp.register_script_message("unbind", unbind)

local input_conf = mp.get_property_native("input-conf")
local input_conf_path = mp.command_native({ "expand-path", input_conf == "" and "~~/input.conf" or input_conf })
if o.enable_external_config then
    local external_config_path = mp.command_native({ "expand-path", o.external_config })
    local parsed = read_conf(external_config_path)
    if parsed and not table.isEmpty(parsed) then
        for key, on in pairs(parsed) do
            bind(key, on)
        end
    end
else
    local parsed = read_conf(input_conf_path)
    if parsed and not table.isEmpty(parsed) then
        for key, on in pairs(parsed) do
            bind(key, on)
        end
    end
end
