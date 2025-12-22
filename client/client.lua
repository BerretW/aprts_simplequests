local Prompt = nil
local promptGroup = GetRandomIntInRange(0, 0xffffff)

ActiveQuestID = 0

TargetBlip = nil
function debugPrint(msg)
    if Config.Debug == true then
        print("^1[Questy]^0 " .. msg)
    end
end

function notify(text)
    TriggerEvent('notifications:notify', "Questy", text, 15000)
end
function waitForCharacter()
    while not LocalPlayer do
        Citizen.Wait(100)
    end
    while not LocalPlayer.state do
        Citizen.Wait(100)
    end
    while not LocalPlayer.state.Character do
        Citizen.Wait(100)
    end
end

function table.count(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function round(num)
    return math.floor(num * 100 + 0.5) / 100
end

-- Config.Jobs = {
--     {job = 'police', grade = 1},
--     {job = 'doctor', grade = 3}
-- }
function hasJob(jobtable)
    if not jobtable then
        return true
    end
    local pjob = LocalPlayer.state.Character.Job
    local pGrade = LocalPlayer.state.Character.Grade
    for _, v in pairs(jobtable) do
        if v.job == pjob and v.grade <= pGrade then
            return true
        end
    end
    return false
end

function isOpen(timesTable)
    local currentTime = GetClockHours()
    for _, time in pairs(timesTable) do
        if currentTime == time then
            return true
        end
    end
    return false
end
function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

function string.split(str, sep)
    if sep == nil or sep == "" then
        return {str}
    end

    local result = {}
    local pattern = string.format("([^%s]+)", sep)

    for part in string.gmatch(str, pattern) do
        table.insert(result, part)
    end

    return result
end

function GetQuestState(quest)
    local charID = LocalPlayer.state.Character.CharId
    return GetResourceKvpInt("aprts_simplequests:" .. quest .. ":" .. charID)
end

function SetQuestState(quest, value)
    value = clamp(value, 0, 100)
    local charID = LocalPlayer.state.Character.CharId
    SetResourceKvpInt("aprts_simplequests:" .. quest .. ":" .. charID, value)
end

local function parseItemsFromString(itemString) -- "branch,5;wood,1" => {{name="branch",count=5},{name="wood",count=1}}
    if not itemString or itemString == "" then
        return {}
    end
    local items = {}
    local itemPairs = string.split(itemString, ";")
    for _, pair in pairs(itemPairs) do
        local itemData = string.split(pair, ",")
        if #itemData == 2 then
            table.insert(items, {
                name = itemData[1],
                count = tonumber(itemData[2])
            })
        end
    end
    return items
end

local function parseParamForKill(param) -- "a_c_pronghorn_01,3,1,30" => {model="a_c_pronghorn_01",count=3,spawn=true,range=30}
    local data = string.split(param, ",")
    local param = {
        model = data[1],
        count = tonumber(data[2]),
        spawn = data[3] == "1",
        range = tonumber(data[4]) or 30
    }
    return param
end

local function OpenIn(timestable) -- return closest opening hour
    local currentTime = GetClockHours()
    local closest = nil
    for _, time in pairs(timestable) do
        if time > currentTime then
            if not closest then
                closest = time
            elseif time < closest then
                closest = time
            end
        end
    end
    if not closest then
        closest = timestable[1] + 24
    end
    return closest - currentTime
end

function playAnim(entity, dict, name, flag, time, sound)
    print(entity, dict, name, flag, time, sound)
    if sound then
        -- print("Playing sound: " .. sound)
        SendNUIMessage({
            action = 'playSound',
            soundFile = sound,
            volume = 1.0
        })
    end
    -- print("Playing animation: " .. dict .. " - " .. name)
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
    Wait(time)
end

-- SetResourceKvp("aprts_vzor:deht", 0)
-- local deht = GetResourceKvpString("aprts_vzor:deht")

local function prompt()
    Citizen.CreateThread(function()
        local str = "Aktivovat"
        Prompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(Prompt, 0x760A9C6F)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(Prompt, str)
        PromptSetEnabled(Prompt, true)
        PromptSetVisible(Prompt, true)
        PromptSetHoldMode(Prompt, true)
        PromptSetGroup(Prompt, promptGroup)
        PromptRegisterEnd(Prompt)
    end)
end

function CreateBlip(coords, sprite, name)
    -- print("Creating Blip: ")
    -- hash sprite if is string
    if type(sprite) == "string" then
        sprite = GetHashKey(sprite)
    end
    local blip = BlipAddForCoords(1664425300, coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite, 1)
    SetBlipScale(blip, 0.2)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, name)
    return blip
