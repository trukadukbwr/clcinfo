-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "SHAMAN" then return end

local mod = clcInfo_Options.templates
local defs = mod.defs
local format = string.format


-- elemental
--------------------------------------------------------------------------------
-- Ele Rotation Skill 1 & 2
mod:Add("icons", defs.CLASS_1, "Elemental Rotation Skill 1", 'return IconElemental1()')
mod:Add("icons", defs.CLASS_1, "Elemental Rotation Skill 2", 'IconElemental2()')
