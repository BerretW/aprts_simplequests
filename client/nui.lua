-- =======================================================
-- NUI.LUA - Logika Questbooku (Deníku) a Admin Menu
-- =======================================================

local isBookOpen = false
local isAdmin = false

-- 1. Přijetí informace o admin právech od serveru
RegisterNetEvent('aprts_simplequests:client:receiveAdminStatus')
AddEventHandler('aprts_simplequests:client:receiveAdminStatus', function(status)
    isAdmin = status
    OpenQuestBookInternal() -- Otevřeme knihu až ve chvíli, kdy víme status
end)

-- 2. Aktualizace stavu questu (vyvoláno admin zásahem)
RegisterNetEvent('aprts_simplequests:client:adminUpdateState')
AddEventHandler('aprts_simplequests:client:adminUpdateState', function(questId, state)
    -- Aktualizace lokální paměti (KVP)
    SetQuestState(questId, state)
    
    -- Logika pro trasování při změně stavu
    if state == 1 then
        -- Pokud admin quest zapnul, můžeme ho rovnou aktivovat (volitelné)
        -- ActivateQuest(questId) 
    elseif state == 0 or state == 100 then
        -- Pokud admin quest vypnul nebo dokončil a hráč ho zrovna sledoval, zrušíme trasu
        if ActiveQuestID == questId then
            DeactivateCurrentQuest()
        end
    end
    
    -- Pokud je kniha otevřená, obnovíme data v UI
    if isBookOpen then
        SendNUIMessage({
            action = "openBook",
            quests = GetQuestDataForUI(),
            isAdmin = isAdmin
        })
        notify("Stav úkolu byl změněn (Admin).")
    end
end)

-- 3. Funkce pro přípravu dat pro HTML/JS
function GetQuestDataForUI()
    local uiData = {
        active = {},
        completed = {},
        all = {} -- Seznam pro adminy (obsahuje vše)
    }

    for id, quest in pairs(Config.Quests) do
        local state = GetQuestState(id)
                -- Získání názvu skupiny
        local gId = quest.groupid or 1 -- Předpokládáme default 1
        local gName = Config.QuestGroups[gId] or "Neznámá skupina ("..gId..")"
        -- Textový popisek stavu
        local sLabel = "Neznámý"
        if Config.QuestStates[state] then sLabel = Config.QuestStates[state] end
        
        -- Objekt pro UI
        local questEntry = {
            id = quest.id,
            groupId = gId,       -- NOVÉ
            groupName = gName,   -- NOVÉ
            name = quest.name,
            image = quest.image,
            description = quest.description,
            start_text = quest.start.text,   -- NOVÉ (pro editaci)
            target_text = quest.target.text, -- NOVÉ (pro editaci)
            state = state,
            stateLabel = Config.QuestStates[state] or "Neznámý",
            isTracking = (ActiveQuestID == quest.id),
            sounds = {}
        }

        -- Logika zvuků
        -- A) Zvuk zadání (Start): Zobrazit vždy, pokud existuje
        if quest.start.sound and quest.start.sound ~= "" then
            table.insert(questEntry.sounds, {label = "Zadání", file = quest.start.sound})
        end
        
        -- B) Zvuk závěru (Target): Zobrazit POUZE pokud je hotovo
        if state == 100 and quest.target.sound and quest.target.sound ~= "" then
             table.insert(questEntry.sounds, {label = "Závěr", file = quest.target.sound})
        end

        -- Třídění do záložek
        if state == 1 then
            table.insert(uiData.active, questEntry)
        elseif state == 100 then
            table.insert(uiData.completed, questEntry)
        end
        
        -- Do "all" dáme všechno (pro admin panel)
        table.insert(uiData.all, questEntry)
    end
    
    -- Seřadíme "all" seznam podle ID, aby v tom měl admin pořádek
    table.sort(uiData.all, function(a, b) return a.id < b.id end)

    return uiData
end

-- 4. Funkce pro otevření (Trigger -> Server Check -> Internal Open)
function OpenQuestBook()
    if isBookOpen then return end
    -- Zeptáme se serveru na práva. Odpověď spustí 'receiveAdminStatus'
    -- TriggerServerEvent('aprts_simplequests:server:checkAdminStatus')
    if LocalPlayer.state.Character.Group == "admin" then
        isAdmin = true
    else
        isAdmin = false
    end
    OpenQuestBookInternal()
end

function OpenQuestBookInternal()
    local data = GetQuestDataForUI()
    isBookOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = "openBook",
        quests = data,
        isAdmin = isAdmin
    })
end

function CloseQuestBook()
    isBookOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "closeBook"
    })
end

-- 5. NUI Callbacky (Reakce na klikání v HTML)

-- Zavření křížkem nebo ESC
RegisterNUICallback('close', function(data, cb)
    CloseQuestBook()
    cb('ok')
end)

-- Sledovat úkol
RegisterNUICallback('setActive', function(data, cb)
    local questId = tonumber(data.questId)
    if questId then
        ActivateQuest(questId)
        notify("Sleduješ úkol: " .. Config.Quests[questId].name)
        
        SendNUIMessage({
            action = "updateTracking",
            activeId = questId
        })
    end
    cb('ok')
end)

-- Přestat sledovat úkol
RegisterNUICallback('stopTracking', function(data, cb)
    DeactivateCurrentQuest()
    
    SendNUIMessage({
        action = "updateTracking",
        activeId = 0
    })
    cb('ok')
end)

-- Admin akce (změna stavu)
RegisterNUICallback('adminSetState', function(data, cb)
    if not isAdmin then return end -- Pojistka
    
    local questId = tonumber(data.questId)
    local state = tonumber(data.state)
    
    TriggerServerEvent('aprts_simplequests:server:adminSetQuestState', questId, state)
    cb('ok')
end)
RegisterNUICallback('adminSaveQuest', function(data, cb)
    if not isAdmin then return end
    TriggerServerEvent('aprts_simplequests:server:adminEditQuest', data)
    cb('ok')
end)
-- 6. Příkazy a Klávesy

RegisterCommand("journal", function() OpenQuestBook() end, false)
RegisterCommand("questbook", function() OpenQuestBook() end, false)

-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(0)
--         -- Klávesa J (0xF3830D8E)
--         if IsControlJustPressed(0, 0xF3830D8E) and not IsPauseMenuActive() then 
--             if not isBookOpen then
--                 OpenQuestBook()
--             else
--                 CloseQuestBook()
--             end
--         end
--     end
-- end)

RegisterNetEvent('aprts_simplequests:client:syncQuestData')
AddEventHandler('aprts_simplequests:client:syncQuestData', function(questId, data)
    if Config.Quests[questId] then
        Config.Quests[questId].name = data.name
        Config.Quests[questId].description = data.description
        Config.Quests[questId].start.text = data.start_text
        Config.Quests[questId].target.text = data.target_text
        
        -- Pokud je admin v menu, refreshneme mu to
        if isAdmin and isBookOpen then
            OpenQuestBookInternal()
        end
    end
end)