-- This sets the action name in Reaper I believe
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")

-- Define the names of our two important tracks
local cueTrackName    = "CUE TRACK"
local masterTrackName = "MASTER TRACK"

-- Constants to make code more readable
local SOLOED     = 1
local RECEIVES   = -1
local SENDS      = 0
local POST_FADER = 0
local POST_FX    = 3


-- This function returns a track when passed a track name. Linear search.
-- Returns nil if no track is found
local function getTrackByName(inputName)
    local numTracks = reaper.CountTracks(0)
    for i = 0, numTracks - 1 do
        track = reaper.GetTrack(0, i)
        ret, trackName = reaper.GetTrackName(track)
        if trackName == inputName then
            return track
        end
    end
    return nil
end

-- This function returns an array of tracks that are solo'd
-- This function DISCLUDES AND DISABLES solo'ing of "master", master, and cue tracks
local function getSoloedTracks(cueTrack, masterTrack)
    soloedTracks = {}

    -- Unsolo the true master track.
    trueMasterTrack = reaper.GetMasterTrack()
    reaper.PreventUIRefresh(1)
    reaper.SetMediaTrackInfo_Value(trueMasterTrack, "I_SOLO", 0)
    reaper.PreventUIRefresh(-1)

    -- Check if any tracks are soloed
    if reaper.AnyTrackSolo() then
        local numTracks = reaper.CountTracks(0)
        for i = 0, numTracks - 1 do
            track = reaper.GetTrack(0, i)
            trackSoloValue = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")

            -- Check if this track is soloed. If this is our "master" track or cue track, disable it.
            -- If it is just a regular track, add it to our list of soloed tracks
            if trackSoloValue == SOLOED then
                if track == cueTrack then
                    reaper.PreventUIRefresh(1)
                    reaper.SetMediaTrackInfo_Value(cueTrack, "I_SOLO", 0)
                    reaper.PreventUIRefresh(-1)
                elseif track == masterTrack then
                    reaper.PreventUIRefresh(1)
                    reaper.SetMediaTrackInfo_Value(masterTrack, "I_SOLO", 0)
                    reaper.PreventUIRefresh(-1)
                else
                    table.insert(soloedTracks, track)
                end
            end
        end
    end
    return soloedTracks
end

-- Remove all the receives from the track given in the args
local function removeReceives(track)
    while (reaper.GetTrackNumSends(track, RECEIVES) > 0) do
        reaper.RemoveTrackSend(track, RECEIVES, 0)
    end
end

-- Create a main function
local function main()
    -- reaper.AnyTrackSolo()
    cueTrack    = getTrackByName(cueTrackName)
    masterTrack = getTrackByName(masterTrackName)

    reaper.PreventUIRefresh(1)

    -- Disable default solo in place
    reaper.SNM_SetIntConfigVar("soloip", 0)

    -- Make sure we have our two special tracks
    if cueTrack and masterTrack then

        -- Get our soloed tracks
        soloedTracks = getSoloedTracks(cueTrack, masterTrack)

        -- If this list is empty, remove all sends from the cue track
        -- then send the master track to the cue track post fader
        if rawequal(next(soloedTracks), nil) then
            removeReceives(cueTrack)
            sendIndex = reaper.CreateTrackSend(masterTrack, cueTrack)
            reaper.SetTrackSendInfo_Value(masterTrack, SENDS, sendIndex, "I_SENDMODE", POST_FADER)
        -- If not, remove every receive from the Cue Track...
        -- ... then, send every track that's soloed post fx to the cue track
        else
            removeReceives(cueTrack)
            for i,track in ipairs(soloedTracks) do
                sendIndex = reaper.CreateTrackSend(track, cueTrack)
                if not reaper.SetTrackSendInfo_Value(track, SENDS, sendIndex, "I_SENDMODE", POST_FX) then
                    reaper.ShowConsoleMsg("Failed!")
                end
            end
        end
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateTimeline()
end

main()
