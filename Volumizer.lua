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
	icon	= "Interface\\COMMON\\VOICECHAT-SPEAKER"
})

local DropDown = CreateFrame("Frame", "Volumizer_DropDown")
DropDown.displayMode = "MENU"
DropDown.point = "TOPLEFT"
DropDown.relativePoint = "TOPRIGHT"
DropDown.info = {}
DropDown.levelADjust = 0
DropDown.HideMenu = function()
			    if UIDROPDOWNMENU_OPEN_MENU == DropDown then
				    CloseDropDownMenus()
			    end
		    end

-------------------------------------------------------------------------------
-- Localized globals
-------------------------------------------------------------------------------
local g_env = _G
local GameTooltip = g_env.GameTooltip
local tostring = g_env.tostring
local format = g_env.string.format
local CreateFrame = g_env.CreateFrame
local pairs = g_env.pairs

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local NUM_PRESETS = 5

-------------------------------------------------------------------------------
-- Local variables
-------------------------------------------------------------------------------
local default_preset_values = {
	["ambience"]	= {
		["volume"] = 0.6,
		["enable"] = 1
	},
	["music"]	= {
		["volume"] = 0.4,
		["enable"] = 1
	},
	["master"]	= {
		["volume"] = 1.0,
		["enable"] = 1
	},
	["sfx"]		= {
		["volume"] = 1.0,
		["enable"] = 1
	},
	["error"]	= 1,
	["emote"]	= 1,
	["loop"]	= 0,
	["background"]	= 0
}

local default_presets = {
	[1] = {
		["name"] = "Preset 1",
		["values"] = default_preset_values,
	},
	[2] = {
		["name"] = "Preset 2",
		["values"] = default_preset_values,
	},
	[3] = {
		["name"] = "Preset 3",
		["values"] = default_preset_values,
	},
	[4] = {
		["name"] = "Preset 4",
		["values"] = default_preset_values,
	},
	[5] = {
		["name"] = "Preset 5",
		["values"] = default_preset_values,
	},
	[6] = {
		["name"] = DEFAULT,
		["values"] = default_preset_values
	},
}
VolumizerPresets = VolumizerPresets or default_presets

local info = {
	["ambience"] = {
		SoundOption	= SoundPanelOptions.Sound_AmbienceVolume,
		VolumeCVar	= "Sound_AmbienceVolume",
		Volume		= AudioOptionsSoundPanelAmbienceVolume,
		EnableCVar	= "Sound_EnableAmbience",
		Enable		= AudioOptionsSoundPanelAmbientSounds,
		Tooltip		= OPTION_TOOLTIP_ENABLE_AMBIENCE,
	},
	["music"] = {
		SoundOption	= SoundPanelOptions.Sound_MusicVolume,
		VolumeCVar	= "Sound_MusicVolume",
		Volume		= AudioOptionsSoundPanelMusicVolume,
		EnableCVar	= "Sound_EnableMusic",
		Enable		= AudioOptionsSoundPanelMusic,
		Tooltip		= OPTION_TOOLTIP_ENABLE_MUSIC,
	},
	["master"] = {
		SoundOption	= SoundPanelOptions.Sound_MasterVolume,
		VolumeCVar	= "Sound_MasterVolume",
		Volume		= AudioOptionsSoundPanelMasterVolume,
		EnableCVar	= "Sound_EnableAllSound",
		Enable		= AudioOptionsSoundPanelEnableSound,
		Tooltip		= OPTION_TOOLTIP_ENABLE_SOUND,
	},
	["sfx"]	= {
		SoundOption	= SoundPanelOptions.Sound_SFXVolume,
		VolumeCVar	= "Sound_SFXVolume",
		Volume		= AudioOptionsSoundPanelSoundVolume,
		EnableCVar	= "Sound_EnableSFX",
		Enable		= AudioOptionsSoundPanelSoundEffects,
		Tooltip		= OPTION_TOOLTIP_ENABLE_SOUNDFX,
	}
}

