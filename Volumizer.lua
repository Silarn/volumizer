-------------------------------------------------------------------------------
-- Addon namespace
-------------------------------------------------------------------------------
local Volumizer = CreateFrame("Frame", "VolumizerPanel", UIParent)
Volumizer:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event] (self, event, ...) end end)

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

local DataObj = LDB:NewDataObject("Volumizer", {
	type	= "launcher",
	label	= "Volumizer",
	text	= "0%",
	icon	= "Interface\\COMMON\\VoiceChat-Speaker-Small",
})

-------------------------------------------------------------------------------
-- Localized globals
-------------------------------------------------------------------------------
local _G = _G
local GameTooltip = _G.GameTooltip
local tostring = _G.tostring
local format = _G.string.format
local CreateFrame = _G.CreateFrame

-------------------------------------------------------------------------------
-- Local variables
-------------------------------------------------------------------------------
local info = {
	["ambience"] = {
		SoundOption	= SoundPanelOptions.Sound_AmbienceVolume,
		VolumeCVar	= "Sound_AmbienceVolume",
		Volume		= AudioOptionsSoundPanelAmbienceVolume,
		EnableCVar	= "Sound_EnableAmbience",
		Enable		= AudioOptionsSoundPanelAmbientSounds,
		Tooltip		= OPTION_TOOLTIP_ENABLE_AMBIENCE,
		Default		= 0.6
	},
	["music"] = {
		SoundOption	= SoundPanelOptions.Sound_MusicVolume,
		VolumeCVar	= "Sound_MusicVolume",
		Volume		= AudioOptionsSoundPanelMusicVolume,
		EnableCVar	= "Sound_EnableMusic",
		Enable		= AudioOptionsSoundPanelMusic,
		Tooltip		= OPTION_TOOLTIP_ENABLE_MUSIC,
		Default		= 0.4
	},
	["master"] = {
		SoundOption	= SoundPanelOptions.Sound_MasterVolume,
		VolumeCVar	= "Sound_MasterVolume",
		Volume		= AudioOptionsSoundPanelMasterVolume,
		EnableCVar	= "Sound_EnableAllSounds",
		Enable		= AudioOptionsSoundPanelEnableSound,
		Tooltip		= OPTION_TOOLTIP_ENABLE_SOUND,
		Default		= 1.0
	},
	["sfx"]	= {
		SoundOption	= SoundPanelOptions.Sound_SFXVolume,
		VolumeCVar	= "Sound_SFXVolume",
		Volume		= AudioOptionsSoundPanelSoundVolume,
		EnableCVar	= "Sound_EnableSFX",
		Enable		= AudioOptionsSoundPanelSoundEffects,
		Tooltip		= OPTION_TOOLTIP_ENABLE_SOUNDFX,
		Default		= 1.0
	}
}

local toggle = {
	["error"] = {
		SoundOption	= SoundPanelOptions.Sound_EnableErrorSpeech,
		EnableCVar	= "Sound_EnableErrorSpeech",
		Enable		= AudioOptionsSoundPanelErrorSpeech,
		Tooltip		= OPTION_TOOLTIP_ENABLE_ERROR_SPEECH,
		Default		= 1
	},
	["emote"] = {
		SoundOption	= SoundPanelOptions.Sound_EnableEmoteSounds,
		EnableCVar	= "Sound_EnableEmoteSounds",
		Enable		= AudioOptionsSoundPanelEmoteSounds,
		Tooltip		= OPTION_TOOLTIP_ENABLE_EMOTE_SOUNDS,
		Default		= 1
	},
	["loop"] = {
		SoundOption	= SoundPanelOptions.Sound_ZoneMusicNoDelay,
		EnableCVar	= "Sound_ZoneMusicNoDelay",
		Enable		= AudioOptionsSoundPanelLoopMusic,
		Tooltip		= OPTION_TOOLTIP_ENABLE_MUSIC_LOOPING,
		Default		= 0
	},
	["background"] = {
		SoundOption	= SoundPanelOptions.Sound_EnableSoundWhenGameIsInBG,
		EnableCVar	= "Sound_EnableSoundWhenGameIsInBG",
		Enable		= AudioOptionsSoundPanelSoundInBG,
		Tooltip		= OPTION_TOOLTIP_ENABLE_BGSOUND,
		Default		= 0
	},
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
local function HideTooltip() GameTooltip:Hide() end
local function ShowTooltip(self)
	if not self.tooltip then return end
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, true)
end

