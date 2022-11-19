# simple-mpv-webui

[![Build Status](https://github.com/open-dynaMIX/simple-mpv-webui/workflows/Tests/badge.svg)](https://github.com/open-dynaMIX/simple-mpv-webui/actions?query=workflow%3ATests)
[![License](https://img.shields.io/badge/license-MIT-green)](https://opensource.org/licenses/MIT)

A web based user interface with controls for the [mpv mediaplayer](https://mpv.io/).

  * [Usage](#usage)
    + [Options](#options)
      - [port (int)](#port-int)
      - [ipv4 (bool)](#ipv4-bool)
      - [ipv6 (bool)](#ipv6-bool)
      - [disable (bool)](#disable-bool)
      - [logging (bool)](#logging-bool)
      - [osd_logging (bool)](#osd_logging-bool)
      - [audio_devices (string)](#audio_devices-string)
      - [static_dir](#static_dir)
      - [htpasswd_path](#htpasswd_path)
      - [collections](#collections)
    + [Setting options](#setting-options)
      - [CLI](#cli)
      - [mpv config file](#mpv-config-file)
      - [Webui config file](#webui-config-file)
    + [Authentication](#authentication)
  * [Dependencies](#dependencies)
    + [Linux](#linux)
    + [Windows](#windows)
    + [macOS](#macos)
  * [Screenshots](#screenshots)
  * [Key bindings](#key-bindings)
  * [Media Session API](#media-session-api)
    + [Playing other audio while using the webui on Android](#playing-other-audio-while-using-the-webui-on-android)
  * [Endpoints](#endpoints)
    + [List of endpoints](#list-of-endpoints)
    + [/api/status](#-api-status)
  * [Thanks](#thanks)
  * [Differences to mpv-web-ui](#differences-to-mpv-web-ui)
  * [Contributing](#contributing)

## Usage

For mpv>=v0.33.0 you can just clone/copy the whole repository into your mpv scripts
directory.

Alternatively you can also use the `--script` or `--scripts-append` option from mpv or
add something like `scripts-append=/path/to/simple-mpv-webui/` to `mpv.conf`.

<details>
  <summary>Installing for mpv &lt;v0.33.0</summary>

  Copy `webui.lua` and the `webui-page`-folder into your mpv scripts directory, mpv will
  then run it automatically.

  Alternatively you can also use the `--script` or `--scripts-append` option from mpv or
  add something like `scripts-append=/path/to/simple-mpv-webui/webui.lua` to `mpv.conf`.
  ---
</details>

See [dependencies](#dependencies) for more information about the installation.

You can access the webui when visiting [http://127.0.0.1:8080](http://127.0.0.1:8080) or
[http://[::1]:8080](http://[::1]:8080) in your webbrowser.

By default, it listens on `0.0.0.0:8080` and `[::0]:8080`. As described below, this can be changed.

### Options

Information about how to set options can be found [here](#setting-options).

#### port (int)
Set the port to serve the webui (default: 8080). Setting this allows for
running multiple instances on different ports.

Example:

```
webui-port=8000
```

#### ipv4 (bool)
Enable listening on ipv4 (default: yes)

Example:

```
webui-ipv4=no
```

#### ipv6 (bool)
Enable listening on ipv6 (default: yes)

Example:

```
webui-ipv6=no
```

#### disable (bool)
Disable webui (default: no)

Example:

```
webui-disable=yes
```

#### logging (bool)
Log requests to STDOUT (default: no)

Example:

```
webui-logging=yes
```

#### osd_logging (bool)
Log to OSD (default: yes)

Example:

```
webui-osd_logging=yes
```

#### audio_devices (string)
Set the audio-devices used for cycling. By default it uses all interfaces MPV 
knows of.

You can see a list of them with following command:

```shell
mpv --audio-device=help
```

Example:

```
webui-audio_devices="pulse/alsa_output.pci-0000_00_1b.0.analog-stereo pulse/alsa_output.pci-0000_00_03.0.hdmi-stereo"
```

#### static_dir

Configure the directory from which the static files should be served.

This is useful, if you want to use an alternative frontend.

The provided path may be absolute or relative.

Example:

```
webui-static_dir="/path/to/directory"
```

Content types are hardcoded into the server. If you miss something, please
[create an issue](https://github.com/open-dynaMIX/simple-mpv-webui/issues/new/choose) or - even better -
a pull request.

#### htpasswd_path

See [authentication](#authentication) below.

Example:

```
webui-htpasswd_path="/path/to/file"
```

Relative paths are searched relative to the program's current working directory,
so stick to absolute paths all the time.

Shortcuts to your homedir like `~/` are not supported.

#### collections

In order to use the basic file-browser API at `/api/collections`, the absolute paths of
to-be exposed directories need to be configured here (semicolon delimited). By default,
responses from `/api/collections` remain empty.

Example:

```
webui-collections="/home/user/Music;/home/user/Videos"
```

### Setting options

There are three ways to set an option for the webui. Please refer to the MPV
documentation for more details about this, as this is no feature of the webui.

#### CLI

If you want to set webui-options from the CLI, you need to pass them to `--script-opts`
or `--script-opts-add` respectively, like this: `--script-opts-add=webui-osd_logging=no`.

#### mpv config file

If you want to set webui-options in the main mpv config file, you need to write it like
this: `script-opts-add=webui-osd_logging=no`.

#### Webui config file

Finally, if you want to webui-options in their dedicated config file, you can put them
in a file `/path/to/mpv/user/dir/script-opts/webui.conf` (usually
`~/.config/mpv/script-opts/webui.conf` on Linux) like this: `osd_logging=no`.


### Authentication
There is a very simple implementation of
[Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication).

It can be enabled by providing the htpasswd file via the [htpasswd_path](#htpasswd_path) option.
The file does not need to be named `htpasswd`.

The provided file needs to contain data in the following format:

```
user1:password1
user2:password2
```

Only plaintext `.htpasswd` entries are supported.

## Dependencies

### Linux

 - [luasocket](https://github.com/diegonehab/luasocket)

### Windows

In [this repository](https://github.com/57op/simple-mpv-webui-windows-libs) you can find a guide,
build script and pre-built binaries.

Thanks to [@57op](https://github.com/57op) for providing this!

### macOS

Install luarocks:

```
brew install luarocks
```

Check lua version of your mpv instance.

```
mpv -v

...
--lua=51deb # <- this is your lua version
...
```

Proceed to install correct luasocket:

```
luarocks --lua-dir=/usr/local/opt/lua@5.1 install luasocket
```

Set correct path:

```
eval $(luarocks --lua-dir=/usr/local/opt/lua@5.1 path --bin)
```

## Screenshots
![webui screenshot](screenshots/webui.png#2)

![playlist screenshot](screenshots/playlist.png#1)

## Key bindings
There are some keybindings available:

| Key        | Function                     |
| ---------- | ---------------------------- |
| SPACE      | Play/Pause                   |
| ArrowRight | seek +10                     |
| ArrowLeft  | seek -10                     |
| ArrowUp    | seek +1min                   |
| ArrowDown  | seek -1min                   |
| PageDown   | seek +3                      |
| PageUp     | seek -3                      |
| 9          | decrease volume              |
| 0          | increase volume              |
| f          | toggle fullscreen            |
| n          | playlist next                |
| p          | playlist previous            |
| j          | cycle subtitles              |
| v          | toggle subtitle visibility   |
| [          | decrease playback speed      |
| ]          | increase playback speed      |
| {          | decrease playback speed more |
| }          | increase playback speed more |
| Backspace  | reset playback speed         |
| Escape     | hide current overlay         |
| ?          | toggle keyboard shortcuts    |

## Media Session API
When using a browser that supports it, simple-mpv-webui uses the Media Session
API to provide a notification with some metadata and controls:

![notification screenshot](screenshots/notification.png#1)

In order to have the notification work properly you need to at least once trigger play from the webui.

### Playing other audio while using the webui on Android
For the notification to work, the webui plays a silent audio file in a loop. This is
necessary in order for Chrome on Android to create such notification
([see](https://developers.google.com/web/updates/2017/02/media-session#implementation_notes)).
As soon as this silent mp3 is played, audio from other apps is paused automatically by Android.
The only way to prevent this from happening is to disable the notifications, which is
possible in the settings of the webui (client).

## Endpoints

### List of endpoints

| URI                                | Method | Parameter                                                                                              | Description                                                               |
| ---------------------------------- | ------ | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| /api/status                        | GET    |                                                                                                        | Returns JSON data about playing media --> see below                       |
| /api/play                          | POST   |                                                                                                        | Play media                                                                |
| /api/pause                         | POST   |                                                                                                        | Pause media                                                               |
| /api/toggle_pause                  | POST   |                                                                                                        | Toggle play/pause                                                         |
| /api/fullscreen                    | POST   |                                                                                                        | Toggle fullscreen                                                         |
| /api/quit                          | POST   |                                                                                                        | Quit the program                                                          |
| /api/add/:name/:value              | POST   | `string` and `int` or `float`                                                                          | Add `:value` (default of `1`) to the `:name` property                     |
| /api/cycle/:name/:value            | POST   | `string` and `up` or `down`                                                                            | Cycle `:name` by `:value` (default of `up`)                               |
| /api/multiply/:name/:value         | POST   | `string` and `int` or `float`                                                                          | Multiply `:name` by `:value`                                              |
| /api/set/:name/:value              | POST   | `string` and anything                                                                                  | Set `:name` to `:value`                                                   |
| /api/toggle/:name                  | POST   | `string`                                                                                               | Toggle the boolean property                                               |
| /api/seek/:seconds                 | POST   | `int` or `float` (can be negative)                                                                     | Seek                                                                      |
| /api/set_position/:seconds         | POST   |                                                                                                        | Go to position :seconds                                                   |
| /api/playlist_prev                 | POST   |                                                                                                        | Go to previous media in playlist                                          |
| /api/playlist_next                 | POST   |                                                                                                        | Go to next media in playlist                                              |
| /api/playlist_jump/:index          | POST   | `int`                                                                                                  | Jump to playlist item at position `:index`                                |
| /api/playlist_move/:source/:target | POST   | `int` and `int`                                                                                        | Move playlist item from position `:source` to position `:target`          |
| /api/playlist_move_up/:index       | POST   | `int`                                                                                                  | Move playlist item at position `:index` one position up                   |
| /api/playlist_remove/:index        | POST   | `int`                                                                                                  | Remove playlist item at position `:index`                                 |
| /api/playlist_shuffle              | POST   |                                                                                                        | Shuffle the playlist                                                      |
| /api/loop_file/:mode               | POST   | `string` or `int`                                                                                      | Loop the current file. `:mode` accepts the same loop modes as mpv         |
| /api/loop_playlist/:mode           | POST   | `string` or `int`                                                                                      | Loop the whole playlist `:mode` accepts the same loop modes as mpv        |
| /api/add_chapter/:amount           | POST   | `int` (can be negative)                                                                                | Jump `:amount` chapters in current media                                  |
| /api/add_volume/:percent           | POST   | `int` or `float` (can be negative)                                                                     | Add :percent% volume                                                      |
| /api/set_volume/:percent           | POST   | `int` or `float`                                                                                       | Set volume to :percent%                                                   |
| /api/add_sub_delay/:ms             | POST   | `int` or `float` (can be negative)                                                                     | Add :seconds seconds subtitles delay                                      |
| /api/set_sub_delay/:ms             | POST   | `int` or `float` (can be negative)                                                                     | Set subtitles delay to :ms milliseconds                                   |
| /api/add_audio_delay/:seconds      | POST   | `int` or `float` (can be negative)                                                                     | Add :seconds seconds audio delay                                          |
| /api/set_audio_delay/:seconds      | POST   | `int` or `float` (can be negative)                                                                     | Set audio delay to :seconds milliseconds                                  |
| /api/cycle_sub                     | POST   |                                                                                                        | Cycle trough available subtitles                                          |
| /api/cycle_audio                   | POST   |                                                                                                        | Cycle trough available audio tracks                                       |
| /api/cycle_audio_device            | POST   |                                                                                                        | Cycle trough audio devices. [More information.](#audio-devices-string)    |
| /api/speed_set/:speed              | POST   | `int` or `float`                                                                                       | Set playback speed to `:speed` (defaults to `1` for quick reset)          |
| /api/speed_adjust/:amount          | POST   | `int` or `float`                                                                                       | Multiply playback speed by `:amount` (where `1.0` is no change)           |
| /api/loadfile/:path/:mode          | POST   | :path URL encoded `string` <br />:mode `string`  options: `replace` (default), `append`, `append-play` | Load file to playlist. Together with youtube-dl, this also works for URLs |
| /api/collections/:path             | GET    | If no :path is provided, the configured collections are returned.                                      | List directories and files (see [collections](#collections))              |


All POST endpoints return a JSON message. If successful: `{"message": "success"}`, otherwise, the message will contain
information about the error.

### /api/status
`metadata` contains all the metadata mpv can see, below is just an example:

``` json
{
    "audio-delay": 0,        # <-- milliseconds
    "audio-devices": [
        {"active": true, "description": "Autoselect device", "name": "auto"},
        {"active": false, "description": "Default (alsa)", "name": "alsa"},
        {"active": false, "description": "Default (jack)", "name": "jack"},
        {"active": false, "description": "Default (sdl)", "name": "sdl"},
        {"active": false, "description": "Default (sndio)", "name": "sndio"},
    ],
    "chapter": 0,            # <-- current chapter
    "chapters": 0,           # <-- chapters count
    "chapter-list": [        # Array length == "chapters".
        {
            "title": "Chapter 0",
            "time": 0,       # <-- start time in seconds
        },
    ],
    "duration": 6.024,       # <-- seconds
    "end": null,             # <-- seconds as string or null
    "filename": "01 - dummy.mp3",
    "fullscreen": false,
    "loop-file": false,      # <-- false, true or integer
    "loop-playlist": false,  # <-- false, `inf`, `force` or integer
    "metadata": {            # <-- all metadata available to MPV
        "album": "Dummy Album",
        "artist": "Dummy Artist",
        "comment": "0",
        "date": "2020",
        "encoder": "Lavc57.10",
        "genre": "Jazz",
        "title": "First dummy",
    },
    "pause": true,
    "playlist": [
        {
            "current": true,
            "filename": "./environment/test_media/01 - dummy.mp3",
            "id": 1,
            "playing": true,
        },
        {"filename": "./environment/test_media/02 - dummy.mp3", "id": 2},
        {"filename": "./environment/test_media/03 - dummy.mp3", "id": 3},
    ],
    "position": -0.0,        # <-- seconds
    "remaining": 6.024,      # <-- seconds
    "speed": 1,              # <-- multiplier
    "start": null,           # <-- seconds as string or null
    "sub-delay": 0,          # <-- milliseconds
    "track-list": [          # <-- all available video, audio and sub tracks
        {
            "albumart": false,
            "audio-channels": 2,
            "codec": "mp3",
            "decoder-desc": "mp3float (MP3 (MPEG audio layer 3))",
            "default": false,
            "demux-channel-count": 2,
            "demux-channels": "stereo",
            "demux-samplerate": 48000,
            "dependent": false,
            "external": false,
            "ff-index": 0,
            "forced": false,
            "id": 1,
            "image": false,
            "main-selection": 0,
            "selected": true,
            "src-id": 0,
            "type": "audio",
        }
    ],
    "volume": 0,
    "volume-max": 130,
}
```

## Thanks
Thanks to [makedin](https://github.com/makedin) for his work on this.

## Differences to mpv-web-ui
 - More media controls
 - Playlist controls
 - Some styles and font-awesome
 - ipv6 support
 - Option to set the port being used (defaults to 8080)
 - Using the Media Session API

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
