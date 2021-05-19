-- Thanks to Shibou for the API Wrapper code

-- Pulls back the Addon-Local Variables and store them locally.
local addonName, addonTable = ...;
local addon = _G[addonName];

-- Store local copies of Blizzard API and other addon global functions and variables
local GetBuildInfo = GetBuildInfo;
local select, setmetatable, table, type, unpack = select, setmetatable, table, type, unpack;

addonTable.CURRENT_WOW_VERSION = select(4, GetBuildInfo());

local Prototype = {


	-- API Version History
	-- 8.0 - Dropped second parameter (nameSubtext).
	--     - Also, no longer supports querying by spell name.
	UnitBuff = function(...)
		if addonTable.CURRENT_WOW_VERSION >= 80000 then
			local unitID, ID = ...;

			if type(ID) == "string" then
				for counter = 1, 40 do
					local auraName = UnitBuff(unitID, counter);

					if ID == auraName then
						return UnitBuff(unitID, counter);
					end
				end
			end
		else
			local parameters = { UnitBuff(...) };

			table.insert(parameters, 2, "dummyReturn");

			return unpack(parameters);
		end
	end,

	-- API Version History
	-- 8.0 - Dropped second parameter (nameSubtext).
	--     - Also, no longer supports querying by spell name.
	UnitDebuff = function(...)
		if addonTable.CURRENT_WOW_VERSION >= 80000 then
			local unitID, ID = ...;

			if type(ID) == "string" then
				for counter = 1, 40 do
					local auraName = UnitDebuff(unitID, counter);

					if ID == auraName then
						return UnitDebuff(unitID, counter);
					end
				end
			end
		else
			local parameters = { UnitDebuff(...) };

			table.insert(parameters, 2, "dummyReturn");

			return unpack(parameters);
		end
	end,


};

local MT = {
	__index = function(table, key)
		local classPrototype = Prototype[key];

		if classPrototype then
			if type(classPrototype) == "function" then
				return function(...)
					return classPrototype(...);
				end
			else
				return classPrototype;
			end
		else
			return function(...)
				return _G[key](...);
			end
		end
	end,
};

APIWrapper = setmetatable({}, MT);


-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "SHAMAN" then return end

local _, xmod = ...

xmod.elementalmodule = {}
xmod = xmod.elementalmodule

local qTaint = true -- will force queue check

-- 
local GetTime, GetSpellCooldown, UnitBuff, UnitAura, UnitPower, UnitSpellHaste, UnitHealth, UnitHealthMax, GetActiveSpecGroup, GetTalentInfoByID, GetGlyphSocketInfo, IsUsableSpell, GetShapeshiftForm, max, min =
GetTime, GetSpellCooldown, UnitBuff, UnitAura, UnitPower, UnitSpellHaste, UnitHealth, UnitHealthMax, GetActiveSpecGroup, GetTalentInfoByID, GetGlyphSocketInfo, IsUsableSpell, GetShapeshiftForm, max, min
local db


xmod.version = 8000001
xmod.defaults = {
	version = xmod.version,
	prio = "flame lava_surge f_ele earth80 eb sk echo lava_echo vt lmt light_sk_master light_wg ice frost_ice_master lava earth frost_ice sd light",
	rangePerSkill = false,
}

-- @defines
--------------------------------------------------------------------------------
local idGCD = 8042 -- earth shock for gcd

-- racials
local idBagOfTricks = 312411

-- spells
local idLightningShield = 192106
local idFlameShock = 188389
local idEarthShock = 8042
local idFrostShock = 196840
local idLavaBurst = 51505
local idLightningBolt = 188196
local idEarthElemental = 198103
local idFireElemental = 198067

-- Talents
local idStaticDischarge = 342243
local idEchoingShock = 320125
local idElementalBlast = 117014
local idLiquidMagmaTotem = 192222
local idIcefury = 210714
local idStormkeeper = 191634
local idAscendance = 114050

