import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const dist = join(root, 'dist');
const requiredFiles = [
  'index.html',
  'en/index.html',
  'menubario-icon.png',
  'og.png',
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

const source = readFileSync(join(root, 'src/history-page.tsx'), 'utf8');
for (const marker of [
  "pageUrl('en/')",
  'pageUrl()',
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
