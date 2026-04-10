---@meta _

---A ParserConfig object returned by addons
---@class (partial) ParserConfig: ParserAPI
---@field priority number?
---@field api_version string    The minimum API version the string requires.
---@field version string?        The minimum API version the string requires. @deprecated.
---
---@field can_parse (async fun(self: Parser, directory: string, parse_state: ParseState): boolean)?
---@field parse (async fun(self: Parser, directory: string, parse_state: ParseState): List?, Opts?)?
---@field setup fun(self: Parser)?
---
---@field name string?
---@field keybind_name string?
---@field keybinds KeybindList?


---The parser object used by file-browser once the parsers have been loaded and initialised.
---@class Parser: ParserAPI, ParserConfig
---@field name string
---@field priority number
---@field api_version string
---@field can_parse async fun(self: Parser, directory: string, parse_state: ParseState): boolean
---@field parse async fun(self: Parser, directory: string, parse_state: ParseState): List?, Opts?


---@alias ParseStateSource 'browser'|'loadlist'|'script-message'|'addon'|string
---@alias ParseProperties table<string,any>

---The Parse State object passed to the can_parse and parse methods
---@class ParseStateFields
---@field source ParseStateSource
---@field directory string
---@field already_deferred boolean?
---@field properties ParseProperties

---@class ParseState: ParseStateFields, ParseStateAPI

---@class ParseStateTemplate
---@field source ParseStateSource?
---@field properties ParseProperties?
