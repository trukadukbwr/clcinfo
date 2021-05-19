clcInfo = {}	-- the addon
clcInfo.__version = 77

clcInfo.display = {}	-- display elements go here
clcInfo.templates = {}	-- the templates
clcInfo.classModules = {}  -- stuff loaded per class
clcInfo.cmdList = {}	-- list of functions registered to call from command line parameteres

clcInfo.optionsCMLoaders = {} -- class module options loaders
clcInfo.optionsCMLoadersActiveTemplate = {} -- special list for the ones who need options based on active template

clcInfo.activeTemplate = nil  -- points to the active template
clcInfo.activeTemplateIndex = 0 -- index of the active template

clcInfo.lastBuild = nil	 -- string that has talent info, used to see if talents really changed

clcInfo.mf = CreateFrame("Frame", "clcInfoMF", UIParent)  -- all elements parented to this frame, so it's easier to hide/show them

clcInfo.mf.unit = "player" 	-- fix parent unit for when we have to parent bars here
clcInfo.mf.hideTime = 0			-- fix for cooldown disappearing after a hide

-- table with information that could be used by functions, like roster etc
clcInfo.util = {
	roster = {},
	numRoster = 0,
	numRosterPets = 0,
	numRosterPetsBosses = 0,
} 

-- frame levels
-- grid: mf + 1
-- icons, bars: mf + 2
-- text: mf + 5
-- alerts: mf + 10
clcInfo.frameLevel = clcInfo.mf:GetFrameLevel()

clcInfo.env = setmetatable({}, {__index = _G})  -- add all data functions in this environment and pass them to the exec calls
clcInfo.env2 = setmetatable({}, {__index = _G}) -- use a different one for alerts, events etc

clcInfo.LSM = LibStub("LibSharedMedia-3.0")			-- SharedMedia
--[[ clcInfo.MSQ = LibStub("Masque", true)						-- Masque
if clcInfo.MSQ then
	clcInfo.MSQ_ListSkins = function()
		local list = {}
		local msqlist = clcInfo.MSQ:GetSkins()
		for k, v in pairs(msqlist) do
			list[k] = k
		end
		return list
	end
end
]]

-- static popup dialog
StaticPopupDialogs["CLCINFO"] = {
	text = "",
	button1 = OKAY,
	timeout = 0,
}

--------------------------------------------------------------------------------
-- slash command and blizzard options
--------------------------------------------------------------------------------
local function OpenOptions()
	if not clcInfo_Options then
		local loaded, reason = LoadAddOn("clcInfo_Options")
		if( not clcInfo_Options ) then
			print("Failed to load configuration addon. Error returned: ", reason)
			return
		end
	end
	clcInfo_Options:Open()
end

-- add a button to open the config to blizzard's options
local panel = CreateFrame("Frame", "clcInfoPanel", UIParent)
panel.name = "clcInfo"
local b = CreateFrame("Button", "clcInfoPanelOpenConfig", panel, "UIPanelButtonTemplate")
b:SetText("Open config")
b:SetWidth(150)
b:SetHeight(22)
b:SetPoint("TOPLEFT", 10, -10)
b:SetScript("OnClick", OpenOptions)
InterfaceOptions_AddCategory(panel)

-- slash command
SLASH_CLCINFO_OPTIONS1 = "/clcinfo"
SlashCmdList["CLCINFO_OPTIONS"] = function(msg)
	msg = msg and string.lower(string.trim(msg))

	-- no arguments -> open options
	if msg == "" then return OpenOptions() end
	
	-- simple argument handling
	-- try to pass it to the registered function if it exists
	local args = {}
	for v in string.gmatch(msg, "[^ ]+") do tinsert(args, v) end
	local cmd = table.remove(args, 1)
	if clcInfo.cmdList[cmd] then
		clcInfo.cmdList[cmd](args)
	end
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- register functions
--------------------------------------------------------------------------------
-- display modules
function clcInfo:RegisterDisplayModule(name)
	clcInfo.display[name] = {}
	return clcInfo.display[name]
end

-- class modules
function clcInfo:RegisterClassModule(name)
	name = string.lower(name)
	clcInfo.classModules[name] = {}
	return clcInfo.classModules[name]
end

