### This folder stores the corresponding setting files of the mpv script. 

 Usually the script setting file name has the same name as the script file it belongs to. Note that the `-` in the script file name needs to be translated into `_` by default. The actual settings are subject to the script developer's settings. 

 Do not beautify the format of the script settings file (such as adding meaningless spaces); do not comment after the parameters (comments should be written on a separate line). 

 The script and its settings file may not support Windows' CRLF line wrapping (try changing to LF). 

 The above situations may cause (part of) the script settings file to become invalid during the process of self-modification. 

 The following is the settings file used by the mpv built-in script: 

 ```
console.conf
osc.conf
stats.conf
ytdl_hook.conf
``` 


