# Testing

## Quick check before every commit

```bash
./script/verify.sh
```

The command uses an isolated DerivedData directory and runs:

- the privacy audit: no telemetry, update checks or network client code;
- the XCTest suite for device identity, hub classification, Thunderbolt link
  speed, Billboard detection and removal of retired features;
- the Xcode Static Analyzer for the Release configuration.
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
`MENUBARUSB_TEST_ARCH=arm64` or `MENUBARUSB_TEST_ARCH=x86_64` when that native
architecture is available.

## Hardware acceptance before a release

These cases require real hardware and cannot be meaningfully emulated in CI.
After every change to IOKit discovery, check them once:

1. Connect a normal USB device and at least one USB hub. The device must appear
   under **USB Devices**, the hub under **USB Hubs**; the counter counts devices
   only.
2. Connect a Thunderbolt/USB4 device (for example, an SSD enclosure). Its name,
   vendor, Thunderbolt/USB4 version and negotiated link speed must be visible.
3. Connect a Thunderbolt dock with a USB-C Billboard interface. The dock must
   appear once only as a Thunderbolt device, not additionally as a slow USB
   interface.
4. Connect two identical USB devices without serial numbers to different ports.
   Both must remain visible and retain separate settings.
5. Disconnect and reconnect each device. The list and group counter must
   react only once per physical device.
6. If the Ethernet indicator is enabled, turn its setting off and on twice. The
   cable icon may appear only when a wired link is active and must not initiate
   a network connection from the app.
7. Before the first Universal release, repeat cases 1–6 on an Intel Mac. If an
   Intel Mac is unavailable, record the approved exception in the release notes
   instead of claiming physical Intel-device acceptance.

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
- die XCTest-Tests für Geräteidentität, Hub-Klassifizierung, Thunderbolt-Link-Geschwindigkeit, Billboard-Erkennung sowie die Bereinigung entfernter Funktionen;
- den Xcode Static Analyzer für die Release-Konfiguration.
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
`MENUBARUSB_TEST_ARCH=arm64` beziehungsweise `MENUBARUSB_TEST_ARCH=x86_64`
ausdrücklich gewählt werden, wenn diese Architektur nativ verfügbar ist.

## Hardware-Abnahme vor einem Release

Diese Fälle benötigen echte Hardware und können nicht sinnvoll in CI emuliert
werden. Nach jeder Änderung an der IOKit-Erkennung einmal prüfen:

1. Ein normales USB-Gerät und mindestens ein USB-Hub anschließen. Das Gerät
   muss unter **USB-Geräte**, der Hub unter **USB Hubs** erscheinen; der
   Zähler zählt nur Geräte.
2. Ein Thunderbolt-/USB4-Gerät (beispielsweise ein SSD-Gehäuse) anschließen.
   Name, Anbieter, Thunderbolt-/USB4-Version und die ausgehandelte
   Link-Geschwindigkeit müssen sichtbar sein.
3. Ein Thunderbolt-Dock mit USB-C-Billboard-Interface anschließen. Das Dock
   darf nur einmal als Thunderbolt-Gerät erscheinen, nicht zusätzlich als
   langsames USB-Interface.
4. Zwei baugleiche USB-Geräte ohne Seriennummer an unterschiedliche Ports
   anschließen. Beide müssen sichtbar bleiben und getrennte Einstellungen
   behalten.
5. Geräte jeweils ab- und wieder anstecken. Liste und Gruppenzähler dürfen pro
   physischem Gerät nur einmal reagieren.
6. Falls die Ethernet-Anzeige aktiviert ist: Einstellung zweimal ein- und
   ausschalten. Das Kabelsymbol darf nur bei aktivem kabelgebundenem Link
   erscheinen und darf keine Netzwerkverbindung der App auslösen.
7. Vor dem ersten Universal-Release die Fälle 1–6 auf einem Intel-Mac
   wiederholen. Falls kein Intel-Mac verfügbar ist, die genehmigte Ausnahme in
   den Release Notes dokumentieren, statt eine physische Intel-Geräteabnahme zu
   behaupten.

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
