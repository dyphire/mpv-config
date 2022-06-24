--[[
  * chapter_make_read.lua v.2022-06-24
  *
  * AUTHORS: dyphire
  * License: MIT
  * link: https://github.com/dyphire/mpv-scripts
--]]

-- Implementation read and automatically load the namesake external chapter file.
-- The external chapter files should conform to the following formats.
-- Note: The time should strictly follow the 12-bit format of 'hh:mm:ss.sss' !!
-- Note: The file encoding should be UTF-8 and the linebreak should be Unix(LF).
-- Note: The script also supports reading OGM format and MediaInfo format in addition to the following formats.
--[[
00:00:00.000 A part
00:00:40.312 OP
00:02:00.873 B part
00:10:44.269 C part
00:22:40.146 ED
--]]

-- This script also supports marks and creates external chapter files, usage:
-- Note: It can also be used to export the existing chapter information of the playing file.
-- add bindings to input.conf:
-- key script-message-to chapter_make_read create_chapter
-- key script-message-to chapter_make_read write_chapter
-- key script-message-to chapter_make_read write_chapter_xml

local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require "mp.options"

local o = {
    read_external_chapter = true,
    -- Specifies the extension of the external chapter file.
    chapter_flie_ext = "_chapter.chp",
    -- Specifies the subpath of the same directory as the playing file as the external chapter file path.
    -- Note: The external chapter file is read from the subdirectory first. 
    -- If the file does not exist, it will next be read from the same directory as the playing file.
    external_chapter_subpath = "chapters",
}

(require 'mp.options').read_options(o)

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
            t = h*3600 + m*60 + s
            if line:match("^%d+:%d+:%d+.%d*[,%s].*") ~= nil then
                n = line:match("^%d+:%d+:%d+.%d*[,%s](.*)")
                n = n:gsub(":%s%a?%a?:", "")
                    :gsub("^%s*(.-)%s*$", "%1")
            end
            l = line
            line_pos = line_pos + 1
        elseif line:match("^CHAPTER%d+=%d+:%d+:%d+") ~= nil then
            h, m, s = line:match("^CHAPTER%d+=(%d+):(%d+):(%d+.%d*)")
            t = h*3600 + m*60 + s
            l = line
            line_pos = line_pos + 1
        elseif line:match("^CHAPTER%d+NAME=.*") ~= nil then
            n = line:gsub("^CHAPTER%d+NAME=", "")
            n = n:gsub("^%s*(.-)%s*$", "%1")
            l = line
            line_pos = line_pos + 1
        else return end
        return {found_title = n, found_time = t, found_line = l}
	end)
end

local function mark_chapter()
    if not o.read_external_chapter then return end
    local all_chapters = mp.get_property_native("chapter-list")
    local chapter_index = 0
    local chapters_time = {}
    local chapters_title = {}
    local path = mp.get_property("path")
    local dir, filename = utils.split_path(path)
    local fpath = dir:gsub("\\", "/")
    local fname = mp.get_property("filename/no-ext")
    local chapter_fliename = fname .. o.chapter_flie_ext
    chapter_fullpath = fpath .. o.external_chapter_subpath .. "/" .. chapter_fliename
    if io.open(chapter_fullpath, "r") == nil then
        chapter_fullpath = fpath .. chapter_fliename
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

local function create_chapter()
    local time_pos = mp.get_property_number("time-pos")
    local time_pos_osd = mp.get_property_osd("time-pos/full")
    local curr_chapter = mp.get_property_number("chapter")
    local chapter_count = mp.get_property_number("chapter-list/count")
    local all_chapters = mp.get_property_native("chapter-list")
    mp.osd_message(time_pos_osd, 1)

    if chapter_count == 0 then
        all_chapters[1] = {
            title = "Chapter 01",
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
        all_chapters[curr_chapter+2] = {
            title = "Chapter " .. string.format("%02.f", curr_chapter+2),
            time = time_pos
        }
    end
    mp.set_property_native("chapter-list", all_chapters)
    mp.set_property_number("chapter", curr_chapter+1)
end

local function format_time(seconds)
    local result = ""
    if seconds <= 0 then
        return "00:00:00.000";
    else
        hours = string.format("%02.f", math.floor(seconds/3600))
        mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)))
        secs = string.format("%02.f", math.floor(seconds - hours*60*60 - mins*60))
        msecs = string.format("%03.f", seconds*1000 - hours*60*60*1000 - mins*60*1000 - secs*1000)
        result = hours..":"..mins..":"..secs.."."..msecs
    end
    return result
