# Privacy and network access

MenuBarIO has no telemetry, analytics SDKs, crash reporters, accounts,
server API or background network access. It does not transmit device, usage or
settings data.

## Local data

The app reads USB, Thunderbolt and Ethernet metadata through macOS system APIs
and stores settings exclusively in the user's local profile. The Ethernet
indicator processes only the local link status; it does not inspect packets,
destinations or traffic data.

When the user explicitly exports a hardware report, the app receives write
access only to the file selected in the native macOS save panel. It does not
retain access to that file or its containing folder. The Markdown report is
created locally and is not transmitted.

## Network access

The app itself makes no network connections. The `script/privacy_audit.sh`
script enforces this boundary in local verification and GitHub Actions.

---

# Datenschutz und Netzwerkzugriffe

MenuBarIO hat keine Telemetrie, Analyse-SDKs, Crash-Reporter, Konten,
Server-API oder Hintergrundnetzwerkzugriffe. Es übermittelt keine Geräte-,
Nutzungs- oder Einstellungsdaten.

## Lokale Daten

Die App liest USB-, Thunderbolt- und Ethernet-Metadaten über macOS-System-APIs
und speichert Einstellungen ausschließlich lokal im Benutzerprofil. Die
Ethernet-Anzeige verarbeitet ausschließlich den lokalen Link-Status; sie
untersucht keine Pakete, Ziele oder Verkehrsdaten.

Wenn der Benutzer ausdrücklich einen Hardwarebericht exportiert, erhält die
App ausschließlich Schreibzugriff auf die im nativen macOS-Speicherdialog
gewählte Datei. Sie behält keinen Zugriff auf diese Datei oder den
übergeordneten Ordner. Der Markdown-Bericht wird lokal erstellt und nicht
übertragen.

## Netzwerkzugriffe

Die App selbst baut keine Netzwerkverbindungen auf. Das Skript
`script/privacy_audit.sh` erzwingt diese Grenze in der lokalen Prüfung und
in GitHub Actions.
