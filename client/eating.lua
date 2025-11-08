local primaryPrompt, dropPrompt = nil, nil
local promptGroup = GetRandomIntInRange(0, 0xffffff)
foodEntity = nil
local useCount = 0
currentItem = nil

local propsAttachmentCoords = {
    ["p_mugcoffee01x"] = { x = 0.05, y = 0.0, z = 0.01, rotX = 0.0, rotY = 194.0, rotZ = -299.0 },
    ["s_inv_tonic01x"] = { x = 0.05, y = 0.0, z = 0.01, rotX = 0.0, rotY = 194.0, rotZ = -299.0 },
    ["p_bottlebeer01a_1"] = { x = 0.07, y = -0.02, z = 0.1, rotX = -19.0, rotY = 197.0, rotZ = -299.0 },
    ["p_bottlebeer01a_2"] = { x = 0.07, y = -0.02, z = 0.1, rotX = -19.0, rotY = 197.0, rotZ = -299.0 },
    ["s_brandy01x"] = { x = 0.07, y = -0.02, z = 0.1, rotX = -19.0, rotY = 197.0, rotZ = -299.0 },
    ["s_agedpiraterum01x"] = { x = 0.08, y = -0.01, z = 0.13, rotX = -19.0, rotY = 197.0, rotZ = -299.0 },
    ["s_inv_whiskey02x"] = { x = 0.07, y = -0.02, z = 0.1, rotX = -19.0, rotY = 197.0, rotZ = -299.0 },
    ["s_dropperbottle01xa"] = { x = 0.07, y = -0.02, z = 0.1, rotX = -19.0, rotY = 197.0, rotZ = -299.0 },
    ["p_bottlebeer04x"] = { x = 0.07, y = -0.02, z = 0.1, rotX = -19.0, rotY = 197.0, rotZ = -299.0 },
    ["p_bottlewine02x"] = { x = 0.14, y = -0.02, z = 0.23, rotX = -20.0, rotY = 197.0, rotZ = -305.0 },
    ["p_bottlewine03x"] = { x = 0.14, y = -0.02, z = 0.23, rotX = -20.0, rotY = 197.0, rotZ = -305.0 },
    ["p_bottlewine01x"] = { x = 0.14, y = -0.02, z = 0.23, rotX = -20.0, rotY = 197.0, rotZ = -305.0 },
    ["p_bottle003x"] = { x = 0.13, y = -0.01, z = 0.23, rotX = -19.0, rotY = 197.0, rotZ = -299.0 },
    ["p_bottletequila01x"] = { x = 0.07, y = -0.02, z = 0.1, rotX = -19.0, rotY = 197.0, rotZ = -299.0 },
    ["s_wineglass01x_red"] = { x = 0.03, y = -0.03, z = 0.05, rotX = 0.0, rotY = 194.0, rotZ = 0.0 },
}

local defaultAttachmentCoords = { x = 0.01, y = -0.04, z = 0.05, rotX = 4.0, rotY = 175.0, rotZ = 0.0 }

local function createPrompt(label, key, group)
    local prompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(prompt, key)
    PromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', label))
    PromptSetEnabled(prompt, true)
    PromptSetVisible(prompt, true)
    PromptSetHoldMode(prompt, true)
    PromptSetStandardMode(prompt, false)
    PromptSetGroup(prompt, group)
    PromptRegisterEnd(prompt)
    debugPrint("Prompt '" .. label .. "' created.")
    return prompt
end

local function attachEntityToHand(entity)
    local playerPed = PlayerPedId()
    local boneIndex = GetEntityBoneIndexByName(playerPed, "SKEL_R_Finger12")
    --AttachEntityToEntity(entity, playerPed, boneIndex, 0.02, 0.028, 0.001, 15.0, 175.0, 0.0, true, true, false, true, 1, true)

    -- Better attachment with custom coordinates
    local model = GetEntityModel(entity) -- returns model hash, not name
    local found = false

    for k, v in pairs(propsAttachmentCoords) do
        if model == GetHashKey(k) then
            found = true
            debugPrint("Using custom attachment " .. entity .. " coordinates for model: " .. k .. " at " .. v.x .. ", " .. v.y .. ", " .. v.z)
            debugPrint("Rotation: " .. v.rotX .. ", " .. v.rotY .. ", " .. v.rotZ)
            -- Attach with custom coordinates
            AttachEntityToEntity(entity, playerPed, boneIndex, v.x, v.y, v.z, v.rotX, v.rotY, v.rotZ, false, false, false, false, 0, true, false, false)
        end
    end

    if not found then
        debugPrint("Using default attachment coordinates for model: " .. model)
        AttachEntityToEntity(entity, playerPed, boneIndex, defaultAttachmentCoords.x, defaultAttachmentCoords.y, defaultAttachmentCoords.z,
                defaultAttachmentCoords.rotX, defaultAttachmentCoords.rotY, defaultAttachmentCoords.rotZ, false, false, false, false, 0, true, false, false)
    end
