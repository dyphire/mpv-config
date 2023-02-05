--[[
  * chapter-make-read.lua v.2023-02-05
  *
  * AUTHORS: dyphire
  * License: MIT
  * link: https://github.com/dyphire/mpv-scripts
--]]

-- Implementation read and automatically load the namesake external chapter file.
-- The external chapter files should conform to the following formats.
-- Note: The Timestamps should use the 12-bit format of 'hh:mm:ss.sss'.
-- Note: The file encoding should be UTF-8 and the linebreak should be Unix(LF).
-- Note: The script also supports reading OGM format and MediaInfo format in addition to the following formats.
--[[
00:00:00.000 A part
00:00:40.312 OP
00:02:00.873 B part
00:10:44.269 C part
00:22:40.146 ED
--]]

-- This script also supports marks,edits,remove and creates external chapter files, usage:
-- Note: It can also be used to export the existing chapter information of the playback file.
-- add bindings to input.conf:
-- key script-message-to chapter_make_read create_chapter
-- key script-message-to chapter_make_read edit_chapter
-- key script-message-to chapter_make_read remove_chapter
-- key script-message-to chapter_make_read write_chapter
-- key script-message-to chapter_make_read write_chapter_ogm
-- key script-message-to chapter_make_read write_chapter_xml

local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require "mp.options"

local o = {
    autoload = true,
    autosave = false,
    -- Specifies the extension of the external chapter file.
    chapter_flie_ext = ".chp",
    -- Specifies the subpath of the same directory as the playback file as the external chapter file path.
    -- Note: The external chapter file is read from the subdirectory first.
    -- If the file does not exist, it will next be read from the same directory as the playback file.
    external_chapter_subpath = "chapters",
    -- Specifies the path of the external chapter file for the network playback file.
    network_chap_dir = "~~/chapters",
    -- ask for title or leave it empty
    ask_for_title = true,
    -- placeholder when asking for title of a new chapter
    placeholder_title = "Chapter ",
    -- pause the playback when asking for chapter title
    pause_on_input = true,
}

(require 'mp.options').read_options(o)

-- Requires: https://github.com/CogentRedTester/mpv-user-input
package.path = mp.command_native({"expand-path", "~~/script-modules/?.lua;"}) .. package.path
local user_input_module, input = pcall(require, "user-input-module")

local curr = nil
local path = nil
local dir = nil
local fname = nil
local all_chapters = {}
local chapter_count = 0
local insert_chapters = ""
local chapters_modified = false
local paused = false

local function is_protocol(path)
    return type(path) == 'string' and (path:match('^%a[%a%d-_]+://') ~= nil or path:match('^%a[%a%d-_]+:\\?') ~= nil)
end

function str_decode(str)
    local function hex_to_char(x)
        return string.char(tonumber(x, 16))
    end

    if str ~= nil then
        str = str:gsub('^%a[%a%d-_]+://', '')
        str = str:gsub('^%a[%a%d-_]+:\\?', '')
        str = str:gsub('%%(%x%x)', hex_to_char)
        if str:match('://localhost:?') then
            str = str:gsub('^.*/', '')
        end
        str = str:gsub('[\\/:%?]*', '')
        return str
    else
        return
    end
end

--create network_chap_dir if it doesn't exist
network_chap_dir = mp.command_native({ "expand-path", o.network_chap_dir })
if utils.readdir(network_chap_dir) == nil then
    local is_windows = package.config:sub(1, 1) == "\\"
    local windows_args = { 'powershell', '-NoProfile', '-Command', 'mkdir', network_chap_dir }
    local unix_args = { 'mkdir', '-p', network_chap_dir }
    local args = is_windows and windows_args or unix_args
    local res = mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = args })
    if res.status ~= 0 then
        msg.error("Failed to create network_chap_dir save directory " .. network_chap_dir ..
            ". Error: " .. (res.error or "unknown"))
        return
    end
end

local function read_chapter(func)
    local f = io.open(chapter_fullpath, "r")
    if not f then return end
    local contents = {}
    for line in f:lines() do
        table.insert(contents, (func(line)))
    end
    f:close()
    return contents
end

