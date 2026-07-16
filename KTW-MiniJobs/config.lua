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

-- Auswählbare NPC-Modelle im Konfigurator (Spawnname + Anzeigename)
Config.NpcModels = {
    { model = 'a_m_y_business_02', name = 'Marcus Thorn' },
    { model = 'a_f_y_business_01', name = 'Elena Frost' },
    { model = 'a_m_y_business_03', name = 'Jonas Greystone' },
    { model = 'a_f_y_business_02', name = 'Mira Ashford' },
    { model = 'a_m_m_business_01', name = 'Henrik Vale' },
    { model = 'a_f_m_business_02', name = 'Clara Windmere' },
    { model = 'a_m_y_genstreet_01', name = 'Kael River' },
    { model = 'a_f_y_genstreet_01', name = 'Lyra Stone' },
    { model = 'a_m_o_genstreet_01', name = 'Otto Flint' },
    { model = 'a_f_o_genstreet_01', name = 'Helena Dusk' },
    { model = 'a_m_y_vinewood_01', name = 'Finn Oaken' },
    { model = 'a_f_y_vinewood_01', name = 'Nora Silber' },
    { model = 'a_m_y_stbla_02', name = 'Tobias Ember' },
    { model = 'a_f_y_stbla_01', name = 'Sira Moonfall' },
    { model = 'u_m_y_proldriver_01', name = 'Rex Hollow' },
    { model = 'a_m_y_epsilon_01', name = 'Cedric Dawn' },
    { model = 'a_f_y_epsilon_01', name = 'Ava Nightshade' },
    { model = 'ig_old_man1', name = 'Eldric Grimwald' },
    { model = 'ig_old_man2', name = 'Bram Ironroot' },
    { model = 'ig_mrsphillips', name = 'Isolde Thornhill' },
}

-- EMD-Fahrzeugtypen-Tabelle (EmergencyDispatch Administration)
Config.EmdVehicleTypesTable = 'emd_vehicletypes'

-- Postleitzahl-Ressource: 'auto' | 'nearest-postal' | 'postals' | 'none'
Config.PostalResource = 'auto'

-- EmergencyDispatch Ressourcenname
Config.EmergencyDispatchResource = 'emergencydispatch'

-- EmergencyDispatch Event für neue Einsätze
Config.DispatchEvent = 'emergencydispatch:emergencycall:new'

-- Rettungsdienst-Stichworte für EMD-Einsatzmeldungen (Platzhalter: Ziel-PLZ, Strecke, Fahrzeit Min)
Config.DispatchStichworte = {
    patientenverlegung = 'Patientenverlegung – Abholung und Transport ins Ziel-KH (PLZ %s) | Strecke %s / ~%s Min',
    krankentransport = 'Krankentransport – planbarer Patiententransport (Ziel PLZ %s) | Strecke %s / ~%s Min',
    klinikfahrt = 'Klinikfahrt – Verlegung in weiterführendes Krankenhaus (Ziel PLZ %s) | Strecke %s / ~%s Min',
    nef_verlegung = 'NEF – Ärztliche Verlegung, Arzt zum Ziel-KH (PLZ %s) | Strecke %s / ~%s Min',
    ruecktransport = 'Rücktransport – Patient von KH in Versorgungsgebiet (Ziel PLZ %s) | Strecke %s / ~%s Min',
    mtd = 'Medizinischer Transport – Material/Equipment (Ziel PLZ %s) | Strecke %s / ~%s Min',
    dialyse = 'Dialysefahrt – planbarer Fahrdienst (Ziel PLZ %s) | Strecke %s / ~%s Min',
}

-- Auswahl im Konfigurator (id = Schlüssel in DispatchStichworte)
Config.DispatchStichwortList = {
    { id = 'patientenverlegung', label = 'Patientenverlegung' },
    { id = 'krankentransport', label = 'Krankentransport' },
    { id = 'klinikfahrt', label = 'Klinikfahrt / anderes KH' },
    { id = 'nef_verlegung', label = 'NEF / Ärztliche Verlegung' },
    { id = 'ruecktransport', label = 'Rücktransport' },
    { id = 'mtd', label = 'Medizinischer Transport (MTD)' },
    { id = 'dialyse', label = 'Dialysefahrt' },
}

-- Standard-Stichwort wenn im Einsatz nichts gewählt
Config.DefaultStichwortByType = {
    KT = 'krankentransport',
    MTD = 'patientenverlegung',
}

-- Fallback-Meldung
Config.PostalMessageTemplate = '%s (Ziel PLZ %s) | Strecke %s / ~%s Min'

-- Keine Framework-Notify bei EMD-Alarmierung (nur EmergencyDispatch)
Config.SuppressDispatchNotify = true

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
