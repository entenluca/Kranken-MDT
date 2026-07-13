local configuratorOpen = false

local function setNuiFocus(state)
    configuratorOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
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

RegisterNUICallback('checkVehicles', function(data, cb)
    if data.missionId then
        TriggerServerEvent('nm_ktjobs:server:vehicleStatus', data.missionId)
    end
    cb('ok')
end)

CreateThread(function()
    while true do
        if configuratorOpen and IsControlJustReleased(0, 322) then
            setNuiFocus(false)
            SendNUIMessage({ action = 'close' })
        end
        Wait(0)
    end
end)

RegisterNetEvent('nm_ktjobs:client:requestConfigurator', function()
    TriggerServerEvent('nm_ktjobs:server:requestConfigurator')
end)
