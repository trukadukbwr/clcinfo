--[[
mindless rambling:
first icon should show the rotation
second icon should show when stor/wog are available
wog would be displayed at max buff stacks, sotr in rest

increase all cooldowns to make cs more attractive

cs j as how cons hw
]]



-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local GetTime = GetTime
local debug = clcInfo.debug

local version = 3

local modName = "__protection"
local mod = clcInfo:RegisterClassModule(modName)
local emod = clcInfo.env
local db -- template based

local ef = CreateFrame("Frame") 	-- event frame
ef:Hide()
local qTaint = true								-- will force queue check

local defaults = {
	version = version,
	
	prio = "cs j as how cons hw",
	rangePerSkill = false,
}

-- @defines
--------------------------------------------------------------------------------
local gcdId 				= 4987	-- cleanse for gcd

-- list of spellId
local sotrId				= 53600	-- shield of the righteous
local wogId					= 85673	-- shield of the righteous

local howId 				=	24275	-- hammer of wrath
local csId 					= 35395	-- crusader strike
local asId					= 31935	-- avenger's shield
local hotrId				= 53595	-- hammer of the righteous
local jId						= 20271	-- judgement
local consId				= 26573	-- consecration
local consxId				= 116467 -- ranged consecration
local hwId					= 119072 	-- holy wrath
local ssId					= 20925 	-- sacred shield
local esId					= 114157	-- execution sentence
local hprId					= 114165	-- holy prism
local lhId					= 114158	-- light's hammer
-- csName to pass as argument for melee range checks
local csName			= GetSpellInfo(csId)
-- buffs
local buffBoG 		= GetSpellInfo(114637)	-- bastion of glory
local buffAW			= GetSpellInfo(31884)		-- avenging wrath
local buffGC			= GetSpellInfo(85416)				-- grand cursader
-- debuffs
-- local debuffWB			= GetSpellInfo(115798) -- weakened blows

-- custom function to check ss since there are 2 buffs with same name
local buffSS = 20925


-- status vars
local s1, s2
local s_ctime, s_gcd, s_hp, s_haste, s_ss, s_wb, s_aw, s_gc
local s_consId = consId

function mod:OnTemplatesUpdate()
	db = clcInfo:RegisterClassModuleTDB(modName, defaults)
	if db then
		if not db.version or db.version < version then
			-- fix stuff
			clcInfo.AdaptConfigAndClean(modName, db, defaults)
			db.version = version
		end
		
		mod:UpdateQueue()
	end
end


-- the queue
local qn = {} 		-- normal queue
local q						-- working queue


local function GetCooldown(id)
	local start, duration = GetSpellCooldown(id)
	local cd = start + duration - s_ctime - s_gcd
	if cd < 0 then return 0 end
	return cd
end


-- actions ---------------------------------------------------------------------
local actions = {
	cs = {
		id = csId,
		GetCD = function()
			return max(0, GetCooldown(csId) - 0.5)
		end,
		info = "Crusader Strike",
	},
	hotr = {
		id = hotrId,
		GetCD = function()
			return max(0, GetCooldown(hotrId) - 0.5)
		end,
		info = "Hammer of the Righteous",
	},
	as = {
		id = asId,
		GetCD = function()
			return GetCooldown(asId)
		end,
		info = "Avenger's Shield",
	},
	gcas = {
		id = asId,
		GetCD = function()
			if s_gc <= 0 then return 100 end
			return GetCooldown(asId)
		end,
		info = "Avenger's Shield (Grand Crusader active)",
	},
	j = {
		id = jId,
		GetCD = function()
			return GetCooldown(jId)
		end,
		info = "Judgement",
	},
	jaw = {
		id = jId,
		GetCD = function()
			if s_aw <= 1 then
				return GetCooldown(jId)
			end
			return 100
		end,
		info = "Judgement under Avenging Wrath",
	},
	how = {
		id = howId,
		GetCD = function()
			if IsUsableSpell(howId) then
				return GetCooldown(howId)
			end
			return 100
		end,
		info = "Hammer of Wrath",
	},
	hw = {
		id = hwId,
		GetCD = function()
			return GetCooldown(hwId)
		end,
		info = "Holy Wrath",
	},
	fw = {
		id = hwId,
		GetCD = function()
			if (UnitHealth("target") / UnitHealthMax("target")) < 0.2 then
				return GetCooldown(hwId)
			end
			return 100
		end,
		info = "Final Wrath at under 20% hp",
	},
	cons = {
		id = consId,
		GetCD = function()
			return GetCooldown(consId)
		end,
		info = "Consecration",
	},
	es = {
		id = esId,
		GetCD = function()
			return GetCooldown(esId)
		end,
		info = "Execution Sentence",
		reqTalent = 17609,
	},
	hpr = {
		id = hprId,
		GetCD = function()
			return GetCooldown(hprId)
		end,
		info = "Holy Prism",
		reqTalent = 17605,
	},
	lh = {
		id = lhId,
		GetCD = function()
			return GetCooldown(lhId)
		end,
		info = "Light's Hammer",
		reqTalent = 17607,
	},
	ss = {
		id = ssId,
		GetCD = function()
			if s_ss <= 1 then
				return s_gcd + 1
			end
			return 100
		end,
		info = "Sacred Shield",
		reqTalent = 21098,
	},
	ssx = {
		id = ssId,
		GetCD = function()
			if s_ss <= 2 then
				return s_gcd
			end
			return 100
		end,
		info = "Sacred Shield with high priority",
		reqTalent = 21098,
	},
}
mod.actions = actions
--------------------------------------------------------------------------------


