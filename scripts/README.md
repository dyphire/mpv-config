**该文件夹下存放 mpv 的脚本**

以下为脚本及功能介绍

| 脚本名 | 简要说明 |
| --- | --- |
| autosubsync（组）* | 字幕同步菜单（依赖 ffmpeg, [ffsubsync](https://github.com/smacke/ffsubsync) or [alass](https://github.com/dyphire/alass) or both; 配置文件 [autosubsync.conf](../script-opts/autosubsync.conf)） |
| mpv-taskbar-buttons（组）* | 为 mpv 实现任务栏媒体控制按钮（依赖 [libtcc.dll](https://github.com/qwerty12/mpv-taskbar-buttons/blob/master/libtcc.dll); 配置文件 [mpv-taskbar-buttons.conf](../script-opts/mpv-taskbar-buttons.conf)） |
| simple-mpv-webui（组）* | 为 mpv 实现一个简单的 webui（依赖 [luasocket](https://github.com/57op/simple-mpv-webui-windows-libs) ; 配置文件 [webui.conf](../script-opts/webui.conf)） |
| uosc*（组） | 第三方高级 OSC 脚本，实现了许多实用功能（配置文件 [uosc.conf](../script-opts/uosc.conf)） |
| autoload.lua* | 自动加载同级目录的文件（配置文件 [autoload.conf](../script-opts/autoload.conf)） |
| autodeint.lua*      | 自动检测并切换去交错 |
| auto-save-state.lua* | 每隔 1 分钟自动保存播放进度（而不是退出时），播放完毕时自动删除进度 |
| blacklist-extensions.lua         | mpv 直接拖放目录时的文件加载类型的黑/白名单 |
| change-refresh.lua   | 更改显示器刷新率（依赖 [nircmd](https://www.nirsoft.net/utils/nircmd.html) ，配置文件 [changerefresh.conf](../script-opts/changerefresh.conf)） |
| chapter-make-read.lua* | 标记/制作/自动读取并加载外部章节文件（配置文件 [chapter_make_read.conf](../script-opts/chapter_make_read.conf)） |
| chapter-list.lua* | OSD 交互式章节菜单（依赖 [scroll-list.lua](../script-modules/scroll-list.lua)） |
| chapterskip.lua* | 可实现自动跳过指定章节（配置文件 [chapterskip.conf](../script-opts/chapterskip.conf)） |
| copyStuff.lua* | 选择复制当前文件信息（源自：[0xR3V/mpv-copyStuff](https://github.com/0xR3V/mpv-copyStuff)） |
| cycle-commands.lua | 快捷键循环切换命令，使用方法见脚本内说明 |
| delete-current-file.lua* | 删除当前播放文件（windows 可在回收站恢复） |
| display-name.lua* | 实现 mpv 窗口按显示器名称自动切换参数及配置文件，详见脚本内说明（依赖 MultiMonitorTool.exe） |
| drcbox.lua*   | 使用并调整 dynaudnorm 过滤器混音的可视化脚本（配置文件 [drcbox.conf](../script-opts/drcboxp.conf)） |
| dynamic-crop.lua* | 自动检测可变化黑边并裁切（[autocrop.lua](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autocrop.lua) 改进版；配置文件 [dynamic_crop.conf](../script-opts/dynamic_crop.conf)） |
| evafast.lua | 实现比 mpv 内置更高级的倍速功能，遇到字幕（非内嵌）时会减缓速度（配置文件 [evafast.conf](../script-opts/evafast.conf)） |
| file-browser.lua* | OSD 交互式文件浏览器（依赖 [user-input.lua](../scripts/user-input.lua); [user-input-module.lua](../script-modules/user-input-module.lua) ；配置文件 [file_browser.conf](../script-opts/file_browser.conf)） |
| fix-avsync.lua* | 修复切换音轨时伴随的视频冻结卡顿的问题 |
| fuzzydir.lua* | 增强外挂音轨/字幕的路径检测及配置（配置文件 [fuzzydir.conf](../script-opts/fuzzydir.conf)） |
| history-bookmark.lua* | 记录并恢复视频目录播放记录（可确认是否恢复该目录上次播放进度; 配置文件 [history_bookmark.conf](../script-opts/history_bookmark.conf)） |
| inputevent.lua | 可用于增强 input.conf 中的键位绑定功能，具体用法及示例见脚本仓库说明：[InputEvent](https://github.com/Natural-Harmonia-Gropius/InputEvent) |
| manager.lua | 一键更新指定脚本和着色器（配置文件 [manager.json](../manager.json)） |
| mpv_sort_script.lua* | 使用 mpv 直接加载目录时实现高级排序功能：名称、日期、大小和随机排序（配置文件 [mpv_sort_script.conf](../script-opts/mpv_sort_script.conf)） |
| mpv-animated.lua* | 剪切指定片段为 webp/gif 动图（依赖 ffmpeg；配置文件 [mpv_animated.conf](../script-opts/mpv_animated.conf)） |
| notify_media.lua* | 基于 IPC 管道实现 SMTC 功能（依赖 [MPVMediaControl.exe](https://github.com/datasone/MPVMediaControl/releases)；配置文件 [notify_media.conf](../script-opts/notify_media.conf)） |
| ordered-chapters-playlist.lua | 有序章节播放列表 |
| persist_properties.lua | 监视并保存预设参数的全局变化值（如音量）（配置文件 [persist_properties.conf](../script-opts/persist_properties.conf)） |
| playlistmanager.lua* | OSD 交互式播放列表（配置文件 [playlistmanager.conf](../script-opts/playlistmanager.conf)） |
| playlistmanager-save-interactive.lua | 用于 playlistmanager.lua 保存播放列表时进行重命名操作的增强性脚本 |
| quality-menu.lua* | 切换 ytdl 视频/音频质量的 OSD 交互式菜单（依赖 yt-dlp/youtube-dl; 配置文件 [quality-menu.conf](../script-opts/quality-menu.conf)） |
| recentmenu.lua* | 与 uosc 集成的简单播放历史菜单（依赖 uosc; 配置文件 [recentmenu.conf](../script-opts/recentmenu.conf)） |
| segment-linking.lua | 实现对 matroska [硬段链接](https://www.ietf.org/archive/id/draft-ietf-cellar-matroska-06.html#name-hard-linking) 的支持（依赖  [read-file.lua](../script-modules/read-file.lua), `mkvinfo`；配置文件 [segment_linking.conf](../script-opts/segment_linking.conf)） |
| simplebookmark.lua* | OSD 交互式书签菜单（配置文件 [simplebookmark.conf](../script-opts/simplebookmark.conf)）；动态键位绑定在同名配置文件中 |
| simplehistory.lua* | OSD 交互式历史菜单，可恢复最后的播放记录并播放（配置文件 [simplehistory.conf](../script-opts/simplehistory.conf)）；动态键位绑定在同名配置文件中 |
| skiptosilence.lua | 可实现跳至当前播放文件的下一个静音位置（另类地实现跳 op/ed 的方法；配置文件 [skiptosilence.conf](../script-opts/skiptosilence.conf)） |
| slicing_copy.lua* | 剪切视频片段（依赖 ffmpeg；配置文件 [slicing_copy.conf](../script-opts/slicing_copy.conf)） |
| smartcopypaste_II.lua*       | OSD 交互式剪贴菜单，智能复制粘贴视频路径及进度（配置文件 [smartcopypaste_II.conf](../script-opts/smartcopypaste_II.conf)）；动态键位绑定在同名配置文件中 |
| sponsorblock_minimal.lua | 跳过 YouTube 视频的赞助片段（依赖 curl；配置文件 [sponsorblock_minimal.conf](../script-opts/sponsorblock_minimal.conf)） |
| sub_export.lua* | 导出当前视频的内封字幕（依赖 ffmpeg，脚本支持 srt、ass 和 sup 格式的字幕；配置文件 [sub_export.conf](../script-opts/sub_export.conf)） |
| sub-fonts-dir-auto.lua* | 在播放目录下自动查找 fonts 子目录并写入 `sub-fonts-dir` 参数以实现自动加载特定字体路径 |
| sub-select.lua | 指定字幕轨道优先级/黑白名单（配置文件 [sub_select.conf](../script-opts/sub_select.conf)；[sub-select.json](../script-opts/sub-select.json)） |
| thumbfast.lua   | 适用于 mpv 的高性能动态缩略图，需在 OSC 类脚本中自行集成（配置文件 [thumbfast.conf](../script-opts/thumbfast.conf)） |
| track-list.lua* | OSD 交互式轨道菜单（配置文件 [track_list.conf](../script-opts/track_list.conf)） |
| trackselect.lua*              | 指定音频轨道优先级/黑白名单（配置文件 [trackselect.conf](../script-opts/trackselect.conf)） |
| undoredo.lua                  | 可实现智能跳跃记录操作 |
| [webtorrent.js](https://github.com/mrxdst/webtorrent-mpv-hook/blob/master/src/webtorrent.ts) | 为 mpv 添加`magnet:?`磁力链接支持，可边下边播，[使用说明](https://github.com/mrxdst/webtorrent-mpv-hook/blob/master/README.md)（依赖 [webtorrent-mpv-hook](https://github.com/mrxdst/webtorrent-mpv-hook); 配置文件 [webtorrent.conf](../script-opts/webtorrent.conf)） |
| youtube-download.lua* | 下载 ytdl 视频/音频/字幕/片段（依赖 yt-dlp/youtube-dl和ffmpeg; 配置文件 [youtube-download.conf](../script-opts/youtube-download.conf)） |

1. 标记`*`号的部分脚本为**个人修改版或自建脚本**。
2. 所有脚本预绑定的`mp.add_key_binding`静态键位已被 [mpv.conf](../mpv.conf) 中的`input-default-bindings=no`参数屏蔽，可查看 [input.conf](../input.conf)  的"LUA 脚本"部分示例参考绑定所需键位  
   - 本配置绑定的快捷键及功能请参考 [快捷键说明.md](../快捷键说明.md) 文件
3. 部分脚本存在动态绑定键位，可查看对应脚本及配置文件相关部分（或 [快捷键说明.md](../快捷键说明.md) 中相关说明）
4. **MPV已知问题**：当 scripts 文件夹内脚本绑定的`mp.add_key_binding`总数超过一定阈值时，会导致 osc.lua 交互功能失效。本配置已针对该问题进行脚本优化
