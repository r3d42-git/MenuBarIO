# Differences from MenuBarUSB

PortGlance is based on the publicly available
[`rafaelSwi/MenuBarUSB`](https://github.com/rafaelSwi/MenuBarUSB) project under
the MIT License. This document records deliberate, product-relevant changes
for future upstream comparisons. The original idea and source authorship remain
credited, but PortGlance is not an official successor to MenuBarUSB, an official
continuation of it or a version endorsed by its original author. The original
author is not involved in PortGlance development, maintenance, support or
releases. GitHub contributor entries for upstream author accounts reflect only
the preserved source history, not a current collaboration or affiliation.

- Product name and release channel are independent. The legacy bundle
  identifier `de.r3d.menubarusb.tb` is retained only so existing installations
  keep their preferences and login-item identity.
- The original custom app icon and seven custom in-app icon sets were removed.
  PortGlance has its own app icon; in-app category and Ethernet indicators use
  native SF Symbols.
- Thunderbolt and USB4 devices are discovered alongside USB through IOKit;
  link speed, transport and USB4 version are displayed.
- The list separates devices from pure USB hubs and permits both groups to be
  collapsed and expanded.
- Connection and device identity, IOKit ownership, Ethernet monitoring and UI
  threading have been hardened; unit tests, analysis and CI were added.
- Hardware sounds, including all MP3 resources, their import, assignment and
  legacy-value cleanup, have been removed.
- Donation, cryptocurrency and related hiding features have been removed.
- The link and image assets for the upstream-only analysis tool have been
  removed because this fork has no compatible companion of its own.
- Tested local initial values have been set as product-wide defaults. Telemetry,
  update checks and device web search are removed; the privacy audit permits no
  network client code.
- The experimental Ethernet traffic monitor – including byte counters, timer,
  pause/start controls and blinking icon – has been removed. The local
  indicator of a connected LAN cable remains.
- Signing, notarization and release verification use the project-specific
  scripts in `script/`, including a fresh download and a repeat verification of
  the published DMG.

The complete technical difference remains traceable through Git against the
`upstream` remote.

---

# Abweichungen zu MenuBarUSB

PortGlance basiert auf dem öffentlich verfügbaren Projekt
[`rafaelSwi/MenuBarUSB`](https://github.com/rafaelSwi/MenuBarUSB) unter der
MIT-Lizenz. Dieses Dokument hält bewusst eingebrachte, produktrelevante
Abweichungen für spätere Upstream-Vergleiche fest. Die ursprüngliche Idee und
Urheberschaft am Ausgangscode werden ausdrücklich genannt; PortGlance ist
jedoch weder offizieller Nachfolger noch offizielle Fortführung von MenuBarUSB
und auch keine vom ursprünglichen Autor bestätigte Variante. Der ursprüngliche
Autor ist an Entwicklung, Pflege, Support und Releases von PortGlance nicht
beteiligt. Seine GitHub-Contributor-Einträge bilden ausschließlich die
erhaltene Quellcodehistorie ab, nicht eine aktuelle Zusammenarbeit oder
Zugehörigkeit.

- Produktname und Release-Kanal sind unabhängig. Der bisherige
  Bundle-Identifier `de.r3d.menubarusb.tb` bleibt ausschließlich erhalten,
  damit bestehende Installationen ihre Einstellungen und die Identität des
  Anmeldeobjekts behalten.
- Das ursprüngliche eigene App-Icon und sieben eigene Icon-Sets innerhalb der
  App wurden entfernt. PortGlance besitzt ein neues App-Icon; Kategorien und
  Ethernet-Anzeige verwenden native SF Symbols.
- Thunderbolt- und USB4-Geräte werden neben USB per IOKit erfasst; Link-Speed,
  Transport und USB4-Version werden angezeigt.
- Die Liste trennt Geräte von reinen USB-Hubs und erlaubt das Ein- und
  Ausklappen beider Gruppen.
- Verbindungs- und Geräteidentität, IOKit-Ownership, Ethernet-Monitoring und
  UI-Threading wurden gehärtet; Unit-Tests, Analyse und CI wurden ergänzt.
- Hardware-Sounds einschließlich aller MP3-Ressourcen, Import, Zuordnung und
  Altwertbereinigung wurden entfernt.
- Spenden-, Kryptowährungs- und zugehörige Ausblendfunktionen wurden entfernt.
- Die Verknüpfung und Bildressourcen für das reine Upstream-Analysewerkzeug
  wurden entfernt, weil diese Variante keinen eigenen kompatiblen Begleiter hat.
- Die geprüften lokalen Startwerte wurden als produktweite Defaults festgelegt.
  Telemetrie, Update-Abfragen und Websuchen für Geräte sind entfernt; der
  Datenschutz-Audit erlaubt keinen Netzwerk-Client-Code.
- Die experimentelle Ethernet-Verkehrsüberwachung einschließlich Byte-Zähler,
  Timer, Pause/Start-Bedienung und Blink-Symbol wurde entfernt. Die lokale
  Anzeige eines verbundenen LAN-Kabels bleibt erhalten.
- Signierungs-/Notarisierungs- und Release-Verifikation erfolgt über die
  projektspezifischen Skripte in `script/`, einschließlich frischem Download
  und erneuter Prüfung des veröffentlichten DMG.

Die vollständige technische Differenz bleibt über Git gegenüber dem Remote
`upstream` nachvollziehbar.
