**该文件夹下存放 mpv 的脚本**

以下为脚本及功能介绍

| 脚本名 | 简要说明 |
| --- | --- |
| adevice-list.lua | OSD高级音频设备菜单 |
| autoload.lua | 自动加载同级目录的文件（配置文件 [autoload.conf](../script-opts/autoload.conf)） |
| autodeint.lua        | 自动检测去交错（默认禁用，需快捷键启用）       |
| auto-save-state.lua | 每隔 1 分钟自动保存进度（而不是退出时），播放完毕时自动删除进度 |
| blacklist-extensions.lua         | mpv 直接拖放目录时的文件加载类型的黑/白名单 |
| change-refresh.lua   | 更改刷新率（依赖[nircmd](https://www.nirsoft.net/utils/nircmd.html) ，配置文件 [changerefresh.conf](../script-opts/changerefresh.conf)） |
| chapter_make_read.lua | 标记/制作/自动读取加载外部章节文件（配置文件 [chapter_make_read.conf](../script-opts/chapter_make_read.conf)）  |
| chapter-list.lua | OSD高级章节菜单（依赖 [scroll-list.lua](../script-modules/scroll-list.lua)） |
| chapterskip.lua | 跳过指定章节（配置文件 [chapterskip.conf](../script-opts/chapterskip.conf)） |
| copy_subortime.lua | 复制当前字幕内容或播放时间 |
| cycle-commands.lua | 快捷键循环切换命令，使用方法见脚本内说明 |
| delete-current-file.lua | 删除当前文件 |
| display-profiles.lua | 实现mpv窗口按显示器自动切换参数及配置文件，详见脚本内说明（配置文件 [display_profiles.conf](../script-opts/display_profiles.conf)） |
| drcbox.lua    | 使用并调整dynaudnorm过滤器混音的可视化脚本（配置文件 [drcbox.conf](../script-opts/drcboxp.conf)） |
| dynamic-crop.lua | 自动检测黑边并裁切（[autocrop.lua](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autocrop.lua) 改进版；配置文件 [dynamic_crop.conf](../script-opts/dynamic_crop.conf)） |
| editions-notification.lua | 如果检测到播放文件存在多个edition则在OSD上提示 |
| file-browser.lua | 内置文件浏览器（依赖 [user-input.lua](../scripts/user-input.lua); [user-input-module.lua](../script-modules/user-input-module.lua) ；配置文件 [file_browser.conf](../script-opts/file_browser.conf)） |
| fix-avsync.lua | 修复存在af过滤器时切换音轨和调整播放速度带来的视频冻结 |
| fuzzydir.lua | 外挂音轨/字幕路径检测增强（配置文件 [fuzzydir.conf](../script-opts/fuzzydir.conf)） |
| history-bookmark.lua | 记录并恢复视频目录播放记录（可确认是否恢复该目录上次播放进度; 配置文件 [history_bookmark.conf](../script-opts/history_bookmark.conf)） |
| locatefile.lua | 定位当前文件 |
| manager.lua | 一键更新指定脚本和着色器（配置文件 [manager.json](../manager.json)） |
| mpv-webp.lua | 剪切指定片段为 webp 动图（依赖 ffmpeg；配置文件 [webp.conf](../script-opts/webp.conf)） |
| open_dialog.lua | 快捷键载入文件/网址/其他字幕或音轨/高级次字幕                  |
| ordered-chapters-playlist.lua | 有序章节播放列表 |
| pause-indicator.lua | 在 mpv 暂停时在屏幕中间显示暂停图标 |
| persist_properties.lua | 保存预设值（如音量）（配置文件 [persist_properties.conf](../script-opts/persist_properties.conf)） |
| playlistmanager.lua | OSD高级播放列表（配置文件 [playlistmanager.conf](../script-opts/playlistmanager.conf)） |
| quality-menu.lua | ytdl 选择视频/音频质量的菜单脚本（依赖 yt-dlp/youtube-dl; 配置文件 [quality-menu.conf](../script-opts/quality-menu.conf)） |
| segment-linking.lua | 实现对 matroska [硬段链接](https://www.ietf.org/archive/id/draft-ietf-cellar-matroska-06.html#name-hard-linking) 的支持（依赖  [read-file.lua](../script-modules/read-file.lua)；配置文件 [segment_linking.conf](../script-opts/segment_linking.conf)） |
| slicing_copy.lua | 剪切视频片段（依赖 ffmpeg；配置文件 [slicing_copy.conf](../script-opts/slicing_copy.conf)） |
| skiptosilence.lua | 跳至播放文件的下一个静音位置（另类地实现跳 op/ed 的方法；配置文件 [skiptosilence.conf](../script-opts/skiptosilence.conf)） |
| sub_export.lua | 导出当前内封字幕（依赖 ffmpeg，脚本支持 srt、ass 和 sup 格式的字幕；配置文件 [sub_export.conf](../script-opts/sub_export.conf)） |
| simplebookmark.lua | 高级书签菜单（配置文件 [simplebookmark.conf](../script-opts/simplebookmark.conf)）；键位绑定均在同名配置文件中 |
| simplehistory.lua | 高级历史菜单，可恢复最后的播放记录并播放（配置文件 [simplehistory.conf](../script-opts/simplehistory.conf)）；键位绑定均在同名配置文件中 |
| smartcopypaste_II.lua        | 高级剪贴菜单，智能复制粘贴视频路径及进度（配置文件 [smartcopypaste_II.conf](../script-opts/smartcopypaste_II.conf)）；键位绑定均在同名配置文件中 |
| sub-fonts-dir-auto.lua | 在播放目录下自动指定`sub-fonts-dir`要使用的字体目录fonts以实现加载特定字体目录。**注意**：mpv必须以包含pr [mpv-player/#9856](https://github.com/mpv-player/mpv/pull/9856) 的版本编译方可使用此脚本，可在[Releases · dyphire/mpv-winbuild](https://github.com/dyphire/mpv-winbuild/releases)处下载 |
| sub-select.lua | 指定字幕轨道优先级/黑白名单（配置文件 [sub_select.conf](../script-opts/sub_select.conf)；[sub-select.json](../script-opts/sub-select.json)） |
| thumbnailer*.lua          | 缩略图引擎(依赖 [thumbnailer_osc.lua](../scripts/thumbnailer_osc.lua)；配置文件 [thumbnailer.conf](../script-opts/thumbnailer.conf)) |
| thumbnailer_osc.lua         | 缩略图引擎搭配的 OSC 界面（配置文件 [thumbnailer_osc.conf](../script-opts/thumbnailer_osc.conf)） |
| trackselect.lua               | 指定音频轨道优先级/黑白名单（配置文件 [trackselect.conf](../script-opts/trackselect.conf)） |
| undoredo.lua                  | 智能跳跃记录操作                                             |
| ytdl_hook_plus.lua    | 修改版 ytdl_hook 脚本，修复 http 请求头缺失（依赖yt-dlp/youtube-dl; 配置文件 [ytdl_hook_plus.conf](../script-opts/ytdl_hook_plus.conf)） |
| youtube-download.lua | ytdl 下载视频/音频/字幕/片段的脚本（依赖 yt-dlp/youtube-dl和ffmpeg; 配置文件 [youtube-download.conf](../script-opts/youtube-download.conf)） |
| autosubsync（组）         | 字幕同步菜单（依赖 ffmpeg, [ffsubsync](https://github.com/smacke/ffsubsync) or [alass](https://github.com/dyphire/alass) or both; 配置文件 [autosubsync.conf](../script-opts/autosubsync.conf)） |
| contextmenu_gui（组）         | 图形化右键菜单（依赖 tclkit，上游说明：https://github.com/hooke007/MPV_lazy/discussions/60; 配置文件 [contextmenu_gui.conf](../script-opts/contextmenu_gui.conf)） |
1. 部分脚本为**个人修改版本**，主要改进功能实现或键位绑定方式。如：autosubsync（组）; contextmenu_gui（组）; adevice-list.lua; autoload.lua; auto-save-state.lua; chapter_make_read.lua; chapter-list.lua; chapterskip.lua; copy_subortime.lua; drcbox.lua; editions-notification.lua; fix-avsync.lua; file-browser.lua; fuzzydir.lua; history-bookmark.lua; locatefile.lua; mpv-webp.lua; open_dialog.lua; persist_properties.lua; pause-indicator.lua; quality-menu.lua; slicing_copy.lua; sub_export.lua; simplebookmark.lua; simplehistory.lua; smartcopypaste_II.lua; skiptosilence.lua; trackselect.lua; thumbnailer*.lua
2. 所有脚本预绑定的`mp.add_key_binding`静态键位已被 [mpv.conf](../mpv.conf) 中的`input-default-bindings=no`参数屏蔽，可查看 [input.conf](../input.conf)  的"LUA 脚本"部分示例参考绑定所需键位  
   - 本配置绑定的快捷键及功能请参考 [快捷键说明.md](../快捷键说明.md) 文件
3. 部分脚本存在动态绑定键位，可查看对应脚本及配置文件相关部分（或[快捷键.md](../快捷键.md)中相关说明）
4. **MPV已知问题**：当 scripts 文件夹内脚本绑定的`mp.add_key_binding`总数超过一定阈值时，会导致 osc.lua 交互功能失效。本配置已针对该问题进行脚本优化

