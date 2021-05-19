-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options
local AceSerializer = mod.AceSerializer

local currentTree

-- TODO!
-- use temp spec entry and a save button isntead of updating every change
-- TODO
-- less functions inline defined

local function SpecToString(i)
	local spec = clcInfo.cdb.templates[i].spec
	
	local treeName = GetSpecializationInfo(spec.tree)
	if not treeName then return "Undefined" end
	local talentName = GetTalentInfo(spec.talent)
	if not talentName then return "Undefined" end

	return treeName .. " > " .. talentName
end

local selectedForDelete = 0
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_TEMPLATE"] = {
	text = "Are you sure you want to delete this template?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		local db = clcInfo.cdb.templates
		if db[selectedForDelete] then 				
			table.remove(db, selectedForDelete)
			clcInfo:OnTemplatesUpdate()
			mod:UpdateTemplateList()
		end
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

local function GetSpec(info)
	return clcInfo.cdb.templates[tonumber(info[2])].spec[info[5]]
end

local function SetSpec(info, val)
	--local db = clcInfo.cdb.templates
	clcInfo.cdb.templates[tonumber(info[2])].spec[info[5]] = val
	clcInfo:OnTemplatesUpdate()
end


local function GetTalentTrees()
	local list = {}
	local name, _
	for i = 1, 5 do  
		_, name = GetSpecializationInfo(i)
		if name then
			table.insert(list, name)
		else
			break
		end
	end
	return list
end

-- get all talents from a specific tree
local function GetTreeTalents()
	local list = { "Any" }
	local name
	local spec = GetActiveSpecGroup();
	for talentTier = 1, MAX_TALENT_TIERS do
		for talentColumn = 1, NUM_TALENT_COLUMNS do
			_, name = GetTalentInfo(talentTier, talentColumn, spec)
			table.insert(list, name)
		end
	end
	return list
end

local specTrees = GetTalentTrees()
local specTalents = GetTreeTalents()
local function GetTalentList(info)
	return specTalents
end

local function GetForceTemplateList()
	local list = { [0] = "Disabled" }
	local name
	for i = 1, #(clcInfo.cdb.templates) do
		name = clcInfo.cdb.templates[i].options.udLabel
		if name ~= "" then
			list[i] = name
		else
			list[i] = "Template" .. i
		end
	end
	return list
end
local function GetForceTemplate(info)
	return clcInfo.cdb.options.enforceTemplate
end
local function SetForceTemplate(info, val)
	clcInfo.cdb.options.enforceTemplate = val
	clcInfo:OnTemplatesUpdate()
end

local function GetUDLabel(info)
	local name = clcInfo.cdb.templates[tonumber(info[2])].options.udLabel
	if name ~= "" then return name end
	return "Template"..info[2]
end
local function Get(info)
	return clcInfo.cdb.templates[tonumber(info[2])].options.udLabel
end
local function Set(info, val)
	clcInfo.cdb.templates[tonumber(info[2])].options.udLabel = val
end


local function GetShowWhen(info)
	return clcInfo.cdb.templates[tonumber(info[2])].showWhen[info[5]]
end
local function SetShowWhen(info, val)
	clcInfo.cdb.templates[tonumber(info[2])].showWhen[info[5]] = val
	clcInfo:OnTemplatesUpdate()
end

--------------------------------------------------------------------------------
-- import / export
--------------------------------------------------------------------------------
local importString
local importId
StaticPopupDialogs["CLCINFO_CONFIRM_IMPORT_TEMPLATE"] = {
	text = "Are you sure you want to import this data?\nIf the information you pasted is wrong it could lead to a lot of problems.",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not importString or importString == "" then return end
		local success, t = AceSerializer:Deserialize(importString)
		if success then
			mod.SafeCopyTable(t, clcInfo.cdb.templates[importId])
			
			-- now we need to add the elements
			for k in pairs(clcInfo.display) do
				clcInfo.cdb.templates[importId][k] = {}
				for i, v in ipairs(t[k]) do
					clcInfo.cdb.templates[importId][k][i] = clcInfo.display[k]:GetDefault()
					mod.SafeCopyTable(v, clcInfo.cdb.templates[importId][k][i])
				end
			end
			
			mod:UpdateTemplateList()
		else
			print(t)
		end
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}
local function GetExport(info)
	return AceSerializer:Serialize(clcInfo.cdb.templates[tonumber(info[2])])
