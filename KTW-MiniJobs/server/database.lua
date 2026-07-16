Database = {
    driver = nil,
    ready = false,
    tableName = Config.DatabaseTable or 'ktjobs_missions',
}

local function detectDriver()
    if Config.Database == 'oxmysql' or (Config.Database == 'auto' and GetResourceState('oxmysql') == 'started') then
        Database.driver = 'oxmysql'
        return true
    end

    if Config.Database == 'mysql-async' or (Config.Database == 'auto' and GetResourceState('mysql-async') == 'started') then
        Database.driver = 'mysql-async'
        return true
    end

    return false
end

local function splitSqlStatements(sql)
    local statements = {}

    for statement in sql:gmatch('([^;]+)') do
        local trimmed = statement:match('^%s*(.-)%s*$')
        if trimmed and trimmed ~= '' then
            statements[#statements + 1] = trimmed
        end
    end

    return statements
end

function Database.Await(fn)
    if Database.driver == 'oxmysql' then
        return fn()
    end

    local p = promise.new()
    fn(function(result)
        p:resolve(result)
    end)
    return Citizen.Await(p)
end

function Database.Execute(query, params)
    params = params or {}

    if Database.driver == 'oxmysql' then
        return MySQL.update.await(query, params)
    end

    return Database.Await(function(resolve)
        MySQL.Async.execute(query, params, function(rows)
            resolve(rows)
        end)
    end)
end

function Database.Query(query, params)
    params = params or {}

    if Database.driver == 'oxmysql' then
        return MySQL.query.await(query, params) or {}
    end

    return Database.Await(function(resolve)
        MySQL.Async.fetchAll(query, params, function(result)
            resolve(result or {})
        end)
    end)
end

function Database.Scalar(query, params)
    local rows = Database.Query(query, params)
    local row = rows[1]
    if not row then
        return nil
    end

    for _, value in pairs(row) do
        return value
    end

    return nil
end

function Database.RunSqlFile(relativePath)
    local resourceName = GetCurrentResourceName()
    local sql = LoadResourceFile(resourceName, relativePath)

    if not sql or sql == '' then
        print(('[ktjobs] SQL-Datei nicht gefunden: %s'):format(relativePath))
        return false
    end

    for _, statement in ipairs(splitSqlStatements(sql)) do
        Database.Execute(statement, {})
    end

    return true
end

function Database.Init()
    if not detectDriver() then
        print('[ktjobs] FEHLER: Weder oxmysql noch mysql-async gefunden. Einsätze können nicht gespeichert werden.')
        return false
    end

    if Database.driver == 'oxmysql' then
        MySQL.ready.await()
    else
        local waited = 0
        while not MySQL and waited < 100 do
            Wait(100)
            waited = waited + 1
        end
    end

    Database.RunSqlFile('sql/ktjobs.sql')
    Database.ready = true
    print(('[ktjobs] Datenbank bereit (%s, Einsätze: %s, Jobs: %s)'):format(
        Database.driver,
        Config.DatabaseTable,
        Config.JobsTable
    ))
    return true
end

CreateThread(function()
    Database.Init()
end)
