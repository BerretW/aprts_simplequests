local smokeType = nil
local smokeProp = nil
local idleStat = 0
local smokeCount = 5
local smokePrompt = nil
local blowPrompt = nil
local smokePromptGroup = GetRandomIntInRange(0, 0xffffff)

local function smokePrompts()
    Citizen.CreateThread(function()
        local str = "Potáhnout"
        smokePrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(smokePrompt, Config.Key)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(smokePrompt, str)
        PromptSetEnabled(smokePrompt, true)
        PromptSetVisible(smokePrompt, true)
        PromptSetHoldMode(smokePrompt, true)
        PromptSetStandardMode(smokePrompt, false)
        PromptSetGroup(smokePrompt, smokePromptGroup)
        PromptRegisterEnd(smokePrompt)

        local str = "Zahodit"
        blowPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(blowPrompt, Config.Key2)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(blowPrompt, str)
        PromptSetEnabled(blowPrompt, true)
        PromptSetVisible(blowPrompt, true)
        PromptSetHoldMode(blowPrompt, true)
        PromptSetStandardMode(blowPrompt, false)
        PromptSetGroup(blowPrompt, smokePromptGroup)
        PromptRegisterEnd(blowPrompt)
    end)
end

local function changeCigarette(num)
    if IsPedMale(PlayerPedId()) then
        if num == 0 then
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@base", "base", 27, -1)
        elseif num == 1 then
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@nervous_stressed@male_b@base", "base", 27, -1)
        elseif num == 2 then
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_d@base", "base", 27, -1)
        elseif num == 3 then
            playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_a@base", "base", 27, -1)
        end
    else
        if num == 0 then
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@base", "base", 27, -1)
        elseif num == 1 then
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_b@base", "base", 27, -1)
        elseif num == 2 then
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@base", "base", 27, -1)
        elseif num == 3 then
            playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@female_a@base", "base", 27, -1)
        end
    end
    Citizen.Wait(1000)
end

local function changeCigar(num)
    if num == 0 then
        playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@male_a@base", "base", 27, -1)
    elseif num == 1 then
        playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@gus@base", "base", 27, -1)
    end
    Citizen.Wait(2000)
end

