Storage = {
    missions = {},
    ready = false,
    resourceName = GetCurrentResourceName(),
}

local function tableName()
    return Database.tableName
end

local function waitForDatabase()
    while not Database.ready do
        Wait(50)
    end
end

local function rowToMission(row)
    local mission = {
        id = row.id,
        enabled = row.enabled == 1 or row.enabled == true,
        type = row.mission_type,
        job = row.job,
        text = row.dispatch_text,
        start = { x = row.start_x, y = row.start_y, z = row.start_z },
        target = { x = row.target_x, y = row.target_y, z = row.target_z },
        reward = {
            enabled = row.reward_enabled == 1 or row.reward_enabled == true,
            min = row.reward_min,
            max = row.reward_max,
        },
        npcModel = row.npc_model,
        vehicles = json.decode(row.vehicles or '[]') or {},
        items = json.decode(row.items or '[]') or {},
    }

    return Utils.SanitizeMission(mission, VehicleTypes.GetForJob(mission.job))
end

local function missionToParams(mission, sortOrder)
    mission = Utils.SanitizeMission(mission, VehicleTypes.GetForJob(mission.job))

    return {
        mission.id,
        sortOrder,
        mission.enabled and 1 or 0,
        mission.type,
        mission.job,
        mission.text,
        mission.start.x or 0,
        mission.start.y or 0,
        mission.start.z or 0,
        mission.target.x or 0,
        mission.target.y or 0,
        mission.target.z or 0,
        mission.reward.enabled and 1 or 0,
        mission.reward.min or 0,
        mission.reward.max or 0,
        mission.npcModel or '',
        json.encode(mission.vehicles or {}),
        json.encode(mission.items or {}),
    }
end

local function migrateJsonIfEmpty()
    local count = tonumber(Database.Scalar(('SELECT COUNT(*) AS total FROM `%s`'):format(tableName()))) or 0
    if count > 0 then
        return
    end

    local raw = LoadResourceFile(Storage.resourceName, 'data/missions.json')
    if not raw or raw == '' then
        return
    end

    local decoded = json.decode(raw)
    if type(decoded) ~= 'table' or #decoded == 0 then
        return
    end

    Storage.SetMissions(decoded)
    print(('[ktjobs] %s Einsätze von missions.json in die Datenbank importiert.'):format(#decoded))
end

function Storage.Load()
    waitForDatabase()
    VehicleTypes.WaitUntilReady()

    local rows = Database.Query(([[
        SELECT *
        FROM `%s`
        ORDER BY sort_order ASC, updated_at ASC
    ]]):format(tableName()))

    Storage.missions = {}
    for _, row in ipairs(rows) do
        Storage.missions[#Storage.missions + 1] = rowToMission(row)
    end

    migrateJsonIfEmpty()
    Storage.ready = true
end

function Storage.Save()
    -- Wird über SetMissions synchronisiert
end

function Storage.UpsertMission(mission, sortOrder)
    local query = ([[
        INSERT INTO `%s` (
            id, sort_order, enabled, mission_type, job, dispatch_text,
            start_x, start_y, start_z, target_x, target_y, target_z,
            reward_enabled, reward_min, reward_max, npc_model, vehicles, items
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            sort_order = VALUES(sort_order),
            enabled = VALUES(enabled),
            mission_type = VALUES(mission_type),
            job = VALUES(job),
            dispatch_text = VALUES(dispatch_text),
            start_x = VALUES(start_x),
            start_y = VALUES(start_y),
            start_z = VALUES(start_z),
            target_x = VALUES(target_x),
            target_y = VALUES(target_y),
            target_z = VALUES(target_z),
            reward_enabled = VALUES(reward_enabled),
            reward_min = VALUES(reward_min),
            reward_max = VALUES(reward_max),
            npc_model = VALUES(npc_model),
            vehicles = VALUES(vehicles),
            items = VALUES(items)
    ]]):format(tableName())

    Database.Execute(query, missionToParams(mission, sortOrder))
end

function Storage.DeleteExcept(ids)
    if #ids == 0 then
        Database.Execute(('DELETE FROM `%s`'):format(tableName()), {})
        return
    end

    local placeholders = {}
    for i = 1, #ids do
        placeholders[i] = '?'
    end

    local query = ('DELETE FROM `%s` WHERE id NOT IN (%s)'):format(tableName(), table.concat(placeholders, ', '))
    Database.Execute(query, ids)
end

function Storage.GetMissions()
    return Storage.missions
end

function Storage.SetMissions(missions)
    waitForDatabase()
    Jobs.WaitUntilReady()
    VehicleTypes.WaitUntilReady()

    missions = Utils.SanitizeMissions(missions, function(mission)
        return VehicleTypes.GetForJob(Jobs.ResolveJob(mission.job))
    end)
    local ids = {}

    for index, mission in ipairs(missions) do
        mission.job = Jobs.ResolveJob(mission.job)
        ids[#ids + 1] = mission.id
        Storage.UpsertMission(mission, index)
    end

    Storage.DeleteExcept(ids)
    Storage.missions = missions
end

function Storage.GetMissionById(id)
    for _, mission in ipairs(Storage.missions) do
        if mission.id == id then
            return mission
        end
    end
    return nil
end

function Storage.WaitUntilReady()
    while not Database.ready or not Storage.ready do
        Wait(50)
    end
end

CreateThread(function()
    Storage.Load()
end)