function mod:UpdateQueue()
	-- normal queue
	qn = {}
	for v in string.gmatch(db.prio, "[^ ]+") do
		if actions[v] then
			table.insert(qn, v)
		else
			print("clcInfo", modName, "invalid action:", v)
		end
	end
	db.prio = table.concat(qn, " ")

	-- force reconstruction for q
	qTaint = true
end


local function GetBuff(buff)
	local left, _, expires
	_, _, _, _, _, _, expires = UnitBuff("player", buff, nil, "PLAYER")
	if expires then
		left = expires - s_ctime - s_gcd
		if left < 0 then left = 0 end
	else
		left = 0
	end
	return left
end

-- weakened blows
--[[
local function GetDebuffWB()
	local left, _, expires
	_, _, _, _, _, _, expires = UnitDebuff("target", debuffWB, nil)
	if expires then
		left = expires - s_ctime - s_gcd
		if left < 0 then left = 0 end
	else
		left = 0
	end
	s_wb = left
end
]]--

-- special case for SS
local function GetBuffSS()
	-- parse all buffs and look for id
	local i = 1
	local name, _, _, _, _, _, expires, _, _, _, spellId = UnitAura("player", i, "HELPFUL")
	while name do
		if spellId == buffSS then break end
		i = i + 1
		name, _, _, _, _, _, expires, _, _, _, spellId = UnitAura("player", i, "HELPFUL")
	end
	
	local left = 0
	if name and expires then
		left = max(0, expires - s_ctime - s_gcd)
	end
	s_ss = left
end

local function GetBastionStacks()
	local name, _, _, count = UnitBuff("player", buffBoG)
	if name then return count end
	return 0
end

-- reads all the interesting data
local function GetStatus()
	-- current time
	s_ctime = GetTime()
	
	-- gcd value
	local start, duration = GetSpellCooldown(gcdId)
	s_gcd = start + duration - s_ctime
	if s_gcd < 0 then s_gcd = 0 end
	
	-- the buffs
	s_aw = GetBuff(buffAW)
	s_gc = GetBuff(buffGC)
	GetBuffSS()

	-- the debuffs
	-- GetDebuffWB()
	
	-- client hp and haste
	s_hp = UnitPower("player", SPELL_POWER_HOLY_POWER)
	s_haste = 1 + UnitSpellHaste("player") / 100
end

-- remove all talents not available and present in rotation
-- adjust for modified skills present in rotation
local function GetWorkingQueue()
	-- check for final wrath glyph
	local glyphSpellId
	local hwglyph = false
	for i = 1, 3 do
		-- major glyphs are 2, 4, 6
		_, _, _, glyphSpellId = GetGlyphSocketInfo(i*2)
		if glyphSpellId == 54935 then -- glyph of final wrath
			hwglyph = true
			break
		end
	end

	q = {}
	local name, selected, available
	for k, v in pairs(qn) do
		-- see if it has a talent requirement
		if actions[v].reqTalent then
			-- see if the talent is activated
			_, name, _, selected, available = GetTalentInfoByID(actions[v].reqTalent, GetActiveSpecGroup())
			if name and selected and available then
				table.insert(q, v)
			end
		-- final wrath check
		elseif v == "fw" then
			if hwglyph then table.insert(q, v) end
		else
			table.insert(q, v)
		end
	end

	-- adjust consecration depending on glyph
	local consx = false
	for i = 1, 3 do
		-- major glyphs are 2, 4, 6
		_, _, _, glyphSpellId = GetGlyphSocketInfo(i*2)
		if glyphSpellId == 54928 then
			consx = true
			break
		end
	end

	if consx then
		-- ranged consecration detected
		-- switch spellid for actions
		actions["cons"].id = consxId
		s_consId = consxId
	else
		actions["cons"].id = consId
		s_consId = consId
	end

	-- for k, v in pairs(q) do print(k, v) end
end

