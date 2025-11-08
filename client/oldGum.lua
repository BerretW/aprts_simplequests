local active = false
local playerThirst = 100.0
local playerHunger = 100.0
local playerAlcohol = 0
local playerDrugs = 0
local playerDirt = 0
local api
local xRes = 0
local yRes = 0
local droppedProps = {}
local prepareProp = nil
local prepareItemId = nil
local prepareType = nil
local promptDataTable = GetRandomIntInRange(0, 0xffffff)
local promptDataHand = GetRandomIntInRange(0, 0xffffff)
local promptPropTable = {}
local sometingInHand = false
local takeEntity = 0
local canSave = false
local is_particle_effect_active = false
local current_ptfx_handle_id = false
local promptDataCrounch = GetRandomIntInRange(0, 0xffffff)
local promptDataCigarette = GetRandomIntInRange(0, 0xffffff)
local promptDataPipe = GetRandomIntInRange(0, 0xffffff)
local temperatureState = "normal"
local idleStat = 0
local smokeCount = 0
local inMouth = false
local playerEffects = {}
TriggerEvent("getApi",function(gumApi)
    api = gumApi
end)

function getThirst() return playerThirst end
function getHunger() return playerHunger end
function getAlcohol() return playerAlcohol end
function getTemp() return playerTemperature end
function getDrugs() return playerDrugs end
function getDirt() return playerDirt end

local typesTable = {
    ["bottleBeer"] = {
        item = "",
        propId = GetHashKey('p_bottleBeer01x_PH_R_HAND'), 
        interactionState = GetHashKey('DRINK_BOTTLE@Bottle_Cylinder_D1-55_H18_Neck_A8_B1-8_UNCORK'), 
        any = -316468467
    },
    ["bottleLarge"] = {
        item = "",
        propId = GetHashKey('P_BOTTLEJD01X_PH_R_HAND'), 
        interactionState = GetHashKey('DRINK_BOTTLE@Bottle_Cylinder_D1-3_H30-5_Neck_A13_B2-5_HOLD'), 
        any = -1.0
    },
    ["cupCoffe"] = {
        item = "",
        propId = GetHashKey('P_MUGCOFFEE01X_PH_R_HAND'), 
        interactionState = GetHashKey('DRINK_COFFEE_HOLD'), 
        any = -1082130432,
        add = "CTRL_cupFill"
    },
    ["glassChampagne"] = {
        item = "",
        propId = GetHashKey('P_GLASS001X_PH_R_HAND'), 
        interactionState = GetHashKey('DRINK_CHAMPAGNE_HOLD'), 
        any = -1.0
    },
    ["glassWhiskey"] = {
        item = "",
        propId = GetHashKey('P_BOTTLEJD01X_PH_R_HAND'), 
        interactionState = GetHashKey('DRINK_BOTTLE@Bottle_Cylinder_D1-55_H18_Neck_A8_B1-8_HOLD'), 
        any = -1.0
    },
    ["stew"] = {
        item = 599184882,
        propId = GetHashKey('p_bowl04x_stew_ph_l_hand'),
        interactionState = GetHashKey('EAT_STEW_BOWL_BASE'),
        any = -1.0,
        add = "Stew_Fill"
    },
    ["beerOvalQuick"] = {
        item = "",
        propId = GetHashKey('PrimaryItem'), 
        interactionState = GetHashKey('DRINK_Bottle_Oval_L5-5W9-5H10_Neck_A6_B2-5_QUICK_LEFT_HAND'), 
        any = -1.0
    },
    ["cannedItem"] = {
        item = "",
        propId = GetHashKey('PrimaryItem'), 
        interactionState = GetHashKey('EAT_CANNED_FOOD_CYLINDER@D8-2_H10-5_QUICK_LEFT'), 
        any = -1.0
    },
    
    ["whiskeyOvalQuick"] = {
        item = "",
        propId = GetHashKey('P_BOTTLEJD01X_PH_R_HAND'), 
        interactionState = GetHashKey('DRINK_Bottle_Oval_L6-5W12H9-5_Neck_A12-5_B4_QUICK_LEFT_HAND'), 
        any = -1.0
    },
    ["whiskeyRectangleQuick"] = {
        item = "",
        propId = GetHashKey('P_BOTTLEJD01X_PH_R_HAND'), 
        interactionState = GetHashKey('DRINK_Bottle_Rectangle_L4-8_W9-5_H13_Neck_A12-5_B2-8_QUICK_LEFT_HAND'), 
        any = -1.0
    },
}

RegisterCommand("cleancloth", function(source, args, rawCommand)
    api.playAnim(PlayerPedId(), "mech_loco@player@zero@generic@streamed_idles@a","fidget_dust_off", 27, 3500)
    Citizen.Wait(3400)
    Citizen.InvokeNative(0x6585D955A68452A5, PlayerPedId())
    Citizen.InvokeNative(0x8FE22675A5A45817, PlayerPedId())
    Citizen.InvokeNative(0x9C720776DAA43E7E, PlayerPedId())
    ClearPedEnvDirt(PlayerPedId())
    ClearPedDamageDecalByZone(PlayerPedId(), 10, "ALL")
    ClearPedBloodDamage(PlayerPedId())
    api.playAnim(PlayerPedId(), "ai_react@shake_it_off","dustoff", 27, 1700)
end)

RegisterNetEvent('gum_metabolism:tempState', function(state)
    temperatureState = state
end)

RegisterNetEvent('gum_metabolism:changeAttitude', function()
    promptManage(false)
    if smokeType == "cigar" then
        if idleStat == 1 then
            idleStat = 0
        else
            idleStat = idleStat+1
        end
        changeCigar(idleStat)
    else
        if idleStat == 3 then
            idleStat = 0
        else
            idleStat = idleStat+1
        end
        changeCigarette(idleStat)
    end
    promptManage(true)
end)

function promptManage(state)
    if state then
        api.setPromptEnable('Smoke', promptDataCigarette, true)
        api.setPromptEnable('Change attitude', promptDataCigarette, true)
        api.setPromptEnable('Blow', promptDataCigarette, true)
        api.setPromptEnable('To Mouth', promptDataCigarette, true)
        api.setPromptEnable('Blow', promptDataPipe, true)
        api.setPromptEnable('Smoke', promptDataPipe, true)
    else
        api.setPromptEnable('Smoke', promptDataCigarette, false)
        api.setPromptEnable('Change attitude', promptDataCigarette, false)
        api.setPromptEnable('To Mouth', promptDataCigarette, false)
        api.setPromptEnable('Blow', promptDataCigarette, false)
        api.setPromptEnable('Blow', promptDataPipe, false)
        api.setPromptEnable('Smoke', promptDataPipe, false)
    end
end

