local mod = clcInfo:RegisterDisplayModule("texts")  -- register the module
-- special options
mod.hasSkinOptions = true
mod.onGrid = true

-- masque
local LSM = clcInfo.LSM

local prototype = CreateFrame("Frame")  -- base frame object
prototype:Hide()


mod.active = {}  -- active objects
mod.cache = {}  -- cache of objects, to not make unnecesary frames

local db

-- local bindings
local GetTime = GetTime
local pcall = pcall

---------------------------------------------------------------------------------
-- text prototype
---------------------------------------------------------------------------------
-- called for each of the texts
local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed < self.freq then return end
	-- manual set updates per second for dev testing
	-- if self.elapsed < 0.2 then return end
	self.elapsed = 0
	
	-- expose the object
	clcInfo.env.___e = self
	
	-- text
	-- alpha
	-- svc, r, g, b, a                    			(svc - true if we change vertex info)
	local status, text, alpha, scale, svc, r, g, b, a = pcall(self.exec)
	if not status then
		-- display the first error met into the behavior tab
		-- also announce the user we got an error
		if self.errExec == "" then
			local en = self.db.udLabel
			if en == "" then en = "clcInfo.Text" .. self.index end
			print( en ..":", text)
			self.errExec = text
			clcInfo:UpdateOptions() -- request update of the tab
		end
		-- stop execution directly?
		self:FakeHide()
		return
	end
	
	text = text or ""
	if text == "" then self:FakeHide() return end
	
	if text ~= self.lastText then
		self.lastText = text
		self.text:SetText(text)
	end
	
	alpha = alpha or 1
	if alpha ~= self.lastAlpha then
		self.lastAlpha = alpha
		self.text:SetAlpha(alpha)
	end

	scale = scale or 1
	if scale ~= self.lastScale then
		self.lastScale = scale
		self.textScaleFrame:SetScale(scale)
	end
	
	svc = svc or false
	if svc then
		self.text:SetVertexColor(r, g, b, a)
	else
		if self.lastSVC then	-- not changing vertex but call before was used, so reset to 1
			self.text:SetVertexColor(1, 1, 1, 1)
		end
	end
	self.lastSVC = svc
	
	self:FakeShow()
end

local function OnDragStop(self)
	self:StopMovingOrSizing()

	local g
	if self.db.gridId > 0 then
		g = clcInfo.display.grids.active[self.db.gridId]
	end
	if g then
		-- column
		self.db.gridX = 1 + floor((self:GetLeft() - g:GetLeft()) / (g.db.cellWidth + g.db.spacingX))
		-- row
		self.db.gridY = 1 + floor((self:GetBottom() - g:GetBottom()) / (g.db.cellHeight + g.db.spacingY))
	else
		self.db.gridId = 0
		self.db.x = self:GetLeft()
		self.db.y = self:GetBottom()
		
		local gs = clcInfo.activeTemplate.options.gridSize
		self.db.x = self.db.x - self.db.x % gs
		self.db.y = self.db.y - self.db.y % gs
	end

	self:UpdateLayout()
  clcInfo:UpdateOptions() -- update the data in options also
end

function prototype:Init()
	-- type of the object could be useful
	self.etype = "text"
	-- event dispatcher
	self:SetScript("OnEvent", clcInfo.DisplayElementsEventDispatch)
	
	-- black texture to display when unlocked
	self.bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetAllPoints()
	self.bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	self.bg:SetVertexColor(1, 1, 1, 1)
	self.bg:Hide()
	
	self.textScaleFrame = CreateFrame("Frame", nil, self)
	self.textScaleFrame:SetAllPoints()
	
	self.text = self.textScaleFrame:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med1")
	self.text:SetAllPoints()
	
	self:FakeHide()
	self:Show()

  -- move and config
  self:EnableMouse(false)
	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", function()
      self:StartMoving()
  end)
	self:SetScript("OnDragStop", OnDragStop)
end

-- enables control of the frame
function prototype:Unlock()
  self.bg:Show()
  self:EnableMouse(true)
  self:SetScript("OnUpdate", nil)
  self.text:Show()
  self.lastText = self.label
  self.text:SetText(self.label)
  
  self.unlock = true
end

-- disables control of the frame
function prototype:Lock()
  self.bg:Hide()
  self:EnableMouse(false)
  self.unlock = false
  
  self:UpdateEnabled()
end

function prototype:UpdateEnabled()
	if self.db.enabled then
		clcInfo.UpdateExecEvent(self)	-- reenable event code
		if not self.unlock then
			self:SetScript("OnUpdate", OnUpdate)
		end
	else
		self:UnregisterAllEvents()	-- disable event code basically
		self:SetScript("OnUpdate", nil)
		if not self.unlock then
			self:FakeHide()
		end
	end
end

-- try to position on grid
local function TryGridPositioning(self)
	if self.db.gridId <= 0 then return end
	
	local f = clcInfo.display.grids.active[self.db.gridId]
	if not f then return end
	
	local g = f.db
	
	-- size
	self.db.width = g.cellWidth * self.db.sizeX + g.spacingX * (self.db.sizeX - 1) 
	self.db.height = g.cellHeight * self.db.sizeY + g.spacingY * (self.db.sizeY - 1)
	self:ClearAllPoints()
	self:SetSize(self.db.width, self.db.height)
	
	-- position
	local x = g.cellWidth * (self.db.gridX - 1) + g.spacingX * (self.db.gridX - 1)
	local y = g.cellHeight * (self.db.gridY - 1) + g.spacingY * (self.db.gridY - 1)
	self:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, y)
		
	return true
end

