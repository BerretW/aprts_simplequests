local function LoadModel(model)
    local model = GetHashKey(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(10)
    end
    return model
end
function SpawnPed(model, coords)
    debugPrint('Spawning ped: ' .. model .. ' at coords: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)
    model = LoadModel(model)
    
    local ped = CreatePed(model, coords.x, coords.y, coords.z, false, true, true)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)

    PlaceEntityOnGroundProperly(ped)
    SetModelAsNoLongerNeeded(model)
    
    return ped
end


local function spawnNPC(model, x, y, z)
    local modelHash = LoadModel(model)
    local npc_ped = CreatePed(model, x, y, z, false, false, false, false)
    PlaceEntityOnGroundProperly(npc_ped)
    Citizen.InvokeNative(0x283978A15512B2FE, npc_ped, true)
    print('npc_ped: ' .. npc_ped)
    SetEntityHeading(npc_ped, 0.0)
    SetEntityCanBeDamaged(npc_ped, false)
    SetEntityInvincible(npc_ped, true)
    FreezeEntityPosition(npc_ped, true)
    SetBlockingOfNonTemporaryEvents(npc_ped, true)
    SetEntityCompletelyDisableCollision(npc_ped, false, false)

    Citizen.InvokeNative(0xC163DAC52AC975D3, npc_ped, 6)
    Citizen.InvokeNative(0xC163DAC52AC975D3, npc_ped, 0)
    Citizen.InvokeNative(0xC163DAC52AC975D3, npc_ped, 1)
    Citizen.InvokeNative(0xC163DAC52AC975D3, npc_ped, 2)

    SetModelAsNoLongerNeeded(modelHash)
    return npc_ped
end

Citizen.CreateThread(function()
    while true do
        local pause = 3000

        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)
        local dist = 0.0
        for _, quest in pairs(Config.Quests) do
            if reqCheck(quest.id) then
                if not quest.active then
                    if DoesEntityExist(quest.start.obj) then
                        -- DeleteEntity(quest.start.obj)
                        -- quest.start.obj = nil
                    end
                    if DoesEntityExist(quest.target.obj) then
                        DeleteEntity(quest.target.obj)
                        quest.target.obj = nil
                    end
                else
                    if quest.start.coords and quest.start.NPC then
                        dist = #(playerPos - vector3(quest.start.coords.x, quest.start.coords.y, quest.start.coords.z))
                        if dist < 30.0 and GetQuestState(quest.id) ~= 100 then
                            if not DoesEntityExist(quest.start.obj) then
                                if quest.start.activation == "prop" then
                                    -- spawn prop instead of NPC
                                    quest.start.obj = CreateObject(GetHashKey(quest.start.NPC), quest.start.coords.x,
                                        quest.start.coords.y, quest.start.coords.z, false, false, false, false, false)

                                else
                                    quest.start.obj = spawnNPC(quest.start.NPC, quest.start.coords.x,
                                        quest.start.coords.y, quest.start.coords.z)

                                end
                                SetEntityHeading(quest.start.obj, quest.start.coords.w)
                            end
                        else
                            if DoesEntityExist(quest.start.obj) then
                                DeleteEntity(quest.start.obj)
                                quest.start.obj = nil
                            end
                        end
                    end
                    if quest.target.coords and quest.target.NPC then
                        dist = #(playerPos -
                                   vector3(quest.target.coords.x, quest.target.coords.y, quest.target.coords.z))
                        if dist < 30.0 then
                            if not DoesEntityExist(quest.target.obj) then

                                if quest.target.activation == "prop" then
                                    -- spawn prop instead of NPC
                                    quest.target.obj = CreateObject(GetHashKey(quest.target.NPC), quest.target.coords.x,
                                        quest.target.coords.y, quest.target.coords.z, false, false, false, false, false)

                                elseif quest.target.activation ~= "kill" then
                                    quest.target.obj = spawnNPC(quest.target.NPC, quest.target.coords.x,
                                        quest.target.coords.y, quest.target.coords.z)
                                end
                                SetEntityHeading(quest.target.obj, quest.target.coords.w)
                            end
                        else
                            if DoesEntityExist(quest.target.obj) then
                                DeleteEntity(quest.target.obj)
                                quest.target.obj = nil
                            end
                        end
                    end
                end
            end
        end
        Citizen.Wait(pause)
    end
end)
