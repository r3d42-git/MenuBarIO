import assert from 'node:assert/strict';
import test from 'node:test';
import postcss from 'postcss';
import { SourceMapConsumer, SourceMapGenerator, SourceNode } from 'source-map-js';

const flatMap = () => ({
  version: 3,
  sources: ['input.css'],
  sourcesContent: ['a {}'],
  names: [],
  mappings: 'AAAA',
});
const section = (line, column = 0, map = flatMap()) => ({
  version: 3,
  sections: [{ offset: { line, column }, map }],
});

test('source maps reject oversized and malformed section offsets', () => {
  // Reject before an attacker-controlled offset reaches mapping serialization.
  assert.throws(() => new SourceMapConsumer(section(10_000_001)), /must not exceed/);
  for (const value of [-1, 0.5, Infinity, NaN, '1', null, Number.MAX_SAFE_INTEGER + 1]) {
    assert.throws(() => new SourceMapConsumer(section(value)), /offset/);
    assert.throws(() => new SourceMapConsumer(section(0, value)), /offset/);
  }
});

test('source maps bound cumulative offsets of nested sections', () => {
  const nested = section(5_000_000, 0, section(5_000_000, 0, section(5_000_000)));
  assert.throws(() => new SourceMapConsumer(nested), /nested sections/);
});

test('valid indexed source maps retain positions and generated code', () => {
  const consumer = new SourceMapConsumer(section(2));
  assert.deepEqual(consumer.originalPositionFor({ line: 3, column: 1 }), {
    source: 'input.css', line: 1, column: 0, name: null,
  });
  const generator = new SourceMapGenerator({ file: 'output.css' });
  consumer.eachMapping((mapping) => generator.addMapping({
    source: mapping.source,
    original: { line: mapping.originalLine, column: mapping.originalColumn },
    generated: { line: mapping.generatedLine, column: mapping.generatedColumn },
  }));
  const roundTrip = new SourceMapConsumer(generator.toJSON());
  assert.equal(roundTrip.originalPositionFor({ line: 3, column: 1 }).source, 'input.css');
  assert.equal(SourceNode.fromStringWithSourceMap('\n\na {}', consumer).toString(), '\n\na {}');
});

test('nested source-map sources are read once per section', () => {
  let map = flatMap();
  for (let depth = 0; depth < 12; depth++) map = section(0, 0, map);
  const consumer = new SourceMapConsumer(map);
  let leaf = consumer;
  while (leaf._sections) leaf = leaf._sections[0].consumer;
  const sources = leaf.sources;
  let reads = 0;
  Object.defineProperty(leaf, 'sources', { get() { reads++; return sources; } });
  assert.deepEqual(consumer.sources, ['input.css']);
  assert.equal(reads, 1);
});

test('PostCSS preserves CSS with object and inline indexed source maps', async () => {
  const css = 'a {}';
  const map = section(0);
  const inline = Buffer.from(JSON.stringify(map)).toString('base64');
  for (const embedded of [false, true]) {
    const input = embedded ? `${css}\n/*# sourceMappingURL=data:application/json;base64,${inline} */` : css;
    const result = await postcss([{ postcssPlugin: 'source-map-control', Once() {} }]).process(input, {
      from: '/tmp/input.css',
      to: '/tmp/output.css',
      map: { inline: false, annotation: false, ...(embedded ? {} : { prev: map }) },
    });
    assert.equal(result.root.nodes.filter((node) => node.type !== 'comment').map((node) => node.toString()).join(''), css);
    assert.ok(result.map.toJSON().sources.some((source) => source.endsWith('input.css')));
  }
});
