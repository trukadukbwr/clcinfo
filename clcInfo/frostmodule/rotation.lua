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
if class ~= "DEATHKNIGHT" then return end

local _, xmod = ...

xmod.frostmodule = {}
xmod = xmod.frostmodule

local qTaint = true -- will force queue check

-- 
local GetTime, GetSpellCooldown, UnitBuff, UnitAura, UnitPower, UnitSpellHaste, UnitHealth, UnitHealthMax, GetActiveSpecGroup, GetTalentInfoByID, GetGlyphSocketInfo, IsUsableSpell, GetShapeshiftForm, max, min =
GetTime, GetSpellCooldown, UnitBuff, UnitAura, UnitPower, UnitSpellHaste, UnitHealth, UnitHealthMax, GetActiveSpecGroup, GetTalentInfoByID, GetGlyphSocketInfo, IsUsableSpell, GetShapeshiftForm, max, min
local db


xmod.version = 8000001
xmod.defaults = {
	version = xmod.version,
	prio = "how emp rd hb pof bos ff ch scy ob_km hbr fs_obl swarm rw glac fs ds ob hbr dnd",
	rangePerSkill = false,
}

-- @defines
--------------------------------------------------------------------------------
local idGCD = 47541 -- death coil for gcd

-- racials
local idArcaneTorrent = 50613
local idBagOfTricks = 312411

-- spells
local idEmpowerRuneWeapon = 47568
local idDeathCoil = 47541
local idDeathStrike = 49998
local idLichborne = 49039
local idRaiseDead = 46585
local idPillarOfFrost = 51271
local idRemorselessWinter = 196770
local idDeathAndDecay = 43265
local idFrostwyrmsFury = 279302
local idHowlingBlast = 49184
local idObliterate = 49020
local idFrostStrike = 49143
local idChainsOfIce = 45524
local idHornOfWinter = 57330
local idFrostscythe = 207230
local idGlacialAdvance = 194913
local idBreathOfSindragosa = 152279
local idHypothermicPresence = 321995
local idSacrificialPact = 327574

-- covenant spells
local idVampire = 311648

-- buffs
local ln_buff_Rime = GetSpellInfo(59052)
local ln_buff_KillingMachine = GetSpellInfo(51128)
local ln_buff_ColdHeart = GetSpellInfo(281209)
-- could also be 281209 <notice the 9 instead of 8
local ln_buff_RemorselessWinter = GetSpellInfo(196770)
local ln_buff_HypothermicPresence = GetSpellInfo(321995)
local ln_buff_DarkSuccor = GetSpellInfo(101568)
local ln_buff_PillarOfFrost = GetSpellInfo(51271)

-- debuffs
local ln_debuff_FrostFever = GetSpellInfo(55095)

-- status vars
local s1, s2
local s_ctime, s_otime, s_gcd, s_hp, s_dp, s_aw, s_ss, s_dc, s_fv, s_bc, s_haste, s_in_execute_range
local s_buff_Rime, s_buff_KillingMachine, s_buff_ColdHeart, s_buff_RemorselessWinter, s_buff_HypothermicPresence, s_buff_DarkSuccor, s_buff_PillarOfFrost
local s_debuff_FrostFever


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


