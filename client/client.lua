local Prompt = nil
local promptGroup = GetRandomIntInRange(0, 0xffffff)

ActiveQuestID = 0

Progressbar = exports["feather-progressbar"]:initiate()
playingAnimation = false
TargetBlip = nil
function debugPrint(msg)
    if Config.Debug == true then
        print("^1[Questy]^0 " .. msg)
    end
end

function notify(text)
    TriggerEvent('notifications:notify', "Questy", text, 6000)
end
local function waitForCharacter()
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
function playAnim(entity, dict, name, flag, time)
    playingAnimation = true
    RequestAnimDict(dict)
    local waitSkip = 0
    while not HasAnimDictLoaded(dict) do
        waitSkip = waitSkip + 1
        if waitSkip > 100 then
            break
        end
        Citizen.Wait(0)
    end

    Progressbar.start("Něco dělám", time, function()
    end, 'linear', 'rgba(255, 255, 255, 0.8)', '20vw', 'rgba(255, 255, 255, 0.1)', 'rgba(211, 11, 21, 0.5)')

    TaskPlayAnim(entity, dict, name, 1.0, 1.0, time, flag, 0, true, 0, false, 0, false)
    Wait(time)
    playingAnimation = false
end

function equipProp(model, bone, coords)
    local ped = PlayerPedId()
    local playerPos = GetEntityCoords(ped)
    local mainProp = CreateObject(model, playerPos.x, playerPos.y, playerPos.z + 0.2, true, true, true)
    local boneIndex = GetEntityBoneIndexByName(ped, bone)
    AttachEntityToEntity(mainProp, ped, boneIndex, coords.x, coords.y, coords.z, coords.xr, coords.yr, coords.zr, true,
        true, false, true, 1, true)
    return mainProp
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
    -- hash if stylehash is string
    if type(styleHash) == "string" then
        styleHash = GetHashKey(styleHash)
    end
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, styleHash)
end

function isActive()
    local currentHour = GetClockHours()
    if currentHour >= Config.ActiveTimeStart or currentHour < Config.ActiveTimeEnd then
        return true
    end
    return false
end

function isGreenTime()
    local year, month, day, hour, minute, second = GetPosixTime()
    hour = tonumber(hour) + tonumber(Config.DST) -- Přidáme DST, pokud je potřeba
    if hour > 23 then
        hour = hour - 24 -- Oprava, pokud hodina přesáhne 23
    end
    if hour >= Config.GreenTimeStart and hour < Config.GreenTimeEnd then
        return true
    end
    return false
end

CreateThread(function()
    while true do
        local pause = 1000
        if menuOpen == true or PlayingAnimation == true then
            DisableActions(PlayerPedId())
            DisableBodyActions(PlayerPedId())
            pause = 0
        end
        Citizen.Wait(pause)
    end
end)

function DisableBodyActions(ped)
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x27D1C284, true) -- loot
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x399C6619, true) -- loot
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x41AC83D1, true) -- loot
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xBE8593AF, true) -- INPUT_PICKUP_CARRIABLE2
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xEB2AC491, true) -- INPUT_PICKUP_CARRIABLE
end
function DisableActions(ped)
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xA987235F, true) -- LookLeftRight
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xD2047988, true) -- LookUpDown
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x39CCABD5, true) -- VehicleMouseControlOverride

    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x4D8FB4C1, true) -- disable left/right
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xFDA83190, true) -- disable forward/back
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xDB096B85, true) -- INPUT_DUCK
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x8FFC75D6, true) -- disable sprint

    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x9DF54706, true) -- veh turn left
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x97A8FD98, true) -- veh turn right
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x5B9FD4E2, true) -- veh forward
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x6E1F639B, true) -- veh backwards
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xFEFAB9B4, true) -- disable exit vehicle

    Citizen.InvokeNative(0x2970929FD5F9FC89, ped, true) -- Disable weapon firing
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x07CE1E61, true) -- disable attack
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xF84FA74F, true) -- disable aim
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xAC4BD4F1, true) -- disable weapon select
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x73846677, true) -- disable weapon
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x0AF99998, true) -- disable weapon
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xB2F377E8, true) -- disable melee
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xADEAF48C, true) -- disable melee
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

