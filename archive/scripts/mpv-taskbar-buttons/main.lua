-- https://github.com/qwerty12/mpv-taskbar-buttons
local script_dir = mp.get_script_directory()
if not script_dir then
    mp.msg.error("Install this and associated files to its own directory. (READMEs are there to be, y'know, read.)")
    return
end

local ffi = require("ffi")
if ffi.os ~= "Windows" then
    return
end
if ffi.abi("32bit") then
    mp.msg.error("This script won't work with 32-bit Windows.")
    return
end

package.path = package.path .. ";" .. script_dir .. "\\ljf-com\\?.lua;" .. script_dir .. "\\ljf-com\\?\\init.lua"
local bit = require("bit")
local common = require("common")
local com = require("extern.mswindows.com")
local taskbarlist = require("extern.mswindows.taskbarlist")
local C = ffi.C

ffi.cdef [[
    typedef enum THUMBBUTTONFLAGS
    {
        THBF_ENABLED	= 0,
        THBF_DISABLED	= 0x1,
        THBF_DISMISSONCLICK	= 0x2,
        THBF_NOBACKGROUND	= 0x4,
        THBF_HIDDEN	= 0x8,
        THBF_NONINTERACTIVE	= 0x10
    } THUMBBUTTONFLAGS;

    typedef enum THUMBBUTTONMASK
    {
        THB_BITMAP	= 0x1,
        THB_ICON	= 0x2,
        THB_TOOLTIP	= 0x4,
        THB_FLAGS	= 0x8
    } THUMBBUTTONMASK;

    #pragma pack(8)
    typedef struct THUMBBUTTON
    {
        THUMBBUTTONMASK dwMask;
        unsigned int iId;
        unsigned int iBitmap;
        void *hIcon;
        wchar_t szTip[ 260 ];
        THUMBBUTTONFLAGS dwFlags;
    } THUMBBUTTON;
    typedef struct THUMBBUTTON *LPTHUMBBUTTON;
    #pragma pack()

    void* __stdcall LoadImageA(void *hInst, const char *name, unsigned int type, int cx, int cy, unsigned int fuLoad);
    int __stdcall GetSystemMetrics(int nIndex);
]]
local IMAGE_ICON = 1
local SM_CXSMICON = 49
local LR_LOADFROMFILE = 0x00000010

local mpv_hwnd = nil
local cxButton = C.GetSystemMetrics(SM_CXSMICON)
local cbThumbButton = ffi.sizeof("THUMBBUTTON")
local icon_disabled_state = bit.bor(C.THBF_DISABLED, C.THBF_NOBACKGROUND)

-- note: I'm lazy and don't clean any of this up. I leave that task to Windows.
-- This script will only be loaded once per mpv process, so there's not going to be any leaks - from that, anyway.
local w7taskbar = com.new(taskbarlist.clsid, "ITaskbarList3")
if not w7taskbar then
    mp.msg.error("Couldn't create ITaskbarList3 instance")
    return
end

local icons = {
    [C.BUTTON_PREV] = script_dir .. "\\res\\light-previous.ico",
    [C.BUTTON_PLAY_PAUSE] = { -- *shrug*
        [false] = script_dir .. "\\res\\light-pause.ico",
        [true] = script_dir .. "\\res\\light-play.ico"
    },
    [C.BUTTON_NEXT] = script_dir .. "\\res\\light-next.ico"
}
assert(require("table.nkeys")(icons) == C.BUTTON_LAST)

local buttons = ffi.new("THUMBBUTTON[?]", C.BUTTON_LAST)
local updated_buttons = ffi.new("THUMBBUTTON[?]", C.BUTTON_LAST)

local function on_pause(_, value)
    local newIcon = icons[C.BUTTON_PLAY_PAUSE][value]
    if newIcon and newIcon ~= buttons[C.BUTTON_PLAY_PAUSE].hIcon then
        buttons[C.BUTTON_PLAY_PAUSE].hIcon = newIcon
        buttons[C.BUTTON_PLAY_PAUSE].dwMask = C.THB_ICON
        w7taskbar:ThumbBarUpdateButtons(mpv_hwnd, 1, buttons + C.BUTTON_PLAY_PAUSE)
    end
