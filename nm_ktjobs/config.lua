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

-- Verfügbare Jobs im Konfigurator (Name = Framework-Job, Label = Anzeige)
Config.Jobs = {
    { name = 'ambulance', label = 'ambulance' },
    { name = 'fire', label = 'fire' },
}

-- Erlaubte Fahrzeugtypen (EmergencyDispatch mannedvehicles → type)
Config.AllowedVehicleTypes = {
    'RTW',
    'KTW',
}

-- Postleitzahl-Ressource: 'auto' | 'nearest-postal' | 'postals' | 'none'
Config.PostalResource = 'auto'

-- EmergencyDispatch Ressourcenname
Config.EmergencyDispatchResource = 'emergencydispatch'

-- EmergencyDispatch Event für neue Einsätze
Config.DispatchEvent = 'emergencydispatch:emergencycall:new'

-- Postleitzahl in Dispatch-Text einfügen
Config.PostalMessageTemplate = '%s (PLZ %s)'

-- Gesellschaftskonto-Präfix (ESX: society_<job>)
Config.SocietyPrefix = 'society_'

-- Gesellschaftskonto-Ressource: 'auto' | 'esx_addonaccount' | 'qb-management' | 'qb-banking'
Config.SocietyResource = 'auto'

-- Berechtigungen für den Konfigurator (eine davon reicht)
Config.AdminAces = {
    'ktjobs.admin',
    'emergencydispatch.admin',
}

-- Zusätzlich Framework-Admins erlauben (ESX admin/superadmin, QB god/admin)
Config.AllowFrameworkAdmins = true
