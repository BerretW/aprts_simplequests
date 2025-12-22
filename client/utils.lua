-- =======================================================
-- UTILS.LUA - Pomocné funkce, matematika, debug
-- =======================================================

function debugPrint(msg)
    if Config.Debug == true then
        print("^1[Questy]^0 " .. msg)
    end
end

function notify(text)
    TriggerEvent('notifications:notify', "Questy", text, 15000)
end

function waitForCharacter()
    while not LocalPlayer do
        Citizen.Wait(100)
    end
    while not LocalPlayer.state do
        Citizen.Wait(100)
    end
    while not LocalPlayer.state.Character do
        Citizen.Wait(100)
    end
end

function table.count(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function round(num)
    return math.floor(num * 100 + 0.5) / 100
end

function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

function string.split(str, sep)
    if sep == nil or sep == "" then
        return {str}
    end

    local result = {}
    local pattern = string.format("([^%s]+)", sep)

    for part in string.gmatch(str, pattern) do
        table.insert(result, part)
    end

    return result
end

function parseItemsFromString(itemString) -- "branch,5;wood,1" => {{name="branch",count=5},{name="wood",count=1}}
    if not itemString or itemString == "" then
        return {}
    end
    local items = {}
    local itemPairs = string.split(itemString, ";")
    for _, pair in pairs(itemPairs) do
        local itemData = string.split(pair, ",")
        if #itemData == 2 then
            table.insert(items, {
                name = itemData[1],
                count = tonumber(itemData[2])
            })
        end
    end
    return items
end

function parseParamForKill(param) -- "model,spawn_count,kill_count,agresive,spawn_region,kill_region"
    local data = string.split(param, ",")
    local param = {
        model = data[1],
        spawn_count = tonumber(data[2]),
        kill_count = tonumber(data[3]),
        aggressive = data[4] == "true",
        spawn_region = tonumber(data[5]),
        kill_region = tonumber(data[6])
    }
    return param
end