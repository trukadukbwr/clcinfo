local ename = "bars"

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options
local AceSerializer = mod.AceSerializer

local LSM = clcInfo.LSM

local modBars = clcInfo.display.bars

-- static popup to make sure
local deleteObj = nil
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_BAR"] = {
	text = "Are you sure you want to delete this bar?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not deleteObj then return end
		deleteObj:Delete()
		mod:UpdateBarList()
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

-- info:
-- 	1 activeTemplate
-- 	2 bars
--	3 i
--	4 deleteTab
--	5 executeDelete
local function DeleteBar(info)
	local i = tonumber(info[3])
	deleteObj = modBars.active[i]
	StaticPopup_Show("CLCINFO_CONFIRM_DELETE_BAR")
end

-- info:
-- 	1 activeTemplate
-- 	2 bars
--	3 i
--	4 tabLayout
--	5 size, position, ... = group names
-- 	6 width, height, ...	= var names
local function Set(info, val)
	local obj = modBars.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateLayout()
end
local function Get(info)
	return modBars.active[tonumber(info[3])].db[info[6]]
end
-- color ones
local function SetColor(info, r, g, b, a)
	local obj = modBars.active[tonumber(info[3])]
	obj.db[info[6]] = { r, g, b, a } 
	obj:UpdateLayout()
end
local function GetColor(info)
	return unpack(modBars.active[tonumber(info[3])].db[info[6]])
end


-- skin get and set
local function SetSkinBars(info, val)
	local obj = modBars.active[tonumber(info[3])]
	obj.db.skin[info[6]] = val
	obj:UpdateLayout()
end
local function GetSkinBars(info)
	return modBars.active[tonumber(info[3])].db.skin[info[6]]
end
-- color ones
local function SetSkinBarsColor(info, r, g, b, a)
	local obj = modBars.active[tonumber(info[3])]
	obj.db.skin[info[6]] = { r, g, b, a }
	obj:UpdateLayout()
end
local function GetSkinBarsColor(info)
	return unpack(modBars.active[tonumber(info[3])].db.skin[info[6]])
end

local function Lock(info)
	modBars.active[tonumber(info[3])]:Lock()
end

local function Unlock(info)
	modBars.active[tonumber(info[3])]:Unlock()
end

local function SetExec(info, val)
	local obj = modBars.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateExec()
end

-- sound donothing control
local sound = "None"
local function GetSound() return sound end
local function SetSound(info, val) sound = val end
-- used to change error strings
local function GetErrExec(info) return modBars.active[tonumber(info[3])].errExec or "" end
local function GetErrExecAlert(info) return modBars.active[tonumber(info[3])].errExecAlert or "" end
local function GetErrExecEvent(info) return modBars.active[tonumber(info[3])].errExecEvent or "" end

