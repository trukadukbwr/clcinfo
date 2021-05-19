-- grids are frame to which other elements are attached for easier positioning
-- intended to make positioning of the elements like on a piece of science paper

local mod = clcInfo:RegisterDisplayModule("grids")  -- register the module
mod.active = {}				
mod.cache = {}

local prototype = CreateFrame("Frame")  -- grid object
prototype:Hide()

local db

--------------------------------------------------------------------------------
-- grid object
--------------------------------------------------------------------------------
function prototype:Init()
	-- black texture to display when unlocked
	self.bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetAllPoints()
	self.bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	self.bg:SetVertexColor(1, 1, 1, 1)
	
	-- label to display when unlocked
	self.label = self:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	self.label:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2, 2)
	
	self:Hide()
	
  -- move and config
  self:EnableMouse(true)
	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", function()
      self:StartMoving()
  end)
	self:SetScript("OnDragStop", function()
		local _
		self:StopMovingOrSizing()
		self.db.point, _, self.db.relativePoint, self.db.x, self.db.y = self:GetPoint()
    -- update the data in options also
    clcInfo:UpdateOptions()
	end)
end

-- update display according to options
function prototype:UpdateLayout()
	local g = self.db
	
	-- make sure we have at least 1 cell at least 1x1
	if g.cellsX < 1 then g.cellsX = 1 end
	if g.cellsY < 1 then g.cellsY = 1 end
	if g.cellWidth < 1 then g.cellWidth = 1 end
	if g.cellHeight < 1 then g.cellHeight = 1 end
	
	self:ClearAllPoints()
	self:SetWidth(g.cellsX * g.cellWidth + (g.cellsX - 1) * g.spacingX)
	self:SetHeight(g.cellsY * g.cellHeight + (g.cellsY - 1) * g.spacingY)
	self:SetPoint(g.point, "UIParent", g.relativePoint, g.x, g.y)	
	
	-- update the elements attached to it
	self:UpdateChildren()
	
	-- change the text of the label
	local udl = g.udLabel
	if udl == "" then udl = "Grid" .. self.index end
	self.label:SetText(udl)
end

-- enables control of the object
function prototype:Unlock()
  self:Show()
end

-- disables
function prototype:Lock()
  self:Hide()
end

-- caaaaaaaaaaaaaaaaaaareful
function prototype:Delete()
	-- delete the db entry
	table.remove(db, self.index)
	-- rebuild frames
	mod:ClearElements()
	mod:InitElements()
end

-- update the display elements attached to it
function prototype:UpdateChildren()
	for k, v in pairs(clcInfo.display) do
		if v.onGrid then
			local il = clcInfo.display[k].active
			for i = 1, #il do
				if il[i].db.gridId == self.index then
					il[i]:UpdateLayout()
				end
			end
		end
	end
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- module
--------------------------------------------------------------------------------

-- creates or gets from cache and initializes
function mod:New(index)
	-- see if we have stuff in cache
	local grid = table.remove(self.cache)
	if grid then
		-- cache hit
		grid.index = index
		grid.db = db[index]
		self.active[index] = grid
	else
		-- cache miss
		grid = CreateFrame("Frame", nil, clcInfo.mf)
		setmetatable(grid, { __index = prototype })
		grid.index = index
		grid.db = db[index]
		self.active[index] = grid
		grid:SetFrameLevel(clcInfo.frameLevel + 1)
		grid:Init()
	end
	
	grid:UpdateLayout()
	if self.unlock then
		grid:Unlock()
	end
end


-- send all active grids to cache
function mod:ClearElements()
	local grid
	for i = 1, getn(self.active) do
		-- remove from active
		grid = table.remove(self.active)
		if grid then
			-- hide
			grid:Hide()
			-- add to cache
			table.insert(self.cache, grid)
		end
	end
end

-- read data from config and create the grids
function mod:InitElements()
	if not clcInfo.activeTemplate then return end

	db = clcInfo.activeTemplate.grids
	
	-- create them all over again :D
	for index in ipairs(db) do
		self:New(index)
	end
end


-- gets the default options
function mod:GetDefault()
	local t = {
		udLabel = "", -- user defined label
	
		-- cell size
		cellWidth = 30,
		cellHeight = 30,
		-- cell spacing
		spacingX = 2,
		spacingY = 2,
		cellsX = 3, -- columns
		cellsY = 3, -- rows
		-- positioning relative to UIParent, defaults to center of screen
		x = 0,
		y = 0,
		point = "CENTER",
    relativePoint = "CENTER",
    -- skin settings, so that we use grid skin when in a grid
    skinOptions = {}
	}
	
	for k, v in pairs(clcInfo.display) do
		if v.onGrid and v.hasSkinOptions then
			t.skinOptions[k] = clcInfo.display[k]:GetDefaultSkin()
		end
	end
	
	return t
end


-- adds a grid to the template
function mod:Add()
	local data = mod:GetDefault()
		
	-- must be called after init
	table.insert(db, data)
	self:New(getn(db))
end


-- global lock/unlock/update
function mod:LockElements()
	for i = 1, getn(self.active) do
		self.active[i]:Lock()
	end
	self.unlock = false
end
function mod:UnlockElements()
	for i = 1, getn(self.active) do
		self.active[i]:Unlock()
	end
	self.unlock = true
end
function mod:UpdateElementsLayout()
	for i = 1, getn(self.active) do
		self.active[i]:UpdateLayout()
	end
end
--------------------------------------------------------------------------------