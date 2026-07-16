Dispatch = {}

function Dispatch.BuildRouteInfo(mission)
    return Utils.BuildRouteInfo(mission.start, mission.target, {
        roadFactor = Config.RouteRoadFactor,
        speedKmh = Config.RouteSpeedKmh,
    })
end

function Dispatch.BuildMessage(mission, route)
    local postal = Postal.GetPostal(mission.target)
    local baseText = mission.text ~= '' and mission.text or (mission.type == 'KT' and 'Krankentransport' or 'Medizinischer Transport')
    route = route or Dispatch.BuildRouteInfo(mission)

    return Config.PostalMessageTemplate:format(
        baseText,
        postal,
        route.distanceLabel,
        route.eta
    )
end

function Dispatch.Send(job, message, coords, showBlip)
    if not EmergencyDispatch.IsAvailable() then
        print('[ktjobs] EmergencyDispatch nicht gestartet – Einsatz konnte nicht gesendet werden.')
        return false
    end

    local position = Utils.CoordsToVector3(coords)
    local shouldShowBlip = showBlip
    if shouldShowBlip == nil then
        shouldShowBlip = Config.DispatchShowBlip ~= false
    end

    TriggerEvent(
        Config.DispatchEvent,
        job,
        message,
        vector2(position.x, position.y),
        shouldShowBlip
    )

    return true
end
