# Project Summary

## Purpose and scope

MenuBarUSB-TB is a local-only macOS menu-bar app for showing connected USB,
Thunderbolt/USB4 and Bluetooth devices. It targets macOS 13 or newer and does
not contain telemetry, analytics, update checks or network client code.

The current product version is `0.1.4` (build 4). Releases are prepared from a
reviewed branch and integrated into protected `main` before tagging.

## Code structure

- `MenuBarUSB/MenuBarUSBApp.swift` registers defaults, runs the one-time legacy
  migration and composes the app scenes.
- `MenuBarUSB/Services/` contains system adapters and lifecycle code for IOKit
  discovery, connection notifications, power sources, Ethernet state,
  login-item state and legacy-data migration.
- `MenuBarUSB/Structs/` and `MenuBarUSB/Enums/` contain stable device models,
  grouping rules and preference types.
- `MenuBarUSB/Support/` contains stateless formatting and system-action
  helpers.
- `MenuBarUSB/Views/` contains small menu-bar, list, row and settings
  components. Current and legacy settings reuse the same controls.
- `MenuBarUSBTests/` mirrors the model, service and migration boundaries with
  focused test files.

USB and Thunderbolt identities must remain stable across refreshes. Internal
devices and USB hubs do not count toward the external USB-device total.
Bluetooth devices count separately. The visible group order is USB devices,
Bluetooth devices, internal devices, then USB hubs.

## Verification

Run the complete local gate before a commit:

```bash
./script/verify.sh
```

It audits privacy and localization, lints Swift formatting, runs XCTest and
the Xcode Static Analyzer, builds both `arm64` and `x86_64`, and verifies the
resulting Universal app. Use `./script/build_and_run.sh --verify` for a local
launch smoke test. Hardware-dependent USB/Thunderbolt cases remain documented
in `TESTING.md`.

Release, signing, notarization, GitHub upload and publication are separate
steps governed by `RELEASE.md`; do not infer them from a code change.

---

# Projektübersicht

## Zweck und Umfang

MenuBarUSB-TB ist eine rein lokal arbeitende macOS-Menüleisten-App zur Anzeige
angeschlossener USB-, Thunderbolt-/USB4- und Bluetooth-Geräte. Sie unterstützt
macOS 13 oder neuer und enthält weder Telemetrie noch Analysen,
Update-Abfragen oder Netzwerk-Client-Code.

Die aktuelle Produktversion ist `0.1.4` (Build 4). Releases werden auf einem
geprüften Branch vorbereitet und vor dem Tagging in den geschützten Branch
`main` integriert.

## Codestruktur

- `MenuBarUSB/MenuBarUSBApp.swift` registriert Standardwerte, führt die
  einmalige Altdatenmigration aus und setzt die App-Szenen zusammen.
- `MenuBarUSB/Services/` enthält Systemadapter und Lebenszykluscode für
  IOKit-Erkennung, Anschlussmeldungen, Stromquellen, Ethernet-Status,
  Anmeldeobjekt-Status und Altdatenmigration.
- `MenuBarUSB/Structs/` und `MenuBarUSB/Enums/` enthalten stabile
  Gerätemodelle, Gruppierungsregeln und Einstellungstypen.
- `MenuBarUSB/Support/` enthält zustandslose Formatierungs- und
  Systemaktions-Helfer.
- `MenuBarUSB/Views/` enthält kleine Menüleisten-, Listen-, Zeilen- und
  Einstellungskomponenten. Aktuelle und klassische Einstellungen verwenden
  dieselben Bedienelemente.
- `MenuBarUSBTests/` bildet die Modell-, Service- und Migrationsgrenzen in
  gezielten Testdateien ab.

USB- und Thunderbolt-Identitäten müssen über Aktualisierungen hinweg stabil
bleiben. Interne Geräte und USB-Hubs zählen nicht zum Zähler externer
USB-Geräte. Bluetooth-Geräte werden getrennt gezählt. Die sichtbare
Gruppenreihenfolge lautet USB-Geräte, Bluetooth-Geräte, interne Geräte und
USB-Hubs.

## Prüfung

Vor einem Commit die vollständige lokale Prüfkette ausführen:

```bash
./script/verify.sh
```

Sie prüft Datenschutz und Lokalisierung, kontrolliert die Swift-Formatierung,
führt XCTest und den Xcode Static Analyzer aus, baut `arm64` und `x86_64` und
verifiziert die erzeugte Universal-App. Für einen lokalen Starttest dient
`./script/build_and_run.sh --verify`. Hardwareabhängige USB-/Thunderbolt-Fälle
sind weiterhin in `TESTING.md` dokumentiert.

Release, Signierung, Notarisierung, GitHub-Upload und Veröffentlichung sind
getrennte Schritte nach `RELEASE.md`; sie sind nicht automatisch Teil einer
Codeänderung.
