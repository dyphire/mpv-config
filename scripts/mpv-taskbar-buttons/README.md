Hack to add media control taskbar buttons (well, thumbbar buttons) for mpv:

![Screenshot of the usual Windows taskbar preview but with media control buttons](https://github.com/qwerty12/mpv-taskbar-buttons/blob/preview/screenshot.png)

## Requirements

* Windows 7 or later

* 64-bit mpv. This will not work with 32-bit mpv without changes I am not willing to make

* mpv that uses LuaJIT. You can safely assume to be the case; it is 99% likely you're using a build by shinchiro (or one derived from his), which use nothing but LuaJIT.

To install this, just run `git clone https://github.com/qwerty12/mpv-taskbar-buttons` in your mpv scripts folder.
If you instead download the zipped version of this repo, just copy the mpv-taskbar-buttons folder as-is into your mpv scripts folder.
The files **must** be in a subfolder of your mpv scripts folder for this script to load. To get rid of this, just delete the folder.

If you want to change what happens when one of the existing buttons are clicked, look at the `callbacks` table in hook.lua.

Requests to add more buttons to this script will be ignored. If you have code to perform a custom action already written but need help with adding a button to your own copy of this script to call it, make an issue. Windows allows up to seven buttons.

## Known issues

* If you edit the playlist and the current file suddenly becomes the first or last (or in the middle if it wasn't before), the buttons probably won't reflect that. Should be fixable, I'm too lazy to do it as I don't edit playlists

* Again, this is a hack. It relies on assumptions that, unlikely as it is, may not hold true in the future. If you suddenly start noticing mpv crashing where it wouldn't before, the first thing to try is probably disabling this script

## Is this a virus? Actually, why do you even need a DLL file?

I'll forgo the usual cries of "it's open source" and simply mention I'm not stupid enough to stick my actual name on something I would know to have a virus in that scenario. The way Windows lets applications know a thumbbar button has been hit is by posting a message to a window. As this is an external script and does not have direct control over the mpv function handling the message loop, it must use a facility provided by Windows to intercept the message loop. You can't pass it a Lua function and expect Windows to know what to do with it.  
LuaJIT does provide an interoperability mechanism for this, but the problem is, to quote the [LuaJIT manual](https://luajit.org/ext_ffi_semantics.html#callback), "[LuaJIT] callbacks are slow!". They actually work pretty great 99.9% of the time, but when trying one for this I noticed that very rapid mouse movements would cause mpv to crash. Going with something compiled was going to be the way to go.

I didn't want to provide a pre-compiled DLL because I wanted to keep the C part as easily editable as the Lua code, hence using TCC to build the C code on-the-fly. The downside to that decision is that TCC is meant more to be fast at compiling things, so a lot of the optimisations GCC etc. would make when building a DLL aren't there. Still, we're only talking about one pretty-short function, and the TCC-compiled callback is still undoubtedly faster than one written in Lua.

If you're paranoid, then replace the included libtcc.dll with the one in tcc-0.9.27-win64-bin.zip from https://download.savannah.gnu.org/releases/tinycc/ (which is where the bundled libtcc.dll comes from)

If you want to try a version written in nothing but Lua(JIT) - with the caveat it will crash when trying to handle a large number of messages -  check out the `pure-luajit` branch of this repo. I don't recommend using `pure-luajit`, however, and I will not provide support or updates for it, either.

## Credits

https://github.com/duncanc/ljf-com - for the great COM binding in ljf-com, which just happened to have a definition for the very interface I needed to use

https://github.com/reupen/columns_ui - for the taskbar icons in res, which are just straight-up lifted from the excellent Columns UI for foobar2000

## SMTC

This is not the same thing as Windows 8+ System Media Transport Controls integration. Check out one of the following for that:

https://github.com/datasone/MPVMediaControl

https://github.com/x0wllaar/MPV-SMTC

One of the above combined with https://github.com/krlvm/MediaFlyout can serve as an alternative to this, actually.