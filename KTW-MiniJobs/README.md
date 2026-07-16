# KTW-MiniJobs

FiveM-Ressource für automatische **MTD-** (Medizinischer Transport) und **KT-** (Krankentransport) Einsätze in ruhigen Zeiten.

## Voraussetzungen

- [EmergencyDispatch](https://loverp-scripts.de/) (LoveRP)
- ESX (`es_extended`) oder QB-Core (`qb-core`)
- **oxmysql** (empfohlen) oder `mysql-async`
- Optional: `nearest-postal` oder `postals` für Ziel-Postleitzahlen

## Installation

1. Ordner `KTW-MiniJobs` in deinen `resources`-Ordner legen
2. In `server.cfg` eintragen (nach Framework, MySQL und EmergencyDispatch):

```
ensure oxmysql
ensure emergencydispatch
ensure KTW-MiniJobs
```

Die SQL-Tabelle wird beim Start **automatisch** angelegt (`sql/ktjobs.sql`). Ein manueller Import ist nicht nötig.

Bestehende Einsätze aus `data/missions.json` werden einmalig in die Datenbank übernommen, wenn die Tabelle noch leer ist.

3. Optional ACE-Berechtigung (falls kein Framework-Admin / kein EmergencyDispatch-Admin):

```
add_ace group.admin ktjobs.admin allow
```

Bereits berechtigt sind standardmäßig:
- `emergencydispatch.admin`
- ESX `admin` / `superadmin`
- QB `god` / `admin`

4. `config.lua` anpassen (Intervalle, Fahrzeugtypen)

## Nutzung

| Befehl | Beschreibung |
|--------|--------------|
| `/ktjobs` | Öffnet den In-Game Einsatz-Konfigurator (Admin) |

### Ablauf (über EmergencyDispatch)

1. Admin konfiguriert Einsätze im Konfigurator (Typ, Job, Start/Ziel, Fahrzeug-Voraussetzungen, optionale Belohnung)
2. Sind genügend **freie** besetzte Fahrzeuge (RTW/KTW, kein aktiver EMD-Einsatz) im Dienst, wird der Einsatz automatisch ausgelöst
3. Der Dispatch erscheint in **EmergencyDispatch** am **Startpunkt** inkl. Ziel-PLZ und berechneter Strecke/Fahrzeit
4. Die passenden Fahrzeuge werden **direkt zugewiesen** (kein offener Einsatz für alle)
5. Besatzung fährt über **EMD-Navigation** (Funkgerät: Einsatzort → Zielort) zum Start, bestätigt dort mit `E`
6. Transport zum Ziel und Abschluss mit `E` (Abbruch mit `BACKSPACE`)

## Belohnung

Pro Einsatz kann im Konfigurator aktiviert werden, ob eine Belohnung ausgezahlt wird. Der Betrag (Min/Max) wird bei Abschluss **auf das Geschäftskonto des eingestellten Jobs** gutgeschrieben (ESX: `esx_addonaccount`, QB: `qb-management` / `qb-banking`).

## Fahrzeugtypen

Fahrzeugtypen werden aus der **EMD-Tabelle `emd_vehicletypes`** geladen (Spalten `job`, `vehtype`). Im Konfigurator erscheinen nur die Typen des **gewählten Jobs**. Hat ein Job keine Einträge in EMD, können keine Fahrzeug-Voraussetzungen gesetzt werden.

Tabellenname in `config.lua` anpassbar:

```lua
Config.EmdVehicleTypesTable = 'emd_vehicletypes'
```

Die Besetzung wird über den EmergencyDispatch-Export `mannedvehicles` geprüft – Spieler müssen ihr Fahrzeug in EmergencyDispatch besetzt haben.

## Jobs

Alle Jobs im Konfigurator werden aus der **Framework-`jobs`-Tabelle** der Datenbank geladen (ESX/QB). Es werden alle Einträge aus dieser Tabelle angezeigt – keine separate Liste in der `config.lua`.

Tabellenname in `config.lua` anpassbar:

```lua
Config.JobsTable = 'jobs'
```

## Konfiguration

- **Fahrzeugtypen** (`Config.AllowedVehicleTypes`): `RTW`, `KTW`
- **Postleitzahl** (`Config.PostalResource`): `auto`, `nearest-postal`, `postals` oder `none`
- **EMD-Navigation** (`Config.UseEmdNavigation`): keine eigenen Blips/Wegpunkte, Navigation über EMD-Funkgerät
- **Routenberechnung** (`Config.RouteSpeedKmh`, `Config.RouteRoadFactor`): Fahrzeit-Schätzung im Dispatch-Text

Einsätze werden in der MySQL-Tabelle **`ktjobs_missions`** gespeichert.

## EmergencyDispatch

**Besetzte Fahrzeuge prüfen (Server):**

```lua
exports['emergencydispatch']:mannedvehicles()
-- type: Fahrzeugtyp (z. B. RTW, KTW), job: Job des Fahrzeugs, dispatch: 0 = frei
```

**Einsatz senden:**

```lua
TriggerEvent('emergencydispatch:emergencycall:new', job, message, coords, true)
```

Die Meldung enthält Dispatch-Text, Ziel-PLZ und Strecke (z. B. `Krankentransport (Ziel PLZ 8041) | Strecke 2.4 km / ~3 Min`).
