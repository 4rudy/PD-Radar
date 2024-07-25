fx_version 'cerulean'
author '0R Development, 4rudy'
description 'Radar for PD Vehicles'
version '1.1'
game 'gta5'

lua54 'yes'

shared_scripts {
    '@mc9-lib/import.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'
files {
    'html/**/*.*',
    'html/*.*',
}
dependency '/assetpacks'
