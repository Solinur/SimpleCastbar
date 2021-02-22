local em = GetEventManager()
local _
local getms = GetGameTimeMilliseconds
local TimerBar
local offset = 15
local dx = 1 / (tonumber(GetCVar("WindowedWidth")) / GuiRoot:GetWidth())
SIMPLE_CASTBAR_LINE_SIZE = tostring(dx)

SCB = SCB or {}
local SCB = SCB

SCB.name = "SimpleCastbar"
SCB.version = 1.2

local LC = LibCombat
if not LibCombat then return end

local LCdata = LibCombat.data

local GetFormattedAbilityName = LC.GetFormattedAbilityName
local GetFormattedAbilityIcon = LC.GetFormattedAbilityIcon

local dev = false -- or GetDisplayName() == "@Solinur"

local function Print(message, ...)

    if not dev then return end

    df("[%s] %s", "SCB", message:format(...))

end

local abilityDelay = {	-- Radiant Destruction and morphs have a 100ms delay after casting. 50ms for Jabs
    [63044] = 100,
    [63029] = 100,
    [63046] = 100,
    [26797] = 50,
    [38857] = 200
}

local ignoredAbilities = {	-- for stuff that's off the GCD

    [132141] = true,    -- Blood Frenzy (Vampire Toggle)
    [134160] = true,    -- Simmering Frenzy (Vampire Toggle)
    [135841] = true,    -- Sated Fury (Vampire Toggle)

}

local lastSlotUses = {}

for i = 3,8 do

    lastSlotUses[i] = 0
    lastSlotUses[i+10] = 0

end

local lastQueuedAbilities = {}

local red = ZO_ColorDef:New(1, 0, 0)
local green = ZO_ColorDef:New(0, 0.95, 0.1)
local yellow = ZO_ColorDef:New(1, 1, 0)
local grey = ZO_ColorDef:New(.4, .4, .4)

local isLastAttackLightAttack = false
local lastSkillEnd = 0
local secondLastSkillEnd = 0

local function OnSkillEvent(_, timems, reducedslot, abilityId, status)

    TimerBarcontrol = TimerBar.control
    local barControl = TimerBarcontrol:GetNamedChild("Status")
    local slot = reducedslot % 10

    if status == LIBCOMBAT_SKILLSTATUS_REGISTERED then

        lastSlotUses[reducedslot] = timems

        local lineControl = TimerBarcontrol:GetNamedChild(slot == 1 and "LineLA" or "LineSkill")

        local pos = barControl:GetValue() * barControl:GetWidth()

        lineControl:ClearAnchors()
        lineControl:SetAnchor(TOP, barControl, TOPLEFT, pos)
        lineControl:SetAnchor(BOTTOM, barControl, BOTTOMLEFT, pos)
        lineControl:SetAlpha(1)

        return

    elseif status == LIBCOMBAT_SKILLSTATUS_QUEUE then

        lastQueuedAbilities[abilityId] = timems
        return

    end

    -- local timems = timems - GetLatency() + offset

    local lineControl = TimerBarcontrol:GetNamedChild("LineDelay")

    if slot == 1 then

        isLastAttackLightAttack = true
        --[[
        if timems + 300 < lastSkillEnd then

            local LAtime = timems - secondLastSkillEnd
            local color = LAtime < 80 and green or yellow

            lineControl:SetHidden(false)
            lineControl:SetColor(color:UnpackRGB())
        else
            lineControl:SetColor(grey:UnpackRGB())
        end--]]
    else

        local abilityName = GetFormattedAbilityName(abilityId)

        local duration = 1000

        if status == LIBCOMBAT_SKILLSTATUS_BEGIN_DURATION or status == LIBCOMBAT_SKILLSTATUS_BEGIN_CHANNEL then

            local channeled, castTime, channelTime = GetAbilityCastInfo(abilityId)

            duration = math.max(channeled and channelTime or castTime, 1000)

            duration = duration + (abilityDelay[abilityId] or 0) + GetLatency()/2

        end

        local endTime = timems + duration

        TimerBar:SetLabel(abilityName)

        TimerBarcontrol:GetNamedChild("Icon"):SetTexture(GetFormattedAbilityIcon(abilityId))

        if status == LIBCOMBAT_SKILLSTATUS_SUCCESS then

            -- TimerBar:Stop()

            Print("%s ends", abilityName)

            return

        elseif status <= 4 then

            TimerBar:Start(timems / 1000, endTime / 1000)

            Print("%s starts", abilityName)

            local LAline = TimerBarcontrol:GetNamedChild("LineLA")
            local SkillLine = TimerBarcontrol:GetNamedChild("LineSkill")

            if LAline:GetAlpha() < 0.9 then LAline:SetAlpha(0) else LAline:SetAlpha(0.8) end
            if SkillLine:GetAlpha() < 0.9 then SkillLine:SetAlpha(0) else SkillLine:SetAlpha(0.8) end

        end

        local useTime = math.max(lastSlotUses[reducedslot], lastQueuedAbilities[abilityId] or 0)

        local offsetTime = useTime and (useTime + duration) or endTime

        if offsetTime > (timems+300) then

            local relPos = math.min(math.max((offsetTime - timems)/(endTime - timems),0),1)

            local LAtime = timems - lastSkillEnd
            local color = isLastAttackLightAttack and (LAtime < 80 and green or yellow) or red

            local pos = barControl:GetWidth() * relPos

            lineControl:ClearAnchors()
            lineControl:SetAnchor(TOP, barControl, TOPLEFT, pos)
            lineControl:SetAnchor(BOTTOM, barControl, BOTTOMLEFT, pos)
            lineControl:SetHidden(false)
            TimerBarcontrol:GetNamedChild("Backdrop"):SetEdgeColor(color:UnpackRGB())

        else

            TimerBarcontrol:GetNamedChild("LineDelay"):SetHidden(true)

        end

        isLastAttackLightAttack = false
        secondLastSkillEnd = lastSkillEnd
        lastSkillEnd = endTime

    end