function useSmoke(item)
    if consumingItem then
        return
    else
        local type = item.type
        consumingItem = item
        idleStat = 0

        if type == "cigarette" then
            smokeCount = 10
            local ped = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(ped, true))
            smokeType = type
            smokeProp = CreateObject(GetHashKey("p_cigarette01x"), x, y, z + 0.2, true, true, true)
            local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
            local mouth = GetEntityBoneIndexByName(ped, "skel_head")
            AttachEntityToEntity(smokeProp, ped, mouth, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@stand_enter", "enter_back_rf", 27, 9400)
            Wait(1000)
            AttachEntityToEntity(smokeProp, ped, righthand, 0.03, -0.01, 0.0, 0.0, 90.0, 0.0, true, true, false, true,
                1, true)
            Wait(1000)
            AttachEntityToEntity(smokeProp, ped, mouth, -0.017, 0.1, -0.01, 0.0, 90.0, -90.0, true, true, false, true,
                1, true)
            Wait(3000)
            -- print(IsPedMale(PlayerPedId()))
            if IsPedMale(PlayerPedId()) then
                AttachEntityToEntity(smokeProp, ped, righthand, 0.017, -0.01, -0.01, 0.0, 120.0, 10.0, true, true,
                    false, true, 1, true)
                Wait(1000)
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@base", "base", 27, -1)
            else
                AttachEntityToEntity(smokeProp, ped, righthand, 0.002, -0.009, 0.011, 0.0, 0.0, -29.0, true, true,
                    false, true, 1, true)
                Wait(1000)
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@base", "base", 27, -1)
            end
            Wait(1000)
            changeCigarette(idleStat)
        elseif type == "cigar" then
            smokeCount = 20
            local ped = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(ped, true))
            smokeType = type
            smokeProp = CreateObject(GetHashKey("p_cigar02x"), x, y, z + 0.2, true, true, true)
            local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
            local mouth = GetEntityBoneIndexByName(ped, "skel_head")
            AttachEntityToEntity(smokeProp, ped, mouth, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@stand_enter", "enter_back_rf", 27, -1)
            Wait(1000)
            AttachEntityToEntity(smokeProp, ped, righthand, 0.03, 0.0, 0.0, 72.0, 0.0, 0.0, true, true, false, true, 1,
                true)
            Wait(1000)
            AttachEntityToEntity(smokeProp, ped, mouth, -0.02, 0.13, -0.02, 0.0, 0.0, 0.0, true, true, false, true, 1,
                true)
            Wait(3000)
            AttachEntityToEntity(smokeProp, ped, righthand, 0.03, 0.0, 0.0, 72.0, 0.0, 0.0, true, true, false, true, 1,
                true)
            Wait(1000)
            changeCigar(idleStat)
        elseif type == "pipe" then
            smokeCount = 9
            local ped = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(ped, true))
            smokeType = type
            smokeProp = CreateObject(GetHashKey(item.prop), x, y, z + 0.2, true, true, true)
            local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
            AttachEntityToEntity(smokeProp, ped, righthand, 0.005, -0.045, 0.0, -170.0, 10.0, -15.0, true, true, false,
                true, 1, true)
            playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_b@trans", "nopipe_trans_pipe", 27, -1)
            Wait(7000)
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_b@base", "base", 27, -1)
        elseif type == "opiumPipe" then
            smokeCount = 15
            local ped = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(ped, true))
            smokeType = type
            smokeProp = CreateObject(GetHashKey(item.prop), x, y, z + 0.2, true, true, true)
            local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
            AttachEntityToEntity(smokeProp, ped, righthand, 0.0, -0.01, 0.0, 225.0, 0.0, 61.0, true, true, false, true,
                1, true)
            playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_b@trans", "nopipe_trans_pipe", 27, -1)
            Wait(7000)
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_b@base", "base", 27, -1)
        elseif type == "longPipe" then
            smokeCount = 20
            local ped = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(ped, true))
            smokeType = type
            smokeProp = CreateObject(GetHashKey(item.prop), x, y, z + 0.2, true, true, true)
            local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
            AttachEntityToEntity(smokeProp, ped, righthand, 0.04, -0.04, 0.03, 219.0, 0.0, 49.0, true, true, false,
                true, 1, true)
            playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_b@trans", "nopipe_trans_pipe", 27, -1)
            Wait(7000)
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_b@base", "base", 27, -1)
        end
    end
end

function blowSmoke()
    if smokeType == "cigar" or smokeType == "cigarette" then
        local random = math.random(1, 3)
        if IsPedMale(PlayerPedId()) then
            if random == 1 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@stand_exit", "exit_back", 27, 1200)
                Citizen.Wait(1200)
                DeleteEntity(smokeProp)
            elseif random == 2 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@stand_exit", "exit_backleft", 27, 2500)
                Citizen.Wait(2000)
                DeleteEntity(smokeProp)
            elseif random == 3 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@stand_exit", "exit_frontleft", 27, 2700)
                Citizen.Wait(1500)
                DeleteEntity(smokeProp)
            end
        else
            if random == 1 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@stand_exit_withprop", "exit_front", 27,
                    1200)
                Citizen.Wait(1200)
                DeleteEntity(smokeProp)
            elseif random == 2 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@stand_exit_withprop", "exit_front", 27,
                    2500)
                Citizen.Wait(2000)
                DeleteEntity(smokeProp)
            elseif random == 3 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@stand_exit_withprop", "exit_front", 27,
                    2700)
                Citizen.Wait(1500)
                DeleteEntity(smokeProp)
            end
        end
    elseif smokeType == "pipe" or smokeType == "opiumPipe" or smokeType == "longPipe" then
        playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_b@trans", "pipe_trans_nopipe", 27, 6500)
        Wait(5500)
        DeleteEntity(smokeProp)
    end
    ClearPedTasksImmediately(PlayerPedId())
    DeleteEntity(smokeProp)
    smokeProp = nil
    smokeType = nil
    consumingItem = nil
