# Testing

## Quick check before every commit

```bash
./script/verify.sh
```

The command uses an isolated DerivedData directory and runs:

- the deployment-target audit: every project, app and test configuration must
  declare macOS 13.0;
- the privacy audit: no telemetry, update checks or network client code;
- the localization audit for valid syntax, matching locale keys, duplicate keys
  and unused literal keys;
- the Swift formatter in lint mode for all app and test sources;
- the XCTest suite for device identity, device grouping, formatting, refresh
  coordination, migration and settings boundaries;
- the Xcode Static Analyzer for the Release configuration;
- a Release app containing both Apple-Silicon (`arm64`) and Intel (`x86_64`)
  slices; `lipo` verifies both slices in the resulting executable.

The unit tests intentionally run without a debug signature: they test pure
model and data logic, and the unsigned local test host avoids a Gatekeeper
dialog. This does not affect the signed and notarized product delivered to
users, which is verified separately by the release script.

The current Xcode toolchain reports that its bundled XCTest support libraries
were built for macOS 14 when the test bundle declares macOS 13. This toolchain
warning concerns only Apple's non-shipping test runtime. The application target
still builds for macOS 13, and runtime compatibility remains covered by the
separate macOS 13/14 smoke test below.

For an app-launch smoke test only:

```bash
./script/build_and_run.sh --verify
```

GitHub Actions runs the same checks natively on an Apple-Silicon runner and an
Intel runner for pull requests and every push to `main`. The local XCTest run
uses the architecture of the current Mac; it can be selected explicitly with
`MENUBARIO_TEST_ARCH=arm64` or `MENUBARIO_TEST_ARCH=x86_64` when that native
architecture is available.

## CI recovery

Never bypass `main` protection when a pull request has no checks. If GitHub
does not create them after a short wait, close and reopen the pull request to
issue a regular `pull_request` event again. The workflow also supports a
manual dispatch from the Actions page (or `gh workflow run ci.yml --ref
BRANCH`) as a non-administrative fallback. In either case, merge only after
both the `verify` and `verify-intel` checks have completed successfully for the
pull request commit.

## Hardware acceptance before a release

These cases require real hardware and cannot be meaningfully emulated in CI.
After every change to IOKit discovery, check them once:

1. Connect a normal USB device and at least one USB hub. A USB device assigned
   to a visible multi-protocol port must appear at that port; every remaining
   device appears under **Other USB Devices**. The hub remains under **USB
   Hubs**; the counter counts devices only.
2. Verify that built-in hubs appear below **This Mac** and USB hubs tunneled by
   a Thunderbolt/USB4 device appear below that device rather than below their
   chip vendor.
3. Connect a Thunderbolt/USB4 device (for example, an SSD enclosure). Its name,
   vendor, Thunderbolt/USB4 version and negotiated link speed must be visible
   below its physical port, but it must not also appear under **USB Devices**.
   The overall connected-device counter must still include it.
4. Expand **Thunderbolt/USB4 Ports**. Every physical host receptacle must appear
   once. Occupied ports show the attached device, actual protocol and negotiated
   speed; an empty port shows its maximum capability instead.
   Connect a USB2 device and a USB3 stick directly to each host socket on Apple
   Silicon and Intel. With an explicit `UsbCPortNumber`, each must occupy that
   socket with its USB rate, disappear from Other USB Devices and count once.
   Check the detail path, then unplug/move it and verify that the previous port
   clears. Native Thunderbolt/dock assignments must retain priority. If the
   socket property is absent, capture the immediate USB parent-port properties
   and Thunderbolt Socket IDs; do not infer a port from the controller byte.
5. Expand **External TB/USB4 Ports**. Every downstream Thunderbolt connector of
   a connected dock must appear once below that dock. Connect a native
   Thunderbolt device to one of them and verify that the port shows that device,
   its protocol and negotiated speed.
6. Connect USB devices to downstream multi-protocol ports whose Thunderbolt DROM
   provides a USB port map. Each device must appear once at the matching port
   with its actual USB protocol and negotiated speed, and disappear from
   **Other USB Devices**. USB-only sockets and every ambiguous or unsupported
   topology remain in **Other USB Devices** instead of receiving a guessed port.
7. Connect a Thunderbolt dock with a USB-C Billboard interface. The dock must
   appear once only as a Thunderbolt device, not additionally as a slow USB
   interface.
8. Connect two identical USB devices without serial numbers to different ports.
   Both must remain visible and retain separate settings.
9. Disconnect and reconnect each device. The list and group counter must
   react only once per physical device.
10. If the Ethernet indicator is enabled, turn its setting off and on twice. The
   cable icon may appear only when a wired link is active and must not initiate
   a network connection from the app.
11. For a release that changes device discovery, repeat the applicable cases
   1–10 on an Intel Mac. If the required Intel Mac or device is unavailable,
   record the approved exception in the release notes instead of claiming
   physical acceptance that was not performed.
