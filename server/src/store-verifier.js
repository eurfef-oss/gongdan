import { createSign } from 'node:crypto';

import { hashPurchaseIdentity } from './entitlement.js';

const googleAndroidPublisherScope =
  'https://www.googleapis.com/auth/androidpublisher';
const defaultGoogleTokenUrl = 'https://oauth2.googleapis.com/token';
const defaultGoogleApiBaseUrl =
  'https://androidpublisher.googleapis.com/androidpublisher/v3';
const googleTokenCache = new Map();

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

function optionalString(value, field, maxLength = 4096) {
  if (value == null || value === '') return '';
  if (typeof value !== 'string' || value.length > maxLength) {
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

  const purchaseId = optionalString(body.purchaseId, 'purchaseId', 1024);
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

  const serverVerificationData = optionalString(
    verificationData.server,
    'verificationData.server',
    8192,
  );
  const localVerificationData = optionalString(
    verificationData.local,
    'verificationData.local',
    8192,
  );
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
    appId: optionalString(body.appId, 'appId', 256),
  };
}

function base64UrlJson(value) {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

function parseGoogleServiceAccount(config) {
  const googleConfig = config.googlePlay ?? {};
  let account = googleConfig.serviceAccount;
  const encoded = googleConfig.serviceAccountJsonBase64;
  const json = googleConfig.serviceAccountJson;

  if (!account && encoded) {
    try {
      account = JSON.parse(Buffer.from(encoded, 'base64').toString('utf8'));
    } catch (_) {
      throw new StoreVerificationError(
        'billing_provider_misconfigured',
        'Google Play service account JSON is invalid',
        503,
      );
    }
  }

  if (!account && json) {
    try {
      account = JSON.parse(json);
    } catch (_) {
      throw new StoreVerificationError(
        'billing_provider_misconfigured',
        'Google Play service account JSON is invalid',
        503,
      );
    }
  }

  if (!account && googleConfig.serviceAccountEmail &&
      googleConfig.serviceAccountPrivateKey) {
    account = {
      client_email: googleConfig.serviceAccountEmail,
      private_key: googleConfig.serviceAccountPrivateKey,
    };
  }

  if (!account || typeof account !== 'object' ||
      typeof account.client_email !== 'string' ||
      typeof account.private_key !== 'string' ||
      !account.client_email.trim() || !account.private_key.trim()) {
    throw new StoreVerificationError(
      'billing_provider_not_configured',
      'Google Play service account is not configured',
      503,
    );
  }

  return {
    clientEmail: account.client_email.trim(),
    privateKey: account.private_key.replaceAll('\\n', '\n'),
  };
}

export function createGoogleServiceAccountAssertion(
  account,
  tokenUrl = defaultGoogleTokenUrl,
  issuedAtSeconds = Math.floor(Date.now() / 1000),
) {
  const header = base64UrlJson({ alg: 'RS256', typ: 'JWT' });
  const claims = base64UrlJson({
    iss: account.clientEmail,
    scope: googleAndroidPublisherScope,
    aud: tokenUrl,
    iat: issuedAtSeconds,
    exp: issuedAtSeconds + 3600,
  });
  const unsigned = `${header}.${claims}`;
  const signature = createSign('RSA-SHA256')
    .update(unsigned)
    .end()
    .sign(account.privateKey)
    .toString('base64url');
  return `${unsigned}.${signature}`;
}

function responseIsOk(response) {
  return response && response.status >= 200 && response.status < 300;
}

async function responseJson(response) {
  try {
    return await response.json();
  } catch (_) {
    return null;
  }
}

async function fetchWithTimeout(fetchImpl, url, options, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetchImpl(url, { ...options, signal: controller.signal });
  } catch (error) {
    if (error?.name === 'AbortError') {
      throw new StoreVerificationError(
        'google_api_unavailable',
        'Google Play verification timed out',
        503,
      );
    }
    throw new StoreVerificationError(
      'google_api_unavailable',
      'Google Play verification is unavailable',
      503,
    );
  } finally {
    clearTimeout(timer);
  }
}

async function googleAccessToken(config, fetchImpl, now) {
  const googleConfig = config.googlePlay ?? {};
  const tokenUrl = googleConfig.tokenUrl ?? defaultGoogleTokenUrl;
  const account = parseGoogleServiceAccount(config);
  const cacheKey = `${account.clientEmail}:${tokenUrl}`;
  const cached = googleTokenCache.get(cacheKey);
  const nowMs = now();
  if (cached && cached.expiresAtMs > nowMs + 60_000) return cached.token;

  const assertion = createGoogleServiceAccountAssertion(
    account,
    tokenUrl,
    Math.floor(nowMs / 1000),
  );
  const response = await fetchWithTimeout(
    fetchImpl,
    tokenUrl,
    {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }).toString(),
    },
    googleConfig.requestTimeoutMs ?? 10000,
  );
  const body = await responseJson(response);
  if (!responseIsOk(response) || typeof body?.access_token !== 'string') {
    throw new StoreVerificationError(
      'google_auth_failed',
      'Google Play service account authentication failed',
      503,
    );
  }

  const expiresInSeconds = Number(body.expires_in) || 3600;
  googleTokenCache.set(cacheKey, {
    token: body.access_token,
    expiresAtMs: nowMs + Math.max(60, expiresInSeconds - 60) * 1000,
  });
  return body.access_token;
}

