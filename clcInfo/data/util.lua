clcInfo.datautil = {}

-- single UnitAura check that works for ID instead of name
function clcInfo.datautil.UnitAuraId(unit, id, filter)
	local i = 1
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura(unit, i, filter)
	while name do
		if spellId == id then
			return name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3
		end
		i = i + 1
		name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura(unit, i, filter)
	end

	return name
end

do
	local ttf = CreateFrame("GameTooltip", "clcInfoTooltipReaderFrame", nil, "GameTooltipTemplate")
	ttf:Hide()
	ttf:SetOwner(clcInfo.mf, "ANCHOR_NONE")

	function clcInfo.datautil.GetAuraTooltipString(unit, aura, filter)
		if UnitAura(unit, aura, nil, filter) then
			ttf:SetUnitAura(unit, aura, nil, filter)
			return clcInfoTooltipReaderFrameTextLeft2:GetText()
		end
	end
end

--[[
-- return UnitPower("player", ALTERNATE_POWER_INDEX)
if not MyVengeanceFrame then
    CreateFrame("GameTooltip", "MyVengeanceFrame", nil, "GameTooltipTemplate")
    MyVengeanceFrame:Hide()
end
MyVengeanceFrame:SetOwner( clcInfo.mf, "ANCHOR_NONE" )
local vengeanceon = UnitBuff("player", "Vengeance")
local vengeanceValue = 0
if vengeanceon then
MyVengeanceFrame:SetUnitBuff("player", vengeanceon)
local vText = MyVengeanceFrameTextLeft2:GetText()
vengeanceValue = string.match(vText, "%d+")
end
-- local maxHealth = UnitHealthMax("player")
-- local maxVengeance = ceil(maxHealth * 0.1) 
-- return format("%d / %d", vengeanceValue, maxVengeance)
return format("%d", vengeanceValue)
]]