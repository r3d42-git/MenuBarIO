# MenuBarIO verstehen

[Deutsch](index.html) · [English](en/index.html) · Codebasis: `ea9a6e183a2da11b9772aae63cfdfac5ca89852b` · 06.09.2026

Die sieben Diagramme erklären den tatsächlich gelesenen Code von MenuBarIO 0.7.1, Build 12. Ausgangspunkt war `PROJECT_SUMMARY.md`; Architekturbehauptungen wurden gegen Implementierung, vorhandene Tests und Release-Skripte geprüft. Dies ist eine Dokumentationsarbeit, kein neuer Hardwaretest und keine erneute Ausführung der App-Testreihe. Die vorgefundenen Änderungen an `.gitignore` und `PROJECT_SUMMARY.md` bleiben erhalten.

## Empfohlene Lesereihenfolge

| Diagramm | Erkenntnis | Zentrale Implementierung |
| --- | --- | --- |
| [01 · Systemarchitektur](01-system.html) | Drei Quellenfamilien speisen eine lokale SwiftUI-App. | [MenuBarIOApp](../../MenuBarIO/MenuBarIOApp.swift), [USBDeviceManager](../../MenuBarIO/Classes/USBDeviceManager.swift), [BluetoothDeviceManager](../../MenuBarIO/Classes/BluetoothDeviceManager.swift) |
| [02 · Physische Portzuordnung](02-ports.html) | Buchsenbelegung benötigt konkrete, eindeutige Topologiebelege. | [USBDeviceDiscovery](../../MenuBarIO/Services/USBDeviceDiscovery.swift), [USBPortAttachmentResolver](../../MenuBarIO/Structs/USBPortAttachmentResolver.swift) |
| [03 · Refresh-Sequenz](03-refresh.html) | Eine neuere Anfrage macht ältere Ergebnisse unveröffentlichbar. | [DeviceRefreshCoordinator](../../MenuBarIO/Classes/USBDeviceManager.swift), [HardwareRefreshCoordinator](../../MenuBarIO/Services/HardwareRefreshCoordinator.swift) |
| [04 · Quellenstatus](04-status.html) | Ein leeres Ergebnis und ein Erkennungsfehler haben verschiedene Bedeutungen. | [HardwareSourceStatus](../../MenuBarIO/Structs/HardwareSourceStatus.swift), beide Manager |
| [05 · Ausgaben und Datenschutz](05-outputs.html) | Gruppierung, technische Detailkopie und Übersichtsbericht haben verschiedene Aufgaben. | [USBDeviceGroups](../../MenuBarIO/Structs/USBDeviceGroups.swift), [DeviceDetailsBuilder](../../MenuBarIO/Support/DeviceDetailsBuilder.swift), [DiagnosticReportBuilder](../../MenuBarIO/Support/DiagnosticReportBuilder.swift) |
| [06 · Bluetooth-Batterie](06-battery.html) | Lokale HID-Daten haben Vorrang; BLE ist eine begrenzte Ergänzung. | [BluetoothBatteryReader](../../MenuBarIO/Services/BluetoothBatteryReader.swift), [BluetoothDeviceReader](../../MenuBarIO/Services/BluetoothDeviceReader.swift) |
| [07 · Auslieferung](07-release.html) | App und Installationsmedium brauchen jeweils ein eigenes angeheftetes Ticket. | [release.sh](../../script/release.sh), [publish_release.sh](../../script/publish_release.sh), [verify_release.sh](../../script/verify_release.sh) |

Alle Diagramme sind eigenständige HTML-Dateien mit eingebettetem SVG und Viewer. Sie benötigen keinen Server und laden für die Darstellung keine Bibliothek aus dem Netz. Die Startseiten verwenden lokale CSS-Vorschauen. Die `SRC`-Verweise in den Architekturdiagrammen führen auf den festgehaltenen GitHub-Commit; der Viewer prüft oder aktualisiert die Codebasis nicht beim Öffnen. Die sieben Diagramme liegen auf Deutsch und Englisch vor; ein Klick auf eine Diagrammkarte öffnet die jeweilige Datei in einem neuen Tab. Archify unterstützt für seine feste Bedienoberfläche nur Englisch und vereinfachtes Chinesisch, daher verwendet der deutsche Viewer dort den englischen Fallback.

