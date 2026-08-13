import '../../domain/entities/work_order.dart';
import '../work_order_store.dart';

class CostController {
  CostController(this._store);

  final WorkOrderStore _store;

  List<CostType> get costTypes => [..._store.data.settings.costTypes];

  List<CostType> get enabledCostTypes =>
      costTypes.where((item) => item.enabled).toList();

  Future<bool> saveInternalCosts(
    String orderId,
    List<WorkOrderCost> costs,
  ) async {
    final orderIndex =
        _store.data.workOrders.indexWhere((order) => order.id == orderId);
    if (orderIndex < 0 || _store.data.workOrders[orderIndex].isTrashed) {
      return false;
    }
    final normalized = costs
        .map(
          (cost) => cost.copyWith(
            typeId: cost.typeId.trim(),
            typeName:
                cost.typeName.trim().isEmpty ? '其他' : cost.typeName.trim(),
            amount: money(cost.amount < 0 ? 0 : cost.amount),
            note: cost.note.trim(),
          ),
        )
        .where((cost) => cost.typeName.isNotEmpty && cost.amount > 0)
        .toList();
    final orders = [..._store.data.workOrders];
    orders[orderIndex] = orders[orderIndex].copyWith(
      internalCosts: normalized,
      updatedAt: DateTime.now(),
    );
    return _store.commit(_store.data.copyWith(workOrders: orders));
  }

  Future<bool> addCostType(String value) async {
    final name = _cleanName(value);
    if (!_isValidName(name)) return false;
    final types = [
      ...costTypes,
      CostType(id: idFor('cost_type'), name: name, enabled: true)
    ];
    return _store.commit(
      _store.data.copyWith(
        settings: _store.data.settings.copyWith(costTypes: types),
      ),
    );
  }

  Future<bool> renameCostType(String id, String value) async {
    final name = _cleanName(value);
    if (!_isValidName(name, excludingId: id)) return false;
    final types = costTypes
        .map((item) => item.id == id ? item.copyWith(name: name) : item)
        .toList();
    if (!types.any((item) => item.id == id)) return false;
    return _store.commit(
      _store.data.copyWith(
        settings: _store.data.settings.copyWith(costTypes: types),
      ),
    );
  }

  Future<bool> setCostTypeEnabled(String id, bool enabled) async {
    final types = costTypes
        .map((item) => item.id == id ? item.copyWith(enabled: enabled) : item)
        .toList();
    if (!types.any((item) => item.id == id)) return false;
    return _store.commit(
      _store.data.copyWith(
        settings: _store.data.settings.copyWith(costTypes: types),
      ),
    );
  }

  Future<bool> deleteCostType(String id) async {
    final types = costTypes;
    if (!types.any((item) => item.id == id)) return false;
    final inUse = _store.data.workOrders.any(
      (order) => order.internalCosts.any((cost) => cost.typeId == id),
    );
    if (inUse) return false;
    return _store.commit(
      _store.data.copyWith(
        settings: _store.data.settings.copyWith(
          costTypes: types.where((item) => item.id != id).toList(),
        ),
      ),
    );
  }

  bool _isValidName(String name, {String? excludingId}) {
    if (name.isEmpty || name.length > 30) return false;
    return !costTypes.any(
      (item) =>
          item.id != excludingId &&
          item.name.toLowerCase() == name.toLowerCase(),
    );
  }

  static String _cleanName(String value) => value.trim();
}
