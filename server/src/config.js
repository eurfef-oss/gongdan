import path from 'node:path';
import { fileURLToPath } from 'node:url';

const currentDirectory = path.dirname(fileURLToPath(import.meta.url));
const defaultDataFile = path.resolve(currentDirectory, '../data/license-store.json');

const booleanFromEnv = (value, fallback = false) => {
  if (value == null || value === '') return fallback;
  return value.toLowerCase() === 'true' || value === '1';
};

const configuredPath = process.env.DATA_FILE;

export const config = Object.freeze({
  port: Number.parseInt(process.env.PORT ?? '8787', 10) || 8787,
  nodeEnv: process.env.NODE_ENV ?? 'development',
  productId: process.env.PRODUCT_ID ?? 'repair_pro_lifetime',
  allowTestPurchases: booleanFromEnv(process.env.ALLOW_TEST_PURCHASES, false),
  dataFile: configuredPath
    ? path.resolve(process.cwd(), configuredPath)
    : defaultDataFile,
  androidPackageName:
    process.env.ANDROID_PACKAGE_NAME ?? 'com.example.repairworkorderassistant',
  iosBundleId:
    process.env.IOS_BUNDLE_ID ?? 'com.example.repairworkorderassistant',
  entitlementPrivateKeyBase64:
    process.env.ENTITLEMENT_PRIVATE_KEY_BASE64 ?? '',
});
