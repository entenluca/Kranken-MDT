local pendingMissions = {}
local currentMission = nil
local missionBlips = {}
local missionNpc = nil

RegisterNetEvent('nm_ktjobs:client:notify', function(message, nType)
    Framework.Notify(message, nType)
end)

local function clearBlips()
    for _, blip in ipairs(missionBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    missionBlips = {}
end

local function clearNpc()
    if missionNpc and DoesEntityExist(missionNpc) then
        DeleteEntity(missionNpc)
    end
    missionNpc = nil
end

local function addBlip(coords, sprite, color, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, 0.85)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
    missionBlips[#missionBlips + 1] = blip
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
    clearBlips()
    clearNpc()
    currentMission = nil
end

RegisterNetEvent('nm_ktjobs:client:missionDispatched', function(activeId, mission, message)
    if Framework.GetPlayerJob() ~= mission.job then
        return
    end

    pendingMissions[activeId] = mission
    Framework.Notify(message, 'inform')
    addBlip(mission.start, 280, 3, 'Offener Transport')
end)

RegisterNetEvent('nm_ktjobs:client:missionAccepted', function(activeId, mission)
    pendingMissions[activeId] = nil
    cleanupMission()

    currentMission = {
        activeId = activeId,
        mission = mission,
    }

    clearBlips()
    addBlip(mission.start, 1, 3, 'Einsatz Start')
    addBlip(mission.target, 1, 2, 'Einsatz Ziel')
    SetNewWaypoint(mission.target.x, mission.target.y)

    if mission.type == 'KT' then
        spawnKtNpc(mission)
    end

    Framework.Notify('Einsatz angenommen. Fahre zum Ziel.', 'success')
end)

RegisterNetEvent('nm_ktjobs:client:missionEnded', function(activeId, state, reward)
    pendingMissions[activeId] = nil

    if state == 'taken' then
        clearBlips()
        return
    end

    if not currentMission or currentMission.activeId ~= activeId then
        return
    end

    cleanupMission()

    if state == 'completed' then
        Framework.Notify(('Transport abgeschlossen. Belohnung: $%s'):format(reward), 'success')
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local job = Framework.GetPlayerJob()

        if currentMission then
            sleep = 0
            local mission = currentMission.mission
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

            if IsControlJustReleased(0, 177) then
                TriggerServerEvent('nm_ktjobs:server:cancelMission', currentMission.activeId)
            end
        elseif job then
            for activeId, mission in pairs(pendingMissions) do
                if mission.job == job then
                    local start = Utils.CoordsToVector3(mission.start)
                    local dist = #(coords - start)

                    if dist <= Config.AcceptRadius then
                        sleep = 0
                        DrawMarker(1, start.x, start.y, start.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.5, 2.5, 1.0, 52, 152, 219, 120, false, false, 2, false, nil, nil, false)

                        if dist <= 4.0 then
                            BeginTextCommandDisplayHelp('STRING')
                            AddTextComponentSubstringPlayerName('Drücke ~INPUT_CONTEXT~ um den Einsatz anzunehmen')
                            EndTextCommandDisplayHelp(0, false, true, -1)

                            if IsControlJustReleased(0, 38) then
                                TriggerServerEvent('nm_ktjobs:server:acceptMission', activeId)
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterCommand('ktaccept', function(_, args)
    local activeId = args[1]
    if activeId then
        TriggerServerEvent('nm_ktjobs:server:acceptMission', activeId)
    end
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    cleanupMission()
end)
