AddEventHandler("onClientResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    waitForCharacter()
    TriggerServerEvent("aprts_simplequests:server:requestQuests")

end)

RegisterNetEvent("aprts_simplequests:client:recieveQuests")
AddEventHandler("aprts_simplequests:client:recieveQuests", function(quests)
    debugPrint("Received quests from server")
    for _, quest in pairs(quests) do
        debugPrint("Loading quest: " .. quest.name)
        Config.Quests[quest.id] = quest
    end
    for _, quest in pairs(Config.Quests) do
        if quest.start.activation == "clientEvent" and quest.active and reqCheck(quest.id) then
            debugPrint("Registering client event for quest start: " .. quest.start.param)
            AddEventHandler(quest.start.param, function()
                ActiveQuestID = quest.id
                startQuest(quest.id)

            end)
        end
        if quest.target.activation == "clientEvent" and quest.active then
            debugPrint("Registering client event for quest target: " .. quest.target.param)
            AddEventHandler(quest.target.param, function()
                if ActiveQuestID ~= quest.id then
                    notify("Tento úkol jsi ještě nezačal!")
                    return
                end
                finishQuest(quest.id)
            end)
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    for _, quest in pairs(Config.Quests) do
        if DoesEntityExist(quest.start.obj) then
            DeleteEntity(quest.start.obj)
            quest.start.obj = nil
        end
        if DoesEntityExist(quest.target.obj) then
            DeleteEntity(quest.target.obj)
            quest.target.obj = nil
        end
        if quest.start.blipOBJ then
            RemoveBlip(quest.start.blipOBJ)
            quest.start.blipOBJ = nil
        end
    end
    if TargetBlip then
        RemoveBlip(TargetBlip)
        TargetBlip = nil
    end
end)

RegisterNetEvent("aprts_simplequests:client:finishActiveQuest")
AddEventHandler("aprts_simplequests:client:finishActiveQuest", function()
    local quest = Config.Quests[ActiveQuestID]
    if not quest then
        return
    end
    print(json.encode(quest, {
        indent = true
    }))
    if quest.active == false then
        notify("Tento úkol není aktivní.")
        return
    end
    finishQuest(ActiveQuestID)
end)

RegisterNetEvent("aprts_simplequests:client:onQuestStartUseItem")
AddEventHandler("aprts_simplequests:client:onQuestStartUseItem", function(questId)
    local quest = Config.Quests[questId]
    if quest.active == false or not reqCheck(questId) then
        print("Tento úkol není aktivní.")
        return
    end
    startQuest(questId)
end)

RegisterNetEvent("aprts_simplequests:client:onQuestTargetUseItem")
AddEventHandler("aprts_simplequests:client:onQuestTargetUseItem", function(questId)
    local quest = Config.Quests[questId]
    if ActiveQuestID ~= questId then
        print("Tento úkol jsi ještě nezačal!")
        return
    end
    finishQuest(questId)
end)
