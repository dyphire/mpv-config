local fb = require "file-browser"
local fb_utils = require 'modules.utils'

local PLATFORM = fb.get_platform()

-- this code is based on https://github.com/mpvnet-player/mpv.net/issues/575#issuecomment-1817413401
local ffi = require "ffi"
local winapi = {
        ffi = ffi,
        C = ffi.C,
        CP_UTF8 = 65001,
        shlwapi = ffi.load("shlwapi"),
    }

-- ffi code from https://github.com/po5/thumbfast, Mozilla Public License Version 2.0
ffi.cdef[[
    int __stdcall MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags, const char *lpMultiByteStr,
    int cbMultiByte, wchar_t *lpWideCharStr, int cchWideChar);
    int __stdcall StrCmpLogicalW(wchar_t *psz1, wchar_t *psz2);
]]

winapi.utf8_to_wide = function(utf8_str)
    if utf8_str then
        local utf16_len = winapi.C.MultiByteToWideChar(winapi.CP_UTF8, 0, utf8_str, -1, nil, 0)

        if utf16_len > 0 then
            local utf16_str = winapi.ffi.new("wchar_t[?]", utf16_len)

            if winapi.C.MultiByteToWideChar(winapi.CP_UTF8, 0, utf8_str, -1, utf16_str, utf16_len) > 0 then
                return utf16_str
            end
        end
    end

    return ""
end

if PLATFORM == 'windows' then
    fb_utils.sort = function (t)
        table.sort(t, function(a, b)
            local a_wide = winapi.utf8_to_wide(a.type:sub(1, 1) .. (a.label or a.name))
            local b_wide = winapi.utf8_to_wide(b.type:sub(1, 1) .. (b.label or b.name))
            return winapi.shlwapi.StrCmpLogicalW(a_wide, b_wide) == -1
        end)
    
        return t
    end
end

return { api_version = '1.2.0' }