-- Covenant Abilities
local idVesperTotem = 324386
local idChainHarvest = 320674
local idPrimordialWave = 326059
local idFaeTransfusion = 328923

-- buffs
local ln_buff_LightningShield = GetSpellInfo(192106)
local ln_buff_EchoingShock = GetSpellInfo(320125)
local ln_buff_Icefury = GetSpellInfo(210714)
local ln_buff_MasterOfTheElements = GetSpellInfo(260734)
local ln_buff_WindGust = GetSpellInfo(263806)
local ln_buff_LavaSurge = GetSpellInfo(77762)
local ln_buff_StormKeeper = GetSpellInfo(191634)



-- debuffs
local ln_debuff_FlameShock = GetSpellInfo(188389)


-- status vars
local s1, s2
local s_ctime, s_otime, s_gcd, s_ms, s_dp, s_aw, s_ss, s_dc, s_fv, s_bc, s_haste, s_in_execute_range
local s_LavaBurstCharges = 0
local s_buff_LightningShield, s_buff_EchoingShock, s_buff_Icefury, s_buff_MasterOfTheElements, s_buff_WindGust, s_buff_LavaSurge, s_buff_Stormkeeper
local s_debuff_FlameShock


-- the queue
local qn = {} -- normal queue
local q -- working queue

local function GetCooldown(id)
	local start, duration = GetSpellCooldown(id)
	if start == nil then return 100 end
	local cd = start + duration - s_ctime - s_gcd
	if cd < 0 then return 0 end
	return cd
end

--local function GetLBData()
--	local charges, maxCharges, start, duration = GetSpellCharges(idLavaBurst)
--	if (charges >= 2) then
--		return 0, 2
--	end
--
--	if start == nil then
--		return 100, charges
--	end
--	local cd = start + duration - s_ctime - s_gcd
--	if cd < 0 then
--		return 0, min(2, charges + 1)
--	end
--
--	return cd, charges
--end


