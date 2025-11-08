currentEffect = {}
consumingItem = nil

function debugPrint(msg)
    if Config.Debug == true then
        print("^1[SCRIPT]^0 " .. msg)
    end
end

function notify(text)
    TriggerEvent('notifications:notify', "SCRIPT", text, 3000)
end

function table.count(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end
local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end
function fadeOutEffect(effect, current, max)
    if effect then
        local fadeOut = current
        while fadeOut > max do
            fadeOut = fadeOut - 0.01
            AnimpostfxSetStrength(effect, fadeOut)
            Citizen.Wait(50)
        end
        if max == 0 then
            AnimpostfxStop(effect)
        end
    end
end

function fadeInEffect(effect, current, max)
    if effect then
        local fadeIn = current
        while fadeIn < max do
            fadeIn = fadeIn + 0.01
            AnimpostfxSetStrength(effect, fadeIn)
            Citizen.Wait(50)
        end
    end
end

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
    }
}

function GetStat(stat)
    local charID = LocalPlayer.state.Character.CharId
    return GetResourceKvpInt("aprts_consumable:" .. stat .. ":" .. charID)
end

function SetStat(stat, value)
    value = clamp(value, 0, 100)
    local charID = LocalPlayer.state.Character.CharId
    SetResourceKvpInt("aprts_consumable:" .. stat .. ":" .. charID, value)
end

function consume()
    local playerPed = PlayerPedId()
    local charID = LocalPlayer.state.Character.CharId
    local alcohol = GetStat("alcohol")
    local toxin = GetStat("toxin")
    if alcohol > 0 then

        if not AnimpostfxIsRunning(Config.AlcoholLevel1Effect) then
            AnimpostfxPlay(Config.AlcoholLevel1Effect)
            fadeInEffect(Config.AlcoholLevel1Effect, alcohol, alcohol / 100)
        end

        Citizen.InvokeNative(0xCAB4DD2D5B2B7246, Config.AlcoholLevel1Effect, alcohol / 100)

        SetPedDrunkness(playerPed, true, alcohol / 100)
    else
        -- fadeOutEffect(Config.AlcoholLevel1Effect)
        AnimpostfxStop(Config.AlcoholLevel1Effect)
        SetPedDrunkness(playerPed, false, alcohol / 100)
    end

    if toxin > 0 then

        if not AnimpostfxIsRunning(Config.ToxinLevel1Effect) then
            AnimpostfxPlay(Config.ToxinLevel1Effect)
            fadeInEffect(Config.ToxinLevel1Effect, toxin, toxin / 100)
        end
        Citizen.InvokeNative(0xCAB4DD2D5B2B7246, Config.ToxinLevel1Effect, toxin / 100)

    else
        -- fadeOutEffect(Config.ToxinLevel1Effect)
        AnimpostfxStop(Config.ToxinLevel1Effect)
    end

    if toxin > 30 then
        local chance = math.random(1, 100)
        if chance < 20 + toxin then
            SetEntityHealth(playerPed, GetEntityHealth(playerPed) - 10)
        end
    end
end

function setEffect(effectID,duration)
    if effectID == 0 or effectID == nil then
        return
    end
    if duration == 0 or duration == nil then
        return
    end
    debugPrint("Setting effect: " .. effectID .. " for " .. duration .. " seconds")
    if currentEffect[effectID] == nil then
        currentEffect[effectID] = duration
        debugPrint("Starting Effect: " .. effects[effectID].label)
        for v,k in pairs(effects[effectID].effects) do
            debugPrint("AnimpostfxPlay: " .. k)
            AnimpostfxPlay(k)
        end
    else
        currentEffect[effectID] = currentEffect[effectID] + duration
    end
end

Citizen.CreateThread(function()
    while true do
        local pause = 1000
        local playerPed = PlayerPedId()
        for effect,duration in pairs(currentEffect) do
            if duration > 0 then
                currentEffect[effect] = currentEffect[effect] - 1
                if currentEffect[effect] <= 0 then
                    debugPrint("Stopping effect: " .. effects[effect].label)
                    for v,k in pairs(effects[effect].effects) do
                        AnimpostfxStop(k)
                        debugPrint("AnimpostfxStop: " .. k)
                    end
                    currentEffect[effect] = nil
                end
            end
        end
        Citizen.Wait(pause)
    end
end)

Citizen.CreateThread(function()
    while not LocalPlayer do
        Citizen.Wait(100)
    end
    while not LocalPlayer.state do
        Citizen.Wait(100)
    end
    while not LocalPlayer.state.Character do
        Citizen.Wait(100)
    end
    while true do
        local pause = 60000
        local playerPed = PlayerPedId()
        local charID = LocalPlayer.state.Character.CharId
        
        Citizen.Wait(pause)

        local alcohol = GetStat("alcohol") - 1
        local toxin = GetStat("toxin") - 1

        alcohol = math.max(0, alcohol)
        toxin = math.max(0, toxin)
        if alcohol >= 0 then
            SetStat("alcohol", alcohol)
            debugPrint("Alkohol: " .. alcohol)
        end
        if toxin >= 0 then
            SetStat("toxin", toxin)
            debugPrint("Toxin: " .. toxin)
        end
        consume()
    end
end)

function playAnim(entity, dict, name, flag, time)
    RequestAnimDict(dict)
    local waitSkip = 0
    while not HasAnimDictLoaded(dict) do
        waitSkip = waitSkip + 1
        if waitSkip > 100 then
            break
        end
        Citizen.Wait(0)
    end
    TaskPlayAnim(entity, dict, name, 1.0, 1.0, time, flag, 0, true, 0, false, 0, false)
end

function addPlayerOuterHealth(percent)

    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)
    debugPrint("Přidávám outer health:" .. percent .. "/" .. health)
    local newHealth = health + percent

    playAnim(ped, "mech_inventory@item@stimulants@inject@quick", "quick_stimulant_inject_rhand", -1, 0)
    newHealth = math.min(newHealth, 600)
    SetEntityHealth(ped, newHealth)

end

function addPlayerInnerHealth(percent)
    local playerPed = PlayerPedId()
    local innerHealth = Citizen.InvokeNative(0x36731AC041289BB1, playerPed, 0)
    if innerHealth == false then
        innerHealth = 0
    end
    debugPrint("Přidávám inner health:" .. percent .. "/" .. innerHealth)
    local newHealth = tonumber(innerHealth) + percent

    if 100 - tonumber(innerHealth) < percent then

        playAnim(playerPed, "amb_rest_drunk@world_human_drinking@male_a@idle_a", "idle_a", -1, 0)
        Citizen.InvokeNative(0xC6258F41D86676E0, playerPed, 0, newHealth)
        Citizen.InvokeNative(0xDE1B1907A83A1550, playerPed, 1065352316)
        -- Wait(percent * 1000)
    end
end

function  addPlayerOuterStamina(percent)
    local playerPed = PlayerPedId()
    local stamina = GetPedStamina(playerPed)
    debugPrint("Přidávám outer stamina:" .. percent .. "/" .. stamina)
    local newStamina = stamina + percent
    newStamina = math.min(newStamina, 135)
    ChangePedStamina(playerPed, percent)
end

function addPlayerInnerStamina(percent)
    local playerPed = PlayerPedId()
    local stamina = GetAttributeCoreValue(playerPed, 1)
    debugPrint("Přidávám inner stamina:" .. percent .. "/" .. stamina)
    local newStamina = stamina + percent
    newStamina = math.min(newStamina, 100)
    SetAttributeCoreValue(playerPed, 1, newStamina)
end