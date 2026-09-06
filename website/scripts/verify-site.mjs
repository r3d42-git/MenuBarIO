import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const dist = join(root, 'dist');
const architectureDiagrams = [
  '01-system.html',
  '02-ports.html',
  '03-refresh.html',
  '04-status.html',
  '05-outputs.html',
  '06-battery.html',
  '07-release.html',
];
const requiredFiles = [
  'index.html',
  'en/index.html',
  'menubario-icon.png',
  'og.png',
  'architecture/index.html',
  'architecture/en/index.html',
  'architecture/atlas.css',
  ...architectureDiagrams.map((path) => join('architecture', path)),
  ...architectureDiagrams.map((path) => join('architecture/en', path)),
];

for (const path of requiredFiles) {
  if (!existsSync(join(dist, path))) {
    throw new Error(`Missing build artifact: ${path}`);
  }
}

function filesBelow(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? filesBelow(path) : [path];
  });
}

const builtFiles = filesBelow(dist);
const textFiles = builtFiles.filter((path) => /\.(?:css|html|js)$/.test(path));
const builtText = textFiles.map((path) => readFileSync(path, 'utf8')).join('\n');
const forbidden = [
  'chatgpt.site',
  'git.chatgpt-team.site',
  '.openai/hosting.json',
];

for (const marker of forbidden) {
  if (builtText.includes(marker)) {
    throw new Error(`Forbidden deployment marker found: ${marker}`);
  }
}

const htmlChecks = [
  ['index.html', 'lang="de"', 'MenuBarIO – Projektverlauf'],
  ['en/index.html', 'lang="en"', 'MenuBarIO – Project History'],
];

for (const [path, language, title] of htmlChecks) {
  const html = readFileSync(join(dist, path), 'utf8');
  for (const marker of [language, title, '/MenuBarIO/menubario-icon.png']) {
    if (!html.includes(marker)) {
      throw new Error(`${path} is missing ${marker}`);
    }
  }
  const unexpectedRootPath = html.match(
    /(?:href|src)="\/(?!MenuBarIO\/|\/)[^"]+"/,
  );
  if (unexpectedRootPath) {
    throw new Error(`${path} contains an invalid root path: ${unexpectedRootPath[0]}`);
  }

  const externalRuntimeResource = [
    ...html.matchAll(/<(?:script|link)\b[^>]*>/gi),
  ].find((match) => {
    const tag = match[0];
    const isRuntimeTag =
      tag.startsWith('<script') ||
      /\brel="(?:stylesheet|modulepreload|preload|preconnect|dns-prefetch)"/i.test(
        tag,
      );
    return isRuntimeTag && /\b(?:src|href)="https?:\/\//i.test(tag);
  });
  if (externalRuntimeResource) {
    throw new Error(`${path} loads a script, stylesheet or font from another host`);
  }

  for (const match of html.matchAll(/(?:href|src)="(\/MenuBarIO\/[^"#?]*)"/g)) {
    const deployedPath = match[1].slice('/MenuBarIO/'.length);
    const artifactPath = deployedPath.endsWith('/')
      ? join(deployedPath, 'index.html')
      : deployedPath;
    if (!existsSync(join(dist, artifactPath))) {
      throw new Error(`${path} references a missing artifact: ${match[1]}`);
    }
  }
}

const atlasChecks = [
  ['architecture/index.html', 'lang="de"', 'MenuBarIO verstehen · Architektur-Atlas'],
  ['architecture/en/index.html', 'lang="en"', 'Understanding MenuBarIO · Architecture Atlas'],
  ['architecture/01-system.html', 'Systemarchitektur', '01 · MenuBarIO — Systemarchitektur'],
  ['architecture/en/01-system.html', 'lang="en"', '01 · MenuBarIO — System Architecture'],
];

for (const [path, language, title] of atlasChecks) {
  const html = readFileSync(join(dist, path), 'utf8');
  for (const marker of [language, title]) {
    if (!html.includes(marker)) {
      throw new Error(`${path} is missing ${marker}`);
    }
  }

  const externalRuntimeResource = [
    ...html.matchAll(/<(?:script|link)\b[^>]*>/gi),
  ].find((match) => {
    const tag = match[0];
    const isRuntimeTag =
      tag.startsWith('<script') ||
      /\brel="(?:stylesheet|modulepreload|preload|preconnect|dns-prefetch)"/i.test(
        tag,
      );
    return isRuntimeTag && /\b(?:src|href)="https?:\/\//i.test(tag);
  });
  if (externalRuntimeResource) {
    throw new Error(`${path} loads a script, stylesheet or font from another host`);
  }
}

for (const path of architectureDiagrams.flatMap((diagram) => [
  join('architecture', diagram),
  join('architecture/en', diagram),
])) {
  const html = readFileSync(join(dist, path), 'utf8');
  if (/<(?:script|link)\b[^>]*(?:src|href)="https?:\/\//i.test(html)) {
    throw new Error(`${path} must remain a self-contained diagram page`);
  }
}

for (const path of ['architecture/index.html', 'architecture/en/index.html']) {
  const html = readFileSync(join(dist, path), 'utf8');
  const diagramLinks = [
    ...html.matchAll(
      /class="diagram" href="0[1-7]-[a-z-]+\.html" target="_blank" rel="noreferrer"/g,
    ),
  ];
  if (diagramLinks.length !== architectureDiagrams.length) {
    throw new Error(`${path} must open every diagram in a new tab`);
  }
}

const source = readFileSync(join(root, 'src/history-page.tsx'), 'utf8');
for (const marker of [
  "pageUrl('en/')",
  'pageUrl()',
  "pageUrl(isGerman ? 'architecture/' : 'architecture/en/')",
  'https://github.com/r3d42-git/MenuBarIO',
  'https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.5.0',
  'https://github.com/rafaelSwi/MenuBarUSB',
]) {
  if (!source.includes(marker)) {
    throw new Error(`Language or external link is missing: ${marker}`);
  }
}

for (const networkApi of ['fetch(', 'XMLHttpRequest', 'sendBeacon(', 'WebSocket(']) {
  if (source.includes(networkApi)) {
    throw new Error(`Unexpected runtime network API in the published page: ${networkApi}`);
  }
}

const anchors = [...source.matchAll(/href="(#[-\w]+)"/g)].map(
  (match) => match[1].slice(1),
);
for (const anchor of new Set(anchors)) {
  if (!source.includes(`id="${anchor}"`)) {
    throw new Error(`Missing target for internal anchor: #${anchor}`);
  }
}

const fontFiles = builtFiles.filter((path) => /geist.*\.woff2$/i.test(path));
if (fontFiles.length < 2) {
  throw new Error('Expected locally bundled Geist Sans and Geist Mono fonts');
}

for (const path of builtFiles) {
  if (statSync(path).size === 0) {
    throw new Error(`Empty build artifact: ${relative(dist, path)}`);
  }
}

console.log(`Verified ${builtFiles.length} static GitHub Pages artifacts.`);
