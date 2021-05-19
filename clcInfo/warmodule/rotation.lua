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
if class ~= "WARRIOR" then return end

local _, xmod = ...

xmod.warmodule = {}
xmod = xmod.warmodule

local qTaint = true -- will force queue check

-- 
local GetTime, GetSpellCooldown, UnitBuff, UnitAura, UnitPower, UnitSpellHaste, UnitHealth, UnitHealthMax, GetActiveSpecGroup, GetTalentInfoByID, GetGlyphSocketInfo, IsUsableSpell, GetShapeshiftForm, max, min =
GetTime, GetSpellCooldown, UnitBuff, UnitAura, UnitPower, UnitSpellHaste, UnitHealth, UnitHealthMax, GetActiveSpecGroup, GetTalentInfoByID, GetGlyphSocketInfo, IsUsableSpell, GetShapeshiftForm, max, min
local db


xmod.version = 8000001
xmod.defaults = {
	version = xmod.version,
	prio = "cru2 cru bs opx skull cs ex ms r s",
	rangePerSkill = false,
}

-- @defines
--------------------------------------------------------------------------------
local idGCD = 1464 -- slam for gcd

-- spells
local idSlam = 1464
local idSkullsplitter = 260643
local idMortalStrike = 12294
local idVictoryRush = 34428
local idRend = 772
local idExecute = 163201
local idBladestorm = 227847
local idBladeDummy = 227847
local idColossusSmash = 167105
local idWarbreaker = 262161
local idOverpower = 7384
local idHeroicThrow = 57755
local idArcane = 69179
local idCharge = 100
local idRavager = 152277
local idStormBolt = 107570
local idWhirlwind = 1680



-- buffs
local ln_buff_DeadlyCalm = GetSpellInfo(262228)
local ln_buff_Crush = GetSpellInfo(278826)

-- debuffs
local ln_debuff_DeepWounds = GetSpellInfo(262115)
local ln_debuff_Colossus = GetSpellInfo(208086)
local ln_debuff_Rend = GetSpellInfo(772)
local ln_debuff_Razor = GetSpellInfo(303568)

-- status vars
local s1, s2
local s_ctime, s_otime, s_gcd, s_hp, s_dp, s_aw, s_ss, s_dc, s_fv, s_bc, s_haste, s_in_execute_range
local s_OverpowerCharges = 0
local s_buff_DeadlyCalm, s_buff_Crush
local s_debuff_DeepWounds, s_debuff_Razor, s_debuff_Rend, s_debuff_Colossus


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

local function GetOPData()
	local charges, maxCharges, start, duration = GetSpellCharges(idOverpower)
	if (charges >= 2) then
		return 0, 2
	end

	if start == nil then
		return 100, charges
	end
	local cd = start + duration - s_ctime - s_gcd
	if cd < 0 then
		return 0, min(2, charges + 1)
	end

	return cd, charges
end


