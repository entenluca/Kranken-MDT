local State = {
    missions = {},
    jobs = {},
    vehicleTypesByJob = {},
    npcModels = {},
    stichwortList = {},
    defaultStichwortByType = {},
    defaultIntervalMinutes = 15,
    defaultNpcModel = '',
    displayTitle = 'Krankentransport-Jobs',
}

local placementActive = false

local function notify(message, nType)
    lib.notify({
        title = State.displayTitle,
        description = message,
        type = nType or 'inform',
    })
end

local function getMissionById(missionId)
    for _, mission in ipairs(State.missions) do
        if mission.id == missionId then
            return mission
        end
    end
end

local function missionLabel(mission)
    local text = mission.text ~= '' and mission.text or stichwortLabel(mission.stichwort)
    local status = mission.enabled and 'Aktiv' or 'Inaktiv'
    local intervalMinutes = tonumber(mission.intervalMinutes)
    local intervalText = ''

    if intervalMinutes == 0 then
        intervalText = ' · nur manuell'
    elseif intervalMinutes and intervalMinutes > 0 then
        intervalText = (' · alle %s Min'):format(intervalMinutes)
    end

    return ('%s · %s · %s'):format(mission.type, mission.job, text) .. intervalText .. (' (%s)'):format(status)
end

local function jobOptions()
    local options = {}
    for _, job in ipairs(State.jobs) do
        options[#options + 1] = {
            value = job.name,
            label = job.label or job.name,
        }
    end
    return options
end

local function vehicleTypeOptions(jobName)
    local options = {}
    for _, vehicleType in ipairs(State.vehicleTypesByJob[jobName] or {}) do
        options[#options + 1] = {
            value = vehicleType,
            label = vehicleType,
        }
    end
    return options
end

local function npcOptions()
    local options = {}
    for _, entry in ipairs(State.npcModels) do
        options[#options + 1] = {
            value = entry.model,
            label = ('%s · %s'):format(entry.name, entry.model),
        }
    end
    return options
end

local function stichwortLabel(stichwortId)
    for _, entry in ipairs(State.stichwortList) do
        if entry.id == stichwortId then
            return entry.label or entry.id
        end
    end
    return stichwortId ~= '' and stichwortId or 'Standard'
end

local function stichwortOptions()
    local options = {}
    for _, entry in ipairs(State.stichwortList) do
        options[#options + 1] = {
            value = entry.id,
            label = entry.label or entry.id,
        }
    end
    return options
end

local function defaultStichwortForType(missionType)
    return State.defaultStichwortByType[missionType]
        or (missionType == 'KT' and 'krankentransport' or 'patientenverlegung')
end

