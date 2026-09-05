# Project Summary

## Purpose and scope

MenuBarIO is a local-only macOS menu-bar app for showing connected USB,
Thunderbolt/USB4 and Bluetooth devices. It targets macOS 13 or newer and does
not contain telemetry, analytics, update checks or network client code.
Its product subtitle is `USB, Thunderbolt, USB4 & Bluetooth Inspector for
macOS`.

The current product version is `0.7.0` (build 11). Releases are prepared from a
reviewed branch and integrated into protected `main` before tagging.
The product, executable, target and project are named `MenuBarIO`; the test
target is `MenuBarIOTests`. The legacy app bundle identifier
`de.r3d.menubarusb.tb` remains
unchanged so existing preferences and the login-item identity survive the
rebrand; the test bundle uses `de.r3d.menubario.tests`.

Public product language must credit the original MenuBarUSB idea and
MIT-licensed source without presenting MenuBarIO as an official successor to
MenuBarUSB, an official continuation of it or a version endorsed by its
original author. There is no collaboration or affiliation with the original
author, who is not involved in MenuBarIO development, maintenance, support or
releases. GitHub contributor entries for upstream author accounts reflect only
the preserved source history.

## MenuBarIO 0.7.0 compact improvements — 2026-09-05

The user approved device details, clearer link rates, Ethernet/copy fixes,
keyboard/accessibility improvements and Bluetooth battery display. These are
published as 0.7.0 (build 11). On 2026-09-05 the user confirmed
Apple Silicon hardware acceptance and explicitly authorized publication while
physical Intel acceptance remains pending. The previously scheduled GPL
transition is included in this release.

- Clicking a USB, Bluetooth or port row opens a live detail view inside the
  existing menu. Exact known host/dock assignments form a connection path;
  unresolved/ambiguous/cyclic paths remain unknown. Identifier fields are
  collapsed. Command-C copies details, Command-R refreshes, Escape goes back.
- USB list subtitles are compact; full generation names remain in details and
  reports. TB5/USB4-v2 120 Gbps capability is separated into standard 80 Gbps
  bidirectional capacity and asymmetric 120 Gbps Bandwidth Boost. USB occupants
  retain their own USB companion-port maximum rather than inheriting a TB rate.
  USB detail copies now include negotiated rate and protocol.
- EthernetLinkMonitor observes SystemConfiguration link/interface notifications.
  USBDeviceManager refreshes Ethernet independently, stops monitoring when the
  indicator is disabled and rejects obsolete asynchronous results.
- Bluetooth battery values come from local HID BatteryPercent or standard BLE
  service 180F / characteristic 2A19. A same-record IORegistry UUID/address
  mapping ties a currently connected peripheral to the existing device model.
  No name matching, scans, pairing, HID input access or GATT writes are used.
  Reads need existing Bluetooth authorization, time out after 10 seconds and
  are limited to a five-minute cadence; in-memory values expire after 15
  minutes and clear on disconnect, errors or invalid values. Unknown is omitted;
  0 percent is valid. The app does not initiate a new permission prompt solely
  for optional battery enrichment.
- Decorative icons no longer announce Disconnect; rows are native buttons,
  group expansion state is accessible and stale-data notices include the last
  successful timestamp. New UI and permission text covers all seven locales.

Verification: the full local gate passed 99 tests, static analysis and a
Universal arm64/x86_64 build. The sandboxed Debug app launched through the
repository wrapper. Visual/AX checks confirmed the actual Logi M650 L at 45%,
its detail view, the Mac Port 3 -> Anker Dock Port 2 -> ASM1352R-Fast path,
free-TB5 80/120 Gbps explanation and Command-C/Command-R/Escape. A native save
panel export to `/private/tmp/MenuBarIO-GPT6-Pruefbericht.md` contains 45% and
separate standard/boost fields without Bluetooth addresses or identifier labels.
The user subsequently confirmed Apple Silicon testing. Physical Intel
acceptance will follow later; publishing before it is explicitly approved.
Other Bluetooth models, macOS 13/14 and a fresh clean-machine installation
remain outside the directly observed checks; CI does not replace those tests.
Build/test artifacts are under `/private/tmp/menubario-gpt6-check`.

### Published release evidence — 2026-09-05

