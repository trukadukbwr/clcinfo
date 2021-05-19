-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local _, xmod = ...
xmod = xmod.hpalmodule
local db

local function Get(info)
	return db[info[#info]]
end

local function Set(info, val)
	db[info[#info]] = val
	
	if info[#info] == "prio" then
		xmod.Update()
	end
end

function xmod.BuildOptions()
	db = xmod.db

	-- legend for the actions
	local tx = {}
	local actions = xmod.GetActions()
	for k, v in pairs(actions) do
		table.insert(tx, format("\n%s - %s", k, v.info))
	end
	table.sort(tx)
	local prioInfo = "Legend:\n" .. table.concat(tx)

	return {
		order = 1, type = "group", childGroups = "tab", name = "Holy",
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
								order = 2, type="group", inline = true, name = "Normal priority",
								args = {
									prio = {
										order = 2, type = "input", width = "full", name = "",
										get = Get, set = Set,
									},
									infoCMD = {
										order = 3, type = "description", name = "Sample command line usage: cs2 cs j how",
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
			tabSettings = {
				order = 2, type = "group", name = "Settings", args = {
					igRange = {
						order = 1, type = "group", inline = true, name = "Range check",
						args = {
							rangePerSkill = {
								type = "toggle", width = "full", name = "Range check for each skill instead of only melee range.",
								get = Get, set = Set,
							},
						},
					},

				},
			},
		},
	}
end