-- global options for class modules
function clcInfo:RegisterClassModuleDB(name, defaults)
	name = string.lower(name)
	defaults = defaults or {}
	if not clcInfo.cdb.classModules[name] then  clcInfo.cdb.classModules[name] = defaults end
	return clcInfo.cdb.classModules[name]
end

-- per template options for class modules
function clcInfo:RegisterClassModuleTDB(name, defaults)
	name = string.lower(name)
	defaults = defaults or {}
	if not clcInfo.activeTemplate then return end
	if not clcInfo.activeTemplate.classModules[name] then clcInfo.activeTemplate.classModules[name] = defaults end
	return clcInfo.activeTemplate.classModules[name]
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- main initialize function
--------------------------------------------------------------------------------
function clcInfo:OnInitialize()
	self:ReadSavedData()
	
	if not self:FixSavedData() then return end
	
	-- init the class modules
	for k in pairs(clcInfo.classModules) do
		if clcInfo.classModules[k].OnInitialize then
			clcInfo.classModules[k].OnInitialize()
		end
	end
	
	-- update the template
	self:OnTemplatesUpdate()
	
	-- update the rosters
	clcInfo.util.UpdateRoster()
	
	-- register events
	clcInfo.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")  -- to monitor talent changes
	-- clcInfo.eventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")  -- to hide while using vehicles
	-- clcInfo.eventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
	clcInfo.eventFrame:RegisterEvent("PET_BATTLE_OPENING_START") -- hide
	clcInfo.eventFrame:RegisterEvent("PET_BATTLE_CLOSE") -- show
	clcInfo.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE") -- to track group changes
	clcInfo.eventFrame:RegisterEvent("UNIT_PET")
	
	clcInfo.debug:OnInitialize()
	
end
--------------------------------------------------------------------------------

-- looks for the first template that matches current talent build
-- reinitializes the elements
function clcInfo:OnTemplatesUpdate()
	local oldActive = clcInfo.activeTemplateIndex
	
	clcInfo.templates:FindTemplate()  -- find first template if it exists
	-- if nothing changes return
	if clcInfo.activeTemplateIndex == oldActive then return end
	
	-- clear elements
	for k in pairs(clcInfo.display) do
		if self.display[k].ClearElements then
			self.display[k]:ClearElements()
		end
	end
	
	-- init elements
	for k in pairs(clcInfo.display) do
		if self.display[k].InitElements then
			self.display[k]:InitElements()
		end
	end
	
	self:ChangeShowWhen()	-- visibility option is template based
	
	-- call OnTemplatesUpdate on all class modules so they can change options if needed
	for k, v in pairs(clcInfo.classModules) do
		if v.OnTemplatesUpdate then v.OnTemplatesUpdate() end
	end
	
	if clcInfo.activeTemplate then
-- strata of mother frame
		clcInfo.mf:SetFrameStrata(clcInfo.activeTemplate.options.strata)
		-- alpha
		clcInfo.mf:SetAlpha(clcInfo.activeTemplate.options.alpha)
	end
	
	-- change active template and update the options
	if clcInfo_Options then
		clcInfo_Options:LoadActiveTemplate()
	end
	self:UpdateOptions()
end

-- check templates on talent change
clcInfo.PLAYER_TALENT_UPDATE = clcInfo.OnTemplatesUpdate

-- check templates on group settings change
function clcInfo.GROUP_ROSTER_UPDATE()
	-- update roster
	clcInfo.util.UpdateRoster()
	-- check templates
	clcInfo:OnTemplatesUpdate()
end

-- defaults for the db
function clcInfo:GetDefault()
	local data = {
		version = clcInfo.__version,
		options = {
			enforceTemplate = 0,
		},
		classModules = {},
		templates = {},
		debug = {
			enabled = false,
			x = 10,
			y = 10,
		},
	}
	return data
end


-- read data from saved variables
function clcInfo:ReadSavedData()
	-- global defaults
	if not clcInfoDB then
		clcInfoDB = {}
	end
	clcInfo.db = clcInfoDB	

	-- perchar defaults
	if not clcInfoCharDB then
		clcInfoCharDB = clcInfo:GetDefault()
		table.insert(clcInfoCharDB.templates, clcInfo.templates:GetDefault())
	end

	clcInfo.cdb = clcInfoCharDB
