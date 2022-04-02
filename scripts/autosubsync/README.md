# autosubsync-mpv

Automatic subtitle synchronization script for [mpv](https://wiki.archlinux.org/index.php/Mpv).

A demo can be viewed on <a target="_blank" href="https://www.youtube.com/watch?v=w1vwnUiF6Bc"><img src="https://user-images.githubusercontent.com/69171671/115097010-4bd13c80-9f17-11eb-83e9-2583658f73bc.png" width="80px"></a>

Supported backends:
* [ffsubsync](https://github.com/smacke/ffsubsync)
* [alass](https://github.com/kaegi/alass)

## Installation

0. Make sure you have mpv v0.33 or higher installed.
    ```
    $ mpv --version
    ```
1. Install [FFmpeg](https://wiki.archlinux.org/index.php/FFmpeg):
    ```
    $ pacman -S ffmpeg
    ```
    Windows users have to manually install FFmpeg from [here](https://ffmpeg.zeranoe.com/builds/). 
2. Install your retiming program of choice,
[ffsubsync](https://github.com/smacke/ffsubsync), [alass](https://github.com/kaegi/alass) or both:
    ```
    $ pip install ffsubsync
    ```
    ```
    $ trizen -S alass-git # for Arch Linux users
    ```

3. Download the add-on and save it to your mpv scripts folder.

    | GNU/Linux | Windows |
    |---|---|
    | `~/.config/mpv/scripts` | `%AppData%\mpv\scripts\` | 
    
    To do it in one command:

    ```
    $ git clone 'https://github.com/Ajatt-Tools/autosubsync-mpv' ~/.config/mpv/scripts/autosubsync
    ```

## Configuration

You can skip this step if the add-on works out of the box.

Create a config file:

| GNU/Linux | Windows |
|---|---|
| `~/.config/mpv/script-opts/autosubsync.conf` | `%AppData%\mpv\script-opts\autosubsync.conf` | 

Example config:

```
# Absolute paths to the executables, if needed:

# 1. ffmpeg
ffmpeg_path=C:/Program Files/ffmpeg/bin/ffmpeg.exe
ffmpeg_path=/usr/bin/ffmpeg

# 2. ffsubsync
ffsubsync_path=C:/Program Files/ffsubsync/ffsubsync.exe
ffsubsync_path=/home/user/.local/bin/ffsubsync

# 3. alass
alass_path=C:/Program Files/ffmpeg/bin/alass.exe
alass_path=/usr/bin/alass

# Preferred retiming tool. Allowed options: 'ffsubsync', 'alass', 'ask'.
# If set to 'ask', the add-on will ask to choose the tool every time:

# 1. Preferred tool for syncing to audio.
audio_subsync_tool=ask
audio_subsync_tool=ffsubsync
audio_subsync_tool=alass

# 2. Preferred tool for syncing to another subtitle.
altsub_subsync_tool=ask
altsub_subsync_tool=ffsubsync
altsub_subsync_tool=alass

# Unload old subs (yes,no)
# After retiming, tell mpv to forget the original subtitle track.
unload_old_sub=yes
unload_old_sub=no
```

## Notes

* On Windows, you need to use forward slashes or double backslashes for your path.
For example, `"C:\\Users\\YourPath\\Scripts\\ffsubsync"`
or `"C:/Users/YourPath/Scripts/ffsubsync"`,
or it might not work.

* On GNU/Linux you can use `which ffsubsync` to find out where it is.
 
## Usage

When you have an out of sync sub, press `n` to synchronize it.

`ffsubsync` can typically take up to about 20-30 seconds
to synchronize (I've seen it take as much as 2 minutes
with a very large file on a lower end computer), so it
would probably be faster to find another, properly
synchronized subtitle with `autosub` or `trueautosub`.
Many times this is just not possible, as all available
subs for your specific language are out of sync.

Take into account that using this script has the
same limitations as `ffsubsync`, so subtitles that have
a lot of extra text or are meant for an entirely different 
version of the video might not sync properly. `alass` is supposed
to handle some edge cases better, but I haven't fully tested it yet,
obtaining similar results with both.

Note that the script will create a new subtitle file, in the same folder 
as the original, with the `_retimed` suffix at the end.

## Issues and feedback

If you are having trouble getting it to work or you've found a bug,
feel free to [join our community](https://tatsumoto-ren.github.io/blog/join-our-community.html) to ask directly.

Try to check if
[ffsubsync](https://github.com/smacke/ffsubsync)
or
[alass](https://github.com/kaegi/alass)
works properly outside of `mpv` first.
If the retiming tool of choice isn't working, `autosubsync` will likely fail.
