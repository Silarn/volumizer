-------------------------------------------------------------------------------
-- Localized globals
-------------------------------------------------------------------------------
local _G = getfenv(0)

local string = _G.string

local tonumber, tostring = _G.tonumber, _G.tostring

local pairs, ipairs = _G.pairs, _G.ipairs
local wipe = _G.wipe

local CreateFrame = _G.CreateFrame
local GameTooltip = _G.GameTooltip
local UIParent = _G.UIParent
local def_col, def_bg_col = _G.TOOLTIP_DEFAULT_COLOR, _G.TOOLTIP_DEFAULT_BACKGROUND_COLOR

-------------------------------------------------------------------------------
-- Addon namespace
-------------------------------------------------------------------------------
local Volumizer = CreateFrame("Frame", "VolumizerPanel", UIParent)

Volumizer:SetScript("OnEvent",
		    function(self, event, ...)
			    if self[event] then
				    return self[event] (self, event, ...)
			    end
		    end)
Volumizer:RegisterEvent("ADDON_LOADED")

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

local DataObj

local DropDown = CreateFrame("Frame", "Volumizer_DropDown")
DropDown.displayMode = "MENU"
DropDown.point = "TOPLEFT"
DropDown.relativePoint = "RIGHT"
DropDown.yOffset = 8
DropDown.info = {}
DropDown.levelAdjust = 0

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local NUM_PRESETS = 5

local DEFAULT_PRESET_VALUES = {
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
	["pet"]		= 1,
	["loop"]	= 0,
	["background"]	= 0,
	["listener"]	= 1,
}

local INITIAL_PRESETS = {
	[1] = {
		["name"] = "Preset 1",
		["values"] = DEFAULT_PRESET_VALUES,
	},
	[2] = {
		["name"] = "Preset 2",
		["values"] = DEFAULT_PRESET_VALUES,
	},
	[3] = {
		["name"] = "Preset 3",
		["values"] = DEFAULT_PRESET_VALUES,
	},
	[4] = {
		["name"] = "Preset 4",
		["values"] = DEFAULT_PRESET_VALUES,
	},
	[5] = {
		["name"] = "Preset 5",
		["values"] = DEFAULT_PRESET_VALUES,
	},
}

local DEFAULT_PRESET = {
	["values"] = DEFAULT_PRESET_VALUES
}

