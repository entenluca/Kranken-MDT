Utils = {}

function Utils.DeepCopy(value)
    if type(value) ~= 'table' then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = Utils.DeepCopy(v)
    end
    return copy
end

function Utils.NewMissionId()
    return ('m_%s_%s'):format(GetGameTimer(), math.random(1000, 9999))
end

function Utils.DefaultMission()
    return {
        id = Utils.NewMissionId(),
        enabled = true,
        type = 'MTD',
        job = 'ambulance',
        text = '',
        start = { x = 0.0, y = 0.0, z = 0.0 },
        target = { x = 0.0, y = 0.0, z = 0.0 },
        reward = { enabled = false, min = 0, max = 0 },
        npcModel = '',
        vehicles = {},
        items = {},
    }
end

function Utils.CoordsToVector3(coords)
    if not coords then
        return vector3(0.0, 0.0, 0.0)
    end
    return vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
end

function Utils.Vector3ToTable(vec)
    return { x = vec.x + 0.0, y = vec.y + 0.0, z = vec.z + 0.0 }
end

function Utils.GetNpcModels()
    return type(Config.NpcModels) == 'table' and Config.NpcModels or {}
end

function Utils.IsValidNpcModel(model)
    if type(model) ~= 'string' or model == '' then
        return false
    end

    for _, entry in ipairs(Utils.GetNpcModels()) do
        if entry.model == model then
            return true
        end
    end

    return false
end

function Utils.SanitizeNpcModel(model)
    if Utils.IsValidNpcModel(model) then
        return model
    end

    if Utils.IsValidNpcModel(Config.DefaultNpcModel) then
        return Config.DefaultNpcModel
    end

    local models = Utils.GetNpcModels()
    if models[1] and models[1].model then
        return models[1].model
    end

    return type(Config.DefaultNpcModel) == 'string' and Config.DefaultNpcModel or ''
end

function Utils.Distance(a, b)
    return #(Utils.CoordsToVector3(a) - Utils.CoordsToVector3(b))
end

function Utils.FormatDistance(meters)
    local value = tonumber(meters) or 0.0

    if value >= 1000.0 then
        return ('%.1f km'):format(value / 1000.0)
    end

    return ('%d m'):format(math.floor(value + 0.5))
end

function Utils.EstimateTravelMinutes(distanceMeters, speedKmh)
    local speed = tonumber(speedKmh) or 60
    if speed <= 0 then
        speed = 60
    end

    local distanceKm = (tonumber(distanceMeters) or 0.0) / 1000.0
    return math.max(1, math.ceil((distanceKm / speed) * 60.0))
end

function Utils.BuildRouteInfo(startCoords, targetCoords, options)
    options = options or {}

    local start = Utils.CoordsToVector3(startCoords)
    local target = Utils.CoordsToVector3(targetCoords)
    local distance = #(start - target)

    if options.roadFactor then
        distance = distance * options.roadFactor
    end

    local speedKmh = options.speedKmh or 60

    return {
        distance = distance,
        distanceLabel = Utils.FormatDistance(distance),
        eta = Utils.EstimateTravelMinutes(distance, speedKmh),
    }
end

function Utils.ClampReward(reward)
    local min = math.floor(tonumber(reward.min) or 0)
    local max = math.floor(tonumber(reward.max) or min)
    if max < min then
        min, max = max, min
    end
    return { min = min, max = max }
end

function Utils.SanitizeReward(reward)
    local clean = { enabled = false, min = 0, max = 0 }

    if type(reward) ~= 'table' then
        return clean
    end

    clean.enabled = reward.enabled == true

    if clean.enabled then
        local clamped = Utils.ClampReward(reward)
        clean.min = clamped.min
        clean.max = clamped.max
    end

    return clean
end

function Utils.RandomReward(reward)
    reward = Utils.ClampReward(reward)
    if reward.min == reward.max then
        return reward.min
    end
    return math.random(reward.min, reward.max)
end

function Utils.SanitizeMission(mission, allowedTypes)
    local clean = Utils.DefaultMission()
    if type(mission) ~= 'table' then
        return clean
    end

    clean.id = mission.id or Utils.NewMissionId()
    clean.enabled = mission.enabled ~= false
    clean.type = mission.type == 'KT' and 'KT' or 'MTD'
    clean.job = type(mission.job) == 'string' and mission.job or ''
    clean.text = type(mission.text) == 'string' and mission.text or ''
    clean.start = mission.start or clean.start
    clean.target = mission.target or clean.target
    clean.reward = Utils.SanitizeReward(mission.reward or clean.reward)
    clean.npcModel = Utils.SanitizeNpcModel(mission.npcModel)

    clean.vehicles = {}
    if type(mission.vehicles) == 'table' then
        local allowedMap = {}
        if type(allowedTypes) == 'table' then
            for _, allowedType in ipairs(allowedTypes) do
                allowedMap[string.upper(tostring(allowedType))] = true
            end
        end

        for _, vehicle in ipairs(mission.vehicles) do
            if type(vehicle) == 'table' and vehicle.type and vehicle.type ~= '' then
                local vehicleType = string.upper(tostring(vehicle.type))

                if allowedMap[vehicleType] then
                    clean.vehicles[#clean.vehicles + 1] = {
                        type = vehicleType,
                        min = math.max(1, math.floor(tonumber(vehicle.min) or 1)),
                    }
                end
            end
        end
    end

    clean.items = {}
    if clean.type == 'MTD' and type(mission.items) == 'table' then
        for _, item in ipairs(mission.items) do
            if type(item) == 'table' and item.name and item.name ~= '' then
                clean.items[#clean.items + 1] = {
                    name = tostring(item.name),
                    amount = math.max(1, math.floor(tonumber(item.amount) or 1)),
                }
            end
        end
    end

    return clean
end

function Utils.SanitizeMissions(missions, resolveAllowedTypes)
    local result = {}
    if type(missions) ~= 'table' then
        return result
    end

    for _, mission in ipairs(missions) do
        local allowedTypes = resolveAllowedTypes and resolveAllowedTypes(mission) or nil
        result[#result + 1] = Utils.SanitizeMission(mission, allowedTypes)
    end

    return result
end
