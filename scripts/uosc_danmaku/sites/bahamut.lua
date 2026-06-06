local msg = require('mp.msg')
local utils = require("mp.utils")

local function resolve_bahamut_sn(input_string)
    local start_index = 0
    local end_index = 0
    local count = 0
    for i = 1, #input_string do
        if input_string:sub(i, i) == ":" then
            count = count + 1
            if count == 2 then
                start_index = i
            elseif count == 3 then
                end_index = i
                break
            end
        end
    end
    if start_index > 0 and end_index > 0 then
        return input_string:sub(start_index + 1, end_index - 1)
    else
        return nil
    end
end

local function get_type_from_position(position)
    if position == 0 then
        return 1
    end
    if position == 1 then
        return 4
    end
    return 5
end

-- 为 bahamut 网站的视频播放加载弹幕
function load_danmaku_for_bahamut(path, callback)
    callback = callback or function() end
    local path = path:gsub('%%(%x%x)', hex_to_char)
    local sn = resolve_bahamut_sn(path)
    if sn == nil then
        callback(false)
        return
    end
    local url = "https://ani.gamer.com.tw/ajax/danmuGet.php"
    local temp_file = "bahamut-" .. PID .. ".json"
    local danmaku_json = utils.join_path(DANMAKU_PATH, temp_file)
    local arg = {
        "curl",
        "-X",
        "POST",
        "-d",
        "sn=" .. sn,
        "-L",
        "-s",
        "--user-agent",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.83 Safari/537.36",
        "--header",
        "Origin: https://ani.gamer.com.tw",
        "--header",
        "Content-Type: application/x-www-form-urlencoded;charset=utf-8",
        "--header",
        "Accept: application/json",
        "--header",
        "Authority: ani.gamer.com.tw",
        "--output",
        danmaku_json,
        url,
    }

    if options.proxy ~= "" then
        table.insert(arg, '-x')
        table.insert(arg, options.proxy)
    end

    if options.cookie_file and options.cookie_file ~= "" then
        table.insert(arg, '-b')
        table.insert(arg, mp.command_native({"expand-path", options.cookie_file}))
    end

    call_cmd_async(arg, function(error)
        if error then
            show_message("HTTP 请求失败，打开控制台查看详情", 5)
            msg.error(error)
            callback(false)
            return
        end
        if not file_exists(danmaku_json) then
            callback(false)
            return
        end

        local comments_json = read_file(danmaku_json)
        os.remove(danmaku_json)
        local comments = utils.parse_json(comments_json)
        if not comments then
            callback(false)
            return
        end

        local output_table = {}
        for _, comment in ipairs(comments) do
            local color = hex_to_int_color(comment["color"])
            local mode = get_type_from_position(comment["position"])
            local time = tonumber(comment["time"]) / 10
            local c_param = string.format("%s,%s,%s,25,,,", time, color, mode)
            table.insert(output_table, {
                c = c_param,
                m = comment["text"]
            })
        end

        local final_json_str = utils.format_json(output_table)
        save_danmaku_json("https://ani.gamer.com.tw/animeVideo.php?sn=" .. sn, final_json_str)
        load_danmaku(true)
        callback(true)
    end)
end
