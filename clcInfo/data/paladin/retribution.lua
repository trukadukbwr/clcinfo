-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local modName = "__retribution"
local mod = clcInfo:RegisterClassModule(modName)
local emod = clcInfo.env
local db -- template based

local _, xmod = ...
xmod = xmod.retmodule

-- csName to pass as argument for melee range checks
local csName = GetSpellInfo(35395)


function mod.OnTemplatesUpdate()
	db = clcInfo:RegisterClassModuleTDB(modName, xmod.defaults)
	if db then
		if not db.version or db.version < xmod.version then
			-- fix stuff
			print("__retribution module/", "cleaning up saved vars")
			clcInfo.AdaptConfigAndClean(modName, db, xmod.defaults)
			db.version = xmod.version
		end
		
		mod.actions = xmod.GetActions()

		xmod.db = db
		xmod.Init()
	end
end

function mod.UpdateQueue()
	xmod.Update()
end

function mod.BuildOptions()
	return xmod.BuildOptions()
end

-- plug in
--------------------------------------------------------------------------------
local secondarySkill
local s1, s2
function emod.IconRet1(...)
	s1, s2 = xmod.Rotation(...)
	if secondarySkill then secondarySkill:DoUpdate() end
	if s1 == mexoId then 
		return emod.IconSpell(s1, csName)
	end
	return emod.IconSpell(s1, db.rangePerSkill or csName)
end
local function SecondaryExec()
	if s2 == mexoId then 
		return emod.IconSpell(s2, csName)
	end
	return emod.IconSpell(s2, db.rangePerSkill or csName)
end
local function ExecCleanup2()
	secondarySkill = nil
end
function emod.IconRet2(...)
	secondarySkill = emod.___e
	secondarySkill:SetScript("OnUpdate", nil)
	secondarySkill.exec = SecondaryExec
	secondarySkill.ExecCleanup = ExecCleanup2
end

-- giving queue as command line
local function CmdRet(args)
	db.prio = table.concat(args, " ")
	xmod.Update()
	clcInfo:UpdateOptions()
end
clcInfo.cmdList["retprio"] = CmdRet