end

function SetBlipStyle(blip, styleHash)
    -- -- hash if stylehash is string
    -- if type(styleHash) == "string" then
    --     styleHash = GetHashKey(styleHash)
    -- end
    -- Citizen.InvokeNative(0x9CB1A1623062F402, blip, styleHash)
end

function createRoute(coords)
    SetWaypointOff()
    Wait(100)
    ClearGpsMultiRoute()
    StartGpsMultiRoute(GetHashKey("COLOR_RED"), true, true)
    AddPointToGpsMultiRoute(coords.x, coords.y, coords.z)
    SetGpsMultiRouteRender(true)
end

function giveItems(items)
    if items then
        TriggerServerEvent("aprts_simplequests:server:giveItems", items)
    end
end

function hasItems(questID, remove)
    local quest = Config.Quests[questID]
    local inventory = exports.vorp_inventory:getInventoryItems()
    print(json.encode(inventory, {
        indent = true
    }))
    local items = parseItemsFromString(quest.target.param)
    local hasAllItems = true
    for _, reqItem in pairs(items) do
        local found = false
        for _, invItem in pairs(inventory) do
            if invItem.name == reqItem.name and invItem.count >= reqItem.count then
                reqItem.label = invItem.label or invItem.name
                found = true
                break
            end
        end
        if not found then
            hasAllItems = false
            break
        end
    end
    if not hasAllItems then
        notify("Nemáš všechny potřebné předměty pro dokončení úkolu.")
        return false
    end
    if remove then
        TriggerServerEvent("aprts_simplequests:server:removeItems", items)
    end
    return true
end

function finishQuest(questID)
    local quest = Config.Quests[questID]
    if quest.target.activation == "delivery" or quest.target.activation == "prop" or quest.target.activation ==
        "talktoNPC" then
        if not hasItems(questID, true) then
            notify("Nemáš všechny potřebné předměty pro dokončení úkolu.")
            return
        end
    end
    notify(quest.target.text)
    giveItems(quest.target.items)
    TriggerServerEvent("aprts_simplequests:server:giveMoney", quest.target.money)
    if quest.target.events and quest.target.events.client then
        for _, event in pairs(quest.target.events.client) do

            TriggerEvent(event.name, event.args[1], event.args[2], event.args[3], event.args[4], event.args[5])
        end
    end
    if quest.target.events and quest.target.events.server then
        for _, event in pairs(quest.target.events.server) do
            TriggerServerEvent(event.name, event.args[1], event.args[2], event.args[3], event.args[4], event.args[5])
        end
    end
    Config.Quests[questID].active = false
    -- print(quest.name, tostring(Config.Quests[questID].active))
    ActiveQuestID = 0
    if TargetBlip then
        RemoveBlip(TargetBlip)
        TargetBlip = nil
    end
    ClearGpsMultiRoute()
    if DoesEntityExist(quest.target.obj) then
        playAnim(quest.target.obj, quest.target.animDict, quest.target.animName, 0, -1, quest.target.sound)
    end
    TriggerServerEvent("aprts_simplequests:server:finishQuest", questID)
    SetQuestState(questID, 100)
    debugPrint("Finished quest: " .. quest.name .. " (ID: " .. questID .. ")")