end


-- checks if options are loaded and notifies the changes
function clcInfo:UpdateOptions()
	if clcInfo_Options then
		clcInfo_Options.AceRegistry:NotifyChange("clcInfo")
	end
end


--------------------------------------------------------------------------------
-- hide/show according to combat status, target, etc
--------------------------------------------------------------------------------

-- called when the setting updates
function clcInfo.ChangeShowWhen()
	if not clcInfo.activeTemplate then return end
	
	local mf = clcInfo.mf  -- parent of all frames

	-- pet battle check
	if C_PetBattles.IsInBattle() then
		mf:Hide()
		mf.hideTime = GetTime();
		return
	end
	
	-- vehicle check
	if UnitUsingVehicle("player") then
		mf:Hide()
		mf.hideTime = GetTime();
		return
	end

	local val = clcInfo.activeTemplate.options.showWhen

	-- unregister all events first
	local f = clcInfo.eventFrame
	f:UnregisterEvent("PLAYER_REGEN_ENABLED")
	f:UnregisterEvent("PLAYER_REGEN_DISABLED")
	f:UnregisterEvent("PLAYER_TARGET_CHANGED")
	f:UnregisterEvent("PLAYER_ENTERING_WORLD")
	f:UnregisterEvent("UNIT_FACTION")
	
	-- show in combat
	if val == "combat" then
		if InCombatLockdown() then
			mf:Show()
		else
			mf:Hide()
			mf.hideTime = GetTime();
		end
		f:RegisterEvent("PLAYER_REGEN_ENABLED")
		f:RegisterEvent("PLAYER_REGEN_DISABLED")
		
	-- show on certain targets
	elseif val == "valid" or val == "boss" then
		clcInfo:PLAYER_TARGET_CHANGED()
		f:RegisterEvent("PLAYER_TARGET_CHANGED")
		f:RegisterEvent("PLAYER_ENTERING_WORLD")
		f:RegisterEvent("UNIT_FACTION")
		
	-- show always
	else
			mf:Show()
	end
end

-- hide/show according to target
function clcInfo.PLAYER_TARGET_CHANGED()
	if not clcInfo.activeTemplate then return end
	
	local show = clcInfo.activeTemplate.options.showWhen

	if show == "boss" then
		if UnitClassification("target") ~= "worldboss" and UnitClassification("target") ~= "elite" then
			clcInfo.mf:Hide()
			clcInfo.mf.hideTime = GetTime();
			return
		end
	end
	
	if UnitExists("target") and UnitCanAttack("player", "target") and (not UnitIsDead("target")) then
		clcInfo.mf:Show()
	else
		clcInfo.mf:Hide()
		clcInfo.mf.hideTime = GetTime();
	end
end
-- force target update on rezoning
function clcInfo.PLAYER_ENTERING_WORLD()
	SetMapToCurrentZone()		

	-- check for target since it's not fired the specific event
	clcInfo.PLAYER_TARGET_CHANGED()
end

-- for when target goes from friendly to unfriendly
function clcInfo.UNIT_FACTION(self, event, unit)
	if unit == "target" then
		self.PLAYER_TARGET_CHANGED()
	end
end

-- hide out of combat
function clcInfo.PLAYER_REGEN_ENABLED()
	clcInfo.mf:Hide()
	clcInfo.mf.hideTime = GetTime();
end
function clcInfo.PLAYER_REGEN_DISABLED()
	clcInfo.mf:Show()
end

-- hide in vehicles
function clcInfo.UNIT_ENTERED_VEHICLE(self, event, unit)
	if unit == "player" then
	-- vehicle check
		if UnitUsingVehicle("player") then
			clcInfo.mf:Hide()
			clcInfo.mf.hideTime = GetTime();
			return
		end
	end
end
function clcInfo.UNIT_EXITED_VEHICLE(self, event, unit)
	if unit == "player" then
		clcInfo.ChangeShowWhen()
	end
end

-- hide in pet battles
function clcInfo.PET_BATTLE_OPENING_START(self, event)
	clcInfo.ChangeShowWhen()