end

local function smokeCigarF(num)
    if num == 0 then
        local random = math.random(1, 2)
        if random == 1 then
            playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@male_a@idle_a", "idle_b", 27, 6500)
        elseif random == 2 then
            playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@male_a@idle_c", "idle_g", 27, 9500)
        end
        if random == 1 then
            Citizen.Wait(6500)
        elseif random == 2 then
            Citizen.Wait(9500)
        end
        playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@male_a@base", "base", 27, -1)
    elseif num == 1 then
        local random = math.random(1, 3)
        if random == 1 then
            playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@gus@idle_b", "idle_e", 27, 6500)
        elseif random == 2 then
            playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@gus@idle_c", "idle_g", 27, 9500)
        elseif random == 3 then
            playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@gus@idle_d", "idle_j", 27, 9500)
        end
        if random == 1 then
            Citizen.Wait(6500)
        elseif random == 2 then
            Citizen.Wait(9500)
        end
        playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@gus@base", "base", 27, -1)
    end
end

local function smokeCigarette(num)
    debugPrint("Cigarette: " .. num)
    if IsPedMale(PlayerPedId()) then
        if num == 0 then
            local random = math.random(1, 4)
            if random == 1 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@idle_a", "idle_a", 27, -1)
                Wait(7000)
            elseif random == 2 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@idle_a", "idle_b", 27, -1)
                Wait(9000)
            elseif random == 3 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@idle_b", "idle_d", 27, -1)
                Wait(7000)
            elseif random == 4 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@idle_c", "idle_h", 27, -1)
                Wait(10000)
            end
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@base", "base", 27, -1)
        elseif num == 1 then
            local random = math.random(1, 2)
            if random == 1 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@nervous_stressed@male_b@idle_a", "idle_a", 27, -1)
                Wait(4000)
            elseif random == 2 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@nervous_stressed@male_b@idle_c", "idle_g", 27, -1)
                Wait(8000)
            end
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@nervous_stressed@male_b@base", "base", 27, -1)
        elseif num == 2 then
            local random = math.random(1, 3)
            if random == 1 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_d@idle_a", "idle_a", 27, -1)
                Citizen.Wait(10000)
            elseif random == 2 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_d@idle_b", "idle_e", 27, -1)
                Citizen.Wait(8000)
            elseif random == 3 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_d@idle_c", "idle_g", 27, -1)
                Citizen.Wait(8000)
            end
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_d@base", "base", 27, -1)
        elseif num == 3 then
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_a@idle_a", "idle_c", 27, -1)
            Citizen.Wait(12000)
            playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_a@base", "base", 27, -1)
        end
    else
        if num == 0 then
            local random = math.random(1, 4)
            if random == 1 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@idle_a", "idle_a", 27, -1)
                Wait(7000)
            elseif random == 2 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@idle_a", "idle_b", 27, -1)
                Wait(9000)
            elseif random == 3 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@idle_b", "idle_d", 27, -1)
                Wait(7000)
            elseif random == 4 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@idle_c", "idle_h", 27, -1)
                Wait(10000)
            end
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@base", "base", 27, -1)
        elseif num == 1 then
            local random = math.random(1, 3)
            if random == 1 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_a", "idle_a", 27, -1)
                Citizen.Wait(10000)
            elseif random == 2 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_b", "idle_e", 27, -1)
                Citizen.Wait(8000)
            elseif random == 3 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_c", "idle_g", 27, -1)
                Citizen.Wait(8000)
            end
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@base", "base", 27, -1)
        elseif num == 2 then
            local random = math.random(1, 3)
            if random == 1 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_a", "idle_a", 27, -1)
                Citizen.Wait(10000)
            elseif random == 2 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_b", "idle_e", 27, -1)
                Citizen.Wait(8000)
            elseif random == 3 then
                playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_c", "idle_g", 27, -1)
                Citizen.Wait(8000)
            end
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@base", "base", 27, -1)
        elseif num == 3 then
            playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_a@idle_a", "idle_c", 27, -1)
            Citizen.Wait(12000)
            playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@female_a@base", "base", 27, -1)
        end
    end
