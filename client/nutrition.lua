-- aprts_nutrition/client.lua
-- REVIZE 2: Responzivní systém + cena za regeneraci zdraví
local punishmentSystem = false

local NAMESPACE = "aprts_consumable"

-- ===== KONFIGURACE =====
local TICK_MS = 5000 -- 5 sekund
local CLAMP_MIN, CLAMP_MAX = 1.0, 100.0

-- ===== NOVÉ: Cena za aktivní regeneraci zdraví (za 1 TICK) =====
-- Tyto hodnoty se odečtou POUZE pokud se hráč aktivně léčí (nemá plné HP)
local REGEN_COST_PER_TICK = {
    protein = 2.0, -- Tělo potřebuje proteiny na opravu tkání
    fats = 1.0, -- Dlouhodobá energie pro proces léčení
    carbs = 3.0, -- Rychlá energie pro metabolické procesy
    vitamins = 1.0 -- Vitamíny jsou klíčové pro imunitní odpověď a opravy
}
-- -------------------------------------------------------------------
local DEBUF_TIMERS = {
    fatigue = 0,
    hunger = 0,
    thirst = 0
}

local NUTRI_DEBUF_ACTIVE = {
    protein = false,
    fats = false,
    carbs = false,
    vitamins = false
}
-- Hodnoty úbytku za MINUTU (skript si je sám přepočítá pro kratší tick)
local DECAY_PER_MINUTE = {
    IDLE = {
        protein = 0.4,
        fats = 0.4,
        carbs = 1.5,
        vitamins = 0.5
    },
    RUN = {
        protein = 0.6,
        fats = 0.6,
        carbs = 3.2,
        vitamins = 0.7
    },
    RIDE = {
        protein = 0.5,
        fats = 0.5,
        carbs = 1.2,
        vitamins = 0.6
    }
}
local ticks_per_minute = 60000 / TICK_MS
local DECAY_PER_TICK = {}
for state, values in pairs(DECAY_PER_MINUTE) do
    DECAY_PER_TICK[state] = {}
    for nutrient, value in pairs(values) do
        DECAY_PER_TICK[state][nutrient] = value / ticks_per_minute
    end
end

-- Konfigurace odtoku do VORP metabolismu (za 1 MINUTU)
local VORP_DRAIN_PER_MINUTE = {
    hungry = {
        hunger = -12,
        thirst = -12
    },
    starving = {
        hunger = -30,
        thirst = -36
    },
    unbalanced = {
        hunger = -6,
        thirst = -6
    },
    balanced = {
        hunger = 0,
        thirst = 0
    }
}
local VORP_DRAIN_PER_TICK = {}
for state, values in pairs(VORP_DRAIN_PER_MINUTE) do
    VORP_DRAIN_PER_TICK[state] = {}
    for meter, value in pairs(values) do
        VORP_DRAIN_PER_TICK[state][meter] = value / ticks_per_minute
    end
end

---------------------------------------------------------------------
-- Helpers (beze změn)
---------------------------------------------------------------------
local function waitForCharacter()
    while not LocalPlayer or not LocalPlayer.state or not LocalPlayer.state.Character do
        Citizen.Wait(100)
    end
end
local function keyFor(stat, charId)
    return string.format("%s:%s", stat, charId)
end

local function kvpGetNumberOrDefault(key, defaultVal)
    local v = GetResourceKvpFloat(key)
    if v == 0.0 then
        notify("KVP Key " .. key .. " not found, returning default: " .. defaultVal)
        return defaultVal
    else
        return v
    end
end
local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end
local function hasTag(tags, name)
    for _, t in ipairs(tags) do
        if t == name then
            return true
        end
    end
    return false
end
local function activityMultiplier()
    local ped = PlayerPedId();
    if IsPedRunning(ped) or IsPedSprinting(ped) or IsPedInMeleeCombat(ped) then
        return 1.6
    elseif IsPedOnMount(ped) then
        return 1.2
    end
    return 1.0
end
local function computeVorpDrain(tags)
    if hasTag(tags, "starving") then
        return VORP_DRAIN_PER_TICK.starving
    end
    if hasTag(tags, "hungry") then
        return VORP_DRAIN_PER_TICK.hungry
    end
    if hasTag(tags, "unbalanced") then
        return VORP_DRAIN_PER_TICK.unbalanced
    end
    return VORP_DRAIN_PER_TICK.balanced
