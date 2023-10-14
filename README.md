**MPV config**

This project is the configuration file of the MPV player on Windows, which should be put into the `portable_config` folder of the directory where `mpv.exe` is located. Or mpv configuration under the default path `%APPDATA%/mpv/` , this way takes effect globally.

Using `portable_config` overrides the global configuration scheme.

PS: When editing the configuration file by yourself, pay attention to the encoding format should be UTF-8 and the newline character should be Unix, otherwise MPV may not recognize it.

**mpv integration package download**：[Releases](https://github.com/dyphire/mpv-config/releases)

- At present, there is no officially released client for mpv. There are some recommended third-party compiled versions on the official website: [https://mpv.io/installation](https://mpv.io/installation)
  - Shanchiro’s bulid recommended on Windows: [shinchiro_mpv](https://github.com/shinchiro/mpv-winbuild-cmake/releases) ![releases](https://img.shields.io/github/v/release/shinchiro/mpv-winbuild-cmake)
  - Build based on a personal modified: [dyphire_mpv](https://github.com/dyphire/mpv-winbuild) [![releases](https://img.shields.io/github/v/release/dyphire/mpv-winbuild)](https://github.com/dyphire/mpv-winbuild/releases)
    -  [Modified MPV related instructions](https://github.com/dyphire/mpv-config/discussions/7)
-   Recommended methods for browsers to invoke MPV playback
	- [mpv-handler](https://github.com/akiirui/mpv-handler) with [play-with-mpv](https://greasyfork.org/zh-CN/scripts/416271-play-with-mpv)
	- [Play-With-MPV](https://github.com/LuckyPuppy514/Play-With-MPV)


Reference:

* [ MPV Official Manual](https://mpv.io/manual/master/)
