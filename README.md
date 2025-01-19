## MPV config

### Project Introduction

 This item is the configuration file of the [mpv](https://github.com/mpv-player/mpv) player under Windows, and should be put into the directory where the 'mpv.exe' is located. portable_config' folder, 

or mpv configuration under the default path '%APPDATA%/mpv/', this mode takes effect globally. 

'portable_config' overrides the global configuration scheme.

PS: When editing the configuration file by yourself, pay attention to the encoding format should be UTF-8 and the line break should be Unix, otherwise MPV may not recognize 

**mpv modpack download**:[Releases](https://github.com/dyphire/mpv-config/releases) 

### MPV client

- At present, there is no official client for MPV, and there are some recommended third-party compilations on the official website: [https://mpv.io/installation](https://mpv.io/installation)
  - Recommended for Shinkiro on Windows: [shinchiro_mpv](https://github.com/shinchiro/mpv-winbuild-cmake/releases)! [releases] (https://img.shields.io/github/v/release/shinchiro/mpv-winbuild-cmake)
  - Daily build: [zhongfly_mpv](https://github.com/zhongfly/mpv-winbuild) [![ releases](https://img.shields.io/github/v/release/zhongfly/mpv-winbuild)](https://github.com/zhongfly/mpv-winbuild/releases)
  - Based on a personal modified version [mpv](https://github.com/dyphire/mpv/tree/patch) build: [dyphire_mpv](https://github.com/dyphire/mpv-winbuild) [!] [releases] (https://img.shields.io/github/v/release/dyphire/mpv-winbuild)] (https://github.com/dyphire/mpv-winbuild/releases)
    - [Modified MPV Instructions](https://github.com/dyphire/mpv-config/discussions/7)
- At present, the more mature MPV/libmpv front-end recommendation: [mpv.net](https://github.com/mpvnet-player/mpv.net) [!] [mpv.net] (https://flat.badgen.net/github/last-commit/mpvnet-player/mpv.net?scale=1.0&cache=1800)] (https://github.com/mpvnet-player/mpv.net) [! [releases] (https://img.shields.io/github/v/release/mpvnet-player/mpv.net)] (https://github.com/mpvnet-player/mpv.net/releases)
	- Personal mpv.net profile reference: https://github.com/dyphire/mpv-config/tree/mpvnet
- The browser is recommended for invoking MPV playback
	- [mpv-handler](https://github.com/akiirui/mpv-handler) [play-with-mpv](https://greasyfork.org/zh-CN/scripts/416271-play-with-mpv)
	- [Play-With-MPV](https://github.com/LuckyPuppy514/Play-With-MPV)
- Singleton mode: [umpvw](https://github.com/SilverEzhik/umpvw)

### Script shader description
For details of the MPV scripts and functions used in this project, please refer to the wiki content: [Script Description-wiki](https://github.com/dyphire/mpv-config/wiki/ Script Description)

 see mpv.conf for the shaders involved in this project

### Preview

 ! [image-20231103224421000] (https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224421000.png)

! [image-20231103224540075] (https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224540075.png)

! [image-20231103224557019] (https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224557019.png)

|  Pinyin search (support initials) |   Subtitle download |
| ---------------- | ---------------- |
| ! [image] (https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224614449.png)   |  ! [image] (https://cdn.jsdelivr.net/gh/dyphire/PicGo/img/2023/11/03/image-20231103224721066.png) |


### Reference

* [hooke007 configuration manual](https://hooke007.github.io/mpv-lazy/mpv.html)
* [MPV Original Official Development Manual (English)] (https://mpv.io/manual/master/)
* [MPV Official Documentation of the Chinese Version -Hooke007](https://github.com/hooke007/mpv_doc-CN)