end
local function SetExport(info, val) end
local function GetImport(info) end
local function SetImport(info, val)
	importString = val
	importId = tonumber(info[2])
	StaticPopup_Show("CLCINFO_CONFIRM_IMPORT_TEMPLATE")
end
--------------------------------------------------------------------------------


function mod:UpdateTemplateList()
	local db = clcInfo.cdb.templates
	local optionsTemplates = options.args.templates
	for i = 1, #(db) do
		optionsTemplates.args[tostring(i)] = {
			order = i,
			type = "group",
			name = GetUDLabel,
			childGroups = "tab",
			args = {
				tabSpec = {
					type="group",
					name = "Spec",
					order = 1,
					args = {
						label = {
							order = 1, type = "group", inline = true, name = "Label",
							args = {
								udLabel = {
									type = "input", width = "double", name = "",
									get = Get, set = Set,
								}
							},
						},
						primaryTree = {
							order = 2, type = "group", inline = true, name = "Specialization",
							args = {
								primary = {
									order = 1, type = "select", name = "", values = specTrees,
									get = GetSpec, set = SetSpec,	
								},
							},
						},
						spec = {
							order = 3, type = "group", inline = true, name = "Distinctive talent",							
							args = {
								talent = {
									order = 2, type = "select", name = "Talent", values = GetTalentList,
									get = GetSpec, set = SetSpec,		
								},
							},
						},
						showWhen = {
							order = 4, type = "group", inline = true, name = "Active when",
							args = {
								solo = {
									order = 1, type = "toggle", width = "half", name = "Solo", get = GetShowWhen, set = SetShowWhen,
								},
								party = {
									order = 2, type = "toggle", width = "normal", name = "Party", get = GetShowWhen, set = SetShowWhen,
								},
								raid5 = {
									order = 3, type = "toggle", width = "half", name = "Raid 5", get = GetShowWhen, set = SetShowWhen,
								},
								raid10 = {
									order = 4, type = "toggle", width = "half", name = "Raid 10", get = GetShowWhen, set = SetShowWhen,
								},
								raid25 = {
									order = 5, type = "toggle", width = "half", name = "Raid 25", get = GetShowWhen, set = SetShowWhen,
								},
							},
						},
					},
				},
				
				tabExport = {
					order = 90, type = "group", name = "Export/Import", 
					args = {
						export = {
							order = 1, type = "group", inline = true, name = "Export string",
							args = {
								text = {
									order = 1, type = "input", multiline = true, name = "", width = "full",
									get = GetExport, set = SetExport,
								},
							},
						},
						import = {
							order = 1, type = "group", inline = true, name = "Import string",
							args = {
								info = {
									order = 1, type = "description", name = "Do not import objects of different type here.\nClass Modules settings might not import properly.",
								},
								text = {
									order = 3, type = "input", multiline = true, name = "", width = "full",
									get = GetImport, set = SetImport,
								},
							},
						},
					},
				},
				
				tabDelete = {
					type = "group",
					name = "Delete",
					order = 100,
					args = {
							execDelete = {
							type = "execute",
							name = "Delete",
							func = function(info)						
								selectedForDelete = i,
								StaticPopup_Show("CLCINFO_CONFIRM_DELETE_TEMPLATE")
							end
						},
					},
				},
			},
		}
	end
	
	if mod.lastTemplateCount > #(db) then
		-- nil the rest of the args
		for i = #(db) + 1, mod.lastTemplateCount do
			optionsTemplates.args[tostring(i)] = nil
		end
	end
	mod.lastTemplateCount = #(db)
	AceRegistry:NotifyChange("clcInfo")
end

-- global template options
-- 		+ add template
-- 		+	delete template
function mod:LoadTemplates()
	options.args.templates = {
		order = 100, type = "group", name = "Templates", args = {
			-- add template button
			add = {
				order = 1, type = "execute", name = "Add template",
				func = clcInfo.templates.AddTemplate,
			},
			_space1 = {
				order = 2, type = "description", name = ""
			},
			forceTemplate = {
				order = 3, type = "select", name = "Force template regardless of spec:", values = GetForceTemplateList,
				get = GetForceTemplate, set = SetForceTemplate,
				
			},
		},
	}
	
	mod.lastTemplateCount = 0
	
	mod:UpdateTemplateList()
end