end

---------------------------------------------------------------------
-- Základní API (beze změn)
---------------------------------------------------------------------
local function getCharId()
    return LocalPlayer.state.Character.CharId
end
local function getNutrition()
    waitForCharacter()
    local charID = getCharId()
    return {
        protein = kvpGetNumberOrDefault(keyFor("protein", charID), 50.0),
        carbs = kvpGetNumberOrDefault(keyFor("carbs", charID), 50.0),
        fats = kvpGetNumberOrDefault(keyFor("fat", charID), 50.0),
        vitamins = kvpGetNumberOrDefault(keyFor("vitamins", charID), 50.0)
    }
end

local function getDebufTimer(name)
    return DEBUF_TIMERS[name] or 0
end

local function setDebufTimer(name, value)
    value = math.floor(value / (TICK_MS / 1000)) -- Přepočet na počet ticků
    value = clamp(value, 0, 300) -- Max 5 minut
    DEBUF_TIMERS[name] = value
end

local function tickDebufTimers()
    for name, time in pairs(DEBUF_TIMERS) do
        if time > 0 then
            DEBUF_TIMERS[name] = math.max(0, time - 1)
        end
    end
end

local function setNutrition(n)
    waitForCharacter()
    local charID = getCharId()
    local clampn = function(v)
        return clamp(v, CLAMP_MIN, CLAMP_MAX)
    end
    -- print("Setting nutrition: " .. json.encode(n))
    SetResourceKvpFloat(keyFor("protein", charID), clampn(n.protein))
    SetResourceKvpFloat(keyFor("carbs", charID), clampn(n.carbs))
    SetResourceKvpFloat(keyFor("fat", charID), clampn(n.fats))
    SetResourceKvpFloat(keyFor("vitamins", charID), clampn(n.vitamins))
end

