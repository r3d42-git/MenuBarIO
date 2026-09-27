import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';
import test from 'node:test';
import vm from 'node:vm';

const root = resolve(import.meta.dirname, '../../docs/architecture');
const pages = ['', 'en'].flatMap((locale) => readdirSync(resolve(root, locale))
  .filter((name) => /^0[1-7]-[a-z-]+\.html$/.test(name)).map((name) => resolve(root, locale, name)));
assert.equal(pages.length, 14);

function focusRuntime(html) {
  const start = html.indexOf('      function setMany(ids, options) {');
  const end = html.indexOf('\n      function set(id, options)', start);
  assert.ok(start > 0 && end > start);
  const ids = [...html.matchAll(/<g\b[^>]*data-node-id="([^"]+)"/g)].map((m) => m[1]);
  assert.ok(ids.length >= 2);
  const nodeList = ids.map((id) => ({
    id, attributes: {},
    getAttribute(name) { return name === 'data-node-id' ? id : this.attributes[name] || null; },
    setAttribute(name, value) { this.attributes[name] = value; },
  }));
  const context = vm.createContext({
    activeIds: [], Archify: {}, nodes: () => nodeList, edges: () => [],
    svg: { attributes: {}, setAttribute(name, value) { this.attributes[name] = value; } },
    label: {}, chip: {}, nodeLabel: (node) => node.getAttribute('data-node-id'),
    viewerText: () => 'Selection', renderRelationshipLens() {}, requestLensPlacement() {},
    location: { pathname: '/', search: '' }, history: { replaceState() {} },
  });
  vm.runInContext('function clear() { activeIds = []; svg.attributes = {}; }\n' + html.slice(start, end), context);
  return { context, ids };
}

for (const path of pages) {
  test(`${path}: focus rejects inherited/encoded names and preserves valid selection`, () => {
    const { context, ids } = focusRuntime(readFileSync(path, 'utf8'));
    const options = { updateUrl: false, toggle: false };
    for (const payload of ['__proto__', 'constructor', 'toString', 'hasOwnProperty',
      '__defineGetter__', '%5F%5Fproto%5F%5F', '%63onstructor', 'missing-node']) {
      const id = new URLSearchParams('focus=' + payload).get('focus');
      assert.equal(context.setMany([ids[0]], options), true);
      assert.equal(context.setMany([id], options), false, payload);
      assert.deepEqual(Array.from(context.activeIds), [ids[0]], payload);
      assert.equal(context.svg.attributes['data-focus-active'], ids[0]);
    }
    assert.equal(context.setMany([ids[0], 'constructor', ids[1], ids[0]], options), true);
    assert.deepEqual(Array.from(context.activeIds), [ids[0], ids[1]]);
    assert.equal(context.setMany([ids[0], ids[1]], { updateUrl: false }), true);
    assert.equal(context.activeIds.length, 0, 'same selection toggles off');
    assert.equal(context.setMany([ids[1]], options), true, 'normal focus still works after rejection');
  });
}
