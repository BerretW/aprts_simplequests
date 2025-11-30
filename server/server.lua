-- CREATE TABLE IF NOT EXISTS `aprts_simplequests_char` (
--   `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
--   `charId` mediumint(8) unsigned NOT NULL,
--   `questID` smallint(5) unsigned NOT NULL,
--   UNIQUE KEY `Index 1` (`id`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- CREATE TABLE IF NOT EXISTS `aprts_simplequests_quests` (
--   `id` int(11) NOT NULL,
--   `active` tinyint(1) NOT NULL DEFAULT 1,
--   `name` varchar(100) NOT NULL,
--   `description` varchar(255) DEFAULT NULL,
--   `jobs` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`jobs`)),
--   `repeatable` tinyint(1) NOT NULL DEFAULT 0,
--   `start_activation` enum('talktoNPC','distance','useItem','clientEvent') DEFAULT NULL,
--   `start_param` varchar(100) DEFAULT NULL,
--   `start_npc` varchar(50) DEFAULT NULL,
--   `start_coords` varchar(100) DEFAULT NULL,
--   `start_text` varchar(255) DEFAULT NULL,
--   `start_prompt` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`start_prompt`)),
--   `start_items` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`start_items`)),
--   `start_events` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`start_events`)),
--   `target_activation` enum('talktoNPC','distance','useItem','clientEvent') DEFAULT NULL,
--   `target_param` varchar(100) DEFAULT NULL,
--   `target_npc` varchar(50) DEFAULT NULL,
--   `target_blip` varchar(50) DEFAULT NULL,
--   `target_coords` varchar(100) DEFAULT NULL,
--   `target_text` varchar(255) DEFAULT NULL,
--   `target_prompt` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`target_prompt`)),
--   `target_items` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`target_items`)),
--   `target_money` int(11) NOT NULL DEFAULT 0,
--   `target_events` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`target_events`)),
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
MySQL = exports.oxmysql
Core = exports.vorp_core:GetCore()
charQuests = {}


function debugPrint(msg)
    if Config.Debug == true then
        print("^1[Questy]^0 " .. msg)
    end
end
function notify(playerId, message)
    TriggerClientEvent('notifications:notify', playerId, "Questy", message, 15000)
end

function table.count(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function hasJob(player, jobtable)
    local pjob = Player(player).state.Character.Job
    local pGrade = Player(player).state.Character.Grade
    local pLabel = Player(player).state.Character.Label
    for _, v in pairs(jobtable) do
        if v.job == pjob and v.grade <= pGrade and (v.label == "" or v.label == nil or v.label == pLabel) then
            return true
        end
    end
    return false
end

function round(num)
    return math.floor(num * 100 + 0.5) / 100
end

function GetPlayerName(source)
    local user = Core.getUser(source)
    if not user then
        return "nobody"
    end
    local character = user.getUsedCharacter
    local firstname = character.firstname
    local lastname = character.lastname
    return firstname .. " " .. lastname
end

function getTimeStamp()
    local time = 0
    MySQL:execute("SELECT NOW() as time", {}, function(result)
        if result then
            time = result[1].time
        end
    end)
    while time == 0 do
        Wait(100)
    end
    return time
end

function unixToDateTime(unixTime)
    return os.date('%Y-%m-%d %H:%M:%S', unixTime)
end

function vec4FromString(coordString)

    if not coordString or coordString == '' then
        return nil
    end
    local coords = {}
    for val in string.gmatch(coordString, "[^,]+") do
        table.insert(coords, tonumber(val))
    end
    if #coords == 4 then
        return vector4(coords[1], coords[2], coords[3], coords[4])
    elseif #coords == 3 then
        return vector3(coords[1], coords[2], coords[3])
    end
    return nil

end

function DiscordWeb(name, message, footer)
    if Config.WebHook == "" then
        return
    end
    local embed = {{
        ["color"] = Config.DiscordColor,
        ["title"] = "",
        ["description"] = "**" .. name .. "** \n" .. message .. "\n\n",
        ["footer"] = {
            ["text"] = footer
        }
    }}
    PerformHttpRequest(Config.WebHook, function(err, text, headers)
    end, 'POST', json.encode({
        username = Config.ServerName,
        embeds = embed
    }), {
        ['Content-Type'] = 'application/json'
    })
end

function LokiLog(event, player, playerName, message, ...)

    local text = Player(player).state.Character.CharId .. "/" .. playerName .. ": " .. message
    lib.logger(player, event, text, ...)

end

function LOG(player, event, message, ...)
    local playerName = GetPlayerName(player)
    local charID = 0
    if Player(player) and Player(player).state and Player(player).state.Character and
        Player(player).state.Character.CharId then
        charID = Player(player).state.Character.CharId
    end
    local text = charID .. "/" .. playerName .. ": " .. message
    if Config.Debug == true then
        print("^1[" .. event .. "]^0 " .. text)
    end
    DiscordWeb(event .. ", " .. playerName, message, os.date("Datum: %d.%m.%Y Čas: %H:%M:%S"))
    lib.logger(player, event, text, ...)

end

QuestsLoaded = false
function LoadQuests()
    MySQL:execute("SELECT * FROM aprts_simplequests_quests", {}, function(result)
        local tempQuests = {}
        if result and #result > 0 then
            
            -- Pomocná funkce pro bezpečné dekódování JSONu
            local function safeJsonDecode(jsonString, questId, columnName)
                if not jsonString or jsonString == '' or jsonString == 'null' then 
                    return nil 
                end
                
                local success, data = pcall(json.decode, jsonString)
                if success then
                    return data
                else
                    print(('[^1[Quests] CHYBA:^7 Nepodařilo se dekódovat JSON v questu s ID ^5%s^7, sloupec: ^5%s^7. Data v DB jsou pravděpodobně poškozená.'):format(tostring(questId), columnName))
                    return nil -- Vrátíme nil, pokud je JSON neplatný
                end
            end

            for _, quest in ipairs(result) do
                if quest.target_activation == 'distance' then
                    quest.target_param = tonumber(quest.target_param)
                end

                local newQuest = {
                    id = quest.id,
                    active = quest.active,
                    name = quest.name,
                    description = quest.description,
                    hoursOpen = safeJsonDecode(quest.hoursOpen, quest.id, 'hoursOpen') or {},
                    jobs = safeJsonDecode(quest.jobs, quest.id, 'jobs'),
                    bljobs = safeJsonDecode(quest.bljobs, quest.id, 'bljobs') or {},
                    repeatable = quest.repeatable,
                    complete_quests = safeJsonDecode(quest.complete_quests, quest.id, 'complete_quests') or {},
                    start = {
                        activation = quest.start_activation,
                        param = quest.start_param,
                        NPC = quest.start_npc,
                        blip = quest.start_blip or "blip_adversary_small",
                        animDict = quest.start_anim_dict or nil,
                        animName = quest.start_anim_name or nil,
                        coords = vec4FromString(quest.start_coords),
                        sound = quest.start_sound or nil,
                        text = quest.start_text,
                        prompt = safeJsonDecode(quest.start_prompt, quest.id, 'start_prompt'),
                        items = safeJsonDecode(quest.start_items, quest.id, 'start_items') or {},
                        events = safeJsonDecode(quest.start_events, quest.id, 'start_events') or { server = {}, client = {} },
                    },
                    target = {
                        activation = quest.target_activation,
                        param = quest.target_param,
                        NPC = quest.target_npc,
                        blip = quest.target_blip or 0,
                        animDict = quest.target_anim_dict or nil,
                        animName = quest.target_anim_name or nil,
                        coords = vec4FromString(quest.target_coords),
                        sound = quest.target_sound or nil,
                        text = quest.target_text,
                        prompt = safeJsonDecode(quest.target_prompt, quest.id, 'target_prompt'),
                        items = safeJsonDecode(quest.target_items, quest.id, 'target_items') or {},
                        money = quest.target_money or 0,
                        events = safeJsonDecode(quest.target_events, quest.id, 'target_events') or { server = {}, client = {} },
                    }
                }
                tempQuests[quest.id] = newQuest
            end
        end
        
        Config.Quests = tempQuests -- Až zde přepíšeme globální config
        
        if Config.Debug then
            print("Questy:", json.encode(Config.Quests, { indent = true }))
        end
        
        print(('[^2[Quests]^7 Úspěšně načteno ^5%d^7 questů z databáze.'):format(table.count(Config.Quests)))
        QuestsLoaded = true
    end)
end



CharacterDataLoaded = false
function LoadCharacterData()
    MySQL:execute("SELECT * FROM aprts_simplequests_char", {}, function(result)
        charQuests = {}
        if result then
            for _, row in pairs(result) do
                local charID = row.charId
                local questID = row.questID
                if not charQuests[charID] then
                    charQuests[charID] = {}
                end
                table.insert(charQuests[charID], questID)
            end
        end
        CharacterDataLoaded = true
    end)
end