local VOLUMES = {
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

local TOGGLES = {
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
	["pet"] = {
		SoundOption	= SoundPanelOptions.Sound_EnablePetSounds,
		EnableCVar	= "Sound_EnablePetSounds",
		Enable		= AudioOptionsSoundPanelPetSounds,
		Tooltip		= OPTION_TOOLTIP_ENABLE_PET_SOUNDS,
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
	["listener"] = {
		SoundOption	= SoundPanelOptions.Sound_ListenerAtCharacter,
		EnableCVar	= "Sound_ListenerAtCharacter",
		Enable		= nil,
		Tooltip		= OPTION_TOOLTIP_ENABLE_SOUND_AT_CHARACTER,
	},
}

local HorizontalSliderBG = {
	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	edgeSize = 8, tile = true, tileSize = 8,
	insets = {left = 3, right = 3, top = 6, bottom = 6}
}

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------
VolumizerPresets = VolumizerPresets or INITIAL_PRESETS

-------------------------------------------------------------------------------
-- Local functions
-------------------------------------------------------------------------------
local function HideTooltip() GameTooltip:Hide() end
local function ShowTooltip(self)
	if not self.tooltip then
		return
	end
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
	container:SetPoint("TOP", relative, 0, (relative == Volumizer) and -22 or (relative and dist or -30))

	return container
end

local MakeToggle, MakeControl
do
	local hooksecurefunc = _G.hooksecurefunc
	local BlizzardOptionsPanel_GetCVarSafe = _G.BlizzardOptionsPanel_GetCVarSafe

	function MakeToggle(name, relative)
		local ref = TOGGLES[name]
		local container = MakeContainer(relative, -15)
		local check = MakeCheckButton(container)
		check:SetPoint("LEFT", container, "LEFT")

		if ref.Enable then
			check:SetChecked(ref.Enable:GetValue())
		else
			check:SetChecked(tonumber(GetCVar(ref.EnableCVar)))
		end
		check:SetHitRectInsets(-10, -150, 0, 0)
		check:SetScript("OnClick",
				function(checkButton)
					if ref.Enable then
						ref.Enable:SetValue(check:GetChecked() and 1 or 0)
					else
						SetCVar(ref.EnableCVar, check:GetChecked() and 1 or 0)
					end
				end)
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
		local ref = VOLUMES[name]
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
		slider:EnableMouseWheel(true)

		slider.text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		slider.text:SetPoint("BOTTOM", slider, "TOP", 0, 3)
		slider.text:SetText(string.format("%s %d%%", _G[ref.SoundOption.text], tostring(ref.Volume:GetValue() * 100)))

		slider:SetScript("OnValueChanged",
				 function(slider, value)
					 ref.Volume:SetValue(value)
					 slider.text:SetText(string.format("%s %d%%", _G[ref.SoundOption.text], tostring(ref.Volume:GetValue() * 100)))

					 if ref == VOLUMES["master"] then
						 DataObj:UpdateText()
					 end
				 end)

		slider:SetScript("OnMouseWheel", function(self, delta)
							 local currentValue = self:GetValue()
							 local minValue, maxValue = self:GetMinMaxValues()

							 if delta > 0 and currentValue < maxValue then
								 self:SetValue(math.min(maxValue, currentValue + 0.10))
							 elseif delta < 0 then
								 if currentValue == maxValue then
									 self:SetValue(math.max(minValue, currentValue - 0.20))
								 elseif currentValue > minValue then
									 self:SetValue(math.max(minValue, currentValue - 0.10))
								 end
							 end
						 end)

		hooksecurefunc("SetCVar",
			       function(cvar, value)
				       if cvar == ref.VolumeCVar then
					       slider:SetValue(value)
				       elseif cvar == ref.EnableCVar then
					       check:SetChecked(value)

					       if ref == VOLUMES["master"] then
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

-------------------------------------------------------------------------------
-- Panel Backdrops
-------------------------------------------------------------------------------
local TooltipBackdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 5, right = 5, top = 5, bottom = 5, }
}

local PlainBackdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 5, right = 5, top = 5, bottom = 5, }
}

-------------------------------------------------------------------------------
-- Main AddOn functions
-------------------------------------------------------------------------------
function Volumizer:ChangeBackdrop(backdrop)
	self:SetBackdrop(backdrop)
	self:SetBackdropBorderColor(def_col.r, def_col.g, def_col.b)
	self:SetBackdropColor(def_bg_col.r, def_bg_col.g, def_bg_col.b)
end

local function UsePreset(self, preset)
	local ref = (preset < 1) and DEFAULT_PRESET or VolumizerPresets[preset]

	if not ref then
		error("The preset '"..preset.."' does not exist.")
		return
	end

	for k, v in pairs(VOLUMES) do
		SetCVar(VOLUMES[k].VolumeCVar, ref.values[k].volume)
		SetCVar(VOLUMES[k].EnableCVar, ref.values[k].enable)
	end

	for k, v in pairs(TOGGLES) do
		SetCVar(TOGGLES[k].EnableCVar, ref.values[k])
	end

	-- Remove the check-mark from the menu entry.
	_G[self:GetName().."Check"]:Hide()
end

local function SavePreset(self, preset)
	local ref = VolumizerPresets[preset]

	if not ref then
		error("The preset '"..preset.."' does not exist.")
		return
	end

	for k, v in pairs(VOLUMES) do
		ref.values[k].volume = GetCVar(VOLUMES[k].VolumeCVar)
		ref.values[k].enable = GetCVar(VOLUMES[k].EnableCVar)
	end

	for k, v in pairs(TOGGLES) do
		ref.values[k] = GetCVar(TOGGLES[k].EnableCVar)
	end
	VolumizerPresets[preset] = ref
end

function DropDown:HideMenu()
	if UIDROPDOWNMENU_OPEN_MENU == self then
		CloseDropDownMenus()
	end
end

local function RenamePreset_Popup(self, preset)
	Volumizer.renaming = preset
	StaticPopup_Show("Volumizer_RenamePreset")
	CloseDropDownMenus(1)
