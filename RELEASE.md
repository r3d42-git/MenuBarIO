# Release

`script/release.sh` produces a Developer-ID-signed, notarized and stapled DMG
and its matching `.dmg.sha256` checksum. It notarizes and staples the app before
packaging, independently notarizes the DMG, then mounts that exact DMG read-only
and verifies both tickets with `script/verify_release.sh`. The delivered image
opens as a small installer window:
the app can be dragged onto the visible **Programme** alias, which points to
`/Applications`. `LICENSE`, `LICENSE.upstream`, `NOTICE`, `SOURCE.md` and the installer background
are included in the image. The four license/source files are also bundled
inside the app before signing. Verification compares both delivered copies
with the release source and checks the exact public source tag.

## DMG design rule

Every DMG release of this app uses the same direct installation pattern: app
icon on the left, **Programme** on the right, an arrow and short instruction
between them. Do not fall back to an unarranged Finder folder. The layout is
created only with macOS tools and source-controlled scripts; it does not add
network access or a third-party packaging dependency. Because Finder records
the window layout, create a DMG from an unlocked local macOS session with
Finder available; a headless release intentionally fails before packaging.

After a manual read-only Finder inspection, close the installer window and
detach that inspection mount before running `publish_release.sh` or another
`verify_release.sh`. The verifier mounts the exact image afresh; leaving the
same DMG mounted can make `hdiutil attach` fail with `Resource busy`. Detach
only the known inspection mount and rerun the unchanged verifier/wrapper.

Before creating any release, run `./script/verify.sh` and complete the
hardware acceptance checks in [`TESTING.md`](TESTING.md). The script executes
the XCTest suite and the Xcode static analyzer in isolated DerivedData. The
same two checks run in GitHub Actions for pushes to `main` and pull requests;
that CI workflow deliberately has no signing or notary credentials.

The product identity is fixed as `MenuBarIO`. The legacy bundle identifier
`de.r3d.menubarusb.tb` is deliberately retained for upgrade continuity. The
project uses Developer Team `G6JH37W285` and the
existing local `notarytool` keychain profile `MenuBarUSB-TB-notary` by default.
When configuring another Mac for releases, ensure the corresponding Developer
ID Application certificate is available and create that profile interactively:

```bash
./script/store_notary_credentials.sh 'YOUR-APPLE-ID'
```