function finishQuest(questID)
    local quest = Config.Quests[questID]
    notify(quest.target.text)
    giveItems(quest.target.items)
    TriggerServerEvent("aprts_simplequests:server:giveMoney", quest.start.money)
    if quest.target.events and quest.target.events.client then
        for _, event in pairs(quest.target.events.client) do
            TriggerEvent(event.name, event.args)
        end
    end
    if quest.target.events and quest.target.events.server then
        for _, event in pairs(quest.target.events.server) do
            TriggerServerEvent(event.name, event.args)
        end
    end
    Config.Quests[questID].active = false
    -- print(quest.name, tostring(Config.Quests[questID].active))
    ActiveQuestID = 0
    if TargetBlip then
        RemoveBlip(TargetBlip)
        TargetBlip = nil
    end
end

function startQuest(questID)
    local quest = Config.Quests[questID]
    if not quest.active or ActiveQuestID ~= 0 then
        print("Tento úkol není aktivní nebo je aktivní jiný.")
        return
    end
    ActiveQuestID = questID
    giveItems(quest.start.items)
    notify(quest.start.text)
    if quest.start.events and quest.start.events.client then
        for _, event in pairs(quest.start.events.client) do
            TriggerEvent(event.name, event.args)
        end
    end
    if quest.start.events and quest.start.events.server then
        for _, event in pairs(quest.start.events.server) do
            TriggerServerEvent(event.name, event.args)
        end
    end
    if quest.target.coords and quest.target.blip then
        createRoute(quest.target.coords)
       TargetBlip = CreateBlip(quest.target.coords, quest.target.blip or "blip_mission", quest.name)
    end
end

Citizen.CreateThread(function()
    prompt()
    while true do
        local pause = 1000
        local playerPed = PlayerPedId()
        local pcoords = GetEntityCoords(playerPed)
        if ActiveQuestID == 0 then
            for _, quest in pairs(Config.Quests) do

                if (quest.start.activation == "talktoNPC" or quest.start.activation == "distance") and quest.active ==
                    true and hasJob(quest.start.jobs) then
                    local dist = #(pcoords - vector3(quest.start.coords.x, quest.start.coords.y, quest.start.coords.z))
                    if quest.start.activation == "talktoNPC" then
                        if dist < 1.2 then
                            pause = 0
                            PromptSetActiveGroupThisFrame(promptGroup, CreateVarString(10, 'LITERAL_STRING',
                                quest.start.prompt.groupText))
                            PromptSetText(Prompt, CreateVarString(10, 'LITERAL_STRING', quest.start.prompt.text))
                            if PromptHasHoldModeCompleted(Prompt) then
                                startQuest(quest.id)
                                Wait(500)
                            end
                            break
                        end
                    elseif quest.start.activation == "distance" then
                        if dist < quest.start.param then
                            startQuest(quest.id)
                            break
                        end
                    end
                end
            end

        end
        Citizen.Wait(pause)
    end
end)

-- target part
Citizen.CreateThread(function()

    while true do
        local pause = 1000
        local playerPed = PlayerPedId()
        local pcoords = GetEntityCoords(playerPed)
        if ActiveQuestID ~= 0 then
            local quest = Config.Quests[ActiveQuestID]

            if (quest.target.activation == "talktoNPC" or quest.target.activation == "distance") and quest.active then
                local dist = #(pcoords - vector3(quest.target.coords.x, quest.target.coords.y, quest.target.coords.z))
                -- print(dist)
                if quest.target.activation == "talktoNPC" then
                    if dist < 1.2 then
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
                end
            end

        end
        Citizen.Wait(pause)
    end
end)
