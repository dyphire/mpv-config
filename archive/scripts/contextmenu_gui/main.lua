--[[
*****************************************************************
** Context menu for mpv.                                       **
** Origin_ Avi Halachmi https://github.com/avih                **
** Extension_ Thomas Carmichael https://gitlab.com/carmanaught **
*****************************************************************
mpv的tcl图形菜单的核心脚本
建议在 input.conf 中绑定右键以支持唤起菜单
MOUSE_BTN2   script-message-to contextmenu_gui contextmenu_tk
--]]

local langcodes = require "contextmenu_gui_lang"
local function mpdebug(x) mp.msg.info(x) end
local propNative = mp.get_property_native

-- Set options
local options = require "mp.options"
local opt = {
    filter01B = "", filter01C = "", filter01D = "", filter01G = false,
    filter02B = "", filter02C = "", filter02D = "", filter02G = false,
    filter03B = "", filter03C = "", filter03D = "", filter03G = false,
    filter04B = "", filter04C = "", filter04D = "", filter04G = false,
    filter05B = "", filter05C = "", filter05D = "", filter05G = false,
    filter06B = "", filter06C = "", filter06D = "", filter06G = false,
    filter07B = "", filter07C = "", filter07D = "", filter07G = false,
    filter08B = "", filter08C = "", filter08D = "", filter08G = false,
    filter09B = "", filter09C = "", filter09D = "", filter09G = false,
    filter10B = "", filter10C = "", filter10D = "", filter10G = false,

    shader01B = "", shader01C = "", shader01D = "", shader01G = false,
    shader02B = "", shader02C = "", shader02D = "", shader02G = false,
    shader03B = "", shader03C = "", shader03D = "", shader03G = false,
    shader04B = "", shader04C = "", shader04D = "", shader04G = false,
    shader05B = "", shader05C = "", shader05D = "", shader05G = false,
    shader06B = "", shader06C = "", shader06D = "", shader06G = false,
    shader07B = "", shader07C = "", shader07D = "", shader07G = false,
    shader08B = "", shader08C = "", shader08D = "", shader08G = false,
    shader09B = "", shader09C = "", shader09D = "", shader09G = false,
    shader10B = "", shader10C = "", shader10D = "", shader10G = false,
}
options.read_options(opt)

-- Set some constant values
local SEP = "separator"
local CASCADE = "cascade"
local COMMAND = "command"
local CHECK = "checkbutton"
local RADIO = "radiobutton"
local AB = "ab-button"

local function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

-- 版本（Edition）子菜单
local function inspectEdition()
    local editionDisable = false
    if propNative("edition-list/count") == nil or propNative("edition-list/count") < 1 then editionDisable = true end
    return editionDisable
end

local function checkEdition(editionNum)
    local editionState, editionCur = false, propNative("current-edition")
    if (editionNum == editionCur) then editionState = true end
    return editionState
end

local function editionMenu()
    local editionCount = propNative("edition-list/count")
    local editionMenuVal = {}

    if editionCount ~= nil and not (editionCount == 0) then
        for editionNum=0, (editionCount - 1), 1 do
            local editionTitle = propNative("edition-list/" .. editionNum .. "/title")
            if not (editionTitle) then editionTitle = "Edition " .. string.format("%02.f", editionNum + 1) end

            local editionCommand = "set edition " .. editionNum
            table.insert(editionMenuVal, {RADIO, editionTitle, "", editionCommand, function() return checkEdition(editionNum) end, false})
        end
    end

    return editionMenuVal
end

-- 章节子菜单
local function inspectChapter()
    local chapterDisable = false
    if propNative("chapter-list/count") == nil or propNative("chapter-list/count") < 1 then chapterDisable = true end
    return chapterDisable
end

local function checkChapter(chapterNum)
    local chapterState, chapterCur = false, propNative("chapter")
    if (chapterNum == chapterCur) then chapterState = true end
    return chapterState
end

local function chapterMenu()
    local chapterCount = propNative("chapter-list/count")
    local chapterMenuVal = {}

    chapterMenuVal = {
        {COMMAND, "上一章节", "PGDWN", "add chapter -1", "", false},
        {COMMAND, "下一章节", "PGUP", "add chapter 1", "", false},
    }
    if chapterCount ~= nil and not (chapterCount == 0) then
        for chapterNum=0, (chapterCount - 1), 1 do
            local chapterTitle = propNative("chapter-list/" .. chapterNum .. "/title")
            local chapterTime = propNative("chapter-list/" .. chapterNum .. "/time")
            if chapterTitle == "" then chapterTitle = "章节 " .. string.format("%02.f", chapterNum + 1) end
            if chapterTime < 0 then chapterTime = 0
            else chapterTime = math.floor(chapterTime) end
            chapterTime = string.format("[%02d:%02d:%02d]", math.floor(chapterTime/60/60), math.floor(chapterTime/60)%60, chapterTime%60)
            chapterTitle = chapterTime ..'   '.. chapterTitle

            local chapterCommand = "set chapter " .. chapterNum
            if (chapterNum == 0) then table.insert(chapterMenuVal, {SEP}) end
            table.insert(chapterMenuVal, {RADIO, chapterTitle, "", chapterCommand, function() return checkChapter(chapterNum) end, false})
        end
    end

    return chapterMenuVal
end

-- Track type count function to iterate through the track-list and get the number of
-- tracks of the type specified. Types are:  video / audio / sub. This actually
-- returns a table of track numbers of the given type so that the track-list/N/
-- properties can be obtained.

local function trackCount(checkType)
    local tracksCount = propNative("track-list/count")
    local trackCountVal = {}

    if not (tracksCount < 1) then
        for i = 0, (tracksCount - 1), 1 do
            local trackType = propNative("track-list/" .. i .. "/type")
            if (trackType == checkType) then table.insert(trackCountVal, i) end
        end
    end

    return trackCountVal
end

-- Track check function, to check if a track is selected. This isn't specific to a set
-- track type and can be used for the video/audio/sub tracks, since they're all part
-- of the track-list.

local function checkTrack(trackNum)
    local trackState, trackCur = false, propNative("track-list/" .. trackNum .. "/selected")
    if (trackCur == true) then trackState = true end
    return trackState
end

-- Convert ISO 639-1/639-2 codes to be full length language names. The full length names
-- are obtained by using the property accessor with the iso639_1/_2 tables stored in
-- the contextmenu_gui_lang.lua file (require "langcodes" above).
local function getLang(trackLang)
    trackLang = string.upper(trackLang)
    if (string.len(trackLang) == 2) and trackLang == "SC" then trackLang = "sc"  --修复中文字幕常见语言标识的误识别
    elseif (string.len(trackLang) == 2) then trackLang = langcodes.iso639_1(trackLang)
    elseif (string.len(trackLang) == 3) then trackLang = langcodes.iso639_2(trackLang) end
    return trackLang
end

local function noneCheck(checkType)
    local checkVal, trackID = false, propNative(checkType)
    if (type(trackID) == "boolean") then
        if (trackID == false) then checkVal = true end
    end
    return checkVal
end

local function is_empty(input)
    if input == nil or input == "" then
        return true
    end
end

----- string
local function replace(str, what, with)
    if is_empty(str) then return "" end
    if is_empty(what) then return str end
    if with == nil then with = "" end
    what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1")
    with = string.gsub(with, "[%%]", "%%%%")
    return string.gsub(str, what, with)
end

local function esc_for_title(string)
    string = string:gsub('^[%._%-%s]*', '')
            :gsub('%.%w+$', '')
    return string
end