-- actions ---------------------------------------------------------------------
local actions = {
		--Arcane Torrent
	arc = {
			id = idArcane,
		GetCD = function()
			if (s1 ~= idArcane) and (IsSpellKnown(155145)) then
				return GetCooldown(idArcane)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Arcane Torrent",
	},

		-- Bag o tricks
	bag = {
			id = idBagOfTricks,
		GetCD = function()
			if (s1 ~= idBagOfTricks) and (IsSpellKnown(312411))then
				return GetCooldown(idBagOfTricks)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Bag Of Tricks",
	},

	-- --------------------------------------

		-- emp rune wep with sub 80 runic power
	emp = {
			id = idEmpowerRuneWeapon,
		GetCD = function()
			if (s1 ~= idEmpowerRuneWeapon) and (s_rp < 80) and ((level < 0) or (level > 62)) then
				return GetCooldown(idEmpowerRuneWeapon)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Empower Rune Weapon (Boss Fights)",
	},

		-- Death coil if no other spell is in range
--	dc = {
--			id = idDeathCoil,
--		GetCD = function()
--			if (s1 ~= idDeathCoil) and (s_rp > 39) then
--				return GetCooldown(idDeathCoil)
--			end
--			return 100
--		end,
--		UpdateStatus = function()
--			s_ctime = s_ctime + s_gcd + 1.5
--
--		end,
--		info = "Death Coil at ranged distance",
--	},


		-- Death strike w/ dark succor proc
	ds = {
			id = idDeathStrike,
		GetCD = function()
			if (s1 ~= idDeathStrike) and (s_buff_DarkSuccor > 1) then
				return GetCooldown(idDeathStrike)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Death Strike with Dark Succor proc",
	},

		-- Raise Dead
	rd = {
			id = idRaiseDead,
		GetCD = function()
			level = UnitLevel("target")
			if (s1 ~= idRaiseDead) and ((level < 0) or (level > 62)) then
				return GetCooldown(idRaiseDead)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Raise Dead (Boss Fights)",
	},

		-- Sacrificial Pact
	sac = {
			id = idSacrificialPact,
			GetCD = function()
			seconds = GetTotemTimeLeft(1)
			if (s1 ~= idSacrificialPact) and (s_rp > 20) and (GetCooldown(idRaiseDead) > 60) and (seconds < 5) then
				return GetCooldown(idSacrificialPact)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Sacririficial Pact with <5 seconds remaining",
	},


		-- pillar of frost
	pof = {
			id = idPillarOfFrost,
		GetCD = function()
			if (s1 ~= idPillarOfFrost) then
				return GetCooldown(idPillarOfFrost)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Pillar Of Frost",
	},

		-- remorseless winter
	rw = {
			id = idRemorselessWinter,
		GetCD = function()
			if (s1 ~= idRemorselessWinter) and (s_rune >= 1) then
				return GetCooldown(idRemorselessWinter)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Remorseless Winter",
	},

		-- dnd
	dnd = {
			id = idDeathAndDecay,
		GetCD = function()
			if (s1 ~= idDeathAndDecay) and (s_rune >= 1) then
				return GetCooldown(idDeathAndDecay)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Death and Decay",
	},

		-- frostwyrms fury
	ff = {
			id = idFrostwyrmsFury,
		GetCD = function()
			level = UnitLevel("target")
			if (s1 ~= idFrostwyrmsFury) and ((level < 0) or (level > 62)) then
				return GetCooldown(idFrostwyrmsFury)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Frostwyrm's Fury (Boss Fights)",
	},

		-- howling blast
	hb = {
			id = idHowlingBlast,
		GetCD = function()
			if (s_rune >=1) and (s1 ~= idHowlingBlast) and (s_debuff_FrostFever < 3) then
				return GetCooldown(idHowlingBlast)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Howling Blast to apply Frost Fever",
	},

		-- howling blast w/rime proc
	hbr = {
			id = idHowlingBlast,
		GetCD = function()
			if (s1 ~= idHowlingBlast) and (s_buff_Rime > 1) then
				return GetCooldown(idHowlingBlast)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Howling Blast w/ Rime proc",
	},

		-- frost strike
	fs = {
			id = idFrostStrike,
		GetCD = function()
			if (s1 ~= idFrostStrike) and ((s_rp > 90) or ((s_buff_Rime < 2) and (s_rp > 25) or (((s_rp > 16) and (s_buff_HypothermicPresence > 1))))) then
				return GetCooldown(idFrostStrike)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Frost Strike",
	},

		-- obliterate
	ob = {
			id = idObliterate,
		GetCD = function()
			if (s1 ~= idObliterate) and (s_rp < 95) and (s_rune >= 2) and (s_buff_Rime < 2) then
				return GetCooldown(idObliterate)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Obliterate",
	},

		-- obliterate w/ killing machine for gauranteed crit
	ob_km = {
			id = idObliterate,
		GetCD = function()
			if (s1 ~= idObliterate) and (s_rp < 95) and (s_rune >= 2) and (s_buff_KillingMachine > 1) and (s_buff_Rime < 2) then
				return GetCooldown(idObliterate)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Obliterate w/Killing Machine proc (Guaranteed Crit)",
	},

		-- frost strike
	fs_obl = {
			id = idFrostStrike,
		GetCD = function()
			if (s1 ~= idFrostStrike) and (s_rune < 1) and (s_buff_PillarOfFrost > 1) and (s_rp > 25) or (((s_rp > 16) and (s_buff_HypothermicPresence > 1))) then
				return GetCooldown(idFrostStrike)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Frost Strike w/ Obliteration talent, Pillar of Frost active, and no runes to spend on Obliterate",
		reqTalent = 22109,
	},

		-- horn of winter w/ less then 25 runi cpower
	how = {
			id = idHornOfWinter,
		GetCD = function()
			if (s1 ~= idHornOfWinter) and (s_rp < 20) then
				return GetCooldown(idHornOfWinter)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Horn Of Winter w/ less then 25 runic power",
		reqTalent = 22021,
	},

		-- frostscythe w/killing machine proc
	scy = {
			id = idFrostscythe,
		GetCD = function()
			if (s1 ~= idFrostscythe) and (s_buff_KillingMachine > 1) then
				return GetCooldown(idFrostscythe)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Frostscythe w/ Killing Machine proc",
		reqTalent = 22525,
	},

		-- Glacial advance
	glac = {
			id = idGlacialAdvance,
		GetCD = function()
			if (s1 ~= idGlacialAdvance) and ((s_rp > 90) or ((s_rp > 30) or (((s_rp > 17) and (s_buff_HypothermicPresence > 1))))) then
				return GetCooldown(idGlacialAdvance)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Glacial Advance",
		reqTalent = 22535,
	},

		-- Sindragosa's breath
	bos = {
			id = idBreathOfSindragosa,
		GetCD = function()
			if (s1 ~= idBreathOfSindragosa) and (s_rp > 90) and (s_rune < 3) then
				return GetCooldown(idBreathOfSindragosa)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Breath Of Sindragosa",
		reqTalent = 22537,
	},

		-- chains of ice w/ coldheart @ 20 stacks
	ch = {
			id = idChainsOfIce,
		GetCD = function()
		name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
  nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod
= GetPlayerAuraBySpellID(281209)

			if (s1 ~= idChainsOfIce) and (count == 20) then
				return GetCooldown(idChainsOfIce)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Chains of Ice w/ Cold Heart @ 20 Stacks",
	},

-- -------------------
-- Covenant Abilities
-- -------------------

	--Swarming Mist
	swarm = {
		id = idVampire,
		GetCD = function()
		UiMapID = C_Map.GetBestMapForUnit("player")
			if (s1 ~= idVampire) and (s_rune >= 1) and ((C_QuestLog.IsQuestFlaggedCompleted(57179) and (UiMapID == 1525) and (not(C_QuestLog.IsQuestFlaggedCompleted(57878))) and (not(C_QuestLog.IsQuestFlaggedCompleted(62000)))) or IsSpellKnown(311648)) then
				return GetCooldown(idVampire)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5 / s_haste

		end,
		info = "Swarming Mist (Venthyr)",
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
			print("slashrendmodule - invalid action:", v)
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

	s_buff_Rime = GetBuff(ln_buff_Rime)
	s_buff_KillingMachine = GetBuff(ln_buff_KillingMachine)
	s_buff_ColdHeart = GetBuff(ln_buff_ColdHeart)
	s_buff_RemorselessWinter = GetBuff(ln_buff_RemorselessWinter)
	s_buff_HypothermicPresence = GetBuff(ln_buff_HypothermicPresence)
	s_buff_DarkSuccor = GetBuff(ln_buff_DarkSuccor)
	s_buff_PillarOfFrost = GetBuff(ln_buff_PillarOfFrost)

	-- the debuffs
	s_debuff_FrostFever = GetDebuff(ln_debuff_FrostFever)


	-- client runic power, runes, and haste
	s_rp = UnitPower("player", 6)
	s_rune = UnitPower("player", 5)
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
		debug:AddBoth("hp", s_hp)
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
	s_buff_Rime = max(0, s_buff_Rime - s_otime)
	s_buff_KillingMachine = max(0, s_buff_KillingMachine - s_otime)
--	s_buff_Coldheart = max(0, s_buff_Coldheart - s_otime)
	s_buff_RemorselessWinter = max(0, s_buff_RemorselessWinter - s_otime)
	s_buff_HypothermicPresence = max(0, s_buff_HypothermicPresence - s_otime)
	s_buff_DarkSuccor = max(0, s_buff_DarkSuccor - s_otime)
	s_buff_PillarOfFrost = max(0, s_buff_PillarOfFrost - s_otime)

	-- adjust debuffs
	s_debuff_FrostFever = max(0, s_debuff_FrostFever - s_otime)

	if debug and debug.enabled then
		debug:AddBoth("csc", s_CrusaderStrikeCharges)
	end

	if debug and debug.enabled then
		debug:AddBoth("ctime", s_ctime)
		debug:AddBoth("otime", s_otime)
		debug:AddBoth("gcd", s_gcd)
		debug:AddBoth("hp", s_hp)
		debug:AddBoth("haste", s_haste)

	end
	s2, action = GetNextAction()
	if debug and debug.enabled then
		debug:AddBoth("s2", action)
	end

	return s1, s2
end

-- event frame
local ef = CreateFrame("Frame", "frostdkModuleEventFrame") -- event frame
ef:Hide()
local function OnEvent()
	qTaint = true


end
ef:SetScript("OnEvent", OnEvent)
ef:RegisterEvent("PLAYER_ENTERING_WORLD")
ef:RegisterEvent("PLAYER_TALENT_UPDATE")
ef:RegisterEvent("PLAYER_LEVEL_UP")
