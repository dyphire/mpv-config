local mp = require 'mp'
local scroll_list = {
    global_style = [[]],
    header_style = [[{\q2\fs35\c&00ccff&}]],
    list_style = [[{\q2\fs25\c&Hffffff&}]],
    wrapper_style = [[{\c&00ccff&\fs16}]],
    cursor_style = [[{\c&00ccff&}]],
    selected_style = [[{\c&Hfce788&}]],

    cursor = [[➤\h]],
    indent = [[\h\h\h\h]],

    num_entries = 16,
    wrap = false,
    empty_text = "no entries"
}

--formats strings for ass handling
--this function is based on a similar function from https://github.com/mpv-player/mpv/blob/master/player/lua/console.lua#L110
function scroll_list.ass_escape(str, replace_newline)
    if replace_newline == true then replace_newline = "\\\239\187\191n" end

    --escape the invalid single characters
    str = str:gsub('[\\{}\n]', {
        -- There is no escape for '\' in ASS (I think?) but '\' is used verbatim if
        -- it isn't followed by a recognised character, so add a zero-width
        -- non-breaking space
        ['\\'] = '\\\239\187\191',
        ['{'] = '\\{',
        ['}'] = '\\}',
        -- Precede newlines with a ZWNBSP to prevent ASS's weird collapsing of
        -- consecutive newlines
        ['\n'] = '\239\187\191\\N',
    })

    -- Turn leading spaces into hard spaces to prevent ASS from stripping them
    str = str:gsub('\\N ', '\\N\\h')
    str = str:gsub('^ ', '\\h')

    if replace_newline then
        str = str:gsub("\\N", replace_newline)
    end
    return str
end

--appends the entered text to the overlay
function scroll_list:append(text)
        if text == nil then return end
        self.ass.data = self.ass.data .. text
    end

--appends a newline character to the osd
function scroll_list:newline()
    self.ass.data = self.ass.data .. '\\N'
end

--re-parses the list into an ass string
--if the list is closed then it flags an update on the next open
function scroll_list:update()
    if self.hidden then self.flag_update = true
    else self:update_ass() end
end

--prints the header to the overlay
function scroll_list:format_header()
    self:append(self.header_style)
    self:append(self.header)
    self:newline()
end

--formats each line of the list and prints it to the overlay
function scroll_list:format_line(index, item)
    self:append(self.list_style)

    if index == self.selected then self:append(self.cursor_style..self.cursor..self.selected_style)
    else self:append(self.indent) end

    self:append(item.style)
    self:append(item.ass)
    self:newline()
end

--refreshes the ass text using the contents of the list
function scroll_list:update_ass()
    self.ass.data = self.global_style
    self:format_header()

    if #self.list < 1 then
        self:append(self.empty_text)
        self.ass:update()
        return
    end

    local start = 1
    local finish = start+self.num_entries-1

    --handling cursor positioning
    local mid = math.ceil(self.num_entries/2)+1
    if self.selected+mid > finish then
        local offset = self.selected - finish + mid

        --if we've overshot the end of the list then undo some of the offset
        if finish + offset > #self.list then
            offset = offset - ((finish+offset) - #self.list)
        end

        start = start + offset
        finish = finish + offset
    end

    --making sure that we don't overstep the boundaries
    if start < 1 then start = 1 end
    local overflow = finish < #self.list
    --this is necessary when the number of items in the dir is less than the max
    if not overflow then finish = #self.list end

    --adding a header to show there are items above in the list
    if start > 1 then self:append(self.wrapper_style..(start-1)..' item(s) above\\N\\N') end

    for i=start, finish do
        self:format_line(i, self.list[i])
    end

    if overflow then self:append('\\N'..self.wrapper_style..#self.list-finish..' item(s) remaining') end
    self.ass:update()
end

--moves the selector down the list
function scroll_list:scroll_down()
    if self.selected < #self.list then
        self.selected = self.selected + 1
        self:update_ass()
    elseif self.wrap then
        self.selected = 1
        self:update_ass()
    end
end

--moves the selector up the list
function scroll_list:scroll_up()
    if self.selected > 1 then
        self.selected = self.selected - 1
        self:update_ass()
    elseif self.wrap then
        self.selected = #self.list
        self:update_ass()
    end
end

--adds the forced keybinds
function scroll_list:add_keybinds()
    for _,v in ipairs(self.keybinds) do
        mp.add_forced_key_binding(v[1], 'dynamic/'..self.ass.id..'/'..v[2], v[3], v[4])
    end
end

--removes the forced keybinds
function scroll_list:remove_keybinds()
    for _,v in ipairs(self.keybinds) do
        mp.remove_key_binding('dynamic/'..self.ass.id..'/'..v[2])
    end
end

--opens the list and sets the hidden flag
function scroll_list:open_list()
    self.hidden = false
    if not self.flag_update then self.ass:update()
    else self.flag_update = false ; self:update_ass() end
end

--closes the list and sets the hidden flag
function scroll_list:close_list()
    self.hidden = true
    self.ass:remove()
end

--modifiable function that opens the list
function scroll_list:open()
    if self.hidden then self:add_keybinds() end
    self:open_list()
end

--modifiable function that closes the list
function scroll_list:close ()
    self:remove_keybinds()
    self:close_list()
end

--toggles the list
function scroll_list:toggle()
    if self.hidden then self:open()
    else self:close() end
end

--clears the list in-place
function scroll_list:clear()
    local i = 1
    while self.list[i] do
        self.list[i] = nil
        i = i + 1
    end
end

--added alias for ipairs(list.list) for lua 5.1
function scroll_list:ipairs()
    return ipairs(self.list)
end

--append item to the end of the list
function scroll_list:insert(item)
    self.list[#self.list + 1] = item
end

local metatable = {
    __index = function(t, key)
        if scroll_list[key] ~= nil then return scroll_list[key]
        elseif key == "__current" then return t.list[t.selected]
        elseif type(key) == "number" then return t.list[key] end
    end,
    __newindex = function(t, key, value)
        if type(key) == "number" then rawset(t.list, key, value)
        else rawset(t, key, value) end
    end,
    __scroll_list = scroll_list,
    __len = function(t) return #t.list end,
    __ipairs = function(t) return ipairs(t.list) end
}

--creates a new list object
function scroll_list:new()
    local vars
    vars = {
        ass = mp.create_osd_overlay('ass-events'),
        hidden = true,
        flag_update = true,

        header = "header \\N ----------------------------------------------",
        list = {},
        selected = 1,

        keybinds = {
            {'DOWN', 'scroll_down', function() vars:scroll_down() end, {repeatable = true}},
            {'UP', 'scroll_up', function() vars:scroll_up() end, {repeatable = true}},
            {'ESC', 'close_browser', function() vars:close() end, {}}
        }
    }
    return setmetatable(vars, metatable)
end

return scroll_list:new()