local function read_chapter_table()
    local line_pos = 0
    return read_chapter(function(line)
        local h, m, s, t, n, l
        if line:match("^%d+:%d+:%d+") ~= nil then
            h, m, s = line:match("^(%d+):(%d+):(%d+.%d*)")
            t = h * 3600 + m * 60 + s
            if line:match("^%d+:%d+:%d+.%d*[,%s].*") ~= nil then
                n = line:match("^%d+:%d+:%d+.%d*[,%s](.*)")
                n = n:gsub(":%s%a?%a?:", "")
                    :gsub("^%s*(.-)%s*$", "%1")
            end
            l = line
            line_pos = line_pos + 1
        elseif line:match("^CHAPTER%d+=%d+:%d+:%d+") ~= nil then
            h, m, s = line:match("^CHAPTER%d+=(%d+):(%d+):(%d+.%d*)")
            t = h * 3600 + m * 60 + s
            l = line
            line_pos = line_pos + 1
        elseif line:match("^CHAPTER%d+NAME=.*") ~= nil then
            n = line:gsub("^CHAPTER%d+NAME=", "")
            n = n:gsub("^%s*(.-)%s*$", "%1")
            l = line
            line_pos = line_pos + 1
        else return end
        return { found_title = n, found_time = t, found_line = l }
    end)
end

local function refresh_globals()
    path = mp.get_property("path")
    dir, name_ext = utils.split_path(path)
    fname = str_decode(mp.get_property("filename"))
    all_chapters = mp.get_property_native("chapter-list")
    chapter_count = mp.get_property_number("chapter-list/count")
end

local function format_time(seconds)
    local result = ""
    if seconds <= 0 then
        return "00:00:00.000";
    else
        hours = string.format("%02.f", math.floor(seconds / 3600))
        mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)))
        secs = string.format("%02.f", math.floor(seconds - hours * 60 * 60 - mins * 60))
        msecs = string.format("%03.f", seconds * 1000 - hours * 60 * 60 * 1000 - mins * 60 * 1000 - secs * 1000)
        result = hours .. ":" .. mins .. ":" .. secs .. "." .. msecs
    end
    return result
end

local function mark_chapter()
    refresh_globals()
    local chapter_index = 0
    local chapters_time = {}
    local chapters_title = {}
    if is_protocol(path) or utils.readdir(dir) == nil then
        dir = network_chap_dir
        fname = str_decode(mp.get_property("media-title"))
    end
    local fpath = dir
    local chapter_fliename = fname .. o.chapter_flie_ext
    if o.external_chapter_subpath ~= '' and not is_protocol(path) then
        fpath = utils.join_path(dir, o.external_chapter_subpath)
    end
    chapter_fullpath = utils.join_path(fpath, chapter_fliename)
    if io.open(chapter_fullpath, "r") == nil then
        chapter_fullpath = utils.join_path(dir, chapter_fliename)
    end
    list_contents = read_chapter_table()

    if not list_contents then return end
    for i = 1, #list_contents do
        local chapter_time = tonumber(list_contents[i].found_time)
        if chapter_time ~= nil and chapter_time >= 0 then
            table.insert(chapters_time, chapter_time)
        end
        if list_contents[i].found_title ~= nil then
            table.insert(chapters_title, list_contents[i].found_title)
        end
    end
    if not chapters_time[1] then return end

    table.sort(chapters_time, function(a, b) return a < b end)

    for i = 1, #chapters_time do
        chapter_index = chapter_index + 1
        all_chapters[chapter_index] = {
            title = chapters_title[i] or ("Chapter " .. string.format("%02.f", chapter_index)),
            time = chapters_time[i]
        }
    end

    table.sort(all_chapters, function(a, b) return a['time'] < b['time'] end)

    mp.set_property_native("chapter-list", all_chapters)
    msg.info("load external chapter flie successful: " .. chapter_fliename)
end

local function change_title_callback(user_input, err, chapter_index)
    if user_input == nil or err ~= nil then
        if paused then return elseif o.pause_on_input then mp.set_property_native("pause", false) end
        msg.warn("no chapter title provided:", err)
        return
    end

    local chapter_list = mp.get_property_native("chapter-list")

    if chapter_index > mp.get_property_number("chapter-list/count") then
        msg.warn("can't set chapter title")
        return
    end

    chapter_list[chapter_index].title = user_input

    mp.set_property_native("chapter-list", chapter_list)
    if paused then return elseif o.pause_on_input then mp.set_property_native("pause", false) end
    chapters_modified = true
end