12. On a MacBook with charging-status display enabled, connect a known power
   adapter while the battery is actively charging. The row should show battery
   percentage, live charging watts and adapter watts when macOS provides them.
   At full charge or during an intentional charging pause, it must not claim a
   live charging wattage. Missing measurements must disappear without hiding
   the remaining valid values.
13. With a USB device, a Thunderbolt dock and a Bluetooth device connected,
    use the footer refresh button. It must show a compact progress state, avoid
    overlapping work and update USB/Thunderbolt, Bluetooth, power and Ethernet
    together. Put the Mac to sleep and wake it again; the same refresh must run
    without restarting the app. Repeat the physical sleep/wake case on Apple
    Silicon and the supported Intel/T2 Mac.
14. Temporarily make one discovery source unavailable. The last successfully
    discovered devices must remain visible with a stale-data notice; a valid
    empty result must still show zero devices. Turning Bluetooth off must show
    the explicit Bluetooth-off notice rather than presenting the controller as
    a successful empty scan.
15. Export the Markdown report from the footer and confirm that the native save
    panel proposes a `.md` file. Open the saved file and compare its heading
    hierarchy with the visible order: host ports, external ports, other USB
    devices, Bluetooth devices, internal devices and USB hubs. Names, vendors,
    protocols, negotiated speeds, port maxima and unknown hub assignments must
    be clearly labelled, while serial numbers, Bluetooth addresses, location
    IDs, stable internal IDs, usernames and paths must be absent. Check the
    separate USB, Bluetooth and Thunderbolt-port context-menu copies as well.

### MenuBarIO 0.7.1 acceptance and release exception — 2026-09-05

The local gate passed 106 tests, static analysis and the Universal archive.
The exact sandboxed Debug build showed SanDisk Ultra USB 3.0 at Mac mini
Port 1 with 5 Gbps and its correct detail path. The residual USB count changed
from three to two, the total stayed ten, and D1 plus all three Anker downstream
assignments remained correct. Physical replug, USB2 and repeat Intel-MacBook
checks remain pending. The maintainer requested publication after these open
checks were stated; this is the approved 0.7.1 release exception. Automated
Intel checks, macOS 13/14 and a fresh clean-Mac installation are separate
acceptance boundaries.

### MenuBarIO 0.7.0 acceptance — 2026-09-05

The local 99-test gate, analyzer and Universal build passed. The sandboxed
Debug UI on the M4 Pro Mac mini showed Logi M650 L battery **45%**, device/port
navigation, the Anker Port 2 storage path, and separate TB5 80/120 Gbps fields.
Command-C, Command-R, Escape and a native Markdown save were checked. Battery
matching uses exact OS identifiers; no percentage is inferred from a name.

The user confirmed Apple Silicon hardware tests on 2026-09-05 and explicitly
authorized this release with physical Intel testing deferred. Later on the
same day the user confirmed that the physical Intel and MacBook tests had
also completed successfully. This closes the deferred Intel acceptance.
The cases below remain the regression checklist for future changes.
macOS 13/14 and other Bluetooth models were not newly observed by the agent.

Regression checklist:

- Disconnect/reconnect a selected device and swap the occupant of a selected
  port. The detail view must reflect the current snapshot, with stale status
  when discovery fails; a missing item must not remain presented as connected.
- Pull only the Ethernet cable from a still-connected dock or built-in Ethernet
  port. The indicator must follow the link without manual USB refresh. Repeat
  with the indicator disabled/re-enabled and after wake.
- On supported Bluetooth hardware check battery updates, zero/unknown values,
  disconnect/reconnect and permission-denied behavior. The currently connected
  Logi M650 L is physically verified; other hardware remains unverified.
- With macOS keyboard navigation enabled, reach device rows with Tab and open
  them with the native button action. Verify VoiceOver announces rows as detail
  buttons, expansion state and battery percentage, never as a Disconnect action.
- Check long names and all supported menu widths/languages, plus macOS 13/14
  and Intel runtime. Apple Silicon, Intel and MacBook hardware acceptance is
  maintainer-reported and complete for 0.7.0.

### Compatibility smoke tests

- On macOS 15 or newer, verify the integrated settings view, the menu-bar
  presentation, language switching, launch at login and device refresh.
- On macOS 13 or 14, verify the separate legacy settings window, the legacy
  menu-bar presentation, language switching, launch at login and device
  refresh. No control may look active when its function is unavailable.
- The declared deployment target and Universal slices are automated checks;
  these runtime smoke tests remain required because current SDK testing cannot
  emulate the complete menu-bar, login-item and physical-hardware behavior of
  an older macOS installation.

### Approved MenuBarIO 0.6.0 release exception — 2026-09-01

The complete automated gate passed with 76 tests, static analysis, the macOS 13
deployment-target audit and both Universal slices. The integrated settings view
and native Markdown save panel were checked on macOS 26. The macOS 13/14 legacy
settings smoke test and the new physical coordinated-refresh, sleep/wake and
failure-state cases on Apple Silicon and the supported Intel/T2 Mac were not
repeated for 0.6.0. Their absence was explicitly approved as a release exception
and is not presented as physical acceptance.

### Recorded M4 Pro Mac mini topology validation — 2026-08-31

