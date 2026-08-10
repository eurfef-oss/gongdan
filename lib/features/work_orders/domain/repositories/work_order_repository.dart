import '../entities/work_order.dart';

abstract interface class WorkOrderRepository {
  Future<RepairAppData> load();

  Future<void> save(RepairAppData data);
}

abstract interface class WorkOrderPersistenceStatus {
  bool get persistenceAvailable;
}
