local utils = require("mp.utils")
local options = require("mp.options")

local o = {
    path = "~~/recent.json",
    title = 'Recently played',
    length = 10,
    width = 88,
    ignore_same_series = true,
}
options.read_options(o)

local path = mp.command_native({ "expand-path", o.path })

local menu = {
    type = 'recent_menu',
    title = o.title,
    items = {},
}

local dyn_menu = {
    type = 'submenu',
    submenu = {}
}

local current_item = { nil, nil, nil }

function utf8_char_bytes(str, i)
    local char_byte = str:byte(i)
    if char_byte < 0xC0 then
        return 1
    elseif char_byte < 0xE0 then
        return 2
    elseif char_byte < 0xF0 then
        return 3
    elseif char_byte < 0xF8 then
        return 4
    else
        return 1
    end
end

function utf8_iter(str)
    local byte_start = 1
    return function()
        local start = byte_start
        if #str < start then return nil end
        local byte_count = utf8_char_bytes(str, start)
        byte_start = start + byte_count
        return start, str:sub(start, start + byte_count - 1)
    end
end

function utf8_to_table(str)
    local t = {}
    for _, ch in utf8_iter(str) do
        t[#t + 1] = ch
    end
    return t
end

function utf8_subwidth(str, indexStart, indexEnd)
    if indexStart > indexEnd then
        return str
    end

    local index = 1
    local substr = ""
    for _, char in utf8_iter(str) do
        if indexStart <= index and index <= indexEnd then
            local width = #char > 2 and 2 or 1
            index = index + width
            substr = substr .. char
        end
    end
    return substr, index
end

function jaro(s1, s2)
    local match_window = math.floor(math.max(#s1, #s2) / 2.0) - 1
    local matches1 = {}
    local matches2 = {}

    local m = 0;
    local t = 0;

    for i = 0, #s1, 1 do
        local start = math.max(0, i - match_window)
        local final = math.min(i + match_window + 1, #s2)

        for k = start, final, 1 do
            if matches2[k] then
                goto continue
            end

            if s1[i] ~= s2[k] then
                goto continue
            end

            matches1[i] = true
            matches2[k] = true
            m = m + 1
            break

            ::continue::
        end
    end

    if m == 0 then
        return 0.0
    end

    local k = 0
    for i = 0, #s1, 1 do
        if (not matches1[i]) then
            goto continue
        end

        while not matches2[k] do
            k = k + 1
        end

        if s1[i] ~= s2[k] then
            t = t + 1
        end

        k = k + 1

        ::continue::
    end

    t = t / 2.0

    return (m / #s1 + m / #s2 + (m - t) / m) / 3.0
end

function jaro_winkler_distance(s1, s2)
    if #s1 + #s2 == 0 then
        return 0.0
    end

    if s1 == s2 then
        return 1.0
    end

    s1 = utf8_to_table(s1)
    s2 = utf8_to_table(s2)

    local d = jaro(s1, s2)
    local p = 0.1
    local l = 0;
    while (s1[l] == s2[l] and l < 4) do
        l = l + 1
    end

    return d + l * p * (1 - d)
end

function split_path(path)
    -- return path, filename, extension
    return path:match("(.-)([^\\/]-)%.?([^%.\\/]*)$")
end

function is_protocol(path)
    return type(path) == 'string' and (path:find('^%a[%w.+-]-://') ~= nil or path:find('^%a[%w.+-]-:%?') ~= nil)
end

function is_same_series(path1, path2)
    if not o.ignore_same_series then
        return false
    end

    local dir1, filename1, extension1 = split_path(path1)
    local dir2, filename2, extension2 = split_path(path2)

    -- in same folder
    if dir1 == dir2 then
        -- same filename but different extensions
        if filename1 == filename2 then
            return false
        end

        -- by episode
        local episode1 = filename1:gsub("^[%[%(]+.-[%]%)]+[%s%[]*", ""):match("(.-%D+)0*%d+")
        local episode2 = filename2:gsub("^[%[%(]+.-[%]%)]+[%s%[]*", ""):match("(.-%D+)0*%d+")
        if episode1 and episode2 and episode1 == episode2 then
            return true
        end

        -- by similarity
        local threshold = 0.8
        local similarity = jaro_winkler_distance(filename1, filename2)
        if similarity > threshold then
            return true
        end
    end

    return false
end

function get_dyn_menu_title(title, hint, path)
    if is_protocol(path) then
        local protocol = path:match("^(%a[%w.+-]-)://")
        hint = protocol
    else
        local dir, filename, extension = split_path(path)
        title = filename
        hint = extension
    end
    local title_clip = utf8_subwidth(title, 1, o.width)
    if title ~= title_clip then
        title = utf8_subwidth(title_clip, 1, o.width - 2) .. "..."
    end
    return string.format('%s\t%s', title, hint:upper())
end

function remove_deleted()
    local new_items = {}
    for _, item in ipairs(menu.items) do
        local path = item.value[2]
        local deleted = false

        if not is_protocol(path) then
            local meta, meta_error = utils.file_info(path)
            if not (meta and meta.is_file) then
                deleted = true
            end
        end

        if not deleted then
            new_items[#new_items + 1] = item
        end
    end

    if #menu.items ~= #new_items then
        menu.items = new_items
        write_json()
    end
end

function read_json()
    local meta, meta_error = utils.file_info(path)
    if not meta or not meta.is_file then
        menu.items = {}
        return
    end

    local json_file = io.open(path, "r")
    if not json_file then
        menu.items = {}
        return
    end

    local json = json_file:read("*all")
    json_file:close()

    menu.items = utils.parse_json(json) or {}
    remove_deleted()
end

function write_json()
    local json_file = io.open(path, "w")
    if not json_file then return end

    local json = utils.format_json(menu.items)

    json_file:write(json)
    json_file:close()
    update_dyn_menu_items()
end

function append_item(path, filename, title)
    if title and title ~= "" then
        local width
        filename, width = utf8_subwidth(filename, 1, o.width * 0.618)
        title = utf8_subwidth(title, 1, o.width - width)
    else
        filename = utf8_subwidth(filename, 1, o.width)
    end

    local new_items = { { title = filename, hint = title, value = { "loadfile", path } } }
    read_json()
    for index, value in ipairs(menu.items) do
        local ofilename = value.title
        local opath = value.value[2]
        if #new_items < o.length and
            opath ~= path and
            not is_same_series(path, opath)
        then
            new_items[#new_items + 1] = value
        end
    end
    menu.items = new_items
    write_json()
end

function open_menu()
    read_json()
    local json = utils.format_json(menu)
    mp.commandv('script-message-to', 'uosc', 'open-menu', json)
end

function update_dyn_menu_items()
    if #menu.items == 0 then
        read_json()
    end
    local submenu = {}
    local menu_items = menu.items
    for _, item in ipairs(menu_items) do
        submenu[#submenu + 1] = {
            title = get_dyn_menu_title(item.title, item.hint, item.value[2]),
            cmd = string.format("%s '%s'", item.value[1], item.value[2]),
        }
    end
    dyn_menu.submenu = submenu
    mp.commandv('script-message-to', 'dyn_menu', 'update', 'recent', utils.format_json(dyn_menu))
end

function play_last()
    read_json()
    if menu.items[1] then
        mp.command_native(menu.items[1].value)
    end
end

function on_load()
    local path = mp.get_property("path")
    if not path then return end
    local filename = mp.get_property("filename")
    local dir, filename_without_ext, ext = split_path(filename)
    local title = mp.get_property("media-title") or path
    if filename == title or filename_without_ext == title then
        title = ""
    end
    if is_protocol(path) and title and title ~= "" then
        filename, title = title, filename
    end
    current_item = { path, filename, title }
    append_item(path, filename, title)
end

function on_end(e)
    if e and e.reason and e.reason == "quit" then
        append_item(current_item[1], current_item[2], current_item[3])
    end
end

mp.add_key_binding(nil, "open", open_menu)
mp.add_key_binding(nil, "last", play_last)
mp.register_event("file-loaded", on_load)
mp.register_event("end-file", on_end)

mp.register_script_message('menu-ready', update_dyn_menu_items)
