Jobs = {
    list = {},
    ready = false,
}

local function jobsTableName()
    return Config.JobsTable or 'jobs'
end

local function waitForDatabase()
    while not Database.ready do
        Wait(50)
    end
end

function Jobs.Load()
    waitForDatabase()

    local ok, rows = pcall(function()
        return Database.Query(([[
            SELECT name, label
            FROM `%s`
            ORDER BY label ASC
        ]]):format(jobsTableName()))
    end)

    Jobs.list = {}

    if ok and type(rows) == 'table' then
        for _, row in ipairs(rows) do
            if row.name and row.name ~= '' then
                Jobs.list[#Jobs.list + 1] = {
                    name = row.name,
                    label = row.label and row.label ~= '' and row.label or row.name,
                }
            end
        end
    else
        print(('[ktjobs] WARNUNG: Jobs konnten nicht aus `%s` geladen werden.'):format(jobsTableName()))
    end

    Jobs.ready = true
    print(('[ktjobs] %s Jobs aus `%s` geladen.'):format(#Jobs.list, jobsTableName()))
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
