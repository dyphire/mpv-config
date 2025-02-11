local mp = require 'mp'
local utils = require 'mp.utils'
local assdraw = require 'mp.assdraw'

-- create namespace with default values
local em = {

  -- customisable values ------------------------------------------------------

  loop_when_navigating = false,          -- Loop when navigating through list
  lines_to_show = 17,                    -- NOT including search line
  pause_on_open = true,
  resume_on_exit = "only-if-was-paused", -- another possible value is true

  -- styles (earlyer it was a table, but required many more steps to pass def-s
  --            here from .conf file)
  font_size = 21,
  --font size scales by window
  scale_by_window = false,
  -- cursor 'width', useful to change if you have hidpi monitor
  cursor_x_border = 0.3,
  line_bottom_margin = 1, -- basically space between lines
  text_color = {
    default = 'ffffff',
    accent = 'd8a07b',
    current = 'aaaaaa',
    comment = '636363',
  },
  menu_x_padding = 5, -- this padding for now applies only to 'left', not x
  menu_y_padding = 2, -- but this one applies to both - top & bottom


  -- values that should be passed from main script ----------------------------

  search_heading = 'Default search heading',
  -- 'full' is required from main script, 'current_i' is optional
  -- others are 'private'
  list = {
    full = {}, filtered = {}, current_i = nil, pointer_i = 1, show_from_to = {}
  },
  -- field to compare with when searching for 'current value' by 'current_i'
  index_field = 'index',
  -- fields to use when searching for string match / any other custom searching
  -- if value has 0 length, then search list item itself
  filter_by_fields = {},


  -- 'private' values that are not supposed to be changed from the outside ----

  is_active = false,
  -- https://mpv.io/manual/master/#lua-scripting-mp-create-osd-overlay(format)
  ass = mp.create_osd_overlay("ass-events"),
  was_paused = false, -- flag that indicates that vid was paused by this script

  line = '',
  -- if there was no cursor it wouldn't have been needed, but for now we need
  -- variable below only to compare it with 'line' and see if we need to filter
  prev_line = '',
  cursor = 1,
  history = {},
  history_pos = 1,
  key_bindings = {},
  insert_mode = false,

  -- used only in 'update' func to get error text msgs
  error_codes = {
    no_match = 'Match required',
    no_submit_provided = 'No submit function provided'
  }
}

-- PRIVATE METHODS ------------------------------------------------------------

local ime_active = mp.get_property_native("input-ime")

-- declare constructor function
function em:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  -- some options might be customised by user in .conf file and read as strings
  -- in that case parse those
  if type(o.filter_by_fields) == 'string' then
    o.filter_by_fields = utils.parse_json(o.filter_by_fields)
  end

  if type(o.text_color) == 'string' then
    o.text_color = utils.parse_json(o.text_color)
  end

  return o
end

-- this func is just a getter of a current list depending on search line
function em:current()
  return self.line == '' and self.list.full or self.list.filtered
end

-- REVIEW: how to get rid of this wrapper and handle filter func sideeffects
-- in a more elegant way?
function em:filter_wrapper()
  -- handles sideeffect that are needed to be run on filtering list
  -- cuz the filter func may be redefined in main script and therefore needs
  -- to be straight forward - only doing filtering and returning the table

  -- passing current query just in case, so ppl can use it in their custom funcs
  self.list.filtered = self:filter(self.line)

  self.prev_line = self.line
  self.list.pointer_i = 1
  self:set_from_to(true)
end

function em:set_from_to(reset_flag)
  -- additional variables just for shorter var name
  local i = self.list.pointer_i
  local to_show = self.lines_to_show
  local total = #self:current()

  if reset_flag or to_show >= total then
    self.list.show_from_to = { 1, math.min(to_show, total) }
    return
  end

  -- If menu is opened with something already selected we want this 'selected'
  -- to be displayed close to the middle of the menu. That's why 'show_from_to'
  -- is not initially set, so we can know - if show_from_to length is 0 - it is
  -- first call of this func in cur. init
  if #self.list.show_from_to == 0 then
    -- set show_from_to so chosen item will be displayed close to middle
    local half_list = math.ceil(to_show / 2)
    if i < half_list then
      self.list.show_from_to = { 1, to_show }
    elseif total - i < half_list then
      self.list.show_from_to = { total - to_show + 1, total }
    else
      self.list.show_from_to = { i - half_list + 1, i - half_list + to_show }
    end
  else
    table.unpack = table.unpack or unpack -- 5.1 compatibility
    local first, last = table.unpack(self.list.show_from_to)

    -- handle cursor moving towards start / end bondary
    if first ~= 1 and i - first < 2 then
      self.list.show_from_to = { first - 1, last - 1 }
    end
    if last ~= total and last - i < 2 then
      self.list.show_from_to = { first + 1, last + 1 }
    end

    -- handle index jumps from beginning to end and backwards
    if i > last then
      self.list.show_from_to = { i - to_show + 1, i }
    end
    if i < first then self.list.show_from_to = { 1, to_show } end
  end
