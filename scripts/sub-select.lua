--[[
    mpv-sub-select

    This script allows you to configure advanced subtitle track selection based on
    the current audio track and the names and language of the subtitle tracks.

    https://github.com/CogentRedTester/mpv-sub-select
]]--

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'
local opt = require 'mp.options'

local o = {
    --forcibly enable the script regardless of the sid option
    force_enable = false,

    --selects subtitles synchronously during the preloaded hook, which has better
    --compatability with other scripts and options
    --this requires that the script predict what the default audio track will be,
    --so this can be wrong on some rare occasions
    --disabling this will switch the subtitle track after playback starts
    preload = true,

    --experimental audio track selection based on the preferences.
    --this overrides force_prection and detect_incorrect_predictions.
    select_audio = false,

    --remove any potential prediction failures by forcibly selecting whichever
    --audio track was predicted
    force_prediction = false,

    --detect when a prediction is wrong and re-check the subtitles
    --this is automatically disabled if `force_prediction` is enabled
    detect_incorrect_predictions = true,

    --observe audio switches and reselect the subtitles when alang changes
    observe_audio_switches = false,

    --only select forced subtitles if they are explicitly included in slang
    explicit_forced_subs = false,

    --the folder that contains the 'sub-select.json' file
    config = "~~/script-opts"
}

opt.read_options(o, "sub_select")

local prefs

local ENABLED = o.force_enable or mp.get_property("options/sid", "auto") == "auto"
local latest_audio = {}
local alang_priority = mp.get_property_native("alang", {})
local audio_tracks = {}
local sub_tracks = {}

-- represents when there is no audio or subtitle track selected
local NO_TRACK = {
    id = 0
}

--returns a table that stores the given table t as the __index in its metatable
--creates a prototypally inherited table
local function redirect_table(t, new)
    return setmetatable(new or {}, { __index = t })
end

local function type_check(val, t, required)
    if val == nil then return not required end
    if not t:find(type(val)) then return false end
    return true
end

local function setup_prefs()
    local file = assert(io.open(mp.command_native({"expand-path", o.config .. "/sub-select.json"})))
    local json = file:read("*all")
    file:close()
    prefs = utils.parse_json(json)

    assert(prefs, "Invalid JSON format in sub-select.json.")
    local reservedIDs = { ['^'] = true }
    local IDs = {}

    -- storing the ID in the first pass
    for _, pref in ipairs(prefs) do
        if pref.id then
            assert(not reservedIDs[pref.id], 'using reserved ID '..pref.id)
            assert(not IDs[pref.id], 'duplicate ID '..pref.id)
            IDs[pref.id] = pref
        end
    end

    -- doing a second pass to inherit prefs and type check
    for i, pref in ipairs(prefs) do
        local pref_str = 'pref_'..i..' '..utils.to_string(pref)
        assert(type_check(pref.inherit, 'string'), '`inherit` must be a string: '..pref_str)

        if pref.inherit then
            local parent = pref.inherit == '^' and prefs[i-1] or IDs[pref.inherit]
            assert(parent, 'failed to find matching id: '..pref_str)
            pref = redirect_table(parent, pref)
        end

        -- type checking the options
        assert(type_check(pref.alang, 'string table', true), '`alang` must be a string or a table of strings: '..pref_str)
        assert(type_check(pref.slang, 'string table', true), '`slang` must be a string or a table of strings: '..pref_str)
        assert(type_check(pref.blacklist, 'table'), '`blacklist` must be a table: '..pref_str)
        assert(type_check(pref.whitelist, 'table'), '`whitelist` must be a table: '..pref_str)
        assert(type_check(pref.condition, 'string'), '`condition` must be a string: '..pref_str)
        assert(type_check(pref.id, 'string'), '`id` must be a string: '..pref_str)
    end
end

setup_prefs()

--evaluates and runs the given string in both Lua 5.1 and 5.2
--the name argument is used for error reporting
--provides the mpv modules and the fb module to the string
local function evaluate_string(str, env)
    msg.trace('evaluating string '..str)

    env = redirect_table(_G, env)
    env.mp = redirect_table(mp)
    env.msg = redirect_table(msg)
    env.utils = redirect_table(utils)

    local chunk, err
    if setfenv then
        chunk, err = loadstring(str)
        if chunk then setfenv(chunk, env) end
    else
        chunk, err = load(str, nil, 't', env)
    end
    if not chunk then
        msg.warn('failed to load string:', str)
        msg.error(err)
        chunk = function() return nil end
    end

    local success, boolean = pcall(chunk)
    if not success then msg.error(boolean) end
    return boolean
end

