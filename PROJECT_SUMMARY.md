# Project Summary

## Purpose and scope

PortGlance is a local-only macOS menu-bar app for showing connected USB,
Thunderbolt/USB4 and Bluetooth devices. It targets macOS 13 or newer and does
not contain telemetry, analytics, update checks or network client code.

The current product version is `0.2.1` (build 6). Releases are prepared from a
reviewed branch and integrated into protected `main` before tagging.
The product, executable, target, project and test target are named
`PortGlance`. The legacy app bundle identifier `de.r3d.menubarusb.tb` remains
unchanged so existing preferences and the login-item identity survive the
rebrand; the test bundle uses `de.r3d.portglance.tests`.

Public product language must credit the original MenuBarUSB idea and
MIT-licensed source without presenting PortGlance as an official successor to
MenuBarUSB, an official continuation of it or a version endorsed by its
original author. There is no collaboration or affiliation with the original
author, who is not involved in PortGlance development, maintenance, support or
releases. GitHub contributor entries for upstream author accounts reflect only
the preserved source history.

On 2026-08-31, the configurable menu-bar symbol section was removed as a
deliberate minimal-product change. The menu bar now always shows the fixed USB
symbol with its decimal external-device count and the native Bluetooth symbol
with its decimal connected-device count. The compact `99＋` cap and optional
Ethernet indicator remain. The corresponding modern and legacy settings,
stored preference keys, alternative numeral systems, tests and localization
strings were removed. The complete local verification and launch smoke test
passed; no new version or release was created.

The configurable list section was removed on the same date. Device names now
always use the larger type; vendor, connection details and the detected USB
connection speed remain visible whenever the underlying data is available. The
device list measures its rendered content and grows or shrinks when groups are
expanded or collapsed. It uses the available screen height before falling back
to scrolling without a forced indicator. The six obsolete list preferences and
the separate speed preference, including their context-menu paths, defaults,
tests and localization strings, were removed.

The System Information button is now always available in the device-list
footer, so its setting, stored preference, hide action and localization strings
were removed as well. All remaining settings are presented in one flat view
without category cards. The current menu uses the shared content-fitting scroll
container, while the legacy window keeps its supported controls in one plain
list. Obsolete category types, wrappers and localization strings were deleted;
the window-width control remains directly available. The complete local
verification and launch smoke test passed for this combined minimal-settings
change; no new version or release was created.

Appearance selection was simplified on 2026-08-31 as part of the same cleanup.
A single segmented `System / Light / Dark` preference now replaces the two
mutually exclusive force-mode checkboxes. This makes invalid combinations
unrepresentable and removes the related warning state, hover timer, animation
and dedicated warning color. A versioned local migration maps existing force
mode preferences to the new value, preserving the former light-mode priority
if both legacy flags were set.
The complete local verification and launch smoke test passed; no new version or
release was created.

The forced light appearance initially changed only SwiftUI's local color-scheme
environment, leaving the hosting `MenuBarExtra` material dark and producing
dark text on a dark background. A first `preferredColorScheme` correction was
also ignored by the menu-bar presentation and therefore did not fix the actual
window. The final implementation uses a narrow `NSViewRepresentable` bridge to
set the host `NSWindow.appearance` to Aqua, Dark Aqua or inherited system
appearance while keeping SwiftUI's semantic colors aligned. A focused AppKit
test exercises all three states on a real `NSWindow`.

The remaining boolean settings now use native trailing macOS switches instead
of low-contrast checkboxes. The app-specific Reduce Transparency preference,
its stored value, custom ultra-thick background and the additional regular
material overlay were removed. The `MenuBarExtra` host now owns the surface and
therefore follows the platform's current material, accessibility behavior and
newer system styling without a custom glass imitation. Migration version 4
removes this and every other preference retired by the minimal-settings changes,
including installations that had already recorded migration version 3 from a
development build.

A follow-up cleanup audit checked Swift declarations and references, source-file
inclusion, asset-catalog use, localization references, retired preference keys,
empty files and the complete build gate. No additional unreferenced production
type, view, resource or localization key was confirmed. The remaining macOS
13/14 legacy-settings window and the IOKit/AppKit callback paths are still live
compatibility code. The complete local verification and launch smoke test
passed; no new version or release was created.

