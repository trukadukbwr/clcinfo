-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "WARRIOR" then return end

local mod = clcInfo_Options.templates
local defs = mod.defs
local format = string.format


-- arms
--------------------------------------------------------------------------------
-- Arms Rotation Skill 1 & 2
mod:Add("icons", defs.CLASS_1, "Arms Rotation Skill 1", 'return IconArms1()')
mod:Add("icons", defs.CLASS_1, "Arms Rotation Skill 2", 'IconArms2()')
