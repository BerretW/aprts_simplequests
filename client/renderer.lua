local function LoadModel(model)
    local model = GetHashKey(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(10)
    end
end

local function spawnProp(prop, coords, h)
    local hash = GetHashKey(prop)
    LoadModel(prop)
    local object = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(object, h)
    SetModelAsNoLongerNeeded(hash)
    PlaceObjectOnGroundProperly(object)
    FreezeEntityPosition(object, true)
    return object
end

Citizen.CreateThread(function()
    while true do
        local pause = 1000

        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)


        Citizen.Wait(pause)
    end
end)
