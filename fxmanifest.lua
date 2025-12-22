fx_version 'cerulean'
lua54 'yes'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'SpoiledMouse'
version '1.75'
description 'aprts_simplequests'

games {"rdr3"}

client_scripts {
    'config.lua',
    'client/utils.lua',      -- Matematika, stringy, debug
    'client/functions.lua',  -- Herní funkce (Blipy, animace, job check)
    'client/core.lua',       -- Hlavní logika questů (Start, Finish, ActiveID)
    'client/threads.lua',    -- Hlavní smyčky (Loop)
    'client/events.lua',     -- Původní eventy (beze změny)
    'client/renderer.lua',   -- Původní renderer (beze změny)
    'client/visualizer.lua', -- Původní visualizer (beze změny)
    'client/commands.lua',   -- Původní commands (beze změny)
    'client/nui.lua', 
}
server_scripts {'@oxmysql/lib/MySQL.lua','config.lua','server/server.lua','server/events.lua','server/commands.lua',}
ui_page 'html/index.html'


-- Zahrnutí souborů pro NUI
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/sounds/*.ogg',
    'html/sounds/*.mp3',
    'html/img/*.png', -- Pokud budeš chtít obrázky (volitelné)
    'html/img/*.jpg'
}