Der Vite-Build der Projektwebsite veröffentlicht ausschließlich den kuratierten Atlas unter `/MenuBarIO/architecture/` und `/MenuBarIO/architecture/en/`: beide selbstgestylten Startseiten und die 14 Diagramme. `atlas.css` bleibt die gemeinsame Quellvorlage und wird beim Aktualisieren in beide Startseiten eingebettet. Spezifikationen, Prüfnachweise und lokale Sichtprüfdateien bleiben im Repository und werden nicht als Pages-Artefakte ausgeliefert. Der bestehende Projektverlauf verlinkt auf die passende Atlas-Sprache. Diese Änderung ist lokal vorbereitet; sie löst erst nach einer Veröffentlichung von `main` den Pages-Workflow aus.

## 1. Aufbau und Lebensdauer

`MenuBarIOApp.init()` führt zuerst `LegacyDataMigrator.runIfNeeded()` aus, registriert Standardwerte und erstellt zwei Manager sowie den übergreifenden Refresh-Koordinator als `StateObject`. In Tests werden die Hardwaremonitore nicht automatisch gestartet. `MenuBarExtra` verwendet eine Fensterdarstellung; `MenuBarRootView` wechselt zwischen Geräteliste und Einstellungen. Das separate Legacy-Einstellungsfenster bleibt für macOS 13/14 erhalten. Die Manager werden über EnvironmentObjects geteilt.

Die App besitzt keine Datenbank für Gerätehistorien. Gerätemodelle, Quellenstatus und BLE-Cache liegen im Arbeitsspeicher. UserDefaults speichern Einstellungen, Gruppenzustände und Migrationsstand. `LaunchAtLoginService` kapselt die Anmeldung beim System. `WindowAppearanceBridge` setzt gezielt die Erscheinung des AppKit-Hostfensters; die eigentliche Oberfläche bleibt SwiftUI.

Die Systemkarte fasst Adapter und konsumierende Views bewusst zusammen. Ihr „Backend“ bezeichnet lokale Swift-Logik im selben App-Prozess, keinen Netzwerkserver. Strom und Ethernet veröffentlichen ebenfalls im `USBDeviceManager`, haben aber unabhängige Quellen und Aktualisierungswege.

## 2. Von Registry-Einträgen zu einer physischen Topologie

`USBDeviceDiscovery.connectedTopology()` liest beide USB-Geräteklassen, entfernt doppelte IDs, entdeckt native Thunderbolt-Router, erzeugt Hostports und externe Portgruppen und führt USB- und Thunderbolt-Geräte zusammen. USB-Repräsentationen desselben nativen Thunderbolt-Geräts werden dabei herausgefiltert. `USBTopologySnapshot.isComplete` verknüpft die Vollständigkeit der USB- und Thunderbolt-Abfragen.

Die native Hostportbelegung nutzt Controller, Tiefe 1 und Hostportnummer. Besitzt ein Router nur einen Connector, existiert ein begrenzter Fallback auf denselben Controller und Tiefe 1. Erst danach werden direkte USB-Geräte zu freien Hostports ergänzt. Externe Router liefern Downstream-Connectoren und ihre DROM-`USB Port Map`.

Für direkte Host-USB-Zuordnung liest die Discovery ausschließlich `UsbCPortNumber` am **unmittelbaren IOService-Elternport**. Der Resolver verlangt einen zählbaren externen USB-Kandidaten ohne Hub-Elternteil, Billboard, Tunnel oder Thunderbolt-Eigentümer. Sowohl der Connector als auch der passende Kandidat müssen eindeutig sein. Ein Controller-ID-Wert oder eine USB-Location-ID allein genügt dafür nicht.

Für Dock-USB-Zuordnung müssen bereits eine bekannte Mac-seitige Bindung des Routers, ein Controller und ein DROM-Mapping vorliegen. Passende externe Hubs auf demselben Controller benötigen Tunnel- beziehungsweise Eigentümerevidenz. Erst die Verbindung von Hub-Elternteil, logischer USB-Hubportnummer und USB-2/USB-3-Companion-Mapping ergibt einen Kandidaten für die physische Dockbuchse. Eine native Thunderbolt-Belegung bleibt immer erhalten. Bei fehlenden Voraussetzungen oder mehreren Kandidaten bleiben die USB-Geräte in der Restliste.