local function create_chapter()
    refresh_globals()
    local time_pos = mp.get_property_number("time-pos")
    local time_pos_osd = mp.get_property_osd("time-pos/full")
    local curr_chapter = mp.get_property_number("chapter")
    mp.osd_message(time_pos_osd, 1)

    if chapter_count == 0 then
        all_chapters[1] = {
            title = o.placeholder_title .. "01",
            time = time_pos
        }
        -- We just set it to zero here so when we add 1 later it ends up as 1
        -- otherwise it's probably "nil"
        curr_chapter = 0
        -- note that mpv will treat the beginning of the file as all_chapters[0] when using pageup/pagedown
        -- so we don't actually have to worry if the file doesn't start with a chapter
    else
        -- to insert a chapter we have to increase the index on all subsequent chapters
        -- otherwise we'll end up with duplicate chapter IDs which will confuse mpv
        -- +2 looks weird, but remember mpv indexes at 0 and lua indexes at 1
        -- adding two will turn "current chapter" from mpv notation into "next chapter" from lua's notation
        -- count down because these areas of memory overlap
        for i = chapter_count, curr_chapter + 2, -1 do
            all_chapters[i + 1] = all_chapters[i]
        end
        all_chapters[curr_chapter + 2] = {
            title = o.placeholder_title .. string.format("%02.f", curr_chapter + 2),
            time = time_pos
        }
    end
    mp.set_property_native("chapter-list", all_chapters)
    mp.set_property_number("chapter", curr_chapter + 1)
    chapters_modified = true
    
    if o.ask_for_title then
        if not user_input_module then
            msg.error("no mpv-user-input, can't get user input, install: https://github.com/CogentRedTester/mpv-user-input")
            return
        end
        -- ask user for chapter title
        local chapter_index = mp.get_property_number("chapter") + 1
        input.get_user_input(change_title_callback, {
            request_text = "title of the chapter:",
            default_input = o.placeholder_title .. string.format("%02.f", chapter_index),
            cursor_pos = #(o.placeholder_title .. string.format("%02.f", chapter_index)) + 1,
        }, chapter_index)

        if o.pause_on_input then
            paused = mp.get_property_native("pause")
            mp.set_property_bool("pause", true)
            -- FIXME: for whatever reason osd gets hidden when we pause the
            -- playback like that, workaround to make input prompt appear
            -- right away without requiring mouse or keyboard action
            mp.osd_message(" ", 0.1)
        end
    end 
end

local function edit_chapter()
    local mpv_chapter_index = mp.get_property_number("chapter")
    local chapter_list = mp.get_property_native("chapter-list")

    if mpv_chapter_index == nil or mpv_chapter_index == -1 then
        msg.verbose("no chapter selected, nothing to edit")
        return
    end

    if not user_input_module then
        msg.error("no mpv-user-input, can't get user input, install: https://github.com/CogentRedTester/mpv-user-input")
        return
    end
    -- ask user for chapter title
    -- (+1 because mpv indexes from 0, lua from 1)
    input.get_user_input(change_title_callback, {
        request_text = "title of the chapter:",
        default_input = chapter_list[mpv_chapter_index + 1].title,
        cursor_pos = #(chapter_list[mpv_chapter_index + 1].title) + 1,
    }, mpv_chapter_index + 1)

    if o.pause_on_input then
        paused = mp.get_property_native("pause")
        mp.set_property_bool("pause", true)
        -- FIXME: for whatever reason osd gets hidden when we pause the
        -- playback like that, workaround to make input prompt appear
        -- right away without requiring mouse or keyboard action
        mp.osd_message(" ", 0.1)
    end
end

local function remove_chapter()
    local chapter_count = mp.get_property_number("chapter-list/count")

    if chapter_count < 1 then
        msg.verbose("no chapters to remove")
        return
    end

    local chapter_list = mp.get_property_native("chapter-list")
    -- +1 because mpv indexes from 0, lua from 1
    local current_chapter = mp.get_property_number("chapter") + 1

    table.remove(chapter_list, current_chapter)
    msg.debug("removing chapter", current_chapter)

    mp.set_property_native("chapter-list", chapter_list)
    chapters_modified = true
end

local function write_chapter(force_write)
    if not force_write and mp.get_property_number("chapter-list/count") == 0 or not chapters_modified then
        msg.debug("nothing to write")
        return
    end

    refresh_globals()
    local out_path = utils.join_path(dir, fname .. o.chapter_flie_ext)
    for i = 1, chapter_count, 1 do
        curr = all_chapters[i]
        local time_pos = format_time(curr.time)
        local next_chapter = time_pos .. " " .. curr.title .. "\n"
        if i == 1 then
            insert_chapters = "# " .. path .. "\n\n" .. next_chapter
        else
            insert_chapters = insert_chapters .. next_chapter
        end
    end

    local chapters = insert_chapters

    local file = io.open(out_path, "w")
    if file == nil then
        dir = network_chap_dir
        name = str_decode(mp.get_property("media-title"))
        out_path = utils.join_path(dir, name .. o.chapter_flie_ext)
        file = io.open(out_path, "w")
    end
    if file == nil then
        mp.error("Could not open chapter file for writing.")
        return
    end
    file:write(chapters)
    file:close()
    if not force_write then
        mp.osd_message("Export chapter file to: " .. out_path, 3)
    else
        msg.info("Auto save chapter file to: " .. out_path)
    end
