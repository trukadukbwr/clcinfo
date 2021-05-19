-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local modName = "__protection"

local baseMod, baseDB

--[[
classModules
retribution
tabGeneral
igRange
rangePerSkill
--]]
local function Get(info)
	return baseDB[info[#info]]
end

local function Set(info, val)
	baseDB[info[#info]] = val
	
	if info[#info] == "prio" then
		baseMod:UpdateQueue()
	end
end

local function LoadModule()
	if not clcInfo.activeTemplate then return end
	
	baseMod = clcInfo.classModules[modName]
	baseDB = clcInfo.activeTemplate.classModules[modName]
	
	local tx = {}
	for k, v in pairs(baseMod.actions) do
		table.insert(tx, format("\n%s - %s", k, v.info))
	end
	table.sort(tx)
	local prioInfo = "Legend:\n" .. table.concat(tx)
	
	options.args.classModules.args[modName] = {
		order = 4, type = "group", childGroups = "tab", name = "Protection",
		args = {
			tabPriority = {
				order = 1, type = "group", name = "Priority", args = {
					igPrio = {
						order = 1, type = "group", inline = true, name = "",
						args = {
							info = {
								order = 1, type = "description", name = prioInfo,
							},
							normalPrio = {
								order = 2, type="group", inline = true, name = "",
								args = {
									prio = {
										order = 2, type = "input", width = "full", name = "",
										get = Get, set = Set,
									},
									infoCMD = {
										order = 3, type = "description", name = "Sample command line usage: /clcinfo protprio cs j as cons how hw",
									},
								},
							},
							disclaimer = {
								order = 4, type = "description", name = "|cffff0000These are just examples, make sure you adjust them properly!|cffffffff",
							},
						},
					},
				},
			},
		},
	}
end
clcInfo_Options.optionsCMLoaders[#(clcInfo_Options.optionsCMLoaders) + 1] = LoadModule