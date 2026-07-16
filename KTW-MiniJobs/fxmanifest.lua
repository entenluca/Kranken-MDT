fx_version 'cerulean'
game 'gta5'

name 'KTW-MiniJobs'
description 'Automatische MTD- und Krankentransporte mit Einsatz-Konfigurator'
author ''
version '2.0.0'

lua54 'yes'

escrow_ignore {
    'config.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
    'bridge/framework.lua',
    'bridge/postal.lua',
}

client_scripts {
    'bridge/emergencydispatch_client.lua',
    'client/main.lua',
    'client/missions.lua',
    'client/configurator.lua',
}

server_scripts {
    '@ox_lib/init.lua',
    '@oxmysql/lib/MySQL.lua',
    'bridge/emergencydispatch.lua',
    'bridge/dispatch.lua',
    'server/database.lua',
    'server/jobs.lua',
    'server/vehicletypes.lua',
    'server/storage.lua',
    'server/missions.lua',
    'server/main.lua',
}

files {
    'sql/ktjobs.sql',
    'data/missions.json',
}