end

local remainingUntilUpdate

local function TimerBarUpdate(self, time) -- rewrite of original function from ZOS

    if time > self.ends then

        self:Stop()
        return

    end

    local barReady = time > self.nextBarUpdate
    local labelReady = self.time and time > self.nextLabelUpdate

    if not (barReady or labelReady) then return end

    local timeString = ""

    if self.direction == TIMER_BAR_COUNTS_UP then

        local totalElapsed = time - self.starts - self.pauseElapsed

        if barReady then self.status:SetValue(totalElapsed) end

        if labelReady then

            timeString, remainingUntilUpdate =
                ZO_FormatTime(totalElapsed, self.timeFormatStyle,
                              self.timePrecision,
                              TIME_FORMAT_DIRECTION_ASCENDING)
            self.time:SetText(timeString)

        end

    else

        local totalRemaining = self.ends - time

        if barReady then self.status:SetValue(totalRemaining) end

        local totalRemainingRounded = zo_roundToNearest(totalRemaining, 0.1)

        if labelReady then

            timeString, remainingUntilUpdate =
                ZO_FormatTime(totalRemainingRounded, self.timeFormatStyle,
                              self.timePrecision,
                              TIME_FORMAT_DIRECTION_DESCENDING)
            self.time:SetText(timeString)

        end

    end

    if barReady then self.nextBarUpdate = time + self.barUpdateInterval end

    if labelReady then self.nextLabelUpdate = math.ceil(time * 10) / 10 end
end

local function Initialize(event, addon)

    if addon ~= SCB.name then return end

    LC:RegisterForCombatEvent(SCB.name, LIBCOMBAT_EVENT_SKILL_TIMINGS, OnSkillEvent)

    TimerBar = ZO_TimerBar:New(SimpleCastbar_TLW)
    TimerBar:SetTimeFormatParameters(
        TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL_SHOW_TENTHS_SECS,
        TIME_FORMAT_PRECISION_MILLISECONDS)
    TimerBar.Update = TimerBarUpdate

    local function showTimerBar()

        TimerBar.control:SetHidden(false)

    end

    showTimerBar()

    SLASH_COMMANDS["/scb"] = showTimerBar

    em:AddFilterForEvent(SCB.name, EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_QUEUED)
    em:UnregisterForEvent(SCB.name, EVENT_ADD_ON_LOADED)
end

em:RegisterForEvent(SCB.name, EVENT_ADD_ON_LOADED, Initialize)