function googleApiError(response) {
  if (response.status === 400 || response.status === 404) {
    return new StoreVerificationError(
      'invalid_purchase',
      'Google Play purchase token is invalid',
      422,
    );
  }
  if (response.status === 401 || response.status === 403) {
    return new StoreVerificationError(
      'google_api_not_authorized',
      'Google Play API authorization failed',
      503,
    );
  }
  return new StoreVerificationError(
    'google_api_unavailable',
    'Google Play verification is unavailable',
    503,
  );
}

async function googleApiRequest(config, fetchImpl, now, url, options = {}) {
  const googleConfig = config.googlePlay ?? {};
  const token = await googleAccessToken(config, fetchImpl, now);
  const response = await fetchWithTimeout(
    fetchImpl,
    url,
    {
      ...options,
      headers: {
        authorization: `Bearer ${token}`,
        ...(options.headers ?? {}),
      },
    },
    googleConfig.requestTimeoutMs ?? 10000,
  );
  if (!responseIsOk(response)) throw googleApiError(response);
  return response;
}

function googlePurchaseTime(value) {
  const millis = Number(value);
  if (!Number.isFinite(millis) || millis <= 0) return null;
  return new Date(millis).toISOString();
}

async function verifyGooglePlayPurchase(request, config, dependencies) {
  const googleConfig = config.googlePlay ?? {};
  const packageName = googleConfig.packageName ?? config.androidPackageName;
  if (request.appId && request.appId !== packageName) {
    throw new StoreVerificationError(
      'invalid_app',
      'Android application identifier does not match the server configuration',
    );
  }
  const purchaseToken = request.verificationData.server;
  if (!purchaseToken) {
    throw new StoreVerificationError(
      'invalid_request',
      'Google Play purchase token is required',
    );
  }

  const fetchImpl = dependencies.fetchImpl ?? globalThis.fetch;
  if (typeof fetchImpl !== 'function') {
    throw new StoreVerificationError(
      'google_api_unavailable',
      'Google Play verification is unavailable',
      503,
    );
  }
  const now = dependencies.now ?? (() => Date.now());
  const apiBaseUrl = googleConfig.apiBaseUrl ?? defaultGoogleApiBaseUrl;
  const encodedPackage = encodeURIComponent(packageName);
  const encodedProduct = encodeURIComponent(request.productId);
  const encodedToken = encodeURIComponent(purchaseToken);
  const purchaseUrl = `${apiBaseUrl}/applications/${encodedPackage}` +
    `/purchases/products/${encodedProduct}/tokens/${encodedToken}`;
  const response = await googleApiRequest(
    config,
    fetchImpl,
    now,
    purchaseUrl,
  );
  const purchase = await responseJson(response);
  if (!purchase || Number(purchase.purchaseState) !== 0) {
    if (Number(purchase?.purchaseState) === 2) {
      throw new StoreVerificationError(
        'purchase_pending',
        'Google Play purchase is still pending',
        409,
      );
    }
    throw new StoreVerificationError(
      'purchase_not_active',
      'Google Play purchase is not active',
      422,
    );
  }
  // Google documents orderId as an optional field on ProductPurchase. Some
  // valid test/restored purchases omit it, so use the server-verified token
  // as a stable fallback identity instead of rejecting the purchase.
  const orderId = optionalString(purchase.orderId, 'Google Play orderId', 256) ||
    `token-${hashPurchaseIdentity(
      `android:${packageName}:${request.productId}:${purchaseToken}`,
    )}`;

  if (googleConfig.acknowledgePurchases !== false &&
      Number(purchase.acknowledgementState) === 0) {
    const acknowledgeUrl = `${purchaseUrl}:acknowledge`;
    await googleApiRequest(
      config,
      fetchImpl,
      now,
      acknowledgeUrl,
      {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: '{}',
      },
    );
  }

  return {
    verified: true,
    source: 'google_play',
    purchaseId: orderId,
    purchaseToken,
    identityKey: hashPurchaseIdentity(
      `android:${packageName}:${request.productId}:${orderId}:${purchaseToken}`,
    ),
    purchasedAtUtc: googlePurchaseTime(purchase.purchaseTimeMillis),
    purchaseState: Number(purchase.purchaseState),
    acknowledgementState: Number(purchase.acknowledgementState),
  };
}

export function clearGoogleAccessTokenCache() {
  googleTokenCache.clear();
}

export async function verifyStorePurchase(
  request,
  config,
  dependencies = {},
) {
  if (config.allowTestPurchases) {
    return {
      verified: true,
      source: 'development',
      purchaseId: request.purchaseId,
      purchaseToken: request.verificationData.server || null,
      identityKey: request.identityKey,
    };
  }

  if (request.platform === 'android') {
    return verifyGooglePlayPurchase(request, config, dependencies);
  }

  throw new StoreVerificationError(
    'billing_provider_not_configured',
    'Apple App Store verification is not configured',
    503,
  );
}
