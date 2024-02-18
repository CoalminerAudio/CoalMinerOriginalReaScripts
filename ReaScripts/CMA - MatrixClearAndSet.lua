-- @description resets region matrix, and sets it from time and track selection
-- @version 1.0.2
-- @author CoalminerAudio
-- @about see master script for function, CMA - MatrixSetMaster
-- @changelog 1.0.2 more file path bug fixes
-- 1.0.1 file name bug fix
-- 1.0 inital release 

---------------------------------------
--[Functions]]--
---------------------------------------

function isPathValid(path)
  local file = io.open(path, "r")
  
  if file then 
    dofile(path)
    clearMatrix()
    setMatrix()
    file:close()
  else
    reaper.ShowMessageBox("Can't open " .. path .. " directory invalid", "oof (Matrix Clear and Set)", 0)
  end
end

---------------------------------------
--[Main]]--
---------------------------------------
local path = reaper.GetResourcePath() .. "/Scripts/CoalMinerOriginalReaScripts/ReaScripts/CMA - MatrixSetMaster.lua"
isPathValid(path)
