--[[
    Shows a notification when the file loads if it has multiple editions
    switches the osd-playing-message to show the list of editions to allow for better edition navigation

    available at: https://github.com/CogentRedTester/mpv-scripts
]]--

msg = require 'mp.msg'

playingMessage = mp.get_property('options/osd-playing-msg')
editionSwitching = false
lastFilename = ""

--shows a message on the OSD if the file has editions
function showNotification()
    local editions = mp.get_property_number('editions', 0)

    --if there are no editions (or 1 dummy edition) then exit the function
    if editions < 2 then return end

    local time = mp.get_time()
    while (mp.get_time() - time < 1) do

    end
    mp.osd_message('file has ' .. editions .. ' editions', '2')
end

--The script remembers the first time the edition is switched using mp.observe_property, and afterwards always displays the edition-list on each file-loaded
--event, instead of the default osd-playting-msg. The script needs to compare the filenames each time in order to test when a new file has been loaded.
--When this happens it resets the editionSwitching boolean and displays the original osd-playing-message.
--This process is necessary because there seems to be no way to differentiate between a new file being loaded and a new edition being loaded
function main()
    local edition = mp.get_property_number('current-edition')

    --resets editionSwitching boolean and sets the new filename
    if lastFilename ~= mp.get_property('filename') then
        changedFile()
        lastFilename = mp.get_property('filename')

        --if the file is new then it runs then notification function
        showNotification()
    end

    if (editionSwitching == false or edition == nil) then
        mp.set_property('options/osd-playing-msg', playingMessage)
    else
        mp.set_property('options/osd-playing-msg', '${edition-list}')
    end
end

--logs when the edition is changed
function editionChanged()
    msg.log('v', 'edition changed')
    editionSwitching = true
end

--resets the edition switch boolean on a file change
function changedFile()
    msg.log('v', 'switched file')
    editionSwitching = false
end

mp.observe_property('current-edition', nil, editionChanged)

mp.register_event('file-loaded', main)