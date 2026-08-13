import { createHash, createPrivateKey, sign } from 'node:crypto';

export const proFeatures = Object.freeze([
  'unlimited_orders',
  'unlimited_customers',
  'custom_templates',
  'statistics',
]);

export const hashPurchaseIdentity = (value) =>
  createHash('sha256').update(value).digest('hex');

export const base64Url = (value) => Buffer.from(value).toString('base64url');

export function createEntitlement({
  purchaseKey,
  purchaseId,
  platform,
  productId,
  activatedAtUtc,
  status = 'active',
}) {
  return {
    purchaseKey,
    state: status,
    plan: status === 'active' ? 'pro' : 'free',
    productId,
    purchaseId,
    platform,
    features: status === 'active' ? [...proFeatures] : [],
    activatedAtUtc,
    verifiedAtUtc: activatedAtUtc,
    expiresAtUtc: null,
  };
}

export function signEntitlement(entitlement, privateKeyBase64) {
  const payload = JSON.stringify(entitlement);
  if (!privateKeyBase64) {
    return {
      payload: base64Url(payload),
      signature: null,
    };
  }

  const privateKey = createPrivateKey({
    key: Buffer.from(privateKeyBase64, 'base64'),
    format: 'der',
    type: 'pkcs8',
  });
  const signature = sign(null, Buffer.from(payload), privateKey);
  return {
    payload: base64Url(payload),
    signature: signature.toString('base64url'),
  };
}

export function entitlementResponse(entitlement, privateKeyBase64) {
  return {
    entitlement,
    ...signEntitlement(entitlement, privateKeyBase64),
  };
}