--anticipates the default audio track
--returns the node for the predicted track
--this whole function can be skipped if the user decides to load the subtitles asynchronously instead,
--or if `--aid` is not set to `auto`
local function predict_audio()
    --if the option is not set to auto then it is easy
    local opt = mp.get_property("options/aid", "auto")
    if opt == "no" then return NO_TRACK
    elseif opt ~= "auto" then return audio_tracks[tonumber(opt)] end

    local num_tracks = #audio_tracks
    if num_tracks == 1 then return audio_tracks[1]
    elseif num_tracks == 0 then return NO_TRACK end

    local highest_priority = nil
    local priority_str = ""
    local num_prefs = #alang_priority

    --loop through the track list for any audio tracks
    for i = 1, num_tracks do
        local track = audio_tracks[i]
        if track.forced then return track end

        --loop through the alang list to check if it has a preference
        local pref = 0
        for j = 1, num_prefs do
            if track.lang == alang_priority[j] then

                --a lower number j has higher priority, so flip the numbers around so the lowest j has highest preference
                pref = num_prefs - j
                break
            end
        end

        --format the important preferences so that we can easily use a lexicographical comparison to find the default
        local formatted_str = string.format("%03d-%d-%02d", pref, track.default and 1 or 0, num_tracks - track.id)
        msg.trace("formatted track info: " .. formatted_str)

        if formatted_str > priority_str then
            priority_str = formatted_str
            highest_priority = track
        end
    end

    msg.verbose("predicted audio track is "..tostring(highest_priority.id))
    return highest_priority
end

--sets the subtitle track to the given sid
--this is a function to prepare for some upcoming functionality, but I've forgotten what that is
local function set_track(type, id)
    msg.verbose("setting", type, "to", id)
    if mp.get_property_number(type) == id then return end
    mp.set_property(type, id)
end

--checks if the given audio matches the given track preference
local function is_valid_audio(audio, pref)
    local alangs = type(pref.alang) == "string" and {pref.alang} or pref.alang

    for _,lang in ipairs(alangs) do
        msg.trace("Checking for valid audio:", lang)

        if audio == NO_TRACK then
            if lang == "no" then return true end
        else
            if lang == '*' then
                return true
            elseif lang == "forced" then
                if audio.forced then return true end
            elseif lang == "default" then
                if audio.default then return true end
            else
                if audio.lang and audio.lang:find(lang) then return true end
            end
        end
    end
    return false
end

--checks if the given sub matches the given track preference
local function is_valid_sub(sub, slang, pref)
    msg.trace("checking sub", slang, "against track", utils.to_string(sub))

    -- Do not try to un-nest these if statements, it will break detection of default and forced tracks.
    -- I've already had to un-nest these statements twice due to this mistake, don't let it happen again.
    if sub == NO_TRACK then
        return slang == 'no'
    else
        if slang == "default" then
            if not sub.default then return false end
        elseif slang == "forced" then
            if not sub.forced then return false end
        else
            if sub.forced and o.explicit_forced_subs then return false end
            if not sub.lang:find(slang) and slang ~= "*" then return false end
        end
    end

    local title = sub.title or ''

    -- if the whitelist is not set then we don't need to find anything
    local passes_whitelist = not pref.whitelist
    local passes_blacklist = true

    -- whitelist/blacklist handling
    if pref.whitelist and title then
        for _,word in ipairs(pref.whitelist) do
            if title:lower():find(word) then passes_whitelist = true end
        end
    end

    if pref.blacklist and title then
        for _,word in ipairs(pref.blacklist) do
            if title:lower():find(word) then passes_blacklist = false end
        end
    end

    msg.trace(string.format("%s %s whitelist: %s | %s blacklist: %s",
        title,
        passes_whitelist and "passed" or "failed", utils.to_string(pref.whitelist),
        passes_blacklist and "passed" or "failed", utils.to_string(pref.blacklist)
    ))
    return passes_whitelist and passes_blacklist
end