local function MakeCheckButton(parent)
	local check = CreateFrame("CheckButton", nil, parent)
	check:SetWidth(15)
	check:SetHeight(15)
	check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
	check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
	check:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
	check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

	return check
end

local function MakeContainer(relative, dist)
	local container = CreateFrame("Frame", nil, Volumizer)
	container:SetWidth(155)
	container:SetHeight(40)
	container:SetPoint("TOP", relative, 0, (relative == Volumizer) and -10 or (relative and dist or -30))

	return container
end

local MakeToggle, MakeControl
do
	local hooksecurefunc = _G.hooksecurefunc
	local BlizzardOptionsPanel_GetCVarSafe = _G.BlizzardOptionsPanel_GetCVarSafe

	function MakeToggle(name, relative)
		local ref = toggle[name]
		local container = MakeContainer(relative, -15)
		local check = MakeCheckButton(container)
		check:SetPoint("LEFT", container, "LEFT")
		check:SetChecked(ref.Enable:GetValue())
		check:SetHitRectInsets(-10, -150, 0, 0)
		check:SetScript("OnClick", function(checkButton) ref.Enable:SetValue(check:GetChecked() and 1 or 0) end)
		check.tooltip = ref.Tooltip
		check:SetScript("OnEnter", ShowTooltip)
		check:SetScript("OnLeave", HideTooltip)

		local text = check:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", check, "RIGHT", 0, 3)
		text:SetText(_G[ref.SoundOption.text])

		hooksecurefunc("SetCVar",
			       function(cvar, value)
				       if cvar == ref.EnableCVar then
					       check:SetChecked(value)
				       end
			       end)
		return container
	end

	function MakeControl(name, relative)
		local ref = info[name]
		local container = MakeContainer(relative)
		local check = MakeCheckButton(container)
		check:SetPoint("LEFT", container, "LEFT")
		check:SetChecked(ref.Enable:GetValue())
		check:SetScript("OnClick", function(checkButton) ref.Enable:SetValue(check:GetChecked() and 1 or 0) end)
		check.tooltip = ref.Tooltip
		check:SetScript("OnEnter", ShowTooltip)
		check:SetScript("OnLeave", HideTooltip)

		local slider = CreateFrame("Slider", nil, container)
		slider:SetPoint("LEFT", check, "RIGHT", 0, 0)
		slider:SetPoint("RIGHT")
		slider:SetHeight(15)
		slider:SetHitRectInsets(0, 0, -10, -10)
		slider:SetOrientation("HORIZONTAL")
		slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		slider:SetBackdrop(HorizontalSliderBG)
		slider:SetMinMaxValues(ref.SoundOption.minValue, ref.SoundOption.maxValue)
		slider:SetValue(BlizzardOptionsPanel_GetCVarSafe(ref.VolumeCVar))
		slider:SetValueStep(ref.SoundOption.valueStep)

		slider.text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		slider.text:SetPoint("BOTTOM", slider, "TOP", 0, 3)
		slider.text:SetText(format("%s %d%%", _G[ref.SoundOption.text], tostring(ref.Volume:GetValue() * 100)))

		slider:SetScript("OnValueChanged",
				 function(slider, value)
					 ref.Volume:SetValue(value)
					 slider.text:SetText(format("%s %d%%", _G[ref.SoundOption.text], tostring(ref.Volume:GetValue() * 100)))
					 if (ref == info["master"]) then
						 DataObj:UpdateText()
					 end
				 end)

		hooksecurefunc("SetCVar",
			       function(cvar, value)
				       if cvar == ref.VolumeCVar then
					       slider:SetValue(value)
				       elseif cvar == ref.EnableCVar then
					       check:SetChecked(value)
				       end
			       end)
		return container
	end
end