end

function Volumizer.Menu(self, level)
	if not level then
		return
	end

	local info = DropDown.info
	wipe(info)

	if level == 1 then
		for k, v in ipairs(VolumizerPresets) do
			if k > NUM_PRESETS then VolumizerPresets[k] = nil else
				info.text = v.name
				info.value = k
				info.hasArrow = true
				info.notCheckable = 1
				info.keepShownOnClick = 1

				info.arg1 = k
				info.func = UsePreset

				UIDropDownMenu_AddButton(info, level)
			end
		end
		wipe(info)		-- Blank space in menu.
		info.disabled = true
		UIDropDownMenu_AddButton(info, level)
		info.disabled = nil

		info.text = DEFAULTS
		info.func = UsePreset
		info.arg1 = 0
		info.colorCode = "|cffffff00"
		UIDropDownMenu_AddButton(info, level)
	elseif level == 2 then
			wipe(info)
			info.arg1 = UIDROPDOWNMENU_MENU_VALUE

			info.text = SAVE
			info.func = SavePreset
			UIDropDownMenu_AddButton(info, level)

			info.text = NAME
			info.func = RenamePreset_Popup
			UIDropDownMenu_AddButton(info, level)
	end
end

do
	local function GetAnchor(frame)
		if not frame then
			return "CENTER", UIParent, 0, 0
		end

		local x,y = frame:GetCenter()

		if not x or not y then
			return "TOPLEFT", "BOTTOMLEFT"
		end

		local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
		local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"

		return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
	end

	function Volumizer:Toggle(anchor, use_border)
		if self:IsShown() then
			self:Hide()
			self.border:Hide()
		else
			self:ClearAllPoints()
			self:SetPoint(GetAnchor(anchor))
			self:Show()

			if use_border then
				self:ChangeBackdrop(PlainBackdrop)
				self.border:Show()
			else
				self:ChangeBackdrop(TooltipBackdrop)
			end
		end
	end
end	-- do

-------------------------------------------------------------------------------
-- Event functions
-------------------------------------------------------------------------------
function Volumizer:ADDON_LOADED(event, addon)
	if addon ~= "Volumizer" then
		return
	end

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then
		self:PLAYER_ENTERING_WORLD()
	else
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
	end
end

