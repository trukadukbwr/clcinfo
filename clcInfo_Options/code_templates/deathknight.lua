-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

local mod = clcInfo_Options.templates
local defs = mod.defs
local format = string.format


-- frost
--------------------------------------------------------------------------------
-- Frost Rotation Skill 1 & 2
mod:Add("icons", defs.CLASS_2, "Frost Rotation Skill 1", 'return IconFrost1()')
mod:Add("icons", defs.CLASS_2, "Frost Rotation Skill 2", 'IconFrost2()')
