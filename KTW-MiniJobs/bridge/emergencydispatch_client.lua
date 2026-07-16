EmergencyDispatchClient = {}

local function resourceName()
    return Config.EmergencyDispatchResource or 'emergencydispatch'
end

function EmergencyDispatchClient.IsAvailable()
    return GetResourceState(resourceName()) == 'started'
end

function EmergencyDispatchClient.IsEmd()
    if not EmergencyDispatchClient.IsAvailable() then
        return false
    end

    local ok, result = pcall(function()
        return exports[resourceName()]:isemd()
    end)

    return ok and result == true
end

function EmergencyDispatchClient.GetFunkrufname()
    if not EmergencyDispatchClient.IsAvailable() then
        return false
    end

    local ok, result = pcall(function()
        return exports[resourceName()]:funkrufname()
    end)

    if ok then
        return result
    end

    return false
end

function EmergencyDispatchClient.CalculateRoute(startCoords, targetCoords)
    local start = Utils.CoordsToVector3(startCoords)
    local target = Utils.CoordsToVector3(targetCoords)

    local distance = CalculateTravelDistanceBetweenPoints(
        start.x, start.y, start.z,
        target.x, target.y, target.z
    )

    return {
        distance = distance,
        distanceLabel = Utils.FormatDistance(distance),
        eta = Utils.EstimateTravelMinutes(distance, Config.RouteSpeedKmh),
    }
end
