--[[
  * chapter-make-read.lua v.2025-03-01
  *
  * AUTHORS: dyphire
  * License: MIT
  * link: https://github.com/dyphire/mpv-scripts
--]]

--[[
Copyright (c) 2023 dyphire <qimoge@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
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

-- This script also supports manually load/refresh,marks,edits,remove and creates external chapter files, usage:
-- Note: It can also be used to export the existing chapter information of the playback file.
-- add bindings to input.conf:
-- key script-message-to chapter_make_read load_chapter
-- key script-message-to chapter_make_read create_chapter
-- key script-message-to chapter_make_read edit_chapter
-- key script-message-to chapter_make_read remove_chapter
-- key script-message-to chapter_make_read write_chapter chp
-- key script-message-to chapter_make_read write_chapter ogm

local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require "mp.options"

local o = {
    autoload = true,
    autosave = false,
    force_overwrite = false,
    -- Specifies the extension of the external chapter file.
    chapter_file_ext = ".chp",
    -- Select whether the external chapter file needs to match the extension of the source file.
    basename_with_ext = true,
    -- Specifies the subpath of the same directory as the playback file as the external chapter file path.
    -- Note: The external chapter file is read from the subdirectory first.
    -- If the file does not exist, it will next be read from the same directory as the playback file.
    external_chapter_subpath = "chapters",
    -- save all chapter files in a single global directory
    global_chapters = false,
    global_chapters_dir = "~~/chapters",
    -- hash works only in global_chapters_dir
    hash = false,
    -- ask for title or leave it empty
    ask_for_title = true,
    -- placeholder when asking for title of a new chapter
    placeholder_title = "Chapter ",
    -- pause the playback when asking for chapter title
    pause_on_input = true,
}

options.read_options(o)

local input_loaded, input = pcall(require, "mp.input")
-- Requires: https://github.com/CogentRedTester/mpv-user-input
local user_input_loaded, user_input = pcall(require, "user-input-module")

local path = nil
local dir = nil
local fname = nil
local chapter_fullpath = nil
local all_chapters = {}
local chapter_count = 0
local chapters_modified = false
local paused = false
local protocol = false

local function is_protocol(path)
    return type(path) == 'string' and (path:find('^%a[%w.+-]-://') ~= nil or path:find('^%a[%w.+-]-:%?') ~= nil)
end

function url_decode(str)
    local function hex_to_char(x)
        return string.char(tonumber(x, 16))
    end

    if str ~= nil then
        str = str:gsub('^%a[%a%d-_]+://', '')
              :gsub('^%a[%a%d-_]+:\\?', '')
              :gsub('%%(%x%x)', hex_to_char)
        if str:find('://localhost:?') then
            str = str:gsub('^.*/', '')
        end
        str = str:gsub('[\\/:%?]*', '')
        return str
    end
end

--create global_chapters_dir if it doesn't exist
local global_chapters_dir = mp.command_native({ "expand-path", o.global_chapters_dir })
if global_chapters_dir and global_chapters_dir ~= '' then
    local meta = utils.file_info(global_chapters_dir)
    if not meta or not meta.is_dir then
        local is_windows = package.config:sub(1, 1) == "\\"
        local windows_args = { 'powershell', '-NoProfile', '-Command', 'mkdir', string.format("\"%s\"", global_chapters_dir) }
        local unix_args = { 'mkdir', '-p', global_chapters_dir }
        local args = is_windows and windows_args or unix_args
        local res = mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = args })
        if res.status ~= 0 then
            msg.error("Failed to create global_chapters_dir save directory " .. global_chapters_dir ..
            ". Error: " .. (res.error or "unknown"))
            return
        end
    end
end

