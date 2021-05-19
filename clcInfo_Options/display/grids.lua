-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options
local AceSerializer = mod.AceSerializer

local modGrids = clcInfo.display.grids

local LSM = clcInfo.LSM

-- static popup to make sure
local deleteObj = nil
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_GRID"] = {
	text = "Are you sure you want to delete this grid?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not deleteObj then return end
		deleteObj:Delete()
		mod:UpdateGridList()
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

-- info:
-- 	1 activeTemplate
-- 	2 grids
--	3 i
--	4 deleteTab
--	5 executeDelete
local function DeleteGrid(info)
	local i = tonumber(info[3])
	deleteObj = modGrids.active[i]
	StaticPopup_Show("CLCINFO_CONFIRM_DELETE_GRID")
end

-- info:
-- 	1 activeTemplate
-- 	2 grids
--	3 i
--	4 tabLayout
--	5 size, position, ... = group names
-- 	6 width, height, ...	= var names
local function Set(info, val)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateLayout()
end
local function Get(info)
	return modGrids.active[tonumber(info[3])].db[info[6]]
end

-- general skin functions
-- info: activeTemplate grids 1 tabSkins micons selectType skinType

local function SetSkin(info, val)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db.skinOptions[info[5]][info[7]] = val
	obj:UpdateLayout() 
end
local function GetSkin(info)
	return modGrids.active[tonumber(info[3])].db.skinOptions[info[5]][info[7]]
end
local function SetSkinColor(info, r, g, b, a)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db.skinOptions[info[5]][info[7]] = { r, g, b, a }
	obj:UpdateLayout()
end
local function GetSkinColor(info)
	return unpack(modGrids.active[tonumber(info[3])].db.skinOptions[info[5]][info[7]])
end

local function SetLocked(info, val)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db.cellWidth = val
	obj.db.cellHeight = val
	obj:UpdateLayout()
end
local function GetLocked(info)
	return modGrids.active[tonumber(info[3])].db.cellWidth
end

local function Lock(info)
	modGrids.active[tonumber(info[3])]:Lock()
end

local function Unlock(info)
	modGrids.active[tonumber(info[3])]:Unlock()
end

local function AddIcon(info)
	clcInfo.display.icons:Add(tonumber(info[3]))
	mod:UpdateIconList()
end
local function AddMIcon(info)
	clcInfo.display.micons:Add(tonumber(info[3]))
	mod:UpdateMIconList()
end
local function AddBar(info)
	clcInfo.display.bars:Add(tonumber(info[3]))
	mod:UpdateBarList()
end
local function AddMBar(info)
	clcInfo.display.mbars:Add(tonumber(info[3]))
	mod:UpdateMBarList()
end
local function AddText(info)
	clcInfo.display.texts:Add(tonumber(info[3]))
	mod:UpdateTextList()
end



local function GetSkinTypeList()
	local list = { ["Default"] = "Default", ["BareBone"] = "BareBone" }
	if clcInfo.MSQ then list["Masque"] = "Masque" end
	return list
end

local function GetUDLabel(info)
	local name = modGrids.active[tonumber(info[3])].db.udLabel
	if name == "" then name = "Grid" .. info[3] end
	return name
end


