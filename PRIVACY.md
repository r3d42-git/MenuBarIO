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
