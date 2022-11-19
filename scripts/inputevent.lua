-- InputEvent
-- https://github.com/Natural-Harmonia-Gropius/InputEvent

local utils = require("mp.utils")

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

function now()
    return mp.get_time() * 1000
end

function command(command)
    return mp.command(command)
end

function command_invert(command)
    local invert = ""
    local command_list = command:split(";")
    for i, v in ipairs(command_list) do
        local trimed = v:trim()
        local subs = trimed:split("%s*")
        local prefix = table.has(prefixes, subs[1]) and subs[1] or ""
        local command = subs[prefix == "" and 1 or 2]
        local property = subs[prefix == "" and 2 or 3]
        local value = mp.get_property(property)
        local semi = i == #command_list and "" or ";"

        if table.has(commands, command) then
            invert = invert .. prefix .. " set " .. property .. " " .. value .. semi
        else
            mp.msg.warn("\"" .. trimed .. "\" doesn't support auto restore.")
        end
    end
    return invert
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

local InputEvent = {}

function InputEvent:new(key, on)
    local Instance = {}
    setmetatable(Instance, self);
    self.__index = self;

    Instance.key = key
    Instance.name = "@" .. key
    Instance.on = table.assign({ click = "" }, on)
    Instance.queue = {}
    Instance.queue_max = { length = 0 }
    Instance.duration = mp.get_property_number("input-doubleclick-time", 300)

    for _, event in ipairs(event_pattern) do
        if Instance.on[event.to] and event.length > 1 then
            Instance.queue_max = { event = event.to, length = event.length }
            break
        end
    end

    return Instance
end

function InputEvent:emit(event)
    local ignore = event .. "-ignore"
    if self.on[ignore] then
        if now() - self.on[ignore] < self.duration then
            return
        end

        self.on[ignore] = nil
    end

    if event == "press" and self.on["release"] == "ignore" then
        self.on["release-auto"] = command_invert(self.on["press"])
    end

    if event == "release" and self.on[event] == "ignore" then
        event = "release-auto"
    end

    local cmd = self.on[event]
    if not cmd or cmd == "" then
        return
    end

    command(cmd)
end

function InputEvent:handler(event)
    if event == "press" then
        self:handler("down")
        self:handler("up")
        return
    end

    if event == "down" then
        self.on["repeat-ignore"] = now()
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

function InputEvent:bind()
    self.exec_debounced = debounce(function() self:exec() end, self.duration)
    mp.add_forced_key_binding(self.key, self.name, function(e) self:handler(e.event) end, { complex = true })
end

function InputEvent:unbind()
    mp.remove_key_binding(self.name)
end

function InputEvent:rebind(diff)
    if type(diff) == "table" then
        self = table.assign(self, diff)
    end

    self:unbind()
    self:bind()
end

function bind(key, on)
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

function unbind(key)
    bind_map[key]:unbind()
end

function bind_from_input_conf()
    local input_conf = mp.get_property_native("input-conf")
    local input_conf_path = mp.command_native({ "expand-path", input_conf == "" and "~~/input.conf" or input_conf })
    local input_conf_meta, meta_error = utils.file_info(input_conf_path)
    if not input_conf_meta or not input_conf_meta.is_file then return end -- File doesn"t exist

    local parsed = {}
    for line in io.lines(input_conf_path) do
        line = line:trim()
        if line ~= "" then
            local key, cmd, comment = line:match("%s*([%S]+)%s+(.-)%s+#%s*(.-)%s*$")
            if comment and key:sub(1, 1) ~= "#" then
                local comments = comment:split("#")
                local events = table.filter(comments, function(i, v) return v:match("^@") end)
                if events and #events > 0 then
                    local event = events[1]:match("^@(.*)"):trim()
                    if event and event ~= "" then
                        if parsed[key] == nil then
                            parsed[key] = {}
                        end
                        parsed[key][event] = cmd
                    end
                end
            end
        end
    end
    for key, on in pairs(parsed) do
        bind(key, on)
    end
end

mp.observe_property("input-doubleclick-time", "native", function(_, new_duration)
    for _, binding in pairs(bind_map) do
        binding:rebind({ duration = new_duration })
    end
end)

mp.observe_property("focused", "native", function(_, focused)
    local binding = bind_map["MBTN_LEFT"]
    if not binding or not focused then return end
    binding.on["click-ignore"] = now() + 100
end)

mp.register_script_message("bind", bind)
mp.register_script_message("unbind", unbind)

bind_from_input_conf()
