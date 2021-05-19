-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

-- functions visible to exec should be attached to this
local emod = clcInfo.env

--------------------------------------------------------------------------------
--[[
	-- sov tracking
--]]
do
	local sovName, sovId, sovSpellTexture
	sovId = 31803
	sovName, _, sovSpellTexture = GetSpellInfo(sovId)						-- Censure
	
	local function ExecCleanup()
		emod.___e.___sovList = nil
	end
	
	local units = {"target", "focus", "mouseover"}

	function emod.MBarSoV(a1, a2, showStack, timeRight)
		-- setup the table for sov data
		if not emod.___e.___sovList then
			emod.___e.___sovList = {}
			emod.___e.ExecCleanup = ExecCleanup
		end
		
		local tsov = emod.___e.___sovList
	
		-- check target for sov
		local guid
		
		for k, v in pairs(units) do
			if UnitExists(v) then
				guid = UnitGUID(v)
				local j = 1
				local name, rank, icon, count, dispelType, duration, expires, caster = UnitDebuff(v, sovName, nil, "PLAYER")
				if name then
					-- found it
					if count > 0 and showStack then 
						if showStack == "before" then
							name = string.format("(%s) %s", count, UnitName(v))
						else
							name = string.format("%s (%s)", UnitName(v), count)
						end
					else
						name = UnitName(v)
					end
					tsov[guid] = { name, duration, expires }
				end
			end
		end
		
		-- go through the saved data
		-- delete the ones that expired
		-- display the rest
		local gt = GetTime()
		local value, tr, alpha
		for k, v in pairs(tsov) do
			-- 3 = expires
			if gt > v[3] then
				tsov[k] = nil
			else
				value = v[3] - gt
				if timeRight then
					tr = tostring(math.floor(value + 0.5))
				else
					tr = ""
				end
				if k == UnitGUID("target") then
					alpha = a1
				else
					alpha = a2
				end
				
				emod.___e:___AddBar(nil, alpha, nil, nil, nil, nil, sovSpellTexture, 0, v[2], value, "normal", v[1], "", tr)
			end
		end
	end
end

-- inquisition
function emod.IconInq(e)
	local _, _, _, _, _, dur, exp = UnitBuff("player", "Inquisition", nil, "PLAYER")
	if exp then 
	  if (exp - GetTime()) <= e then
	    return true, "Interface\\Icons\\spell_paladin_inquisition", (exp - dur), dur, 1, nil, nil, 0.5
	  end
	else
		return true, "Interface\\Icons\\spell_paladin_inquisition"
	end
end