- The three rear host receptacles appeared once each. Port 1 updated live from
  empty at up to 120 Gbps to TerraMaster TDAS at 40 Gbps; Port 2 showed
  TerraMaster D1 SSD Pro at 80 Gbps; Port 3 showed Anker Thunderbolt 4 Mini Dock
  at 40 Gbps.
- The two built-in Apple hub functions appeared below **This Mac**. The D1 USB
  hub functions appeared below **TerraMaster D1 SSD Pro**, and the Fresco Logic
  plus Intel functions appeared below **Anker Thunderbolt 4 Mini Dock**.
- The Anker dock exposed three downstream protocol connectors. A later physical
  check of its DROM USB port map assigned Maono Wireless Mic RX, ASM1352R-Fast
  and Loupedeck Live S to external Ports 1, 2 and 3 respectively. Each row
  showed the active USB protocol and negotiated speed. YubiKey remained under
  **Other USB Devices** because it was connected to the dock's front USB-A
  socket, whose port-map record intentionally has no Thunderbolt companion.
- The live connection change updated the device and port totals without an app
  restart. This Apple-silicon observation does not replace the Intel cases.

### Recorded Intel MacBook validation — 2026-08-26

The following physical checks were successfully observed on an Intel MacBook:

- Eight built-in USB peripherals appeared in **Internal Devices** and did not
  affect the menu-bar device count.
- One external USB 3 device and one connected Bluetooth mouse appeared in their
  respective groups; the menu-bar count was correctly **2**.
- Power supply through the Mac power adapter was detected and displayed
  correctly.

This record covers these observed cases only; it does not replace the remaining
Thunderbolt/USB4 acceptance cases above when a change affects that discovery.

### Recorded Intel MacBook topology follow-up — 2026-08-31

- The IOUSB tree exposed eight built-in functions directly below the virtual
  T2 host controller `AppleUSBVHCIBCE`, with no intervening class-9 USB hub.
  **USB Hubs: 0** is therefore correct for this model.
- Four physical Thunderbolt/USB4 host ports appeared. TerraMaster TDAS occupied
  Port 2 at 40 Gbps while the other three ports were free.
- The USB device, Thunderbolt device and connected Bluetooth device produced
  the expected overall device count of **3**. Internal functions remained
  excluded.
- The signed Universal test artifact reported an **87 W adapter** through a
  CalDigit TS3 Plus dock and a separate **100 W adapter** correctly. With the
  battery at 100%, live charging watts were correctly omitted; that measurement
  still requires a later observation while the battery is actively charging.
- Physical testing of the v6 port-assignment artifact passed on this Intel
  MacBook. A directly attached 100 W USB-C power adapter initially left its
  occupied host port labelled **Free** because it creates no data transport.
  Registry comparison while moving the adapter from visible Port 2 to Port 1
  showed the unique winning `PortControllerInfo` record move from position 0
  to 1. `BestAdapterIndex` remained 0 and must not be used as a port number.
  The four `AppleHPMDevice` records (`RID 0/1`, `Address 0/1`) and the root
  Thunderbolt routers' ordered `Socket ID` records provide the conservative
  bridge to MenuBarIO's existing visible port numbers. The resulting build
  must display an otherwise empty occupied row as **Port N · Power supply**
  with the adapter wattage, while leaving USB, native Thunderbolt and dock
  occupants unchanged. If any of those registry sources are incomplete or
  ambiguous, the app must decline the assignment. The signed and notarized
  Universal artifact for this physical check was
  `PortGlance-Power-Port-Test-2026-08-31-v7.zip`, SHA-256
  `f0e33d36da497c7cce5aa04b402da601f469d454990d9ff319a755f52355decf`.
  The app re-extracted from that exact ZIP passed strict signature, physical
  ticket, Gatekeeper and both-architecture verification. Physical testing then
  confirmed the 100 W adapter on Ports 1, 2, 3 and 4 and cleared the former
  assignment after each move. TS3 Plus and TDAS continued to occupy their data
  rows while supplying power, confirming the intended precedence.
- At 86% with charging active, the public IOPowerSources description still did
  not produce live watts. The captured `AppleSmartBattery` properties exposed
  a positive instantaneous current and battery voltage instead. The v8 build
  therefore uses `InstantAmperage` plus `Voltage` only when the preferred public
  calculation is unavailable; it uses averaged `Amperage` only when the
  instantaneous field is absent and rejects zero, negative or incomplete
  values. The physical artifact was
  `PortGlance-Charging-Power-Test-2026-08-31-v8.zip`, SHA-256
  `83b05e6580c33705067a7b6c6758b638c98a97c17a96600666b2caff5625048a`.
  Its freshly re-extracted app passed strict signature, physical ticket,
  Gatekeeper and both-architecture verification. Testing that exact artifact
  showed **Charging at 10 W · 100 W adapter** at 79% and **Charging at 41 W ·
  100 W adapter** at 80%, with the power-only connection still on Port 2. The
  changing value confirms the live five-second refresh rather than a static
  adapter-capacity display.
