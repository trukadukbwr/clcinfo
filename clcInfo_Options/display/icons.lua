local ename = "icons"

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local AceSerializer = mod.AceSerializer
local options = mod.options

local modIcons = clcInfo.display.icons

local LSM = clcInfo.LSM

-- static popup to make sure
local deleteObj = nil
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_ICON"] = {
	text = "Are you sure you want to delete this icon?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not deleteObj then return end
		deleteObj:Delete()
		mod:UpdateIconList()
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

-- info:
-- 	1 activeTemplate
-- 	2 icons
--	3 i
--	4 deleteTab
--	5 executeDelete
local function DeleteIcon(info)
	local i = tonumber(info[3])
	deleteObj = modIcons.active[i]
	StaticPopup_Show("CLCINFO_CONFIRM_DELETE_ICON")
end

-- info:
-- 	1 activeTemplate
-- 	2 icons
--	3 i
--	4 tabLayout
--	5 size, position, ... = group names
-- 	6 width, height, ...	= var names
local function Set(info, val)
	local obj = modIcons.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateLayout()
end
local function Get(info)
	return modIcons.active[tonumber(info[3])].db[info[6]]
end

local function SetLockedGrid(info, val)
	local obj = modIcons.active[tonumber(info[3])]
	obj.db.sizeX = val
	obj.db.sizeY = val
	obj:UpdateLayout()
end
local function GetLockedGrid(info)
	return modIcons.active[tonumber(info[3])].db.sizeX
end

local function SetLockedLayout(info, val)
	local obj = modIcons.active[tonumber(info[3])]
	obj.db.width = val
	obj.db.height = val
	obj:UpdateLayout()
end
local function GetLockedLayout(info)
	return modIcons.active[tonumber(info[3])].db.width
end

local function Lock(info)
	modIcons.active[tonumber(info[3])]:Lock()
end

local function Unlock(info)
	modIcons.active[tonumber(info[3])]:Unlock()
end

local function SetExec(info, val)
	local obj = modIcons.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateExec()
end

-- set/get for skin icons
local function SetSkinIcons(info, val)
	local obj = modIcons.active[tonumber(info[3])]
	obj.db.skin[info[6]] = val
	obj:UpdateLayout()
end
local function GetSkinIcons(info)
	return modIcons.active[tonumber(info[3])].db.skin[info[6]]
end
local function GetSkinTypeList()
	local list = { ["Default"] = "Default", ["BareBone"] = "BareBone" }
	if clcInfo.MSQ then list["Masque"] = "Masque" end
	return list
end

local function SetSkinColor(info, r, g, b, a)
	local obj = modIcons.active[tonumber(info[3])]
	obj.db.skin[info[6]] = { r, g, b, a }
	obj:UpdateLayout()
end
local function GetSkinColor(info)
	return unpack(modIcons.active[tonumber(info[3])].db.skin[info[6]])
end

-- sound donothing control
local sound = "None"
local function GetSound() return sound end
local function SetSound(info, val) sound = val end
-- used to change error strings
local function GetErrExec(info) return modIcons.active[tonumber(info[3])].errExec or "" end
local function GetErrExecAlert(info) return modIcons.active[tonumber(info[3])].errExecAlert or "" end
local function GetErrExecEvent(info) return modIcons.active[tonumber(info[3])].errExecEvent or "" end

-- get label
local function GetUDLabel(info)
	local name = modIcons.active[tonumber(info[3])].db.udLabel
	if name == "" then name = "Icon" .. info[3] end
	return name