end

local function write_chapter()
    local euid = mp.get_property_number("estimated-frame-count")
    local chapter_count = mp.get_property_number("chapter-list/count")
    local all_chapters = mp.get_property_native("chapter-list")
    local insert_chapters = ""
    local curr = nil

    for i = 1, chapter_count, 1 do
        curr = all_chapters[i]
        local time_pos = format_time(curr.time)
        local next_chapter = time_pos .. " " .. curr.title .. "\n"
        insert_chapters = insert_chapters .. next_chapter
    end

    local chapters = insert_chapters

    local path = mp.get_property("path")
    dir, name_ext = utils.split_path(path)
    local name = string.sub(name_ext, 1, (string.len(name_ext)-4))
    local out_path = utils.join_path(dir, name .. o.chapter_flie_ext)
    local file = io.open(out_path, "w")
    if file == nil then
        dir = utils.getcwd()
        out_path = utils.join_path(dir, "create" .. o.chapter_flie_ext)
        file = io.open(out_path, "w")
    end
    if file == nil then
        mp.error("Could not open chapter file for writing.")
        return
    end
    file:write(chapters)
    file:close()
    mp.osd_message("Export file to: " .. out_path, 3)
end

local function write_chapter_xml()
    local euid = mp.get_property_number("estimated-frame-count")
    local chapter_count = mp.get_property_number("chapter-list/count")
    local all_chapters = mp.get_property_native("chapter-list")
    local insert_chapters = ""
    local curr = nil

    for i = 1, chapter_count, 1 do
        curr = all_chapters[i]
        local time_pos = format_time(curr.time)

        if i == 1 and curr.time ~= 0 then
            local first_chapter="    <ChapterAtom>\n      <ChapterUID>"..math.random(1000, 9000).."</ChapterUID>\n      <ChapterFlagHidden>0</ChapterFlagHidden>\n      <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      <ChapterDisplay>\n        <ChapterString>Prologue</ChapterString>\n        <ChapterLanguage>eng</ChapterLanguage>\n      </ChapterDisplay>\n      <ChapterTimeStart>00:00:00.000</ChapterTimeStart>\n    </ChapterAtom>\n"
            insert_chapters = insert_chapters..first_chapter
        end

        local next_chapter="      <ChapterAtom>\n        <ChapterDisplay>\n          <ChapterString>"..curr.title.."</ChapterString>\n          <ChapterLanguage>eng</ChapterLanguage>\n        </ChapterDisplay>\n        <ChapterUID>"..math.random(1000, 9000).."</ChapterUID>\n        <ChapterTimeStart>"..time_pos.."</ChapterTimeStart>\n        <ChapterFlagHidden>0</ChapterFlagHidden>\n        <ChapterFlagEnabled>1</ChapterFlagEnabled>\n      </ChapterAtom>\n"
        insert_chapters = insert_chapters..next_chapter
    end

    local chapters="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<Chapters>\n  <EditionEntry>\n    <EditionFlagHidden>0</EditionFlagHidden>\n    <EditionFlagDefault>0</EditionFlagDefault>\n    <EditionUID>"..euid.."</EditionUID>\n"..insert_chapters.."  </EditionEntry>\n</Chapters>"

    local path = mp.get_property("path")
    dir, name_ext = utils.split_path(path)
    local name = string.sub(name_ext, 1, (string.len(name_ext)-4))
    local out_path = utils.join_path(dir, name.."_chapter.xml")
    local file = io.open(out_path, "w")
    if file == nil then
        dir = utils.getcwd()
        out_path = utils.join_path(dir, "create_chapter.xml")
        file = io.open(out_path, "w")
    end
    if file == nil then
        mp.error("Could not open chapter file for writing.")
        return
    end
    file:write(chapters)
    file:close()
    mp.osd_message("Export file to: "..out_path, 3)
end

mp.add_hook("on_preloaded", 50, mark_chapter)

mp.register_script_message("create_chapter", create_chapter, {repeatable=true})
mp.register_script_message("write_chapter", write_chapter, {repeatable=false})
mp.register_script_message("write_chapter_xml", write_chapter_xml, {repeatable=false})