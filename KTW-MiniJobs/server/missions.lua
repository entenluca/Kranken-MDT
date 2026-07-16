Missions = {
    cooldowns = {},
    active = {},
}

local function getOccupiedVehicleCounts(jobName)
    return EmergencyDispatch.GetMannedVehicleCounts(jobName)
end

function Missions.VehicleRequirementsMet(mission)
    if not mission.vehicles or #mission.vehicles == 0 then
        return #EmergencyDispatch.SelectVehiclesForMission(mission) > 0
    end

    local counts = getOccupiedVehicleCounts(mission.job)

    for _, requirement in ipairs(mission.vehicles) do
        local reqType = EmergencyDispatch.NormalizeVehicleType(requirement.type)
        local current = counts[reqType] or 0
        if current < requirement.min then
            return false
        end
    end

    return #EmergencyDispatch.SelectVehiclesForMission(mission) > 0
end

function Missions.GetVehicleStatus(mission)
    local result = {
        ready = false,
        issues = {},
        requirements = {},
        emdAvailable = EmergencyDispatch.IsAvailable(),
    }

    local jobName = mission.job or ''

    if jobName == '' then
        result.issues[#result.issues + 1] = 'Kein Job ausgewählt.'
        return result
    end

    if #VehicleTypes.GetForJob(jobName) == 0 then
        result.issues[#result.issues + 1] = ('Für Job „%s“ sind keine EMD-Fahrzeugtypen hinterlegt.'):format(jobName)
        return result
    end

    if not result.emdAvailable then
        result.issues[#result.issues + 1] = 'EmergencyDispatch ist nicht gestartet – Live-Status der besetzten Fahrzeuge nicht verfügbar.'
    end

    local mannedCounts = getOccupiedVehicleCounts(jobName)
    local availableGrouped = EmergencyDispatch.GroupAvailableVehiclesByType(jobName)
    local vehicles = mission.vehicles or {}
    local configValid = true

    if #vehicles == 0 then
        local availableTotal = 0
        local mannedTotal = 0

        for vehicleType, pool in pairs(availableGrouped) do
            availableTotal = availableTotal + #pool
            mannedTotal = mannedTotal + (mannedCounts[vehicleType] or 0)
        end

        local met = availableTotal > 0
        result.requirements[#result.requirements + 1] = {
            type = 'Beliebig',
            min = 1,
            manned = mannedTotal,
            available = availableTotal,
            met = met,
            message = met
                and 'Keine Zeilen konfiguriert – mindestens ein freies Fahrzeug verfügbar.'
                or 'Keine Zeilen konfiguriert – kein freies besetztes Fahrzeug im Dienst verfügbar.',
        }

        if not met and result.emdAvailable then
            result.issues[#result.issues + 1] = 'Kein freies besetztes Fahrzeug im Dienst verfügbar.'
        end

        result.ready = met and result.emdAvailable
        return result
    end

    for index, requirement in ipairs(vehicles) do
        local reqType = EmergencyDispatch.NormalizeVehicleType(requirement.type)
        local min = tonumber(requirement.min)

        if reqType == '' then
            result.issues[#result.issues + 1] = ('Zeile %s: Fahrzeugtyp fehlt.'):format(index)
            configValid = false
        elseif not VehicleTypes.IsValidForJob(jobName, reqType) then
            result.issues[#result.issues + 1] = ('Zeile %s: „%s“ ist für diesen Job kein gültiger EMD-Typ.'):format(index, reqType)
            configValid = false
        elseif not min or min < 1 then
            result.issues[#result.issues + 1] = ('Zeile %s: Mindestanzahl fehlt oder ist ungültig.'):format(index)
            configValid = false
        end
    end

    if not configValid then
        return result
    end

    local allMet = true

    for _, requirement in ipairs(vehicles) do
        local reqType = EmergencyDispatch.NormalizeVehicleType(requirement.type)
        local min = math.max(1, math.floor(tonumber(requirement.min) or 1))
        local manned = mannedCounts[reqType] or 0
        local available = #(availableGrouped[reqType] or {})
        local met = available >= min
        local message

        if met then
            message = ('%s: %s/%s frei verfügbar (erfüllt)'):format(reqType, available, min)
        elseif manned < min then
            message = ('%s: nur %s/%s besetzt – es fehlen %s'):format(reqType, manned, min, min - manned)
        else
            message = ('%s: %s besetzt, aber nur %s/%s frei (andere im Einsatz)'):format(reqType, manned, available, min)
        end

        result.requirements[#result.requirements + 1] = {
            type = reqType,
            min = min,
            manned = manned,
            available = available,
            met = met,
            message = message,
        }

        if not met then
            result.issues[#result.issues + 1] = message
            allMet = false
        end
    end

    if allMet and result.emdAvailable then
        result.ready = #EmergencyDispatch.SelectVehiclesForMission(mission) > 0
        if not result.ready then
            result.issues[#result.issues + 1] = 'Nicht genügend freie Fahrzeuge für die automatische Zuweisung verfügbar.'
        end
    end

    return result
end

function Missions.IsOnCooldown(missionId)
    local untilTime = Missions.cooldowns[missionId]
    return untilTime ~= nil and untilTime > os.time()
end

function Missions.SetCooldown(missionId)
    Missions.cooldowns[missionId] = os.time() + Config.MissionCooldown
end

function Missions.CountActive()
    local count = 0
    for _ in pairs(Missions.active) do
        count = count + 1
    end
    return count
end

function Missions.CreateActive(mission, assignees, route)
    local activeId = ('a_%s_%s'):format(mission.id, os.time())
    local assignedTo = {}

    for _, entry in ipairs(assignees) do
        assignedTo[entry.source] = {
            source = entry.source,
            type = EmergencyDispatch.NormalizeVehicleType(entry.type),
            value = entry.value,
            veh = entry.veh,
        }
    end

    Missions.active[activeId] = {
        id = activeId,
        missionId = mission.id,
        mission = mission,
        assignedTo = assignedTo,
        state = 'assigned',
        route = route,
        createdAt = os.time(),
    }

    return activeId, Missions.active[activeId]
end

function Missions.GetActive(activeId)
    return Missions.active[activeId]
end

function Missions.IsAssigned(active, source)
    return active and active.assignedTo and active.assignedTo[source] ~= nil
end

function Missions.RemoveActive(activeId)
    Missions.active[activeId] = nil
end

function Missions.DispatchMission(mission)
    if Missions.IsOnCooldown(mission.id) then
        return false
    end

    if Missions.CountActive() >= Config.MaxActiveMissions then
        return false
    end

    for _, active in pairs(Missions.active) do
        if active.missionId == mission.id and active.state ~= 'completed' then
            return false
        end
    end

    local assignees = EmergencyDispatch.SelectVehiclesForMission(mission)
    if #assignees == 0 then
        return false
    end

    local route = Dispatch.BuildRouteInfo(mission)
    local message = Dispatch.BuildMessage(mission, route)

    if not Dispatch.Send(mission.job, message, mission.start, Config.DispatchShowBlip) then
        return false
    end

    local activeId = Missions.CreateActive(mission, assignees, route)
    Missions.SetCooldown(mission.id)

    for _, entry in ipairs(assignees) do
        TriggerClientEvent('nm_ktjobs:client:missionAssigned', entry.source, activeId, mission, route)
    end

    return true, activeId
end

function Missions.GiveMissionItems(source, mission)
    if mission.type ~= 'MTD' then
        return
    end

    for _, item in ipairs(mission.items or {}) do
        Framework.AddItem(source, item.name, item.amount)
    end
end

function Missions.RemoveMissionItems(source, mission)
    if mission.type ~= 'MTD' then
        return
    end

    for _, item in ipairs(mission.items or {}) do
        Framework.RemoveItem(source, item.name, item.amount)
    end
end

function Missions.ArrivedAtStart(source, activeId)
    local active = Missions.GetActive(activeId)
    if not active or not Missions.IsAssigned(active, source) then
        return false
    end

    if active.state ~= 'assigned' then
        return false
    end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local start = Utils.CoordsToVector3(active.mission.start)

    if #(coords - start) > Config.AcceptRadius + 5.0 then
        Framework.Notify(source, 'Du bist nicht am Startpunkt.', 'error')
        return false
    end

    active.state = 'transport'
    Missions.GiveMissionItems(source, active.mission)

    TriggerClientEvent('nm_ktjobs:client:missionTransport', source, activeId, active.mission)
    return true
end

function Missions.CompleteMission(source, activeId)
    local active = Missions.GetActive(activeId)
    if not active or not Missions.IsAssigned(active, source) then
        return false
    end

    if active.state ~= 'transport' then
        return false
    end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local target = Utils.CoordsToVector3(active.mission.target)

    if #(coords - target) > Config.CompleteRadius + 5.0 then
        Framework.Notify(source, 'Du bist nicht am Zielpunkt.', 'error')
        return false
    end

    local rewardAmount = 0

    if active.mission.reward.enabled then
        rewardAmount = Utils.RandomReward(active.mission.reward)
        Framework.AddSocietyMoney(active.mission.job, rewardAmount)
    end

    Missions.RemoveMissionItems(source, active.mission)
    Missions.RemoveActive(activeId)

    TriggerClientEvent('nm_ktjobs:client:missionEnded', source, activeId, 'completed', rewardAmount, active.mission.job)
    return true, rewardAmount, active.mission.job
end

function Missions.CancelMission(source, activeId)
    local active = Missions.GetActive(activeId)
    if not active or not Missions.IsAssigned(active, source) then
        return false
    end

    Missions.RemoveMissionItems(source, active.mission)
    Missions.RemoveActive(activeId)
    TriggerClientEvent('nm_ktjobs:client:missionEnded', source, activeId, 'cancelled', 0)
    return true
end

CreateThread(function()
    Storage.WaitUntilReady()

    while true do
        Wait(Config.CheckInterval * 1000)

        for _, mission in ipairs(Storage.GetMissions()) do
            if mission.enabled and Missions.VehicleRequirementsMet(mission) then
                Missions.DispatchMission(mission)
            end
        end
    end
end)
