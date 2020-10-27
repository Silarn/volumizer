-------------------------------------------------------------------------------
-- Localized globals
-------------------------------------------------------------------------------
local math = _G.math
local string = _G.string
local table = _G.table

local tonumber = _G.tonumber
local tostring = _G.tostring

local pairs = _G.pairs

local CreateFrame = _G.CreateFrame
local GameTooltip = _G.GameTooltip
local UIParent = _G.UIParent
local def_col, def_bg_col = _G.TOOLTIP_DEFAULT_COLOR, _G.TOOLTIP_DEFAULT_BACKGROUND_COLOR

-------------------------------------------------------------------------------
-- Addon namespace
-------------------------------------------------------------------------------
local Volumizer = CreateFrame("Frame", "VolumizerPanel", UIParent, _G.BackdropTemplateMixin and "BackdropTemplate")

Volumizer:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self, event, ...)
end)

Volumizer:RegisterEvent("ADDON_LOADED")

local LDB = _G.LibStub:GetLibrary("LibDataBroker-1.1")

local DataObj

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local DEFAULT_PRESET_VALUES = {
	ambience = {
		volume = 0.6,
		enable = 1
	},
	music = {
		volume = 0.4,
		enable = 1
	},
	master = {
		volume = 1.0,
		enable = 1
	},
	sfx = {
		volume = 1.0,
		enable = 1
	},
	error = 1,
	emote = 1,
	pet = 1,
	loop = 0,
	background = 0,
	listener = 1,
}

local INITIAL_PRESETS = {
	{
		name = "Preset 1",
		values = _G.CopyTable(DEFAULT_PRESET_VALUES),
	},
	{
		name = "Preset 2",
		values = _G.CopyTable(DEFAULT_PRESET_VALUES),
	},
	{
		name = "Preset 3",
		values = _G.CopyTable(DEFAULT_PRESET_VALUES),
	},
	{
		name = "Preset 4",
		values = _G.CopyTable(DEFAULT_PRESET_VALUES),
	},
	{
		name = "Preset 5",
		values = _G.CopyTable(DEFAULT_PRESET_VALUES),
	},
}

local DEFAULT_PRESET = {
	values = _G.CopyTable(DEFAULT_PRESET_VALUES)
}

local VOLUMES = {
	ambience = {
		SoundOption	= _G.SoundPanelOptions.Sound_AmbienceVolume,
		VolumeCVar	= "Sound_AmbienceVolume",
		Volume		= _G.AudioOptionsSoundPanelAmbienceVolume,
		EnableCVar	= "Sound_EnableAmbience",
		Enable		= _G.AudioOptionsSoundPanelAmbientSounds,
		Tooltip		= _G.OPTION_TOOLTIP_ENABLE_AMBIENCE,
	},
	music = {
		SoundOption	= _G.SoundPanelOptions.Sound_MusicVolume,
		VolumeCVar	= "Sound_MusicVolume",
		Volume		= _G.AudioOptionsSoundPanelMusicVolume,
		EnableCVar	= "Sound_EnableMusic",
		Enable		= _G.AudioOptionsSoundPanelMusic,
		Tooltip		= _G.OPTION_TOOLTIP_ENABLE_MUSIC,
	},
	master = {
		SoundOption	= _G.SoundPanelOptions.Sound_MasterVolume,
		VolumeCVar	= "Sound_MasterVolume",
		Volume		= _G.AudioOptionsSoundPanelMasterVolume,
		EnableCVar	= "Sound_EnableAllSound",
		Enable		= _G.AudioOptionsSoundPanelEnableSound,
		Tooltip		= _G.OPTION_TOOLTIP_ENABLE_SOUND,
	},
	sfx	= {
		SoundOption	= _G.SoundPanelOptions.Sound_SFXVolume,
		VolumeCVar	= "Sound_SFXVolume",
		Volume		= _G.AudioOptionsSoundPanelSoundVolume,
		EnableCVar	= "Sound_EnableSFX",
		Enable		= _G.AudioOptionsSoundPanelSoundEffects,
		Tooltip		= _G.OPTION_TOOLTIP_ENABLE_SOUNDFX,
	}
}