local function formatCoords(coords)
    if not coords then
        return 'Nicht gesetzt'
    end

    return ('%.2f, %.2f, %.2f'):format(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
end

local function saveMissions()
    local ok = lib.callback.await('ktjobs:saveMissions', false, State.missions)
    if ok then
        local data = lib.callback.await('ktjobs:getConfiguratorData', false)
        if data and data.missions then
            State.missions = data.missions
        end
        notify('Einsätze gespeichert.', 'success')
        return true
    end

    notify('Speichern fehlgeschlagen.', 'error')
    return false
end

local function showVehicleStatus(missionId)
    local mission = getMissionById(missionId)
    if not mission then
        return
    end

    local status = lib.callback.await('ktjobs:getVehicleStatus', false, mission)
    if not status then
        notify('Status konnte nicht geladen werden.', 'error')
        return
    end

    local lines = {}

    if status.ready then
        lines[#lines + 1] = 'Alle Voraussetzungen erfüllt.'
    end

    for _, issue in ipairs(status.issues or {}) do
        lines[#lines + 1] = '• ' .. issue
    end

    for _, requirement in ipairs(status.requirements or {}) do
        if requirement.message then
            lines[#lines + 1] = (requirement.met and '✓ ' or '✗ ') .. requirement.message
        end
    end

    if #lines == 0 then
        lines[#lines + 1] = 'Keine Statusinformationen verfügbar.'
    end

    lib.alertDialog({
        header = status.ready and 'Fahrzeug-Status: Bereit' or 'Fahrzeug-Status: Nicht bereit',
        content = table.concat(lines, '\n'),
        centered = true,
        cancel = false,
    })
end

local function showRoute(missionId)
    local mission = getMissionById(missionId)
    if not mission then
        return
    end

    local start = mission.start
    local target = mission.target

    if not start or not target or not start.x or not target.x then
        notify('Start- und Zielpunkt müssen gesetzt sein.', 'error')
        return
    end

    local route = EmergencyDispatchClient.CalculateRoute(start, target)
    lib.alertDialog({
        header = 'Strecke Start → Ziel',
        content = ('Strecke: %s\nGeschätzte Fahrzeit: ~%s Min'):format(route.distanceLabel, route.eta),
        centered = true,
        cancel = false,
    })
end

local function finishPlacement(field, missionId, coords)
    placementActive = false
    lib.hideTextUI()

    local mission = getMissionById(missionId)
    if not mission then
        return
    end

    mission[field] = {
        x = tonumber(string.format('%.2f', coords.x)),
        y = tonumber(string.format('%.2f', coords.y)),
        z = tonumber(string.format('%.2f', coords.z)),
    }

    notify(('%s gesetzt: %s'):format(field == 'target' and 'Zielpunkt' or 'Startpunkt', formatCoords(mission[field])), 'success')
    lib.showContext('ktjobs_mission_' .. missionId)
end

local function cancelPlacement(missionId)
    if not placementActive then
        return
    end

    placementActive = false
    lib.hideTextUI()
    lib.showContext('ktjobs_mission_' .. missionId)
end

local function startPlacement(missionId, field)
    if placementActive then
        return
    end

    placementActive = true
    DisplayRadar(true)

    local label = field == 'target' and 'Zielpunkt' or 'Startpunkt'
    lib.showTextUI(('[ %s ] %s setzen\n[ ESC ] Abbrechen'):format(Config.PlacementKeyLabel, label), {
        position = 'left-center',
    })

    CreateThread(function()
        while placementActive do
            Wait(0)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            DrawMarker(
                1,
                coords.x, coords.y, coords.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.2, 1.2, 1.0,
                59, 130, 246, 140,
                false, false, 2, false, nil, nil, false
            )

            if IsControlJustReleased(0, Config.PlacementKey) then
                finishPlacement(field, missionId, coords)
                break
            end

            if IsControlJustReleased(0, Config.PlacementCancelKey) then
                cancelPlacement(missionId)
                break
            end
        end
    end)
end

local function editMissionBasics(missionId)
    local mission = getMissionById(missionId)
    if not mission then
        return
    end

    local jobs = jobOptions()
    if #jobs == 0 then
        notify('Keine Jobs verfügbar.', 'error')
        return
    end

    local currentJobIndex = 1
    for index, option in ipairs(jobs) do
        if option.value == mission.job then
            currentJobIndex = index
            break
        end
    end

    local stichworte = stichwortOptions()
    local currentStichwortIndex = 1
    local missionStichwort = Utils.SanitizeStichwort(mission.stichwort, mission.type)
    for index, option in ipairs(stichworte) do
        if option.value == missionStichwort then
            currentStichwortIndex = index
            break
        end
    end

    local dialogFields = {
        {
            type = 'select',
            label = 'Typ',
            options = {
                { value = 'MTD', label = 'MTD' },
                { value = 'KT', label = 'KT' },
            },
            default = mission.type == 'KT' and 2 or 1,
        },
        {
            type = 'select',
            label = 'Job',
            options = jobs,
            default = currentJobIndex,
        },
    }

    if #stichworte > 0 then
        dialogFields[#dialogFields + 1] = {
            type = 'select',
            label = 'EMD-Stichwort',
            description = 'Meldungstext wie im Rettungsdienst (Patientenverlegung, NEF, Klinikfahrt …)',
            options = stichworte,
            default = currentStichwortIndex,
        }
    end

    dialogFields[#dialogFields + 1] = {
        type = 'input',
        label = 'Zusatztext (optional)',
        description = 'Wird an die EMD-Meldung angehängt',
        default = mission.text or '',
    }
    dialogFields[#dialogFields + 1] = {
        type = 'checkbox',
        label = 'Einsatz aktiv',
        checked = mission.enabled ~= false,
    }
    dialogFields[#dialogFields + 1] = {
        type = 'number',
        label = 'Intervall (Minuten)',
        description = 'Automatische Wiederholung; 0 = nur Test-Auslösung, kein Auto-Einsatz',
        default = mission.intervalMinutes ~= nil and mission.intervalMinutes or State.defaultIntervalMinutes,
        min = 0,
        max = 1440,
    }

    local input = lib.inputDialog('Einsatz bearbeiten', dialogFields)

    if not input then
        lib.showContext('ktjobs_mission_' .. missionId)
        return
    end

    local fieldIndex = {
        type = 1,
        job = 2,
    }
    local nextIndex = 3

    if #stichworte > 0 then
        fieldIndex.stichwort = nextIndex
        nextIndex = nextIndex + 1
    end

    fieldIndex.text = nextIndex
    fieldIndex.enabled = nextIndex + 1
    fieldIndex.intervalMinutes = nextIndex + 2

    local previousType = mission.type
    mission.type = input[fieldIndex.type]
    mission.job = input[fieldIndex.job]
    if fieldIndex.stichwort then
        mission.stichwort = input[fieldIndex.stichwort]
    elseif mission.type ~= previousType then
        mission.stichwort = defaultStichwortForType(mission.type)
    end

    if mission.type ~= previousType and fieldIndex.stichwort then
        local oldDefault = defaultStichwortForType(previousType)
        if not mission.stichwort or mission.stichwort == '' or mission.stichwort == oldDefault then
            mission.stichwort = defaultStichwortForType(mission.type)
        end
    end

    mission.stichwort = Utils.SanitizeStichwort(mission.stichwort, mission.type)
    mission.text = input[fieldIndex.text] or ''
    mission.enabled = input[fieldIndex.enabled] == true
    mission.intervalMinutes = Utils.SanitizeIntervalMinutes(input[fieldIndex.intervalMinutes])

    local allowedTypes = State.vehicleTypesByJob[mission.job] or {}
    local allowedMap = {}
    for _, vehicleType in ipairs(allowedTypes) do
        allowedMap[vehicleType] = true
    end

    mission.vehicles = mission.vehicles or {}
    local filtered = {}
    for _, vehicle in ipairs(mission.vehicles) do
        if allowedMap[vehicle.type] then
            filtered[#filtered + 1] = vehicle
        end
    end
    mission.vehicles = filtered

    if mission.type == 'KT' then
        mission.items = {}
    end

    registerMissionMenus()
    lib.showContext('ktjobs_mission_' .. missionId)
end

local function editReward(missionId)
    local mission = getMissionById(missionId)
    if not mission then
        return
    end

    mission.reward = mission.reward or { enabled = false, min = 0, max = 0 }

    local input = lib.inputDialog('Belohnung', {
        {
            type = 'checkbox',
            label = 'Belohnung aktivieren',
            checked = mission.reward.enabled == true,
        },
        {
            type = 'number',
            label = 'Minimum',
            default = mission.reward.min or 0,
            min = 0,
        },
        {
            type = 'number',
            label = 'Maximum',
            default = mission.reward.max or 0,
            min = 0,
        },
    })

    if not input then
        lib.showContext('ktjobs_mission_' .. missionId)
        return
    end

    mission.reward = {
        enabled = input[1] == true,
        min = tonumber(input[2]) or 0,
        max = tonumber(input[3]) or 0,
    }

    lib.showContext('ktjobs_mission_' .. missionId)
end

local function editNpc(missionId)
    local mission = getMissionById(missionId)
    if not mission then
        return
    end

    local options = npcOptions()
    if #options == 0 then
        notify('Keine NPC-Modelle konfiguriert.', 'error')
        return
    end

    local currentIndex = 1
    for index, option in ipairs(options) do
        if option.value == mission.npcModel then
            currentIndex = index
            break
        end
    end

    local input = lib.inputDialog('NPC-Modell', {
        {
            type = 'select',
            label = 'NPC',
            options = options,
            default = currentIndex,
        },
    })

    if not input then
        lib.showContext('ktjobs_mission_' .. missionId)
        return
    end

    mission.npcModel = input[1]
    lib.showContext('ktjobs_mission_' .. missionId)
end

local function addVehicleRequirement(missionId)
    local mission = getMissionById(missionId)
    if not mission then
        return
    end

    local options = vehicleTypeOptions(mission.job)
    if #options == 0 then
        notify('Für diesen Job sind keine EMD-Fahrzeugtypen hinterlegt.', 'error')
        return
    end

    local input = lib.inputDialog('Fahrzeug hinzufügen', {
        {
            type = 'select',
            label = 'Fahrzeugtyp',
            options = options,
        },
        {
            type = 'number',
            label = 'Mindestanzahl besetzt',
            default = 1,
            min = 1,
        },
    })

    if not input then
        lib.showContext('ktjobs_vehicles_' .. missionId)
        return
    end

    mission.vehicles = mission.vehicles or {}
    mission.vehicles[#mission.vehicles + 1] = {
        type = input[1],
        min = tonumber(input[2]) or 1,
    }

    registerMissionMenus()
    lib.showContext('ktjobs_vehicles_' .. missionId)
end

local function editVehicleRequirement(missionId, index)
    local mission = getMissionById(missionId)
    if not mission or not mission.vehicles or not mission.vehicles[index] then
        return
    end

    local vehicle = mission.vehicles[index]
    local options = vehicleTypeOptions(mission.job)
    if #options == 0 then
        notify('Für diesen Job sind keine EMD-Fahrzeugtypen hinterlegt.', 'error')
        return
    end

    local currentIndex = 1
    for optionIndex, option in ipairs(options) do
        if option.value == vehicle.type then
            currentIndex = optionIndex
            break
        end
    end

    local input = lib.inputDialog('Fahrzeug bearbeiten', {
        {
            type = 'select',
            label = 'Fahrzeugtyp',
            options = options,
            default = currentIndex,
        },
        {
            type = 'number',
            label = 'Mindestanzahl besetzt',
            default = vehicle.min or 1,
            min = 1,
        },
    })

    if not input then
        lib.showContext('ktjobs_vehicles_' .. missionId)
        return
    end

    vehicle.type = input[1]
    vehicle.min = tonumber(input[2]) or 1

    registerMissionMenus()
    lib.showContext('ktjobs_vehicles_' .. missionId)
end

local function removeVehicleRequirement(missionId, index)
    local mission = getMissionById(missionId)
    if not mission or not mission.vehicles then
        return
    end

    table.remove(mission.vehicles, index)
    registerMissionMenus()
    lib.showContext('ktjobs_vehicles_' .. missionId)
end

local function addMissionItem(missionId)
    local mission = getMissionById(missionId)
    if not mission then
        return
    end

    local input = lib.inputDialog('MTD-Item hinzufügen', {
        { type = 'input', label = 'Item-Name' },
        { type = 'number', label = 'Menge', default = 1, min = 1 },
    })

    if not input or input[1] == '' then
        lib.showContext('ktjobs_items_' .. missionId)
        return
    end

    mission.items = mission.items or {}
    mission.items[#mission.items + 1] = {
        name = input[1],
        amount = tonumber(input[2]) or 1,
    }

    registerMissionMenus()
    lib.showContext('ktjobs_items_' .. missionId)
end

local function editMissionItem(missionId, index)
    local mission = getMissionById(missionId)
    if not mission or not mission.items or not mission.items[index] then
        return
    end

    local item = mission.items[index]
    local input = lib.inputDialog('MTD-Item bearbeiten', {
        { type = 'input', label = 'Item-Name', default = item.name or '' },
        { type = 'number', label = 'Menge', default = item.amount or 1, min = 1 },
    })

    if not input or input[1] == '' then
        lib.showContext('ktjobs_items_' .. missionId)
        return
    end

    item.name = input[1]
    item.amount = tonumber(input[2]) or 1

    registerMissionMenus()
    lib.showContext('ktjobs_items_' .. missionId)
end

local function removeMissionItem(missionId, index)
    local mission = getMissionById(missionId)
    if not mission or not mission.items then
        return
    end

    table.remove(mission.items, index)
    registerMissionMenus()
    lib.showContext('ktjobs_items_' .. missionId)
end

local function testDispatchMission(missionId)
    local mission = getMissionById(missionId)
    if not mission then
        return
    end

    local confirmed = lib.alertDialog({
        header = 'Test-Auslösung',
        content = 'Einsatz sofort an EmergencyDispatch senden? Cooldown wird dabei ignoriert.',
        centered = true,
        cancel = true,
    })

    if confirmed ~= 'confirm' then
        lib.showContext('ktjobs_mission_' .. missionId)
        return
    end

    local result = lib.callback.await('ktjobs:testDispatchMission', false, mission)
    if result and result.ok then
        notify(result.message or 'Test-Auslösung erfolgreich.', result.emdOnly and 'inform' or 'success')
    else
        notify((result and result.reason) or 'Test-Auslösung fehlgeschlagen.', 'error')
    end

    lib.showContext('ktjobs_mission_' .. missionId)
end

local function deleteMission(missionId)
    local confirmed = lib.alertDialog({
        header = 'Einsatz löschen',
        content = 'Diesen Einsatz wirklich löschen?',
        centered = true,
        cancel = true,
    })

    if confirmed ~= 'confirm' then
        lib.showContext('ktjobs_mission_' .. missionId)
        return
    end

    for index, mission in ipairs(State.missions) do
        if mission.id == missionId then
            table.remove(State.missions, index)
            break
        end
    end

    registerMissionMenus()
    lib.showContext('ktjobs_main')
end

function registerMissionMenus()
    for _, mission in ipairs(State.missions) do
        local missionId = mission.id
        local vehicleOptions = {
            {
                title = 'Fahrzeug hinzufügen',
                icon = 'plus',
                onSelect = function()
                    addVehicleRequirement(missionId)
                end,
            },
            {
                title = 'Status prüfen',
                icon = 'truck-medical',
                onSelect = function()
                    showVehicleStatus(missionId)
                end,
            },
        }

        for index, vehicle in ipairs(mission.vehicles or {}) do
            local vehicleIndex = index
            vehicleOptions[#vehicleOptions + 1] = {
                title = ('%s · min. %s'):format(vehicle.type or '?', vehicle.min or 1),
                icon = 'pen',
                onSelect = function()
                    editVehicleRequirement(missionId, vehicleIndex)
                end,
            }
            vehicleOptions[#vehicleOptions + 1] = {
                title = ('%s · Zeile %s entfernen'):format(vehicle.type or '?', vehicleIndex),
                icon = 'trash',
                onSelect = function()
                    removeVehicleRequirement(missionId, vehicleIndex)
                end,
            }
        end

        lib.registerContext({
            id = 'ktjobs_vehicles_' .. missionId,
            title = 'Fahrzeug-Voraussetzungen',
            menu = 'ktjobs_mission_' .. missionId,
            options = vehicleOptions,
        })

        if mission.type == 'MTD' then
            local itemOptions = {
                {
                    title = 'Item hinzufügen',
                    icon = 'plus',
                    onSelect = function()
                        addMissionItem(missionId)
                    end,
                },
            }

            for index, item in ipairs(mission.items or {}) do
                local itemIndex = index
                itemOptions[#itemOptions + 1] = {
                    title = ('%s x%s'):format(item.name or '?', item.amount or 1),
                    icon = 'pen',
                    onSelect = function()
                        editMissionItem(missionId, itemIndex)
                    end,
                }
                itemOptions[#itemOptions + 1] = {
                    title = ('%s · Item %s entfernen'):format(item.name or '?', itemIndex),
                    icon = 'trash',
                    onSelect = function()
                        removeMissionItem(missionId, itemIndex)
                    end,
                }
            end

            lib.registerContext({
                id = 'ktjobs_items_' .. missionId,
                title = 'MTD-Items',
                menu = 'ktjobs_mission_' .. missionId,
                options = itemOptions,
            })
        end

        local options = {
            {
                title = 'Grunddaten bearbeiten',
                description = missionLabel(mission),
                icon = 'pen-to-square',
                onSelect = function()
                    editMissionBasics(missionId)
                end,
            },
            {
                title = 'Startpunkt setzen',
                description = formatCoords(mission.start),
                icon = 'location-dot',
                onSelect = function()
                    startPlacement(missionId, 'start')
                end,
            },
            {
                title = 'Zielpunkt setzen',
                description = formatCoords(mission.target),
                icon = 'flag-checkered',
                onSelect = function()
                    startPlacement(missionId, 'target')
                end,
            },
            {
                title = 'Strecke anzeigen',
                icon = 'route',
                onSelect = function()
                    showRoute(missionId)
                end,
            },
            {
                title = 'Belohnung',
                icon = 'coins',
                onSelect = function()
                    editReward(missionId)
                end,
            },
            {
                title = 'Fahrzeug-Voraussetzungen',
                icon = 'truck-medical',
                menu = 'ktjobs_vehicles_' .. missionId,
            },
            {
                title = 'Fahrzeug-Status prüfen',
                icon = 'circle-check',
                onSelect = function()
                    showVehicleStatus(missionId)
                end,
            },
            {
                title = 'Test-Auslösung',
                description = 'Sendet Einsatz sofort an EMD (ignoriert Cooldown)',
                icon = 'bell',
                onSelect = function()
                    testDispatchMission(missionId)
                end,
            },
            {
                title = 'Einsatz speichern',
                icon = 'floppy-disk',
                onSelect = function()
                    if saveMissions() then
                        registerMissionMenus()
                        lib.showContext('ktjobs_mission_' .. missionId)
                    end
                end,
            },
            {
                title = 'Einsatz löschen',
                icon = 'trash',
                onSelect = function()
                    deleteMission(missionId)
                end,
            },
        }

        if mission.type == 'KT' then
            table.insert(options, 6, {
                title = 'NPC-Modell',
                icon = 'user',
                onSelect = function()
                    editNpc(missionId)
                end,
            })
        end

        if mission.type == 'MTD' then
            table.insert(options, 7, {
                title = 'MTD-Items',
                icon = 'briefcase-medical',
                menu = 'ktjobs_items_' .. missionId,
            })
        end

        lib.registerContext({
            id = 'ktjobs_mission_' .. missionId,
            title = missionLabel(mission),
            menu = 'ktjobs_main',
            options = options,
        })
    end
end

local function openMainMenu()
    registerMissionMenus()

    local options = {}

    for _, mission in ipairs(State.missions) do
        options[#options + 1] = {
            title = missionLabel(mission),
            icon = mission.enabled and 'circle-check' or 'circle-xmark',
            menu = 'ktjobs_mission_' .. mission.id,
        }
    end

    options[#options + 1] = {
        title = 'Neuen Einsatz anlegen',
        icon = 'plus',
        onSelect = function()
            local mission = Utils.DefaultMission()
            if State.jobs[1] then
                mission.job = State.jobs[1].name
            end
            mission.stichwort = defaultStichwortForType(mission.type)
            if State.defaultNpcModel ~= '' then
                mission.npcModel = State.defaultNpcModel
            end
            State.missions[#State.missions + 1] = mission
            registerMissionMenus()
            lib.showContext('ktjobs_mission_' .. mission.id)
        end,
    }

    options[#options + 1] = {
        title = 'Alle speichern',
        icon = 'floppy-disk',
        onSelect = function()
            if saveMissions() then
                registerMissionMenus()
                lib.showContext('ktjobs_main')
            end
        end,
    }

    lib.registerContext({
        id = 'ktjobs_main',
        title = State.displayTitle .. ' · Konfigurator',
        options = options,
    })

    lib.showContext('ktjobs_main')
end

function OpenConfigurator()
    local data = lib.callback.await('ktjobs:getConfiguratorData', false)
    if not data then
        notify('Keine Berechtigung für den Einsatz-Konfigurator.', 'error')
        return
    end

    State.missions = data.missions or {}
    State.jobs = data.jobs or {}
    State.vehicleTypesByJob = data.vehicleTypesByJob or {}
    State.npcModels = data.npcModels or {}
    State.stichwortList = data.stichwortList or {}
    State.defaultStichwortByType = data.defaultStichwortByType or {}
    State.defaultIntervalMinutes = data.defaultIntervalMinutes or 15
    State.defaultNpcModel = data.defaultNpcModel or ''
    State.displayTitle = data.displayTitle or 'Krankentransport-Jobs'

    openMainMenu()
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    placementActive = false
    lib.hideTextUI()
end)
