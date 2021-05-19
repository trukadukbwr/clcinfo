-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options
local AceSerializer = mod.AceSerializer

local modAlerts = clcInfo.display.alerts  -- link to the module

-- static popup to make sure
local deleteObj = nil
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_ALERT"] = {
	text = "Are you sure you want to delete this animation?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not deleteObj then return end
		deleteObj:Delete()
		mod:UpdateAlertList()
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

-- info:
-- 	1 activeTemplate
-- 	2 alerts
--	3 i
--	4 deleteTab
--	5 executeDelete
local function DeleteAlert(info)
	local i = tonumber(info[3])
	deleteObj = modAlerts.active[i]
	StaticPopup_Show("CLCINFO_CONFIRM_DELETE_ALERT")
end

-- info:
-- 	1 activeTemplate
-- 	2 alerts
--	3 i
--	4 tabLayout
--	5 size, position, ... = group names
-- 	6 width, height, ...	= var names
local function Set(info, val)
	local obj = modAlerts.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateLayout()
end
local function Get(info)
	return modAlerts.active[tonumber(info[3])].db[info[6]]
end
local function SetLockedLayout(info, val)
	local obj = modAlerts.active[tonumber(info[3])]
	obj.db.width = val
	obj.db.height = val
	obj:UpdateLayout()
end
local function GetLockedLayout(info)
	return modAlerts.active[tonumber(info[3])].db.width
end

local function Lock(info)
	modAlerts.active[tonumber(info[3])]:Lock()
end
local function Unlock(info)
	modAlerts.active[tonumber(info[3])]:Unlock()
end

local function TestAnimation(info)
	modAlerts.active[tonumber(info[3])]:StartAnim()
end

local SmoothingValues = { IN = "IN", IN_OUT = "IN_OUT", NONE = "NONE", OUT = "OUT"}

-- get label
local function GetUDLabel(info)
	local name = modAlerts.active[tonumber(info[3])].db.udLabel
	if name == "" then name = "Animation" .. info[3] end
	return "[" .. info[3] .. "]" .. name
end

