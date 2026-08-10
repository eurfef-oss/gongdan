import '../domain/entities/work_order.dart';
import '../domain/repositories/work_order_repository.dart';

enum WorkOrderLoadStatus { initial, loading, ready, failure }

class WorkOrderStore {
  WorkOrderStore(this.repository, this.onChanged);

  final WorkOrderRepository repository;
  final void Function() onChanged;

  WorkOrderLoadStatus status = WorkOrderLoadStatus.initial;
  RepairAppData data = RepairAppData.empty();
  Object? error;

  bool get persistenceAvailable => repository is! WorkOrderPersistenceStatus
      ? true
      : (repository as WorkOrderPersistenceStatus).persistenceAvailable;

  Future<void> initialize() async {
    status = WorkOrderLoadStatus.loading;
    error = null;
    onChanged();
    try {
      data = await repository.load();
      status = WorkOrderLoadStatus.ready;
    } catch (value) {
      error = value;
      status = WorkOrderLoadStatus.failure;
    }
    onChanged();
  }

  Future<bool> commit(RepairAppData next) async {
    try {
      await repository.save(next);
      data = next;
      error = null;
      status = WorkOrderLoadStatus.ready;
      onChanged();
      return true;
    } catch (value) {
      error = value;
      status = WorkOrderLoadStatus.failure;
      onChanged();
      return false;
    }
  }
}
