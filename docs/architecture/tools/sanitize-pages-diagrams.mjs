import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const architectureRoot = resolve(import.meta.dirname, '..');
const diagrams = [
  '01-system.html',
  '02-ports.html',
  '03-refresh.html',
  '04-status.html',
  '05-outputs.html',
  '06-battery.html',
  '07-release.html',
];

for (const localeDirectory of ['', 'en/']) {
  for (const filename of diagrams) {
    const path = resolve(architectureRoot, localeDirectory, filename);
    const html = await readFile(path, 'utf8');
    const localHtml = html.replace(
      /\n\s*<!-- Async font load:[\s\S]*?<\/noscript>\n/,
      '\n',
    );
    if (localHtml !== html) await writeFile(path, localHtml);
  }
}

console.log('Ensured that 14 standalone diagram pages do not request external fonts.');
