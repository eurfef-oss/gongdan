import assert from 'node:assert/strict';
import { generateKeyPairSync, verify } from 'node:crypto';
import test from 'node:test';
import {
  createEntitlement,
  signEntitlement,
} from '../src/entitlement.js';

test('signs an entitlement with an Ed25519 key', () => {
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  const privateKeyBase64 = privateKey
    .export({ format: 'der', type: 'pkcs8' })
    .toString('base64');
  const entitlement = createEntitlement({
    purchaseKey: 'purchase-key',
    purchaseId: 'transaction-1',
    platform: 'android',
    productId: 'repair_pro_lifetime',
    activatedAtUtc: new Date().toISOString(),
  });

  const signed = signEntitlement(entitlement, privateKeyBase64);
  const payload = Buffer.from(signed.payload, 'base64url');
  const signature = Buffer.from(signed.signature, 'base64url');

  assert.equal(verify(null, payload, publicKey, signature), true);
});
