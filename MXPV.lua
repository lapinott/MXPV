----------------------------------------------
--          MyXPView -- XP Display          --
--        Edda's Comprehensive XP UI        --
----------------------------------------------


--[[ DONATION WALL

	@Enercul 2k 20140426
	@Chelatron 200g 20140426
	@Limalia 1k 20140505
	@Gizmodio 1k 20140508
	@Eks 5k 20140513
	@demeiz 5k 20140515
	@Badios 2k 20140518
	NA @halilihq materials 20140518
	NA @thegoonies99 2k 20140518
	NA @Deano 1k 20140518
	NA @rhinobear 5k 20140518
	NA @... 20140526 500g
	@Sayorim 10g :) 20140602
	...
	
]]--


-- Main objects
MXPV = {}
MXPV.Meter = {}
MXPV.Options = {}

-- Init main vars
MXPV.name = "MXPV"
MXPV.command = "/mxpv"
MXPV.version = 2.24
MXPV.varVersion = 1
MXPV.debug = _mxpvdebug or false
MXPV.tick = 250
MXPV.nextUpdate = 0
MXPV.XPBarWidth = 342
MXPV.CombatState = false
MXPV.OutOfCombatTime = 0
MXPV.StartOfCombatTime = 0

-- Init XP vars
MXPV.fadeXPCountdown = false
MXPV.lastXPGainTime = 0
MXPV.XPGainPool = 0
MXPV.XPGainPack = 0

-- Init RP vars
MXPV.fadeRPCountdown = false
MXPV.lastRPGainTime = 0
MXPV.RPGainPool = 0
MXPV.RPGainPack = 0

-- Init meter vars
MXPV.Meter.InitTime = GetGameTimeMilliseconds()
MXPV.Meter.TimeElapsed = 0
MXPV.Meter.XPGains = 0
MXPV.Meter.RPGains = 0
MXPV.Meter.XPTimeLeft = 0
MXPV.Meter.RPTimeLeft = 0
MXPV.Meter.CurrentXPGain = 0
MXPV.Meter.CurrentRPGain = 0
MXPV.Meter.BufferSize = 10
MXPV.Meter.Buffer = {}
MXPV.Meter.RPBuffer = {}
MXPV.Meter.XPTimeLeft = 0
MXPV.Meter.MobsLeft = 0
MXPV.Meter.KillsLeft = 0
MXPV.Meter.XPPerHour = 0
MXPV.Meter.RPPerHour = 0
MXPV.Meter.PercentXPPerHour = 0
MXPV.Meter.PercentRPPerHour = 0
MXPV.Meter.XPHoursLeft = 0
MXPV.Meter.XPMinutesLeft = 0
MXPV.Meter.XPSecondsLeft = 0
MXPV.Meter.Paused = false

-- Options
MXPV.Options.ConsoleMode = false
MXPV.Options.UIMode = true
MXPV.Options.XPBarMode = true
MXPV.Options.MeterMode = true
MXPV.Options.CombatOnly = false
MXPV.Options.XPMode = true
MXPV.Options.RPMode = false
MXPV.Options.AutoSwitch = true
MXPV.Options.fadeXPGainDelay = 10000
MXPV.Options.RateFactor = 1
MXPV.Options.OffsetX = -50
MXPV.Options.OffsetY = -40
MXPV.Options.point = 12
MXPV.Options.relativePoint = 12
MXPV.Options.ScaleFactor = 1

