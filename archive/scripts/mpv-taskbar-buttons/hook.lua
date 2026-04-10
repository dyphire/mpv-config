-- https://github.com/qwerty12/mpv-taskbar-buttons
--[[
    Copyright (C) 2022 Faheem Pervez

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
    https://www.gnu.org/licenses/gpl-2.0.html
--]]

-- can't use mp.get_script_directory() because this is loaded through load-script, which lacks context
local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)") -- https://stackoverflow.com/a/23535333
package.path = script_dir .. "\\?.lua;" .. package.path

local ffi = require("ffi")
local common = require("common")
local C = ffi.C

local options = nil

local callbacks = {
    [common.button_ids[C.BUTTON_PREV]] = function() mp.command(options.prev_command == "" and "playlist-prev" or options.prev_command) end,
    [common.button_ids[C.BUTTON_PLAY_PAUSE]] = function()
        if options.play_pause_command == "" then
            mp.commandv("cycle", "pause")
        else
            mp.command(options.play_pause_command)
        end
    end,
    [common.button_ids[C.BUTTON_NEXT]] = function() mp.command(options.next_command == "" and "playlist-next" or options.next_command) end
}

ffi.cdef [[
    // From lua.c @ e686297ecf3928b768c674bb10faa6f352b999b8
    struct script_ctx {
        const char *name;
        const char *filename;
        const char *path;
        void *lua_State;
        void *mp_log;
        void *mpv_handle_client;
        void *MPContext;
        size_t lua_malloc_size;
        uintptr_t lua_allocf;
        void *lua_alloc_ud;
        void *stats_ctx;
    };
    typedef void (*mpv_set_wakeup_callback) (void *mpv_handle_ctx, void (*cb)(void *q12), const void *d);

    bool __stdcall CloseHandle(const void *hObject);
    void* __stdcall GetModuleHandleA(const char *lpModuleName);
    void* __stdcall GetProcAddress(void *hModule, const char *lpProcName);

    void* __stdcall CreateEventW(void *lpEventAttributes, bool bManualReset, bool bInitialState, const wchar_t *lpName);
    unsigned long __stdcall WaitForMultipleObjects(unsigned long nCount, const void **lpHandles, bool bWaitAll, unsigned long dwMilliseconds);

    void* __stdcall GlobalAlloc(unsigned int uFlags, size_t dwBytes);
    void* __stdcall GlobalFree(void *hMem);
    bool __stdcall VirtualProtect(void *lpAddress, size_t dwSize, unsigned long flNewProtect, unsigned long *lpflOldProtect);

    typedef __int64 (__stdcall *HOOKPROC)(int code, unsigned __int64 wParam, __int64 lParam);
    void* __stdcall SetWindowsHookExW(int idHook, HOOKPROC lpfn, void *hmod, unsigned long dwThreadId);
    bool __stdcall UnhookWindowsHookEx(void *hhk);

    bool __stdcall ChangeWindowMessageFilterEx(void *hwnd, unsigned int message, unsigned long action, void *pChangeFilterStruct);
]]
local WH_GETMESSAGE = 3
local WM_COMMAND = 0x0111
local MSGFLT_ADD = 1
local INFINITE, WAIT_OBJECT_0 = 0xFFFFFFFF, 0x00000000
local GPTR = 0x0040
local PAGE_EXECUTE_READWRITE = 0x40
local SetEvent = C.GetProcAddress(C.GetModuleHandleA("kernel32.dll"), "SetEvent")
local mpv_set_wakeup_callback = ffi.cast("mpv_set_wakeup_callback", C.GetProcAddress(C.GetModuleHandleA(nil), "mpv_set_wakeup_callback"))

