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

-- Edition menu functions
local function enableEdition()
    local editionState = false
    if (propNative("edition-list/count") < 1) then editionState = true end
    return editionState
end

local function checkEdition(editionNum)
    local editionEnable, editionCur = false, propNative("edition")
    if (editionNum == editionCur) then editionEnable = true end
    return editionEnable
end

local function editionMenu()
    local editionCount = propNative("edition-list/count")
    local editionMenuVal = {}

    if not (editionCount == 0) then
        for editionNum=0, (editionCount - 1), 1 do
            local editionTitle = propNative("edition-list/" .. editionNum .. "/title")
            if not (editionTitle) then editionTitle = "Edition " .. (editionNum + 1) end

            local editionCommand = "set edition " .. editionNum
            table.insert(editionMenuVal, {RADIO, editionTitle, "", editionCommand, function() return checkEdition(editionNum) end, false})
        end
    else
        table.insert(editionMenuVal, {COMMAND, "No Editions", "", "", ""})
    end

    return editionMenuVal
end

-- Chapter menu functions
local function enableChapter()
    local chapterEnable = false
    if (propNative("chapter-list/count") < 1) then chapterEnable = true end
    return chapterEnable
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
    if not (chapterCount == 0) then
        for chapterNum=0, (chapterCount - 1), 1 do
            local chapterTitle = propNative("chapter-list/" .. chapterNum .. "/title")
            if not (chapterTitle) then chapterTitle = "章节 " .. (chapterNum + 1) end

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