end

function reqCheck(questID)
    local quest = Config.Quests[questID]
    if not quest then
        return true
    end
    local charId = LocalPlayer.state.Character.id
    if not quest.complete_quests or table.count(quest.complete_quests) == 0 then
        return true
    end
    local completed = false
    -- print(json.encode(quest.complete_quests, {indent = true}))
    for _, reqQuestID in pairs(quest.complete_quests) do

        if Config.Quests[reqQuestID] then
            if Config.Quests[reqQuestID].active == false then
                completed = true
            else
                completed = false
                break
            end
        else
            completed = true
        end
    end
    return completed
end

function ActivateQuest(questID)
    ActiveQuestID = questID
    local quest = Config.Quests[questID]
    if quest.target.coords and (quest.target.blip or quest.target.blip ~= "") and quest.target.blip ~= 0 then
        createRoute(quest.target.coords)
        TargetBlip = CreateBlip(quest.target.coords, quest.target.blip or "blip_mission", quest.name)
        SetBlipStyle(TargetBlip, "BLIP_STYLE_BOUNTY_TARGET")
        --
    end
end

function startQuest(questID)
    local quest = Config.Quests[questID]
    if not quest.active or ActiveQuestID ~= 0 then
        print("Tento úkol není aktivní nebo je aktivní jiný.")
        return
    end
    
    local param = quest.start.param
    if quest.start.activation == "talktoNPC" then
        -- Zkontrolujeme, zda hráč má potřebný item
        local inventory = exports.vorp_inventory:getInventoryItems()
       local items = parseItemsFromString(param)
        for _, reqItem in pairs(items) do
            local found = false
            for _, invItem in pairs(inventory) do
                if invItem.name == reqItem.name and invItem.count >= reqItem.count then
                    reqItem.label = invItem.label or invItem.name
                    found = true
                    break
                end
            end
            if not found then
                notify("Nemáš všechny potřebné předměty pro zahájení úkolu.")
                return
            end
        end
    end
    giveItems(quest.start.items)
    notify(quest.start.text)
    if quest.start.events and quest.start.events.client then
        for _, event in pairs(quest.start.events.client) do
            -- print("Triggering event:", event.name)
            -- print("With args:", event.args)
            TriggerEvent(event.name, event.args[1], event.args[2], event.args[3], event.args[4], event.args[5])
        end
    end
    if quest.start.events and quest.start.events.server then
        for _, event in pairs(quest.start.events.server) do
            TriggerServerEvent(event.name, event.args[1], event.args[2], event.args[3], event.args[4], event.args[5])
        end
    end
    ActivateQuest(questID)
    if DoesEntityExist(quest.start.obj) then
        -- print("Playing start animation")
        -- print("Starting quest animation for quest ID: " .. questID)
        -- print(json.encode(quest.start, {indent = true}))
        -- print(quest.start.obj, quest.start.animDict, quest.start.animName)
        playAnim(quest.start.obj, quest.start.animDict, quest.start.animName, 0, -1, quest.start.sound)
    end
    SetQuestState(questID, 1)
    debugPrint("Started quest: " .. quest.name .. " (ID: " .. questID .. ")")
end

