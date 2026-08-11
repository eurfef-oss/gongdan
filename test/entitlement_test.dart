import 'package:flutter_test/flutter_test.dart';
import 'package:repair_work_order_assistant/features/monetization/domain/entities/entitlement.dart';

void main() {
  test('free plan enforces the 30 work order limit', () {
    final entitlement = Entitlement.free();

    expect(entitlement.isPro, isFalse);
    expect(
      FeatureAccessService().canCreateOrder(entitlement, 29),
      isTrue,
    );
    expect(
      FeatureAccessService().canCreateOrder(entitlement, 30),
      isFalse,
    );
    expect(entitlement.canUse(ProFeature.statistics), isFalse);
  });

  test('professional entitlement round trips through JSON', () {
    final activated = Entitlement(
      state: EntitlementState.active,
      plan: 'pro',
      features: ProFeature.values.map((feature) => feature.key).toList(),
      productId: proProductId,
      purchaseId: 'transaction-1',
      platform: 'android',
      activatedAt: DateTime.utc(2026, 8, 11, 10),
      verifiedAt: DateTime.utc(2026, 8, 11, 10),
    );

    final restored = Entitlement.fromJson(activated.toJson());

    expect(restored.isPro, isTrue);
    expect(restored.productId, proProductId);
    expect(restored.purchaseId, 'transaction-1');
    expect(restored.canUse(ProFeature.documentExport), isTrue);
  });
}
