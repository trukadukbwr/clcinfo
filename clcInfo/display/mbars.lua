--[[
-- general info
-- mbar -> spawns normal bars
-- onupdate is called on mbar
-- the spawned bars have same skin but can configure colors
--]]

-- base bar
local barPrototype = CreateFrame("Frame")
barPrototype:Hide()

-- base mbar
local prototype = CreateFrame("Frame")
prototype:Hide()

local mod = clcInfo:RegisterDisplayModule("mbars")
-- special options
mod.hasSkinOptions = true
mod.onGrid = true


-- active objects
mod.active = {}
-- cache of objects, to not make unnecesary frames
mod.cache = {}
-- cache of bars that are used by the objects
-- their active list is hold by the object
mod.cacheBars = {}			

local LSM = clcInfo.LSM

local db

-- local bindings
local GetTime = GetTime
local pcall = pcall

local modAlerts = clcInfo.display.alerts

--------------------------------------------------------------------------------
-- bar object
--------------------------------------------------------------------------------

function barPrototype:Init()
	self.bd = {}
	
	self.iconFrame = CreateFrame("Frame", nil, self)
	self.iconBd = {}
	self.icon = self.iconFrame:CreateTexture(nil, "ARTWORK")
	self.icon:SetTexture("Interface\\Icons\\ABILITY_SEAL")
	self.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	
	self.barFrame = CreateFrame("Frame", nil, self)
	self.barBd = {}
	self.bar = CreateFrame("StatusBar", nil, self.barFrame)
	
	self.t1 = self.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	self.t1:SetJustifyH("LEFT")
	self.t2 = self.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	self.t2:SetJustifyH("CENTER")
	self.t3 = self.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	self.t3:SetJustifyH("RIGHT")
	
	self:Hide()
end

-- a simple skin, for faster use
local function SimpleSkin(self, skin)
	local opt = self.parent.db
	
	-- hide backdrops like a bawss
	self:SetBackdrop(nil)
	self.iconFrame:SetBackdrop(nil)
	
	if not skin.barBg then
		self.barFrame:SetBackdrop(nil)
	else
		self.barBd.bgFile = LSM:Fetch("statusbar", skin.barBgTexture)
		self.barBd.insets = { left = 0, right = 0, top = 0, bottom = 0 }
		self.barFrame:SetBackdrop(self.barBd)
		self.barFrame:SetBackdropColor(unpack(skin.barBgColor))
		self.barFrame:SetBackdropBorderColor(0, 0, 0, 0)
	end
	
	-- icon is same size as height and positioned to the left
	self.iconFrame:ClearAllPoints()
	self.iconFrame:SetSize(opt.height, opt.height)
	self.iconFrame:SetPoint("LEFT", self)
	self.icon:ClearAllPoints()
	self.icon:SetAllPoints(self.iconFrame)
	
	-- 1px spacing
	self.barFrame:ClearAllPoints()
	self.barFrame:SetSize(opt.width - 1 - opt.height, opt.height)
	self.barFrame:SetPoint("LEFT", self, "LEFT", opt.height + 1, 0)
	self.bar:ClearAllPoints()
	self.bar:SetAllPoints(self.barFrame)
	
	
	self.bar:SetStatusBarTexture(LSM:Fetch("statusbar", skin.barTexture))
	self.bar:SetStatusBarColor(unpack(skin.barColor))
	
	-- font size should be height - 5 ? good balpark?
	-- stack
	local fh = opt.height * 0.7
	if fh < 6 then fh = 6 end
	local fontFace, _, fontFlags = self.t1:GetFont()
	
	self.t1:SetFont(fontFace, fh, fontFlags)
	self.t1:SetPoint("LEFT", self.barFrame, "LEFT", 2, 0)
	self.t1:SetVertexColor(1, 1, 1, 1)
	
	self.t2:SetFont(fontFace, fh, fontFlags)
	self.t2:SetPoint("CENTER", self.barFrame)
	self.t2:SetVertexColor(1, 1, 1, 1)
	
	self.t3:SetFont(fontFace, fh, fontFlags)
	self.t3:SetPoint("RIGHT", self.barFrame, "RIGHT", -2, 0)
	self.t3:SetVertexColor(1, 1, 1, 1)
end