-- Init
function MXPV.Initialize(eventCode, addOnName)

	-- Verify Add-On
	if (addOnName ~= MXPV.name) then return end

	-- Load user's variables
	MXPV.SavedVars = ZO_SavedVars:New("MXPVvars", math.floor(MXPV.varVersion * 100), nil, MXPV.Options, nil)

	-- Set loaded variables
	if not MXPV.SavedVars.UIMode then MXPV.ToggleUI(false) end
	if not MXPV.SavedVars.XPBarMode then MXPV.ToggleXPBar(false) end
	if not MXPV.SavedVars.MeterMode then MXPV.ToggleMeter(false) end

	-- Init more XP vars
	MXPV.IsVeteran = IsUnitVeteran("player")
	MXPV.IsChampion = IsUnitVeteran("player") and GetUnitVeteranRank("player") == 16 and GetUnitVeteranPoints("player") >= GetUnitVeteranPointsMax("player")
	MXPV.CurrentXP = MXPV.GetUnit("XP")
	MXPV.CurrentLevel = MXPV.GetUnit("Level")
	MXPV.CurrentMaxXP = MXPV.GetUnit("XPMax")
	MXPV.BeforeGainXP = MXPV.GetUnit("XP")
	MXPV.BeforeGainLevel = MXPV.GetUnit("Level")
	MXPV.BeforeGainMaxXP = MXPV.GetUnit("XPMax")

	-- Init more RP vars
	MXPV.CurrentRP = MXPV.GetUnit("RP")
	MXPV.CurrentRank = MXPV.GetUnit("Rank")
	MXPV.CurrentMaxRP = MXPV.GetUnit("RPMax")
	MXPV.BeforeGainRP = MXPV.GetUnit("RP")
	MXPV.BeforeGainRank = MXPV.GetUnit("Rank")
	MXPV.BeforeGainMaxRP = MXPV.GetUnit("RPMax")

	-- Register the slash command handler
	SLASH_COMMANDS[MXPV.command] = MXPV.SlashCommands

	-- Attach Event listeners
	EVENT_MANAGER:RegisterForEvent(MXPV.name, EVENT_EXPERIENCE_UPDATE, MXPV.ExperienceUpdate)
	EVENT_MANAGER:RegisterForEvent(MXPV.name, EVENT_RANK_POINT_UPDATE, MXPV.RankPointsUpdate)
	EVENT_MANAGER:RegisterForEvent(MXPV.name, EVENT_PLAYER_COMBAT_STATE, MXPV.GetSetCombatState)
	EVENT_MANAGER:RegisterForEvent(MXPV.name, EVENT_RETICLE_TARGET_CHANGED, MXPV.ReticleChangedEvent)
	EVENT_MANAGER:RegisterForEvent(MXPV.name, EVENT_ACTION_LAYER_POPPED, MXPV.LayerPopped)
	EVENT_MANAGER:RegisterForEvent(MXPV.name, EVENT_ACTION_LAYER_PUSHED, MXPV.LayerPushed)

	-- Load successful
	d(string.format("MXPV v%f loaded.", MXPV.version))
	d(string.format("MXPV.CurrentLevel : %d", MXPV.CurrentLevel))
	d(string.format("MXPV.CurrentXP : %d", MXPV.CurrentXP))
	d(string.format("MXPV.CurrentMaxXP : %d", MXPV.CurrentMaxXP))
	d(string.format("MXPV.lastXPGainTime : %d", MXPV.lastXPGainTime))
	d(string.format("MXPV.SavedVars.fadeXPGainDelay : %d", MXPV.SavedVars.fadeXPGainDelay))

	-- Scale the UI
	MXPV.SetScale(MXPV.SavedVars.ScaleFactor)

	-- Update XP bar
	MXPV.UpdateProgressbar(false)

	-- Init Meter
	if MXPV.SavedVars.CombatOnly then MXPV.Meter.Pause()
	else MXPV.Meter.Start() end
	MXPV.Meter.Update()

	-- Position the UI
	MXPVUI:ClearAnchors()
	MXPVUI:SetAnchor (MXPV.SavedVars.point, parent, MXPV.SavedVars.relativePoint, MXPV.SavedVars.OffsetX, MXPV.SavedVars.OffsetY)

	-- Build menu
	local LAM = LibStub("LibAddonMenu-2.0")
	local panelData = {
		type = "panel",
		name = "MyXPView v"..MXPV.version,
		author = "Edda",
		version = "1.7",
		registerForRefresh = true,
		registerForDefaults = true,
	}
	LAM:RegisterAddonPanel("MXPV_OPTIONS", panelData)

	local optionsData = {
		{
			type = "header",
			name = "Display Options",
		},
		{
			type = "checkbox",
			name = "+ Display MyXPView",
			getFunc = function() return MXPV.SavedVars.UIMode end,
			setFunc = function() MXPV.ToggleUI(not MXPV.SavedVars.UIMode, true) end,
			default = MXPV.Options.UIMode,
		},
		{
			type = "checkbox",
			name = "+ Display XP bar",
			getFunc = function() return MXPV.SavedVars.XPBarMode end,
			setFunc = function() MXPV.ToggleXPBar(not MXPV.SavedVars.XPBarMode, true) end,
			default = MXPV.Options.XPBarMode,
		},
		{
			type = "checkbox",
			name = "+ Display XP meter",
			getFunc = function() return MXPV.SavedVars.MeterMode end,
			setFunc = function() MXPV.ToggleMeter(not MXPV.SavedVars.MeterMode, true) end,
			default = MXPV.Options.MeterMode,
		},
		{
			type = "checkbox",
			name = "+ Enable console logs",
			tooltip = "Display XP gains in the chat box",
			getFunc = function() return MXPV.SavedVars.ConsoleMode end,
			setFunc = function() MXPV.ToggleConsole(not MXPV.SavedVars.ConsoleMode, true) end,
			default = MXPV.Options.ConsoleMode,
		},
		{
			type = "slider",
			name = "+ Scale Factor %",
			tooltip = "Scales the UI from 25% to 100%",
			min = 25,
			max = 100,
			getFunc = function() return math.floor(100 * MXPV.SavedVars.ScaleFactor) end,
			setFunc = function (value) MXPV.SetScale(value / 100, true) end,
			default = math.floor(100 * MXPV.Options.ScaleFactor),
		},
		{
			type = "header",
			name = "Meter Options",
		},
		{
			type = "checkbox",
			name = "+ Combat Only",
			tooltip = "Only run the XP meter when you are in combat",
			getFunc = function() return MXPV.SavedVars.CombatOnly end,
			setFunc = function() MXPV.ToggleCombatOnly(not MXPV.SavedVars.CombatOnly) end,
			default = MXPV.Options.CombatOnly,
		},
		{
			type = "slider",
			name = "+ Rate Factor %",
			tooltip = "Rate factor for the combatonly mode",
			min = 0,
			max = 100,
			getFunc = function() return math.floor(100 * MXPV.SavedVars.RateFactor) end,
			setFunc = function (value) MXPV.SetRateFactor(value / 100, true) end,
			default = math.floor(100 * MXPV.Options.RateFactor),
		},
		{
			type = "description",
			title = nil,
			text = "+ Reset the XP meter",
		},
		{
			type = "button",
			name = "Reset now",
			func = function() MXPV.Meter.Reset() end,
			warning = "Will reset all meter data",
		},
		{
			type = "header",
			name = "XP Bar Options",
		},
		{
			type = "slider",
			name = "+ Persistance - in seconds",
			tooltip = "Sets the XP gain display & pool duration",
			min = 0,
			max = 20,
			getFunc = function() return math.floor(MXPV.SavedVars.fadeXPGainDelay / 1000) end,
			setFunc = function (value) MXPV.SetFadeXPGainDelay(value * 1000, true) end,
			default = math.floor(MXPV.Options.fadeXPGainDelay / 1000),
		},
		{
			type = "header",
			name = "PvP and PvM Options",
		},
		{
			type = "dropdown",
			name = "+ XP or RP tracking",
			choices = {"XP tracking", "RP tracking"},
			getFunc = function() return MXPV.GetTrackingValue() end,
			setFunc = function(valueString) MXPV.SwitchTracking(valueString, true) end,
		},
		{
			type = "checkbox",
			name = "+ Autoswitch tracking",
			tooltip = "Automatically switch between XP and RP tracking",
			getFunc = function() return MXPV.SavedVars.AutoSwitch end,
			setFunc = function() MXPV.ToggleAutoSwitch(not MXPV.SavedVars.AutoSwitch, true) end,
			default = MXPV.Options.AutoSwitch,
		},
		{
			type = "header",
			name = "Command Line",
		},
		{
			type = "description",
			title = nil,
			text = "+ All options are available via command-line. For a list of available commands type '/mxpv ?'",
		},
	}
	LAM:RegisterOptionControls("MXPV_OPTIONS", optionsData)
	
	-- Ready
	MXPV.READY = true

	-- Out
	return true
