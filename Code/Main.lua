-- find text element by ID
---
--- Finds an object in a hierarchy by the text ID of its `Text` field.
---
--- @param obj table The root object to search.
--- @param id string The ID of the text element to find.
--- @return table|nil The object with the matching text ID, or `nil` if not found.
function audaFindXtByTextId(obj, id)
    if obj.Text and TGetID(obj.Text) == id then
        return obj
    end
    for _, sub in ipairs(obj) do
        local match = audaFindXtByTextId(sub, id)
        if match then
            return match
        end
    end
end


function CompleteCurrentTrainMercs(sector, mercs)
    NetUpdateHash("CompleteCurrentTrainMercs")
    local eventId = g_MilitiaTrainingCompleteCounter
    g_TrainMercsCompleteCounter = g_TrainMercsCompleteCounter + 1
    local start_time = Game.CampaignTime
    CreateMapRealTimeThread(function()
        sector.merc_training = false
        
        local students = GetOperationProfessionals(sector.Id, self.id, "Student")
        local teachers = GetOperationProfessionals(sector.Id, self.id, "Teacher")
        
        for _, merc in ipairs(mercs) do
            if merc.OperationProfession == "Student" then
                table.insert(students, merc)
            else
                teacher = merc
            end
        end
        
        local popupHost = GetDialog("PDADialogSatellite")
        popupHost = popupHost and popupHost:ResolveId("idDisplayPopupHost")
        
        if not teacher or #students == 0 then
            local dlg = CreateMessageBox(
                popupHost,
                T(295710973806, "Merc Training"),
                T{522643975325, "Merc training cannot proceed - no teacher or students found.<newline><GameColorD>(<sectorName>)</GameColorD>",
                    sectorName = GetSectorName(sector)}
                )
                dlg:Wait()
        else
            local cost, costTexts, names, errors = GetOperationCosts(mercs, "MercTraining", "Trainer", "refund")
            local buyAgainText = T(460261217340, "Do you want to train mercs again?")
            local costText = table.concat(costTexts, ", ")    
            local dlg = CreateQuestionBox(
                popupHost,
                T(295710973806, "Merc Training"),
                T{522643975325, "Merc training is finished - trained <merc_trained> defenders.<newline><GameColorD>(<sectorName>)</GameColorD>",
                    sectorName = GetSectorName(sector),
                    students = #students},
                T(689884995409, "Yes"),
                T(782927325160, "No"),
                { sector = sector, mercs = mercs, textLower = buyAgainText, costText = costText }, 
                function() return not next(errors) and "enabled" or "disabled" end,
                nil,
                "ZuluChoiceDialog_MilitiaTraining")
            
            assert(g_MercTrainingCompletePopups[eventId] == nil)
            g_MercTrainingCompletePopups[eventId] = dlg
            NetSyncEvent("ProcessMercTrainingPopupResults", dlg:Wait(), eventId, sector.Id, UnitDataToSessionIds(mercs), cost, start_time)
            g_MercTrainingCompletePopups[eventId] = nil
        end
    end)
end



---
--- Initializes various training actions and settings in the game.
---
--- This function sets up the following training actions and settings:
---
--- - Disarming explosives trap training: `oncePerMapVisit` is set to `false`, and the action is reloaded.
--- - Disarming mechanical trap training: `oncePerMapVisit` is set to `false`, and the action is reloaded.
--- - Resource discovery training: `oncePerMapVisit` is set to `false`, and the action is reloaded.
--- - Trap discovery training: `oncePerMapVisit` is set to `false`, and the action is reloaded.
--- - Weapon modification training: `failChance` is set to `50`, and the action is reloaded.
--- - Explosive multi-hit training: `failChance` is set to `0`, and the action is reloaded.
--- - Mercenary training: `hoursToSpend` parameter is set to `9`, and the action is reloaded.
--- - Militia training: `hoursToSpend` parameter is set to `9`, and the action is reloaded.
--- - Mechanic training: `hoursToSpend` parameter is set to `9`, and the action is reloaded.
---
--- @function initStuff
function initStuff()
    -- Setup training actions
    StatGainingPrerequisites.TrapDisarmExplosives.oncePerMapVisit = false
    StatGainingPrerequisites.TrapDisarmExplosives:PostLoad()

    StatGainingPrerequisites.TrapDisarmMechanical.oncePerMapVisit = false
    StatGainingPrerequisites.TrapDisarmMechanical:PostLoad()

    StatGainingPrerequisites.ResourceDiscovery.oncePerMapVisit = false
    StatGainingPrerequisites.ResourceDiscovery:PostLoad()

    StatGainingPrerequisites.TrapDiscovery.oncePerMapVisit = false
    StatGainingPrerequisites.TrapDiscovery:PostLoad()

    StatGainingPrerequisites.WeaponModification.failChance = 50
    StatGainingPrerequisites.WeaponModification:PostLoad()

    StatGainingPrerequisites.ExplosiveMultiHit.failChance = 0
    StatGainingPrerequisites.ExplosiveMultiHit:PostLoad()

    table.find_value(StatGainingPrerequisites.MercTraining.parameters, 'Name', 'hoursToSpend').Value = 9
    StatGainingPrerequisites.MercTraining:PostLoad()

    table.find_value(StatGainingPrerequisites.MilitiaTraining.parameters, 'Name', 'hoursToSpend').Value = 9
    StatGainingPrerequisites.MilitiaTraining:PostLoad()

    table.find_value(StatGainingPrerequisites.Mechanic.parameters, 'Name', 'hoursToSpend').Value = 9
    StatGainingPrerequisites.Mechanic:PostLoad()

end

---
--- Initializes a training action for gathering intel in the game.
---
--- This training action tracks the time spent by mercenary units with the "Spy" profession in the "GatherIntel" operation. Once the unit has spent the required number of hours, the training action is marked as gained.
---
--- @param unit table The mercenary unit performing the training action.
--- @param oldOperation table The previous operation of the unit.
--- @param newOperation table The new operation of the unit.
--- @param prevProfession string The previous profession of the unit.
--- @param interrupted boolean Whether the operation was interrupted.
---
if not StatGainingPrerequisites.GatheredIntel then
    local op = PlaceObj('StatGainingPrerequisite',
        {Comment="Finished a Scout Sector activity in the satellite view lasting <hoursToSpend>+ hours", group="Wisdom",
            id="GatheredIntel", msg_reactions={PlaceObj('MsgReaction',
                {Event="OperationChanged",
                    Handler=function(self, unit, oldOperation, newOperation, prevProfession, interrupted)
                        if IsMerc(unit) then
                            -- Track start time of training activity
                            if newOperation and newOperation.id == "GatherIntel" and unit.OperationProfession == "Spy" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                state.startTime = Game.CampaignTime
                                SetPrerequisiteState(unit, self.id, state)
                                -- Accumulate time spent at end of activity
                            elseif oldOperation and oldOperation.id == "GatherIntel" and unit.OperationProfession
                                ~= "Spy" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                if not state.startTime or state.startTime == 0 then
                                    return
                                end
                                state.timeSpent = (state.timeSpent or 0) + (Game.CampaignTime - state.startTime)
                                state.startTime = 0
                                if DivRound(state.timeSpent, const.Scale.h) >= self:ResolveValue("hoursToSpend") then
                                    SetPrerequisiteState(unit, self.id, state, "gain")
                                else
                                    SetPrerequisiteState(unit, self.id, state)
                                end
                            end
                        end
                    end, HandlerCode=function(self, unit, oldOperation, newOperation, prevProfession, interrupted)
                        if IsMerc(unit) then
                            -- Track start time of training activity
                            if newOperation and newOperation.id == "GatherIntel" and unit.OperationProfession == "Spy" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                state.startTime = Game.CampaignTime
                                SetPrerequisiteState(unit, self.id, state)
                                -- Accumulate time spent at end of activity
                            elseif oldOperation and oldOperation.id == "GatherIntel" and unit.OperationProfession
                                ~= "Spy" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                if not state.startTime or state.startTime == 0 then
                                    return
                                end
                                state.timeSpent = (state.timeSpent or 0) + (Game.CampaignTime - state.startTime)
                                state.startTime = 0
                                if DivRound(state.timeSpent, const.Scale.h) >= self:ResolveValue("hoursToSpend") then
                                    SetPrerequisiteState(unit, self.id, state, "gain")
                                else
                                    SetPrerequisiteState(unit, self.id, state)
                                end
                            end
                        end
                    end})},
            parameters={PlaceObj('PresetParamNumber', {'Name', "hoursToSpend", 'Value', 9, 'Tag', "<hoursToSpend>"})},
            relatedStat="Wisdom"})

    op:PostLoad()
end

---
--- Tracks the time spent by mercenaries performing the "HarvestJunk" operation and grants a "Mechanical" stat increase once the required time threshold is met.
---
--- @param self StatGainingPrerequisite
--- @param unit table The mercenary unit
--- @param oldOperation table The previous operation
--- @param newOperation table The new operation
--- @param prevProfession string The previous profession
--- @param interrupted boolean Whether the operation was interrupted
---
if not StatGainingPrerequisites.HarvestedJunk then
    local op = PlaceObj('StatGainingPrerequisite',
        {Comment="Finished a Scout Sector activity in the satellite view lasting <hoursToSpend>+ hours",
            group="Mechanical", id="HarvestedJunk", msg_reactions={PlaceObj('MsgReaction',
                {Event="OperationChanged",
                    Handler=function(self, unit, oldOperation, newOperation, prevProfession, interrupted)
                        if IsMerc(unit) then
                            -- Track start time of training activity
                            if newOperation and newOperation.id == "HarvestJunk" and unit.OperationProfession
                                == "Junk Harvester" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                state.startTime = Game.CampaignTime
                                SetPrerequisiteState(unit, self.id, state)
                                -- Accumulate time spent at end of activity
                            elseif oldOperation and oldOperation.id == "HarvestJunk" and unit.OperationProfession
                                ~= "Junk Harvester" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                if not state.startTime or state.startTime == 0 then
                                    return
                                end
                                state.timeSpent = (state.timeSpent or 0) + (Game.CampaignTime - state.startTime)
                                state.startTime = 0
                                if DivRound(state.timeSpent, const.Scale.h) >= self:ResolveValue("hoursToSpend") then
                                    SetPrerequisiteState(unit, self.id, state, "gain")
                                else
                                    SetPrerequisiteState(unit, self.id, state)
                                end
                            end
                        end
                    end, HandlerCode=function(self, unit, oldOperation, newOperation, prevProfession, interrupted)
                        if IsMerc(unit) then
                            -- Track start time of training activity
                            if newOperation and newOperation.id == "HarvestJunk" and unit.OperationProfession
                                == "Junk Harvester" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                state.startTime = Game.CampaignTime
                                SetPrerequisiteState(unit, self.id, state)
                                -- Accumulate time spent at end of activity
                            elseif oldOperation and oldOperation.id == "HarvestJunk" and unit.OperationProfession
                                ~= "Junk Harvester" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                if not state.startTime or state.startTime == 0 then
                                    return
                                end
                                state.timeSpent = (state.timeSpent or 0) + (Game.CampaignTime - state.startTime)
                                state.startTime = 0
                                if DivRound(state.timeSpent, const.Scale.h) >= self:ResolveValue("hoursToSpend") then
                                    SetPrerequisiteState(unit, self.id, state, "gain")
                                else
                                    SetPrerequisiteState(unit, self.id, state)
                                end
                            end
                        end
                    end})},
            parameters={PlaceObj('PresetParamNumber', {'Name', "hoursToSpend", 'Value', 9, 'Tag', "<hoursToSpend>"})},
            relatedStat="Mechanical"})

    op:PostLoad()
end

if not StatGainingPrerequisites.ScroungeOperation then
    local op = PlaceObj('StatGainingPrerequisite',
        {Comment="Gain strenght gathering junk", group="Strength", id="ScroungeOperation",
            msg_reactions={PlaceObj('MsgReaction',
                {Event="OperationChanged",
                    Handler=function(self, unit, oldOperation, newOperation, prevProfession, interrupted)
                        if IsMerc(unit) then
                            -- Track start time of training activity
                            if newOperation and newOperation.id == "Scrounge" and unit.OperationProfession
                                == "Somethingseeker" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                state.startTime = Game.CampaignTime
                                SetPrerequisiteState(unit, self.id, state)
                                -- Accumulate time spent at end of activity
                            elseif oldOperation and oldOperation.id == "Scrounge" and unit.OperationProfession
                                ~= "Somethingseeker" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                if not state.startTime or state.startTime == 0 then
                                    return
                                end
                                state.timeSpent = (state.timeSpent or 0) + (Game.CampaignTime - state.startTime)
                                state.startTime = 0
                                if DivRound(state.timeSpent, const.Scale.h) >= self:ResolveValue("hoursToSpend") then
                                    SetPrerequisiteState(unit, self.id, state, "gain")
                                else
                                    SetPrerequisiteState(unit, self.id, state)
                                end
                            end
                        end
                    end, HandlerCode=function(self, unit, oldOperation, newOperation, prevProfession, interrupted)
                        if IsMerc(unit) then
                            -- Track start time of training activity
                            if newOperation and newOperation.id == "Srounge" and unit.OperationProfession
                                == "Somethingseeker" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                state.startTime = Game.CampaignTime
                                SetPrerequisiteState(unit, self.id, state)
                                -- Accumulate time spent at end of activity
                            elseif oldOperation and oldOperation.id == "Scrounge" and unit.OperationProfession
                                ~= "Somethingseeker" then
                                local state = GetPrerequisiteState(unit, self.id) or {}
                                if not state.startTime or state.startTime == 0 then
                                    return
                                end
                                state.timeSpent = (state.timeSpent or 0) + (Game.CampaignTime - state.startTime)
                                state.startTime = 0
                                if DivRound(state.timeSpent, const.Scale.h) >= self:ResolveValue("hoursToSpend") then
                                    SetPrerequisiteState(unit, self.id, state, "gain")
                                else
                                    SetPrerequisiteState(unit, self.id, state)
                                end
                            end
                        end
                    end})},
            parameters={PlaceObj('PresetParamNumber', {'Name', "hoursToSpend", 'Value', 9, 'Tag', "<hoursToSpend>"})},
            relatedStat="Strength"})

    op:PostLoad()
end

---Unlocks the "Mechanical" stat when a mercenary unlocks a door using a lockpick.
if not StatGainingPrerequisites.DoorLockPicked then
    local op = PlaceObj('StatGainingPrerequisite',
        {Comment="Unlocked a Door with Lockpick", group="Mechanical", id="DoorLockPicked",
            msg_reactions={PlaceObj('MsgReaction', {Event="DoorUnlocked", Handler=function(self, door, unit)
                if IsMerc(unit) then
                    if door.interaction_log and #door.interaction_log >= 1
                        and door.interaction_log[#door.interaction_log].action == 'Lockpick' then
                        SetPrerequisiteState(mechanic, self.id, true, "gain")
                    end
                end
            end, HandlerCode=function(self, door, unit)
                if IsMerc(unit) then
                    if door.interaction_log and #door.interaction_log >= 1
                        and door.interaction_log[#door.interaction_log].action == 'Lockpick' then
                        SetPrerequisiteState(mechanic, self.id, true, "gain")
                    end
                end
            end})}, relatedStat="Mechanical"})

    op:PostLoad()
end

---Represents a prerequisite for gaining the "Strength" stat when a mercenary unlocks a door using a crowbar.
if not StatGainingPrerequisites.DoorLockBroken then
    local op = PlaceObj('StatGainingPrerequisite',
        {Comment="Unlocked a Door with Crowbar", group="Strength", id="DoorLockBroken",
            msg_reactions={PlaceObj('MsgReaction', {Event="DoorUnlocked", Handler=function(self, door, unit)
                if IsMerc(unit) then
                    if door.interaction_log and #door.interaction_log >= 1
                        and door.interaction_log[#door.interaction_log].action == 'Break' then
                        SetPrerequisiteState(mechanic, self.id, true, "gain")
                    end
                end
            end, HandlerCode=function(self, door, unit)
                if IsMerc(unit) then
                    if door.interaction_log and #door.interaction_log >= 1
                        and door.interaction_log[#door.interaction_log].action == 'Break' then
                        SetPrerequisiteState(mechanic, self.id, true, "gain")
                    end
                end
            end})}, relatedStat="Strength"})

    op:PostLoad()
end

AudaAto = {isKira=table.find(ModsLoaded, 'id', 'audaTest'), -- 12 hours
tickLength=12 * 60 * 60, -- sge = Stat Gaining (Points) Extra
-- sgeGainMod = "Train Boost Gain Modifier"
sgeGainMod=50, sectorTrainingStatCap=80, applyOptions=function(self)
    local s = CurrentModOptions.audaAtoSgeGainMod or '50%'
    self.sgeGainMod = tonumber(string.sub(s, 1, (string.find(s, '%%') - 1)))

    s = CurrentModOptions.audaAtoSectorTrainStatCap or '80'
    self.sectorTrainingStatCap = tonumber(string.sub(s, 1, 3))
end, --- List of all stat names used in the mod.
-- @field statNames table
-- The list of stat names that are tracked and modified by the mod.
statNames={'Health', 'Agility', 'Dexterity', 'Strength', 'Wisdom', 'Leadership', 'Marksmanship', 'Mechanical',
    'Explosives', 'Medical'}, --- List of stat names that are dependent on the Wisdom stat.
-- @field wisdomDependentStatNames table
-- The list of stat names that are affected by the Wisdom stat.
wisdomDependentStatNames={'Leadership', 'Marksmanship', 'Mechanical', 'Explosives', 'Medical'}, ---
--- Generates a random cooldown duration for a stat based on the given stat value.
---
--- @param self table The AudaAto table.
--- @param stat number The current value of the stat.
--- @param minTicks? number The minimum number of ticks for the cooldown (default is 15).
--- @param maxTicks? number The maximum number of ticks for the cooldown (default is 30).
--- @return number The calculated cooldown duration in seconds.
---
randCd=function(self, stat, minTicks, maxTicks)
    minTicks = minTicks or 15
    maxTicks = maxTicks or 30
    local cd = InteractionRandRange(minTicks * self.tickLength, maxTicks * self.tickLength, "StatCooldown")
    local cdMod = MulDivRound(Clamp(stat, 15, 99), 175, 100)
    if stat >= 90 then
        cdMod = MulDivRound(cdMod, 100 + 25 * (stat - 89), 100)
    end
    cd = MulDivRound(cd, cdMod, 100)
    return cd
end, ---
--- Generates random cooldown durations for each stat on a unit.
---
--- @param self table The AudaAto table.
--- @param unit_data table The unit data.
---
randomCooldownsToUnit=function(self, unit_data)
    local sgData = GetMercStateFlag(unit_data.session_id, "StatGaining") or {}
    if not sgData.Cooldowns then
        sgData.Cooldowns = {}
    end

    for _, statName in ipairs(self.statNames) do
        sgData.Cooldowns[statName] = Game.CampaignTime + self:randCd(unit_data[statName] or 60, 5)
    end

    SetMercStateFlag(unit_data.session_id, "StatGaining", sgData)
end}

---
--- Applies mod options, initializes stuff, and modifies operations when the mods are reloaded.
---
--- This function is called when the mods are reloaded, and it performs the following actions:
--- - Applies the mod options using the `AudaAto:applyOptions()` function.
--- - Initializes stuff using the `initStuff()` function.
--- - Modifies operations using the `modifyOperations()` function.
---
--- @function OnMsg.ModsReloaded
--- @return nil
function OnMsg.ModsReloaded()
    AudaAto:applyOptions()
    initStuff()
    modifyOperations()
end

---
--- Applies mod options, initializes stuff, and modifies operations when the mods are reloaded.
---
--- This function is called when the mods are reloaded, and it performs the following actions:
--- - Applies the mod options using the `AudaAto:applyOptions()` function.
--- - Initializes stuff using the `initStuff()` function.
--- - Modifies operations using the `modifyOperations()` function.
---
--- @function OnMsg.ModsReloaded
--- @return nil
function OnMsg.ApplyModOptions()
    AudaAto:applyOptions()
    initStuff()
    modifyOperations()
end

function RollForStatGaining(unit, stat, failChance)
    if HasPerk(unit, "OldDog") then
        return
    end

    --- Checks if the unit's stat value is within the valid range (greater than 0 and less than 100).
    ---
    --- This function is used to ensure that the unit's stat value is within the valid range before
    --- attempting to modify it. If the stat value is outside the valid range, the function will
    --- return without performing any further actions.
    ---
    --- @param unit table The unit whose stat value is being checked.
    --- @param stat string The name of the stat being checked.
    --- @return nil
    if unit[stat] <= 0 or unit[stat] >= 100 then
        return
    end

    local statAbbr = ''
    if stat == 'Health' then
        statAbbr = 'HLT'
    elseif stat == 'Agility' then
        statAbbr = 'AGI'
    elseif stat == 'Dexterity' then
        statAbbr = 'DEX'
    elseif stat == 'Strength' then
        statAbbr = 'STR'
    elseif stat == 'Wisdom' then
        statAbbr = 'WIS'
    elseif stat == 'Leadership' then
        statAbbr = 'LDR'
    elseif stat == 'Marksmanship' then
        statAbbr = 'MRK'
    elseif stat == 'Mechanical' then
        statAbbr = 'MEC'
    elseif stat == 'Explosives' then
        statAbbr = 'EXP'
    elseif stat == 'Medical' then
        statAbbr = 'MED'
    end

    local statBefore = unit[stat]

    local sgData = GetMercStateFlag(unit.session_id, "StatGaining") or {}
    local prefix = 'FAIL'
    local reason_text = ""
    sgData.Cooldowns = sgData.Cooldowns or {}
    local cooldowns = sgData.Cooldowns

    local extraFailRoll = InteractionRand(100, "StatGaining")
    if failChance and extraFailRoll < failChance then
        reason_text = 'CtF: ' .. failChance .. '%'
        goto statGainNope
    end

    if cooldowns[stat] and cooldowns[stat] > Game.CampaignTime then
        prefix = 'CD'
        reason_text = 'roll CD'

        if cooldowns[stat] then
            cooldowns[stat] = Max(cooldowns[stat] - AudaAto.tickLength, Game.CampaignTime)
        end

        goto statGainNope
    end

    if true then

        local bonusToRoll = 4

        -- 0 to 6
        local wisdomBonus = (Clamp(unit.Wisdom, 52, 100) - 52) / 8
        local thresholdDiffDiv = 180

        if stat == 'Health' then
            bonusToRoll = bonusToRoll + 2
        elseif stat == 'Agility' then
            bonusToRoll = bonusToRoll
        elseif stat == 'Dexterity' then
            bonusToRoll = bonusToRoll + 2
        elseif stat == 'Strength' then
            bonusToRoll = bonusToRoll + 4
        elseif stat == 'Wisdom' then
            bonusToRoll = bonusToRoll
            thresholdDiffDiv = 155
        elseif stat == 'Leadership' then
            bonusToRoll = bonusToRoll + wisdomBonus
            thresholdDiffDiv = 400 + wisdomBonus * 50
        elseif stat == 'Marksmanship' then
            bonusToRoll = bonusToRoll + wisdomBonus
            thresholdDiffDiv = 400 + wisdomBonus * 50
        elseif stat == 'Mechanical' then
            bonusToRoll = bonusToRoll + wisdomBonus
            thresholdDiffDiv = 250 + wisdomBonus * 25
        elseif stat == 'Explosives' then
            bonusToRoll = bonusToRoll + wisdomBonus
            thresholdDiffDiv = 250 + wisdomBonus * 25
        elseif stat == 'Medical' then
            bonusToRoll = bonusToRoll + wisdomBonus
            thresholdDiffDiv = 250 + wisdomBonus * 25
        end

        local thresholdBase = Clamp(unit[stat], 60, 99)
        local thresholdAdd = MulDivRound(99 - thresholdBase, 100, thresholdDiffDiv)
        local threshold = thresholdBase + thresholdAdd - bonusToRoll
        local roll = InteractionRand(100, "StatGaining")
        -- reason_text = 'Need: ' .. threshold .. ' (' .. thresholdBase .. '+' .. thresholdAdd .. '-' .. bonusToRoll .. '), Chance: ' .. (100 - threshold) .. '%, Roll: ' .. roll
        reason_text = T({'CtR: <chance>%', chance=99 - threshold})
        if roll >= threshold then
            GainStat(unit, stat)
            cooldowns[stat] = Game.CampaignTime + AudaAto:randCd(statBefore)
            prefix = 'WIN'
        else
            prefix = 'MISS'
        end
    end

    ::statGainNope::

    if statBefore <= 99 then
        CombatLog(AudaAto.isKira and "important" or "debug",
            T(
                {'SG:<prefix> <nick> <statAbbr>(<statBefore>) <reason>', prefix=prefix, nick=unit.Nick or 'Merc',
                    statAbbr=statAbbr, statBefore=statBefore, reason=reason_text}))
    end

    SetMercStateFlag(unit.session_id, "StatGaining", sgData)
end

---
--- Receives stat gaining points for a unit based on their experience gain.
--- Handles cooldowns, stat gaining point bonuses, and logging.
---
--- @param unit table The unit to receive the stat gaining points.
--- @param xpGain number The amount of experience gained by the unit.
---
function ReceiveStatGainingPoints(unit, xpGain)
    if HasPerk(unit, "OldDog") then
        return
    end

    local pointsToGain = 0
    local sgp = unit.statGainingPoints or 0
    local wis = unit.Wisdom or 50

    if 0 < xpGain then

        local sgData = GetMercStateFlag(unit.session_id, "StatGaining")
        if sgData and sgData.Cooldowns then
            for _, key in ipairs(table.keys(sgData.Cooldowns)) do
                sgData.Cooldowns[key] = Max(sgData.Cooldowns[key] - AudaAto.tickLength, Game.CampaignTime)
            end
            SetMercStateFlag(unit.session_id, "StatGaining", sgData)
        end

        local sgeIncrease = 142 + MulDivRound(wis, 169, 100)
        sgeIncrease = MulDivRound(sgeIncrease, AudaAto.sgeGainMod, 100)
        if sgp <= 4 then
            local minBoost = MulDivRound(sgeIncrease, 40, 100)
            local maxBoost = MulDivRound(sgeIncrease, 50, 100)
            local sgeBoost = InteractionRandRange(minBoost, maxBoost, 'StatGainingExtra')
            if sgp == 1 then
                sgeBoost = MulDivRound(sgeBoost, 90, 100)
            elseif sgp == 2 then
                sgeBoost = MulDivRound(sgeBoost, 80, 100)
            elseif sgp == 3 then
                sgeBoost = MulDivRound(sgeBoost, 70, 100)
            elseif sgp == 4 then
                sgeBoost = MulDivRound(sgeBoost, 60, 100)
            end
            sgeIncrease = sgeIncrease + sgeBoost
        elseif sgp <= 9 then
            -- base
        elseif sgp <= 13 then
            sgeIncrease = MulDivRound(sgeIncrease, 90, 100)
        elseif sgp <= 17 then
            sgeIncrease = MulDivRound(sgeIncrease, 80, 100)
        elseif sgp <= 20 then
            sgeIncrease = MulDivRound(sgeIncrease, 60, 100)
        elseif sgp <= 22 then
            sgeIncrease = MulDivRound(sgeIncrease, 40, 100)
        else
            sgeIncrease = MulDivRound(sgeIncrease, 20, 100)
        end

        unit.statGainingPointsExtra = floatfloor((unit.statGainingPointsExtra or 0) + sgeIncrease + 0.5)
    end

    while unit.statGainingPointsExtra >= 10000 do
        CombatLog(AudaAto.isKira and "important" or "debug", T {"<nick> +1 Train Boost (sge)", nick=unit.Nick or 'Merc'})
        unit.statGainingPointsExtra = Max(0, unit.statGainingPointsExtra - 10000)
        pointsToGain = pointsToGain + 1
    end

    unit.statGainingPoints = unit.statGainingPoints + pointsToGain
end

-- Add random cooldowns on merc hire
---
--- Adds random cooldowns to a unit when they are hired.
---
--- @param unit_data table The unit data for the hired unit.
---
function OnMsg.MercHireStatusChanged(unit_data, previousState, newState)
    if newState == "Hired" and previousState ~= newState then

        AudaAto:randomCooldownsToUnit(unit_data)

        if unit_data.statGainingPointsExtra == 0 then
            unit_data.statGainingPointsExtra = InteractionRandRange(1, 4242, 'StatGainingExtra')
        end

    end
end

---
--- Modifies the operations for training mercs.
--- 
--- This function sets the duration of the 'TrainMercs' operation to 24 hours, and modifies the progress per tick calculation to be faster if the 'FastActivity' cheat is enabled.
--- It also updates the 'Tick' function of the 'TrainMercs' operation to handle the training logic for both teachers and students.
---
--- @param none
--- @return none
---
function modifyOperations()
    for _, param in ipairs(SectorOperations.TrainMercs.Parameters) do
        if param.Name == 'ActivityDurationInHoursFull' then
            param.Value = 24
        end
    end
end

local hasExtraStatGainProperty = false
---Checks if the 'statGainingPointsExtra' property exists in the UnitProperties.properties table.
---If the property does not exist, the flag 'hasExtraStatGainProperty' is set to false.
---This is used to determine if the 'statGainingPointsExtra' property needs to be added to the UnitProperties.properties table.
for _, prop in ipairs(UnitProperties.properties) do
    if prop.id == 'statGainingPointsExtra' then
        hasExtraStatGainProperty = true
    end
end

---@class UnitProperty
---@field category string
---@field id string
---@field editor string
---@field default any

---Adds a new unit property to the UnitProperties.properties table if the 'statGainingPointsExtra' property does not already exist.
---This property represents an extra number of stat gaining points that a unit can have.
if not hasExtraStatGainProperty then
    UnitProperties.properties[#UnitProperties.properties + 1] =
        {category="XP", id="statGainingPointsExtra", editor="number", default=0}
end
