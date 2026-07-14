local function isAdmin(source)
    for _, ace in ipairs(Config.AdminAces) do
        if IsPlayerAceAllowed(source, ace) then
            return true
        end
    end

    if Config.AllowFrameworkAdmins and Framework.IsAdmin(source) then
        return true
    end

    return false
end

local function buildConfiguratorPayload()
    return {
        missions = Storage.GetMissions(),
        jobs = Config.Jobs,
        vehicleTypeOptions = Config.AllowedVehicleTypes,
        defaultNpcModel = Config.DefaultNpcModel,
        displayTitle = Config.DisplayTitle,
    }
end

RegisterNetEvent('nm_ktjobs:server:requestConfigurator', function()
    local source = source
    if not isAdmin(source) then
        Framework.Notify(source, 'Keine Berechtigung für den Einsatz-Konfigurator.', 'error')
        return
    end

    TriggerClientEvent('nm_ktjobs:client:openConfigurator', source, buildConfiguratorPayload())
end)

RegisterNetEvent('nm_ktjobs:server:saveMissions', function(missions)
    local source = source
    if not isAdmin(source) then
        return
    end

    Storage.SetMissions(missions)
    Framework.Notify(source, 'Einsätze gespeichert.', 'success')
    TriggerClientEvent('nm_ktjobs:client:configSaved', source, Storage.GetMissions())
end)

RegisterNetEvent('nm_ktjobs:server:acceptMission', function(activeId)
    local source = source
    local active = Missions.GetActive(activeId)
    if not active or active.acceptedBy then
        return
    end

    if Framework.GetJob(source) ~= active.mission.job then
        Framework.Notify(source, 'Du hast nicht den richtigen Job für diesen Einsatz.', 'error')
        return
    end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local start = Utils.CoordsToVector3(active.mission.start)
    if #(coords - start) > Config.AcceptRadius + 5.0 then
        Framework.Notify(source, 'Du bist nicht am Startpunkt.', 'error')
        return
    end

    active.acceptedBy = source
    active.state = 'accepted'
    Missions.GiveMissionItems(source, active.mission)

    TriggerClientEvent('nm_ktjobs:client:missionAccepted', source, activeId, active.mission)
    TriggerClientEvent('nm_ktjobs:client:missionEnded', -1, activeId, 'taken', 0)
end)

RegisterNetEvent('nm_ktjobs:server:completeMission', function(activeId)
    local source = source
    local ok, reward, job = Missions.CompleteMission(source, activeId)
    if not ok then
        return
    end

    if reward > 0 then
        Framework.Notify(source, ('Einsatz abgeschlossen. $%s auf Geschäftskonto (%s) gutgeschrieben.'):format(reward, job or ''), 'success')
    else
        Framework.Notify(source, 'Einsatz abgeschlossen.', 'success')
    end
end)

RegisterNetEvent('nm_ktjobs:server:cancelMission', function(activeId)
    local source = source
    if Missions.CancelMission(source, activeId) then
        Framework.Notify(source, 'Einsatz abgebrochen.', 'error')
    end
end)

RegisterNetEvent('nm_ktjobs:server:vehicleStatus', function(missionId)
    local source = source
    if not isAdmin(source) then
        return
    end

    local mission = Storage.GetMissionById(missionId)
    if not mission then
        return
    end

    TriggerClientEvent('nm_ktjobs:client:vehicleStatus', source, missionId, Missions.GetVehicleStatus(mission))
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    print('[ktjobs] Gestartet – Framework: ' .. Framework.name)
end)
