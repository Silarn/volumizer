-------------------------------------------------------------------------------
-- Addon namespace
-------------------------------------------------------------------------------
local Volumizer = LibStub("AceAddon-3.0"):NewAddon("Volumizer")
_G["Volumizer"] = Volumizer

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

local objdata = {
	type	= "launcher",
	label	= "Volumizer",
	icon	= "Interface\\COMMON\\VoiceChat-Speaker-Small",
}

local DataObj = LDB:NewDataObject("Volumizer", objdata)

-------------------------------------------------------------------------------
-- Local variables
-------------------------------------------------------------------------------
local Panel

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
	local container = CreateFrame("Frame", nil, Panel)
	container:SetWidth(130)
	container:SetHeight(40)

	if (relative == Panel) then
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
 
	Panel:SetHeight(Panel:GetHeight() + 32)

	local option = Data[name].SoundOption
	slider:SetMinMaxValues(option.minValue, option.maxValue)
	slider:SetValue(BlizzardOptionsPanel_GetCVarSafe(Data[name].CVar))
	slider:SetValueStep(option.valueStep)

	slider:SetScript("OnValueChanged", function(slider, value) Data[name].AudioOption:SetValue(value) end)
	hooksecurefunc('SetCVar',
		       function(cvar, value)
			       if cvar == Data[name].CVar then
				       slider:SetValue(value)
			       end
		       end)
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
	if MouseIsOver(Panel) then return end
	Panel:SetScript("OnLeave", nil)
	Panel:Hide()
end

local function ShowPanel(anchor)
	Panel:ClearAllPoints()
	Panel:SetPoint(GetAnchor(anchor))
	Panel:SetScript("OnLeave", HidePanel)
	Panel:Show()
end

-------------------------------------------------------------------------------
-- LDB Functions
-------------------------------------------------------------------------------
function DataObj:OnEnter(self)
end

function DataObj:OnLeave()
	HidePanel()
end

function DataObj:OnClick(button)
	ShowPanel(self)
end

-------------------------------------------------------------------------------
-- Main AddOn functions
-------------------------------------------------------------------------------
function Volumizer:OnInitialize()
	Panel = CreateFrame("Frame", nil, UIParent)
	Panel:SetFrameStrata("TOOLTIP")
	Panel:SetBackdrop(GameTooltip:GetBackdrop())
	Panel:SetBackdropBorderColor(GameTooltip:GetBackdropBorderColor())
	Panel:SetBackdropColor(GameTooltip:GetBackdropColor())
	Panel:SetWidth(150)
	Panel:SetHeight(10)
	Panel:EnableMouse(true)
	Panel:Hide()

	local relative = Panel
	local slider
	for k, v in pairs(Data) do
		slider = MakeSlider(k, relative)
		relative = slider
	end
end