-- @description explodes selected items into lanes
-- @version 1.0
-- @author CoalminerAudio
-- @about gets the selected media items and explodes them to new track lanes based on the 
--  first item position in each track
-- @changelog initial release


---------------------------------------
--[Functions]]--
---------------------------------------

--count the number of media items selected in each track
function gatherItemsInTracks(numMedia)
  local tTable = {}
  --local numMedia = reaper.CountSelectedMediaItems(0)

  for i = 0, numMedia - 1 do
    local mItem = reaper.GetSelectedMediaItem(0, i)
    local mTrack = reaper.GetMediaItem_Track(mItem)
    local _, trackName = reaper.GetTrackName(mTrack)
    
    local trackEntry = nil
    for _, value in ipairs(tTable) do
      if value.track == mTrack then
        trackEntry = value
        break
      end
    end
    
    if not trackEntry then
      trackEntry = {track = mTrack, num = 1}
      table.insert(tTable, trackEntry)
    else
      trackEntry.num = trackEntry.num + 1
    end
  end
  
  --Debug string
  --[[
  for _, entry in ipairs(tTable) do
    local track = entry.track
    local num = entry.num
    local _, tName = reaper.GetTrackName(track)
    reaper.ShowConsoleMsg("track " .. tName .. " Has " .. num .. " selected media items " .. "\n")
  end
  ]]--
  return tTable
end


--Make track lanes for each item, and color each item
function makeLanes(track, numItems, numLanes, startNum)
  local currentNumLanes = reaper.GetMediaTrackInfo_Value(track, "I_NUMFIXEDLANES")
  --if the track already has the correct number of lanes, do nothing (otherwise it reorganizes items)
  if currentNumLanes ~= numLanes then
    local trackColor = reaper.GetTrackColor(track)
    local x = 0
    local pos
    --stop iterating when we've iterated through the number of items in this track
    for i = startNum, numItems do
      if i == numItems then
        break
      end
      
      local mediaItem = reaper.GetSelectedMediaItem(0, i)
      
      --set the starting position to be uniform across all items
      if i == startNum then
        pos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      end
      
      reaper.SetMediaItemInfo_Value(mediaItem, "I_FIXEDLANE", x)
      reaper.SetMediaItemInfo_Value(mediaItem, "D_POSITION", pos)
      local newColor = trackColor - 1000
      reaper.SetMediaItemInfo_Value(mediaItem, "I_CUSTOMCOLOR", newColor)
      trackColor = newColor
      x = x + 1
    end
    reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:0", 1)

  else 
  --debug string
  --[[
  local _, tName = reaper.GetTrackName(track)
  reaper.ShowConsoleMsg(tName)
  --]]
  end
end


---------------------------------------
--[Main]]--
---------------------------------------

function main()

  --count total number of selected items, get the starting position
  local nItems = reaper.CountSelectedMediaItems(0)
  if nItems <= 0 then
    reaper.ShowMessageBox("Select at least one media item", "Oof: Lane exploder", 0)
      
  else
   
    --get which tracks the items are in, and how many items are in each track
    local tTable = gatherItemsInTracks(nItems)
           
    --iterate through tTable to make lanes. 
    --track: the track from the table
    --lNum: the number of items selected in the track
    --startingNum tracks which number of media item to start iterating through from the total number of selected items
    local startingNum = 0
    for _, entry in ipairs(tTable) do
      local track = entry.track
      local lNum = entry.num
               
      local _, name = reaper.GetTrackName(track)
      
      makeLanes(track, nItems, lNum, startingNum)
      startingNum = startingNum + lNum
    end
  end
end


main()