local last_button_hit = ffi.cast("int*", C.GlobalAlloc(GPTR, ffi.sizeof("int"))) -- not actually thread safe...
local script_ctx = ffi.cast("struct script_ctx*", debug.getregistry()["ctx"]) -- hell yeah, Lua(JIT)
local nEventCount = 2
local hEvents = ffi.cast("const void**", C.GlobalAlloc(GPTR, ffi.sizeof("void*[?]", nEventCount)))
local mpv_hwnd, mpv_tid
local lpCompiledCallback, lpGetMsgProc
local hHook = nil

local function generate_hook_callback()
    -- Taken from https://github.com/nucular/tcclua
    ffi.cdef [[
        typedef struct TCCState TCCState;
        TCCState *tcc_new(void);
        void tcc_delete(TCCState *s);
        int tcc_set_options(TCCState *s, const char *str);
        int tcc_compile_string(TCCState *s, const char *buf);
        int tcc_set_output_type(TCCState *s, int output_type);
        int tcc_relocate(TCCState *s1, void *ptr);
        void *tcc_get_symbol(TCCState *s, const char *name);
    ]]

    local tcc = ffi.load(options.tcc_dll_path)
    assert(tcc)
    local state = tcc.tcc_new()
    assert(state)
    tcc.tcc_set_output_type(state, 1) -- TCC_OUTPUT_MEMORY
    tcc.tcc_set_options(state, "-nostdinc -nostdlib")
    local hook = [[
    void _start(){}
    #define NULL ((void *)0)
    #define __int64 long long
    #define __stdcall __attribute__((__stdcall__))

    typedef struct tagMSG {
        void *hwnd;
        unsigned int message;
        unsigned __int64 wParam;
        __int64 lParam;
        unsigned long time;
        long pt[2];
    } MSG, *LPMSG;
    typedef __int64 (__stdcall *CALLNEXTHOOKEX)(void*, int, unsigned __int64, __int64);
    typedef int (__stdcall *SETEVENT)(void*);

    __int64 __stdcall GetMsgProc(int code, unsigned __int64 wParam, __int64 lParam)
    {
        volatile const CALLNEXTHOOKEX CallNextHookEx = (CALLNEXTHOOKEX)#CallNextHookEx#;
        if (code < 0 || wParam != 0x0001) // HC_ACTION, PM_REMOVE; remove PM_REMOVE comparison if all button presses aren't being caught
            goto cont;

        const LPMSG msg = (LPMSG)lParam;
        if (msg && msg->message == #WM_COMMAND# && msg->hwnd == (void*)#mpv_hwnd#) {
            int const wmId = ((unsigned short)(((unsigned __int64)(msg->wParam)) & 0xffff)); // LOWORD
            if (wmId < #BUTTON_FIRST# || wmId > #BUTTON_LAST#)
                goto cont;

            int volatile *const last_button_hit = (int*)#last_button_hit#;
            void* volatile const hCommandReceivedEvent = (void*)#hCommandReceivedEvent#;
            volatile const SETEVENT SetEvent = (SETEVENT)#SetEvent#;

            *last_button_hit = wmId;
            SetEvent(hCommandReceivedEvent);
            msg->message = 0x0000; // WM_NULL
            return 0;
        }

        cont:
        return CallNextHookEx(NULL, code, wParam, lParam);
    }
    ]]
    for name, value in pairs({
        ["mpv_hwnd"] = mpv_hwnd,
        ["WM_COMMAND"] = WM_COMMAND,
        ["BUTTON_FIRST"] = common.button_ids[C.BUTTON_FIRST],
        ["BUTTON_LAST"] = common.button_ids[C.BUTTON_LAST - 1],
        ["last_button_hit"] = last_button_hit,
        ["hCommandReceivedEvent"] = hEvents[1],
        ["SetEvent"] = SetEvent,
        ["CallNextHookEx"] = C.GetProcAddress(C.GetModuleHandleA("user32.dll"), "CallNextHookEx")
    }) do
        value = type(value) == "cdata" and tostring(value):match("^cdata<.+>: (0x.+)") or tostring(value)
        hook = hook:gsub("#" .. name .. "#", value)
    end

    assert(tcc.tcc_compile_string(state, hook) == 0)
    local size = tcc.tcc_relocate(state, nil)
    assert(size > 0)
    -- a buffer allocated with ffi.new here eventually causes a crash
    local lpCompiled = C.GlobalAlloc(GPTR, size)
    assert(lpCompiled)
    assert(C.VirtualProtect(lpCompiled, size, PAGE_EXECUTE_READWRITE, ffi.new("int[1]")))
    assert(tcc.tcc_relocate(state, lpCompiled) == 0)

    local lpGetMsgProc = tcc.tcc_get_symbol(state, "_GetMsgProc@" .. tostring(3 * ffi.sizeof("void*")))
    assert(lpGetMsgProc)

    tcc.tcc_delete(state)
    tcc = nil

    return lpCompiled, lpGetMsgProc
end
for i = 0, nEventCount - 1 do
    hEvents[i] = C.CreateEventW(nil, false, i == 0, nil)
end
mpv_set_wakeup_callback(script_ctx.mpv_handle_client, SetEvent, hEvents[0])

local function start()
    mp.unregister_idle(start)

    mpv_hwnd, mpv_tid = common.get_mpv_hwnd()
    if mpv_tid == 0 then
        return
    end
    options = common.read_options()
    lpCompiledCallback, lpGetMsgProc = generate_hook_callback()
    hHook = C.SetWindowsHookExW(WH_GETMESSAGE, lpGetMsgProc, nil, mpv_tid)
    if hHook then
        -- allow unelevated Explorer to post WM_COMMAND to mpv running as adminstrator
        C.ChangeWindowMessageFilterEx(mpv_hwnd, WM_COMMAND, MSGFLT_ADD, nil)
    end

    collectgarbage("collect") -- force TCC unload
end
mp.register_idle(start)

_G.mp_event_loop = function()
    while mp.keep_running do
        local dwStart, dwElapsed, dwTimeout = 0, 0, mp.get_next_timeout()
        if dwTimeout == nil then
            dwTimeout = INFINITE
        else
            dwStart = mp.get_time() * 1000
            dwTimeout = dwTimeout * 1000
            --dwElapsed = (mp.get_time() * 1000) - dwStart
        end

        while mp.keep_running do
            local dwStatus = C.WaitForMultipleObjects(nEventCount, hEvents, false, dwTimeout - dwElapsed)
            if dwStatus == WAIT_OBJECT_0 then --hMpvWakeupEvent signalled
                mp.dispatch_events(false)
                -- break? new timers might have been introduced
            elseif dwStatus == WAIT_OBJECT_0 + 1 then -- hCommandReceivedEvent signalled
                local wmId = last_button_hit[0]
                if callbacks[wmId] then
                    callbacks[wmId]()
                    -- if your modified callbacks introduce timers, break here
                end
            end

            if dwTimeout == INFINITE then
                break
            end

            dwElapsed = (mp.get_time() * 1000) - dwStart
            if dwElapsed < dwTimeout then
                -- re-call mp.get_next_timeout() here and break if less than dwTimeout?
                -- continue
            else -- timed out
                mp.dispatch_events(false)
                break
            end
        end
    end

    -- shutdown
    if hHook ~= nil then
        C.UnhookWindowsHookEx(hHook)
        hHook = nil
    end
    if lpCompiledCallback ~= nil then
        lpGetMsgProc = nil
        C.GlobalFree(lpCompiledCallback)
        lpCompiledCallback = nil
    end
    mpv_set_wakeup_callback(script_ctx.mpv_handle_client, nil, nil)
    if hEvents ~= nil then
        for i = 0, nEventCount - 1 do
            if hEvents[i] ~= nil then
                C.CloseHandle(hEvents[i])
                hEvents[i] = nil
            end
        end
        C.GlobalFree(hEvents)
        hEvents = nil
    end
    if last_button_hit ~= nil then
        C.GlobalFree(last_button_hit)
        last_button_hit = nil
    end
end