RegisterNetEvent('gum_metabolism:useDrug', function(a, b)
    if sometingInHand then
        return false
    end
    sometingInHand = true
    local ped = PlayerPedId()
    local hasWeaponInHead = GetCurrentPedWeapon(ped, 0)
    SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true, 0, 0, 0)

    TriggerServerEvent('gum_metabolism:removeItem', a)
    if b.type == "sniffing" then
        api.playAnim(PlayerPedId(), "mech_loco_m@character@arthur@fidgets@normal@unarmed","scratch_nose_right_a", 1, 3000)
        Citizen.Wait(3000)
    elseif b.type == "injection" then
        local propEntity = CreateObject(GetHashKey(b.prop), GetEntityCoords(ped), false, true, false, false, true)
        TaskItemInteraction_2(ped, -1199896558, propEntity, GetHashKey("PrimaryItem"), GetHashKey("USE_STIMULANT_INJECTION_QUICK_LEFT_HAND"), 1, 0, -1.0)
        Citizen.Wait(2000)
        api.deleteObj(propEntity)
    end
    playerDrugs = playerDrugs+b.drugs
    playerAlcohol = playerAlcohol+b.alcohol
    playerThirst = playerThirst+b.thirst
    playerHunger = playerHunger+b.hunger
    
    local startCountValue = 0
    if playerDrugs-b.drugs < 0 then
        startCountValue = 0
    else
        startCountValue = playerDrugs-b.drugs
    end
    for i = startCountValue, playerDrugs do
        if not AnimpostfxIsRunning(b.effect) then
            AnimpostfxPlay(b.effect)
        end
        playerDrugs = i
        if i/100 > 1 then
            break
        end
        Citizen.InvokeNative(0xCAB4DD2D5B2B7246, b.effect, i/100)
        Citizen.InvokeNative(0x406CCF555B04FAD3, PlayerPedId(), true, i/100)
        Citizen.Wait(300)
    end
    local findEffect = false
    for k,v in pairs(playerEffects) do
        if v == b.effect then
            findEffect = true
        end
    end
    if not findEffect then
        table.insert(playerEffects, b.effect)
    end
    sometingInHand = false
end)

function drugSet()
    for a,b in pairs(playerEffects) do
        if playerEffects[a] ~= nil then
            if playerDrugs == 0 then
                AnimpostfxStop(b)
                Citizen.InvokeNative(0xCAB4DD2D5B2B7246,b, 0.0)
                playerEffects[a] = nil
            else
                if not AnimpostfxIsRunning(b) then
                    AnimpostfxPlay(b)
                end
                Citizen.InvokeNative(0xCAB4DD2D5B2B7246, b, playerDrugs/100)
            end
        end
    end
end

RegisterNetEvent('gum_metabolism:useSmoke', function(a, b)
    if sometingInHand then
        return false
    end
    TriggerServerEvent('gum_metabolism:removeItem', a)
    idleStat = 0
    promptManage(false)
    smokeCount = b.smokeCount
    if b.type == "cigarette" then
        local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped, true))
        smokeType = b.type
        smokeProp = CreateObject(GetHashKey(b.prop), x, y, z + 0.2, true, true, true)
        local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
        local mouth = GetEntityBoneIndexByName(ped, "skel_head")
        AttachEntityToEntity(smokeProp, ped, mouth, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@stand_enter","enter_back_rf",27,9400)
        Wait(1000)
        AttachEntityToEntity(smokeProp, ped, righthand, 0.03, -0.01, 0.0, 0.0, 90.0, 0.0, true, true, false, true, 1, true)
        Wait(1000)
        AttachEntityToEntity(smokeProp, ped, mouth, -0.017, 0.1, -0.01, 0.0, 90.0, -90.0, true, true, false, true, 1, true)
        Wait(3000)
        print(IsPedMale(PlayerPedId()))
        if IsPedMale(PlayerPedId()) then
            AttachEntityToEntity(smokeProp, ped, righthand, 0.017, -0.01, -0.01, 0.0, 120.0, 10.0, true, true, false, true, 1, true)
            Wait(1000)
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@base","base",27,-1)
        else
            AttachEntityToEntity(smokeProp, ped, righthand, 0.002, -0.009, 0.011, 0.0, 0.0, -29.0, true, true, false, true, 1, true)
            Wait(1000)
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@base","base",27,-1)
        end
        Wait(1000)
    elseif b.type == "cigar" then
        local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped, true))
        smokeType = b.type
        smokeProp = CreateObject(GetHashKey(b.prop), x, y, z + 0.2, true, true, true)
        local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
        local mouth = GetEntityBoneIndexByName(ped, "skel_head")
        AttachEntityToEntity(smokeProp, ped, mouth, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@stand_enter","enter_back_rf", 27, -1)
        Wait(1000)
        AttachEntityToEntity(smokeProp, ped, righthand, 0.03, 0.0, 0.0, 72.0, 0.0, 0.0, true, true, false, true, 1, true)
        Wait(1000)
        AttachEntityToEntity(smokeProp, ped, mouth, -0.02, 0.13, -0.02, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        Wait(3000)
        AttachEntityToEntity(smokeProp, ped, righthand, 0.03, 0.0, 0.0, 72.0, 0.0, 0.0, true, true, false, true, 1, true)
        Wait(1000)
        changeCigar(idleStat)
    elseif b.type == "pipe" then
        local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped, true))
        smokeType = b.type
        smokeProp = CreateObject(GetHashKey(b.prop), x, y, z + 0.2, true, true, true)
        local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
        AttachEntityToEntity(smokeProp, ped, righthand, 0.005, -0.045, 0.0, -170.0, 10.0, -15.0, true, true, false, true, 1, true)
        api.playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_b@trans","nopipe_trans_pipe",27,-1)
        Wait(7000)
        api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_b@base","base",27,-1)
    elseif b.type == "opiumPipe" then
        local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped, true))
        smokeType = b.type
        smokeProp = CreateObject(GetHashKey(b.prop), x, y, z + 0.2, true, true, true)
        local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
        AttachEntityToEntity(smokeProp, ped, righthand, 0.0, -0.01, 0.0, 225.0, 0.0, 61.0, true, true, false, true, 1, true)
        api.playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_b@trans","nopipe_trans_pipe",27,-1)
        Wait(7000)
        api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_b@base","base",27,-1)
    elseif b.type == "longPipe" then
        local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped, true))
        smokeType = b.type
        smokeProp = CreateObject(GetHashKey(b.prop), x, y, z + 0.2, true, true, true)
        local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
        AttachEntityToEntity(smokeProp, ped, righthand, 0.04, -0.04, 0.03, 219.0, 0.0, 49.0, true, true, false, true, 1, true)
        api.playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_b@trans","nopipe_trans_pipe",27, -1)
        Wait(7000)
        api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_b@base","base",27, -1)
    end
    playerDrugs = playerDrugs+b.drugs
    playerAlcohol = playerAlcohol+b.alcohol
    playerThirst = playerThirst+b.thirst
    playerHunger = playerHunger+b.hunger
    
    promptManage(true)
