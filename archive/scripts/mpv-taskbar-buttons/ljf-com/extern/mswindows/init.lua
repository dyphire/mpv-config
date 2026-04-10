
-- /!\ This is a DELIBERATELY MINIMAL, INCOMPLETE binding! /!\
-- do not take it too seriously, it is only here to support the com library

local ffi = require 'ffi'

local mswindows = {}

-- miscellaneous things
ffi.cdef [[
  typedef int bool32;
  typedef struct RECT { int32_t left, top, right, bottom; } RECT;
]]

-- GUIDs
ffi.cdef [[
  typedef struct GUID { uint32_t Data1; uint16_t Data2, Data3; uint8_t Data4[8]; } GUID;
]]
local GUID = ffi.metatype('GUID', {
  __tostring = function(guid)
    if pcall(ffi.cast, ffi.typeof(guid), nil) and (guid == nil) then
      return '<NULL GUID>'
    end
    return string.format('%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x',
      guid.Data1,
      guid.Data2, guid.Data3,
      guid.Data4[0], guid.Data4[1], guid.Data4[2], guid.Data4[3],
      guid.Data4[4], guid.Data4[5], guid.Data4[6], guid.Data4[7])
  end
})
function mswindows.guid(v)
  local a, b, c, d1, d2, d3, d4, d5, d6, d7, d8 = string.match(v,
    '^{?(%x%x%x%x%x%x%x%x)%-?(%x%x%x%x)%-?(%x%x%x%x)%-?(%x%x)(%x%x)%-?(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)}?$')
  if not a then
    error('invalid guid string')
  end
  return GUID(tonumber(a, 16), tonumber(b, 16), tonumber(c, 16),
    {tonumber(d1, 16), tonumber(d2, 16), tonumber(d3, 16), tonumber(d4, 16),
    tonumber(d5, 16), tonumber(d6, 16), tonumber(d7, 16), tonumber(d8, 16)})
end

mswindows.ole32 = ffi.load 'ole32'

local module_meta = {
  __index = function(self, key)
    return ffi.C[key]
  end;
}

setmetatable(mswindows, module_meta)

return mswindows
