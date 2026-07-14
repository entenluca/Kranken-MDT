# Krankentransport-Jobs

FiveM-Ressource für automatische **MTD-** (Medizinischer Transport) und **KT-** (Krankentransport) Einsätze in ruhigen Zeiten.

## Voraussetzungen

- [EmergencyDispatch](https://loverp-scripts.de/) (LoveRP)
- ESX (`es_extended`) oder QB-Core (`qb-core`)
- **oxmysql** (empfohlen) oder `mysql-async`
- Optional: `nearest-postal` oder `postals` für Ziel-Postleitzahlen

## Installation

1. Ordner `nm_ktjobs` in deinen `resources`-Ordner legen
2. In `server.cfg` eintragen (nach Framework, MySQL und EmergencyDispatch):

```
ensure oxmysql
ensure emergencydispatch
ensure nm_ktjobs
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

4. `config.lua` anpassen (Jobs, Intervalle)

## Nutzung

| Befehl | Beschreibung |
|--------|--------------|
| `/ktjobs` | Öffnet den In-Game Einsatz-Konfigurator (Admin) |

### Ablauf

1. Admin konfiguriert Einsätze im Konfigurator (Typ, Job, Koordinaten, Fahrzeug-Voraussetzungen, optionale Belohnung)
2. Sind genügend besetzte Fahrzeuge (RTW/KTW) in EmergencyDispatch im Dienst, wird der Einsatz automatisch ausgelöst
3. Der Dispatch erscheint in **EmergencyDispatch** inkl. Ziel-Postleitzahl
4. Spieler mit passendem Job fahren zum Startpunkt und nehmen den Einsatz an (`E`)
5. Transport zum Ziel und Abschluss mit `E` (Abbruch mit `BACKSPACE`)

## Belohnung

Pro Einsatz kann im Konfigurator aktiviert werden, ob eine Belohnung ausgezahlt wird. Der Betrag (Min/Max) wird bei Abschluss **auf das Geschäftskonto des eingestellten Jobs** gutgeschrieben (ESX: `esx_addonaccount`, QB: `qb-management` / `qb-banking`).

## Fahrzeugtypen

Nur **RTW** und **KTW** sind erlaubt. Die Besetzung wird über den EmergencyDispatch-Export `mannedvehicles` geprüft – Spieler müssen ihr Fahrzeug in EmergencyDispatch besetzt haben.

## Konfiguration

- **Jobs** (`Config.Jobs`): Auswahl im Konfigurator
- **Fahrzeugtypen** (`Config.AllowedVehicleTypes`): `RTW`, `KTW`
- **Postleitzahl** (`Config.PostalResource`): `auto`, `nearest-postal`, `postals` oder `none`

Einsätze werden in der MySQL-Tabelle **`ktjobs_missions`** gespeichert.

## EmergencyDispatch

**Besetzte Fahrzeuge prüfen (Server):**

```lua
exports['emergencydispatch']:mannedvehicles()
-- type: Fahrzeugtyp (z. B. RTW, KTW), job: Job des Fahrzeugs
```

**Einsatz senden:**

```lua
TriggerEvent('emergencydispatch:emergencycall:new', job, message, coords, false)
```

Die Meldung enthält den Dispatch-Text und die Ziel-PLZ (z. B. `Krankentransport (PLZ 8041)`).
