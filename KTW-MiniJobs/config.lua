Config = {}

-- Framework: 'auto' | 'esx' | 'qb'
Config.Framework = 'auto'

-- Anzeigename in der UI
Config.DisplayTitle = 'Krankentransport-Jobs'

-- Befehl zum Öffnen des Einsatz-Konfigurators (ACE: ktjobs.admin)
Config.ConfiguratorCommand = 'ktjobs'

-- Intervall in Sekunden, in dem Fahrzeug-Voraussetzungen geprüft werden
Config.CheckInterval = 30

-- Cooldown pro Mission in Sekunden nach Auslösung
Config.MissionCooldown = 600

-- Maximale gleichzeitig aktive Einsätze (gesamt)
Config.MaxActiveMissions = 3

-- Abstand zum Startpunkt für Annahme (Meter)
Config.AcceptRadius = 25.0

-- Abstand zum Zielpunkt für Abschluss (Meter)
Config.CompleteRadius = 15.0

-- NPC-Modell-Fallback für KT (nur wenn im Einsatz leer)
Config.DefaultNpcModel = 'a_m_y_business_02'

-- EMD-Fahrzeugtypen-Tabelle (EmergencyDispatch Administration)
Config.EmdVehicleTypesTable = 'emd_vehicletypes'

-- Postleitzahl-Ressource: 'auto' | 'nearest-postal' | 'postals' | 'none'
Config.PostalResource = 'auto'

-- EmergencyDispatch Ressourcenname
Config.EmergencyDispatchResource = 'emergencydispatch'

-- EmergencyDispatch Event für neue Einsätze
Config.DispatchEvent = 'emergencydispatch:emergencycall:new'

-- Postleitzahl und Strecke in Dispatch-Text (Platzhalter: Text, Ziel-PLZ, Strecke, Fahrzeit)
Config.PostalMessageTemplate = '%s (Ziel PLZ %s) | Strecke %s / ~%s Min'

-- EMD: Blip auf der Karte bei Dispatch anzeigen
Config.DispatchShowBlip = true

-- Navigation über EMD-Funkgerät (keine eigenen Blips/Wegpunkte)
Config.UseEmdNavigation = true

-- Geschätzte Fahrgeschwindigkeit für Routenberechnung (km/h)
Config.RouteSpeedKmh = 60

-- Straßenfaktor für Server-Schätzung (Luftlinie × Faktor)
Config.RouteRoadFactor = 1.35

-- Gesellschaftskonto-Präfix (ESX: society_<job>)
Config.SocietyPrefix = 'society_'

-- Gesellschaftskonto-Ressource: 'auto' | 'esx_addonaccount' | 'qb-management' | 'qb-banking'
Config.SocietyResource = 'auto'

-- Datenbank: 'auto' | 'oxmysql' | 'mysql-async'
Config.Database = 'auto'

-- Tabellenname für Einsätze
Config.DatabaseTable = 'ktjobs_missions'

-- Framework-Jobs-Tabelle (ESX/QB: standardmäßig "jobs")
Config.JobsTable = 'jobs'

-- Berechtigungen für den Konfigurator (eine davon reicht)
Config.AdminAces = {
    'ktjobs.admin',
    'emergencydispatch.admin',
}

-- Zusätzlich Framework-Admins erlauben (ESX admin/superadmin, QB god/admin)
Config.AllowFrameworkAdmins = true

-- Taste zum Setzen von Start-/Zielpunkt im Konfigurator (38 = E)
Config.PlacementKey = 38
Config.PlacementKeyLabel = 'E'
Config.PlacementCancelKey = 322
