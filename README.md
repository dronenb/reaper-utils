# True Cue
Set of Reascripts to create a more traditional style cue bus in REAPER. Essentially makes it so that soloing a track sends it post-fx to a bus entitled "CUE TRACK", which will not affect the master output (requires creating a fake "Master" track with solo defeat enabled). This eliminates problems when routing tracks through multiple buses prior to going to the "master" bus.

# Installation
To be added
# Usage
This requires you have two tracks, "CUE TRACK" and "MASTER TRACK". Solo defeat must be enabled on the "MASTER TRACK". If you wish, this "MASTER TRACK" can be routed to the main master track, but it is necessary to have it for the solo defeat functionality. When the solo button is pressed on any track except for the master track, it will send that track post-fx to the cue track. If no solo buttons are pressed, the "MASTER TRACK" will automatically be routed to the "CUE TRACK".