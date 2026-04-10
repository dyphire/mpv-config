local ffi = require("ffi")
local C = ffi.C

-- no point bundling this with common{}: hook.lua's package.path needs to be modified to in order to see this file...
local function get_script_directory()
    local ret = mp.get_script_directory()
    if ret == nil then
        -- if we're here, then either this isn't installed to a scripts subdir or it's called from a script loaded with load-script
        ret = debug.getinfo(2, "S").source:sub(2):match("(.*/)") -- https://stackoverflow.com/a/23535333
    end
    return ret
end

ffi.cdef [[
    void* __stdcall FindWindowExA(void *hWndParent, void *hWndChildAfter, const char *lpszClass, const char *lpszWindow);
    unsigned int __stdcall GetWindowThreadProcessId(void *hWnd, unsigned int *lpdwProcessId);

    enum {
        BUTTON_FIRST,
        BUTTON_PREV = BUTTON_FIRST,
        BUTTON_PLAY_PAUSE,
        BUTTON_NEXT,
        BUTTON_LAST // note: Windows imposes a limit of seven buttons.
    };
]]

local common = {
    button_ids = {}
}
for i = C.BUTTON_FIRST, C.BUTTON_LAST - 1 do
    common.button_ids[i] = 0x0400 + i
end

common.user_opts = {
    never_disable_buttons = false,
    tcc_dll_path = "",

    prev_command = "",
    play_pause_command = "",
    next_command = ""
}

function common.read_options()
    require("mp.options").read_options(common.user_opts, "mpv-taskbar-buttons")
    if common.user_opts.tcc_dll_path ~= "" then
        common.user_opts.tcc_dll_path = mp.command_native({ "expand-path", common.user_opts.tcc_dll_path })
    else
        local script_dir = get_script_directory()
        assert(script_dir) -- initial slash notwithstanding, try to avoid a DLL being loaded from the working directory...
        common.user_opts.tcc_dll_path = script_dir .. "/libtcc.dll"
    end
    return common.user_opts
end

function common.get_mpv_hwnd()
    local our_pid = mp.get_property_number("pid")
    local hwnd_pid = ffi.new("unsigned int[1]")
    local hwnd = nil

    repeat
        hwnd = C.FindWindowExA(nil, hwnd, "mpv", nil)
        if hwnd ~= nil then
            local thread_id = C.GetWindowThreadProcessId(hwnd, hwnd_pid)
            if hwnd_pid[0] == our_pid then
                return hwnd, thread_id
            end
        else
            return nil, 0
        end
    until false
end

return common
