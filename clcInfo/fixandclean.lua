--------------------------------------------------------------------------------
-- TODO, make this GOOD
-- !!! think properly about this shit
--------------------------------------------------------------------------------
--[[
mirrors config table t2 to t1
	* looks for keys in t2 that do not exist in t1 and adds them
	* looks for keys in t1 that do not exist in t2 and deletes them
	* common keys are not changed
--]]
local function HasKey(t, key)
	for k, v in pairs(t) do
		if k == key then return true end
	end
	return false
end
-- IMPORTANT: does not delete not found keys due to the way it's called
local function AdaptConfig(info, t1, t2)
	if t1 == nil or type(t1) ~= "table" then return end
	if t2 == nil or type(t2) ~= "table" then return end
	
	for k, v in pairs(t2) do
		if not HasKey(t1, k) then
			-- go recursive for tables
			if type(v) == "table" then
				t1[k] = {}
				if not AdaptConfig(info .. "." .. tostring(k), t1[k], v) then return end
			else
				t1[k] = v
			end
		else
			if type(v) == "table" then
				if type(t1[k]) ~= "table" then t1[k] = {} end
				if not AdaptConfig(info .. "." .. tostring(k), t1[k], t2[k]) then return end
			end
		end
	end
	
	return true
end

local function AdaptConfigAndClean(info, t1, t2)
	if t1 == nil or type(t1) ~= "table" then return end
	if t2 == nil or type(t2) ~= "table" then return end
	
	-- adapt first
	if not AdaptConfig(info, t1, t2) then return end
	
	-- now clean
	for k, v in pairs(t1) do
		if not HasKey(t2, k) then
			-- not found so delete
			t1[k] = nil
		else
			if type(v) == "table" then
				-- recursive scan
				if not AdaptConfigAndClean(info .. "." .. tostring(k), t1[k], t2[k]) then return end
			end
		end
	end
	
	return true
end


-- to be done
local function CleanConfig()
	for k, v in pairs(t1) do
		if not HasKey(t2, k) then t1[k] = nil end
	end
end

function clcInfo:CleanCDB()
	AdaptConfig("cdb", clcInfo.cdb, clcInfo:GetDefault())
	
	-- skined elements
	local ts = {}
	for k, v in pairs(clcInfo.display) do
		if v.hasSkinOptions then ts[k] = {} end
	end
	
	-- templates
	local x = clcInfo.cdb.templates
	for i = 1, #x do
		if not AdaptConfig("template" .. i, x[i], clcInfo.templates:GetDefault()) then return end
		if not AdaptConfig("template" .. i .. ".spec", x[i].spec, { tree = 1, talent = 0, rank = 1 }) then return end
		if not AdaptConfig("template" .. i .. ".options", x[i].options, { gridSize = 1, showWhen = "always" }) then return end
		
		if not AdaptConfig("template" .. i .. ".skinOptions", x[i].skinOptions, ts) then return end
		for k in pairs(ts) do
			if not AdaptConfigAndClean("template" .. i .. ".skinOptions." .. k, x[i].skinOptions[k], clcInfo.display[k]:GetDefaultSkin()) then return end
		end
		
		-- display elements
		for k in pairs(clcInfo.display) do
			local y = x[i][k]
			for j = 1, #y do
				if not AdaptConfigAndClean("template" .. i .. "." .. k .. j, y[j], clcInfo.display[k].GetDefault()) then return end
			end	
		end
	end
	
	clcInfo.cdb.version = clcInfo.__version
	return true
end

-- NOT FINISHED
function clcInfo:FixSavedData()
	-- check last version
	
	if not clcInfo.cdb.version then clcInfo.cdb.version = 0 end
	if clcInfo.cdb.version == clcInfo.__version then return true end
	
	if clcInfo.cdb.version < 44 then
		print("clcInfo:", "Made some changes to templates to reflect new way talent trees are handled. Please make sure you edit your settings (/clcInfo -> templates)!")
	end
	
	if clcInfo.cdb.version < 59 then
		clcInfo.SPD("clcInfo:\nNew skin settings for bars and multi bars elements. Also your UI scale settings will be applied to clcInfo elements.\nPlease adjust your configuration.\nSorry for the inconvenience.")
	end
	
	return self:CleanCDB()
end

-- expose the 2 functions for other modules
clcInfo.AdaptConfig = AdaptConfig
clcInfo.AdaptConfigAndClean = AdaptConfigAndClean
--------------------------------------------------------------------------------