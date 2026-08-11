import fs from 'node:fs/promises';
import path from 'node:path';

const emptyState = () => ({
  version: 1,
  purchases: [],
  entitlements: [],
  events: [],
});

const clone = (value) => JSON.parse(JSON.stringify(value));

export class LicenseStore {
  constructor(filePath) {
    this.filePath = filePath;
    this.state = emptyState();
    this.writeQueue = Promise.resolve();
  }

  async init() {
    try {
      const raw = await fs.readFile(this.filePath, 'utf8');
      const parsed = JSON.parse(raw);
      this.state = {
        version: 1,
        purchases: Array.isArray(parsed.purchases) ? parsed.purchases : [],
        entitlements: Array.isArray(parsed.entitlements)
          ? parsed.entitlements
          : [],
        events: Array.isArray(parsed.events) ? parsed.events : [],
      };
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
      await this._persist();
    }
  }

  findPurchase(platform, purchaseId) {
    return this.state.purchases.find(
      (item) => item.platform === platform && item.purchaseId === purchaseId,
    );
  }

  findPurchaseByIdentity(identityKey) {
    return this.state.purchases.find((item) => item.identityKey === identityKey);
  }

  findEntitlement(purchaseKey) {
    return this.state.entitlements.find((item) => item.purchaseKey === purchaseKey);
  }

  async savePurchase(purchase) {
    const index = this.state.purchases.findIndex(
      (item) => item.purchaseKey === purchase.purchaseKey,
    );
    if (index === -1) {
      this.state.purchases.push(clone(purchase));
    } else {
      this.state.purchases[index] = clone(purchase);
    }
    await this._persist();
  }

  async saveEntitlement(entitlement) {
    const index = this.state.entitlements.findIndex(
      (item) => item.purchaseKey === entitlement.purchaseKey,
    );
    if (index === -1) {
      this.state.entitlements.push(clone(entitlement));
    } else {
      this.state.entitlements[index] = clone(entitlement);
    }
    await this._persist();
  }

  hasEvent(eventId) {
    return this.state.events.some((event) => event.eventId === eventId);
  }

  async appendEvent(event) {
    if (this.hasEvent(event.eventId)) return false;
    this.state.events.push(clone(event));
    await this._persist();
    return true;
  }

  async _persist() {
    const write = async () => {
      await fs.mkdir(path.dirname(this.filePath), { recursive: true });
      const temporary = `${this.filePath}.tmp`;
      await fs.writeFile(temporary, `${JSON.stringify(this.state, null, 2)}\n`, 'utf8');
      await fs.rename(temporary, this.filePath);
    };
    this.writeQueue = this.writeQueue.then(write, write);
    return this.writeQueue;
  }
}