-- actions ---------------------------------------------------------------------
local actions = {

		-- Bag o tricks
	bag = {
			id = idBagOfTricks,
		GetCD = function()
			if (s1 ~= idBagOfTricks) and (IsSpellKnown(312411)) then
				return GetCooldown(idBagOfTricks)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Bag Of Tricks (Vulpera Racial)",
	},
	
	-- Lightning Shield

	ls = {
			id = idLightningShield,
		GetCD = function()
			if (s1 ~= idLightningShield) and (s_buff_LightningShield < 120) then
				return GetCooldown(idLightningShield)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Lightning Shield",
	},

	-- Earth Shock
	earth = {
		id = idEarthShock,
		GetCD = function()
			if (s1 ~= idEarthShock) and (s_ms > 60) then
				return GetCooldown(idEarthShock)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_ms = min(100, s_ms - 60)
		end,
		info = "Earth Shock",

	},

	-- Earth Shock
	earth80 = {
		id = idEarthShock,
		GetCD = function()
			if (s1 ~= idEarthShock) and (s_ms > 80) then
				return GetCooldown(idEarthShock)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_ms = min(100, s_ms - 60)
		end,
		info = "Earth Shock above 80 maelstrom",

	},

	-- flame Shock
	flame = {
		id = idFlameShock,
		GetCD = function()


		name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
  nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod
= GetPlayerAuraBySpellID(263806)


			if (s1 ~= idFlameShock) and (s_debuff_FlameShock < 3) or ((s_debuff_FlameShock < 3) and (s_buff_WindGust > 0) and (count < 20)) then
				return GetCooldown(idFlameShock)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
		end,
		info = "Flame Shock",


	}, 

	-- frost Shock w/icefury
	frost_ice = {
		id = idFrostShock,
		GetCD = function()
			if (s1 ~= idFrostShock) and (s_buff_Icefury > 1) then
				return GetCooldown(idFrostShock)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
		end,
		info = "Frost Shock w/ Icefury up (talent)",
		reqTalent = 23111,

	}, 

	-- frost Shock w/ icefury and master of the elements buff
	frost_ice_master = {
		id = idFrostShock,
		GetCD = function()
			if (s1 ~= idFrostShock) and (s_buff_Icefury > 1) and (s_buff_MasterOfTheElements > 1) then
				return GetCooldown(idFrostShock)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
		end,
		info = "Frost Shock w/ Icefury and Master of the Elements up (talents)",
		reqTalent = 19271,

	}, 

	-- Lava Burst
	lava = {
		id = idLavaBurst,
		GetCD = function()
			if (s1 ~= idLavaBurst) then
				return GetCooldown(idLavaBurst)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_ms = max(100, s_ms + 10)
		end,
		info = "Lava Burst",
	},

	-- Lava Burst w/ Lava Surge buff
	lava_surge = {
		id = idLavaBurst,
		GetCD = function()
			if (s1 ~= idLavaBurst) and (s_buff_LavaSurge > 1) then
				return GetCooldown(idLavaBurst)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_ms = max(100, s_ms + 10)
		end,
		info = "Lava Burst",
	},

	--lava burst @ 2 charges
--	lava2 = {
--		id = idLavaBurst,
--		GetCD = function()
--			if (s1 ~= idLavaBurst) then
--				return GetCooldown(idLavaBurst)
--			end
--			return 100
--		end,
--		UpdateStatus = function()
--			s_ctime = s_ctime + s_gcd + 1.5
--			s_ms = max(100, s_ms + 10)
--			s_LavaBurstCharges = max(2, s_LavaBurstCharges - 1)
--
--		end,
--		info = "Lava Burst = 2",
--		reqTalent = 22357,
--	},

	-- Lava Burst w/Echoing Shock buff
	lava_echo = {
		id = idLavaBurst,
		GetCD = function()
			if (s1 ~= idLavaBurst) and (s_buff_EchoingShock > 1) then
				return GetCooldown(idLavaBurst)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_ms = max(100, s_ms + 10)
		end,
		info = "Lava Burst w/ Echoing Shock buff (talent)",
		reqTalent = 23460,

	},

	-- Lightning Bolt
	light = {
		id = idLightningBolt,
		GetCD = function()
			if (s1 ~= idLightningBolt) then
				return GetCooldown(idLightningBolt)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_ms = max(100, s_ms + 8)
		end,
		info = "Lightning Bolt",

	},

	-- Lightning Bolt w/ sk and master of ele
	light_sk_master = {
		id = idLightningBolt,
		GetCD = function()
			if (s1 ~= idLightningBolt) and (s_buff_MasterOfTheElements > 1) and (s_buff_Stormkeeper > 1) then
				return GetCooldown(idLightningBolt)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_ms = max(100, s_ms + 8)
		end,
		info = "Lightning Bolt",

	},

	-- Lightning Bolt w/ over 18 stacks of wind gust (storm ele talent)
	light_wg = {
		id = idLightningBolt,
		GetCD = function()


		name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
  nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod
= GetPlayerAuraBySpellID(263806)


			if (s1 ~= idLightningBolt) and ((s_buff_WindGust > 0) and (count > 17)) then
				return GetCooldown(idLightningBolt)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_ms = max(100, s_ms + 8)
		end,
		info = "Lightning Bolt w/ over 18 stacks of Wind Gust (Storm Elemental Talent)",

	},


	-- Fire Elemental
	f_ele = {
		id = idFireElemental,
		GetCD = function()
			level = UnitLevel("target")
			if (s1 ~= idFireElemental) and ((level < 0) or (level > 62)) then
				return GetCooldown(idFireElemental)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
		end,
		info = "Fire Elemental (or Storm if talented) on Boss Fights",
	},

	-- Earth Elemental
	e_ele = {
		id = idEarthElemental,
		GetCD = function()
			level = UnitLevel("target")
			if (s1 ~= idEarthElemental) and ((level < 0) or (level > 62)) then
				return GetCooldown(idEarthElemental)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
		end,
		info = "Earth Elemental on Boss Fights",
	},

	-- ----------------
	-- Talents
	-- ----------------

	-- Static Discharge
	sd = {
		id = idStaticDischarge,
		GetCD = function()
			if (s1 ~= idStaticDischarge) and (s_buff_LightningShield > 30) then
				return GetCooldown(idStaticDischarge)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Static Discharge (talent)",
		reqTalent = 22358,
	},


	-- Echoing Shock
	echo = {
			id = idEchoingShock,
		GetCD = function()
			if (s1 ~= idEchoingShock) and ((GetCooldown(idLavaBurst) < 2) or (s_ms > 60)) then
				return GetCooldown(idEchoingShock)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Echoing Shock (talent)",
		reqTalent = 23460,

	},

	-- Elemental Blast
	eb = {
			id = idElementalBlast,
		GetCD = function()
			if (s1 ~= idElementalBlast) then
				return GetCooldown(idElementalBlast)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Elemental Blast (talent)",
		reqTalent = 23190,

	},

	-- Liquid Magma Totem
	lmt = {
			id = idLiquidMagmaTotem,
		GetCD = function()
			if (s1 ~= idLiquidMagmaTotem) then
				return GetCooldown(idLiquidMagmaTotem)
			end
			return 0.5
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Liquid Magma Totem (Talent)",
		reqTalent = 19273,

	},

	-- Icefury
	ice = {
			id = idIcefury,
		GetCD = function()
			if (s1 ~= idIcefury) and (GetCooldown(idFrostShock) < 2) then
				return GetCooldown(idIcefury)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_ms = max(100, s_ms + 25 )
		end,
		info = "Icefury (talent)",
		reqTalent = 23111,

	},

	-- stormkeeper
	sk = {
			id = idStormkeeper,
		GetCD = function()
			if (s1 ~= idStormkeeper) then
				return GetCooldown(idStormkeeper)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
		end,
		info = "Stormkeeper",
		reqTalent = 22153,

	},

	-- ----------------------------------
	-- Covenant Abilities
	-- ----------------------------------

	--Vesper Totem
	vt = {
		id = idVesperTotem,
		GetCD = function()
		UiMapID = C_Map.GetBestMapForUnit("player")
			if ((C_QuestLog.IsQuestFlaggedCompleted(60021) and (UiMapID == 1536) and (not(C_QuestLog.IsQuestFlaggedCompleted(57878))) and (not(C_QuestLog.IsQuestFlaggedCompleted(62000)))) or IsSpellKnown(324386)) then
				return GetCooldown(idVesperTotem)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Vesper Totem (Kyrian)",
	},


}
--------------------------------------------------------------------------------



