import '../entities/entitlement.dart';

abstract interface class EntitlementRepository {
  Future<Entitlement> load();

  Future<void> save(Entitlement entitlement);

  Future<void> clear();
}

abstract interface class SecureValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}
