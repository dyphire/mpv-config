## MPV config ([English branch](https://github.com/dyphire/mpv-config/tree/eng))

### Project Introduction

This project is the configuration file for the [mpv](https://github.com/mpv-player/mpv) player on Windows. It should be placed in the `portable_config` folder in the directory where `mpv.exe` is located,

or under the default mpv configuration path `%APPDATA%/mpv/`. This method takes effect globally.

Using `portable_config` will override the global configuration scheme.

PS: When editing the configuration file yourself, please note that the encoding format should be UTF-8 and the newline character should be Unix, otherwise MPV may not recognize it.

**mpv integration package download**: [Releases](https://github.com/dyphire/mpv-config/releases)

### mpv Clients

- Currently, there is no officially released client for mpv. The official website lists some recommended third-party compiled versions: [https://mpv.io/installation](https://mpv.io/installation)
  - On Windows, the shinchiro version is recommended: [shinchiro_mpv](https://github.com/shinchiro/mpv-winbuild-cmake/releases) ![releases](https://img.shields.io/github/v/release/shinchiro/mpv-winbuild-cmake)
  - Daily build version: [zhongfly_mpv](https://github.com/zhongfly/mpv-winbuild) [![releases](https://img.shields.io/github/v/release/zhongfly/mpv-winbuild)](https://github.com/zhongfly/mpv-winbuild/releases)
  - Personal modified version [mpv](https://github.com/dyphire/mpv/tree/patch) build: [dyphire_mpv](https://github.com/dyphire/mpv-winbuild) [![releases](https://img.shields.io/github/v/release/dyphire/mpv-winbuild)](https://github.com/dyphire/mpv-winbuild/releases)
    - [Modified mpv related instructions](https://github.com/dyphire/mpv-config/discussions/7)
- Currently mature mpv/libmpv front-end recommendations: [mpv.net](https://github.com/mpvnet-player/mpv.net) [![mpv.net](https://flat.badgen.net/github/last-commit/mpvnet-player/mpv.net?scale=1.0&cache=1800)](https://github.com/mpvnet-player/mpv.net) [![releases](https://img.shields.io/github/v/release/mpvnet-player/mpv.net)](https://github.com/mpvnet-player/mpv.net/releases)
  - Personal mpv.net configuration reference: https://github.com/dyphire/mpv-config/tree/mpvnet
- Recommended methods for calling mpv playback from browser
  - [mpv-handler](https://github.com/akiirui/mpv-handler) with script [play-with-mpv](https://greasyfork.org/en/scripts/416271-play-with-mpv)
  - [external-player](https://github.com/LuckyPuppy514/external-player)
- Single instance mode: [umpv](https://github.com/zhongfly/umpv-go)

### Script and Shader Documentation

For a detailed introduction to the mpv scripts and functions used in this project, please see the wiki content: [Script Documentation-wiki](https://github.com/dyphire/mpv-config/wiki/script-documentation)

For the shaders involved in this project, see the relevant content in mpv.conf

### Preview

![image-20231103224421000](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224421000.png)

![image-20231103224540075](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224540075.png)

![image-20231103224557019](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224557019.png)

| Pinyin Search (supports initials)                                                                          | Subtitle Download                                                                                       |
| ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| ![image](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224614449.png) | ![image](https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224721066.png) |

### References

* [hooke007 Configuration Manual](https://hooke007.github.io/mpv-lazy/mpv.html)
* [mpv Official Development Manual (English)](https://mpv.io/manual/master/)
* [mpv Official Documentation Chinese Translation - hooke007](https://github.com/hooke007/mpv_doc-CN)