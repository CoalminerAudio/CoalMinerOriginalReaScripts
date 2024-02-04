-- @description randomize parameter values, track volume, or shuffle lanes based on input into imgui
-- @version 1.0
-- @author CoalminerAudio
-- @about
-- @changelog


---------------------------------------
--[Intro]]--
---------------------------------------
--[[
Hello, this script is designed to create a randomization tool to control selected parameters from track FX with input from the user.
The logic revolves around grabbing a track, and then displaying it's variables. If you have question or commets reguarding the script,
please shoot me an email at Kevin@Coalmineraudio.com
]]--

---------------------------------------
--[Variables]]--
---------------------------------------
local ctx = reaper.ImGui_CreateContext('Parameter Serendipator')
local lineTable = {}
local makeTitleString = true
local lasttrack = reaper.GetTrack(0, 0)
local doOnce = true
---------------------------------------
--[[main Loop]]--
---------------------------------------

local function loop()
    local visible, open = reaper.ImGui_Begin(ctx, 'Parameter Serendipator', true)
    if visible then
    --[[ test slider for positioning items
    bTestSlider, iTestSlider = reaper.ImGui_SliderInt(ctx,"##posSlider", testSliderVal, 0, 1000)
    if bTestSlider then
      testSliderVal = iTestSlider
    end
    ]]--
    
    --[[ each integer is used to create a imgui element, itype is used to differentiate multiple istances of a type of element
    0 - bullet text 
    1 - button        | itype1: Get track, itype2: reset values, itype3: remove list
    2 - checkbox      | itype1: allow lane shuffle, itype 2: allow vol change, itype3 and 4: allows respective parameter to be changed
    3 - combo box     | itype1: Fx list, itype2 and 3: respective parameter list
    4 - slider        | itype1 and 2: respective parameter change power
    5 - new line      | no itypes
    ]]--
    
    if makeTitleString then
      local lineTableLine = #lineTable + 1
      lineTable[lineTableLine] =
      {
        {int = 0, str = "Selected Tracks"}, 
        {int = 0, str = "TrackShuffle"}, 
        {int = 0, str = "Volume Shift"}, 
        {int = 0, str = "Track FX", loc = 367},  
        {int = 0, str = "Fx Param: One", loc = 492}, 
        {int = 0, str = "Fx Param: Two", loc = 617}
      }
      reaper.ClearConsole()
      makeTitleString = false
    end
    
    --add a new line to the table, not just checkboxes
    if reaper.ImGui_Button(ctx, "New line") then
      local lineTableLine = #lineTable + 1
      lineTable[lineTableLine] = 
      {
        {int = 1, itype = 1, str = "Grab Track", bool = false, loc = 35},
        {int = 2, itype = 1, str = "LaneShuffle", bool = false, loc = 190},
        {int = 2, itype = 2, str = "VolumeShuffle", bool = false, loc = 305},
        {int = 3, itype = 1, str = "TrackFX", bool = false, wdth = 120, loc = 375},
        {int = 3, itype = 2, str = "FxParamOne", bool = false, wdth = 120, loc = 500},
        {int = 3, itype = 3, str = "FxParamTwo", bool = false, wdth = 120, loc = 625},
        {int = 1, itype = 2, str = "reset", bool = false, loc = 750},
        {int = 1, itype = 3, str = "remove line", bool = false, loc = 800},
        {int = 5},
        {int = 4, itype = 1, str = "sliderOne", val = 0, min = 0, max = 1, wdth = 100, loc = 500},
        {int = 2, itype = 3, str = "allowRandomOne", bool = true, loc = 601},
        {int = 4, itype = 2, str = "sliderTwo", val = 0, min = 0, max = 1, wdth = 100, loc = 625},
        {int = 2, itype = 4, str = "allowRandomTwo", bool = true, loc = 726},
        --the last line is used to track all variabels set and selected by the imgui elements--
        {track = track, selfx = selfx, trackfx = {}, selparam1 = selparam1, selparam2 = selparam2, fxparams = {}, 
        randval1 = 0, def1 = def1, randval2 = 0, def2 =  def2, trackdefv = trackdefv, 
        laneshuf = false, volset = false, allowrand1 = true, allowrand2 = true, param1set = false, param2set = false, trackset = false}
      }
    end
    
    reaper.ImGui_SameLine(ctx)
    
    --trigger the reaper function to randomize based on elements from teh last line of the table
    if reaper.ImGui_Button(ctx, "Randomize") then
      local tableVal = {}
      for idx, entry in ipairs(lineTable) do
        local trackcheck = entry[#entry].track
        if trackcheck then
          randomizeValue(entry[#entry])
        end
      end
    end
      
    --for each item in the line table, make a line. Makes it possible to track parameter states across lines
    for i, lineData in ipairs(lineTable) do 
      addLine(i, lineData)
    end
    
    --end of gui logic
    reaper.ImGui_End(ctx)
      end
      if open then
          reaper.defer(loop)
      end
end

---------------------------------------
--[[Reaper functions]]--
---------------------------------------

-- get most recently touched track
function getTrack()
  local lastTrack = reaper.GetLastTouchedTrack()
  local isTrack, lastTrackName = reaper.GetTrackName(lastTrack)
  
  if isTrack then
    return lastTrack, lastTrackName
    
  else 
    return 0, "No Track selected"
    
  end
end

--gets the given tracks FXs
function getFxList(trackVal)
  local fxCount = reaper.TrackFX_GetCount(trackVal)
  local fxTable = {}
  for i = 0, fxCount - 1, 1 do
    local hasFX, fxName = reaper.TrackFX_GetFXName(trackVal, i)
    if hasFX then
      local colonPos = fxName:find(":")
        if colonPos then
          fxName = fxName:sub(colonPos + 2)
        end
      table.insert(fxTable, fxName)
    end
  end
  return fxTable
end

--gets the given Fxs params 
function getParamList(trackVal, fxVal)
  local paramCount = reaper.TrackFX_GetNumParams(trackVal, fxVal)
  local paramTable = {}
  for i = 1, paramCount - 1, 1 do
    _, trackName = reaper.GetTrackName(trackVal)
    local hasParam, paramName = reaper.TrackFX_GetParamName(trackVal, fxVal, i)
    if hasParam then
      table.insert(paramTable, paramName)
    end
  end
  return paramTable
end

--set the value of the parameter
function randomizeValue(line)--[[track, fx, param, value, default]]--)
  reaper.Undo_BeginBlock()
  
  --set param one's value
  if line.param1set and line.allowrand1 then
    local rangeLow = line.def1 - line.randval1
    local rangeHigh = line.def1 + line.randval1
    local setVal = rangeLow + math.random() * (rangeHigh - rangeLow)
    reaper.TrackFX_SetParam(line.track, line.selfx, line.selparam1, setVal)
  end
  
  --set param two's value
  if line.param2set and line.allowrand2 then
    local rangeLow = line.def2 - line.randval2
    local rangeHigh = line.def2 + line.randval2
    local setVal = rangeLow + math.random() * (rangeHigh - rangeLow)
    reaper.TrackFX_SetParam(line.track, line.selfx, line.selparam2, setVal)
  end
  
  if line.trackset then
    --shuffle track lanes 
    if line.laneshuf then
      numLanes = reaper.GetMediaTrackInfo_Value(line.track, "I_NUMFIXEDLANES")
      fRand = math.random(0, numLanes - 1)
      local setTrackVal = "C_LANEPLAYS:" .. fRand
      reaper.SetMediaTrackInfo_Value(line.track, setTrackVal, 1)
    end
    
    --set track volume
    if line.volset then
      local rangeLow = line.trackdefv - .5
      local rangeHigh = line.trackdefv + .5
      local setVal = rangeLow + math.random() * (rangeHigh - rangeLow)
      reaper.SetTrackUIVolume(line.track, setVal, false, false, 0)
    end
  end
  reaper.Undo_EndBlock("Randomizer: set value", 0)
end

--resets param values to inital values
function resetVal(bool, track, fx, param, value)
  reaper.Undo_BeginBlock()
  if bool then
    reaper.TrackFX_SetParam(track, fx, param, value)
  end
  reaper.Undo_EndBlock("Randomizer: reset", 0)
end
  
---------------------------------------
--[[LineMaker function]]--
---------------------------------------


function addLine(index, lineData)
  local trackFx = {} 
  local fxParams = lineData[#lineData].fxparams
  local trackGrabbed 
  
  for _, element in ipairs(lineData) do
  
    --make a text block
    if element.int == 0 then
    
      --position the item
      if element.loc then
        reaper.ImGui_SetCursorPosX(ctx, element.loc)
      end
      
      reaper.ImGui_BulletText(ctx, element.str)
      reaper.ImGui_SameLine(ctx)
    
    --make button
    elseif element.int == 1 then
    
      --position the item
      if element.loc then
        reaper.ImGui_SetCursorPosX(ctx, element.loc)
      end
      
      --button logic
      element.bool = reaper.ImGui_Button(ctx, element.str .. "##" .. index)
      reaper.ImGui_SameLine(ctx)
      if element.bool then
        local trackNum, trackName = getTrack()
        lineData[#lineData].trackset = true
        
        --grab the fx list from the track
        if element.itype == 1 then
          if trackNum then
            trackFx = getFxList(trackNum)
          end
          
        --reset the parameter values
        elseif element.itype == 2 then
          local lastLine = lineData[#lineData]
          resetVal(lastLine.param1set, lastLine.track, lastLine.selfx, lastLine.selparam1, lastLine.def1)
          resetVal(lastLine.param2set, lastLine.track, lastLine.selfx, lastLine.selparam2, lastLine.def2)
        
        
        elseif element.itype == 3 then
          table.remove(lineTable, index)
        end
        
        --set variabels based on return values
        if element.itype == 1 then
          element.str = trackName
          lineData[#lineData].track = trackNum
          lineData[#lineData].trackfx = trackFx
          local _, vol, _ = reaper.GetTrackUIVolPan(trackNum)
          lineData[#lineData].trackdefv = vol
        end
        trackGrabbed = true
      end 
    
    
    --make checkbox
    elseif element.int == 2 then

      --position the item
      if element.loc then
        reaper.ImGui_SetCursorPosX(ctx, element.loc)
      end
      
        --main checkbox logic
        local changed, value = reaper.ImGui_Checkbox(ctx, "##" .. element.str .. index, element.bool)
        if changed then
          element.bool = value
          
          --should we shuffle lanes
          if element.itype == 1 then
            lineData[#lineData].laneshuf = value
            
          --should we set volume 
          elseif element.itype == 2 then
            lineData[#lineData].volset = value
            
          --should we allow param one to be randomized
          elseif element.itype == 3 then 
            lineData[#lineData].allowrand1 = value
            
          --should we allow param two to be randomized
          elseif element.itype == 4 then 
            lineData[#lineData].allowrand2 = value
            
          else
            reaper.ShowMessageBox("invalid Itype in checkboxes", "oof", 1)
          end
        end
    reaper.ImGui_SameLine(ctx)
        
      
    --make combobox
    elseif element.int == 3 then
      
      --set item position
      if element.loc then
        reaper.ImGui_SetCursorPosX(ctx, element.loc)
      end
      
      --what type of combo box, fx or parameter?
      local comboSelection = {}
      if element.itype then
        if element.itype == 1 then
          comboSelection = lineData[#lineData].trackfx
        elseif element.itype == 2 or 3 then
          comboSelection =  lineData[#lineData].fxparams
        else
          comboSelection = comboTest
        end
      end
      
      --main checkbox logic
      local comboName = element.str
      local selectedValue = comboName
      reaper.ImGui_SetNextItemWidth(ctx, element.wdth)
      local combo = reaper.ImGui_BeginCombo(ctx, "##" .. element.str .. index, comboName)
      if combo then
        for i, value in ipairs(comboSelection) do
          --make selectable items in the combo box
          local touched = reaper.ImGui_Selectable(ctx, value, selectedValue == i .. value)
          
          --when an item is selected from the box
          if touched then
            selectedValue = value
      
            --get the params from teh seleceted FX
            if element.itype == 1 then
              local paramlist = getParamList(lineData[#lineData].track, i - 1)
              lineData[#lineData].fxparams = paramlist
              lineData[#lineData].selfx = i - 1
            
            --set the param to control with param1
            elseif element.itype == 2 then
              lineData[#lineData].param1set = true
              lineData[#lineData].selparam1 = i
              local defVal = reaper.TrackFX_GetParam(lineData[#lineData].track, lineData[#lineData].selfx, i)
              lineData[#lineData].def1 = defVal
              
            --set the param to control with param2
            elseif element.itype == 3 then
              lineData[#lineData].param2set = true
              lineData[#lineData].selparam2 = i
              local defVal = reaper.TrackFX_GetParam(lineData[#lineData].track, lineData[#lineData].selfx, i)
              lineData[#lineData].def2 = defVal
            
            --error message inscase something messed up
            else
              reaper.ShowMessageBox("invalid Itype in comboboxes", "Serendipiter(oof)", 1)
            end
            
          end
        end
        --update variables
        reaper.ImGui_EndCombo(ctx)
        element.str = selectedValue
      end
      
      reaper.ImGui_SameLine(ctx, element.spc)
        
      
      --make a slider
      elseif element.int == 4 then
        --set item location
        if element.loc then
          reaper.ImGui_SetCursorPosX(ctx, element.loc)
        end
        reaper.ImGui_SetNextItemWidth(ctx, element.wdth)
        
        --slider main logic
        local sliderBool, value = reaper.ImGui_SliderDouble(ctx, "##" .. element.str .. index,  element.val, element.min, element.max)
        
        if sliderBool then
          element.val = value
          
          --set the random power for parameter one
          if element.itype == 1 then
            lineData[#lineData].randval1 = value
          
          --set the random power for parameter two
          elseif element.itype == 2 then
            lineData[#lineData].randval2 = value
            
          --error message incase of issues
          else
            reaper.ShowMessageBox("invalid Itype in sliders",  "Serendipiter(oof)", 1)
        end
      end
        
      reaper.ImGui_SameLine(ctx, element.spc)
      
    --make a new line
    elseif element.int == 5 then
      reaper.ImGui_NewLine(ctx)
    end
    
  end
  --prep next group of imguis to start on a new line, and add spacing
  reaper.ImGui_NewLine(ctx)
  reaper.ImGui_Dummy(ctx,0,10)
end
    
    -- Start the main loop
reaper.defer(loop)