end

local function createHandProp(model, coords)
    if not model or model == "" then
        debugPrint("No model provided for hand prop creation.")
        return nil
    end
    if foodEntity then
        DeleteObject(foodEntity)
        foodEntity = nil
    end
    debugPrint("Creating hand prop for model: " .. model)
    local prop = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    SetEntityVisible(prop, true)
    debugPrint("Hand prop created.")
    return prop
end

local function setupPrompts()
    Citizen.CreateThread(function()
        primaryPrompt = createPrompt("Použít", Config.Key, promptGroup)
        dropPrompt = createPrompt("Zahodit", Config.Key2, promptGroup)
        debugPrint("Prompts setup complete.")
    end)
end

function PlayAnimDiscardItem()
    local playerPed = PlayerPedId()
    local dict = "mech_pickup@trash@pocket"
    local anim = "drop_front"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(100)
    end
    debugPrint("Discarding item animation started.")
    TaskPlayAnim(playerPed, dict, anim, 1.0, 8.0, 5000, 31, 0.0, false, false, false)
    Wait(5000)
    ClearPedSecondaryTask(playerPed)
    debugPrint("Discarding item animation finished.")
end

function PlayAnimDrink()
    debugPrint("Starting drink animation (prop in hand).")
    local playerPed = PlayerPedId()
    local dict = "amb_rest_drunk@world_human_drinking@male_a@idle_a"
    local anim = "idle_a"

    --[[if not IsPedMale(playerPed) then
        dict = "amb_rest_drunk@world_human_drinking@female_a@idle_b"
        anim = "idle_e"
    end]]

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(100)
    end
    --Wait(1000)
    TaskPlayAnim(playerPed, dict, anim, 0.0, 0.0, -1, 27, 0.0, false, false, false)
    Wait(6000)
    --ClearPedSecondaryTask(playerPed)
    debugPrint("Drink animation finished.")
end

function PlayAnimEat()
    debugPrint("Starting eat animation (prop in hand).")
    local playerPed = PlayerPedId()
    local dict = "mech_inventory@clothing@bandana"
    local anim = "NECK_2_FACE_RH"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(100)
    end
    Wait(1000)
    TaskPlayAnim(playerPed, dict, anim, 1.0, 8.0, 5000, 31, 0.0, false, false, false)
    Wait(6000)
    ClearPedSecondaryTask(playerPed)
    debugPrint("Eat animation finished.")
end

function PlayAnimSyring()
    debugPrint("Starting eat animation (prop in hand).")
    local playerPed = PlayerPedId()
    local dict = "mech_inventory@item@stimulants@inject@quick"
    local anim = "quick_stimulant_inject_lhand"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(100)
    end
    Wait(1000)
    TaskPlayAnim(playerPed, dict, anim, 1.0, 8.0, 5000, 31, 0.0, false, false, false)
    Wait(6000)
    ClearPedSecondaryTask(playerPed)
    debugPrint("Syringe animation finished.")
end

