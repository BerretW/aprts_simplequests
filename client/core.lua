-- =======================================================
-- CORE.LUA - Logika správy questů (Start/Finish)
-- =======================================================

ActiveQuestID = 0

function reqCheck(questID)
    local quest = Config.Quests[questID]
    if not quest then
        return true
    end
    if not quest.complete_quests or table.count(quest.complete_quests) == 0 then
        return true
    end
    local completed = false
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
        playAnim(quest.start.obj, quest.start.animDict, quest.start.animName, 0, -1, quest.start.sound)
    end
    
    SetQuestState(questID, 1)
    debugPrint("Started quest: " .. quest.name .. " (ID: " .. questID .. ")")
end

function finishQuest(questID)
    local quest = Config.Quests[questID]
    if quest.target.activation == "delivery" or quest.target.activation == "prop" or quest.target.activation == "talktoNPC" then
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
    ActiveQuestID = 0
    
    if TargetBlip then
        RemoveBlip(TargetBlip)
        TargetBlip = nil
    end
    ClearGpsMultiRoute()
    
    if DoesEntityExist(quest.target.obj) then
        playAnim(quest.target.obj, quest.target.animDict, quest.target.animName, 0, 10, quest.target.sound)
        DeleteEntity(quest.target.obj)
    end
    
    TriggerServerEvent("aprts_simplequests:server:finishQuest", questID)
    SetQuestState(questID, 100)
    debugPrint("Finished quest: " .. quest.name .. " (ID: " .. questID .. ")")
end

function DeactivateCurrentQuest()
    if ActiveQuestID ~= 0 then
        debugPrint("Deactivating quest ID: " .. ActiveQuestID)
        ActiveQuestID = 0
        if TargetBlip then
            RemoveBlip(TargetBlip)
            TargetBlip = nil
        end
        ClearGpsMultiRoute()
        notify("Sledování úkolu zrušeno.")
    end
end