end

function MXPV.EyeOfMoscow ()

	-- Ready ?
	if not MXPV.READY then return end

	-- Break if tick not reached
	local now = GetGameTimeMilliseconds()
	if MXPV.nextUpdate > now then return end

	-- Else update ticker
	MXPV.nextUpdate = now + MXPV.tick

	-- Update meter
	if not MXPV.SavedVars.CombatOnly or MXPV.SavedVars.CombatOnly and not MXPV.Meter.Paused then MXPV.Meter.Update() end

	-- or MXPV.Meter.Update()

	-- Pool Management
	if (now - MXPV.lastXPGainTime) > MXPV.SavedVars.fadeXPGainDelay and (now - MXPV.lastRPGainTime) > MXPV.SavedVars.fadeXPGainDelay and (MXPV.fadeXPCountdown or MXPV.fadeRPCountdown) then
		MXPV.XPGainPool = 0
		MXPV.RPGainPool = 0
		MXPV.XPGainPack = 0
		MXPV.RPGainPack = 0
		MXPV.BeforeGainXP = MXPV.GetUnit("XP")
		MXPV.BeforeGainRP = MXPV.GetUnit("RP")
		MXPV.BeforeGainLevel = MXPV.GetUnit("Level")
		MXPV.BeforeGainRank = MXPV.GetUnit("Rank")
		MXPV.BeforeGainMaxXP = MXPV.GetUnit("XPMax")
		MXPV.BeforeGainMaxRP = MXPV.GetUnit("RPMax")
		MXPV.fadeXPCountdown = false
		MXPV_XP_PROGRESSBAR_GAIN:SetHidden(true)
		MXPV.UpdateProgressbar(false)
	end

end

-- Get user data function
function MXPV.GetUnit (arg)
	if arg == "XP" then
		if MXPV.IsVeteran and MXPV.IsChampion then return GetPlayerChampionXP()
		elseif MXPV.IsVeteran then return GetUnitVeteranPoints("player")
		else return GetUnitXP("player") end
	elseif arg == "Level" then
		if MXPV.IsVeteran and MXPV.IsChampion then return GetPlayerChampionPointsEarned()
		elseif MXPV.IsVeteran then return GetUnitVeteranRank("player")
		else return GetUnitLevel("player") end
	elseif arg == "XPMax" then
		if MXPV.IsVeteran and MXPV.IsChampion then return GetChampionXPInRank(GetPlayerChampionPointsEarned())
		elseif MXPV.IsVeteran then return GetUnitVeteranPointsMax("player")
		else return GetUnitXPMax("player") end
	elseif arg == "RP" then
		return GetUnitAvARankPoints("player")
	elseif arg == "RPMax" then
		return GetNumPointsNeededForAvARank(MXPV.CurrentRank + 1)
	elseif arg == "Rank" then
		return GetUnitAvARank("player")
	end
end

-- Experience Update
function MXPV.ExperienceUpdate (event, unitTag, currentExp, maxExp, reason)
	if AreUnitsEqual(unitTag, "player") then
		MXPV.Update(unitTag, currentExp, maxExp, reason)
	end
end

-- Alliance points update
function MXPV.RankPointsUpdate (event, unitTag, rankPoints, difference)
	if AreUnitsEqual(unitTag, "player") then
		if (difference > 0) then MXPV.RPUpdate (rankPoints, difference) end
	end
end

function MXPV.LayerPopped (event, layerIndex, activeLayerIndex)
	if (layerIndex == 2 or layerIndex == 12) and MXPV.SavedVars.UIMode then
		MXPVUI:SetHidden(false)
		if MXPV.Meter.Paused then MXPV.Meter.Update() end -- Visual glitch when pausing the meter while interface is open i.e. from the option menu! -> always refresh meter ?
	end
end

function MXPV.LayerPushed (event, layerIndex, activeLayerIndex)
	if (layerIndex == 2 or layerIndex == 12) and MXPV.SavedVars.UIMode then MXPVUI:SetHidden(true) end
end

function MXPV.SaveUIPosition ()
	local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = MXPVUI:GetAnchor()
	MXPV.SavedVars.OffsetX = offsetX
	MXPV.SavedVars.OffsetY = offsetY
	MXPV.SavedVars.point = point
	MXPV.SavedVars.relativePoint = relativePoint
	if MXPV.debug then MXPV.Log("OffsetX : " .. MXPV.SavedVars.OffsetX) end
	if MXPV.debug then MXPV.Log("OffsetY : " .. MXPV.SavedVars.OffsetY) end
	if MXPV.debug then MXPV.Log("point : " .. point) end
	if MXPV.debug then MXPV.Log("relativePoint : " .. relativePoint) end
end

-- Debug log
function MXPV.Log (text)
	MXPV_UI_DEBUG_LABEL:SetText(text .. "\n.\n" .. MXPV_UI_DEBUG_LABEL:GetText())
end

--Should auto switch?
-- Unit types:
-- 0 = UNIT_TYPE_INVALID
-- 1 = UNIT_TYPE_PLAYER
-- 2 = UNIT_TYPE_MONSTER
-- 3 = UNIT_TYPE_INTERACTOBJ
-- 4 = UNIT_TYPE_INTERACTFIXTURE
-- 5 = UNIT_TYPE_ANCHOR
-- 6 = UNIT_TYPE_SIEGEWEAPON
-- 7 = UNIT_TYPE_SIMPLEINTERACTOBJ
-- 8 = UNIT_TYPE_SIMPLEINTERACTFIXTURE

function MXPV.AutoSwitchMode()

	if MXPV.SavedVars.AutoSwitch then
		local unitType = GetUnitType("reticleover")
		if unitType == UNIT_TYPE_INVALID then return end

		if MXPV.CombatState and GetUnitReaction("reticleover") == UNIT_REACTION_HOSTILE then
			if (MXPV.SavedVars.XPMode and unitType == UNIT_TYPE_PLAYER) or (MXPV.SavedVars.RPMode and unitType == UNIT_TYPE_MONSTER) then MXPV.SwitchTracking(nil, true) end
		end
	end

end

