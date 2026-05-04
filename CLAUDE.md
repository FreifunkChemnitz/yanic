# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Build:** `docker build -t yanic .` (empfohlen, da kein lokales Go nötig)  
oder: `go build -ldflags "-X github.com/FreifunkBremen/yanic/cmd.VERSION=$(git describe --tags)" -o yanic`

**Tests:** `go test -race ./...`  
**Einzelner Test:** `go test -v ./database/influxdb2/ -run TestConnect`  
**Lint:** `golangci-lint run --timeout=5m`

## Architektur

Yanic sammelt Mesh-Netzwerkstatistiken über das respondd-Protokoll (Multicast-UDP) und schreibt sie in konfigurierte Datenbanken und Ausgabeformate.

**Datenfluss:**
```
respondd UDP → respond/collector.go → runtime/nodes.go (In-Memory-Store)
                                            ↓                    ↓
                                     database/*           output/*
                                  (InsertNode etc.)       (Save)
```

### Plugin-System: Datenbanken (`database/`)

Interface `database.Connection` (`database/database.go`): `InsertNode`, `InsertLink`, `InsertGlobals`, `PruneNodes`, `Close`.

Jedes Backend registriert sich in seinem `init()` via `database.RegisterAdapter(name, connectFunc)`.  
`database/all/main.go` importiert alle Backends per Blank-Import; `database/all/connection.go` multiplext die Schreibzugriffe.

**Neues Backend hinzufügen:** Paket unter `database/newdb/` anlegen → Interface implementieren → in `init()` registrieren → Blank-Import in `database/all/main.go`.

### Plugin-System: Ausgaben (`output/`)

Interface `output.Output` (`output/output.go`): einzige Methode `Save(nodes *runtime.Nodes)`.  
Gleiche Registrierungslogik wie Datenbanken. Blank-Imports in `output/all/main.go`.

Filter (`output/filter/`) können in jedem Output-Abschnitt der Config gesetzt werden und werden vor `Save()` ausgewertet.

### Konfiguration

TOML-Datei (Beispiel: `config_example.toml`). Wichtige Abschnitte:
- `[respondd]` + `[[respondd.interfaces]]` — Collector-Einstellungen
- `[[nodes.output.*]]` — wiederholbar pro Ausgabetyp, optional mit `[filter]`-Unterabschnitt
- `[database.*]` — je Backend ein Abschnitt

### InfluxDB2-Hinweis

Der InfluxDB2-Go-Client unterstützt keine `int32`/`uint32`-Feldwerte. Alle Integer-Felder müssen in `database/influxdb2/node.go` explizit zu `int64` gecastet werden (gilt auch für neue Felder).