-- Interakce pro bottle: Podobné jako plate, ale jen PlayAnimDrink a "Napít se"
function drinkInteraction()
    local playerPed = PlayerPedId()
    local pause = 1000
    local drinking = false
    local idle = false
    local first = true

    RequestAnimDict("amb_rest_drunk@world_human_drinking@male_a@base")
    while (not HasAnimDictLoaded("amb_rest_drunk@world_human_drinking@male_a@base")) do
        Wait(100)
    end

    while DoesEntityExist(foodEntity) and currentItem and useCount > 0 do

        PromptSetActiveGroupThisFrame(promptGroup, CreateVarString(10, 'LITERAL_STRING', "Pití"))
        pause = 0
        PromptSetText(primaryPrompt, CreateVarString(10, 'LITERAL_STRING', "Napít se"))
        PromptSetText(dropPrompt, CreateVarString(10, 'LITERAL_STRING', "Zahodit"))

        if PromptHasHoldModeCompleted(primaryPrompt) then
            drinking = true
            idle = false

            debugPrint("Prompt hold for drink completed. Consuming one sip.")
            useCount = useCount - 1

            TriggerEvent('vorpmetabolism:changeValue', 'Thirst', tonumber(currentItem.water))
            TriggerEvent('vorpmetabolism:changeValue', 'Hunger', tonumber(currentItem.food))

            addPlayerInnerHealth(tonumber(currentItem.innerHealth))
            addPlayerOuterHealth(tonumber(currentItem.outerHealth))
            addPlayerInnerStamina(tonumber(currentItem.innerStamina))
            addPlayerOuterStamina(tonumber(currentItem.outerStamina))

            local alcohol = GetStat("alcohol")
            SetStat("alcohol", alcohol + currentItem.alcohol)
            debugPrint("Napil jsem se a mám alkoholu: " .. alcohol)
            local toxin = GetStat("toxin")
            SetStat("toxin", toxin + currentItem.toxin)
            debugPrint("Napil jsem se a mám toxinu: " .. toxin)
            PlayAnimDrink()
            debugPrint("Sip consumed. Remaining: " .. useCount)

            if useCount <= 0 then
                debugPrint("No sips left, removing bottle.")
                DeleteObject(foodEntity)
                foodEntity = nil
                currentItem = nil
                debugPrint("Bottle finished.")
                ClearPedSecondaryTask(playerPed)
                break
            end
            consume()
            setEffect(currentItem.effect_id, currentItem.effect_duration)
            pause = 1000

            drinking = false
        end

        if PromptHasHoldModeCompleted(dropPrompt) then
            debugPrint("Drop prompt hold completed, discarding bottle.")
            -- PlayAnimDiscardItem()
            -- DeleteObject(foodEntity)
            -- foodEntity = nil
            useCount = 0
            currentItem = nil
            debugPrint("Bottle dropped, reset done.")
            ClearPedSecondaryTask(playerPed)
            pause = 1000
            break
        end

        if not drinking and not idle then
            idle = true

            local increaseTime = 0.0
            if first then
                increaseTime = 1.0
                first = false
            end

            TaskPlayAnim(playerPed, "amb_rest_drunk@world_human_drinking@male_a@base", "base", increaseTime, increaseTime, -1, 27, 0.0, false, false, false)
        end

        Citizen.Wait(pause)
    end
end

-- Interakce pro plate: Jíst lžící
function feedInteraction()
    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    Citizen.Wait(300)
    TaskItemInteraction_2(playerPed, 599184882, foodEntity, GetHashKey("p_bowl04x_stew_ph_l_hand"),
        GetHashKey('EAT_STEW_BOWL_BASE'), 3, 0, 0.0)
    local spoon = CreateObject(GetHashKey("p_spoon01x"), pCoords, true, true, false, false, true)
    TaskItemInteraction_2(playerPed, 599184882, spoon, GetHashKey("p_spoon01x_ph_r_hand"),
        GetHashKey('EAT_STEW_BOWL_BASE'), 3, 0, 1.0)

    Citizen.Wait(1500)
    -- Citizen.InvokeNative(0x669655FFB29EF1A9, foodEntity, 0, "Stew_Fill", 0.5)
    local pause = 1000
    while DoesEntityExist(foodEntity) and currentItem and useCount > 0 do

        pause = 0

        if Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) == 1776449982 then
            notify("Najedl ses")
            debugPrint("Prompt hold for eat completed. Consuming one bite.")
            useCount = useCount - 1

            TriggerEvent('vorpmetabolism:changeValue', 'Thirst', tonumber(currentItem.water))
            TriggerEvent('vorpmetabolism:changeValue', 'Hunger', tonumber(currentItem.food))

            -- addPlayerInnerHealth(tonumber(currentItem.innerHealth))
            -- addPlayerOuterHealth(tonumber(currentItem.outerHealth))
            addPlayerInnerStamina(tonumber(currentItem.innerStamina))
            addPlayerOuterStamina(tonumber(currentItem.outerStamina))

            local alcohol = GetStat("alcohol")
            SetStat("alcohol", alcohol + currentItem.alcohol)
            local toxin = GetStat("toxin")
            SetStat("toxin", toxin + currentItem.toxin)

            debugPrint("Bite consumed. Remaining: " .. useCount)

            if useCount <= 0 then
                debugPrint("No bites left, removing plate and spoon.")
                DeleteObject(spoon)
                DeleteObject(foodEntity)
                spoon = nil
                foodEntity = nil
                currentItem = nil
                debugPrint("Plate finished.")
                break
            end
            consume()
            setEffect(currentItem.effect_id, currentItem.effect_duration)
            pause = 5000
        end
        if not Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D, PlayerPedId()) then
            notify("Dojedl jsi")
            debugPrint("Drop prompt hold completed, discarding plate.")
            -- PlayAnimDiscardItem()
            DeleteObject(spoon)
            DeleteObject(foodEntity)
            spoon = nil
            foodEntity = nil
            useCount = 0
            currentItem = nil
            debugPrint("Plate dropped, reset done.")
            break
        end

        Citizen.Wait(pause)
    end
    DeleteObject(spoon)
    DeleteObject(foodEntity)
    spoon = nil
    foodEntity = nil
    currentItem = nil
