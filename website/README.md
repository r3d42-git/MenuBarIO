# MenuBarIO project history website

This directory contains the static GitHub Pages version of the bilingual
MenuBarIO project history. Its design and editorial content were imported from
the deployed Sites version 3 at source commit
`27132925a8f797583cdaf857ab2668a67fb6215f`.

The German page is served at `/MenuBarIO/`; the English page is served at
`/MenuBarIO/en/`. Both render the localized content in `src/history-page.tsx`.
The narrative remains deliberately curated: add only meaningful milestones and
update both language variants in the same pull request.

## Local verification

```bash
npm ci
npm run lint
npm run typecheck
npm run build
npm run check:artifact
```

`dist/` is generated and must not be committed. GitHub Actions builds and
publishes it through the `github-pages` environment after changes reach
protected `main`. The original Sites project is a separate private backup and
is not synchronized from this directory.