local function UpdateQueue()
	-- normal queue
	qn = {}
	for v in string.gmatch(db.prio, "[^ ]+") do
		if actions[v] then
			table.insert(qn, v)
		else
			print("elemental module - invalid action:", v)
		end
	end
	db.prio = table.concat(qn, " ")

	-- force reconstruction for q
	qTaint = true
end

local function GetBuff(buff)

	local left = 0
	local _, expires
	_, _, _, _, _, expires = APIWrapper.UnitBuff("player", buff, nil, "PLAYER")
	if expires then
		left = max(0, expires - s_ctime - s_gcd)
	end
	return left
end

local function GetDebuff(debuff)
	local left = 0
	local _, expires
	_, _, _, _, _, expires = APIWrapper.UnitDebuff("target", debuff, nil, "PLAYER")
	if expires then
		left = max(0, expires - s_ctime - s_gcd)
	end
	return left
end

-- reads all the interesting data // List of Buffs
local function GetStatus()
	-- current time
	s_ctime = GetTime()

	-- gcd value
	local start, duration = GetSpellCooldown(idGCD)
	s_gcd = start + duration - s_ctime
	if s_gcd < 0 then s_gcd = 0 end

--------------

	-- the buffs
	s_buff_LightningShield = GetBuff(ln_buff_LightningShield)
	s_buff_EchoingShock = GetBuff(ln_buff_EchoingShock)
	s_buff_Icefury = GetBuff(ln_buff_Icefury)
	s_buff_MasterOfTheElements = GetBuff(ln_buff_MasterOfTheElements)
	s_buff_WindGust = GetBuff(ln_buff_WindGust)
	s_buff_LavaSurge = GetBuff(ln_buff_LavaSurge)
	s_buff_Stormkeeper = GetBuff(ln_buff_Stormkeeper)

	-- the debuffs
	s_debuff_FlameShock = GetDebuff(ln_debuff_FlameShock)

	-- Lava Bust stacks