-- Combat state
function MXPV.GetSetCombatState (event, inCombat)

	-- Save combat state
	MXPV.CombatState = inCombat

	-- Log for nabs = me
	if MXPV.debug then MXPV.Log ("COMBAT_STATE : " .. tostring(MXPV.CombatState)) end

	-- Register combat state tymes
	if inCombat then
		MXPV.StartOfCombatTime = GetGameTimeMilliseconds()
	else
		 MXPV.OutOfCombatTime = GetGameTimeMilliseconds()
	end

	-- Pause / start meter
	if MXPV.SavedVars.CombatOnly then
		if inCombat then
			MXPV.Meter.Start()
		else
			MXPV.Meter.Pause()
		end
	end

	-- Handle auto-switch
	MXPV.AutoSwitchMode()

end

-- Reticle changed event
function MXPV.ReticleChangedEvent ()

	MXPV.AutoSwitchMode()

end

-- Main
function MXPV.Update (unitTag, currentExp, maxExp, reason)

	-- Check if we gained XP
	if MXPV.GetUnit("XP") - MXPV.CurrentXP > 0 or MXPV.GetUnit("Level") > MXPV.CurrentLevel then

		-- Calculate XP Gain
		local XPGain = -1
		if MXPV.GetUnit("XP") - MXPV.CurrentXP > 0 then XPGain = MXPV.GetUnit("XP") - MXPV.CurrentXP end
		if MXPV.GetUnit("Level") > MXPV.CurrentLevel then XPGain = MXPV.CurrentMaxXP - MXPV.CurrentXP + MXPV.GetUnit("XP") end

		-- Update our vars
		MXPV.IsVeteran = MXPV.IsVeteran or IsUnitVeteran("player")
		MXPV.IsChampion = MXPV.IsChampion or MXPV.IsVeteran and GetUnitVeteranRank("player") == 16 and GetUnitVeteranPoints("player") >= GetUnitVeteranPointsMax("player")
		MXPV.CurrentXP = MXPV.GetUnit("XP")
		MXPV.CurrentLevel = MXPV.GetUnit("Level")
		MXPV.CurrentMaxXP = MXPV.GetUnit("XPMax")
		MXPV.lastXPGainTime = GetGameTimeMilliseconds()
		MXPV.fadeXPCountdown = true

		-- Add XP to pool & update pack
		MXPV.XPGainPool = MXPV.XPGainPool + XPGain
		MXPV.XPGainPack = MXPV.XPGainPack + 1

		-- Display XP gain
		if MXPV.SavedVars.fadeXPGainDelay ~= 0 then MXPV.UpdateProgressbar(true)
		else MXPV.UpdateProgressbar(false) end

		-- Update Meter
		if reason == 0 or reason == 9 or reason == 24 then MXPV.Meter.CurrentXPGain = MXPV.Meter.InsertIntoBuffer(XPGain) end
		MXPV.Meter.XPGains = MXPV.Meter.XPGains + XPGain
		if MXPV.Meter.Paused then MXPV.Meter.Update() end

		-- Console mode
		if MXPV.SavedVars.ConsoleMode then d(string.format("You gained %d XP", XPGain)) end
	end

end

-- RP
function MXPV.RPUpdate (alliancePoints, playSound, difference)

	-- Check if we gained RP
	if MXPV.GetUnit("RP") - MXPV.CurrentRP > 0 or MXPV.GetUnit("Rank") > MXPV.CurrentRank then

		-- Calculate RP Gain
		local RPGain = -1
		if MXPV.GetUnit("RP") - MXPV.CurrentRP > 0 then RPGain = MXPV.GetUnit("RP") - MXPV.CurrentRP end
		--if MXPV.GetUnit("Rank") > MXPV.CurrentRank then RPGain = MXPV.CurrentMaxRP - MXPV.CurrentRP + MXPV.GetUnit("RP") end

		-- Update our vars
		MXPV.IsVeteran = IsUnitVeteran("player")
		MXPV.CurrentRP = MXPV.GetUnit("RP")
		MXPV.CurrentRank = MXPV.GetUnit("Rank")
		MXPV.CurrentMaxRP = MXPV.GetUnit("RPMax")
		MXPV.lastRPGainTime = GetGameTimeMilliseconds()
		MXPV.fadeRPCountdown = true

		-- Add RP to pool & update pack
		MXPV.RPGainPool = MXPV.RPGainPool + RPGain
		MXPV.RPGainPack = MXPV.RPGainPack + 1

		-- Display RP gain
		if MXPV.SavedVars.fadeXPGainDelay ~= 0 then MXPV.UpdateProgressbar(true)
		else MXPV.UpdateProgressbar(false) end

		-- Update Meter
		MXPV.Meter.CurrentRPGain = MXPV.Meter.InsertIntoRPBuffer(RPGain)
		MXPV.Meter.RPGains = MXPV.Meter.RPGains + RPGain
		if MXPV.Meter.Paused then MXPV.Meter.Update() end

		-- Console mode
		if MXPV.SavedVars.ConsoleMode then d(string.format("You gained %d RP", RPGain)) end
	end

end