-- user defined label
local function GetUDLabel(info)
	local name = modBars.active[tonumber(info[3])].db.udLabel
	if name == "" then name = "Bar" .. info[3] end
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
	local obj = modBars.active[tonumber(info[3])]
	obj.db.exec = clcInfo_Options.templates[ename][stc][val].exec
	obj:UpdateExec()
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- import / export
--------------------------------------------------------------------------------
local importString
local importId
StaticPopupDialogs["CLCINFO_CONFIRM_IMPORT_BAR"] = {
	text = "Are you sure you want to import this data?\nIf the information you pasted is wrong it could lead to a lot of problems.",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not importString or importString == "" then return end
		local success, t = AceSerializer:Deserialize(importString)
		if success then
			mod.SafeCopyTable(t, clcInfo.cdb.templates[clcInfo.activeTemplateIndex].bars[importId])
			clcInfo.display.bars.active[importId]:UpdateLayout()
			clcInfo.display.bars.active[importId]:UpdateExec()
			mod:UpdateBarList()
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
	return AceSerializer:Serialize(modBars.active[tonumber(info[3])].db)
end
local function SetExport(info, val) end
local function GetImport(info) end
local function SetImport(info, val)
	importString = val
	importId = tonumber(info[3])
	StaticPopup_Show("CLCINFO_CONFIRM_IMPORT_BAR")
end
--------------------------------------------------------------------------------


function mod:UpdateBarList()
	local db = modBars.active
	local optionsBars = options.args.activeTemplate.args.bars
	
	for i = 1, #db do
		optionsBars.args[tostring(i)] = {
			type = "group",
			name = GetUDLabel,
			order = i,
			childGroups = "tab",
			args = {
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
							order = 3, type = "group", inline = true, name = "",
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
							order = 4, type = "group", inline = true, name = "",
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
						ownColors = {
							order = 5, type = "group", inline = true, name = "Colors",
							args = {
								ownColors = {
									order = 1, type = "toggle", width = "full", name = "Force own colors.",
									get = Get, set = Set,
								},
								barColor = {
										order = 2, type = "color", hasAlpha = true, name = "Bar",
										get = GetSkinBarsColor, set = SetSkinBarsColor,
									},
								barBgColor = {
									order = 3, type = "color", hasAlpha = true, name = "Background",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
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
							order = 1,  type = "group", inline = true, name = "Position in grid and size of the bar in cells",
							args = {
								gridX = {
									order = 3, name = "Column", type = "range", min = -200, max = 200, step = 1,
									get = Get, set = Set,
								},
								gridY = {
									order = 4, name = "Row", type = "range", min = -200, max = 200, step = 1,
									get = Get, set = Set,
								},
								sizeX = {
									order = 5, name = "Width", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
								sizeY = {
									order = 6, name = "Height", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
							},
						},
					},
				},
			
				-- layout options
				tabLayout = {
					order = 3, type = "group", name = "Layout", args = {
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
									order = 1, type = "range", min = 1, max = 1000, step = 1, name = "Width",
									get = Get, set = Set,
								},
								height = {
									order = 2, type = "range", min = 1, max = 500, step = 1, name = "Height", 
									get = Get, set = Set,
								},
							},
						},
					},
				},
				
				-- tab skin here
				tabSkin = {
					order = 4, type = "group", name = "Skin",
					args = {
						__warning = {
							order = 1, type = "description",
							name = "|cff00ffffIn order to use these settings go to General tab and set |cffffffff[Use skin from] |cff00ffffoption to |cffffffff[Self]|cff00ffff.\n",
						},
						hasBg = {
							order = 2, type = "group", inline = true, name = "",
							args = {
								barBg = {
									type = "toggle", width = "full", name = "Use background texture.",
									get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						barColors = {
							order = 3, type = "group", inline = true, name = "Bar Colors",
							args = {
									barColor = {
										order = 1, type = "color", hasAlpha = true, name = "Bar",
										get = GetSkinBarsColor, set = SetSkinBarsColor,
									},
									__f1 = {
										order = 2, type = "description", width = "half", name = "",
									},
									barBgColor = {
										order = 3, type = "color", hasAlpha = true, name = "Background",
										get = GetSkinBarsColor, set = SetSkinBarsColor,
									},
							},
						},
						barTextures = {
							order = 4, type = "group", inline = true, name = "Bar Textures",
							args = {
								barTexture = {
									order = 1, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Bar',
									values = LSM:HashTable("statusbar"), get = GetSkinBars, set = SetSkinBars,
								},
								__f1 = {
									order = 2, type = "description", width = "half", name = "",
								},
								barBgTexture = {
									order = 3, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Background',
									values = LSM:HashTable("statusbar"), get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						
						
						
						advanced = {
							order = 5, type = "group", inline = true, name = "",
							args = {
								advancedSkin = {
									type = "toggle", width = "full", name = "Use advanced options",
									get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						
						iconpos = {
							order = 7, type = "group", inline = true, name = "Icon Position",
							args = {
								iconAlign = {
									order = 1, type = "select", name = "Icon Alignment",
									values = { ["left"] = "Left", ["right"] = "Right", ["hidden"] = "Hidden" },
									get = GetSkinBars, set = SetSkinBars,
								},
								_s1 = {
									order = 2, type = "description", name = "", width = "full"
								},
								iconLeft = {
									order = 3, type = "range", min = -100, max = 100, step = 0.1, name = "Left",
									get = GetSkinBars, set = SetSkinBars,
								},
								iconRight = {
									order = 4, type = "range", min = -100, max = 100, step = 0.1, name = "Right",
									get = GetSkinBars, set = SetSkinBars,
								},
								iconTop = {
									order = 5, type = "range", min = -100, max = 100, step = 0.1, name = "Top",
									get = GetSkinBars, set = SetSkinBars,
								},
								iconBottom = {
									order = 6, type = "range", min = -100, max = 100, step = 0.1, name = "Bottom",
									get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						
						barpos = {
							order = 8, type = "group", inline = true, name = "Bar Position",
							args = {
								barLeft = {
									order = 1, type = "range", min = -100, max = 100, step = 0.1, name = "Left",
									get = GetSkinBars, set = SetSkinBars,
								},
								barRight = {
									order = 2, type = "range", min = -100, max = 100, step = 0.1, name = "Right",
									get = GetSkinBars, set = SetSkinBars,
								},
								barTop = {
									order = 3, type = "range", min = -100, max = 100, step = 0.1, name = "Top",
									get = GetSkinBars, set = SetSkinBars,
								},
								barBottom = {
									order = 4, type = "range", min = -100, max = 100, step = 0.1, name = "Bottom",
									get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						
						textPosition = {
							order = 9, type = "group", inline = true, name = "Text positions",
							args = {
								l1 = {
									order = 1, type = "description", name = "Left Text", width = "half"
								},
								t1Left = {
									order = 2, type = "range", min = -100, max = 100, step = 0.1, name = "Horizontal",
									get = GetSkinBars, set = SetSkinBars,
								},
								t1Center = {
									order = 3, type = "range", min = -100, max = 100, step = 0.1, name = "Vertical",
									get = GetSkinBars, set = SetSkinBars,
								},
								_s1 = {
									order = 5, type = "description", name = "", width = "full"
								},
								
								l2 = {
									order = 6, type = "description", name = "Center Text", width = "half"
								},
								t2Center = {
									order = 7, type = "range", min = -100, max = 100, step = 0.1, name = "Vertical",
									get = GetSkinBars, set = SetSkinBars,
								},
								_s2 = {
									order = 9, type = "description", name = "", width = "full"
								},
								
								l3 = {
									order = 10, type = "description", name = "Right Text", width = "half"
								},
								t3Right = {
									order = 11, type = "range", min = -100, max = 100, step = 0.1, name = "Horizontal",
									get = GetSkinBars, set = SetSkinBars,
								},
								t3Center = {
									order = 12, type = "range", min = -100, max = 100, step = 0.1, name = "Vertical",
									get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						
						fontLeft = {
							order = 10, type = "group", inline = true, name = "Left Text",
							args = {
								t1Font = {
									order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
									values = LSM:HashTable("font"),
									get = GetSkinBars, set = SetSkinBars,
								},
								t1Size = {
									order = 2, type = "range", min = 1, max = 200, step = 1, name = "Height",
									get = GetSkinBars, set = SetSkinBars,
								},
								t1HSize = {
									order = 3, type = "range", min = 1, max = 200, step = 1, name = "Width",
									get = GetSkinBars, set = SetSkinBars,
								},
								t1Color = {
									order = 4, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
								t1Aliasing = {
									order = 5, type = "toggle", name = "Aliasing",
									get = GetSkinBars, set = SetSkinBars,
								},
								t1Outline = {
									order = 6, type = "toggle", name = "Outline",
									get = GetSkinBars, set = SetSkinBars,
								},
								t1ThickOutline = {
									order = 7, type = "toggle", name = "Thick Outline",
									get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						
						fontCenter = {
							order = 11, type = "group", inline = true, name = "Center Text",
							args = {
								t2Font = {
									order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
									values = LSM:HashTable("font"),
									get = GetSkinBars, set = SetSkinBars,
								},
								t2Size = {
									order = 2, type = "range", min = 1, max = 200, step = 1, name = "Text Size",
									get = GetSkinBars, set = SetSkinBars,
								},
								t2HSize = {
									order = 3, type = "range", min = 1, max = 200, step = 1, name = "Width",
									get = GetSkinBars, set = SetSkinBars,
								},
								t2Color = {
									order = 4, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
								t2Aliasing = {
									order = 5, type = "toggle", name = "Aliasing",
									get = GetSkinBars, set = SetSkinBars,
								},
								t2Outline = {
									order = 6, type = "toggle", name = "Outline",
									get = GetSkinBars, set = SetSkinBars,
								},
								t2ThickOutline = {
									order = 7, type = "toggle", name = "Thick Outline",
									get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						
						fontRight = {
							order = 12, type = "group", inline = true, name = "Right Text",
							args = {
								t3Font = {
									order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
									values = LSM:HashTable("font"),
									get = GetSkinBars, set = SetSkinBars,
								},
								t3Size = {
									order = 2, type = "range", min = 1, max = 200, step = 1, name = "Text Size",
									get = GetSkinBars, set = SetSkinBars,
								},
								t3HSize = {
									order = 3, type = "range", min = 1, max = 200, step = 1, name = "Width",
									get = GetSkinBars, set = SetSkinBars,
								},
								t3Color = {
									order = 4, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
								t3Aliasing = {
									order = 5, type = "toggle", name = "Aliasing",
									get = GetSkinBars, set = SetSkinBars,
								},
								t3Outline = {
									order = 6, type = "toggle", name = "Outline",
									get = GetSkinBars, set = SetSkinBars,
								},
								t3ThickOutline = {
									order = 7, type = "toggle", name = "Thick Outline",
									get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						
						bothbd = {
							order = 21, type = "group", inline = true, name = "Frame Backdrop",
							args = {
								bd = {
									order = 1, type = "toggle", name = "Enable",
									get = GetSkinBars, set = SetSkinBars,
								},
								inset = {
									order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
									get = GetSkinBars, set = SetSkinBars,
								},
								edgeSize = {
									order = 3, type = "range", min = 0, max = 64, step = 1, name = "Edge",
									get = GetSkinBars, set = SetSkinBars,
								},
								__f1 = {
									order = 4, type = "description", width = "full", name = "",
								},
								_bg = {
									order = 10, type = "description", width = "normal", name = "Background",
								},
								bdBg = {
									order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
									values = LSM:HashTable("background"), get = GetSkinBars, set = SetSkinBars,
								},
								__f2 = {
									order = 12, type = "description", width = "half", name = "",
								},
								bdColor = {
									order = 13, type = "color", hasAlpha = true, name = "Color", width = "normal",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
								_border = {
									order = 20, type = "description", width = "normal", name = "Border",
								},
								bdBorder = {
									order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
									values = LSM:HashTable("border"), get = GetSkinBars, set = SetSkinBars,
								},
								__f3 = {
									order = 22, type = "description", width = "half", name = "",
								},
								bdBorderColor = {
									order = 23, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
							},
						},
						
						iconbd = {
							order = 22, type = "group", inline = true, name = "Icon Backdrop",
							args = {
								iconBd = {
									order = 1, type = "toggle", name = "Enable",
									get = GetSkinBars, set = SetSkinBars,
								},
								iconInset = {
									order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
									get = GetSkinBars, set = SetSkinBars,
								},
								iconPadding = {
									order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
									get = GetSkinBars, set = SetSkinBars,
								},
								iconEdgeSize = {
									order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
									get = GetSkinBars, set = SetSkinBars,
								},
								_bg = {
									order = 10, type = "description", width = "normal", name = "Background",
								},
								iconBdBg = {
									order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
									values = LSM:HashTable("background"), get = GetSkinBars, set = SetSkinBars,
								},
								__f1 = {
									order = 12, type = "description", width = "half", name = "",
								},
								iconBdColor = {
									order = 13, type = "color", hasAlpha = true, name = "Color", width = "normal",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
								_border = {
									order = 20, type = "description", width = "normal", name = "Border",
								},
								iconBdBorder = {
									order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
									values = LSM:HashTable("border"), get = GetSkinBars, set = SetSkinBars,
								},
								__f2 = {
									order = 22, type = "description", width = "half", name = "",
								},
								iconBdBorderColor = {
									order = 23, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
							},
						},
						
						barbd = {
							order = 23, type = "group", inline = true, name = "Bar Backdrop",
							args = {
								barBd = {
									order = 1, type = "toggle", name = "Enable",
									get = GetSkinBars, set = SetSkinBars,
								},
								barInset = {
									order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
									get = GetSkinBars, set = SetSkinBars,
								},
								barPadding = {
									order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
									get = GetSkinBars, set = SetSkinBars,
								},
								barEdgeSize = {
									order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
									get = GetSkinBars, set = SetSkinBars,
								},
								_border = {
									order = 20, type = "description", width = "normal", name = "Border",
								},
								barBdBorder = {
									order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
									values = LSM:HashTable("border"), get = GetSkinBars, set = SetSkinBars,
								},
								__f2 = {
									order = 22, type = "description", width = "half", name = "",
								},
								barBdBorderColor = {
									order = 23, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
							},
						},
					},
				},
				
				
				-- behavior options
				tabBehavior = {
					order = 50, type = "group", name = "Behavior", 
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
								_x1 = {
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
							func = DeleteBar,
						},
					},
				},
			},
		}
	end
	
	if mod.lastBarCount > #(db) then
		-- nil the rest of the args
		for i = #db + 1, mod.lastBarCount do
			optionsBars.args[tostring(i)] = nil
		end
	end
	mod.lastBarCount = #db
	
	AceRegistry:NotifyChange("clcInfo")
end