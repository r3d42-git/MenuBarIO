# MenuBarUSB-TB

MenuBarUSB-TB is a native macOS menu-bar utility for inspecting connected USB,
Thunderbolt and USB4 hardware.

It is an independent fork of [rafaelSwi/MenuBarUSB](https://github.com/rafaelSwi/MenuBarUSB), retained under its MIT license. The fork focuses on reliable Thunderbolt/USB4 discovery and a compact device-first view.

## Highlights

- USB devices and USB hubs in independently collapsible groups
- Thunderbolt and USB4 devices, including negotiated link speed and protocol
- USB-C Billboard interfaces are identified as companion interfaces, so compatible Thunderbolt docks are not listed twice
- Optional local Ethernet-link indicator; network traffic monitoring is not included
- Compact device-first view without saved per-device customizations
- No bundled audio, custom hardware sound or donation functionality
- No telemetry, analytics, crash reporting or network requests; see
  [PRIVACY.md](PRIVACY.md)

## Compatibility

The current development branch builds a **Universal** app for Apple Silicon
(`arm64`) and Intel (`x86_64`) Macs running macOS 13 or newer. The released
version 0.1.1 remains Apple-Silicon-only. Before the first Universal release,
the device acceptance cases in [TESTING.md](TESTING.md) still need to be run on
an Intel Mac (or that exception must be explicitly accepted for the release).

## Build and test

Open `MenuBarUSB.xcodeproj` in Xcode, or use the local checks:

```bash
./script/verify.sh
./script/build_and_run.sh --verify
```

Hardware acceptance cases and the release workflow are documented in
[TESTING.md](TESTING.md) and [RELEASE.md](RELEASE.md).

## License and origin

MenuBarUSB-TB is distributed under the [MIT License](LICENSE). The original
copyright notice and license terms are preserved. This fork has no affiliation
with the original developer beyond its licensed source-code origin.

---

# MenuBarUSB-TB – Deutsch

MenuBarUSB-TB ist ein natives macOS-Menüleistenprogramm zur Anzeige
angeschlossener USB-, Thunderbolt- und USB4-Hardware.

Es ist ein unabhängiger Fork von
[rafaelSwi/MenuBarUSB](https://github.com/rafaelSwi/MenuBarUSB), der unter
seiner MIT-Lizenz weitergeführt wird. Der Fork konzentriert sich auf eine
zuverlässige Thunderbolt-/USB4-Erkennung und eine kompakte, geräteorientierte
Ansicht.

## Wichtige Funktionen

- USB-Geräte und USB-Hubs in unabhängig einklappbaren Gruppen
- Thunderbolt- und USB4-Geräte einschließlich ausgehandelter Link-Geschwindigkeit
  und Protokoll
- USB-C-Billboard-Schnittstellen werden als Begleitschnittstellen erkannt,
  sodass kompatible Thunderbolt-Docks nicht doppelt erscheinen
- Optionale lokale Ethernet-Link-Anzeige; eine Überwachung des Netzwerkverkehrs
  ist nicht enthalten
- Kompakte, geräteorientierte Ansicht ohne gespeicherte Anpassungen je Gerät
- Keine eingebundenen Audiodateien, eigenen Hardware-Sounds oder
  Spendenfunktionen
- Keine Telemetrie, Analyse, Crash-Berichte oder Netzwerkanfragen; siehe
  [PRIVACY.md](PRIVACY.md)

## Kompatibilität

Der aktuelle Entwicklungsstand baut eine **Universal-App** für Apple-Silicon-
(`arm64`) und Intel-Macs (`x86_64`) mit macOS 13 oder neuer. Die veröffentlichte
Version 0.1.1 bleibt ausschließlich für Apple Silicon. Vor dem ersten
Universal-Release müssen die Geräte-Abnahmefälle aus
[TESTING.md](TESTING.md) noch auf einem Intel-Mac ausgeführt werden (oder diese
Ausnahme muss für den Release ausdrücklich akzeptiert werden).

## Bauen und testen

`MenuBarUSB.xcodeproj` in Xcode öffnen oder die lokalen Prüfungen ausführen:

```bash
./script/verify.sh
./script/build_and_run.sh --verify
```

Hardware-Abnahmefälle und der Release-Ablauf sind in
[TESTING.md](TESTING.md) und [RELEASE.md](RELEASE.md) dokumentiert.

## Lizenz und Herkunft

MenuBarUSB-TB wird unter der [MIT-Lizenz](LICENSE) vertrieben. Der ursprüngliche
Copyright-Hinweis und die Lizenzbedingungen bleiben erhalten. Dieser Fork ist
über die lizenzierte Herkunft des Quellcodes hinaus nicht mit dem ursprünglichen
Entwickler verbunden.
