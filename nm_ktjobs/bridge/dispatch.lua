Dispatch = {}

function Dispatch.Send(job, message, coords)
    local position = Utils.CoordsToVector3(coords)
    TriggerEvent(Config.DispatchEvent, job, message, vector2(position.x, position.y), false)
end

function Dispatch.BuildMessage(mission)
    local postal = Postal.GetPostal(mission.target)
    local baseText = mission.text ~= '' and mission.text or (mission.type == 'KT' and 'Krankentransport' or 'Medizinischer Transport')
    return Config.PostalMessageTemplate:format(baseText, postal)
end