end)

RegisterNetEvent('gum_metabolism:blow', function()
    promptManage(false)
    if smokeType == "cigar" or smokeType == "cigarette" then
        local random = math.random(1,3)
        if IsPedMale(PlayerPedId()) then
            if random == 1 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@stand_exit","exit_back", 27, 1200)
                Citizen.Wait(1200)
                api.deleteObj(smokeProp)
            elseif random == 2 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@stand_exit","exit_backleft", 27, 2500)
                Citizen.Wait(2000)
                api.deleteObj(smokeProp)
            elseif random == 3 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@stand_exit","exit_frontleft", 27, 2700)
                Citizen.Wait(1500)
                api.deleteObj(smokeProp)
            end
        else
            if random == 1 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@stand_exit_withprop","exit_front", 27, 1200)
                Citizen.Wait(1200)
                api.deleteObj(smokeProp)
            elseif random == 2 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@stand_exit_withprop","exit_front", 27, 2500)
                Citizen.Wait(2000)
                api.deleteObj(smokeProp)
            elseif random == 3 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@stand_exit_withprop","exit_front", 27, 2700)
                Citizen.Wait(1500)
                api.deleteObj(smokeProp)
            end
        end
    elseif smokeType == "pipe" or smokeType == "opiumPipe" or smokeType == "longPipe" then
        api.playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_b@trans","pipe_trans_nopipe", 27, 6500)
        Wait(5500)
        api.deleteObj(smokeProp)
    end
    smokeProp = nil
    smokeType = nil
    promptManage(true)
end)

RegisterNetEvent('gum_metabolism:smokeCig', function()
    promptManage(false)
    if smokeCount > 0 then
        smokeCount = smokeCount-1
    end
    if smokeType == "cigar" or smokeType == "cigarette" then
        if smokeType == "cigarette" then
            smokeCigarette(idleStat)
        else
            smokeCigarF(idleStat)
        end
    elseif smokeType == "pipe" or smokeType == "opiumPipe" or smokeType == "longPipe" then
        api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_b@idle_a","idle_a", 27, 9000)
        Wait(9000)
        api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_b@base","base", 27, -1)
    end
    if smokeCount <= 0 then
        TriggerEvent("gum_metabolism:blow")
    end
    promptManage(true)
end)

function smokeCigarette(num)
    if IsPedMale(PlayerPedId()) then
        if num == 0 then
            local random = math.random(1, 4)
            if random == 1 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@idle_a","idle_a", 27, -1)
                Wait(7000)
            elseif random == 2 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@idle_a","idle_b", 27, -1)
                Wait(9000)
            elseif random == 3 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@idle_b","idle_d", 27, -1)
                Wait(7000)
            elseif random == 4 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@idle_c","idle_h", 27, -1)
                Wait(10000)
            end
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@base","base", 27, -1)
        elseif num == 1 then
            local random = math.random(1, 2)
            if random == 1 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@nervous_stressed@male_b@idle_a","idle_a", 27, -1)
                Wait(4000)
            elseif random == 2 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@nervous_stressed@male_b@idle_c","idle_g", 27, -1)
                Wait(8000)
            end
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@nervous_stressed@male_b@base", "base", 27, -1)
        elseif num == 2 then
            local random = math.random(1, 3)
            if random == 1 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_d@idle_a","idle_a", 27, -1)
                Citizen.Wait(10000)
            elseif random == 2 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_d@idle_b","idle_e", 27, -1)
                Citizen.Wait(8000)
            elseif random == 3 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_d@idle_c","idle_g", 27, -1)
                Citizen.Wait(8000)
            end
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_d@base","base", 27, -1)
        elseif num == 3 then
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_a@idle_a","idle_c", 27, -1)
            Citizen.Wait(12000)
            api.playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_a@base","base", 27, -1)
        end
    else
        if num == 0 then
            local random = math.random(1, 4)
            if random == 1 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@idle_a","idle_a", 27, -1)
                Wait(7000)
            elseif random == 2 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@idle_a","idle_b", 27, -1)
                Wait(9000)
            elseif random == 3 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@idle_b","idle_d", 27, -1)
                Wait(7000)
            elseif random == 4 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@idle_c","idle_h", 27, -1)
                Wait(10000)
            end
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@base","base", 27, -1)
        elseif num == 1 then
            local random = math.random(1, 3)
            if random == 1 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_a","idle_a", 27, -1)
                Citizen.Wait(10000)
            elseif random == 2 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_b","idle_e", 27, -1)
                Citizen.Wait(8000)
            elseif random == 3 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_c","idle_g", 27, -1)
                Citizen.Wait(8000)
            end
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@base","base", 27, -1)
        elseif num == 2 then
            local random = math.random(1, 3)
            if random == 1 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_a","idle_a", 27, -1)
                Citizen.Wait(10000)
            elseif random == 2 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_b","idle_e", 27, -1)
                Citizen.Wait(8000)
            elseif random == 3 then
                api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@idle_c","idle_g", 27, -1)
                Citizen.Wait(8000)
            end
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@base","base", 27, -1)
        elseif num == 3 then
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_a@idle_a","idle_c", 27, -1)
            Citizen.Wait(12000)
            api.playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@female_a@base","base", 27, -1)
        end
    end
end

function smokeCigarF(num)
    if num == 0 then
        local random = math.random(1,2)
        if random == 1 then
            api.playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@male_a@idle_a","idle_b", 27, 6500)
        elseif random == 2 then
            api.playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@male_a@idle_c","idle_g", 27, 9500)
        end
        if random == 1 then
            Citizen.Wait(6500)
        elseif random == 2 then
            Citizen.Wait(9500)
        end
        api.playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@male_a@base","base", 27, -1)
    elseif num == 1 then
        local random = math.random(1,3)
        if random == 1 then
            api.playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@gus@idle_b","idle_e", 27, 6500)
        elseif random == 2 then
            api.playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@gus@idle_c","idle_g", 27, 9500)
        elseif random == 3 then
            api.playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@gus@idle_d","idle_j", 27, 9500)
        end
        if random == 1 then
            Citizen.Wait(6500)
        elseif random == 2 then
            Citizen.Wait(9500)
        end
        api.playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@gus@base","base", 27, -1)
    end
end

RegisterNetEvent('gum_metabolism:attach', function()
    promptManage(false)
    inMouth = true
    api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@idle_a","idle_a", 27, 3000)
    Citizen.Wait(2900)
    local ped = PlayerPedId()
    local mouth = GetEntityBoneIndexByName(ped, "PH_HEAD")
    if smokeType == "cigarette" then
        AttachEntityToEntity(smokeProp, ped, mouth, -0.104, 0.099, -0.015, 0.0, -26.0, -90.0, true, true, false, true, 1, true)
    else
        AttachEntityToEntity(smokeProp, ped, mouth, -0.104, 0.139, -0.039, -16.0, 0.0, 0.0, true, true, false, true, 1, true)
    end
    ClearPedTasks(ped)
    promptManage(true)
end)

