# Release

`script/release.sh` produces a Developer-ID-signed, notarized and stapled DMG
and its matching `.dmg.sha256` checksum. It verifies the app before packaging,
validates the notarized DMG, then mounts that exact DMG read-only and verifies
the enclosed app again. The delivered image opens as a small installer window:
the app can be dragged onto the visible **Programme** alias, which points to
`/Applications`. `LICENSE` and the installer background stay included in the
image and are verified during the release.

## DMG design rule

Every DMG release of this app uses the same direct installation pattern: app
icon on the left, **Programme** on the right, an arrow and short instruction
between them. Do not fall back to an unarranged Finder folder. The layout is
created only with macOS tools and source-controlled scripts; it does not add
network access or a third-party packaging dependency. Because Finder records
the window layout, create a DMG from an unlocked local macOS session with
Finder available; a headless release intentionally fails before packaging.

Before creating any release, run `./script/verify.sh` and complete the
hardware acceptance checks in [`TESTING.md`](TESTING.md). The script executes
the XCTest suite and the Xcode static analyzer in isolated DerivedData. The
same two checks run in GitHub Actions for pushes to `main` and pull requests;
that CI workflow deliberately has no signing or notary credentials.

The product identity is fixed as `MenuBarUSB-TB` with bundle identifier
`de.r3d.menubarusb.tb`. The project uses Developer Team `G6JH37W285` and the
local `notarytool` keychain profile `MenuBarUSB-TB-notary` by default. Before
the first release, ensure the corresponding Developer ID Application
certificate is available and create that profile interactively:

```bash
./script/store_notary_credentials.sh 'YOUR-APPLE-ID'
```

`notarytool` prompts for the app-specific password and stores it only in the
local Keychain. Generate that password at [account.apple.com](https://account.apple.com/)
under **Sign-In and Security → App-Specific Passwords**; do not put it in a
shell history, file, patch, or repository. Apple documents this credential
flow in its [notarization guide](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).

Run the release with only values appropriate to this fork:

```bash
MENUBARUSB_SIGNING_IDENTITY='Developer ID Application: Your Name (YOURTEAMID)' \
./script/release.sh 0.1.1
```

Version 0.1.1 is deliberately distributed for **Apple Silicon (`arm64`) only**
and requires macOS 13 or newer. Intel Macs are not supported by this release.
The release script verifies the requested executable slice. A future Universal
release requires explicit additional hardware acceptance on both architectures.

The release script aborts when uncommitted or nonignored untracked files exist,
runs the XCTest suite and static analysis, then verifies the signed app, the
notarized DMG, and the app inside that exact DMG. It does not upload anything.

After reviewing and pushing the release commit and its annotated `vVERSION`
tag, publish the DMG, its checksum and the versioned release notes. The script
then independently re-checks the exact GitHub download with:

```bash
./script/publish_release.sh 0.1.1
```

The update feed is configured for this public repository. It will become
usable after its first GitHub Release is published.

---

# Release – Deutsch

`script/release.sh` erzeugt ein mit Developer ID signiertes, notarisiertes und
gestapeltes DMG sowie die zugehörige Prüfsumme `.dmg.sha256`. Es prüft die App
vor dem Paketbau, validiert das notarisierte DMG, bindet dann genau dieses DMG
schreibgeschützt ein und prüft die enthaltene App erneut. Das ausgelieferte
Image öffnet sich als kleines Installationsfenster: Die App kann auf den
sichtbaren Alias **Programme** gezogen werden, der auf `/Applications` zeigt.
`LICENSE` und der Installationshintergrund bleiben im Image enthalten und
werden während des Release geprüft.

## Regel für das DMG-Design

Jedes DMG-Release dieser App verwendet dasselbe direkte Installationsmuster:
App-Symbol links, **Programme** rechts, dazwischen ein Pfeil und eine kurze
Anweisung. Nicht auf einen ungeordneten Finder-Ordner zurückfallen. Das Layout
wird ausschließlich mit macOS-Werkzeugen und versionsverwalteten Skripten
erstellt; es fügt weder Netzwerkzugriff noch eine Drittanbieter-Abhängigkeit
für den Paketbau hinzu. Weil Finder das Fensterlayout speichert, ein DMG aus
einer entsperrten lokalen macOS-Sitzung mit verfügbarem Finder erstellen; ein
kopfloser Release bricht bewusst vor dem Paketbau ab.

Vor jedem Release `./script/verify.sh` ausführen und die Hardware-Abnahme in
[`TESTING.md`](TESTING.md) abschließen. Das Skript führt die XCTest-Suite und
den Xcode Static Analyzer in isoliertem DerivedData aus. Dieselben beiden
Prüfungen laufen in GitHub Actions bei Pushes auf `main` und Pull Requests;
dieser CI-Ablauf enthält bewusst keine Signierungs- oder
Notarisierungszugangsdaten.

Die Produktidentität ist auf `MenuBarUSB-TB` mit der Bundle-ID
`de.r3d.menubarusb.tb` festgelegt. Das Projekt verwendet standardmäßig das
Entwicklerteam `G6JH37W285` und das lokale `notarytool`-Schlüsselbundprofil
`MenuBarUSB-TB-notary`. Vor dem ersten Release sicherstellen, dass das
entsprechende Developer-ID-Application-Zertifikat verfügbar ist, und dieses
Profil interaktiv anlegen:

```bash
./script/store_notary_credentials.sh 'YOUR-APPLE-ID'
```

`notarytool` fragt nach dem app-spezifischen Passwort und speichert es nur im
lokalen Schlüsselbund. Dieses Passwort unter
[account.apple.com](https://account.apple.com/) unter **Anmeldung und
Sicherheit → App-spezifische Passwörter** erzeugen; es nicht in der
Shell-Historie, Datei, einem Patch oder Repository ablegen. Apple dokumentiert
diesen Ablauf in seinem [Notarisierungsleitfaden](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).

Den Release nur mit für diesen Fork geeigneten Werten ausführen:

```bash
MENUBARUSB_SIGNING_IDENTITY='Developer ID Application: Your Name (YOURTEAMID)' \
./script/release.sh 0.1.1
```

Version 0.1.1 wird bewusst nur für **Apple Silicon (`arm64`)** ausgeliefert
und benötigt macOS 13 oder neuer. Intel-Macs werden von dieser Version nicht
unterstützt. Das Release-Skript prüft den angeforderten ausführbaren Slice. Ein
künftiger Universal-Release erfordert ausdrücklich eine zusätzliche
Hardware-Abnahme auf beiden Architekturen.

Das Release-Skript bricht bei nicht übergebenen oder nicht ignorierten
unversionierten Dateien ab, führt die XCTest-Suite und die statische Analyse
aus und prüft anschließend die signierte App, das notarisierte DMG und die App
in genau diesem DMG. Es lädt nichts hoch.

Nach Prüfung und Push des Release-Commits und seines annotierten Tags
`vVERSION` das DMG, seine Prüfsumme und die versionsbezogenen Release Notes
veröffentlichen. Das Skript prüft danach den exakten GitHub-Download
unabhängig erneut mit:

```bash
./script/publish_release.sh 0.1.1
```

Der Update-Feed ist für dieses öffentliche Repository eingerichtet. Er wird
nach Veröffentlichung des ersten GitHub Release nutzbar.
