const booleanFromEnv = (value, fallback = false) => {
  if (value == null || value === '') return fallback;
  return value.toLowerCase() === 'true' || value === '1';
};

export const config = Object.freeze({
  port: Number.parseInt(process.env.PORT ?? '8787', 10) || 8787,
  host: process.env.HOST ?? '127.0.0.1',
  nodeEnv: process.env.NODE_ENV ?? 'development',
  productId: process.env.PRODUCT_ID ?? 'repair_pro_lifetime',
  allowTestPurchases: booleanFromEnv(process.env.ALLOW_TEST_PURCHASES, false),
  storeDriver: process.env.STORE_DRIVER ?? 'mariadb',
  database: {
    host: process.env.DB_HOST ?? '127.0.0.1',
    port: Number.parseInt(process.env.DB_PORT ?? '3306', 10) || 3306,
    name: process.env.DB_NAME ?? 'repair_license',
    user: process.env.DB_USER ?? 'repair_license',
    password: process.env.DB_PASSWORD ?? '',
    connectionLimit:
      Number.parseInt(process.env.DB_CONNECTION_LIMIT ?? '10', 10) || 10,
  },
  androidPackageName:
    process.env.ANDROID_PACKAGE_NAME ?? 'com.example.repairworkorderassistant',
  iosBundleId:
    process.env.IOS_BUNDLE_ID ?? 'com.example.repairworkorderassistant',
  entitlementPrivateKeyBase64:
    process.env.ENTITLEMENT_PRIVATE_KEY_BASE64 ?? '',
});