Citizen.CreateThread(function()
    api.createPrompt('Use', 0x27D1C284, promptDataTable, nil, 'gum_metabolism:takeItem')
    api.createPrompt('Place', 0x27D1C284, promptDataHand, nil, 'gum_metabolism:placeItem')
    api.createPrompt('Wash', 0x27D1C284, promptDataCrounch, nil, 'gum_metabolism:cleanMe')

	api.createPrompt("Smoke", 0x27D1C284, promptDataCigarette, nil, "gum_metabolism:smokeCig")
    api.createPrompt("Change attitude", 0xA1ABB953, promptDataCigarette, nil, "gum_metabolism:changeAttitude")
	api.createPrompt("Blow", 0x156F7119, promptDataCigarette, nil, "gum_metabolism:blow")
	api.createPrompt("To Mouth", 0xC13A6564, promptDataCigarette, nil, "gum_metabolism:attach")

    api.createPrompt("Smoke", 0x27D1C284, promptDataPipe, nil, "gum_metabolism:smokeCig")
	api.createPrompt("Blow", 0x156F7119, promptDataPipe, nil, "gum_metabolism:blow")

    while true do
        local optimalization = 1000
        coordsTarget, entity = api.getTarget()
        api.showPrompt('', promptDataTable, false)
        api.showPrompt('', promptDataHand, false)
        api.showPrompt('', promptDataCrounch, false)
        api.showPrompt('', promptDataCigarette, false)
        api.showPrompt('', promptDataPipe, false)
        if smokeProp then
            if inMouth then
                optimalization = 5
                local _, wepHash = GetCurrentPedWeapon(PlayerPedId(), true, 0, true)
                if Citizen.InvokeNative(0x91AEF906BCA88877, 0, 0xC13A6564) and wepHash == -1569615261 then
                    promptManage(false)
                    local ped = PlayerPedId()
                    inMouth = false
                    api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@idle_a","idle_a", 27, 3000)
                    Citizen.Wait(2900)
                    if smokeType == "cigarette" then
                        local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
                        if IsPedMale(PlayerPedId()) then
                            AttachEntityToEntity(smokeProp, ped, righthand, 0.017, -0.01, -0.01, 0.0, 120.0, 10.0, true, true, false, true, 1, true)
                        else
                            AttachEntityToEntity(smokeProp, ped, righthand, 0.002, -0.009, 0.011, 0.0, 0.0, -29.0, true, true, false, true, 1, true)
                        end
                        changeCigarette(idleStat)
                    elseif smokeType == "cigar" then
                        local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
                        AttachEntityToEntity(smokeProp, ped, righthand, 0.03, 0.0, 0.0, 72.0, 0.0, 0.0, true, true, false, true, 1, true)
                        changeCigar(idleStat)
                    end
                    promptManage(true)
                end
            else
                if smokeType == "cigarette" or smokeType == "cigar" then
                    api.showPrompt('Smoke : '..smokeCount, promptDataCigarette, true)
                else
                    api.showPrompt('Smoke : '..smokeCount, promptDataPipe, true)
                end
            end
        end
        if prepareProp ~= nil then
            optimalization = 5
            SetEntityCoords(prepareProp, coordsTarget.x, coordsTarget.y, coordsTarget.z, 0.0, 0.0, 0.0, false)
            if IsControlPressed(0, 0x07CE1E61) then
                createDrop(GetEntityModel(prepareProp), prepareType, GetEntityCoords(prepareProp), prepareLabel, prepareItemId)
                api.deleteObj(prepareProp)
                prepareProp = nil
            end
        end

        local pCoords = GetEntityCoords(PlayerPedId())
        for a,b in pairs(droppedProps) do
            if b ~= nil then
                local entityId = NetworkGetEntityFromNetworkId(a)
                if GetEntityModel(entityId) == b.model then
                    local eCoords = GetEntityCoords(entityId)
                    local dist = GetDistanceBetweenCoords(pCoords, eCoords, true)
                    local interactionEntity = Citizen.InvokeNative(0x5a0100ea714db68, PlayerPedId())
                    if dist < 3 then
                        optimalization = 200
                    end
                    if dist < 0.9 and not sometingInHand then
                        optimalization = 5
                        takeEntity = entityId
                        takeType = b.type
                        takeItem = b.itemId
                        prepareType = b.type
                        prepareLabel = b.label
                        api.showPrompt(''..b.label..'', promptDataTable, true)
                    elseif dist < 2.0 and interactionEntity and sometingInHand then
                        optimalization = 5
                        if b.percent <= 0 then
                            DisableControlAction(0, 0x07B8BEAF, true)
                        end
                        DisableControlAction(0, 0x3B24C470, true)
                        DrawText3D(eCoords.x, eCoords.y, eCoords.z, ""..math.floor(b.percent).."%")
                    end
                end
            end
        end
        if Citizen.InvokeNative(0xDDE5C125AC446723, PlayerPedId()) then
            if Citizen.InvokeNative(0xD5FE956C70FF370B, PlayerPedId()) then
                api.showPrompt('Wash in water', promptDataCrounch, true)
            end
        end
        Citizen.Wait(optimalization)
    end
end)

RegisterNetEvent('gum_metabolism:cleanMe', function()
    FreezeEntityPosition(PlayerPedId(), true)
    api.setPromptEnable('Wash', promptDataCrounch, false)
    clearAnimationSkin()
    FreezeEntityPosition(PlayerPedId(), false)
    api.setPromptEnable('Wash', promptDataCrounch, true)
end)

function isRainyWeather()
    local pCoords = GetEntityCoords(PlayerPedId())
    if not Citizen.InvokeNative(0x5054D1A5218FA696, pCoords) then
        local weather = Citizen.InvokeNative(0x51021D36F62AAA83)
        if weather == 1420204096 or weather == 2082228755 or weather == -1721991356 or weather == -416908843 or weather == 212278652 then
            return true
        end
    end
end

