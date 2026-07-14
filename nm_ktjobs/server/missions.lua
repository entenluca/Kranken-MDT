Missions = {
    cooldowns = {},
    active = {},
    pendingDispatch = {},
}

local function getOccupiedVehicleCounts(jobName)
    return EmergencyDispatch.GetMannedVehicleCounts(jobName)
end

function Missions.VehicleRequirementsMet(mission)
    if not mission.vehicles or #mission.vehicles == 0 then
        return true
    end

    local counts = getOccupiedVehicleCounts(mission.job)

    for _, requirement in ipairs(mission.vehicles) do
        local reqType = EmergencyDispatch.NormalizeVehicleType(requirement.type)
        local current = counts[reqType] or 0
        if current < requirement.min then
            return false
        end
    end

    return true
end

function Missions.GetVehicleStatus(mission)
    local counts = getOccupiedVehicleCounts(mission.job)
    local status = {}

    for _, requirement in ipairs(mission.vehicles or {}) do
        local reqType = EmergencyDispatch.NormalizeVehicleType(requirement.type)
        status[#status + 1] = {
            type = reqType,
            min = requirement.min,
            current = counts[reqType] or 0,
            met = (counts[reqType] or 0) >= requirement.min,
        }
    end

    return status
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

function Missions.CreateActive(mission)
    local activeId = ('a_%s_%s'):format(mission.id, os.time())
    Missions.active[activeId] = {
        id = activeId,
        missionId = mission.id,
        mission = mission,
        acceptedBy = nil,
        state = 'dispatched',
        createdAt = os.time(),
    }
    return activeId, Missions.active[activeId]
end

function Missions.GetActive(activeId)
    return Missions.active[activeId]
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

    local message = Dispatch.BuildMessage(mission)
    if not Dispatch.Send(mission.job, message, mission.start) then
        return false
    end

    local activeId = Missions.CreateActive(mission)
    Missions.SetCooldown(mission.id)

    TriggerClientEvent('nm_ktjobs:client:missionDispatched', -1, activeId, mission, message)
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

function Missions.CompleteMission(source, activeId)
    local active = Missions.GetActive(activeId)
    if not active or active.acceptedBy ~= source then
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
    if not active or active.acceptedBy ~= source then
        return false
    end

    Missions.RemoveMissionItems(source, active.mission)
    Missions.RemoveActive(activeId)
    TriggerClientEvent('nm_ktjobs:client:missionEnded', source, activeId, 'cancelled', 0)
    return true
end

CreateThread(function()
    while true do
        Wait(Config.CheckInterval * 1000)

        for _, mission in ipairs(Storage.GetMissions()) do
            if mission.enabled and Missions.VehicleRequirementsMet(mission) then
                Missions.DispatchMission(mission)
            end
        end
    end
end)
