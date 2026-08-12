import mariadb from 'mariadb';

import { hashPurchaseIdentity } from './entitlement.js';

const toDatabaseDateTime = (value) => {
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new TypeError(`invalid date value: ${value}`);
  }
  return date.toISOString().slice(0, 23).replace('T', ' ');
};

const fromDatabaseDateTime = (value) => {
  if (value == null) return null;
  if (value instanceof Date) return value.toISOString();
  const text = String(value).trim();
  if (!text) return null;
  const iso = text.includes('T') ? text : text.replace(' ', 'T');
  return iso.endsWith('Z') ? iso : `${iso}Z`;
};

const parseFeatures = (value) => {
  if (Array.isArray(value)) return value.map(String);
  if (typeof value !== 'string' || value.trim() === '') return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed.map(String) : [];
  } catch (_) {
    return [];
  }
};

const mapPurchase = (row) => row && ({
  purchaseKey: row.purchase_key,
  identityKey: row.identity_key,
  platform: row.platform,
  productId: row.product_id,
  purchaseId: row.purchase_id,
  purchaseToken: row.purchase_token,
  source: row.source,
  status: row.status,
  purchasedAtUtc: fromDatabaseDateTime(row.purchased_at_utc),
  updatedAtUtc: fromDatabaseDateTime(row.updated_at_utc),
});

const mapEntitlement = (row) => row && ({
  purchaseKey: row.purchase_key,
  state: row.state,
  plan: row.plan,
  productId: row.product_id,
  purchaseId: row.purchase_id,
  platform: row.platform,
  features: parseFeatures(row.features_json),
  activatedAtUtc: fromDatabaseDateTime(row.activated_at_utc),
  verifiedAtUtc: fromDatabaseDateTime(row.verified_at_utc),
  expiresAtUtc: fromDatabaseDateTime(row.expires_at_utc),
});

const purchaseColumns = `
  purchase_key,
  identity_key,
  platform,
  product_id,
  purchase_id,
  purchase_token,
  source,
  status,
  purchased_at_utc,
  updated_at_utc
`;

const entitlementColumns = `
  purchase_key,
  state,
  plan,
  product_id,
  purchase_id,
  platform,
  features_json,
  activated_at_utc,
  verified_at_utc,
  expires_at_utc
`;

export class MariaDbLicenseStore {
  constructor(database) {
    this.pool = mariadb.createPool({
      host: database.host,
      port: database.port,
      user: database.user,
      password: database.password,
      database: database.name,
      connectionLimit: database.connectionLimit,
      dateStrings: true,
      insertIdAsNumber: true,
    });
  }