-- Updating progress bar visuals
function MXPV.UpdateProgressbar (gainMode)

	-- Progress %
	local progressPercent
	if MXPV.SavedVars.XPMode then progressPercent = MXPV.CurrentXP / MXPV.CurrentMaxXP * 100 end
	if MXPV.SavedVars.RPMode and MXPV.CurrentRank == 0 then progressPercent = MXPV.CurrentRP / MXPV.CurrentMaxRP * 100 end
	if MXPV.SavedVars.RPMode and MXPV.CurrentRank > 0 then progressPercent = (MXPV.CurrentRP - GetNumPointsNeededForAvARank(MXPV.CurrentRank - 1)) / (MXPV.CurrentMaxRP - GetNumPointsNeededForAvARank(MXPV.CurrentRank - 1)) * 100 end

	if gainMode then

		-- Progress % before gain
		local progressPercentBefore
		if MXPV.SavedVars.XPMode then progressPercentBefore = MXPV.BeforeGainXP / MXPV.BeforeGainMaxXP * 100 end
		if MXPV.SavedVars.RPMode and MXPV.CurrentRank == 0 then progressPercentBefore = MXPV.BeforeGainRP / MXPV.BeforeGainMaxRP * 100 end
		if MXPV.SavedVars.RPMode and MXPV.CurrentRank > 0 then progressPercentBefore = (MXPV.BeforeGainRP - GetNumPointsNeededForAvARank(MXPV.BeforeGainRank)) / (MXPV.BeforeGainMaxRP - GetNumPointsNeededForAvARank(MXPV.BeforeGainRank)) * 100 end

		-- Display gain bar
		local GainPercent
		if MXPV.SavedVars.XPMode then GainPercent = MXPV.XPGainPool / MXPV.BeforeGainMaxXP * 100 end
		if MXPV.SavedVars.RPMode and MXPV.CurrentRank == 0 then GainPercent = MXPV.RPGainPool / MXPV.BeforeGainMaxRP * 100 end
		if MXPV.SavedVars.RPMode and MXPV.CurrentRank > 0 then GainPercent = MXPV.RPGainPool / (MXPV.BeforeGainMaxRP - GetNumPointsNeededForAvARank(MXPV.BeforeGainRank)) * 100 end

		if progressPercentBefore + GainPercent > 100 then GainPercent = 100 - progressPercentBefore end
		local offsetX = MXPV.XPBarWidth * progressPercentBefore / 100 + 4

		MXPV_XP_PROGRESSBAR_GAIN:SetAnchor (BOTTOMLEFT, parent, BOTTOMLEFT, offsetX, -4)
		MXPV_XP_PROGRESSBAR_GAIN:SetValue (GainPercent)
		MXPV_XP_PROGRESSBAR_GAIN:SetHidden (false)

		-- Display gain text
		local XPGainText, RPGainText, Separator

		if MXPV.XPGainPack > 0 and MXPV.RPGainPack > 0 then Separator = " & " else Separator = "" end

		if MXPV.XPGainPack == 0 then XPGainText = "" end
		if MXPV.XPGainPack == 1 then XPGainText = string.format("%d XP", MXPV.XPGainPool) end
		if MXPV.XPGainPack > 1 then XPGainText = string.format("%d XP (+%d)", MXPV.XPGainPool, MXPV.XPGainPack - 1) end

		if MXPV.RPGainPack == 0 then RPGainText = "" end
		if MXPV.RPGainPack == 1 then RPGainText = string.format("%d RP", MXPV.RPGainPool) end
		if MXPV.RPGainPack > 1 then RPGainText = string.format("%d RP (+%d)", MXPV.RPGainPool, MXPV.RPGainPack - 1) end

		MXPV_XP_LABEL:SetText("You gained " .. XPGainText .. Separator .. RPGainText)

		--if MXPV.XPGainPack == 1 then MXPV_XP_LABEL:SetText (string.format("You gained %d XP", MXPV.XPGainPool)) end
		--if MXPV.XPGainPack > 1 then MXPV_XP_LABEL:SetText (string.format("You gained %d XP (+%d)", MXPV.XPGainPool, MXPV.XPGainPack - 1)) end

	else
		-- Set XP bar progress
		MXPV_XP_PROGRESSBAR:SetValue(progressPercent)

		-- Set XP bar text
		local LvlOrVrOrCP
		if MXPV.IsVeteran and MXPV.IsChampion then LvlOrVrOrCP = "CP"
		elseif MXPV.IsVeteran then LvlOrVrOrCP = "VR"
		else LvlOrVrOrCP = "Lvl" end
		if MXPV.SavedVars.XPMode then MXPV_XP_LABEL:SetText (LvlOrVrOrCP .. " " .. MXPV.CurrentLevel .. "  " .. string.format("%d / %d XP  [%d", MXPV.CurrentXP, MXPV.CurrentMaxXP, progressPercent) .. "%]") end
		if MXPV.SavedVars.RPMode then MXPV_XP_LABEL:SetText ("Rank " .. MXPV.CurrentRank .. "  " .. string.format("%d / %d RP  [%d", MXPV.CurrentRP, MXPV.CurrentMaxRP, progressPercent) .. "%]") end
	end

end

-- Pausing Meter
function MXPV.Meter.Pause()
	MXPV.Meter.TimeElapsed = MXPV.Meter.TimeElapsed + GetGameTimeMilliseconds() - MXPV.Meter.InitTime
	MXPV.Log("MXPV.Meter.TimeElapsed = " .. MXPV.Meter.TimeElapsed)
	MXPV.Meter.Paused = true
end

-- Starting Meter
function MXPV.Meter.Start()
	MXPV.Meter.InitTime = GetGameTimeMilliseconds()
	MXPV.Log("MXPV.Meter.InitTime = " .. MXPV.Meter.InitTime)
	MXPV.Meter.Paused = false
end