end

function em:change_selected_index(num)
  self.list.pointer_i = self.list.pointer_i + num
  if self.loop_when_navigating then
    if self.list.pointer_i < 1 then
      self.list.pointer_i = #self:current()
    elseif self.list.pointer_i > #self:current() then
      self.list.pointer_i = 1
    end
  else
    if self.list.pointer_i < 1 then
      self.list.pointer_i = 1
    elseif self.list.pointer_i > #self:current() then
      self.list.pointer_i = #self:current()
    end
  end
  self:set_from_to()
  self:update()
end

-- Render the REPL and console as an ASS OSD
function em:update(err_code)
  -- ASS tags documentation here - https://aegi.vmoe.info/docs/3.0/ASS_Tags/

  -- do not bother if function was called to close the menu..
  if not self.is_active then
    em.ass:remove()
    return
  end

  local line_height = self.font_size + self.line_bottom_margin
  local _, h, aspect = mp.get_osd_size()
  local wh = self.scale_by_window and 720 or h
  local ww = wh * aspect

  -- '+ 1' below is a search string
  local menu_y_pos =
      wh - (line_height * (self.lines_to_show + 1) + self.menu_y_padding * 2)

  -- didn't find better place to handle filtered list update
  if self.line ~= self.prev_line then self:filter_wrapper() end

  local function get_background()
    local a = self:ass_new_wrapper()
    a:append('{\\1c&H1c1c1c\\1a&H19}') -- background color & opacity
    a:pos(0, 0)
    a:draw_start()
    a:rect_cw(0, menu_y_pos, ww, wh)
    a:draw_stop()
    return a.text
  end

  local function get_search_header()
    local a = self:ass_new_wrapper()

    a:pos(self.menu_x_padding, menu_y_pos + self.menu_y_padding)

    local search_prefix = table.concat({
      self:get_font_color('accent'),
      (#self:current() ~= 0 and self.list.pointer_i or '!'),
      '/', #self:current(), '\\h\\h', self.search_heading, ':\\h'
    });

    a:append(search_prefix)
    -- reset font color after search prefix
    a:append(self:get_font_color 'default')

    -- Create the cursor glyph as an ASS drawing. ASS will draw the cursor
    -- inline with the surrounding text, but it sets the advance to the width
    -- of the drawing. So the cursor doesn't affect layout too much, make it as
    -- thin as possible and make it appear to be 1px wide by giving it 0.5px
    -- horizontal borders.
    local cheight = self.font_size * 8
    -- TODO: maybe do it using draw_rect from ass?
    local cglyph = '{\\r' ..                                   -- styles reset
        '\\1c&Hffffff&\\3c&Hffffff' ..                         -- font color and border color
        '\\xbord' .. self.cursor_x_border .. '\\p4\\pbo24}' .. -- xborder, scale x8 and baseline offset
        'm 0 0 l 0 ' .. cheight ..                             -- drawing just a line
        '{\\p0\\r}'                                            -- finish drawing and reset styles
    local before_cur = self:ass_escape(self.line:sub(1, self.cursor - 1))
    local after_cur = self:ass_escape(self.line:sub(self.cursor))

    a:append(table.concat({
      before_cur, cglyph, self:reset_styles(),
      self:get_font_color('default'), after_cur,
      (err_code and '\\h' .. self.error_codes[err_code] or "")
    }))

    return a.text

    -- NOTE: perhaps this commented code will some day help me in coding cursor
    -- like in M-x emacs menu:
    -- Redraw the cursor with the REPL text invisible. This will make the
    -- cursor appear in front of the text.
    -- ass:new_event()
    -- ass:an(1)
    -- ass:append(style .. '{\\alpha&HFF&}> ' .. before_cur)
    -- ass:append(cglyph)
    -- ass:append(style .. '{\\alpha&HFF&}' .. after_cur)
  end

  local function get_list()
    local a = assdraw.ass_new()

    local function apply_highlighting(y)
      a:new_event()
      a:append(self:reset_styles())
      a:append('{\\1c&Hffffff\\1a&HE6}') -- background color & opacity
      a:pos(0, 0)
      a:draw_start()
      a:rect_cw(0, y, ww, y + self.font_size)
      a:draw_stop()
    end

    -- REVIEW: maybe make another function 'get_line_str' and move there
    -- everything from this for loop?
    -- REVIEW: how to use something like table.unpack below?
    for i = self.list.show_from_to[1], self.list.show_from_to[2] do
      local value = assert(self:current()[i], 'no value with index ' .. i)
      local y_offset = menu_y_pos + self.menu_y_padding +
          (line_height * (i - self.list.show_from_to[1] + 1))

      if i == self.list.pointer_i then apply_highlighting(y_offset) end

      a:new_event()
      a:append(self:reset_styles())
      a:pos(self.menu_x_padding, y_offset)
      a:append(self:get_line(i, value))
    end

    return a.text
  end

  em.ass.res_x = ww
  em.ass.res_y = wh
  em.ass.data = table.concat({
    get_background(),
    get_search_header(),
    get_list()
  }, "\n")

  em.ass:update()
end

-- params:
--  - data : {list: {}, [current_i] : num}
function em:init(data)
  self.list.full = data.list or {}
  self.list.current_i = data.current_i or nil
  self.list.pointer_i = data.current_i or 1
  self:set_active(true)
end

function em:exit()
  self:undefine_key_bindings()
  collectgarbage()
end

-- TODO: write some idle func like this
-- function idle()
--     if pending_selection then
--         gallery:set_selection(pending_selection)
--         pending_selection = nil
--     end
--     if ass_changed or geometry_changed then
--         local ww, wh = mp.get_osd_size()
--         if geometry_changed then
--             geometry_changed = false
--             compute_geometry(ww, wh)
--         end
--         if ass_changed then
--             ass_changed = false
--             mp.set_osd_ass(ww, wh, ass)
--         end
--     end
-- end
-- ...
-- and handle it as follows
-- init():
-- mp.register_idle(idle)
-- idle()
-- exit():
-- mp.unregister_idle(idle)
-- idle()
-- And in these observers he is setting a flag, that's being checked in func above
-- mp.observe_property("osd-width", "native", mark_geometry_stale)
-- mp.observe_property("osd-height", "native", mark_geometry_stale)

-- PRIVATE METHODS END --------------------------------------------------------

-- PUBLIC METHODS -------------------------------------------------------------

function em:filter()
  -- default filter func, might be redefined in main script
  local result = {}

  local function get_full_search_str(v)
    local str = ''
    for _, key in ipairs(self.filter_by_fields) do str = str .. (v[key] or '') end
    return str
  end

  for _, v in ipairs(self.list.full) do
    -- if filter_by_fields has 0 length, then search list item itself
    if #self.filter_by_fields == 0 then
      if self:search_method(v) then table.insert(result, v) end
    else
      -- NOTE: we might use search_method on fiels separately like this:
      -- for _,key in ipairs(self.filter_by_fields) do
      --   if self:search_method(v[key]) then table.insert(result, v) end
      -- end
      -- But since im planning to implement fuzzy search in future i need full
      -- search string here
      if self:search_method(get_full_search_str(v)) then
        table.insert(result, v)
      end
    end
  end
  return result
end

-- TODO: implement fuzzy search and maybe match highlights
function em:search_method(str)
  -- also might be redefined by main script

  -- convert to string just to make sure..
  return tostring(str):lower():find(self.line:lower(), 1, true)
end

-- this module requires submit function to be defined in main script
function em:submit() self:update('no_submit_provided') end

function em:update_list(list)
  -- for now this func doesn't handle cases when we have 'current_i' to update
  -- it
  self.list.full = list
  if self.line ~= self.prev_line then self:filter_wrapper() end
end

-- PUBLIC METHODS END ---------------------------------------------------------

-- HELPER METHODS -------------------------------------------------------------

function em:get_line(_, v) -- [i]ndex, [v]alue
  -- this func might be redefined in main script to get a custom-formatted line
  -- default implementation of this func supposes that value.content field is a
  -- String
  local a = assdraw.ass_new()
  local style = (self.list.current_i == v[self.index_field])
      and 'current' or 'default'

  a:append(self:reset_styles())
  a:append(self:get_font_color(style))
  -- content as default field, which is holding string
  -- no point in moving it to main object since content itself is being
  -- composed in THIS function, that might (and most likely, should) be
  -- redefined in main script
  a:append(v.content or 'Something is off in `get_line` func')
  return a.text
end

-- REVIEW: for now i don't see normal way of mergin this func with below one
-- but it's being used only once
function em:reset_styles()
  local a = assdraw.ass_new()
  -- alignment top left, no word wrapping, border 0, shadow 0
  a:append('{\\an7\\q2\\bord0\\shad0}')
  a:append('{\\fs' .. self.font_size .. '}')
  return a.text
end

-- function to get rid of some copypaste
function em:ass_new_wrapper()
  local a = assdraw.ass_new()
  a:new_event()
  a:append(self:reset_styles())
  return a
end

function em:get_font_color(style)
  return '{\\1c&H' .. self.text_color[style] .. '}'
end

-- HELPER METHODS END ---------------------------------------------------------


--[[
  The below code is a modified implementation of text input from mpv's console.lua:
  https://github.com/mpv-player/mpv/blob/87c9eefb2928252497f6141e847b74ad1158bc61/player/lua/console.lua

  I was too lazy to list all modifications i've done to the script, but if u
  rly need to see those - do diff with the original code
]]
   --

-------------------------------------------------------------------------------
--                          START ORIGINAL MPV CODE                          --
-------------------------------------------------------------------------------

-- Copyright (C) 2019 the mpv developers
--
-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
-- SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
-- OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
-- CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

function em:detect_platform()
  local o = {}
  -- Kind of a dumb way of detecting the platform but whatever
  if mp.get_property_native('options/vo-mmcss-profile', o) ~= o then
    return 'windows'
  elseif mp.get_property_native('options/macos-force-dedicated-gpu', o) ~= o then
    return 'macos'
  elseif os.getenv('WAYLAND_DISPLAY') then
    return 'wayland'
  end
  return 'x11'
end

-- Escape a string for verbatim display on the OSD
function em:ass_escape(str)
  -- There is no escape for '\' in ASS (I think?) but '\' is used verbatim if
  -- it isn't followed by a recognised character, so add a zero-width
  -- non-breaking space
  str = str:gsub('\\', '\\\239\187\191')
  str = str:gsub('{', '\\{')
  str = str:gsub('}', '\\}')
  -- Precede newlines with a ZWNBSP to prevent ASS's weird collapsing of
  -- consecutive newlines
  str = str:gsub('\n', '\239\187\191\\N')
  -- Turn leading spaces into hard spaces to prevent ASS from stripping them
  str = str:gsub('\\N ', '\\N\\h')
  str = str:gsub('^ ', '\\h')
  return str
end

-- Set the REPL visibility ("enable", Esc)
function em:set_active(active)
  if active == self.is_active then return end
  if active then
    if ime_active == false then
      mp.set_property_bool("input-ime", true)
    end
    self.is_active = true
    self.insert_mode = false
    mp.enable_messages('terminal-default')
    self:define_key_bindings()

    -- set flag 'was_paused' only if vid wasn't paused before EM init
    if self.pause_on_open and not mp.get_property_bool("pause", false) then
      mp.set_property_bool("pause", true)
      self.was_paused = true
    end

    self:set_from_to()
    self:update()
  else
    -- no need to call 'update' in this block cuz 'clear' method is calling it
    if ime_active == false then
      mp.set_property_bool("input-ime", false)
    end
    self.is_active = false
    self:undefine_key_bindings()

    if self.resume_on_exit == true or
        (self.resume_on_exit == "only-if-was-paused" and self.was_paused) then
      mp.set_property_bool("pause", false)
    end

    self:clear()
    collectgarbage()
  end
end

-- Naive helper function to find the next UTF-8 character in 'str' after 'pos'
-- by skipping continuation bytes. Assumes 'str' contains valid UTF-8.
function em:next_utf8(str, pos)
  if pos > str:len() then return pos end
  repeat
    pos = pos + 1
  until pos > str:len() or str:byte(pos) < 0x80 or str:byte(pos) > 0xbf
  return pos
end

-- As above, but finds the previous UTF-8 charcter in 'str' before 'pos'
function em:prev_utf8(str, pos)
  if pos <= 1 then return pos end
  repeat
    pos = pos - 1
  until pos <= 1 or str:byte(pos) < 0x80 or str:byte(pos) > 0xbf
  return pos
end

-- Insert a character at the current cursor position (any_unicode)
function em:handle_char_input(c)
  if self.insert_mode then
    self.line = self.line:sub(1, self.cursor - 1) .. c .. self.line:sub(self:next_utf8(self.line, self.cursor))
  else
    self.line = self.line:sub(1, self.cursor - 1) .. c .. self.line:sub(self.cursor)
  end
  self.cursor = self.cursor + #c
  self:update()
end

-- Remove the character behind the cursor (Backspace)
function em:handle_backspace()
  if self.cursor <= 1 then return end
  local prev = self:prev_utf8(self.line, self.cursor)
  self.line = self.line:sub(1, prev - 1) .. self.line:sub(self.cursor)
  self.cursor = prev
  self:update()
end

-- Remove the character in front of the cursor (Del)
function em:handle_del()
  if self.cursor > self.line:len() then return end
  self.line = self.line:sub(1, self.cursor - 1) .. self.line:sub(self:next_utf8(self.line, self.cursor))
  self:update()
end

-- Toggle insert mode (Ins)
function em:handle_ins()
  self.insert_mode = not self.insert_mode
end

-- Move the cursor to the next character (Right)
function em:next_char()
  self.cursor = self:next_utf8(self.line, self.cursor)
  self:update()
end

-- Move the cursor to the previous character (Left)
function em:prev_char()
  self.cursor = self:prev_utf8(self.line, self.cursor)
  self:update()
end

-- Clear the current line (Ctrl+C)
function em:clear()
  self.line = ''
  self.prev_line = ''

  self.list.current_i = nil
  self.list.pointer_i = 1
  self.list.filtered = {}
  self.list.show_from_to = {}

  self.was_paused = false

  self.cursor = 1
  self.insert_mode = false
  self.history_pos = #self.history + 1

  self:update()
end

-- Run the current command and clear the line (Enter)
function em:handle_enter()
  if #self:current() == 0 then
    self:update('no_match')
    return
  end

  if self.history[#self.history] ~= self.line then
    self.history[#self.history + 1] = self.line
  end

  self:submit(self:current()[self.list.pointer_i])
  self:set_active(false)
end

-- Go to the specified position in the command history
function em:go_history(new_pos)
  local old_pos = self.history_pos
  self.history_pos = new_pos

  -- Restrict the position to a legal value
  if self.history_pos > #self.history + 1 then
    self.history_pos = #self.history + 1
  elseif self.history_pos < 1 then
    self.history_pos = 1
  end

  -- Do nothing if the history position didn't actually change
  if self.history_pos == old_pos then
    return
  end

  -- If the user was editing a non-history line, save it as the last history
  -- entry. This makes it much less frustrating to accidentally hit Up/Down
  -- while editing a line.
  if old_pos == #self.history + 1 and self.line ~= '' and self.history[#self.history] ~= self.line then
    self.history[#self.history + 1] = self.line
  end

  -- Now show the history line (or a blank line for #history + 1)
  if self.history_pos <= #self.history then
    self.line = self.history[self.history_pos]
  else
    self.line = ''
  end
  self.cursor = self.line:len() + 1
  self.insert_mode = false
  self:update()
end

-- Go to the specified relative position in the command history (Up, Down)
function em:move_history(amount)
  self:go_history(self.history_pos + amount)
end

-- Go to the first command in the command history (PgUp)
function em:handle_pgup()
  -- Determine the number of items to move up (half a page)
  local half_page = math.ceil(self.lines_to_show / 2)

  -- Move the history position up by half a page
  self:change_selected_index(-half_page)
end

-- Stop browsing history and start editing a blank line (PgDown)
function em:handle_pgdown()
  -- Determine the number of items to move down (half a page)
  local half_page = math.ceil(self.lines_to_show / 2)

  -- Move the history position down by half a page
  self:change_selected_index(half_page)
end

-- Move to the start of the current word, or if already at the start, the start
-- of the previous word. (Ctrl+Left)
function em:prev_word()
  -- This is basically the same as next_word() but backwards, so reverse the
  -- string in order to do a "backwards" find. This wouldn't be as annoying
  -- to do if Lua didn't insist on 1-based indexing.
  self.cursor = self.line:len() - select(2, self.line:reverse():find('%s*[^%s]*', self.line:len() - self.cursor + 2)) + 1
  self:update()
end

-- Move to the end of the current word, or if already at the end, the end of
-- the next word. (Ctrl+Right)
function em:next_word()
  self.cursor = select(2, self.line:find('%s*[^%s]*', self.cursor)) + 1
  self:update()
end

-- Move the cursor to the beginning of the line (HOME)
function em:go_home()
  self.cursor = 1
  self:update()
end

-- Move the cursor to the end of the line (END)
function em:go_end()
  self.cursor = self.line:len() + 1
  self:update()
end

-- Delete from the cursor to the beginning of the word (Ctrl+Backspace)
function em:del_word()
  local before_cur = self.line:sub(1, self.cursor - 1)
  local after_cur = self.line:sub(self.cursor)

  before_cur = before_cur:gsub('[^%s]+%s*$', '', 1)
  self.line = before_cur .. after_cur
  self.cursor = before_cur:len() + 1
  self:update()
end

-- Delete from the cursor to the end of the word (Ctrl+Del)
function em:del_next_word()
  if self.cursor > self.line:len() then return end

  local before_cur = self.line:sub(1, self.cursor - 1)
  local after_cur = self.line:sub(self.cursor)

  after_cur = after_cur:gsub('^%s*[^%s]+', '', 1)
  self.line = before_cur .. after_cur
  self:update()
end

-- Delete from the cursor to the end of the line (Ctrl+K)
function em:del_to_eol()
  self.line = self.line:sub(1, self.cursor - 1)
  self:update()
end

-- Delete from the cursor back to the start of the line (Ctrl+U)
function em:del_to_start()
  self.line = self.line:sub(self.cursor)
  self.cursor = 1
  self:update()
end

-- Returns a string of UTF-8 text from the clipboard (or the primary selection)
function em:get_clipboard(clip)
  -- Pick a better default font for Windows and macOS
  local platform = self:detect_platform()

  if platform == 'x11' then
    local res = utils.subprocess({
      args = { 'xclip', '-selection', clip and 'clipboard' or 'primary', '-out' },
      playback_only = false,
    })
    if not res.error then
      return res.stdout
    end
  elseif platform == 'wayland' then
    local res = utils.subprocess({
      args = { 'wl-paste', clip and '-n' or '-np' },
      playback_only = false,
    })
    if not res.error then
      return res.stdout
    end
  elseif platform == 'windows' then
    local res = utils.subprocess({
      args = { 'powershell', '-NoProfile', '-Command', [[& {
                Trap {
                    Write-Error -ErrorRecord $_
                    Exit 1
                }

                $clip = ""
                if (Get-Command "Get-Clipboard" -errorAction SilentlyContinue) {
                    $clip = Get-Clipboard -Raw -Format Text -TextFormatType UnicodeText
                } else {
                    Add-Type -AssemblyName PresentationCore
                    $clip = [Windows.Clipboard]::GetText()
                }

                $clip = $clip -Replace "`r",""
                $u8clip = [System.Text.Encoding]::UTF8.GetBytes($clip)
                [Console]::OpenStandardOutput().Write($u8clip, 0, $u8clip.Length)
            }]] },
      playback_only = false,
    })
    if not res.error then
      return res.stdout
    end
  elseif platform == 'macos' then
    local res = utils.subprocess({
      args = { 'pbpaste' },
      playback_only = false,
    })
    if not res.error then
      return res.stdout
    end
  end
  return ''
end

-- Paste text from the window-system's clipboard. 'clip' determines whether the
-- clipboard or the primary selection buffer is used (on X11 and Wayland only.)
function em:paste(clip)
  local text = self:get_clipboard(clip)
  local before_cur = self.line:sub(1, self.cursor - 1)
  local after_cur = self.line:sub(self.cursor)
  self.line = before_cur .. text .. after_cur
  self.cursor = self.cursor + text:len()
  self:update()
end

-- List of input bindings. This is a weird mashup between common GUI text-input
-- bindings and readline bindings.
function em:get_bindings()
  local bindings = {
    { 'ctrl+[',      function() self:set_active(false) end },
    { 'ctrl+g',      function() self:set_active(false) end },
    { 'esc',         function() self:set_active(false) end },
    { 'enter',       function() self:handle_enter() end },
    { 'kp_enter',    function() self:handle_enter() end },
    { 'ctrl+m',      function() self:handle_enter() end },
    { 'bs',          function() self:handle_backspace() end },
    { 'shift+bs',    function() self:handle_backspace() end },
    { 'ctrl+h',      function() self:handle_backspace() end },
    { 'del',         function() self:handle_del() end },
    { 'shift+del',   function() self:handle_del() end },
    { 'ins',         function() self:handle_ins() end },
    { 'shift+ins',   function() self:paste(false) end },
    { 'mbtn_mid',    function() self:paste(false) end },
    { 'left',        function() self:prev_char() end },
    { 'ctrl+b',      function() self:prev_char() end },
    { 'right',       function() self:next_char() end },
    { 'ctrl+f',      function() self:next_char() end },
    { 'ctrl+k',      function() self:change_selected_index(-1) end },
    { 'ctrl+p',      function() self:change_selected_index(-1) end },
    { 'ctrl+j',      function() self:change_selected_index(1) end },
    { 'ctrl+n',      function() self:change_selected_index(1) end },
    { 'up',          function() self:move_history(-1) end },
    { 'alt+p',       function() self:move_history(-1) end },
    { 'wheel_up',    function() self:move_history(-1) end },
    { 'down',        function() self:move_history(1) end },
    { 'alt+n',       function() self:move_history(1) end },
    { 'wheel_down',  function() self:move_history(1) end },
    { 'wheel_left',  function() end },
    { 'wheel_right', function() end },
    { 'ctrl+left',   function() self:prev_word() end },
    { 'alt+b',       function() self:prev_word() end },
    { 'ctrl+right',  function() self:next_word() end },
    { 'alt+f',       function() self:next_word() end },
    { 'ctrl+a',      function() self:go_home() end },
    { 'home',        function() self:go_home() end },
    { 'ctrl+e',      function() self:go_end() end },
    { 'end',         function() self:go_end() end },
    { 'ctrl+shift+f',function() self:handle_pgdown() end },
    { 'ctrl+shift+b',function() self:handle_pgup() end },
    { 'pgdwn',       function() self:handle_pgdown() end },
    { 'pgup',        function() self:handle_pgup() end },
    { 'ctrl+c',      function() self:clear() end },
    { 'ctrl+d',      function() self:handle_del() end },
    { 'ctrl+u',      function() self:del_to_start() end },
    { 'ctrl+v',      function() self:paste(true) end },
    { 'meta+v',      function() self:paste(true) end },
    { 'ctrl+bs',     function() self:del_word() end },
    { 'ctrl+w',      function() self:del_word() end },
    { 'ctrl+del',    function() self:del_next_word() end },
    { 'alt+d',       function() self:del_next_word() end },
    { 'kp_dec',      function() self:handle_char_input('.') end },
  }

  for i = 0, 9 do
    bindings[#bindings + 1] =
    { 'kp' .. i, function() self:handle_char_input('' .. i) end }
  end

  return bindings
end

function em:text_input(info)
  if info.key_text and (info.event == "press" or info.event == "down"
        or info.event == "repeat")
  then
    self:handle_char_input(info.key_text)
  end
end

function em:define_key_bindings()
  if #self.key_bindings > 0 then
    return
  end
  for _, bind in ipairs(self:get_bindings()) do
    -- Generate arbitrary name for removing the bindings later.
    local name = "search_" .. (#self.key_bindings + 1)
    self.key_bindings[#self.key_bindings + 1] = name
    mp.add_forced_key_binding(bind[1], name, bind[2], { repeatable = true })
  end
  mp.add_forced_key_binding("any_unicode", "search_input", function(...)
    self:text_input(...)
  end, { repeatable = true, complex = true })
  self.key_bindings[#self.key_bindings + 1] = "search_input"
end

function em:undefine_key_bindings()
  for _, name in ipairs(self.key_bindings) do
    mp.remove_key_binding(name)
  end
  self.key_bindings = {}
end

-------------------------------------------------------------------------------
--                           END ORIGINAL MPV CODE                           --
-------------------------------------------------------------------------------

return em
