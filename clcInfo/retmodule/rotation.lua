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
if class ~= "PALADIN" then return end

local _, xmod = ...

xmod.retmodule = {}
xmod = xmod.retmodule

local qTaint = true -- will force queue check

-- thanks cremor
local GetTime, GetSpellCooldown, UnitBuff, UnitAura, UnitPower, UnitSpellHaste, UnitHealth, UnitHealthMax, GetActiveSpecGroup, GetTalentInfoByID, GetGlyphSocketInfo, IsUsableSpell, GetShapeshiftForm, max, min, SPELL_POWER_HOLY_POWER =
GetTime, GetSpellCooldown, UnitBuff, UnitAura, UnitPower, UnitSpellHaste, UnitHealth, UnitHealthMax, GetActiveSpecGroup, GetTalentInfoByID, GetGlyphSocketInfo, IsUsableSpell, GetShapeshiftForm, max, min, SPELL_POWER_HOLY_POWER
local db

-- debug if clcInfo detected
local debug
if clcInfo then debug = clcInfo.debug end

xmod.version = 8000001
xmod.defaults = {
	version = xmod.version,
	prio = "bless j s5 s fr esfr esj tvv woa vh4 tvdp tv ha_es vhj ds ash boj how dt cs2 cs cons",
	rangePerSkill = false,
	howclash = 0, -- priority time for hammer of wrath
	csclash = 0, -- priority time for cs
	exoclash = 0, -- priority time for exorcism
	ssduration = 0, -- minimum duration on ss buff before suggesting refresh
}

-- @defines
--------------------------------------------------------------------------------
local idGCD = 85256 -- tv for gcd

-- spells
local idTemplarsVerdict = 85256
local idCrusaderStrike = 35395
local idJudgement = 20271
local idConsecration = 26573
local idJusticarsVengeance = 215661
local idWakeOfAshes = 255937
local idExecutionSentence = 343527
local idHammerOfJustice = 853
local idDivineStorm = 53385
local idArcaneTorrent = 155145
local idHoW = 24275
local idSer = 152262
local idBladeOfJustice = 184575
local idDivineStorm = 53385
local idAvengingWrath = 31884
local idWord = 85673
local idFinal = 343721
local idHolyAvenger = 105809


-- ------------------------
-- ---Covenant Abilities---
-- ------------------------

local idVanq = 328204
local idToll = 304971
local idAsh = 316958
local idSummer = 328620
local idAutumn = 328622
local idWinter = 328281
local idSpring = 328282

-- ------
-- buffs
-- ------

local ln_buff_TheFiresOfJustice = GetSpellInfo(209785)
local ln_buff_DivinePurpose = GetSpellInfo(223819)
local ln_buff_aow = GetSpellInfo(281178)
local ln_buff_rv = GetSpellInfo(267611)
local ln_buff_ds = GetSpellInfo(286393)
local ln_buff_ds2 = GetSpellInfo(326733)
local ln_buff_aw = GetSpellInfo(31884)
local ln_buff_ha = GetSpellInfo(105809)
local ln_buff_Vanq = GetSpellInfo(328204)

-- debuffs
local ln_debuff_Judgement = GetSpellInfo(197277)
local ln_debuff_Exec = GetSpellInfo(343527)
local ln_debuff_FinalReckoning = GetSpellInfo(343721)

-- status vars
local s1, s2
local s_ctime, s_otime, s_gcd, s_hp, s_dp, s_aw, s_ss, s_dc, s_fv, s_bc, s_haste, s_in_execute_range
local s_CrusaderStrikeCharges = 0
local s_CrucibleCharges = 0
local s_buff_DivinePurpose, s_buff_TheFiresOfJustice, s_buff_rv, s_buff_ds, s_buff_ds2, s_buff_aw, s_buff_ha, s_buff_vanq
local s_debuff_Judgement, s_debuff_Exec, s_debuff_FinalReckoning

local talent_DivinePurpose = false

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

--local function GetCSData()
--	local charges, maxCharges, start, duration = GetSpellCharges(idCrusaderStrike)
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

