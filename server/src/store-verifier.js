import { hashPurchaseIdentity } from './entitlement.js';

export class StoreVerificationError extends Error {
  constructor(code, message, statusCode = 422) {
    super(message);
    this.name = 'StoreVerificationError';
    this.code = code;
    this.statusCode = statusCode;
  }
}

function requiredString(value, field, maxLength = 4096) {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new StoreVerificationError('invalid_request', `${field} is required`);
  }
  if (value.length > maxLength) {
    throw new StoreVerificationError('invalid_request', `${field} is too long`);
  }
  return value.trim();
}

export function validatePurchaseRequest(body, expectedProductId) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new StoreVerificationError('invalid_request', 'request body must be an object');
  }
  const platform = requiredString(body.platform, 'platform', 16).toLowerCase();
  if (platform !== 'ios' && platform !== 'android') {
    throw new StoreVerificationError('invalid_request', 'platform must be ios or android');
  }
  const productId = requiredString(body.productId, 'productId', 128);
  if (productId !== expectedProductId) {
    throw new StoreVerificationError('invalid_product', 'unknown productId');
  }

  const purchaseId = typeof body.purchaseId === 'string'
    ? body.purchaseId.trim()
    : '';
  const verificationData = body.verificationData;
  if (
    !verificationData ||
    typeof verificationData !== 'object' ||
    Array.isArray(verificationData)
  ) {
    throw new StoreVerificationError(
      'invalid_request',
      'verificationData must be an object',
    );
  }

  const serverVerificationData = typeof verificationData.server === 'string'
    ? verificationData.server.trim()
    : '';
  const localVerificationData = typeof verificationData.local === 'string'
    ? verificationData.local.trim()
    : '';
  if (!purchaseId && !serverVerificationData && !localVerificationData) {
    throw new StoreVerificationError(
      'invalid_request',
      'a purchase identifier or verification data is required',
    );
  }

  const identitySource = `${platform}:${productId}:${purchaseId}:${serverVerificationData || localVerificationData}`;
  return {
    platform,
    productId,
    purchaseId: purchaseId || hashPurchaseIdentity(identitySource),
    identityKey: hashPurchaseIdentity(identitySource),
    verificationData: {
      source: typeof verificationData.source === 'string'
        ? verificationData.source
        : platform,
      server: serverVerificationData,
      local: localVerificationData,
    },
    appId: typeof body.appId === 'string' ? body.appId.trim() : '',
  };
}

export async function verifyStorePurchase(request, config) {
  if (config.allowTestPurchases) {
    return {
      verified: true,
      source: 'development',
      purchaseId: request.purchaseId,
      identityKey: request.identityKey,
    };
  }

  // The platform-specific verification boundary is deliberately explicit. It
  // must never silently trust a client-provided purchase in production.
  throw new StoreVerificationError(
    'billing_provider_not_configured',
    `No ${request.platform} store verifier is configured`,
    503,
  );
}
