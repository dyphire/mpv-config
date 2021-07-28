--   A script to save screenshots in different
--   locations based on whatever conditions.
--   Requires lua knowledge or some will to experiment.

local utils = require 'mp.utils'
local msg = require 'mp.msg'

local settings = {
  basepath = mp.get_property('screenshot-directory'),
  basetemplate = mp.get_property('screenshot-template'),

  --the command to creating your custom directory without the path
  createdir = { 'mkdir', '-p' }, 

  --patterns are in priority order, first match will be used for screenshot
  --about patterns in lua: http://lua-users.org/wiki/PatternsTutorial and https://www.lua.org/pil/20.2.html
  --about strings in lua: http://lua-users.org/wiki/StringLibraryTutorial
  --useful tool to test patterns and strings: https://www.lua.org/demo.html
  patterns = {
    --you can copy paste the template below and change values to create more rules
    {
      --This rule will be applied for files containing [SubGroup] in their name
      --An example filename would be [SubGroup] Show name - 01 [720].mkv
      --screenshots will be saved in your_screenshots/Show name/Show name - 01/Show name - 01[02m25s].jpg

      --this function will be called on file load to determine whether current file is a match for these rules or not
      --return booleanish value(for if statement)
      ['match'] =
        function()
          return mp.get_property('filename/no-ext'):match('%[SubGroup%]') and true or false
        end
      ,

      --function that will return the absolute save path for files
      ['savepath'] =
        function()
          --parse filename to create directory name - note that naming conventions differ so you need to modify this
          --in this case I parse it so that files will be added in show_name/show_name_episode/
          --you can use your imagination when creating this. Having a static string will make all under this rule in same folder
          --you could even make sub folders inside episode based on duration if you wanted

          --match the show name on a known format because this rule only applies to shows formatted like this
          local head_dir = mp.get_property('filename/no-ext'):match('%]%s(.*)%s%-%s%d')

          --remove brackets for the subfolder name
          --instead of match you can also use gsub to strip parts of the filename
          local sub_dir = mp.get_property('filename/no-ext'):gsub('%s*[%[%(].-[%]%)]%s*', '')

          local relative_dir = utils.join_path(head_dir, sub_dir)

          --join and return our custom path with basepath
          return utils.join_path(mp.get_property('screenshot-directory'), relative_dir)
        end
      ,

      --if not nil then overriding default screenshot-template, will property expand
      --needs to be a function that returns the template as a string
      ['filename'] =
        function()
          --remove brackets, their content and surrounding white space from filename
          local name = mp.get_property('filename/no-ext'):gsub('%s*[%[%(].-[%]%)]%s*', '')
          return name.."[%wMm%wSs]" --add property expanding part
        end
      , 
    },
  }
}

local state = {
  pattern = nil,
}

function on_load()
  state.pattern = nil

  for index, pattern in ipairs(settings.patterns) do
    if pattern.match() then
      state.pattern = pattern
      break
    end
  end
end

function screenshot(param)
  param = (param or "")
  if state.pattern then
    custom_screenshot(state.pattern, param)
  else
    mp.command("screenshot "..param)
  end
end

function custom_screenshot(pattern, param)
  local savepath = pattern.savepath()

  --prepare and create/check directory
  local args = settings.createdir
  table.insert(args, savepath)
  res = utils.subprocess({ args = args })

  if not res.error and res.status == 0 then

    --set temporary screenshot settings
    if pattern.filename then
      mp.set_property('screenshot-template', pattern.filename())
    end
    mp.set_property("screenshot-directory", savepath)

    --take the screenshot
    mp.command("screenshot "..param)

    --reset screenshot settings
    mp.set_property("screenshot-directory", settings.basepath)
    mp.set_property("screenshot-template", settings.basetemplate)

  else
    msg.error("Failed to create directory "..savepath)
    msg.error("Status: "..(res.status or "unknown"))
    msg.error("Error: "..(res.error or "unknown"))
  end
end

mp.register_script_message("custom-screenshot", screenshot)
mp.register_event('file-loaded', on_load)