Citizen.CreateThread(function()
    prompt()
    while true do
        local pause = 1000
        local playerPed = PlayerPedId()
        local pcoords = GetEntityCoords(playerPed)

        if ActiveQuestID == 0 then
            for _, quest in pairs(Config.Quests) do
                if reqCheck(quest.id) then

                    if (quest.start.activation == "talktoNPC" or quest.start.activation == "distance" or
                        quest.start.activation == "prop") and quest.active and hasJob(quest.start.jobs) then
                        local dist = #(pcoords -
                                         vector3(quest.start.coords.x, quest.start.coords.y, quest.start.coords.z))
                        if quest.start.activation == "talktoNPC" or quest.start.activation == "prop" then
                            local mesure = 1.2
                            if quest.start.activation == "prop" then
                                mesure = 2.0
                            end
                            if dist < mesure and GetQuestState(quest.id) == 0 then
                                pause = 0
                                PromptSetActiveGroupThisFrame(promptGroup, CreateVarString(10, 'LITERAL_STRING',
                                    quest.start.prompt.groupText))

                                if isOpen(quest.hoursOpen) then
                                    PromptSetEnabled(Prompt, true)
                                    PromptSetText(Prompt, CreateVarString(10, 'LITERAL_STRING', quest.start.prompt.text))
                                    if PromptHasHoldModeCompleted(Prompt) then
                                        startQuest(quest.id)
                                        Wait(500)

                                    end
                                else
                                    local openin = OpenIn(quest.hoursOpen)
                                    PromptSetText(Prompt,
                                        CreateVarString(10, 'LITERAL_STRING', "Budu dostupný v " .. openin))
                                    PromptSetEnabled(Prompt, false)
                                end
                                break

                            end
                        elseif quest.start.activation == "distance" then
                            if dist < tonumber(quest.start.param) then
                                startQuest(quest.id)
                                break
                            end
                        end
                    end
                end
            end
        end
        Citizen.Wait(pause)
    end
end)