--------------------------------------------------------------------------------
-- import / export
--------------------------------------------------------------------------------
local importString
local importId
StaticPopupDialogs["CLCINFO_CONFIRM_IMPORT_GRID"] = {
	text = "Are you sure you want to import this data?\nIf the information you pasted is wrong it could lead to a lot of problems.",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not importString or importString == "" then return end
		local success, t = AceSerializer:Deserialize(importString)
		if success then
			mod.SafeCopyTable(t, clcInfo.cdb.templates[clcInfo.activeTemplateIndex].grids[importId])
			clcInfo.display.grids.active[importId]:UpdateLayout()
			mod:UpdateGridList()
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
	return AceSerializer:Serialize(modGrids.active[tonumber(info[3])].db)
end
local function SetExport(info, val) end
local function GetImport(info) end
local function SetImport(info, val)
	importString = val
	importId = tonumber(info[3])
	StaticPopup_Show("CLCINFO_CONFIRM_IMPORT_GRID")
end
--------------------------------------------------------------------------------


function mod:UpdateGridList()
	local db = modGrids.active
	local optionsGrids = options.args.activeTemplate.args.grids
	
	for i = 1, #db do
		optionsGrids.args[tostring(i)] = {
			type = "group", childGroups = "tab", name = GetUDLabel,
			args = {
				tabGeneral = {
					order = 1, type = "group", name = "General",
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
						add = {
							order = 2, type = "group", inline = true, name = "Add Elements", args = {
								addIcon = { order = 1, type = "execute", name = "Add Icon", func = AddIcon },
								addBar = { order = 2, type = "execute", name = "Add Bar", func = AddBar },
								addMIcon = { order = 3, type = "execute", name = "Add Multi Icon", func = AddMIcon },
								addMBar = { order = 4, type = "execute", name = "Add Multi Bar", func = AddMBar },
								addText = { order = 5, type = "execute", name = "Add Text", func = AddText },
				  		}
						},
						lock = {
							order = 3, type = "group", inline = true, name = "Lock",
							args = {
								lock = {
				  				order = 1, type = "execute", name = "Lock", func = Lock
				  			},
				  			unlock = {
				  				order = 2, type = "execute", name = "Unlock", func = Unlock,
				  			},
							},
						},
					},
				},
			
				-- layout options
				tabLayout = {
					order = 2, type = "group", name = "Layout",
					args = {
						position = {
							order = 3, type = "group", inline = true, name = "Position",
							args = {
								x = {
									order = 1, name = "X", type = "range", min = -2000, max = 2000, step = 1,
									get = Get, set = Set,
								},
								y = {
									order = 2, name = "Y", type = "range", min = -1000, max = 1000, step = 1,
									get = Get, set = Set,
								},
							},
						},
							
						cellSize = {
							order = 4, type = "group", inline = true, name = "Cell Size",
							args = {
								cellWidth = {
									order = 1, name = "Cell Width", type = "range", min = 1, max = 1000, step = 1,
									get = Get, set = Set,
								},
								cellHeight = {
									order = 2, name = "Cell Height", type = "range", min = 1, max = 1000, step = 1,
									get = Get, set = Set,
								},
								WandH = {
									order = 3, name = "Width and Height", type = "range", min = 1, max = 1000, step = 1,
									get = GetLocked, set = SetLocked,
								},
							},
						},
							
						cellNum = {
							order = 5, type = "group", inline = true, name = "Number of cells",
							args = {
								cellsX = {
									order = 1, name = "Columns", type = "range", min = 1, max = 50, step = 1,
									get = Get, set = Set,
								},
								cellsY = {
									order = 2, name = "Rows", type = "range", min = 1, max = 50, step = 1,
									get = Get, set = Set,
								},
							},
						},
						spacing = {
							order = 6, type = "group", inline = true, name = "Spacing",
							args = {
								spacingX = {
									order = 3, name = "Horizontal", type = "range", min = -10, max = 50, step = 1,
									get = Get, set = Set,
								},
								spacingY = {
									order = 4, name = "Vertical", type = "range", min = -10, max = 50, step = 1,
									get = Get, set = Set,
								},
							},
						},
					},
				},
				
				tabSkins = {
					order = 3, type = "group", name = "Skins", childGroups = "tab",
					args = {
						icons = {
							order = 3, type = "group", name = "Icons",
							args = {
								selectType = {
									order = 1, type = "group", inline = true, name = "Skin Type",
									args = {
										skinType = {
											order = 1, type = "select", name = "Skin type", values = GetSkinTypeList,
											get = GetSkin, set = SetSkin,
										},
									},
								},
							}
						},
						
						micons = {
							order = 4, type = "group", name = "Multi Icons",
							args = {
								selectType = {
									order = 1, type = "group", inline = true, name = "Skin Type",
									args = {
										skinType = {
											order = 1, type = "select", name = "Skin type", values = GetSkinTypeList,
											get = GetSkin, set = SetSkin,
										},
									},
								},
							}
						},
						
						bars = {
							order = 5, type = "group", name = "Bars",
							args = {
								hasBg = {
									order = 2, type = "group", inline = true, name = "",
									args = {
										barBg = {
											type = "toggle", width = "full", name = "Use background texture.",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								barColors = {
									order = 3, type = "group", inline = true, name = "Bar Colors",
									args = {
											barColor = {
												order = 1, type = "color", hasAlpha = true, name = "Bar",
												get = GetSkinColor, set = SetSkinColor,
											},
											__f1 = {
												order = 2, type = "description", width = "half", name = "",
											},
											barBgColor = {
												order = 3, type = "color", hasAlpha = true, name = "Background",
												get = GetSkinColor, set = SetSkinColor,
											},
									},
								},
								barTextures = {
									order = 4, type = "group", inline = true, name = "Bar Textures",
									args = {
										barTexture = {
											order = 1, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Bar',
											values = LSM:HashTable("statusbar"), get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 2, type = "description", width = "half", name = "",
										},
										barBgTexture = {
											order = 3, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Background',
											values = LSM:HashTable("statusbar"), get = GetSkin, set = SetSkin,
										},
									},
								},
								
								advanced = {
									order = 5, type = "group", inline = true, name = "",
									args = {
										advancedSkin = {
											type = "toggle", width = "full", name = "Use advanced options",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								iconpos = {
									order = 7, type = "group", inline = true, name = "Icon Position",
									args = {
										iconAlign = {
											order = 1, type = "select", name = "Icon Alignment",
											values = { ["left"] = "Left", ["right"] = "Right", ["hidden"] = "Hidden" },
											get = GetSkin, set = SetSkin,
										},
										_s1 = {
											order = 2, type = "description", name = "", width = "full"
										},
										iconLeft = {
											order = 3, type = "range", min = -100, max = 100, step = 0.1, name = "Left",
											get = GetSkin, set = SetSkin,
										},
										iconRight = {
											order = 4, type = "range", min = -100, max = 100, step = 0.1, name = "Right",
											get = GetSkin, set = SetSkin,
										},
										iconTop = {
											order = 5, type = "range", min = -100, max = 100, step = 0.1, name = "Top",
											get = GetSkin, set = SetSkin,
										},
										iconBottom = {
											order = 6, type = "range", min = -100, max = 100, step = 0.1, name = "Bottom",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								barpos = {
									order = 8, type = "group", inline = true, name = "Bar Position",
									args = {
										barLeft = {
											order = 1, type = "range", min = -100, max = 100, step = 0.1, name = "Left",
											get = GetSkin, set = SetSkin,
										},
										barRight = {
											order = 2, type = "range", min = -100, max = 100, step = 0.1, name = "Right",
											get = GetSkin, set = SetSkin,
										},
										barTop = {
											order = 3, type = "range", min = -100, max = 100, step = 0.1, name = "Top",
											get = GetSkin, set = SetSkin,
										},
										barBottom = {
											order = 4, type = "range", min = -100, max = 100, step = 0.1, name = "Bottom",
											get = GetSkin, set = SetSkin,
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
											get = GetSkin, set = SetSkin,
										},
										t1Center = {
											order = 3, type = "range", min = -100, max = 100, step = 0.1, name = "Vertical",
											get = GetSkin, set = SetSkin,
										},
										_s1 = {
											order = 5, type = "description", name = "", width = "full"
										},
										
										l2 = {
											order = 6, type = "description", name = "Center Text", width = "half"
										},
										t2Center = {
											order = 7, type = "range", min = -100, max = 100, step = 0.1, name = "Vertical",
											get = GetSkin, set = SetSkin,
										},
										_s2 = {
											order = 9, type = "description", name = "", width = "full"
										},
										
										l3 = {
											order = 10, type = "description", name = "Right Text", width = "half"
										},
										t3Right = {
											order = 11, type = "range", min = -100, max = 100, step = 0.1, name = "Horizontal",
											get = GetSkin, set = SetSkin,
										},
										t3Center = {
											order = 12, type = "range", min = -100, max = 100, step = 0.1, name = "Vertical",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								fontLeft = {
									order = 10, type = "group", inline = true, name = "Left Text",
									args = {
										t1Font = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										t1Size = {
											order = 2, type = "range", min = 1, max = 200, step = 1, name = "Height",
											get = GetSkin, set = SetSkin,
										},
										t1HSize = {
											order = 3, type = "range", min = 1, max = 200, step = 1, name = "Width",
											get = GetSkin, set = SetSkin,
										},
										t1Color = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
										t1Aliasing = {
											order = 5, type = "toggle", name = "Aliasing",
											get = GetSkin, set = SetSkin,
										},
										t1Outline = {
											order = 6, type = "toggle", name = "Outline",
											get = GetSkin, set = SetSkin,
										},
										t1ThickOutline = {
											order = 7, type = "toggle", name = "Thick Outline",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								fontCenter = {
									order = 11, type = "group", inline = true, name = "Center Text",
									args = {
										t2Font = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										t2Size = {
											order = 2, type = "range", min = 1, max = 200, step = 1, name = "Text Size",
											get = GetSkin, set = SetSkin,
										},
										t2HSize = {
											order = 3, type = "range", min = 1, max = 200, step = 1, name = "Width",
											get = GetSkin, set = SetSkin,
										},
										t2Color = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
										t2Aliasing = {
											order = 5, type = "toggle", name = "Aliasing",
											get = GetSkin, set = SetSkin,
										},
										t2Outline = {
											order = 6, type = "toggle", name = "Outline",
											get = GetSkin, set = SetSkin,
										},
										t2ThickOutline = {
											order = 7, type = "toggle", name = "Thick Outline",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								fontRight = {
									order = 12, type = "group", inline = true, name = "Right Text",
									args = {
										t3Font = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										t3Size = {
											order = 2, type = "range", min = 1, max = 200, step = 1, name = "Text Size",
											get = GetSkin, set = SetSkin,
										},
										t3HSize = {
											order = 3, type = "range", min = 1, max = 200, step = 1, name = "Width",
											get = GetSkin, set = SetSkin,
										},
										t3Color = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
										t3Aliasing = {
											order = 5, type = "toggle", name = "Aliasing",
											get = GetSkin, set = SetSkin,
										},
										t3Outline = {
											order = 6, type = "toggle", name = "Outline",
											get = GetSkin, set = SetSkin,
										},
										t3ThickOutline = {
											order = 7, type = "toggle", name = "Thick Outline",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								bothbd = {
									order = 21, type = "group", inline = true, name = "Frame Backdrop",
									args = {
										bd = {
											order = 1, type = "toggle", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										inset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										edgeSize = {
											order = 3, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 4, type = "description", width = "full", name = "",
										},
										_bg = {
											order = 10, type = "description", width = "normal", name = "Background",
										},
										bdBg = {
											order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
											values = LSM:HashTable("background"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 12, type = "description", width = "half", name = "",
										},
										bdColor = {
											order = 13, type = "color", hasAlpha = true, name = "Color", width = "normal",
											get = GetSkinColor, set = SetSkinColor,
										},
										_border = {
											order = 20, type = "description", width = "normal", name = "Border",
										},
										bdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f3 = {
											order = 22, type = "description", width = "half", name = "",
										},
										bdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								iconbd = {
									order = 22, type = "group", inline = true, name = "Icon Backdrop",
									args = {
										iconBd = {
											order = 1, type = "toggle", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										iconInset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										iconPadding = {
											order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
											get = GetSkin, set = SetSkin,
										},
										iconEdgeSize = {
											order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										_bg = {
											order = 10, type = "description", width = "normal", name = "Background",
										},
										iconBdBg = {
											order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
											values = LSM:HashTable("background"), get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 12, type = "description", width = "half", name = "",
										},
										iconBdColor = {
											order = 13, type = "color", hasAlpha = true, name = "Color", width = "normal",
											get = GetSkinColor, set = SetSkinColor,
										},
										_border = {
											order = 20, type = "description", width = "normal", name = "Border",
										},
										iconBdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 22, type = "description", width = "half", name = "",
										},
										iconBdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								barbd = {
									order = 23, type = "group", inline = true, name = "Bar Backdrop",
									args = {
										barBd = {
											order = 1, type = "toggle", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										barInset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										barPadding = {
											order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
											get = GetSkin, set = SetSkin,
										},
										barEdgeSize = {
											order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										_border = {
											order = 20, type = "description", width = "normal", name = "Border",
										},
										barBdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 22, type = "description", width = "half", name = "",
										},
										barBdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
							},
						},
						
						mbars = {
							order = 6, type = "group", name = "Multi Bars",
							args = {
								hasBg = {
									order = 2, type = "group", inline = true, name = "",
									args = {
										barBg = {
											type = "toggle", width = "full", name = "Use background texture.",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								barColors = {
									order = 3, type = "group", inline = true, name = "Bar Colors",
									args = {
											barColor = {
												order = 1, type = "color", hasAlpha = true, name = "Bar",
												get = GetSkinColor, set = SetSkinColor,
											},
											__f1 = {
												order = 2, type = "description", width = "half", name = "",
											},
											barBgColor = {
												order = 3, type = "color", hasAlpha = true, name = "Background",
												get = GetSkinColor, set = SetSkinColor,
											},
									},
								},
								barTextures = {
									order = 4, type = "group", inline = true, name = "Bar Textures",
									args = {
										barTexture = {
											order = 1, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Bar',
											values = LSM:HashTable("statusbar"), get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 2, type = "description", width = "half", name = "",
										},
										barBgTexture = {
											order = 3, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Background',
											values = LSM:HashTable("statusbar"), get = GetSkin, set = SetSkin,
										},
									},
								},
								
								
								
								advanced = {
									order = 5, type = "group", inline = true, name = "",
									args = {
										advancedSkin = {
											type = "toggle", width = "full", name = "Use advanced options",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								iconpos = {
									order = 7, type = "group", inline = true, name = "Icon Position",
									args = {
										iconAlign = {
											order = 1, type = "select", name = "Icon Alignment",
											values = { ["left"] = "Left", ["right"] = "Right", ["hidden"] = "Hidden" },
											get = GetSkin, set = SetSkin,
										},
										_s1 = {
											order = 2, type = "description", name = "", width = "full"
										},
										iconLeft = {
											order = 3, type = "range", min = -100, max = 100, step = 0.1, name = "Left",
											get = GetSkin, set = SetSkin,
										},
										iconRight = {
											order = 4, type = "range", min = -100, max = 100, step = 0.1, name = "Right",
											get = GetSkin, set = SetSkin,
										},
										iconTop = {
											order = 5, type = "range", min = -100, max = 100, step = 0.1, name = "Top",
											get = GetSkin, set = SetSkin,
										},
										iconBottom = {
											order = 6, type = "range", min = -100, max = 100, step = 0.1, name = "Bottom",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								barpos = {
									order = 8, type = "group", inline = true, name = "Bar Position",
									args = {
										barLeft = {
											order = 1, type = "range", min = -100, max = 100, step = 0.1, name = "Left",
											get = GetSkin, set = SetSkin,
										},
										barRight = {
											order = 2, type = "range", min = -100, max = 100, step = 0.1, name = "Right",
											get = GetSkin, set = SetSkin,
										},
										barTop = {
											order = 3, type = "range", min = -100, max = 100, step = 0.1, name = "Top",
											get = GetSkin, set = SetSkin,
										},
										barBottom = {
											order = 4, type = "range", min = -100, max = 100, step = 0.1, name = "Bottom",
											get = GetSkin, set = SetSkin,
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
											get = GetSkin, set = SetSkin,
										},
										t1Center = {
											order = 3, type = "range", min = -100, max = 100, step = 0.1, name = "Vertical",
											get = GetSkin, set = SetSkin,
										},
										_s1 = {
											order = 5, type = "description", name = "", width = "full"
										},
										
										l2 = {
											order = 6, type = "description", name = "Center Text", width = "half"
										},
										t2Center = {
											order = 7, type = "range", min = -100, max = 100, step = 0.1, name = "Vertical",
											get = GetSkin, set = SetSkin,
										},
										_s2 = {
											order = 9, type = "description", name = "", width = "full"
										},
										
										l3 = {
											order = 10, type = "description", name = "Right Text", width = "half"
										},
										t3Right = {
											order = 11, type = "range", min = -100, max = 100, step = 0.1, name = "Horizontal",
											get = GetSkin, set = SetSkin,
										},
										t3Center = {
											order = 12, type = "range", min = -100, max = 100, step = 0.1, name = "Vertical",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								fontLeft = {
									order = 10, type = "group", inline = true, name = "Left Text",
									args = {
										t1Font = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										t1Size = {
											order = 2, type = "range", min = 1, max = 200, step = 1, name = "Height",
											get = GetSkin, set = SetSkin,
										},
										t1HSize = {
											order = 3, type = "range", min = 1, max = 200, step = 1, name = "Width",
											get = GetSkin, set = SetSkin,
										},
										t1Color = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
										t1Aliasing = {
											order = 5, type = "toggle", name = "Aliasing",
											get = GetSkin, set = SetSkin,
										},
										t1Outline = {
											order = 6, type = "toggle", name = "Outline",
											get = GetSkin, set = SetSkin,
										},
										t1ThickOutline = {
											order = 7, type = "toggle", name = "Thick Outline",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								fontCenter = {
									order = 11, type = "group", inline = true, name = "Center Text",
									args = {
										t2Font = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										t2Size = {
											order = 2, type = "range", min = 1, max = 200, step = 1, name = "Text Size",
											get = GetSkin, set = SetSkin,
										},
										t2HSize = {
											order = 3, type = "range", min = 1, max = 200, step = 1, name = "Width",
											get = GetSkin, set = SetSkin,
										},
										t2Color = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
										t2Aliasing = {
											order = 5, type = "toggle", name = "Aliasing",
											get = GetSkin, set = SetSkin,
										},
										t2Outline = {
											order = 6, type = "toggle", name = "Outline",
											get = GetSkin, set = SetSkin,
										},
										t2ThickOutline = {
											order = 7, type = "toggle", name = "Thick Outline",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								fontRight = {
									order = 12, type = "group", inline = true, name = "Right Text",
									args = {
										t3Font = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										t3Size = {
											order = 2, type = "range", min = 1, max = 200, step = 1, name = "Text Size",
											get = GetSkin, set = SetSkin,
										},
										t3HSize = {
											order = 3, type = "range", min = 1, max = 200, step = 1, name = "Width",
											get = GetSkin, set = SetSkin,
										},
										t3Color = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
										t3Aliasing = {
											order = 5, type = "toggle", name = "Aliasing",
											get = GetSkin, set = SetSkin,
										},
										t3Outline = {
											order = 6, type = "toggle", name = "Outline",
											get = GetSkin, set = SetSkin,
										},
										t3ThickOutline = {
											order = 7, type = "toggle", name = "Thick Outline",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								bothbd = {
									order = 21, type = "group", inline = true, name = "Frame Backdrop",
									args = {
										bd = {
											order = 1, type = "toggle", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										inset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										edgeSize = {
											order = 3, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 4, type = "description", width = "full", name = "",
										},
										_bg = {
											order = 10, type = "description", width = "normal", name = "Background",
										},
										bdBg = {
											order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
											values = LSM:HashTable("background"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 12, type = "description", width = "half", name = "",
										},
										bdColor = {
											order = 13, type = "color", hasAlpha = true, name = "Color", width = "normal",
											get = GetSkinColor, set = SetSkinColor,
										},
										_border = {
											order = 20, type = "description", width = "normal", name = "Border",
										},
										bdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f3 = {
											order = 22, type = "description", width = "half", name = "",
										},
										bdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								iconbd = {
									order = 22, type = "group", inline = true, name = "Icon Backdrop",
									args = {
										iconBd = {
											order = 1, type = "toggle", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										iconInset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										iconPadding = {
											order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
											get = GetSkin, set = SetSkin,
										},
										iconEdgeSize = {
											order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										_bg = {
											order = 10, type = "description", width = "normal", name = "Background",
										},
										iconBdBg = {
											order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
											values = LSM:HashTable("background"), get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 12, type = "description", width = "half", name = "",
										},
										iconBdColor = {
											order = 13, type = "color", hasAlpha = true, name = "Color", width = "normal",
											get = GetSkinColor, set = SetSkinColor,
										},
										_border = {
											order = 20, type = "description", width = "normal", name = "Border",
										},
										iconBdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 22, type = "description", width = "half", name = "",
										},
										iconBdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								barbd = {
									order = 23, type = "group", inline = true, name = "Bar Backdrop",
									args = {
										barBd = {
											order = 1, type = "toggle", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										barInset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										barPadding = {
											order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
											get = GetSkin, set = SetSkin,
										},
										barEdgeSize = {
											order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										_border = {
											order = 20, type = "description", width = "normal", name = "Border",
										},
										barBdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 22, type = "description", width = "half", name = "",
										},
										barBdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
							},
						},
						
						texts = {
							order = 7, type = "group", name = "Texts",
							args = {
								base = {
									order = 2, type = "group", inline = true, name = "Base",
									args = {
										family = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font', values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										size = {
											order = 2, type = "range", min = 0, max = 200, step = 1, name = "Size%",
											get = GetSkin, set = SetSkin,
										},
										color = {
											order = 3, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								shadow = {
									order = 3, type = "group", inline = true, name = "Shadow",
									args = {
										shadowOffsetX = {
											order = 1, type = "range", min = -20, max = 20, step = 0.01, name = "Shadow Offset X",
											get = GetSkin, set = SetSkin,
										},
										shadowOffsetY = {
											order = 2, type = "range", min = -20, max = 20, step = 0.01, name = "Shadow Offset Y",
											get = GetSkin, set = SetSkin,
										},
										shadowColor = {
											order = 3, type = "color", hasAlpha = true, name = "Shadow Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								flags = {
									order = 4, type = "group", inline = true, name = "Flags",
									args = {
										aliasing = {
											order = 1, type = "toggle", name = "Aliasing",
											get = GetSkin, set = SetSkin,
										},
										outline = {
											order = 2, type = "toggle", name = "Outline",
											get = GetSkin, set = SetSkin,
										},
										thickoutline = {
											order = 3, type = "toggle", name = "Thick Outline",
											get = GetSkin, set = SetSkin,
										},
									},
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
							func = DeleteGrid,
						},
					},
				},
			},
		}
	end
	
	-- if we have masque then add it to options
  if clcInfo.MSQ then
  	for i = 1, #db do
	  	optionsGrids.args[tostring(i)].args.tabSkins.args.icons.args.bfOptions = {
	  		order = 2, type = "group", inline = true, name = "Masque Options",
	  		args = {
	  			bfSkin = {
	  				order = 1, type = "select", name = "Masque Skin", values = clcInfo.MSQ_ListSkins,
	  				get = GetSkin, set = SetSkin,
	  			},
	  			bfGloss = {
	  				order = 1, type = "range", name = "Gloss", step = 1, min = 0, max = 100,
	  				get = GetSkin, set = SetSkin,
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
	  	optionsGrids.args[tostring(i)].args.tabSkins.args.micons.args.bfOptions = {
	  		order = 2, type = "group", inline = true, name = "Masque Options",
	  		args = {
	  			bfSkin = {
	  				order = 1, type = "select", name = "Masque Skin", values = clcInfo.MSQ_ListSkins,
	  				get = GetSkin, set = SetSkin,
	  			},
	  			bfGloss = {
	  				order = 1, type = "range", name = "Gloss", step = 1, min = 0, max = 100,
	  				get = GetSkin, set = SetSkin,
	  			},
	  			_x1 = {
	  			  order =  3, type = "description", name = "",
	  			},
	  			bfColorNormal = {
						order = 4, type = "color", hasAlpha = true, name = "Normal Color",
						get = GetSkinColor, set = SetSkinColor,
	  			},
	  			bfColorGloss = {
	  			  order = 5, type = "color", hasAlpha = false, name = "Gloss Color",
						get = GetSkinColor, set = SetSkinColor,
	  			},
	  		}
	  	}
	  end
  end
	
	if mod.lastGridCount > #(db) then
		-- nil the rest of the args
		for i = #db + 1, mod.lastGridCount do
			optionsGrids.args[tostring(i)] = nil
		end
	end
	mod.lastGridCount = #db
	
	AceRegistry:NotifyChange("clcInfo")
end