end
local function smokeCig()

    if smokeCount > 0 then
        smokeCount = smokeCount - 1
    end
    if smokeType == "cigar" or smokeType == "cigarette" then
        if smokeType == "cigarette" then
            idleStat = idleStat + 1
            if idleStat > 3 then
                idleStat = 0
            end
            smokeCigarette(idleStat)
        else
            idleStat = idleStat + 1
            if idleStat > 1 then
                idleStat = 0
            end
            smokeCigarF(idleStat)
        end
    elseif smokeType == "pipe" or smokeType == "opiumPipe" or smokeType == "longPipe" then
        playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_b@idle_a", "idle_a", 27, 9000)
        Wait(9000)
        playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_b@base", "base", 27, -1)
    end
    if smokeCount <= 0 then
        blowSmoke()
    end
end

Citizen.CreateThread(function()
    smokePrompts()
    while true do
        local pause = 1000
        local playerPed = PlayerPedId()
        if smokeCount >= 1 and DoesEntityExist(smokeProp) and consumingItem then
            local name = CreateVarString(10, 'LITERAL_STRING', "Kouření")
            PromptSetActiveGroupThisFrame(smokePromptGroup, name)
            pause = 0
            if PromptHasHoldModeCompleted(smokePrompt) then
                -- debugPrint("Hold mode completed")
                TriggerEvent("aprts_consumable:Client:setEffect", consumingItem.effect_id, consumingItem.effect_duration)


                TriggerEvent('vorpmetabolism:changeValue', 'Thirst', tonumber(consumingItem.water))
                -- TriggerEvent('vorpmetabolism:changeValue', 'Thirst', thirst * 10)
                TriggerEvent('vorpmetabolism:changeValue', 'Hunger', tonumber(consumingItem.food))

                -- local health = GetAttributeCoreValue(PlayerPedId(), 0, Citizen.ResultAsInteger())
                -- local stamina = GetAttributeCoreValue(PlayerPedId(), 1, Citizen.ResultAsInteger())
                -- SetAttributeCoreValue(PlayerPedId(), 0, health + tonumber(consumingItem.health))
                -- SetAttributeCoreValue(PlayerPedId(), 1, stamina + tonumber(consumingItem.stamina))
                -- if consumingItem.stamina > 0 then
                --     RestorePlayerStamina(PlayerId(), 100.0)
                -- end
                -- SetEntityHealth(PlayerPedId(), health + tonumber(consumingItem.health))

                addPlayerInnerHealth(tonumber(consumingItem.innerHealth))
                addPlayerOuterHealth(tonumber(consumingItem.outerHealth))
                addPlayerInnerStamina(tonumber(consumingItem.innerStamina))
                addPlayerOuterStamina(tonumber(consumingItem.outerStamina))

                local alcohol = GetStat("alcohol")
                local toxin = GetStat("toxin")
                alcohol = math.min(100, alcohol + consumingItem.alcohol)
                toxin = math.min(100, toxin + consumingItem.toxin)
                alcohol = math.max(0, alcohol)
                toxin = math.max(0, toxin)
                SetStat("alcohol", alcohol)
                SetStat("toxin", toxin)
                consume()

                smokeCig()
            end
            if PromptHasHoldModeCompleted(blowPrompt) then
                blowSmoke()
            end
        end

        Citizen.Wait(pause)
    end
end)
