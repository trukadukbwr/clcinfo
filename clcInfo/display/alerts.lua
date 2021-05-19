-- frame showing where the alert icons will be displayed
local mod = clcInfo:RegisterDisplayModule("alerts")  -- register the module
mod.active = {}				
mod.cache = {}

local prototype = CreateFrame("Frame")  -- alert object
prototype:Hide()

local db

local LSM = clcInfo.LSM

--------------------------------------------------------------------------------
-- alert object
--------------------------------------------------------------------------------
function prototype:StartAnim(texture)
	self.ag:Stop()
	if texture then self.tex:SetTexture(texture) end
	self.ag:Play()
end
function prototype:StopAnim()
	self.ag:Stop()
end

local function AGOnFinished(self) self.parent:Hide() end
local function AGOnStop(self) self.parent:Hide() end
local function AGOnPlay(self)
	self.loop = 0
	self.parent:Show()
end
local function AGOnLoop(self)
	self.loop = self.loop + 1
	if self.loop >= self.loops then self:Stop() end
end

function prototype:Init()
	-- black texture to display when unlocked
	self.bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetAllPoints()
	self.bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	self.bg:SetVertexColor(1, 1, 1, 1)
	self.bg:Hide()
	
	-- label to display when unlocked
	self.label = self:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	self.label:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2, 2)
	self.label:Hide()
	
	-- main texture that's displayed while animating
	self.tex = self:CreateTexture(nil, "ARTWORK")
	self.tex:SetAllPoints()
	self.tex:SetTexture("Interface\\Icons\\ABILITY_SEAL")
	self.tex:SetVertexColor(1, 1, 1, 1)
	self.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	self.tex:Hide()
	
	-- animation stuff
	self.ag = self.tex:CreateAnimationGroup()
	self.ag.parent = self.tex
	self.ag:SetScript("OnFinished", AGOnFinished) 
	self.ag:SetScript("OnStop", AGOnStop)
	self.ag:SetScript("OnPlay", AGOnPlay)
	self.ag:SetScript("OnLoop", AGOnLoop)
	
	-- rotation doesn't really make much sense without a complex system
	self.agTranslation = self.ag:CreateAnimation("Translation")
	self.agTranslation:SetOrder(1)
	
	self.agAlpha = self.ag:CreateAnimation("Alpha")
	self.agAlpha:SetOrder(1)
	
	self.agScale = self.ag:CreateAnimation("Scale")
	self.agScale:SetOrder(1)
	
	-- wierd fix for really wierd bug
	local tempshit = self.ag:CreateAnimation("Scale")
	tempshit:SetOrder(2)
	tempshit:SetDuration(0.05)
	
  -- move and config
  self:EnableMouse(false)
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
	local opt = self.db
	self:ClearAllPoints()
	self:SetWidth(self.db.width)
	self:SetHeight(self.db.height)
	self:SetPoint(self.db.point, "UIParent", self.db.relativePoint, self.db.x, self.db.y)	
	
	-- update animation stuff here
	self.ag:SetLooping(opt.loopType)
	self.ag.loops = opt.loops
	
	local a = self.agTranslation
	a:SetOffset(opt.translationX, opt.translationY)
	a:SetSmoothing(opt.translationSmoothType)
	a:SetDuration(opt.translationDuration)
	a:SetStartDelay(opt.translationStartDelay)
	a:SetEndDelay(opt.translationEndDelay)
	
	a = self.agAlpha
	self.tex:SetAlpha(opt.alpha)
	a:SetFromAlpha(opt.alphaChange)
	a:SetSmoothing(opt.alphaSmoothType)
	a:SetDuration(opt.alphaDuration)
	a:SetStartDelay(opt.alphaStartDelay)
	a:SetEndDelay(opt.alphaEndDelay)
	
	a = self.agScale
	a:SetScale(opt.scaleX, opt.scaleY)
	a:SetSmoothing(opt.scaleSmoothType)
	a:SetDuration(opt.scaleDuration)
	a:SetStartDelay(opt.scaleStartDelay)
	a:SetEndDelay(opt.scaleEndDelay)
	
	-- change the text of the label
	local udl = opt.udLabel
	if udl == "" then udl = "Animation" .. self.index end
	self.label:SetText(udl)
end

-- enables control of the object
function prototype:Unlock()
  self:StopAnim()  -- stop if in an animation
  -- hide main icon and show bg and label
  self.bg:Show()
  self.label:Show()
  self:EnableMouse(true)
  self.unlock = true
end

-- disables
function prototype:Lock()
  self.bg:Hide()
  self.label:Hide()
  self:EnableMouse(false)
  self.unlock = false
end

-- caaaaaaaaaaaaaaaaaaareful
function prototype:Delete()
	-- delete the db entry
	self:StopAnim()
	table.remove(db, self.index)
	-- rebuild frames
	mod:ClearElements()
	mod:InitElements()
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- module
--------------------------------------------------------------------------------

-- creates or gets from cache and initializes
function mod:New(index)
	-- see if we have stuff in cache
	local alert = table.remove(self.cache)
	if alert then
		-- cache hit
		alert.index = index
		alert.db = db[index]
	else
		-- cache miss
		alert = CreateFrame("Frame", nil, clcInfo.mf)
		setmetatable(alert, { __index = prototype })
		alert.index = index
		alert.db = db[index]
		alert:SetFrameLevel(clcInfo.frameLevel + 10)
		alert:Init()
	end
	
	self.active[index] = alert
	alert:Show()
	
	alert:UpdateLayout()
	if self.unlock then
		alert:Unlock()
	end
end


-- send all active alerts to cache
function mod:ClearElements()
	local alert
	for i = 1, getn(self.active) do
		-- remove from active
		alert = table.remove(self.active)
		if alert then
			-- hide
			alert:Hide()
			-- add to cache
			table.insert(self.cache, alert)
		end
	end
end

-- read data from config and create the alerts
function mod:InitElements()
	if not clcInfo.activeTemplate then return end

	db = clcInfo.activeTemplate.alerts
	
	-- create them all over again :D
	for index in ipairs(db) do
		self:New(index)
	end
end

function mod.Play(index, texture, sound)
	if mod.active[index] then
		mod.active[index]:StartAnim(texture)
	end
	if sound then PlaySoundFile(LSM:Fetch("sound", sound), "Master") end
end


-- gets the default options
function mod:GetDefault()
	return {
		udLabel = "", -- user defined label
	
		-- size and position relative to UIParent, defaults to center of screen
		width = 100, height = 100, x = 0, y = 0,
		point = "CENTER", relativePoint = "CENTER",
    
    -- animation settings
    loops = 1, loopType = "NONE", smoothType = "NONE", -- group
    translationX = 0, translationY = 0, translationSmoothType = "NONE", translationDuration = 0, translationStartDelay = 0, translationEndDelay = 0, -- translation
    alpha = 0.5, alphaChange = 0.5, alphaSmoothType = "NONE", alphaDuration = 1, alphaStartDelay = 0, alphaEndDelay = 0, -- alpha
    scaleX = 1, scaleY = 1, scaleSmoothType = "NONE", scaleDuration = 0, scaleStartDelay = 0, scaleEndDelay = 0, -- scale
	}
end


-- adds a alert to the template
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