[MenuBarIO v0.7.0](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.7.0)
was published from the immutable annotated tag at release commit
`05d641c8abb85cb81c0cdad43b76ef33d84b38fb`, after PRs
[#24](https://github.com/r3d42-git/MenuBarIO/pull/24),
[#25](https://github.com/r3d42-git/MenuBarIO/pull/25) and
[#26](https://github.com/r3d42-git/MenuBarIO/pull/26).

- Public asset: [MenuBarIO-0.7.0-mac.dmg](https://github.com/r3d42-git/MenuBarIO/releases/download/v0.7.0/MenuBarIO-0.7.0-mac.dmg),
  3,181,432 bytes, with a published `.dmg.sha256` sidecar.
- SHA-256: `7125c9386664c5c425eafad82c7e9ee7289ab55c3493b88c225dfaf8aa802bcc`.
  Local bytes, fresh public download and GitHub's asset digest agree; the
  checksum sidecar's digest was independently compared as well.
- Universal `arm64 x86_64`, macOS 13+, version 0.7.0 (build 11), bundle
  `de.r3d.menubarusb.tb`, Hardened Runtime. Signing authority:
  `Developer ID Application: Philipp John Hild (G6JH37W285)`.
- Apple accepted the app submission `a0c04520-d80b-46f3-8994-00e0a292c5aa`.
  Its ticket was stapled and validated before packaging. Apple separately
  accepted the final DMG submission `03fcedfb-5817-4e88-8397-d2037dc42876`;
  the DMG ticket was also stapled and validated.
- The repository-native release and publication wrappers passed. The freshly
  downloaded DMG was mounted read-only; its integrity, signature, Gatekeeper
  acceptance, enclosed-app signature/ticket/Gatekeeper, both architectures,
  bundle/version, entitlements, and exact GPL/upstream/source files passed.
  A read-only Finder inspection of the final local DMG confirmed that the
  installer shows all six items with the complete license/source row.
- Both native macOS jobs passed on the release commit in
  [run 33961965054](https://github.com/r3d42-git/MenuBarIO/actions/runs/33961965054);
  Pages passed in [run 33961965050](https://github.com/r3d42-git/MenuBarIO/actions/runs/33961965050).
  All three PRs also passed their required checks and the native Intel job.
- Apple Silicon hardware acceptance was confirmed by the maintainer. Physical
  Intel acceptance remains deferred with explicit publication approval. A fresh
  clean-Mac installation, other Bluetooth models and macOS 13/14 hardware were
  not newly tested; CI and Gatekeeper do not replace those acceptance checks.

The existing notary profile briefly became unreadable while the Mac was
reported locked, including in the permitted local execution context. On the
user-requested retry the same profile worked; no credentials, Keychain items
or system security settings were changed. Final logs are
`/private/tmp/menubario-070-delivery.log` and
`/private/tmp/menubario-070-publish.log`. This documentation update follows
publication and must not move the release tag.

## Licensing from 0.7.0

MenuBarIO 0.7.0 and later uses GPL-3.0-or-later. LICENSE contains the full GPL,
LICENSE.upstream preserves the original MenuBarUSB MIT text verbatim, and
NOTICE records the origin and forward-only transition. SOURCE.md points to
https://github.com/r3d42-git/MenuBarIO/tree/v0.7.0 and its source archive.
All four files are bundled in the app before signing and in the DMG; the
release verifier checks the enclosed copies. Earlier MIT releases and their
tags remain unchanged.

The first local 0.7.0 archive exposed an Xcode user-script sandbox denial when
copying LICENSE: declaring only the output directory passed ordinary builds
but failed for archive installation paths. Each of the four output files is
now declared explicitly, with script sandboxing retained. The regular local
and CI gate now creates and verifies an ad-hoc Universal archive, catching this
class of packaging failure before Developer ID signing. The corrected local
gate passed; the failed attempt never reached Apple or GitHub publication.

The DMG window and background are 760 x 560 points/pixels so the four license
and source files remain visible below the app/Applications row. The original
420-point window clipped those files during the final read-only Finder check.

The bilingual project-history website is maintained as a curated static site
in `website/` and published from protected `main` through GitHub Pages at
[`r3d42-git.github.io/MenuBarIO`](https://r3d42-git.github.io/MenuBarIO/).
It preserves the exact design and editorial line of Sites version 3 while
remaining technically separate from the macOS app and its release process.
The private Sites deployment remains an unchanged backup rather than a second
synchronized publication channel.

On 2026-08-31, the working product was renamed from PortGlance to MenuBarIO.
The new name deliberately retains a visible connection to the MenuBarUSB
source origin, while the subtitle states the current app scope. The source
directory, Xcode project, app and test targets, executable, scripts, UI,
privacy text and current documentation use the new identity. Historical
PortGlance release names, tags and artifacts remain unchanged facts. The
canonical GitHub repository is now `r3d42-git/MenuBarIO`; historical release
links use that repository path while retaining their original tags and asset
names. Version 0.5.0 packages this identity change as the first MenuBarIO
release. It was published on 2026-08-31 as the signed, notarized and stapled
Universal release
[`v0.5.0`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.5.0) from
merged pull request
[`#18`](https://github.com/r3d42-git/MenuBarIO/pull/18) and release commit
`ee63ead636460ff7bfad3f2ad1649355a087af9c`. The public asset
`MenuBarIO-0.5.0-mac.dmg` is 2,901,103 bytes and has SHA-256
`d0f1738c83bf20577744dd7cff3e47408a2d3a605679a20ee2a717cc425ecead`.
Apple accepted the separately submitted app under
`e989bccd-b350-4140-8027-a7c2d86baf52` and the DMG under
`49e9ce14-ad88-44d4-a0d3-6199d80ccf4f`. Both pull-request CI jobs and both
jobs for the merged `main` commit in run
[`33409923818`](https://github.com/r3d42-git/MenuBarIO/actions/runs/33409923818)
passed. The full local gate, Universal build and launch verification also
passed. A direct UI check confirmed the localized subtitle fits in the German
settings view and the main device view shows the new name. The final GitHub
asset was freshly downloaded and passed checksum, DMG, Gatekeeper, staple and
enclosed-app ticket verification.

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

Device-row metadata was refined on 2026-08-31 so the subtitle identifies the
USB tier or Thunderbolt/USB4 transport while the aligned trailing value alone
shows the negotiated link rate. A different USB port maximum remains explicitly
labelled in the subtitle, and a port maximum no longer substitutes for an
unknown negotiated rate in the trailing position. USB Low-Speed is rendered as
the exact `1.5 Mbps` there. The complete local verification, launch smoke test
and visual inspection of the running menu passed; no new version or release was
created.

USB topology presentation was refined on 2026-08-31 as well. USB hubs are no
longer shown as one flat chip-vendor list: built-in hubs appear below This Mac,
while tunneled hubs appear below their owning Thunderbolt/USB4 device. A new
collapsed Thunderbolt/USB4 Ports group shows every physical host receptacle,
its attached device or free state, the active protocol and negotiated speed,
or the host maximum for a free port. Physical validation on the M4 Pro Mac mini
covered all three rear ports, the TerraMaster TDAS and D1 SSD Pro, the Anker
Thunderbolt 4 Mini Dock, all six hub functions and a live connection change.
Thunderbolt/USB4 devices now appear only below their physical ports rather than
also being duplicated in USB Devices. They remain included in the overall
connected-device and menu-bar count. The two Thunderbolt sections now precede
USB Devices: the first contains only the Mac host ports, while a separate
External TB/USB4 Ports section discovers downstream protocol connectors from
attached-device IOKit topology and groups them by owner. The connected Anker
Thunderbolt 4 Mini Dock exposed three such ports, all shown free at up to
40 Gbps during validation. A USB device attached through a Thunderbolt-capable
USB-C connector remains exclusively in USB Devices; only native Thunderbolt
transport can populate a Thunderbolt port row. The complete local verification,
Universal build, launch smoke test and visual inspection passed; no new version
or release was created.

That transport-only presentation was revised after physical testing showed why
the Anker dock's three downstream ports looked empty while carrying USB
devices. PortGlance now parses the router's Thunderbolt DROM `USB Port Map` and
combines it with the direct IOUSB parent-hub path. A USB device is attached to
an external multi-protocol port only when the dock is itself linked to a known
host port, tunnel evidence exists, the DROM maps that connector to the observed
companion-hub port and exactly one device matches. Native Thunderbolt remains
higher priority and every ambiguous case stays unassigned. The local M4 Pro Mac
mini check assigned Maono Wireless Mic RX, ASM1352R-Fast and Loupedeck Live S to
Anker Ports 1, 2 and 3 with their actual USB protocols and rates. YubiKey stayed
under the renamed **Other USB Devices** group because the dock's front USB-A
port is USB-only in the DROM map. Attached USB devices are removed from that
residual list without changing the overall count. Intel docks whose native
host-port relationship is missing, including the observed TS3 Plus topology,
are deliberately left unchanged instead of being guessed. Unit tests cover the
Anker map, USB-only socket, native-Thunderbolt priority, ambiguity rejection and
Intel safeguard. The complete local verification, Universal build, launch
smoke test and visual inspection passed. Apple accepted the standalone test app
under submission `dcbd88ba-1d31-4c72-ab60-29048bdc8c94`; its ticket was
stapled before packaging `PortGlance-Port-Assignment-Test-2026-08-31-v6.zip`,
SHA-256 `57b6604901423dfda9c044e5cc23f9e654ddc8abfc206a6c46b4686462aefaa8`.
The app re-extracted from that exact ZIP passed strict signature, physical
ticket, Gatekeeper and both-architecture verification. No new version or
release was created.

Physical Intel/T2 testing of that v6 artifact also passed, but exposed one
remaining host-port ambiguity: a directly connected 100 W USB-C power adapter
correctly appeared in the power-supply row while its occupied Thunderbolt port
still said Free because a power-only USB-C PD connection creates no USB or
Thunderbolt data device. Follow-up registry captures established a conservative
model-specific bridge. `AppleSmartBattery.PortControllerInfo` contains exactly
one winning controller with an active PD state, a nonzero FET status and a
positive maximum power value. Moving the adapter from visible Port 2 to Port 1
changed that winner from array position 0 to 1, while `BestAdapterIndex` stayed
0 and was therefore rejected as a physical-port signal. Four `AppleHPMDevice`
records identify the same controllers by `RID` and `Address`; root
`IOThunderboltSwitch` records map each router's ordered connector pair to the
existing visible `Socket ID` numbers. PortGlance now combines those three
sources and labels an otherwise empty matching row **Port N · Power supply**
with the rated adapter wattage. It returns no port at all unless the contract,
controller and Thunderbolt topologies are complete, unique and internally
consistent. Existing USB and native Thunderbolt occupants always retain
priority. Five focused resolver tests cover both controller sides and rejection
of incomplete or multiple-winner data; the full 58-test gate, static analysis
and Universal build passed. Apple accepted the standalone test app under
submission `b98bddbc-253f-4f07-b05a-84d8018957a3`; its ticket was stapled
before packaging `PortGlance-Power-Port-Test-2026-08-31-v7.zip`, SHA-256
`f0e33d36da497c7cce5aa04b402da601f469d454990d9ff319a755f52355decf`.
The app re-extracted from that exact ZIP passed strict signature, physical
ticket, Gatekeeper and both-architecture verification. Physical Intel/T2
validation of that exact v7 artifact subsequently confirmed the 100 W adapter
on each of the four host ports, with the previous assignment clearing after
every move. The TS3 Plus and TDAS remained the visible data occupants while
supplying power, confirming that USB, Thunderbolt and dock occupancy retains
priority over the power-only label. No new product version or public release
was created.

A physical Intel/T2 MacBook follow-up confirmed that its eight built-in USB
functions attach directly below `AppleUSBVHCIBCE`; it exposes no intervening
class-9 USB hub device. PortGlance therefore correctly reports zero USB hubs on
that machine even though each host controller necessarily provides root-port
functionality. To make the resulting list clearer without guessing hardware
identities, the group is now named Internal USB Components and a raw
`IOUSBHostDevice`/`IOUSBDevice` registry fallback is displayed as Unnamed
Internal USB Component. The original registry name remains available when
device details are copied.

The optional power-supply row now combines battery percentage with live charging
power and the attached adapter wattage when macOS provides those values. It uses
the public IOPowerSources current and voltage keys to calculate actual battery
charging power, and `IOPSCopyExternalPowerAdapterDetails` for the adapter's
rated wattage. The measurement refreshes every five seconds while the feature
is enabled. Missing values are omitted instead of estimated; macOS does not
reliably expose an adapter marketing name or manufacturer through this API. The
complete local verification, Universal build and launch smoke test passed. Apple
accepted the standalone test app under submission
`aa29ea83-811c-4cdb-b240-a8bcc29e3d2f`; its ticket was stapled before the final
Universal ZIP was created and independently re-extracted and verified. The test
ZIP is `PortGlance-MacBook-Test-2026-08-31.zip`, SHA-256
`b04b11a273e1124ced9468042eb118e7b43fbd3990a8929b9c359d1ae12b0c6c`.
Physical Intel validation of that artifact confirmed an 87 W supply through a
CalDigit TS3 Plus dock and a separate 100 W adapter at a full battery. The row
correctly omitted live charging power at 100%; live charging-power validation
therefore remained pending until the battery was below its charging threshold.
A later check at 86% confirmed active charging but still showed no live watts:
the Intel/T2 IOPowerSources description omitted its public `Current` value.
The already captured `AppleSmartBattery` properties did expose
`InstantAmperage = 997 mA` and `Voltage = 12618 mV`, which represents about
12.6 W of actual battery charging power. PortGlance now prefers the public
current and voltage values, then uses positive `InstantAmperage` with the
battery voltage only when that calculation is unavailable; averaged
`Amperage` is considered only when the instantaneous field itself is absent.
Zero, negative or incomplete values produce no wattage, and charger target
current is never presented as an actual measurement. Six additional tests
cover this priority and rejection behavior; all 64 tests, static analysis, the
Universal build and launch smoke test passed. Apple accepted the standalone
test app under submission `14534bdd-6ca2-4521-8d71-7c9b7dfb51e7`; its ticket
was stapled before packaging
`PortGlance-Charging-Power-Test-2026-08-31-v8.zip`, SHA-256
`83b05e6580c33705067a7b6c6758b638c98a97c17a96600666b2caff5625048a`.
The app re-extracted from that exact ZIP passed strict signature, physical
ticket, Gatekeeper and both-architecture verification. Physical Intel/T2
validation of that exact v8 artifact subsequently showed **Charging at 10 W ·
100 W adapter** at 79% and **Charging at 41 W · 100 W adapter** at 80%, while
the power-only connector remained assigned to Port 2. The changing value
confirmed that the five-second refresh reports the live battery-side charging
measurement rather than the adapter rating. No new product version or public
release had been created at that test stage.
The dock, its downstream Thunderbolt port, five USB functions and two USB hub
functions were detected. Both dock hubs initially appeared under Directly
Connected USB Hubs because Intel `AppleUSBXHCITR` bus numbers do not identify
the physical Thunderbolt host router. A second physical test showed that the
v2 attempt still left both hubs in that group: on this Intel Mac the tunneled
controller is visible in the `IOUSB` registry plane used by `ioreg -p IOUSB`,
but not in the IOService parent chain that v2 inspected. Discovery now follows
both planes independently and also consumes the direct `UsbTunnel` property
when macOS supplies it. Physical testing showed that v3 still left both hubs in
the direct group, while the unchanged M4 Pro Mac mini mapping continued to
work. The remaining Intel difference is that the CalDigit Thunderbolt router
is present without being attached to a host-port model. The final v4 fallback
therefore also resolves an explicit tunneled hub against the discovered native
Thunderbolt devices. For a generic `IOUSBHostDevice` hub lacking that signal,
it requires one native Thunderbolt device plus a same-controller USB sibling
whose vendor matches that Thunderbolt device; otherwise the hub remains direct
or unknown. This keeps the inference restricted to the observed Intel topology
instead of assigning every unresolved hub. Regression tests cover explicit
ancestry precedence, tunnel-based ownership, the same-controller vendor match
and the no-match safeguard. The complete verification and Universal launch
build passed. Apple accepted the final v4 test app under submission
`7f1d2fd1-4f82-48d2-928a-ea145bd51da0`; its ticket was stapled before creating
`PortGlance-MacBook-Hub-Test-2026-08-31-v4.zip`, SHA-256
`fb4a4b407ef35b7dbe8242f4dedf8da7b7f8c740c766ecb5c1e5ea4a92717bfc`. The app
re-extracted from that final ZIP passed strict code-signature, physical-ticket,
Gatekeeper and both-architecture verification. Physical v4 testing assigned
the 480 Mbps hub to the CalDigit TS3 Plus through the constrained vendor
evidence, while the generic 12 Mbps hub remained in the direct group. This
partial result confirms that macOS does not expose enough ownership evidence
for the second hub. The v5 presentation now separates this ambiguity from the
existing direct cases: ordinary named hubs and generic hubs without any native
Thunderbolt topology remain under Directly Connected USB Hubs, while a generic
unresolved registry entry in the presence of native Thunderbolt devices appears
under USB Hubs with Unknown Assignment. Existing internal and Thunderbolt owner
paths are unchanged. Regression tests cover all four outcomes. Apple accepted
the v5 test app under submission `4b1b1153-f924-4002-84c2-6b3f3570de78`; its
ticket was stapled before creating
`PortGlance-MacBook-Hub-Test-2026-08-31-v5.zip`, SHA-256
`594b615d24a61cc328b8fd01180d42ced5f628ae7d7fcee891f975ea3a480132`. The app
re-extracted from that final ZIP passed strict code-signature, physical-ticket,
Gatekeeper and both-architecture verification. Physical Intel testing of that
exact v5 artifact confirmed the intended final presentation: the 480 Mbps hub
remained below CalDigit, Inc. TS3 Plus and the unresolved 12 Mbps hub appeared
below USB Hubs with Unknown Assignment. No new product version or public
release was created.

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

Version 0.4.0 packages the Intel/T2 MacBook work, conservative USB ownership
and downstream-port attachment, power-only USB-C port occupancy and live
battery charging power into one feature release. It preserves native
Thunderbolt and USB device-count semantics, declines ambiguous assignments and
keeps all hardware inspection local. It was published on 2026-08-31 as the
signed, notarized and stapled Universal release
[`v0.4.0`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.4.0) from
merge commit `89c9d18546f27c197a796676a5487dbc9fb35c22`. Apple accepted the
separately submitted app (`628f94de-7781-47ca-8a48-fdb49f47748b`) and DMG
(`cc9d6127-78e6-4c9a-bc54-259f4eda8c62`). The public asset
`PortGlance-0.4.0-mac.dmg` has SHA-256
`5bdd2287ce002c9ac1a825ae987bd2a16cdaf9e8aa5daf350e7adc34c2678196`, matching
GitHub's reported digest; a fresh GitHub download passed the independent
release verification, including the physically stapled app inside the mounted
DMG. All 64 tests, static analysis, the Universal build, local launch smoke
test and both native pull-request CI jobs passed. Physical acceptance covered
the M4 Pro Mac mini topology plus the Intel/T2 MacBook's internal components,
CalDigit hub ownership, unknown-hub fallback, all four power-only host ports,
TS3 Plus and TDAS data-priority cases, and dynamic 10 W to 41 W charging
measurements with a 100 W adapter.

Version 0.3.0 packages the device-row metadata and USB/Thunderbolt topology
work into a feature release. It was published on 2026-08-31 as the signed,
notarized and stapled Universal release
[`v0.3.0`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.3.0) from
merge commit `323c25a5d7ac8cc00400681547eafa51e26a40b4`. Apple accepted the
separately submitted app (`2d0460f3-5228-4cd1-97d2-9370cba3b541`) and DMG
(`99669732-8ee5-490e-9b0d-231d662e452d`). The public asset
`PortGlance-0.3.0-mac.dmg` has SHA-256
`2a1fee426174beb54c9a91c7c233a137187ca5f209d5196f9f2cee849d2013ed`, matching
GitHub's reported digest; a fresh GitHub download passed the independent
release verification, including the physically stapled app inside the mounted
DMG. The complete automated gate, both native GitHub CI jobs, static analysis,
Universal build, local launch smoke test and user visual inspection passed.
Physical validation on the M4 Pro Mac mini covered the documented host ports,
attached devices, hub ownership and live connection change. The physical Intel
check of the new topology will be performed later with the published v0.3.0
GitHub artifact; this release does not claim physical Intel hardware acceptance
for the new topology.

Version 0.2.1 collects these minimal-settings, appearance and cleanup changes
into one maintenance release. The device-discovery services, hardware
classification and privacy model are unchanged. The complete automated gate,
Universal build, local launch smoke test and user visual inspection passed.
It was published on 2026-08-31 as the signed, notarized and stapled Universal
release [`v0.2.1`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.2.1)
from merge commit `22e7b542409fc024e5610ec4cc042d0315f939b8`. Apple accepted the
separately submitted app (`bbce9e54-529e-4de9-aa3c-1a80e01bd42e`) and DMG
(`5ce8ed88-2b8f-4f54-9c12-256ffa74dcbb`). The public asset
`PortGlance-0.2.1-mac.dmg` has SHA-256
`e52f4b0c47faf266af1f24e1627ada397e8b07f92ff283f90a7df6f0690659c0`; a
fresh GitHub download passed the independent release verification, including
the physically stapled app inside the mounted DMG.

The PortGlance rebrand was completed on 2026-08-30 and passed the complete
local verification plus launch smoke test. The canonical repository is
`r3d42-git/MenuBarIO`; `upstream` remains the read-only source reference to
`rafaelSwi/MenuBarUSB`. The rebrand was published as the signed, notarized and
stapled Universal release
[`v0.2.0`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.2.0). Its
release asset is `PortGlance-0.2.0-mac.dmg` with SHA-256
`c79e5a61dca6e6a160df23a8a2361f29121ce71ae402e4ecae9a131a55847709`; the
publicly downloaded artifact passed the independent release verification.

Version 0.6.0 keeps macOS 13 as the unified project, app and test deployment
target and retains both Universal architectures plus
the Ventura/Sonoma settings window. A central lifecycle coordinator refreshes
USB/Thunderbolt, Bluetooth, power and Ethernet together from the footer and
after wake or session activation, while coalescing adjacent lifecycle events.
Discovery now distinguishes ready, refreshing, stale and unavailable states:
a failed refresh preserves the last complete USB/Thunderbolt or Bluetooth
snapshot, a legitimate empty result remains zero devices and a powered-off
Bluetooth controller is identified explicitly. The footer exports a structured
Markdown report in visible group order through the native save panel, without
serial numbers, Bluetooth addresses, location IDs, stable internal IDs,
usernames or paths. Its sandbox access is limited to the file explicitly chosen
by the user and is not retained. The detailed USB copy remains unchanged, and
Bluetooth rows plus Thunderbolt-port rows provide their own explicit
context-menu copies. Automated verification covers 76 tests, static analysis,
the macOS 13 deployment-target audit and both Universal slices. The integrated
settings and Markdown save panel were checked on macOS 26. The explicitly
approved release exception records that the macOS 13/14 legacy-settings smoke
test and the new physical refresh, sleep/wake and failure-state cases on Apple
Silicon and the supported Intel/T2 Mac were not repeated for this release. It
was published on 2026-09-01 as the signed, notarized and stapled Universal
release [`v0.6.0`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.6.0)
from merged pull request
[`#22`](https://github.com/r3d42-git/MenuBarIO/pull/22) and merge commit
`6c2f10b63f5de12be6e1a7fb866b60530a6457db`. Apple accepted the separately
submitted app under `df885c77-14e4-44cc-b931-59d120f670a7` and the DMG under
`6d72c7ac-dddd-41f3-8e34-72baa5416431`. The public
`MenuBarIO-0.6.0-mac.dmg` is 2,984,052 bytes and has SHA-256
`8ffbced9b240d2d3cfd39d689322971e3b12ff80761c81df15b966f7f08ba84c`,
matching GitHub's asset digest. Both native jobs passed in pull-request CI run
[`33509359572`](https://github.com/r3d42-git/MenuBarIO/actions/runs/33509359572)
and main CI run
[`33509796189`](https://github.com/r3d42-git/MenuBarIO/actions/runs/33509796189);
the main Pages build and public-route verification also passed in run
[`33509796257`](https://github.com/r3d42-git/MenuBarIO/actions/runs/33509796257).
A fresh GitHub download passed checksum, DMG integrity, Gatekeeper, both staple
checks, enclosed-app signature, version/build, Universal slices and installer
layout verification.

## Code structure

- `MenuBarIO/MenuBarIOApp.swift` registers defaults, runs the one-time legacy
  migration and composes the app scenes.
- `MenuBarIO/Services/` contains system adapters and lifecycle code for IOKit
  discovery, connection notifications, power sources, Ethernet state,
  login-item state and legacy-data migration.
- `MenuBarIO/Structs/` and `MenuBarIO/Enums/` contain stable device models,
  grouping rules and preference types.
- `MenuBarIO/Support/` contains stateless formatting and system-action
  helpers.
- `MenuBarIO/Views/` contains small menu-bar, list, row and settings
  components. Current and legacy settings reuse the same controls.
- `MenuBarIOTests/` mirrors the model, service and migration boundaries with
  focused test files.
- `branding/MenuBarIO-AppIcon-master.png` is the generated high-resolution
  icon master. `MenuBarIO/Assets.xcassets/AppIcon.appiconset/` contains the
  derived macOS icon sizes. In-app category and status icons use SF Symbols.

USB and Thunderbolt identities must remain stable across refreshes. Internal
devices and USB hubs do not count toward the external-device total. Thunderbolt
devices remain in that total but are rendered only in the physical port group,
not in Other USB Devices. Safely mapped USB devices likewise remain counted but
are rendered at the external multi-protocol port instead of in the residual
list. Bluetooth devices count separately. The visible group order is
Thunderbolt/USB4 host ports, external Thunderbolt/USB4 ports, Other USB Devices,
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

## Veröffentlichung 0.7.0 — 05.09.2026

Die freigegebenen Punkte 1–4 und Bluetooth-Akkustände sind veröffentlicht:
Gerätedetails mit sicher zugeordnetem Verbindungsweg, kurze USB-Zeilen und
getrennte TB5-Standard-/Boost-Kapazität, ereignisgesteuerter Ethernet-Status,
vollständigere Detailkopien, Tastaturkürzel, verbesserte Bedienungshilfen und
Akkustände bereits verbundener Geräte über macOS-HID beziehungsweise den
standardisierten BLE-Akkudienst. Die Logi M650 L zeigte im gestarteten,
sandboxed Build 45 %. Der vollständige lokale Prüflauf bestand 99 Tests,
statische Analyse und Universal-Build; Detailansichten, Kürzel und nativer
Berichtsexport wurden geprüft. Die nachfolgend bestätigte Apple-Silicon-Abnahme
ist berücksichtigt; Intel-/macOS-13/14- und weitere Bluetooth-Gerätefälle bleiben
offen. Die englische Sektion „MenuBarIO 0.7.0 compact improvements“ enthält die
Prüfpfade. Version 0.7.0 (Build 11) enthält die geplante Umstellung auf GPL-3.0-or-later
mit erhaltenem MIT-Herkunftshinweis und exaktem Quellcode-Tag in App und DMG.
Der Benutzer hat am 05.09.2026 die Apple-Silicon-Abnahme bestätigt und die
Veröffentlichung trotz noch ausstehender physischer Intel-Abnahme freigegeben.

[Version 0.7.0](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.7.0)
ist als signierte, separat für App und DMG notarisierte Universal-Version
öffentlich verfügbar. Der frische GitHub-Download bestand alle Prüfungen;
seine SHA-256 stimmt mit dem lokalen Artefakt und GitHubs Dateidigest überein.
Release-Commit ist `05d641c8abb85cb81c0cdad43b76ef33d84b38fb`. Beide nativen
CI-Jobs und Pages sind grün. Exakte Prüfsumme, Download, Apple-Vorgangsnummern
und verbleibende Hardwaregrenzen stehen oben unter „Published release evidence“.


## Zweck und Umfang

MenuBarIO ist eine rein lokal arbeitende macOS-Menüleisten-App zur Anzeige
angeschlossener USB-, Thunderbolt-/USB4- und Bluetooth-Geräte. Sie unterstützt
macOS 13 oder neuer und enthält weder Telemetrie noch Analysen,
Update-Abfragen oder Netzwerk-Client-Code.
Ihr Produktuntertitel lautet `USB, Thunderbolt, USB4 & Bluetooth Inspector for
macOS`.

Die aktuelle Produktversion ist `0.7.0` (Build 11). Releases werden auf einem
geprüften Branch vorbereitet und vor dem Tagging in den geschützten Branch
`main` integriert.
Produkt, Programmdatei, Target und Projekt heißen `MenuBarIO`; das Test-Target
heißt `MenuBarIOTests`.
Die bisherige App-Bundle-ID `de.r3d.menubarusb.tb` bleibt erhalten, damit
Einstellungen und Anmeldeobjekt-Identität die Umbenennung überstehen; das
Test-Bundle verwendet `de.r3d.menubario.tests`.

Die öffentliche Produktkommunikation muss die ursprüngliche MenuBarUSB-Idee
und den MIT-lizenzierten Ausgangscode nennen, ohne MenuBarIO als offiziellen
Nachfolger, offizielle Fortführung oder vom ursprünglichen Autor bestätigte
Variante darzustellen. Es bestehen weder Zusammenarbeit noch Zugehörigkeit zum
ursprünglichen Autor, der an Entwicklung, Pflege, Support und Releases von
MenuBarIO nicht beteiligt ist. GitHub-Contributor-Einträge der Upstream-Autoren
bilden ausschließlich die erhaltene Quellcodehistorie ab.

Am 31.08.2026 wurde das aktuelle Produkt von PortGlance in MenuBarIO
umbenannt. Der neue Name hält die Herkunft aus MenuBarUSB bewusst sichtbar;
der Untertitel beschreibt zugleich den heutigen Funktionsumfang. Quellordner,
Xcode-Projekt, App- und Test-Targets, Programmdatei, Skripte, Oberfläche,
Datenschutztext und aktuelle Dokumentation verwenden die neue Identität.
Historische PortGlance-Releasenamen, Tags und Artefakte bleiben als Fakten
unverändert. Das kanonische GitHub-Repository heißt jetzt
`r3d42-git/MenuBarIO`; Links auf historische Releases verwenden diesen
Repository-Pfad und behalten ihre ursprünglichen Tags und Artefaktnamen.
Version 0.5.0 bündelt diese Identitätsänderung als ersten
MenuBarIO-Release. Er wurde am 31.08.2026 als signierter, notarisierter und
gestapelter Universal-Release
[`v0.5.0`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.5.0) aus dem
gemergten Pull Request
[`#18`](https://github.com/r3d42-git/MenuBarIO/pull/18) und dem Release-Commit
`ee63ead636460ff7bfad3f2ad1649355a087af9c` veröffentlicht. Das öffentliche
Artefakt `MenuBarIO-0.5.0-mac.dmg` ist 2.901.103 Bytes groß und hat den SHA-256
`d0f1738c83bf20577744dd7cff3e47408a2d3a605679a20ee2a717cc425ecead`.
Apple akzeptierte die separat eingereichte App unter
`e989bccd-b350-4140-8027-a7c2d86baf52` und das DMG unter
`49e9ce14-ad88-44d4-a0d3-6199d80ccf4f`. Beide Pull-Request-CI-Jobs sowie beide
Jobs für den gemergten `main`-Commit im Lauf
[`33409923818`](https://github.com/r3d42-git/MenuBarIO/actions/runs/33409923818)
waren erfolgreich. Auch die vollständige lokale Prüfkette, der Universal-Build
und der Starttest waren erfolgreich. Eine direkte UI-Prüfung bestätigte, dass
der lokalisierte Untertitel in der deutschen Einstellungsansicht vollständig
sichtbar ist und die Geräteansicht den neuen Namen zeigt. Das finale
GitHub-Artefakt wurde frisch heruntergeladen und bestand die Prüfung von
Prüfsumme, DMG, Gatekeeper, Staple und dem Ticket der enthaltenen App.

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

Die Metadaten der Gerätezeilen wurden am 31.08.2026 weiter präzisiert: Der
Untertext benennt jetzt die USB-Klasse beziehungsweise den
Thunderbolt-/USB4-Transport, während ausschließlich der rechts ausgerichtete
Wert die ausgehandelte Verbindungsgeschwindigkeit zeigt. Eine abweichende
maximale USB-Portgeschwindigkeit bleibt im Untertext ausdrücklich bezeichnet
und ersetzt rechts keine unbekannte Verbindungsgeschwindigkeit mehr. USB
Low-Speed wird dort exakt als `1.5 Mbps` dargestellt. Die vollständige lokale
Prüfkette, der Starttest und die Sichtprüfung des laufenden Menüs waren
erfolgreich; es wurde keine neue Version und kein Release erstellt.

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

Am 31.08.2026 wurde außerdem die Darstellung der USB-Topologie präzisiert.
USB-Hubs erscheinen nicht mehr als flache Liste ihrer Chip-Hersteller:
integrierte Hubs stehen unter Dieser Mac, getunnelte Hubs unter ihrem
zugehörigen Thunderbolt-/USB4-Gerät. Eine neue, standardmäßig eingeklappte
Gruppe Thunderbolt-/USB4-Ports zeigt jeden physischen Host-Anschluss, das
angeschlossene Gerät oder den freien Zustand, das aktive Protokoll und die
ausgehandelte Geschwindigkeit beziehungsweise bei einem freien Port das
Host-Maximum. Die physische Abnahme am M4-Pro-Mac-mini umfasste alle drei
rückseitigen Ports, TerraMaster TDAS und D1 SSD Pro, das Anker Thunderbolt 4
Mini Dock, alle sechs Hub-Funktionen und eine laufende Anschlussänderung. Die
Thunderbolt-/USB4-Geräte erscheinen jetzt nur noch unter ihren physischen Ports
und nicht zusätzlich unter USB-Geräte. Im Gesamt- und Menüleistenzähler werden
sie weiterhin mitgezählt. Die beiden Thunderbolt-Bereiche stehen jetzt vor
USB-Geräte: Der erste enthält nur die Hostanschlüsse des Mac, während eine
eigene Gruppe Externe TB-/USB4-Ports nachgelagerte Protokollanschlüsse aus der
IOKit-Topologie angeschlossener Geräte erkennt und nach Besitzer gruppiert. Das
angeschlossene Anker Thunderbolt 4 Mini Dock stellte drei solche Ports bereit,
die bei der Abnahme jeweils frei mit bis zu 40 Gbit/s erschienen. Ein über eine
Thunderbolt-fähige USB-C-Buchse angeschlossenes USB-Gerät bleibt ausschließlich
unter USB-Geräte; nur nativer Thunderbolt-Transport kann eine
Thunderbolt-Portzeile belegen. Die vollständige lokale Prüfung, der
Universal-Build, der Starttest und die Sichtprüfung waren erfolgreich; es wurde
keine neue Version und kein Release erstellt.

Diese rein transportbezogene Darstellung wurde nach der physischen Beobachtung
überarbeitet, dass die drei nachgelagerten Anker-Ports trotz angeschlossener
USB-Geräte leer wirkten. PortGlance wertet jetzt die Thunderbolt-DROM-Eigenschaft
`USB Port Map` des Routers zusammen mit dem direkten IOUSB-Elternhubpfad aus.
Ein USB-Gerät wird einem externen Mehrprotokoll-Port nur zugeordnet, wenn das
Dock selbst an einem bekannten Hostport hängt, ein Tunnelhinweis vorliegt, die
DROM-Map den Anschluss mit dem beobachteten Begleithub-Port verbindet und genau
ein Gerät passt. Nativer Thunderbolt-Transport hat Vorrang; jeder mehrdeutige
Fall bleibt unzugeordnet. Die lokale Prüfung am M4-Pro-Mac-mini ordnete Maono
Wireless Mic RX, ASM1352R-Fast und Loupedeck Live S den Anker-Ports 1, 2 und 3
mit den tatsächlichen USB-Protokollen und Geschwindigkeiten zu. Der YubiKey
blieb in der umbenannten Gruppe **Weitere USB-Geräte**, weil der vordere
USB-A-Port des Docks laut DROM-Map nur USB unterstützt. Zugeordnete USB-Geräte
verschwinden aus dieser Restliste, ohne den Gesamtzähler zu verändern. Bei
Intel-Docks ohne native Hostportbeziehung, darunter die beobachtete TS3-Plus-
Topologie, wird bewusst nichts geraten und die bisherige Darstellung bleibt
erhalten. Unit-Tests decken Anker-Map, reine USB-Buchse, Thunderbolt-Vorrang,
Mehrdeutigkeitsabbruch und Intel-Absicherung ab. Die vollständige lokale
Prüfung, der Universal-Build, der Starttest und die Sichtprüfung waren
erfolgreich. Apple akzeptierte die eigenständige Test-App unter der
Einreichungs-ID `dcbd88ba-1d31-4c72-ab60-29048bdc8c94`; ihr Ticket wurde vor
dem Erzeugen von `PortGlance-Port-Assignment-Test-2026-08-31-v6.zip` gestapelt.
Das ZIP hat den SHA-256
`57b6604901423dfda9c044e5cc23f9e654ddc8abfc206a6c46b4686462aefaa8`. Die
daraus erneut entpackte App bestand die strenge Signatur-, physische Ticket-,
Gatekeeper- und Architekturprüfung. Es wurde keine neue Version und kein
Release erstellt.

Die physische Intel-/T2-Prüfung dieses v6-Artefakts war ebenfalls erfolgreich,
zeigte aber eine verbleibende Mehrdeutigkeit am Hostanschluss: Ein direkt
angeschlossenes 100-W-USB-C-Netzteil erschien korrekt in der Zeile zur
Stromversorgung, während sein belegter Thunderbolt-Port **Frei** meldete, weil
eine reine USB-C-PD-Verbindung kein USB- oder Thunderbolt-Datengerät erzeugt.
Registry-Aufnahmen beim Umstecken von Port 2 auf Port 1 belegen eine
konservative, modellspezifische Zuordnung aus `PortControllerInfo`,
`AppleHPMDevice` sowie den geordneten `Socket ID`-Einträgen der
Thunderbolt-Root-Router. PortGlance kennzeichnet damit einen ansonsten leeren,
eindeutig zugeordneten Anschluss als **Port N · Stromversorgung** und zeigt die
Netzteilleistung an. Bei unvollständigen, widersprüchlichen oder mehrdeutigen
Daten wird keine Zuordnung behauptet; bestehende USB- und native
Thunderbolt-Belegungen haben stets Vorrang. Fünf fokussierte Resolver-Tests
decken beide Controllerseiten und die Abbruchfälle ab; alle 58 Tests, die
statische Analyse und der Universal-Build waren erfolgreich. Apple akzeptierte
die eigenständige Test-App unter der Einreichungs-ID
`b98bddbc-253f-4f07-b05a-84d8018957a3`; ihr Ticket wurde vor dem Erzeugen von
`PortGlance-Power-Port-Test-2026-08-31-v7.zip` gestapelt. Das ZIP hat den
SHA-256 `f0e33d36da497c7cce5aa04b402da601f469d454990d9ff319a755f52355decf`.
Die daraus erneut entpackte App bestand die strenge Signatur-, physische
Ticket-, Gatekeeper- und Architekturprüfung. Die anschließende physische
Intel-/T2-Prüfung genau dieses v7-Artefakts erkannte das 100-W-Netzteil an
jedem der vier Hostanschlüsse und entfernte die vorherige Zuordnung nach jedem
Umstecken. TS3 Plus und TDAS blieben beim gleichzeitigen Bereitstellen von
Strom als Datenbelegung sichtbar; USB-, Thunderbolt- und Dock-Belegungen haben
damit bestätigt Vorrang vor der Kennzeichnung für reine Stromversorgung. Es
wurde keine neue Produktversion und kein öffentlicher Release erstellt.

Eine anschließende physische Prüfung auf einem Intel-/T2-MacBook bestätigte,
dass dessen acht integrierte USB-Funktionen direkt unter
`AppleUSBVHCIBCE` hängen; ein dazwischenliegendes USB-Hub-Gerät der Klasse 9
wird nicht bereitgestellt. PortGlance zeigt auf diesem Mac daher trotz der
notwendigen Root-Port-Funktion der Hostcontroller korrekt null USB-Hubs an. Für
eine verständlichere Darstellung ohne erratene Hardwareidentitäten heißt die
Gruppe nun Interne USB-Komponenten; ein roher Registry-Ersatzname
`IOUSBHostDevice` beziehungsweise `IOUSBDevice` erscheint als Unbenannte
interne USB-Komponente. Beim Kopieren der Gerätedetails bleibt der ursprüngliche
Registry-Name erhalten.

Die optionale Zeile zur Stromversorgung verbindet den Akkustand nun mit der
aktuellen Ladeleistung und der Leistung des angeschlossenen Netzteils, sofern
macOS diese Werte bereitstellt. Die tatsächliche Batterieladeleistung wird aus
den öffentlichen IOPowerSources-Werten für Strom und Spannung berechnet; die
Netzteil-Nennleistung stammt aus `IOPSCopyExternalPowerAdapterDetails`. Bei
aktivierter Funktion werden die Werte alle fünf Sekunden aktualisiert. Fehlende
Angaben werden nicht geschätzt, und einen Marketingnamen oder Hersteller des
Netzteils stellt diese API nicht verlässlich bereit. Die vollständige lokale
Prüfung, der Universal-Build und der Starttest waren erfolgreich. Apple
akzeptierte die eigenständige Test-App unter der Einreichungs-ID
`aa29ea83-811c-4cdb-b240-a8bcc29e3d2f`; ihr Ticket wurde vor dem Erzeugen des
finalen Universal-ZIP gestapelt und die daraus erneut entpackte App anschließend
unabhängig geprüft. Das Test-ZIP
`PortGlance-MacBook-Test-2026-08-31.zip` hat den SHA-256
`b04b11a273e1124ced9468042eb118e7b43fbd3990a8929b9c359d1ae12b0c6c`.
Die physische Intel-Prüfung dieses Artefakts bestätigte 87 W über ein CalDigit
TS3 Plus Dock und ein separates 100-W-Netzteil bei vollem Akku. Die Zeile
blendete bei 100 % korrekt keine aktuelle Ladeleistung ein; deren physische
Prüfung blieb deshalb offen, bis der Akku wieder unterhalb seiner Ladeschwelle
lag. Eine spätere Prüfung bei 86 % bestätigte aktives Laden, zeigte aber
weiterhin keine Ladeleistung: In der IOPowerSources-Beschreibung des Intel-/T2-
MacBooks fehlte der öffentliche Wert `Current`. Die bereits erfassten
`AppleSmartBattery`-Eigenschaften stellten dagegen `InstantAmperage = 997 mA`
und `Voltage = 12618 mV` bereit, entsprechend rund 12,6 W tatsächlicher
Batterieladeleistung. PortGlance bevorzugt weiterhin die öffentlichen Strom-
und Spannungswerte und verwendet nur dann einen positiven
`InstantAmperage`-Wert zusammen mit der Batteriespannung, wenn diese Berechnung
nicht möglich ist. Der gemittelte Wert `Amperage` wird nur berücksichtigt, wenn
das momentane Feld selbst fehlt. Null, negative oder unvollständige Werte
erzeugen keine Wattangabe; der Soll-Ladestrom des Netzteils wird nie als
tatsächliche Messung ausgegeben. Sechs zusätzliche Tests decken diese
Priorität und die Abbruchfälle ab; alle 64 Tests, die statische Analyse, der
Universal-Build und der Starttest waren erfolgreich. Apple akzeptierte die
eigenständige Test-App unter der Einreichungs-ID
`14534bdd-6ca2-4521-8d71-7c9b7dfb51e7`; ihr Ticket wurde vor dem Erzeugen von
`PortGlance-Charging-Power-Test-2026-08-31-v8.zip` gestapelt. Das ZIP hat den
SHA-256 `83b05e6580c33705067a7b6c6758b638c98a97c17a96600666b2caff5625048a`.
Die daraus erneut entpackte App bestand die strenge Signatur-, physische
Ticket-, Gatekeeper- und Architekturprüfung. Die physische Intel-/T2-Abnahme
genau dieses v8-Artefakts zeigte anschließend bei 79 % **Lädt mit 10 W ·
100-W-Netzteil** und bei 80 % **Lädt mit 41 W · 100-W-Netzteil**, während der
rein zur Stromversorgung belegte Anschluss weiter Port 2 zugeordnet blieb. Der
wechselnde Wert bestätigt, dass die Aktualisierung im Fünf-Sekunden-Takt die
aktuelle batterieseitige Ladeleistung und nicht die Netzteilkapazität anzeigt.
In diesem Testschritt wurde noch keine neue Produktversion und kein öffentlicher
Release erstellt. Das Dock,
sein nachgelagerter Thunderbolt-Port, fünf USB-Funktionen und
zwei USB-Hub-Funktionen wurden erkannt. Beide Dock-Hubs erschienen zunächst
unter Direkt angeschlossene USB-Hubs, weil die Busnummern von Intel
`AppleUSBXHCITR` nicht den physischen Thunderbolt-Hostrouter bezeichnen. Eine
zweite physische Prüfung zeigte, dass auch der v2-Versuch beide Hubs in dieser
Gruppe beließ: Auf diesem Intel-Mac ist der getunnelte Controller in der durch
`ioreg -p IOUSB` dargestellten IOUSB-Registry-Ebene sichtbar, aber nicht in der
von v2 geprüften IOService-Elternkette. Die Erkennung verfolgt beide Ebenen nun
getrennt und wertet zusätzlich die direkte Eigenschaft `UsbTunnel` aus, falls
macOS sie bereitstellt. Die physische Prüfung zeigte, dass auch v3 beide Hubs in
der direkten Gruppe beließ, während die unveränderte Zuordnung auf dem
M4-Pro-Mac-mini weiterhin funktionierte. Der verbleibende Intel-Unterschied ist,
dass der CalDigit-Thunderbolt-Router vorhanden ist, ohne im Host-Port-Modell
angehängt zu sein. Der abschließende v4-Rückfall löst deshalb einen ausdrücklich
getunnelten Hub auch gegen die erkannten nativen Thunderbolt-Geräte auf. Für
einen generischen `IOUSBHostDevice`-Hub ohne dieses Signal verlangt er genau ein
natives Thunderbolt-Gerät sowie eine USB-Funktion desselben Controllers, deren
Hersteller zum Thunderbolt-Gerät passt; andernfalls bleibt der Hub direkt oder
unbekannt. Die Ableitung bleibt damit auf die beobachtete Intel-Topologie
beschränkt, statt jeden unaufgelösten Hub zuzuordnen. Regressionstests decken
den Vorrang der expliziten Abstammung, getunnelten Besitz, den
Herstellerabgleich auf demselben Controller und die Absicherung ohne Treffer ab.
Die vollständige Prüfung und der Universal-Starttest waren erfolgreich. Apple
akzeptierte die abschließende v4-Test-App unter der Einreichungs-ID
`7f1d2fd1-4f82-48d2-928a-ea145bd51da0`; ihr Ticket wurde vor dem Erzeugen von
`PortGlance-MacBook-Hub-Test-2026-08-31-v4.zip` gestapelt. Das ZIP hat den
SHA-256 `fb4a4b407ef35b7dbe8242f4dedf8da7b7f8c740c766ecb5c1e5ea4a92717bfc`. Die
daraus erneut entpackte App bestand die strenge Signatur-, physische Ticket-,
Gatekeeper- und Architekturprüfung. Die physische v4-Prüfung ordnete den
480-Mbit/s-Hub anhand des eng begrenzten Herstellerhinweises dem CalDigit TS3
Plus zu; der generische 12-Mbit/s-Hub blieb in der direkten Gruppe. Dieses
Teilergebnis bestätigt, dass macOS für den zweiten Hub nicht genügend
Besitzinformationen bereitstellt. Die v5-Darstellung trennt diese Unklarheit
nun von den bestehenden direkten Fällen: normal benannte Hubs und generische Hubs
ohne native Thunderbolt-Topologie bleiben unter Direkt angeschlossene
USB-Hubs; ein generischer, nicht auflösbarer Registry-Eintrag bei vorhandenen
nativen Thunderbolt-Geräten erscheint unter USB-Hubs mit unbekannter Zuordnung.
Bestehende interne und Thunderbolt-Zuordnungen bleiben unverändert.
Regressionstests decken alle vier Ergebnisse ab. Apple akzeptierte die
v5-Test-App unter der Einreichungs-ID
`4b1b1153-f924-4002-84c2-6b3f3570de78`; ihr Ticket wurde vor dem Erzeugen von
`PortGlance-MacBook-Hub-Test-2026-08-31-v5.zip` gestapelt. Das ZIP hat den
SHA-256 `594b615d24a61cc328b8fd01180d42ced5f628ae7d7fcee891f975ea3a480132`. Die
daraus erneut entpackte App bestand die strenge Signatur-, physische Ticket-,
Gatekeeper- und Architekturprüfung. Die physische Intel-Prüfung genau dieses
v5-Artefakts bestätigte die beabsichtigte endgültige Darstellung: Der
480-Mbit/s-Hub blieb unter CalDigit, Inc. TS3 Plus und der nicht auflösbare
12-Mbit/s-Hub erschien unter USB-Hubs mit unbekannter Zuordnung. Es wurde weder
eine neue Produktversion noch ein öffentlicher Release erstellt.

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

Version 0.4.0 bündelt die Intel-/T2-MacBook-Arbeiten, die konservative
USB-Zuordnung zu Besitzern und nachgelagerten Ports, die Belegung eines
USB-C-Ports allein durch Stromversorgung und die aktuelle Batterieladeleistung
in einem Funktionsrelease. Native Thunderbolt-Belegungen und die Semantik der
Gerätezähler bleiben erhalten; mehrdeutige Zuordnungen werden nicht behauptet
und alle Hardwaredaten bleiben lokal. Er wurde am 31.08.2026 als signierter,
notarisierter und gestapelter Universal-Release
[`v0.4.0`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.4.0) aus dem
Merge-Commit `89c9d18546f27c197a796676a5487dbc9fb35c22` veröffentlicht. Apple
akzeptierte die getrennt eingereichte App
(`628f94de-7781-47ca-8a48-fdb49f47748b`) und das DMG
(`cc9d6127-78e6-4c9a-bc54-259f4eda8c62`). Das öffentliche Artefakt
`PortGlance-0.4.0-mac.dmg` hat den SHA-256
`5bdd2287ce002c9ac1a825ae987bd2a16cdaf9e8aa5daf350e7adc34c2678196`, passend
zum von GitHub gemeldeten Digest. Ein frischer GitHub-Download bestand die
unabhängige Release-Prüfung einschließlich der physisch gestapelten App im
eingebundenen DMG. Alle 64 Tests, die statische Analyse, der Universal-Build,
der lokale Starttest und beide nativen Pull-Request-CI-Jobs waren erfolgreich.
Die physische Abnahme umfasste die Topologie am M4-Pro-Mac-mini sowie auf dem
Intel-/T2-MacBook die internen Komponenten, die CalDigit-Hub-Zuordnung, den
Fallback für unbekannte Hubs, alle vier rein zur Stromversorgung belegten
Host-Ports, den Vorrang der Datenbelegung bei TS3 Plus und TDAS und die
dynamischen Messwerte von 10 W bis 41 W mit einem 100-W-Netzteil.

Version 0.3.0 bündelt die Metadaten der Gerätezeilen und die neue
USB-/Thunderbolt-Topologie in einem Funktionsrelease. Er wurde am 31.08.2026 als
signierter, notarisierter und gestapelter Universal-Release
[`v0.3.0`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.3.0) aus dem
Merge-Commit `323c25a5d7ac8cc00400681547eafa51e26a40b4` veröffentlicht. Apple
akzeptierte die getrennt eingereichte App
(`2d0460f3-5228-4cd1-97d2-9370cba3b541`) und das DMG
(`99669732-8ee5-490e-9b0d-231d662e452d`). Das öffentliche Artefakt
`PortGlance-0.3.0-mac.dmg` hat den SHA-256
`2a1fee426174beb54c9a91c7c233a137187ca5f209d5196f9f2cee849d2013ed`, der mit
GitHubs gemeldetem Digest übereinstimmt; ein frischer GitHub-Download bestand
die unabhängige Release-Prüfung einschließlich der physisch gestapelten App im
eingebundenen DMG. Die vollständige automatische Prüfkette, beide nativen
GitHub-CI-Jobs, die statische Analyse, der Universal-Build, der lokale Starttest
und die Sichtprüfung des Benutzers waren erfolgreich. Die physische Abnahme am
M4-Pro-Mac-mini umfasste die dokumentierten Hostanschlüsse, angeschlossenen
Geräte, Hub-Zuordnung und eine laufende Anschlussänderung. Die physische
Intel-Prüfung der neuen Topologie wird später mit dem veröffentlichten
GitHub-Artefakt von v0.3.0 nachgeholt; dieser Release beansprucht keine physische
Intel-Hardwareabnahme für die neue Topologie.

Version 0.2.1 fasst diese Minimalisierung der Einstellungen, die neue
Darstellungswahl und die Bereinigung in einem Wartungsrelease zusammen. Die
Dienste zur Geräteerkennung, die Hardwareklassifizierung und das
Datenschutzmodell bleiben unverändert. Die vollständige automatische
Prüfkette, der Universal-Build, der lokale Starttest und die Sichtprüfung des
Benutzers waren erfolgreich.
Der signierte, notarisierte und gestapelte Universal-Release wurde am
31.08.2026 als
[`v0.2.1`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.2.1) aus
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
Repository ist `r3d42-git/MenuBarIO`; `upstream` bleibt die schreibgeschützte
Quellreferenz auf `rafaelSwi/MenuBarUSB`. Das Rebranding wurde als signierter,
notarisierter und gestapelter Universal-Release
[`v0.2.0`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.2.0)
veröffentlicht. Das Release-Artefakt `PortGlance-0.2.0-mac.dmg` hat den SHA-256
`c79e5a61dca6e6a160df23a8a2361f29121ce71ae402e4ecae9a131a55847709`; der
öffentlich heruntergeladene Stand bestand die unabhängige Release-Prüfung.

Version 0.6.0 behält macOS 13 als einheitliches Deployment Target für Projekt,
App und Tests bei und erhält beide
Universal-Architekturen sowie das separate Einstellungsfenster für Ventura und
Sonoma. Eine zentrale Lebenszyklus-Koordination aktualisiert USB/Thunderbolt,
Bluetooth, Stromversorgung und Ethernet gemeinsam aus der Fußzeile sowie nach
dem Aufwachen oder Aktivieren einer Sitzung; unmittelbar aufeinanderfolgende
Lebenszyklusereignisse werden zusammengeführt. Die Erkennung unterscheidet nun
zwischen bereit, wird aktualisiert, möglicherweise veraltet und nicht
verfügbar: Eine fehlgeschlagene Aktualisierung erhält den letzten vollständigen
USB-/Thunderbolt- oder Bluetooth-Stand, ein gültiges leeres Ergebnis bleibt bei
null Geräten und ein ausgeschalteter Bluetooth-Controller wird ausdrücklich
benannt. Aus der Fußzeile lässt sich über den nativen Speicherdialog ein
strukturierter Markdown-Bericht in der sichtbaren Gruppenreihenfolge
exportieren, ohne Seriennummern, Bluetooth-Adressen, Location-IDs, stabile
interne IDs, Benutzernamen oder Pfade. Der Sandbox-Zugriff ist auf die vom
Benutzer ausdrücklich gewählte Datei beschränkt und wird nicht gespeichert.
Die detaillierte USB-Einzelkopie bleibt unverändert; Bluetooth-Zeilen und
Thunderbolt-Port-Zeilen besitzen eigene ausdrückliche Kontextmenü-Kopien. Die
automatische Prüfung umfasst 76 Tests, die statische Analyse, den Audit des
macOS-13-Deployment-Targets und beide Universal-Slices. Die integrierten
Einstellungen und der Markdown-Speicherdialog wurden unter macOS 26 geprüft.
Die ausdrücklich genehmigte Release-Ausnahme hält fest, dass der Starttest der
klassischen Einstellungen unter macOS 13/14 sowie die neuen physischen
Aktualisierungs-, Sleep/Wake- und Fehlerzustandsfälle auf Apple Silicon und dem
unterstützten Intel-/T2-Mac für diesen Release nicht wiederholt wurden. Er
wurde am 01.09.2026 als signierter, notarisierter und gestapelter
Universal-Release
[`v0.6.0`](https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.6.0) aus dem
gemergten Pull Request
[`#22`](https://github.com/r3d42-git/MenuBarIO/pull/22) und dem Merge-Commit
`6c2f10b63f5de12be6e1a7fb866b60530a6457db` veröffentlicht. Apple akzeptierte
die separat eingereichte App unter `df885c77-14e4-44cc-b931-59d120f670a7` und
das DMG unter `6d72c7ac-dddd-41f3-8e34-72baa5416431`. Das öffentliche
`MenuBarIO-0.6.0-mac.dmg` ist 2.984.052 Bytes groß und hat den SHA-256
`8ffbced9b240d2d3cfd39d689322971e3b12ff80761c81df15b966f7f08ba84c`,
passend zu GitHubs Asset-Digest. Beide nativen Jobs waren sowohl im
Pull-Request-CI-Lauf
[`33509359572`](https://github.com/r3d42-git/MenuBarIO/actions/runs/33509359572)
als auch im `main`-CI-Lauf
[`33509796189`](https://github.com/r3d42-git/MenuBarIO/actions/runs/33509796189)
erfolgreich; auch der Pages-Build und die Prüfung der öffentlichen Routen waren
im Lauf
[`33509796257`](https://github.com/r3d42-git/MenuBarIO/actions/runs/33509796257)
erfolgreich. Ein frischer GitHub-Download bestand die Prüfung von Prüfsumme,
DMG-Integrität, Gatekeeper, beiden Staple-Tickets, Signatur, Version/Build und
Universal-Slices der enthaltenen App sowie des Installer-Layouts.

## Codestruktur

- `MenuBarIO/MenuBarIOApp.swift` registriert Standardwerte, führt die
  einmalige Altdatenmigration aus und setzt die App-Szenen zusammen.
- `MenuBarIO/Services/` enthält Systemadapter und Lebenszykluscode für
  IOKit-Erkennung, Anschlussmeldungen, Stromquellen, Ethernet-Status,
  Anmeldeobjekt-Status und Altdatenmigration.
- `MenuBarIO/Structs/` und `MenuBarIO/Enums/` enthalten stabile
  Gerätemodelle, Gruppierungsregeln und Einstellungstypen.
- `MenuBarIO/Support/` enthält zustandslose Formatierungs- und
  Systemaktions-Helfer.
- `MenuBarIO/Views/` enthält kleine Menüleisten-, Listen-, Zeilen- und
  Einstellungskomponenten. Aktuelle und klassische Einstellungen verwenden
  dieselben Bedienelemente.
- `MenuBarIOTests/` bildet die Modell-, Service- und Migrationsgrenzen in
  gezielten Testdateien ab.
- `branding/MenuBarIO-AppIcon-master.png` ist die hochauflösende generierte
  Icon-Vorlage. Die abgeleiteten macOS-Größen liegen in
  `MenuBarIO/Assets.xcassets/AppIcon.appiconset/`. Kategorien und Status in
  der App verwenden SF Symbols.
- `website/` enthält den zweisprachigen statischen Projektverlauf, seine
  lokal eingebundenen Assets und die GitHub-Pages-Prüfungen.

USB- und Thunderbolt-Identitäten müssen über Aktualisierungen hinweg stabil
bleiben. Interne Geräte und USB-Hubs zählen nicht zum Zähler externer Geräte.
Thunderbolt-Geräte bleiben Teil dieses Zählers, werden aber nur in der Gruppe
der physischen Ports und nicht unter Weitere USB-Geräte dargestellt. Sicher
zugeordnete USB-Geräte bleiben ebenfalls gezählt, erscheinen aber am externen
Mehrprotokoll-Port statt in dieser Restliste. Bluetooth-Geräte werden getrennt
gezählt. Die sichtbare Gruppenreihenfolge lautet Thunderbolt-/USB4-Hostports,
externe Thunderbolt-/USB4-Ports, Weitere USB-Geräte, Bluetooth-Geräte, interne
Geräte und USB-Hubs.

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

Änderungen am Projektverlauf werden in `website/` auf Deutsch und Englisch
gemeinsam gepflegt. Vor einem Pull Request sind dort Installation, Lint,
TypeScript-Prüfung, Produktions-Build und Artefaktprüfung auszuführen; nach
dem Merge veröffentlicht der separate Pages-Workflow ausschließlich den
statischen Build.
