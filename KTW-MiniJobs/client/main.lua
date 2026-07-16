CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. Config.ConfiguratorCommand, 'Öffnet den Einsatz-Konfigurator für MTD/KT')
end)

RegisterCommand(Config.ConfiguratorCommand, function()
    TriggerServerEvent('nm_ktjobs:server:requestConfigurator')
end, false)