  async init() {
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS purchases (
        purchase_key CHAR(64) NOT NULL,
        identity_key CHAR(64) NOT NULL,
        platform VARCHAR(16) NOT NULL,
        product_id VARCHAR(128) NOT NULL,
        purchase_id VARCHAR(1024) NOT NULL,
        purchase_token VARCHAR(8192) NULL,
        source VARCHAR(64) NOT NULL,
        status VARCHAR(32) NOT NULL,
        purchased_at_utc DATETIME(3) NOT NULL,
        updated_at_utc DATETIME(3) NOT NULL,
        PRIMARY KEY (purchase_key),
        UNIQUE KEY uq_purchases_identity (identity_key),
        KEY idx_purchases_platform (platform)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
    await this.pool.query(`
      ALTER TABLE purchases
        ADD COLUMN IF NOT EXISTS purchase_token VARCHAR(8192) NULL AFTER purchase_id
    `);
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS entitlements (
        purchase_key CHAR(64) NOT NULL,
        state VARCHAR(32) NOT NULL,
        plan VARCHAR(32) NOT NULL,
        product_id VARCHAR(128) NOT NULL,
        purchase_id VARCHAR(1024) NOT NULL,
        platform VARCHAR(16) NOT NULL,
        features_json LONGTEXT NOT NULL,
        activated_at_utc DATETIME(3) NOT NULL,
        verified_at_utc DATETIME(3) NOT NULL,
        expires_at_utc DATETIME(3) NULL,
        PRIMARY KEY (purchase_key),
        CONSTRAINT fk_entitlements_purchase
          FOREIGN KEY (purchase_key) REFERENCES purchases(purchase_key)
          ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS webhook_events (
        event_id VARCHAR(255) NOT NULL,
        platform VARCHAR(16) NOT NULL,
        received_at_utc DATETIME(3) NOT NULL,
        payload_hash CHAR(64) NOT NULL,
        PRIMARY KEY (event_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
  }

  async findPurchase(platform, purchaseId) {
    const purchaseKey = hashPurchaseIdentity(`${platform}:${purchaseId}`);
    const rows = await this.pool.query(
      `SELECT ${purchaseColumns} FROM purchases WHERE purchase_key = ? LIMIT 1`,
      [purchaseKey],
    );
    return mapPurchase(rows[0]);
  }

  async findPurchaseByIdentity(identityKey) {
    const rows = await this.pool.query(
      `SELECT ${purchaseColumns} FROM purchases WHERE identity_key = ? LIMIT 1`,
      [identityKey],
    );
    return mapPurchase(rows[0]);
  }

  async findPurchaseByToken(platform, productId, purchaseToken) {
    if (!purchaseToken) return undefined;
    const rows = await this.pool.query(
      `
        SELECT ${purchaseColumns}
        FROM purchases
        WHERE platform = ? AND product_id = ? AND purchase_token = ?
        LIMIT 1
      `,
      [platform, productId, purchaseToken],
    );
    return mapPurchase(rows[0]);
  }

  async findEntitlement(purchaseKey) {
    const rows = await this.pool.query(
      `SELECT ${entitlementColumns} FROM entitlements WHERE purchase_key = ? LIMIT 1`,
      [purchaseKey],
    );
    return mapEntitlement(rows[0]);
  }

  async savePurchase(purchase, connection = this.pool) {
    await connection.query(
      `
        INSERT INTO purchases (${purchaseColumns})
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          identity_key = VALUES(identity_key),
          platform = VALUES(platform),
          product_id = VALUES(product_id),
          purchase_id = VALUES(purchase_id),
          purchase_token = VALUES(purchase_token),
          source = VALUES(source),
          status = VALUES(status),
          purchased_at_utc = VALUES(purchased_at_utc),
          updated_at_utc = VALUES(updated_at_utc)
      `,
      [
        purchase.purchaseKey,
        purchase.identityKey,
        purchase.platform,
        purchase.productId,
        purchase.purchaseId,
        purchase.purchaseToken ?? null,
        purchase.source,
        purchase.status,
        toDatabaseDateTime(purchase.purchasedAtUtc),
        toDatabaseDateTime(purchase.updatedAtUtc),
      ],
    );
  }

  async saveEntitlement(entitlement, connection = this.pool) {
    await connection.query(
      `
        INSERT INTO entitlements (${entitlementColumns})
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          state = VALUES(state),
          plan = VALUES(plan),
          product_id = VALUES(product_id),
          purchase_id = VALUES(purchase_id),
          platform = VALUES(platform),
          features_json = VALUES(features_json),
          activated_at_utc = VALUES(activated_at_utc),
          verified_at_utc = VALUES(verified_at_utc),
          expires_at_utc = VALUES(expires_at_utc)
      `,
      [
        entitlement.purchaseKey,
        entitlement.state,
        entitlement.plan,
        entitlement.productId,
        entitlement.purchaseId,
        entitlement.platform,
        JSON.stringify(entitlement.features ?? []),
        toDatabaseDateTime(entitlement.activatedAtUtc),
        toDatabaseDateTime(entitlement.verifiedAtUtc),
        entitlement.expiresAtUtc == null
          ? null
          : toDatabaseDateTime(entitlement.expiresAtUtc),
      ],
    );
  }

  async savePurchaseAndEntitlement(purchase, entitlement) {
    const connection = await this.pool.getConnection();
    try {
      await connection.beginTransaction();
      await this.savePurchase(purchase, connection);
      await this.saveEntitlement(entitlement, connection);
      await connection.commit();
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async appendEvent(event) {
    const result = await this.pool.query(
      `
        INSERT INTO webhook_events
          (event_id, platform, received_at_utc, payload_hash)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE event_id = event_id
      `,
      [
        event.eventId,
        event.platform,
        toDatabaseDateTime(event.receivedAtUtc),
        event.payloadHash,
      ],
    );
    return result.affectedRows === 1;
  }

  async close() {
    await this.pool.end();
  }
}