- The CalDigit dock, one free downstream Thunderbolt port, five USB functions
  and two USB hub functions were detected. The first test artifact showed the
  hubs under **Directly Connected USB Hubs**; v2 and v3 produced the same
  result, while v3 retained correct ownership on the M4 Pro Mac mini. The final
  v4 test resolves a tunneled hub against the native Thunderbolt-device list
  even when Intel macOS does not attach that device to a host port. A generic
  unresolved hub is inferred only when exactly one native Thunderbolt device
  exists and a same-controller USB sibling has the matching vendor. Physical
  v4 testing assigned the 480 Mbps hub to the CalDigit device; the generic
  12 Mbps hub remained direct because macOS exposed no matching evidence.
  Physical v5 testing confirmed that the second entry appears under **USB Hubs
  with Unknown Assignment**, while the 480 Mbps hub remains below the CalDigit
  device. Named direct hubs, generic hubs without native Thunderbolt topology,
  internal hubs and already resolved Thunderbolt hubs retain their existing
  groups.

For signed distribution, then follow the complete instructions in
[`RELEASE.md`](RELEASE.md).

## DMG layout acceptance

After changing the packaging process, open the generated DMG in Finder. It
must show a compact installation view with the app, arrow and **Programme**
alias. The app must be draggable to **Programme**; `LICENSE` must remain
present. The release script also automatically checks the alias, background and
license in the freshly mounted DMG.

---

# Tests

## Schnellprüfung vor jedem Commit

```bash
./script/verify.sh
```

Der Befehl verwendet ein isoliertes DerivedData-Verzeichnis und führt aus:

- die Deployment-Target-Prüfung: jede Projekt-, App- und Testkonfiguration muss
  macOS 13.0 deklarieren;
- die Datenschutzprüfung: keine Telemetrie, Update-Abfragen oder
  Netzwerk-Client-Code;
- die Lokalisierungsprüfung auf gültige Syntax, identische Schlüssel je
  Sprache, Duplikate und ungenutzte literale Schlüssel;
- den Swift-Formatter im Prüfmodus für alle App- und Testquellen;
- die XCTest-Tests für Geräteidentität, Gerätegruppierung, Formatierung,
  Aktualisierungskoordination, Migration und Einstellungsgrenzen;
- den Xcode Static Analyzer für die Release-Konfiguration;
- eine Release-App mit Apple-Silicon- (`arm64`) und Intel-Slice (`x86_64`);
  `lipo` prüft beide Slices in der erzeugten ausführbaren Datei.

Die Unit-Tests laufen bewusst ohne Debug-Signatur: Sie prüfen reine
Modell- und Datenlogik, und der unsignierte lokale Test-Host vermeidet einen
Gatekeeper-Dialog. Das signierte, notarisiert ausgelieferte Produkt wird davon
nicht berührt und wird im Release-Skript separat geprüft.

Die aktuelle Xcode-Toolchain weist darauf hin, dass ihre mitgelieferten
XCTest-Unterstützungsbibliotheken für macOS 14 gebaut wurden, obwohl das
Test-Bundle macOS 13 deklariert. Diese Toolchain-Warnung betrifft nur Apples
nicht ausgelieferte Testlaufzeit. Das App-Target wird weiterhin für macOS 13
gebaut; die Laufzeitkompatibilität deckt zusätzlich der separate
macOS-13-/14-Starttest weiter unten ab.

Zum reinen Starttest der App:

```bash
./script/build_and_run.sh --verify
```

GitHub Actions führt dieselben Prüfungen bei Pull Requests und jedem Push auf
`main` nativ auf einem Apple-Silicon- und einem Intel-Runner aus. Die lokalen
XCTest-Tests verwenden die Architektur des aktuellen Macs; sie kann mit
`MENUBARIO_TEST_ARCH=arm64` beziehungsweise `MENUBARIO_TEST_ARCH=x86_64`
ausdrücklich gewählt werden, wenn diese Architektur nativ verfügbar ist.

## CI-Wiederherstellung

Den Schutz von `main` niemals umgehen, wenn für einen Pull Request keine
Checks erscheinen. Falls GitHub sie nach kurzer Wartezeit nicht anlegt, den
Pull Request schließen und wieder öffnen, damit erneut ein reguläres
`pull_request`-Ereignis ausgelöst wird. Der Workflow unterstützt zusätzlich
einen manuellen Start über die Actions-Seite (oder `gh workflow run ci.yml
--ref BRANCH`) als nicht-administrativen Fallback. In beiden Fällen erst
mergen, wenn die Checks `verify` und `verify-intel` für den Pull-Request-Commit
erfolgreich abgeschlossen sind.

## Hardware-Abnahme vor einem Release

Diese Fälle benötigen echte Hardware und können nicht sinnvoll in CI emuliert
werden. Nach jeder Änderung an der IOKit-Erkennung einmal prüfen:

