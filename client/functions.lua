-- =======================================================
-- FUNCTIONS.LUA - Herní mechaniky, animace, blipy
-- =======================================================

QuestPrompt = nil -- Globální proměnná pro prompt
promptGroup = GetRandomIntInRange(0, 0xffffff)
TargetBlip = nil

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

function OpenIn(timestable) -- return closest opening hour
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

function GetQuestState(quest)
    local charID = LocalPlayer.state.Character.CharId
    return GetResourceKvpInt("aprts_simplequests:" .. quest .. ":" .. charID)
end

function SetQuestState(quest, value)
    value = clamp(value, 0, 100)
    local charID = LocalPlayer.state.Character.CharId
    SetResourceKvpInt("aprts_simplequests:" .. quest .. ":" .. charID, value)
end

function playAnim(entity, dict, name, flag, time, sound)
    -- print(entity, dict, name, flag, time, sound)
    if sound then
        SendNUIMessage({
            action = 'playSound',
            soundFile = sound,
            volume = 1.0
        })
    end
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

function SetupPrompt()
    Citizen.CreateThread(function()
        local str = "Aktivovat"
        QuestPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(QuestPrompt, 0x760A9C6F)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(QuestPrompt, str)
        PromptSetEnabled(QuestPrompt, true)
        PromptSetVisible(QuestPrompt, true)
        PromptSetHoldMode(QuestPrompt, true)
        PromptSetGroup(QuestPrompt, promptGroup)
        PromptRegisterEnd(QuestPrompt)
    end)
end

function CreateBlip(coords, sprite, name)
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
    -- print(json.encode(inventory, { indent = true }))
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
            notify("Nemáš všechny potřebné předměty pro dokončení úkolu.")
            return false
        end
    end
    if remove then
        TriggerServerEvent("aprts_simplequests:server:removeItems", items)
    end
    return true
end