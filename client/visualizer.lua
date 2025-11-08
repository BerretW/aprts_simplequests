local function getFPS()
    local frameTime = GetFrameTime()
    local frame = 1.0 / frameTime
    return frame
end

function fpsTimer()
    local minFPS = 15
    local maxFPS = 165
    local minSpeed = 0
    local maxSpeed = 15
    local coefficient = 1 - (getFPS() - minFPS) / (maxFPS - minFPS)
    return minSpeed + coefficient * (maxSpeed - minSpeed)
end

-- Funkce pro konverzi hex kódu na RGB (např. "#fc0a03" => 252, 10, 3)
function hexToRGB(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
end

function DrawTxt(str, x, y, w, h, enableShadow, col1, col2, col3, a, centre)
    local str = CreateVarString(10, "LITERAL_STRING", str)
    SetTextScale(w, h)
    SetTextColor(math.floor(col1), math.floor(col2), math.floor(col3), math.floor(a))
    SetTextCentre(centre)
    if enableShadow then
        SetTextDropshadow(1, 0, 0, 0, 255)
    end
    Citizen.InvokeNative(0xADA9255D, 22)
    DisplayText(str, x, y)
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoord())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
    local scale = (2 / dist) * 1.1

    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    local fov = (2 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    if onScreen then
        SetTextScale(0.18 * scale, 0.18 * scale)
        SetTextFontForCurrentCommand(1)
        SetTextColor(180, 180, 240, 205)
        SetTextCentre(1)
        DisplayText(str, _x, _y)
        local factor = (string.len(text)) / 355
    end
end

function displayData3D(x, y, z, data, showImage, imagePath)
    -- Získání koordinátů na obrazovce a vzdálenosti od kamery
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoord())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)

    -- Pevná škála, která bere v potaz vzdálenost a fov kamery
    local scale = (1 / dist) * 2.0
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    if onScreen then
        -- Upravíme základní posun na ose Y, aby se prvky pohybovaly správně vzhledem k pozici
        local baseYOffset = -0.03 -- Posun, aby první řádek začal o trochu výše

        -- Projdi jednotlivé položky v `data` tabulce
        for i, row in pairs(data) do
            local yOffset = baseYOffset + (0.03 * (i - 1)) * scale -- Dynamický posun na základě škálování

            -- Zpracuj a vykresli text pro aktuální řádek
            if row.text then
                SetTextScale(0.35 * scale, 0.35 * scale) -- Zvětšíme text dle vzdálenosti
                SetTextFontForCurrentCommand(1)
                local r, g, b = hexToRGB(row.color) -- Konverze hex na RGB
                SetTextColor(r, g, b, 255)
                SetTextCentre(1)
                DisplayText(CreateVarString(10, "LITERAL_STRING", row.text, Citizen.ResultAsLong()), _x, _y + yOffset)
            end

            -- Pokud je definovaná čára (line = true), vykresli ji s procentuální hodnotou (value)
            if row.line and row.value then
                local lineLength = 0.06 * scale -- Délka čáry (přizpůsobená dle měřítka)
                local lineStartX = _x - (lineLength / 2) -- Začátek čáry
                local lineEndX = lineStartX + (lineLength * (row.value / 100)) -- Konec čáry dle procent

                local lineColorR, lineColorG, lineColorB = hexToRGB(row.lineColor or "#ffffff") -- Barva čáry
                local lineWidth = row.lineWidth or 0.005 -- Tloušťka čáry

                -- Vykreslení čáry blíže pod text
                DrawRect(lineStartX + ((lineEndX - lineStartX) / 2), _y + yOffset + (0.015 * scale),
                    (lineEndX - lineStartX), lineWidth * scale, lineColorR, lineColorG, lineColorB, 255)
            end
        end

        -- Vykreslení PNG obrázku, pokud je zapnuto
        if showImage and imagePath then
            DrawSprite(imagePath, "default", _x + 0.05 * scale, _y + 0.02 * scale, 0.05 * scale, 0.05 * scale, 0.0, 255,
                255, 255, 255)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        if Config.Debug == true then
            local pause = 1000

            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            DrawTxt("Alcohol: " .. GetStat("alcohol") .. ". Otrava: " ..
                        GetStat("toxin"), 0.5, 0.01, 0.5, 0.5, true, 255, 255, 255, 255, true)
            pause = fpsTimer()

        end
        Citizen.Wait(pause)

    end
end)