local function read_chapter(func)
    local meta = utils.file_info(chapter_fullpath)
    if not meta or not meta.is_file then return end
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
        local thin_space = string.char(0xE2, 0x80, 0x89)
        local line = line:gsub(thin_space, " ")
        if line:match("^%d+:%d+:%d+") ~= nil then
            h, m, s = line:match("^(%d+):(%d+):(%d+[,%.]?%d+)")
            s = s:gsub(',', '.')
            t = h * 3600 + m * 60 + s
            if line:match("^%d+:%d+:%d+[,%.]?%d+[,%s].*") ~= nil then
                n = line:match("^%d+:%d+:%d+[,%.]?%d+[,%s](.*)")
                n = n:gsub(":%s%a?%a?:", "")
                    :gsub("^%s*(.-)%s*$", "%1")
            end
            l = line
            line_pos = line_pos + 1
        elseif line:match("^%d+:%d+[,%.]?%d+[,%s].*") ~= nil then
            m, s = line:match("^(%d+):(%d+[,%.]?%d+)")
            s = s:gsub(',', '.')
            t = m * 60 + s
            if line:match("^%d+:%d+[,%.]?%d+[,%s].*") ~= nil then
                n = line:match("^%d+:%d+[,%.]?%d+[,%s](.*)")
                n = n:gsub(":%s%a?%a?:", "")
                    :gsub("^%s*(.-)%s*$", "%1")
            end
            l = line
            line_pos = line_pos + 1
        elseif line:match("^CHAPTER%d+=%d+:%d+:%d+") ~= nil then
            h, m, s = line:match("^CHAPTER%d+=(%d+):(%d+):(%d+[,%.]?%d+)")
            s = s:gsub(',', '.')
            t = h * 3600 + m * 60 + s
            l = line
            line_pos = line_pos + 1
        elseif line:match("^CHAPTER%d+NAME=.*") ~= nil then
            n = line:gsub("^CHAPTER%d+NAME=", "")
            n = n:gsub("^%s*(.-)%s*$", "%1")
            l = line
            line_pos = line_pos + 1
        else
            return
        end
        return { found_title = n, found_time = t, found_line = l }
    end)
end

local function refresh_globals()
    path = mp.get_property("path")
    if path then
        protocol = is_protocol(path)
        dir = utils.split_path(path)
    end

    if protocol then
        fname = url_decode(mp.get_property("media-title"))
    elseif o.basename_with_ext then
        fname = mp.get_property("filename")
    else
        fname = mp.get_property("filename/no-ext")
    end

    all_chapters = mp.get_property_native("chapter-list")
    chapter_count = mp.get_property_number("chapter-list/count")
end

local function format_time(seconds)
    local result = ""
    local hours, mins, secs, msecs
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

-- for unix use only
-- returns a table of command path and varargs, or nil if command was not found
local function command_exists(command, ...)
    msg.debug("looking for command:", command)
    -- msg.debug("args:", )
    local process = mp.command_native({
        name = "subprocess",
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
        args = {"sh", "-c", "command -v -- " .. command}
    })

    if process.status == 0 then
        local command_path = process.stdout:gsub("\n", "")
        msg.debug("command found:", command_path)
        return {command_path, ...}
    else
        msg.debug("command not found:", command)
        return nil
    end
end

-- returns md5 hash of the full path of the current media file
local function hash(path)
    if path == nil then
        msg.debug("something is wrong with the path, can't get full_path, can't hash it")
        return
    end

    msg.debug("hashing:", path)

    local cmd = {
        name = 'subprocess',
        capture_stdout = true,
        playback_only = false,
    }

    local args = nil
    local is_unix = package.config:sub(1,1) == "/"
    if is_unix then
        local md5 = command_exists("md5sum") or command_exists("md5") or command_exists("openssl", "md5 | cut -d ' ' -f 2")
        if md5 == nil then
            msg.warn("no md5 command found, can't generate hash")
            return
        end
        md5 = table.concat(md5, " ")
        cmd["stdin_data"] = path
        args = {"sh", "-c", md5 .. " | cut -d ' ' -f 1 | tr '[:lower:]' '[:upper:]'" }
    else --windows
        -- https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash?view=powershell-7.3
        local hash_command = [[
            $s = [System.IO.MemoryStream]::new();
            $w = [System.IO.StreamWriter]::new($s);
            $w.write(']] .. path .. [[');
            $w.Flush();
            $s.Position = 0;
            Get-FileHash -Algorithm MD5 -InputStream $s | Select-Object -ExpandProperty Hash
        ]]

        args = {"powershell", "-NoProfile", "-Command", hash_command}
    end
    cmd["args"] = args
    msg.debug("hash cmd:", utils.to_string(cmd))
    local process = mp.command_native(cmd)

    if process.status == 0 then
        local hash = process.stdout:gsub("%s+", "")
        msg.debug("hash:", hash)
        return hash
    else
        msg.warn("hash function failed")
        return
    end
end

