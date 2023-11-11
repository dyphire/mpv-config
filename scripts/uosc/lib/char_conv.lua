require('lib/text')

local char_dir = mp.get_script_directory() .. '/char-conv/'
local data = {}

local languages = get_languages()
for i = #languages, 1, -1 do
    lang = languages[i]
    if (lang == 'en') then
        data = {}
    else
        table_assign(data, get_locale_from_json(char_dir .. lang:lower() .. '.json'))
    end
end

local pyTable = {}

function getPyTable()
    for k, v in pairs(data) do
        for _, char in utf8_iter(v) do
            pyTable[char] = k
        end
    end
end
getPyTable()

function getStringLength(str)
    if not str or type(str) ~= "string" or #str <= 0 then
        return nil
    end
    local length = 0
    local i = 1
    while true do
        local curByte = string.byte(str, i)
        local byteCount = 1
        if curByte > 239 then
            byteCount = 4
        elseif curByte > 223 then
            byteCount = 3
        elseif curByte > 128 then
            byteCount = 2
        else
            byteCount = 1
        end
        i = i + byteCount
        length = length + 1
        if i > #str then
            break
        end
    end
    return length
end

function char_conv(chars, ligature, separator)
    if next(pyTable) == nil then
        return chars
    end

    local separator = separator or ' '
    local char_conv, sp, cache = {}, {}, {}
    local chars_length = getStringLength(chars)
    for n, char in utf8_iter(chars) do
        if ligature then
            if string.len(char) == 1 then
                char_conv[#char_conv + 1] = char
            else
                char_conv[#char_conv + 1] = pyTable[char] or char
            end
        else
            if string.len(char) <= 2 then
                if (char ~= ' ' and n ~= chars_length) then
                    cache[#cache + 1] = pyTable[char] or char
                elseif (char == ' ' or n == chars_length) then
                    sp[#sp + 1] = table.concat(cache)
                    cache = {}
                end
            else
                if next(cache) ~= nil then
                    sp[#sp + 1] = table.concat(cache)
                    cache = {}
                end
                sp[#sp + 1] = pyTable[char] or char
            end
        end
    end
    if ligature then
        return table.concat(char_conv)
    else
        return table.concat(sp, separator)
    end
end

return char_conv
