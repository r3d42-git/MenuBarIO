# Privacy and network access

MenuBarUSB-TB has no telemetry, analytics SDKs, crash reporters, accounts,
server API or background network access. It does not transmit device, usage or
settings data.

## Local data

The app reads USB, Thunderbolt and Ethernet metadata through macOS system APIs
and stores settings, custom device names and – only when explicitly enabled –
connection logs exclusively in the user's local profile. Connection logs are
disabled by default. The Ethernet indicator processes only the local link
status; it does not inspect packets, destinations or traffic data.

## Explicitly user-triggered access

The app connects only after a clear user action:

- **“Check for Updates”** downloads this project's public GitHub Releases
  response. The source code sends no device or usage data. As with every HTTPS
  connection, GitHub receives technical transport metadata such as the IP
  address.
- Searching for a device opens the selected search engine in the default
  browser and sends the search term chosen by the user to that website.
- Links to the repository or release page open in the default browser.

There is no automatic update check at app launch. The `script/privacy_audit.sh`
script enforces these boundaries in local verification and GitHub Actions.

---

# Datenschutz und Netzwerkzugriffe

MenuBarUSB-TB hat keine Telemetrie, Analyse-SDKs, Crash-Reporter, Konten,
Server-API oder Hintergrundnetzwerkzugriffe. Es übermittelt keine Geräte-,
Nutzungs- oder Einstellungsdaten.

## Lokale Daten

Die App liest USB-, Thunderbolt- und Ethernet-Metadaten über macOS-System-APIs
und speichert Einstellungen, eigene Gerätenamen und – falls ausdrücklich
aktiviert – Verbindungsprotokolle ausschließlich lokal im Benutzerprofil.
Verbindungsprotokolle sind standardmäßig deaktiviert. Die Ethernet-Anzeige
verarbeitet ausschließlich den lokalen Link-Status; sie untersucht keine
Pakete, Ziele oder Verkehrsdaten.

## Ausdrücklich vom Nutzer ausgelöste Zugriffe

Die App stellt nur nach einer eindeutigen Nutzeraktion eine Verbindung her:

- **„Suche nach Updates“** lädt die öffentliche GitHub-Releases-Antwort dieses
  Projekts. Der Quellcode übermittelt dabei keine Geräte- oder Nutzungsdaten.
  Wie bei jeder HTTPS-Verbindung erhält GitHub jedoch technische
  Transportmetadaten wie die IP-Adresse.
- Eine Suche nach einem Gerät öffnet die ausgewählte Suchmaschine im
  Standardbrowser und übergibt den vom Nutzer gewählten Suchbegriff an diese
  Website.
- Links zu Repository oder Release-Seite werden im Standardbrowser geöffnet.

Es gibt keine automatische Update-Suche beim App-Start. Das Skript
`script/privacy_audit.sh` erzwingt diese Grenzen in der lokalen Prüfung und
in GitHub Actions.
