# PortGlance

<img src="branding/PortGlance-AppIcon-master.png" alt="PortGlance app icon" width="128">

PortGlance is a native macOS menu-bar utility for inspecting connected USB,
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

The current release, **PortGlance 0.2.0**, is a **Universal** app for Apple
Silicon (`arm64`) and Intel (`x86_64`) Macs running macOS 13 or newer. Automated
checks run natively on both architectures. The physical Intel-Mac observations
and the hardware cases that still apply after discovery changes are documented
in [TESTING.md](TESTING.md).

The legacy bundle identifier `de.r3d.menubarusb.tb` is intentionally retained
so existing installations keep their preferences and login-item identity.

## Build and test

Open `PortGlance.xcodeproj` in Xcode, or use the local checks:

```bash
./script/verify.sh
./script/build_and_run.sh --verify
```

Hardware acceptance cases and the release workflow are documented in
[TESTING.md](TESTING.md) and [RELEASE.md](RELEASE.md).

## License and origin

PortGlance is distributed under the [MIT License](LICENSE). The original
copyright notice and license terms are preserved. This fork has no affiliation
with the original developer beyond its licensed source-code origin.

---

# PortGlance – Deutsch

<img src="branding/PortGlance-AppIcon-master.png" alt="PortGlance App-Icon" width="128">

PortGlance ist ein natives macOS-Menüleistenprogramm zur Anzeige
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

Der aktuelle Release **PortGlance 0.2.0** ist eine **Universal-App** für
Apple-Silicon- (`arm64`) und Intel-Macs (`x86_64`) mit macOS 13 oder neuer. Die
automatischen Prüfungen laufen nativ auf beiden Architekturen. Die physischen
Beobachtungen auf einem Intel-Mac und die nach Änderungen an der
Geräteerkennung weiterhin erforderlichen Hardware-Abnahmen sind in
[TESTING.md](TESTING.md) dokumentiert.

Die bisherige Bundle-ID `de.r3d.menubarusb.tb` bleibt absichtlich erhalten,
damit vorhandene Installationen ihre Einstellungen und die Identität des
Anmeldeobjekts behalten.

## Bauen und testen

`PortGlance.xcodeproj` in Xcode öffnen oder die lokalen Prüfungen ausführen:

```bash
./script/verify.sh
./script/build_and_run.sh --verify
```

Hardware-Abnahmefälle und der Release-Ablauf sind in
[TESTING.md](TESTING.md) und [RELEASE.md](RELEASE.md) dokumentiert.

## Lizenz und Herkunft

PortGlance wird unter der [MIT-Lizenz](LICENSE) vertrieben. Der ursprüngliche
Copyright-Hinweis und die Lizenzbedingungen bleiben erhalten. Dieser Fork ist
über die lizenzierte Herkunft des Quellcodes hinaus nicht mit dem ursprünglichen
Entwickler verbunden.
