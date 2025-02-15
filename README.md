## MPV config

### Project introduction

This project is a configuration file for [mpv](https://github.com/mpv-player/mpv) player under windows, which should be placed in the `portable_config` folder in the directory where `mpv.exe` is located.

Or mpv is configured under the default path `%APPDATA%/mpv/`. This method takes effect globally.

The global configuration scheme will be overridden when using `portable_config`.

PS: When editing the configuration file by yourself, please note that the encoding format should be UTF-8 and the newline character should be Unix, otherwise MPV may not be recognized.

**mpv integration package download**: [Releases](https://github.com/dyphire/mpv-config/releases)

### mpv client

- Currently, there is no officially released client for mpv. There are some recommended third-party compiled versions on the official website: [https://mpv.io/installation](https://mpv.io/installation)
- It is recommended to use shinchiro version on windows: [shinchiro_mpv](https://github.com/shinchiro/mpv-winbuild-cmake/releases) ![releases](https://img.shields.io/github/v/release/shinchiro/mpv-winbuild-cmake)
- Daily build version: [zhongfly_mpv](https://github.com/zhongfly/mpv-winbuild) [![releases](https://img.shields.io/github/v/release/zhongfly/mpv-winbuild)](https://github.com/zhongfly/mpv-winbuild/releases)
- Based on personal modified version [mpv](https://github.com/dyphire/mpv/tree/patch) Build version: [dyphire_mpv](https://github.com/dyphire/mpv-winbuild) [![releases ](https://img.shields.io/github/v/release/dyphire/mpv-winbuild)](https://github.com/dyphire/mpv-winbuild/releases)
- [Instructions related to modified version of mpv](https://github.com/dyphire/mpv-config/discussions/7)
- The currently relatively mature mpv/libmpv front-end recommendation: [mpv.net](https://github.com/mpvnet-player/mpv.net) [![mpv.net](https://flat.badgen.net/github/last-commit/mpvnet-player/mpv.net?scale=1.0&cache=1800)](https://github.com/mpvnet-player/mpv.net) [![releases](https://img.shields.io/github/v/release/mpvnet-player/mpv.net)](https://github.com/mpvnet-player/mpv.net/releases)
- Personal mpv.net configuration file reference: https://github.com/dyphire/mpv-config/tree/mpvnet
- Recommended method for browser to call mpv playback
- [mpv-handler](https://github.com/akiirui/mpv-handler) with script [play-with-mpv](https://greasyfork.org/zh-CN/scripts/416271-play-with-mpv)
- [Play-With-MPV](https://github.com/LuckyPuppy514/Play-With-MPV)
- Single instance mode: [umpvw](https://github.com/SilverEzhik/umpvw)

### Script shader description
For a detailed introduction to the mpv script and functions used in this project, please see the wiki content: [Script description - wiki](https://github.com/dyphire/mpv-config/wiki/脚本说明)

For the shaders involved in this project, see the relevant content in mpv.conf

### Preview

![image-20231103224421000](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224421000.png)

![image-20231103224540075](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224540075.png)

![image-20231103224557019](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224557019.png)

| Pinyin search (supports initial letters) | Subtitle download |
|----------------|----------------|
| ![image](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224614449.png) | ![image](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224721066.png) |


### Refer to

* [hooke007 Configuration Manual](https://hooke007.github.io/mpv-lazy/mpv.html)
* [mpv original official development version manual (English)](https://mpv.io/manual/master/)
* [Chinese version of mpv official document-hooke007](https://github.com/hooke007/mpv_doc-CN)