-- actions ---------------------------------------------------------------------
local actions = {
		--1	Arcane Torrent
	arc = {
			id = idArcane,
		GetCD = function()
			if (s1 ~= idArcane) and (s_hp < 10) and (GetCooldown(idBladestorm) > 2) then
				return GetCooldown(idArcane)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
				s_hp = max(100, s_hp + 15)

		end,
		info = "Arcane Torrent",
	},

	--2	Colossus Smash
	cs = {
		id = idColossusSmash,
		GetCD = function()
			if (s1 ~= idColossusSmash) and (GetCooldown(idWarbreaker) <1) then
				return GetCooldown(idColossusSmash)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = max(100, s_hp + 30)
		end,
		info = "Colossus Smash",

	},



	--3	Rend
	r = {
		id = idRend,
		GetCD = function()
			if (s1 ~= idRend) and (s_debuff_Rend < 2) and (s_hp > 29) and ((GetCooldown(idBladestorm) > 2) or (GetCooldown(idRavager) > 0)) then
				return GetCooldown(idRend)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 30)
		end,
		info = "Rend",
		reqTalent = 19138,
	},

	--4	Slam
	s = {
		id = idSlam,
		GetCD = function()
			if (s1 ~= idSlam) and (s_hp > 19) and (GetCooldown(idMortalStrike) > 1) and ((GetCooldown(idBladestorm) > 2) or (GetCooldown(idRavager) > 0)) then
				return GetCooldown(idSlam)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 20)

		end,
		info = "Slam / WW w/Fervor of Battle",

	},


	--4b	Slam or WW w/Fervor AND Crushing assault az trait up
	sca = {
		id = idSlam,
		GetCD = function()
			if (s1 ~= idSlam) and (s_hp > 9) and (s_buff_Crush > 1) then
				return GetCooldown(idSlam)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp + 10)
		end,
		info = "Slam / WW w/Fervor of Battle AND Crushing Assault up",

	},

	--4x		Skullsplitter
	skull = {
		id = idSkullsplitter,
		GetCD = function()
			if (s1 ~= idSkullsplitter) and (GetCooldown(idSkullsplitter) < 2) and (s_hp < 57) and ((GetCooldown(idBladestorm) > 2) or (GetCooldown(idRavager) > 0)) then
				return GetCooldown(idSkullsplitter)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = max(100, s_hp + 20)

		end,
		info = "Skullsplitter",
	},


	--5	Mortal Strike
	ms = {
			id = idMortalStrike,
		GetCD = function()
			if (s1 ~= idMortalStrike) and ((GetCooldown(idBladestorm) > 2) or (GetCooldown(idRavager) > 0)) then
				return GetCooldown(idMortalStrike)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 30)

		end,
		info = "Mortal Strike",
	},

	--6	Execute
	ex = {
			id = idExecute,
		GetCD = function()
			if (s1 ~= idExecute) and IsUsableSpell(idExecute) and (s_hp > 20) and ((GetCooldown(idBladestorm) > 2) or (GetCooldown(idRavager) > 0)) then
				return GetCooldown(idExecute)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5

		end,
		info = "Execute",
	},

	--7	Bladestorm
	bs = {
			id = idBladeDummy,
		GetCD = function()
			if (s1 ~= idBladeStorm) then
				return GetCooldown(idBladestorm)
			end
			return 0.5
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = max(100, s_hp + 50)

		end,
		info = "Bladestorm",
	},

	--9a	Overpower
	opx = {
			id = idOverpower,
		GetCD = function()
			if (s1 ~= idOverpower) and ((GetCooldown(idBladestorm) > 2) or (GetCooldown(idRavager) > 0)) then
				return GetCooldown(idOverpower)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = max(100, s_hp + 25 )
		end,
		info = "Overpower",
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

	s_buff_DeadlyCalm = GetBuff(ln_buff_DeadlyCalm)
	s_buff_Crush = GetBuff(ln_buff_Crush)

	-- the debuffs
	s_debuff_DeepWounds = GetDebuff(ln_debuff_DeepWounds)
	s_debuff_Colossus = GetDebuff(ln_debuff_Colossus)
	s_debuff_Rend = GetDebuff(ln_debuff_Rend)
	s_debuff_Razor = GetDebuff(ln_debuff_Razor)


	-- Overpower stacks
--	local cd, charges = GetOPData()
--	s_OverpowerCharges = charges


	-- client rage and haste
	s_hp = UnitPower("player", 1)
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
	s_buff_DeadlyCalm = max(0, s_buff_DeadlyCalm - s_otime)
	s_buff_Crush = max(0, s_buff_Crush - s_otime)

	-- adjust debuffs
	s_debuff_Colossus = max(0, s_debuff_Colossus - s_otime)
	s_debuff_Razor = max(0, s_debuff_Razor - s_otime)
	s_debuff_Rend = max(0, s_debuff_Rend - s_otime)
	s_debuff_DeepWounds = max(0, s_debuff_DeepWounds - s_otime)

	-- Overpower stacks
--	local cd, charges = GetOPData()
--	s_OverpowerCharges = charges
--	if (s1 == idOverpower) then
--		s_OverpowerCharges = s_OverpowerCharges - 1
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

	end
	s2, action = GetNextAction()
	if debug and debug.enabled then
		debug:AddBoth("s2", action)
	end

	return s1, s2
end

-- event frame
local ef = CreateFrame("Frame", "slashRendModuleEventFrame") -- event frame
ef:Hide()
local function OnEvent()
	qTaint = true


-- Tells addon to use WW in place of slam with fervor talent

	_, name, _, selected, available = GetTalentInfoByID(22489, GetActiveSpecGroup())
	if name and selected and available then
		idSlam = 1680
	end

	actions['s'].id = idSlam

	_, name, _, selected, available = GetTalentInfoByID(22380, GetActiveSpecGroup())
	if name and selected and available then
		idSlam = 1464
	end

	actions['s'].id = idSlam

	_, name, _, selected, available = GetTalentInfoByID(19138, GetActiveSpecGroup())
	if name and selected and available then
		idSlam = 1464
	end

	actions['s'].id = idSlam

-- Tells addon to use WW in place of slam with fervor talent w/ crushing assault azerite trait procced

	_, name, _, selected, available = GetTalentInfoByID(22489, GetActiveSpecGroup())
	if name and selected and available then
		idSlam = 1680
	end

	actions['sca'].id = idSlam

	_, name, _, selected, available = GetTalentInfoByID(22380, GetActiveSpecGroup())
	if name and selected and available then
		idSlam = 1464
	end

	actions['sca'].id = idSlam

	_, name, _, selected, available = GetTalentInfoByID(19138, GetActiveSpecGroup())
	if name and selected and available then
		idSlam = 1464
	end

	actions['sca'].id = idSlam

-- Tells addon to use Warbreaker in place of Colossus Smash

	_, name, _, selected, available = GetTalentInfoByID(22391, GetActiveSpecGroup())
	if name and selected and available then
		idColossusSmash = 262161
	end

	actions['cs'].id = idColossusSmash

	_, name, _, selected, available = GetTalentInfoByID(22392, GetActiveSpecGroup())
	if name and selected and available then
		idColossusSmash = 167105
	end

	actions['cs'].id = idColossusSmash

	_, name, _, selected, available = GetTalentInfoByID(22362, GetActiveSpecGroup())
	if name and selected and available then
		idColossusSmash = 167105
	end

	actions['cs'].id = idColossusSmash

-- Tells addon to use Ravager in place of Bladestorm

	_, name, _, selected, available = GetTalentInfoByID(21667, GetActiveSpecGroup())
	if name and selected and available then
		idBladestorm = 152277
	end

	actions['bs'].id = idBladestorm

	_, name, _, selected, available = GetTalentInfoByID(21204, GetActiveSpecGroup())
	if name and selected and available then
		idBladestorm = 227847
	end

	actions['bs'].id = idBladestorm
	_, name, _, selected, available = GetTalentInfoByID(21667, GetActiveSpecGroup())
	if name and selected and available then
		idBladestorm = 227847
	end

	actions['bs'].id = idBladestorm


end
ef:SetScript("OnEvent", OnEvent)
ef:RegisterEvent("PLAYER_ENTERING_WORLD")
ef:RegisterEvent("PLAYER_TALENT_UPDATE")
ef:RegisterEvent("PLAYER_LEVEL_UP")
