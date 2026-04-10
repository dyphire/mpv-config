---@meta mp.msg

---@class mp.msg
local msg = {}

---@param level 'fatal'|'error'|'warn'|'info'|'v'|'debug'|'trace'
---@param ... any
function msg.log(level, ...) end

---@param ... any
function msg.fatal(...) end

---@param ... any
function msg.error(...) end

---@param ... any
function msg.warn(...) end

---@param ... any
function msg.info(...) end

---@param ... any
function msg.verbose(...) end

---@param ... any
function msg.debug(...) end

---@param ... any
function msg.trace(...) end


return msg