import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/entities/entitlement.dart';
import '../domain/repositories/entitlement_repository.dart';
import 'purchase_verifier.dart';

class PlatformSecureValueStore implements SecureValueStore {
  PlatformSecureValueStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class LocalEntitlementRepository implements EntitlementRepository {
  LocalEntitlementRepository({SecureValueStore? store})
      : _store = store ?? PlatformSecureValueStore();

  static const storageKey = 'repair_work_order_assistant:entitlement:v1';

  final SecureValueStore _store;

  @override
  Future<Entitlement> load() async {
    try {
      final raw = await _store.read(storageKey);
      if (raw == null || raw.trim().isEmpty) return Entitlement.free();
      final value = jsonDecode(raw);
      if (value is! Map) return Entitlement.free();
      final entitlement = await decodeStoredEntitlement(
        Map<String, Object?>.from(value),
      );
      return entitlement?.isPro == true ? entitlement! : Entitlement.free();
    } catch (_) {
      return Entitlement.free();
    }
  }

  @override
  Future<void> save(Entitlement entitlement) async {
    await _store.write(storageKey, entitlement.encode());
  }

  @override
  Future<void> clear() => _store.delete(storageKey);
}
