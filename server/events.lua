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
    while not QuestsLoaded or not CharacterDataLoaded do
        Citizen.Wait(100)
    end
    local playerQuests = json.decode(json.encode(Config.Quests))

    -- Deaktivujeme splněné questy pro tohoto hráče
    for _, questID in ipairs(charQuests[CharID] or {}) do
        if playerQuests[questID] then
            playerQuests[questID].active = false
        end
    end
    -- TriggerClientEvent("aprts_simplequests:client:recieveQuests", _source, playerQuests)
    TriggerClientEvent("aprts_simplequests:client:recieveQuests", _source, playerQuests, Config.QuestGroups)
end)

RegisterServerEvent("vorp_inventory:useItem")
AddEventHandler("vorp_inventory:useItem", function(data)
    local _source = source
    local itemName = data.item
    -- print("Item used: " .. itemName)
    exports.vorp_inventory:getItemByMainId(_source, data.id, function(data)
        if data == nil then
            return
        end
        for _, quest in pairs(Config.Quests) do
            if quest.start.activation == "useItem" and quest.start.param == itemName then
                debugPrint("Triggering useItem for quest start")
                TriggerClientEvent("aprts_simplequests:client:onQuestStartUseItem", _source, quest.id)
            end
            if quest.target.activation == "useItem" and quest.target.param == itemName then
                debugPrint("Triggering useItem for quest target")
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

RegisterServerEvent("aprts_simplequests:server:removeItems")
AddEventHandler("aprts_simplequests:server:removeItems", function(items)
    local _source = source
    for _, item in pairs(items) do
        if exports.vorp_inventory:subItem(_source, item.name, item.count) then
            notify(_source, "Removing item: " .. item.label .. " x" .. item.count)
        else
            notify(_source, "Failed to remove item: " .. item.label .. " x" .. item.count)
        end
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


-- Admin akce: Změna stavu questu
RegisterServerEvent('aprts_simplequests:server:adminSetQuestState')
AddEventHandler('aprts_simplequests:server:adminSetQuestState', function(questId, state)
    local _source = source
    local User = Core.getUser(_source)
    if not User then return end
    local charId = User.getUsedCharacter.charIdentifier
    
    -- Bezpečnostní kontrola, zda je admin (pro jistotu)
    local group = User.getGroup
    if group ~= 'admin' and group ~= 'superadmin' and group ~= 'moderator' then
        print("Hráč " .. _source .. " se pokusil použít admin funkci bez oprávnění.")
        return 
    end

    debugPrint("Admin " .. _source .. " mění quest " .. questId .. " na stav " .. state)

    -- 1. Pokud resetujeme nebo startujeme, musíme smazat záznam o dokončení z DB
    if state == 0 or state == 1 then
        MySQL:execute("DELETE FROM aprts_simplequests_char WHERE charId = @charId AND questID = @questId", {
            ['@charId'] = charId,
            ['@questId'] = questId
        })
    end

    -- 2. Pokud dokončujeme "natvrdo", zapíšeme do DB
    if state == 100 then
        -- Nejprve smažeme, aby nebyl duplikát
        MySQL:execute("DELETE FROM aprts_simplequests_char WHERE charId = @charId AND questID = @questId", {
            ['@charId'] = charId,
            ['@questId'] = questId
        })
        MySQL:execute("INSERT INTO aprts_simplequests_char (charId, questID) VALUES (@charId, @questId)", {
            ['@charId'] = charId,
            ['@questId'] = questId
        })
    end
    
    -- Poslat klientovi info, ať si aktualizuje KVP a UI
    TriggerClientEvent('aprts_simplequests:client:adminUpdateState', _source, questId, state)
end)


-- Přidej globální proměnnou pro skupiny
Config.QuestGroups = {}

-- Funkce pro načtení skupin (Volat v onResourceStart)
function LoadGroups()
    MySQL:execute("SELECT * FROM aprts_simplequests_groups", {}, function(result)
        Config.QuestGroups = {}
        if result then
            for _, row in pairs(result) do
                Config.QuestGroups[row.id] = row.name
            end
        end
        print(('[^2[Quests]^7 Načteno ^5%d^7 skupin questů.'):format(table.count(Config.QuestGroups)))
    end)
end

-- Uprav onResourceStart, aby načítal i skupiny
AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        LoadGroups() -- NOVÉ
        LoadQuests()
        LoadCharacterData()
    end
end)

-- Event pro Admin Editaci Textů
RegisterServerEvent('aprts_simplequests:server:adminEditQuest')
AddEventHandler('aprts_simplequests:server:adminEditQuest', function(data)
    local _source = source
    local User = Core.getUser(_source)
    if not User then return end
    
    -- Admin kontrola
    local group = User.getGroup
    if group ~= 'admin' and group ~= 'superadmin' and group ~= 'moderator' then
        return 
    end

    local qId = data.id
    -- Update Database
    MySQL:execute('UPDATE aprts_simplequests_quests SET name = @name, description = @desc, start_text = @st, target_text = @tt WHERE id = @id', {
        ['@name'] = data.name,
        ['@desc'] = data.description,
        ['@st'] = data.start_text,
        ['@tt'] = data.target_text,
        ['@id'] = qId
    })

    -- Update Live Config na Serveru (aby se změna projevila hned bez restartu)
    if Config.Quests[qId] then
        Config.Quests[qId].name = data.name
        Config.Quests[qId].description = data.description
        Config.Quests[qId].start.text = data.start_text
        Config.Quests[qId].target.text = data.target_text
    end

    debugPrint("Admin " .. _source .. " upravil texty questu " .. qId)
    
    -- Rozeslat aktualizovaná data všem klientům (nebo alespoň adminovi)
    TriggerClientEvent('aprts_simplequests:client:syncQuestData', -1, qId, data)
end)