---------------------------------------------------------------------
-- CENTRÁLNÍ LOGIKA APLIKACE EFEKTŮ (beze změn)
---------------------------------------------------------------------
local function updateAndApplyEffects()
    local n = getNutrition()
    local player = PlayerId()
    if IsPlayerDead(player) then
        return
    end

    -- 1. Vyhodnocení stavu
    local avg = (n.protein + n.fats + n.carbs + n.vitamins) / 4
    local dev =
        (math.abs(n.protein - 50) + math.abs(n.fats - 50) + math.abs(n.carbs - 50) + math.abs(n.vitamins - 50)) / 4
    local balance = clamp(100 - dev * 2, 0, 100)
    local tags = {}
    if avg < 20 then
        table.insert(tags, "starving")
    elseif avg < 40 then
        table.insert(tags, "hungry")
    end
    if balance >= 85 then
        table.insert(tags, "balanced_plus")
    elseif balance <= 35 then
        table.insert(tags, "unbalanced")
    end
    TriggerEvent("aprts_nutrition:effectsUpdated", {
        tags = tags,
        score = balance,
        avg = avg,
        state = n
    })

    -- 2. Aplikace regenerace zdraví
    local regen = 0.4
    if avg < 30 then
        regen = 0.0
    elseif avg < 40 then
        regen = 0.2
    end
    if balance >= 85 and avg >= 50 then
        regen = 1.0
    end
    if balance <= 35 then
        regen = 0.0
    end
    -- kontrola jestli mám dost živin na regeneraci
    if n.protein < 10 or n.fats < 10 or n.carbs < 10 or n.vitamins < 10 then
        regen = 0.0
    end

    if GetPlayerHealthRechargeMultiplier(player) ~= regen then
        debugPrint(
            ("[NUTRI] Health Regen Multiplier set to %.2f (Avg: %.1f, Balance: %.1f)"):format(regen, avg, balance))
        SetPlayerHealthRechargeMultiplier(player, regen)
    end

    -- 3. Aplikace VORP drainu
    if punishmentSystem then
        local base = computeVorpDrain(tags)
        local mult = activityMultiplier()
        local dhunger = (base.hunger or 0.0) * mult
        local dthirst = (base.thirst or 0.0) * mult
        if dhunger ~= 0 then
            TriggerEvent('vorpmetabolism:changeValue', 'Hunger', dhunger)
        end
        if dthirst ~= 0 then
            TriggerEvent('vorpmetabolism:changeValue', 'Thirst', dthirst)
        end
        debugPrint(("[VORP] drain H: %.2f, T: %.2f | mult %.1f | tags: %s"):format(dhunger, dthirst, mult,
            table.concat(tags, ",")))
    end
    -- 4. Speciální efekty (Sugar Spike)
    local ped = PlayerPedId()
    if n.carbs >= 85 and (IsPedRunning(ped) or IsPedSprinting(ped)) and GetPedStamina(ped) < 20 then
        RestorePedStamina(ped, 50.0)
        notify("Tolik energie! Cítíš se najednou plný sil! (Sugar spike)")
        addNutrition({
            carbs = -40
        })
    end
    -- 5. Speciální efekty (Vitamin Boost)
    if n.vitamins >= 90 then
        -- Dočasně zvýší imunitu (sníží šanci na onemocnění)
        TriggerEvent('aprts_medicalAtention:Client:AddImunity', 3, -20) -- Přidá 3 minuty imunity
        notify("Cítíš se zdravý jako nikdy předtím! (Vitamin boost)")
        addNutrition({
            vitamins = -50
        })
    end
    -- 6. Debuf pokud jsou tuky výrazně nad ostatními živinami
    local diff = n.fats - math.max(n.protein, n.carbs, n.vitamins)
    -- print("Fat difference: " .. diff)
    if n.fats >= 80 and diff >= 21 then
        if punishmentSystem then
            setDebufTimer("fatigue", 15) -- 15 sekund debufu
            notify("Cítíš se těžký a unavený... (Příliš mnoho tuků)")
            addNutrition({
                fats = -21
            })
        end
    end
    -- 7. protein buff
    if n.protein >= 90 then
        -- Dočasně zvýší sílu (sníží šanci na selhání v boji)
        TriggerEvent('aprts_combat:Client:AddStrength', 3) -- Přidá 3 minuty síly
        notify("Cítíš se silný jako nikdy předtím! (Protein buff)")
        addNutrition({
            protein = -50
        })
    end

    -- 8. Vitamin debuff
    if n.vitamins <= 20 then
        if NUTRI_DEBUF_ACTIVE.vitamins == false then
            NUTRI_DEBUF_ACTIVE.vitamins = true
            -- Dočasně sníží odolnost (zvýší šanci na onemocnění)
            if punishmentSystem then
                TriggerEvent('aprts_medicalAtention:Client:AddImunity', 1, 20) -- Přidá 1 minutu "negativní" imunity
                notify("Cítíš se oslabený a náchylný k nemocem... (Vitamin debuff)")
            end
        end
    else
        NUTRI_DEBUF_ACTIVE.vitamins = false
    end
end

function addNutrition(delta)
    local cur = getNutrition()
    cur.protein = cur.protein + (delta.protein or 0)
    cur.carbs = cur.carbs + (delta.carbs or 0)
    cur.fats = cur.fats + (delta.fats or 0)
    cur.vitamins = cur.vitamins + (delta.vitamins or 0)
    setNutrition(cur)
    updateAndApplyEffects()
end

---------------------------------------------------------------------
-- UPRAVENÁ HLAVNÍ SMYČKA (Decay loop + Regen Cost)
---------------------------------------------------------------------

