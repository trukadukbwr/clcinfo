-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

local mod = clcInfo_Options.templates
local defs = mod.defs
local format = string.format


-- Marksman
--------------------------------------------------------------------------------
-- Marksman Rotation Skill 1 & 2
mod:Add("icons", defs.CLASS_2, "Marksman Rotation Skill 1", 'return IconMarksman1()')
mod:Add("icons", defs.CLASS_2, "Marksman Rotation Skill 2", 'IconMarksman2()')
