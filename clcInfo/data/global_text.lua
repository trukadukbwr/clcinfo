local mod = clcInfo.env

local lsVengeance = GetSpellInfo(93099)
local GetAuraTooltipString = clcInfo.datautil.GetAuraTooltipString
function mod.TextVengeance()
    local tt = GetAuraTooltipString("player", lsVengeance, "HELPFUL|PLAYER")
    if tt then
        return tonumber(string.match(tt, "%d+"))
    end
    return 0
end

function mod.TextTooltipAura(unit, aura, filter)
    local tt = GetAuraTooltipString(unit, aura, filter)
    if tt then
        return tonumber(string.match(tt, "%d+"))
    end
    return 0
end
