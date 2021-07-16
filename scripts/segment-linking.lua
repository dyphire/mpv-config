--[[
    A script to implement support for matroska next/prev segment linking.
    Available at: https://github.com/CogentRedTester/mpv-segment-linking

    This is a different feature to ordered chapters, which mpv already supports natively.
    This script requires mkvinfo to be available in the system path.
]]--

local mp = require "mp"
local msg = require "mp.msg"
local utils = require "mp.utils"

local FLAG_CHAPTER_FIX

local ORDERED_CHAPTERS_ENABLED
local REFERENCES_ENABLED
local MERGE_THRESHOLD

--file extensions that support segment linking
local file_extensions = {
    mkv = true,
    mka = true
}

--returns the uid of the given file, along with the previous and next uids if they exist.
--if fail_silent is true then do not print any error messages
local function get_uids(file, fail_silently)
    local cmd = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        args = {"mkvinfo", file}
    })

    if cmd.status ~= 0 then
        if fail_silently then return end
        msg.error("could not read file", file)
        msg.error(cmd.stdout)
        return
    end

    local output = cmd.stdout
    return  output:match("Segment UID: ([^\n\r]+)"),
            output:match("Previous segment UID: ([^\n\r]+)"),
            output:match("Next segment UID: ([^\n\r]+)")
end

--creates a table of available UIDs for the current file
--scans either the current file's directory, or the ordered-chapters-files playlist.
--set ordered_chapters_files to an empty string to scan the current directory
local function create_uid_table(path, ordered_chapters_files)
    local files

    --grabs the directory portion of the original path
    local directory = ordered_chapters_files ~= "" and ordered_chapters_files or path
    directory = directory:match("^(.+[/\\])[^/\\]+[/\\]?$") or ""

    --grabs either the contents of the current directory, or the contents of the `ordered-chapters-files` option
    if ordered_chapters_files == "" then
        local open_dir = directory ~= "" and directory or mp.get_property("working-directory", "")
        files = utils.readdir(open_dir, "files")
        if not files then return msg.error("Could not read directory '"..open_dir.."'") end

    else
        local pl, err = io.open(ordered_chapters_files, "r")
        if not pl then return msg.error(err) end

        files = {}
        for line in pl:lines() do
            --remove the newline character at the end of each line
            table.insert(files, line:match("[^\r\n]+"));
        end
    end

    --go through the file list and populate the table
    local files_segments = {}
    for _, file in ipairs(files) do
        local file_ext = file:match("%.(%w+)$")

        if file_extensions[file_ext] then
            file = utils.join_path(directory,file)
            local uid, prev, next = get_uids(file)
            if uid ~= nil then
                files_segments[uid] = {
                    prev = prev,
                    next = next,
                    file = file
                }
            end
        end
    end

    return files_segments
end

--builds a timeline of linked segments for the current file
local function main()
    --we will respect these options just as ordered chapters do
    if not (ORDERED_CHAPTERS_ENABLED and REFERENCES_ENABLED) then return end

    local path = mp.get_property("stream-open-filename", "")
    local file_ext = path:match("%.(%w+)$")

    --if not a file that can contain segments then return
    if not file_extensions[file_ext] then return end

    --read the uid info for the current file
    --if the file cannot be read, or if it does not contain next or prev uids, then return
    local uid, prev, next = get_uids(path, true)
    if not uid then return end
    if not prev and not next then return end

    ------------------------------------------------------------------
    --------- Files without hard links will stop before here ---------
    ------------------------------------------------------------------

    msg.info("File uses linked segments, will build edit timeline.")

    local ordered_chapters_files = mp.get_property("ordered-chapters-files", "")

    if ordered_chapters_files == "" then
        msg.info("Will scan other files in the same directory to find referenced sources.")
    else
        msg.info("Loading references from '"..ordered_chapters_files.."'")
    end

    --creates a table of available UIDs for the current file
    local segments = create_uid_table(path, ordered_chapters_files)
    if not segments then return msg.error("Aborting segment link.") end
    local list = {path}

    --adds the next and previous segment ids until reaching the end of the uid chain
    while (prev and segments[prev]) do
        msg.info("Match for previous segment:", segments[prev].file)
        table.insert(list, 1, segments[prev].file)
        prev = segments[prev].prev
    end

    while (next and segments[next]) do
        msg.info("Match for next segment:", segments[next].file)
        table.insert(list, segments[next].file)
        next = segments[next].next
    end

    --we'll use the mpv edl specification to merge the files into one seamless timeline
    local edl_path = "edl://"
    for _, segment in ipairs(list) do
        edl_path = edl_path..segment..",title=__mkv_segment;"
    end

    mp.set_property("stream-open-filename", edl_path)
    FLAG_CHAPTER_FIX = true
end

--[[
    Remove chapters added by the edl specification, with adjacent matching titles, or within the merge threshold.

    Segment linking does not have chapter generation as part of the specification and vlc does not do this, so we'll remove them all.

    If chapters are exactly equal to an existing chapter then it can make it impossible to seek backwards past the chapter
    unless we remove something, hence we'll merge chapters that are close together. Using the ordered-chapters merge option provides
    an easy way for people to customise this value, and further ties this script to the inbuilt ordered-chapters feature.

    Splitting chapters often results in the same chapter being present in both files, so we'll also merge adjacent chapters
    with the same chapter name. This is not part of the spec, but should provide a nice QOL change, with no downsides for encodes
    that avoid this issue.
]]--
local function fix_chapters()
    if not FLAG_CHAPTER_FIX then return end

    local chapters = mp.get_property_native("chapter-list", {})

    --remove chapters added by this script
    for i=#chapters, 1, -1 do
        if chapters[i].title == "__mkv_segment" then
            table.remove(chapters, i)
        end
    end

    --remove chapters with adjacent matching chapter names, which can happen when splitting segments
    --we want to do this pass separately to the threshold pass in case the end of a previous chapter falls
    --within the threshold of an actually new (named) chapter.
    for i = #chapters, 2, -1 do
        if chapters[i].title == chapters[i-1].title then
            table.remove(chapters, i)
        end
    end

    --go over the chapters again and remove ones within the merge threshold
    for i = #chapters, 2, -1 do
        if chapters[i].time - chapters[i-1].time < MERGE_THRESHOLD then
            table.remove(chapters, i)
        end
    end

    mp.set_property_native("chapter-list", chapters)
    FLAG_CHAPTER_FIX = false
end

mp.add_hook("on_load", 50, main)
mp.add_hook("on_preloaded", 50, fix_chapters)

--monitor the relevant options
mp.observe_property("access-references", "bool", function(_, val) REFERENCES_ENABLED = val end)
mp.observe_property("ordered-chapters", "bool", function(_, val) ORDERED_CHAPTERS_ENABLED = val end)
mp.observe_property("chapter-merge-threshold", "number", function(_, val) MERGE_THRESHOLD = val/1000 end)