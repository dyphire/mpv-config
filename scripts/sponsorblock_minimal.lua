-- sponsorblock_minimal.lua v 0.5.1
--
-- This script skip/mute sponsored segments of YouTube and bilibili videos
-- using data from https://github.com/ajayyy/SponsorBlock
-- and https://github.com/hanydd/BilibiliSponsorBlock

local opt = require 'mp.options'
local utils = require 'mp.utils'

local options = {
    youtube_sponsor_server = "https://sponsor.ajay.app/api/skipSegments",
    bilibili_sponsor_server = "https://bsbsb.top/api/skipSegments",
    -- Categories to fetch
    -- Perform skip/mute/mark chapter based on the 'actionType' returned
    categories = '"sponsor"',
}

opt.read_options(options)

local ranges = nil
local video_id = nil
local sponsor_server = nil
local cache = {}
local mute = false
local ON = false

local function getranges(url)
    local res = mp.command_native{
        name = "subprocess",
        capture_stdout = true,
        playback_only = false,
        args = {
            "curl", "-L", "-s", "-g",
            "-H", "origin: mpv-script/sponsorblock_minimal",
            "-H", "x-ext-version: 0.5.1",
            url
        }
    }

    if res.status ~= 0 then
        return nil
    end

    return utils.parse_json(res.stdout)
end

local function make_chapter(ranges)
    local chapters_time = {}
    local chapters_title = {}
    local chapter_index = 0
    local all_chapters = mp.get_property_native("chapter-list")
    for _, v in pairs(ranges) do
        table.insert(chapters_time, v.segment[1])
        table.insert(chapters_title, v.category)
        table.insert(chapters_time, v.segment[2])
        table.insert(chapters_title, "normal")
    end

    for i = 1, #chapters_time do
        chapter_index = chapter_index + 1
        all_chapters[chapter_index] = {
            title = chapters_title[i] or ("Chapter " .. string.format("%02.f", chapter_index)),
            time = chapters_time[i]
        }
    end

    table.sort(all_chapters, function(a, b) return a['time'] < b['time'] end)
    mp.set_property_native("chapter-list", all_chapters)
end

local function skip_ads(_, pos)
    if pos ~= nil and ranges ~= nil then
        for _, v in pairs(ranges) do
            if v.actionType == "skip" and v.segment[1] <= pos and v.segment[2] > pos then
                --this message may sometimes be wrong
                --it only seems to be a visual thing though
                local time = math.floor(v.segment[2] - pos)
                mp.osd_message(string.format("[sponsorblock] skipping forward %ds", time))
                --need to do the +0.01 otherwise mpv will start spamming skip sometimes
                mp.set_property("time-pos", v.segment[2] + 0.01)
            elseif v.actionType == "mute" then
                if v.segment[1] <= pos and v.segment[2] >= pos then
                    cache[v.segment[2]] = nil
                    mp.set_property_bool("mute", true)
                elseif pos > v.segment[2] and not cache[v.segment[2]] and mute ~= false then
                    cache[v.segment[2]] = true
                    mp.set_property_bool("mute", false)
                end
            end
        end
    end
end

local function file_loaded()
    cache = {}
    local video_path = mp.get_property("path", "")
    local video_referer = mp.get_property("http-header-fields", ""):match("[Rr]eferer:%s*([^,\r\n]+)") or ""
    local purl = mp.get_property("metadata/by-key/PURL", "")
    local bilibili = video_path:match("bilibili.com/video") or video_referer:match("bilibili.com/video") or false
    mute = mp.get_property_bool("mute")

    local urls = {
        "ytdl://youtu%.be/([%w-_]+).*",
        "ytdl://w?w?w?%.?youtube%.com/v/([%w-_]+).*",
        "ytdl://w?w?w?%.?bilibili%.com/video/([%w-_]+).*",
        "https?://youtu%.be/([%w-_]+).*",
        "https?://w?w?w?%.?youtube%.com/v/([%w-_]+).*",
        "https?://w?w?w?%.?bilibili%.com/video/([%w-_]+).*",
        "/watch.*[?&]v=([%w-_]+).*",
        "/embed/([%w-_]+).*",
        "^ytdl://([%w-_]+)$",
        "-([%w-_]+)%."
    }

    for _, url in ipairs(urls) do
        video_id = video_id or video_path:match(url) or video_referer:match(url) or purl:match(url)
    end

    if not video_id or string.len(video_id) < 11 then return end

    if bilibili then
        sponsor_server = options.bilibili_sponsor_server
        video_id = string.sub(video_id, 1, 12)
    else
        sponsor_server = options.youtube_sponsor_server
        video_id = string.sub(video_id, 1, 11)
    end

    local url = ("%s?videoID=%s&categories=[%s]"):format(sponsor_server, video_id, options.categories)

    ranges = getranges(url)
    if ranges ~= nil then
        make_chapter(ranges)
        ON = true
        mp.observe_property("time-pos", "native", skip_ads)
    end
end

local function end_file()
    if not ON then return end
    mp.unobserve_property(skip_ads)
    cache = nil
    ranges = nil
    ON = false
end

mp.register_event("file-loaded", file_loaded)
mp.register_event("end-file", end_file)
