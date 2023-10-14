------------------------------------------------------------
-- Menu visuals

local mp = require('mp')
local assdraw = require('mp.assdraw')
local Menu = assdraw.ass_new()

function Menu:new(o)
    self.__index = self
    o = o or {}
    o.selected = o.selected or 1
    o.canvas_width = o.canvas_width or 1280
    o.canvas_height = o.canvas_height or 720
    o.pos_x = o.pos_x or 0
    o.pos_y = o.pos_y or 0
    o.rect_width = o.rect_width or 320
    o.rect_height = o.rect_height or 40
    o.active_color = o.active_color or 'ffffff'
    o.inactive_color = o.inactive_color or 'aaaaaa'
    o.border_color = o.border_color or '000000'
    o.text_color = o.text_color or 'ffffff'

    return setmetatable(o, self)
end

function Menu:set_position(x, y)
    self.pos_x = x
    self.pos_y = y
end

function Menu:font_size(size)
    self:append(string.format([[{\fs%s}]], size))
end

function Menu:set_text_color(code)
    self:append(string.format("{\\1c&H%s%s%s&\\1a&H05&}", code:sub(5, 6), code:sub(3, 4), code:sub(1, 2)))
end

function Menu:set_border_color(code)
    self:append(string.format("{\\3c&H%s%s%s&}", code:sub(5, 6), code:sub(3, 4), code:sub(1, 2)))
end

function Menu:apply_text_color()
    self:set_border_color(self.border_color)
    self:set_text_color(self.text_color)
end

function Menu:apply_rect_color(i)
    self:set_border_color(self.border_color)
    if i == self.selected then
        self:set_text_color(self.active_color)
    else
        self:set_text_color(self.inactive_color)
    end
end

function Menu:draw_text(i)
    local padding = 5
    local font_size = 25

    self:new_event()
    self:pos(self.pos_x + padding, self.pos_y + self.rect_height * (i - 1) + padding)
    self:font_size(font_size)
    self:apply_text_color(i)
    self:append(self.items[i])
end

function Menu:draw_item(i)
    self:new_event()
    self:pos(self.pos_x, self.pos_y)
    self:apply_rect_color(i)
    self:draw_start()
    self:rect_cw(0, 0 + (i - 1) * self.rect_height, self.rect_width, i * self.rect_height)
    self:draw_stop()
    self:draw_text(i)
end

function Menu:draw()
    self.text = ''
    for i, _ in ipairs(self.items) do
        self:draw_item(i)
    end

    mp.set_osd_ass(self.canvas_width, self.canvas_height, self.text)
end

function Menu:erase()
    mp.set_osd_ass(self.canvas_width, self.canvas_height, '')
end

function Menu:up()
    self.selected = self.selected - 1
    if self.selected == 0 then
        self.selected = #self.items
    end
    self:draw()
end

function Menu:down()
    self.selected = self.selected + 1
    if self.selected > #self.items then
        self.selected = 1
    end
    self:draw()
end

return Menu
