local ename = "texts"

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local AceSerializer = AceSerializer
local options = mod.options
local AceSerializer = mod.AceSerializer

local modTexts = clcInfo.display.texts

local LSM = clcInfo.LSM

-- static popup to make sure
local deleteObj = nil
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_TEXT"] = {
	text = "Are you sure you want to delete this text?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not deleteObj then return end
		deleteObj:Delete()
		mod:UpdateTextList()
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

-- info:
-- 	1 activeTemplate
-- 	2 texts
--	3 i
--	4 deleteTab
--	5 executeDelete
local function DeleteText(info)
	local i = tonumber(info[3])
	deleteObj = modTexts.active[i]
	StaticPopup_Show("CLCINFO_CONFIRM_DELETE_TEXT")
end

-- info:
-- 	1 activeTemplate
-- 	2 texts
--	3 i
--	4 tabLayout
--	5 size, position, ... = group names
-- 	6 width, height, ...	= var names
local function Set(info, val)
	local obj = modTexts.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateLayout()
end
local function Get(info)
	return modTexts.active[tonumber(info[3])].db[info[6]]
end

local function Lock(info)
	modTexts.active[tonumber(info[3])]:Lock()
end

local function Unlock(info)
	modTexts.active[tonumber(info[3])]:Unlock()
end

local function SetExec(info, val)
	local obj = modTexts.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateExec()
end

-- set/get for skin texts
local function GetSkinTexts(info)
	return modTexts.active[tonumber(info[3])].db.skin[info[6]]
end
local function SetSkinTexts(info, val)
	local obj = modTexts.active[tonumber(info[3])]
	obj.db.skin[info[6]] = val
	obj:UpdateLayout()
end
-- set/get for skin color
local function SetSkinTextsColor(info, r, g, b, a)
	local obj = modTexts.active[tonumber(info[3])]
	obj.db.skin[info[6]] = { r, g, b, a }
	obj:UpdateLayout()
end
local function GetSkinTextsColor(info)
	return unpack(modTexts.active[tonumber(info[3])].db.skin[info[6]])
end

-- get label
local function GetUDLabel(info)
	local name = modTexts.active[tonumber(info[3])].db.udLabel
	if name == "" then name = "Text" .. info[3] end
	return name
end

-- used to change error strings
local function GetErrExec(info) return modTexts.active[tonumber(info[3])].errExec or "" end
local function GetErrExecAlert(info) return modTexts.active[tonumber(info[3])].errExecAlert or "" end
local function GetErrExecEvent(info) return modTexts.active[tonumber(info[3])].errExecEvent or "" end

-- template code
--------------------------------------------------------------------------------
local function execTemplateCategories()
	local t = {}
	for k, v in pairs(clcInfo_Options.templates[ename]) do
		t[k] = k
	end
	return t	
end
local stc = nil -- selectedTemplateCategory
local function GetExecTemplateList()
	local list = {}
	if stc then
		local cat = clcInfo_Options.templates[ename][stc]
		if cat then
			for k, v in pairs(cat) do
				list[k] = v.name
			end
		end
	end
	return list
