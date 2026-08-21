# Release

`script/release.sh` produces a Developer-ID-signed, notarized and stapled DMG
and its matching `.dmg.sha256` checksum. It verifies the app before packaging,
validates the notarized DMG, then mounts that exact DMG read-only and verifies
the enclosed app again. `LICENSE` is included beside the app in the delivered
image.

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
./script/release.sh 0.1.0
```

Version 0.1.0 is deliberately distributed for **Apple Silicon (`arm64`) only**
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
./script/publish_release.sh 0.1.0
```

The update feed is configured for this public repository. It will become
usable after its first GitHub Release is published.
