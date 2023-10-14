**The mpv script is stored in this folder**

| Scripts name | A brief description |
| --- | --- |
| autosubsync (group)* | Subtitle sync menu  (depends on ffmpeg, [ffsubsync](https://github.com/smacke/ffsubsync) or [alass](https://github.com/dyphire/alass) or both; configuration file: [autosubsync.conf](../script-opts/autosubsync.conf)) |
| mpv-taskbar-buttons (group)* | Implement taskbar media control buttons for mpv (depends on [libtcc.dll](https://github.com/qwerty12/mpv-taskbar-buttons/blob/master/libtcc.dll); configuration file: [mpv-taskbar-buttons.conf](../script-opts/mpv-taskbar-buttons.conf)) |
| simple-mpv-webui (group)* | Implement a simple webui for mpv (depends on [luasocket](https://github.com/57op/simple-mpv-webui-windows-libs) ; configuration file: [webui.conf](../script-opts/webui.conf)) |
| uosc* (group) | Third-party advanced OSC script, which implements many practical functions (configuration file: [uosc.conf](../script-opts/uosc.conf)) |
| autoload.lua* | Automatically load files in the same directory (configuration file: [autoload.conf](../script-opts/autoload.conf)) |
| autodeint.lua      | Automatically detect and switch deinterlacing |
| auto-save-state.lua* | Automatically save the playback progress every 1 minute (rather than when exiting), and automatically delete the progress when the playback is completed |
| blacklist-extensions.lua         | mpv Black/white list of file loading types when dragging and dropping directories directly |
| change-refresh.lua   | Change the monitor refresh rate (depends on [nircmd](https://www.nirsoft.net/utils/nircmd.html) ，configuration file: [changerefresh.conf](../script-opts/changerefresh.conf)) |
| chapter-make-read.lua* | Mark/make/automatically read and load external chapter files (configuration file: [chapter_make_read.conf](../script-opts/chapter_make_read.conf)) |
| chapter-list.lua* | OSD interactive chapter menu (depends on [scroll-list.lua](../script-modules/scroll-list.lua)) |
| chapterskip.lua* | Automatically skip specified chapters (configuration file: [chapterskip.conf](../script-opts/chapterskip.conf)) |
| copyStuff.lua* | Select to copy the current file information (from: [0xR3V/mpv-copyStuff](https://github.com/0xR3V/mpv-copyStuff)) |
| cycle-commands.lua | Shortcut keys cycle to switch commands. Please see the instructions in the script for how to use it. |
| delete-current-file.lua* | Delete the currently playing file (Windows can restore it in the Recycle Bin) |
| display-name.lua* | Implement the mpv window to automatically switch parameters and configuration files according to the monitor name. For details, see the instructions in the script (depends on MultiMonitorTool.exe) |
| drcbox.lua*   | Visual script for using and adjusting the dynaudnorm filter mix (configuration file: [drcbox.conf](../script-opts/drcboxp.conf)) |
| dynamic-crop.lua* | Automatically detect variable black borders and crop (improved version of [autocrop.lua](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autocrop.lua); configuration file: [dynamic_crop.conf](../script-opts/dynamic_crop.conf)) |
| evafast.lua | Implement a more advanced speed-doubling function than mpv's built-in one, which will slow down when encountering subtitles (non-embedded) (configuration file: [evafast.conf](../script-opts/evafast.conf)) |
| file-browser.lua* | OSD interactive file browser (depends on [user-input.lua](../scripts/user-input.lua); [user-input-module.lua](../script-modules/user-input-module.lua) ; configuration file: [file_browser.conf](../script-opts/file_browser.conf)) |
| fix-avsync.lua* | Fixed the issue of video freezing and lag when switching audio tracks |
| fuzzydir.lua* | Enhanced path detection and configuration of external audio tracks/subtitles (configuration file: [fuzzydir.conf](../script-opts/fuzzydir.conf)) |
| history-bookmark.lua* | Record and restore the video directory playback record (you can confirm whether to restore the last playback progress of the directory; configuration file: [history_bookmark.conf](../script-opts/history_bookmark.conf)) |
| inputevent.lua | It can be used to enhance the key binding function in input.conf. For specific usage and examples, see the script warehouse description: InputEvent](https://github.com/Natural-Harmonia-Gropius/InputEvent) |
| manager.lua | Update specified scripts and shaders with one click (configuration file: [manager.json](../manager.json)) |
| mpv_sort_script.lua* | Implement advanced sorting capabilities when loading directories directly using mpv: name, date, size and random sorting (configuration file: [mpv_sort_script.conf](../script-opts/mpv_sort_script.conf)) |
| mpv-animated.lua* | Cut the specified fragment into a webp/gif animation (depends on ffmpeg; configuration file: [mpv_animated.conf](../script-opts/mpv_animated.conf)) |
| notify_media.lua* | Implement SMTC on Windows based on IPC pipeline (depends on [MPVMediaControl.exe](https://github.com/datasone/MPVMediaControl/releases); configuration file: [notify_media.conf](../script-opts/notify_media.conf)) |
| ordered-chapters-playlist.lua | Ordered Chapter Playlist |
| persist_properties.lua | Monitor and save global changes in preset parameters (such as volume) (configuration file: [persist_properties.conf](../script-opts/persist_properties.conf)) |
| playlistmanager.lua* | OSD interactive playlist (configuration file: [playlistmanager.conf](../script-opts/playlistmanager.conf)) |
| playlistmanager-save-interactive.lua | Enhanced script for playlistmanager.lua to rename playlists when saving |
| quality-menu.lua* | Switch the OSD interactive menu of ytdl video/audio quality (depends on yt-dlp/youtube-dl; configuration file: [quality-menu.conf](../script-opts/quality-menu.conf)) |
| recentmenu.lua* | Simple playback history menu integrated with uosc (depends on uosc; configuration file: [recentmenu.conf](../script-opts/recentmenu.conf)) |
| segment-linking.lua | Implement support for matroska [hard segment linking](https://www.ietf.org/archive/id/draft-ietf-cellar-matroska-06.html#name-hard-linking)  (depends on  [read-file.lua](../script-modules/read-file.lua), `mkvinfo`; configuration file: [segment_linking.conf](../script-opts/segment_linking.conf)) |
| simplebookmark.lua* | OSD interactive bookmark menu (configuration file: [simplebookmark.conf](../script-opts/simplebookmark.conf)); dynamic key bindings are in the configuration file of the same name |
| simplehistory.lua* | OSD interactive history menu, which can restore and play the last playback record (configuration file: [simplehistory.conf](../script-opts/simplehistory.conf)); dynamic key bindings are in the configuration file of the same name |
| skiptosilence.lua | It can jump to the next silent position of the currently playing file (an alternative method of jumping op/ed; configuration file: [skiptosilence.conf](../script-opts/skiptosilence.conf)) |
| slicing_copy.lua* | Cut video clips (depends on ffmpeg; configuration file: [slicing_copy.conf](../script-opts/slicing_copy.conf)) |
| smartcopypaste_II.lua*       | OSD interactive clipping menu, smart copy and paste video path and progress (configuration file: [smartcopypaste_II.conf](../script-opts/smartcopypaste_II.conf)); dynamic key bindings are in the configuration file of the same name |
| sponsorblock_minimal.lua | Skip sponsored segments of YouTube videos (depends on curl; configuration file: [sponsorblock_minimal.conf](../script-opts/sponsorblock_minimal.conf)) |
| sub_export.lua* | Export the inner subtitles of the current video (depends on ffmpeg, supports subtitles in srt,ass and sup formats; configuration file: [sub_export.conf](../script-opts/sub_export.conf)) |
| sub-fonts-dir-auto.lua* | Automatically find the fonts subdirectory in the playback directory and write the `sub-fonts-dir` parameter to automatically load a specific font path |
| sub-select.lua | Specify subtitle track priority/black and white list (configuration file: [sub_select.conf](../script-opts/sub_select.conf); [sub-select.json](../script-opts/sub-select.json)) |
| thumbfast.lua   | High-performance dynamic thumbnails for mpv, which need to be integrated in the OSC class script (configuration file: [thumbfast.conf](../script-opts/thumbfast.conf)) |
| track-list.lua* | OSD interactive track menu (configuration file: [track_list.conf](../script-opts/track_list.conf)) |
| trackselect.lua*              | Specify audio track priority/blacklist and whitelist (configuration file: [trackselect.conf](../script-opts/trackselect.conf)) |
| undoredo.lua                  | Intelligent jump recording operation can be realized |
| [webtorrent.js](https://github.com/mrxdst/webtorrent-mpv-hook/blob/master/src/webtorrent.ts) | Add `magnet:?` magnet link support to mpv, which can be played while downloading. [Instructions for use](https://github.com/mrxdst/webtorrent-mpv-hook/blob/master/README.md) (depends on [webtorrent-mpv-hook](https://github.com/mrxdst/webtorrent-mpv-hook); configuration file: [webtorrent.conf](../script-opts/webtorrent.conf)) |
| youtube-download.lua* | Download ytdl video/audio/subtitles/clips (depends on yt-dlp/youtube-dl and ffmpeg; configuration file: [youtube-download.conf](../script-opts/youtube-download.conf)) |

1. Some scripts marked `*` are personally modified versions or self-built scripts.
2. The `mp.add_key_binding` static keys pre-bound by all scripts have been blocked by the `input-default-bindings=no` parameter in [mpv.conf](../mpv.conf).
3. Some scripts have dynamic key bindings. You can check the corresponding scripts and relevant parts of the configuration file
4. **Known issue with MPV**：When the total number of `mp.add_key_binding` bound to scripts in the scripts folder exceeds a certain threshold, the osc.lua interactive function will fail. This configuration has been script optimized to address this issue