Citizen.CreateThread(function()
    while true do
        playerHunger = playerHunger-Config.StatusDrainSetup["hunger"].idle
        playerThirst = playerThirst-Config.StatusDrainSetup["thirst"].idle
        playerDirt = playerDirt+Config.StatusDrainSetup["dirt"].idle
        if  Citizen.InvokeNative(0x9DE327631295B4C2, PlayerPedId()) then
            playerHunger = playerHunger-Config.StatusDrainSetup["hunger"].swim-Config.StatusDrainSetup["hunger"][temperatureState]
            playerThirst = playerThirst-Config.StatusDrainSetup["thirst"].swim-Config.StatusDrainSetup["thirst"][temperatureState]
            if not isRainyWeather() then
                playerDirt = playerDirt+Config.StatusDrainSetup["dirt"].swim+Config.StatusDrainSetup["dirt"][temperatureState]
            end
        elseif Citizen.InvokeNative(0xDE4C184B2B9B071A, PlayerPedId()) then
            playerHunger = playerHunger-Config.StatusDrainSetup["hunger"].walk-Config.StatusDrainSetup["hunger"][temperatureState]
            playerThirst = playerThirst-Config.StatusDrainSetup["thirst"].walk-Config.StatusDrainSetup["thirst"][temperatureState]
            if not isRainyWeather() then
                playerDirt = playerDirt+Config.StatusDrainSetup["dirt"].walk+Config.StatusDrainSetup["dirt"][temperatureState]
            end
        elseif Citizen.InvokeNative(0xC5286FFC176F28A2, PlayerPedId()) then
            playerHunger = playerHunger-Config.StatusDrainSetup["hunger"].run-Config.StatusDrainSetup["hunger"][temperatureState]
            playerThirst = playerThirst-Config.StatusDrainSetup["thirst"].run-Config.StatusDrainSetup["thirst"][temperatureState]
            if not isRainyWeather() then
                playerDirt = playerDirt+Config.StatusDrainSetup["dirt"].run+Config.StatusDrainSetup["dirt"][temperatureState]
            end
        elseif Citizen.InvokeNative(0x57E457CD2C0FC168, PlayerPedId()) then
            playerHunger = playerHunger-Config.StatusDrainSetup["hunger"].sprint-Config.StatusDrainSetup["hunger"][temperatureState]
            playerThirst = playerThirst-Config.StatusDrainSetup["thirst"].sprint-Config.StatusDrainSetup["thirst"][temperatureState]
            if not isRainyWeather() then
                playerDirt = playerDirt+Config.StatusDrainSetup["dirt"].sprint+Config.StatusDrainSetup["dirt"][temperatureState]
            end
        end
        if isRainyWeather() then
            playerDirt = playerDirt+Config.StatusDrainSetup["dirt"].rain+Config.StatusDrainSetup["dirt"][temperatureState]
        end

        if playerAlcohol > 0 then
            if Citizen.InvokeNative(0xDE4C184B2B9B071A, PlayerPedId()) then
                playerAlcohol = playerAlcohol-Config.StatusDrainSetup["alcohol"].walk-Config.StatusDrainSetup["alcohol"][temperatureState]
            elseif Citizen.InvokeNative(0xC5286FFC176F28A2, PlayerPedId()) then
                playerAlcohol = playerAlcohol-Config.StatusDrainSetup["alcohol"].run-Config.StatusDrainSetup["alcohol"][temperatureState]
            elseif Citizen.InvokeNative(0x57E457CD2C0FC168, PlayerPedId()) then
                playerAlcohol = playerAlcohol-Config.StatusDrainSetup["alcohol"].sprint-Config.StatusDrainSetup["alcohol"][temperatureState]
            elseif Citizen.InvokeNative(0x9DE327631295B4C2, PlayerPedId()) then
                playerAlcohol = playerAlcohol-Config.StatusDrainSetup["alcohol"].swim-Config.StatusDrainSetup["alcohol"][temperatureState]
            else
                playerAlcohol = playerAlcohol-Config.StatusDrainSetup["alcohol"].idle-Config.StatusDrainSetup["alcohol"][temperatureState]
            end
        end

        if playerDrugs > 0 then
            if Citizen.InvokeNative(0xDE4C184B2B9B071A, PlayerPedId()) then
                playerDrugs = playerDrugs-Config.StatusDrainSetup["drugs"].walk-Config.StatusDrainSetup["drugs"][temperatureState]
            elseif Citizen.InvokeNative(0xC5286FFC176F28A2, PlayerPedId()) then
                playerDrugs = playerDrugs-Config.StatusDrainSetup["drugs"].run-Config.StatusDrainSetup["drugs"][temperatureState]
            elseif Citizen.InvokeNative(0x57E457CD2C0FC168, PlayerPedId()) then
                playerDrugs = playerDrugs-Config.StatusDrainSetup["drugs"].sprint-Config.StatusDrainSetup["drugs"][temperatureState]
            elseif Citizen.InvokeNative(0x9DE327631295B4C2, PlayerPedId()) then
                playerDrugs = playerDrugs-Config.StatusDrainSetup["alcohol"].swim-Config.StatusDrainSetup["drugs"][temperatureState]
            else
                playerDrugs = playerDrugs-Config.StatusDrainSetup["drugs"].idle-Config.StatusDrainSetup["drugs"][temperatureState]
            end
        end
        fixZeroValue()
        if playerThirst == 0 then
            SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId())-5)
        end
        if playerHunger == 0 then
            SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId())-5)
        end
        -- SetAttributePoints(PlayerPedId(), 16, math.floor(playerDirt*100))
        -- SetAttributePoints(PlayerPedId(), 17, math.floor(playerDirt*100))
        SetAttributePoints(PlayerPedId(), 22, math.floor(playerDirt*100))
        if (playerDirt > 70) then
            loadDirtEffect()
        else
            cancelDirtEffect()

        end 
        drunkSet()
        if not sometingInHand then    
            drugSet()
        end
        Citizen.Wait(1000)
    end
end)

function loadDirtEffect()
    local new_ptfx_dictionary = "core"
	local new_ptfx_name = "ent_amb_insect_fly_swarm_shit_tracking"
	local current_ptfx_dictionary = new_ptfx_dictionary
	local current_ptfx_name = new_ptfx_name
	local bone_index = 117
	local ptfx_offcet_x = -0.5
	local ptfx_offcet_y = -0.8
	local ptfx_offcet_z = 0.0
	local ptfx_rot_x = -90.0
	local ptfx_rot_y = 0.0
	local ptfx_rot_z = 0.0
	local ptfx_scale = 1.0
	local ptfx_axis_x = 0
	local ptfx_axis_y = 0
	local ptfx_axis_z = 0
    if not is_particle_effect_active or not Citizen.InvokeNative(0x9DD5AFF561E88F2A, current_ptfx_handle_id) then
        current_ptfx_dictionary = new_ptfx_dictionary
        current_ptfx_name = new_ptfx_name
        if not Citizen.InvokeNative(0x65BB72F29138F5D6, GetHashKey(current_ptfx_dictionary)) then
            Citizen.InvokeNative(0xF2B2353BBC0D4E8F, GetHashKey(current_ptfx_dictionary))
            local counter = 0
            while not Citizen.InvokeNative(0x65BB72F29138F5D6, GetHashKey(current_ptfx_dictionary)) and counter <= 300 do
                Citizen.Wait(0)
            end
        end
        if Citizen.InvokeNative(0x65BB72F29138F5D6, GetHashKey(current_ptfx_dictionary)) then
            Citizen.InvokeNative(0xA10DB07FC234DD12, current_ptfx_dictionary)

            current_ptfx_handle_id = Citizen.InvokeNative(0x9C56621462FFE7A6, current_ptfx_name,PlayerPedId(),ptfx_offcet_x,ptfx_offcet_y,ptfx_offcet_z,ptfx_rot_x,ptfx_rot_y,ptfx_rot_z,bone_index,ptfx_scale,ptfx_axis_x,ptfx_axis_y,ptfx_axis_z)
            is_particle_effect_active = true
        end
    end