local TOGGLES = {
	error = {
		SoundOption	= _G.SoundPanelOptions.Sound_EnableErrorSpeech,
		EnableCVar	= "Sound_EnableErrorSpeech",
		Enable		= _G.AudioOptionsSoundPanelErrorSpeech,
		Tooltip		= _G.OPTION_TOOLTIP_ENABLE_ERROR_SPEECH,
	},
	emote = {
		SoundOption	= _G.SoundPanelOptions.Sound_EnableEmoteSounds,
		EnableCVar	= "Sound_EnableEmoteSounds",
		Enable		= _G.AudioOptionsSoundPanelEmoteSounds,
		Tooltip		= _G.OPTION_TOOLTIP_ENABLE_EMOTE_SOUNDS,
	},
	pet = {
		SoundOption	= _G.SoundPanelOptions.Sound_EnablePetSounds,
		EnableCVar	= "Sound_EnablePetSounds",
		Enable		= _G.AudioOptionsSoundPanelPetSounds,
		Tooltip		= _G.OPTION_TOOLTIP_ENABLE_PET_SOUNDS,
	},
	loop = {
		SoundOption	= _G.SoundPanelOptions.Sound_ZoneMusicNoDelay,
		EnableCVar	= "Sound_ZoneMusicNoDelay",
		Enable		= _G.AudioOptionsSoundPanelLoopMusic,
		Tooltip		= _G.OPTION_TOOLTIP_ENABLE_MUSIC_LOOPING,
	},
	background = {
		SoundOption	= _G.SoundPanelOptions.Sound_EnableSoundWhenGameIsInBG,
		EnableCVar	= "Sound_EnableSoundWhenGameIsInBG",
		Enable		= _G.AudioOptionsSoundPanelSoundInBG,
		Tooltip		= _G.OPTION_TOOLTIP_ENABLE_BGSOUND,
	},
	listener = {
		SoundOption	= _G.SoundPanelOptions.Sound_ListenerAtCharacter,
		EnableCVar	= "Sound_ListenerAtCharacter",
		Enable		= nil,
		Tooltip		= _G.OPTION_TOOLTIP_ENABLE_SOUND_AT_CHARACTER,
	},
}

local HorizontalSliderBG = {
	bgFile = [[Interface\Buttons\UI-SliderBar-Background]],
	edgeFile = [[Interface\Buttons\UI-SliderBar-Border]],
	edgeSize = 8,
	tile = true,
	tileSize = 8,
	insets = {
		left = 3,
		right = 3,
		top = 6,
		bottom = 6
	}
}

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------
local user_presets

-------------------------------------------------------------------------------
-- Local functions
-------------------------------------------------------------------------------
local function HideTooltip()
	GameTooltip:Hide()
