EmergencyDispatch = {}

function EmergencyDispatch.IsAvailable()
    return GetResourceState('emergencydispatch') == 'started'
end

function EmergencyDispatch.NormalizeVehicleType(vehicleType)
    return string.upper(tostring(vehicleType or ''))
end

function EmergencyDispatch.IsAllowedVehicleType(vehicleType)
    local normalized = EmergencyDispatch.NormalizeVehicleType(vehicleType)

    for _, allowed in ipairs(Config.AllowedVehicleTypes) do
        if normalized == allowed then
            return true
        end
    end

    return false
end

function EmergencyDispatch.GetMannedVehicleCounts(jobName)
    local counts = {}

    if not EmergencyDispatch.IsAvailable() then
        return counts
    end

    local ok, manned = pcall(function()
        return exports.emergencydispatch:mannedvehicles()
    end)

    if not ok or type(manned) ~= 'table' then
        return counts
    end

    for _, entry in ipairs(manned) do
        if entry.job == jobName then
            local vehicleType = EmergencyDispatch.NormalizeVehicleType(entry.type)

            if EmergencyDispatch.IsAllowedVehicleType(vehicleType) then
                counts[vehicleType] = (counts[vehicleType] or 0) + 1
            end
        end
    end

    return counts
end
