Dispatch = {}

function Dispatch.Send(job, message, coords)
    if not EmergencyDispatch.IsAvailable() then
        print('[ktjobs] EmergencyDispatch nicht gestartet – Einsatz konnte nicht gesendet werden.')
        return false
    end

    local position = Utils.CoordsToVector3(coords)
    TriggerEvent(Config.DispatchEvent, job, message, vector2(position.x, position.y), false)
    return true
end

function Dispatch.BuildMessage(mission)
    local postal = Postal.GetPostal(mission.target)
    local baseText = mission.text ~= '' and mission.text or (mission.type == 'KT' and 'Krankentransport' or 'Medizinischer Transport')
    return Config.PostalMessageTemplate:format(baseText, postal)
end
