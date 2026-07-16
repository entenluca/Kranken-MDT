fx_version 'cerulean'
game 'gta5'

name 'KTW-MiniJobs'
description 'Automatische MTD- und Krankentransporte mit Einsatz-Konfigurator'
author ''
version '1.1.0'

lua54 'yes'

escrow_ignore {
    'config.lua',
}

dependencies {
    'oxmysql',
}

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
    '@oxmysql/lib/MySQL.lua',
    'bridge/emergencydispatch.lua',
    'bridge/dispatch.lua',
    'server/database.lua',
    'server/jobs.lua',
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
    'sql/ktjobs.sql',
    'data/missions.json',
}
