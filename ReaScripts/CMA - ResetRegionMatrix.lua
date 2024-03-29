-- @description resets region matrix
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
    file:close()
  else
    reaper.ShowMessageBox("Can't open " .. path .. " directory invalid", "oof (reset matrix)", 0)
  end
end

---------------------------------------
--[Main]]--
---------------------------------------
local path = reaper.GetResourcePath() .. "/Scripts/CoalMinerOriginalReaScripts/ReaScripts/CMA - MatrixSetMaster.lua"
isPathValid(path)
