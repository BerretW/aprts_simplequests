RegisterCommand("resetquests", function()
    for k, v in pairs(Config.Quests) do
        local charID = LocalPlayer.state.Character.CharId
        DeleteResourceKvp("aprts_simplequests:" .. v.id .. ":" .. charID)
    end
    print("All quests have been reset for character ID: " .. LocalPlayer.state.Character.CharId)
end, false)

RegisterCommand("setQuestState", function(source, args, rawCommand)
    local questID = tonumber(args[1])
    local state = tonumber(args[2])
    if not questID or not state then
        print("Please provide valid quest ID and state.")
        return
    end
    local quest = Config.Quests[questID]
    if not quest then
        print("Quest ID " .. args[1] .. " does not exist.")
        return
    end
    if state == 1 then
        ActivateQuest(questID)
    end
    if state == 100 then
        Config.Quests[questID].active = false
    end
    local charID = LocalPlayer.state.Character.CharId
    SetResourceKvpInt("aprts_simplequests:" .. questID .. ":" .. charID, state)
    print("Quest ID " .. questID .. " state set to " .. state .. " for character ID: " .. charID)
end, false)

RegisterCommand("getquestlog", function()
    local charID = LocalPlayer.state.Character.CharId
    print("Quest log for character ID: " .. charID)
    print("===================================")
    print("Active Quest: " .. ActiveQuestID)
    for k, v in pairs(Config.Quests) do
        local state = GetResourceKvpInt("aprts_simplequests:" .. v.id .. ":" .. charID)
        print("Quest ID: " .. v.id .. " | Name: " .. v.name .. " | State: " .. Config.QuestStates[state])
    end
end, false  )

RegisterCommand("activateQuest", function(source, args, rawCommand)
    local questID = tonumber(args[1])
    if not questID then
        print("Please provide a valid quest ID.")
        return
    end
    local quest = Config.Quests[questID]
    if not quest then
        print("Quest ID " .. args[1] .. " does not exist.")
        return
    end
    if GetQuestState(questID) == 1 then
        print("Quest ID " .. args[1] .. " activated.")
        ActivateQuest(questID)
    else
        print("Quest ID " .. args[1] .. " is done or does not exist.")
    end
end, false)