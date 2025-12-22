-- =======================================================
-- THREADS.LUA - Hlavní smyčky (Loops)
-- =======================================================

-- 1. Setup Promptu a Startovací smyčka
Citizen.CreateThread(function()
    SetupPrompt() -- Volání z functions.lua
    
    while true do
        local pause = 1000
        local playerPed = PlayerPedId()
        local pcoords = GetEntityCoords(playerPed)

        if ActiveQuestID == 0 then
            for _, quest in pairs(Config.Quests) do
                if reqCheck(quest.id) then
                    if (quest.start.activation == "talktoNPC" or quest.start.activation == "distance" or
                        quest.start.activation == "prop") and quest.active and hasJob(quest.start.jobs) then
                        
                        local dist = #(pcoords - vector3(quest.start.coords.x, quest.start.coords.y, quest.start.coords.z))
                        
                        if quest.start.activation == "talktoNPC" or quest.start.activation == "prop" then
                            local mesure = 1.2
                            if quest.start.activation == "prop" then mesure = 2.0 end
                            
                            if dist < mesure and GetQuestState(quest.id) == 0 then
                                pause = 0
                                PromptSetActiveGroupThisFrame(promptGroup, CreateVarString(10, 'LITERAL_STRING', quest.start.prompt.groupText))

                                if isOpen(quest.hoursOpen) then
                                    PromptSetEnabled(QuestPrompt, true)
                                    PromptSetText(QuestPrompt, CreateVarString(10, 'LITERAL_STRING', quest.start.prompt.text))
                                    if PromptHasHoldModeCompleted(QuestPrompt) then
                                        startQuest(quest.id)
                                        Wait(500)
                                    end
                                else
                                    local openin = OpenIn(quest.hoursOpen)
                                    PromptSetText(QuestPrompt, CreateVarString(10, 'LITERAL_STRING', "Budu dostupný v " .. openin))
                                    PromptSetEnabled(QuestPrompt, false)
                                end
                                break
                            end
                        elseif quest.start.activation == "distance" then
                            if dist < tonumber(quest.start.param) then
                                startQuest(quest.id)
                                break
                            end
                        end
                    end
                end
            end
        end
        Citizen.Wait(pause)
    end
end)

-- 2. Target / Hostile / Kill Logic Smyčka
Citizen.CreateThread(function()
    AddRelationshipGroup("hostile_group")
    SetRelationshipBetweenGroups(5, GetHashKey("hostile_group"), GetHashKey("PLAYER"))
    SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("hostile_group"))
    
    while true do
        local pause = 1000
        local playerPed = PlayerPedId()
        local pcoords = GetEntityCoords(playerPed)
        
        if ActiveQuestID ~= 0 then
            local quest = Config.Quests[ActiveQuestID]

            if (quest.target.activation == "talktoNPC" or quest.target.activation == "distance" or
                quest.target.activation == "prop" or quest.target.activation == "delivery" or quest.target.activation == "kill") and quest.active then
                
                local dist = #(pcoords - vector3(quest.target.coords.x, quest.target.coords.y, quest.target.coords.z))

                if quest.target.activation == "talktoNPC" or quest.target.activation == "prop" or quest.target.activation == "delivery" then
                    local mesure = 1.2
                    if quest.target.activation == "prop" then mesure = 2.0 end
                    
                    if dist < mesure then
                        pause = 0
                        PromptSetActiveGroupThisFrame(promptGroup, CreateVarString(10, 'LITERAL_STRING', quest.target.prompt.groupText))
                        PromptSetText(QuestPrompt, CreateVarString(10, 'LITERAL_STRING', quest.target.prompt.text))
                        if PromptHasHoldModeCompleted(QuestPrompt) then
                            finishQuest(quest.id)
                            Wait(500)
                        end
                    end
                    
                elseif quest.target.activation == "distance" then
                    if dist < tonumber(quest.target.param) then
                        finishQuest(quest.id)
                    end
                    
                elseif quest.target.activation == "kill" then
                    local param = parseParamForKill(quest.target.param)
                    
                    -- Inicializace počítadel
                    if not quest.target.killedCount then
                        quest.target.killedCount = 0
                        quest.target.killCount = param.kill_count
                        quest.target.processedEntities = {} 
                    end

                    -- VARIANTA A: SPAWN = TRUE
                    if param.spawn_count > 0 then
                        if not quest.target.killEntities then
                            if dist < param.kill_region + 50.0 then
                                quest.target.killEntities = {}
                                -- quest.target.killBlips = {}
                                for i = 1, param.spawn_count do
                                    local spawnCoords = vector3(quest.target.coords.x, quest.target.coords.y, quest.target.coords.z) +
                                                        vector3(math.random(-param.spawn_region, param.spawn_region), math.random(-param.spawn_region, param.spawn_region), 0)
                                    local ped = SpawnPed(param.model, spawnCoords)
                                    ClearPedTasks(ped)
                                    if param.aggressive then
                                        TaskCombatPed(ped, playerPed, 0, 16)
                                        SetPedRelationshipGroupHash(ped, GetHashKey("hostile_group"))
                                    end
                                    -- table.insert(quest.target.killBlips, Citizen.InvokeNative(0x23f74c2fda6e7c61, -1230993421, ped))
                                    table.insert(quest.target.killEntities, ped)
                                end
                            end
                        else
                            for k, ped in pairs(quest.target.killEntities) do
                                if DoesEntityExist(ped) then
                                    if IsEntityDead(ped) then
                                        quest.target.killedCount = quest.target.killedCount + 1
                                        -- if quest.target.killBlips and quest.target.killBlips[k] then
                                        --     RemoveBlip(quest.target.killBlips[k])
                                        --     quest.target.killBlips[k] = nil
                                        -- end
                                        quest.target.killEntities[k] = nil
                                        notify("Zabit cíl: " .. quest.target.killedCount .. " / " .. quest.target.killCount)
                                    end
                                else
                                    quest.target.killEntities[k] = nil
                                end
                            end
                        end

                    -- VARIANTA B: SPAWN = FALSE (Lov)
                    else
                        if dist < param.kill_region + 50.0 then
                            local targetModelHash = GetHashKey(param.model)
                            local allPeds = GetGamePool('CPed')

                            for _, ped in ipairs(allPeds) do
                                if GetEntityModel(ped) == targetModelHash and IsEntityDead(ped) then
                                    if not quest.target.processedEntities[ped] then
                                        local pedCoords = GetEntityCoords(ped)
                                        local distFromZone = #(pedCoords - vector3(quest.target.coords.x, quest.target.coords.y, quest.target.coords.z))

                                        if distFromZone <= param.kill_region then
                                            if GetPedSourceOfDeath(ped) == playerPed then
                                                quest.target.processedEntities[ped] = true
                                                quest.target.killedCount = quest.target.killedCount + 1
                                                notify("Uloveno: " .. quest.target.killedCount .. " / " .. quest.target.killCount)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- KONTROLA DOKONČENÍ
                    if quest.target.killedCount >= quest.target.killCount then
                        -- if quest.target.killBlips then
                        --     for _, blip in pairs(quest.target.killBlips) do
                        --         RemoveBlip(blip)
                        --     end
                        --     quest.target.killBlips = nil
                        -- end
                        finishQuest(quest.id)
                    end
                end
            end
        end
        Citizen.Wait(pause)
    end
end)