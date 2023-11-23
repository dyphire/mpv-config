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

function need_romanization()
	if next(pyTable) ~= nil then
		return true
	end
	return false
end

function utf8_length(str)
	local length = 0
	for _, c in utf8_iter(str) do
		length = length + 1
	end
	return length
end

function char_conv(chars, ligature, separator)
	local separator = separator or ' '
	local length = 0
	local char_conv, sp, cache = {}, {}, {}
	local chars_length = utf8_length(chars)
	local concat = table.concat
	for _, char in utf8_iter(chars) do
		if ligature then
			if #char == 1 then
				char_conv[#char_conv + 1] = char
			else
				char_conv[#char_conv + 1] = pyTable[char] or char
			end
		else
			length = length + 1
			if #char <= 2 then
				if (char ~= ' ' and length ~= chars_length) then
					cache[#cache + 1] = pyTable[char] or char
				elseif (char == ' ' or length == chars_length) then
					if length == chars_length then
						cache[#cache + 1] = pyTable[char] or char
					end
					sp[#sp + 1] = concat(cache)
					itable_clear(cache)
				end
			else
				if next(cache) ~= nil then
					sp[#sp + 1] = concat(cache)
					itable_clear(cache)
				end
				sp[#sp + 1] = pyTable[char] or char
			end
		end
	end
	if ligature then
		return concat(char_conv)
	else
		return concat(sp, separator)
	end
end

return char_conv
