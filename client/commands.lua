-- příkaz pro vytvoření stopy, bude ve formátu /stopa [vzdálenost] [text]  text může obsahovat mezery a až 20 slov
if Config.Debug == true then
    RegisterCommand("sober", function(source, args, rawCommand)
        SetStat("alcohol", 0)
        SetStat("toxin", 0)
        AnimpostfxStopAll()
        SetPedDrunkness(PlayerPedId(), false, 0)
        consume()   
    end, false)

    RegisterCommand("fullHeal", function(source, args, rawCommand)
        addPlayerOuterHealth(100)
        addPlayerInnerHealth(100)
        addPlayerOuterStamina(100)
        addPlayerInnerStamina(100)
    end, false)
    RegisterCommand("effect", function(source, args, rawCommand)
        local effectID = args[1]
        local duration = tonumber(args[2])
        if effectID ~= nil and duration ~= nil then
            setEffect(tonumber(effectID), tonumber(duration))
        else
            print("Usage: /effect [effect] [duration]")
        end
    end, false)
    RegisterCommand("playFx", function(source, args, rawCommand)
        local effectID = args[1]
        if effectID ~= nil then

            debugPrint("AnimpostfxPlay: " .. effectID)
            AnimpostfxPlay(effectID)

        else
            print("Usage: /playFx [effect]")
        end
    end, false)
    RegisterCommand("stopFx", function(source, args, rawCommand)
        AnimpostfxStopAll()
    end, false)
    RegisterCommand("setRegen", function(source, args, rawCommand)
        local regenValue = tonumber(args[1])
        if regenValue ~= nil then
            SetPlayerHealthRechargeMultiplier(PlayerId(), regenValue)
            debugPrint("SetPlayerHealthRechargeMultiplier to " .. regenValue)
        else
            print("Usage: /setRegen [value]")
        end
    end, false)

end

local isRag = false
RegisterCommand("rag", function(source, args, rawCommand)
    if isRag == false then
        isRag = true
        SetPedToRagdoll(PlayerPedId(), 100000, 100000, 0, 0, 0, 0)
    else
        isRag = false
        SetPedToDisableRagdoll(PlayerPedId(), false)
    end
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(9000)
        if isRag then
            ResetPedRagdollTimer(PlayerPedId())
        end
    end
end)
