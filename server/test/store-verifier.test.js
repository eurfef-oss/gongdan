import assert from 'node:assert/strict';
import test from 'node:test';
import {
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
