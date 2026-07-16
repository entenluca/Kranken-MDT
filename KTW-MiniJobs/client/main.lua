CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. Config.ConfiguratorCommand, 'Öffnet den Einsatz-Konfigurator für MTD/KT')
end)

RegisterCommand(Config.ConfiguratorCommand, function()
    OpenConfigurator()
end, false)

RegisterNetEvent('nm_ktjobs:client:openConfigurator', function()
    OpenConfigurator()
end)
