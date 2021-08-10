-- Original by Scheliux, Dragoner7 which was ported from Ruin0x11
-- Adapted to webp by DonCanjas

-- Create animated webps with mpv
-- Requires ffmpeg.
-- Adapted from https://github.com/Scheliux/mpv-gif-generator
-- Usage: "w" to set start frame, "W" to set end frame, "Ctrl+w" to create.

require 'mp.options'
local msg = require 'mp.msg'

local options = {
    dir = "C:/Users/%USERNAME%/Desktop/",
    rez = 600,
    fps = 15,
    lossless = 0,
    qscale = 90,
    compression_level = 6,
}

read_options(options, "webp")


local fps

-- Check for invalid fps values
-- Can you believe Lua doesn't have a proper ternary operator in the year of our lord 2020?
if options.fps ~= nil and options.fps >= 1 and options.fps < 30 then
    fps = options.fps
else
    fps = 15
end

-- Set this to the filters to pass into ffmpeg's -vf option.
-- filters="fps=24,scale=320:-1:flags=spline"
filters=string.format("fps=%s,zscale='trunc(ih*dar/2)*2:trunc(ih/2)*2':f=spline36,setsar=1/1,zscale=%s:-1:f=spline36", fps, options.rez)  

-- Setup output directory
output_directory=options.dir

start_time = -1
end_time = -1

-- The roundabout way has to be used due to a some weird
-- behavior with %TEMP% on the subtitles= parameter in ffmpeg
-- on Windows–it needs to be quadruple backslashed
subs = "C:/Users/%USERNAME%/AppData/Local/Temp/subs.srt"

function make_webp_with_subtitles()
    make_webp_internal(true)
end

function make_webp()
    make_webp_internal(false)
end    

function table_length(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end


function make_webp_internal(burn_subtitles)
    local start_time_l = start_time
    local end_time_l = end_time
    if start_time_l == -1 or end_time_l == -1 or start_time_l >= end_time_l then
        mp.osd_message("Invalid start/end time.")
        return
    end

    mp.osd_message("Creating webP.")

    -- shell escape
    function esc(s)
        return string.gsub(s, '"', '"\\""')
    end

    function esc_for_sub(s)
        s = string.gsub(s, [[\]], [[/]])
        s = string.gsub(s, '"', '"\\""')
        s = string.gsub(s, ":", [[\\:]])
        s = string.gsub(s, "'", [[\\']])
        return s
    end

    local pathname = mp.get_property("path", "")
    local trim_filters = esc(filters)

    local position = start_time_l
    local duration = end_time_l - start_time_l

    if burn_subtitles then
        -- Determine currently active sub track

        local i = 0
        local tracks_count = mp.get_property_number("track-list/count")
        local subs_array = {}
        
        -- check for subtitle tracks

        while i < tracks_count do
            local type = mp.get_property(string.format("track-list/%d/type", i))
            local selected = mp.get_property(string.format("track-list/%d/selected", i))

            -- if it's a sub track, save it

            if type == "sub" then
                local length = table_length(subs_array)
                subs_array[length] = selected == "yes"
            end
            i = i + 1
        end

        if table_length(subs_array) > 0 then

            local correct_track = 0

            -- iterate through saved subtitle tracks until the correct one is found

            for index, is_selected in pairs(subs_array) do
                if (is_selected) then
                    correct_track = index
                end
            end

            trim_filters = trim_filters .. string.format(",subtitles=%s:si=%s", esc_for_sub(pathname), correct_track)

        end

    end

    -- make the webp
    local filename = mp.get_property("filename/no-ext")
    local file_path = output_directory .. filename

    -- increment filename
    for i=0,999 do
        local fn = string.format('%s_%03d.webp',file_path,i)
        if not file_exists(fn) then
            webpname = fn
            break
        end
    end
    if not webpname then
        mp.osd_message('No available filenames!')
        return
    end

    local copyts = ""

    if burn_subtitles then
        copyts = "-copyts"
    end

    args = string.format('ffmpeg -ss %s %s -t %s -i "%s" -lavfi "%s" -lossless "%s" -qscale "%s" -compression_level "%s" -y "%s"', position, copyts, duration, esc(pathname), esc(trim_filters), options.lossless, options.qscale, options.compression_level, esc(webpname))
    os.execute(args)

    msg.info("webP created.")
    mp.osd_message("webP created.")
end

function set_webp_start()
    start_time = mp.get_property_number("time-pos", -1)
    mp.osd_message("webP Start: " .. start_time)
end

function set_webp_end()
    end_time = mp.get_property_number("time-pos", -1)
    mp.osd_message("webP End: " .. end_time)
end

function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

mp.add_key_binding("w", "set_webp_start", set_webp_start)
mp.add_key_binding("W", "set_webp_end", set_webp_end)
mp.add_key_binding("Ctrl+w", "make_webp", make_webp)
mp.add_key_binding("Ctrl+W", "make_webp_with_subtitles", make_webp_with_subtitles) --only works with srt for now
