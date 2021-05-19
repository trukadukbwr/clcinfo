-- simple tooltip frame to show debug information
clcInfo.debug = {}
local mod = clcInfo.debug
local db
local df

function mod:OnInitialize()
	db = clcInfo.cdb.debug
	self:Update()
end

local NUM_LINES = 50
local LINE_HEIGHT = 10

local function InitDF()
	df = CreateFrame("Frame", "clcInfoDebugFrame")
	df:SetSize(200, NUM_LINES * (LINE_HEIGHT + 1))
	df:SetPoint("LEFT", UIParent, 300, 30)
	df:SetBackdrop(GameTooltip:GetBackdrop())
	df:SetBackdropColor(GameTooltip:GetBackdropColor())
	df.numLeft, df.numRight = 0, 0
	df.left, df.right = {}, {}
	
	for i = 1, NUM_LINES do
		df.left[i] = df:CreateFontString(nil, nil, "SystemFont_Tiny")
		df.left[i]:SetJustifyH("LEFT")
		df.left[i]:SetPoint("TOPLEFT", 10, -(LINE_HEIGHT + 1) * i)
		df.right[i] = df:CreateFontString(nil, nil, "SystemFont_Tiny")
		df.right[i]:SetJustifyH("RIGHT")
		df.right[i]:SetPoint("TOPRIGHT", -10, -(LINE_HEIGHT + 1) * i)
	end
end

function mod:Update()
	self.enabled = db.enabled
	if self.enabled then
		if df == nil then InitDF() end
		df:SetPoint("TOPLEFT", UIParent, "TOPLEFT", db.x, db.y)
		df:Show()
	else
		if df then df:Hide() end
	end
end

function mod:Clear()
	df.numLeft, df.numRight = 0, 0
	for i = 1, NUM_LINES do
		df.left[i]:SetText("")
		df.right[i]:SetText("")
	end
end

function mod:AddLeft(text)
	df.numLeft = df.numLeft + 1
	df.numRight = df.numRight + 1
	df.left[df.numLeft]:SetText(text)
end

function mod:AddRight(text)
	df.numLeft = df.numLeft + 1
	df.numRight = df.numRight + 1
	df.right[df.numRight]:SetText(text)
end

function mod:AddBoth(t1, t2)
	df.numLeft = df.numLeft + 1
	df.numRight = df.numRight + 1
	df.left[df.numLeft]:SetText(t1)
	df.right[df.numRight]:SetText(t2)
end
