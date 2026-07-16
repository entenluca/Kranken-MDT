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
    Jobs.WaitUntilReady()
    VehicleTypes.WaitUntilReady()

    return {
        missions = Storage.GetMissions(),
        jobs = Jobs.GetJobs(),
        vehicleTypesByJob = VehicleTypes.GetGrouped(),
        npcModels = Utils.GetNpcModels(),
        defaultNpcModel = Config.DefaultNpcModel,
        displayTitle = Config.DisplayTitle,
        placementKeyLabel = Config.PlacementKeyLabel,
    }
end

lib.callback.register('ktjobs:getConfiguratorData', function(source)
    Storage.WaitUntilReady()

    if not isAdmin(source) then
        return nil
    end

    return buildConfiguratorPayload()
end)

lib.callback.register('ktjobs:saveMissions', function(source, missions)
    Storage.WaitUntilReady()

    if not isAdmin(source) then
        return false
    end

    Storage.SetMissions(missions)
    return true
end)

lib.callback.register('ktjobs:getVehicleStatus', function(source, mission)
    if not isAdmin(source) or type(mission) ~= 'table' then
        return nil
    end

    mission = Utils.SanitizeMission(mission, VehicleTypes.GetForJob(Jobs.ResolveJob(mission.job)))
    mission.job = Jobs.ResolveJob(mission.job)

    return Missions.GetVehicleStatus(mission)
end)

RegisterNetEvent('nm_ktjobs:server:requestConfigurator', function()
    local source = source
    if not isAdmin(source) then
        Framework.Notify(source, 'Keine Berechtigung für den Einsatz-Konfigurator.', 'error')
        return
    end

    TriggerClientEvent('nm_ktjobs:client:openConfigurator', source)
end)

RegisterNetEvent('nm_ktjobs:server:arrivedAtStart', function(activeId)
    Missions.ArrivedAtStart(source, activeId)
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

RegisterNetEvent('nm_ktjobs:server:vehicleStatus', function(_, missionPayload)
    local source = source
    if not isAdmin(source) then
        return
    end

    if type(missionPayload) ~= 'table' then
        return
    end

    local mission = Utils.SanitizeMission(missionPayload, VehicleTypes.GetForJob(Jobs.ResolveJob(missionPayload.job)))
    mission.job = Jobs.ResolveJob(mission.job)

    TriggerClientEvent('nm_ktjobs:client:vehicleStatus', source, mission.id, Missions.GetVehicleStatus(mission))
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    print(('[ktjobs] Gestartet – Framework: %s | DB: %s'):format(
        Framework.name,
        Database.ready and Database.driver or 'nicht bereit'
    ))
end)