„Frei“ bedeutet in solchen Fällen: im Modell keine nachgewiesene Datenbelegung. Die App kann bei unvollständiger Registry-Evidenz nicht beweisen, dass physisch kein Gerät in der Buchse steckt. Zudem kann eine unbelegte Datenbuchse als Ladeport angezeigt werden.

### Hub-Eigentümer sind eine andere Aussage

`USBDeviceGroups.makeHubGroups()` ordnet Hubs für die Anzeige einem Eigentümer zu. Diese Reihenfolge ist im Code implementiert; sie ist **kein zweiter Beweis für die physische Buchsenbelegung**:

| Priorität | Bedingung | Anzeige |
| --- | --- | --- |
| 1 | Hub ist intern | Dieser Mac |
| 2 | Explizite `thunderboltOwnerID` lässt sich auflösen | Der bekannte Thunderbolt-Eigentümer |
| 3 | Genau ein natives TB-Gerät; Hub ist getunnelt | Dieses TB-Gerät als abgeleiteter Eigentümer |
| 4 | Genau ein natives TB-Gerät; generischer Hub; gleiches Controllersegment und passende USB-Vendor-Evidenz | Begrenzter Intel/T2-Fallback auf dieses TB-Gerät |
| 5 | Passender Controller eines Hostports mit nativer TB-Belegung | Dessen TB-Gerät; USB-Belegungen dürfen das nicht übernehmen |
| 6 | Weiter ungelöste TB-Evidenz, Tunnel oder generischer Hub neben nativer TB-Topologie | Unbekannte Zuordnung |
| 7 | Übrige Fälle | Direkt angeschlossene USB-Hubs |

Die letzten beiden Gruppen sind Darstellungskategorien. Ein aufgelöster Hub-Eigentümer wird von `ConnectionPathResolver` nicht ungeprüft in einen physischen Pfad umgewandelt. Pfade verwenden bereits aufgelöste Host-/Dockportbelegungen und eindeutige USB-Elternketten. Fehlende Eltern, Mehrdeutigkeiten und Zyklen ergeben `nil` beziehungsweise die Anzeige „unbekannt“.

## 3. Identität, Gruppierung und Geschwindigkeiten

[USBDevice](../../MenuBarIO/Structs/USBDevice.swift) bildet USB-IDs bevorzugt aus Vendor, Produkt und Seriennummer. Fehlt eine Seriennummer, wird die Location-ID verwendet; ohne beide bleibt Vendor/Produkt als schwächerer Fallback. Serienlose Geräte können daher beim Umstecken eine andere Identität erhalten. „Stabil“ ist keine Garantie über jede physische Neuverbindung und jede mangelhafte Registry-Beschreibung hinweg.

Die externe USB-Zahl ist `usbDevices.count + portAttachedUSBDevices.count + thunderboltDevices.count`. Interne Geräte und Hubs sind ausgeschlossen. Portzuordnung ändert die Platzierung, nicht die einmalige Zählung. Die Gesamtzahl im Listenkopf addiert den eigenständigen Bluetooth-Zähler. In der Liste folgen Hostports, externe Ports, restliche USB-Geräte, Bluetooth, interne Geräte und USB-Hubs aufeinander; optionale Strominformationen stehen zusätzlich zur Verfügung.

`speedMbps` beschreibt die ausgehandelte Verbindung, `portMaxSpeedMbps` eine bekannte Portkapazität. Eine unbekannte Verbindungsgeschwindigkeit wird nicht durch das Portmaximum ersetzt. Ein USB-Gerät an einem TB5-fähigen Anschluss behält USB-Transport und USB-Companion-Kapazität. Die TB5-/USB4-v2-Angabe trennt 80 Gbps bidirektionale Kapazität von 120 Gbps asymmetrischem Bandwidth Boost.

## 4. Aktualisierung ohne alte Ergebnisse

Der übergreifende `HardwareRefreshCoordinator` bündelt Wake- und Session-Aktivierung mit 350 ms Verzögerung. Der manuelle Refresh führt sofort beide Manager aus und verwirft einen noch geplanten Lifecycle-Refresh. Der USB-Verbindungsmonitor hat einen direkten Weg zum USB-Manager. Bluetooth beobachtet Verbindungs-, Trennungs- und Controllerereignisse selbst.