local GetAnchor
do
	local UIParent = UIParent

	function GetAnchor(frame)
		if not frame then return "CENTER", UIParent, 0, 0 end

		local x,y = frame:GetCenter()

		if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end

		local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
		local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"

		return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
	end
end

-------------------------------------------------------------------------------
-- Main AddOn functions
-------------------------------------------------------------------------------
do
	local pairs = _G.pairs

	function Volumizer:PLAYER_ENTERING_WORLD()
		self:SetFrameStrata("DIALOG")
		self:SetBackdrop(GameTooltip:GetBackdrop())
		self:SetBackdropBorderColor(GameTooltip:GetBackdropBorderColor())
		self:SetBackdropColor(GameTooltip:GetBackdropColor())
		self:SetWidth(175)
		self:SetHeight(225)
		self:EnableMouse(true)
		self:Hide()
		tinsert(UISpecialFrames, "VolumizerPanel")

		local WorldFrame_OnMouseDown = WorldFrame:GetScript("OnMouseDown")
		local WorldFrame_OnMouseUp = WorldFrame:GetScript("OnMouseUp")
		local old_x, old_y, click_time
		WorldFrame:SetScript("OnMouseDown",
				     function(frame, ...)
					     old_x, old_y = GetCursorPosition()
					     click_time = GetTime()
					     if WorldFrame_OnMouseDown then WorldFrame_OnMouseDown(frame, ...) end
				     end)

		WorldFrame:SetScript("OnMouseUp",
				     function(frame, ...)
					     local x, y = GetCursorPosition()
					     if not old_x or not old_y or not x or not y or not click_time then
						     self:Hide()
						     if WorldFrame_OnMouseUp then WorldFrame_OnMouseUp(frame, ...) end
						     return
					     end
					     if (math.abs(x - old_x) + math.abs(y - old_y)) <= 5 and GetTime() - click_time < 1 then
						     self:Hide()
					     end
					     if WorldFrame_OnMouseUp then WorldFrame_OnMouseUp(frame, ...) end
				     end)

		local relative = self
		local widget
		for k, v in pairs(info) do
			widget = MakeControl(k, relative)
			relative = widget
		end
		relative = MakeContainer(relative, -10)	-- Blank space in panel.

		for k, v in pairs(toggle) do
			widget = MakeToggle(k, relative)
			relative = widget
		end
		relative = MakeContainer(relative, -20)	-- Blank space in panel.

		widget = CreateFrame("Button", "Volumizer_PresetButton", relative)
		widget:SetWidth(20)
		widget:SetHeight(20)
		widget:SetPoint("RIGHT")
		widget:SetNormalTexture("Interface\\BUTTONS\\UI-SpellbookIcon-NextPage-Up")
		widget:SetHighlightTexture("Interface\\BUTTONS\\ButtonHilight-Round")
		widget:SetDisabledTexture("Interface\\BUTTONS\\UI-SpellbookIcon-NextPage-Disabled")
		widget:SetPushedTexture("Interface\\BUTTONS\\UI-SpellbookIcon-NextPage-Down")

		local text = widget:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("RIGHT", widget, "LEFT")
		text:SetText("Presets")

		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self.PLAYER_ENTERING_WORLD = nil
		DataObj:UpdateText()
	end
end

function Volumizer:Toggle(anchor)
	if self:IsShown() then
		self:Hide()
	else
		self:ClearAllPoints()
		self:SetPoint(GetAnchor(anchor))
		self:Show()
	end
end

function DataObj:OnClick(frame, button)	Volumizer:Toggle(self) end

function DataObj:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine("Click to show or hide the control panel.")
	GameTooltip:Show()
end

function DataObj:OnLeave() GameTooltip:Hide() end

function DataObj:UpdateText()
	self.text = format("%d%%", tostring(info["master"].Volume:GetValue() * 100))
end

Volumizer:RegisterEvent("PLAYER_ENTERING_WORLD")

_G.SLASH_Volumizer1 = "/volumizer"
_G.SLASH_Volumizer2 = "/vol"
SlashCmdList["Volumizer"] = function() Volumizer:Toggle(nil) end