-- 视频轨子菜单
local function enableVidTrack()
    local vidTrackEnable, vidTracks = false, trackCount("video")
    if (#vidTracks < 1) then vidTrackEnable = true end
    return vidTrackEnable
end

local function vidTrackMenu()
    local vidTrackMenuVal, vidTrackCount = {}, trackCount("video")

    if not (#vidTrackCount == 0) then
        for i = 1, #vidTrackCount, 1 do
            local vidTrackNum = vidTrackCount[i]
            local vidTrackID = propNative("track-list/" .. vidTrackNum .. "/id")
            local vidTrackTitle = propNative("track-list/" .. vidTrackNum .. "/title")
            if not (vidTrackTitle) then vidTrackTitle = "视频轨 " .. i end

            local vidTrackCommand = "set vid " .. vidTrackID
            table.insert(vidTrackMenuVal, {RADIO, vidTrackTitle, "", vidTrackCommand, function() return checkTrack(vidTrackNum) end, false})
        end
    else
        table.insert(vidTrackMenuVal, {RADIO, "无视频轨", "", "", ""})
    end

    return vidTrackMenuVal
end

-- Convert ISO 639-1/639-2 codes to be full length language names. The full length names
-- are obtained by using the property accessor with the iso639_1/_2 tables stored in
-- the contextmenu_gui_lang.lua file (require "langcodes" above).
function getLang(trackLang)
    trackLang = string.upper(trackLang)
    if (string.len(trackLang) == 2) then trackLang = langcodes.iso639_1(trackLang)
    elseif (string.len(trackLang) == 3) then trackLang = langcodes.iso639_2(trackLang) end
    return trackLang
end

function noneCheck(checkType)
    local checkVal, trackID = false, propNative(checkType)
    if (type(trackID) == "boolean") then
        if (trackID == false) then checkVal = true end
    end
    return checkVal
end

-- 音频轨子菜单
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
            -- Convert ISO 639-1/2 codes
            if not (audTrackLang == nil) then audTrackLang = getLang(audTrackLang) and getLang(audTrackLang) or audTrackLang end

            if (audTrackTitle) then audTrackTitle = audTrackTitle .. ((audTrackLang ~= nil) and " (" .. audTrackLang .. ")" or "")
            elseif (audTrackLang) then audTrackTitle = audTrackLang
            else audTrackTitle = "Audio Track " .. i end

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

-- Subtitle label
local function subVisLabel() return propNative("sub-visibility") and "隐藏" or "取消隐藏" end

-- 字幕轨子菜单
local function subTrackMenu()
    local subTrackMenuVal, subTrackCount = {}, trackCount("sub")

    subTrackMenuVal = {
        {COMMAND, "重载当前字幕轨（限外挂）", "", "sub-reload", "", false},
        {COMMAND, "移除当前字幕轨（限外挂）", "", "sub-remove", "", false},
        {CHECK, function() return subVisLabel() end, "v", "cycle sub-visibility", function() return not propNative("sub-visibility") end, false},
    }
    if not (#subTrackCount == 0) then
        for i = 1, (#subTrackCount), 1 do
            local subTrackNum = subTrackCount[i]
            local subTrackID = propNative("track-list/" .. subTrackNum .. "/id")
            local subTrackTitle = propNative("track-list/" .. subTrackNum .. "/title")
            local subTrackLang = propNative("track-list/" .. subTrackNum .. "/lang")
            -- Convert ISO 639-1/2 codes
            if not (subTrackLang == nil) then subTrackLang = getLang(subTrackLang) and getLang(subTrackLang) or subTrackLang end

            if (subTrackTitle) then subTrackTitle = subTrackTitle .. ((subTrackLang ~= nil) and " (" .. subTrackLang .. ")" or "")
            elseif (subTrackLang) then subTrackTitle = subTrackLang
            else subTrackTitle = "Subtitle Track " .. i end

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
        {COMMAND, "【外置脚本】文件", "CTRL+o", "script-binding open_dialog/import_files", "", false},
        {COMMAND, "【外置脚本】地址", "CTRL+O", "script-binding open_dialog/import_url", "", false},
        {COMMAND, "【外置脚本】加载最后播放文件", "CTRL+l", "script-binding simplehistory/history-load-last", "", false},
        {COMMAND, "【外置脚本】加载最后播放文件及进度", "CTRL+L", "script-binding simplehistory/history-resume", "", false},
        {COMMAND, "【外部脚本】打开剪贴菜单", "ALT+w", "script-binding smartcopypaste_II/open-list", "", false},
        {COMMAND, "【外置脚本】打开书签菜单", "N", "script-binding simplebookmark/open-list", "", false},
        {COMMAND, "【外置脚本】打开历史菜单", "`", "script-binding simplehistory/open-list", "", false},
        {COMMAND, "【外置脚本】内置文件浏览器", "Tab", "script-message browse-files", "", false},
    },

-- 二级菜单 —— 画面
    output_menu = {
        {CHECK, "窗口置顶", "ALT+t", "cycle ontop", function() return propNative("ontop") end, false},
        {CHECK, "窗口边框", "ALT+B", "cycle border", function() return propNative("border") end, false},
        {CHECK, "全屏", "ENTER", "cycle fullscreen", function() return propNative("fullscreen") end, false},
        {SEP},
        {COMMAND, "【外置脚本】开/关 进度条预览", "CTRL+T", "cycle-values script-opts thumbnailer-auto_gen=no,thumbnailer-auto_show=no thumbnailer-auto_gen=yes,thumbnailer-auto_show=yes", "", false},
    },

-- 二级菜单 —— 其它
    etc_menu = {
        {COMMAND, "【内部脚本】状态信息（开/关）", "I", "script-binding stats/display-stats-toggle", "", false},
        {COMMAND, "【内部脚本】状态信息-概览", "", "script-binding stats/display-page-1", "", false},
        {COMMAND, "【内部脚本】状态信息-帧计时（可翻页）", "", "script-binding stats/display-page-2", "", false},
        {COMMAND, "【内部脚本】状态信息-输入缓存", "", "script-binding stats/display-page-3", "", false},
        {COMMAND, "【内部脚本】状态信息-快捷键（可翻页）", "", "script-binding stats/display-page-4", "", false},
        {COMMAND, "【内部脚本】状态信息-内部流（可翻页）", "", "script-binding stats/display-page-0", "", false},
        {COMMAND, "【内部脚本】控制台", "~", "script-binding console/enable", "", false},
    },

-- 二级菜单 —— 关于
    about_menu = {
        {COMMAND, mp.get_property("mpv-version"), "", "", "", false},
        {COMMAND, "ffmpeg " .. mp.get_property("ffmpeg-version"), "", "", "", false},
        {COMMAND, "libass " .. mp.get_property("libass-version"), "", "", "", false},
    },

}

-- DO NOT create the "playing" menu tables until AFTER the file has loaded as we're unable to
-- dynamically create some menus if it tries to build the table before the file is loaded.
-- A prime example is the chapter-list or track-list values, which are unavailable until
-- the file has been loaded.

mp.register_event("file-loaded", function()
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
            {COMMAND, "【外置脚本】文件", "CTRL+o", "script-binding open_dialog/import_files", "", false},
            {COMMAND, "【外置脚本】地址", "CTRL+O", "script-binding open_dialog/import_url", "", false},
            {COMMAND, "【外置脚本】打开历史菜单", "`", "script-binding simplehistory/open-list", "", false},
            {COMMAND, "【外置脚本】内置文件浏览器", "Tab", "script-message browse-files", "", false},
            {SEP},
            {COMMAND, "【外置脚本】加载其他字幕（切换）", "ALT+e", "script-binding open_dialog/append_sid", "", false},
            {COMMAND, "【外置脚本】加载其他音轨（不切换）", "ALT+E", "script-binding open_dialog/append_aid", "", false},
            {COMMAND, "【外置脚本】装载次字幕（滤镜型）", "CTRL+e", "script-binding open_dialog/append_vfSub", "", false},
            {COMMAND, "【外置脚本】隐藏/显示 次字幕", "CTRL+E", "script-binding open_dialog/toggle_vfSub", "", false},
            {COMMAND, "【外置脚本】移除次字幕", "CTRL+ALT+e", "script-binding open_dialog/remove_vfSub", "", false},
            {SEP},
            {COMMAND, "播放列表乱序重排", "", "playlist-shuffle", "", false},
            {CHECK, "列表循环", "", "cycle-values loop-playlist inf no", function() return statePlayLoop() end, false},
            {CHECK, "随机播放", "", "cycle shuffle", function() return propNative("shuffle") end, false},
        },

-- 二级菜单 —— 文件
        file_menu = {
            {COMMAND, "停止", "F11", "stop", "", false},
            {CHECK, "播放/暂停", "SPACE", "cycle pause", function() return propNative("pause") end, false},
            {SEP},
            {COMMAND, "显示OSD时间轴", "O", "no-osd cycle-values osd-level 3 1", "", false},
            {RADIO, "开", "", "set osd-level 3", function() return stateOsdLevel(3) end, false},
            {RADIO, "关", "", "set osd-level 1", function() return stateOsdLevel(1) end, false},  
            {SEP},
            {AB, "A-B循环", "l", "ab-loop", function() return stateABLoop() end, false},
            {CHECK, "循环播放", "L", "cycle-values loop-file inf no", function() return stateFileLoop() end, false},
            {SEP},
            {COMMAND, "速度 -0.1", "[", "add speed -0.1", "", false},
            {COMMAND, "速度 +0.1", "]", "add speed 0.1", "", false},
            {COMMAND, "半速", "{", "set speed 0.5", "", false},
            {COMMAND, "倍速", "}", "set speed 2", "", false},
            {COMMAND, "重置速度", "BS", "set speed 1", "", false},
            {SEP},
            {CASCADE, "【外置脚本】删除文件", "del_menu", "", "", false},
        },

-- 三级菜单 —— 删除文件
        del_menu = {
            {COMMAND, "标记/取消", "CTRL+DEL", "script-message delete_file", "", false},
            {COMMAND, "显示删除列表", "ALT+DEL", "script-message list_marks", "", false},
            {COMMAND, "清除删除列表", "CTRL+SHIFT+DEL", "script-message clear_list", "", false},
        },

-- 二级菜单 —— 导航
        navi_menu = {
            {COMMAND, "【外置脚本】OSD高级播放列表", "F8", "script-binding playlistmanager/showplaylist", "", false},
            {COMMAND, "OSD轨道信息", "F9", "show-text ${track-list} 5000", "", false},
            {COMMAND, "重播", "", "seek 0 absolute", "", false},
            {COMMAND, "上个文件", "<", "playlist-prev;show-text ${playlist-pos-1}/${playlist-count}", "", false},
            {COMMAND, "下个文件", ">", "playlist-next;show-text ${playlist-pos-1}/${playlist-count}", "", false},
            {COMMAND, "上一帧", ",", "frame-back-step;show-text ${estimated-frame-number}", "", false},
            {COMMAND, "下一帧", ".", "frame-step;show-text ${estimated-frame-number}", "", false},
            {COMMAND, "后退5秒", "RIGHT", "seek -5", "", false},
            {COMMAND, "前进5秒", "LEFT", "seek 5", "", false},
            {SEP},
            {CASCADE, "【外置脚本】书签", "bookmarker_menu", "", "", false},
            {COMMAND, "【外置脚本】自动跳过指定章节", "ALT+q", "script-message chapter-skip;show-text 自动跳过指定章节", "", false},
            {COMMAND, "【外置脚本】跳到下一个静音位置 ", "F4", "script-message skip-to-silence;show-text 跳到下一个静音位置", "", false},
            {SEP},
--            {CASCADE, "Title/Edition", "edition_menu", "", "", function() return enableEdition() end},
            {CASCADE, "章节", "chapter_menu", "", "", function() return enableChapter() end},
        },

        -- Use functions returning tables, since we don't need these menus if there aren't any editions or any chapters to seek through.
        edition_menu = editionMenu(),
        chapter_menu = chapterMenu(),

-- 三级菜单 —— 书签
        bookmarker_menu = {
            {COMMAND, "打开书签菜单", "N", "script-binding simplebookmark/open-list", "", false},
            {COMMAND, "添加进度书签", "CTRL+n", "script-binding simplebookmark/bookmark-save", "", false},
            {COMMAND, "添加文件书签", "ALT+n", "script-binding simplebookmark/bookmark-fileonly", "", false},
        },

-- 二级菜单 —— 画面
        output_menu = {
            {CHECK, "窗口置顶", "ALT+t", "cycle ontop", function() return propNative("ontop") end, false},
--            {COMMAND, "窗口置顶", "", "cycle ontop", "", false},
--            {RADIO, "关", "", "set ontop yes", function() return stateOnTop(false) end, false},
--            {RADIO, "开", "", "set ontop no", function() return stateOnTop(true) end, false},
            {CHECK, "窗口边框", "ALT+B", "cycle border", function() return propNative("border") end, false},
            {CHECK, "最大化", "ALT+b", "cycle window-maximized", function() return propNative("window-maximized") end, false},
            {CHECK, "全屏", "ENTER", "cycle fullscreen", function() return propNative("fullscreen") end, false},
            {CASCADE, "长宽比", "aspect_menu", "", "", false},
            {SEP},
            {COMMAND, "裁切填充（无/最大）", "ALT+p", "cycle-values panscan 0.0 1.0", "", false},
            {COMMAND, "左旋转", "CTRL+LEFT", "cycle-values video-rotate 0 270 180 90", "", false},
            {COMMAND, "右旋转", "CTRL+RIGHT", "cycle-values video-rotate 0 90 180 270", "", false},
            {COMMAND, "缩小", "ALT+-", "add video-zoom -0.1", "", false},
            {COMMAND, "放大", "ALT+=", "add video-zoom 0.1", "", false},
            {COMMAND, "窗口缩小", "CTRL+-", "add current-window-scale -0.1", "", false},
            {COMMAND, "窗口放大", "CTRL+=", "add current-window-scale 0.1", "", false},
            {COMMAND, "重置", "ALT+BS", "set video-zoom 0;set panscan 0;set video-rotate 0;set video-pan-x 0;set video-pan-y 0", "", false},
            {SEP},
            {CHECK, "自动ICC校色", "CTRL+I", "cycle icc-profile-auto", function() return propNative("icc-profile-auto") end, false},
            {COMMAND, "切换 色调映射基准", "CTRL+t", "cycle tone-mapping-mode", "", false},
            {COMMAND, "切换 色域剪切方式", "CTRL+g", "cycle gamut-mapping-mode", "", false},
            {COMMAND, "切换 gamma环境系数", "G", "cycle-values gamma-factor 1.1 1.2 1.0", "", false},
            {COMMAND, "切换 hdr映射曲线 ", "h", "cycle-values tone-mapping auto mobius reinhard hable bt.2390 gamma spline bt.2446a", "", false},
            {COMMAND, "切换 hdr动态映射", "ALT+h", "cycle-values hdr-compute-peak yes no", "", false},
            {SEP},
            {COMMAND, "【外置脚本】开/关 进度条预览", "CTRL+T", "cycle-values script-opts thumbnailer-auto_gen=no,thumbnailer-auto_show=no thumbnailer-auto_gen=yes,thumbnailer-auto_show=yes", "", false},
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

-- 二级菜单 —— 视频
        video_menu = {
            {CASCADE, "轨道", "vidtrack_menu", "", "", function() return enableVidTrack() end},
            {SEP},
            {CASCADE, "解码模式", "hwdec_menu", "", "", false},
            {COMMAND, "切换 帧同步方式", "CTRL+p", "cycle video-sync", "", false},
            {CHECK, "抖动补偿", "ALT+i", "cycle interpolation", function() return propNative("interpolation") end, false},
            {COMMAND, "开/关 去黑边", "C", "script-message toggle_crop", "", false},
            {CHECK, "去色带", "D", "cycle deband", function() return propNative("deband") end, false},
            {CHECK, "反交错", "d", "cycle deinterlace", function() return propNative("deinterlace") end, false},
            {SEP},
            {CASCADE, "调色", "color_menu", "", "", false},
            {CASCADE, "截屏", "screenshot_menu", "", "", false},
            {SEP},
            {CASCADE, "【外置脚本】剪切片段", "slicing_menu", "", "", false},
            {CASCADE, "【外置脚本】剪切动图", "webp_menu", "", "", false},
        },

        -- Use function to return list of Video Tracks
        vidtrack_menu = vidTrackMenu(),

-- 三级菜单 —— 解码
        hwdec_menu = {
            {COMMAND, "优先 软解", "", "set hwdec no", "", false},
            {COMMAND, "优先 硬解", "", "set hwdec yes", "", false},
            {COMMAND, "优先 硬解（增强）", "", "set hwdec auto-copy", "", false},
            {SEP},
            {RADIO, "SW", "", "set hwdec no", function() return stateHwdec("no") end, false},
            {RADIO, "dxva2", "", "set hwdec dxva2", function() return stateHwdec("dxva2") end, false},
            {RADIO, "dxva2-copy", "", "set hwdec dxva2-copy", function() return stateHwdec("dxva2-copy") end, false},
            {RADIO, "d3d11va", "", "set hwdec d3d11va", function() return stateHwdec("d3d11va") end, false},
            {RADIO, "d3d11va-copy", "", "set hwdec d3d11va-copy", function() return stateHwdec("d3d11va-copy") end, false},
            {RADIO, "qsv", "", "set hwdec qsv", function() return stateHwdec("qsv") end, false},
            {RADIO, "qsv-copy", "", "set hwdec qsv-copy", function() return stateHwdec("qsv-copy") end, false},
            {RADIO, "cuda", "", "set hwdec cuda", function() return stateHwdec("cuda") end, false},
            {RADIO, "cuda-copy", "", "set hwdec cuda-copy", function() return stateHwdec("cuda-copy") end, false},
            {RADIO, "nvdec", "", "set hwdec nvdec", function() return stateHwdec("nvdec") end, false},
            {RADIO, "nvdec-copy", "", "set hwdec nvdec-copy", function() return stateHwdec("nvdec-copy") end, false},

        },

-- 三级菜单 —— 调色
        color_menu = {
            {COMMAND, "重置", "CTRL+BS", "no-osd set contrast 0; no-osd set brightness 0; no-osd set gamma 0; no-osd set saturation 0; no-osd set hue 0", "", false},
            {COMMAND, "对比 -1", "1", "add contrast -1", "", false},
            {COMMAND, "对比 +1", "2", "add contrast 1 ", "", false},
            {COMMAND, "明亮 -1", "3", "add brightness -1", "", false},
            {COMMAND, "明亮 +1", "4", "add brightness 1 ", "", false},
            {COMMAND, "伽马 -1", "5", "add gamma -1", "", false},
            {COMMAND, "伽马 +1", "6", "add gamma 1 ", "", false},
            {COMMAND, "饱和 -1", "7", "add saturation -1", "", false},
            {COMMAND, "饱和 +1", "8", "add saturation 1 ", "", false},
            {COMMAND, "色相 -1", "-", "add hue -1", "", false},
            {COMMAND, "色相 +1", "=", "add hue 1 ", "", false},
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
            {CASCADE, "轨道", "audtrack_menu", "", "", false},
            {COMMAND, "切换 音轨", "y", "cycle audio", "", false},
            {CHECK, "音频独占", "CTRL+y", "cycle audio-exclusive", function() return propNative("audio-exclusive") end, false},
            {CHECK, "音频同步", "CTRL+Y", "cycle hr-seek-framedrop", function() return propNative("hr-seek-framedrop") end, false},
            {COMMAND, "多通道音轨调节各通道音", "F2", "cycle-values  af @audnorm:lavfi=[dynaudnorm=g=5:f=250:r=0.9:p=0.5] @dynnorm:lavfi=[loudnorm=I=-16:TP=-3:LRA=4] \"\"", "", false},
            {SEP},
            {COMMAND, "音量 -1", "9", "add volume -1", "", false},
            {COMMAND, "音量 +1", "0", "add volume  1", "", false},
            {CHECK, function() return muteLabel() end, "m", "cycle mute", function() return propNative("mute") end, false},
            {SEP},
            {COMMAND, "延迟 -0.1", "CTRL+,", "add audio-delay -0.1", "", false},
            {COMMAND, "延迟 +0.1", "CTRL+.", "add audio-delay +0.1", "", false},
            {COMMAND, "重置偏移", ";", "set audio-delay 0", "", false},
            {SEP},
            {COMMAND, "音频设备列表", "F6", "show-text ${audio-device-list} 5000", "", false},
            {COMMAND, "上个输出设备", "CTRL+a", "script-binding cycle_adevice/back", "", false},
            {COMMAND, "下个输出设备", "ALT+a", "script-binding cycle_adevice/next", "", false},
            {CASCADE, "声道布局", "channel_layout", "", "", false},
        },

        -- Use function to return list of Audio Tracks
        audtrack_menu = audTrackMenu(),
        channel_layout = audLayoutMenu(),

-- 二级菜单 —— 字幕
        subtitle_menu = {
            {CASCADE, "轨道", "subtrack_menu", "", "", false},
            {COMMAND, "切换 渲染样式", "u", "cycle sub-ass-override", "", false},
            {COMMAND, "切换 默认字体", "T", "cycle-values sub-font SourceHanSansSC-Bold SourceHanSerifSC-Bold 思源黑体 思源宋体", "", false},
            {COMMAND, "切换 字幕", "j", "cycle sub", "", false},
            {COMMAND, "加载次字幕", "k", "cycle secondary-sid", "", false},
            {COMMAND, "开/关 字幕选择脚本", "Y", "script-message sub-select toggle", "", false},
            {SEP},
            {COMMAND, "重置", "SHIFT+BS", "no-osd set sub-delay 0; no-osd set sub-pos 100; no-osd set sub-scale 1.0", "", false},
            {COMMAND, "字号 -0.1", "ALT+j", "add sub-scale -0.1", "", false},
            {COMMAND, "字号 +0.1", "ALT+k", "add sub-scale  0.1", "", false},
            {COMMAND, "延迟 -0.1", "z", "add sub-delay -0.1", "", false},
            {COMMAND, "延迟 +0.1", "x", "add sub-delay  0.1", "", false},
            {COMMAND, "上移", "r", "add sub-pos -1", "", false},
            {COMMAND, "下移", "t", "add sub-pos  1", "", false},
            {SEP},
            {COMMAND, "字幕纵向位置", "", "cycle-values sub-align-y top bottom", "", false},
            {RADIO, "顶部", "", "set sub-align-y top", function() return stateSubAlign("top") end, false},
            {RADIO, "底部", "", "set sub-align-y bottom", function() return stateSubAlign("bottom") end, false},
            {SEP},
            {CASCADE, "字幕兼容性", "sub_menu", "", "", false},
        },

        -- Use function to return list of Subtitle Tracks
        subtrack_menu = subTrackMenu(),

-- 三级菜单 —— 字幕兼容性
        sub_menu = {
             {COMMAND, "切换 字体渲染方式", "F", "cycle sub-font-provider", "", false},
             {COMMAND, "切换 字幕颜色转换方式", "J", "cycle sub-ass-vsfilter-color-compat", "", false},
             {COMMAND, "切换 ass字幕阴影边框缩放", "X", "cycle-values sub-ass-force-style ScaledBorderAndShadow=no ScaledBorderAndShadow=yes", "", false},
             {CHECK, "vsfilter系兼容", "V", "cycle sub-ass-vsfilter-aspect-compat", function() return propNative("sub-ass-vsfilter-aspect-compat") end, false},
             {CHECK, "blur标签缩放", "B", "cycle sub-ass-vsfilter-blur-compat", function() return propNative("sub-ass-vsfilter-blur-compat") end, false},
             {SEP},
             {CHECK, "ass字幕输出到黑边", "H", "cycle sub-ass-force-margins", function() return propNative("sub-ass-force-margins") end, false},
             {CHECK, "srt字幕输出到黑边", "Z", "cycle sub-use-margins", function() return propNative("sub-use-margins") end, false},
             {CHECK, "pgs字幕输出到黑边", "P", "cycle stretch-image-subs-to-screen", function() return propNative("stretch-image-subs-to-screen") end, false},
             {CHECK, "pgs字幕灰度转换", "p", "cycle sub-gray", function() return propNative("sub-gray") end, false},
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
            {COMMAND, "【内部脚本】状态信息（开/关）", "I", "script-binding stats/display-stats-toggle", "", false},
            {COMMAND, "【内部脚本】状态信息-概览", "", "script-binding stats/display-page-1", "", false},
            {COMMAND, "【内部脚本】状态信息-帧计时（可翻页）", "", "script-binding stats/display-page-2", "", false},
            {COMMAND, "【内部脚本】状态信息-输入缓存", "", "script-binding stats/display-page-3", "", false},
            {COMMAND, "【内部脚本】状态信息-快捷键（可翻页）", "", "script-binding stats/display-page-4", "", false},
            {COMMAND, "【内部脚本】状态信息-内部流（可翻页）", "", "script-binding stats/display-page-0", "", false},
            {COMMAND, "【内部脚本】控制台", "~", "script-binding console/enable", "", false},
        },

-- 二级菜单 —— 工具
        tool_menu = {
            {COMMAND, "【外部脚本】匹配视频刷新率", "F10", "script-message match-refresh", "", false},
            {COMMAND, "【外部脚本】复制当前时间", "CTRL+ALT+t", "script-message copy-time", "", false},
            {COMMAND, "【外部脚本】复制当前字幕内容", "CTRL+ALT+s", "script-message copy-subtitle", "", false},
            {CASCADE, "【外部脚本】视频剪贴功能", "copy_menu", "", "", false},
            {COMMAND, "【外部脚本】更新脚本着色器", "M", "script-binding manager-update-all;show-text 更新脚本着色器", "", false},
        },

-- 三级菜单 —— 视频剪贴功能
        copy_menu = {
            {COMMAND, "【外部脚本】打开剪贴菜单", "ALT+w", "script-binding smartcopypaste_II/open-list", "", false},
            {COMMAND, "【外部脚本】复制视频路径", "CTRL+ALT+c", "script-binding smartcopypaste_II/copy-specific", "", false},
            {COMMAND, "【外部脚本】复制视频路径及进度", "CTRL+c", "script-binding smartcopypaste_II/copy", "", false},
            {COMMAND, "【外部脚本】跳转到复制的视频", "CTRL+v", "script-binding smartcopypaste_II/paste", "", false},
            {COMMAND, "【外部脚本】复制内容添加至播放列表", "CTRL+ALT+v", "script-binding smartcopypaste_II/paste-specific", "", false},
        },

-- 二级菜单 —— 配置组
        profile_menu = {
            {COMMAND, "切换 Normal配置", "ALT+1", "apply-profile Normal;show-text Normal", "", false},
            {COMMAND, "切换 Normal+配置", "ALT+2", "apply-profile Normal+;show-text Normal+", "", false},
            {COMMAND, "切换 Anime配置", "ALT+3", "apply-profile Anime;show-text Anime", "", false},
            {COMMAND, "切换 Anime+配置", "ALT+4", "apply-profile Anime+;show-text Anime+", "", false},
            {COMMAND, "切换 Ravu配置", "", "apply-profile ravu;show-text ravu", "", false},
            {COMMAND, "切换 Ravu-zoom配置", "", "apply-profile ravu-zoom;show-text ravu-zoom", "", false},
            {COMMAND, "切换 Ravu-lite配置", "", "apply-profile ravu-lite;show-text ravu-lite", "", false},
            {COMMAND, "切换 Ravu-3x配置", "ALT+5", "apply-profile ravu-3x;show-text ravu-3x", "", false},
            {COMMAND, "切换 ACNet配置", "ALT+6", "apply-profile ACNet;show-text ACNet", "", false},
            {COMMAND, "切换 ACNet+配置", " ", "apply-profile ACNet+;show-text ACNet+", "", false},
            {COMMAND, "切换 Anime4K配置", "ALT+7", "apply-profile Anime4K;show-text Anime4K", "", false},
            {COMMAND, "切换 Anime4K+配置", "ALT+8", "apply-profile Anime4K+;show-text Anime4K+", "", false},
            {COMMAND, "切换 NNEDI3配置", "ALT+9", "apply-profile NNEDI3;show-text NNEDI3", "", false},
            {COMMAND, "切换 NNEDI3+配置", "ALT+0", "apply-profile NNEDI3+;show-text NNEDI3+", "", false},
            {COMMAND, "切换 SSIM配置", "", "apply-profile SSIM;show-text SSIM", "", false},
            {SEP},
            {COMMAND, "切换 ICC配置", "", "apply-profile ICC;show-text ICC", "", false},
            {COMMAND, "切换 ICC+配置", "", "apply-profile ICC+;show-text ICC+", "", false},
            {COMMAND, "切换 Target配置", "", "apply-profile Target;show-text Target", "", false},
            {COMMAND, "切换 DeBand-low配置", "ALT+1", "apply-profile DeBand-low;show-text DeBand-low", "", false},
            {COMMAND, "切换 DeBand-mediu配置", "ALT+d", "apply-profile DeBand-medium;show-text DeBand-medium", "", false},
            {COMMAND, "切换 DeBand-high配置", "ALT+D", "apply-profile DeBand-high;show-text DeBand-high", "", false},
            {COMMAND, "切换 Tscale配置", "F", "apply-profile Tscale;show-text Tscale", "", false},
            {COMMAND, "切换 Tscale+配置", "f", "apply-profile Tscale+;show-text Tscale+", "", false},
            {COMMAND, "切换 Dither配置", "", "apply-profile Dither;show-text Dither", "", false},
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
end)

--[[ ************ 菜单内容 ************ ]]--

local menuEngine = require "contextmenu_gui_engine"

mp.register_script_message("contextmenu_tk", function()
    menuEngine.createMenu(menuList, "context_menu", -1, -1, "tk")
end)

