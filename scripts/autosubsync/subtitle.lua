local P = {}

local TimeStamp = {}
local TimeStamp_mt = { __index = TimeStamp }
function TimeStamp:new(hours, minutes, seconds)
    local new = {}
    new.hours = hours
    new.minutes = minutes
    new.seconds = seconds
    return setmetatable(new, TimeStamp_mt)
end

function TimeStamp.toTimeStamp(seconds)
    local diff, h, m, s = seconds, 0, 0, 0
    h = math.floor(diff / 3600)
    diff = diff - (h * 3600)
    m = math.floor(diff / 60)
    diff = diff - (m * 60)
    s = diff
    return TimeStamp:new(h, m, s)
end

function TimeStamp:toSeconds()
    return (3600 * self.hours) + (60 * self.minutes) + self.seconds
end

function TimeStamp:adjustTime(seconds)
    return self.toTimeStamp(self:toSeconds() + seconds)
end

function TimeStamp:toString(decimal_symbol)
    local seconds_fmt = string.format("%06.3f", self.seconds):gsub("%.", decimal_symbol)
    return string.format("%02d:%02d:%s", self.hours, self.minutes, seconds_fmt)
end

function TimeStamp.to_seconds(seconds, milliseconds)
    return tonumber(string.format("%s.%s", seconds, milliseconds))
end

local AbstractSubtitle = {}
local AbstractSubtitle_mt = { __index = AbstractSubtitle }

function AbstractSubtitle:create()
    local new = {}
    return setmetatable(new, AbstractSubtitle_mt)
end

function AbstractSubtitle:save()
    print(string.format("Writing '%s' to file..", self.filename))
    local f = io.open(self.filename, 'w')
    f:write(self:toString())
    f:close()
end

