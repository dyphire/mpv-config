-- Clean up media name
local function clean_name(name)
    return name:gsub("^%[.-%]", " ")
           :gsub("^%(.-%)", " ")
           :gsub("[_%.%[%]]", " ")
           :gsub("^%s*(.-)%s*$", "%1")
           :gsub("[@#%.%+%-%%&*_=,/~`]+$", "")
end

-- Formatters for media titles
local formatters = {
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
        regex = "^(.-)%s*[_%.%s]%s*(%d%d%d%d)%s*[_%.%s]%s*[sS](%d+)[%.%-%s:]?[eE](%d+)",
        format = function(name, year, season, episode)
            return clean_name(name) .. " (" .. year .. ") S" .. season .. "E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d%d%d%d)%s*[_%.%s]%s*[eEpP]+(%d+)",
        format = function(name, year, episode)
            return clean_name(name) .. " (" .. year .. ") E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[_%-%.%s]%s*[sS](%d+)[%.%-%s:]?[eE](%d+)%s*[_%.%s]%s*(%d%d%d%d)[^%dhHxXvVpPkKxXbBfF]",
        format = function(name, season, episode, year)
            return clean_name(name) .. " (" .. year .. ") S" .. season .. "E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[_%-%.%s]%s*[sS](%d+)[%.%-%s:]?[eE](%d+)",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. season .. "E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[_%.%s]%s*(%d+)[nrdsth]+[_%.%s]%s*[sS]eason[_%.%s]%s*%[(%d+[%.v]?%d*)%]",
        format = function(name, season, episode)
            return clean_name(name) .. " S" .. season .. "E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[eEpP]+(%d+)[_%.%s]%s*(%d%d%d%d)[^%dhHxXvVpPkKxXbBfF]",
        format = function(name, episode, year)
            return clean_name(name) .. " (" .. year .. ") E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[eEpP]+(%d+)",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode
        end
    },
    {
        regex = "^(.-)%s*%[(%d+[%.v]?%d*)%]",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode
        end
    },
    {
        regex = "^(.-)%s*%[(%d+[%.v]?%d*%(%a+%))%]",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[%-#]%s*(%d+)%s*",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode
        end
    },
    {
        regex = "^(.-)%s*%[(%d+)%]%D+",
        format = function(name, episode)
            return clean_name(name) .. " E" .. episode
        end
    },
    {
        regex = "^(.-)%s*[%[%(]([OVADSPs]+)[%]%)]",
        format = function(name, SP)
            return clean_name(name) .. " [" .. SP .. "]"
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
            title = formatter.format(table.unpack(matches))
            return title
        end
    end
    title = title:gsub("^%[.-%]", " ")
        :gsub("^%(.-%)", " ")
        :gsub("[_%.]", " ")
        :gsub("^%s*(.-)%s*$", "%1")
        :gsub("[@#%.%+%-%%&*_=,/~`]+$", "")
    return title
end
