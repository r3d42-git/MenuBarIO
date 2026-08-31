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
`PORTGLANCE_TEST_ARCH=arm64` or `PORTGLANCE_TEST_ARCH=x86_64` when that native
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

1. Connect a normal USB device and at least one USB hub. The device must appear
   under **USB Devices**, the hub under **USB Hubs**; the counter counts devices
   only.
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
6. Connect a USB device to a Thunderbolt-capable USB-C connector on the Mac or a
   dock. It must remain under **USB Devices** and must not appear as a connected
   device in either Thunderbolt port group.
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

### Recorded M4 Pro Mac mini topology validation — 2026-08-31

- The three rear host receptacles appeared once each. Port 1 updated live from
  empty at up to 120 Gbps to TerraMaster TDAS at 40 Gbps; Port 2 showed
  TerraMaster D1 SSD Pro at 80 Gbps; Port 3 showed Anker Thunderbolt 4 Mini Dock
  at 40 Gbps.
- The two built-in Apple hub functions appeared below **This Mac**. The D1 USB
  hub functions appeared below **TerraMaster D1 SSD Pro**, and the Fresco Logic
  plus Intel functions appeared below **Anker Thunderbolt 4 Mini Dock**.
- The Anker dock exposed three downstream protocol connectors. PortGlance
  displayed all three below the dock in **External TB/USB4 Ports**, each free
  with up to 40 Gbps during this observation.
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
`PORTGLANCE_TEST_ARCH=arm64` beziehungsweise `PORTGLANCE_TEST_ARCH=x86_64`
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

1. Ein normales USB-Gerät und mindestens ein USB-Hub anschließen. Das Gerät
   muss unter **USB-Geräte**, der Hub unter **USB Hubs** erscheinen; der
   Zähler zählt nur Geräte.
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
6. Ein USB-Gerät an eine Thunderbolt-fähige USB-C-Buchse des Mac oder eines
   Docks anschließen. Es muss unter **USB-Geräte** bleiben und darf in keiner der
   beiden Thunderbolt-Portgruppen als verbundenes Gerät erscheinen.
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

### Dokumentierte Topologie-Abnahme am M4-Pro-Mac-mini — 31.08.2026

- Die drei rückseitigen Host-Anschlüsse erschienen jeweils einmal. Port 1
  wechselte live von frei mit bis zu 120 Gbit/s zu TerraMaster TDAS mit
  40 Gbit/s; Port 2 zeigte TerraMaster D1 SSD Pro mit 80 Gbit/s; Port 3 zeigte
  das Anker Thunderbolt 4 Mini Dock mit 40 Gbit/s.
- Die zwei integrierten Apple-Hub-Funktionen erschienen unter **Dieser Mac**.
  Die USB-Hub-Funktionen des D1 erschienen unter **TerraMaster D1 SSD Pro**,
  die Fresco-Logic- und Intel-Funktionen unter **Anker Thunderbolt 4 Mini Dock**.
- Das Anker Dock stellte drei nachgelagerte Protokollanschlüsse bereit.
  PortGlance zeigte alle drei unter dem Dock in **Externe TB-/USB4-Ports**, bei
  dieser Beobachtung jeweils frei mit bis zu 40 Gbit/s.
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

Für die signierte Auslieferung danach die vollständige Anleitung in
[`RELEASE.md`](RELEASE.md) befolgen.

## DMG-Layout-Abnahme

Nach Änderungen am Paketbau das erzeugte DMG im Finder öffnen. Es muss eine
kompakte Installationsansicht mit App, Pfeil und **Programme**-Alias zeigen.
Die App muss sich auf **Programme** ziehen lassen; `LICENSE` muss weiterhin
vorhanden sein. Der Release-Skript prüft Alias, Hintergrund und Lizenz zudem
automatisiert im frisch eingebundenen DMG.
