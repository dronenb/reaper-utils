-- @version 1.0.0
-- @author Ben Dronen
-- @description Records at end of timeline and drops marker if already recording
-- @about Records at end of timeline and drops marker if already recording

local proj = 0 -- The active project window
local state = reaper.GetPlayStateEx(proj)
if state == 0 or state == 1 or state == 2 or state == 6 then  -- The project is currently stopped, playing, paused, or paused and recording
    reaper.OnStopButton()
    local current_length = reaper.GetProjectLength(proj)
    reaper.SetEditCurPos2(proj, current_length + 5, true, true)
    reaper.Main_OnCommand(1013, proj)
elseif state == 5 or state == 4 then  -- The project is currently playing and recording or just recording (which isn't possible maybe?)
    reaper.Main_OnCommand(40157, proj)
end
