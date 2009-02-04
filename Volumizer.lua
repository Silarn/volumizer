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
	tooltip	= "Right-click to display controls."
})

-------------------------------------------------------------------------------
-- Local variables
-------------------------------------------------------------------------------
local Data = {
	["ambience"] = {
		SoundOption	= SoundPanelOptions.Sound_AmbienceVolume,
		CVar		= "Sound_AmbienceVolume",
		AudioOption	= AudioOptionsSoundPanelAmbienceVolume
	},
	["music"] = {
		SoundOption	= SoundPanelOptions.Sound_MusicVolume,
		CVar		= "Sound_MusicVolume",
		AudioOption	= AudioOptionsSoundPanelMusicVolume
	},
	["master"] = {
		SoundOption	= SoundPanelOptions.Sound_MasterVolume,
		CVar		= "Sound_MasterVolume",
		AudioOption	= AudioOptionsSoundPanelMasterVolume
	},
	["sfx"]	= {
		SoundOption	= SoundPanelOptions.Sound_SFXVolume,
		CVar		= "Sound_SFXVolume",
		AudioOption	= AudioOptionsSoundPanelSoundVolume
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
local function MakeSlider(name, relative)
	local container = CreateFrame("Frame", nil, Volumizer)
	container:SetWidth(130)
	container:SetHeight(40)

	if (relative == Volumizer) then
		container:SetPoint("TOP", relative, 0, -5)
	else
		container:SetPoint("TOP", relative, 0, -30)
	end

	local slider = CreateFrame("Slider", nil, container)
	slider:SetPoint("LEFT")
	slider:SetPoint("RIGHT")
	slider:SetHeight(15)
	slider:SetHitRectInsets(0, 0, -10, -10)
	slider:SetOrientation("HORIZONTAL")
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:SetBackdrop(HorizontalSliderBG)
 
	Volumizer:SetHeight(Volumizer:GetHeight() + 32)

	local option = Data[name].SoundOption
	slider:SetMinMaxValues(option.minValue, option.maxValue)
	slider:SetValue(BlizzardOptionsPanel_GetCVarSafe(Data[name].CVar))
	slider:SetValueStep(option.valueStep)

	slider:SetScript("OnValueChanged", function(slider, value) Data[name].AudioOption:SetValue(value) end)
	hooksecurefunc("SetCVar", function(cvar, value) if cvar == Data[name].CVar then slider:SetValue(value) end end)

	local text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("BOTTOM", slider, "TOP", 0, 3)
	text:SetText(_G[option.text])

	local low = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -4, 3)
	low:SetText(option.minValue * 100)
 
	local high = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 4, 3)
	high:SetText(option.maxValue * 100)
 
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
	Volumizer:SetScript("OnLeave", nil)
	Volumizer:Hide()
end

local function ShowPanel(anchor)
	Volumizer:ClearAllPoints()
	Volumizer:SetPoint(GetAnchor(anchor))
	Volumizer:SetScript("OnLeave", HidePanel)
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
	self:SetWidth(150)
	self:SetHeight(10)
	self:EnableMouse(true)
	self:Hide()

	local relative = self
	local slider
	for k, v in pairs(Data) do
		slider = MakeSlider(k, relative)
		relative = slider
	end
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function DataObj:OnClick(button) ShowPanel(self) end

if IsLoggedIn() then Volumizer:PLAYER_LOGIN() else Volumizer:RegisterEvent("PLAYER_LOGIN") end