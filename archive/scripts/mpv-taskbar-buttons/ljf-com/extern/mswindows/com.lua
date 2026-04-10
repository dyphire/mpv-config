
local ffi = require 'ffi'
local mswin = require 'extern.mswindows'

local com = {}

local instance_meta = {
  __index = function(self, key)
    return self.lpVtbl[key]
  end;
}

local interfaces = {}

local function add_methods(buf, object_name, object_def, getters, setters)
  if not object_def.root then
    add_methods(buf, object_name,
      interfaces[object_def.inherits or 'IUnknown'],
      getters, setters)
  end
  for i, method_def in ipairs(object_def.methods) do
    local name = method_def[1]
    local get = name:match('^get_(.+)$')
    if get then
      getters[get] = function(self)
        return self.lpVtbl[name](self)
      end
    end
    local put = name:match('^put_(.+)$')
    if put then
      setters[put] = function(self, value)
        self.lpVtbl[name](self, value)
      end
    end
    buf[#buf+1] = (method_def.ret or 'int32_t')
      .. ' (__stdcall *' .. method_def[1] .. ')(' .. object_name .. '* self'
    if method_def[2] then
      buf[#buf+1] = ', ' .. method_def[2] .. ');\n'
    else
      buf[#buf+1] = ');\n'
    end
  end
end

function com.predef(...)
  for i = 1, select('#', ...) do
    local name = select(i, ...)
    if not pcall(ffi.typeof, name) then
      ffi.cdef(string.format('typedef struct %s %s;', name, name))
    end
  end
end

function com.def(objects_def)
  for i, object_def in ipairs(objects_def) do
    object_def.methods = object_def.methods or {}
    local object_name = object_def[1]
    local stored_version = {name = object_name, iid = mswin.guid(object_def.iid)}
    if object_def.root then
      if object_def.inherits then
        error('root interface cannot inherit')
      end
      stored_version.root = true
    elseif object_def.inherits then
      stored_version.inherits = object_def.inherits
    end
    stored_version.methods = object_def.methods
    interfaces[object_name] = stored_version
    com.predef(object_name)
  end
  for i, object_def in ipairs(objects_def) do
    local object_name = object_def[1]
    local object_fields = object_def.fields or ''
    local buf = {}
    local getters, setters = {}, {}
    add_methods(buf, object_name, object_def, getters, setters)
    local object_methods = table.concat(buf)
    local struct_cdef = string.format('typedef struct %s {\n  struct {\n%s\n  } *lpVtbl;\n%s\n} %s;', object_name, object_methods, object_fields, object_name)
    ffi.cdef(struct_cdef)
    local stored = interfaces[object_name]
    local main_getter
    local meta = instance_meta
    if main_getter or next(getters) or next(setters) then
      meta = {
        __index = function(self, key)
          local getter = getters[key]
          if getter then
            return getter(self)
          end
          return self.lpVtbl[key]
        end;
        __newindex = function(self, key, value)
          local setter = setters[key]
          if setter then
            return setter(self, value)
          end
          if getters[key] then
            error('attempt to set read-only property')
          end
          error('attempt to set undefined property')
        end;
      }
    end
    ffi.metatype(object_name, meta)
  end
end

function com.iidof(interfaceName)
  local interface = interfaces[interfaceName]
  if not interface then
    error('COM interface not defined: ' .. tostring(interfaceName), 2)
  end
  return interface.iid
end

com.def {
  {'IUnknown', root = true;
    methods = {
      {'QueryInterface', 'GUID* guid, void** out_interface'};
      {'AddRef', ret='uint32_t'};
      {'Release', ret='uint32_t'};
    };
    iid = '00000000-0000-0000-C000000000000046';
  };
}

ffi.cdef [[

  typedef enum {
    CLSCTX_INPROC_SERVER          = 0x1,
    CLSCTX_INPROC_HANDLER         = 0x2,
    CLSCTX_LOCAL_SERVER           = 0x4,
    CLSCTX_INPROC_SERVER16        = 0x8,
    CLSCTX_REMOTE_SERVER          = 0x10,
    CLSCTX_INPROC_HANDLER16       = 0x20,
    CLSCTX_RESERVED1              = 0x40,
    CLSCTX_RESERVED2              = 0x80,
    CLSCTX_RESERVED3              = 0x100,
    CLSCTX_RESERVED4              = 0x200,
    CLSCTX_NO_CODE_DOWNLOAD       = 0x400,
    CLSCTX_RESERVED5              = 0x800,
    CLSCTX_NO_CUSTOM_MARSHAL      = 0x1000,
    CLSCTX_ENABLE_CODE_DOWNLOAD   = 0x2000,
    CLSCTX_NO_FAILURE_LOG         = 0x4000,
    CLSCTX_DISABLE_AAA            = 0x8000,
    CLSCTX_ENABLE_AAA             = 0x10000,
    CLSCTX_FROM_DEFAULT_CONTEXT   = 0x20000,
    CLSCTX_ACTIVATE_32_BIT_SERVER = 0x40000,
    CLSCTX_ACTIVATE_64_BIT_SERVER = 0x80000,
    CLSCTX_ENABLE_CLOAKING        = 0x100000,
    CLSCTX_PS_DLL                 = 0x80000000 
  } CLSCTX;
  
  int32_t CoCreateInstance(GUID* clsid, IUnknown* outer, CLSCTX context, GUID* iid, void** out_obj);
  int32_t CoInitializeEx(void* pvReserved, unsigned long dwCoInit);
  
]]

mswin.ole32.CoInitializeEx(nil, 0) -- COINIT_MULTITHREADED

local function com_gc(v)
  return v.lpVtbl.Release(v)
end

function com.gc(v)
  if (v == nil) then
    return nil
  end
  return ffi.gc(v, com_gc)
end

function com.release(v)
  ffi.gc(v, nil).lpVtbl.Release(v)
end

function com.cast(newtype, value)
  local temp = ffi.new(newtype .. '*[1]')
  if (value:QueryInterface(com.iidof(newtype), ffi.cast('void**', temp)) == 0) then
    return ffi.gc(temp[0], com_gc)
  else
    return nil
  end
end

function com.new(clsid, name)
  local temp = ffi.new(name .. '*[1]')
  if (mswin.ole32.CoCreateInstance(
      mswin.guid(clsid),
      nil,
      mswin.ole32.CLSCTX_INPROC_SERVER,
      com.iidof(name),
      ffi.cast('void**', temp)) == 0) then
    return ffi.gc(temp[0], com_gc)
  else
    return nil
  end
end

return com