1. Ein normales USB-Gerät und mindestens einen USB-Hub anschließen. Ein sicher
   zugeordneter USB-Teilnehmer muss an seinem sichtbaren Mehrprotokoll-Port
   erscheinen; alle übrigen Geräte stehen unter **Weitere USB-Geräte**. Der Hub
   bleibt unter **USB-Hubs**; der Zähler zählt nur Geräte.
2. Prüfen, dass integrierte Hubs unter **Dieser Mac** und über ein
   Thunderbolt-/USB4-Gerät getunnelte USB-Hubs unter diesem Gerät statt unter
   ihrem Chip-Hersteller erscheinen.
3. Ein Thunderbolt-/USB4-Gerät (beispielsweise ein SSD-Gehäuse) anschließen.
   Name, Anbieter, Thunderbolt-/USB4-Version und die ausgehandelte
   Link-Geschwindigkeit müssen unter seinem physischen Port sichtbar sein; das
   Gerät darf nicht zusätzlich unter **USB-Geräte** erscheinen. Der
   Gesamtzähler der verbundenen Geräte muss es weiterhin mitzählen.
4. **Thunderbolt-/USB4-Ports** aufklappen. Jeder physische Host-Anschluss muss
   genau einmal erscheinen. Belegte Ports zeigen Gerät, tatsächliches Protokoll
   und ausgehandelte Geschwindigkeit; ein freier Port stattdessen seine
   maximale Fähigkeit.
   Auf Apple Silicon und Intel ein USB2-Gerät und einen USB3-Stick direkt an
   jedem Hostanschluss prüfen. Bei expliziter `UsbCPortNumber` muss das Gerät
   dort mit seiner USB-Rate erscheinen, aus **Weitere USB-Geräte** verschwinden
   und genau einmal zählen. Detailpfad kontrollieren, dann ab-/umstecken: Die
   alte Portbelegung muss verschwinden. Native Thunderbolt-/Dock-Belegungen
   behalten Vorrang. Fehlt die Portangabe, die unmittelbaren USB-Elternport-
   Eigenschaften und Thunderbolt-Socket-IDs erfassen; keine Portnummer aus dem
   Controllerbyte ableiten.
5. **Externe TB-/USB4-Ports** aufklappen. Jeder nachgelagerte
   Thunderbolt-Anschluss eines verbundenen Docks muss genau einmal unter diesem
   Dock erscheinen. Ein natives Thunderbolt-Gerät anschließen und prüfen, dass
   der Port Gerät, Protokoll und ausgehandelte Geschwindigkeit anzeigt.
6. USB-Geräte an nachgelagerte Mehrprotokoll-Ports anschließen, deren
   Thunderbolt-DROM eine USB-Port-Map bereitstellt. Jedes Gerät muss genau
   einmal am passenden Port mit tatsächlichem USB-Protokoll und ausgehandelter
   Geschwindigkeit erscheinen und aus **Weitere USB-Geräte** verschwinden.
   Reine USB-Buchsen sowie jede mehrdeutige oder nicht unterstützte Topologie
   bleiben dort, statt einem geratenen Port zugeordnet zu werden.
7. Ein Thunderbolt-Dock mit USB-C-Billboard-Interface anschließen. Das Dock
   darf nur einmal als Thunderbolt-Gerät erscheinen, nicht zusätzlich als
   langsames USB-Interface.
8. Zwei baugleiche USB-Geräte ohne Seriennummer an unterschiedliche Ports
   anschließen. Beide müssen sichtbar bleiben und getrennte Einstellungen
   behalten.
9. Geräte jeweils ab- und wieder anstecken. Liste und Gruppenzähler dürfen pro
   physischem Gerät nur einmal reagieren.
10. Falls die Ethernet-Anzeige aktiviert ist: Einstellung zweimal ein- und
   ausschalten. Das Kabelsymbol darf nur bei aktivem kabelgebundenem Link
   erscheinen und darf keine Netzwerkverbindung der App auslösen.
11. Bei einem Release mit Änderungen an der Geräteerkennung die zutreffenden
   Fälle 1–10 auf einem Intel-Mac wiederholen. Falls der benötigte Intel-Mac oder
   ein Gerät nicht verfügbar ist, die genehmigte Ausnahme in den Release Notes
   dokumentieren, statt eine nicht durchgeführte physische Abnahme zu
   behaupten.
12. Auf einem MacBook mit aktivierter Ladestatusanzeige bei aktiv ladendem Akku
   ein bekanntes Netzteil anschließen. Die Zeile soll Akkustand, aktuelle
   Ladeleistung und Netzteilleistung zeigen, sofern macOS die Werte liefert. Bei
   vollem Akku oder einer beabsichtigten Ladepause darf keine aktuelle
   Ladeleistung behauptet werden. Fehlende Messwerte müssen verschwinden, ohne
   die übrigen gültigen Angaben auszublenden.
13. Bei angeschlossenem USB-Gerät, Thunderbolt-Dock und Bluetooth-Gerät den
    Aktualisieren-Button in der Fußzeile verwenden. Er muss einen kompakten
    Aktivitätszustand zeigen, überlappende Arbeit vermeiden und
    USB/Thunderbolt, Bluetooth, Stromversorgung und Ethernet gemeinsam
    aktualisieren. Den Mac anschließend in den Ruhezustand versetzen und wieder
    aufwecken; dieselbe Aktualisierung muss ohne App-Neustart erfolgen. Diesen
    physischen Sleep/Wake-Fall auf Apple Silicon und dem unterstützten
    Intel-/T2-Mac wiederholen.
