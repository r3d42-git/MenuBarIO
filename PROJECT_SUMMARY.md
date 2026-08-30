# Project Summary

## Purpose and scope

PortGlance is a local-only macOS menu-bar app for showing connected USB,
Thunderbolt/USB4 and Bluetooth devices. It targets macOS 13 or newer and does
not contain telemetry, analytics, update checks or network client code.

The current product version is `0.2.0` (build 5). Releases are prepared from a
reviewed branch and integrated into protected `main` before tagging.
The product, executable, target, project and test target are named
`PortGlance`. The legacy app bundle identifier `de.r3d.menubarusb.tb` remains
unchanged so existing preferences and the login-item identity survive the
rebrand; the test bundle uses `de.r3d.portglance.tests`.

The PortGlance rebrand was completed on 2026-08-30 and passed the complete
local verification plus launch smoke test. The canonical repository is
`r3d42-git/PortGlance`; `upstream` remains the read-only source reference to
`rafaelSwi/MenuBarUSB`. The rebrand did not create a version bump, tag or
release.

## Code structure

- `PortGlance/PortGlanceApp.swift` registers defaults, runs the one-time legacy
  migration and composes the app scenes.
- `PortGlance/Services/` contains system adapters and lifecycle code for IOKit
  discovery, connection notifications, power sources, Ethernet state,
  login-item state and legacy-data migration.
- `PortGlance/Structs/` and `PortGlance/Enums/` contain stable device models,
  grouping rules and preference types.
- `PortGlance/Support/` contains stateless formatting and system-action
  helpers.
- `PortGlance/Views/` contains small menu-bar, list, row and settings
  components. Current and legacy settings reuse the same controls.
- `PortGlanceTests/` mirrors the model, service and migration boundaries with
  focused test files.
- `branding/PortGlance-AppIcon-master.png` is the generated high-resolution
  icon master. `PortGlance/Assets.xcassets/AppIcon.appiconset/` contains the
  derived macOS icon sizes. In-app category and status icons use SF Symbols.

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
in `TESTING.md`. `./script/verify_release.sh VERSION DMG_PATH` validates the
final DMG plus the separately notarized and stapled enclosed app.

Release, signing, notarization, GitHub upload and publication are separate
steps governed by `RELEASE.md`; do not infer them from a code change.

---

# Projektübersicht

## Zweck und Umfang

PortGlance ist eine rein lokal arbeitende macOS-Menüleisten-App zur Anzeige
angeschlossener USB-, Thunderbolt-/USB4- und Bluetooth-Geräte. Sie unterstützt
macOS 13 oder neuer und enthält weder Telemetrie noch Analysen,
Update-Abfragen oder Netzwerk-Client-Code.

Die aktuelle Produktversion ist `0.2.0` (Build 5). Releases werden auf einem
geprüften Branch vorbereitet und vor dem Tagging in den geschützten Branch
`main` integriert.
Produkt, Programmdatei, Target, Projekt und Test-Target heißen `PortGlance`.
Die bisherige App-Bundle-ID `de.r3d.menubarusb.tb` bleibt erhalten, damit
Einstellungen und Anmeldeobjekt-Identität die Umbenennung überstehen; das
Test-Bundle verwendet `de.r3d.portglance.tests`.

Das PortGlance-Rebranding wurde am 30.08.2026 abgeschlossen und hat die
vollständige lokale Prüfkette sowie den Starttest bestanden. Das kanonische
Repository ist `r3d42-git/PortGlance`; `upstream` bleibt die schreibgeschützte
Quellreferenz auf `rafaelSwi/MenuBarUSB`. Durch das Rebranding wurden weder
Versionssprung noch Tag oder Release erstellt.

## Codestruktur

- `PortGlance/PortGlanceApp.swift` registriert Standardwerte, führt die
  einmalige Altdatenmigration aus und setzt die App-Szenen zusammen.
- `PortGlance/Services/` enthält Systemadapter und Lebenszykluscode für
  IOKit-Erkennung, Anschlussmeldungen, Stromquellen, Ethernet-Status,
  Anmeldeobjekt-Status und Altdatenmigration.
- `PortGlance/Structs/` und `PortGlance/Enums/` enthalten stabile
  Gerätemodelle, Gruppierungsregeln und Einstellungstypen.
- `PortGlance/Support/` enthält zustandslose Formatierungs- und
  Systemaktions-Helfer.
- `PortGlance/Views/` enthält kleine Menüleisten-, Listen-, Zeilen- und
  Einstellungskomponenten. Aktuelle und klassische Einstellungen verwenden
  dieselben Bedienelemente.
- `PortGlanceTests/` bildet die Modell-, Service- und Migrationsgrenzen in
  gezielten Testdateien ab.
- `branding/PortGlance-AppIcon-master.png` ist die hochauflösende generierte
  Icon-Vorlage. Die abgeleiteten macOS-Größen liegen in
  `PortGlance/Assets.xcassets/AppIcon.appiconset/`. Kategorien und Status in
  der App verwenden SF Symbols.

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
sind weiterhin in `TESTING.md` dokumentiert. Mit
`./script/verify_release.sh VERSION DMG_PATH` werden das finale DMG und die
getrennt notarisierte und gestapelte enthaltene App geprüft.

Release, Signierung, Notarisierung, GitHub-Upload und Veröffentlichung sind
getrennte Schritte nach `RELEASE.md`; sie sind nicht automatisch Teil einer
Codeänderung.
