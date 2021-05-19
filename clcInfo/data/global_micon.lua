local mod = clcInfo.env

-- IMPORTANT
-- really careful at the params
function mod.AddMIcon(id, visible, ...)
	if visible then
		mod.___e:___AddIcon(id, ...)
	else
		if id then mod.___e:___HideIcon(id) end
	end
end



-- experimental
-- show debuffs on specified unit if in raid
function mod.MIconRaidUnitAuras(unitName, filter, exact)

	-- get raidslot
	local unit = UnitInRaid(unitName)
	if not unit then return end

	unit = "raid" .. unit

	-- cycle through auras and add them to mbar
	local i = 1
	local name, rank, icon, count, debuffType, duration, expires, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura(unit, i, filter)
	while name do
		-- add aura as micon
		if count <= 1 then count = nil end
		if exact then
			if exact == name then
				mod.AddMIcon("mirua", true, icon, expires - duration, duration, 1, true, count)
				return
			end
		else
			mod.AddMIcon("mirua", true, icon, expires - duration, duration, 1, true, count)
		end

		i = i + 1
		name, rank, icon, count, debuffType, duration, expires, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura(unit, i, filter)
	end
end
