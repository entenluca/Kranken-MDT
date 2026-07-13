fx_version 'cerulean'
game 'gta5'

name 'nm_ktjobs'
description 'Automatische MTD- und Krankentransporte mit Einsatz-Konfigurator'
author 'nm'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/utils.lua',
    'bridge/framework.lua',
    'bridge/postal.lua',
}

client_scripts {
    'client/main.lua',
    'client/missions.lua',
    'client/configurator.lua',
}

server_scripts {
    'bridge/dispatch.lua',
    'server/storage.lua',
    'server/missions.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/icons.js',
    'html/components.js',
    'html/app.js',
    'data/missions.json',
}
