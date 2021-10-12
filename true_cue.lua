-- Define the names of our two important tracks
local cueTrackName    = "CUE TRACK"
local masterTrackName = "MASTER TRACK"

-- Constants to make code more readable
local NOT_SOLOED            = 0
local SOLOED                = 1
local SOLOED_IN_PLACE       = 2
local SAFE_SOLOED           = 5
local SAFE_SOLOED_IN_PLACE  = 6 -- <--- This should NOT be used, since we disable default SIP in the init() function
local RECEIVES              = -1
local SENDS                 = 0
local POST_FADER            = 0
local POST_FX               = 3

-- Function to get the length of a table
local function tableLength(T)
    local count = 0
    if next(T) == nil then
        return count
    end

    for _ in pairs(T) do count = count + 1 end
    return count
end

-- Function to compare two arrays
local function compare(array1, array2)
    if tableLength(array1) ~= tableLength(array2) then
        return false
    end
    for i,v in pairs(array1) do
        if v ~= array2[i] then
            return false
        end
    end
    return true
end

-- Function to copy one array into another in place
local function shallowCopy(sourceArray, destArray)
    -- Remove everything in the desination array
    for k in pairs(destArray) do
        destArray[k] = nil
    end

    -- Put everything from sourceArray into destArray
    for i,v in ipairs(sourceArray) do
        destArray[i] = v
    end
end

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
local function trackSoloStatus()
    local trackSoloStatusArray = {}

    for i = 0, reaper.CountTracks(0) - 1 do
        -- Do index i+1 since lua indexes starting at 1 by default
        trackSoloStatusArray[i+1] = reaper.GetMediaTrackInfo_Value(reaper.GetTrack(0, i), "I_SOLO")
    end
    return trackSoloStatusArray
end

-- Return an array of tracks that are soloed from the trackSoloStatusArray
local function getSoloedTracks(trackSoloStatusArray)
    soloedTracks = {}
    for i, v in ipairs(trackSoloStatusArray) do
        if v == SOLOED then
            table.insert(soloedTracks, reaper.GetTrack(0, i - 1))
        end
    end
    return soloedTracks
end

-- Function to check to see if solo change occurred. Uses previousSoloedTracks as shared memory
local function checkSoloChange (previousTrackSoloStatusArray)
    cueTrack    = getTrackByName(cueTrackName)
    masterTrack = getTrackByName(masterTrackName)

    -- Make SURE our special tracks are not soloed.
    reaper.PreventUIRefresh(1)
    reaper.SetMediaTrackInfo_Value(reaper.GetMasterTrack(), "I_SOLO", 0)
    if cueTrack then
        reaper.SetMediaTrackInfo_Value(getTrackByName(cueTrackName), "I_SOLO", 0)
    end

    if masterTrack then
        reaper.SetMediaTrackInfo_Value(getTrackByName(masterTrackName), "I_SOLO", 0)
    end
    reaper.PreventUIRefresh(-1)

    -- Get the currently soloed tracks
    local trackSoloStatusArray = trackSoloStatus()

    -- Compare the array in memory to the array of currently soloed tracks
    local is_change = not(compare(previousTrackSoloStatusArray, trackSoloStatusArray))

    -- If a change has occurred, we need to update the shared memory for the next time this runs
    if is_change then
        shallowCopy(trackSoloStatusArray, previousTrackSoloStatusArray)
    end

    -- Return our boolean
    return is_change
end

-- Remove all the receives from the track given in the args
local function removeReceives(track)
    while (reaper.GetTrackNumSends(track, RECEIVES) > 0) do
        reaper.RemoveTrackSend(track, RECEIVES, 0)
    end
end

local function updateCueBus(trackSoloStatusArray)
    local cueTrack    = getTrackByName(cueTrackName)
    local masterTrack = getTrackByName(masterTrackName)

    reaper.PreventUIRefresh(1)

    -- Make sure we have our two special tracks
    if cueTrack and masterTrack then
        -- Get our array of soloed tracks
        local soloedTracks = getSoloedTracks(trackSoloStatusArray)
        -- If this list is empty, remove all sends from the cue track
        -- then send the master track to the cue track post fader
        if rawequal(next(soloedTracks), nil) then
            removeReceives(cueTrack)
            local sendIndex = reaper.CreateTrackSend(masterTrack, cueTrack)
            reaper.SetTrackSendInfo_Value(masterTrack, SENDS, sendIndex, "I_SENDMODE", POST_FADER)
        -- If not, remove every receive from the Cue Track...
        -- ... then, send every track that's soloed post fx to the cue track
        else
            removeReceives(cueTrack)
            for i, track in ipairs(soloedTracks) do
                local sendIndex = reaper.CreateTrackSend(track, cueTrack)
                reaper.SetTrackSendInfo_Value(track, SENDS, sendIndex, "I_SENDMODE", POST_FX)
            end
        end
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateTimeline()
end

local function main()
    updateCueBus(trackSoloStatus())
end

local function init()
    -- Disable default solo in place
    reaper.SNM_SetIntConfigVar("soloip", 0)

    -- Make sure we have our cue and master tracks
    local cueTrack    = getTrackByName(cueTrackName)
    local masterTrack = getTrackByName(masterTrackName)

    if cueTrack and masterTrack then
        main()
    else
        reaper.ShowConsoleMsg("Please create two rackes named '" .. cueTrackName .."' and '"..masterTrackName.."' to be used as your cue and master tracks!")
    end
end


init()