end

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
	check:SetNormalTexture([[Interface\Buttons\UI-CheckBox-Up]])
	check:SetPushedTexture([[Interface\Buttons\UI-CheckBox-Down]])
	check:SetHighlightTexture([[Interface\Buttons\UI-CheckBox-Highlight]])
	check:SetDisabledCheckedTexture([[Interface\Buttons\UI-CheckBox-Check-Disabled]])
	check:SetCheckedTexture([[Interface\Buttons\UI-CheckBox-Check]])

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
	function MakeToggle(name, relative)
		local ref = TOGGLES[name]
		local container = MakeContainer(relative, -15)
		local check = MakeCheckButton(container)
		check:SetPoint("LEFT", container, "LEFT")

		if ref.Enable then
			check:SetChecked(ref.Enable:GetValue())
		else
			check:SetChecked(tonumber(_G.GetCVar(ref.EnableCVar)))
		end
		check:SetHitRectInsets(-10, -150, 0, 0)
		check:SetScript("OnClick", function(checkButton)
			if ref.Enable then
				ref.Enable:SetValue(check:GetChecked() and 1 or 0)
			else
				_G.SetCVar(ref.EnableCVar, check:GetChecked() and 1 or 0)
			end
		end)
		check.tooltip = ref.Tooltip
		check:SetScript("OnEnter", ShowTooltip)
		check:SetScript("OnLeave", HideTooltip)

		local text = check:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", check, "RIGHT", 0, 3)
		text:SetText(_G[ref.SoundOption.text])

		_G.hooksecurefunc("SetCVar", function(cvar, value)
			if cvar == ref.EnableCVar then
				check:SetChecked(value)
			end
		end)
		return container
	end

	local function SetSliderLabel(slider, ref, value)
		slider.text:SetFormattedText("%s %d%%", _G[ref.SoundOption.text], value * 100)
	end

	function MakeControl(name, relative)
		local ref = VOLUMES[name]
		local container = MakeContainer(relative)

		local check = MakeCheckButton(container)
		check:SetPoint("LEFT", container, "LEFT")
		check:SetChecked(ref.Enable:GetValue())
		check:SetScript("OnClick", function(checkButton)
			ref.Enable:SetValue(check:GetChecked() and 1 or 0)
		end)
		check.tooltip = ref.Tooltip
		check:SetScript("OnEnter", ShowTooltip)
		check:SetScript("OnLeave", HideTooltip)

		local slider = CreateFrame("Slider", nil, container, _G.BackdropTemplateMixin and "BackdropTemplate")
		slider:SetPoint("LEFT", check, "RIGHT", 0, 0)
		slider:SetPoint("RIGHT")
		slider:SetHeight(15)
		slider:SetHitRectInsets(0, 0, -10, -10)
		slider:SetOrientation("HORIZONTAL")
		slider:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Horizontal]])
		slider:SetBackdrop(HorizontalSliderBG)
		slider:SetMinMaxValues(ref.SoundOption.minValue, ref.SoundOption.maxValue)
		slider:SetValue(_G.BlizzardOptionsPanel_GetCVarSafe(ref.VolumeCVar))
		slider:SetValueStep(0.05)
		slider:EnableMouseWheel(true)

		slider.text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		slider.text:SetPoint("BOTTOM", slider, "TOP", 0, 3)

		SetSliderLabel(slider, ref, ref.Volume:GetValue())

		slider:SetScript("OnValueChanged", function(self, value)
			ref.Volume:SetValue(value)

			SetSliderLabel(self, ref, value)

			if ref == VOLUMES.master then
				DataObj:UpdateText(value)
			end
		end)

		slider:SetScript("OnMouseWheel", function(self, delta)
			local currentValue = self:GetValue()
			local minValue, maxValue = self:GetMinMaxValues()
			local step = self:GetValueStep()

			if delta > 0 then
				self:SetValue(math.min(maxValue, currentValue + step))
			elseif delta < 0 then
				self:SetValue(math.max(minValue, currentValue - step))
			end
		end)

		_G.hooksecurefunc("SetCVar", function(cvar, value)
			if cvar == ref.VolumeCVar then
				slider:SetValue(value)
			elseif cvar == ref.EnableCVar then
				check:SetChecked(value)

				if ref == VOLUMES.master then
					if tonumber(value) == 1 then
						DataObj.icon = [[Interface\COMMON\VoiceChat-Speaker-Small]]
					else
						DataObj.icon = [[Interface\COMMON\VOICECHAT-MUTED]]
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
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = {
		left = 5,
		right = 5,
		top = 5,
		bottom = 5,
	}
}

local PlainBackdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = {
		left = 5,
		right = 5,
		top = 5,
		bottom = 5,
	}
}

-------------------------------------------------------------------------------
-- Main AddOn functions
-------------------------------------------------------------------------------
function Volumizer:ChangeBackdrop(backdrop)
	self:SetBackdrop(backdrop)
	self:SetBackdropBorderColor(def_col.r, def_col.g, def_col.b)
	self:SetBackdropColor(def_bg_col.r, def_bg_col.g, def_bg_col.b)
end

local function __UsePreset(preset)
	local ref = (preset < 1) and DEFAULT_PRESET or user_presets[preset]

	if not ref then
		_G.error("The preset '"..preset.."' does not exist.")
		return
	end

	for category, data in pairs(VOLUMES) do
		_G.SetCVar(data.VolumeCVar, ref.values[category].volume)
		_G.SetCVar(data.EnableCVar, ref.values[category].enable)
	end

	for category, data in pairs(TOGGLES) do
		_G.SetCVar(data.EnableCVar, ref.values[category])
	end
end

local function DropDownUsePreset(self, preset)
	__UsePreset(preset)

	-- Remove the check-mark from the menu entry.
	_G[self:GetName().."Check"]:Hide()
end