end
function clcInfo.PET_BATTLE_CLOSE(self, event)
	clcInfo.ChangeShowWhen()
end
--------------------------------------------------------------------------------

-- OnEvent dispatcher
local function OnEvent(self, event, ...)
	clcInfo[event](clcInfo, event, ...)
	--[[
	if clcInfo[event] then
		clcInfo[event](clcInfo, event, ...)
	else
		print(event, "event registered but not handled")
	end
	--]]
end
-- event frame
clcInfo.eventFrame = CreateFrame("Frame")
clcInfo.eventFrame:Hide()
clcInfo.eventFrame:SetScript("OnEvent", function(self, event)
	if event == "QUEST_LOG_UPDATE" then
		-- intialize, unregister, change event function
		clcInfo.eventFrame:UnregisterEvent("QUEST_LOG_UPDATE")
		clcInfo.eventFrame:SetScript("OnEvent", OnEvent)
		clcInfo:OnInitialize()
	end
end)
-- need an event that fires first time after talents are loaded and fires both at login and reloadui
-- in case this doesn't work have to do with delayed timer
-- using QUEST_LOG_UPDATE atm
clcInfo.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")

-- register some sounds for LSM just to be sure I have them
clcInfo.LSM:Register("sound", "clcInfo: Default", [[Sound\Doodad\BellTollAlliance.ogg]])
clcInfo.LSM:Register("sound", "clcInfo: Run", [[Sound\Creature\HoodWolf\HoodWolfTransformPlayer01.ogg]])
clcInfo.LSM:Register("sound", "clcInfo: Explosion", [[Sound\Doodad\Hellfire_Raid_FX_Explosion05.ogg]])
clcInfo.LSM:Register("sound", "clcInfo: Die", [[Sound\Creature\CThun\CThunYouWillDIe.ogg]])
clcInfo.LSM:Register("sound", "clcInfo: Cheer", [[Sound\Event Sounds\OgreEventCheerUnique.ogg]])

-- static popup dialog call
function clcInfo.SPD(s)
	StaticPopupDialogs.CLCINFO.text = s
	StaticPopup_Show("CLCINFO")
end

-- utils
--------------------------------------------------------------------------------
do
	local party = { "party1", "party2", "party3", "party4" }
	local partyPets = { "party1pet", "party2pet", "party3pet", "party4pet" }
	local bosses = { "boss1", "boss2", "boss3", "boss4" }
	local raid, raidPets = {}, {}
	for i = 1, 40 do
		raid[i] = "raid" .. i
		raidPets[i] = raid[i] .. "pet"
	end

	-- 3 different tables, since some functions might need to check different stuff
	function clcInfo.util.UpdateRoster()
		local num = 0
		local roster = clcInfo.util.roster
		
		-- add the player
		num = num + 1
		roster[num] = "player"

		local ngm = GetNumGroupMembers()
		if IsInRaid() then
			-- raid logic
			if ngm > 1 then
				for i = 1, ngm do
					num = num + 1
					roster[num] = raid[i]
				end
			end
		else
			-- party logic
			if ngm > 0 then
				for i = 1, ngm - 1 do
					num = num + 1
					roster[num] = party[i]
				end
			end
		end
		
		-- done with roster
		clcInfo.util.numRoster = num
		
		-- player pet
		if UnitExists("playerpet") then
			num = num + 1
			roster[num] = "playerpet"
		end
		
		if IsInRaid() then
			-- add the raid pets
			if ngm > 1 then
				for i = 1, ngm do
					if UnitExists(raidPets[i]) then
						num = num + 1
						roster[num] = raidPets[i]
					end
				end
			end
		else
			-- add party pets
			if ngm > 0 then
				for i = 1, ngm - 1 do
					if UnitExists(partyPets[i]) then
						num = num + 1
						roster[num] = partyPets[i]
					end
				end
			end
		end
		
		-- done with rosterPets
		clcInfo.util.numRosterPets = num
		
		-- add the 5 bosses
		for i = 1, 5 do			
			num = num + 1
			roster[num] = bosses[i]
		end
		
		-- done with roster
		clcInfo.util.numRosterPetsBosses = num
	end
end
-- update roster when pets are spawned
clcInfo.UNIT_PET = clcInfo.util.UpdateRoster

