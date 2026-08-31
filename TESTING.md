# Testing

## Quick check before every commit

```bash
./script/verify.sh
```

The command uses an isolated DerivedData directory and runs:

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
