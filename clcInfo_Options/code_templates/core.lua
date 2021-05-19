local mod = clcInfo_Options.templates
local format = string.format
-- function that is used to add all templates
function mod:Add(etype, category, name, exec)
	if not mod[etype] then
		print("AddTemplate:", "invalid type for ", category, name)
		return
	end
	
	if not mod[etype][category] then mod[etype][category] = {} end
	table.insert(mod[etype][category], { name = name, exec = exec })
end
local class = UnitClass("player")
mod.defs = {
	ITEMS = "Items",
	ITEMS_DPS = "Items | dps",
	ITEMS_DPS_PHYSICAL = "Items | dps | physical",
	ITEMS_DPS_MAGIC = "Items | dps | magic",
	ITEMS_HEAL = "Items | healing",
	ITEMS_TANK = "Items | tank",
	CLASS = class,
	CLASS_1 = format("%s | %s", class, select(2, GetSpecializationInfo(1))),
	CLASS_2 = format("%s | %s", class, select(2, GetSpecializationInfo(2))),
	CLASS_3 = format("%s | %s", class, select(2, GetSpecializationInfo(3))),
}