-- -------------------
-- /dump GetTalentInfo(row, column, 1)
-- s_hp = min(3, s_hp + 2) is telling the addon what hp you need to reach for tv
-- /dump UnitBuff("Player", 1)
-- /dump UnitDebuff("Target", 1)
-- -------------------

local UiMapID = C_Map.GetBestMapForUnit("player")

-- actions ---------------------------------------------------------------------
local actions = {

	--Arcane Torrent
	arc = {
		id = idArcaneTorrent,
		GetCD = function()
			if ((s1 ~= idArcaneTorrent) and (s_hp <= 2) and (IsSpellKnown(155145))) then
				return GetCooldown(idArcaneTorrent)
			end
			return 100
		end,
			UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				if (s_buff_ha > 0) then
					s_hp = min(3, s_hp + 3)
				else
					s_hp = min(3, s_hp + 1)
				end
		end,
		info = "Arcane Torrent",
	},

	--Consecration
	cons = {
		id = idConsecration,
		GetCD = function()
			if (s1 ~= idConsecration) and (IsSpellKnown(26573)) then
				return GetCooldown(idConsecration)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5 / s_haste

		end,
		info = "Consecration",
	},

	-- ----------------------------------
	-- Holy Power Generators
	-- ----------------------------------

	--Wake of Ashes
	woa = {
		id = idWakeOfAshes,
		GetCD = function()
			if ((s1 ~= idWakeOfAshes) and (s_hp <= 1)) and (IsSpellKnown(255937)) and (not(IsUsableSpell(idTemplarsVerdict))) then
				return GetCooldown(idWakeOfAshes)
			end
			return 100
		end,
			UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				if (s_buff_ha > 0) then
					s_hp = max(5, s_hp + 5)
				else
					s_hp = min(3, s_hp + 3)
				end
		end,
		info = "Wake Of Ashes",
	},

	--Judgment
	j = {
		id = idJudgement,
		GetCD = function()
			if s1 ~= idJudgement and (IsSpellKnown(20271)) and (not(IsUsableSpell(idTemplarsVerdict))) then
				return GetCooldown(idJudgement)
			end
			return 100 -- lazy stuff
		end,
			UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_debuff_Judgement = 8
				if (s_buff_ha > 0) then
					s_hp = min(3, s_hp + 3)
				else
					s_hp = min(3, s_hp + 1)
				end
		end,
		info = "Judgement",
	},

	--Crusader Strike @ 2 charges
	cs2 = {
		id = idCrusaderStrike,
		GetCD = function()
			if (s_hp < 3) and (not(IsUsableSpell(idTemplarsVerdict))) then
				return 0
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			if (s_buff_ha > 0) then
				s_hp = max(3, s_hp + 3)
			else
				s_hp = max(3, s_hp + 1)

			end
		end,
		info = "Crusader Strike stacks = 2",
	},

	--Crusader Strike
	cs = {
		id = idCrusaderStrike,
		GetCD = function()
			if (s_hp < 3) and (not(IsUsableSpell(idTemplarsVerdict))) then
				return 0
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			if (s_buff_ha > 0) then
				s_hp = min(3, s_hp + 3)
			else
				s_hp = min(3, s_hp + 1)

			end
		end,
		info = "Crusader Strike",
	},

	--Hammer of Wrath
	how = {
		id = idHoW,
		GetCD = function()
			if (s1 ~= idHoW) and IsUsableSpell(idHoW) and (IsSpellKnown(24275)) and (not(IsUsableSpell(idTemplarsVerdict))) then
				return GetCooldown(idHoW)
			end
			return 100
		end,
			UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				if (s_buff_ha > 0) then
					s_hp = min(3, s_hp + 3)
				else
					s_hp = min(3, s_hp + 1)
				end
		end,
		info = "Hammer of Wrath",
	},
	--Hammer of Wrath w/ Avenging Wrath
	how_aw = {
		id = idHoW,
		GetCD = function()
			if (s1 ~= idHoW) and IsUsableSpell(idHoW) and (s_buff_aw > 0) and (IsSpellKnown(24275)) and (not(IsUsableSpell(idTemplarsVerdict))) then
				return GetCooldown(idHoW)
			end
			return 100
		end,
			UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				if (s_buff_ha > 0) then
					s_hp = min(3, s_hp + 3)
				else
					s_hp = min(3, s_hp + 1)
				end
		end,
		info = "Hammer of Wrath during Avenging Wrath",
	},

	--Blade of Justice
	boj = {
		id = idBladeOfJustice,
		GetCD = function()
			if (s1 ~= idBladeOfJustice) and (s_hp <= 3) and (IsSpellKnown(184575)) and (not(IsUsableSpell(idTemplarsVerdict))) then
				return GetCooldown(idBladeOfJustice)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			if (s_buff_ha > 0) then
				s_hp = min(3, s_hp + 4)
			else
				s_hp = min(3, s_hp + 2)
			end
		end,
		info = "Blade of Justice",
	},
	--Blade of Justice w/ Art of War proc
	boj_aow = {
		id = idBladeOfJustice,
		GetCD = function()
			if (s1 ~= idBladeOfJustice) and (s_hp <= 3) and (s_buff_aow > 2) and (not(IsUsableSpell(idTemplarsVerdict))) then
				return GetCooldown(idBladeOfJustice)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			if (s_buff_ha > 0) then
				s_hp = min(3, s_hp + 4)
			else
				s_hp = min(3, s_hp + 2)
			end
		end,
		info = "Blade of Justice w/ Art of War Proc",
	},

	-- ----------------------------------
	-- Holy Power Consumers
	-- ----------------------------------

	--Divine Storm Proc
	ds = {
		id = idDivineStorm,
		GetCD = function()
			if (s_buff_ds > 1) or (s_buff_ds2 > 1) then
				return 0
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				s_hp = max(3, s_hp - 0)
		end,
		info = "Divine Storm w/ Empyrean Power Proc",
	},

	-- ----------------------------------
	-- Templar's Verdict
	-- ----------------------------------

	--Templar's Verdict dynamic
	tv = {
		id = idTemplarsVerdict,
		GetCD = function()
			if (s_hp >= 3) or ((s_hp >= 2) and (s_buff_TheFiresOfJustice > 0)) or (s_buff_DivinePurpose > 0) then
				return 0
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				s_hp = max(3, s_hp - 3)
		end,
		info = "Templar's Verdict at 3 Holy Power",
	},

	--Templar's Verdict dynamic
	tv5 = {
		id = idTemplarsVerdict,
		GetCD = function()
			if (s_hp >= 5) or ((s_hp >= 4) and (s_buff_TheFiresOfJustice > 0)) or (s_buff_DivinePurpose > 0) then
				return 0
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				s_hp = max(5, s_hp - 3)
		end,
		info = "Templar's Verdict at 5 Holy Power",
	},


	--Templar's Verdict w/ j
	tvj = {
		id = idTemplarsVerdict,
		GetCD = function()
			if (s_debuff_Judgement > 1) and ((s_hp >= 3) or ((s_hp >= 2) and (s_buff_TheFiresOfJustice > 0)) or (s_buff_DivinePurpose > 0)) then
				return 0
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				s_hp = max(3, s_hp - 3)
		end,
		info = "Templar's Verdict w/ Judgment Debuff",
	},

		--Templar's Verdict dynamic
	tvv = {
		id = idTemplarsVerdict,
		GetCD = function()
			if (s_buff_Vanq > 0) and ((s_hp >= 3) or ((s_hp >= 2) and (s_buff_TheFiresOfJustice > 0)) or (s_buff_DivinePurpose > 0)) then
				return 0
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				s_hp = max(3, s_hp - 3)
		end,
		info = "Templar's Verdict With Vanquisher's Hammer Buff (Necrolord)",
	},

	-- ----------------------------------
	-- Talents (Execution Sentence, etc)
	-- ----------------------------------

	--Final Reckoning
	fr = {
		id = idFinal,
		GetCD = function()
			if (s1 ~= idFinal) and (s_hp >= 2) then
				return GetCooldown(idFinal)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5 / s_haste

		end,
		info = "Final Reckoning",
		reqTalent = 22634,
	},

	--Execution Sentence no j
	es = {
		id = idExecutionSentence,
		GetCD = function()
			if (s_hp >= 3) or ((s_hp >= 2) and (s_buff_TheFiresOfJustice > 0)) or (s_hp >= 2 and s_buff_DivinePurpose > 0) then
				return GetCooldown(idExecutionSentence)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(3, s_hp - 3)

		end,
		info = "Execution Sentence",
		reqTalent = 23467,
	},

	--Execution Sentence w/ J up
	esj = {
		id = idExecutionSentence,
		GetCD = function()
			if (s_debuff_Judgement > 1) and ((s_hp >= 3) or ((s_hp >= 2) and (s_buff_TheFiresOfJustice > 0)) or (s_hp >= 2 and s_buff_DivinePurpose > 0)) then
				return GetCooldown(idExecutionSentence)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(3, s_hp - 3)

		end,
		info = "Execution Sentence w/ Judgment Debuff",
		reqTalent = 23467,
	},

	--Execution Sentence w/ J up and Final Reckoning Debuff
	esfr = {
		id = idExecutionSentence,
		GetCD = function()
			if (s_debuff_Judgement > 1) and ((GetCooldown(idFinal) > 1) and (s_debuff_FinalReckoning > 1)) and ((s_hp >= 3) or ((s_hp >= 2) and (s_buff_TheFiresOfJustice > 0)) or (s_hp >= 2 and s_buff_DivinePurpose > 0)) then
				return GetCooldown(idExecutionSentence)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(3, s_hp - 3)

		end,
		info = "Execution Sentence w/ Judgment and Final Reckoning Debuff",
		reqTalent = 23467, 22634, 
	},

	--Holy Avenger
	ha = {
		id = idHolyAvenger,
		GetCD = function()
			if s1 ~= idHolyAvenger then
				return GetCooldown(idHolyAvenger)
			end
			return 100

		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5 / s_haste
		end,
		info = "Holy Avenger",
		reqTalent = 17599,
	},

	--Holy Avenger w/ ES debuff
	ha_es = {
		id = idHolyAvenger,
		GetCD = function()
			if (s1 ~= idHolyAvenger) and (s_debuff_Exec > 2) then
				return GetCooldown(idHolyAvenger)
			end
			return 100

		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5 / s_haste
		end,
		info = "Holy Avenger with Execution Sentence debuff up",
		reqTalent = 17599,
	},

	-- -------------------------------
	-- Holy Power Consumers (Buffs)
	-- -------------------------------

	--Seraphim
	s = {
		id = idSer,
		GetCD = function()
			if (s_hp >= 3) or ((s_hp >= 2) and (s_buff_TheFiresOfJustice > 0)) or (s_buff_DivinePurpose > 0) then
				return GetCooldown(idSer)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				s_hp = max(3, s_hp - 3)
		end,
		info = "Seraphim",
		reqTalent = 17601,
	},

	--Seraphim w/5 HoPo
	s5 = {
		id = idSer,
		GetCD = function()
			if (s_hp >= 5) or ((s_hp >= 4) and (s_buff_TheFiresOfJustice > 0)) or (s_buff_DivinePurpose > 0) then
				return GetCooldown(idSer)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				s_hp = max(5, s_hp - 3)
		end,
		info = "Seraphim",
		reqTalent = 17601,
	},

	-- --------------------------------------------
	-- Divine Purpose Procs
	-- --------------------------------------------

	--Templar's Verdict with Divine Purpose
	tvdp = {
		id = idTemplarsVerdict,
		GetCD = function()
			if (s_buff_DivinePurpose > 0) then
				return 0
			end
			return 100
		end,
		UpdateStatus = function()
		end,
		info = "Templar's Verdict w/ DP Proc",
	},


	--Execution Sentence with DP up
	esdp = {
		id = idExecutionSentence,
		GetCD = function()
			if (s_buff_DivinePurpose > 0)  then
				return GetCooldown(idExecutionSentence)
			end
			return 100

		end,
		UpdateStatus = function()
		end,
		info = "Execution Sentence w/ DP Proc",
		reqTalent = 23467,
	},

	-- ----------------------------------
	-- Covenant Abilities
	-- ----------------------------------

	--Vanq Hamma no j
	vh = {
		id = idVanq,
		GetCD = function()
		UiMapID = C_Map.GetBestMapForUnit("player")
			if ((s_hp >= 1) or (s_buff_TheFiresOfJustice > 0) or (s_buff_DivinePurpose < 0)) and ((C_QuestLog.IsQuestFlaggedCompleted(60021) and (UiMapID == 1536) and (not(C_QuestLog.IsQuestFlaggedCompleted(57878)))) or IsSpellKnown(328204)) then
				return GetCooldown(idVanq)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(1, s_hp - 1)

		end,
		info = "Vanquisher's Hammer (Necrolord)",
	},

	--Vanq Hamma w/ j
	vh4 = {
		id = idVanq,
		GetCD = function()
		UiMapID = C_Map.GetBestMapForUnit("player")
			if ((s_hp >= 4) or ((s_buff_TheFiresOfJustice > 0) and (s_hp >=3)) or (s_buff_DivinePurpose < 0)) and ((C_QuestLog.IsQuestFlaggedCompleted(60021) and (UiMapID == 1536) and (not(C_QuestLog.IsQuestFlaggedCompleted(57878)))) or IsSpellKnown(328204)) then
				return GetCooldown(idVanq)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(1, s_hp - 1)

		end,
		info = "Vanquisher's Hammer (Necrolord) w/ 4 Holy Power",
	},

	--Vanq Hamma w/ j
	vhj = {
		id = idVanq,
		GetCD = function()
		UiMapID = C_Map.GetBestMapForUnit("player")
			if (s_debuff_Judgement > 1) and ((s_hp >= 1) or (s_buff_TheFiresOfJustice > 0) or (s_buff_DivinePurpose < 0)) and ((C_QuestLog.IsQuestFlaggedCompleted(60021) and (UiMapID == 1536) and (not(C_QuestLog.IsQuestFlaggedCompleted(57878)))) or IsSpellKnown(328204)) then
				return GetCooldown(idVanq)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(1, s_hp - 1)

		end,
		info = "Vanquisher's Hammer (Necrolord) w/ Judgment up",
	},

	--Divine Toll
	dt = {
		id = idToll,
		GetCD = function()
		UiMapID = C_Map.GetBestMapForUnit("player")
			if (s1 ~= idToll) and ((C_QuestLog.IsQuestFlaggedCompleted(60222) and (UiMapID == 1533) and (not(C_QuestLog.IsQuestFlaggedCompleted(57878)))) or IsSpellKnown(304971)) then
				return GetCooldown(idToll)
			end
			return 100 -- lazy stuff
		end,
			UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_debuff_Judgement = 8
				if (s_buff_ha > 0) then
					s_hp = min(3, s_hp + 3)
				else
					s_hp = min(3, s_hp + 1)
				end
		end,
		info = "Divine Toll (Kyrian)",
	},

	--Ashen Hallow
	ash = {
		id = idAsh,
		GetCD = function()
		UiMapID = C_Map.GetBestMapForUnit("player")
			if (s1 ~= idAsh) and ((C_QuestLog.IsQuestFlaggedCompleted(57179) and (UiMapID == 1525) and (not(C_QuestLog.IsQuestFlaggedCompleted(57878)))) or IsSpellKnown(316958)) then
				return GetCooldown(idAsh)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5 / s_haste

		end,
		info = "Ashen Hallow (Venthyr)",
	},

	--Blessings of the Night Fae
	bless = {
		id = idSummer,
		GetCD = function()
		UiMapID = C_Map.GetBestMapForUnit("player")
			if (s1 ~= idSummer) and ((C_QuestLog.IsQuestFlaggedCompleted(60600) and (UiMapID == 1565) and (not(C_QuestLog.IsQuestFlaggedCompleted(57878)))) or IsSpellKnown(328620)) then
				return GetCooldown(idSummer)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5 / s_haste

		end,
		info = "Blessings of The Night Fae",
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
			print("clcretmodule - invalid action:", v)
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


	-- the buffs
	if (talent_DivinePurpose) then
		s_buff_DivinePurpose = GetBuff(ln_buff_DivinePurpose)
	else
		s_buff_DivinePurpose = 0
	end
	s_buff_TheFiresOfJustice = GetBuff(ln_buff_TheFiresOfJustice)
	s_buff_DivinePurpose = GetBuff(ln_buff_DivinePurpose)
	s_buff_aow = GetBuff(ln_buff_aow)
	s_buff_rv = GetBuff(ln_buff_rv)
	s_buff_ds = GetBuff(ln_buff_ds)
	s_buff_ds2 = GetBuff(ln_buff_ds2)
	s_buff_aw = GetBuff(ln_buff_aw)
	s_buff_ha = GetBuff(ln_buff_ha)
	s_buff_Vanq = GetBuff(ln_buff_Vanq)

	-- the debuffs
	s_debuff_Judgement = GetDebuff(ln_debuff_Judgement)
	s_debuff_Exec = GetDebuff(ln_debuff_Exec)
	s_debuff_FinalReckoning = GetDebuff(ln_debuff_FinalReckoning)

	-- crusader strike stacks
--	local cd, charges = GetCSData()
--	s_CrusaderStrikeCharges = charges

	-- client hp and haste
	s_hp = UnitPower("player", 9)
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

		debug:AddBoth("dJudgement", s_debuff_Judgement)
		debug:AddBoth("bDivinePurpose", s_buff_DivinePurpose)
		debug:AddBoth("bTFOJ", s_buff_TheFiresOfJustice)
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
	s_buff_TheFiresOfJustice = max(0, s_buff_TheFiresOfJustice - s_otime)
	s_buff_DivinePurpose = max(0, s_buff_DivinePurpose - s_otime)	
	s_buff_rv = max(0, s_buff_rv - s_otime)
	s_buff_ds = max(0, s_buff_ds - s_otime)
	s_buff_ds2 = max(0, s_buff_ds2 - s_otime)
	s_buff_aw = max(0, s_buff_aw - s_otime)
	s_buff_ha = max(0, s_buff_ha - s_otime)
	s_buff_Vanq = max(0, s_buff_Vanq - s_otime)

	-- crusader strike stacks
--	local cd, charges = GetCSData()
--	s_CrusaderStrikeCharges = charges
--	if (s1 == idCrusaderStrike) then
--		s_CrusaderStrikeCharges = s_CrusaderStrikeCharges - 1
--
--	end




	if debug and debug.enabled then
		debug:AddBoth("csc", s_CrusaderStrikeCharges)
	end

	if debug and debug.enabled then
		debug:AddBoth("ctime", s_ctime)
		debug:AddBoth("otime", s_otime)
		debug:AddBoth("gcd", s_gcd)
		debug:AddBoth("hp", s_hp)
		debug:AddBoth("haste", s_haste)
		debug:AddBoth("dJudgement", s_debuff_Judgement)
		debug:AddBoth("bDivinePurpose", s_buff_DivinePurpose)
		debug:AddBoth("bTFOJ", s_buff_TheFiresOfJustice)
	end
	s2, action = GetNextAction()
	if debug and debug.enabled then
		debug:AddBoth("s2", action)
	end

	return s1, s2
end

-- event frame
local ef = CreateFrame("Frame", "clcRetModuleEventFrame") -- event frame
ef:Hide()
local function OnEvent()
	qTaint = true

	-- DivinePurpose talent
	local _, name, _, selected, available = GetTalentInfoByID(22215, GetActiveSpecGroup())
	if name and selected and available then
		talent_DivinePurpose = selected
	end




end
ef:SetScript("OnEvent", OnEvent)
ef:RegisterEvent("PLAYER_ENTERING_WORLD")
ef:RegisterEvent("PLAYER_TALENT_UPDATE")
ef:RegisterEvent("PLAYER_LEVEL_UP")