The three remaining toggle rows were simplified after the audit. Their former
blue info buttons and expandable descriptions were replaced by complete,
action-oriented labels: open automatically at login, show MacBook charging
status in the device list and show a LAN icon for active wired connections.
The always-visible app-language explanation was also removed because the
`Automatic` picker value is self-explanatory. The shared disclosure state,
description arguments and the now-unused Info color asset and localization keys
were deleted. The complete local verification and launch smoke test passed; no
new version or release was created.

Version 0.2.1 collects these minimal-settings, appearance and cleanup changes
into one maintenance release. The device-discovery services, hardware
classification and privacy model are unchanged. The complete automated gate,
Universal build, local launch smoke test and user visual inspection passed.
It was published on 2026-08-31 as the signed, notarized and stapled Universal
release [`v0.2.1`](https://github.com/r3d42-git/PortGlance/releases/tag/v0.2.1)
from merge commit `22e7b542409fc024e5610ec4cc042d0315f939b8`. Apple accepted the
separately submitted app (`bbce9e54-529e-4de9-aa3c-1a80e01bd42e`) and DMG
(`5ce8ed88-2b8f-4f54-9c12-256ffa74dcbb`). The public asset
`PortGlance-0.2.1-mac.dmg` has SHA-256
`e52f4b0c47faf266af1f24e1627ada397e8b07f92ff283f90a7df6f0690659c0`; a
fresh GitHub download passed the independent release verification, including
the physically stapled app inside the mounted DMG.

The PortGlance rebrand was completed on 2026-08-30 and passed the complete
local verification plus launch smoke test. The canonical repository is
`r3d42-git/PortGlance`; `upstream` remains the read-only source reference to
`rafaelSwi/MenuBarUSB`. The rebrand was published as the signed, notarized and
stapled Universal release
[`v0.2.0`](https://github.com/r3d42-git/PortGlance/releases/tag/v0.2.0). Its
release asset is `PortGlance-0.2.0-mac.dmg` with SHA-256
`c79e5a61dca6e6a160df23a8a2361f29121ce71ae402e4ecae9a131a55847709`; the
publicly downloaded artifact passed the independent release verification.

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

Die aktuelle Produktversion ist `0.2.1` (Build 6). Releases werden auf einem
geprüften Branch vorbereitet und vor dem Tagging in den geschützten Branch
`main` integriert.
Produkt, Programmdatei, Target, Projekt und Test-Target heißen `PortGlance`.
Die bisherige App-Bundle-ID `de.r3d.menubarusb.tb` bleibt erhalten, damit
Einstellungen und Anmeldeobjekt-Identität die Umbenennung überstehen; das
Test-Bundle verwendet `de.r3d.portglance.tests`.

Die öffentliche Produktkommunikation muss die ursprüngliche MenuBarUSB-Idee
und den MIT-lizenzierten Ausgangscode nennen, ohne PortGlance als offiziellen
Nachfolger, offizielle Fortführung oder vom ursprünglichen Autor bestätigte
Variante darzustellen. Es bestehen weder Zusammenarbeit noch Zugehörigkeit zum
ursprünglichen Autor, der an Entwicklung, Pflege, Support und Releases von
PortGlance nicht beteiligt ist. GitHub-Contributor-Einträge der Upstream-Autoren
bilden ausschließlich die erhaltene Quellcodehistorie ab.

Am 31.08.2026 wurde der konfigurierbare Menüleisten-Symbolblock als bewusste
Minimalisierung vollständig entfernt. Die Menüleiste zeigt jetzt immer das
feste USB-Symbol mit der dezimalen Anzahl externer Geräte und das native
Bluetooth-Symbol mit der dezimalen Anzahl verbundener Geräte. Die kompakte
Begrenzung auf `99＋` und die optionale Ethernet-Anzeige bleiben erhalten. Die
zugehörigen modernen und klassischen Einstellungen, Speicherkeys, alternativen
Zahlensysteme, Tests und Übersetzungen wurden entfernt. Die vollständige lokale
Prüfung und der Starttest waren erfolgreich; es wurde keine neue Version und
kein Release erstellt.

Am selben Tag wurde auch der konfigurierbare Bereich „Liste“ entfernt.
Gerätenamen werden nun immer größer dargestellt; Hersteller, Verbindungsdetails
und die erkannte USB-Verbindungsgeschwindigkeit bleiben sichtbar, sofern die
jeweiligen Daten verfügbar sind. Die Geräteliste misst ihren tatsächlich
gerenderten Inhalt und wächst oder schrumpft beim Auf- und Zuklappen der Gruppen.
Sie nutzt zunächst die verfügbare Bildschirmhöhe und wird erst danach ohne
erzwungene Bildlaufleiste scrollbar. Die sechs überholten Listeneinstellungen
und die eigenständige Geschwindigkeitsoption samt Kontextmenüpfaden,
Standardwerten, Tests und Übersetzungen wurden entfernt.

Die Schaltfläche für die Systeminformationen ist jetzt immer in der Fußzeile
der Geräteliste verfügbar. Deshalb wurden auch ihre Einstellung, der
gespeicherte Wert, die Ausblenden-Aktion und die zugehörigen Übersetzungen
entfernt. Alle verbleibenden Einstellungen stehen ohne Kategorie-Karten in
einer flachen Ansicht. Das aktuelle Menü verwendet dafür den gemeinsamen,
inhaltsabhängig wachsenden Scroll-Container; das klassische Fenster führt seine
unterstützten Bedienelemente in einer einfachen Liste. Überholte Kategorie-
Typen, Wrapper und Übersetzungen wurden gelöscht; die Fensterbreite bleibt
direkt verfügbar. Die vollständige lokale Prüfung und der Starttest waren für
diese zusammengefasste Minimalisierung erfolgreich; es wurde keine neue Version
und kein Release erstellt.

Die Darstellungswahl wurde am 31.08.2026 im Zuge derselben Bereinigung
vereinfacht. Eine einzige segmentierte Auswahl `System / Hell / Dunkel` ersetzt
die zwei gegenseitig ausschließenden Erzwingen-Checkboxen. Ungültige
Kombinationen sind damit nicht mehr darstellbar; der zugehörige Warnzustand,
Hover-Timer, die Animation und die eigene Warnfarbe wurden entfernt. Eine
versionierte lokale Migration überführt vorhandene Erzwingen-Einstellungen in
den neuen Wert und erhält den bisherigen Vorrang des Hellmodus, falls beide
alten Werte gesetzt waren.
Die vollständige lokale Prüfung und der Starttest waren erfolgreich; es wurde
keine neue Version und kein Release erstellt.

Die erzwungene helle Darstellung änderte zunächst nur die lokale
SwiftUI-Farbschema-Umgebung. Das Material des beherbergenden `MenuBarExtra`
blieb dadurch dunkel und führte zu dunkler Schrift auf dunklem Hintergrund.
Auch ein erster Korrekturversuch mit `preferredColorScheme` wurde von der
Menüleisten-Präsentation ignoriert und reparierte das tatsächliche Fenster
nicht. Die endgültige Umsetzung setzt über eine schmale
`NSViewRepresentable`-Brücke die `NSWindow.appearance` des Hostfensters auf
Aqua, Dark Aqua oder die geerbte Systemdarstellung und hält zugleich die
semantischen SwiftUI-Farben synchron. Ein gezielter AppKit-Test prüft alle drei
Zustände an einem echten `NSWindow`.

Die verbleibenden booleschen Einstellungen verwenden nun native, rechts
ausgerichtete macOS-Schalter anstelle kontrastarmer Checkboxen. Die app-eigene
Option „Transparenz reduzieren“, ihr gespeicherter Wert, der benutzerdefinierte
ultradicke Hintergrund und der zusätzliche reguläre Materialüberzug wurden
entfernt. Damit besitzt wieder das `MenuBarExtra` selbst die Oberfläche und
folgt ohne nachgebauten Glaseffekt dem aktuellen Systemmaterial, den
Bedienungshilfen und der Gestaltung neuerer macOS-Versionen. Migration 4
entfernt den überholten Einstellungswert zusammen mit allen weiteren durch die
Minimalisierungen überholten Einstellungen, auch wenn ein Entwicklungsstand
zuvor bereits Migrationsversion 3 gespeichert hatte.

Ein anschließender Bereinigungs-Audit prüfte Swift-Deklarationen und Referenzen,
die Aufnahme aller Quelldateien, die Asset-Katalog-Nutzung,
Übersetzungsreferenzen, überholte Einstellungswerte, leere Dateien und die
vollständige Prüfkette. Es wurde kein weiterer unreferenzierter Produktionstyp,
keine View, Ressource oder Übersetzung bestätigt. Das klassische
Einstellungsfenster für macOS 13/14 sowie die IOKit-/AppKit-Callback-Pfade sind
weiterhin aktive Kompatibilitätslogik. Die vollständige lokale Prüfung und der
Starttest waren erfolgreich; es wurde keine neue Version und kein Release
erstellt.

Die drei verbliebenen Schalterzeilen wurden nach dem Audit weiter vereinfacht.
Ihre bisherigen blauen Info-Schaltflächen und aufklappbaren Beschreibungen
wurden durch vollständige, handlungsorientierte Bezeichnungen ersetzt: „Beim
Anmelden automatisch öffnen“, „MacBook-Ladestatus in der Geräteliste anzeigen“
und „LAN-Symbol bei aktiver Kabelverbindung anzeigen“. Auch der dauerhaft
sichtbare Erklärungssatz zur App-Sprache entfiel, weil die Auswahl
„Automatisch“ bereits eindeutig ist. Der gemeinsame Aufklappzustand, die
Beschreibungsparameter sowie das nun ungenutzte Info-Farbasset und die
zugehörigen Übersetzungsschlüssel wurden gelöscht. Die vollständige lokale
Prüfung und der Starttest waren erfolgreich; es wurde keine neue Version und
kein Release erstellt.

Version 0.2.1 fasst diese Minimalisierung der Einstellungen, die neue
Darstellungswahl und die Bereinigung in einem Wartungsrelease zusammen. Die
Dienste zur Geräteerkennung, die Hardwareklassifizierung und das
Datenschutzmodell bleiben unverändert. Die vollständige automatische
Prüfkette, der Universal-Build, der lokale Starttest und die Sichtprüfung des
Benutzers waren erfolgreich.
Der signierte, notarisierte und gestapelte Universal-Release wurde am
31.08.2026 als
[`v0.2.1`](https://github.com/r3d42-git/PortGlance/releases/tag/v0.2.1) aus
dem Merge-Commit `22e7b542409fc024e5610ec4cc042d0315f939b8` veröffentlicht. Apple
akzeptierte die getrennt eingereichte App
(`bbce9e54-529e-4de9-aa3c-1a80e01bd42e`) und das DMG
(`5ce8ed88-2b8f-4f54-9c12-256ffa74dcbb`). Das öffentliche Artefakt
`PortGlance-0.2.1-mac.dmg` hat den SHA-256
`e52f4b0c47faf266af1f24e1627ada397e8b07f92ff283f90a7df6f0690659c0`; ein
frischer GitHub-Download bestand die unabhängige Release-Prüfung einschließlich
der physisch gestapelten App im eingebundenen DMG.

Das PortGlance-Rebranding wurde am 30.08.2026 abgeschlossen und hat die
vollständige lokale Prüfkette sowie den Starttest bestanden. Das kanonische
Repository ist `r3d42-git/PortGlance`; `upstream` bleibt die schreibgeschützte
Quellreferenz auf `rafaelSwi/MenuBarUSB`. Das Rebranding wurde als signierter,
notarisierter und gestapelter Universal-Release
[`v0.2.0`](https://github.com/r3d42-git/PortGlance/releases/tag/v0.2.0)
veröffentlicht. Das Release-Artefakt `PortGlance-0.2.0-mac.dmg` hat den SHA-256
`c79e5a61dca6e6a160df23a8a2361f29121ce71ae402e4ecae9a131a55847709`; der
öffentlich heruntergeladene Stand bestand die unabhängige Release-Prüfung.

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
