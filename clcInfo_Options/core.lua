clcInfo_Options = { templates = { icons = {}, bars = {}, micons = {}, mbars = {}, texts = {} } }
local mod = clcInfo_Options
local AceDialog, AceRegistry, AceSerializer, AceGUI, SML, registered, options

-- have them here too for my options to not create them unnecesarry when options aren't loaded
clcInfo_Options.optionsCMLoaders = {} -- class module options loaders
clcInfo_Options.optionsCMLoadersActiveTemplate = {} -- special list for the ones who need options based on active template

AceDialog = AceDialog or LibStub("AceConfigDialog-3.0")
AceRegistry = AceRegistry or LibStub("AceConfigRegistry-3.0")
AceSerializer = AceSerializer or LibStub("AceSerializer-3.0")
mod.AceSerializer = AceSerializer

options = {
	type = "group",
	name = "clcInfo",
	args = {}
}

-- expose
mod.AceDialog = AceDialog
mod.AceRegistry = AceRegistry
mod.AceSerializer = AceSerializer
mod.options = options

-- useful tables for options
mod.anchorPoints = { CENTER = "CENTER", TOP = "TOP", BOTTOM = "BOTTOM", LEFT = "LEFT", RIGHT = "RIGHT", TOPLEFT = "TOPLEFT", TOPRIGHT = "TOPRIGHT", BOTTOMLEFT = "BOTTOMLEFT", BOTTOMRIGHT = "BOTTOMRIGHT" }

local function Init()
	mod:LoadTemplates()
	-- info: class modules are loaded together with active template because of the data that might be template stored
	mod:LoadActiveTemplate()
	mod:LoadSimpleDocs()
	mod:LoadDebug()
end

function mod:LoadClassModules()
	-- delete old table
	options.args.classModules = { order = 50, type = "group", name = "Class Modules", args = {} }
	for i = 1, #(clcInfo.optionsCMLoaders) do
		clcInfo.optionsCMLoaders[i]()
	end
	for i = 1, #(clcInfo_Options.optionsCMLoaders) do
		clcInfo_Options.optionsCMLoaders[i]()
	end
	
	-- update all the class modules that save options in templates
	if clcInfo.activeTemplate then
  	for i = 1, #(clcInfo.optionsCMLoadersActiveTemplate) do
			clcInfo.optionsCMLoadersActiveTemplate[i]()
		end
		for i = 1, #(clcInfo_Options.optionsCMLoadersActiveTemplate) do
			clcInfo_Options.optionsCMLoadersActiveTemplate[i]()
		end
	end
end

function mod:Open()
	if( not registered ) then
		Init()
		
		LibStub("AceConfig-3.0"):RegisterOptionsTable("clcInfo", options)
		AceDialog:SetDefaultSize("clcInfo", 1000, 600)
		registered = true
	end
	
	AceDialog:Open("clcInfo")
end

--------------------------------------------------------------------------------
-- functions that are identical for elements
--------------------------------------------------------------------------------
-- grid list
function mod.GetGridList()
	local list = { [0] = "None" }
	local name
	for i = 1, #(clcInfo.display.grids.active) do
		name = clcInfo.display.grids.active[i].db.udLabel
		if name == "" then name = "Grid" .. i end
		list[i] = name
	end
	return list
end


--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

-- recursive copy
-- s = source, t = target
-- doesn't delete existing elements
local function SafeCopyTable(s, t)
	if not s or not t then return end
	if type(s) ~= "table" or type(t) ~= "table" then return end
	-- if #s > 0 or #t > 0 then return end  -- don't copy indexed tables

	-- copy data
	for k, v in pairs(s) do
		if t[k] ~= nil then
			if type(v) == "table" then
				SafeCopyTable(v, t[k])
			else
				t[k] = v
			end
		end
	end
end
mod.SafeCopyTable = SafeCopyTable






