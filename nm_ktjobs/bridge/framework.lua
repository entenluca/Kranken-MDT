Framework = {
    name = 'standalone',
    object = nil,
}

local function detectFramework()
    if Config.Framework == 'esx' or (Config.Framework == 'auto' and GetResourceState('es_extended') == 'started') then
        Framework.name = 'esx'
        Framework.object = exports['es_extended']:getSharedObject()
        return
    end

    if Config.Framework == 'qb' or (Config.Framework == 'auto' and GetResourceState('qb-core') == 'started') then
        Framework.name = 'qb'
        Framework.object = exports['qb-core']:GetCoreObject()
        return
    end

    Framework.name = 'standalone'
    Framework.object = nil
end

if IsDuplicityVersion() then
    CreateThread(function()
        detectFramework()
    end)
else
    detectFramework()
end

if IsDuplicityVersion() then
    function Framework.GetPlayer(source)
        if Framework.name == 'esx' then
            return Framework.object.GetPlayerFromId(source)
        elseif Framework.name == 'qb' then
            return Framework.object.Functions.GetPlayer(source)
        end
        return nil
    end

    function Framework.GetJob(source)
        local player = Framework.GetPlayer(source)
        if not player then
            return nil
        end

        if Framework.name == 'esx' then
            return player.job and player.job.name or nil
        elseif Framework.name == 'qb' then
            return player.PlayerData.job and player.PlayerData.job.name or nil
        end

        return nil
    end

    function Framework.IsOnDuty(source)
        local player = Framework.GetPlayer(source)
        if not player then
            return false
        end

        if Framework.name == 'esx' then
            return true
        elseif Framework.name == 'qb' then
            return player.PlayerData.job.onduty == true
        end

        return true
    end

    function Framework.AddMoney(source, amount)
        local player = Framework.GetPlayer(source)
        if not player or amount <= 0 then
            return false
        end

        if Framework.name == 'esx' then
            if Config.RewardAccount == 'bank' then
                player.addAccountMoney('bank', amount)
            else
                player.addMoney(amount)
            end
            return true
        elseif Framework.name == 'qb' then
            local account = Config.RewardAccount == 'bank' and 'bank' or 'cash'
            player.Functions.AddMoney(account, amount, 'nm_ktjobs-reward')
            return true
        end

        return false
    end

    function Framework.AddItem(source, itemName, amount)
        local player = Framework.GetPlayer(source)
        if not player or amount <= 0 then
            return false
        end

        if Framework.name == 'esx' then
            player.addInventoryItem(itemName, amount)
            return true
        elseif Framework.name == 'qb' then
            return player.Functions.AddItem(itemName, amount) == true
        end

        return false
    end

    function Framework.RemoveItem(source, itemName, amount)
        local player = Framework.GetPlayer(source)
        if not player or amount <= 0 then
            return false
        end

        if Framework.name == 'esx' then
            player.removeInventoryItem(itemName, amount)
            return true
        elseif Framework.name == 'qb' then
            return player.Functions.RemoveItem(itemName, amount) == true
        end

        return false
    end

    function Framework.Notify(source, message, nType)
        TriggerClientEvent('nm_ktjobs:client:notify', source, message, nType or 'inform')
    end
else
    function Framework.Notify(message, nType)
        if Framework.name == 'esx' and Framework.object then
            Framework.object.ShowNotification(message)
            return
        end

        if Framework.name == 'qb' and Framework.object then
            Framework.object.Functions.Notify(message, nType or 'primary')
            return
        end

        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end

    function Framework.GetPlayerJob()
        if Framework.name == 'esx' and Framework.object then
            local data = Framework.object.GetPlayerData()
            return data.job and data.job.name or nil
        end

        if Framework.name == 'qb' and Framework.object then
            local data = Framework.object.Functions.GetPlayerData()
            return data.job and data.job.name or nil
        end

        return nil
    end
end
