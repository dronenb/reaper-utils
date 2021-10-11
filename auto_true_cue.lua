-- SET THIS TO WHATEVER YOUR TRUE CUE COMMAND ID IS
trueCueCommandId = "_RS6eec5613bb183592c1b3ba37593ca60d07a088c6"

-- Find the numeric ID of the command and append ,0
trueCueCommandAction = tostring(reaper.NamedCommandLookup(trueCueCommandId))..",0"

-- Function to check to see if solo change occurred. Uses previousSoloedTracks as shared memory
local function checkSoloChange (previousSoloedTracks)
    -- Define the names of our two important tracks
    local cueTrackName    = "CUE TRACK"
    local masterTrackName = "MASTER TRACK"

    --Constants to make code more readable
    local SOLOED = 1
    local NOT_SOLOED = 0

    -- Function to get the length of a table
    function tableLength(T)
        local count = 0
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
        local soloedTracks = {}

        -- Unsolo the true master track.
        local trueMasterTrack = reaper.GetMasterTrack()

        local numTracks = reaper.CountTracks(0)
        for i = 0, numTracks - 1 do
            local track = reaper.GetTrack(0, i)
            local trackSoloValue = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
            soloedTracks[i+1] = trackSoloValue
        end
        return soloedTracks
    end

    -- Get the currently soloed tracks
    currentSoloedTracks = getSoloedTracks(getTrackByName(cueTrackName), getTrackByName(masterTrackName))

    -- Compare the array in memory to the array of currently soloed tracks
    is_change = not(compare(previousSoloedTracks, currentSoloedTracks))
    
    -- If a change has occurred, we need to update the shared memory for the next time this runs
    if is_change then
        -- Remove everything in the shared memory
        for k in pairs(previousSoloedTracks) do
            previousSoloedTracks[k] = nil
        end
        
        -- Put everything from currentSoloedTracks into previousSoloedTracks
        for i,v in ipairs(currentSoloedTracks) do
            previousSoloedTracks[i] = v
        end
    end
    
    -- Return our boolean
    return is_change
end

-- Import the ultraschall library
dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

-- Stop the event manager. This way, when you re-run the code, the EventManager is fresh
ultraschall.EventManager_Stop()

-- Start the event manager
ultraschall.EventManager_Start()

-- Add the event listener
EventIdentifier = ultraschall.EventManager_AddEvent(
    "Run true_cue if solo changes",
    0,
    0,
    false,
    false,
    checkSoloChange,
    {trueCueCommandAction}
)
