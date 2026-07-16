Dispatch = {}

function Dispatch.GetStichwortId(mission)
    if type(mission.stichwort) == 'string' and mission.stichwort ~= '' and Config.DispatchStichworte[mission.stichwort] then
        return mission.stichwort
    end

    local byType = Config.DefaultStichwortByType or {}
    return byType[mission.type] or 'patientenverlegung'
end

function Dispatch.BuildRouteInfo(mission)
    return Utils.BuildRouteInfo(mission.start, mission.target, {
        roadFactor = Config.RouteRoadFactor,
        speedKmh = Config.RouteSpeedKmh,
    })
end

function Dispatch.BuildMessage(mission, route)
    local postal = Postal.GetPostal(mission.target)
    route = route or Dispatch.BuildRouteInfo(mission)

    local stichwortId = Dispatch.GetStichwortId(mission)
    local template = Config.DispatchStichworte[stichwortId] or Config.PostalMessageTemplate
    local message = template:format(postal, route.distanceLabel, route.eta)

    if type(mission.text) == 'string' and mission.text ~= '' then
        message = message .. ' | ' .. mission.text
    end

    return message
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