--------------------------------------------------------------------------------
-- import / export
--------------------------------------------------------------------------------
local importString
local importId
StaticPopupDialogs["CLCINFO_CONFIRM_IMPORT_ALERT"] = {
	text = "Are you sure you want to import this data?\nIf the information you pasted is wrong it could lead to a lot of problems.",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not importString or importString == "" then return end
		local success, t = AceSerializer:Deserialize(importString)
		if success then
			mod.SafeCopyTable(t, clcInfo.cdb.templates[clcInfo.activeTemplateIndex].alerts[importId])
			clcInfo.display.alerts.active[importId]:UpdateLayout()
			mod:UpdateAlertList()
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
	return AceSerializer:Serialize(modAlerts.active[tonumber(info[3])].db)
end
local function SetExport(info, val) end
local function GetImport(info) end
local function SetImport(info, val)
	importString = val
	importId = tonumber(info[3])
	StaticPopup_Show("CLCINFO_CONFIRM_IMPORT_ALERT")
end
--------------------------------------------------------------------------------

function mod:UpdateAlertList()
	local db = modAlerts.active
	local optionsAlerts = options.args.activeTemplate.args.alerts
	
	for i = 1, #db do
		optionsAlerts.args[tostring(i)] = {
			type = "group",
			name = GetUDLabel,
			order = i,
			childGroups = "tab",
			args = {
				-- general
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
						lock = {
							order = 2, type = "group", inline = true, name = "",
							args = {
								lock = {
				  				type = "execute", name = "Lock", func = Lock
				  			},
				  			unlock = {
				  				type = "execute", name = "Unlock", func = Unlock,
				  			},
							},
						},
					},
				},
				
				tabAnim = {
					order = 2, type = "group", name = "Animation",
					args = {
						group = {
							order = 1, type = "group", inline = true, name = "Group",
							args = {
								loops = {
									order = 1, type = "range", min = 1, max = 50, step = 1, name = "Loops",
									get = Get, set = Set, 
								},
								loopType = {
									order = 2, type = "select", name = "Loop type", values = { NONE = "NONE", REPEAT = "REPEAT", BOUNCE = "BOUNCE" },
									get = Get, set = Set, 
								},
								test = {
									order = 10, type = "execute", name = "Test Animation", func = TestAnimation,
								},
							},
						},
						
						scale = {
							order = 2, type = "group", inline = true, name = "Scale",
							args = {
								scaleX = {
									order = 1, type = "range", min = 0.01, max = 10, step = 0.01, name = "X",
									get = Get, set = Set, 
								},
								scaleY = {
									order = 2, type = "range", min = 0.01, max = 10, step = 0.01, name = "Y",
									get = Get, set = Set, 
								},
								scaleSmoothType = {
									order = 3, type = "select", name = "Smooth type", values = SmoothingValues,
									get = Get, set = Set, 
								},
								scaleDuration = {
									order = 11, type = "range", min = 0, max = 10, step = 0.01, name = "Duration",
									get = Get, set = Set, 
								},
								scaleStartDelay = {
									order = 12, type = "range", min = 0, max = 10, step = 0.01, name = "StartDelay",
									get = Get, set = Set, 
								},
								scaleEndDelay = {
									order = 13, type = "range", min = 0, max = 10, step = 0.01, name = "EndDelay",
									get = Get, set = Set, 
								},
							},
						},
						
						alpha = {
							order = 3, type = "group", inline = true, name = "Alpha",
							args = {
								alpha = {
									order = 1, type = "range", min = -1, max = 1, step = 0.01, name = "Initial",
									get = Get, set = Set, 
								},
								alphaChange = {
									order = 2, type = "range", min = -1, max = 1, step = 0.01, name = "Change",
									get = Get, set = Set, 
								},
								alphaSmoothType = {
									order = 3, type = "select", name = "Smooth type", values = SmoothingValues,
									get = Get, set = Set, 
								},
								alphaDuration = {
									order = 11, type = "range", min = 0, max = 10, step = 0.01, name = "Duration",
									get = Get, set = Set, 
								},
								alphaStartDelay = {
									order = 12, type = "range", min = 0, max = 10, step = 0.01, name = "StartDelay",
									get = Get, set = Set, 
								},
								alphaEndDelay = {
									order = 13, type = "range", min = 0, max = 10, step = 0.01, name = "EndDelay",
									get = Get, set = Set, 
								},
							},
						},
						
						translation = {
							order = 4, type = "group", inline = true, name = "Translation",
							args = {
								translationX = {
									order = 1, type = "range", min = -100, max = 100, step = 1, name = "X",
									get = Get, set = Set, 
								},
								translationY = {
									order = 2, type = "range", min = -100, max = 100, step = 1, name = "Y",
									get = Get, set = Set, 
								},
								translationSmoothType = {
									order = 3, type = "select", name = "Smooth type", values = SmoothingValues,
									get = Get, set = Set, 
								},
								translationDuration = {
									order = 11, type = "range", min = 0, max = 10, step = 0.01, name = "Duration",
									get = Get, set = Set, 
								},
								translationStartDelay = {
									order = 12, type = "range", min = 0, max = 10, step = 0.01, name = "StartDelay",
									get = Get, set = Set, 
								},
								translationEndDelay = {
									order = 13, type = "range", min = 0, max = 10, step = 0.01, name = "EndDelay",
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
									order = 1, type = "range", min = 1, max = 500, step = 1, name = "Width",
									get = Get, set = Set,
								},
								height = {
									order = 2, type = "range", min = 1, max = 500, step = 1, name = "Height", 
									get = Get, set = Set,
								},
								wandh = {
									order = 3, type = "range", min = 1, max = 500, step = 1, name = "Width and Height", 
									get = GetLockedLayout, set = SetLockedLayout,
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
							func = DeleteAlert,
						},
					},
				},
			},
		}
	end
	
	if mod.lastAlertCount > #(db) then
		-- nil the rest of the args
		for i = #db + 1, mod.lastAlertCount do
			optionsAlerts.args[tostring(i)] = nil
		end
	end
	mod.lastAlertCount = #db
	
	AceRegistry:NotifyChange("clcInfo")
end