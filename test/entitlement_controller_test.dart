import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:repair_work_order_assistant/features/monetization/application/entitlement_controller.dart';
import 'package:repair_work_order_assistant/features/monetization/data/billing_gateway.dart';
import 'package:repair_work_order_assistant/features/monetization/data/purchase_verifier.dart';
import 'package:repair_work_order_assistant/features/monetization/domain/entities/entitlement.dart';
import 'package:repair_work_order_assistant/features/monetization/domain/repositories/entitlement_repository.dart';

class _MemoryEntitlementRepository implements EntitlementRepository {
  Entitlement value = Entitlement.free();

  @override
  Future<void> clear() async => value = Entitlement.free();

  @override
  Future<Entitlement> load() async => value;

  @override
  Future<void> save(Entitlement entitlement) async => value = entitlement;
}

class _FakeBillingGateway implements BillingGateway {
  final StreamController<PurchaseUpdate> updates =
      StreamController<PurchaseUpdate>.broadcast();
  var completed = 0;

  @override
  Stream<PurchaseUpdate> get purchaseUpdates => updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<StoreProduct?> loadProduct() async => const StoreProduct(
        id: proProductId,
        title: 'Professional',
        description: 'Unlocks professional features',
        price: '¥68.00',
      );

  @override
  Future<bool> buyNonConsumable() async => true;

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> complete(PurchaseUpdate update) async => completed++;

  @override
  void dispose() => updates.close();
}

class _FakeVerifier implements PurchaseVerifier {
  @override
  Future<Entitlement> verify(PurchaseUpdate update) async => Entitlement(
        state: EntitlementState.active,
        plan: 'pro',
        features: ProFeature.values.map((feature) => feature.key).toList(),
        productId: proProductId,
        purchaseId: update.purchaseId,
        platform: 'android',
      );
}

PurchaseUpdate _purchasedUpdate() => const PurchaseUpdate(
      eventId: 'event-1',
      productId: proProductId,
      status: PurchaseStatus.purchased,
      purchaseId: 'transaction-1',
      localVerificationData: 'local',
      serverVerificationData: 'server',
      verificationSource: 'Google Play',
      pendingCompletePurchase: true,
    );

void main() {
  test('verified purchase activates and completes the transaction', () async {
    final gateway = _FakeBillingGateway();
    final controller = EntitlementController(
      repository: _MemoryEntitlementRepository(),
      billingGateway: gateway,
      verifier: _FakeVerifier(),
    );
    await controller.initialize();

    gateway.updates.add(_purchasedUpdate());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(controller.isPro, isTrue);
    expect(gateway.completed, 1);
    controller.dispose();
  });
}
