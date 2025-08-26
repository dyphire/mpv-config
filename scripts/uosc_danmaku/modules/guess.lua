-- Clean up media name
local function clean_name(name)
    return name:gsub("^%[.-%]", " ")
           :gsub("^%(.-%)", " ")
           :gsub("[_%.%[%]]", " ")
           :gsub("第%s*%d+%s*季", "")
           :gsub("第%s*%d+%s*部", "")
           :gsub("第[一二三四五六七八九十]+季", "")
           :gsub("第[一二三四五六七八九十]+部", "")
           :gsub("^%s*(.-)%s*$", "%1")
           :gsub("[!@#%.%?%+%-%%&*_=,/~`]+$", "")
end

-- Formatters for media titles
local formatters = {
    {
        regex = "^(.-)%s*[_%-%.%s]%s*第%s*(%d+)%s*[季部]+%s*[_%-%.%s]%s*第%s*(%d+[%.v]?%d*)%s*[话集回]",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. season .. "E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[_%-%.%s]%s*第([一二三四五六七八九十]+)[季部]+%s*[_%-%.%s]%s*第%s*(%d+[%.v]?%d*)%s*[话集回]",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. chinese_to_number(season) .. "E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[_%-%.%s]%s*第%s*(%d+)%s*[季部]+%s*[_%-%.%s]%s*[^%ddD][eEpP]+(%d+[%.v]?%d*)",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. season .. "E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[_%-%.%s]%s*第([一二三四五六七八九十]+)[季部]+%s*[_%-%.%s]%s*[^%ddD][eEpP]+(%d+[%.v]?%d*)",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. chinese_to_number(season) .. "E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d%d%d%d)[_%.%s]%d%d[_%.%s]%d%d%s*[_%.%s]?(.-)%s*[_%.%s]%d+[pPkKxXbBfF]",
        format = function(name, year, subtitle)
            local title = clean_name(name)
            if subtitle then
                title = title .. ": " .. subtitle:gsub("%.", " "):gsub("^%s*(.-)%s*$", "%1")
            end
            return title .. " (" .. year .. ")"
        end
    },
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d%d%d%d)%s*[_%.%s]%s*[sS](%d+)[%.%-%s:]?[eE](%d+%.?%d*)",
        format = function(name, year, season, episode)
            return clean_name(name) .. " (" .. year .. ") S" .. season .. "E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d%d%d%d)%s*[_%.%s]%s*[^%ddD][eEpP]+(%d+%.?%d*)",
        format = function(name, year, episode)
            return clean_name(name) .. " (" .. year .. ") E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[_%-%.%s]%s*[sS](%d+)[%.%-%s:]?[eE](%d+[%.v]?%d*)%s*[_%.%s]%s*(%d%d%d%d)[^%dhHxXvVpPkKxXbBfF]",
        format = function(name, season, episode, year)
            return clean_name(name) .. " (" .. year .. ") S" .. season .. "E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[_%-%.%s]%s*[sS](%d+)[%.%-%s:]?[eE](%d+%.?%d*)",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. season .. "E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d+)[nrdsth]+[_%.%s]%s*[sS]eason[_%.%s]%s*%[(%d+[%.v]?%d*)%]",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. season .. "E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[^%ddD][eEpP]+(%d+[%.v]?%d*)[_%.%s]%s*(%d%d%d%d)[^%dhHxXvVpPkKxXbBfF]",
        format = function(name, episode, year)
            return clean_name(name) .. " (" .. year .. ") E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[^%ddD][eEpP]+(%d+%.?%d*)",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode
        end
    },
    {
        regex = "^(.-)%s*第%s*(%d+[%.v]?%d*)%s*[话集回]",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*%[(%d+[%.v]?%d*)%]",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*%[(%d+[%.v]?%d*)%(%a+%)%]",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode:gsub("v%d+$","")
        end
    },
    {
        regex = "^(.-)%s*[%-#]%s*(%d+%.?%d*)%s*",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[%[%(]([OVADSPs]+)[%]%)]",
        format = function(name, sp)
            return clean_name(name) .. " [" .. sp .. "]"
        end
    },
    {
        regex = "^(.-)%s*[_%-%.%s]%s*(%d?%d)x(%d%d?%d?%d?)[^%dhHxXvVpPkKxXbBfF]",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. season .. "E" .. episode
        end
    },
    {
        regex = "^%((%d%d%d%d)%.?%d?%d?%.?%d?%d?%)%s*(.-)%s*[%(%[]",
        format = function(year, name)
            return clean_name(name) .. " (" .. year .. ")"
        end
    },
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d%d%d%d)[^%dhHxXvVpPkKxXbBfF]",
        format = function(name, year)
            return clean_name(name) .. " (" .. year .. ")"
        end
    },
    {
        regex = "^%[.-%]%s*%[?(.-)%]?%s*[%(%[]",
        format = function(name)
            return clean_name(name)
        end
    },
}

-- Format filename based on regex patterns
function format_filename(title)
    for _, formatter in ipairs(formatters) do
        local matches = {title:match(formatter.regex)}
        if #matches > 0 then
            title = formatter.format(unpack(matches))
            return title
        end
    end
end
