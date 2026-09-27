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

// Keep this fix in the repository's post-generation step: the external
// Archify installation is not part of this checkout.
function hardenFocusRuntime(html) {
  const start = html.indexOf('      function setMany(ids, options) {');
  const end = html.indexOf('\n      function set(id, options)', start);
  if (start < 0 || end < 0) throw new Error('Unknown Archify focus runtime');
  let body = html.slice(start, end);
  const changes = [
    ['var byId = {};', 'var byId = Object.create(null);'],
    ['if (byId[id] && normalized.indexOf(id) === -1) normalized.push(id);',
      "if (typeof id === 'string' && Object.prototype.hasOwnProperty.call(byId, id) && normalized.indexOf(id) === -1) normalized.push(id);"],
    ['var selected = {};\n        var related = {};',
      'var selected = new Set(normalized);\n        var related = new Set(normalized);'],
    ['        normalized.forEach(function (id) { selected[id] = true; related[id] = true; });\n', ''],
    ['selectionMode ? selected[from] && selected[to] : selected[from] || selected[to]',
      'selectionMode ? selected.has(from) && selected.has(to) : selected.has(from) || selected.has(to)'],
    ['if (!selectionMode) { related[from] = true; related[to] = true; }',
      'if (!selectionMode) { related.add(from); related.add(to); }'],
    ['if (related[nodeId])', 'if (related.has(nodeId))'],
    ['if (selected[nodeId])', 'if (selected.has(nodeId))'],
  ];
  for (const [before, after] of changes) {
    const count = body.split(before).length - 1;
    if (count === 1) body = body.replace(before, after);
    else if (count !== 0 || (after && !body.includes(after))) {
      throw new Error('Changed Archify focus runtime; review the security patch before publishing');
    }
  }
  return html.slice(0, start) + body + html.slice(end);
}

for (const localeDirectory of ['', 'en/']) {
  for (const filename of diagrams) {
    const path = resolve(architectureRoot, localeDirectory, filename);
    const html = await readFile(path, 'utf8');
    const localHtml = hardenFocusRuntime(html).replace(
      /\n\s*<!-- Async font load:[\s\S]*?<\/noscript>\n/,
      '\n',
    );
    if (localHtml !== html) await writeFile(path, localHtml);
  }
}

console.log('Hardened focus IDs in 14 standalone diagrams and removed external font requests.');
