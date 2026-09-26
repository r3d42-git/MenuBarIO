# Security policy

## Reporting a vulnerability

Please report suspected vulnerabilities confidentially through
[GitHub private vulnerability reporting](https://github.com/r3d42-git/MenuBarIO/security/advisories/new).
Do not include security-sensitive details in public issues. Include the affected
version, macOS version, reproduction steps and expected impact. Remove credentials,
serial numbers, Bluetooth addresses and other personal data from attachments.

## Supported versions

Security fixes target the latest stable MenuBarIO release (currently 0.8.x,
Apple Silicon, macOS 15+). Version 0.7.2 is the last regular release for Intel
and macOS 13/14; critical fixes may be considered individually, without a
commitment to ongoing maintenance. Older versions are not maintained.

## Scope

Reports may concern the macOS app, its build and release scripts, GitHub Actions,
or the project website. MenuBarIO processes local device information; it has no
telemetry, analytics, automatic update checks or network client code. This does
not make local device input inherently trustworthy. Signing and notarization
credentials stay outside pull-request CI.

---

# Sicherheitsrichtlinie

## Eine Schwachstelle melden

Bitte melde vermutete Schwachstellen vertraulich über
[GitHubs private Sicherheitsmeldungen](https://github.com/r3d42-git/MenuBarIO/security/advisories/new).
Veröffentliche sicherheitskritische Einzelheiten nicht in öffentlichen Issues.
Nenne die betroffene Version, macOS-Version, Schritte zur Reproduktion und die
vermuteten Auswirkungen. Entferne Zugangsdaten, Seriennummern, Bluetooth-Adressen
und andere persönliche Daten aus Anhängen.

## Unterstützte Versionen

Sicherheitskorrekturen erfolgen für die aktuelle stabile MenuBarIO-Version
(derzeit 0.8.x, Apple Silicon, macOS 15+). Version 0.7.2 ist die letzte reguläre
Version für Intel und macOS 13/14. Kritische Korrekturen können im Einzelfall
geprüft werden; eine laufende Wartung wird nicht zugesagt. Ältere Versionen
werden nicht gepflegt.

## Geltungsbereich

Meldungen können die macOS-App, Build- und Release-Skripte, GitHub Actions oder
die Projektwebsite betreffen. MenuBarIO verarbeitet lokale Geräteinformationen;
es enthält keine Telemetrie, Analyseübertragung, automatischen Update-Abfragen
oder Netzwerk-Client-Code. Lokale Gerätedaten sind deshalb nicht automatisch
vertrauenswürdig. Signierungs- und Notarisierungszugangsdaten bleiben außerhalb
der Pull-Request-CI.