local toggle = {
	["error"] = {
		SoundOption	= SoundPanelOptions.Sound_EnableErrorSpeech,
		EnableCVar	= "Sound_EnableErrorSpeech",
		Enable		= AudioOptionsSoundPanelErrorSpeech,
		Tooltip		= OPTION_TOOLTIP_ENABLE_ERROR_SPEECH,
	},
	["emote"] = {
		SoundOption	= SoundPanelOptions.Sound_EnableEmoteSounds,
		EnableCVar	= "Sound_EnableEmoteSounds",
		Enable		= AudioOptionsSoundPanelEmoteSounds,
		Tooltip		= OPTION_TOOLTIP_ENABLE_EMOTE_SOUNDS,
	},
	["loop"] = {
		SoundOption	= SoundPanelOptions.Sound_ZoneMusicNoDelay,
		EnableCVar	= "Sound_ZoneMusicNoDelay",
		Enable		= AudioOptionsSoundPanelLoopMusic,
		Tooltip		= OPTION_TOOLTIP_ENABLE_MUSIC_LOOPING,
	},
	["background"] = {
		SoundOption	= SoundPanelOptions.Sound_EnableSoundWhenGameIsInBG,
		EnableCVar	= "Sound_EnableSoundWhenGameIsInBG",
		Enable		= AudioOptionsSoundPanelSoundInBG,
		Tooltip		= OPTION_TOOLTIP_ENABLE_BGSOUND,
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
--	container:SetPoint("TOP", relative, 0, (relative and dist or -30))
	container:SetPoint("TOP", relative, 0, (relative == Volumizer) and -22 or (relative and dist or -30))

	return container
end

local MakeToggle, MakeControl
do
	local hooksecurefunc = g_env.hooksecurefunc
	local BlizzardOptionsPanel_GetCVarSafe = g_env.BlizzardOptionsPanel_GetCVarSafe

	function MakeToggle(name, relative)
		local ref = toggle[name]
		local container = MakeContainer(relative, -15)
		local check = MakeCheckButton(container)
		check:SetPoint("LEFT", container, "LEFT")
		check:SetChecked(ref.Enable:GetValue())
		check:SetHitRectInsets(-10, -150, 0, 0)
		check:SetScript("OnClick",
				function(checkButton)
					ref.Enable:SetValue(check:GetChecked() and 1 or 0)
				end)
		check.tooltip = ref.Tooltip
		check:SetScript("OnEnter", ShowTooltip)
		check:SetScript("OnLeave", HideTooltip)

		local text = check:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", check, "RIGHT", 0, 3)
		text:SetText(g_env[ref.SoundOption.text])

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
		check:SetScript("OnClick",
				function(checkButton)
					ref.Enable:SetValue(check:GetChecked() and 1 or 0)
				end)
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
		slider.text:SetText(format("%s %d%%", g_env[ref.SoundOption.text], tostring(ref.Volume:GetValue() * 100)))

		slider:SetScript("OnValueChanged",
				 function(slider, value)
					 ref.Volume:SetValue(value)
					 slider.text:SetText(format("%s %d%%", g_env[ref.SoundOption.text], tostring(ref.Volume:GetValue() * 100)))
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
					       if (ref == info["master"]) then
						       if tonumber(value) == 1 then
							       DataObj.icon = "Interface\\COMMON\\VoiceChat-Speaker-Small"
						       else
							       DataObj.icon = "Interface\\COMMON\\VOICECHAT-MUTED"
						       end
					       end
				       end
			       end)
		return container
	end
end

local GetAnchor
do
	local UIParent = g_env.UIParent

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
function Volumizer:PLAYER_ENTERING_WORLD()
	-----------------------------------------------------------------------
	-- Main panel setup
	-----------------------------------------------------------------------
	self:SetFrameStrata("FULLSCREEN_DIALOG")
	self:SetBackdrop({
				 bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				 edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				 tile = true, tileSize = 32, edgeSize = 32,
				 insets = { left = 11, right = 12, top = 12, bottom = 11 }
			 })
	self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
	self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)
	self:SetWidth(180)
	self:SetHeight(245)
	self:EnableMouse(true)
	self:Hide()

	local titlebox = CreateFrame("Frame", nil, Volumizer)
	titlebox:SetBackdrop({
				     bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				     edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				     tile = true, tileSize = 24, edgeSize = 24,
				     insets = { left = 6, right = 7, top = 7, bottom = 6 }
			     })
	titlebox:SetBackdropColor(255, 255, 255, 1)
	titlebox:SetWidth(84)
	titlebox:SetHeight(30)
	titlebox:SetPoint("TOP", self, "TOP", 0, 10)

--	local title = titlebox:CreateTexture(nil, "ARTWORK")
--	title:SetTexture("Interface\DialogFrame\UI-DialogBox-Header")
--	title:SetWidth(80)
--	title:SetHeight(35)
--	title:SetAllPoints(titlebox)

	local text = titlebox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("TOP", titlebox, "TOP", 0, -9)
	text:SetText("Volumizer")

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
	widget:SetScript("OnClick",
		function(self, button, down)
			if DropDown.initialize ~= Volumizer.Menu then
				CloseDropDownMenus()
				DropDown.initialize = Volumizer.Menu
			end
			DropDown.relativeTo = self
			ToggleDropDownMenu(1, nil, DropDown, self:GetName(), 0, 0)
		end)
	widget:SetScript("OnHide", DropDown.HideMenu)

	local text = widget:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetPoint("RIGHT", widget, "LEFT")
	text:SetText("Presets")

	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self.PLAYER_ENTERING_WORLD = nil

	-----------------------------------------------------------------------
	-- Frame interaction with keyboard/mouse
	-----------------------------------------------------------------------
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

	-----------------------------------------------------------------------
	-- LDB Icon initial display
	-----------------------------------------------------------------------
	local enabled = tonumber(AudioOptionsSoundPanelEnableSound:GetValue())

	if enabled == 1 then
		DataObj.icon = "Interface\\COMMON\\VoiceChat-Speaker-Small"
	else
		DataObj.icon = "Interface\\COMMON\\VOICECHAT-MUTED"
	end
	DataObj:UpdateText()
end

local function EnablePreset(self, preset)
	local ref = VolumizerPresets[preset]

	if not ref then error("The preset '"..preset.."' does not exist.") return end

	for k, v in pairs(info) do
		SetCVar(info[k].VolumeCVar, ref.values[k].volume)
		SetCVar(info[k].EnableCVar, ref.values[k].enable)
	end
	for k, v in pairs(toggle) do
		SetCVar(toggle[k].EnableCVar, ref.values[k])
	end
end

function Volumizer.Menu(self, level)
	if not level then return end
	local info = DropDown.info
	wipe(info)

	if level == 1 then
		for k, v in ipairs(VolumizerPresets) do
			if v.name ~= DEFAULT then
				info.text = v.name
				info.func = EnablePreset
				info.arg1 = k
				UIDropDownMenu_AddButton(info, level)
			end
		end
		wipe(info)
		info.disabled = true
		UIDropDownMenu_AddButton(info, level)
		info.disabled = nil

		info.text = DEFAULTS
		info.func = EnablePreset
		info.arg1 = NUM_PRESETS + 1
		info.colorCode = "|cffffff00"
		UIDropDownMenu_AddButton(info, level)
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
	self.text = format("%d%%", tostring(info.master.Volume:GetValue() * 100))
end

Volumizer:RegisterEvent("PLAYER_ENTERING_WORLD")

g_env.SLASH_Volumizer1 = "/volumizer"
g_env.SLASH_Volumizer2 = "/vol"
g_env.SlashCmdList["Volumizer"] = function() Volumizer:Toggle(nil) end