14. Eine Erkennungsquelle vorübergehend nicht verfügbar machen. Die zuletzt
    erfolgreich erkannten Geräte müssen mit einem Hinweis auf möglicherweise
    veraltete Daten sichtbar bleiben; ein gültiges leeres Ergebnis zeigt
    weiterhin null Geräte. Wird Bluetooth ausgeschaltet, muss der ausdrückliche
    Bluetooth-aus-Hinweis statt eines erfolgreichen leeren Scans erscheinen.
15. Den Markdown-Bericht aus der Fußzeile exportieren und prüfen, dass der
    native Speicherdialog eine `.md`-Datei vorschlägt. Die gespeicherte Datei
    öffnen und ihre Überschriftenhierarchie mit der sichtbaren Reihenfolge
    vergleichen: Hostports, externe Ports, weitere USB-Geräte,
    Bluetooth-Geräte, interne Geräte und USB-Hubs. Namen, Anbieter, Protokolle,
    ausgehandelte Geschwindigkeiten, Port-Maxima und unbekannte Hub-Zuordnungen
    müssen klar beschriftet sein; Seriennummern, Bluetooth-Adressen,
    Location-IDs, stabile interne IDs, Benutzernamen und Pfade dürfen nicht
    enthalten sein. Zusätzlich die getrennten Kontextmenü-Kopien für USB,
    Bluetooth und Thunderbolt-Ports prüfen.

### Abnahme und Release-Ausnahme für MenuBarIO 0.7.1 — 05.09.2026

Die lokale Prüfkette bestand 106 Tests, statische Analyse und Universal-Archiv.
Der exakte sandboxed Debug-Build zeigte SanDisk Ultra USB 3.0 an Mac-mini-Port 1
mit 5 Gbit/s und korrektem Detailpfad. Der USB-Restzähler sank von drei auf zwei,
der Gesamtzähler blieb zehn; D1 und alle drei Anker-Portzuordnungen blieben
korrekt. Physisches Umstecken, USB2 und die erneute Intel-MacBook-Prüfung stehen
noch aus. Nach Nennung dieser offenen Prüfungen hat der Maintainer die
Veröffentlichung freigegeben; dies ist die genehmigte Release-Ausnahme für
0.7.1. Automatische Intel-Prüfungen, macOS 13/14 und eine Neuinstallation auf
einem frischen Mac bleiben getrennte Abnahmegrenzen.

### Abnahme von MenuBarIO 0.7.0 — 05.09.2026

99 lokale Tests, statische Analyse und Universal-Build sind erfolgreich.
Im sandboxed Debug-Build wurden Logi M650 L mit 45 %, Gerätedetails,
Anker-Verbindungsweg, TB5-80/120-Gbit/s-Erklärung, ⌘C/⌘R/Esc und nativer
Markdown-Export geprüft. Der Benutzer hat die Apple-Silicon-Tests am 05.09.2026
bestätigt und den Release zunächst vor der physischen Intel-Abnahme
ausdrücklich freigegeben. Im Anschluss hat er am selben Tag auch die Intel-
und MacBook-Tests als erfolgreich bestätigt. Damit ist die zurückgestellte
Intel-Abnahme abgeschlossen. Die obige Prüfliste gilt für künftige Änderungen;
zusätzliche Bluetooth-Modelle sowie macOS 13/14 bleiben
außerhalb der neu beobachteten Abnahme. Mit aktivierter
macOS-Tastaturnavigation zusätzlich Tab und die native Tastenaktivierung der
Gerätezeilen sowie VoiceOver kontrollieren. Die vollständigen neuen Fälle
stehen oben unter „MenuBarIO 0.7.0 acceptance“.

### Kompatibilitäts-Starttests

- Unter macOS 15 oder neuer die integrierte Einstellungsansicht, die
  Menüleistendarstellung, Sprachumschaltung, Start bei Anmeldung und
  Geräteaktualisierung prüfen.
- Unter macOS 13 oder 14 das separate klassische Einstellungsfenster, die
  ältere Menüleistendarstellung, Sprachumschaltung, Start bei Anmeldung und
  Geräteaktualisierung prüfen. Kein Bedienelement darf aktiv wirken, wenn
  seine Funktion nicht verfügbar ist.
- Das deklarierte Deployment Target und die Universal-Slices werden
  automatisiert geprüft. Die Laufzeit-Starttests bleiben nötig, weil das
  aktuelle SDK das vollständige Verhalten von Menüleiste, Anmeldeobjekt und
  physischer Hardware unter einer älteren macOS-Installation nicht emuliert.

### Genehmigte Release-Ausnahme für MenuBarIO 0.6.0 — 01.09.2026

