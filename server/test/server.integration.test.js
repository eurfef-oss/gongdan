import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { rm } from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const serverDirectory = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
);
const dataFile = path.join(serverDirectory, 'data', 'integration-test.json');
const port = 18787;

async function waitForHealth() {
  for (let attempt = 0; attempt < 30; attempt += 1) {
    try {
      const response = await fetch(`http://127.0.0.1:${port}/healthz`);
      if (response.ok) return response.json();
    } catch (_) {
      // The child process may need a few milliseconds to bind its port.
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error('license server did not become healthy');
}

test('development server verifies and restores a purchase idempotently', async () => {
  const child = spawn(process.execPath, ['src/server.js'], {
    cwd: serverDirectory,
    env: {
      ...process.env,
      PORT: String(port),
      ALLOW_TEST_PURCHASES: 'true',
      DATA_FILE: dataFile,
    },
    stdio: 'ignore',
  });

  try {
    const health = await waitForHealth();
    assert.equal(health.ok, true);

    const request = {
      platform: 'android',
      productId: 'repair_pro_lifetime',
      purchaseId: 'integration-transaction-1',
      verificationData: {
        source: 'test',
        server: 'integration-token',
      },
    };
    const firstResponse = await fetch(
      `http://127.0.0.1:${port}/v1/purchases/verify`,
      {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(request),
      },
    );
    const first = await firstResponse.json();
    assert.equal(firstResponse.status, 200);
    assert.equal(first.entitlement.plan, 'pro');
    assert.equal(first.cached, false);

    const restoreResponse = await fetch(
      `http://127.0.0.1:${port}/v1/purchases/restore`,
      {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(request),
      },
    );
    const restored = await restoreResponse.json();
    assert.equal(restoreResponse.status, 200);
    assert.equal(restored.cached, true);
    assert.equal(restored.entitlement.purchaseId, 'integration-transaction-1');
  } finally {
    child.kill();
    await rm(dataFile, { force: true });
    await rm(`${dataFile}.tmp`, { force: true });
  }
});
