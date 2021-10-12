# True Cue
Set of Reascripts to create a more traditional style cue bus in REAPER. Essentially makes it so that soloing a track sends it post-fx to a bus entitled "CUE TRACK", which will not affect the master output (requires creating a fake "Master" track with solo defeat enabled). This eliminates problems when routing tracks through multiple buses prior to going to the "master" bus.

# Installation
For these ReaScripts to work, you must have [SWS](https://www.sws-extension.org/), [Ultraschall](https://forum.cockos.com/showthread.php?t=214539), and [Julian Sader's js_ReaScriptAPI](https://github.com/juliansader/ReaExtensions/tree/master/js_ReaScriptAPI/) installed. Then, import the two lua scripts in this repository to the action list. Then, copy the command ID of the "true_cue.lua" command and put it in the variable at the top of the "auto_true_cua.lua" file.
# Usage
This requires you have two tracks, "CUE TRACK" and "MASTER TRACK". Solo defeat must be enabled on the "MASTER TRACK". If you wish, this "MASTER TRACK" can be routed to the main master track, but it is necessary to have it for the solo defeat functionality. When the solo button is pressed on any track except for the master track, it will send that track post-fx to the cue track. If no solo buttons are pressed, the "MASTER TRACK" will automatically be routed to the "CUE TRACK".
