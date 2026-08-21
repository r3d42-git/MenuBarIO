# Tests

## Schnellprüfung vor jedem Commit

```bash
./script/verify.sh
```

Der Befehl verwendet ein isoliertes DerivedData-Verzeichnis und führt aus:

- die Datenschutzprüfung: keine Telemetrie, keine automatische
  Update-Abfrage und nur die manuellen Update-Schaltflächen dürfen
  `URLSession` verwenden;
- die XCTest-Tests für Geräteidentität, Hub-Klassifizierung, Thunderbolt-Link-Geschwindigkeit, Billboard-Erkennung sowie die Bereinigung entfernter Funktionen;
- den Xcode Static Analyzer für die Release-Konfiguration.

Die Unit-Tests laufen bewusst ohne Debug-Signatur: Sie prüfen reine
Modell- und Datenlogik, und der unsignierte lokale Test-Host vermeidet einen
Gatekeeper-Dialog. Das signierte, notarisiert ausgelieferte Produkt wird davon
nicht berührt und wird im Release-Skript separat geprüft.

Zum reinen Starttest der App:

```bash
./script/build_and_run.sh --verify
```

Die gleichen Unit-Tests und die Analyse laufen in GitHub Actions bei Pull
Requests und bei jedem Push auf `main`.

## Hardware-Abnahme vor einem Release

Diese Fälle benötigen echte Hardware und können nicht sinnvoll in CI emuliert
werden. Nach jeder Änderung an der IOKit-Erkennung einmal prüfen:

1. Ein normales USB-Gerät und mindestens ein USB-Hub anschließen. Das Gerät
   muss unter **USB-Geräte**, der Hub unter **USB Hubs** erscheinen; der
   Zähler zählt nur Geräte.
2. Ein Thunderbolt-/USB4-Gerät (beispielsweise ein SSD-Gehäuse) anschließen.
   Name, Anbieter, Thunderbolt-/USB4-Version und die ausgehandelte
   Link-Geschwindigkeit müssen sichtbar sein.
3. Ein Thunderbolt-Dock mit USB-C-Billboard-Interface anschließen. Das Dock
   darf nur einmal als Thunderbolt-Gerät erscheinen, nicht zusätzlich als
   langsames USB-Interface.
4. Zwei baugleiche USB-Geräte ohne Seriennummer an unterschiedliche Ports
   anschließen. Beide müssen sichtbar bleiben und getrennte Einstellungen
   behalten.
5. Geräte jeweils ab- und wieder anstecken. Liste, Gruppenzähler, Log und
   Benachrichtigungen dürfen pro physischem Gerät nur einmal reagieren.
6. Falls die Ethernet-Anzeige aktiviert ist: Einstellung zweimal ein- und
   ausschalten. Das Kabelsymbol darf nur bei aktivem kabelgebundenem Link
   erscheinen und darf keine Netzwerkverbindung der App auslösen.

Für die signierte Auslieferung danach die vollständige Anleitung in
[`RELEASE.md`](RELEASE.md) befolgen.

## DMG-Layout-Abnahme

Nach Änderungen am Paketbau das erzeugte DMG im Finder öffnen. Es muss eine
kompakte Installationsansicht mit App, Pfeil und **Programme**-Alias zeigen.
Die App muss sich auf **Programme** ziehen lassen; `LICENSE` muss weiterhin
vorhanden sein. Der Release-Skript prüft Alias, Hintergrund und Lizenz zudem
automatisiert im frisch eingebundenen DMG.
