import 'package:flutter_test/flutter_test.dart';
import 'package:repair_work_order_assistant/features/monetization/data/local_entitlement_repository.dart';
import 'package:repair_work_order_assistant/features/monetization/domain/entities/entitlement.dart';
import 'package:repair_work_order_assistant/features/monetization/domain/repositories/entitlement_repository.dart';

class _MemorySecureStore implements SecureValueStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  test('stores and loads a local professional entitlement', () async {
    final store = _MemorySecureStore();
    final repository = LocalEntitlementRepository(store: store);
    final entitlement = Entitlement(
      state: EntitlementState.active,
      plan: 'pro',
      features: const ['statistics'],
      productId: proProductId,
      purchaseId: 'local-transaction',
    );

    await repository.save(entitlement);
    final loaded = await repository.load();

    expect(loaded.isPro, isTrue);
    expect(loaded.purchaseId, 'local-transaction');
  });

  test('malformed local data falls back to free plan', () async {
    final store = _MemorySecureStore()
      ..values[LocalEntitlementRepository.storageKey] = '{not-json';
    final repository = LocalEntitlementRepository(store: store);

    final loaded = await repository.load();

    expect(loaded.isPro, isFalse);
    expect(loaded.state, EntitlementState.free);
  });
}