Die vollständige automatische Prüfkette war mit 76 Tests, statischer Analyse,
dem Audit des macOS-13-Deployment-Targets und beiden Universal-Slices
erfolgreich. Die integrierte Einstellungsansicht und der native
Markdown-Speicherdialog wurden unter macOS 26 geprüft. Der Starttest der
klassischen Einstellungen unter macOS 13/14 sowie die neuen physischen Fälle
für koordinierte Aktualisierung, Sleep/Wake und Fehlerzustände auf Apple
Silicon und dem unterstützten Intel-/T2-Mac wurden für 0.6.0 nicht wiederholt.
Diese Auslassung wurde ausdrücklich als Release-Ausnahme genehmigt und wird
nicht als physische Abnahme dargestellt.

### Dokumentierte Topologie-Abnahme am M4-Pro-Mac-mini — 31.08.2026

- Die drei rückseitigen Host-Anschlüsse erschienen jeweils einmal. Port 1
  wechselte live von frei mit bis zu 120 Gbit/s zu TerraMaster TDAS mit
  40 Gbit/s; Port 2 zeigte TerraMaster D1 SSD Pro mit 80 Gbit/s; Port 3 zeigte
  das Anker Thunderbolt 4 Mini Dock mit 40 Gbit/s.
- Die zwei integrierten Apple-Hub-Funktionen erschienen unter **Dieser Mac**.
  Die USB-Hub-Funktionen des D1 erschienen unter **TerraMaster D1 SSD Pro**,
  die Fresco-Logic- und Intel-Funktionen unter **Anker Thunderbolt 4 Mini Dock**.
- Das Anker Dock stellte drei nachgelagerte Protokollanschlüsse bereit. Eine
  spätere physische Prüfung seiner DROM-USB-Port-Map ordnete Maono Wireless Mic
  RX, ASM1352R-Fast und Loupedeck Live S den externen Ports 1, 2 und 3 zu. Jede
  Zeile zeigte das aktive USB-Protokoll und die ausgehandelte Geschwindigkeit.
  Der YubiKey blieb unter **Weitere USB-Geräte**, weil er am vorderen USB-A-Port
  des Docks steckte, dessen Port-Map-Eintrag absichtlich keinen
  Thunderbolt-Begleitpfad besitzt.
- Die laufende App aktualisierte Geräte- und Portanzahl beim Anschließen ohne
  Neustart. Diese Apple-Silicon-Beobachtung ersetzt keine Intel-Abnahme.

### Dokumentierte Intel-MacBook-Abnahme — 26.08.2026

Auf einem Intel-MacBook wurden folgende physische Prüfungen erfolgreich
beobachtet:

- Acht integrierte USB-Peripheriegeräte erschienen unter **Interne Geräte** und
  beeinflussten nicht den Zähler in der Menüleiste.
- Ein externes USB-3-Gerät und eine verbundene Bluetooth-Maus erschienen in
  ihren jeweiligen Gruppen; der Zähler in der Menüleiste zeigte korrekt **2**.
- Die Stromversorgung über das Mac-Netzteil wurde korrekt erkannt und
  angezeigt.

Dieser Eintrag hält nur diese beobachteten Fälle fest; bei Änderungen an der
Thunderbolt-/USB4-Erkennung ersetzt er nicht die übrigen oben genannten
Abnahmefälle.

### Dokumentierte Intel-MacBook-Topologieprüfung — 31.08.2026

- Der IOUSB-Baum stellte acht integrierte Funktionen direkt unter dem virtuellen
  T2-Hostcontroller `AppleUSBVHCIBCE` bereit, ohne dazwischenliegendes
  USB-Hub-Gerät der Klasse 9. **USB-Hubs: 0** ist für dieses Modell daher
  korrekt.
- Vier physische Thunderbolt-/USB4-Hostanschlüsse erschienen. TerraMaster TDAS
  belegte Port 2 mit 40 Gbit/s; die übrigen drei Ports waren frei.
- USB-Gerät, Thunderbolt-Gerät und verbundenes Bluetooth-Gerät ergaben den
  erwarteten Gesamtzähler **3**. Interne Funktionen blieben ausgeschlossen.
- Das signierte Universal-Testartefakt zeigte über ein CalDigit TS3 Plus Dock
  korrekt ein **87-W-Netzteil** und separat ein **100-W-Netzteil**. Bei 100 %
  Akkustand wurde die aktuelle Ladeleistung korrekt ausgeblendet; dieser
  Messwert muss später noch bei aktiv ladendem Akku beobachtet werden.