-- 视频轨子菜单
local function inspectVidTrack()
    local vidTrackDisable, vidTracks = false, trackCount("video")
    if (#vidTracks < 1) then vidTrackDisable = true end
    return vidTrackDisable
end

local function vidTrackMenu()
    local vidTrackMenuVal, vidTrackCount = {}, trackCount("video")

    if not (#vidTrackCount == 0) then
        for i = 1, #vidTrackCount, 1 do
            local vidTrackNum = vidTrackCount[i]
            local vidTrackID = propNative("track-list/" .. vidTrackNum .. "/id")
            local vidTrackTitle = propNative("track-list/" .. vidTrackNum .. "/title")
            local vidTrackCodec = propNative("track-list/" .. vidTrackNum .. "/codec"):upper()
            local vidTrackImage = propNative("track-list/" .. vidTrackNum .. "/image")
            local vidTrackwh = propNative("track-list/" .. vidTrackNum .. "/demux-w") .. "x" .. propNative("track-list/" .. vidTrackNum .. "/demux-h") 
            local vidTrackFps = string.format("%.3f", propNative("track-list/" .. vidTrackNum .. "/demux-fps"))
            local vidTrackDefault = propNative("track-list/" .. vidTrackNum .. "/default")
            local vidTrackForced = propNative("track-list/" .. vidTrackNum .. "/forced")
            local vidTrackExternal = propNative("track-list/" .. vidTrackNum .. "/external")
            local filename = propNative("filename/no-ext")

            if vidTrackTitle then vidTrackTitle = replace(vidTrackTitle, filename, "") end
            if vidTrackExternal then vidTrackTitle = esc_for_title(vidTrackTitle) end
            if vidTrackCodec:match("MPEG2") then vidTrackCodec = "MPEG2"
            elseif vidTrackCodec:match("DVVIDEO") then vidTrackCodec = "DV"
            end

            if vidTrackTitle and not vidTrackImage then vidTrackTitle = vidTrackTitle .. "[" .. vidTrackCodec .. "]" .. "," .. vidTrackwh .. "," .. vidTrackFps .. " FPS"
            elseif vidTrackTitle then vidTrackTitle = vidTrackTitle .. "[" .. vidTrackCodec .. "]" .. "," .. vidTrackwh
            elseif vidTrackImage then vidTrackTitle = "[" .. vidTrackCodec .. "]" .. "," .. vidTrackwh
            elseif vidTrackFps then vidTrackTitle = "[" .. vidTrackCodec .. "]" .. "," .. vidTrackwh .. "," .. vidTrackFps .. " FPS"
            else vidTrackTitle = "视频轨 " .. i end
            if vidTrackForced then  vidTrackTitle = vidTrackTitle .. "," .. "Forced" end
            if vidTrackDefault then  vidTrackTitle = vidTrackTitle .. "," .. "Default" end
            if vidTrackExternal then  vidTrackTitle = vidTrackTitle .. "," .. "External" end

            local vidTrackCommand = "set vid " .. vidTrackID
            table.insert(vidTrackMenuVal, {RADIO, vidTrackTitle, "", vidTrackCommand, function() return checkTrack(vidTrackNum) end, false})
        end
    else
        table.insert(vidTrackMenuVal, {RADIO, "无视频轨", "", "", "", true})
    end

    return vidTrackMenuVal
end

-- 音频轨子菜单
local function inspectAudTrack()
    local audTrackDisable, audTracks = false, trackCount("audio")
    if (#audTracks < 1) then audTrackDisable = true end
    return audTrackDisable
end

local function audTrackMenu()
    local audTrackMenuVal, audTrackCount = {}, trackCount("audio")

    audTrackMenuVal = {
         {COMMAND, "重载当前音频轨（限外挂）", "", "audio-reload", "", false},
         {COMMAND, "移除当前音频轨（限外挂）", "", "audio-remove", "", false},
    }
    if not (#audTrackCount == 0) then
        for i = 1, (#audTrackCount), 1 do
            local audTrackNum = audTrackCount[i]
            local audTrackID = propNative("track-list/" .. audTrackNum .. "/id")
            local audTrackTitle = propNative("track-list/" .. audTrackNum .. "/title")
            local audTrackLang = propNative("track-list/" .. audTrackNum .. "/lang")
            local audTrackCodec = propNative("track-list/" .. audTrackNum .. "/codec"):upper()
            -- local audTrackBitrate = propNative("track-list/" .. audTrackNum .. "/demux-bitrate")/1000  -- 此属性似乎不可用
            local audTrackSamplerate = string.format("%.1f", propNative("track-list/" .. audTrackNum .. "/demux-samplerate")/1000)
            local audTrackChannels = propNative("track-list/" .. audTrackNum .. "/demux-channel-count")
            local audTrackDefault = propNative("track-list/" .. audTrackNum .. "/default")
            local audTrackForced = propNative("track-list/" .. audTrackNum .. "/forced")
            local audTrackExternal = propNative("track-list/" .. audTrackNum .. "/external")
            local filename = propNative("filename/no-ext")
            -- Convert ISO 639-1/2 codes
            if not (audTrackLang == nil) then audTrackLang = getLang(audTrackLang) and getLang(audTrackLang) or audTrackLang end
            if audTrackTitle then audTrackTitle = replace(audTrackTitle, filename, "") end
            if audTrackExternal then audTrackTitle = esc_for_title(audTrackTitle) end
            if audTrackCodec:match("PCM") then audTrackCodec = "PCM" end

            if audTrackTitle and audTrackLang then audTrackTitle = audTrackTitle .. "," .. audTrackLang .. "[" .. audTrackCodec .. "]" .. "," .. audTrackChannels .. " ch" .. "," .. audTrackSamplerate .. " kHz"
            elseif audTrackTitle then audTrackTitle = audTrackTitle .. "[" .. audTrackCodec .. "]" .. "," .. audTrackChannels .. " ch" .. "," .. audTrackSamplerate .. " kHz"
            elseif audTrackLang then audTrackTitle = audTrackLang .. "[" .. audTrackCodec .. "]" .. "," .. audTrackChannels .. " ch" .. "," .. audTrackSamplerate .. " kHz"
            elseif audTrackChannels then audTrackTitle = "[" .. audTrackCodec .. "]" .. "," .. audTrackChannels .. " ch" .. "," .. audTrackSamplerate .. " kHz"
            else audTrackTitle = "音频轨 " .. i end
            if audTrackForced then  audTrackTitle = audTrackTitle .. "," .. "Forced" end
            if audTrackDefault then  audTrackTitle = audTrackTitle .. "," .. "Default" end
            if audTrackExternal then  audTrackTitle = audTrackTitle .. "," .. "External" end

            local audTrackCommand = "set aid " .. audTrackID
            if (i == 1) then
                table.insert(audTrackMenuVal, {RADIO, "不渲染音频", "", "set aid 0", function() return noneCheck("aid") end, false})
                table.insert(audTrackMenuVal, {SEP})
            end
            table.insert(audTrackMenuVal, {RADIO, audTrackTitle, "", audTrackCommand, function() return checkTrack(audTrackNum) end, false})
        end
    end

    return audTrackMenuVal
end

-- 字幕轨子菜单
local function inspectSubTrack()
    local subTrackDisable, subTracks = false, trackCount("sub")
    if (#subTracks < 1) then subTrackDisable = true end
    return subTrackDisable
end

-- Subtitle label
local function subVisLabel() return propNative("sub-visibility") and "隐藏" or "取消隐藏" end

local function subTrackMenu()
    local subTrackMenuVal, subTrackCount = {}, trackCount("sub")

    subTrackMenuVal = {
        {COMMAND, "重载当前字幕轨（限外挂）", "", "sub-reload", "", false},
        {COMMAND, "移除当前字幕轨（限外挂）", "", "sub-remove", "", false},
        {CHECK, function() return subVisLabel() end, "v", "cycle sub-visibility;show-text 字幕可见性:${sub-visibility} ", function() return not propNative("sub-visibility") end, false},
    }
    if not (#subTrackCount == 0) then
        for i = 1, (#subTrackCount), 1 do
            local subTrackNum = subTrackCount[i]
            local subTrackID = propNative("track-list/" .. subTrackNum .. "/id")
            local subTrackTitle = propNative("track-list/" .. subTrackNum .. "/title")
            local subTrackLang = propNative("track-list/" .. subTrackNum .. "/lang")
            local subTrackCodec = propNative("track-list/" .. subTrackNum .. "/codec"):upper()
            local subTrackDefault = propNative("track-list/" .. subTrackNum .. "/default")
            local subTrackForced = propNative("track-list/" .. subTrackNum .. "/forced")
            local subTrackExternal = propNative("track-list/" .. subTrackNum .. "/external")
            local filename = propNative("filename/no-ext")
            -- Convert ISO 639-1/2 codes
            if not (subTrackLang == nil) then subTrackLang = getLang(subTrackLang) and getLang(subTrackLang) or subTrackLang end
            if subTrackTitle then subTrackTitle = replace(subTrackTitle, filename, "") end end
            if subTrackExternal then subTrackTitle = esc_for_title(subTrackTitle) end
            if subTrackCodec:match("PGS") then subTrackCodec = "PGS"
            elseif subTrackCodec:match("SUBRIP") then subTrackCodec = "SRT"
            elseif subTrackCodec:match("VTT") then subTrackCodec = "VTT"
            elseif subTrackCodec:match("DVB_SUB") then subTrackCodec = "DVB"
            elseif subTrackCodec:match("DVD_SUB") then subTrackCodec = "VOB"
            end

            if subTrackTitle and subTrackLang then subTrackTitle = subTrackTitle .. "," .. subTrackLang .. "[" .. subTrackCodec .. "]" 
            elseif subTrackTitle then subTrackTitle = subTrackTitle .. "[" .. subTrackCodec .. "]"
            elseif subTrackLang then subTrackTitle = subTrackLang .. "[" .. subTrackCodec .. "]"
            elseif subTrackCodec then subTrackTitle = "[" .. subTrackCodec .. "]"
            else subTrackTitle = "字幕轨 " .. i end
            if subTrackForced then  subTrackTitle = subTrackTitle .. "," .. "Forced" end
            if subTrackDefault then  subTrackTitle = subTrackTitle .. "," .. "Default" end
            if subTrackExternal then  subTrackTitle = subTrackTitle .. "," .. "External" end

            local subTrackCommand = "set sid " .. subTrackID
            if (i == 1) then
                table.insert(subTrackMenuVal, {RADIO, "不渲染字幕", "", "set sid 0", function() return noneCheck("sid") end, false})
                table.insert(subTrackMenuVal, {SEP})
            end
            table.insert(subTrackMenuVal, {RADIO, subTrackTitle, "", subTrackCommand, function() return checkTrack(subTrackNum) end, false})
        end
    end

    return subTrackMenuVal
end

local function stateABLoop()
    local abLoopState = ""
    local abLoopA, abLoopB = propNative("ab-loop-a"), propNative("ab-loop-b")

    if (abLoopA == "no") and (abLoopB == "no") then abLoopState =  "off"
    elseif not (abLoopA == "no") and (abLoopB == "no") then abLoopState = "a"
    elseif not (abLoopA == "no") and not (abLoopB == "no") then abLoopState = "b" end

    return abLoopState
end

local function stateFileLoop()
    local loopState, loopval = false, propNative("loop-file")
    if (loopval == "inf") then loopState = true end
    return loopState
end

-- 长宽比子菜单
local function stateRatio(ratioVal)
    -- Ratios and Decimal equivalents
    -- Ratios:    "4:3" "16:10"  "16:9" "1.85:1" "2.35:1"
    -- Decimal: "1.333" "1.600" "1.778"  "1.850"  "2.350"
    local ratioState = false
    local ratioCur = round(propNative("video-aspect-override"), 3)

    if (ratioVal == "4:3") and (ratioCur == round(4/3, 3)) then ratioState = true
    elseif (ratioVal == "16:10") and (ratioCur == round(16/10, 3)) then ratioState = true
    elseif (ratioVal == "16:9") and (ratioCur == round(16/9, 3)) then ratioState = true
    elseif (ratioVal == "1.85:1") and (ratioCur == round(1.85/1, 3)) then ratioState = true
    elseif (ratioVal == "2.35:1") and (ratioCur == round(2.35/1, 3)) then ratioState = true
    end

    return ratioState
end

-- 解码模式子菜单
local function stateHwdec(hwdecVal)

    local hwdecState = false
    local hwdecCur = propNative("hwdec-current")

    if (hwdecVal == "no") and (hwdecCur == "no" or hwdecCur == "") then hwdecState = true
    elseif (hwdecVal == "dxva2") and (hwdecCur == "dxva2") then hwdecState = true
    elseif (hwdecVal == "dxva2-copy") and (hwdecCur == "dxva2-copy") then hwdecState = true
    elseif (hwdecVal == "d3d11va") and (hwdecCur == "d3d11va") then hwdecState = true
    elseif (hwdecVal == "d3d11va-copy") and (hwdecCur == "d3d11va-copy") then hwdecState = true
    elseif (hwdecVal == "qsv") and (hwdecCur == "qsv") then hwdecState = true
    elseif (hwdecVal == "qsv-copy") and (hwdecCur == "qsv-copy") then hwdecState = true
    elseif (hwdecVal == "cuda") and (hwdecCur == "cuda") then hwdecState = true
    elseif (hwdecVal == "cuda-copy") and (hwdecCur == "cuda-copy") then hwdecState = true
    elseif (hwdecVal == "nvdec") and (hwdecCur == "nvdec") then hwdecState = true
    elseif (hwdecVal == "nvdec-copy") and (hwdecCur == "nvdec-copy") then hwdecState = true

    end

    return hwdecState
end

-- Video Rotate radio item check
local function stateRotate(rotateVal)
    local rotateState, rotateCur = false, propNative("video-rotate")
    if (rotateVal == rotateCur) then rotateState = true end
    return rotateState
end

-- Video Alignment radio item checks
local function stateAlign(alignAxis, alignPos)
    local alignState = false
    local alignValY, alignValX = propNative("video-align-y"), propNative("video-align-x")

    -- This seems a bit unwieldy. Should look at simplifying if possible.
    if (alignAxis == "y") then
        if (alignPos == alignValY) then alignState = true end
    elseif (alignAxis == "x") then
        if (alignPos == alignValX) then alignState = true end
    end

    return alignState
end

-- Deinterlacing radio item check
local function stateDeInt(deIntVal)
    local deIntState, deIntCur = false, propNative("deinterlace")
    if (deIntVal == deIntCur) then deIntState = true end
    return deIntState
end

local function stateFlip(flipVal)
    local vfState, vfVals = false, propNative("vf")
    for i, vf in pairs(vfVals) do
        if (vf["name"] == flipVal) then vfState = true end
    end
    return vfState
end

-- Mute label
local function muteLabel() return propNative("mute") and "取消静音" or "静音" end

-- 输出声道子菜单
local audio_channels = { {"自动（安全）", "auto-safe"}, {"自动", "auto"}, {"无", "empty"}, {"单声道", "mono"}, {"立体声", "stereo"}, {"2.1", "2.1"}, {"5.1（标准）", "5.1"}, {"7.1（标准）", "7.1"} }

-- Create audio key/value pairs to check against the native property
-- e.g. audio_pair["2.1"] = "2.1", etc.
local audio_pair = {}
for i = 1, #audio_channels do
    audio_pair[audio_channels[i][2]] = audio_channels[i][2]
end

-- Audio channel layout radio item check
local function stateAudChannel(audVal)
    local audState, audLayout = false, propNative("audio-channels")

    audState = (audio_pair[audVal] == audLayout) and true or false
    return audState
end

-- Audio channel layout menu creation
local function audLayoutMenu()
    local audLayoutMenuVal = {}

    for i = 1, #audio_channels do
        if (i == 3) then table.insert(audLayoutMenuVal, {SEP}) end
        table.insert(audLayoutMenuVal, {RADIO, audio_channels[i][1], "", "set audio-channels \"" .. audio_channels[i][2] .. "\"", function() return stateAudChannel(audio_channels[i][2]) end, false})
    end

    return audLayoutMenuVal
end

-- OSD时间轴检查
local function stateOsdLevel(osdLevelVal)
    local osdLevelState, osdLevelCur = false, propNative("osd-level")
    osdLevelState = (osdLevelVal == osdLevelCur) and true or false
    return osdLevelState
end

-- Subtitle Alignment radio item check
local function stateSubAlign(subAlignVal)
    local subAlignState, subAlignCur = false, propNative("sub-align-y")
    subAlignState = (subAlignVal == subAlignCur) and true or false
    return subAlignState
end

-- Subtitle Position radio item check
local function stateSubPos(subPosVal)
    local subPosState, subPosCur = false, propNative("image-subs-video-resolution")
    subPosState = (subPosVal == subPosCur) and true or false
    return subPosState
end

local function movePlaylist(direction)
    local playlistPos, newPos = propNative("playlist-pos"), 0
    -- We'll remove 1 here to "0 index" the value since we're using it with playlist-pos
    local playlistCount = propNative("playlist-count") - 1

    if (direction == "up") then
        newPos = playlistPos - 1
        if not (playlistPos == 0) then
            mp.commandv("plalist-move", playlistPos, newPos)
        else mp.osd_message("已排最前") end
    elseif (direction == "down") then
        if not (playlistPos == playlistCount) then
            newPos = playlistPos + 2
            mp.commandv("plalist-move", playlistPos, newPos)
        else mp.osd_message("已排最后") end
    end
end

local function statePlayLoop()
    local loopState, loopVal = false, propNative("loop-playlist")
    if not (tostring(loopVal) == "false") then loopState = true end
    return loopState
end

local function stateOnTop(onTopVal)
    local onTopState, onTopCur = false, propNative("ontop")
    onTopState = (onTopVal == onTopCur) and true or false
    return onTopState
end

--[[ ************ 菜单内容 ************ ]]--

local menuList = {}

-- Format for object tables
-- {Item Type, Label, Accelerator, Command, Item State, Item Disable, Repost Menu (Optional)}

-- Item Type - The type of item, e.g. CASCADE, COMMAND, CHECK, RADIO, etc
-- Label - The label for the item
-- Accelerator - The text shortcut/accelerator for the item
-- Command - This is the command to run when the item is clicked
-- Item State - The state of the item (selected/unselected). A/B Repeat is a special case.
-- Item Disable - Whether to disable
-- Repost Menu (Optional) - This is only for use with the Tk menu and is optional (only needed
-- if the intent is for the menu item to cause the menu to repost)

-- Item Type, Label and Accelerator should all evaluate to strings as a result of the return
-- from a function or be strings themselves.
-- Command can be a function or string, this will be handled after a click.
-- Item State and Item Disable should normally be boolean but can be a string for A/B Repeat.
-- Repost Menu (Optional) should only be boolean and is only needed if the value is true.

-- The 'file_loaded_menu' value is used when the table is passed to the menu-engine to handle the
-- behavior of the 'playback_only' (cancellable) argument.

-- This is to be shown when nothing is open yet and is a small subset of the greater menu that
-- will be overwritten when the full menu is created.

menuList = {
    file_loaded_menu = false,

-- 一级菜单（未导入文件时）
    context_menu = {
        {CASCADE, "加载", "open_menu", "", "", false},
        {SEP},
        {CASCADE, "画面", "output_menu", "", "", false},
        {SEP},
        {CASCADE, "其它", "etc_menu", "", "", false},
        {SEP},
        {CASCADE, "关于", "about_menu", "", "", false},
        {COMMAND, "退出 mpv", "q", "quit", "", false},
    },

-- 二级菜单 —— 加载
    open_menu = {
        {COMMAND, "[外置脚本] 文件", "CTRL+o", "script-message-to open_dialog import_files", "", false},
        {COMMAND, "[外置脚本] 地址", "CTRL+O", "script-message-to open_dialog import_url", "", false},
        {COMMAND, "[外置脚本] 内置文件浏览器", "Tab", "script-message-to file_browser browse-files;script-message-to file_browser dynamic/reload;show-text ''", "", false},
        {COMMAND, "[外置脚本] 加载最后播放文件", "CTRL+l", "script-binding simplehistory/history-load-last", "", false},
        {COMMAND, "[外置脚本] 加载最后播放文件及进度", "CTRL+L", "script-binding simplehistory/history-resume", "", false},
        {COMMAND, "[外置脚本] 开/关 隐身历史", "ALT+l", "script-binding simplehistory/history-incognito-mode", "", false},
        {COMMAND, "[外置脚本] 打开  历史菜单", "`", "script-binding simplehistory/open-list;show-text ''", "", false},
        {COMMAND, "[外置脚本] 打开  书签菜单", "N", "script-binding simplebookmark/open-list;show-text ''", "", false},
        {COMMAND, "[外部脚本] 打开  剪贴菜单", "ALT+w", "script-binding smartcopypaste_II/open-list;show-text ''", "", false},
    },

-- 二级菜单 —— 画面
    output_menu = {
        {CHECK, "窗口置顶", "ALT+t", "cycle ontop", function() return propNative("ontop") end, false},
        {CHECK, "窗口边框", "CTRL+B", "cycle border", function() return propNative("border") end, false},
        {CHECK, "全屏", "ENTER", "cycle fullscreen", function() return propNative("fullscreen") end, false},
    },

-- 二级菜单 —— 其它
    etc_menu = {
        {COMMAND, "[内部脚本] 控制台", "~", "script-binding console/enable", "", false},
        {COMMAND, "[外置脚本] OSD高级音频设备菜单", "F6", "script-message-to adevice_list toggle-adevice-browser;show-text ''", "", false},
        {COMMAND, "[外部脚本] 更新  脚本着色器", "M", "script-message manager-update-all;show-text 更新脚本着色器", "", false},
    },

-- 二级菜单 —— 关于
    about_menu = {
        {COMMAND, mp.get_property("mpv-version"), "", "", "", false},
        {COMMAND, "ffmpeg " .. mp.get_property("ffmpeg-version"), "", "", "", false},
        {COMMAND, "libass " .. mp.get_property("libass-version"), "", "", "", false},
    },

}

-- If mpv enters a stopped state, change the change the menu back to the "no file loaded" menu
-- so that it will still popup.
menuListBase = menuList

-- DO NOT create the "playing" menu tables until AFTER the file has loaded as we're unable to
-- dynamically create some menus if it tries to build the table before the file is loaded.
-- A prime example is the chapter-list or track-list values, which are unavailable until
-- the file has been loaded.

local function playmenuList()
    menuList = {
        file_loaded_menu = true,

-- 一级菜单（已导入文件后）
        context_menu = {
            {CASCADE, "加载", "open_menu", "", "", false},
            {SEP},
            {CASCADE, "文件", "file_menu", "", "", false},
            {CASCADE, "导航", "navi_menu", "", "", false},
            {CASCADE, "画面", "output_menu", "", "", false},
            {CASCADE, "视频", "video_menu", "", "", false},
            {CASCADE, "音频", "audio_menu", "", "", false},
            {CASCADE, "字幕", "subtitle_menu", "", "", false},
            {SEP},
            {CASCADE, "滤镜", "filter_menu", "", "", false},
            {CASCADE, "着色器", "shader_menu", "", "", false},
            {CASCADE, "配置组", "profile_menu", "", "", false},
            {CASCADE, "其它", "etc_menu", "", "", false},
            {CASCADE, "工具", "tool_menu", "", "", false},
            {SEP},
            {CASCADE, "关于", "about_menu", "", "", false},
            {COMMAND, "最小化", "b", "cycle window-minimized", "", false},
            {COMMAND, "退出 mpv", "q", "quit", "", false},
            {COMMAND, "退出并保存当前文件状态", "Q", "quit-watch-later", "", false},
        },

-- 二级菜单 —— 加载
        open_menu = {
            {COMMAND, "[外置脚本] 文件", "CTRL+o", "script-message-to open_dialog import_files", "", false},
            {COMMAND, "[外置脚本] 地址", "CTRL+O", "script-message-to open_dialog import_url", "", false},
            {CASCADE, "[外置脚本] 书签", "bookmarker_menu", "", "", false},
            {CASCADE, "[外部脚本] 剪贴", "copy_menu", "", "", false},
            {CASCADE, "[外部脚本] 章节制作", "chaptercreat_menu", "", "", false},
            {COMMAND, "[外置脚本] 内置文件浏览器", "Tab", "script-message-to file_browser browse-files;script-message-to file_browser dynamic/reload;show-text ''", "", false},
            {COMMAND, "[外置脚本] 开/关 隐身历史", "ALT+l", "script-binding simplehistory/history-incognito-mode", "", false},
            {COMMAND, "[外置脚本] 打开  历史菜单", "`", "script-binding simplehistory/open-list;show-text ''", "", false},
            {SEP},
            {COMMAND, "[外置脚本] 加载其他字幕（切换）", "ALT+e", "script-message-to open_dialog append_sid", "", false},
            {COMMAND, "[外置脚本] 加载其他音轨（不切换）", "ALT+E", "script-message-to open_dialog append_aid", "", false},
            {COMMAND, "[外置脚本] 装载次字幕（滤镜型）", "CTRL+e", "script-message-to open_dialog append_vfSub", "", false},
            {COMMAND, "[外置脚本] 隐藏/显示 次字幕", "CTRL+E", "script-message-to open_dialog toggle_vfSub", "", false},
            {COMMAND, "[外置脚本] 移除次字幕", "CTRL+ALT+e", "script-message-to open_dialog remove_vfSub", "", false},
        },

-- 三级菜单 —— 书签
        bookmarker_menu = {
            {COMMAND, "打开书签菜单", "N", "script-binding simplebookmark/open-list;show-text ''", "", false},
            {COMMAND, "添加进度书签", "CTRL+n", "script-binding simplebookmark/bookmark-save", "", false},
            {COMMAND, "添加文件书签", "ALT+n", "script-binding simplebookmark/bookmark-fileonly", "", false},
        },
-- 三级菜单 —— 剪贴
        copy_menu = {
            {COMMAND, "打开剪贴菜单", "ALT+w", "script-binding smartcopypaste_II/open-list;show-text ''", "", false},
            {COMMAND, "复制文件路径", "CTRL+ALT+c", "script-binding smartcopypaste_II/copy-specific", "", false},
            {COMMAND, "复制文件路径及进度", "CTRL+c", "script-binding smartcopypaste_II/copy", "", false},
            {COMMAND, "跳转到复制内容", "CTRL+v", "script-binding smartcopypaste_II/paste", "", false},
            {COMMAND, "复制内容添加至播放列表", "CTRL+ALT+v", "script-binding smartcopypaste_II/paste-specific", "", false},
        },
-- 三级菜单 —— 章节制作
        chaptercreat_menu = {
            {COMMAND, "标记章节时间", "ALT+C", "script-message create_chapter", "", false},
            {COMMAND, "创建chp外部章节文件", "ALT+B", "script-message write_chapter", "", false},
            {COMMAND, "创建xml外部章节文件", "CTRL+ALT+b", "script-message write_chapter_xml", "", false},
        },
-- 二级菜单 —— 文件
        file_menu = {
            {CHECK, "播放/暂停", "SPACE", "cycle pause;show-text 暂停:${pause}", function() return propNative("pause") end, false},
            {COMMAND, "停止", "SHIFT+F11", "stop", "", false},
            {COMMAND, "重置播放中更改项", "R", "cycle-values reset-on-next-file all no vf,af,border,contrast,brightness,gamma,saturation,hue,video-zoom,video-rotate,video-pan-x,video-pan-y,panscan,speed,audio,sub,audio-delay,sub-pos,sub-scale,sub-delay,sub-speed,sub-visibility;show-text 播放下一个文件时重置以下选项:${reset-on-next-file}", "", false},
            {SEP},
            {AB, "A-B循环", "l", "ab-loop", function() return stateABLoop() end, false},
            {CHECK, "循环播放", "L", "cycle-values loop-file inf no;show-text 循环播放:${loop-file}", function() return stateFileLoop() end, false},
            {SEP},
            {COMMAND, "速度 -0.1", "[", "add speed -0.1;show-text 减速播放:${speed}", "", false},
            {COMMAND, "速度 +0.1", "]", "add speed  0.1;show-text 加速播放:${speed}", "", false},
            {COMMAND, "半速", "{", "set speed 0.5;show-text 半速播放:${speed}", "", false},
            {COMMAND, "倍速", "}", "set speed 2;show-text 倍速播放:${speed}", "", false},
            {COMMAND, "重置速度", "BS", "set speed 1;show-text 重置播放速度:${speed}", "", false},
            {SEP},
            {COMMAND, "[外置脚本] 定位当前文件", "ALT+o", "script_message-to locatefile locate-current-file", "", false},
            {COMMAND, "[外置脚本] 删除当前文件", "CTRL+DEL", "script-message-to delete_current_file delete-file 1 '请按1确认删除'", "", false},
            {CASCADE, "[外置脚本] Youtube-dl菜单", "ytdl_menu", "", "", false},
        },

-- 三级菜单 —— Youtube-dl菜单
        ytdl_menu = {
            {COMMAND, "开/关 ytdl视频选择菜单", "CTRL+F", "script-message-to quality_menu video_formats_toggle;show-text ''", "", false},
            {COMMAND, "开/关 ytdl音频选择菜单", "ALT+F", "script-message-to quality_menu audio_formats_toggle;show-text ''", "", false},
            {COMMAND, "重新加载", "CTRL+ALT+f", "script-message-to quality_menu reload", "", false},
            {COMMAND, "下载ytdl视频", "ALT+V", "script-message-to youtube_download download-video", "", false},
            {COMMAND, "下载ytdl音频", "ALT+Y", "script-message-to youtube_download download-audio", "", false},
            {COMMAND, "下载ytdl字幕", "ALT+Z", "script-message-to youtube_download download-subtitle", "", false},
            {COMMAND, "下载ytdl字幕+视频", "CTRL+ALT+V", "script-message-to youtube_download download-embed-subtitle", "", false},
            {COMMAND, "选择ytdl下载片段", "ALT+R", "script-message-to youtube_download select-range-start", "", false},
        },

-- 二级菜单 —— 导航
        navi_menu = {
            {CHECK, "显示OSD时间轴", "O", "no-osd cycle-values osd-level 3 1", function() return stateOsdLevel(3) end, false},
--            {COMMAND, "显示OSD时间轴", "O", "no-osd cycle-values osd-level 3 1", "", false},
--            {RADIO, " 开", "", "set osd-level 3", function() return stateOsdLevel(3) end, false},
--            {RADIO, " 关", "", "set osd-level 1", function() return stateOsdLevel(1) end, false},  
            {COMMAND, "OSD轨道信息", "", "show-text ${track-list} 5000", "", false},
            {CASCADE, "OSD交互菜单", "advosd_menu", "", "", false},
            {SEP},
            {CASCADE, "版本（Edition）", "edition_menu", "", "", function() return inspectEdition() end},
            {CASCADE, "章节", "chapter_menu", "", "", function() return inspectChapter() end},
            {SEP},
            {CHECK, "列表循环", "", "cycle-values loop-playlist inf no", function() return statePlayLoop() end, false},
            {CHECK, "随机播放", "", "cycle shuffle", function() return propNative("shuffle") end, false},
            {COMMAND, "清除播放列表", "", "playlist-clear", "", false},
            {COMMAND, "播放列表乱序重排", "", "playlist-shuffle", "", false},
            {COMMAND, "播放列表恢复排序", "", "playlist-unshuffle", "", false},
            {SEP},
            {COMMAND, "重播", "", "seek 0 absolute", "", false},
            {COMMAND, "上个文件", "<", "playlist-prev;show-text 播放列表:${playlist-pos-1}/${playlist-count}", "", false},
            {COMMAND, "下个文件", ">", "playlist-next;show-text 播放列表:${playlist-pos-1}/${playlist-count}", "", false},
            {COMMAND, "上一帧", ",", "frame-back-step;show-text 当前帧:${estimated-frame-number}", "", false},
            {COMMAND, "下一帧", ".", "frame-step;show-text 当前帧:${estimated-frame-number}", "", false},
            {CASCADE, "前进后退", "seek_menu", "", "", false},
            {SEP},
            {CASCADE, "[外置脚本] 跳转", "undoredo_menu", "", "", false},
            {COMMAND, "[外置脚本] 自动跳过指定章节", "ALT+q", "script-message-to chapterskip chapter-skip;show-text 自动跳过指定章节", "", false},
            {COMMAND, "[外置脚本] 跳到下一个静音位置", "F4", "script-message-to skiptosilence skip-to-silence;show-text 跳到下一个静音位置", "", false},
        },

        -- Use functions returning tables, since we don't need these menus if there aren't any editions or any chapters to seek through.
        edition_menu = editionMenu(),
        chapter_menu = chapterMenu(),

-- 三级菜单 —— OSD交互菜单
        advosd_menu = {
            {COMMAND, "[外置脚本] 播放列表", "F7", "script-message-to playlistmanager showplaylist;show-text ''", "", false},
            {COMMAND, "[外置脚本] 章节列表", "F8", "script-message-to chapter_list toggle-chapter-browser;show-text ''", "", false},
            {COMMAND, "[外置脚本] 视频轨列表", "F9", "script-message-to track_menu toggle-vidtrack-browser;show-text ''", "", false},
            {COMMAND, "[外置脚本] 音频轨列表", "F10", "script-message-to track_menu toggle-audtrack-browser;show-text ''", "", false},
            {COMMAND, "[外置脚本] 字幕轨列表", "F11", "script-message-to track_menu toggle-subtrack-browser;show-text ''", "", false},
            {COMMAND, "[外置脚本] Edition列表", "F12", "script-message-to editions_notification_menu toggle-edition-browser;show-text ''", "", false},
        },

-- 三级菜单 —— 前进后退
        seek_menu = {
            {COMMAND, "前进05秒", "LEFT", "seek 5", "", false},
            {COMMAND, "后退05秒", "RIGHT", "seek -5", "", false},
            {COMMAND, "前进60秒", "UP", "seek 60", "", false},
            {COMMAND, "后退60秒", "DOWN", "seek -60", "", false},
            {COMMAND, "精准前进01秒", "SHIFT+LEFT", "seek  1 exact", "", false},
            {COMMAND, "精准后退01秒", "SHIFT+RIGHT", "seek -1 exact", "", false},
            {COMMAND, "精准前进80秒", "SHIFT+UP", "seek  80 exact", "", false},
            {COMMAND, "精准后退80秒", "SHIFT+DOWN", "seek -80 exact", "", false},
        },
 
-- 三级菜单 —— 跳转
        undoredo_menu = {
            {COMMAND, "撤消跳转", "CTRL+z", "script-binding undoredo/undo", "", false},
            {COMMAND, "重做跳转", "CTRL+r", "script-binding undoredo/redo", "", false},
            {COMMAND, "循环跳转", "CTRL+ALT+z", "script-binding undoredo/undoLoop", "", false},
        },

-- 二级菜单 —— 画面
        output_menu = {
            {CHECK, "窗口置顶", "ALT+t", "cycle ontop;show-text 置顶:${ontop}", function() return propNative("ontop") end, false},
--            {COMMAND, "窗口置顶", "", "cycle ontop", "", false},
--            {RADIO, "关", "", "set ontop yes", function() return stateOnTop(false) end, false},
--            {RADIO, "开", "", "set ontop no", function() return stateOnTop(true) end, false},
            {CHECK, "窗口边框", "CTRL+B", "cycle border", function() return propNative("border") end, false},
            {CHECK, "最大化", "ALT+b", "cycle window-maximized", function() return propNative("window-maximized") end, false},
            {CHECK, "全屏", "ENTER", "cycle fullscreen", function() return propNative("fullscreen") end, false},
            {CASCADE, "长宽比", "aspect_menu", "", "", false},
            {SEP},
            {COMMAND, "裁切填充（无/最大）", "ALT+p", "cycle-values panscan 0.0 1.0;show-text 视频画面缩放:${panscan}", "", false},
            {COMMAND, "左旋转", "CTRL+LEFT", "cycle-values video-rotate 0 270 180 90;show-text 视频旋转:${video-rotate}", "", false},
            {COMMAND, "右旋转", "CTRL+RIGHT", "cycle-values video-rotate 0 90 180 270;show-text 视频旋转:${video-rotate}", "", false},
            {COMMAND, "画面缩小", "ALT+-", "add video-zoom -0.1;show-text 画面缩小:${video-zoom}", "", false},
            {COMMAND, "画面放大", "ALT+=", "add video-zoom  0.1;show-text 画面放大:${video-zoom}", "", false},
            {CASCADE, "画面移动", "videopan_menu", "", "", false},
            {COMMAND, "窗口缩小", "CTRL+-", "add current-window-scale -0.1;show-text 当前窗口缩小:${current-window-scale}", "", false},
            {COMMAND, "窗口放大", "CTRL+=", "add current-window-scale  0.1;show-text 当前窗口放大:${current-window-scale}", "", false},
            {COMMAND, "重置", "ALT+BS", "set video-zoom 0;set panscan 0;set video-rotate 0;set video-pan-x 0;set video-pan-y 0;show-text 重置画面操作", "", false},
            {SEP},
            {CHECK, "自动ICC校色", "CTRL+I", "cycle icc-profile-auto;show-text ICC自动校色:${icc-profile-auto}", function() return propNative("icc-profile-auto") end, false},
            {CHECK, "非线性色彩转换", "ALT+s", "cycle sigmoid-upscaling;show-text 非线性色彩转换:${sigmoid-upscaling}", function() return propNative("sigmoid-upscaling") end, false},
            {COMMAND, "切换 gamma环境系数", "G", "cycle-values gamma-factor 1.1 1.2 1.0;show-text gamma环境系数:${gamma-factor}", "", false},
            {COMMAND, "切换 hdr映射曲线 ", "h", "cycle-values tone-mapping auto mobius reinhard hable bt.2390 gamma spline bt.2446a;show-text hdr映射曲线:${tone-mapping}", "", false},
            {COMMAND, "切换 hdr动态映射", "ALT+h", "cycle-values hdr-compute-peak yes no;show-text hdr动态映射:${hdr-compute-peak}", "", false},
            {COMMAND, "切换 色调映射模式", "CTRL+t", "cycle tone-mapping-mode;show-text 色调映射模式:${tone-mapping-mode}", "", false},
            {COMMAND, "切换 色域剪切模式", "CTRL+g", "cycle gamut-mapping-mode;show-text 色域剪切方式:${gamut-mapping-mode}", "", false},
        },

-- 三级菜单 —— 长宽比
        aspect_menu = {
            {COMMAND, "重置", "", "set video-aspect-override -1", "", false},
            {RADIO, "强制4:3", "", "set video-aspect-override 4:3", function() return stateRatio("4:3") end, false},
            {RADIO, "强制16:9", "", "set video-aspect-override 16:9", function() return stateRatio("16:9") end, false},
            {RADIO, "强制16:10", "", "set video-aspect-override 16:10", function() return stateRatio("16:10") end, false},
            {RADIO, "强制1.85:1", "", "set video-aspect-override 1.85:1", function() return stateRatio("1.85:1") end, false},
            {RADIO, "强制2.35:1", "", "set video-aspect-override 2.35:1", function() return stateRatio("2.35:1") end, false},
        },

-- 三级菜单 —— 画面移动
        videopan_menu = {
            {COMMAND, "重置", "", "set video-pan-x 0;set video-pan-y 0;show-text 重置画面移动", "", false},
            {COMMAND, "画面左移动", "ALT+LEFT", "add video-pan-x -0.1;show-text 画面左移动:${video-pan-x}", "", false},
            {COMMAND, "画面右移动", "ALT+RIGHT", "add video-pan-x  0.1;show-text 画面右移动:${video-pan-x}", "", false},
            {COMMAND, "画面上移动", "ALT+UP", "add video-pan-y -0.1;show-text 画面上移动:${video-pan-y}", "", false},
            {COMMAND, "画面下移动", "ALT+DOWN", "add video-pan-y  0.1;show-text 画面下移动:${video-pan-y}", "", false},
        },

-- 二级菜单 —— 视频
        video_menu = {
            {CASCADE, "轨道", "vidtrack_menu", "", "", function() return inspectVidTrack() end},
            {SEP},
            {CASCADE, "解码模式", "hwdec_menu", "", "", false},
            {COMMAND, "开/关 flip模式", "CTRL+f", "cycle d3d11-flip;show-text flip模式:${d3d11-flip}", "", false},
            {COMMAND, "开/关 兼容x264旧编码模式", "", "cycle vd-lavc-assume-old-x264;show-text 兼容x264旧编码模式:${vd-lavc-assume-old-x264}", "", false},
            {COMMAND, "切换  帧同步模式", "CTRL+p", "cycle-values video-sync display-resample audio display-vdrop display-resample-vdrop;show-text 帧同步模式:${video-sync}", "", false},
            {CHECK, "抖动补偿", "ALT+i", "cycle interpolation;show-text 抖动补偿:${interpolation}", function() return propNative("interpolation") end, false},
            {COMMAND, "开/关 去黑边", "C", "script-message-to dynamic_crop toggle_crop", "", false},
            {CHECK, "去交错", "d", "cycle deinterlace;show-text 去交错:${deinterlace}", function() return propNative("deinterlace") end, false},
            {CHECK, "去色带", "D", "cycle deband;show-text 去色带:${deband}", function() return propNative("deband") end, false},
            {COMMAND, "去色带强度+1", "ALT+z", "add deband-iterations +1;show-text 增加去色带强度:${deband-iterations}", "", false},
            {COMMAND, "去色带强度-1", "ALT+x", "add deband-iterations -1;show-text 降低去色带强度:${deband-iterations}", "", false},
            {SEP},
            {CASCADE, "调色", "color_menu", "", "", false},
            {CASCADE, "截屏", "screenshot_menu", "", "", false},
            {SEP},
            {CASCADE, "[外置脚本] 剪切片段", "slicing_menu", "", "", false},
            {CASCADE, "[外置脚本] 剪切动图", "webp_menu", "", "", false},
        },

        -- Use function to return list of Video Tracks
        vidtrack_menu = vidTrackMenu(),

-- 三级菜单 —— 解码
        hwdec_menu = {
            {COMMAND, "优先 软解", "", "set hwdec no", "", false},
            {COMMAND, "优先 硬解", "", "set hwdec auto-safe", "", false},
            {COMMAND, "优先 硬解（copy）", "", "set hwdec auto-copy-safe", "", false},
            {SEP},
            {RADIO, "SW", "", "set hwdec no", function() return stateHwdec("no") end, false},
            {RADIO, "nvdec", "", "set hwdec nvdec", function() return stateHwdec("nvdec") end, false},
            {RADIO, "nvdec-copy", "", "set hwdec nvdec-copy", function() return stateHwdec("nvdec-copy") end, false},
            {RADIO, "d3d11va", "", "set hwdec d3d11va", function() return stateHwdec("d3d11va") end, false},
            {RADIO, "d3d11va-copy", "", "set hwdec d3d11va-copy", function() return stateHwdec("d3d11va-copy") end, false},
            {RADIO, "dxva2", "", "set hwdec dxva2", function() return stateHwdec("dxva2") end, false},
            {RADIO, "dxva2-copy", "", "set hwdec dxva2-copy", function() return stateHwdec("dxva2-copy") end, false},
            {RADIO, "cuda", "", "set hwdec cuda", function() return stateHwdec("cuda") end, false},
            {RADIO, "cuda-copy", "", "set hwdec cuda-copy", function() return stateHwdec("cuda-copy") end, false},
        },

-- 三级菜单 —— 调色
        color_menu = {
            {COMMAND, "重置", "CTRL+BS", "no-osd set contrast 0; no-osd set brightness 0; no-osd set gamma 0; no-osd set saturation 0; no-osd set hue 0;show-text 重置调色", "", false},
            {COMMAND, "对比 -1", "1", "add contrast -1;show-text 对比度:${contrast}", "", false},
            {COMMAND, "对比 +1", "2", "add contrast  1;show-text 对比度:${contrast}", "", false},
            {COMMAND, "明亮 -1", "3", "add brightness -1;show-text 亮度:${brightness}", "", false},
            {COMMAND, "明亮 +1", "4", "add brightness  1;show-text 亮度:${brightness}", "", false},
            {COMMAND, "伽马 -1", "5", "add gamma -1;show-text 伽马:${gamma}", "", false},
            {COMMAND, "伽马 +1", "6", "add gamma  1;show-text 伽马:${gamma}", "", false},
            {COMMAND, "饱和 -1", "7", "add saturation -1;show-text 饱和度:${saturation}", "", false},
            {COMMAND, "饱和 +1", "8", "add saturation  1;show-text 饱和度:${saturation}", "", false},
            {COMMAND, "色相 -1", "-", "add hue -1;show-text 色相:${hue}", "", false},
            {COMMAND, "色相 +1", "=", "add hue  1;show-text 色相:${hue}", "", false},
        },

-- 三级菜单 —— 截屏
        screenshot_menu = {
            {COMMAND, "同源尺寸-有字幕-有OSD-单帧", "s", "screenshot subtitles", "", false},
            {COMMAND, "同源尺寸-无字幕-无OSD-单帧", "S", "screenshot video", "", false},
            {COMMAND, "实际尺寸-有字幕-有OSD-单帧", "CTRL+s", "screenshot window", "", false},
            {SEP},
            {COMMAND, "同源尺寸-有字幕-有OSD-逐帧", "", "screenshot subtitles+each-frame", "", false},
            {COMMAND, "同源尺寸-无字幕-无OSD-逐帧", "", "screenshot video+each-frame", "", false},
            {COMMAND, "实际尺寸-有字幕-有OSD-逐帧", "CTRL+S", "screenshot window+each-frame", "", false},
        },

-- 三级菜单 —— 剪切片段
        slicing_menu = {
            {COMMAND, "指定剪切起始/结束位置", "c", "script-message slicing_mark", "", false},
            {COMMAND, "开/关 剪切音频信息", "a", "script-message slicing_audio", "", false},
            {COMMAND, "清除标记", "CTRL+C", "script-message clear_slicing_mark", "", false},
        },

-- 三级菜单 —— 剪切动图
        webp_menu = {
            {COMMAND, "开始时间", "w", "script-message set_webp_start", "", false},
            {COMMAND, "结束时间", "W", "script-message set_webp_end", "", false},
            {COMMAND, "导出webp动图", "CTRL+w", "script-message make_webp", "", false},
            {COMMAND, "导出带字幕的动图", "CTRL+W", "script-message make_webp_with_subtitles", "", false},

        },

-- 二级菜单 —— 音频
        audio_menu = {
            {CASCADE, "轨道", "audtrack_menu", "", "", function() return inspectAudTrack() end},
            {SEP},
            {COMMAND, "切换 音轨", "y", "cycle audio;show-text 音轨切换为:${audio}", "", false},
            {CHECK, "音频规格化", "", "cycle audio-normalize-downmix;show-text 音频规格化:${audio-normalize-downmix}", function() return propNative("audio-normalize-downmix") end, false},
            {CHECK, "音频独占模式", "CTRL+y", "cycle audio-exclusive;show-text 音频独占模式:${audio-exclusive}", function() return propNative("audio-exclusive") end, false},
            {CHECK, "音频同步模式", "CTRL+Y", "cycle hr-seek-framedrop;show-text 音频同步模式:${hr-seek-framedrop}", function() return propNative("hr-seek-framedrop") end, false},
            {COMMAND, "多通道音轨调节各通道音", "F2", "cycle-values  af @loudnorm:lavfi=[loudnorm=I=-16:TP=-3:LRA=4] @dynaudnorm:lavfi=[dynaudnorm=g=5:f=250:r=0.9:p=0.5] \"\"", "", false},
            {SEP},
            {COMMAND, "音量 -1", "9", "add volume -1;show-text 音量:${volume}", "", false},
            {COMMAND, "音量 +1", "0", "add volume  1;show-text 音量:${volume}", "", false},
            {CHECK, function() return muteLabel() end, "m", "cycle mute;show-text 静音:${mute}", function() return propNative("mute") end, false},
            {SEP},
            {COMMAND, "延迟 -0.1", "CTRL+,", "add audio-delay -0.1;show-text 音频延迟:${audio-delay}", "", false},
            {COMMAND, "延迟 +0.1", "CTRL+.", "add audio-delay +0.1;show-text 音频预载:${audio-delay}", "", false},
            {COMMAND, "重置偏移", ";", "set audio-delay 0;show-text 重置音频延迟:${audio-delay}", "", false},
            {SEP},
            {CASCADE, "声道布局", "channel_layout", "", "", false},
            {SEP},
            {COMMAND, "[外置脚本] 开/关 交互式音频设备菜单", "F6", "script-message-to adevice_list toggle-adevice-browser;show-text ''", "", false},
            {COMMAND, "[外置脚本] 开/关 dynaudnorm混音菜单", "ALT+n", "script-message-to drcbox key_toggle_bindings", "", false},
        },

        -- Use function to return list of Audio Tracks
        audtrack_menu = audTrackMenu(),
        channel_layout = audLayoutMenu(),

-- 二级菜单 —— 字幕
        subtitle_menu = {
            {CASCADE, "轨道", "subtrack_menu", "", "", function() return inspectSubTrack() end},
            {SEP},
            {COMMAND, "切换 字幕", "j", "cycle sub;show-text 字幕切换为:${sub}", "", false},
            {COMMAND, "切换 渲染样式", "u", "cycle sub-ass-override;show-text 字幕渲染样式:${sub-ass-override}", "", false},
            {COMMAND, "切换 默认字体", "T", "cycle-values sub-font 'NotoSansCJKsc-Bold' 'NotoSerifCJKsc-Bold';show-text 使用字体:${sub-font}", "", false},
            {COMMAND, "加载次字幕", "k", "cycle secondary-sid;show-text 加载次字幕:${secondary-sid}", "", false},
            {SEP},
            {CASCADE, "字幕兼容性", "sub_menu", "", "", false},
            {SEP},
            {COMMAND, "重置", "SHIFT+BS", "no-osd set sub-delay 0; no-osd set sub-pos 100; no-osd set sub-scale 1.0;show-text 重置字幕状态", "", false},
            {COMMAND, "字号 -0.1", "ALT+j", "add sub-scale -0.1;show-text 字幕缩小:${sub-scale}", "", false},
            {COMMAND, "字号 +0.1", "ALT+k", "add sub-scale  0.1;show-text 字幕放大:${sub-scale}", "", false},
            {COMMAND, "延迟 -0.1", "z", "add sub-delay -0.1;show-text 字幕延迟:${sub-delay}", "", false},
            {COMMAND, "延迟 +0.1", "x", "add sub-delay  0.1;show-text 字幕预载:${sub-delay}", "", false},
            {COMMAND, "上移", "r", "add sub-pos -1;show-text 字幕上移:${sub-pos}", "", false},
            {COMMAND, "下移", "t", "add sub-pos  11;show-text 字幕下移:${sub-pos}", "", false},
--            {SEP},
--            {COMMAND, "字幕纵向位置", "", "cycle-values sub-align-y top bottom", "", false},
--            {RADIO, " 顶部", "", "set sub-align-y top", function() return stateSubAlign("top") end, false},
--            {RADIO, " 底部", "", "set sub-align-y bottom", function() return stateSubAlign("bottom") end, false},
            {SEP},
            {COMMAND, "[外部脚本] 打开  字幕同步菜单", "CTRL+m", "script-message-to autosubsync autosubsync-menu", "", false},
            {COMMAND, "[外部脚本] 开/关 字幕选择脚本", "Y", "script-message sub-select toggle", "", false},
            {COMMAND, "[外部脚本] 导出当前内封字幕", "ALT+m", "script-message-to sub_export export-selected-subtitles", "", false},
        },

        -- Use function to return list of Subtitle Tracks
        subtrack_menu = subTrackMenu(),

-- 三级菜单 —— 字幕兼容性
        sub_menu = {
             {COMMAND, "切换 字体渲染方式", "F", "cycle sub-font-provider;show-text 字体渲染方式:${sub-font-provider}", "", false},
             {COMMAND, "切换 字幕颜色转换方式", "J", "cycle sub-ass-vsfilter-color-compat;show-text 字幕颜色转换方式:${sub-ass-vsfilter-color-compat}", "", false},
             {COMMAND, "切换 ass字幕阴影边框缩放", "X", "cycle-values sub-ass-force-style ScaledBorderAndShadow=no ScaledBorderAndShadow=yes;show-text 强制替换ass样式:${sub-ass-force-style}", "", false},
             {CHECK, "vsfilter系兼容性", "V", "cycle sub-ass-vsfilter-aspect-compat;show-text vsfilter系兼容性:${sub-ass-vsfilter-aspect-compat}", function() return propNative("sub-ass-vsfilter-aspect-compat") end, false},
             {CHECK, "blur标签缩放兼容性", "B", "cycle sub-ass-vsfilter-blur-compat;show-text blur标签缩放兼容性:${sub-ass-vsfilter-blur-compat}", function() return propNative("sub-ass-vsfilter-blur-compat") end, false},
             {SEP},
             {CHECK, "开/关 Unicode双向算法", "", "cycle sub-ass-feature-bidi-brackets;show-text 启用Unicode双向算法:${sub-ass-feature-bidi-brackets}", function() return propNative("sub-ass-feature-bidi-brackets") end, false},
             {CHECK, "开/关 文本整体处理方式", "", "cycle sub-ass-feature-whole-text-layout;show-text 启用文本整体处理:${sub-ass-feature-whole-text-layout}", function() return propNative("sub-ass-feature-whole-text-layout") end, false},
             {CHECK, "开/关 Unicode换行处理方式", "", "cycle sub-ass-feature-wrap-unicode;show-text 启用Unicode换行处理:${sub-ass-feature-wrap-unicode}", function() return propNative("sub-ass-feature-wrap-unicode") end, false},
             {SEP},
             {CHECK, "ass字幕输出到黑边", "H", "cycle sub-ass-force-margins;show-text ass字幕输出黑边:${sub-ass-force-margins}", function() return propNative("sub-ass-force-margins") end, false},
             {CHECK, "srt字幕输出到黑边", "Z", "cycle sub-use-margins;show-text srt字幕输出黑边:${sub-use-margins}", function() return propNative("sub-use-margins") end, false},
             {CHECK, "pgs字幕输出到黑边", "P", "cycle stretch-image-subs-to-screen;show-text pgs字幕输出黑边:${stretch-image-subs-to-screen}", function() return propNative("stretch-image-subs-to-screen") end, false},
             {CHECK, "pgs字幕灰度转换", "p", "cycle sub-gray;show-text pgs字幕灰度转换:${sub-gray}", function() return propNative("sub-gray") end, false},
            },
-- 二级菜单 —— 滤镜
        filter_menu = {
            {COMMAND, "清除全部视频滤镜", "CTRL+`", "vf clr \"\"", "", false},
            {COMMAND, "清除全部音频滤镜", "ALT+`", "af clr \"\"", "", false},
            {SEP},
            {COMMAND, opt.filter01B, opt.filter01C, opt.filter01D, "", false, opt.filter01G},
            {COMMAND, opt.filter02B, opt.filter02C, opt.filter02D, "", false, opt.filter02G},
            {COMMAND, opt.filter03B, opt.filter03C, opt.filter03D, "", false, opt.filter03G},
            {COMMAND, opt.filter04B, opt.filter04C, opt.filter04D, "", false, opt.filter04G},
            {COMMAND, opt.filter05B, opt.filter05C, opt.filter05D, "", false, opt.filter05G},
            {COMMAND, opt.filter06B, opt.filter06C, opt.filter06D, "", false, opt.filter06G},
            {COMMAND, opt.filter07B, opt.filter07C, opt.filter07D, "", false, opt.filter07G},
            {COMMAND, opt.filter08B, opt.filter08C, opt.filter08D, "", false, opt.filter08G},
            {COMMAND, opt.filter09B, opt.filter09C, opt.filter09D, "", false, opt.filter09G},
            {COMMAND, opt.filter10B, opt.filter10C, opt.filter10D, "", false, opt.filter10G},
        },

-- 二级菜单 —— 着色器
        shader_menu = {
            {COMMAND, "清除全部着色器", "CTRL+0", "change-list glsl-shaders clr \"\"", "", false},
            {SEP},
            {COMMAND, opt.shader01B, opt.shader01C, opt.shader01D, "", false, opt.shader01G},
            {COMMAND, opt.shader02B, opt.shader02C, opt.shader02D, "", false, opt.shader02G},
            {COMMAND, opt.shader03B, opt.shader03C, opt.shader03D, "", false, opt.shader03G},
            {COMMAND, opt.shader04B, opt.shader04C, opt.shader04D, "", false, opt.shader04G},
            {COMMAND, opt.shader05B, opt.shader05C, opt.shader05D, "", false, opt.shader05G},
            {COMMAND, opt.shader06B, opt.shader06C, opt.shader06D, "", false, opt.shader06G},
            {COMMAND, opt.shader07B, opt.shader07C, opt.shader07D, "", false, opt.shader07G},
            {COMMAND, opt.shader08B, opt.shader08C, opt.shader08D, "", false, opt.shader08G},
            {COMMAND, opt.shader09B, opt.shader09C, opt.shader09D, "", false, opt.shader09G},
            {COMMAND, opt.shader10B, opt.shader10C, opt.shader10D, "", false, opt.shader10G},
        },

-- 二级菜单 —— 其它
        etc_menu = {
            {COMMAND, "[内部脚本] 状态信息（开/关）", "I", "script-binding stats/display-stats-toggle", "", false},
            {COMMAND, "[内部脚本] 状态信息-概览", "", "script-binding stats/display-page-1", "", false},
            {COMMAND, "[内部脚本] 状态信息-帧计时（可翻页）", "", "script-binding stats/display-page-2", "", false},
            {COMMAND, "[内部脚本] 状态信息-输入缓存", "", "script-binding stats/display-page-3", "", false},
            {COMMAND, "[内部脚本] 状态信息-快捷键（可翻页）", "", "script-binding stats/display-page-4", "", false},
            {COMMAND, "[内部脚本] 状态信息-内部流（可翻页）", "", "script-binding stats/display-page-0", "", false},
            {COMMAND, "[内部脚本] 控制台", "~", "script-binding console/enable", "", false},
        },

-- 二级菜单 —— 工具
        tool_menu = {
            {COMMAND, "[外部脚本] 匹配视频刷新率", "CTRL+F10", "script-binding change_refresh/match-refresh", "", false},
            {COMMAND, "[外部脚本] 复制当前时间", "CTRL+ALT+t", "script-message-to copy_subortime copy-time", "", false},
            {COMMAND, "[外部脚本] 复制当前字幕内容", "CTRL+ALT+s", "script-message-to copy_subortime copy-subtitle", "", false},
            {COMMAND, "[外部脚本] 更新脚本着色器", "M", "script-message manager-update-all;show-text 更新脚本着色器", "", false},
        },

-- 二级菜单 —— 配置组
        profile_menu = {
            {COMMAND, "[外部脚本] 切换 指定配置组", "CTRL+P", "script-message cycle-commands \"apply-profile Anime4K;show-text 配置组：Anime4K\" \"apply-profile ravu-3x;show-text 配置组：ravu-3x\" \"apply-profile Normal;show-text 配置组：Normal\" \"apply-profile AMD-FSR_EASU;show-text 配置组：AMD-FSR_EASU\" \"apply-profile NNEDI3;show-text 配置组：NNEDI3\"", "", false},
            {SEP},
            {COMMAND, "切换 Normal配置", "ALT+1", "apply-profile Normal;show-text 配置组：Normal", "", false},
            {COMMAND, "切换 Normal+配置", "ALT+2", "apply-profile Normal+;show-text 配置组：Normal+", "", false},
            {COMMAND, "切换 Anime配置", "ALT+3", "apply-profile Anime;show-text 配置组：Anime", "", false},
            {COMMAND, "切换 Anime+配置", "ALT+4", "apply-profile Anime+;show-text 配置组：Anime+", "", false},
            {COMMAND, "切换 Ravu-lite配置", "", "apply-profile ravu-lite;show-text 配置组：ravu-lite", "", false},
            {COMMAND, "切换 Ravu-3x配置", "ALT+5", "apply-profile ravu-3x;show-text 配置组：ravu-3x", "", false},
            {COMMAND, "切换 ACNet配置", "ALT+6", "apply-profile ACNet;show-text 配置组：ACNet", "", false},
            {COMMAND, "切换 ACNet+配置", "", "apply-profile ACNet+;show-text 配置组：ACNet+", "", false},
            {COMMAND, "切换 Anime4K配置", "ALT+7", "apply-profile Anime4K;show-text 配置组：Anime4K", "", false},
            {COMMAND, "切换 Anime4K+配置", "", "apply-profile Anime4K+;show-text 配置组：Anime4K+", "", false},
            {COMMAND, "切换 NNEDI3配置", "ALT+8", "apply-profile NNEDI3;show-text 配置组：NNEDI3", "", false},
            {COMMAND, "切换 NNEDI3+配置", "", "apply-profile NNEDI3+;show-text 配置组：NNEDI3+", "", false},
            {COMMAND, "切换 AMD-FSR_EASU配置", "ALT+9", "apply-profile AMD-FSR_EASU;show-text 配置组：AMD-FSR_EASU", "", false},
            {COMMAND, "切换 Blur2Sharpen配置", "ALT+0", "apply-profile Blur2Sharpen;show-text 配置组：Blur2Sharpen", "", false},
            {COMMAND, "切换 SSIM配置", "", "apply-profile SSIM;show-text 配置组：SSIM", "", false},
            {SEP},
            {COMMAND, "切换 ICC配置", "", "apply-profile ICC;show-text 配置组：ICC", "", false},
            {COMMAND, "切换 ICC+配置", "", "apply-profile ICC+;show-text 配置组：ICC+", "", false},
            {COMMAND, "切换 Target配置", "", "apply-profile Target;show-text 配置组：Target", "", false},
            {COMMAND, "切换 Tscale配置", "", "apply-profile Tscale;show-text 配置组：Tscale", "", false},
            {COMMAND, "切换 Tscale-box配置", "", "apply-profile Tscale-box;show-text 配置组：Tscale-box", "", false},
            {COMMAND, "切换 DeBand-low配置", "ALT+1", "apply-profile DeBand-low;show-text 配置组：DeBand-low", "", false},
            {COMMAND, "切换 DeBand-mediu配置", "ALT+d", "apply-profile DeBand-medium;show-text 配置组：DeBand-medium", "", false},
            {COMMAND, "切换 DeBand-high配置", "ALT+D", "apply-profile DeBand-high;show-text 配置组：DeBand-high", "", false},
        },

-- 二级菜单 —— 关于
        about_menu = {
            {COMMAND, mp.get_property("mpv-version"), "", "", "", false},
            {COMMAND, "ffmpeg " .. mp.get_property("ffmpeg-version"), "", "", "", false},
            {COMMAND, "libass " .. mp.get_property("libass-version"), "", "", "", false},
        },

--[[
留着备用
            -- Y Values: -1 = Top, 0 = Vertical Center, 1 = Bottom
            -- X Values: -1 = Left, 0 = Horizontal Center, 1 = Right
            {RADIO, "Top", "", "set video-align-y -1", function() return stateAlign("y",-1) end, false},
            {RADIO, "Vertical Center", "", "set video-align-y 0", function() return stateAlign("y",0) end, false},
            {RADIO, "Bottom", "", "set video-align-y 1", function() return stateAlign("y",1) end, false},
            {RADIO, "Left", "", "set video-align-x -1", function() return stateAlign("x",-1) end, false},
            {RADIO, "Horizontal Center", "", "set video-align-x 0", function() return stateAlign("x",0) end, false},
            {RADIO, "Right", "", "set video-align-x 1", function() return stateAlign("x",1) end, false},
            {CHECK, "Flip Vertically", "", "vf toggle vflip", function() return stateFlip("vflip") end, false},
            {CHECK, "Flip Horizontally", "", "vf toggle hflip", function() return stateFlip("hflip") end, false}

            {RADIO, "Display on Letterbox", "", "set image-subs-video-resolution \"no\"", function() return stateSubPos(false) end, false},
            {RADIO, "Display in Video", "", "set image-subs-video-resolution \"yes\"", function() return stateSubPos(true) end, false},
            {COMMAND, "Move Up", "", function() movePlaylist("up") end, "", function() return (propNative("playlist-count") < 2) and true or false end},
            {COMMAND, "Move Down", "", function() movePlaylist("down") end, "", function() return (propNative("playlist-count") < 2) and true or false end},
]]--

    }

    -- This check ensures that all tables of data without SEP in them are 6 or 7 items long.
    for key, value in pairs(menuList) do
        -- Skip the 'file_loaded_menu' key as the following for loop will fail due to an
        -- attempt to get the length of a boolean value.
        if (key == "file_loaded_menu") then goto keyjump end

        for i = 1, #value do
            if (value[i][1] ~= SEP) then
                if (#value[i] < 6 or #value[i] > 7) then mpdebug("Menu item at index of " .. i .. " is " .. #value[i] .. " items long for: " .. key) end
            end
        end
        
        ::keyjump::
    end
end

mp.add_hook("on_preloaded", 100, playmenuList)

local function observe_change()
    mp.observe_property("track-list/count", "number", playmenuList)
    mp.observe_property("chapter-list/count", "number", playmenuList)
end

mp.register_event("file-loaded", observe_change)

mp.register_event("end-file", function()
    mp.unobserve_property(playmenuList)
    menuList = menuListBase
end)

--[[ ************ 菜单内容 ************ ]]--

local menuEngine = require "contextmenu_gui_engine"

mp.register_script_message("contextmenu_tk", function()
    menuEngine.createMenu(menuList, "context_menu", -1, -1, "tk")
end)