--	local cd, charges = GetLBData()
--	s_LavaBurstCharges = charges

	-- client rage and haste
	s_ms = UnitPower("player", 11)
	s_haste = 1 + UnitSpellHaste("player") / 100
end

-- remove all talents not available and present in rotation
-- adjust for modified skills present in rotation
local function GetWorkingQueue()
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
		else
			table.insert(q, v)
		end
	end
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
		if debug and debug.enabled then
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

-- exposed functions

-- this function should be called from addons
function xmod.Init()
	db = xmod.db
	UpdateQueue()
end

function xmod.GetActions()
	return actions
end

function xmod.Update()
	UpdateQueue()
end

function xmod.Rotation()
	s1 = nil
	GetStatus()
	if debug and debug.enabled then
		debug:Clear()
		debug:AddBoth("ctime", s_ctime)
		debug:AddBoth("gcd", s_gcd)
		debug:AddBoth("ms", s_ms)
		debug:AddBoth("haste", s_haste)

	end
	local action
	s1, action = GetNextAction()
	if debug and debug.enabled then
		debug:AddBoth("s1", action)
		debug:AddBoth("s1Id", s1)
	end
	-- 
	s_otime = s_ctime -- save it so we adjust buffs for next
	actions[action].UpdateStatus()

	s_otime = s_ctime - s_otime

	-- adjust buffs
	s_buff_LightningShield = max(0, s_buff_LightningShield - s_otime)
	s_buff_EchoingShock = max(0, s_buff_EchoingShock - s_otime)
	s_buff_Icefury = max(0, s_buff_Icefury - s_otime)
	s_buff_MasterOfTheElements = max(0, s_buff_MasterOfTheElements - s_otime)
	s_buff_WindGust = max(0, s_buff_WindGust - s_otime)
	s_buff_LavaSurge = max(0, s_buff_LavaSurge - s_otime)
	s_buff_Stormkeeper = max(0, s_buff_Stormkeeper - s_otime)

	-- adjust debuffs
	s_debuff_FlameShock = max(0, s_debuff_FlameShock - s_otime)

	-- Lava Burst stacks
--	local cd, charges = GetLBData()
--	s_LavaBurstCharges = charges
--	if (s1 == idLavaBurst) then
--		s_LavaBurstCharges = s_LavaBurstCharges - 1
--
--	end

	if debug and debug.enabled then
		debug:AddBoth("csc", s_LavaBurstCharges)
	end

	-- -----------------------------------

	if debug and debug.enabled then
		debug:AddBoth("ctime", s_ctime)
		debug:AddBoth("otime", s_otime)
		debug:AddBoth("gcd", s_gcd)
		debug:AddBoth("ms", s_ms)
		debug:AddBoth("haste", s_haste)

	end
	s2, action = GetNextAction()
	if debug and debug.enabled then
		debug:AddBoth("s2", action)
	end

	return s1, s2
end

-- event frame
local ef = CreateFrame("Frame", "ElementalModuleEventFrame") -- event frame
ef:Hide()
local function OnEvent()
	qTaint = true


end
ef:SetScript("OnEvent", OnEvent)
ef:RegisterEvent("PLAYER_ENTERING_WORLD")
ef:RegisterEvent("PLAYER_TALENT_UPDATE")
ef:RegisterEvent("PLAYER_LEVEL_UP")