local function GetNextAction()
	-- check if working queue needs updated due to glyph talent changes
	if qTaint then
		GetWorkingQueue()
		qTaint = false
	end


	local n = #q
	
	-- parse once, get cooldowns, return first 0
	for i = 1, n do
		local action = actions[q[i]]
		local cd = action.GetCD()
		if debug.enabled then
			debug:AddBoth(q[i], cd)
		end
		if cd == 0 then
			return action.id, q[i]
		end
		action.cd = cd
	end
	
	-- parse again, return min cooldown
	local minQ = 1
	local minCd = actions[q[1]].cd
	for i = 2, n do
		local action = actions[q[i]]
		if minCd > action.cd then
			minCd = action.cd
			minQ = i
		end
	end
	return actions[q[minQ]].id, q[minQ]
end

local function ProtRotation()
	s1 = nil
	GetStatus()
	if debug.enabled then
		debug:Clear()
		debug:AddBoth("ctime", s_ctime)
		debug:AddBoth("gcd", s_gcd)
		debug:AddBoth("hp", s_hp)
		debug:AddBoth("haste", s_haste)
	end
	local action
	s1, action = GetNextAction()
	if debug.enabled then
		debug:AddBoth("s1", action)
	end

	-- if s1 == csId and s_wb < 5 then s1 = hotrId end

	s2 = nil
	if IsUsableSpell(sotrId) then
		if GetBastionStacks() == 5 then
			s2 = wogId
		else
			s2 = sotrId
		end
	end
end


-- plug in
--------------------------------------------------------------------------------
local secondarySkill
function emod.IconProtection1(...)
	ProtRotation(...)
	if secondarySkill then secondarySkill:DoUpdate() end
	return emod.IconSpell(s1, db.rangePerSkill or csName)
end
local function SecondaryExec()
	return emod.IconSpell(s2, db.rangePerSkill or csName)
end
local function ExecCleanup2()
	secondarySkill = nil
end
function emod.IconProtection2(...)
	secondarySkill = emod.___e
	secondarySkill:SetScript("OnUpdate", nil)
	secondarySkill.exec = SecondaryExec
	secondarySkill.ExecCleanup = ExecCleanup2
end

-- giving queue as command line
local function CmdProt(args)
	db.prio = table.concat(args, " ")
	mod:UpdateQueue()
	clcInfo:UpdateOptions()
end
clcInfo.cmdList["protprio"] = CmdProt

-- event frame
ef = CreateFrame("Frame")
ef:Hide()
ef:SetScript("OnEvent", function() qTaint = true end)
ef:RegisterEvent("PLAYER_TALENT_UPDATE")





-- prot paladin cooldown micon
do
	local namelist = {
	}
	--[[
		["Guardian of Ancient Kings"] = true,
		["Ardent Defender"] = true,
		["Divine Protection"] = true,
		["Pain Suppression"] = true,
		["Guardian Spirit"] = true,
		["Hand of Sacrifice"] = true,
		["Hand of Purity"] = true,
		["Devotion Aura"] = true,
		["Hand of Protection"] = true,
		["Divine Shield"] = true,
		["Power Word: Barrier"] = true,
		["Ironbark"] = true,
		["Shield of Glory"] = true,
	}
	

	local idlist = {
		[20925] = true,	-- sacred shield
	}
	--]]
	local idlist = {
		[20925] = true, --Sacred Shield
		[31850] = true, --Guardian of Ancient Kings
		[86659] = true, --Ardent Defender
		[498] = true, --Divine Protection
		[33206] = true, --Pain Suppression
		[47788] = true, --Guardian Spirit
		[6940] = true, --Hand of Sacrifice
		[114039] = true, --Hand of Purity
		[31821] = true, --Devotion Aura
		[1022] = true, --Hand of Protection
		[642] = true, --Divine Shield
		[1044] = true, --Hand of Freedom
		[81782] = true, --Power Word: Barrier
		[102342] = true, --Ironbark
		[116849] = true, --Life Cocoon
		[145629] = true, --Anti-Magic Zone
		[98021] = true, --Spirit Link Totem
		[172106] = true, -- Aspect of the Fox
		[159916] = true, --Amplify Magic
		[97463] = true, --Rallying Cry
		[114030] = true, --Vigilance
		[165447] = true, --Faith Barricade T17 2P
		[167742] = true, --Defender of the Light T17 4P
	}

	-- player only
	local namepolist = {
	}	

	local idpolist = {
		[20925] = true,	-- sacred shield
	}

	function emod.MIconProtPCooldowns()
		local found = false
		local i = 1
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura("player", i, "HELPFUL")
		while name do
			if namelist[name] or idlist[spellId] then
				found = true
				-- test for player only buffs
				if (namepolist[name] or idpolist[spellId]) and unitCaster ~= "player" then found = false end
				
				if found then
					if count <= 1 then count = nil end
					emod.___e:___AddIcon(nil, icon, expirationTime - duration, duration, 1, true, count)
				end
			end
			i = i + 1
			found = false
			name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura("player", i, "HELPFUL")
		end
	end
end