end

function cancelDirtEffect()
    if is_particle_effect_active then
        if current_ptfx_handle_id then
            if Citizen.InvokeNative(0x9DD5AFF561E88F2A, current_ptfx_handle_id) then
                Citizen.InvokeNative(0x459598F579C98929, current_ptfx_handle_id, false)
            end
        end
        current_ptfx_handle_id = false
        is_particle_effect_active = false
    end
end

Citizen.CreateThread(function()
    while true do
        if playerAlcohol > 0 then
            ShakeGameplayCam("DEATH_FAIL_IN_EFFECT_SHAKE", playerAlcohol*0.01)
            ShakeGameplayCam("DRUNK_SHAKE", playerAlcohol*0.01)
        else
            ShakeGameplayCam("DEATH_FAIL_IN_EFFECT_SHAKE", 0.0)
            ShakeGameplayCam("DRUNK_SHAKE", 0.0)
        end
        Citizen.Wait(30000)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        if canSave then
            TriggerServerEvent('gum_metabolism:updateMeta', playerHunger, playerThirst, playerAlcohol, playerDrugs, playerDirt)
        end
    end
end)



function GetPedDrunkness(player)
    return Citizen.InvokeNative(0x6FB76442469ABD68, player, Citizen.ResultAsFloat())
end

function drunkSet()
    if playerAlcohol ~= 0 then
        if GetPedDrunkness(PlayerPedId()) ~= playerAlcohol*0.01 then
            if not AnimpostfxIsRunning("OJDominoBlur") then
                AnimpostfxPlay("OJDominoBlur")
            end
            Citizen.InvokeNative(0xCAB4DD2D5B2B7246, "OJDominoBlur", playerAlcohol*0.01)
            Citizen.InvokeNative(0x406CCF555B04FAD3, PlayerPedId(), true, playerAlcohol*0.01)
        end
    else
        if AnimpostfxIsRunning("OJDominoBlur") then
            AnimpostfxStop("OJDominoBlur")
            Citizen.InvokeNative(0xCAB4DD2D5B2B7246, "OJDominoBlur", 0.0)
            Citizen.InvokeNative(0x406CCF555B04FAD3, PlayerPedId(), false, 0.0)
        end
    end
end

function fixZeroValue()
    if playerHunger < 0 then
        playerHunger = 0
    end
    if playerThirst < 0 then
        playerThirst = 0
    end
    if playerAlcohol < 0 then
        playerAlcohol = 0
    end
    if playerDrugs < 0 then
        playerDrugs = 0
    end
    if playerHunger > 100 then
        playerHunger = 100
    end
    if playerThirst > 100 then
        playerThirst = 100
    end
    if playerAlcohol > 100 then
        playerAlcohol = 100
    end
    if playerDrugs > 100 then
        playerDrugs = 100
    end
    if playerDirt < 0 then
        playerDirt = 0
    end
    if playerDirt > 100 then
        playerDirt = 100
    end
end

function feedInteraction(eatType)
    local pCoords = GetEntityCoords(PlayerPedId())
    TaskItemInteraction_2(PlayerPedId(), 599184882, takeEntity, GetHashKey("p_bowl04x_stew_ph_l_hand"), GetHashKey('EAT_STEW_BOWL_BASE'), 3, 0, 0.0)

    local spoon = CreateObject("p_spoon01x", pCoords, true, true, false, false, true)
    TaskItemInteraction_2(PlayerPedId(), 599184882, spoon, GetHashKey("p_spoon01x_ph_r_hand"), GetHashKey('EAT_STEW_BOWL_BASE'), 3, 0, 1.0)
    Citizen.Wait(150)
    Citizen.InvokeNative(0x669655FFB29EF1A9, takeEntity, 0, "Stew_Fill", 1.0)
    local holdTimer = 0
    local netId = NetworkGetNetworkIdFromEntity(takeEntity)
    while true do
        Wait(fpsTimer())
        if Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 1776449982 then
            holdTimer = holdTimer + 1
            if droppedProps[netId] ~= nil then
                if holdTimer > 25 then
                    droppedProps[netId].percent = droppedProps[netId].percent - 1.5
                else
                    droppedProps[netId].percent = droppedProps[netId].percent - 1.1
                end
                addToMetabolism(Config.Items[takeItem].hunger, Config.Items[takeItem].thirst, Config.Items[takeItem].alcohol, Config.Items[takeItem].drugs, Config.Items[takeItem].health, Config.Items[takeItem].stamina)
                if droppedProps[netId].percent < 0 then
                    DisableControlAction(0, 0x07B8BEAF, true)
                    droppedProps[netId].percent = 0
                    Wait(3500)
                    droppedProps[netId] = nil
                    api.deleteObj(takeEntity)
                    api.deleteObj(spoon)
                    TriggerServerEvent('gum_metabolism:removeItemProp', netId)
                    sometingInHand = false
                    break
                end
            end
        end
        if Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == -583731576 then
            holdTimer = 0
        end
        if Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == false then
            droppedProps[netId] = nil
            TriggerServerEvent('gum_metabolism:removeItemProp', netId)
            api.deleteObj(takeEntity)
            api.deleteObj(spoon)
            sometingInHand = false
            break
        end
    end
end

RegisterNetEvent('gum_metabolism:useItem', function(a, b)
    if Citizen.InvokeNative(0xEC7E480FF8BD0BED, PlayerPedId()) then
        return false
    end
    if sometingInHand then
        return false
    end
    ClearPedTasks(PlayerPedId())
    TriggerServerEvent("gum_metabolism:removeItem", a)
    if string.find(b.type, "Quick") then
        takeItem = a
        local quickEntity = createQuickDrop(b.prop, b.type, GetEntityCoords(PlayerPedId()), b.label)
        TaskItemInteraction_2(PlayerPedId(), GetHashKey(b.prop), quickEntity, typesTable[b.type].propId, typesTable[b.type].interactionState, 1, 0, typesTable[b.type].any)
        api.deleteObj(quickEntity)
        addToMetabolism(b.hunger, b.thirst, b.alcohol, b.drugs, b.health, b.stamina)
    else
        api.getAnswer('What you want?', 'Take', 'Prepare', function(cb)
            if cb == true then
                if b.type == "stew" then
                    prepareType = b.type
                    prepareLabel = b.label
                    takeItem = a
                    takeEntity = createDrop(b.prop, b.type, GetEntityCoords(PlayerPedId()), b.label, a)
                    TriggerEvent("gum_metabolism:takeItem")
                else
                    takeEntity = createDrop(b.prop, b.type, GetEntityCoords(PlayerPedId()), b.label, a)
                    prepareType = b.type
                    prepareLabel = b.label
                    takeItem = a
                    TriggerEvent("gum_metabolism:takeItem")
                end
            else
                prepareDrop(b.prop, b.type, coordsTarget.x, coordsTarget.y, coordsTarget.z, b.label, a)
            end
        end)
    end
end)

