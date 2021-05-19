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
if class ~= "HUNTER" then return end

local _, xmod = ...

xmod.marksmanmodule = {}
xmod = xmod.marksmanmodule

local qTaint = true -- will force queue check

-- 
local GetTime, GetSpellCooldown, UnitBuff, UnitAura, UnitPower, UnitSpellHaste, UnitHealth, UnitHealthMax, GetActiveSpecGroup, GetTalentInfoByID, GetGlyphSocketInfo, IsUsableSpell, GetShapeshiftForm, max, min =
GetTime, GetSpellCooldown, UnitBuff, UnitAura, UnitPower, UnitSpellHaste, UnitHealth, UnitHealthMax, GetActiveSpecGroup, GetTalentInfoByID, GetGlyphSocketInfo, IsUsableSpell, GetShapeshiftForm, max, min
local db


xmod.version = 8000001
xmod.defaults = {
	version = xmod.version,
	prio = "moc sting ss_sf ks dt ss es ws v rf aimless arc_p ss",
	rangePerSkill = false,
}

-- @defines
--------------------------------------------------------------------------------
local idGCD = 185358 -- arcane shot for gcd

-- racials
local idArcaneTorrent = 80483
local idBagOfTricks = 312411

-- spells
local idArcaneShot = 185358
local idHuntersMark = 257284
local idSteadyShot = 56641
local idKillShot = 53351
local idAimedShot = 19434
local idMultiShot = 2643
local idRapidFire = 257044
local idTrueshot = 288613

-- talents
local idSerpentSting = 271788
local idAMurderOfCrows = 131894
local idBarrage = 120360
local idExplosiveShot = 212431
local idChimaeraShot = 342049
local idDoubleTap = 260402
local idVolley = 260243

-- covenants
local idWildSpirit = 328520

-- buffs
local ln_buff_PreciseShots = GetSpellInfo(260242)
local ln_buff_Trueshot = GetSpellInfo(288613)
local ln_buff_Streamline = GetSpellInfo(342076)
local ln_buff_DoubleTap = GetSpellInfo(260402)
local ln_buff_SteadyFocus = GetSpellInfo(193534)
local ln_buff_LockAndLoad = GetSpellInfo(194594)



-- debuffs
local ln_debuff_SerpentSting = GetSpellInfo(259491)


-- status vars
local s1, s2
local s_ctime, s_otime, s_gcd, s_hp, s_dp, s_aw, s_ss, s_dc, s_fv, s_bc, s_haste, s_in_execute_range
--local s_OverpowerCharges = 0
local s_buff_PreciseShots, s_buff_Trueshot, s_buff_Streamline, s_buff_DoubleTap, s_buff_SteadyFocus, s_buff_LockAndLoad
local s_debuff_SerpentSting


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