end
local function GetExecTemplateCategory(info) return stc end
local function SetExecTemplateCategory(info, val) stc = val end
local function SetExecTemplate(info, val)
	local obj = modTexts.active[tonumber(info[3])]
	obj.db.exec = clcInfo_Options.templates[ename][stc][val].exec
	obj:UpdateExec()
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- import / export
--------------------------------------------------------------------------------
local importString
local importId
StaticPopupDialogs["CLCINFO_CONFIRM_IMPORT_TEXT"] = {
	text = "Are you sure you want to import this data?\nIf the information you pasted is wrong it could lead to a lot of problems.",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not importString or importString == "" then return end
		local success, t = AceSerializer:Deserialize(importString)
		if success then
			mod.SafeCopyTable(t, clcInfo.cdb.templates[clcInfo.activeTemplateIndex].texts[importId])
			clcInfo.display.texts.active[importId]:UpdateLayout()
			clcInfo.display.texts.active[importId]:UpdateExec()
			mod:UpdateTextList()
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
	return AceSerializer:Serialize(modTexts.active[tonumber(info[3])].db)
end
local function SetExport(info, val) end
local function GetImport(info) end
local function SetImport(info, val)
	importString = val
	importId = tonumber(info[3])
	StaticPopup_Show("CLCINFO_CONFIRM_IMPORT_TEXT")
end
--------------------------------------------------------------------------------

-- value lists
--------------------------------------------------------------------------------
local listJustifyH = { CENTER = "CENTER", LEFT = "LEFT", RIGHT = "RIGHT" }
local listJustifyV = { BOTTOM = "BOTTOM", MIDDLE = "MIDDLE", TOP = "TOP" }
--------------------------------------------------------------------------------
						
function mod:UpdateTextList()
	local db = modTexts.active
	local optionsTexts = options.args.activeTemplate.args.texts
	
	for i = 1, #db do
		optionsTexts.args[tostring(i)] = {
			type = "group",
			name = GetUDLabel,
			order = i,
			childGroups = "tab",
			args = {
				-- general
				tabGeneral = {
					order = 1, type = "group", name = "General",
					args = {
						enabled = {
							order = 1, type = "group", inline = true, name = "",
							args = {
								enabled = {
									type = "toggle", name = "Enabled",
									get = Get, set = Set,
								},
							},
						},
						label = {
							order = 2, type = "group", inline = true, name = "",
							args = {
								udLabel = {
									type = "input", width = "double", name = "Label",
									get = Get, set = Set,
								}
							},
						},
						lock = {
							order = 5, type = "group", inline = true, name = "",
							args = {
								lock = {
				  				type = "execute", name = "Lock", func = Lock
				  			},
				  			unlock = {
				  				type = "execute", name = "Unlock", func = Unlock,
				  			},
							},
						},
						grid = {
							order = 11, type = "group", inline = true, name = "",
							args = {
								gridId = {
									order = 1, type = "select", name = "Select Grid", values = clcInfo_Options.GetGridList,
									get = Get, set = Set, 
								},
								skinSource = {
									order = 2, type = "select", name = "Use skin from",
									values = { Self = "Self", Template = "Template", Grid = "Grid" },
									get = Get, set = Set, 
								},
								alpha = {
									order = 3, type = "range", min = 0, max = 1, step = 0.01, name = "Alpha",
									get = Get, set = Set, 
								},
								frameLevel = {
									order = 4, type = "range", min = 0, max = 1000, step = 1, name = "Frame Level",
									get = Get, set = Set, 
								},
							},
						},
					},
				},
			
				-- grid options
				tabGrid = {
					order = 2, type = "group", name = "Grid",
					args = {
						grid = {
							order = 1,  type = "group", inline = true, name = "Position in grid and size of the textbox in cells",
							args = {
								gridX = {
									order = 2, name = "Column", type = "range", min = -200, max = 200, step = 1,
									get = Get, set = Set,
								},
								gridY = {
									order = 3, name = "Row", type = "range", min = -200, max = 200, step = 1,
									get = Get, set = Set,
								},
								sizeX = {
									order = 4, name = "Width", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
								sizeY = {
									order = 5, name = "Height", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
							},
						},
					},
				},
			
				-- layout options
				tabLayout = {
					order = 3, type = "group", name = "Layout",
					args = {
						__dGrid = {
							order = 1, type = "description",
							name = "If a grid is selected, none of the following options have any real effect.\n",
						},
					
						position = {
							order = 10, type = "group", inline = true, name = "Position ( [0, 0] is bottom left corner )",
							args = {
								x = {
									order = 1, name = "X", type = "range", min = 0, max = 4000, step = 1,
									get = Get, set = Set,
								},
								y = {
									order = 2, name = "Y", type = "range", min = 0, max = 2000, step = 1,
									get = Get, set = Set,
								},
							},
						},
							
						size = {
							order = 20, type = "group", inline = true, name = "Size",
							args = {
								width = {
									order = 1, type = "range", min = 1, max = 2000, step = 1, name = "Width",
									get = Get, set = Set,
								},
								height = {
									order = 2, type = "range", min = 1, max = 1000, step = 1, name = "Height", 
									get = Get, set = Set,
								},
							},
						},
						
						justify = {
							order = 30, type = "group", inline = true, name = "Justify",
							args = {
								justifyH = {
									order = 1, type = "select", name = "Horizontal", values = listJustifyH,
									get = Get, set = Set,
								},
								justifyV = {
									order = 2, type = "select", name = "Vertical", values = listJustifyV,
									get = Get, set = Set,
								},
							},
						},
					},
				},
				
				tabSkin = {
					order = 4, type = "group", name = "Skin",
					args = {
						__warning = {
							order = 1, type = "description",
							name = "|cff00ffffIn order to use these settings go to General tab and set |cffffffff[Use skin from] |cff00ffffoption to |cffffffff[Self]|cff00ffff.\n",
						},
						base = {
							order = 2, type = "group", inline = true, name = "Base",
							args = {
								family = {
									order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font', values = LSM:HashTable("font"),
									get = GetSkinTexts, set = SetSkinTexts,
								},
								size = {
									order = 2, type = "range", min = 0, max = 200, step = 1, name = "Size%",
									get = GetSkinTexts, set = SetSkinTexts,
								},
								color = {
									order = 3, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinTextsColor, set = SetSkinTextsColor,
								},
							},
						},
						shadow = {
							order = 3, type = "group", inline = true, name = "Shadow",
							args = {
								shadowOffsetX = {
									order = 1, type = "range", min = -20, max = 20, step = 0.01, name = "Shadow Offset X",
									get = GetSkinTexts, set = SetSkinTexts,
								},
								shadowOffsetY = {
									order = 2, type = "range", min = -20, max = 20, step = 0.01, name = "Shadow Offset Y",
									get = GetSkinTexts, set = SetSkinTexts,
								},
								shadowColor = {
									order = 3, type = "color", hasAlpha = true, name = "Shadow Color",
									get = GetSkinTextsColor, set = SetSkinTextsColor,
								},
							},
						},
						flags = {
							order = 4, type = "group", inline = true, name = "Flags",
							args = {
								aliasing = {
									order = 1, type = "toggle", name = "Aliasing",
									get = GetSkinTexts, set = SetSkinTexts,
								},
								outline = {
									order = 2, type = "toggle", name = "Outline",
									get = GetSkinTexts, set = SetSkinTexts,
								},
								thickoutline = {
									order = 3, type = "toggle", name = "Thick Outline",
									get = GetSkinTexts, set = SetSkinTexts,
								},
							},
						},
					},
				},
				
				
				-- behavior options
				tabBehavior = {
					order = 5, type = "group", name = "Behavior", 
					args = {
						code = {
							order = 1, type = "group", inline = true, name = "Code",
							args = {
								exec = {
									order = 1, type = "input", multiline = true, name = "", width = "full",
									get = Get, set = SetExec,
								},
								err = { order = 2, type = "description", width = "full", name = GetErrExec },
								templatesCategories = {
									order = 3, type = "select", width = "double", name = "Categories", values = execTemplateCategories,
									get = GetExecTemplateCategory, set = SetExecTemplateCategory,
								},
								templates = {
									order = 4, type = "select", width = "double", name = "Templates", values = GetExecTemplateList,
									set = SetExecTemplate,
								},
							},
						},
						ups = {
							order = 2, type = "group", inline = true, name = "Updates per second",
							args = {
								ups = {
									type = "range", min = 1, max = 100, step = 1, name = "", 
									get = Get, set = SetExec,
								},
							},
						},
						events = {
							order = 4, type = "group", inline = true, name = "Events",
							args = {
								eventExec = {
									order = 1, type = "input", multiline = true, name = "", width = "full",
									get = Get, set = SetExec,
								},
								err = { order = 2, type = "description", name = GetErrExecEvent },
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
									order = 1, type = "description", name = "Do not import objects of different type here.",
								},
								text = {
									order = 2, type = "input", multiline = true, name = "", width = "full",
									get = GetImport, set = SetImport,
								},
							},
						},
					},
				},
				
				tabDelete = {
					order = 100, type = "group", name = "Delete", 
					args = {
						-- delete button
						executeDelete = {
							type = "execute", name = "Delete",
							func = DeleteText,
						},
					},
				},
			},
		}
	end
	
	if mod.lastTextCount > #(db) then
		-- nil the rest of the args
		for i = #db + 1, mod.lastTextCount do
			optionsTexts.args[tostring(i)] = nil
		end
	end
	mod.lastTextCount = #db
	
	AceRegistry:NotifyChange("clcInfo")
end