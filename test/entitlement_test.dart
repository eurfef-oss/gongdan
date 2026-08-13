import 'package:flutter_test/flutter_test.dart';
import 'package:repair_work_order_assistant/features/monetization/domain/entities/entitlement.dart';

void main() {
  test('free plan enforces the 10 work order limit', () {
    final entitlement = Entitlement.free();

    expect(entitlement.isPro, isFalse);
    expect(
      FeatureAccessService().canCreateOrder(entitlement, 9),
      isTrue,
    );
    expect(
      FeatureAccessService().canCreateOrder(entitlement, 10),
      isFalse,
    );
    expect(entitlement.canUse(ProFeature.statistics), isFalse);
    expect(entitlement.canUse(ProFeature.internalCosts), isFalse);
    expect(entitlement.canUse(ProFeature.documentExport), isTrue);
    expect(entitlement.canUse(ProFeature.customerSignature), isTrue);
    expect(entitlement.canUse(ProFeature.photoAttachments), isTrue);
  });

  test('free plan enforces the 10 customer profile limit', () {
    final entitlement = Entitlement.free();

    expect(
      FeatureAccessService().canCreateCustomer(entitlement, 9),
      isTrue,
    );
    expect(
      FeatureAccessService().canCreateCustomer(entitlement, 10),
      isFalse,
    );
    expect(
      FeatureAccessService().canCreateCustomer(
        Entitlement(
          state: EntitlementState.active,
          plan: 'pro',
          features: const [],
        ),
        10,
      ),
      isTrue,
    );
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
    expect(restored.canUse(ProFeature.internalCosts), isTrue);
  });
}
