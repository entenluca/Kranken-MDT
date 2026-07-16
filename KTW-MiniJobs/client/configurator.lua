local configuratorOpen = false
local placementActive = false

local function setNuiFocus(state)
    configuratorOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
    DisplayRadar(true)
end

local function cancelPlacement()
    if not placementActive then
        return
    end

    placementActive = false
    SendNUIMessage({ action = 'placementCancel' })
    setNuiFocus(true)
end

local function finishPlacement(field, missionId, coords)
    placementActive = false

    SendNUIMessage({
        action = 'placementDone',
        data = {
            field = field,
            missionId = missionId,
            x = tonumber(string.format('%.2f', coords.x)),
            y = tonumber(string.format('%.2f', coords.y)),
            z = tonumber(string.format('%.2f', coords.z)),
        },
    })

    setNuiFocus(true)
end

local function startPlacement(field, missionId)
    if placementActive then
        return
    end

    placementActive = true
    SetNuiFocus(false, false)
    DisplayRadar(true)

    SendNUIMessage({
        action = 'placementMode',
        data = {
            field = field,
            missionId = missionId,
            key = Config.PlacementKeyLabel,
        },
    })

    CreateThread(function()
        while placementActive do
            Wait(0)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            DrawMarker(
                1,
                coords.x, coords.y, coords.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.2, 1.2, 1.0,
                59, 130, 246, 140,
                false, false, 2, false, nil, nil, false
            )

            if IsControlJustReleased(0, Config.PlacementKey) then
                finishPlacement(field, missionId, coords)
                break
            end

            if IsControlJustReleased(0, Config.PlacementCancelKey) then
                cancelPlacement()
                break
            end
        end
    end)
end

RegisterNetEvent('nm_ktjobs:client:openConfigurator', function(payload)
    setNuiFocus(true)
    SendNUIMessage({
        action = 'open',
        data = payload,
    })
end)

RegisterNetEvent('nm_ktjobs:client:configSaved', function(missions)
    SendNUIMessage({
        action = 'saved',
        data = { missions = missions },
    })
end)

RegisterNetEvent('nm_ktjobs:client:vehicleStatus', function(missionId, status)
    SendNUIMessage({
        action = 'vehicleStatus',
        data = { missionId = missionId, status = status },
    })
end)

RegisterNUICallback('close', function(_, cb)
    if placementActive then
        cancelPlacement()
    end

    setNuiFocus(false)
    SendNUIMessage({ action = 'close' })
    cb('ok')
end)

RegisterNUICallback('save', function(data, cb)
    TriggerServerEvent('nm_ktjobs:server:saveMissions', data.missions or {})
    cb('ok')
end)

RegisterNUICallback('getPosition', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    cb({
        x = tonumber(string.format('%.2f', coords.x)),
        y = tonumber(string.format('%.2f', coords.y)),
        z = tonumber(string.format('%.2f', coords.z)),
        field = data.field,
        missionId = data.missionId,
    })
end)

RegisterNUICallback('beginPlacement', function(data, cb)
    if not data.field or not data.missionId then
        cb('error')
        return
    end

    startPlacement(data.field, data.missionId)
    cb('ok')
end)

RegisterNUICallback('calculateRoute', function(data, cb)
    local start = data.start
    local target = data.target

    if type(start) ~= 'table' or type(target) ~= 'table' then
        cb({})
        return
    end

    local route = EmergencyDispatchClient.CalculateRoute(start, target)
    cb(route)
end)

RegisterNUICallback('checkVehicles', function(data, cb)
    if data.missionId then
        TriggerServerEvent('nm_ktjobs:server:vehicleStatus', data.missionId, data.mission)
    end
    cb('ok')
end)

CreateThread(function()
    while true do
        if configuratorOpen and not placementActive and IsControlJustReleased(0, 322) then
            setNuiFocus(false)
            SendNUIMessage({ action = 'close' })
        end
        Wait(0)
    end
end)

RegisterNetEvent('nm_ktjobs:client:requestConfigurator', function()
    TriggerServerEvent('nm_ktjobs:server:requestConfigurator')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    placementActive = false
    setNuiFocus(false)
end)
