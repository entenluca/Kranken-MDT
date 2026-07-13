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
    return ('m_%s_%s'):format(os.time(), math.random(1000, 9999))
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
        reward = { min = 0, max = 0 },
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

function Utils.Distance(a, b)
    return #(Utils.CoordsToVector3(a) - Utils.CoordsToVector3(b))
end

function Utils.ClampReward(reward)
    local min = math.floor(tonumber(reward.min) or 0)
    local max = math.floor(tonumber(reward.max) or min)
    if max < min then
        min, max = max, min
    end
    return { min = min, max = max }
end

function Utils.RandomReward(reward)
    reward = Utils.ClampReward(reward)
    if reward.min == reward.max then
        return reward.min
    end
    return math.random(reward.min, reward.max)
end

function Utils.SanitizeMission(mission)
    local clean = Utils.DefaultMission()
    if type(mission) ~= 'table' then
        return clean
    end

    clean.id = mission.id or Utils.NewMissionId()
    clean.enabled = mission.enabled ~= false
    clean.type = mission.type == 'KT' and 'KT' or 'MTD'
    clean.job = type(mission.job) == 'string' and mission.job or 'ambulance'
    clean.text = type(mission.text) == 'string' and mission.text or ''
    clean.start = mission.start or clean.start
    clean.target = mission.target or clean.target
    clean.reward = Utils.ClampReward(mission.reward or clean.reward)
    clean.npcModel = type(mission.npcModel) == 'string' and mission.npcModel or ''

    clean.vehicles = {}
    if type(mission.vehicles) == 'table' then
        for _, vehicle in ipairs(mission.vehicles) do
            if type(vehicle) == 'table' and vehicle.type and vehicle.type ~= '' then
                local vehicleType = string.upper(tostring(vehicle.type))
                local allowed = false

                for _, allowedType in ipairs(Config.AllowedVehicleTypes) do
                    if vehicleType == allowedType then
                        allowed = true
                        break
                    end
                end

                if allowed then
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

function Utils.SanitizeMissions(missions)
    local result = {}
    if type(missions) ~= 'table' then
        return result
    end

    for _, mission in ipairs(missions) do
        result[#result + 1] = Utils.SanitizeMission(mission)
    end

    return result
end