CreateThread(function()
    waitForCharacter()
    updateAndApplyEffects()
    -- Wait(30000)
    while true do
        Citizen.Wait(TICK_MS)

        local ped = PlayerPedId()
        if not IsEntityDead(ped) then
            tickDebufTimers()
            -- ČÁST 1: Přirozený úbytek živin (Decay)
            local decay_table
            if IsPedRunning(ped) or IsPedSprinting(ped) or IsPedInMeleeCombat(ped) then
                decay_table = DECAY_PER_TICK.RUN
            elseif IsPedOnMount(ped) then
                decay_table = DECAY_PER_TICK.RIDE
            else
                decay_table = DECAY_PER_TICK.IDLE
            end

            addNutrition({
                protein = -decay_table.protein,
                fats = -decay_table.fats,
                carbs = -decay_table.carbs,
                vitamins = -decay_table.vitamins
            })

            -- --- NOVÁ ČÁST ---
            -- ČÁST 2: Spotřeba živin za aktivní regeneraci zdraví
            local currentRegenMultiplier = GetPlayerHealthRechargeMultiplier(PlayerId())
            if currentRegenMultiplier > 0.0 then
                local currentHealth = GetEntityHealth(ped)
                local maxHealth = GetEntityMaxHealth(ped)
                debugPrint(("[NUTRI] Current Health: %d / %d | Regen Multiplier: %.2f"):format(currentHealth, maxHealth,
                    currentRegenMultiplier))
                -- Podmínka: hráč se aktivně léčí (má buff a není na max HP)
                if currentHealth < maxHealth then
                    debugPrint("Aktivní regenerace zdraví spotřebovává živiny.")
                    -- Odečteme cenu za regeneraci. `addNutrition` se postará o přepočet efektů.
                    addNutrition({
                        protein = -REGEN_COST_PER_TICK.protein,
                        fats = -REGEN_COST_PER_TICK.fats,
                        carbs = -REGEN_COST_PER_TICK.carbs,
                        vitamins = -REGEN_COST_PER_TICK.vitamins
                    })
                end
            end

            -- --- KONEC NOVÉ ČÁSTI ---
        end
    end
end)
CreateThread(function()
    while true do
        local n = getNutrition()
        Citizen.Wait(10)
        if punishmentSystem then
            if getDebufTimer("fatigue") > 0 or n.carbs < 10 then
                DisableControlAction(0, 0xF84FA74F, true)
                DisableControlAction(0, 0x8FFC75D6, true)
                DisableControlAction(0, 0xB5EEEFB7, true)
            end
        end
    end
end)
---------------------------------------------------------------------
-- Konzumace itemů a příkazy (beze změn)
---------------------------------------------------------------------
RegisterNetEvent("aprts_nutrition:consumeItem", function(data)
    if not data then
        return
    end
    debugPrint("Konzumace: " .. json.encode(data));
    addNutrition(data)
end)
RegisterCommand("nutri", function()
    local n = getNutrition();
    local avg = (n.protein + n.fats + n.carbs + n.vitamins) / 4;
    local dev =
        (math.abs(n.protein - 50) + math.abs(n.fats - 50) + math.abs(n.carbs - 50) + math.abs(n.vitamins - 50)) / 4;
    local balance = clamp(100 - dev * 2, 0, 100);
    debugPrint(("[NUTRITION] P:%.1f F:%.1f C:%.1f V:%.1f | Průměr: %.1f | Balance: %.1f"):format(n.protein, n.fats,
        n.carbs, n.vitamins, avg, balance))
    notify(("[NUTRI] P:%.1f F:%.1f C:%.1f V:%.1f | Průměr: %.1f | Balance: %.1f"):format(n.protein, n.fats, n.carbs,
        n.vitamins, avg, balance))
end)

if Config.Debug then
    RegisterCommand("nutri_reset", function()
        setNutrition({
            protein = 60.0,
            fats = 60.0,
            carbs = 60.0,
            vitamins = 60.0
        });
        updateAndApplyEffects();
        notify("Nutri hodnoty resetovány na 50.")
    end)
    RegisterCommand("nutri_add", function(source, args)
        local nutrient = args[1]
        local amount = tonumber(args[2]) or 0
        if nutrient and amount ~= 0 then
            local delta = {}
            delta[nutrient] = amount
            addNutrition(delta)
            notify(("Přidáno %d k %s"):format(amount, nutrient))
        else
            notify("Použití: /nutri_add [protein|fats|carbs|vitamins] [amount]")
        end
    end)
end
---------------------------------------------------------------------
-- Exports (beze změn)
---------------------------------------------------------------------
exports("getNutrition", getNutrition)
exports("add", addNutrition)
exports("getNutritionStatus", function()
    local n = getNutrition();
    local avg = (n.protein + n.fats + n.carbs + n.vitamins) / 4;
    local dev =
        (math.abs(n.protein - 50) + math.abs(n.fats - 50) + math.abs(n.carbs - 50) + math.abs(n.vitamins - 50)) / 4;
    local balance = clamp(100 - dev * 2, 0, 100);
    return {
        avg = avg,
        balance = balance,
        state = n
    }
end)
