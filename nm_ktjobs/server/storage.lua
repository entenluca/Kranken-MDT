Storage = {
    missions = {},
    resourceName = GetCurrentResourceName(),
}

function Storage.Load()
    local raw = LoadResourceFile(Storage.resourceName, 'data/missions.json')
    if not raw or raw == '' then
        Storage.missions = {}
        return
    end

    local decoded = json.decode(raw)
    Storage.missions = Utils.SanitizeMissions(decoded or {})
end

function Storage.Save()
    local encoded = json.encode(Storage.missions, { indent = true })
    SaveResourceFile(Storage.resourceName, 'data/missions.json', encoded, -1)
end

function Storage.GetMissions()
    return Storage.missions
end

function Storage.SetMissions(missions)
    Storage.missions = Utils.SanitizeMissions(missions)
    Storage.Save()
end

function Storage.GetMissionById(id)
    for _, mission in ipairs(Storage.missions) do
        if mission.id == id then
            return mission
        end
    end
    return nil
end

CreateThread(function()
    Storage.Load()
end)