local function DropDownSavePreset(self, preset)
	local ref = user_presets[preset]

	if not ref then
		_G.error("The preset '"..preset.."' does not exist.")
		return
	end

	for category, data in pairs(VOLUMES) do
		ref.values[category].volume = _G.GetCVar(data.VolumeCVar)
		ref.values[category].enable = _G.GetCVar(data.EnableCVar)
	end

	for category, data in pairs(TOGGLES) do
		ref.values[category] = _G.GetCVar(data.EnableCVar)
	end
	user_presets[preset] = ref
end

local function DropDownDeletePreset(self, preset)
	local ref = user_presets[preset]

	if not ref then
		_G.error("The preset '"..preset.."' does not exist.")
		return
	end
	table.remove(user_presets, preset)
	_G.CloseDropDownMenus(1)
end

local function RenamePreset_Popup(self, preset)
	Volumizer.renaming = preset
	_G.StaticPopup_Show("Volumizer_RenamePreset")
	_G.CloseDropDownMenus(1)
end

local function DropDownAddPreset(self)
	local preset = {
		name = ("Preset %s"):format(_G.date("%b %d %H:%M:%S %Y", _G.GetTime())),
		values = {},
	}
	for category, data in pairs(DEFAULT_PRESET_VALUES) do
		if _G.type(data) == "table" then
			preset.values[category] = {}

			for label, value in pairs(data) do
				preset.values[category][label] = value
			end
		else
			preset.values[category] = data
		end
	end
	table.insert(user_presets, preset)
	RenamePreset_Popup(self, #user_presets)
end

do
	local function GetAnchor(frame)
		if not frame then
			return "CENTER", UIParent, 0, 0
		end

		local x, y = frame:GetCenter()

		if not x or not y then
			return "TOPLEFT", "BOTTOMLEFT"
		end

		local hhalf = (x > UIParent:GetWidth() * 2 / 3) and "RIGHT" or (x < UIParent:GetWidth() / 3) and "LEFT" or ""
		local vhalf = (y > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"

		return vhalf .. hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf
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
	user_presets = _G.VolumizerPresets

	if not user_presets then
		_G.VolumizerPresets = INITIAL_PRESETS
		user_presets = _G.VolumizerPresets
	end
	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if _G.IsLoggedIn() then
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
	self:SetHeight(305)
	self:SetToplevel(true)
	self:EnableMouse(true)
	self:SetMovable(true)
	self:SetClampedToScreen(true)
	self:Hide()

	-----------------------------------------------------------------------
	-- Panel border setup
	-----------------------------------------------------------------------
	local border = CreateFrame("Frame", nil, self, _G.BackdropTemplateMixin and "BackdropTemplate")
	self.border = border

	border:SetFrameStrata("MEDIUM")
	border:SetBackdrop({
		edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
		tile = true,
		tileSize = 32,
		edgeSize = 32,
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
	titlebg:SetTexture([[Interface\DialogFrame\UI-DialogBox-Header]])
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
	do
		local widget

		for category in pairs(VOLUMES) do
			widget = MakeControl(category, relative)
			relative = widget
		end
		relative = MakeContainer(relative, -10)	-- Blank space in panel.

		for category in pairs(TOGGLES) do
			widget = MakeToggle(category, relative)
			relative = widget
		end
	end	-- do-block

	-----------------------------------------------------------------------
	-- Hardware output controls
	-----------------------------------------------------------------------
	do
		local cvar = "Sound_OutputDriverIndex"
		local driver_index = _G.BlizzardOptionsPanel_GetCVarSafe(cvar)
		local device_name = _G.Sound_GameSystem_GetOutputDriverNameByIndex(driver_index)

		local output = CreateFrame("Frame", "Volumizer_OutputDropDown", self, "UIDropDownMenuTemplate")
		output:SetPoint("TOPLEFT", relative, "BOTTOMLEFT", -5, 0)

		local function output_OnClick(info)
			local value = info.value
			local dropdown = output

			_G.UIDropDownMenu_SetSelectedValue(dropdown, value)

			local prev_value = dropdown:GetValue()
			dropdown:SetValue(value)

			if prev_value ~= value then
				_G.AudioOptionsFrame_AudioRestart()
			end
		end

		function output:initialize()
			local value = _G.UIDropDownMenu_GetSelectedValue(self)
			local num = _G.Sound_GameSystem_GetNumOutputDrivers()
			local info = _G.UIDropDownMenu_CreateInfo()

			for index = 0, num - 1, 1 do
				info.text = _G.Sound_GameSystem_GetOutputDriverNameByIndex(index)
				info.value = index
				info.checked = nil

				if value and value == index then
					_G.UIDropDownMenu_SetText(self, info.text)
					info.checked = true
				else
					info.checked = nil
				end
				info.func = output_OnClick

				_G.UIDropDownMenu_AddButton(info)
			end
		end
		output.type = _G.CONTROLTYPE_DROPDOWN
		output.cvar = cvar
		output.defaultValue = _G.BlizzardOptionsPanel_GetCVarDefaultSafe(cvar)
		output.value = driver_index
		output.newValue = driver_index

		_G.UIDropDownMenu_SetSelectedValue(output, driver_index)
		_G.UIDropDownMenu_Initialize(output, output.initialize)

		function output:SetValue(value)
			self.value = value
			_G.BlizzardOptionsPanel_SetCVarSafe(self.cvar, value)
		end

		function output:GetValue()
			return _G.BlizzardOptionsPanel_GetCVarSafe(self.cvar)
		end

		function output:RefreshValue()
			local driver_index = _G.BlizzardOptionsPanel_GetCVarSafe(self.cvar)
			self.value = driver_index
			self.newValue = driver_index

			_G.UIDropDownMenu_SetSelectedValue(self, driver_index)
			_G.UIDropDownMenu_Initialize(self, self.initialize)
		end

		local text = output:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("BOTTOM", output, "TOP", 63, 3)
		text:SetText(_G.GAME_SOUND_OUTPUT)
	end	-- do-block

	-----------------------------------------------------------------------
	-- Presets
	-----------------------------------------------------------------------
	do
		local preset_menu = CreateFrame("Frame", nil, self)
		preset_menu.displayMode = "MENU"
		preset_menu.point = "TOPLEFT"
		preset_menu.relativePoint = "RIGHT"
		preset_menu.yOffset = 8
		preset_menu.levelAdjust = 0
		preset_menu.info = {}

		function preset_menu.initialize(self, level)
			if not level then
				return
			end
			local info = preset_menu.info

			table.wipe(info)

			if level == 1 then
				for index = 1, #user_presets do
					info.text = user_presets[index].name
					info.value = index
					info.hasArrow = true
					info.notCheckable = true

					info.arg1 = index
					info.func = DropDownUsePreset

					_G.UIDropDownMenu_AddButton(info, level)
				end
				table.wipe(info)		-- Blank space in menu.

				info.disabled = true
				info.notCheckable = 1

				_G.UIDropDownMenu_AddButton(info, level)

				info.disabled = nil
				info.text = _G.ADD
				info.func = DropDownAddPreset
				info.arg1 = 0
				info.colorCode = "|cffffff00"
				info.notCheckable = 1
				_G.UIDropDownMenu_AddButton(info, level)

				info.text = _G.DEFAULTS
				info.func = DropDownUsePreset
				info.arg1 = 0
				info.colorCode = "|cffffff00"
				info.notCheckable = 1
				_G.UIDropDownMenu_AddButton(info, level)
			elseif level == 2 then
				table.wipe(info)

				info.arg1 = _G.UIDROPDOWNMENU_MENU_VALUE
				info.notCheckable = 1

				info.text = _G.SAVE
				info.func = DropDownSavePreset
				_G.UIDropDownMenu_AddButton(info, level)

				info.text = _G.NAME
				info.func = RenamePreset_Popup
				_G.UIDropDownMenu_AddButton(info, level)

				info.text = _G.DELETE
				info.func = DropDownDeletePreset
				_G.UIDropDownMenu_AddButton(info, level)
			end
		end

		local preset_button = CreateFrame("Button", "Volumizer_PresetButton", self)
		preset_button:SetWidth(20)
		preset_button:SetHeight(20)
		preset_button:SetPoint("RIGHT", self, "BOTTOMRIGHT", -8, 17)
		preset_button:SetNormalTexture([[Interface\BUTTONS\UI-SpellbookIcon-NextPage-Up]])
		preset_button:SetHighlightTexture([[Interface\BUTTONS\ButtonHilight-Round]])
		preset_button:SetDisabledTexture([[Interface\BUTTONS\UI-SpellbookIcon-NextPage-Disabled]])
		preset_button:SetPushedTexture([[Interface\BUTTONS\UI-SpellbookIcon-NextPage-Down]])

		preset_button:SetScript("OnClick", function(self, button, down)
			preset_menu.relativeTo = self
			_G.ToggleDropDownMenu(1, nil, preset_menu, self:GetName(), 0, 0)
		end)

		preset_button:SetScript("OnHide", function()
			if _G.UIDROPDOWNMENU_OPEN_MENU == preset_menu then
				_G.CloseDropDownMenus()
			end
		end)

		local text = preset_button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("RIGHT", preset_button, "LEFT")
		text:SetText("Presets")
	end	-- do-block

	-----------------------------------------------------------------------
	-- Static popup initialization
	-----------------------------------------------------------------------
	do
		local function OnRenamePreset(self)
			local edit_box = self:GetParent().editBox or self.editBox
			local text = edit_box:GetText()

			if text == "" then
				text = nil
			end
			edit_box:SetText("")

			user_presets[Volumizer.renaming].name = text
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
			EditBoxOnTextChanged = function(self)
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
	end	-- do-block

	-----------------------------------------------------------------------
	-- Frame interaction with keyboard/mouse
	-----------------------------------------------------------------------
	do
		local old_x, old_y, click_time

		_G.WorldFrame:HookScript("OnMouseDown", function(frame, ...)
			old_x, old_y = _G.GetCursorPosition()
			click_time = _G.GetTime()
		end)

		_G.WorldFrame:HookScript("OnMouseUp", function(frame, ...)
			local x, y = _G.GetCursorPosition()

			if not old_x or not old_y or not x or not y or not click_time then
				self:Hide()
				border:Hide()
				return
			end

			if (math.abs(x - old_x) + math.abs(y - old_y)) <= 5 and _G.GetTime() - click_time < 1 then
				self:Hide()
				border:Hide()
			end
		end)

		table.insert(_G.UISpecialFrames, "VolumizerPanel")

		SLASH_Volumizer1 = "/volumizer"
		SLASH_Volumizer2 = "/vol"
		SlashCmdList["Volumizer"] = function(preset_name)
			local can_toggle = true
			preset_name = preset_name:lower()

			if preset_name then
				for index = 1, #user_presets do
					if user_presets[index].name:lower() == preset_name then
						can_toggle = false
						__UsePreset(index)
						break
					end
				end
			end

			if can_toggle then
				Volumizer:Toggle(nil, true)
			end
		end
	end	-- do-block

	-----------------------------------------------------------------------
	-- LDB Icon initial display
	-----------------------------------------------------------------------
	DataObj = LDB:NewDataObject("Volumizer", {
		type	= "data source",
		label	= "Volumizer",
		text	= "0%",
		icon	= [[Interface\COMMON\VOICECHAT-SPEAKER]],
		OnClick = function(display, button)
			if button == "LeftButton" then
				_G.SetCVar("Sound_EnableAllSound", (tonumber(_G.GetCVar("Sound_EnableAllSound")) == 0) and 1 or 0)
			elseif button == "RightButton" then
				Volumizer:Toggle(display, false)
			end
		end,
		OnTooltipShow = function(self)
			self:AddLine(_G.KEY_BUTTON1 .. " - " .. _G.MUTE)
			self:AddLine(_G.KEY_BUTTON2 .. " - " .. _G.CLICK_FOR_DETAILS)
		end,
		OnMouseWheel = function(self, delta)
			local ref = VOLUMES.master
			local current = _G.BlizzardOptionsPanel_GetCVarSafe(ref.VolumeCVar)
			local step = 0.05

			if delta > 0 then
				_G.SetCVar(ref.VolumeCVar, math.min(ref.SoundOption.maxValue, current + step))
			elseif delta < 0 then
				_G.SetCVar(ref.VolumeCVar, math.max(ref.SoundOption.minValue, current - step))
			end
		end,
		UpdateText = function(self, value)
			self.text = ("%d%%"):format(value * 100)
		end,
	})

	if tonumber(_G.AudioOptionsSoundPanelEnableSound:GetValue()) == 1 then
		DataObj.icon = [[Interface\COMMON\VoiceChat-Speaker-Small]]
	else
		DataObj.icon = [[Interface\COMMON\VOICECHAT-MUTED]]
	end
	DataObj:UpdateText(VOLUMES.master.Volume:GetValue())

	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self.PLAYER_ENTERING_WORLD = nil
end
