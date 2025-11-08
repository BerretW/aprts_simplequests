AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        MySQL:execute("SELECT * FROM aprts_consumable", {}, function(result)
            for _, v in pairs(result) do
                v.animation = json.decode(v.animation)
                items[v.id] = v
                exports.vorp_inventory:registerUsableItem(v.item, function(data)
                    local _source = data.source
                    exports.vorp_inventory:closeInventory(_source)

                    local item = exports.vorp_inventory:getItem(_source, v.item, nil, data.item.metadata)
                    if not item then
                        return
                    end -- Pokud item neexistuje, nic nedělat

                    local itemId = item.id
                    local meta = item.metadata or {}

                    -- Nastav kapacitu pokud není
                    if not meta.capacity then
                        meta.capacity = v.capacity
                    end

                    meta.capacity = meta.capacity - 1
                    meta.description = "Zbývá " .. meta.capacity

                    if meta.capacity <= 0 then
                        meta.capacity = meta.capacity + 1
                        meta.description = "Zbývá " .. meta.capacity
                        -- odeber spotřebovaný item
                        if exports.vorp_inventory:subItem(_source, v.item, 1, meta) == true then
                            -- pokud je return_item, vrať ho hráči
                            if v.return_item and v.return_item ~= "" then
                                exports.vorp_inventory:addItem(_source, v.return_item, 1)
                            end
                        else
                            exports.vorp_inventory:subItem(_source, v.item, 1)
                            if v.return_item and v.return_item ~= "" then
                                exports.vorp_inventory:addItem(_source, v.return_item, 1)
                            end
                        end
                    else
                        -- nastav nová metadata
                        exports.vorp_inventory:setItemMetadata(_source, itemId, meta)
                    end

                    TriggerClientEvent("aprts_consumable:Client:UseItem", _source, v)
                    local nutriData = {
                        protein = v.protein,
                        carbs = v.carbs,
                        fats = v.fat,
                        vitamins = v.vitamins,
                    }
                    TriggerClientEvent("aprts_nutrition:consumeItem", _source, nutriData)
                end)
            end
        end)

        MySQL:execute("SELECT * FROM aprts_consumable_effects", {}, function(result)
            for _, v in pairs(result) do
                v.effects = json.decode(v.effects)
                effects[v.id] = v
            end
        end)
    end
end)

RegisterServerEvent("aprts_consumable:Server:getItems")
AddEventHandler("aprts_consumable:Server:getItems", function()
    local src = source
    while not next(items) do
        Wait(100)
    end
    TriggerClientEvent("aprts_consumable:Client:LoadItems", src, items)
end)

RegisterServerEvent("aprts_consumable:Server:getEffects")
AddEventHandler("aprts_consumable:Server:getEffects", function()
    local src = source
    while not next(effects) do
        Wait(100)
    end
    TriggerClientEvent("aprts_consumable:Client:LoadEffects", src, effects)
end)