end

function startEat(item)
    debugPrint("startEat called. Item: " .. item.item .. ", Type: " .. item.type)
    currentItem = item
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    if item.type == "snack" then
        foodEntity = createHandProp(item.prop, coords)
        attachEntityToHand(foodEntity)
        debugPrint("Single-use snack, consuming now.")
        PlayAnimEat()
        TriggerEvent('vorpmetabolism:changeValue', 'Thirst', tonumber(item.water))
        TriggerEvent('vorpmetabolism:changeValue', 'Hunger', tonumber(item.food))

        addPlayerInnerHealth(tonumber(item.innerHealth))
        addPlayerOuterHealth(tonumber(item.outerHealth))
        addPlayerInnerStamina(tonumber(item.innerStamina))
        addPlayerOuterStamina(tonumber(item.outerStamina))

        local alcohol = GetStat("alcohol")
        SetStat("alcohol", alcohol + item.alcohol)
        local toxin = GetStat("toxin")
        SetStat("toxin", toxin + item.toxin)

        DetachEntity(foodEntity, true, false)
        DeleteObject(foodEntity)
        foodEntity = nil
        debugPrint("Single-use snack consumed.")
        consume()
        print(json.encode(item, { indent = true }))
        print("Effect ID: " .. currentItem.effect_id)
        print("Effect Duration: " .. currentItem.effect_duration)
        setEffect(currentItem.effect_id, currentItem.effect_duration)
    elseif item.type == "shot" or item.type == "glass" then
        foodEntity = createHandProp(item.prop, coords)
        attachEntityToHand(foodEntity)
        debugPrint("Single-use drink, consuming now.")
        PlayAnimDrink()
        TriggerEvent('vorpmetabolism:changeValue', 'Thirst', tonumber(item.water))
        TriggerEvent('vorpmetabolism:changeValue', 'Hunger', tonumber(item.food))

        addPlayerInnerHealth(tonumber(item.innerHealth))
        addPlayerOuterHealth(tonumber(item.outerHealth))
        addPlayerInnerStamina(tonumber(item.innerStamina))
        addPlayerOuterStamina(tonumber(item.outerStamina))

        local alcohol = GetStat("alcohol")
        SetStat("alcohol", alcohol + item.alcohol)
        local toxin = GetStat("toxin")
        SetStat("toxin", toxin + item.toxin)

        DetachEntity(foodEntity, true, false)
        DeleteObject(foodEntity)
        foodEntity = nil
        debugPrint("Single-use drink consumed.")
        consume()
        setEffect(currentItem.effect_id, currentItem.effect_duration)
    elseif item.type == "bottle" then
        debugPrint("Multi-use bottle setup. 10 sips available.")
        useCount = 10
        foodEntity = createHandProp(item.prop, coords)
        attachEntityToHand(foodEntity)
        debugPrint("Bottle ready with " .. useCount .. " sips.")
        drinkInteraction() -- Funkce pro pití z lahve s prompty
        DetachEntity(foodEntity, true, false)
        DeleteObject(foodEntity)
        foodEntity = nil

    elseif item.type == "plate" then
        debugPrint("Multi-use plate setup. 10 bites available.")
        useCount = 10
        local modelHash = GetHashKey(item.prop)
        foodEntity = CreateObject(modelHash, coords, true, true, false)
        attachEntityToHand(foodEntity)
        feedInteraction() -- Funkce pro jídlo z talíře s lžící
        DetachEntity(foodEntity, true, false)
        DeleteObject(foodEntity)
        foodEntity = nil
    elseif item.type == "syringe" then
        foodEntity = createHandProp(item.prop, coords)
        attachEntityToHand(foodEntity)
        debugPrint("Single-use snack, consuming now.")

        TriggerEvent('vorpmetabolism:changeValue', 'Thirst', tonumber(item.water))
        TriggerEvent('vorpmetabolism:changeValue', 'Hunger', tonumber(item.food))
        PlayAnimSyring()
        addPlayerInnerHealth(tonumber(item.innerHealth))
        addPlayerOuterHealth(tonumber(item.outerHealth))
        addPlayerInnerStamina(tonumber(item.innerStamina))
        addPlayerOuterStamina(tonumber(item.outerStamina))

        local alcohol = GetStat("alcohol")
        SetStat("alcohol", alcohol + item.alcohol)
        local toxin = GetStat("toxin")
        SetStat("toxin", toxin + item.toxin)

        DetachEntity(foodEntity, true, false)
        DeleteObject(foodEntity)
        foodEntity = nil
        debugPrint("Single-use snack consumed.")
        consume()
        setEffect(currentItem.effect_id, currentItem.effect_duration)
    end
end

Citizen.CreateThread(function()
    setupPrompts()

end)

