local currentMission = nil
local missionNpc = nil

RegisterNetEvent('nm_ktjobs:client:notify', function(message, nType)
    Framework.Notify(message, nType)
end)

local function clearNpc()
    if missionNpc and DoesEntityExist(missionNpc) then
        DeleteEntity(missionNpc)
    end
    missionNpc = nil
end

local function spawnKtNpc(mission)
    clearNpc()

    local model = joaat(mission.npcModel or Config.DefaultNpcModel)
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasModelLoaded(model) then
        return
    end

    local start = mission.start
    missionNpc = CreatePed(4, model, start.x, start.y, start.z - 1.0, 0.0, false, true)
    SetEntityAsMissionEntity(missionNpc, true, true)
    SetBlockingOfNonTemporaryEvents(missionNpc, true)
    FreezeEntityPosition(missionNpc, true)
    SetModelAsNoLongerNeeded(model)
end

local function cleanupMission()
    clearNpc()
    currentMission = nil
end

local function notifyEmdNavigation()
    if Config.UseEmdNavigation then
        Framework.Notify('Navigation über das EMD-Funkgerät: Einsatzort → Zielort.', 'inform')
    end
end

RegisterNetEvent('nm_ktjobs:client:missionAssigned', function(activeId, mission, message, route)
    if Framework.GetPlayerJob() ~= mission.job then
        return
    end

    cleanupMission()

    currentMission = {
        activeId = activeId,
        mission = mission,
        route = route,
        phase = 'to_start',
    }

    if EmergencyDispatchClient.IsEmd() then
        Framework.Notify(message, 'inform')
        notifyEmdNavigation()
    else
        Framework.Notify('Einsatz alarmiert – besetze ein Fahrzeug in EmergencyDispatch.', 'inform')
    end
end)

RegisterNetEvent('nm_ktjobs:client:missionTransport', function(activeId, mission)
    if not currentMission or currentMission.activeId ~= activeId then
        return
    end

    currentMission.phase = 'to_target'

    if mission.type == 'KT' then
        spawnKtNpc(mission)
    end

    Framework.Notify('Transport gestartet. Fahre zum Ziel.', 'success')
    notifyEmdNavigation()
end)

RegisterNetEvent('nm_ktjobs:client:missionEnded', function(activeId, state, reward, job)
    if not currentMission or currentMission.activeId ~= activeId then
        return
    end

    cleanupMission()

    if state == 'completed' then
        if reward and reward > 0 then
            Framework.Notify(('Transport abgeschlossen. $%s auf Geschäftskonto (%s) gutgeschrieben.'):format(reward, job or ''), 'success')
        else
            Framework.Notify('Transport abgeschlossen.', 'success')
        end
    elseif state == 'cancelled' then
        Framework.Notify('Einsatz abgebrochen.', 'error')
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000

        if currentMission then
            sleep = 0
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local mission = currentMission.mission
            local phase = currentMission.phase

            if not EmergencyDispatchClient.IsEmd() then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Besetze ein Fahrzeug in EmergencyDispatch, um den Einsatz fortzusetzen.')
                EndTextCommandDisplayHelp(0, false, true, -1)
            elseif phase == 'to_start' then
                local start = Utils.CoordsToVector3(mission.start)
                local dist = #(coords - start)

                if dist <= Config.AcceptRadius then
                    DrawMarker(1, start.x, start.y, start.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.5, 2.5, 1.0, 52, 152, 219, 120, false, false, 2, false, nil, nil, false)

                    if dist <= 4.0 then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('Drücke ~INPUT_CONTEXT~ am Startpunkt')
                        EndTextCommandDisplayHelp(0, false, true, -1)

                        if IsControlJustReleased(0, 38) then
                            TriggerServerEvent('nm_ktjobs:server:arrivedAtStart', currentMission.activeId)
                        end
                    end
                end
            elseif phase == 'to_target' then
                local target = Utils.CoordsToVector3(mission.target)
                local distTarget = #(coords - target)

                if distTarget <= Config.CompleteRadius then
                    DrawMarker(1, target.x, target.y, target.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 1.0, 46, 204, 113, 120, false, false, 2, false, nil, nil, false)
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Drücke ~INPUT_CONTEXT~ um den Einsatz abzuschließen')
                    EndTextCommandDisplayHelp(0, false, true, -1)

                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('nm_ktjobs:server:completeMission', currentMission.activeId)
                    end
                end
            end

            if IsControlJustReleased(0, 177) then
                TriggerServerEvent('nm_ktjobs:server:cancelMission', currentMission.activeId)
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    cleanupMission()
end)
