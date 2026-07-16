EmergencyDispatch = {}

local function resourceName()
    return Config.EmergencyDispatchResource or 'emergencydispatch'
end

function EmergencyDispatch.IsAvailable()
    return GetResourceState(resourceName()) == 'started'
end

function EmergencyDispatch.NormalizeVehicleType(vehicleType)
    return string.upper(tostring(vehicleType or ''))
end

function EmergencyDispatch.IsAllowedVehicleTypeForJob(jobName, vehicleType)
    return VehicleTypes.IsValidForJob(jobName, vehicleType)
end

function EmergencyDispatch.GetMannedVehicles()
    if not EmergencyDispatch.IsAvailable() then
        return {}
    end

    local ok, manned = pcall(function()
        return exports[resourceName()]:mannedvehicles()
    end)

    if ok and type(manned) == 'table' then
        return manned
    end

    return {}
end

function EmergencyDispatch.GetMannedVehicleCounts(jobName)
    local counts = {}

    for _, entry in ipairs(EmergencyDispatch.GetMannedVehicles()) do
        if entry.job == jobName then
            local vehicleType = EmergencyDispatch.NormalizeVehicleType(entry.type)

            if EmergencyDispatch.IsAllowedVehicleTypeForJob(jobName, vehicleType) then
                counts[vehicleType] = (counts[vehicleType] or 0) + 1
            end
        end
    end

    return counts
end

function EmergencyDispatch.IsVehicleAvailable(entry)
    local dispatch = tonumber(entry.dispatch) or 0
    return dispatch == 0
end

function EmergencyDispatch.GroupAvailableVehiclesByType(jobName)
    local grouped = {}

    for _, entry in ipairs(EmergencyDispatch.GetMannedVehicles()) do
        if entry.job == jobName and EmergencyDispatch.IsVehicleAvailable(entry) then
            local vehicleType = EmergencyDispatch.NormalizeVehicleType(entry.type)

            if EmergencyDispatch.IsAllowedVehicleTypeForJob(jobName, vehicleType) then
                grouped[vehicleType] = grouped[vehicleType] or {}
                grouped[vehicleType][#grouped[vehicleType] + 1] = entry
            end
        end
    end

    return grouped
end

function EmergencyDispatch.SelectVehiclesForMission(mission)
    local grouped = EmergencyDispatch.GroupAvailableVehiclesByType(mission.job)
    local selected = {}
    local requirements = mission.vehicles or {}

    if #requirements == 0 then
        for _, vehicles in pairs(grouped) do
            if vehicles[1] then
                selected[#selected + 1] = vehicles[1]
                break
            end
        end

        return selected
    end

    for _, requirement in ipairs(requirements) do
        local reqType = EmergencyDispatch.NormalizeVehicleType(requirement.type)
        local pool = grouped[reqType] or {}
        local needed = math.max(1, math.floor(tonumber(requirement.min) or 1))

        for i = 1, needed do
            if not pool[i] then
                return {}
            end

            selected[#selected + 1] = pool[i]
        end
    end

    return selected
end
