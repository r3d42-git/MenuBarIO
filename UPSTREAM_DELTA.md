# Abweichungen zu MenuBarUSB

MenuBarUSB-TB basiert auf dem öffentlich verfügbaren Projekt
[`rafaelSwi/MenuBarUSB`](https://github.com/rafaelSwi/MenuBarUSB) unter der
MIT-Lizenz. Dieses Dokument hält bewusst eingebrachte, produktrelevante
Abweichungen für spätere Upstream-Vergleiche fest.

- Produktidentität, Bundle-Identifier und Release-Kanal sind unabhängig:
  `MenuBarUSB-TB` / `de.r3d.menubarusb.tb`.
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
  Telemetrie und automatische Update-Abfragen sind entfernt; der Datenschutz-
  Audit begrenzt Netzwerkzugriffe auf ausdrücklich ausgelöste Aktionen.
- Die experimentelle Ethernet-Verkehrsüberwachung einschließlich Byte-Zähler,
  Timer, Pause/Start-Bedienung und Blink-Symbol wurde entfernt. Die lokale
  Anzeige eines verbundenen LAN-Kabels bleibt erhalten.
- Signierungs-/Notarisierungs- und Release-Verifikation erfolgt über die
  projektspezifischen Skripte in `script/`, einschließlich frischem Download
  und erneuter Prüfung des veröffentlichten DMG.

Die vollständige technische Differenz bleibt über Git gegenüber dem Remote
`upstream` nachvollziehbar.
