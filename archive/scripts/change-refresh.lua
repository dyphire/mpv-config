--[[
    This script uses nircmd to change the refresh rate of the display that the mpv window is currently open in
    This was written because I could not get autospeedwin to work :(

    The script uses a hotkey by default, but can be setup to run on startup, see the options below for more details

    If the display does not support the specified resolution or refresh rate it will silently fail
    If the video refresh rate does not match any on the whitelist it will pick the next highest.
    If the video fps is higher tha any on the whitelist it will pick the highest available
    The whitelist is specified via the script-opt 'rates'. Valid rates are separated via semicolons, do not include spaces and list in asceding order.
        Example:    script-opts=changerefresh-rates="23;24;30;60"

    You can also set a custom display rate for individual video rates using a hyphen:
        Example:    script-opts=changerefresh-rates="23;24;25-50;30;60"
    This will change the display to 23, 24, and 30 fps when playing videos in those same rates, but will change the display to 50 fps when
    playing videos in 25 Hz

    The script will keep track of the original refresh rate of the monitor and revert when either the
    correct keybind is pressed, or when mpv exits. The original rate needs to be included on the whitelist and follows
    custom rate rules (i.e. if the monitor was originally 25Hz and the whitelist contains "25-50", then it will revert to 50)

    The script is able to find the current resolution of the monitor and will always use those dimensions when switching refresh rates,
    however I have an UHD mode (option is UHD_adaptive) hardcoded to use a resolution of 3840x2160p for videos with a height of > 1440 pixels.

    It is possible to disable automatic resolution detection and use manual values (see options below).
    The detection is done via switching to fullscreen mode and grabbing the resolution of the OSD, so it can be disabled if one finds it annoying.

    The keybind to switch refresh rates is f10 by default, but this can be changed by setting different script bindings in input.conf. All of the valid keybinds,
    their names, and their defaults are at the bottom of this script file

    You can also send refresh change commands directly using script messages:
        script-message change-refresh [width] [height] [rate] [display]

    Display stands for the display number (starting from 0) which is printed to the console when the display is changed.
    Leaving out this argument will auto-detect the currently used monitor, like the usual behaviour.

    These script messages completely bypass the whitelist and rate associations and are sent to nircmd directly, so make sure you send a valid integer.
    They are also completely independant from the usual automatic reversion system, so you'll have to handle that yourself.

    Note that if the mpv window is lying across multiple displays it may not save the original refresh rate of the correct display

    See below for the full options list, don't change the defaults manually, use script opts.
]]--

msg = require 'mp.msg'
utils = require 'mp.utils'
require 'mp.options'

--options available through --script-opts=changerefresh-[option]=value
--all of these options can be changed at runtime using profiles, the script will automatically update
local options = {
    --the location of nircmd.exe, tries to use the system path by default
    nircmd = "nircmd",

    --list of valid refresh rates, separated by semicolon, listed in ascending order
    --by adding a hyphen after a number you can set a custom display rate for that specific video rate:
    --  "23;24;25-50;60"  Will set the display to 50fps for 25fps videos
    --this whitelist also applies when attempting to revert the display, so include that rate in the list
    --nircmd only seems to work with integers, DO NOT use the full refresh rate, i.e. 23.976
    rates = "23;24;25;29;30;50;59;60",

    --change refresh automatically on startup
    auto = false,

    --duration (in seconds) of the pause when changing display modes
    --set to zero to disable video pausing
    pause = 3,

    --colour bit depth to send to nircmd
    --you shouldn't need to change this, but it's here just in case
    bdepth = "32",

    --set whether to use the estimated fps or the container fps
    --see https://mpv.io/manual/master/#command-interface-container-fps for details
    estimated_fps = false,

    --automatically detect monitor resolution when changing refresh rates
    --will use this resolution when reverting changes
    detect_display_resolution = true,

    --default width and height to use when changing & reverting the refresh rate
    --ony used if detect_display_resolution is false
    original_width = 1920,
    original_height = 1080,

    --if this value is set to anything but zero to script will always to to revert to this rate
    --this rate bypasses the usual rates whitelist, so make sure it is valid
    --the actual original rate will be ignored
    original_rate = 0,

    --if enabled, this mode sets the monitor to the specified dimensions when the resolution of the video is greater than or equal to the threshold
    --if less than the threshold the monitor will be set to the default shown above, or to the current resolution
    --this feature is only really useful if you don't want to be upscaling video to UHD, but still want to play UHD files in native resolution
    UHD_adaptive = false,
    UHD_threshold = 1440,
    UHD_width = 3840,
    UHD_height = 2160,

    --set whether to output status messages to the osd
    osd_output = true
}

local var = {
    --saved as strings
    dname = "",
    dnumber = "",

    --saved as numbers
    current_width = 0,
    current_height = 0,
    original_width = options.original_width,
    original_height = options.original_height,
    original_fps = 0,
    new_fps = 0,
    new_width = 0,
    new_height = 0,

    beenReverted = true,
    rateList = {},
    rates = {}
}

--is run whenever a change in script-opts is detected
function updateOptions(changes)
    msg.verbose('updating options')
    msg.debug(utils.to_string(changes))

    --only runs the heavy commands if the rates string has been changed
    if changes == nil or changes.rates then
        msg.verbose('rates whitelist has changed')

        checkRatesString()
        updateTable()
    end
end
read_options(options, 'changerefresh', updateOptions)

--checks if the rates string contains any invalid characters
function checkRatesString()
    local str = options.rates
    
    str = str:gsub(";", '')
    str = str:gsub("%-", '')

    if str:match("%D") then
        msg.error('Rates whitelist contains invalid characters, can only contain numbers, semicolons and hyphens. Be prepared for the script to crash')
    end
end

--creates an array of valid video rates and a map of display rates to switch to
function updateTable()
    var.rates = {}
    var.rateList = {}

    msg.verbose("updating tables of valid rates")
    for rate in string.gmatch(options.rates, "[^;]+") do
        msg.debug("found option: " .. rate)
        if rate:match("-") then
            msg.debug("contains hyphen, extracting custom rates")

            local originalRate = rate:gsub("-.*$", "")
            msg.debug("-originalRate = " .. originalRate)

            local newRate = rate:gsub(".*-", "")
            msg.debug("-customRate = " .. newRate)

            originalRate = tonumber(originalRate)
            newRate = tonumber(newRate)

            --tests for nil values caused by missing rates on either side of hyphens
            if originalRate == nil and newRate == nil then
                msg.debug('-no rates found, ignoring')
                goto loopend
            end

            if originalRate == nil then
                msg.warn("missing rate before hyphen in whitelist, ignoring option")
                goto loopend
            end
            if newRate == nil then
                msg.warn("missing rate after hyphen in whitelist for option: " .. rate)
                msg.warn("ignoring and setting " .. rate .. " to " .. originalRate)
                newRate = originalRate
            end
            var.rates[originalRate] = newRate
            rate = originalRate
        else
            rate = tonumber(rate)
            var.rates[rate] = rate
        end
        table.insert(var.rateList, rate)

        ::loopend::
    end

    if #var.rateList < 1 then
        msg.warn('rate list empty, will not be able to change refresh rate')
    end
end

--saves the current resolution of the display
--this value is only stored until the changeRefresh function returns
--this function exists because the current res information is required at different points for different commands and to find
--the res the player must switch into and out of fullscreen. Doing so multiple times would be annoying, so
--this function makes sure it will only happen once, no matter which command is sent
function setCurrentRes()
    if options.detect_display_resolution and var.current_width == 0 then
        var.current_width, var.current_height = getDisplayResolution()
    elseif var.current_width == 0 then
        var.current_width, var.current_height = options.original_width, options.original_height
    end
end

--prints osd messages if the option is enabled
function osdMessage(string)
    if options.osd_output then
        mp.osd_message(string)
    end
end

--calls nircmd to change the display resolution and rate
function changeRefresh(width, height, rate, display)
    rate = tostring(rate)
    width = tostring(width)
    height = tostring(height)
    display = tostring(display)

    setCurrentRes()

    msg.verbose('calling nircmd with command: ' .. options.nircmd .. " setdisplay monitor:" .. display .. " " .. width .. " " .. height .. " " .. options.bdepth .. " " .. rate)

    msg.info("changing display " .. display .. " to " .. width .. "x" .. height .. " " .. rate .. "Hz")

    --pauses the video while the change occurs to avoid A/V desyncs
    if
        options.pause > 0 and not mp.get_property_bool("pause")
        and not (   tostring(var.current_height) == height and
                    tostring(var.current_width) == width and
                    tostring(math.floor(mp.get_property_number('display-fps'))) == rate
                )
    then
        mp.set_property_bool("pause", true)
        mp.add_timeout(options.pause, function()
            mp.set_property_bool("pause", false)
        end)
    end

    local process = mp.command_native({
        name = 'subprocess',
        playback_only = false,
        args = {
            options.nircmd,
            "setdisplay",
            "monitor:" .. display,
            width,
            height,
            options.bdepth,
            rate
        }
    })

    if (process.status < 0) then
        local error = process.error_string
        msg.error('Error sending command')
        if error == "init" then
            msg.error('could not start nircmd - make sure you are using the right path')
        end
    end

    osdMessage("changing display " .. var.dnumber .. " to " .. width .. "x" .. height .. " " .. rate .. "Hz")

    --clears the memory for the display resolution
    var.current_width, var.current_height = 0, 0
end

--finds the display resolution by going into fullscreen and grabbing the resolution of the OSD
--this is seemingly the easiest way to get the true screen resolution
--if detect_screen_resolution is disabled this won't be required
function getDisplayResolution()
    local isFullscreen = mp.get_property_bool('fullscreen')

    mp.set_property_bool('fullscreen', true)

    --requires a small delay for the osd to go to fullscreen
    local time = mp.get_time()
    while time + 0.1 > mp.get_time() do end

    local width, height = mp.get_osd_size()

    msg.verbose('current monitor resolution = ' .. width .. 'x' .. height)

    mp.set_property_bool("fullscreen", isFullscreen)

    return width, height
end

--Finds the name of the display mpv is currently running on
--when passed display names nircmd seems to apply the command across all displays instead of just one
--so to get around this the name must be converted into an integer
--the names are in the form \\.\DISPLAY# starting from 1, while the integers start from 0
function getDisplayDetails()
    local name = mp.get_property_native('display-names')

    --the display-fps property always refers to the display with the lowest refresh rate
    --there is no way to test which display this is, so reverting the refresh when mpv is on multiple monitors is unpredictable
    --however, by default I'm just selecting whatever the first monitor in the list is
    if #name > 1 then
        msg.warn('mpv window is on multiplem displays, script may revert to wrong display rate')
    end

    name = name[1]
    msg.verbose('display name = ' .. name)

    --the last character in the name will always be the display number
    --we extract the integer and subtract by 1, as nircmd starts from 0
    local number = string.sub(name, -1)
    number = tonumber(number)
    number = number - 1

    msg.verbose('display number = ' .. number)
    return name, tostring(number)
end

--chooses a width and height to switch the display to based on the resolution of the video
function getModifiedWidthHeight(width, height)
    --if UHD adaptive is disabled then it doesn't matter what the video resolution is it'll just use the current resolution
    if (options.UHD_adaptive == false) then
        setCurrentRes()
        height = var.current_height
        width = var.current_width
        goto functionend
    end
    --sets the monitor to 2160p if an UHD video is played, otherwise set to the default
    if (height < options.UHD_threshold) then
        setCurrentRes()
        height = var.current_height
        width = var.current_width
    else
        height = options.UHD_height
        width = options.UHD_width
    end

    ::functionend::
    msg.verbose("setting display to: " .. width .. "x" .. height)
    return width, height
end


--picks which whitelisted rate to switch the monitor to
function findValidRate(rate)
    msg.verbose('searching for closest valid rate to ' .. rate)
    
    --if the rate already exists in the table then the function just returns that
    if var.rates[rate] ~= nil then
        msg.verbose(rate .. ' already in list, returning matching rate: ' .. var.rates[rate])
        return var.rates[rate]
    end

    local closestRate
    rate = tonumber(rate)

    --picks either the same fps in the whitelist, or the next highest
    --if none of the whitelisted rates are higher, then it uses the highest
    for i = 1, #var.rateList, 1 do
        closestRate = var.rateList[i]
        msg.debug('comparing ' .. rate .. ' to ' .. closestRate)
        if (closestRate >= rate) then
            break
        end
    end

    if closestRate == nil then
        closestRate = 0
    end
    msg.verbose('closest rate is ' .. closestRate .. ', saving...')

    --saves the rate to reduce repeated searches
    var.rates[rate] = var.rates[closestRate]

    return closestRate
end

--executes commands to switch monior to video refreshrate
function matchVideo()
    --gets display details
    local dname, dnumber = getDisplayDetails()

    --if the change is executed on a different monitor to the previous, and the previous monitor has not been been reverted
    --then revert the previous changes before changing the new monitor
    if ((var.beenReverted == false) and (var.dname ~= dname)) then
        msg.verbose('changing new display, reverting old one first')
        revertRefresh()
    end

    --records video properties
    var.new_width = mp.get_property_number('dwidth')
    var.new_height = mp.get_property_number('dheight')
    msg.verbose("video resolution = " .. tostring(var.new_width) .. "x" .. tostring(var.new_height))

    --saves either the estimated or specified fps of the video
    if (options.estimated_fps == true) then
        var.new_fps = mp.get_property_number('estimated-vf-fps', 0)
    else
        var.new_fps = mp.get_property_number('container-fps', 0)
    end
    
    --Floor is used because 23fps video has an actual framerate of ~23.9, this occurs across many video rates
    var.new_fps = math.floor(var.new_fps)
    var.new_width, var.new_height = getModifiedWidthHeight(var.new_width, var.new_height)

    --picks which whitelisted rate to switch the monitor to based on the video rate
    var.new_fps = findValidRate(var.new_fps)

    --if beenReverted=true, then the current display settings may not be saved
    if (var.beenReverted == true) then
        setCurrentRes()

        --saves the actual resolution only if option set, otherwise uses the defaults
        msg.verbose('saving original resolution: ' .. var.current_width .. 'x' .. var.current_height)
        var.original_width, var.original_height = var.current_width, var.current_height

        var.original_fps = math.floor(mp.get_property_number('display-fps'))
        msg.verbose('saving original fps: ' .. var.original_fps)
    end

    --saves the current name and number for next time
    var.dname = dname
    var.dnumber = dnumber

    changeRefresh(var.new_width, var.new_height, var.new_fps, dnumber)
    var.beenReverted = false
end

--reverts the monitor to its original refresh rate
function revertRefresh()
    if (var.beenReverted == false) then
        msg.verbose("reverting refresh rate")

        local rate
        if options.original_rate == 0 then
            rate = findValidRate(var.original_fps)
        else
            rate = options.original_rate
        end
        changeRefresh(var.original_width, var.original_height, rate, var.dnumber)
        var.beenReverted = true
    else
        msg.verbose("aborting reversion, display has not been changed")
        osdMessage('[change-refresh] display has not been changed')
    end
end

--sets the current resolution and refresh as the default to use upon reversion
function setDefault()
    var.original_width, var.original_height = getDisplayResolution()
    var.original_fps = math.floor(mp.get_property_number('display-fps'))

    var.beenReverted = true

    --logging change to OSD & the console
    msg.info('set ' .. var.original_width .. "x" .. var.original_height .. " " .. var.original_fps .. "Hz as defaut display rate")
    osdMessage('Change-Refresh: set ' .. var.original_width .. "x" .. var.original_height .. " " .. var.original_fps .. "Hz as defaut display rate")
end

--toggles between using estimated and specified fps
function toggleFpsType()
    if options.estimated_fps then
        options.estimated_fps = false
        osdMessage("[Change-Refresh] now using container fps")
        msg.info("now using container fps")
    else
        options.estimated_fps = true
        osdMessage("[Change-Refresh] now using estimated fps")
        msg.info("now using estimated fps")
    end
    return
end

--runs the script automatically on startup if option is enabled
function autoChange()
    if options.auto then
        --waits until some of the required properties have been loaded before running
        msg.verbose('automatically changing refresh')
        mp.add_timeout(0.5, matchVideo)
    end
end

function scriptMessage(width, height, rate, display)
    local name
    if display == nil then
        name, display = getDisplayDetails()
    end

    if width == nil or height == nil or rate == nil then
        msg.warn('script message must include a width, height, and rate')
        return
    end

    msg.verbose('recieved script message: ' .. width .. ' ' .. height .. ' ' .. rate .. ' ' .. display)
    changeRefresh(width, height, rate, display)
end

updateOptions()

--tries to change current display to match video fps (the main function you'd want to use)
mp.add_key_binding("f10", "match-refresh", matchVideo)

--reverts monitor to original refreshrate
mp.add_key_binding("Ctrl+f10", "revert-refresh", revertRefresh)

--switches between using estimated and specified fps property
mp.add_key_binding("", 'toggle-fps-type', toggleFpsType)

--set the current resolution and refresh rate as the default
mp.add_key_binding("", "set-default-refresh", setDefault)

--sends a command to switch to the specified display rate
--syntax is: script-message change-refresh [width] [height] [rate] [display]
mp.register_script_message("change-refresh", scriptMessage)

--runs the script automatically on startup if option is enabled
mp.register_event('file-loaded', autoChange)

--reverts refresh on mpv shutdown
mp.register_event("shutdown", revertRefresh)
