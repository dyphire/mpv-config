--[[
This script uses the lavfi cropdetect filter to automatically insert a crop filter with appropriate parameters
    for the currently playing video, the script run continuously by default (mode 4).

To use this script, "hwdec=no" (mpv default/recommended) or any "-copy" variant like "hwdec=auto-copy" is required,
    consider editing "mpv.conf" to an appropriate value.

The workflow is as follows: We observe ffmpeg log to collect metadata and process it.
    Collected metadata are stored sequentially in s.buffer, then process to check and
    store trusted values to speed up future change for the current video.
    It will automatically crop the video as soon as a change is validated.

The default options can be overridden by adding a line into "mpv.conf" with:
    script-opts-append=<script_name>-<parameter>=<value>
    script-opts-append=dynamic_crop-mode=0
    script-opts-append=dynamic_crop-ratios=2.4 2.39 2 4/3 (quotes aren't needed like below)

Extended descriptions for some parameters (For default values, see <options>):

mode: [0-4] 0 disable, 1 on-demand, 2 one-shot, 3 dynamic-manual, 4 dynamic-auto
    Mode 1 and 3 requires using the shortcut to start, 2 and 4 have an automatic start.

Shortcut "C" (shift+c) to control the script.
Cycle between ENABLE / DISABLE_WITH_CROP / DISABLE

prevent_change_mode: [0-3] 0 disable 1 keep-largest, 2 keep-lowest, 3 keep-latest
    The prevent_change_timer is trigger after a change.

fix_windowed_behavior: [0-3] Avoid the default behavior that resizes the window to the source size
    when the crop filter changes in windowed/maximized mode by adjusting geometry.

limit_timer: Only used if the cropdetect filter doesn't handle limit changes with a command (patch 01/2023).
    Extend the time between each limit change to reduce the impact on performance caused by re-initializing the
    full filter.

read_ahead_mode: Linked to the associated timer and tells how much time in advance to collect the metadata.
    This feature is useful for videos with multiple aspect ratio changes for "fast_change_timer".
    Note: because this function is in sync with the playback, a delay equivalent to the timer used is
    added/reset every time you seek before you get a reaction, so setting 1 is recommanded.
    Required at least https://github.com/FFmpeg/FFmpeg/commit/69c060bea21d3b4ce63b5fff40d37e98c70ab88f
    and optionally https://github.com/mpv-player/mpv/pull/11182, until mpv patch is being merged to master,
    considered this feature experimental because of the errors generated in logs/console by vf-command and
    the filter used to sync the filter chain (psnr).

read_ahead_sync: Compensates for the delay when applying the crop filter and the visible result.
    Must be adjusted to your tastes and each MPV client depending on their reaction time.
    Note: Perfect adjustment is not really possible but generally <= 1 frame, sometimes more in
    dark/ambiguous scenes.

segmentation: e.g. 0.5 for 50% - Extra time to allow new metadata to be segmented instead of being continuous.
    This is used with ratio_timer, offset_timer and fallback_timer.
    e.g. ratio_timer is validated with 5 sec accumulated over 7.5 sec elapsed.
]] --
require "mp.options"

-- options
local options = {
    -- behavior
    mode = 4, -- [0-4] more details above
    start_delay = 0, -- delay in seconds used to skip intro (usefull with mode 2)
    prevent_change_timer = 30, -- seconds
    prevent_change_mode = 0, -- [0-3], more details above
    fix_windowed_behavior = 1, -- [0-3], 0 no-fix, 1 fix-no-resize, 2 fix-keep-width, 3 fix-keep-height
    limit_timer = 0.5, -- seconds, 0 disable, more details above
    fast_change_timer = 0.2, -- seconds, recommanded to keep default or > 0 if read_ahead is supported by mpv
    ratio_timer = 2, -- seconds, meta in ratios list
    offset_timer = 20, -- seconds, >= 'ratio_timer', new offset for asymmetric video
    fallback_timer = 40, -- seconds, >= 'offset_timer', not in ratios list and possibly with new offset
    linked_tolerance = 2, -- int, scale with detect_round to match against source width/height
    ratios = "2.76 2.55 24/9 2.4 2.39 2.35 2.2 2.1 2 1.9 1.85 16/9 5/3 1.5 1.43 4/3 1.25 9/16", -- list
    ratio_tolerance = 2, -- int (even number), adjust in order to match more easly the ratios list
    read_ahead_mode = 0, -- [0-2], 0 disable, 1 fast_change_timer, 2 ratio_timer, more details above
    read_ahead_sync = 0, -- int/frame, increase for advance, more details above
    segmentation = 0.5, -- [0.0-1] %, 0 will approved only a continuous metadata (strict)
    crop_method = 1, -- 0 lavfi-crop (ffmpeg/filter), 1 video-crop (mpv/VO)
    -- filter, see https://ffmpeg.org/ffmpeg-filters.html#cropdetect for details
    detect_limit = 26, -- is the maximum use, increase it slowly if lighter black are present
    detect_round = 2, -- even number
    -- verbose
    debug = false
}
read_options(options)

if options.mode == 0 then
    mp.msg.info("mode = 0, disable script.")
    return
end

-- forward declarations
local cleanup, on_toggle
local s = {}

-- labels
local label_prefix = mp.get_script_name()
local labels = {
    crop = string.format("%s-crop", label_prefix), cropdetect = string.format("%s-cropdetect", label_prefix)
}

-- shifting decimal to
local LEFT, RIGHT = true, false
local function shifting_to(left, value)
    local shift = 1e3
    return left and (value / shift) or value >= 1 and math.ceil(value * shift) or value * shift
end

-- options: compute timer and other stuff
for k, v in pairs(options) do
    local timer = string.match(tostring(k), "_timer")
    if timer then options[k] = shifting_to(RIGHT, v) end
end
options.read_ahead_timer =
    options.read_ahead_mode == 1 and options.fast_change_timer or options.read_ahead_mode == 2 and options.ratio_timer *
        (1 + options.segmentation) or nil
options.read_ahead_cropdetect = options.read_ahead_timer and shifting_to(LEFT, options.read_ahead_timer) or nil
options.reverse_segmentation = 1 / (1 * (1 + options.segmentation))
options.crop_method_sync = options.crop_method == 0 and 1 or 0 -- lavfi-crop is slower, so give it some advance for read_ahead

local function print_debug(msg_type, meta, label)
    if not options.debug then
        return
    elseif msg_type == "pre_format" then
        mp.msg.info(meta)
    elseif msg_type == "metadata" then
        mp.msg.info(string.format("%s, %-29s | offX:%3s offY:%3s | limit:%-2s", label, meta.whxy, meta.offset.x,
            meta.offset.y, s.limit.current))
    elseif msg_type == "buffer" and s.stats.buffer then
        mp.msg.info("Buffer stats:")
        for whxy, ref in pairs(s.stats.buffer) do
            mp.msg.info(string.format(
                "\\ %-29s | offX=%4s offY=%4s | time=%6ss linked_source=%-4s known_ratio=%-4s trusted_offsets=%s", whxy,
                ref.offset.x, ref.offset.y, shifting_to(LEFT, ref.time.buffer), ref.is_linked_to_source or false,
                ref.is_known_ratio or false, ref.is_trusted_offsets))
        end
        mp.msg.info("Buffer list:")
        for i, v in ipairs(s.buffer.indexed_list) do
            local new_ref = v.new_ref and v.new_ref.whxy or ""
            local pts = shifting_to(RIGHT, v.pts)
            mp.msg.info(string.format("\\ %3s %-29s %4sms pts:%d new_ref:%s", i, v.ref.whxy, v.t_elapsed, pts, new_ref))
        end
        mp.msg.info("i_fallback", s.candidate.i_fallback)
        mp.msg.info("i_offset", s.candidate.i_offset)
    elseif msg_type == "applied" and s.stats.indexed_applied then
        mp.msg.info("Applied list:")
        for i, v in ipairs(s.stats.indexed_applied) do
            mp.msg.info(string.format("\\ %3s %-29s pts:%d", i, v.ref.whxy, shifting_to(RIGHT, v.pts)))
        end
    end
end

local function print_stats()
    if not s.stats and not s.stats.trusted then return end
    mp.msg.info("Meta Stats:")
    local offsets_list = {x = "", y = ""}
    for axis, _ in pairs(offsets_list) do
        for _, v in pairs(s.stats.trusted_offset[axis]) do offsets_list[axis] = offsets_list[axis] .. v .. " " end
    end
    mp.msg.info(
        string.format("Limit - min/max: %s/%s | counter: %s", s.limit.min, options.detect_limit, s.limit.counter))
    mp.msg.info(string.format("Trusted - unique: %s | offset: X:%sY:%s", s.stats.trusted_unique, offsets_list.x,
        offsets_list.y))
    for whxy, ref in pairs(s.stats.trusted) do
        if s.stats.trusted[whxy] then
            mp.msg.info(string.format("\\ %-29s | offX=%3s offY=%3s | applied=%s overall=%ss accumulated=%ss", whxy,
                ref.offset.x, ref.offset.y, ref.applied, shifting_to(LEFT, ref.time.overall),
                shifting_to(LEFT, ref.time.accumulated)))
        end
    end
    mp.msg.info("Buffer - unique: " .. s.stats.buffer_unique .. " | total: " .. s.buffer.i_total,
        shifting_to(LEFT, s.buffer.t_total) .. "s | known_ratio:", s.buffer.i_ratio,
        shifting_to(LEFT, s.buffer.t_ratio) .. "s")
end

local function is_trusted_offset(offset, axis)
    local trusted_offset = s.stats.trusted_offset[axis]
    for _, v in ipairs(trusted_offset) do if math.abs(offset - v) <= 1 then return true end end
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
        if filter["label"] == label and
            ((not key or key ~= "graph" and filter[key] == value or key == "graph" and
                string.find(filter.params.graph, value))) then return true end
    end
    return false
end

local function command_filter(label, command, argument, target)
    if not s.f_vfcommand then
        local res, reason = mp.commandv("vf-command", label, command, argument, target)
        if not res and reason == "invalid parameter" then
            s.f_vfcommand = true -- if mpv doesn't handle target parameter
        end
    end
    if s.f_vfcommand then
        -- fallback and send to all filters inside the graph
        mp.commandv("vf-command", label, command, argument)
    end
end

local function insert_cropdetect_filter(limit, change)
    if s.toggled > 1 or s.paused then return end
    local function insert_filter()
        local cropdetect = string.format("cropdetect@dyn_cd=limit=%d/255:round=%d:reset=1", limit, options.detect_round)
        if s.f_limit_runtime and change then
            command_filter(labels.cropdetect, "limit", string.format("%d/255", limit), "cropdetect")
            return true
        elseif s.f_limit_runtime and options.read_ahead_mode > 0 then
            return mp.commandv("vf", "pre",
                string.format("@%s:lavfi=[split[a][b];[b]setpts=PTS-%s/TB,%s[b];%s]", labels.cropdetect,
                    options.read_ahead_cropdetect, cropdetect, s.f_sync))
        else
            return mp.commandv("vf", "pre", string.format("@%s:lavfi=[split[a][b];[b]%s,nullsink;[a]null]",
                labels.cropdetect, cropdetect))
        end
    end
    if not insert_filter() then
        mp.msg.error("Does vf=help as #1 line in mvp.conf return libavfilter list with crop/cropdetect in log?")
        s.f_missing = true
        cleanup()
        return
    end
    if not s.f_limit_runtime then
        s.f_inserted = true -- skip process and wait for new s.collected
    end
    s.f_limit_change = change -- filter is updated for limit change
end

local function apply_crop(ref, pts)
    -- osd size change
    -- TODO add auto/smart mode
    local prop_fullscreen = mp.get_property("fullscreen")
    if prop_fullscreen ~= "yes" and options.fix_windowed_behavior ~= 0 then
        local prop_maximized = mp.get_property("window-maximized")
        local osd = mp.get_property_native("osd-dimensions")
        local prop_auto_window_resize = mp.get_property("auto-window-resize")
        if prop_auto_window_resize == "yes" and options.fix_windowed_behavior == 1 then
            -- disable auto resize to avoid resizing at the original size of the video
            mp.set_property("auto-window-resize", "no")
        end
        if prop_maximized ~= "yes" then
            if options.fix_windowed_behavior == 2 then
                mp.set_property("geometry", string.format("%s", osd.w))
            elseif options.fix_windowed_behavior == 3 then
                mp.set_property("geometry", string.format("x%s", osd.h))
            end
        end
    end

    -- crop filter insertion/update
    if s.f_video_crop then
        mp.set_property("video-crop", string.format("%sx%s+%s+%s", ref.w, ref.h, ref.x, ref.y))
    elseif filter_state(labels.crop) and not s.seeking then
        for _, axis in ipairs({"w", "x", "h", "y"}) do -- "w""x" then "h""y" to reduce visual glitch
            if s.applied[axis] ~= ref[axis] then command_filter(labels.crop, axis, ref[axis], "crop") end
        end
    else
        mp.commandv("vf", "append", string.format("@%s:lavfi-crop=%s", labels.crop, ref.whxy))
    end
    ref.applied = ref.applied + 1
    s.applied = ref

    print_debug("pre_format", string.format("- Apply: %s", ref.whxy))
    if options.debug and pts then table.insert(s.stats.indexed_applied, {ref = ref, pts = pts}) end
end

local function compute_metadata(meta)
    meta.whxy = string.format("w=%s:h=%s:x=%s:y=%s", meta.w, meta.h, meta.x, meta.y)
    meta.offset = {x = meta.x - (s.source.w - meta.w) / 2, y = meta.y - (s.source.h - meta.h) / 2}
    meta.mt = meta.y
    meta.mb = s.source.h - meta.h - meta.y
    meta.ml = meta.x
    meta.mr = s.source.w - meta.w - meta.x
    meta.is_source = meta.whxy == s.source.whxy
    meta.is_invalid = meta.h < 0 or meta.w < 0
    meta.is_trusted_offsets = is_trusted_offset(meta.offset.x, "x") and is_trusted_offset(meta.offset.y, "y")
    meta.time = {buffer = 0, overall = 0}
    if options.read_ahead_mode > 0 then meta.pts = {} end
    local margin = options.detect_round * options.linked_tolerance
    meta.is_linked_to_source = meta.mt <= margin and meta.mb <= margin or meta.ml <= margin and meta.mr <= margin
    if meta.is_linked_to_source and not meta.is_invalid and s.ratios.w[meta.w] or s.ratios.h[meta.h] then
        meta.is_known_ratio = true
    end
    return meta
end

local function generate_ratios(list)
    for ratio in string.gmatch(list, "%S+%s?") do
        for a, b in string.gmatch(tostring(ratio), "(%d+)/(%d+)") do ratio = a / b end
        local w, h = math.floor((s.source.h * ratio)), math.floor((s.source.w / ratio))
        local margin = options.ratio_tolerance
        for k, v in pairs({w = w, h = h}) do
            if v < s.source[k] - options.linked_tolerance then
                if v % 2 == 1 then
                    s.ratios[k][v + 1], s.ratios[k][v - 1] = true, true
                    if margin > 0 then
                        s.ratios[k][v + 1 + margin], s.ratios[k][v - 1 - margin] = true, true
                    end
                else
                    s.ratios[k][v] = true
                    if margin > 0 then s.ratios[k][v + margin], s.ratios[k][v - margin] = true, true end
                end
            end
        end
    end
end

local function switch_hwdec(id, hwdec, error)
    if hwdec ~= "no" and not string.match(hwdec, "-copy") then
        local msg = "Switch to SW decoding or HW -copy variant."
        mp.msg.info(msg)
        mp.osd_message(string.format("%s: %s", label_prefix, msg), 5)
    end
    if s.hwdec and hwdec ~= s.hwdec and s.hwdec ~= "no" and not string.match(s.hwdec, "-copy") and
        filter_state(labels.cropdetect) then mp.commandv("vf", "remove", string.format("@%s", labels.cropdetect)) end
    s.hwdec = hwdec
end

local function process_metadata(collected, timestamp, elapsed_time)
    s.in_progress = true -- prevent event race
    print_debug("metadata", collected, "Collected")

    local function cleanup_stat(whxy, ref, ref_i, index)
        if ref[whxy] then
            ref[whxy] = nil
            ref_i[index] = ref_i[index] - 1
        end
    end

    -- buffer: init
    if not s.stats.buffer[collected.whxy] then
        s.stats.buffer[collected.whxy] = collected
        s.stats.buffer_unique = s.stats.buffer_unique + 1
    end

    -- buffer: add collected or increase it's timer
    if s.buffer.i_total == 0 or s.buffer.indexed_list[s.buffer.i_total].ref ~= collected then
        s.buffer.i_total = s.buffer.i_total + 1
        s.buffer.i_ratio = s.buffer.i_ratio + 1
        s.buffer.indexed_list[s.buffer.i_total] = {ref = collected, pts = timestamp, t_elapsed = elapsed_time}
        if options.read_ahead_mode > 0 then table.insert(collected.pts, timestamp) end
    elseif s.last_collected == collected then
        s.buffer.indexed_list[s.buffer.i_total].t_elapsed = s.buffer.indexed_list[s.buffer.i_total].t_elapsed +
                                                                elapsed_time
    end
    collected.time.overall = collected.time.overall + elapsed_time
    collected.time.buffer = collected.time.buffer + elapsed_time
    s.buffer.t_total = s.buffer.t_total + elapsed_time
    if s.buffer.i_ratio > 0 then s.buffer.t_ratio = s.buffer.t_ratio + elapsed_time end

    -- candidate offset/fallback to later extend buffer size
    if not s.stats.trusted[collected.whxy] and collected.time.buffer > options.ratio_timer and
        collected.is_linked_to_source then
        if not s.candidate.offset[collected.whxy] and not collected.is_trusted_offsets and collected.is_known_ratio then
            s.candidate.offset[collected.whxy] = collected
            s.candidate.i_offset = s.candidate.i_offset + 1
        elseif not collected.is_known_ratio and not s.candidate.offset[collected.whxy] and
            not s.candidate.fallback[collected.whxy] then
            s.candidate.fallback[collected.whxy] = collected
            s.candidate.i_fallback = s.candidate.i_fallback + 1
        end
    end

    -- add new fallback ratio to the ratio list
    if s.candidate.fallback[collected.whxy] and collected.time.buffer >= options.fallback_timer then
        -- TODO eventually re-check the buffer list with new ratio
        generate_ratios(collected.w .. "/" .. collected.h)
        collected.is_known_ratio = true
        cleanup_stat(collected.whxy, s.candidate.fallback, s.candidate, "i_fallback")
    end

    -- add new offset to the trusted_offsets list
    if s.candidate.offset[collected.whxy] and collected.is_known_ratio and collected.is_linked_to_source and
        collected.time.buffer >= options.offset_timer then
        for _, axis in ipairs({"x", "y"}) do
            if not is_trusted_offset(collected.offset[axis], axis) then
                table.insert(s.stats.trusted_offset[axis], collected.offset[axis])
            end
        end
        cleanup_stat(collected.whxy, s.candidate.offset, s.candidate, "i_offset")
        collected.is_trusted_offsets = true
    end

    -- add collected ready to the trusted list
    local new_ready =
        not s.stats.trusted[collected.whxy] and collected.is_trusted_offsets and not collected.is_invalid and
            collected.is_linked_to_source and collected.is_known_ratio and collected.time.buffer >= options.ratio_timer
    if new_ready then
        s.stats.trusted[collected.whxy] = collected
        s.stats.trusted_unique = s.stats.trusted_unique + 1
        collected.applied = 0
        collected.time.accumulated = collected.time.buffer
    end

    -- use current as main metadata, override by corrected or stabilized if needed
    local current = collected

    -- correction with trusted metadata for fast change in dark/ambiguous scene
    local corrected = {}
    if not current.is_invalid and s.stats.trusted_unique > 1 and not s.stats.trusted[current.whxy] then
        -- is_bigger than applied meta
        corrected.is_bigger = current.mt < s.approved.mt or current.mb < s.approved.mb or current.ml < s.approved.ml or
                                  current.mr < s.approved.mr
        -- find closest trusted metadata
        local closest = {}
        local margin = options.detect_round * options.linked_tolerance
        for _, ref in pairs(s.stats.trusted) do
            local diff = {ref = ref, vs_current = 0, vs_applied = 0, total = 0}
            for _, side in ipairs({"mt", "mb", "ml", "mr"}) do
                diff[side] = current[side] - ref[side]
                diff.total = diff.total + math.abs(diff[side])
                if diff[side] > margin or diff[side] < -margin then diff.vs_current = diff.vs_current + 1 end
                if ref[side] ~= s.approved[side] then diff.vs_applied = diff.vs_applied + 1 end
            end
            -- is_inside this trusted meta with tiny tolerance for being outside
            diff.is_inside = not (diff.mt < -margin or diff.mb < -margin or diff.ml < -margin or diff.mr < -margin)
            local pattern = diff.is_inside and
                                (diff.vs_current <= 1 or diff.vs_current == 2 and diff.vs_applied <= 2 or
                                    diff.vs_current > 2 and corrected.is_bigger)
            local set = closest.ref and
                            (diff.vs_current < closest.vs_current or diff.vs_current == closest.vs_current and
                                diff.vs_applied < closest.vs_applied or diff.vs_current == closest.vs_current and
                                diff.vs_applied == closest.vs_applied and diff.total < closest.total)
            -- mp.msg.info(string.format("\\ %-5s %-29s curr:%s appl:%s | %-3s %-3s %-3s %-3s %-4s | is_in:%s ",
            --     pattern and (not closest.ref or set), ref.whxy, diff.vs_current, diff.vs_applied, diff.mt, diff.mb,
            --     diff.ml, diff.mr, diff.total, diff.is_inside))
            if pattern and (not closest.ref or set) then closest = diff end
        end
        -- replace current with corrected
        if closest.ref then
            current = closest.ref
            corrected.ref = closest.ref
            s.buffer.indexed_list[s.buffer.i_total].new_ref = current
            print_debug("metadata", current, "\\ Corrected")
        else
            print_debug("pre_format", "\\ Uncorrected")
        end
    end

    -- stabilization of odd/unstable meta
    local stabilized
    if options.detect_round <= 4 and s.stats.trusted[current.whxy] then
        local margin = options.detect_round * 4
        local applied_in_margin = math.abs(current.w - s.approved.w) <= margin and math.abs(current.h - s.approved.h) <=
                                      margin
        for _, ref in pairs(s.stats.trusted) do
            local in_margin = math.abs(current.w - ref.w) <= margin and math.abs(current.h - ref.h) <= margin
            if in_margin then
                local gt_applied = applied_in_margin and ref ~= s.approved and ref.time.overall >
                                       s.approved.time.overall * 2
                local applied_gt = applied_in_margin and ref == s.approved and ref.time.overall * 2 >
                                       current.time.overall
                local pattern = not applied_in_margin and ref.time.overall > current.time.overall or gt_applied or
                                    applied_gt
                local set = stabilized and ref.time.overall > stabilized.time.overall
                -- mp.msg.info("\\", ref.whxy, ref.time.overall, current.time.overall, s.approved.time.overall)
                if ref ~= current and pattern and (not stabilized or set) then stabilized = ref end
            end
        end
        if stabilized then
            current = stabilized
            s.buffer.indexed_list[s.buffer.i_total].new_ref = current
            print_debug("metadata", current, "\\ Stabilized")
        end
    end

    -- cycle time.accumulated for fast_change_timer (reset if uncorrected)
    for whxy, ref in pairs(s.stats.trusted) do
        ref.time.accumulated = whxy ~= current.whxy and 0 or ref.time.accumulated < 0 and 0 + elapsed_time or
                                   not new_ready and ref.time.accumulated + elapsed_time or ref.time.accumulated
    end

    -- crop: final validation then store or apply it
    local detect_source = current == s.last_current and (current.is_source or collected.is_source) and s.limit.target >=
                              0
    local confirmation = not current.is_source and s.stats.trusted[current.whxy] and current.time.accumulated >=
                             options.fast_change_timer and (not corrected.ref or current == s.last_current)
    local crop_filter = s.approved ~= current and (confirmation or detect_source)
    if crop_filter and (not s.timestamps.prevent or timestamp >= s.timestamps.prevent) then
        s.approved = current -- reflect s.applied for read_head
        if s.limit.current < s.limit.min then
            s.limit.min = s.limit.current -- store minimum limit
        end
        if s.f_limit_runtime and options.read_ahead_mode > 0 then
            local pts = current.time.accumulated < options.ratio_timer and timestamp - current.time.accumulated or
                            current.pts[1]
            table.insert(s.indexed_read_ahead, {ref = current, pts = pts})
            s.timestamps.read_ahead = nil
        else
            apply_crop(current, timestamp)
        end
        if options.prevent_change_mode > 0 then
            s.timestamps.prevent = nil
            if (options.prevent_change_mode == 1 and (current.w > s.approved.w or current.h > s.approved.h) or
                options.prevent_change_mode == 2 and (current.w < s.approved.w or current.h < s.approved.h) or
                options.prevent_change_mode == 3) then
                s.timestamps.prevent = timestamp + options.prevent_change_timer
            end
        end
        if options.mode <= 2 then on_toggle(true) end
    end

    local function is_time_to_cleanup_buffer(time, target_time)
        return time > target_time * (1 + options.segmentation)
    end

    -- buffer: reduce size of known ratio stats
    while is_time_to_cleanup_buffer(s.buffer.t_ratio, options.ratio_timer) do
        local i = (s.buffer.i_total + 1) - s.buffer.i_ratio
        s.buffer.t_ratio = s.buffer.t_ratio - s.buffer.indexed_list[i].t_elapsed
        s.buffer.i_ratio = s.buffer.i_ratio - 1
    end

    -- buffer: check for candidate to extend it
    local buffer_timer = s.candidate.i_offset > 0 and options.offset_timer or s.candidate.i_fallback > 0 and
                             options.fallback_timer or options.ratio_timer

    -- buffer: cleanup fake candidate
    local function is_proactive_cleanup_needed()
        local test
        if is_time_to_cleanup_buffer(s.buffer.t_total, options.ratio_timer) then
            for _, cat in ipairs({"offset", "fallback"}) do
                if s.candidate["i_" .. cat] > 0 then
                    test = true
                    for whxy, ref in pairs(s.candidate[cat]) do
                        if ref.time.buffer > s.buffer.t_total * options.reverse_segmentation then
                            return false -- if at least one is a proper candidate
                        end
                    end
                end
            end
        end
        return test
    end

    -- buffer: reduce total size
    while is_time_to_cleanup_buffer(s.buffer.t_total, buffer_timer) or is_proactive_cleanup_needed() do
        s.buffer.i_to_shift = s.buffer.i_to_shift + 1
        local entry = s.buffer.indexed_list[s.buffer.i_to_shift]
        entry.ref.time.buffer = entry.ref.time.buffer - entry.t_elapsed
        if options.read_ahead_mode > 0 then table.remove(entry.ref.pts, 1) end
        if s.stats.buffer[entry.ref.whxy] and entry.ref.time.buffer == 0 then
            cleanup_stat(entry.ref.whxy, s.stats.buffer, s.stats, "buffer_unique")
            cleanup_stat(entry.ref.whxy, s.candidate.offset, s.candidate, "i_offset")
            cleanup_stat(entry.ref.whxy, s.candidate.fallback, s.candidate, "i_fallback")
        end
        s.buffer.t_total = s.buffer.t_total - entry.t_elapsed
    end

    -- buffer: shift the list to overwrite unused data
    if s.buffer.i_to_shift >= 20 or s.buffer.i_to_shift == s.buffer.i_total then
        for i = s.buffer.i_to_shift + 1, s.buffer.i_total do
            s.buffer.indexed_list[i - s.buffer.i_to_shift] = s.buffer.indexed_list[i]
        end
        for i = 0, s.buffer.i_to_shift - 1 do s.buffer.indexed_list[s.buffer.i_total - i] = nil end
        s.buffer.i_total = s.buffer.i_total - s.buffer.i_to_shift
        s.buffer.i_to_shift = 0
        collectgarbage("step")
    end

    -- limit: automatic adjustment
    s.last_limit = s.limit.current
    if s.f_limit_runtime or timestamp >= s.limit.timer then
        s.limit.last_target = s.limit.target
        if collected.is_source or current.is_source or corrected.is_bigger then
            -- increase limit
            s.limit.target = 1
            if s.limit.current + s.limit.step * s.limit.up <= options.detect_limit then
                s.limit.current = s.limit.current + s.limit.step * s.limit.up
            else
                s.limit.current = options.detect_limit
            end
        elseif not current.is_invalid and
            (collected.is_trusted_offsets or collected == s.last_collected or current == s.last_current) then
            -- stable limit
            s.limit.target = 0
            -- reset limit to help with different dark color
            if not current.is_trusted_offsets then s.limit.current = options.detect_limit end
        elseif s.limit.current > 0 then
            -- decrease limit
            s.limit.target = -1
            if s.limit.min < s.limit.current and s.limit.last_target == -1 then
                s.limit.current = s.limit.min
            elseif s.limit.current - s.limit.step >= 0 then
                s.limit.current = s.limit.current - s.limit.step
            else
                s.limit.current = 0
            end
        end
    end

    -- store for next process
    s.last_current = current
    s.last_collected = collected
    s.last_timestamp = timestamp

    -- limit: apply change
    if s.last_limit ~= s.limit.current then
        if not s.f_limit_runtime and options.limit_timer > 0 then s.limit.timer = timestamp + options.limit_timer end
        s.limit.counter = s.limit.counter + 1
        insert_cropdetect_filter(s.limit.current, true)
    end

    s.in_progress = false
end

local function time_pos(event, value, err)
    if value and s.indexed_read_ahead[1] then
        local time_pos = shifting_to(RIGHT, value)
        local deviation = math.abs(time_pos - s.pts)
        local crop_sync = s.frametime * (options.read_ahead_sync + options.crop_method_sync)
        local time_pos_read_ahead = time_pos - (options.read_ahead_timer - deviation - crop_sync)
        if time_pos_read_ahead >= s.indexed_read_ahead[1].pts then
            apply_crop(s.indexed_read_ahead[1].ref, s.indexed_read_ahead[1].pts)
            table.remove(s.indexed_read_ahead, 1)
        end
    end
end

local function collect_metadata(event)
    if event.prefix == "ffmpeg" and event.level == "v" and string.find(event.text, "^.*dyn_cd: ") and
        not (s.seeking or s.paused or s.toggled > 1) then
        local tmp = {}
        for k, v in string.gmatch(event.text, "(%w+):(%-?%d+%.?%d* )") do tmp[k] = tonumber(v) end
        tmp.whxy = string.format("w=%d:h=%d:x=%d:y=%d", tmp.w, tmp.h, tmp.x, tmp.y)
        s.pts = shifting_to(LEFT, tmp.pts)
        if tmp.whxy ~= s.collected.whxy then
            s.collected = s.stats.trusted[tmp.whxy] or s.stats.buffer[tmp.whxy] or compute_metadata(tmp)
        end

        s.limit.last_collect = s.limit.collect
        s.limit.collect = tmp.limit or s.limit.collect
        s.f_limit_runtime = tmp.limit ~= nil -- if ffmpeg is patch for limit change at runtime

        s.timestamps.previous = s.timestamps.current
        s.timestamps.current = s.pts

        local wait_limit = s.f_limit_runtime and s.f_limit_change and s.limit.collect == s.limit.last_collect
        if not wait_limit then s.f_limit_change = false end

        if s.in_progress or not s.timestamps.previous or wait_limit or s.f_inserted or s.timestamps.current <
            options.start_delay then
            s.f_inserted = false
            return
        end

        local elapsed_time = s.timestamps.current - s.timestamps.previous
        if not s.frametime or elapsed_time < s.frametime and elapsed_time > 0 then s.frametime = elapsed_time end

        process_metadata(s.collected, s.timestamps.current, elapsed_time)
    end
end

local function seek(event)
    if s.seek_done then return end
    print_debug("pre_format", string.format("Stop by %s event.", event))
    if event == "seek" or event == "toggle" then
        s.timestamps = {}
        s.limit.timer = 0
        s.approved = s.applied -- re-sync
        if event == "seek" then
            if s.f_limit_runtime then insert_cropdetect_filter(s.limit.current) end
            if not s.f_video_crop and
                (filter_state(labels.crop, "enabled", true) or not filter_state(labels.crop) and s.applied ~= s.source) then
                apply_crop(s.applied)
            end
        end
        if s.f_limit_runtime then
            s.indexed_read_ahead = {}
            s.collected = {}
        end
        s.seek_done = true -- avoid seek() in loop until we resume()
    end
end

local function resume(event)
    s.seek_done = false
    print_debug("pre_format", string.format("Resume by %s event.", event))
    if event == "toggle" and s.f_limit_runtime or not filter_state(labels.cropdetect) then
        insert_cropdetect_filter(s.limit.current)
    end
end

local function playback_events(t, id, error)
    if t.event == "seek" then
        s.seeking = true
        seek(t.event)
    else
        if not s.paused then resume(t.event) end
        s.seeking = false
    end
end

local ENABLE, DISABLE_WITH_CROP, DISABLE = 1, 2, 3
function on_toggle(auto)
    if s.f_missing then
        mp.osd_message("Libavfilter cropdetect missing", 3)
        return
    end
    local EVENT = "toggle"
    if s.toggled == ENABLE then
        s.toggled = DISABLE_WITH_CROP
        if filter_state(labels.cropdetect, "enabled", true) then
            mp.commandv("vf", EVENT, string.format("@%s", labels.cropdetect))
        end
        seek(EVENT)
        if not auto then mp.osd_message(string.format("%s: disabled, crop remains.", label_prefix), 3) end
    elseif s.toggled == DISABLE_WITH_CROP then
        s.toggled = DISABLE
        if filter_state(labels.cropdetect, "enabled", false) then
            if s.f_video_crop then
                mp.set_property("video-crop", "")
            elseif filter_state(labels.crop, "enabled", true) then
                mp.commandv("vf", EVENT, string.format("@%s", labels.crop))
            end
        end
        if not auto then mp.osd_message(string.format("%s: crop removed.", label_prefix), 3) end
    else -- s.toggled == DISABLE
        s.toggled = ENABLE
        if filter_state(labels.cropdetect, "enabled", false) then
            mp.commandv("vf", EVENT, string.format("@%s", labels.cropdetect))
        end
        if s.f_video_crop then
            apply_crop(s.applied)
        elseif filter_state(labels.crop, "enabled", false) then
            mp.commandv("vf", EVENT, string.format("@%s", labels.crop))
        end
        resume(EVENT)
        if not auto then mp.osd_message(string.format("%s: enabled.", label_prefix), 3) end
    end
end

local function pause(event, is_paused)
    s.paused = is_paused
    if is_paused then
        seek(event)
        print_stats()
        print_debug("buffer")
        print_debug("applied")
        print_debug("pre_format", "s.approved: " .. s.approved.whxy)
        print_debug("pre_format", "s.applied: " .. s.applied.whxy)
        if s.indexed_read_ahead[1] then
            print_debug("pre_format", "s.indexed_read_ahead[1]: " .. s.indexed_read_ahead[1].ref.whxy)
        end
    else
        if s.toggled == 1 then resume(event) end
    end
end

function cleanup()
    if not s.started then return end
    if not s.paused then print_stats() end
    mp.msg.info("Cleanup...")
    local prop_maximized = mp.get_property("window-maximized")
    if options.fix_windowed_behavior == 1 and prop_maximized == "no" then
        mp.set_property("auto-window-resize", s.user_auto_window_resize)
    end
    mp.unregister_event(playback_events)
    mp.unregister_event(collect_metadata)
    mp.unobserve_property(time_pos)
    mp.unobserve_property(switch_hwdec)
    mp.unobserve_property(pause)
    for _, label in pairs(labels) do
        if filter_state(label) then mp.commandv("vf", "remove", string.format("@%s", label)) end
    end
    if s.f_video_crop then mp.set_property("video-crop", "") end
    mp.msg.info("Done.")
    s.started = false
end

local function on_start()
    mp.msg.info("File loaded.")
    if not is_cropable() then
        mp.msg.warn("Exit, only works for videos.")
        return
    end
    s.user_auto_window_resize = mp.get_property("auto-window-resize")
    -- init/re-init stored data
    s.buffer = {i_to_shift = 0, i_total = 0, i_ratio = 0, indexed_list = {}, t_total = 0, t_ratio = 0}
    s.candidate = {i_fallback = 0, i_offset = 0, fallback = {}, offset = {}}
    s.collected = {}
    s.indexed_read_ahead = {}
    s.limit = {
        counter = 0, current = options.detect_limit, min = options.detect_limit, step = 2, target = 0, timer = 0, up = 2
    }
    s.stats = {applied = {}, buffer = {}, buffer_unique = 0, trusted = {}, trusted_offset = {}, trusted_unique = 1}
    s.stats.indexed_applied = {}
    s.source = {w_untouched = mp.get_property_number("width"), h_untouched = mp.get_property_number("height")}
    s.source.w = math.floor(s.source.w_untouched / options.detect_round) * options.detect_round
    s.source.h = math.floor(s.source.h_untouched / options.detect_round) * options.detect_round
    s.source.x = math.floor((s.source.w_untouched - s.source.w) / 2)
    s.source.y = math.floor((s.source.h_untouched - s.source.h) / 2)
    s.stats.trusted_offset = {x = {s.source.x}, y = {s.source.y}}
    s.ratios = {w = {}, h = {}}
    generate_ratios(options.ratios)
    s.source = compute_metadata(s.source)
    s.stats.trusted[s.source.whxy] = s.source
    s.source.applied = 1
    s.source.time.accumulated = 0
    s.applied = s.source
    s.approved = s.source
    s.timestamps = {}
    if options.read_ahead_mode > 0 then
        -- assume cropdetect is patch for command "limit", fallback at the first collected metadata otherwise.
        s.f_limit_runtime = true
        -- quick test for dummysync filter
        s.f_sync = mp.commandv("vf", "add", string.format("@%s:lavfi=[split[a][b];[a][b]dummysync]", label_prefix)) and
                       mp.commandv("vf", "remove", string.format("@%s", label_prefix)) and "[a][b]dummysync" or
                       "[a][b]psnr=eof_action=pass"
    end
    s.f_video_crop = options.crop_method == 1 and mp.get_property("video-crop") ~= nil -- true if supported
    -- register events
    mp.register_event("seek", playback_events)
    mp.register_event("playback-restart", playback_events)
    mp.observe_property("time-pos", "number", time_pos)
    mp.observe_property("hwdec", "string", switch_hwdec)
    mp.observe_property("pause", "bool", pause)
    mp.enable_messages('v')
    mp.register_event("log-message", collect_metadata)
    s.toggled = (options.mode % 2 == 1) and DISABLE or ENABLE
    s.started = true -- everything ready
end

mp.add_key_binding("C", "toggle_crop", on_toggle)
mp.register_event("end-file", cleanup)
mp.register_event("file-loaded", on_start)
