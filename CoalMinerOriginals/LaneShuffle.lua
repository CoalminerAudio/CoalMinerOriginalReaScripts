-- @description shuffle through track lanes
-- @version 1.0
-- @author CoalminerAudio


---------------------------------------
--[Intro]]--
---------------------------------------
--[[
Hello, this script is designed to shuffle through track lanes, which were added to reaper 7.
If you are familiar with game audio implementation, compare it to a random container in Wwise
If you have any problems or questions, feel free to email me at Kevin@coalmineraudio.com
]]--

---------------------------------------
--[FunctionS]]--
---------------------------------------

function prepForShuffle()
  numTracks = reaper.CountSelectedTracks(0)
  if numTracks and numTracks > 0 then
    local valid = true
    return numTracks, valid
  else
     reaper.ShowMessageBox("Select at least one track", "oof", 0)
     valid = false
  end
end

function shuffleLanes(numtracks, validcheck)
  reaper.Undo_BeginBlock()
  if numtracks > 0 and validcheck then
    for i = 1, numtracks do
    track = reaper.GetSelectedTrack(0, i - 1)
    numLanes = reaper.GetMediaTrackInfo_Value(track, "I_NUMFIXEDLANES")
    fRand = math.random(0, numLanes - 1)
    setTrackVal = "C_LANEPLAYS:" .. fRand
    reaper.SetMediaTrackInfo_Value(track, setTrackVal, 1)
    end
  else 
   
  end
  reaper.Undo_EndBlock("Shuffle lanes", 0)
end

---------------------------------------
--[Call functions]]--
---------------------------------------
trackCount, valid = prepForShuffle()
shuffleLanes(trackCount, valid)