end

local function write_chapter_ogm()
    refresh_globals()
    local out_path = utils.join_path(dir, fname .. o.chapter_flie_ext)
    for i = 1, chapter_count, 1 do
        curr = all_chapters[i]
        local time_pos = format_time(curr.time)
        local next_chapter = "CHAPTER" .. string.format("%02.f", i) .. "=" .. time_pos .. "\n" .. 
                             "CHAPTER" .. string.format("%02.f", i) .. "NAME=" .. curr.title .. "\n"
        if i == 1 then
            insert_chapters = "# " .. path .. "\n\n" .. next_chapter
        else
            insert_chapters = insert_chapters .. next_chapter
        end
    end

    local chapters = insert_chapters

    local file = io.open(out_path, "w")
    if file == nil then
        dir = network_chap_dir
        name = str_decode(mp.get_property("media-title"))
        out_path = utils.join_path(dir, name .. o.chapter_flie_ext)
        file = io.open(out_path, "w")
    end
    if file == nil then
        mp.error("Could not open chapter file for writing.")
        return
    end
    file:write(chapters)
    file:close()
    mp.osd_message("Export chapter file to: " .. out_path, 3)
end

local function write_chapter_xml()
    refresh_globals()
    local out_path = utils.join_path(dir, fname .. o.chapter_flie_ext)
    for i = 1, chapter_count, 1 do
        curr = all_chapters[i]
        local time_pos = format_time(curr.time)

        if i == 1 and curr.time ~= 0 then
            local first_chapter = "    <ChapterAtom>\n      <ChapterUID>" ..
                math.random(1000, 9000) ..
                "</ChapterUID>\n      <ChapterFlagHidden>0</ChapterFlagHidden>\n      <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      <ChapterDisplay>\n        <ChapterString>Prologue</ChapterString>\n        <ChapterLanguage>eng</ChapterLanguage>\n      </ChapterDisplay>\n      <ChapterTimeStart>00:00:00.000</ChapterTimeStart>\n    </ChapterAtom>\n"
            insert_chapters = insert_chapters .. first_chapter
        end

        local next_chapter = "      <ChapterAtom>\n        <ChapterDisplay>\n          <ChapterString>" ..
            curr.title ..
            "</ChapterString>\n          <ChapterLanguage>eng</ChapterLanguage>\n        </ChapterDisplay>\n        <ChapterUID>"
            ..
            math.random(1000, 9000) ..
            "</ChapterUID>\n        <ChapterTimeStart>" ..
            time_pos ..
            "</ChapterTimeStart>\n        <ChapterFlagHidden>0</ChapterFlagHidden>\n        <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      </ChapterAtom>\n"
        insert_chapters = insert_chapters .. next_chapter
    end

    local chapters = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<Chapters>\n  <EditionEntry>\n    <EditionFlagHidden>0</EditionFlagHidden>\n    <EditionFlagDefault>0</EditionFlagDefault>\n    <EditionUID>"
        .. euid .. "</EditionUID>\n" .. insert_chapters .. "  </EditionEntry>\n</Chapters>"
    
    local file = io.open(out_path, "w")
    if file == nil then
        dir = network_chap_dir
        name = str_decode(mp.get_property("media-title"))
        out_path = utils.join_path(dir, name .. "_chapter.xml")
        file = io.open(out_path, "w")
    end
    if file == nil then
        mp.error("Could not open chapter file for writing.")
        return
    end
    file:write(chapters)
    file:close()
    mp.osd_message("Export chapter file to: " .. out_path, 3)
end

-- HOOKS -----------------------------------------------------------------------

if o.autoload then
    mp.add_hook("on_preloaded", 50, mark_chapter)
end

if o.autosave then
    mp.add_hook("on_unload", 50, function() write_chapter(true) end)
end

if user_input_module then
    mp.add_hook("on_unload", 50, function() input.cancel_user_input() end)
end

mp.register_script_message("create_chapter", create_chapter, { repeatable = true })
mp.register_script_message("remove_chapter", remove_chapter)
mp.register_script_message("edit_chapter", edit_chapter)
mp.register_script_message("write_chapter", write_chapter)
mp.register_script_message("write_chapter_ogm", write_chapter_ogm)
mp.register_script_message("write_chapter_xml", write_chapter_xml)
