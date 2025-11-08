
AddEventHandler("vorp_inventory:useItem")
RegisterServerEvent("vorp_inventory:useItem", function(data)
    local _source = source
    local itemName = data.item
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
    if amount > 0 then
        character.addCurrency(0, amount)
    end
end)