end

local check_pause = false
local function on_pl_pos_change(_, value)
    if value == -1 then
        check_pause = true
        return
    end
    local cmp_values = { [C.BUTTON_PREV] = 1, [C.BUTTON_NEXT] = mp.get_property_number("playlist-count") }
    local to_update = {}
    local count = 0

    for k, v in pairs(cmp_values) do
        buttons[k].dwMask = 0
        if value == v then
            if bit.band(buttons[k].dwFlags, C.THBF_DISABLED) ~= C.THBF_DISABLED then
                buttons[k].dwFlags = icon_disabled_state
                buttons[k].dwMask = C.THB_FLAGS
            end
        else
            if buttons[k].dwFlags ~= C.THBF_ENABLED then
                buttons[k].dwFlags = C.THBF_ENABLED
                buttons[k].dwMask = C.THB_FLAGS
            end
        end

        if buttons[k].dwMask == C.THB_FLAGS then
            to_update[count] = k
            count = count + 1
        end
    end

    if check_pause then
        check_pause = false
        buttons[C.BUTTON_PLAY_PAUSE].dwFlags = C.THBF_ENABLED
        buttons[C.BUTTON_PLAY_PAUSE].dwMask = C.THB_FLAGS
        to_update[count] = C.BUTTON_PLAY_PAUSE
        count = count + 1
    end

    if count == 0 then
        return
    end

    if count == 1 then
        w7taskbar:ThumbBarUpdateButtons(mpv_hwnd, 1, buttons + to_update[0])
        return
    end

    assert(count < C.BUTTON_LAST)
    for i = 0, count - 1 do
        ffi.copy(updated_buttons + i, buttons + to_update[i], cbThumbButton)
    end
    w7taskbar:ThumbBarUpdateButtons(mpv_hwnd, count, updated_buttons)
end

local function on_idle()
    mp.unregister_idle(on_idle)

    mpv_hwnd = common.get_mpv_hwnd()
    if mpv_hwnd == nil then
        mp.msg.error("Couldn't find mpv window handle")
        return
    end

    local options = common.read_options()
    local is_idle_active = not options.never_disable_buttons and mp.get_property_bool("idle-active", false)
    for i = C.BUTTON_FIRST, C.BUTTON_LAST - 1 do
        if not is_idle_active then
            buttons[i].dwMask = C.THB_ICON
        else
            buttons[i].dwMask = bit.bor(C.THB_ICON, C.THB_FLAGS)
            buttons[i].dwFlags = icon_disabled_state
        end
        buttons[i].iId = common.button_ids[i]
        if type(icons[i]) ~= "table" then
            icons[i] = C.LoadImageA(nil, icons[i], IMAGE_ICON, cxButton, cxButton, LR_LOADFROMFILE)
            buttons[i].hIcon = icons[i]
        else
            for key, value in pairs(icons[i]) do
                icons[i][key] = C.LoadImageA(nil, value, IMAGE_ICON, cxButton, cxButton, LR_LOADFROMFILE)
                buttons[i].hIcon = icons[i][key]
            end
        end
    end

    local hr = w7taskbar:ThumbBarAddButtons(mpv_hwnd, C.BUTTON_LAST, buttons)
    if hr >= 0 then
        mp.observe_property("pause", "bool", on_pause)
        if not options.never_disable_buttons then
            mp.observe_property("playlist-pos-1", "number", on_pl_pos_change)
        end
        mp.commandv("load-script", script_dir .. "/hook.lua")
    else
        mp.msg.error("ITaskbarList3::ThumbBarAddButtons failed with " .. hr)
    end
end

local function on_vo_configured(_, value)
    if not value then return end
    mp.unobserve_property(on_vo_configured)
    mp.register_idle(on_idle)
end

mp.observe_property("vo-configured", "bool", on_vo_configured)