`notarytool` prompts for the app-specific password and stores it only in the
local Keychain. Generate that password at [account.apple.com](https://account.apple.com/)
under **Sign-In and Security → App-Specific Passwords**; do not put it in a
shell history, file, patch, or repository. Apple documents this credential
flow in its [notarization guide](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).

Run the Universal release with only values appropriate to this fork:

```bash
MENUBARIO_SIGNING_IDENTITY='Developer ID Application: Your Name (YOURTEAMID)' \
./script/release.sh VERSION
```

The release script always archives **both** executable slices: Apple Silicon
(`arm64`) and Intel (`x86_64`). It verifies each slice before packaging, and
the CI workflow runs the XCTest suite natively on both architectures. Version
0.1.1 was Apple-Silicon-only; releases from 0.1.2 onward, including the current
MenuBarIO 0.7.1 release, are Universal. When a release changes device discovery,
complete
the applicable hardware acceptance cases in [`TESTING.md`](TESTING.md),
including the Intel-Mac cases, or record an explicit release exception if a
required device is not available.

The release script aborts when uncommitted or nonignored untracked files exist,
runs the XCTest suite and static analysis, then verifies the separately stapled
app, the notarized DMG, and the app inside that exact DMG. It does not upload
anything.

After reviewing and pushing the release commit and its annotated `vVERSION`
tag, publish the DMG, its checksum and the versioned release notes. The script
then independently re-checks the exact GitHub download with:

```bash
./script/publish_release.sh VERSION
```

---

# Release – Deutsch

`script/release.sh` erzeugt ein mit Developer ID signiertes, notarisiertes und
gestapeltes DMG sowie die zugehörige Prüfsumme `.dmg.sha256`. Es notarisiert und
stapelt die App vor dem Paketbau, notarisiert das DMG unabhängig davon und
bindet anschließend genau dieses DMG schreibgeschützt ein. Dabei prüft
`script/verify_release.sh` beide Tickets. Das ausgelieferte Image öffnet sich
als kleines Installationsfenster: Die App kann auf den
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

Nach einer manuellen schreibgeschützten Finder-Prüfung das Installerfenster
schließen und den eigenen Prüfmount aushängen, bevor `publish_release.sh` oder
erneut `verify_release.sh` läuft. Der Verifier bindet genau dieses Image frisch
ein; ein noch vorhandener Mount desselben DMGs kann `hdiutil attach` mit
„Ressource ist belegt“ abbrechen lassen. Nur den bekannten Prüfmount aushängen
und den unveränderten Verifier beziehungsweise Wrapper erneut ausführen.

Vor jedem Release `./script/verify.sh` ausführen und die Hardware-Abnahme in
[`TESTING.md`](TESTING.md) abschließen. Das Skript führt die XCTest-Suite und
den Xcode Static Analyzer in isoliertem DerivedData aus. Dieselben beiden
Prüfungen laufen in GitHub Actions bei Pushes auf `main` und Pull Requests;
dieser CI-Ablauf enthält bewusst keine Signierungs- oder
Notarisierungszugangsdaten.

Die Produktidentität ist auf `MenuBarIO` festgelegt. Die bisherige Bundle-ID
`de.r3d.menubarusb.tb` bleibt für nahtlose Aktualisierungen absichtlich
erhalten. Das Projekt verwendet standardmäßig das Entwicklerteam `G6JH37W285`
und das vorhandene lokale `notarytool`-Schlüsselbundprofil
`MenuBarUSB-TB-notary`. Beim Einrichten eines weiteren Macs für Releases
sicherstellen, dass das entsprechende Developer-ID-Application-Zertifikat
verfügbar ist, und dieses Profil interaktiv anlegen:

```bash
./script/store_notary_credentials.sh 'YOUR-APPLE-ID'
```

`notarytool` fragt nach dem app-spezifischen Passwort und speichert es nur im
lokalen Schlüsselbund. Dieses Passwort unter
[account.apple.com](https://account.apple.com/) unter **Anmeldung und
Sicherheit → App-spezifische Passwörter** erzeugen; es nicht in der
Shell-Historie, Datei, einem Patch oder Repository ablegen. Apple dokumentiert
diesen Ablauf in seinem [Notarisierungsleitfaden](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).

Den Universal-Release nur mit für diesen Fork geeigneten Werten ausführen:

```bash
MENUBARIO_SIGNING_IDENTITY='Developer ID Application: Your Name (YOURTEAMID)' \
./script/release.sh VERSION
```

Das Release-Skript archiviert immer **beide** ausführbaren Slices: Apple
Silicon (`arm64`) und Intel (`x86_64`). Es prüft jeden Slice vor dem Paketbau;
der CI-Ablauf führt die XCTest-Suite nativ auf beiden Architekturen aus.
Version 0.1.1 war ausschließlich für Apple Silicon bestimmt; die Releases ab
0.1.2 einschließlich des aktuellen Releases MenuBarIO 0.7.1 sind
Universal-Versionen.
Wenn ein Release die Geräteerkennung ändert, die zutreffenden
Hardware-Abnahmefälle in [`TESTING.md`](TESTING.md) einschließlich der
Intel-Mac-Fälle ausführen oder eine ausdrückliche Release-Ausnahme
dokumentieren, falls ein benötigtes Gerät nicht verfügbar ist.

Das Release-Skript bricht bei nicht committeten oder nicht ignorierten
unversionierten Dateien ab, führt die XCTest-Suite und die statische Analyse
aus und prüft anschließend die getrennt gestapelte App, das notarisierte DMG
und die App in genau diesem DMG. Es lädt nichts hoch.

Nach Prüfung und Push des Release-Commits und seines annotierten Tags
`vVERSION` das DMG, seine Prüfsumme und die versionsbezogenen Release Notes
veröffentlichen. Das Skript prüft danach den exakten GitHub-Download
unabhängig erneut mit:

```bash
./script/publish_release.sh VERSION
```