--local function GetOPData()
--	local charges, maxCharges, start, duration = GetSpellCharges(idOverpower)
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

	--Arcane Torrent
	at = {
		id = idArcaneTorrent,
		GetCD = function()
			if (s1 ~= idArcaneTorrent) and (IsSpellKnown(80483)) then
				return GetCooldown(idArcaneTorrent)
			end
			return 100
		end,
			UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = max(100, s_hp + 15)

		end,
		info = "Arcane Torrent",
	},

	--Bag o tricks
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
		info = "Bag Of Tricks",
	},


	--Arcane Shot
	arc = {
		id = idArcaneShot,
		GetCD = function()
			if (s1 ~= idArcaneShot) and (s_hp > 19) then
				return GetCooldown(idArcaneShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 20)
		end,
		info = "Arcane Shot",

	},

	--Arcane Shot w/precise shot buff
	arc_p = {
		id = idArcaneShot,
		GetCD = function()
			if (s1 ~= idArcaneShot) and (s_buff_PreciseShots > 1) and (s_hp > 19) then
				return GetCooldown(idArcaneShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 20)
		end,
		info = "Arcane Shot w/Precise Shots buff (+75% Dmg)",

	},

	--Steady Shot
	ss = {
		id = idSteadyShot,
		GetCD = function()
			if (s1 ~= idSteadyShot) and (GetCooldown(idAimedShot) > 2) and (GetCooldown(idRapidFire) > 2) and (s_buff_PreciseShots < 1) then
				return GetCooldown(idSteadyShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = max(100, s_hp + 10)
		end,
		info = "Steady Shot",

	},

	--Steady Shot w/ steady focus
	ss_sf = {
		id = idSteadyShot,
		GetCD = function()
			if (s1 ~= idSteadyShot) and (s_buff_SteadyFocus < 2) then
				return GetCooldown(idSteadyShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = max(100, s_hp + 10)
		end,
		info = "Steady Shot w/Steady Focus buff (Talent)",
		reqTalent = 22267,
	},

	--kill shot
	ks = {
		id = idKillShot,
		GetCD = function()
			if (s1 ~= idKillShot) and IsUsableSpell(idKillShot) and (s_hp > 10) then
				return GetCooldown(idKillShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 10)
		end,
		info = "Kill Shot",

	},


	--Aimed Shot
	aim = {
		id = idAimedShot,
		GetCD = function()
			if (s1 ~= idAimedShot) and (s_hp > 35) then
				return GetCooldown(idAimedShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 35)
		end,
		info = "Aimed Shot",

	},

	--Aimed Shot w/o precise shot buff
	aimless = {
		id = idAimedShot,
		GetCD = function()
			if (s1 ~= idAimedShot) and (s_buff_PreciseShots < 1) and (s_hp > 35)  then
				return GetCooldown(idAimedShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 35)
		end,
		info = "Aimed Shot with NO Precise Shots up",

	},

	--Aimed Shot w/ lock n load
	aim_lnl = {
		id = idAimedShot,
		GetCD = function()
			if (s1 ~= idAimedShot) and (s_buff_LockAndLoad > 1) then
				return GetCooldown(idAimedShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 35)
		end,
		info = "Aimed Shot w/Lock n Load Proc (Talent)",

	},


	--Aimed Shot w/ streamline talent buff
	aim_s = {
		id = idAimedShot,
		GetCD = function()
			if (s1 ~= idAimedShot) and (s_buff_Streamline > 1) and (s_hp > 35) then
				return GetCooldown(idAimedShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 35)
		end,
		info = "Aimed Shot w/Streamline buff (Talent)",

	},

	--Aimed Shot w/ double tap talent buff
	aim_dt = {
		id = idAimedShot,
		GetCD = function()
			if (s1 ~= idAimedShot) and (s_buff_DoubleTap > 1) then
				return GetCooldown(idAimedShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 35)
		end,
		info = "Aimed Shot w/Double Tap buff (Talent)",

	},

	--Aimed Shot w/ stream and double tap talent buffs
	aim_s_dt = {
		id = idAimedShot,
		GetCD = function()
			if (s1 ~= idAimedShot) and (s_buff_Streamline > 1) and (s_buff_DoubleTap > 1) then
				return GetCooldown(idAimedShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 35)
		end,
		info = "Aimed Shot w/Streamline and Double Tap buffs (Talents)",

	},


	--Multi Shot
--	ms = {
--		id = idMultiShot,
--		GetCD = function()
--			if (s1 ~= idMultiShot) and (s_hp > 20) then
--				return GetCooldown(idMultiShot)
--			end
--			return 100
--		end,
--		UpdateStatus = function()
--			s_ctime = s_ctime + s_gcd + 1.5
--			s_hp = min(100, s_hp - 20)
--		end,
--		info = "Multi Shot",
--
--	},

	--Rapid Fire
	rf = {
		id = idRapidFire,
		GetCD = function()
			if (s1 ~= idRapidFire) then
				return GetCooldown(idRapidFire)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = max(100, s_hp + 3)
		end,
		info = "Rapid Fire",

	},

	--Rapid Fire w/ Double tap talent buff
	rf_dt = {
		id = idRapidFire,
		GetCD = function()
			if (s1 ~= idRapidFire) and (s_buff_DoubleTap > 1) then
				return GetCooldown(idRapidFire)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = max(100, s_hp + 3)
		end,
		info = "Rapid Fire w/Double Tap buff (Talent)",

	},

	------------
	--Cooldowns
	------------

	--trueshot
	ts = {
		id = idTrueshot,
		GetCD = function()
			if (s1 ~= idTrueshot) and (s_buff_Trueshot < 2) then
				return GetCooldown(idTrueshot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
		end,
		info = "Trueshot",

	},

	----------
	--Talents
	----------

	--serpent sting
	sting = {
		id = idSerpentSting,
		GetCD = function()
			if (s1 ~= idSerpentSting) and (s_debuff_SerpentSting < 3) and (s_hp > 10) then
				return GetCooldown(idSerpentSting)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 10)
		end,
		info = "Serpent Sting (Talent)",
		reqTalent = 22501,
	},

	--murder of crows
	moc = {
		id = idAMurderOfCrows,
		GetCD = function()
			if (s1 ~= idAMurderOfCrows) and (s_hp > 20) then
				return GetCooldown(idAMurderOfCrows)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 20)
		end,
		info = "A Murder Of Crows (Talent)",
		reqTalent = 22289,
	},

	--barrage
	b = {
		id = idBarrage,
		GetCD = function()
			if (s1 ~= idBarrage) and (s_hp > 20)then
				return GetCooldown(idBarrage)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 20)
		end,
		info = "Barrage (Talent)",
		reqTalent = 22497,
	},

	--explosive shot
	es = {
		id = idExplosiveShot,
		GetCD = function()
			if (s1 ~= idExplosiveShot) and (s_hp > 30) then
				return GetCooldown(idExplosiveShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 30)
		end,
		info = "Explosive Shot(Talent)",
		reqTalent = 22498,
	},

	--Chimaera Shot
	cs = {
		id = idChimaeraShot,
		GetCD = function()
			if (s1 ~= idChimaeraShot) and (s_hp > 20) then
				return GetCooldown(idChimaeraShot)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
			s_hp = min(100, s_hp - 20)
		end,
		info = "Chimaera Shot (Talent)",
		reqTalent = 21998,
	},

	--Double Tap
	dt = {
		id = idDoubleTap,
		GetCD = function()
			if (s1 ~= idDoubleTap) then
				return GetCooldown(idDoubleTap)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
		end,
		info = "Double Tap (Talent)",
		reqTalent = 22287,
	},

	--volley
	v = {
		id = idVolley,
		GetCD = function()
			if (s1 ~= idVolley) then
				return GetCooldown(idVolley)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5
		end,
		info = "Volley (Talent)",
		reqTalent = 22288,
	},


	--------------------
	--Covenant Abilities
	--------------------

	--Wild Spirit Night Fae
	ws = {
		id = idWildSpirit,
		GetCD = function()
		UiMapID = C_Map.GetBestMapForUnit("player")
			if (s1 ~= idWildSpirit) and ((C_QuestLog.IsQuestFlaggedCompleted(60600) and (UiMapID == 1565) and (not(C_QuestLog.IsQuestFlaggedCompleted(57878)))) or IsSpellKnown(328520)) then
				return GetCooldown(idSummer)
			end
			return 100
		end,
		UpdateStatus = function()
			s_ctime = s_ctime + s_gcd + 1.5 / s_haste

		end,
		info = "Wild Spirit (Night Fae)",
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



	-- --------------



	-- the buffs
	s_buff_PreciseShots = GetBuff(ln_buff_PreciseShots)
	s_buff_Trueshot = GetBuff(ln_buff_Trueshot)
	s_buff_Streamline = GetBuff(ln_buff_Streamline)
	s_buff_DoubleTap = GetBuff(ln_buff_DoubleTap)
	s_buff_SteadyFocus = GetBuff(ln_buff_SteadyFocus)
	s_buff_LockAndLoad = GetBuff(ln_buff_LockAndLoad)


	-- the debuffs
	s_debuff_SerpentSting = GetDebuff(ln_debuff_SerpentSting)


	-- Overpower stacks
--	local cd, charges = GetOPData()
--	s_OverpowerCharges = charges


	-- client rage and haste
	s_hp = UnitPower("player", 2)
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
	s_buff_PreciseShots = max(0, s_buff_PreciseShots - s_otime)
	s_buff_Trueshot = max(0, s_buff_Trueshot - s_otime)
	s_buff_Streamline = max(0, s_buff_Streamline - s_otime)
	s_buff_DoubleTap = max(0, s_buff_DoubleTap - s_otime)
	s_buff_SteadyFocus = max(0, s_buff_SteadyFocus - s_otime)
	s_buff_LockAndLoad = max(0, s_buff_LockAndLoad - s_otime)

	-- adjust debuffs
	s_debuff_SerpentSting = max(0, s_debuff_SerpentSting - s_otime)


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
local ef = CreateFrame("Frame", "clcinfoModuleEventFrame") -- event frame
ef:Hide()
local function OnEvent()
	qTaint = true

end
ef:SetScript("OnEvent", OnEvent)
ef:RegisterEvent("PLAYER_ENTERING_WORLD")
ef:RegisterEvent("PLAYER_TALENT_UPDATE")
ef:RegisterEvent("PLAYER_LEVEL_UP")
