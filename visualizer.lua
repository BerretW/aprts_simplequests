function drawMarkerBig(x, y, z)
    Citizen.InvokeNative(0x2A32FAA57B937173, 0x94FDAE17, x, y, z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0.6, 100, 100, 20,
        20.0, 0, 0, 2, 0, 0, 0, 0)
end

Citizen.CreateThread(function()
    while true do
        local pause = 3000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        if ActiveQuestID ~= 0 then
            local quest = Config.Quests[ActiveQuestID]
            if quest and quest.target.coords and
                (quest.target.activation == "distance" or quest.target.activation == "talktoNPC") then

                local targetCoords = vector3(quest.target.coords.x, quest.target.coords.y, quest.target.coords.z)
                local distance = #(playerCoords - targetCoords)
                -- print(distance)
                if distance < 20.0 then
                    drawMarkerBig(targetCoords.x, targetCoords.y, targetCoords.z)
                    
                    pause = 0
                end
            end
        end
        Citizen.Wait(pause)
    end
end)