--scans the track list and selects audio and subtitle tracks which match the track preferences
--if an audio track is provided to the function it will assume this track is the only audio
local function find_valid_tracks(manual_audio)
    assert(manual_audio == nil or (type(manual_audio) == 'table' and manual_audio.id), 'argument must be an audio track or nil')

    local sub_track_list = {NO_TRACK, unpack(sub_tracks)}
    local audio_track_list

    if manual_audio == nil then
        audio_track_list = {NO_TRACK, unpack(audio_tracks)}
    else
        audio_track_list = {manual_audio}
    end

    if manual_audio then msg.debug("select subtitle for", utils.to_string(manual_audio))
    else msg.debug('selecting audio and subtitles') end

    --searching the selection presets for one that applies to this track
    for _,pref in ipairs(prefs) do
        msg.debug("checking pref:", utils.to_string(pref))

        for _, audio_track in ipairs(audio_track_list) do
            if is_valid_audio(audio_track, pref) then
                local aid = audio_track and audio_track.id

                --checks if any of the subtitle tracks match the preset for the current audio
                local slangs = type(pref.slang) == "string" and {pref.slang} or pref.slang
                msg.trace("valid audio preference found:", utils.to_string(pref.alang))

                for _, slang in ipairs(slangs) do
                    msg.trace("checking for valid sub:", slang)


                    for _,sub_track in ipairs(sub_track_list) do
                        if  is_valid_sub(sub_track, slang, pref)
                            and (not pref.condition or (evaluate_string('return '..pref.condition, {
                                audio = aid > 0 and audio_track or nil,
                                sub = sub_track.id > 0 and sub_track or nil
                            }) == true))
                        then
                            msg.verbose("valid audio preference found:", utils.to_string(pref.alang))
                            msg.verbose("valid subtitle preference found:", utils.to_string(pref.slang))
                            return aid, sub_track and sub_track.id
                        end
                    end
                end
            end
        end
    end
end


--returns the audio node for the currently playing audio track
local function find_current_audio()
    local aid = mp.get_property_number("aid", 0)
    return audio_tracks[aid] or NO_TRACK
end

--extract the language code from an audio track node and pass it to select_subtitles
local function select_tracks(audio)
    -- if the audio track has no fields we assume that there is no actual track selected
    local aid, sid = find_valid_tracks(audio)
    if sid then
        set_track('sid', sid == 0 and 'no' or sid)
    end
    if aid and o.select_audio then
        set_track('aid', aid == 0 and 'no' or aid)
    end

    latest_audio = find_current_audio()
end

--select subtitles asynchronously after playback start
local function async_load()
    select_tracks(not o.select_audio and find_current_audio() or nil)
end

--select subtitles synchronously during the on_preloaded hook
local function preload()
    if o.select_audio then return select_tracks() end

    local audio = predict_audio()
    if o.force_prediction and next(audio) then set_track("aid", audio.id) end
    select_tracks(audio)
end

local track_auto_selection = true
mp.observe_property("track-auto-selection", "bool", function(_,b) track_auto_selection = b end)

local function continue_script()
    if #sub_tracks < 1 then return false end
    if not ENABLED then return false end
    if not track_auto_selection then return false end
    return true
end

--reselect the subtitles if the audio is different from what was last used
local function reselect_subtitles()
    if not continue_script() then return end
    local audio = find_current_audio()
    if latest_audio.id ~= audio.id then

        msg.info("detected audio change - reselecting subtitles")
        select_tracks(audio)
    end
end

--setups the audio and subtitle track lists to use for the rest of the script
local function read_track_list()
    local track_list = mp.get_property_native("track-list", {})
    audio_tracks = {}
    sub_tracks = {}
    for _,track in ipairs(track_list) do
        if not track.lang then track.lang = "und" end

        if track.type == "audio" then
            table.insert(audio_tracks, track)
        elseif track.type == "sub" then
            table.insert(sub_tracks, track)
        end
    end
end

--setup the audio and subtitle track lists when a new file is loaded
mp.add_hook('on_preloaded', 25, read_track_list)

--events for file loading
if o.preload then
    mp.add_hook('on_preloaded', 30, function()
        if not continue_script() then return end
        preload()
    end)

    --double check if the predicted subtitle was correct
    if o.detect_incorrect_predictions and not o.select_audio and not o.force_prediction and not o.observe_audio_switches then
        mp.register_event("file-loaded", reselect_subtitles)
    end
else
    mp.register_event("file-loaded", function()
        if not continue_script() then return end
        async_load()
    end)
end

--reselect subs when changing audio tracks
if o.observe_audio_switches then
    mp.observe_property("aid", "string", function(_,aid)
        if aid ~= "auto" then reselect_subtitles() end
    end)
end

mp.observe_property('track-list/count', 'number', read_track_list)

--force subtitle selection during playback
mp.register_script_message("select-subtitles", async_load)

--toggle sub-select during playback
mp.register_script_message("sub-select", function(arg)
    if arg == "toggle" then ENABLED = not ENABLED
    elseif arg == "enable" then ENABLED = true
    elseif arg == "disable" then ENABLED = false end
    local str = "sub-select: ".. (ENABLED and "enabled" or "disabled")
    mp.osd_message(str)

    if not continue_script() then return end
    async_load()
end)

