local mod = clcInfo_Options

local function Get(info)
	return clcInfo.cdb.debug[info[#info]]
end

local function Set(info, val)
	clcInfo.cdb.debug[info[#info]] = val
	clcInfo.debug:Update()
end

function mod:LoadDebug()
	self.options.args.debug = {
		order = 1000, type = "group", name = "Debug",
		args = {
			enabled = {
				order = 1, type = "toggle", name = "Enabled", set = Set, get = Get,
			},
			position = {
				order = 2, type = "group", inline = true, name = "Position (from top left)",
				args = {
					x = {
						order = 1, type = "range", name = "X", min = -2000, max = 2000, step = 1, set = Set, get = Get,
					},
					y = {
						order = 2, type = "range", name = "Y", min = -2000, max = 2000, step = 1, set = Set, get = Get,
					},
				},
			},
		},
	}
end

