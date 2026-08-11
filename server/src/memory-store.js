const clone = (value) => JSON.parse(JSON.stringify(value));

export class MemoryLicenseStore {
  constructor() {
    this.purchases = [];
    this.entitlements = [];
    this.events = [];
  }

  async init() {}

  findPurchase(platform, purchaseId) {
    return this.purchases.find(
      (item) => item.platform === platform && item.purchaseId === purchaseId,
    );
  }

  findPurchaseByIdentity(identityKey) {
    return this.purchases.find((item) => item.identityKey === identityKey);
  }

  findEntitlement(purchaseKey) {
    return this.entitlements.find((item) => item.purchaseKey === purchaseKey);
  }

  async savePurchase(purchase) {
    const index = this.purchases.findIndex(
      (item) => item.purchaseKey === purchase.purchaseKey,
    );
    const value = clone(purchase);
    if (index === -1) this.purchases.push(value);
    else this.purchases[index] = value;
  }

  async saveEntitlement(entitlement) {
    const index = this.entitlements.findIndex(
      (item) => item.purchaseKey === entitlement.purchaseKey,
    );
    const value = clone(entitlement);
    if (index === -1) this.entitlements.push(value);
    else this.entitlements[index] = value;
  }

  async savePurchaseAndEntitlement(purchase, entitlement) {
    await this.savePurchase(purchase);
    await this.saveEntitlement(entitlement);
  }

  async appendEvent(event) {
    if (this.events.some((item) => item.eventId === event.eventId)) return false;
    this.events.push(clone(event));
    return true;
  }

  async close() {}
}
