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
    TriggerServerEvent("aprts_simplequests:server:finishQuest", questID)
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
            print("Triggering event:", event.name)
            print("With args:", event.args)
            TriggerEvent(event.name, event.args[1], event.args[2], event.args[3], event.args[4], event.args[5])
        end
    end
    if quest.start.events and quest.start.events.server then
        for _, event in pairs(quest.start.events.server) do
            TriggerServerEvent(event.name, event.args[1], event.args[2], event.args[3], event.args[4], event.args[5])
        end
    end
    if quest.target.coords and quest.target.blip then
        createRoute(quest.target.coords)
       TargetBlip = CreateBlip(quest.target.coords, quest.target.blip or "blip_mission", quest.name)
       SetBlipStyle(TargetBlip, "BLIP_STYLE_BOUNTY_TARGET")
       --
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
