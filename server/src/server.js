import http from 'node:http';
import { createHash } from 'node:crypto';
import { config } from './config.js';
import {
  createEntitlement,
  entitlementResponse,
  hashPurchaseIdentity,
} from './entitlement.js';
import { MariaDbLicenseStore } from './mariadb-store.js';
import { MemoryLicenseStore } from './memory-store.js';
import {
  StoreVerificationError,
  validatePurchaseRequest,
  verifyStorePurchase,
} from './store-verifier.js';

if (config.nodeEnv === 'production' && config.storeDriver !== 'mariadb') {
  throw new Error('production requires STORE_DRIVER=mariadb');
}
if (config.storeDriver === 'memory' && config.nodeEnv !== 'test') {
  throw new Error('STORE_DRIVER=memory is only available in NODE_ENV=test');
}

const store = config.storeDriver === 'memory'
  ? new MemoryLicenseStore()
  : new MariaDbLicenseStore(config.database);

const jsonHeaders = {
  'content-type': 'application/json; charset=utf-8',
  'cache-control': 'no-store',
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'content-type',
  'access-control-allow-methods': 'GET,POST,OPTIONS',
};

function sendJson(response, statusCode, payload) {
  response.writeHead(statusCode, jsonHeaders);
  response.end(JSON.stringify(payload));
}

function readJson(request) {
  return new Promise((resolve, reject) => {
    let size = 0;
    let raw = '';
    request.setEncoding('utf8');
    request.on('data', (chunk) => {
      size += Buffer.byteLength(chunk);
      if (size > 256 * 1024) {
        reject(new StoreVerificationError('payload_too_large', 'request body is too large', 413));
        request.destroy();
        return;
      }
      raw += chunk;
    });
    request.on('end', () => {
      if (!raw.trim()) {
        reject(new StoreVerificationError('invalid_json', 'request body is empty', 400));
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch (_) {
        reject(new StoreVerificationError('invalid_json', 'request body is not valid JSON', 400));
      }
    });
    request.on('error', reject);
  });
}

function purchaseKey(platform, purchaseId) {
  return hashPurchaseIdentity(`${platform}:${purchaseId}`);
}

function responseForEntitlement(entitlement, cached = false) {
  return {
    ...entitlementResponse(entitlement, config.entitlementPrivateKeyBase64),
    cached,
  };
}

async function verifyPurchase(body) {
  const request = validatePurchaseRequest(body, config.productId);
  const verified = await verifyStorePurchase(request, config);
  const key = purchaseKey(request.platform, verified.purchaseId);
  const identityKey = verified.identityKey ?? request.identityKey;
  const existing = await store.findPurchaseByIdentity(identityKey) ??
    await store.findPurchaseByToken(
      request.platform,
      request.productId,
      verified.purchaseToken ?? request.verificationData.server,
    ) ??
    await store.findPurchase(request.platform, verified.purchaseId);
  if (existing) {
    const current = await store.findEntitlement(existing.purchaseKey);
    if (current) return responseForEntitlement(current, true);
  }

  const now = new Date().toISOString();
  const purchase = {
    purchaseKey: key,
    identityKey,
    platform: request.platform,
    productId: request.productId,
    purchaseId: verified.purchaseId,
    purchaseToken: verified.purchaseToken ?? request.verificationData.server ?? null,
    source: verified.source,
    status: 'active',
    purchasedAtUtc: verified.purchasedAtUtc ?? now,
    updatedAtUtc: now,
  };
  const entitlement = createEntitlement({
    purchaseKey: key,
    purchaseId: verified.purchaseId,
    platform: request.platform,
    productId: request.productId,
    activatedAtUtc: now,
  });
  await store.savePurchaseAndEntitlement(purchase, entitlement);
  return responseForEntitlement(entitlement);
}

async function handleWebhook(platform, body, request) {
  const raw = JSON.stringify(body);
  const eventId = request.headers['x-event-id'] ||
    createHash('sha256').update(`${platform}:${raw}`).digest('hex');
  const accepted = await store.appendEvent({
    eventId,
    platform,
    receivedAtUtc: new Date().toISOString(),
    payloadHash: createHash('sha256').update(raw).digest('hex'),
  });

  // Development-only helper for exercising revocation locally. Real Apple and
  // Google notifications must be verified and decoded before applying this.
  if (config.allowTestPurchases && body && body.status === 'revoked') {
    const purchaseId = typeof body.purchaseId === 'string' ? body.purchaseId : '';
    const purchase = await store.findPurchase(platform, purchaseId);
    if (purchase) {
      const current = await store.findEntitlement(purchase.purchaseKey);
      if (current) {
        await store.saveEntitlement({
          ...current,
          state: 'revoked',
          plan: 'free',
          features: [],
          verifiedAtUtc: new Date().toISOString(),
        });
      }
    }
  }

  return { accepted, eventId };
}

async function requestHandler(request, response) {
  if (request.method === 'OPTIONS') {
    response.writeHead(204, jsonHeaders);
    response.end();
    return;
  }

  const url = new URL(request.url ?? '/', `http://${request.headers.host ?? 'localhost'}`);
  try {
    if (request.method === 'GET' && url.pathname === '/healthz') {
      sendJson(response, 200, {
        ok: true,
        environment: config.nodeEnv,
        testPurchasesEnabled: config.allowTestPurchases,
        productId: config.productId,
        storeDriver: config.storeDriver,
      });
      return;
    }

    if (
      request.method === 'POST' &&
      (url.pathname === '/v1/purchases/verify' ||
        url.pathname === '/v1/purchases/restore')
    ) {
      const body = await readJson(request);
      sendJson(response, 200, await verifyPurchase(body));
      return;
    }

    if (request.method === 'POST' && url.pathname === '/v1/webhooks/apple') {
      const body = await readJson(request);
      sendJson(response, 202, await handleWebhook('ios', body, request));
      return;
    }

    if (request.method === 'POST' && url.pathname === '/v1/webhooks/google') {
      const body = await readJson(request);
      sendJson(response, 202, await handleWebhook('android', body, request));
      return;
    }

    sendJson(response, 404, { error: 'not_found' });
  } catch (error) {
    const statusCode = error instanceof StoreVerificationError
      ? error.statusCode
      : 500;
    if (statusCode >= 500) {
      console.error(`[license-server] ${error.code ?? error.name}: ${error.message}`);
    }
    sendJson(response, statusCode, {
      error: error.code ?? 'internal_error',
      message: statusCode >= 500 ? 'The license service is temporarily unavailable' : error.message,
    });
  }
}

await store.init();
const server = http.createServer(requestHandler);
server.listen(config.port, config.host, () => {
  console.log(`[license-server] listening on http://${config.host}:${config.port}`);
  if (config.allowTestPurchases) {
    console.warn('[license-server] ALLOW_TEST_PURCHASES is enabled; do not use this in production');
  }
});

const shutdown = async () => {
  server.close(async () => {
    await store.close();
    process.exit(0);
  });
};

process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);
