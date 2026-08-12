import assert from 'node:assert/strict';
import { generateKeyPairSync } from 'node:crypto';
import test from 'node:test';
import {
  clearGoogleAccessTokenCache,
  createGoogleServiceAccountAssertion,
  StoreVerificationError,
  validatePurchaseRequest,
  verifyStorePurchase,
} from '../src/store-verifier.js';

test('validates a development purchase request', async () => {
  const request = validatePurchaseRequest(
    {
      platform: 'android',
      productId: 'repair_pro_lifetime',
      purchaseId: 'transaction-1',
      verificationData: {
        source: 'Google Play',
        server: 'purchase-token',
      },
    },
    'repair_pro_lifetime',
  );
  const result = await verifyStorePurchase(request, { allowTestPurchases: true });

  assert.equal(result.verified, true);
  assert.equal(result.purchaseId, 'transaction-1');
});

test('rejects an unknown product', () => {
  assert.throws(
    () =>
      validatePurchaseRequest(
        {
          platform: 'ios',
          productId: 'wrong-product',
          purchaseId: 'transaction-1',
          verificationData: { server: 'receipt' },
        },
        'repair_pro_lifetime',
      ),
    (error) =>
      error instanceof StoreVerificationError && error.code === 'invalid_product',
  );
});

test('verifies a Google Play product and acknowledges it', async () => {
  clearGoogleAccessTokenCache();
  const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const account = {
    client_email: 'play-verifier-test@example.iam.gserviceaccount.com',
    private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }),
  };
  const request = validatePurchaseRequest(
    {
      platform: 'android',
      productId: 'repair_pro_lifetime',
      purchaseId: 'client-value-is-not-trusted',
      appId: 'com.cosdk.repairdesk',
      verificationData: {
        source: 'Google Play',
        server: 'google-purchase-token',
      },
    },
    'repair_pro_lifetime',
  );
  const calls = [];
  const fetchImpl = async (url, options) => {
    calls.push({ url, options });
    if (url === 'https://oauth.test/token') {
      return new Response(
        JSON.stringify({ access_token: 'access-token', expires_in: 3600 }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    }
    if (url.endsWith(':acknowledge')) {
      return new Response('', { status: 200 });
    }
    return new Response(
      JSON.stringify({
        orderId: 'GPA.1234-5678-9012-34567',
        purchaseState: 0,
        acknowledgementState: 0,
        purchaseTimeMillis: '1760000000000',
      }),
      { status: 200, headers: { 'content-type': 'application/json' } },
    );
  };
  const config = {
    allowTestPurchases: false,
    androidPackageName: 'com.cosdk.repairdesk',
    googlePlay: {
      packageName: 'com.cosdk.repairdesk',
      serviceAccount: account,
      tokenUrl: 'https://oauth.test/token',
      apiBaseUrl: 'https://api.test/androidpublisher/v3',
      acknowledgePurchases: true,
      requestTimeoutMs: 1000,
    },
  };

  const result = await verifyStorePurchase(request, config, {
    fetchImpl,
    now: () => 1_760_000_000_000,
  });

  assert.equal(result.verified, true);
  assert.equal(result.source, 'google_play');
  assert.equal(result.purchaseId, 'GPA.1234-5678-9012-34567');
  assert.equal(result.purchaseToken, 'google-purchase-token');
  assert.equal(result.purchaseState, 0);
  assert.equal(result.acknowledgementState, 0);
  assert.equal(calls.length, 3);
  assert.equal(calls[0].url, 'https://oauth.test/token');
  assert.match(calls[0].options.body, /grant_type=/);
  assert.equal(calls[1].options.headers.authorization, 'Bearer access-token');
  assert.equal(calls[2].options.headers.authorization, 'Bearer access-token');
  assert.match(calls[2].url, /:acknowledge$/);

  const assertion = createGoogleServiceAccountAssertion(
    {
      clientEmail: account.client_email,
      privateKey: account.private_key,
    },
    'https://oauth.test/token',
    1_760_000_000,
  );
  assert.equal(assertion.split('.').length, 3);
  clearGoogleAccessTokenCache();
});

test('rejects a pending Google Play purchase', async () => {
  clearGoogleAccessTokenCache();
  const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const request = validatePurchaseRequest(
    {
      platform: 'android',
      productId: 'repair_pro_lifetime',
      verificationData: { server: 'pending-token' },
    },
    'repair_pro_lifetime',
  );
  const config = {
    allowTestPurchases: false,
    androidPackageName: 'com.cosdk.repairdesk',
    googlePlay: {
      packageName: 'com.cosdk.repairdesk',
      serviceAccount: {
        client_email: 'pending-test@example.com',
        private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }),
      },
      tokenUrl: 'https://oauth.pending/token',
      apiBaseUrl: 'https://api.pending/androidpublisher/v3',
      acknowledgePurchases: false,
      requestTimeoutMs: 1000,
    },
  };
  const fetchImpl = async (url) => {
    if (url === 'https://oauth.pending/token') {
      return new Response(JSON.stringify({ access_token: 'pending-access' }), {
        status: 200,
      });
    }
    return new Response(JSON.stringify({ purchaseState: 2 }), { status: 200 });
  };

  await assert.rejects(
    verifyStorePurchase(request, config, { fetchImpl }),
    (error) =>
      error instanceof StoreVerificationError &&
      error.code === 'purchase_pending' &&
      error.statusCode === 409,
  );
  clearGoogleAccessTokenCache();
});

test('does not trust a client purchase when Google credentials are absent', async () => {
  const request = validatePurchaseRequest(
    {
      platform: 'android',
      productId: 'repair_pro_lifetime',
      purchaseId: 'fake-order',
      verificationData: { server: 'fake-token' },
    },
    'repair_pro_lifetime',
  );

  await assert.rejects(
    verifyStorePurchase(request, {
      allowTestPurchases: false,
      androidPackageName: 'com.cosdk.repairdesk',
      googlePlay: { packageName: 'com.cosdk.repairdesk' },
    }, { fetchImpl: async () => new Response('{}', { status: 200 }) }),
    (error) =>
      error instanceof StoreVerificationError &&
      error.code === 'billing_provider_not_configured',
  );
});
