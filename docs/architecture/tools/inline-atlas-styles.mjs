import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const architectureRoot = resolve(import.meta.dirname, '..');
const css = await readFile(resolve(architectureRoot, 'atlas.css'), 'utf8');
const inlineStyle = `<style data-atlas-styles>\n${css}</style>`;
const stylesheetReference = /<link rel="stylesheet" href="(?:\.\.\/)?atlas\.css">|<style data-atlas-styles>[\s\S]*?<\/style>/;

for (const page of ['index.html', 'en/index.html']) {
  const path = resolve(architectureRoot, page);
  const html = await readFile(path, 'utf8');
  if (!stylesheetReference.test(html)) {
    throw new Error(`No atlas stylesheet reference found in ${path}`);
  }
  await writeFile(path, html.replace(stylesheetReference, inlineStyle));
}

console.log('Inlined the atlas stylesheet into both landing pages.');
