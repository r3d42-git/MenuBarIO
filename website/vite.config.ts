import { cp } from 'node:fs/promises';
import tailwindcss from '@tailwindcss/postcss';
import react from '@vitejs/plugin-react';
import { relative, resolve } from 'node:path';
import { defineConfig } from 'vite';

const architectureSource = resolve(import.meta.dirname, '../docs/architecture');
const architectureOutput = resolve(import.meta.dirname, 'dist/architecture');

function architectureAtlas() {
  return {
    name: 'copy-architecture-atlas',
    apply: 'build' as const,
    async closeBundle() {
      await cp(architectureSource, architectureOutput, {
        recursive: true,
        filter(source) {
          const path = relative(architectureSource, source);
          return (
            path === '' ||
            path === 'en' ||
            path === 'atlas.css' ||
            path === 'index.html' ||
            /^0[1-7]-[a-z-]+\.html$/.test(path) ||
            /^en\/(?:index|0[1-7]-[a-z-]+)\.html$/.test(path)
          );
        },
      });
    },
  };
}

export default defineConfig({
  base: '/MenuBarIO/',
  css: {
    postcss: {
      plugins: [tailwindcss()],
    },
  },
  plugins: [react(), architectureAtlas()],
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        de: resolve(import.meta.dirname, 'index.html'),
        en: resolve(import.meta.dirname, 'en/index.html'),
      },
    },
  },
});
