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

function utf8_subwidth(str, indexStart, indexEnd)
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

function is_protocol(path)
    return type(path) == 'string' and (path:find('^%a[%w.+-]-://') ~= nil or path:find('^%a[%w.+-]-:%?') ~= nil)
end

function is_same_folder(s1, s2, p1, p2)
    local i1 = p1:find(s1, 1, true)
    local i2 = p2:find(s2, 1, true)
    if i1 and i2 then
        local t1 = p1:sub(1, i1 - 1)
        local t2 = p2:sub(1, i2 - 1)
        return t1 == t2, p1:sub(i1, #p1), p2:sub(i2, #p2)
    end
    return false
end

function is_same_series(s1, s2, p1, p2)
    if not o.ignore_same_series then
        return false
    end

    local _is_same_folder, f1, f2 = is_same_folder(s1, s2, p1, p2)
    if _is_same_folder and
        f1 and
        f2 and
        get_filename_without_ext(f1) ~= get_filename_without_ext(f2)
    then
        local ratio = 0.5
        local limit = #f1 * ratio
        local temp = ""
        for start, char in utf8_iter(f1) do
            local sub1 = char
            local sub2 = f2:sub(start, start + #char - 1)
            if sub1 ~= sub2 then
                temp = temp .. sub1
            end
        end
        if limit > #temp then
            return true
        end
        local sub1, sub2 = f1:match("(.+%D+)0*%d+"), f2:match("(.+%D+)0*%d+")
        if sub1 and sub2 and sub1 == sub2 then
            return true
        end
    end
    return false
end

function get_filename_without_ext(filename)
    local idx = filename:match(".+()%.%w+$")
    if idx then
        filename = filename:sub(1, idx - 1)
    end
    return filename
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
            not is_same_series(filename, ofilename, path, opath)
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

function play_last()
    read_json()
    if menu.items[1] then
        mp.command_native(menu.items[1].value)
    end
end

function on_load()
    local path = mp.get_property("path")
    if not path then return end
    if not is_protocol(path) then path = path:gsub("/", "\\") end
    local filename = mp.get_property("filename")
    local filename_without_ext = get_filename_without_ext(filename)
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