-- Updating meter
function MXPV.Meter.Update()

	-- Meter vars
	local RateFactor, TimeElapsed
	local XPLeft = MXPV.CurrentMaxXP - MXPV.CurrentXP
	local RPLeft = MXPV.CurrentMaxRP - MXPV.CurrentRP

	-- Rate factor
	if MXPV.SavedVars.CombatOnly then RateFactor = MXPV.SavedVars.RateFactor else RateFactor = 1 end

	-- Time elapsed
	if not MXPV.Meter.Paused then TimeElapsed = (MXPV.Meter.TimeElapsed + GetGameTimeMilliseconds() - MXPV.Meter.InitTime) / 1000
	else TimeElapsed = MXPV.Meter.TimeElapsed / 1000 end

	local HoursElapsed = math.floor(TimeElapsed / 3600)
	local MinutesElapsed = math.floor((TimeElapsed - HoursElapsed * 3600) / 60)
	local SecondsElapsed = TimeElapsed % 60

	-- XP rates
	if TimeElapsed == 0 then MXPV.Meter.XPPerHour = 0 else MXPV.Meter.XPPerHour = math.floor(RateFactor * (3600 / TimeElapsed * MXPV.Meter.XPGains)) end
	MXPV.Meter.PercentXPPerHour = math.floor(MXPV.Meter.XPPerHour / MXPV.CurrentMaxXP * 100)

	-- RP rates
	if TimeElapsed == 0 then MXPV.Meter.RPPerHour = 0 else MXPV.Meter.RPPerHour = math.floor(RateFactor * (3600 / TimeElapsed * MXPV.Meter.RPGains)) end
	MXPV.Meter.PercentRPPerHour = math.floor(MXPV.Meter.RPPerHour / (MXPV.CurrentMaxRP - GetNumPointsNeededForAvARank(MXPV.BeforeGainRank)) * 100)

	-- XP time left
	if MXPV.Meter.XPGains == 0 then MXPV.Meter.XPTimeLeft = 0 else MXPV.Meter.XPTimeLeft = TimeElapsed / MXPV.Meter.XPGains * XPLeft / RateFactor end

	MXPV.Meter.XPHoursLeft = math.floor(MXPV.Meter.XPTimeLeft / 3600)
	MXPV.Meter.XPMinutesLeft = math.floor((MXPV.Meter.XPTimeLeft - 3600 * MXPV.Meter.XPHoursLeft) / 60)
	MXPV.Meter.XPSecondsLeft = MXPV.Meter.XPTimeLeft % 60

	-- RP time left
	if MXPV.Meter.RPGains == 0 then MXPV.Meter.RPTimeLeft = 0 else MXPV.Meter.RPTimeLeft = TimeElapsed / MXPV.Meter.RPGains * RPLeft / RateFactor end

	MXPV.Meter.RPHoursLeft = math.floor(MXPV.Meter.RPTimeLeft / 3600)
	MXPV.Meter.RPMinutesLeft = math.floor((MXPV.Meter.RPTimeLeft - 3600 * MXPV.Meter.RPHoursLeft) / 60)
	MXPV.Meter.RPSecondsLeft = MXPV.Meter.RPTimeLeft % 60

	-- Mobs left
	if MXPV.Meter.CurrentXPGain == 0 then MXPV.Meter.MobsLeft = 0 else MXPV.Meter.MobsLeft =  math.floor(XPLeft / MXPV.Meter.GetBufferAvg()) end

	-- Kills left
	if MXPV.Meter.CurrentRPGain == 0 then MXPV.Meter.KillsLeft = 0 else MXPV.Meter.KillsLeft =  math.floor(RPLeft / MXPV.Meter.GetRPBufferAvg()) end

	-- Update UI
	local MeterText

	if MXPV.SavedVars.XPMode then MeterText = ' Time : ' .. string.format("%02d", HoursElapsed) .. ':' .. string.format("%02d", MinutesElapsed) .. ':' .. string.format("%02d", SecondsElapsed) .. ' - |cffff00' .. MXPV.Meter.XPGains .. ' XP|r gained\n' end
	if MXPV.SavedVars.RPMode then MeterText = ' Time : ' .. string.format("%02d", HoursElapsed) .. ':' .. string.format("%02d", MinutesElapsed) .. ':' .. string.format("%02d", SecondsElapsed) .. ' - |cffff00' .. MXPV.Meter.RPGains .. ' RP|r gained\n' end

	if MXPV.SavedVars.XPMode then MeterText = MeterText .. 'XP rate : |cffff00' .. MXPV.Meter.XPPerHour .. ' XP|r/hour (|cffff00' .. MXPV.Meter.PercentXPPerHour .. '%|r) = |cff1111' .. MXPV.Meter.MobsLeft .. ' mobs|r left\n' end
	if MXPV.SavedVars.RPMode then MeterText = MeterText .. 'RP rate : |cffff00' .. MXPV.Meter.RPPerHour .. ' RP|r/hour (|cffff00' .. MXPV.Meter.PercentRPPerHour .. '%|r) = |cff1111' .. MXPV.Meter.KillsLeft .. ' kills|r left\n' end

	if MXPV.SavedVars.XPMode then MeterText = MeterText .. 'Next level in approx. : |c9999ff' .. string.format("%02d", MXPV.Meter.XPHoursLeft) .. ':' .. string.format("%02d", MXPV.Meter.XPMinutesLeft) .. ':' .. string.format("%02d", MXPV.Meter.XPSecondsLeft) .. '|r' end
	if MXPV.SavedVars.RPMode then MeterText = MeterText .. 'Next rank in approx. : |c9999ff' .. string.format("%02d", MXPV.Meter.RPHoursLeft) .. ':' .. string.format("%02d", MXPV.Meter.RPMinutesLeft) .. ':' .. string.format("%02d", MXPV.Meter.RPSecondsLeft) .. '|r' end

	MXPV_METER_LABEL:SetText(MeterText)

end

-- Reset meter
function MXPV.Meter.Reset()
	MXPV.Meter.InitTime = GetGameTimeMilliseconds()
	MXPV.Meter.TimeElapsed = 0
	MXPV.Meter.XPTimeLeft = 0
	MXPV.Meter.XPGains = 0
	MXPV.Meter.CurrentXPGain = 0
	MXPV.Meter.Buffer = {}
	MXPV.Meter.MobsLeft = 0
	MXPV.Meter.XPPerHour = 0
	MXPV.Meter.XPHoursLeft = 0
	MXPV.Meter.XPMinutesLeft = 0
	MXPV.Meter.XPSecondsLeft = 0
	MXPV.Meter.Update()

	-- Notify
	d("MyXpView v" .. MXPV.version .. " : xp meter reseted")

end