local function get_chapter_filename(path)
    name = hash(path)
    if name == nil then
        msg.warn("hash function failed, fallback to filename")
        name = fname
    end
    return name
end

local function mark_chapter(force_overwrite)
    refresh_globals()
    if not path then return end

    local chapter_index = 0
    local chapters_time = {}
    local chapters_title = {}
    local fpath = dir
    if protocol then
        fpath = global_chapters_dir
        if o.hash then fname = get_chapter_filename(path) end
    elseif o.external_chapter_subpath ~= '' then
        fpath = utils.join_path(dir, o.external_chapter_subpath)
        local meta = utils.file_info(fpath)
        if not meta or not meta.is_dir then
            fpath = dir
        end
    end

    if o.global_chapters and global_chapters_dir and global_chapters_dir ~= '' and not protocol then
        fpath = global_chapters_dir
        local meta = utils.file_info(fpath)
        if meta and meta.is_dir then
            if o.hash then
                fname = get_chapter_filename(path)
            end
        end
    end

    local chapter_filename = fname .. o.chapter_file_ext
    chapter_fullpath = utils.join_path(fpath, chapter_filename)
    local fmeta = utils.file_info(chapter_fullpath)
    if (not fmeta or not fmeta.is_file) and fpath ~= dir and not protocol then
        if o.basename_with_ext then
            fname = mp.get_property("filename")
        else
            fname = mp.get_property("filename/no-ext")
        end
        chapter_filename = fname .. o.chapter_file_ext
        chapter_fullpath = utils.join_path(dir, chapter_filename)
    end
    local list_contents = read_chapter_table()

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

    if force_overwrite then all_chapters = {} end
    for i = 1, #chapters_time do
        chapter_index = chapter_index + 1
        all_chapters[chapter_index] = {
            title = chapters_title[i] or ("Chapter " .. string.format("%02.f", chapter_index)),
            time = chapters_time[i]
        }
    end

    table.sort(all_chapters, function(a, b) return a['time'] < b['time'] end)

    mp.set_property_native("chapter-list", all_chapters)
    msg.info("load external chapter file successful: " .. chapter_filename)
end

local function change_chapter_list(chapter_tltle, chapter_index)
    local chapter_list = mp.get_property_native("chapter-list")

    if chapter_index > mp.get_property_number("chapter-list/count") then
        msg.warn("can't set chapter title")
        return
    end

    chapter_list[chapter_index].title = chapter_tltle
    mp.set_property_native("chapter-list", chapter_list)
end

local function change_title_callback(user_input, err, chapter_index)
    if user_input == nil or err ~= nil then
        if paused then return elseif o.pause_on_input then mp.set_property_native("pause", false) end
        msg.warn("no chapter title provided:", err)
        return
    end
    change_chapter_list(user_input, chapter_index)
    if paused then return elseif o.pause_on_input then mp.set_property_native("pause", false) end
    chapters_modified = true
end

local function input_title(default_input, cursor_pos, chapter_index)
    input.get({
        prompt = 'Chapter title:',
        default_text = default_input,
        cursor_position = cursor_pos,
        submit = function(text)
            input.terminate()
            change_chapter_list(text, chapter_index)
        end,
        closed = function()
            if paused then return elseif o.pause_on_input then mp.set_property_native("pause", false) end
        end
    })
end

