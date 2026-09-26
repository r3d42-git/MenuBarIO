# Security checks

Normal pull requests run the native Apple Silicon test/analyzer/archive gate,
website validation, and CodeQL for JavaScript/TypeScript and GitHub Actions.
The two CodeQL analyses also run weekly. Dependabot proposes weekly dependency
and Actions updates; security update PRs are enabled separately. Updates are
reviewed and checked before merging.

Swift CodeQL is optional because initial extraction proved too slow for normal
PRs. It has not yet completed a validated scan. It runs only through Actions →
Optional Swift CodeQL analysis → Run workflow, with a 20-minute limit. A
successful run saves a SARIF report for seven days; it does not change the
mandatory code-scanning baseline. Use it selectively when its expected value
justifies the run. Swift remains covered by the existing compiler, tests and
Xcode static analyzer; those do not provide equivalent CodeQL security coverage.

Repository controls include secret scanning/push protection, Dependabot alerts,
private vulnerability reporting and immutable future releases. Existing release
assets are not retroactively locked. See [the reporting policy](../.github/SECURITY.md)
and [release procedure](../RELEASE.md).

---

# Sicherheitsprüfungen

Normale Pull Requests durchlaufen die native Apple-Silicon-Prüfkette mit Tests,
Xcode-Analyse und Archivbau, die Website-Prüfung sowie CodeQL für JavaScript/
TypeScript und GitHub Actions. Die beiden CodeQL-Analysen laufen zusätzlich
wöchentlich. Dependabot schlägt wöchentliche Updates für Abhängigkeiten und
Actions vor; Sicherheitsupdate-PRs sind separat aktiviert. Änderungen werden
vor dem Merge geprüft.

Swift-CodeQL ist optional: Die anfängliche Extraktion dauerte für normale PRs
zu lange. Ein erfolgreich abgeschlossener Scan ist bislang nicht nachgewiesen.
Der Workflow startet ausschließlich manuell unter Actions → Optional Swift
CodeQL analysis → Run workflow und ist auf 20 Minuten begrenzt. Ein erfolgreicher
Lauf speichert einen SARIF-Bericht für sieben Tage, ohne die verpflichtende
Code-Scanning-Basis zu verändern. Er sollte gezielt eingesetzt werden, wenn der
erwartete Nutzen den Lauf rechtfertigt. Compiler, Tests und Xcode-Analyse prüfen
Swift weiterhin; ihre Abdeckung entspricht nicht der CodeQL-Sicherheitsanalyse.

Zum Repository-Schutz gehören Secret Scanning/Push Protection, Dependabot-Alerts,
vertrauliche Sicherheitsmeldungen und unveränderliche künftige Releases.
Bestehende Release-Dateien werden nicht rückwirkend gesperrt. Siehe
[Melderichtlinie](../.github/SECURITY.md) und [Release-Ablauf](../RELEASE.md).
