-------------------------------------------------------------------------------
-- Addon namespace
-------------------------------------------------------------------------------
local Volumizer = CreateFrame("Frame", nil, UIParent)
Volumizer:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event] (self, event, ...) end end)

_G["Volumizer"] = Volumizer

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

local DataObj = LDB:NewDataObject("Volumizer", {
	type	= "launcher",
	label	= "Volumizer",
	icon	= "Interface\\COMMON\\VoiceChat-Speaker-Small",
})

-------------------------------------------------------------------------------
-- Local variables
-------------------------------------------------------------------------------
local info = {
	["ambience"] = {
		SoundOption	= SoundPanelOptions.Sound_AmbienceVolume,
		VolumeCVar	= "Sound_AmbienceVolume",
		Volume		= AudioOptionsSoundPanelAmbienceVolume,
		EnableCVar	= "Sound_EnableAmbience",
		Enable		= AudioOptionsSoundPanelAmbientSounds
	},
	["music"] = {
		SoundOption	= SoundPanelOptions.Sound_MusicVolume,
		VolumeCVar	= "Sound_MusicVolume",
		Volume		= AudioOptionsSoundPanelMusicVolume,
		EnableCVar	= "Sound_EnableMusic",
		Enable		= AudioOptionsSoundPanelMusic
	},
	["master"] = {
		SoundOption	= SoundPanelOptions.Sound_MasterVolume,
		VolumeCVar	= "Sound_MasterVolume",
		Volume		= AudioOptionsSoundPanelMasterVolume,
		EnableCVar	= "Sound_EnableAllSounds",
		Enable		= AudioOptionsSoundPanelEnableSound
	},
	["sfx"]	= {
		SoundOption	= SoundPanelOptions.Sound_SFXVolume,
		VolumeCVar	= "Sound_SFXVolume",
		Volume		= AudioOptionsSoundPanelSoundVolume,
		EnableCVar	= "Sound_EnableSFX",
		Enable		= AudioOptionsSoundPanelSoundEffects
	}
}

local HorizontalSliderBG = {
	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	edgeSize = 8, tile = true, tileSize = 8,
	insets = {left = 3, right = 3, top = 6, bottom = 6}
}

-------------------------------------------------------------------------------
-- Local functions
-------------------------------------------------------------------------------
local function MakeControl(name, relative)
	local container = CreateFrame("Frame", nil, Volumizer)
	container:SetWidth(155)
	container:SetHeight(40)
	container:SetPoint("TOP", relative, 0, (relative == Volumizer) and -10 or -30)

	local check = CreateFrame("CheckButton", nil, container)
	check:SetWidth(15)
	check:SetHeight(15)
	check:SetPoint("LEFT", container, "LEFT")
	check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
	check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
	check:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
	check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
	check:SetChecked(info[name].Enable:GetValue())
	check:SetScript("OnClick", function(checkButton) info[name].Enable:SetValue(check:GetChecked() and 1 or 0) end)

	local slider = CreateFrame("Slider", nil, container)
	slider:SetPoint("LEFT", check, "RIGHT", 0, 0)
	slider:SetPoint("RIGHT")
	slider:SetHeight(15)
	slider:SetHitRectInsets(0, 0, -10, -10)
	slider:SetOrientation("HORIZONTAL")
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:SetBackdrop(HorizontalSliderBG)
	slider:SetMinMaxValues(info[name].SoundOption.minValue, info[name].SoundOption.maxValue)
	slider:SetValue(BlizzardOptionsPanel_GetCVarSafe(info[name].VolumeCVar))
	slider:SetValueStep(info[name].SoundOption.valueStep)
	slider:SetScript("OnValueChanged", function(slider, value) info[name].Volume:SetValue(value) end)

	local text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("BOTTOM", slider, "TOP", 0, 3)
	text:SetText(_G[info[name].SoundOption.text])

	hooksecurefunc("SetCVar",
		       function(cvar, value)
			       if cvar == info[name].VolumeCVar then
				       slider:SetValue(value)
			       elseif cvar == info[name].EnableCVar then
				       check:SetChecked(value)
			       end
		       end)
	return container
end

local function GetAnchor(frame)
	local x,y = frame:GetCenter()

	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local function HidePanel()
	if MouseIsOver(Volumizer) then return end
	Volumizer:Hide()
end

local function ShowPanel(anchor)
	Volumizer:ClearAllPoints()
	Volumizer:SetPoint(GetAnchor(anchor))
	Volumizer:Show()
end

-------------------------------------------------------------------------------
-- Main AddOn functions
-------------------------------------------------------------------------------
function Volumizer:PLAYER_LOGIN()
	self:SetFrameStrata("TOOLTIP")
	self:SetBackdrop(GameTooltip:GetBackdrop())
	self:SetBackdropBorderColor(GameTooltip:GetBackdropBorderColor())
	self:SetBackdropColor(GameTooltip:GetBackdropColor())
	self:SetWidth(175)
	self:SetHeight(140)
	self:EnableMouse(true)
	self:Hide()
	self:SetScript("OnLeave", HidePanel)

	local relative = self
	local control
	for k, v in pairs(info) do
		control = MakeControl(k, relative)
		relative = control
	end

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function DataObj:OnClick(frame, button)	ShowPanel(self) end

function DataObj:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine("Click to display controls.")
	GameTooltip:Show()
end

function DataObj:OnLeave() GameTooltip:Hide() end

if IsLoggedIn() then Volumizer:PLAYER_LOGIN() else Volumizer:RegisterEvent("PLAYER_LOGIN") end