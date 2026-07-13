# ktjobs

FiveM-Ressource für automatische **MTD-** (Medizinischer Transport) und **KT-** (Krankentransport) Einsätze in ruhigen Zeiten.

## Voraussetzungen

- [EmergencyDispatch](https://loverp-scripts.de/) (LoveRP)
- ESX (`es_extended`) oder QB-Core (`qb-core`)
- Optional: `nearest-postal` oder `postals` für Ziel-Postleitzahlen

## Installation

1. Ordner `nm_ktjobs` in deinen `resources`-Ordner legen
2. In `server.cfg` eintragen (nach Framework und EmergencyDispatch):

```
ensure emergencydispatch
ensure nm_ktjobs
```

3. ACE-Berechtigung für den Konfigurator setzen:

```
add_ace group.admin ktjobs.admin allow
```

4. `config.lua` anpassen (Jobs, Intervalle)

## Nutzung

| Befehl | Beschreibung |
|--------|--------------|
| `/ktjobs` | Öffnet den In-Game Einsatz-Konfigurator (Admin) |

### Ablauf

1. Admin konfiguriert Einsätze im Konfigurator (Typ, Job, Koordinaten, Fahrzeug-Voraussetzungen, Belohnung)
2. Sind genügend besetzte Fahrzeuge (RTW/KTW) in EmergencyDispatch im Dienst, wird der Einsatz automatisch ausgelöst
3. Der Dispatch erscheint in **EmergencyDispatch** inkl. Ziel-Postleitzahl
4. Spieler mit passendem Job fahren zum Startpunkt und nehmen den Einsatz an (`E`)
5. Transport zum Ziel und Abschluss mit `E` (Abbruch mit `BACKSPACE`)

## Fahrzeugtypen

Nur **RTW** und **KTW** sind erlaubt. Die Besetzung wird über den EmergencyDispatch-Export `mannedvehicles` geprüft – Spieler müssen ihr Fahrzeug in EmergencyDispatch besetzt haben.

## Konfiguration

- **Jobs** (`Config.Jobs`): Auswahl im Konfigurator
- **Fahrzeugtypen** (`Config.AllowedVehicleTypes`): `RTW`, `KTW`
- **Postleitzahl** (`Config.PostalResource`): `auto`, `nearest-postal`, `postals` oder `none`

Einsätze werden in `data/missions.json` gespeichert.

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
