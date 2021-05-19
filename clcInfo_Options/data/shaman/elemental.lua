-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "SHAMAN" then return end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local modName = "__elemental"

--[[
classModules
elemental
tabGeneral
igRange
rangePerSkill
--]]

local function LoadModule()
	if not clcInfo.activeTemplate then return end
	
	local baseMod = clcInfo.classModules[modName]
	options.args.classModules.args[modName] = baseMod.BuildOptions()
end
clcInfo_Options.optionsCMLoaders[#(clcInfo_Options.optionsCMLoaders) + 1] = LoadModule