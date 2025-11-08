Config = {}
Config.Debug = false
Config.DST = 2
Config.GreenTimeStart = 16
Config.GreenTimeEnd = 23
Config.ActiveTimeStart = 23
Config.ActiveTimeEnd = 3


Config.WebHook = ""
Config.ServerName = 'WestHaven ** Loger'
Config.DiscordColor = 16753920


Config.Quests = {
   [1]= {
        id = 1,
        active = true,
        name = "Doručovací úkol",
        description = "Doruč balíček na určené místo.",
        jobs = nil,
        repeatable = false,
        start = {
            activation = "talktoNPC", -- talktoNPC, distance(distance), useItem(itemname), clientEvent(eventname)
            param = nil,
            NPC = "a_m_m_middlesdtownfolk_01",
            coords = vector4(2858.225342, -1354.093994, 44.557438, 152.488403),

            text = "Tady máš gulášek dej si do nosu!",
            prompt = {
                text = "Přijmout",
                groupText = "Ukoly od Karla"
            },
            items = {
                {name = "food_muschgulas", count = 1}
            },
            events = {
                server = {
                    {name = "aprts_simplequests:server:completeDeliveryQuest", args = {} }
                },
                client = {
                    {name = "aprts_simplequests:client:onDeliveryQuestComplete", args = {} }
                }
            }
        },
        target = {
            activation = "talktoNPC", -- talktoNPC,distance(distance), useItem(itemname), killNPC(model), clientEvent(eventname)
            param = "food_muschgulas",
            NPC = "a_m_m_middlesdtownfolk_01",
            blip = "blip_bag_capture",
            coords = vector4(2822.979736, -1377.657349, 44.507278, 290.667084),
            text = "Snad ti chutnal pane. Tady máš ještě jeden gulášek.",
            prompt = {
                text = "Přinést balíček sem.",
                groupText = "Ukoly od Karla"
            },
            items = {
                {name = "food_muschgulas", count = 1,meta = {} }
            },
            money = 0,
            events = {
                server = {
                    {name = "aprts_simplequests:server:completeDeliveryQuest", args = {} }
                },
                client = {
                    {name = "aprts_simplequests:client:onDeliveryQuestComplete", args = {} }
                }
            }
        },
    },
    [2]= {

        id = 2,
        active = true,
        name = "Žrací úkol",
        description = "Dal sis gulášek? Tak ted si dej další!",
        jobs = nil,
        repeatable = false,
        start = {
            activation = "useItem", -- talktoNPC, distance(distance), useItem(itemname), clientEvent(eventname)
            param = "food_muschgulas",
            NPC = nil,
            coords = nil,

            text = "AAAA tak ty si tu vyžíráš gulášek? Tady máš další!",
            prompt = nil,
            items = {
                {name = "food_muschgulas", count = 1}
            },
            events = {
                server = {
                    -- {name = "aprts_simplequests:server:completeDeliveryQuest", args = {} }
                },
                client = {
                    {name = "aprts_simplequests:client:finishActiveQuest", args = {} }
                }
            }
        },
        target = {
            activation = nil, -- talktoNPC,distance(distance), useItem(itemname), clientEvent(eventname)
            param = nil,
            NPC = nil,
            coords = nil,
            text = "Snad ti chutnal pane. Tady máš ještě jeden gulášek.",
            prompt = {
                text = "Přinést balíček sem.",
                groupText = "Ukoly od Karla"
            },
            items = {
                {name = "food_muschgulas", count = 1,meta = {} }
            },
            money = 0,
            events = {
                server = {
                    {name = "aprts_simplequests:server:completeDeliveryQuest", args = {} }
                },
                client = {
                    {name = "aprts_simplequests:client:onDeliveryQuestComplete", args = {} }
                }
            }
        },
    }
}