function addToMetabolism(hunger, thirst, alcohol, drugs, health, stamina)
    playerHunger = playerHunger + hunger
    playerThirst = playerThirst + thirst
    playerAlcohol = playerAlcohol + alcohol
    playerDrugs = playerDrugs + drugs
    if health ~= 0 then
        addEntityHealth(health)
    end
    if stamina ~= 0 then
        addEntityStamina(stamina)
    end
end

function addEntityHealth(value)
    local ped = PlayerPedId()
    if (value ~= 0)then
        local health = Citizen.InvokeNative(0x36731AC041289BB1, ped, 0)
        local newHealth = health + tonumber(value)

        if (newHealth > 100) then
            newHealth = 100
        end
        Citizen.InvokeNative(0xC6258F41D86676E0, ped, 0, newHealth)
    end
end

function addEntityStamina(value)
    local ped = PlayerPedId()
    if (value ~= 0) then
        local stamina = Citizen.InvokeNative(0x36731AC041289BB1, ped, 1) 
		if stamina == false then
			stamina = 1
		end
        local newStamina = stamina + tonumber(value)
		
        if (newStamina > 100) then
            newStamina = 100
        end
        Citizen.InvokeNative(0xC6258F41D86676E0, ped, 1, newStamina)
    end
end

if Config.Debug == true then
    Citizen.CreateThread(function()
        TriggerServerEvent('gum_metabolism:checkMeta')
        Citizen.Wait(2000)
        ExecuteCommand("hud")
    end)
end

RegisterNetEvent('gum_metabolism:sendStatus', function(hunger, thirst, alcohol, drugs, dirt)
    playerThirst = thirst
    playerHunger = hunger
    playerAlcohol = alcohol
    playerDrugs = drugs
    playerDirt = dirt
    canSave = true
end)

function createQuickDrop(model, type, coords, label)
    local droppedProp = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
	FreezeEntityPosition(droppedProp, true)
    SetEntityCollision(droppedProp, false, false)
    SetEntityVisible(droppedProp, false, false)
    return droppedProp
end
function requestNetwork(entity)
    NetworkRequestControlOfEntity(entity)
    local timeout = 0
    while not NetworkHasControlOfEntity(entity) do
        timeout = timeout+1
        if timeout > 10 then
            break
        end
        if not DoesEntityExist(entity) then
            break
        end
        Wait(100)
    end
    if NetworkHasControlOfEntity(entity) then
    end
end

RegisterNetEvent('gum_metabolism:takeItem', function()
    sometingInHand = true
    requestNetwork(takeEntity)
    if prepareType == nil then
    else
        if prepareType == "stew" then
            feedInteraction(prepareType)
            return false
        else
            TaskItemInteraction_2(PlayerPedId(), typesTable[prepareType].item, takeEntity, typesTable[prepareType].propId, typesTable[prepareType].interactionState, 1, 0, typesTable[prepareType].any)
        end
    end
    if typesTable[prepareType].add ~= nil then
        Citizen.InvokeNative(0x669655FFB29EF1A9, takeEntity, 0, typesTable[prepareType].add, 1.0)
    end

    local amount = 0
    Citizen.Wait(2000)
    local netId = NetworkGetNetworkIdFromEntity(takeEntity)
    local holdTimer = 0
    while true do
        Wait(fpsTimer())
        if Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == -752898125 or Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == -2123939384 or Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == -1493684811 or Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 1918187558 then
            holdTimer = 0
        end 
        if Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == -316468467 or Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 1204708816 or Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 1661448004 or Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 642357238 then
            holdTimer = holdTimer + 1
            if holdTimer > 30 then
                amount = amount + 0.09
                if droppedProps[netId] ~= nil then
                    if Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 1661448004 or Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 642357238 then
                        droppedProps[netId].percent = droppedProps[netId].percent - 0.175
                    else
                        droppedProps[netId].percent = droppedProps[netId].percent - 4.05
                    end
                    addToMetabolism(Config.Items[takeItem].hunger, Config.Items[takeItem].thirst, Config.Items[takeItem].alcohol, Config.Items[takeItem].drugs, Config.Items[takeItem].health, Config.Items[takeItem].stamina)
                    if droppedProps[netId].percent < 0 then
                        DisableControlAction(0, 0x07B8BEAF, true)
                        droppedProps[netId].percent = 0
                        if Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 1661448004 or Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 642357238 then
                            Wait(3500)
                        else
                            Wait(1000)
                        end
                        droppedProps[netId] = nil
                        api.deleteObj(takeEntity)
                        TriggerServerEvent('gum_metabolism:removeItemProp', netId)
                        sometingInHand = false
                        break
                    end
                end
            else
                amount = amount + 0.01
                if droppedProps[netId] ~= nil then
                    if Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 1661448004 or Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 642357238 then
                        droppedProps[netId].percent = droppedProps[netId].percent - 0.175
                    else
                        droppedProps[netId].percent = droppedProps[netId].percent - 0.55
                    end
                    addToMetabolism(Config.Items[takeItem].hunger, Config.Items[takeItem].thirst, Config.Items[takeItem].alcohol, Config.Items[takeItem].drugs, Config.Items[takeItem].health, Config.Items[takeItem].stamina)
                    if droppedProps[netId].percent < 0 then
                        DisableControlAction(0, 0x07B8BEAF, true)
                        droppedProps[netId].percent = 0
                        if Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 1661448004 or Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 642357238 then
                            Wait(3500)
                        else
                            Wait(1000)
                        end
                        TriggerServerEvent('gum_metabolism:removeItemProp', netId)
                        droppedProps[netId] = nil
                        api.deleteObj(takeEntity)
                        sometingInHand = false
                        break
                    end
                end
            end
        elseif Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == false then
            droppedProps[netId] = nil
            TriggerServerEvent('gum_metabolism:removeItemProp', netId)
            api.deleteObj(takeEntity)
            sometingInHand = false
            break
        elseif amount > 60 then
            takeEntity = 0
            break
        end
    end
end)

function fpsTimer()
    local frameTime = GetFrameTime()
    local frame = 1.0 / frameTime

    local add = 1.0
    local fpsTable = {
        {upperLimit = 30, value = 14},
        {upperLimit = 40, value = 16},
        {upperLimit = 50, value = 18},
        {upperLimit = 60, value = 22},
        {upperLimit = 80, value = 25},
        {upperLimit = 100, value = 27},
        {upperLimit = math.huge, value = 30}
    }

    local tableSize = #fpsTable
    for i = 1, tableSize do
        local v = fpsTable[i]
        if frame < v.upperLimit then
            add = v.value
            break
        end
    end
    return add*2