-- strip Byte Order Mark from file, if it's present
function AbstractSubtitle:sanitize(line)
    local bom_table = { 0xEF, 0xBB, 0xBF } -- TODO maybe add other ones (like UTF-16)
    local function has_bom()
        for i = 1, #bom_table do
            if i > #line then return false end
            local ch, byte = line:sub(i, i), line:byte(i, i)
            if byte ~= bom_table[i] then return false end
        end
        return true
    end
    return has_bom() and string.sub(line, #bom_table + 1) or line
end

local function trim(s)
    return s:match "^%s*(.-)%s*$"
end

function AbstractSubtitle:parse_file(filename)
    local lines = {}
    for line in io.lines(filename) do
        if #lines == 0 then line = self:sanitize(line) end
        line = line:gsub('\r\n?', '') -- make sure there's no carriage return
        line = trim(line)
        table.insert(lines, line)
    end
    return lines
end

function AbstractSubtitle:shift_timing(diff_seconds)
    for _, entry in pairs(self.entries) do
        if self.valid_entry(entry) then
            entry.start_time = entry.start_time:adjustTime(diff_seconds)
            entry.end_time = entry.end_time:adjustTime(diff_seconds)
        end
    end
end

function AbstractSubtitle.valid_entry(entry)
    return entry ~= nil
end

local function inheritsFrom (baseClass)
    local new_class = {}
    local class_mt = { __index = new_class }

    function new_class:create(filename)
        local instance = {
            filename = filename,
            language = nil,
            header = nil, -- will be empty for srt, some stuff for ass
            entries = {} -- list of entries
        }
        setmetatable(instance, class_mt)
        return instance
    end

    if baseClass then
        setmetatable(new_class, { __index = baseClass })
    end
    return new_class
end

local SRT = inheritsFrom(AbstractSubtitle)
function SRT.entry()
    return { index = nil, start_time = nil, end_time = nil, text = {} }
end

function SRT:populate(filename)
    local timestamp_fmt = "^(%d+):(%d+):(%d+),(%d+) %-%-> (%d+):(%d+):(%d+),(%d+)$"
    local function parse_timestamp(timestamp)
        local function to_seconds(seconds, milliseconds)
            return tonumber(string.format("%s.%s", seconds, milliseconds))
        end
        local _, _, from_h, from_m, from_s, from_ms, to_h, to_m, to_s, to_ms = timestamp:find(timestamp_fmt)
        return TimeStamp:new(from_h, from_m, to_seconds(from_s, from_ms)), TimeStamp:new(to_h, to_m, to_seconds(to_s, to_ms))
    end

    local new = self:create(filename)
    local entry = self.entry()
    local f_idx, idx = 1, 1
    for _, line in pairs(self:parse_file(filename)) do
        if idx == 1 and #line > 0 then
            assert(line:match("^%d+$"), string.format("SRT FORMAT ERROR (line %d): expected a number but got '%s'", f_idx, line))
            entry.index = line
        elseif idx == 2 then
            assert(line:match("^%d+:%d+:%d+,%d+ %-%-> %d+:%d+:%d+,%d+$"), string.format("SRT FORMAT ERROR (line %d): expected a timecode string but got '%s'", f_idx, line))
            local t_start, t_end = parse_timestamp(line)
            entry.start_time, entry.end_time = t_start, t_end
        else
            if #line == 0 then
                -- end of text
                if entry.index ~= nil then
                    table.insert(new.entries, entry)
                end
                entry = SRT.entry()
                idx = 0
            else
                table.insert(entry.text, line)
            end
        end
        idx = idx + 1
        f_idx = f_idx + 1
    end
    return new
end

function SRT:toString()
    local stringbuilder = {}
    local function append(s)
        table.insert(stringbuilder, s)
    end
    for _, entry in pairs(self.entries) do
        append(entry.index)
        local timestamp_string = string.format("%s --> %s", entry.start_time:toString(","), entry.end_time:toString(","))
        append(timestamp_string)
        if type(entry.text) == 'table' then
            append(table.concat(entry.text, "\n"))
        else append(entry.text) end
        append('')
    end
    return table.concat(stringbuilder, '\n')
end

local ASS = inheritsFrom(AbstractSubtitle)
ASS.header_mapper = { ["Start"] = "start_time", ["End"] = "end_time" }

function ASS.valid_entry(entry)
    return entry['type'] ~= nil
end

function ASS:toString()
    local stringbuilder = {}
    local function append(s) table.insert(stringbuilder, s) end
    append(self.header)
    append('[Events]')
    for i = 1, #self.entries do
        if i == 1 then
            -- stringbuilder for events header
            local event_sb = {};
            for _, v in pairs(self.event_header) do table.insert(event_sb, v) end
            append(string.format("Format: %s", table.concat(event_sb, ", ")))
        end
        local entry = self.entries[i]
        local entry_sb = {}
        for _, col in pairs(self.event_header) do
            local value = entry[col]
            local timestamp_entry_column = self.header_mapper[col]
            if timestamp_entry_column then
                value = entry[timestamp_entry_column]:toString(".")
            end
            table.insert(entry_sb, value)
        end
        append(string.format("%s: %s", entry['type'], table.concat(entry_sb, ",")))
    end
    return table.concat(stringbuilder, '\n')
end

function ASS:populate(filename, language)
    local header, events, parser = {}, {}, nil
    for _, line in pairs(self:parse_file(filename)) do
        local _, _, event = string.find(line, "^%[([^%]]+)%]%s*$")
        if event then
            if event == "Events" then
                parser = function(x) table.insert(events, x) end
            else
                parser = function(x) table.insert(header, x) end
                parser(line)
            end
        else
            parser(line)
        end
    end
    -- create subtitle instance
    local ev_regex = "^(%a+):%s(.+)$"
    local function parse_event(header_columns, ev)
        local function create_timestamp(timestamp_str)
            local timestamp_fmt = "^(%d+):(%d+):(%d+).(%d+)"
            local _, _, h, m, s, ms = timestamp_str:find(timestamp_fmt)
            return TimeStamp:new(h, m, TimeStamp.to_seconds(s, ms))
        end
        local new_event = {}
        local _, _, ev_type, ev_values = string.find(ev, ev_regex)
        new_event['type'] = ev_type
        -- skipping last column, since that's the text, which can contain commas
        local last_idx = 0;
        for i = 1, #header_columns - 1 do
            local col = header_columns[i]
            local idx = string.find(ev_values, ",", last_idx + 1)
            local val = ev_values:sub(last_idx + 1, idx - 1)
            local timestamp_entry_column = self.header_mapper[col]
            if timestamp_entry_column then
                new_event[timestamp_entry_column] = create_timestamp(val)
            else
                new_event[col] = val
            end
            last_idx = idx
        end
        new_event[header_columns[#header_columns]] = ev_values:sub(last_idx + 1)
        return new_event
    end

    local sub = self:create(filename)
    sub.header = table.concat(header, "\n")
    sub.language = language
    -- remove and process first entry in events, which is a header
    local _, _, colstring = string.find(table.remove(events, 1), "^%a+:%s(.+)$")
    local columns = {};
    for i in colstring:gmatch("[^%,%s]+") do table.insert(columns, i) end
    sub.event_header = columns
    for _, event in pairs(events) do
        if #event > 0 then
            table.insert(sub.entries, parse_event(columns, event))
        end
    end
    return sub
end

P.AbstractSubtitle = AbstractSubtitle
P.ASS = ASS
P.SRT = SRT
return P
