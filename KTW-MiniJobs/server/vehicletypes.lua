VehicleTypes = {
    byJob = {},
    ready = false,
}

local function tableName()
    return Config.EmdVehicleTypesTable or 'emd_vehicletypes'
end

local function waitForDatabase()
    while not Database.ready do
        Wait(50)
    end
end

function VehicleTypes.NormalizeType(vehicleType)
    return string.upper(tostring(vehicleType or ''))
end

function VehicleTypes.Load()
    waitForDatabase()

    local ok, rows = pcall(function()
        return Database.Query(([[
            SELECT job, vehtype
            FROM `%s`
            ORDER BY vehtype ASC
        ]]):format(tableName()))
    end)

    VehicleTypes.byJob = {}

    if ok and type(rows) == 'table' then
        for _, row in ipairs(rows) do
            local job = type(row.job) == 'string' and row.job or ''
            local vehicleType = VehicleTypes.NormalizeType(row.vehtype)

            if job ~= '' and vehicleType ~= '' then
                VehicleTypes.byJob[job] = VehicleTypes.byJob[job] or {}

                local exists = false
                for _, existing in ipairs(VehicleTypes.byJob[job]) do
                    if existing == vehicleType then
                        exists = true
                        break
                    end
                end

                if not exists then
                    VehicleTypes.byJob[job][#VehicleTypes.byJob[job] + 1] = vehicleType
                end
            end
        end
    else
        print(('[ktjobs] WARNUNG: EMD-Fahrzeugtypen konnten nicht aus `%s` geladen werden.'):format(tableName()))
    end

    VehicleTypes.ready = true

    local jobCount = 0
    for _ in pairs(VehicleTypes.byJob) do
        jobCount = jobCount + 1
    end

    print(('[ktjobs] EMD-Fahrzeugtypen für %s Jobs aus `%s` geladen.'):format(jobCount, tableName()))
end

function VehicleTypes.GetForJob(jobName)
    if not jobName or jobName == '' then
        return {}
    end

    return VehicleTypes.byJob[jobName] or {}
end

function VehicleTypes.GetGrouped()
    return VehicleTypes.byJob
end

function VehicleTypes.IsValidForJob(jobName, vehicleType)
    local normalized = VehicleTypes.NormalizeType(vehicleType)

    for _, allowed in ipairs(VehicleTypes.GetForJob(jobName)) do
        if allowed == normalized then
            return true
        end
    end

    return false
end

function VehicleTypes.WaitUntilReady()
    while not Database.ready or not VehicleTypes.ready do
        Wait(50)
    end
end

CreateThread(function()
    VehicleTypes.Load()
end)
