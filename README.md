# MenuBarIO

<img src="branding/MenuBarIO-AppIcon-master.png" alt="MenuBarIO app icon" width="128">

**USB, Thunderbolt, USB4 & Bluetooth Inspector for macOS**

[**Projektverlauf / Project History**](https://r3d42-git.github.io/MenuBarIO/)

[**Architektur-Atlas / Architecture Atlas**](https://r3d42-git.github.io/MenuBarIO/architecture/) · [English](https://r3d42-git.github.io/MenuBarIO/architecture/en/)

MenuBarIO is a native macOS menu-bar utility for inspecting connected USB,
Thunderbolt, USB4 and Bluetooth hardware.

MenuBarIO began with the MIT-licensed source of
[rafaelSwi/MenuBarUSB](https://github.com/rafaelSwi/MenuBarUSB). That original
idea and source authorship remain explicitly credited, and the original
copyright notice remains in LICENSE.upstream. MenuBarIO itself is developed and
maintained independently.

> [!IMPORTANT]
> MenuBarIO is not an official successor to MenuBarUSB, an official
> continuation of it or a version endorsed by its original author. There is no
> collaboration or affiliation with the original author, who is not involved
> in MenuBarIO development, maintenance, support or releases. GitHub lists
> upstream author accounts under **Contributors** only because this repository
> preserves the earlier source history.

## Highlights

- USB devices and topology-owned USB hubs in independently collapsible groups;
  Thunderbolt devices remain in the overall count but appear only with their
  physical ports
- Thunderbolt and USB4 devices, including negotiated link speed and protocol
- Physical Thunderbolt/USB4 host ports with occupancy, attached device and
  negotiated or maximum link speed; direct USB peripherals appear at their
  host socket when macOS supplies an explicit assignment
- External Thunderbolt/USB4 ports are detected from dock topology and grouped
  by their owning device; USB devices are shown on those ports when the
  physical topology identifies the connection unambiguously
- Optional MacBook power information shows battery percentage, live charging
  watts, adapter capacity and a power-only occupied USB-C port when available
- USB-C Billboard interfaces are identified as companion interfaces, so compatible Thunderbolt docks are not listed twice
- Optional local Ethernet-link indicator; network traffic monitoring is not included
- One coordinated refresh updates USB/Thunderbolt, Bluetooth, power and
  Ethernet after a manual request, wake or session activation; failed discovery
  keeps the last valid hardware snapshot visible and labels it as stale
- A structured Markdown report follows the visible group order and can be
  exported through the native save panel without serial numbers, Bluetooth
  addresses or internal identifiers; detailed per-device copy actions remain
  available from context menus
- Click any device or port for readable details, the reliably resolved connection
  path and technical identifiers; Command-C copies details, Command-R refreshes
  and Escape returns to the device list
- Bluetooth battery levels appear when available from macOS or the standard
  BLE Battery Service on an already connected, exactly identified device
- Compact USB labels keep protocol-generation details in the detail view;
  Thunderbolt 5 distinguishes 80 Gbps bidirectional capacity from 120 Gbps
  Bandwidth Boost, and explains that link rates are not file-transfer benchmarks
- Ethernet link changes update the indicator independently of USB discovery
- Compact device-first view without saved per-device customizations
- No bundled audio, custom hardware sound or donation functionality
- No telemetry, analytics, crash reporting or network requests; see
  [PRIVACY.md](PRIVACY.md)

## Compatibility

The current release, **MenuBarIO 0.7.1**, is a **Universal** app for Apple
Silicon (`arm64`) and Intel (`x86_64`) Macs running macOS 13 or newer. Automated
checks run natively on both architectures. The physical Intel-Mac observations
and the hardware cases that still apply after discovery changes are documented
in [TESTING.md](TESTING.md).

The legacy bundle identifier `de.r3d.menubarusb.tb` is intentionally retained
so existing installations keep their preferences and login-item identity.

## Build and test

Open `MenuBarIO.xcodeproj` in Xcode, or use the local checks:

```bash
./script/verify.sh
./script/build_and_run.sh --verify
```

Hardware acceptance cases and the release workflow are documented in
[TESTING.md](TESTING.md) and [RELEASE.md](RELEASE.md).

## License and origin

MenuBarIO 0.7.0 and later is distributed under [GPL-3.0-or-later](LICENSE).
The original MIT copyright and permission notice is preserved in
[LICENSE.upstream](LICENSE.upstream); [NOTICE](NOTICE) explains the origin.
Earlier published releases retain their MIT license. [SOURCE.md](SOURCE.md)
links to the exact corresponding public source tag for this release.

---

# MenuBarIO – Deutsch

<img src="branding/MenuBarIO-AppIcon-master.png" alt="MenuBarIO App-Icon" width="128">

**USB-, Thunderbolt-, USB4- & Bluetooth-Inspektor für macOS**

MenuBarIO ist ein natives macOS-Menüleistenprogramm zur Anzeige angeschlossener
USB-, Thunderbolt-, USB4- und Bluetooth-Hardware.

MenuBarIO entstand auf Grundlage des MIT-lizenzierten Quellcodes von
[rafaelSwi/MenuBarUSB](https://github.com/rafaelSwi/MenuBarUSB). Die
ursprüngliche Idee und Urheberschaft am Ausgangscode werden ausdrücklich
genannt; der ursprüngliche Copyright-Hinweis bleibt in der Lizenz erhalten.
MenuBarIO selbst wird unabhängig entwickelt und gepflegt.

> [!IMPORTANT]
> MenuBarIO ist weder ein offizieller Nachfolger noch eine offizielle
> Fortführung von MenuBarUSB und auch keine vom ursprünglichen Autor bestätigte
> Variante. Es bestehen weder Zusammenarbeit noch Zugehörigkeit; der
> ursprüngliche Autor ist an Entwicklung, Pflege, Support und Releases von
> MenuBarIO nicht beteiligt. GitHub führt dessen Konten ausschließlich wegen
> der erhaltenen früheren Quellcodehistorie unter **Contributors** auf.

## Wichtige Funktionen

- USB-Geräte und nach ihrem Topologie-Besitzer gegliederte USB-Hubs in
  unabhängig einklappbaren Gruppen; Thunderbolt-Geräte bleiben im
  Gesamtzähler, erscheinen aber nur an ihren physischen Ports
- Thunderbolt- und USB4-Geräte einschließlich ausgehandelter Link-Geschwindigkeit
  und Protokoll
- Physische Thunderbolt-/USB4-Host-Ports mit Belegung, angeschlossenem Gerät
  und ausgehandelter beziehungsweise maximaler Link-Geschwindigkeit; direkte
  USB-Geräte erscheinen bei expliziter macOS-Zuordnung an ihrem Hostanschluss
- Externe Thunderbolt-/USB4-Ports werden aus der Dock-Topologie erkannt und
  nach ihrem Gerät gruppiert; USB-Geräte erscheinen dort an ihrem Port, wenn
  die physische Topologie die Verbindung eindeutig bestimmt
- Optionale MacBook-Strominformationen zeigen Akkustand, aktuelle
  Ladeleistung, Netzteilkapazität und einen rein zur Stromversorgung belegten
  USB-C-Port, soweit macOS diese Angaben bereitstellt
- USB-C-Billboard-Schnittstellen werden als Begleitschnittstellen erkannt,
  sodass kompatible Thunderbolt-Docks nicht doppelt erscheinen
- Optionale lokale Ethernet-Link-Anzeige; eine Überwachung des Netzwerkverkehrs
  ist nicht enthalten
- Eine koordinierte Aktualisierung erfasst USB/Thunderbolt, Bluetooth,
  Stromversorgung und Ethernet nach manueller Anforderung, Ruhezustand oder
  Sitzungsaktivierung gemeinsam; bei einem Fehler bleibt der letzte gültige
  Hardwarestand sichtbar und wird als möglicherweise veraltet gekennzeichnet
- Ein strukturierter Markdown-Bericht folgt der sichtbaren Gruppenreihenfolge
  und lässt sich über den nativen Speicherdialog ohne Seriennummern,
  Bluetooth-Adressen oder interne Kennungen exportieren; detaillierte
  Einzelkopien bleiben in den Kontextmenüs verfügbar
- Ein Klick auf ein Gerät oder einen Port öffnet lesbare Details mit dem
  zuverlässig ermittelten Verbindungsweg und technischen Kennungen; ⌘C kopiert
  die Details, ⌘R aktualisiert und Esc führt zur Geräteliste zurück
- Bluetooth-Akkustände erscheinen, wenn macOS oder der standardisierte
  BLE-Akkudienst eines bereits verbundenen, eindeutig zugeordneten Geräts
  entsprechende Daten liefern
- Kurze USB-Angaben halten Protokollgenerationen in der Detailansicht;
  Thunderbolt 5 unterscheidet 80 Gbit/s bidirektionale Kapazität und 120 Gbit/s
  Bandwidth Boost und erklärt den Unterschied zwischen Linkrate und Dateitransfer
- Ethernet-Linkwechsel aktualisieren das Symbol unabhängig von der USB-Erkennung
- Kompakte, geräteorientierte Ansicht ohne gespeicherte Anpassungen je Gerät
- Keine eingebundenen Audiodateien, eigenen Hardware-Sounds oder
  Spendenfunktionen
- Keine Telemetrie, Analyse, Crash-Berichte oder Netzwerkanfragen; siehe
  [PRIVACY.md](PRIVACY.md)

## Kompatibilität

Der aktuelle Release **MenuBarIO 0.7.1** ist eine **Universal-App** für
Apple-Silicon- (`arm64`) und Intel-Macs (`x86_64`) mit macOS 13 oder neuer. Die
automatischen Prüfungen laufen nativ auf beiden Architekturen. Die physischen
Beobachtungen auf einem Intel-Mac und die nach Änderungen an der
Geräteerkennung weiterhin erforderlichen Hardware-Abnahmen sind in
[TESTING.md](TESTING.md) dokumentiert.

Die bisherige Bundle-ID `de.r3d.menubarusb.tb` bleibt absichtlich erhalten,
damit vorhandene Installationen ihre Einstellungen und die Identität des
Anmeldeobjekts behalten.

## Bauen und testen

`MenuBarIO.xcodeproj` in Xcode öffnen oder die lokalen Prüfungen ausführen:

```bash
./script/verify.sh
./script/build_and_run.sh --verify
```

Hardware-Abnahmefälle und der Release-Ablauf sind in
[TESTING.md](TESTING.md) und [RELEASE.md](RELEASE.md) dokumentiert.

## Lizenz und Herkunft

MenuBarIO ab Version 0.7.0 wird unter [GPL-3.0-or-later](LICENSE) vertrieben.
Der ursprüngliche MIT-Copyright- und Erlaubnishinweis bleibt in
[LICENSE.upstream](LICENSE.upstream) erhalten; [NOTICE](NOTICE) erläutert die
Herkunft. Frühere veröffentlichte Releases behalten ihre MIT-Lizenz.
[SOURCE.md](SOURCE.md) verlinkt den exakten öffentlichen Quellcode-Tag dieses Releases.
