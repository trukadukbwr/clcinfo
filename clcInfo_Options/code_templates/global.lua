local mod = clcInfo_Options.templates
local defs = mod.defs

local format = string.format
local name

-- list of items used to get localized versions
local items = {
	["Whispering Fanged Skull"] = 50342,
	["Death's Verdict"] = 47115,
	["Deathbringer's Will"] = 50362,
	["Ashen Band of Endless Might"] = 52572,
	["Sharpened Twilight Scale"] = 54569,
}
-- get the real names
for k, v in pairs(items) do
	local name = GetItemInfo(v)
	if not name then name = "Unknown Item" end
	items[k] = { id = v, name = name }
end

--------------------------------------------------------------------------------
-- icons
--------------------------------------------------------------------------------

-- Trinket Slot 1
mod:Add("icons", defs.ITEMS, "Trinket 1", 'return IconItem(GetInventoryItemID("player", 13))')
-- Trinket Slot 2
mod:Add("icons", defs.ITEMS, "Trinket 2", 'return IconItem(GetInventoryItemID("player", 14))')

-- Physical DPS
-- mod:Add("icons", defs.ITEMS_DPS_PHYSICAL,
-- Ashen Band of Endless Might
mod:Add("icons", defs.ITEMS_DPS_PHYSICAL, items["Ashen Band of Endless Might"].name, "return IconICD(72412, 60, 0, 1, 0.3)")

-- Whispering Fanged Skull
mod:Add("icons", defs.ITEMS_DPS_PHYSICAL, items["Whispering Fanged Skull"].name, "return IconICD(71401, 45, 0, 1, 0.3)")
mod:Add("icons", defs.ITEMS_DPS_PHYSICAL, "[H] " .. items["Whispering Fanged Skull"].name, "return IconICD(71541, 45, 0, 1, 0.3)")

-- Death's Verdict
mod:Add("icons", defs.ITEMS_DPS_PHYSICAL, items["Death's Verdict"].name, "return IconICD(67708, 45, 0, 1, 0.3)")
mod:Add("icons", defs.ITEMS_DPS_PHYSICAL, "[H] " .. items["Death's Verdict"].name, "return IconICD(67773, 45, 0, 1, 0.3)")

-- Deathbringer's Will
mod:Add("icons", defs.ITEMS_DPS_PHYSICAL, items["Deathbringer's Will"].name, "return IconMICD(105, 0, 1, 0.3, 71484, 71491, 71492)")
mod:Add("icons", defs.ITEMS_DPS_PHYSICAL, "[H] " .. items["Deathbringer's Will"].name, "return IconMICD(105, 0, 1, 0.3, 71561, 71559, 71560)")

-- Sharpened Twilight Scale
mod:Add("icons", defs.ITEMS_DPS_PHYSICAL, items["Sharpened Twilight Scale"].name, "return IconICD(75458, 45, 0, 1, 0.3)")
mod:Add("icons", defs.ITEMS_DPS_PHYSICAL, "[H] " .. items["Sharpened Twilight Scale"].name, "return IconICD(75456, 45, 0, 1, 0.3)")