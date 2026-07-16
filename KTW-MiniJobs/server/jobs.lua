Jobs = {
    list = {},
    ready = false,
}

local function jobsTableName()
    return Config.DatabaseJobsTable or 'ktjobs_jobs'
end

local function waitForDatabase()
    while not Database.ready do
        Wait(50)
    end
end

function Jobs.Load()
    waitForDatabase()

    local rows = Database.Query(([[
        SELECT name, label, sort_order, enabled
        FROM `%s`
        WHERE enabled = 1
        ORDER BY sort_order ASC, label ASC
    ]]):format(jobsTableName()))

    Jobs.list = {}
    for _, row in ipairs(rows) do
        Jobs.list[#Jobs.list + 1] = {
            name = row.name,
            label = row.label ~= '' and row.label or row.name,
        }
    end

    Jobs.ready = true
    print(('[ktjobs] %s Jobs aus Datenbank geladen.'):format(#Jobs.list))
end

function Jobs.GetJobs()
    return Jobs.list
end

function Jobs.IsValid(jobName)
    if not jobName or jobName == '' then
        return false
    end

    for _, job in ipairs(Jobs.list) do
        if job.name == jobName then
            return true
        end
    end

    return false
end

function Jobs.ResolveJob(jobName)
    if Jobs.IsValid(jobName) then
        return jobName
    end

    if Jobs.list[1] then
        return Jobs.list[1].name
    end

    return type(jobName) == 'string' and jobName or ''
end

function Jobs.WaitUntilReady()
    while not Database.ready or not Jobs.ready do
        Wait(50)
    end
end

CreateThread(function()
    Jobs.Load()
end)