-- full option skinning
local function AdvancedSkin(self, skin)
	local opt = self.parent.db
	
	------------------------------------------------------------------------------
	-- backdrops
	------------------------------------------------------------------------------
	-- full
	if skin.bd then
		self.bd.bgFile 		= LSM:Fetch("background", skin.bdBg)
		self.bd.edgeFile	= LSM:Fetch("border", skin.bdBorder)
		self.bd.edgeSize	= skin.edgeSize
		self.bd.insets 		= { left = skin.inset, right = skin.inset, top = skin.inset, bottom = skin.inset }
		self:SetBackdrop(self.bd)
		self:SetBackdropColor(unpack(skin.bdColor))
		self:SetBackdropBorderColor(unpack(skin.bdBorderColor))
	else
		self:SetBackdrop(nil)
	end
	
	-- icon
	if skin.iconBd then
		self.iconBd.bgFile = LSM:Fetch("statusbar", skin.iconBdBg)
		self.iconBd.edgeFile = LSM:Fetch("border", skin.iconBdBorder)
		self.iconBd.insets 	= { left = skin.iconInset, right = skin.iconInset, top = skin.iconInset, bottom = skin.iconInset }
		self.iconBd.edgeSize = skin.iconEdgeSize
		self.iconFrame:SetBackdrop(self.iconBd)
		self.iconFrame:SetBackdropColor(unpack(skin.iconBdColor))
		self.iconFrame:SetBackdropBorderColor(unpack(skin.iconBdBorderColor))
	else
		self.iconFrame:SetBackdrop(nil)
	end
	
	-- bar
	self.barBd = {}
	if skin.barBd then
		self.barBd.bgFile = LSM:Fetch("statusbar", skin.barBgTexture)
		self.barBd.edgeFile = LSM:Fetch("border", skin.barBdBorder)
		self.barBd.insets 	= { left = skin.barInset, right = skin.barInset, top = skin.barInset, bottom = skin.barInset }
		self.barBd.edgeSize = skin.barEdgeSize
		self.barFrame:SetBackdrop(self.barBd)
		self.barFrame:SetBackdropColor(unpack(skin.barBgColor))
		self.barFrame:SetBackdropBorderColor(unpack(skin.barBdBorderColor))
	else
		self.barBd.bgFile = LSM:Fetch("statusbar", skin.barBgTexture)
		self.barBd.insets 	= { left = skin.barInset, right = skin.barInset, top = skin.barInset, bottom = skin.barInset }
		self.barFrame:SetBackdrop(self.barBd)
		self.barFrame:SetBackdropColor(unpack(skin.barBgColor))
	end
	------------------------------------------------------------------------------
	
	------------------------------------------------------------------------------
	-- icon positioning: left, right or hidden
	------------------------------------------------------------------------------
	self.iconFrame:ClearAllPoints()
	local iconSize = opt.height - skin.iconTop - skin.iconBottom
	local iconSizeLeft, iconSizeRight -- some values useful for the bar
	if skin.iconAlign == "left" then
		self.iconFrame:Show()
		self.iconFrame:SetPoint("TOPLEFT", self, "TOPLEFT", skin.iconLeft, -skin.iconTop)
		self.iconFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", skin.iconLeft + iconSize, skin.iconBottom)
		iconSizeLeft = skin.iconLeft + iconSize + skin.iconRight
		iconSizeRight = 0
	elseif skin.iconAlign == "right" then
		self.iconFrame:Show()
		self.iconFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", -skin.iconRight - iconSize, -skin.iconTop)
		self.iconFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -skin.iconRight, skin.iconBottom)
		iconSizeLeft = 0
		iconSizeRight = skin.iconLeft + iconSize + skin.iconRight
	else
		self.iconFrame:Hide()
		iconSizeLeft = 0
		iconSizeRight = 0
	end
	self.icon:SetPoint("TOPLEFT", skin.iconPadding, -skin.iconPadding)
	self.icon:SetPoint("BOTTOMRIGHT", -skin.iconPadding, skin.iconPadding)
	------------------------------------------------------------------------------
	
	------------------------------------------------------------------------------
	-- bar positioning
	------------------------------------------------------------------------------
	self.barFrame:ClearAllPoints()
	self.barFrame:SetPoint("TOPLEFT", iconSizeLeft + skin.barLeft, -skin.barTop)
	self.barFrame:SetPoint("BOTTOMRIGHT", -iconSizeRight - skin.barRight, skin.barBottom)
	self.bar:ClearAllPoints()
	self.bar:SetPoint("TOPLEFT", self.barFrame, "TOPLEFT", skin.barPadding, -skin.barPadding)
	self.bar:SetPoint("BOTTOMRIGHT", self.barFrame, "BOTTOMRIGHT", -skin.barPadding, skin.barPadding)
	------------------------------------------------------------------------------
	
	-- text positioning
	------------------------------------------------------------------------------
	self.t1:ClearAllPoints()
	self.t1:SetPoint("LEFT", self.barFrame, "LEFT", skin.t1Left, skin.t1Center)
	self.t1:SetWidth(self.barFrame:GetWidth() * skin.t1HSize / 100)
	
	self.t2:ClearAllPoints()
	self.t2:SetPoint("CENTER", self.barFrame, "CENTER", 0, skin.t2Center)
	self.t2:SetWidth(self.barFrame:GetWidth() * skin.t2HSize / 100)
	
	self.t3:ClearAllPoints()
	self.t3:SetPoint("RIGHT", self.barFrame, "RIGHT", -skin.t3Right, skin.t3Center)
	self.t3:SetWidth(self.barFrame:GetWidth() * skin.t3HSize / 100)
	------------------------------------------------------------------------------
	
	
	-- bar texture and color
	self.bar:SetStatusBarTexture(LSM:Fetch("statusbar", skin.barTexture))
	self.bar:SetStatusBarColor(unpack(skin.barColor))
	
	-- text family/color/flags
	local t
	
	local fh = opt.height * skin.t1Size / 100
	if fh < 5 then fh = 5 end
	t = {}
	if not skin.t1Aliasing then t[#t+1] = "MONOCHROME" end
	if skin.t1Outline then t[#t+1] = "OUTLINE" end
	if skin.t1ThickOutline then t[#t+1] = "THICKOUTLINE" end
	self.t1:SetFont(LSM:Fetch("font", skin.t1Font), fh, table.concat(t, "|"))
	self.t1:SetVertexColor(unpack(skin.t1Color))
	
	fh = opt.height * skin.t2Size / 100
	if fh < 5 then fh = 5 end
	t = {}
	if not skin.t2Aliasing then t[#t+1] = "MONOCHROME" end
	if skin.t2Outline then t[#t+1] = "OUTLINE" end
	if skin.t2ThickOutline then t[#t+1] = "THICKOUTLINE" end
	self.t2:SetFont(LSM:Fetch("font", skin.t2Font), fh, table.concat(t, "|"))
	self.t2:SetVertexColor(unpack(skin.t2Color))
	
	fh = opt.height * skin.t3Size / 100
	if fh < 5 then fh = 5 end
	t = {}
	if not skin.t3Aliasing then t[#t+1] = "MONOCHROME" end
	if skin.t3Outline then t[#t+1] = "OUTLINE" end
	if skin.t3ThickOutline then t[#t+1] = "THICKOUTLINE" end
	self.t3:SetFont(LSM:Fetch("font", skin.t3Font), fh, table.concat(t, "|"))
	self.t3:SetVertexColor(unpack(skin.t3Color))
end

function barPrototype:UpdateLayout(i, skin)
	local opt = self.parent.db
	self:SetWidth(opt.width)
	self:SetHeight(opt.height)	
	
	self:ClearAllPoints()
	if opt.growth == "left" then
		self:SetPoint("BOTTOMRIGHT", self.parent, "BOTTOMRIGHT", (1 - i) * (opt.width + opt.spacing), 0)
	elseif opt.growth == "right" then
		self:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", (i - 1) * (opt.width + opt.spacing), 0)
	elseif opt.growth == "up" then
		self:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", 0, (i - 1) * (opt.height + opt.spacing))
	else
		self:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, (1 - i) * (opt.height + opt.spacing))
	end
	
	if skin.advancedSkin then
		AdvancedSkin(self, skin)
	else
		SimpleSkin(self, skin)
	end
	
	-- reset alpha
	self:SetAlpha(1)
	
	-- fix text width/height
	self.t1:SetWidth(self.bar:GetWidth() * 0.8)
	self.t1:SetHeight(self.bar:GetHeight())
	self.t2:SetWidth(self.bar:GetWidth())
	self.t2:SetHeight(self.bar:GetHeight())
	self.t3:SetWidth(self.bar:GetWidth() * 0.3)
	self.t2:SetHeight(self.bar:GetHeight())
	
	-- own colors to make it easier to configure
	if opt.ownColors then
		self.bar:SetStatusBarColor(unpack(opt.skin.barColor))
		self.barFrame:SetBackdropColor(unpack(opt.skin.barBgColor))
	end
	
	self.r, self.g, self.b, self.a = self.bar:GetStatusBarColor()
end

--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- mbar object
--------------------------------------------------------------------------------

-- this one is called for alerts
function prototype:___HideBar(id)
	-- expiration tests for when the aura is forcefully removed
	if self.hasAlerts == 1 and self.alerts[id].expiration then
		local a = self.alerts[id].expiration
		if a.mode == "normal" then
			if a.last > a.timeLeft then
				a.last = 0
				modAlerts.Play(a.alertIndex, a.texture, a.sound)
			end
		elseif a.mode == "reversed" then
			if a.last < a.timeLeft then
				a.last = 10000
				modAlerts.Play(a.alertIndex, a.texture, a.sound)
			end
		end
	end
end

function prototype:___AddBar(id, alpha, r, g, b, a, texture, minValue, maxValue, value, mode, t1, t2, t3)
	self.___dc = self.___dc + 1
	
	local bar
	if self.___dc > #self.___c then
		bar = self:New()
	else
		bar = self.___c[self.___dc]
	end

	bar:SetAlpha(alpha or 1)
	if r then bar.bar:SetStatusBarColor(r, g, b, a)
	else bar.bar:SetStatusBarColor(bar.r, bar.g, bar.b, bar.a) end
	
	bar.icon:SetTexture(texture)
	bar.bar:SetMinMaxValues(minValue, maxValue)
	bar.bar:SetValue(value)
	bar.t1:SetText(t1)
	bar.t2:SetText(t2)
	bar.t3:SetText(t3)
	bar:Show()
	
	-- save important stuff for quick updates
	bar.value = value
	bar.mode = mode
	
	-- alert handling
	if id and self.hasAlerts == 1 then
		if self.alerts[id] then
			-- expiration alert
			if self.alerts[id].expiration then
				local a = self.alerts[id].expiration
				-- mode selection
				if mode == "normal" then
					if value <= a.timeLeft and a.timeLeft < a.last then
						modAlerts.Play(a.alertIndex, texture, a.sound)
					end
				elseif mode == "reversed" then
					if value >= a.timeLeft and a.timeLeft > a.last then
						modAlerts.Play(a.alertIndex, texture, a.sound)
					end
				end
				a.last = value
				a.mode = mode
				a.texture = texture
			end
			-- start alert
			if self.alerts[id].start then
				local a = self.alerts[id].start
				-- mode selection
				if mode == "normal" then
					if value > a.last then
						modAlerts.Play(a.alertIndex, texture, a.sound)
					end
				elseif mode == "reversed" then
					if value < a.lastReversed then
						modAlerts.Play(a.alertIndex, texture, a.sound)
					end
				end
				a.last = value
			end
		end
	end
end


-- on update is used on the mbar object
local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed >= self.freq then
		self.elapsed = 0
		
		-- expose the object
		clcInfo.env.___e = self
		
		-- reset the counter for the data tables
		self.___dc = 0
		
		-- update data
		local status, err = pcall(self.exec)
		if not status then
			-- display the first error met into the behavior tab
			-- also announce the user we got an error
			if self.errExec == "" then
				local en = self.db.udLabel
				if en == "" then en = "clcInfo.MBar" .. self.index end
				print( en ..":", err)
				self.errExec = err
				clcInfo:UpdateOptions() -- request update of the tab
			end
		end
		
		
		if self.___dc < #self.___c then
			-- hide the extra bars
			for i = self.___dc + 1, #self.___c do
				self.___c[i]:Hide()
			end
		end
		
	else
		-- quick update display 
		local bar
		for i = 1, self.___dc do
			bar = self.___c[i]
			if bar.mode == "normal" then
					bar.value = bar.value - elapsed
			elseif bar.mode == "reversed" then
				bar.value = bar.value + elapsed
			end
			
			bar.bar:SetValue(bar.value)	
		end
	end
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
	self.etype = "mbar"
	-- event dispatcher
	self:SetScript("OnEvent", clcInfo.DisplayElementsEventDispatch)
	
	-- bg texture and label
	self.bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetAllPoints()
	self.bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	self.bg:SetVertexColor(1, 1, 1, 1)
	self.bg:Hide()
	self.label = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	self.label:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 1)
	local fontFace, _, fontFlags = self.label:GetFont()
	self.label:SetFont(fontFace, 6, fontFlags)
	self.label:Hide()

	self.elapsed = 0
	self:Show()
	
	self.___dc = 0			-- data count
	self.___c = {}			-- children

	-- move and config
  self:EnableMouse(false)
	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", function()
      self:StartMoving()
  end)
	self:SetScript("OnDragStop", OnDragStop)
end

-- shows and enables control of the frame
function prototype:Unlock()
  self:EnableMouse(true)
  self.bg:Show()
  self.label:Show()
  self:SetScript("OnUpdate", nil)
  self:HideBars()
  
  -- show first bar
  -- alpha, r, g, b, a, texture, minValue, maxValue, value, mode, t1, t2, t3
  self.___dc = 0
 	self:___AddBar(nil, nil, nil, nil, nil, nil, "Interface\\Icons\\ABILITY_SEAL", 1, 100, 50, nil, "left", "center", "right")
 	
 	self.unlock = true
end

-- disables control of the frame
function prototype:Lock()
  self:EnableMouse(false)
  self.bg:Hide()
  self.label:Hide()
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
		self:UnregisterAllEvents()
		if self.unlock then
			self:Unlock()
		else
			self:SetScript("OnUpdate", nil)
			self:ReleaseBars()
		end
	end
end

-- display the elements according to the settings
local function TryGridPositioning(self)
	if self.db.gridId <= 0 then return end
	
	local f = clcInfo.display.grids.active[self.db.gridId]
	if not f then return end
	
	local g = f.db
	
	-- size
	self.db.width = g.cellWidth * self.db.sizeX + g.spacingX * (self.db.sizeX - 1) 
	self.db.height = g.cellHeight * self.db.sizeY + g.spacingY * (self.db.sizeY - 1)
	self:ClearAllPoints()
	self:SetWidth(self.db.width)
	self:SetHeight(self.db.height)
	
	-- position
	local x = g.cellWidth * (self.db.gridX - 1) + g.spacingX * (self.db.gridX - 1)
	local y = g.cellHeight * (self.db.gridY - 1) + g.spacingY * (self.db.gridY - 1)
	self:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, y)
		
	return true
end


function prototype:UpdateLayout()
	-- frame level
	self:SetFrameLevel(clcInfo.frameLevel + 2 + self.db.frameLevel)

	self:SetAlpha(self.db.alpha)

	-- check if it's attached to some grid
	local onGrid = TryGridPositioning(self)
	
	if not onGrid then
		self:ClearAllPoints()
		self:SetWidth(self.db.width)
		self:SetHeight(self.db.height)
		self:SetPoint(self.db.point, self.db.relativeTo, self.db.relativePoint, self.db.x, self.db.y)
	end
	
	-- at least 1 px bar
	if self.db.width <= (self.db.height + 1) then self.db.width = self.db.height + 2 end
	
	local skin
	if onGrid and self.db.skinSource == "Grid" then
		skin = clcInfo.display.grids.active[self.db.gridId].db.skinOptions.mbars
	elseif self.db.skinSource == "Template" then
		skin = clcInfo.activeTemplate.skinOptions.mbars
	else
		skin = self.db.skin
	end
	
	self.skin = skin
	
	-- change the text of the label
	local udl = self.db.udLabel
	if udl == "" then udl = "MBar" .. self.index end
	self.label:SetText(udl)
	
	self:UpdateEnabled()
	
	-- update children
	self:UpdateBarsLayout()	
end

function prototype:UpdateExec()
	clcInfo.UpdateExec(self)
  clcInfo.UpdateExecAlert(self)
  
  -- release the bars
  self:ReleaseBars()
  
  self:UpdateEnabled()
end

-- caaaaaaaaaaaaaaaaaaareful
function prototype:Delete()
	-- delete the db entry
	-- rebuild frames
	table.remove(db, self.index)
	mod:ClearElements()
	mod:InitElements()
end

function prototype:New()
	-- see if we have stuff in cache
	local bar = table.remove(mod.cacheBars)
	if not bar then
		-- cache miss
		bar = CreateFrame("Frame", nil, clcInfo.mf)	-- parented by the mother frame
		setmetatable(bar, { __index = barPrototype })
		bar:SetFrameLevel(clcInfo.frameLevel + 2)
		bar:Init()
	end
	
	bar.parent = self
	bar:SetParent(self)
	
	self.___c[#self.___c + 1] = bar
	
	bar:UpdateLayout(#self.___c, self.skin)
	
	return bar
end

function prototype:ReleaseBars()
	local bar
	local b = #self.___c
	for i = 1, b do
		bar = table.remove(self.___c)
		bar:Hide()
		table.insert(mod.cacheBars, bar)
	end
end
function prototype:UpdateBarsLayout()
	for i = 1, #self.___c do
		self.___c[i]:UpdateLayout(i, self.skin)
	end
end
-- set children bars state
function prototype:HideBars()
	for i = 1, #self.___c do
		self.___c[i]:Hide()
	end
end


---------------------------------------------------------------------------------
-- module functions
---------------------------------------------------------------------------------
function mod:New(index)
	-- see if we have stuff in cache
	local mbar = table.remove(self.cache)
	if mbar then
		-- cache hit
		mbar.index = index
		mbar.db = db[index]
		self.active[index] = mbar
		mbar:Show()
	else
		-- cache miss
		mbar = CreateFrame("Frame", nil, clcInfo.mf)	-- parented by the mother frame
		setmetatable(mbar, { __index = prototype })
		mbar.index = index
		mbar.db = db[index]
		self.active[index] = mbar
		mbar:SetFrameLevel(clcInfo.frameLevel + 2)
		mbar:Init()
	end
	
	mbar:UpdateLayout()
	mbar:UpdateExec()
	
	if self.unlock then
  	mbar:Unlock()
  end
end

-- send all active bars to cache
function mod:ClearElements()
	local mbar, n
	n = #(self.active)
	for i = 1, n do
		-- remove from active
		mbar = table.remove(self.active)
		if mbar then
			-- run cleanup functions
			if mbar.ExecCleanup then 
				mbar.ExecCleanup()
  			mbar.ExecCleanup = nil
  		end
			-- send children to cache too
			mbar:ReleaseBars()
			-- hide (also disables the updates)
			mbar:Hide()
			-- add to cache
			table.insert(self.cache, mbar)
		end
	end
end

-- read data from config and create the bars
-- IMPORTANT, always make sure you call clear first
function mod:InitElements()
	if not clcInfo.activeTemplate then return end

	db = clcInfo.activeTemplate.mbars
	
	-- create them all over again :D
	for index in ipairs(db) do
		self:New(index)
	end
end


-- the bullcrap of skin related settings
-- same as for bars
mod.GetDefaultSkin = clcInfo.display.bars.GetDefaultSkin

-- mbar stuff
function mod:GetDefault()
	local x = (UIParent:GetWidth() - 300) / 2
	local y = (UIParent:GetHeight() - 30) / 2
	
	-- mbar default settings
	return {
		enabled = true,
		udLabel = "", -- user defined label
	
		growth = "up", -- up or down
		spacing = 1, -- space between bars
	
		x = x,
		y = y,
		point = "BOTTOMLEFT",
		relativeTo = "UIParent",
    relativePoint = "BOTTOMLEFT",
		width = 300,
		height = 30,
		exec = "",
		alertExec = "",
		eventExec = "",
		ups = 5,
		gridId = 0,
		gridX = 1,	-- column
		gridY = 1,	-- row
		sizeX = 1, 	-- size in cells
		sizeY = 1, 	-- size in cells
		alpha = 1,
		
		frameLevel = 0,	-- used for display order
		
		skinSource = "Template",	-- template, grid, self
		ownColors	= false,
		skin = mod.GetDefaultSkin(),
	}
end
function mod:Add(gridId)
	local data = mod.GetDefault()
	gridId = gridId or 0
	data.gridId = gridId
	if gridId > 0 then data.skinSource = "Grid" end
	
	-- must be called after init
	table.insert(db, data)
	self:New(getn(db))
end


-- TODO!
-- make sure cached bars are locked
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