Citizen.CreateThread(function()
    AddRelationshipGroup("hostile_group")
    SetRelationshipBetweenGroups(5, GetHashKey("hostile_group"), GetHashKey("PLAYER"))
    SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("hostile_group"))
    while true do
        local pause = 1000
        local playerPed = PlayerPedId()
        local pcoords = GetEntityCoords(playerPed)
        if ActiveQuestID ~= 0 then
            local quest = Config.Quests[ActiveQuestID]
            -- print("Checking quest: " .. quest.name .. " (ID: " .. quest.id .. ")" .. " Active: " ..
            --           tostring(quest.active))
            if (quest.target.activation == "talktoNPC" or quest.target.activation == "distance" or
                quest.target.activation == "prop" or quest.target.activation == "delivery" or quest.target.activation ==
                "kill") and quest.active then
                local dist = #(pcoords - vector3(quest.target.coords.x, quest.target.coords.y, quest.target.coords.z))

                if quest.target.activation == "talktoNPC" or quest.target.activation == "prop" or
                    quest.target.activation == "delivery" then
                    local mesure = 1.2
                    if quest.target.activation == "prop" then
                        mesure = 2.0
                    end
                    -- print(dist, mesure)
                    if dist < mesure then
                        -- print(dist, "<", mesure)
                        pause = 0
                        PromptSetActiveGroupThisFrame(promptGroup, CreateVarString(10, 'LITERAL_STRING',
                            quest.target.prompt.groupText))
                        PromptSetText(Prompt, CreateVarString(10, 'LITERAL_STRING', quest.target.prompt.text))
                        if PromptHasHoldModeCompleted(Prompt) then
                            finishQuest(quest.id)
                            Wait(500)
                        end

                    end
                elseif quest.target.activation == "distance" then
                    if dist < quest.target.param then
                        finishQuest(quest.id)
                    end
                elseif quest.target.activation == "kill" then
                    local param = parseParamForKill(quest.target.param)
                    -- param obsahuje: {model="...", count=..., spawn=true/false, range=...}

                    -- 1. Inicializace počítadel (běží jen jednou při startu logiky)
                    if not quest.target.killedCount then
                        quest.target.killedCount = 0
                        quest.target.killCount = param.count
                        quest.target.processedEntities = {} -- Pro world scan: aby se nezapočítal jeden 2x
                    end

                    local playerPed = PlayerPedId()

                    -- ==============================================================================
                    -- VARIANTA A: SPAWN = TRUE (Script spawne cíle a označí je)
                    -- ==============================================================================
                    if param.spawn then
                        -- Spawnování, pokud ještě neproběhlo
                        if not quest.target.killEntities then
                            if dist < param.range + 30.0 then
                                quest.target.killEntities = {}
                                quest.target.killBlips = {}
                                for i = 1, param.count do
                                    local spawnCoords = vector3(quest.target.coords.x, quest.target.coords.y,
                                        quest.target.coords.z) +
                                                            vector3(math.random(-param.range, param.range),
                                            math.random(-param.range, param.range), 0)

                                    local ped = SpawnPed(param.model, spawnCoords)
                                    -- print("Spawned kill target: " .. param.model .. " | " .. ped)
                                    ClearPedTasks(ped)
                                    TaskCombatPed(ped, playerPed, 0, 16)
                                    SetPedRelationshipGroupHash(ped, GetHashKey("hostile_group"))
                                    -- Přidáme blip a peda do tabulky
                                    table.insert(quest.target.killBlips,
                                        Citizen.InvokeNative(0x23f74c2fda6e7c61, -1230993421, ped))
                                    table.insert(quest.target.killEntities, ped)
                                end
                            end
                        else
                            -- Kontrola stavu spawnutých entit
                            for k, ped in pairs(quest.target.killEntities) do
                                if DoesEntityExist(ped) then
                                    if IsEntityDead(ped) then
                                        -- Započítat kill
                                        quest.target.killedCount = quest.target.killedCount + 1

                                        -- Smazat blip
                                        if quest.target.killBlips and quest.target.killBlips[k] then
                                            RemoveBlip(quest.target.killBlips[k])
                                            quest.target.killBlips[k] = nil
                                        end

                                        -- Vyřadit z kontroly (aby se nepočítal znovu)
                                        quest.target.killEntities[k] = nil

                                        notify("Zabit cíl: " .. quest.target.killedCount .. " / " ..
                                                   quest.target.killCount)
                                    end
                                else
                                    -- Pokud entita despawnula, vyřadíme ji, aby to neházelo error
                                    quest.target.killEntities[k] = nil
                                end
                            end
                        end

                        -- ==============================================================================
                        -- VARIANTA B: SPAWN = FALSE (Lov ve světě - hledá existující zvířata)
                        -- ==============================================================================
                    else
                        -- Skenujeme jen, když jsme blízko zóny úkolu (optimalizace)
                        if dist < param.range + 50.0 then
                            local targetModelHash = GetHashKey(param.model)
                            local allPeds = GetGamePool('CPed')

                            for _, ped in ipairs(allPeds) do
                                -- Je to správný model a je mrtvý?
                                if GetEntityModel(ped) == targetModelHash and IsEntityDead(ped) then

                                    -- Ještě jsme ho nezapočítali?
                                    if not quest.target.processedEntities[ped] then

                                        -- Je v rádiusu úkolu?
                                        local pedCoords = GetEntityCoords(ped)
                                        local distFromZone = #(pedCoords -
                                                                 vector3(quest.target.coords.x, quest.target.coords.y,
                                                quest.target.coords.z))

                                        if distFromZone <= param.range then
                                            -- Zabil ho hráč?
                                            if GetPedSourceOfDeath(ped) == playerPed then
                                                -- Započítat
                                                quest.target.processedEntities[ped] = true
                                                quest.target.killedCount = quest.target.killedCount + 1

                                                notify("Uloveno: " .. quest.target.killedCount .. " / " ..
                                                           quest.target.killCount)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- ==============================================================================
                    -- SPOLEČNÁ KONTROLA DOKONČENÍ
                    -- ==============================================================================
                    if quest.target.killedCount >= quest.target.killCount then
                        -- Úklid blipů (pokud nějaké zbyly z Varianty A)
                        if quest.target.killBlips then
                            for _, blip in pairs(quest.target.killBlips) do
                                RemoveBlip(blip)
                            end
                            quest.target.killBlips = nil
                        end
                        finishQuest(quest.id)
                    end
                end
            end
        end
        Citizen.Wait(pause)
    end
end)