end	

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
	local obj = modIcons.active[tonumber(info[3])]
	obj.db.exec = clcInfo_Options.templates[ename][stc][val].exec
	obj:UpdateExec()
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- import / export
--------------------------------------------------------------------------------
local importString
local importId
StaticPopupDialogs["CLCINFO_CONFIRM_IMPORT_ICON"] = {
	text = "Are you sure you want to import this data?\nIf the information you pasted is wrong it could lead to a lot of problems.",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not importString or importString == "" then return end
		local success, t = AceSerializer:Deserialize(importString)
		if success then
			mod.SafeCopyTable(t, clcInfo.cdb.templates[clcInfo.activeTemplateIndex].icons[importId])
			clcInfo.display.icons.active[importId]:UpdateLayout()
			clcInfo.display.icons.active[importId]:UpdateExec()
			mod:UpdateIconList()
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
	return AceSerializer:Serialize(modIcons.active[tonumber(info[3])].db)
end
local function SetExport(info, val) end
local function GetImport(info) end
local function SetImport(info, val)
	importString = val
	importId = tonumber(info[3])
	StaticPopup_Show("CLCINFO_CONFIRM_IMPORT_ICON")
end
--------------------------------------------------------------------------------
						
function mod:UpdateIconList()
	local db = modIcons.active
	local optionsIcons = options.args.activeTemplate.args.icons
	
	for i = 1, #db do
		optionsIcons.args[tostring(i)] = {
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
						visibility = {
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
							order = 1,  type = "group", inline = true, name = "Position in grid and size of the icon in cells",
							args = {
								gridX = {
									order = 1, name = "Column", type = "range", min = -200, max = 200, step = 1,
									get = Get, set = Set,
								},
								gridY = {
									order = 2, name = "Row", type = "range", min = -200, max = 200, step = 1,
									get = Get, set = Set,
								},
								_s1 = {
									order = 3, type = "description", name = "",
								},
								sizeX = {
									order = 4, name = "Width", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
								sizeY = {
									order = 5, name = "Height", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
								sizeXY = {
									order = 6, name = "Width and Height", type = "range", min = 1, max = 200, step = 1,
									get = GetLockedGrid, set = SetLockedGrid,
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
							order = 101, type = "group", inline = true, name = "Position ( [0, 0] is bottom left corner )",
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
							order = 102, type = "group", inline = true, name = "Size",
							args = {
								width = {
									order = 1, type = "range", min = 1, max = 200, step = 1, name = "Width",
									get = Get, set = Set,
								},
								height = {
									order = 2, type = "range", min = 1, max = 200, step = 1, name = "Height", 
									get = Get, set = Set,
								},
								wandh = {
									order = 3, type = "range", min = 1, max = 200, step = 1, name = "Width and Height", 
									get = GetLockedLayout, set = SetLockedLayout,
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
						selectType = {
							order = 2, type = "group", inline = true, name = "Skin Type",
							args = {
								skinType = {
									order = 1, type = "select", name = "Skin type", values = GetSkinTypeList,
									get = GetSkinIcons, set = SetSkinIcons,
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
						alerts = {
							order = 3, type = "group", inline = true, name = "Alerts",
							args = {
								execAlert = {
									order = 1, type = "input", multiline = true, name = "", width = "full",
									get = Get, set = SetExec,
								},
								err = { order = 2, type = "description", name = GetErrExecAlert },
								soundList = {
									order = 3, type = 'select', dialogControl = 'LSM30_Sound', width="full", name = 'List of available sounds',
									values = LSM:HashTable("sound"), get = GetSound, set = SetSound,
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
							func = DeleteIcon,
						},
					},
				},
			},
		}
	end
	
	-- if we have masque then add it to options
  if clcInfo.MSQ then
  	for i = 1, #db do
	  	optionsIcons.args[tostring(i)].args.tabSkin.args.bfOptions = {
	  		order = 10, type = "group", inline = true, name = "Masque Options",
	  		args = {
	  			bfSkin = {
	  				order = 1, type = "select", name = "Masque Skin", values = clcInfo.MSQ_ListSkins,
	  				get = GetSkinIcons, set = SetSkinIcons,
	  			},
	  			bfGloss = {
	  				order = 2, type = "range", name = "Gloss", step = 1, min = 0, max = 100,
	  				get = GetSkinIcons, set = SetSkinIcons,
	  			},
	  			_x1 = {
	  			  order =  3, type = "description", name = "",
	  			},
	  			bfColorNormal = {
						order = 4, type = "color", hasAlpha = true, name = "Normal Color",
						get = GetSkinColor, set = SetSkinColor,
	  			},
	  			bfColorHighlight = {
	  			  order = 5, type = "color", hasAlpha = true, name = "Highlight Color",
						get = GetSkinColor, set = SetSkinColor,
	  			},
	  			bfColorGloss = {
	  			  order = 6, type = "color", hasAlpha = false, name = "Gloss Color",
						get = GetSkinColor, set = SetSkinColor,
	  			},
	  		}
	  	}
	  end
  end
	
	if mod.lastIconCount > #(db) then
		-- nil the rest of the args
		for i = #db + 1, mod.lastIconCount do
			optionsIcons.args[tostring(i)] = nil
		end
	end
	mod.lastIconCount = #db
	
	AceRegistry:NotifyChange("clcInfo")
end