function MXPV.Meter.InsertIntoBuffer (item)
	table.insert(MXPV.Meter.Buffer, 1, item)
	while #MXPV.Meter.Buffer > MXPV.Meter.BufferSize do
		table.remove(MXPV.Meter.Buffer, #MXPV.Meter.Buffer)
	end
	return lolmode or item
end

function MXPV.Meter.InsertIntoRPBuffer (item)
	table.insert(MXPV.Meter.RPBuffer, 1, item)
	while #MXPV.Meter.RPBuffer > MXPV.Meter.BufferSize do
		table.remove(MXPV.Meter.RPBuffer, #MXPV.Meter.RPBuffer)
	end
	return lolmode or item
end

function MXPV.Meter.GetBufferAvg ()
	local sum = 0
	for index, item in ipairs(MXPV.Meter.Buffer) do
		sum = sum + item
	end

	return sum / #MXPV.Meter.Buffer
end

function MXPV.Meter.GetRPBufferAvg ()
	local sum = 0
	for index, item in ipairs(MXPV.Meter.RPBuffer) do
		sum = sum + item
	end

	return sum / #MXPV.Meter.RPBuffer
end

-- Setting XP gain UI message fade delay
function MXPV.SetFadeXPGainDelay(fadevalue, silent)

	-- Set fade value
	MXPV.SavedVars.fadeXPGainDelay = tonumber(fadevalue)

	-- Notify
	if not silent then d("MyXpView v" .. MXPV.version .. " : fade delay now set to " .. MXPV.SavedVars.fadeXPGainDelay) end

end

-- Setting rate factor
function MXPV.SetRateFactor (rateFactor, silent)

	-- If rateFactor is > 1 then set it to 1
	local cleanValue = 0
	if tonumber(rateFactor) > 1 then cleanValue = 1 else cleanValue = tonumber(rateFactor) end

	-- Set rate factor value
	MXPV.SavedVars.RateFactor = tonumber(cleanValue)

	-- Update visuals if meter is paused
	if MXPV.Meter.Paused then
		MXPV.Meter.Update()
	end

	-- Notify
	if not silent then d("MyXpView v" .. MXPV.version .. " : rate factor now set to " .. MXPV.SavedVars.RateFactor) end

end

-- Setting console mode
function MXPV.ToggleConsole(mode)

	-- Set console mode
	MXPV.SavedVars.ConsoleMode = mode

	-- Notify
	d("MyXpView v" .. MXPV.version .. " : console mode now set to " .. tostring(MXPV.SavedVars.ConsoleMode))

end

-- Hide / Unhide UI
function MXPV.ToggleUI (mode, notify)

	MXPVUI:SetHidden(not mode)
	MXPV.SavedVars.UIMode = mode

	-- Notify
	if notify then d("MyXpView v" .. MXPV.version .. " : UI mode now set to " .. tostring(MXPV.SavedVars.UIMode)) end

end

-- Hide / Unhide XP progress bar
function MXPV.ToggleXPBar (mode)

	MXPV_XP_CONTAINER:SetHidden(not mode)
	MXPV_XP_PROGRESSBAR:SetHidden(not mode)
	MXPV_XP_LABEL:SetHidden(not mode)
	MXPV.SavedVars.XPBarMode = mode

	-- Notify
	d("MyXpView v" .. MXPV.version .. " : XP bar mode now set to " .. tostring(MXPV.SavedVars.XPBarMode))

end

-- Hide / Unhide XP meter
function MXPV.ToggleMeter (mode)

	MXPV.SavedVars.MeterMode = mode
	MXPV_METER_LABEL:SetHidden(not mode)

	-- Notify
	d("MyXpView v" .. MXPV.version .. " : meter now set to " .. tostring(MXPV.SavedVars.MeterMode))

end

-- Combat only meter update
function MXPV.ToggleCombatOnly (mode)

	MXPV.SavedVars.CombatOnly = mode
	if not MXPV.SavedVars.CombatOnly then MXPV.Meter.Start()
	elseif not MXPV.CombatState then MXPV.Meter.Pause() end

	-- Notify
	d("MyXpView v" .. MXPV.version .. " : combatonly now set to " .. tostring(MXPV.SavedVars.CombatOnly))

end

-- Autoswitch toggle
function MXPV.ToggleAutoSwitch (mode)

	MXPV.SavedVars.AutoSwitch = mode

	-- Notify
	d("MyXpView v" .. MXPV.version .. " : autoswitch now set to " .. tostring(MXPV.SavedVars.AutoSwitch))

end

-- Debug toggle
function MXPV.ToggleDebug (mode)

	if mode then
		MXPV.debug = true
		MXPVUI_DEBUG:SetHidden(false)
	else
		MXPV.debug = false
		MXPVUI_DEBUG:SetHidden(true)
	end

end

-- Tracking switch
function MXPV.SwitchTracking (arg, silent)

	-- Set values
	if arg == 'XP tracking' then MXPV.SavedVars.XPMode = true end
	if arg == 'XP tracking' then MXPV.SavedVars.RPMode = false end
	if arg == 'RP tracking' then MXPV.SavedVars.XPMode = false end
	if arg == 'RP tracking' then MXPV.SavedVars.RPMode = true end

	-- Switch values
	if arg == nil then MXPV.SavedVars.XPMode = not MXPV.SavedVars.XPMode end
	if arg == nil then MXPV.SavedVars.RPMode = not MXPV.SavedVars.RPMode end

	-- Update meter if paused
	if MXPV.Meter.Paused then
		MXPV.Meter.Update()
	end

	-- Update progress bar
	if MXPV.fadeXPCountdown or MXPV.fadeRPCountdown then MXPV.UpdateProgressbar(true)
	else MXPV.UpdateProgressbar(false) end

	-- Notify
	if not silent and MXPV.SavedVars.XPMode then d("MyXpView v" .. MXPV.version .. " : now tracking XP") end
	if not silent and MXPV.SavedVars.RPMode then d("MyXpView v" .. MXPV.version .. " : now tracking RP") end

end

-- Get tracking switch value
function MXPV.GetTrackingValue ()
	if MXPV.SavedVars.XPMode then return "XP tracking" end
	if MXPV.SavedVars.RPMode then return "RP tracking" end
end

-- UI scaling
function MXPV.SetScale (scaleFactor)

	-- If rateFactor is > 1 then set it to 1
	local cleanValue = 0
	if tonumber(scaleFactor) > 1 then cleanValue = 1 else cleanValue = tonumber(scaleFactor) end

	-- Set scale factor value
	MXPV.SavedVars.ScaleFactor = tonumber(cleanValue)

	-- Update visuals
	MXPVUI:SetScale(MXPV.SavedVars.ScaleFactor)

end

-- String split
function MXPV.SplitCommand(command)

	-- Search for white-space indexes
	local chunk = command
	local index = string.find(command, " ")
	if index == nil then return {command, nil} end

	-- Iterate our command for white-space indexes
	local explode = {}
	local n = 1
	while index ~= nil do
		explode[n] = string.sub(chunk, 1, index - 1)
		chunk = string.sub(chunk, index + 1, #chunk)
		index = string.find(chunk, " ")
		n = n + 1
	end

	-- Add chunk after last white-space
	explode[n] = chunk

	return {explode[1], explode[2]}
end

-- Help command
function MXPV.GetHelpString()
	local helpString = "\n MyXpView v" .. MXPV.version .. " - Usable commands : \n\n "
	helpString = helpString .. "- 'toggle' : enable/disable MyXpView UI globally \n "
	helpString = helpString .. "- 'xpbar' : enable/disable XP bar display \n "
	helpString = helpString .. "- 'meter' : enable/disable the XP meter UI \n "
	helpString = helpString .. "- 'reset' : resets the XP meter \n "
	helpString = helpString .. "- 'fade x' : sets the XP gain display & pool duration (can be set to '0' to disable) \n "
	helpString = helpString .. "- 'rf x' : sets the XP rate factor (maximum 1 - only used in 'combatonly' mode) \n "
	helpString = helpString .. "- 'console' : enable/disable XP logs in chat window \n "
	helpString = helpString .. "- 'combatonly' : enable/disable XP meter updating only when in combat \n "
	helpString = helpString .. "- 'switch' : switch between XP and RP tracking \n "
	helpString = helpString .. "- 'autoswitch' : auto-switch between XP and RP tracking \n "
	helpString = helpString .. "- 'scale' : scales the UI size - from 0 to 1 \n "
	helpString = helpString .. "- 'dump' : dumps a few variables and options \n "
	return helpString
end

-- Dump
function MXPV.Dump()
	d(string.format("MXPV.CurrentLevel : %d", MXPV.CurrentLevel))
	d(string.format("MXPV.CurrentXP : %d", MXPV.CurrentXP))
	d(string.format("MXPV.CurrentMaxXP : %d", MXPV.CurrentMaxXP))
	d(string.format("MXPV.CurrentRank : %d", MXPV.CurrentRank))
	d(string.format("MXPV.CurrentRP : %d", MXPV.CurrentRP))
	d(string.format("MXPV.CurrentMaxRP : %d", MXPV.CurrentMaxRP))
	d(string.format("MXPV.SavedVars.UIMode : %s", tostring(MXPV.SavedVars.UIMode)))
	d(string.format("MXPV.SavedVars.XPBarMode : %s", tostring(MXPV.SavedVars.XPBarMode)))
	d(string.format("MXPV.SavedVars.MeterMode : %s", tostring(MXPV.SavedVars.MeterMode)))
	d(string.format("MXPV.SavedVars.ConsoleMode : %s", tostring(MXPV.SavedVars.ConsoleMode)))
	d(string.format("MXPV.SavedVars.CombatOnly : %s", tostring(MXPV.SavedVars.CombatOnly)))
	d(string.format("MXPV.SavedVars.XPMode : %s", tostring(MXPV.SavedVars.XPMode)))
	d(string.format("MXPV.SavedVars.RPMode : %s", tostring(MXPV.SavedVars.RPMode)))
	d(string.format("MXPV.SavedVars.AutoSwitch : %s", tostring(MXPV.SavedVars.AutoSwitch)))
	d(string.format("MXPV.SavedVars.fadeXPGainDelay : %d", MXPV.SavedVars.fadeXPGainDelay))
	d(string.format("MXPV.SavedVars.RateFactor : %f", MXPV.SavedVars.RateFactor))
end

function MXPV.SlashCommands(text)

	local command = MXPV.SplitCommand(text)
	local trigger = command[1]

	if (trigger == "?") then d(MXPV.GetHelpString())
	elseif (trigger == "toggle") then MXPV.ToggleUI(not MXPV.SavedVars.UIMode, true)
	elseif (trigger == "xpbar") then MXPV.ToggleXPBar(not MXPV.SavedVars.XPBarMode)
	elseif (trigger == "meter") then MXPV.ToggleMeter(not MXPV.SavedVars.MeterMode)
	elseif (trigger == "reset") then MXPV.Meter.Reset()
	elseif (trigger == "console") then MXPV.ToggleConsole(not MXPV.SavedVars.ConsoleMode)
	elseif (trigger == "combatonly") then MXPV.ToggleCombatOnly(not MXPV.SavedVars.CombatOnly)
	elseif (trigger == "autoswitch") then MXPV.ToggleAutoSwitch(not MXPV.SavedVars.AutoSwitch)
	elseif (trigger == "fade") then
		local fadevalue = command[2]
		if tonumber(fadevalue) ~= nil then
			MXPV.SetFadeXPGainDelay(fadevalue)
		else d("MyXpView " .. MXPV.version .. " : wrong input value for 'fade x' - please insert a number.") end
	elseif (trigger == "rf") then
		local ratefactor = command[2]
		if tonumber(ratefactor) ~= nil then
			MXPV.SetRateFactor(ratefactor)
		else d("MyXpView " .. MXPV.version .. " : wrong input value for 'rf x' - please insert a number.") end
	elseif (trigger == "scale") then
		local scalefactor = command[2]
		if tonumber(scalefactor) ~= nil then
			MXPV.SetScale(scalefactor)
		else d("MyXpView " .. MXPV.version .. " : wrong input value for 'scale x' - please insert a number.") end
	elseif (trigger == "dump") then MXPV.Dump()
	elseif (trigger == 'debug') then MXPV.ToggleDebug(not MXPV.debug)
	elseif (trigger == 'pause') then --experimental
		if not MXPV.Meter.Paused then
			MXPV.Meter.Pause()
			d("MyXpView " .. MXPV.version .. " : meter paused.")
		end
	elseif (trigger == 'start') then --experimental
		if MXPV.Meter.Paused then
			MXPV.Meter.Start()
			d("MyXpView " .. MXPV.version .. " : meter started.")
		end
	elseif (trigger == "switch") then MXPV.SwitchTracking(nil, false)
	elseif (trigger == "scale") then MXPV.SwitchSize("big")
	else d("MyXpView v" .. MXPV.version .. " : No input or wrong command. Type '" .. MXPV.command .. " ?' for help.") end

end

-- Hook initialization onto the ADD_ON_LOADED event
EVENT_MANAGER:RegisterForEvent(MXPV.name, EVENT_ADD_ON_LOADED, MXPV.Initialize)