- Der physische Test des v6-Artefakts zur Portzuordnung war auch auf diesem
  Intel-MacBook erfolgreich. Ein direkt angeschlossenes 100-W-USB-C-Netzteil
  ließ den belegten Host-Port zunächst als **Frei** erscheinen, weil es keinen
  Datentransport erzeugt. Beim Umstecken vom sichtbaren Port 2 auf Port 1
  wechselte der eindeutige Gewinner in `PortControllerInfo` von Position 0 auf
  1. `BestAdapterIndex` blieb dagegen 0 und darf nicht als Portnummer verwendet
  werden. Die vier `AppleHPMDevice`-Einträge (`RID 0/1`, `Address 0/1`) und die
  geordneten `Socket ID`-Einträge der Thunderbolt-Root-Router bilden die
  konservative Brücke zu den bestehenden sichtbaren Portnummern. Der daraus
  erzeugte Build muss einen ansonsten leeren belegten Port als **Port N ·
  Stromversorgung** mit der Netzteilleistung anzeigen, ohne USB-, native
  Thunderbolt- oder Dock-Belegungen zu verändern. Bei unvollständigen oder
  mehrdeutigen Registry-Daten darf die App keine Zuordnung behaupten. Das
  signierte und notarisierte Universal-Artefakt für diese physische Prüfung war
  `PortGlance-Power-Port-Test-2026-08-31-v7.zip`,
  SHA-256 `f0e33d36da497c7cce5aa04b402da601f469d454990d9ff319a755f52355decf`.
  Die aus genau diesem ZIP erneut entpackte App bestand die strenge Signatur-,
  physische Ticket-, Gatekeeper- und Architekturprüfung. Der Hardwaretest
  bestätigte danach das 100-W-Netzteil an Port 1, 2, 3 und 4 und entfernte die
  vorherige Zuordnung bei jedem Umstecken. TS3 Plus und TDAS belegten beim
  Bereitstellen von Strom weiterhin ihre Datenzeilen und bestätigten damit den
  vorgesehenen Vorrang.
- Bei 86 % und aktivem Laden lieferte die öffentliche IOPowerSources-
  Beschreibung weiterhin keine Ladeleistung. Die erfassten
  `AppleSmartBattery`-Eigenschaften stellten stattdessen einen positiven
  momentanen Strom und die Batteriespannung bereit. Der v8-Build verwendet
  deshalb `InstantAmperage` plus `Voltage` nur dann, wenn die bevorzugte
  öffentliche Berechnung nicht möglich ist. Der gemittelte Wert `Amperage`
  greift nur bei fehlendem Momentanwert; Null, negative und unvollständige
  Angaben werden verworfen. Das physisch geprüfte Artefakt war
  `PortGlance-Charging-Power-Test-2026-08-31-v8.zip`, SHA-256
  `83b05e6580c33705067a7b6c6758b638c98a97c17a96600666b2caff5625048a`.
  Die daraus frisch entpackte App bestand die strenge Signatur-, physische
  Ticket-, Gatekeeper- und Architekturprüfung. Genau dieses Artefakt zeigte bei
  79 % **Lädt mit 10 W · 100-W-Netzteil** und bei 80 % **Lädt mit 41 W ·
  100-W-Netzteil**, während die reine Stromverbindung weiter Port 2 zugeordnet
  blieb. Der wechselnde Wert bestätigt die aktuelle Messung im
  Fünf-Sekunden-Takt statt einer statischen Netzteilkapazität.
- Das CalDigit-Dock, ein freier nachgelagerter Thunderbolt-Port, fünf
  USB-Funktionen und zwei USB-Hub-Funktionen wurden erkannt. Im ersten
  Testartefakt erschienen die Hubs unter **Direkt angeschlossene USB-Hubs**; v2
  und v3 zeigten dasselbe Ergebnis, während v3 die korrekte Zuordnung auf dem
  M4-Pro-Mac-mini beibehielt. Der abschließende v4-Test löst einen getunnelten
  Hub auch gegen die Liste nativer Thunderbolt-Geräte auf, wenn Intel-macOS das
  Gerät nicht an einen Host-Port anhängt. Ein generischer unaufgelöster Hub wird
  nur abgeleitet, wenn genau ein natives Thunderbolt-Gerät existiert und eine
  USB-Funktion desselben Controllers den passenden Hersteller besitzt. Die
  v4-Prüfung ergab eine Teilzuordnung: Der 480-Mbit/s-Hub wurde dem CalDigit-Gerät
  zugeordnet; der generische 12-Mbit/s-Hub blieb wegen fehlender Hinweise
  direkt. Die physische v5-Prüfung bestätigte, dass dieser zweite Eintrag unter
  **USB-Hubs mit unbekannter Zuordnung** erscheint, während der 480-Mbit/s-Hub
  unter dem CalDigit-Gerät bleibt. Benannte direkte Hubs, generische Hubs ohne
  native Thunderbolt-Topologie, interne Hubs und bereits aufgelöste
  Thunderbolt-Hubs bleiben in ihren bisherigen Gruppen.

Für die signierte Auslieferung danach die vollständige Anleitung in
[`RELEASE.md`](RELEASE.md) befolgen.

## DMG-Layout-Abnahme

Nach Änderungen am Paketbau das erzeugte DMG im Finder öffnen. Es muss eine
kompakte Installationsansicht mit App, Pfeil und **Programme**-Alias zeigen.
Die App muss sich auf **Programme** ziehen lassen; `LICENSE` muss weiterhin
vorhanden sein. Der Release-Skript prüft Alias, Hintergrund und Lizenz zudem
automatisiert im frisch eingebundenen DMG.
