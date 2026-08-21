# MenuBarUSB-TB

MenuBarUSB-TB is a native macOS menu-bar utility for inspecting connected USB,
Thunderbolt and USB4 hardware.

It is an independent fork of [rafaelSwi/MenuBarUSB](https://github.com/rafaelSwi/MenuBarUSB), retained under its MIT license. The fork focuses on reliable Thunderbolt/USB4 discovery and a compact device-first view.

## Highlights

- USB devices and USB hubs in independently collapsible groups
- Thunderbolt and USB4 devices, including negotiated link speed and protocol
- USB-C Billboard interfaces are identified as companion interfaces, so compatible Thunderbolt docks are not listed twice
- Optional local Ethernet-link indicator; network traffic monitoring is not included
- Local device names, hierarchy, connection logs and notifications
- No bundled audio, custom hardware sound or donation functionality
- No telemetry, analytics, crash reporting or automatic network requests; see
  [PRIVACY.md](PRIVACY.md) for the explicitly user-triggered browser and
  update actions

## Compatibility

**Version 0.1.0 supports Apple Silicon Macs (`arm64`) running macOS 13 or
newer. Intel Macs are not supported by this release.**

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
