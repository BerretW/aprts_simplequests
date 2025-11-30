Config = {}
Config.Debug = false

Config.WebHook = ""
Config.ServerName = 'WestHaven ** Loger'
Config.DiscordColor = 16753920

Config.QuestStates={
    [0] = "Not Started",
    [1] = "In Progress",
    [100] = "Completed"
}

Config.Quests = {}
Config.QuestData = {
   [1]= {
        id = 1,
        active = true,
        name = "Doručovací úkol",
        description = "Doruč balíček na určené místo.",
        jobs = nil,
        blJobs = nil,
        repeatable = false,
        hoursOpen = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23},
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
                    {name = "aprts_simplequests:server:startDeliveryQuest", args = {} }
                },
                client = {
                    {name = "aprts_simplequests:client:startDeliveryQuest", args = {} }
                }
            }
        },
        target = {
            activation = "talktoNPC", -- talktoNPC,distance(distance), useItem(itemname), killNPC(model), clientEvent(eventname), prop(model)
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
        name = "Nášup u Karla", -- ZMĚNA: výstižnější název
        description = "Snědl jsi výborný guláš. Zajdi za Karlem a poděkuj mu.", -- ZMĚNA: nový popis
        jobs = nil,
        repeatable = false,
        start = {
            activation = "useItem", -- Start se aktivuje použitím itemu, to zůstává
            param = "food_muschgulas",
            NPC = nil,
            coords = nil,

            text = "Mmm, to byl ale guláš! Měl bych zajít za Karlem a říct mu, jak mi chutnalo.", -- ZMĚNA: Text, který hráče navede
            prompt = nil,
            items = {}, -- ZMĚNA: Při startu už hráč nedostane žádný item, odměna je až na konci
            events = {
                server = {},
                client = {} 
                -- ZMĚNA: Odebráno automatické dokončení úkolu! To byla hlavní chyba.
            }
        },
        target = {
            activation = "talktoNPC", -- ZMĚNA: Cílem je teď promluvit s NPC
            param = nil, -- param nepotřebujeme, když mluvíme s NPC
            NPC = "s_m_m_valcowpoke_01", -- ZMĚNA: Model pro našeho kuchaře Karla (můžeš změnit)
            blip = "blip_bag_capture", -- ZMĚNA: Přidán blip, aby hráč věděl, kam jít
            coords = vector4(-222.500259, 663.965332, 113.324120, 107.736641), -- !! DŮLEŽITÉ: ZMĚŇ SOUŘADNICE, kam chceš Karla umístit !!

            text = "Rád slyším, že ti chutnalo! Tady máš, přidej si. Čerstvá várka!", -- Text po dokončení
            prompt = {
                text = "Poděkovat za guláš", -- Text, který se ukáže u NPC
                groupText = "Úkol od Karla"
            },
            items = {
                {name = "food_muschgulas", count = 1, meta = {} } -- Odměna - další guláš
            },
            money = 5, -- ZMĚNA: Přidána malá finanční odměna
            events = { 
                -- Zde můžeš nechat původní eventy, pokud chceš po dokončení něco specifického spustit
                server = {
                    -- {name = "neco_na_serveru", args = {} }
                },
                client = {
                    -- {name = "neco_na_klientovi", args = {} }
                }
            }
        },
    },
}