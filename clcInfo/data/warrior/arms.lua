-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "WARRIOR" then return end

local modName = "__arms"
local mod = clcInfo:RegisterClassModule(modName)
local emod = clcInfo.env
local db -- template based

local _, xmod = ...
xmod = xmod.warmodule

-- csName to pass as argument for melee range checks
local csName = GetSpellInfo(12294)


function mod.OnTemplatesUpdate()
	db = clcInfo:RegisterClassModuleTDB(modName, xmod.defaults)
	if db then
		if not db.version or db.version < xmod.version then
			-- fix stuff
			print("__arms module/", "cleaning up saved vars")
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
function emod.IconArms1(...)
	s1, s2 = xmod.Rotation(...)
	if secondarySkill then secondarySkill:DoUpdate() end
	return emod.IconSpell(s1, db.rangePerSkill or csName)
end
local function SecondaryExec()

	return emod.IconSpell(s2, db.rangePerSkill or csName)
end
local function ExecCleanup2()
	secondarySkill = nil
end
function emod.IconArms2(...)
	secondarySkill = emod.___e
	secondarySkill:SetScript("OnUpdate", nil)
	secondarySkill.exec = SecondaryExec
	secondarySkill.ExecCleanup = ExecCleanup2
end

-- giving queue as command line
local function CmdArms(args)
	db.prio = table.concat(args, " ")
	xmod.Update()
	clcInfo:UpdateOptions()
end
clcInfo.cmdList["armsprio"] = CmdArms