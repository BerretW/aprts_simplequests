AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        LoadQuests()
        LoadCharacterData()
    end
end)

RegisterServerEvent("aprts_simplequests:server:requestQuests")
AddEventHandler("aprts_simplequests:server:requestQuests", function()
    local _source = source
    local player = Player(_source)
    if player == nil then
        return
    end
    local CharID = player.state.Character.CharId

    debugPrint("aprts_simplequests:server:requestQuests called by player " .. _source)
    while not QuestsLoaded do
        Citizen.Wait(100)
    end

    while not CharacterDataLoaded do
        Citizen.Wait(100)
    end
    for _, questID in pairs(charQuests[CharID] or {}) do
        if Config.Quests[questID] then
            Config.Quests[questID].active = false
        end
    end
    TriggerClientEvent("aprts_simplequests:client:recieveQuests", _source, Config.Quests)
end)

RegisterServerEvent("vorp_inventory:useItem")
AddEventHandler("vorp_inventory:useItem", function(data)
    local _source = source
    local itemName = data.item
    print("Item used: " .. itemName)
    exports.vorp_inventory:getItemByMainId(_source, data.id, function(data)
        if data == nil then
            return
        end
        for _, quest in pairs(Config.Quests) do
            if quest.start.activation == "useItem" and quest.start.param == itemName then
                print("Triggering useItem for quest start")
                TriggerClientEvent("aprts_simplequests:client:onQuestStartUseItem", _source, quest.id)
            end
            if quest.target.activation == "useItem" and quest.target.param == itemName then
                print("Triggering useItem for quest target")
                TriggerClientEvent("aprts_simplequests:client:onQuestTargetUseItem", _source, quest.id)
            end
        end
    end)
end)

RegisterServerEvent("aprts_simplequests:server:finishQuest")
AddEventHandler("aprts_simplequests:server:finishQuest", function(questID)
    local _source = source
    local player = Player(_source)
    if player == nil then
        return
    end
    local quest = Config.Quests[questID]
    local charID = Player(_source).state.Character.CharId

    if not charQuests[charID] then
        charQuests[charID] = {}
    end
    table.insert(charQuests[charID], questID)
    debugPrint("Player " .. _source .. " completed quest " .. questID)
    if quest.repeatable == false then
        -- Mark quest as inactive for this player
        debugPrint("Marking quest " .. questID .. " as completed for charID " .. charID)
        MySQL:execute("INSERT INTO aprts_simplequests_char (charid, questid) VALUES (@charid, @questid)", {
            ['@charid'] = charID,
            ['@questid'] = questID
        })
    end
    

end)


RegisterServerEvent("aprts_simplequests:server:giveItems")
AddEventHandler("aprts_simplequests:server:giveItems", function(items)
    local _source = source
    for _, item in pairs(items) do
        -- TriggerEvent('inventory:addItem', _source, item.name, item.count)
        exports.vorp_inventory:addItem(_source, item.name, item.count, item.meta or {})
        notify(_source, "Giving item: " .. item.name .. " x" .. item.count)
    end
end)

RegisterServerEvent("aprts_simplequests:server:giveMoney")
AddEventHandler("aprts_simplequests:server:giveMoney", function(amount)
    local _source = source
    local user = Core.getUser(_source)
    if not user then
        return
    end
    local character = user.getUsedCharacter
    if amount and amount > 0 then
        character.addCurrency(0, amount)
    end
end)