function Volumizer:PLAYER_ENTERING_WORLD()
	-----------------------------------------------------------------------
	-- Main panel setup
	-----------------------------------------------------------------------
	self:SetFrameStrata("MEDIUM")
	self:ChangeBackdrop(PlainBackdrop)
	self:SetWidth(180)
	self:SetHeight(270)
	self:SetToplevel(true)
	self:EnableMouse(true)
	self:SetMovable(true)
	self:SetClampedToScreen(true)
	self:Hide()

	-----------------------------------------------------------------------
	-- Panel border setup
	-----------------------------------------------------------------------
	local border = CreateFrame("Frame", nil, self)
	self.border = border

	border:SetFrameStrata("MEDIUM")
	border:SetBackdrop({
				   edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				   tile = true, tileSize = 32, edgeSize = 32,
				   insets = { left = 11, right = 12, top = 12, bottom = 11 }
			   })
	border:SetBackdropBorderColor(def_col.r, def_col.g, def_col.b)
	border:SetAllPoints(self)
	border:Hide()

	local titlebox = CreateFrame("Frame", nil, border)
	titlebox:EnableMouse(true)
	titlebox:SetMovable(true)
	titlebox:RegisterForDrag("LeftButton")
	titlebox:SetScript("OnDragStart", function()
						  Volumizer:StartMoving()
					  end)
	titlebox:SetScript("OnDragStop", function()
						 Volumizer:StopMovingOrSizing()
					 end)

	local titlebg = border:CreateTexture(nil, "ARTWORK")
	titlebg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	titlebg:SetPoint("CENTER", border, "TOP", 0, -17)
	titlebg:SetWidth(230)
	titlebg:SetHeight(56)

	titlebox:SetAllPoints(titlebg)

	local text = titlebox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("TOP", titlebg, "TOP", 0, -11)
	text:SetText("Volumizer")

	-----------------------------------------------------------------------
	-- Slider and Checkbox setup
	-----------------------------------------------------------------------
	local relative = self
	local widget

	for k, v in pairs(VOLUMES) do
		widget = MakeControl(k, relative)
		relative = widget
	end
	relative = MakeContainer(relative, -10)	-- Blank space in panel.

	for k, v in pairs(TOGGLES) do
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

	-----------------------------------------------------------------------
	-- Static popup initialization
	-----------------------------------------------------------------------
	local function OnRenamePreset(self)
		local parent = self:GetParent()
		local edit_box = parent.editBox or self.editBox
		local text = edit_box:GetText()

		if text == "" then
			text = nil
		end
		edit_box:SetText("")

		VolumizerPresets[Volumizer.renaming].name = text
		edit_box:GetParent():Hide()
	end

	StaticPopupDialogs["Volumizer_RenamePreset"] = {
		text = _G.ERR_NAME_NO_NAME,
		button1 = _G.ACCEPT,
		button2 = _G.CANCEL,
		OnShow = function(self)
				 self.button1:Disable()
				 self.button2:Enable()
				 self.editBox:SetFocus()
			 end,
		OnAccept = OnRenamePreset,
		EditBoxOnEnterPressed = OnRenamePreset,
		EditBoxOnEscapePressed = function(self)
						 self:GetParent():Hide()
					 end,
		EditBoxOnTextChanged = function (self)
					       local parent = self:GetParent()

					       if parent.editBox:GetText() ~= "" then
						       parent.button1:Enable()
					       else
						       parent.button1:Disable()
					       end
				       end,
		timeout = 0,
		hideOnEscape = 1,
		exclusive = 1,
		whileDead = 1,
		hasEditBox = 1
	}

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

			if WorldFrame_OnMouseDown then
				WorldFrame_OnMouseDown(frame, ...)
			end
		end)

	WorldFrame:SetScript("OnMouseUp",
		function(frame, ...)
			local x, y = GetCursorPosition()

			if not old_x or not old_y or not x or not y or not click_time then
				self:Hide()
				border:Hide()

				if WorldFrame_OnMouseUp then
					WorldFrame_OnMouseUp(frame, ...)
				end
				return
			end

			if (math.abs(x - old_x) + math.abs(y - old_y)) <= 5 and GetTime() - click_time < 1 then
				self:Hide()
				border:Hide()
			end

			if WorldFrame_OnMouseUp then
				WorldFrame_OnMouseUp(frame, ...)
			end
		end)

	SLASH_Volumizer1 = "/volumizer"
	SLASH_Volumizer2 = "/vol"
	SlashCmdList["Volumizer"] = function()
					    Volumizer:Toggle(nil, true)
				    end

	-----------------------------------------------------------------------
	-- LDB Icon initial display
	-----------------------------------------------------------------------
	DataObj = LDB:NewDataObject("Volumizer", {
		type	= "data source",
		label	= "Volumizer",
		text	= "0%",
		icon	= "Interface\\COMMON\\VOICECHAT-SPEAKER",
		OnClick	= function(display, button)
				  if button == "LeftButton" then
					  SetCVar("Sound_EnableAllSound", (tonumber(GetCVar("Sound_EnableAllSound")) == 0) and 1 or 0)
				  elseif button == "RightButton" then
					  Volumizer:Toggle(display, false)
				  end
			  end,
		OnTooltipShow	= function(self)
					  self:AddLine(KEY_BUTTON1.." - "..MUTE)
					  self:AddLine(KEY_BUTTON2.." - "..CLICK_FOR_DETAILS)
				  end,
		UpdateText	= function(self)
					  self.text = string.format("%d%%", tostring(VOLUMES.master.Volume:GetValue() * 100))
				  end,
	})
	local enabled = tonumber(AudioOptionsSoundPanelEnableSound:GetValue())

	if enabled == 1 then
		DataObj.icon = "Interface\\COMMON\\VoiceChat-Speaker-Small"
	else
		DataObj.icon = "Interface\\COMMON\\VOICECHAT-MUTED"
	end
	DataObj:UpdateText()

	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self.PLAYER_ENTERING_WORLD = nil
end
