local settings = {
  display_timeout = 5,

  loop_cursor = true,

  key_moveup = "UP WHEEL_UP",
  key_movedown = "DOWN WHEEL_DOWN",
  key_execute = "ENTER MBTN_MID",
  key_closemenu = "ESC MBTN_RIGHT",
}

local utils = require("mp.utils")
local msg = require("mp.msg")
local assdraw = require("mp.assdraw")
local opts = require("mp.options")
opts.read_options(settings, "simplemenu")

local file = assert(io.open(mp.command_native({"expand-path", "~~/script-opts"}) .. "/menu.json"))
local json = file:read("*all")
file:close()
local menu_items = utils.parse_json(json)

if menu_items == nil then
  error("Invalid JSON format in menu.json. Please run it through a linter. The script is disabled.")
end

for _, item in pairs(menu_items) do
  local command_type = type(item.command)
  assert(
    command_type == "table",
    "Unexpected command type for \""..item.label.."\". Expected table, received "..command_type
  )
  -- TODO: assert nested commands
end

if #menu_items == 0 then
  msg.warn("Menu list is empty. The script is disabled.")
end

local menu_size = #menu_items
local menu_visible = false
local cursor = 1

function execute()
  local command = menu_items[cursor].command
  local is_nested_command = type(command[1]) == "table"

  if is_nested_command then
    for _, cmd in ipairs(command) do
      mp.command_native(cmd)
    end
  else
    mp.command_native(command)
  end

  if menu_items[cursor].keep_open then
    render()
  else
    remove_keybinds()
  end
end

function toggle_menu()
  if menu_visible then
    remove_keybinds()
    return
  end
  render()
end

function render()
  local font_size = mp.get_property("osd-font-size")

  local ass = assdraw.ass_new()
  ass:new_event()
  ass:pos(30, 15)

  local settings = {
    selected_color = "{\\1c&HFFFFFF}",
    list_color = "{\\1c&H46CFFF}",
  }
  for index, item in ipairs(menu_items) do
    local selected = index == cursor
    local prefix = selected and "⚫ " or "⚪ "
    local prefixcolor = selected and settings.selected_color or settings.list_color
    ass:append(prefixcolor .. prefix .. item.label .. "\\N")
  end

  local w, h = mp.get_osd_size()
  mp.set_osd_ass(w, h, ass.text)

  menu_visible = true
  add_keybinds()
  keybindstimer:kill()
  keybindstimer:resume()
end

function moveup()
  if cursor ~= 1 then
    cursor = cursor - 1
  elseif settings.loop_cursor then
    cursor = menu_size
  end
  render()
end

function movedown()
  if cursor ~= menu_size then
    cursor = cursor + 1
  elseif settings.loop_cursor then
    cursor = 1
  end
  render()
end

function bind_keys(keys, name, func, opts)
  if not keys then
    mp.add_forced_key_binding(keys, name, func, opts)
    return
  end
  local i = 1
  for key in keys:gmatch("[^%s]+") do
    local prefix = i == 1 and '' or i
    mp.add_forced_key_binding(key, name..prefix, func, opts)
    i = i + 1
  end
end

function unbind_keys(keys, name)
  if not keys then
    mp.remove_key_binding(name)
    return
  end
  local i = 1
  for key in keys:gmatch("[^%s]+") do
    local prefix = i == 1 and '' or i
    mp.remove_key_binding(name..prefix)
    i = i + 1
  end
end

function add_keybinds()
  bind_keys(settings.key_moveup, 'simplemenu-moveup', moveup, "repeatable")
  bind_keys(settings.key_movedown, 'simplemenu-movedown', movedown, "repeatable")
  bind_keys(settings.key_execute, 'simplemenu-execute', execute)
  bind_keys(settings.key_closemenu, 'simplemenu-closemenu', remove_keybinds)
end

function remove_keybinds()
  keybindstimer:kill()
  menu_visible = false
  mp.set_osd_ass(0, 0, "")
  unbind_keys(settings.key_moveup, 'simplemenu-moveup')
  unbind_keys(settings.key_movedown, 'simplemenu-movedown')
  unbind_keys(settings.key_execute, 'simplemenu-execute')
  unbind_keys(settings.key_closemenu, 'simplemenu-closemenu')
end

keybindstimer = mp.add_periodic_timer(settings.display_timeout, remove_keybinds)
keybindstimer:kill()

if menu_items and menu_size > 0 then
  mp.register_script_message("simplemenu-toggle", toggle_menu)
  mp.add_key_binding("MBTN_MID", "simplemenu-toggle", toggle_menu)
end