`DeviceRefreshCoordinator` serialisiert USB-Topologieabfragen auf einer Utility-Queue. Jede Anfrage erhöht die Generation. Läuft bereits eine Abfrage, startet keine zweite parallel. Nach dem Abschluss einer veralteten Generation startet direkt die jüngste angeforderte Generation. Nur ein aktuelles und vollständiges Ergebnis ersetzt auf der Main Queue die veröffentlichten Modelle. Die Sequenz zeigt diesen Mechanismus an zwei beispielhaften Generationen; weitere Anfragen folgen derselben Regel.

Ein vollständiges, leeres Ergebnis ist `ready`. Ein Fehler nach einem Erfolg erhält die bisherigen Geräte und deren Erfolgszeitpunkt als `stale`. Ein erster Fehler ist `unavailable`. Bluetooth `poweredOff` hat Vorrang: Geräte und Batteriecache werden geleert und der konkrete Grund angezeigt. Diese Zustände gelten für USB/TB und Bluetooth; Ethernet und Strom verwenden eigene, einfachere Zustandsmodelle.

### Strom und Ethernet laufen zusätzlich

`PowerSourceMonitor` kombiniert IOPowerSources-Ereignisse mit einem 5-Sekunden-Timer. Ladezustand und Adapterleistung kommen aus lokalen Systeminformationen; `AppleSmartBatteryDiscovery` ergänzt elektrische Messwerte. `IntelT2PowerPortDiscovery` und `PowerPortResolver` ermitteln einen Ladeconnector nur bei einer passenden, eindeutigen Controller-/Vertragslage. Die UI zeigt Strombelegung nur, wenn der Datenport nicht bereits durch ein Gerät belegt ist. Aktuelle Ladeleistung und nominelle Netzteilleistung sind getrennte Werte.

`EthernetLinkMonitor` beobachtet lokale SystemConfiguration-Schlüssel. Der Reader prüft `Active` für Ethernet-Interfaces, keine Internet-Erreichbarkeit und keinen Datenverkehr. Die eigene Queue verwendet eine eigene Generation. Ein zunächst getrennter Link wird einmal nach 3,3 Sekunden erneut gelesen; überholte Ergebnisse und Ergebnisse nach dem Abschalten der Anzeige werden verworfen. Das Abschalten beendet den Monitor.

## 5. Bluetooth-Batterie und Datenweitergabe

Der Bluetooth-Gerätereaders liest gekoppelte Geräte, übernimmt in das Modell aber nur die verbundenen. Das ist keine Umgebungssuche. Die Batterieerweiterung verknüpft normalisierte vollständige Adressen mit einer eindeutigen UUID aus demselben Registry-Datensatz. Namensähnlichkeit ist keine Identität.

Ein eindeutiger gültiger HID-`BatteryPercent` wird bevorzugt. GATT wird nur versucht, wenn dieser Wert fehlt, die App bereits autorisiert ist, das Peripheral als verbunden abrufbar ist und eine passende Identität besitzt. Pro Peripheral gilt mindestens fünf Minuten Abstand. Gelesen werden ausschließlich Service `180F` und Characteristic `2A19`. Die App hält dafür eine eigene CoreBluetooth-Clientreferenz auf die bestehende Systemverbindung und gibt sie anschließend frei. Es gibt keinen Scan, kein Pairing und keine GATT-Schreiboperation. Ein einzelnes Byte von 0 bis 100 ist gültig. Timeout nach zehn Sekunden, Fehler und Disconnect bereinigen Werte; der RAM-Cache gilt maximal 15 Minuten. `onChange` bringt asynchrone Änderungen in die Gerätezeile. Die Komponentenkarte erläutert diesen Rückweg im unteren Hinweis, ohne eine lange Rückkante durch die übrigen Quellen zu ziehen.

Der Übersichtsbericht wählt Felder ausdrücklich aus: Version, Zeit, Betriebssystem, Mac-Modell, Gruppen, Messwerte und Status. Seriennummern, Bluetooth-Adressen, Location-IDs, stabile interne IDs und Benutzerpfade werden nicht als technische Felder exportiert. Frei vergebene Gerätenamen werden trotzdem ausgegeben; das ist keine allgemeine Anonymisierung beliebiger Benutzereingaben. Eine explizite USB-/Bluetooth-Detailkopie enthält dagegen bewusst technische Kennungen. Der native Save-Dialog gewährt Zugang zur gewählten Datei, ohne dauerhaftes Bookmark.