-- adjust the elements according to the settings
function prototype:UpdateLayout()
	-- frame level
	self:SetFrameLevel(clcInfo.frameLevel + 2 + self.db.frameLevel)

	self:SetAlpha(self.db.alpha)

	-- check if it's attached to some grid
	local onGrid = TryGridPositioning(self)
	
	if not onGrid then
		self:ClearAllPoints()
		self:SetSize(self.db.width, self.db.height)
		self:SetPoint(self.db.point, self.db.relativeTo, self.db.relativePoint, self.db.x, self.db.y)
	end
	
	-- TODO
	-- add skin negotiation
	local skin
	if onGrid and self.db.skinSource == "Grid" then
		skin = clcInfo.display.grids.active[self.db.gridId].db.skinOptions.texts
	elseif self.db.skinSource == "Template" then
		skin = clcInfo.activeTemplate.skinOptions.texts
	else
		skin = self.db.skin
	end
	
	-- apply the skin
	local x = self.text
	local fontSize = skin.size / 100 * self.db.height
	local t = {}
	if not skin.aliasing then t[#t+1] = "MONOCHROME" end
	if skin.outline then t[#t+1] = "OUTLINE" end
	if skin.thickoutline then t[#t+1] = "THICKOUTLINE" end
	
	x:SetTextColor(unpack(skin.color))
	x:SetFont(LSM:Fetch("font", skin.family), fontSize, table.concat(t, "|"))	
	x:SetShadowColor(unpack(skin.shadowColor))
	x:SetShadowOffset(skin.shadowOffsetX, skin.shadowOffsetY)
	
	-- justify
	x:SetJustifyH(self.db.justifyH)
	x:SetJustifyV(self.db.justifyV)
	
	-- change the text of the label
	local udl = self.db.udLabel
	if udl == "" then udl = "Text" .. self.index end
	self.label = udl
	
	self:UpdateEnabled()
end

-- update the exec function and perform cleanup
function prototype:UpdateExec()
	clcInfo.UpdateExec(self)
  -- reset alpha
  self.text:SetAlpha(1)
  self.lastAlpha = 1
  
	self:UpdateEnabled()
end

-- show/hide only elements
function prototype:FakeShow() self.text:Show() end
function prototype:FakeHide() self.text:Hide() end

-- caaaaaaaaaaaaaaaaaaareful
function prototype:Delete()
	-- delete the db entry
	-- rebuild frames
	table.remove(db, self.index)
	mod:ClearElements()
	mod:InitElements()
end
---------------------------------------------------------------------------------


---------------------------------------------------------------------------------
-- module functions
---------------------------------------------------------------------------------

-- create or take from cache and initialize
function mod:New(index)
	-- see if we have stuff in cache
	local text = table.remove(self.cache)
	if text then
		-- cache hit
		text.index = index
		text.db = db[index]
		self.active[index] = text
		text:Show()
	else
		-- cache miss
		text = CreateFrame("Frame", nil, clcInfo.mf)	-- parented by the mother frame
		setmetatable(text, { __index = prototype })
		text.index = index
		text.db = db[index]
		self.active[index] = text
		text:SetFrameLevel(clcInfo.frameLevel + 5) -- text a bit higher than the rest
		text:Init()
	end
	
	text:UpdateLayout()
	text:UpdateExec()
	if self.unlock then
  	text:Unlock()
  end
end

-- send all active texts to cache
function mod:ClearElements()
	local text
	for i = 1, getn(self.active) do
		-- remove from active
		text = table.remove(self.active)
		if text then
			-- hide (also disables the updates)
			text:Hide()
			-- run cleanup functions
			if text.ExecCleanup then 
				text.ExecCleanup()
  			text.ExecCleanup = nil
  		end
			-- add to cache
			table.insert(self.cache, text)
		end
	end
end

-- read data from config and create the texts
function mod:InitElements()
	if not clcInfo.activeTemplate then return end

	db = clcInfo.activeTemplate.texts
	
	-- create them all over again :D
	for index in ipairs(db) do
		self:New(index)
	end
end

-- default skin options
function mod:GetDefaultSkin()
	return {
		-- simple
		family = "Arial Narrow",
		size = 100, -- % of height
		color = { 1, 1, 1, 1 },
		
		-- advanced
		advanced = false,
		shadowOffsetX = 0,
		shadowOffsetY = 0,
		shadowColor = {0, 0, 0, 0},
		aliasing = true,
		outline = false,
		thickoutline = false,
	}
end

-- default options
function mod:GetDefault()
	local x = (UIParent:GetWidth() - 100) / 2
	local y = (UIParent:GetHeight() - 30) / 2
	
	return {
		enabled = true,
		udLabel = "", -- user defined label
	
		x = x,
		y = y,
		point = "BOTTOMLEFT",
		relativeTo = "UIParent",
    relativePoint = "BOTTOMLEFT",
		width = 100,
		height = 30,
		exec = "",
		eventExec = "",
		ups = 5,
		gridId = 0,
		gridX = 1,	-- column
		gridY = 1,	-- row
		sizeX = 1, 	-- size in cells
		sizeY = 1, 	-- size in cells
		alpha = 1,
		
		frameLevel = 0,	-- used for display order
		
		justifyH = "CENTER",
		justifyV = "MIDDLE",
		
		skinSource = "Template",	-- template, grid, self
		skin = mod:GetDefaultSkin(),
	}
end
function mod:Add(gridId)
	local data = mod:GetDefault()
	gridId = gridId or 0
	data.gridId = gridId
	if gridId > 0 then data.skinSource = "Grid" end
	
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
---------------------------------------------------------------------------------







