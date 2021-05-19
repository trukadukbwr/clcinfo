-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local mod = clcInfo_Options.templates
local defs = mod.defs
local format = string.format


-- holy
--------------------------------------------------------------------------------
-- Holy Rotation Skill 1 & 2
mod:Add("icons", defs.CLASS_1, "Holy Rotation Skill 1", 'return IconHpal1()')
mod:Add("icons", defs.CLASS_1, "Holy Rotation Skill 2", 'IconHpal2()')


-- protection
--------------------------------------------------------------------------------
-- Protection Rotation Skill 1 & 2
mod:Add("icons", defs.CLASS_2, "Protection Rotation Skill 1", 'return IconProtection1()')
mod:Add("icons", defs.CLASS_2, "Protection Rotation Skill 2", 'IconProtection2()')


-- retribution
--------------------------------------------------------------------------------
-- Retribution Rotation Skill 1 & 2
mod:Add("icons", defs.CLASS_3, "Retribution Rotation Skill 1", 'return IconRet1()')
mod:Add("icons", defs.CLASS_3, "Retribution Rotation Skill 2", 'IconRet2()')

