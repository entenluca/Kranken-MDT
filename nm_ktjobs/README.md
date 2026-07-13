# nm_ktjobs

FiveM-Ressource für automatische **MTD-** (Medizinischer Transport) und **KT-** (Krankentransport) Einsätze in ruhigen Zeiten.

## Voraussetzungen

- [EmergencyDispatch](https://loverp-scripts.de/) (LoveRP)
- ESX (`es_extended`) oder QB-Core (`qb-core`)
- Optional: `nearest-postal` oder `postals` für Ziel-Postleitzahlen

## Installation

1. Ordner `nm_ktjobs` in deinen `resources`-Ordner legen
2. In `server.cfg` eintragen (nach Framework und EmergencyDispatch):

```
ensure nm_ktjobs
```

3. ACE-Berechtigung für den Konfigurator setzen:

```
add_ace group.admin nm_ktjobs.admin allow
```

4. `config.lua` anpassen (Jobs, Fahrzeugtypen, Intervalle)

## Nutzung

| Befehl | Beschreibung |
|--------|--------------|
| `/ktjobs` | Öffnet den In-Game Einsatz-Konfigurator (Admin) |

### Ablauf

1. Admin konfiguriert Einsätze im Konfigurator (Typ, Job, Koordinaten, Fahrzeug-Voraussetzungen, Belohnung)
2. Sind genügend besetzte Fahrzeuge des konfigurierten Typs im Dienst, wird der Einsatz automatisch ausgelöst
3. Der Dispatch erscheint in **EmergencyDispatch** inkl. Ziel-Postleitzahl
4. Spieler mit passendem Job fahren zum Startpunkt und nehmen den Einsatz an (`E`)
5. Transport zum Ziel und Abschluss mit `E` (Abbruch mit `BACKSPACE`)

## Konfiguration

- **Fahrzeugtypen** (`Config.VehicleTypes`): Zuordnung z. B. RTW/NEF zu Spawn-Namen
- **Jobs** (`Config.Jobs`): Auswahl im Konfigurator
- **Postleitzahl** (`Config.PostalResource`): `auto`, `nearest-postal`, `postals` oder `none`

Einsätze werden in `data/missions.json` gespeichert.

## EmergencyDispatch

Einsätze werden per Event verschickt:

```lua
TriggerEvent('emergencydispatch:emergencycall:new', job, message, coords, false)
```

Die Meldung enthält den Dispatch-Text und die Ziel-PLZ (z. B. `Test MTD (PLZ 8041)`).
