local settings = {
  display_timeout = 5,

  loop_cursor = true,

  key_moveup = "UP WHEEL_UP",
  key_movedown = "DOWN WHEEL_DOWN",
  key_execute = "ENTER MBTN_LEFT",
  key_closemenu = "ESC MBTN_RIGHT",
}

local mp = require "mp"
local utils = require("mp.utils")
local msg = require("mp.msg")
local opts = require("mp.options")

local list = dofile(mp.command_native({"expand-path", "~~/script-modules/scroll-list.lua"}))
list.header = "菜单"

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

  list:insert({ass = item.label})
  -- TODO: assert nested commands
end

if #menu_items == 0 then
  msg.warn("Menu list is empty. The script is disabled.")
  return
end

local function execute_command(cmd)
  local def, error = mp.command_native(cmd, true)
  if def then
    msg.error('"' .. error .. '" executing command ' .. utils.format_json(cmd))
  end
end

local function execute()
  local command = menu_items[list.selected].command
  local is_nested_command = type(command[1]) == "table"

  if is_nested_command then
    for _, cmd in ipairs(command) do
      execute_command(cmd)
    end
  else
    execute_command(command)
  end

  if not menu_items[list.selected].keep_open then
    list:close()
  end
end

list.keybinds = {}

local function add_keys(keys, name, fn, flags)
  local i = 1
  for key in keys:gmatch("%S+") do
    table.insert(list.keybinds, {key, name..i, fn, flags})
    i = i + 1
  end
end

add_keys(settings.key_moveup, 'moveup', function() list:scroll_up() end, {repeatable = true})
add_keys(settings.key_movedown, 'movedown', function() list:scroll_down() end, {repeatable = true})
add_keys(settings.key_execute, 'execute', execute, {})
add_keys(settings.key_closemenu, 'closemenu', function() list:close() end, {})

mp.register_script_message("simplemenu-toggle", function() list:toggle() end)