local function input_choice(title, chapter_index)
    if not input_loaded and not user_input_loaded then
        msg.error("no mpv-user-input, can't get user input, install: https://github.com/CogentRedTester/mpv-user-input")
        return
    end

    if input_loaded then
        input_title(title, #title + 1, chapter_index)
    elseif user_input_loaded then
        -- ask user for chapter title
        -- (+1 because mpv indexes from 0, lua from 1)
        user_input.get_user_input(change_title_callback, {
            request_text = "Chapter title:",
            default_input = title,
            cursor_pos = #title + 1,
        }, chapter_index)
    end
end

local function create_chapter()
    refresh_globals()
    if not path then return end

    local time_pos = mp.get_property_number("time-pos")
    local time_pos_osd = mp.get_property_osd("time-pos/full")
    local current_chapter = mp.get_property_number("chapter")
    mp.osd_message(time_pos_osd, 1)

    if chapter_count == 0 then
        all_chapters[1] = {
            title = o.placeholder_title .. "01",
            time = time_pos
        }
        -- We just set it to zero here so when we add 1 later it ends up as 1
        -- otherwise it's probably "nil"
        current_chapter = 0
        -- note that mpv will treat the beginning of the file as all_chapters[0] when using pageup/pagedown
        -- so we don't actually have to worry if the file doesn't start with a chapter
    else
        -- to insert a chapter we have to increase the index on all subsequent chapters
        -- otherwise we'll end up with duplicate chapter IDs which will confuse mpv
        -- +2 looks weird, but remember mpv indexes at 0 and lua indexes at 1
        -- adding two will turn "current chapter" from mpv notation into "next chapter" from lua's notation
        -- count down because these areas of memory overlap
        for i = chapter_count, current_chapter + 2, -1 do
            all_chapters[i + 1] = all_chapters[i]
        end
        all_chapters[current_chapter + 2] = {
            title = o.placeholder_title .. string.format("%02.f", current_chapter + 2),
            time = time_pos
        }
    end
    mp.set_property_native("chapter-list", all_chapters)
    mp.set_property_number("chapter", current_chapter + 1)
    chapters_modified = true
    
    if o.ask_for_title then
        local chapter_index = mp.get_property_number("chapter") + 1
        local title = o.placeholder_title .. string.format("%02.f", chapter_index)

        input_choice(title, chapter_index)

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
    local chapter_index = mp.get_property_number("chapter") + 1
    local chapter_list = mp.get_property_native("chapter-list")
    local title = chapter_list[chapter_index + 1].title
    if chapter_index == nil or chapter_index == -1 then
        msg.verbose("no chapter selected, nothing to edit")
        return
    end

    input_choice(title, chapter_index)

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

local function write_chapter(format, force_write)
    refresh_globals()
    if not path or chapter_count == 0 or (not chapters_modified and not force_write) then
        msg.debug("nothing to write")
        return
    end

    if o.global_chapters then dir = global_chapters_dir end
    if o.hash and o.global_chapters then fname = get_chapter_filename(path) end
    local out_path = utils.join_path(dir, fname .. o.chapter_file_ext)
    local chapters = ""
    local next_chapter = nil
    for i = 1, chapter_count, 1 do
        local current_chapter = all_chapters[i]
        local time_pos = format_time(current_chapter.time)
        if format == "ogm" then
            next_chapter = "CHAPTER" .. string.format("%02.f", i) .. "=" .. time_pos .. "\n" .. 
                           "CHAPTER" .. string.format("%02.f", i) .. "NAME=" .. current_chapter.title .. "\n"
        elseif format == "chp" then
            next_chapter = time_pos .. " " .. current_chapter.title .. "\n"
        else
            msg.warn("please specify the correct chapter format: chp/ogm.")
            return
        end
        if i == 1 and (o.global_chapters or protocol) then
            chapters = "# " .. path .. "\n\n" .. next_chapter
        else
            chapters = chapters .. next_chapter
        end
    end

    local file = io.open(out_path, "w")
    if file == nil then
        dir = global_chapters_dir
        fname = url_decode(mp.get_property("media-title"))
        if o.hash then fname = get_chapter_filename(path) end
        out_path = utils.join_path(dir, fname .. o.chapter_file_ext)
        file = io.open(out_path, "w")
    end
    if file == nil then
        mp.error("Could not open chapter file for writing.")
        return
    end
    file:write(chapters)
    file:close()
    if not o.autosave then
        mp.osd_message("Export chapter file to: " .. out_path, 3)
    end
    msg.info("Export chapter file to: " .. out_path)
end

-- HOOKS -----------------------------------------------------------------------

if o.autoload then
    mp.add_hook("on_preloaded", 50, function()
        if o.force_overwrite then
            mark_chapter(true)
        else
            mark_chapter(false)
        end
    end)
end

if o.autosave then
    mp.add_hook("on_unload", 50, function()
        write_chapter("chp", false)
    end)
end

if user_input_loaded and not input_loaded then
    mp.add_hook("on_unload", 50, function() user_input.cancel_user_input() end)
end

mp.register_script_message("load_chapter", function() mark_chapter(true) end)
mp.register_script_message("create_chapter", create_chapter, { repeatable = true })
mp.register_script_message("remove_chapter", remove_chapter)
mp.register_script_message("edit_chapter", edit_chapter)
mp.register_script_message("write_chapter", function(format)
    write_chapter(format, true)
end)
