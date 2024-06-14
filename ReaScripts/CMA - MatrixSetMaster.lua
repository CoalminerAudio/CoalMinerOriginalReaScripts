-- @description a list of functions used in other scripts for region matrix control
-- @version 1.1
-- @author CoalminerAudio
-- @about Functions in this script will either set the region matrix based on
-- selected tracks and regions in the time selection, clear the region matrix, or do both 
-- @changelog fixed bug in getregions function


---------------------------------------
--[Functions]]--
---------------------------------------


function getTracks() --returns a table of the selected tracks
  tTable = {}
  numTracks = reaper.CountSelectedTracks(0)
  for i = 0, numTracks do
    local t = reaper.GetSelectedTrack(0, i)
    table.insert(tTable, t)
  end
  return tTable
end

function getRegions() --returns a table of regions in the time selection
  reaper.ClearConsole()
   local rTable = {}
   local lStart, lEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
   local _, _, numRegions = reaper.CountProjectMarkers(0)
   for i = 0, numRegions - 1 do
     local _, isRgn, rStart, rEnd, rgnName, rgnNum = reaper.EnumProjectMarkers(i)
     if isRgn then
       if rStart >= lStart and rEnd <= lEnd then
         table.insert(rTable, rgnNum)
       end
     end
   end
   return rTable
 end

function getAllRegions() --returns all regions
  local fullRegTable = {}
  local numRegions = reaper.CountProjectMarkers(0)
  for i = 0, numRegions do
    local _, isrgn, _, _, _, rgnNum = reaper.EnumProjectMarkers(i)
    if isrgn then
      table.insert(fullRegTable, rgnNum)
    end
  end
  return fullRegTable
end
  
function setMatrix() --sets the region matrix
  local tTable = getTracks()
  local rTable = getRegions()
  for _, tEntry in ipairs(tTable) do
    for _, rEntry in ipairs(rTable) do
      reaper.SetRegionRenderMatrix(0, rEntry, tEntry, 1)
    end
  end
end

function clearMatrix() --clears the region matrix
  local fullRegTable = getAllRegions()
  for _, regionVal in ipairs(fullRegTable) do
    local t = 0
    local t_temp_tracks = {}
      while reaper.EnumRegionRenderMatrix(0, regionVal, t) do
        t_temp_tracks[t]  = reaper.EnumRegionRenderMatrix(0, regionVal, t)
        t = t + 1
      end
    for i, track in pairs(t_temp_tracks) do
        reaper.SetRegionRenderMatrix(0, regionVal, track, -1)
    end
  end
end


---------------------------------------
--[Main]]--
---------------------------------------
--[[
This script has no main function - instead the events are called in other functions.

  those scripts are:
  CMA - ResetRegionMatrix
  CMA - MatrixSetter
  CMA - MatrixClearAndSet
--]]
