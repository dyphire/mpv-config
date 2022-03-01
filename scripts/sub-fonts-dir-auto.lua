--[[

    Automatically look for a fonts directory to use with `sub-fonts-dir`.

    This mpv Lua script will automatically use the `sub-fonts-dir` option (to
    override the default `~~/fonts` location) if it find a `Fonts` directory
    alongside the currently playing file.  (The name of the directory is
    matched case-insensitively.)

    **NOTE:** The `sub-fonts-dir` option has been submitted as part of [PR
    #9856](https://github.com/mpv-player/mpv/pull/9856).  Until it is merged
    upstream, you will have to download and compile the [mpv
    source](https://github.com/mpv-player/mpv) yourself.


    USAGE:

    Simply drop this script in your scripts configuration directory (usually
    `~/.config/mpv/scripts/`).


    REQUIREMENTS:

    This script requires a version of mpv that includes the `sub-fonts-dir`
    option.


    NOTES:

    - Any `--sub-fonts-dir` option passed on the command-line will override
    this script.

    - When going through a playlist, `sub-fonts-dir` will be dynamically
    updated for each individual file.

    - This script will output some additional information on higher verbosity
    levels (`-v`).  To increase the verbosity for this script only, use
    `--msg-level=sub_fonts_dir_auto=v` (or `=debug` for more output).


    AUTHOR:

    Frédéric Brière (fbriere@fbriere.net)

    Licensed under the GNU General Public License, version 2 or later.

--]]


local utils = require 'mp.utils'
local msg = require 'mp.msg'
-- msg.trace() was added in 0.28.0 -- define it ourselves if it's missing
if msg.trace == nil then
    msg.trace = function(...) return mp.log("trace", ...) end
end


-- Directory name we are looking for (case-insensitive)
local FONTS_DIR_NAME = "Fonts"
-- Option name that we want to set
local OPTION_NAME = "sub-fonts-dir"
-- Make sure this option is available in this version of mpv
do
    local _, err = mp.get_property(OPTION_NAME)
    if err then
        msg.error(string.format("This version of mpv does not support the %s option", OPTION_NAME))
        return
    end
end


-- Whether a path is a directory
local function isdir(path)
    return utils.readdir(path .. "/.") ~= nil
end

-- Set an option's value for this file, without overriding the command-line
local function set_option(name, value)
    if not mp.get_property_bool(string.format("option-info/%s/set-from-commandline", name)) then
        msg.verbose(string.format("Setting %s to %q", name, value))
        mp.set_property(string.format("file-local-options/%s", name), value)
    else
        msg.debug(string.format("Option %s was set on command-line -- leaving it as-is", name))
    end
end

-- Find a "Fonts" directory under a single path
local function find_fonts_dir(path)
    local entries = utils.readdir(path, "dirs")
    if entries == nil then
        -- mpv will throw an error message soon enough, no need to intervene
        return
    end
    msg.trace(string.format("Iterating over directories under %q", path))
    for _, entry in ipairs(entries) do
        msg.trace("Candidate directory:", entry)
        if entry:lower() == FONTS_DIR_NAME:lower() then
            msg.trace("Match found")
            return utils.join_path(path, entry)
        end
    end
    msg.trace("No match found")
end

-- "on_load" hook callback for when a file is about to be loaded.
local function on_load()
    local path = mp.get_property("path")
    if isdir(path) then
        msg.debug("Playing 'file' is actually a directory -- skipping")
        return
    end

    local path_dir = utils.split_path(path)
    -- Cosmetic nitpicking: That trailing "/" just looks annoying to me
    path_dir = path_dir:gsub("(.)/+$", "%1")

    msg.debug(string.format("Searching %q for fonts directory", path_dir))
    local fonts_dir = find_fonts_dir(path_dir)
    if fonts_dir then
        msg.debug("Found fonts directory:", fonts_dir)
        set_option(OPTION_NAME, fonts_dir)
    end
end
mp.add_hook("on_load", 50, on_load)
