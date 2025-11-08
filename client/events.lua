AddEventHandler("onClientResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    TriggerServerEvent("aprts_consumable:Server:getItems")
    TriggerServerEvent("aprts_consumable:Server:getEffects")
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    blowSmoke()
    if DoesEntityExist(smokeProp) then
        debugPrint("Deleting smoke prop")
        DeleteEntity(smokeProp)
    end
    if DoesEntityExist(foodEntity) then
        debugPrint("Deleting foodEntity")
        DeleteEntity(foodEntity)
    end
end)

RegisterNetEvent("aprts_consumable:Client:LoadItems")
AddEventHandler("aprts_consumable:Client:LoadItems", function(data)
    items = data
    print("Items loaded")
    
end)

RegisterNetEvent("aprts_consumable:Client:LoadEffects")
AddEventHandler("aprts_consumable:Client:LoadEffects", function(data)
    effects = data
    print("Effects loaded")

end)

RegisterNetEvent("aprts_consumable:Client:UseItem")
AddEventHandler("aprts_consumable:Client:UseItem", function(item)
    debugPrint(item.water .. ", " .. item.food .. ", " .. item.health)
    if item.type == "cigar" or item.type == "cigarette" or item.type == "pipe" or item.type == "opiumPipe" or item.type ==
        "longPipe" then
        useSmoke(item)
        return
    end
    local playerPed = PlayerPedId()

    if item.capacity > 1 then
        startEat(item)
    else

        startEat(item)

        if item.return_item ~= nil and item.return_item ~= "" then
            debugPrint("Item used returning " .. item.return_item)
            TriggerServerEvent("aprts_consumable:Server:returnItem", item.return_item)
        end
    end
end)

RegisterNetEvent("aprts_consumable:Client:setEffect")
AddEventHandler("aprts_consumable:Client:setEffect", function(effect_id, duration)
    if effect_id == 0 or effect_id == nil then
        return
    end
    if duration == 0 or duration == nil then
        return
    end
    setEffect(effect_id, duration)
   
end)