## 6. Was die Prüfung absichert

| Themenbereich | Vorhandene Testbelege im Checkout |
| --- | --- |
| Direkte USB-Ports und Dock-Mapping | [USBPortAttachmentResolverTests](../../MenuBarIOTests/USBPortAttachmentResolverTests.swift): eindeutige Sockets, USB2/USB3, Replug, native TB-Priorität, fehlende Hostbindung und Mehrdeutigkeit |
| Gruppen und Discovery | [USBDeviceTests](../../MenuBarIOTests/USBDeviceTests.swift), [USBDeviceDiscoveryTests](../../MenuBarIOTests/USBDeviceDiscoveryTests.swift): Identität, Klassifikation und Topologie |
| Refresh und Quellenstatus | [DeviceRefreshCoordinatorTests](../../MenuBarIOTests/DeviceRefreshCoordinatorTests.swift), [HardwareRefreshCoordinatorTests](../../MenuBarIOTests/HardwareRefreshCoordinatorTests.swift), [HardwareSourceStatusTests](../../MenuBarIOTests/HardwareSourceStatusTests.swift) |
| Pfad und Geschwindigkeiten | [ConnectionPathResolverTests](../../MenuBarIOTests/ConnectionPathResolverTests.swift): Dockpfad, Mehrdeutigkeit, Zyklen und USB-/TB-Kapazitätstrennung |
| Batteriedaten | [BluetoothBatteryTests](../../MenuBarIOTests/BluetoothBatteryTests.swift): Identitätsabgleich, Prozentvalidierung, Cacheablauf, asynchrone Anzeige und Power-Off |
| Datenweitergabe | [DiagnosticReportBuilderTests](../../MenuBarIOTests/DiagnosticReportBuilderTests.swift): Gruppenreihenfolge, ausgelassene Kennungen, bewusste Detailkennungen und Status |
| Nebenquellen | [EthernetLinkMonitoringTests](../../MenuBarIOTests/EthernetLinkMonitoringTests.swift), [PowerSourceMonitorTests](../../MenuBarIOTests/PowerSourceMonitorTests.swift), [PowerPortResolverTests](../../MenuBarIOTests/PowerPortResolverTests.swift) |

Diese Tests wurden für die Dokumentation gelesen, nicht erneut ausgeführt. Die früheren 106 erfolgreichen Tests und Hardwarebeobachtungen sind in `PROJECT_SUMMARY.md` als Release-Evidenz dokumentiert. Physische Intel-/USB2-/Replug-Prüfungen der direkten USB-Hostportänderung sowie macOS-13/14- und Clean-Mac-Abnahme sind nicht durch diesen Atlas nachgeprüft. Die automatisch überprüften Diagramme belegen Codeverständnis und Artefaktqualität, keine neue Hardwarekompatibilität.

## 7. Release und Website haben getrennte Grenzen

`script/verify.sh` prüft unter anderem Datenschutz, Lokalisierung, Formatierung, Tests, statische Analyse und ein Universal-Archiv einschließlich Lizenzmaterial. Der CI-Workflow führt das auf nativen Apple-Silicon- und Intel-Runnern aus. Die Release-Skripte bauen/signieren zusätzlich mit Developer ID, lassen zuerst die App notarieren und stapeln, erzeugen dann die gestaltete DMG und notarieren/stapeln diese separat. Der Containerprüfer kontrolliert auch das Ticket der eingeschlossenen App. `publish_release.sh` prüft den vorhandenen Tag, veröffentlicht die Assets und lädt sie für den erneuten Vergleich herunter.

`LICENSE`, `LICENSE.upstream`, `NOTICE` und `SOURCE.md` gehören zu App und DMG. Ab 0.7.0 gilt GPL-3.0-or-later, während die ursprüngliche MIT-Herkunft und historische Tags erhalten bleiben. Die eigenständige Projektwebsite unter `website/` läuft über Vite und einen eigenen Pages-Workflow. Sie ist weder Backend noch Update-Dienst der App. Das Release-Diagramm beschreibt die lokale Skriptpipeline; es ist keine Behauptung über heute live abgefragte GitHub- oder Apple-Zustände.

