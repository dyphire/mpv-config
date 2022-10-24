--[[
This script uses the lavfi cropdetect filter to automatically insert a crop filter with appropriate parameters for the
currently playing video, the script run continuously by default (mode 4).

The workflow is as follows: We observe two main events, vf-metadata and time-pos changes.
    vf-metadata are stored sequentially in buffer with time-pos being updated at every frame,
    then process to check and store trusted values to speed up future change for the current video.
    It will automatically crop the video as soon as a meta change is validated.

The default options can be overridden by adding script-opts-append=<script_name>-<parameter>=<value> into mpv.conf
    script-opts-append=dynamic_crop-mode=0
    script-opts-append=dynamic_crop-ratios=2.4 2.39 2 4/3 (quotes aren't needed like below)

List of available parameters (For default values, see <options>)：

mode: [0-4] 0 disable, 1 on-demand, 2 one-shot, 3 dynamic-manual, 4 dynamic-auto
    Mode 1 and 3 requires using the shortcut to start, 2 and 4 have an automatic start.
Shortcut "C" (shift+c) to control the script.
The first press maintains the cropping and disables the script, a second pressure eliminates the cropping 
and a third pressure is necessary to restart the script.
    Mode = 1-2, single cropping on demand, stays active until a valid cropping is apply.
    Mode = 3-4, start / stop dynamic cropping.

prevent_change_mode: [0-2] - 0 any, 1 keep-largest, 2 keep-lowest - The prevent_change_timer is trigger after a change,
    to disable this, set prevent_change_timer to 0.

fix_windowed_behavior: [0-3] - this option avoid the default behavior, that resize the window to the source size 
    when crop filter change in windowed/maximized mode by adjusting geometry.

segmentation: % [0.0-n] e.g. 0.5 for 50% - Extra time to allow new metadata to be segmented instead of being continuous.
    By default, new_known_ratio_timer is validated with 5 sec accumulated over 7.5 sec elapsed and
    new_fallback_timer with 20 sec accumulated over 30 sec elapsed.
    to disable this, set 0.

correction: % [0.0-1] e.g. 0.6 for 60% - Size minimum of collected meta (in percent based on source), to attempt a correction.
    to disable this, set 1.

detect_skip: number of frames before the filter cropdetect return a metadata, some client experience a slow down during dark scene
    caused by changing the limit used by the filter, increase this option help reduce the impact.
]] --
require "mp.msg"
require "mp.options"

local options = {
    -- behavior
    mode = 4, -- [0-4] more details above
    start_delay = 0, -- delay in seconds used to skip intro (usefull with mode 2)
    prevent_change_timer = 0, -- seconds
    prevent_change_mode = 2, -- [0-2], disable with 'prevent_change_timer = 0'
    fix_windowed_behavior = 2, -- [0-3], 0-no-fix, 1-fix-no-resize, 2-fix-keep-width, 3-fix-keep-height
    fast_change_timer = 0.2, -- seconds, minimum 0 = 1 frame
    limit_timer = 0.5, -- seconds, minimum 0 or < 'new_linked_known_ratio_timer'
    new_linked_known_ratio_timer = 2, -- seconds
    new_known_ratio_timer = 5, -- seconds >= 'new_linked_known_ratio_timer'
    new_offset_timer = 10, -- seconds, >= 'new_known_ratio_timer'
    new_fallback_timer = 40, -- seconds, >= 'new_offset_timer'
    ratios = "24/9 2.4 2.39 2.35 2.2 2 1.85 16/9 5/3 1.5 4/3 1.25 9/16", -- list separated by space
    segmentation = 0.5, -- %, 0 will approved only a continuous metadata (strict)
    -- filter, see https://ffmpeg.org/ffmpeg-filters.html#cropdetect for details
    detect_limit = 26, -- is the maximum use, increase it slowly if lighter black are present
    detect_round = 2, -- even number
    detect_reset = 1, -- minimum 1
    detect_skip = 2, -- mininum 1 (ffmpeg build since 12/2020), more details above
    -- verbose
    debug = false
}
read_options(options)
local user_geometry = mp.get_property("geometry")

if options.mode == 0 then
    mp.msg.info("mode = 0, disable script.")
    return
end

-- forward declarations
local cleanup, on_toggle
local applied, buffer, candidate, collected_, last_collected, last_current, limit, source, stats, timestamps
-- labels
local label_prefix = mp.get_script_name()
local labels = {
    crop = string.format("%s-crop", label_prefix),
    cropdetect = string.format("%s-cropdetect", label_prefix)
}
-- states (boolean)
local in_progress, seeking, paused, toggled, filter_missing, filter_inserted
-- computed options
local function convert_sec_to_ms(num) return math.floor(num * 1000) end
local function convert_ms_to_sec(num) return num / 1000 end
local o_timer = {}
for option, _ in pairs(options) do
    for t in string.gmatch(tostring(option), "_timer") do
        t = string.gsub(tostring(option), "_timer", "")
        o_timer[t] = convert_sec_to_ms(options[option])
    end
end
local cropdetect_skip = string.format(":skip=%d", options.detect_skip)

local function is_trusted_offset(offset, axis)
    for _, v in pairs(stats.trusted_offset[axis]) do if math.abs(offset - v) <= 1 then return true end end
    return false
end

local function is_cropable()
    for _, track in pairs(mp.get_property_native('track-list')) do
        if track.type == 'video' and track.selected then return not track.albumart end
    end
    return false
end

local function filter_state(label, key, value)
    local filters = mp.get_property_native("vf")
    for _, filter in pairs(filters) do
        if filter["label"] == label and (not key or key and filter[key] == value) then return true end
    end
    return false
end

local function manage_filter(action, filter) return mp.command(string.format("no-osd vf %s @%s", action, filter)) end

local function insert_cropdetect_filter()
    if toggled > 1 or paused then return end
    -- "vf pre" cropdetect / "vf append" crop, in a proper order
    local function insert_filter()
        return manage_filter("pre",
                             string.format("%s:lavfi-cropdetect=limit=%d/255:round=%d:reset=%d%s", labels.cropdetect,
                                           limit.current, options.detect_round, options.detect_reset, cropdetect_skip))
    end
    if not insert_filter() then
        cropdetect_skip = ""
        if not insert_filter() then
            mp.msg.error("Does vf=help as #1 line in mvp.conf return libavfilter list with crop/cropdetect in log?")
            filter_missing = true
            cleanup()
            return
        end
    end
    filter_inserted = true
end

local function compute_metadata(meta)
    meta.whxy = string.format("w=%s:h=%s:x=%s:y=%s", meta.w, meta.h, meta.x, meta.y)
    meta.offset = {x = meta.x - (source.w - meta.w) / 2, y = meta.y - (source.h - meta.h) / 2}
    meta.mt, meta.mb, meta.ml, meta.mr = meta.y, source.h - meta.h - meta.y, meta.x, source.w - meta.w - meta.x
    meta.is_source = meta.whxy == source.whxy
    meta.is_invalid = meta.h < 0 or meta.w < 0
    meta.is_trusted_offsets = is_trusted_offset(meta.offset.x, "x") and is_trusted_offset(meta.offset.y, "y")
    meta.time = {buffer = 0, overall = 0}
    -- check aspect ratio with the known list
    if not meta.is_invalid and math.abs(meta.w - source.w) <= options.detect_round * 2 or math.abs(meta.h - source.h) <=
        options.detect_round * 2 then
        for ratio in string.gmatch(options.ratios, "%S+%s?") do
            for a, b in string.gmatch(tostring(ratio), "(%d+)/(%d+)") do ratio = a / b end
            local height = math.floor((meta.w * 1 / ratio) + .5)
            if math.abs(height - meta.h) <= options.detect_round + 1 then -- + 1 for odd meta
                meta.is_known_ratio = true
                break
            end
        end
    end
    -- check for linked height/width to source
    if meta.mt <= options.detect_round and meta.mb <= options.detect_round or meta.ml <= options.detect_round and
        meta.mr <= options.detect_round then meta.is_linked_to_source = true end
    return meta
end

local function osd_size_change()
    -- TODO add auto/smart mode
    local prop_fullscreen = mp.get_property("fullscreen")
    if prop_fullscreen == "yes" or options.fix_windowed_behavior == 0 then return end
    local prop_maximized = mp.get_property("window-maximized")
    local osd = mp.get_property_native("osd-dimensions")
    if prop_maximized == "yes" or options.fix_windowed_behavior == 1 then -- keep current window size to avoid default behavior
        mp.set_property("geometry", string.format("%sx%s", osd.w, osd.h))
    elseif options.fix_windowed_behavior == 2 then
        mp.set_property("geometry", string.format("%s", osd.w))
    elseif options.fix_windowed_behavior == 3 then
        mp.set_property("geometry", string.format("x%s", osd.h))
    end
end

local function print_debug(meta, type_, label)
    if options.debug then
        if type_ == "detail" then
            print(string.format("%s, %-29s | offX:%3s offY:%3s | limit:%-2s", label, meta.whxy, meta.offset.x,
                                meta.offset.y, limit.current))
        end
        if not type_ then print(meta) end
    end
    if type_ == "stats" and stats and stats.trusted then
        mp.msg.info("Meta Stats:")
        local read_maj_offset = {x = "", y = ""}
        for axis, _ in pairs(read_maj_offset) do
            for _, v in pairs(stats.trusted_offset[axis]) do
                read_maj_offset[axis] = read_maj_offset[axis] .. v .. " "
            end
        end
        mp.msg.info(
            string.format("Limit - min/max: %s/%s | counter: %s", limit.min, options.detect_limit, limit.counter))
        mp.msg.info(string.format("Trusted - unique: %s | offset: X:%sY:%s", stats.trusted_unique, read_maj_offset.x,
                                  read_maj_offset.y))
        for whxy, ref in pairs(stats.trusted) do
            if stats.trusted[whxy] then
                mp.msg.info(string.format("\\ %-29s | offX=%3s offY=%3s | applied=%s overall=%s last_seen=%s", whxy,
                                          ref.offset.x, ref.offset.y, ref.applied, convert_ms_to_sec(ref.time.overall),
                                          convert_ms_to_sec(ref.time.last_seen)))
            end
        end
        mp.msg.info("Buffer - unique: " .. buffer.unique_meta .. " | total: " .. buffer.index_total,
                    convert_ms_to_sec(buffer.time_total) .. "sec | known_ratio:", buffer.index_known_ratio,
                    convert_ms_to_sec(buffer.time_known) .. "sec")
        -- if options.debug and stats.buffer then
        --     for whxy, ref in pairs(stats.buffer) do
        --         mp.msg.info(string.format(
        --                         "\\ %-29s | offX=%3s offY=%3s | time=%6ssec linked_source=%-4s known_ratio=%-4s trusted_offsets=%s",
        --                         whxy, ref.offset.x, ref.offset.y, convert_ms_to_sec(ref.time.buffer),
        --                         ref.is_linked_to_source, ref.is_known_ratio, ref.is_trusted_offsets))
        --     end
        --     for pos, ref in pairs(buffer.ordered) do
        --         mp.msg.info(string.format("-- %3s %-29s %sms", pos, ref[1].whxy, ref[2]))
        --     end
        --     for pos, ref in pairs(stats.applied) do
        --         mp.msg.info(string.format("-- %3s %8s %s", pos, convert_ms_to_sec(ref[1]), ref[2].whxy))
        --     end
        -- end
    end
end

local function process_metadata(timestamp, collected)
    in_progress = true -- prevent event race

    local elapsed_time = timestamp - timestamps.insert
    print_debug(collected, "detail", "Collected")
    timestamps.insert = timestamp

    local function cleanup_stat(whxy, ref, ref_i, index)
        if ref[whxy] then
            ref[whxy] = nil
            ref_i[index] = ref_i[index] - 1
        end
    end

    -- init stats.buffer[whxy]
    if not stats.buffer[collected.whxy] then
        stats.buffer[collected.whxy] = collected
        buffer.unique_meta = buffer.unique_meta + 1
    end
    -- add collected to the buffer
    if buffer.index_total == 0 or buffer.ordered[buffer.index_total][1] ~= collected then
        table.insert(buffer.ordered, {collected, elapsed_time})
        buffer.index_total = buffer.index_total + 1
        buffer.index_known_ratio = buffer.index_known_ratio + 1
    elseif last_collected == collected then
        buffer.ordered[buffer.index_total][2] = buffer.ordered[buffer.index_total][2] + elapsed_time
    end
    collected.time.overall = collected.time.overall + elapsed_time
    collected.time.buffer = collected.time.buffer + elapsed_time
    buffer.time_total = buffer.time_total + elapsed_time
    if buffer.index_known_ratio > 0 then buffer.time_known = buffer.time_known + elapsed_time end

    -- candidate offset/fallback
    if not stats.trusted[collected.whxy] and collected.time.buffer > o_timer.new_known_ratio then
        if not candidate.offset[collected.whxy] and not collected.is_trusted_offsets and collected.is_known_ratio and
            collected.is_linked_to_source then
            candidate.offset[collected.whxy] = collected
            candidate.offset_i = candidate.offset_i + 1
        elseif not candidate.offset[collected.whxy] and not candidate.fallback[collected.whxy] then
            candidate.fallback[collected.whxy] = collected
            candidate.fallback_i = candidate.fallback_i + 1
        end
    end

    -- reset last_seen before correction
    if stats.trusted[collected.whxy] and collected.time.last_seen < 0 then collected.time.last_seen = 0 end

    -- add new offset to the trusted_offset list
    if not collected.is_trusted_offsets and stats.buffer[collected.whxy] and collected.is_known_ratio and
        (collected.is_linked_to_source and collected.time.buffer >= o_timer.new_offset or collected.time.buffer >=
            o_timer.new_fallback) then
        for _, axis in pairs({"x", "y"}) do
            if not is_trusted_offset(collected.offset[axis], axis) then
                table.insert(stats.trusted_offset[axis], collected.offset[axis])
            end
        end
        cleanup_stat(collected.whxy, candidate.offset, candidate, "offset_i")
        collected.is_trusted_offsets = true
    end

    -- add collected ready to the trusted list
    local new_ready =
        not stats.trusted[collected.whxy] and collected.is_trusted_offsets and not collected.is_invalid and
            (collected.is_known_ratio and
                (collected.is_linked_to_source and collected.time.buffer >= o_timer.new_linked_known_ratio or
                    collected.time.buffer >= o_timer.new_known_ratio) or not collected.is_known_ratio and
                collected.time.buffer >= o_timer.new_fallback)
    if new_ready then
        stats.trusted[collected.whxy] = collected
        stats.trusted_unique = stats.trusted_unique + 1
        collected.applied, collected.time.last_seen = 0, collected.time.buffer
        cleanup_stat(collected.whxy, candidate.fallback, candidate, "fallback_i")
    end

    -- use current as main metadata that can be collected/corrected/stabilized
    local current = collected

    -- correction with trusted metadata for fast change in dark/ambiguous scene
    local corrected = {}
    if not current.is_invalid and not current.is_trusted_offsets then
        -- find closest trusted metadata
        local closest = {}
        for _, ref in pairs(stats.trusted) do
            local diff = {ref = ref, vs_current = 0, vs_applied = 0, closest_side = {}}
            for _, side in pairs({"mt", "mb", "ml", "mr"}) do
                diff[side] = math.abs(current[side] - ref[side])
                if diff[side] > 0 then
                    diff.vs_current = diff.vs_current + 1
                    table.insert(diff.closest_side, diff[side])
                elseif ref[side] ~= applied[side] then
                    diff.vs_applied = diff.vs_applied + 1
                end
            end
            table.sort(diff.closest_side, function(k1, k2) return k1 < k2 end)
            local ge_applied = ref.w >= applied.w and ref.h >= applied.h
            local diff_2 = diff.vs_current == 2 and (ge_applied or not ge_applied and diff.vs_applied == 2)
            local diff_3_4 = diff.vs_current > 2 and ref.w >= current.w and ref.h >= current.h and ge_applied
            local pattern = (diff.vs_current == 1 or diff_2 or diff_3_4)
            local closest_side
            if closest.ref and diff.vs_current >= 1 and diff.vs_current == closest.vs_current then
                for i = 1, diff.vs_current do
                    if diff.closest_side[i] < closest.closest_side[i] then closest_side = true end
                    if diff.closest_side[i] ~= closest.closest_side[i] then break end
                end
            end
            local set = closest.ref and (diff.vs_current < closest.vs_current or closest_side)
            if pattern and (not closest.ref or set) then
                closest = diff
                closest.diff_3_4 = diff_3_4
            end
            -- print(string.format("\\ %-5s %-29s curr:%s appl:%s | %-3s %-3s %-3s %-3s", closest == diff, ref.whxy,
            -- diff.vs_current, diff.vs_applied, diff.mt, diff.mb, diff.ml, diff.mr))
        end
        -- replace current with corrected
        if closest.ref then
            current, corrected.ref = closest.ref, closest.ref
            corrected.vs_current, corrected.diff_3_4 = closest.vs_current, closest.diff_3_4
            print_debug(current, "detail", "\\ Corrected")
        end
    end

    -- stabilization of odd/unstable meta
    local stabilized
    if options.detect_round <= 4 and stats.trusted[current.whxy] then
        local margin = options.detect_round * 4
        local applied_in_margin = math.abs(current.w - applied.w) <= margin and math.abs(current.h - applied.h) <=
                                      margin
        for _, ref in pairs(stats.trusted) do
            local in_margin = math.abs(current.w - ref.w) <= margin and math.abs(current.h - ref.h) <= margin
            if in_margin then
                local gt_applied = applied_in_margin and ref ~= applied and ref.time.overall > applied.time.overall * 2
                local applied_gt = applied_in_margin and ref == applied and ref.time.overall * 2 > current.time.overall
                local pattern = not applied_in_margin and ref.time.overall > current.time.overall or gt_applied or
                                    applied_gt
                local set = stabilized and ref.time.overall > stabilized.time.overall
                -- print("\\", ref.whxy, ref.time.overall, current.time.overall, applied.time.overall)
                if ref ~= current and pattern and (not stabilized or set) then stabilized = ref end
            end
        end
        if stabilized then
            current = stabilized
            print_debug(current, "detail", "\\ Stabilized")
        end
    end

    -- cycle last_seen
    for whxy, ref in pairs(stats.trusted) do
        if whxy ~= current.whxy then
            if ref.time.last_seen > 0 then ref.time.last_seen = 0 end
            ref.time.last_seen = ref.time.last_seen - elapsed_time
        else
            if ref.time.last_seen < 0 then ref.time.last_seen = 0 end
            ref.time.last_seen = ref.time.last_seen + elapsed_time
        end
    end

    -- apply crop
    local detect_source = current == last_current and (current.is_source or collected.is_source) and limit.target >= 0
    local confirmation = not current.is_source and stats.trusted[current.whxy] and current.time.last_seen >=
                             o_timer.fast_change and (not corrected.ref or current == last_current)
    local crop_filter = applied.whxy ~= current.whxy and (confirmation or detect_source)
    if crop_filter and (not timestamps.prevent or timestamp >= timestamps.prevent) then
        if limit.current < limit.min then limit.min = limit.current end -- store minimum limit
        osd_size_change()
        manage_filter("append", string.format("%s:lavfi-crop=%s", labels.crop, current.whxy))
        print_debug(string.format("- Apply: %s", current.whxy))
        current.applied = current.applied + 1
        table.insert(stats.applied, {timestamp, current})
        applied = current
        if o_timer.prevent_change > 0 then
            timestamps.prevent = nil
            if (options.prevent_change_mode == 1 and (current.w > applied.w or current.h > applied.h) or
                options.prevent_change_mode == 2 and (current.w < applied.w or current.h < applied.h) or
                options.prevent_change_mode == 0) then
                timestamps.prevent = timestamp + o_timer.prevent_change
            end
        end
        if options.mode <= 2 then on_toggle(true) end
    end

    -- cleanup buffer
    local function time_to_cleanup_buffer(time_1, time_2) return time_1 > time_2 * (1 + options.segmentation) end
    while time_to_cleanup_buffer(buffer.time_known, o_timer.new_known_ratio) do
        local position = (buffer.index_total + 1) - buffer.index_known_ratio
        buffer.time_known = buffer.time_known - buffer.ordered[position][2]
        buffer.index_known_ratio = buffer.index_known_ratio - 1
    end
    -- check for offset/fallback candidate to extend buffer
    local buffer_timer = o_timer.new_known_ratio
    if candidate.fallback_i > 0 then
        buffer_timer = o_timer.new_fallback
    elseif candidate.offset_i > 0 then
        buffer_timer = o_timer.new_offset
    end
    local function proactive_cleanup() -- start to cleanup if too much unique meta are present
        return buffer.time_total > buffer.time_known and buffer.unique_meta > buffer.index_total *
                   (buffer_timer * options.segmentation / (buffer_timer * (1 + options.segmentation))) + 1
    end
    while time_to_cleanup_buffer(buffer.time_total, buffer_timer) or proactive_cleanup() do
        local ref = buffer.ordered[1][1]
        ref.time.buffer = ref.time.buffer - buffer.ordered[1][2]
        if stats.buffer[ref.whxy] and ref.time.buffer == 0 then
            cleanup_stat(ref.whxy, stats.buffer, buffer, "unique_meta")
            cleanup_stat(ref.whxy, candidate.offset, candidate, "offset_i")
            cleanup_stat(ref.whxy, candidate.fallback, candidate, "fallback_i")
        end
        buffer.time_total = buffer.time_total - buffer.ordered[1][2]
        buffer.index_total = buffer.index_total - 1
        table.remove(buffer.ordered, 1)
    end

    -- auto limit
    local limit_current = limit.current
    if options.limit_timer == 0 or timestamp >= limit.timer then
        limit.last_target = limit.target
        if not collected.is_source and not current.is_invalid and -- stable limit
            (collected.is_trusted_offsets or collected == last_collected or current == last_current and corrected.ref and
                not current.is_source) then
            limit.target = 0
            -- reset limit to help with different dark color
            if not current.is_trusted_offsets then limit.current = options.detect_limit end
        elseif collected.is_source or current.is_source and corrected.ref and
            (corrected.vs_current == 1 or not applied.is_source and corrected.diff_3_4) then -- increase limit
            limit.target = 1
            if limit.current + limit.step * limit.up <= options.detect_limit then
                limit.current = limit.current + limit.step * limit.up
            else
                limit.current = options.detect_limit
            end
        elseif limit.current > 0 then -- decrease limit
            limit.target = -1
            if limit.min < limit.current and limit.last_target == -1 then
                limit.current = limit.min
            elseif limit.current - limit.step >= 0 then
                limit.current = limit.current - limit.step
            else
                limit.current = 0
            end
        end
    end

    -- store for next process
    last_current = current
    last_collected = collected

    -- apply limit change
    if limit_current ~= limit.current then
        if options.limit_timer > 0 then limit.timer = timestamp + o_timer.limit end
        limit.counter = limit.counter + 1
        insert_cropdetect_filter()
    end
end

local function update_time_pos(_, timestamp)
    if not timestamp then return end

    timestamps.previous = timestamps.current
    timestamps.current = convert_sec_to_ms(timestamp) -- %.3f into int
    if not timestamps.insert then timestamps.insert = timestamps.current end

    if in_progress or not collected_.whxy or not timestamps.previous or filter_inserted or seeking or paused or toggled >
        1 or timestamp < options.start_delay then return end

    process_metadata(timestamps.current, collected_)
    collectgarbage("step")
    in_progress = false
end

local function collect_metadata(_, ref)
    -- check the new metadata for availability and change
    if ref and ref["lavfi.cropdetect.w"] and ref["lavfi.cropdetect.h"] then
        local tmp = {
            w = tonumber(ref["lavfi.cropdetect.w"]),
            h = tonumber(ref["lavfi.cropdetect.h"]),
            x = tonumber(ref["lavfi.cropdetect.x"]),
            y = tonumber(ref["lavfi.cropdetect.y"])
        }
        tmp.whxy = string.format("w=%s:h=%s:x=%s:y=%s", tmp.w, tmp.h, tmp.x, tmp.y)
        timestamps.insert = timestamps.current
        if tmp.whxy ~= collected_.whxy then
            -- use known table if it exists or compute meta
            if stats.trusted[tmp.whxy] then
                collected_ = stats.trusted[tmp.whxy]
            elseif stats.buffer[tmp.whxy] then
                collected_ = stats.buffer[tmp.whxy]
            else
                collected_ = compute_metadata(tmp)
            end
        end
        filter_inserted = false
    end
end

local function seek(name, filter_change)
    print_debug(string.format("Stop by %s event.", name))
    if filter_change and filter_state(labels.cropdetect, "enabled", true) then
        manage_filter("toggle", labels.cropdetect)
    end
    collected_, timestamps, limit.timer = {}, {}, 0
end

local function resume(name, filter_change)
    print_debug(string.format("Resume by %s event.", name))
    if filter_change then insert_cropdetect_filter() end
end

local function playback_events(event, id, error)
    if event["event"] == "seek" then
        seeking = true
        if not paused then seek(event["event"], false) end
    else
        if not paused then resume(event["event"], false) end
        seeking = false
    end
end

function on_toggle(auto)
    if filter_missing then
        mp.osd_message("Libavfilter cropdetect missing", 3)
        return
    end
    -- cycle toggled, 1-enable, 2-disable|crop, 3-disable|nocrop
    if toggled == 1 then
        toggled = 2
        seek("toggle", true)
        if not auto then mp.osd_message(string.format("%s paused.", label_prefix), 3) end
    elseif toggled == 2 then
        toggled = 3
        if filter_state(labels.crop, "enabled", true) and filter_state(labels.cropdetect, "enabled", false) then
            manage_filter("toggle", labels.crop)
            applied = source
        end
    else
        toggled = 1
        resume("toggle", true)
        if not auto then mp.osd_message(string.format("%s resumed.", label_prefix), 3) end
    end
end

local function pause(_, bool)
    if bool then
        seek("pause", true)
        print_debug(nil, "stats")
        paused = true
    else
        paused = false
        if toggled == 1 then resume("unpause", true) end
    end
end

function cleanup()
    if not paused then print_debug(nil, "stats") end
    mp.msg.info("Cleanup...")
    mp.set_property("geometry", user_geometry)
    mp.unregister_event(playback_events)
    mp.unobserve_property(collect_metadata)
    mp.unobserve_property(update_time_pos)
    mp.unobserve_property(pause)
    for _, label in pairs(labels) do if filter_state(label) then manage_filter("remove", label) end end
    mp.msg.info("Done.")
end

local function on_start()
    mp.msg.info("File loaded.")
    if not is_cropable() then
        mp.msg.warn("Exit, only works for videos.")
        return
    end
    -- init/re-init source, buffer, limit and other data
    buffer = {index_total = 0, index_known_ratio = 0, ordered = {}, time_total = 0, time_known = 0, unique_meta = 0}
    limit = {counter = 0, step = 2, target = 0, timer = 0, up = 2}
    limit.current, limit.min = options.detect_limit, options.detect_limit
    collected_, stats = {}, {buffer = {}, trusted = {}, trusted_offset = {x = {}, y = {}}, trusted_unique = 1}
    candidate = {offset = {}, offset_i = 0, fallback = {}, fallback_i = 0}
    source = {w_untouched = mp.get_property_number("width"), h_untouched = mp.get_property_number("height")}
    source.w = math.floor(source.w_untouched / options.detect_round) * options.detect_round
    source.h = math.floor(source.h_untouched / options.detect_round) * options.detect_round
    source.x, source.y = (source.w_untouched - source.w) / 2, (source.h_untouched - source.h) / 2
    stats.trusted_offset = {x = {source.x}, y = {source.y}}
    stats.applied = {}
    source = compute_metadata(source)
    stats.trusted[source.whxy] = source
    source.applied, source.time.last_seen = 1, 0
    applied = source
    timestamps = {current = mp.get_property_number("time-pos")}
    -- register events
    mp.register_event("seek", playback_events)
    mp.register_event("playback-restart", playback_events)
    mp.observe_property("pause", "bool", pause)
    mp.observe_property(string.format("vf-metadata/%s", labels.cropdetect), "native", collect_metadata)
    mp.observe_property("time-pos", "number", update_time_pos)
    toggled = 1 -- 2/4 auto start
    if options.mode % 2 == 1 then toggled = 3 end -- 1/3 manual start
end

mp.add_key_binding("C", "toggle_crop", on_toggle)
mp.register_event("end-file", cleanup)
mp.register_event("file-loaded", on_start)
