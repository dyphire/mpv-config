### This folder stores configuration files for mpv scripts

Usually, the script configuration file name is the same as the script file it belongs to. Note that the `-` in the script filename needs to be escaped to `_` by default. The actual behavior depends on the script developer's settings.

Do not beautify the format of script configuration files (e.g., adding meaningless spaces); do not add comments after parameters (comments should be written on a separate line).

Scripts and their configuration files may not support Windows CRLF line endings (try changing to LF).

In the above cases, modifying the script configuration files yourself may cause them to become (partially) invalid.

The following are configuration files used by mpv's built-in scripts:


```
console.conf
osc.conf
stats.conf
ytdl_hook.conf
```

