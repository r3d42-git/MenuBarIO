const baseUrl = process.argv[2];

if (!baseUrl) {
  throw new Error('Usage: node scripts/verify-public.mjs <page-url>');
}

const root = new URL(baseUrl.endsWith('/') ? baseUrl : `${baseUrl}/`);
const checks = [
  ['', 'MenuBarIO – Projektverlauf'],
  ['en/', 'MenuBarIO – Project History'],
  ['menubario-icon.png', null],
  ['og.png', null],
];

async function fetchWithRetry(url, expectedText) {
  let lastError;
  for (let attempt = 1; attempt <= 12; attempt += 1) {
    try {
      const response = await fetch(url, { redirect: 'follow' });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      if (expectedText && !(await response.text()).includes(expectedText)) {
        throw new Error(`response does not contain ${expectedText}`);
      }
      return;
    } catch (error) {
      lastError = error;
      if (attempt < 12) {
        await new Promise((resolveDelay) => setTimeout(resolveDelay, 5000));
      }
    }
  }
  throw new Error(`Unable to verify ${url}: ${lastError}`);
}

for (const [path, expectedText] of checks) {
  await fetchWithRetry(new URL(path, root), expectedText);
}

console.log(`Verified public GitHub Pages site at ${root}`);