## Artefakte und Reproduktion

- `specs/`: die sieben bearbeitbaren Archify-JSON-Spezifikationen.
- `specs/en/`: aus den deutschen Spezifikationen erzeugte englische Varianten.
- `01-…07-*.html` und `en/01-…07-*.html`: die eigenständigen Diagramme in beiden Sprachen.
- `index.html`, `en/index.html` und `atlas.css`: zweisprachige Pages-Startseiten mit neuen Tabs für die Diagramme; die CSS-Vorlage wird in die beiden HTML-Dateien eingebettet.
- `tools/generate-english-specs.mjs`, `tools/inline-atlas-styles.mjs` und `tools/sanitize-pages-diagrams.mjs`: reproduzierbare Übersetzungsspezifikationen, eingebettete Startseiten-Styles und das Entfernen externer Font-Anfragen aus den gelieferten HTML-Dateien.
- `*.visual-check.json`, `*.visual-check.html`, `*.png`: Browsermessungen und Screenshots der jeweils gelieferten Bytes.
- `receipts/*-validation.json` und `*-delivery.json`: 9 Showcase-Prüfungen, Kompositionsdiagnostik, SHA-256 und Bytegröße je Spezifikation und HTML.
- `receipts/handoff.json`: zusammengefasste Übergabe mit separatem automatischem Browserstatus und bildgestützter Sichtprüfung.

Beispiel, ausgeführt aus dem Repositorywurzelverzeichnis mit dem vorhandenen persönlichen Archify-Skill:

```sh
node /Users/r3d/.codex/skills/archify/bin/archify.mjs validate architecture docs/architecture/specs/01-system.architecture.json --repo-root . --quality showcase --json
node /Users/r3d/.codex/skills/archify/bin/archify.mjs deliver architecture docs/architecture/specs/01-system.architecture.json docs/architecture/01-system.html --repo-root . --quality showcase --json
node docs/architecture/tools/generate-english-specs.mjs
node docs/architecture/tools/inline-atlas-styles.mjs
node docs/architecture/tools/sanitize-pages-diagrams.mjs
```

Für `workflow` und `sequence` wird `--repo-root` weggelassen; deren Codebelege stehen in diesem Begleittext. Architekturquellen sind zusätzlich durch Archify an den festen Commit gebunden. Bei einer späteren Codeänderung sind Aussagen, Quellrevision und Diagramme gemeinsam zu aktualisieren. Die Browserdatei kann unverändert direkt geöffnet werden; für eine lokale HTTP-Vorschau genügt `python3 -m http.server --bind 127.0.0.1 --directory docs/architecture`.

Bei der Erstellung wurden zu breite Workflow-Entwürfe für Batterie und Release verworfen und durch Komponenten-/Auslieferungskarten ersetzt. Der Zustandsentwurf wurde als Entscheidungspfad dargestellt, weil die ursprüngliche Lifecycle-Geometrie kollidierte. Diese verworfenen Entwürfe sind keine bestandenen Lieferartefakte. Im Sequenzdiagramm wurde eine redundante dritte Generation entfernt, damit die vollständige Erklärung auf den geprüften Desktopgrößen sichtbar bleibt.

### Abschließender Prüfstatus

Alle sieben finalen HTML-Dateien bestanden jeweils 9/9 Showcase-Prüfungen mit null Fehlern und Warnungen. Sechs bestanden zusätzlich `visual-check` in vier Desktopgrößen und mit Screenshots in beiden Farbschemata. Beim finalen Refresh-Diagramm brach die automatische Chrome-Prüfung mit einem Lade-Timeout ab. Auf Wunsch des Nutzers wurden weitere Chrome-Starts wegen Schlüsselbunddialogen eingestellt. Die integrierte Codex-Vorschau bestätigte für dieses Diagramm in Hell und Dunkel die vollständige Fenstercontainment bei 1440×900, 1600×1000, 1920×1080 und 2048×1320; eine vollständige dunkle Ansicht wurde bildgestützt geprüft. Der automatische Status bleibt ausdrücklich `failed`, die ergänzende Prüfung steht in `receipts/03-manual-browser.json`. Es wurde keine Schlüsselbundfreigabe erteilt.
