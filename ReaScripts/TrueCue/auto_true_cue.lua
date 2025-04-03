-- @version 1.21 (State-change detection, efficient track searching, adaptive polling frequency, highly optimized sends update, reduced CPU during solo, track caching, granular updates, solo-blocked tracks, redundant calls optimized)
-- @author Ben Dronen (Modified)
-- @description True cue bus for REAPER (auto-create MASTER and CUE tracks, solo-defeat on MASTER, prevent soloing special tracks)
-- @about Automatically manages a cue bus for monitoring soloed tracks in REAPER. Creates MASTER and CUE tracks if they don't exist, sets MASTER track to solo-defeat mode, optimized for CPU usage with adaptive polling frequency, efficient track searching, and state-change detection. Prevents user from manually soloing MASTER and CUE tracks.

local cueTrackName    = "CUE TRACK"
local masterTrackName = "MASTER TRACK"

local NOT_SOLOED            = 0
local SOLOED                = 1
local RECEIVES              = -1
local SENDS                 = 0
local POST_FADER            = 0
local POST_FX               = 3

local CurrentSoloedTracks = {}
local PreviousSoloedTracks = {}
local lastSentTracks = {}

local cachedCueTrack = nil
local cachedMasterTrack = nil
local cachedTrackCount = 0
local cachedTrackList = {}

local function tableLength(T)
    local count = 0
    for _ in pairs(T or {}) do count = count + 1 end
    return count
end

local function compare(array1, array2)
    if tableLength(array1) ~= tableLength(array2) then return false end
    for i,v in pairs(array1) do if v ~= array2[i] then return false end end
    return true
end

local function shallowCopy(sourceArray, destArray)
    for k in pairs(destArray) do destArray[k] = nil end
    for i,v in ipairs(sourceArray) do destArray[i] = v end
end

local function refreshTrackList()
    cachedTrackList = {}
    local numTracks = reaper.CountTracks(0)
    for i = 0, numTracks - 1 do
        local track = reaper.GetTrack(0, i)
        cachedTrackList[i + 1] = track
    end
end

local function getTrackByName(inputName)
    for _, track in ipairs(cachedTrackList) do
        local _, trackName = reaper.GetTrackName(track)
        if trackName == inputName then return track end
    end
    return nil
end

local function getSoloedTracks()
    local soloedTracks = {}
    for _, track in ipairs(cachedTrackList) do
        if reaper.GetMediaTrackInfo_Value(track, "I_SOLO") == SOLOED then
            table.insert(soloedTracks, track)
        end
    end
    return soloedTracks
end

local function removeReceives(track)
    while (reaper.GetTrackNumSends(track, RECEIVES) > 0) do
        reaper.RemoveTrackSend(track, RECEIVES, 0)
    end
end

local function updateCueBus(soloedTracks)
    reaper.PreventUIRefresh(1)

    if cachedCueTrack and cachedMasterTrack then
        local tracksChanged = not compare(soloedTracks, lastSentTracks)

        if tracksChanged then
            removeReceives(cachedCueTrack)

            if #soloedTracks == 0 then
                local sendIndex = reaper.CreateTrackSend(cachedMasterTrack, cachedCueTrack)
                reaper.SetTrackSendInfo_Value(cachedMasterTrack, SENDS, sendIndex, "I_SENDMODE", POST_FADER)
            else
                for _, track in ipairs(soloedTracks) do
                    local sendIndex = reaper.CreateTrackSend(track, cachedCueTrack)
                    reaper.SetTrackSendInfo_Value(track, SENDS, sendIndex, "I_SENDMODE", POST_FX)
                end
            end

            shallowCopy(soloedTracks, lastSentTracks)
        end
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateTimeline()
end

local function preventUserSolo(track)
    if track and reaper.GetMediaTrackInfo_Value(track, "I_SOLO") ~= NOT_SOLOED then
        reaper.SetMediaTrackInfo_Value(track, "I_SOLO", NOT_SOLOED)
    end
end

local function validateTrackCache()
    local currentTrackCount = reaper.CountTracks(0)
    if currentTrackCount ~= cachedTrackCount then
        refreshTrackList()
        cachedCueTrack = getTrackByName(cueTrackName)
        cachedMasterTrack = getTrackByName(masterTrackName)
        cachedTrackCount = currentTrackCount
    end
end

local lastCheckTime = 0
local hadSolo = false
local lastProjectState = -1

local function main_loop()
    local currentTime = reaper.time_precise()
    local pollingInterval = hadSolo and (1/5) or (1/24)
    local currentProjectState = reaper.GetProjectStateChangeCount(0)

    if currentTime - lastCheckTime >= pollingInterval then
        if currentProjectState ~= lastProjectState then
            validateTrackCache()
            preventUserSolo(cachedCueTrack)
            preventUserSolo(cachedMasterTrack)

            CurrentSoloedTracks = getSoloedTracks()
            local hasSoloNow = (#CurrentSoloedTracks > 0)

            if hasSoloNow ~= hadSolo or (hasSoloNow and not compare(CurrentSoloedTracks, PreviousSoloedTracks)) then
                updateCueBus(CurrentSoloedTracks)
                shallowCopy(CurrentSoloedTracks, PreviousSoloedTracks)
                hadSolo = hasSoloNow
            end

            lastProjectState = currentProjectState
        end

        lastCheckTime = currentTime
    end
    reaper.defer(main_loop)
end

local function ensureTrackExists(name)
    local track = getTrackByName(name)
    if not track then
        reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)
        track = reaper.GetTrack(0, reaper.CountTracks(0) - 1)
        reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)
    end
    return track
end

local function init()
    reaper.SNM_SetIntConfigVar("soloip", 0)

    refreshTrackList()
    cachedCueTrack = ensureTrackExists(cueTrackName)
    cachedMasterTrack = ensureTrackExists(masterTrackName)

    reaper.SetMediaTrackInfo_Value(cachedMasterTrack, "I_SOLO", 0)
    reaper.SetMediaTrackInfo_Value(cachedMasterTrack, "B_SOLO_DEFEAT", 1)
    reaper.SetMediaTrackInfo_Value(cachedCueTrack, "I_SOLO", 0)
    reaper.SetMediaTrackInfo_Value(cachedCueTrack, "B_SOLO_DEFEAT", 1)


    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

    main_loop()
end

init()