end

function prepareDrop(model, type, x, y, z, label, id)
    prepareProp = CreateObject(model, x, y, z, false, false, false)
    Citizen.InvokeNative(0x7DFB49BCDB73089A, prepareProp, true)
    FreezeEntityPosition(prepareProp, true)
    SetEntityAlpha(prepareProp, 180, true)
    SetEntityCollision(prepareProp, false, false)
    prepareLabel = label
    prepareType = type
    prepareItemId = id
end

RegisterNetEvent('gum_metabolism:addItem', function(netId, netData)
    droppedProps[netId] = netData
end)

RegisterNetEvent('gum_metabolism:removeItemProp', function(netId)
    if droppedProps[netId] ~= nil then
        droppedProps[netId] = nil
    end
end)

function createDrop(model, type, coords, label, itemId)
    local droppedProp = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
    Citizen.InvokeNative(0x06FAACD625D80CAA, droppedProp)

    local networkId = NetworkGetNetworkIdFromEntity(droppedProp)
    droppedProps[networkId] = {model=GetEntityModel(droppedProp), percent=100, type=type, label=label, itemId=itemId}
    TriggerServerEvent("gum_metabolism:addItem", networkId, droppedProps[networkId])
	-- Citizen.InvokeNative(0x7DFB49BCDB73089A, droppedProp, true)
	FreezeEntityPosition(droppedProp, true)
    return droppedProp
end

RegisterNetEvent('gum_meta_heal:resSetup', function(x, y)
    xRes = x
    yRes = y    
end)

AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() == resourceName) then
        for a,b in pairs(droppedProps) do
            DeleteEntity(NetworkGetEntityFromNetworkId(a))
        end
        if prepareProp ~= nil then
            DeleteEntity(prepareProp)
        end
        AnimpostfxStop("OJDominoBlur")
        Citizen.InvokeNative(0xCAB4DD2D5B2B7246, "OJDominoBlur", 0.0)
        for k,v in pairs(playerEffects) do
            Citizen.InvokeNative(0xCAB4DD2D5B2B7246, v, 0.0)
        end
        
        Citizen.InvokeNative(0x406CCF555B04FAD3, PlayerPedId(), false, 0.0)
        ShakeGameplayCam("DEATH_FAIL_IN_EFFECT_SHAKE", 0.0)
        ShakeGameplayCam("DRUNK_SHAKE", 0.0)
        api.showPrompt('', promptDataTable, false)
        api.showPrompt('', promptDataHand, false)
        api.showPrompt('', promptDataCrounch, false)
        api.showPrompt('', promptDataCigarette, false)
        api.showPrompt('', promptDataPipe, false)
    end
end)

function DrawText3D(x, y, z, text)
	local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
	local px,py,pz=table.unpack(GetGameplayCamCoord())  
	local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
	local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
	local scale = (2/dist)*0.25
	local fov = (2/GetGameplayCamFov())*100
    local scale = scale*fov
	if onScreen then
        SetTextScale(0.0*scale, 0.20*scale)
		SetTextFontForCurrentCommand(1)
		SetTextColor(255,255, 255, 120)
		SetTextCentre(1)
		DisplayText(str,_x,_y)
	end
end


function clearAnimationSkin()
    local random1 = math.random(1, 13)
    local random2 = math.random(1, 13)
    local random3 = math.random(1, 13)
    local random4 = math.random(1, 13)
    local random5 = math.random(1, 13)
    local cleanStates = (playerDirt/5)
    if random1 == 1 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_a", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random1 == 2 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_b", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random1 == 3 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_c", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random1 == 4 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_d", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end   
    if random1 == 5 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_e", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random1 == 6 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_f", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random1 == 7 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_g", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random1 == 8 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_h", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random1 == 9 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_k", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random1 == 10 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_i", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random1 == 11 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_j", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random1 == 12 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_k", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random1 == 13 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_l", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 1 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_a", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 2 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_b", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 3 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_c", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 4 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_d", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end   
    if random2 == 5 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_e", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 6 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_f", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 7 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_g", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 8 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_h", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 9 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_k", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 10 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_i", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 11 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_j", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 12 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_k", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random2 == 13 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_l", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 1 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_a", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 2 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_b", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 3 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_c", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 4 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_d", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end   
    if random3 == 5 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_e", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 6 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_f", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 7 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_g", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 8 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_h", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 9 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_k", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 10 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_i", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 11 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_j", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 12 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_k", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random3 == 13 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_l", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 1 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_a", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 2 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_b", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 3 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_c", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 4 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_d", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end   
    if random4 == 5 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_e", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 6 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_f", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 7 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_g", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 8 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_h", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 9 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_k", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 10 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_i", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 11 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_j", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 12 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_k", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random4 == 13 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_l", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 1 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_a", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 2 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_b", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 3 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_a", "idle_c", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 4 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_d", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end   
    if random5 == 5 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_e", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 6 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_b", "idle_f", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 7 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_g", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 8 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_h", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 9 then      api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_k", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 10 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_c", "idle_i", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 11 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_j", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 12 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_k", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    if random5 == 13 then     api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@idle_d", "idle_l", 1, 4000)        Citizen.Wait(3900)    playerDirt = playerDirt - cleanStates       end
    api.playAnim(PlayerPedId(), "amb_misc@world_human_wash_face_bucket@ground@male_a@stand_exit","exit_front", 1, 2000)
    if (playerDirt < 0) then
        playerDirt = 0
    end
end

function changeCigarette(num)
    if IsPedMale(PlayerPedId()) then
        if num == 0 then
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_c@base","base", 27, -1)
        elseif num == 1 then
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@nervous_stressed@male_b@base", "base", 27, -1)
        elseif num == 2 then
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@male_d@base","base", 27, -1)
        elseif num == 3 then
            api.playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@male_a@base","base", 27, -1)
        end
    else
        if num == 0 then
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_c@base","base", 27, -1)
        elseif num == 1 then
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_b@base","base", 27, -1)
        elseif num == 2 then
            api.playAnim(PlayerPedId(), "amb_rest@world_human_smoking@female_d@base","base", 27, -1)
        elseif num == 3 then
            api.playAnim(PlayerPedId(), "amb_wander@code_human_smoking_wander@female_a@base","base", 27, -1)
        end
    end
    Citizen.Wait(1000)
end

function changeCigar(num)
    if num == 0 then
        api.playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@male_a@base","base", 27, -1)
    elseif num == 1 then
        api.playAnim(PlayerPedId(), "amb_camp@world_camp_dutch_smoke_cigar@gus@base","base", 27, -1)
    end
    Citizen.Wait(2000)
end
