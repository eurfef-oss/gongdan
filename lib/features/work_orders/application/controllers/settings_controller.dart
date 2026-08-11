import '../../domain/entities/work_order.dart';
import '../work_order_store.dart';

const dashboardCardIds = <String>[
  'summaryMetrics',
  'statusProgress',
  'recentOrders',
  'quickActions',
  'warrantyReminder',
];

class SettingsController {
  SettingsController(this._store);

  final WorkOrderStore _store;

  List<String> get dashboardCardOrder {
    final result = <String>[];
    for (final id in _store.data.settings.dashboardCardOrder) {
      if (dashboardCardIds.contains(id) && !result.contains(id)) {
        result.add(id);
      }
    }
    for (final id in dashboardCardIds) {
      if (!result.contains(id)) result.add(id);
    }
    return result;
  }

  Set<String> get dashboardHiddenCards =>
      _store.data.settings.dashboardHiddenCards
          .where(dashboardCardIds.contains)
          .toSet();

  Future<bool> updateDashboardCardOrder(List<String> order) async {
    final normalized = <String>[];
    for (final id in order) {
      if (dashboardCardIds.contains(id) && !normalized.contains(id)) {
        normalized.add(id);
      }
    }
    for (final id in dashboardCardIds) {
      if (!normalized.contains(id)) normalized.add(id);
    }
    return _store.commit(
      _store.data.copyWith(
        settings: _store.data.settings.copyWith(
          dashboardCardOrder: normalized,
        ),
      ),
    );
  }

  Future<bool> setDashboardCardVisible(String id, bool visible) {
    return setDashboardCardsVisible([id], visible);
  }

  Future<bool> setDashboardCardsVisible(
    Iterable<String> ids,
    bool visible,
  ) async {
    final validIds = ids.where(dashboardCardIds.contains).toSet();
    if (validIds.isEmpty) return false;
    final hidden = {...dashboardHiddenCards};
    if (visible) {
      hidden.removeAll(validIds);
    } else {
      hidden.addAll(validIds);
    }
    return _store.commit(
      _store.data.copyWith(
        settings: _store.data.settings.copyWith(
          dashboardHiddenCards:
              dashboardCardIds.where(hidden.contains).toList(),
        ),
      ),
    );
  }

  Future<void> updateSettings(RepairAppSettings settings) async {
    await _store.commit(_store.data.copyWith(settings: settings));
  }

  Future<void> resetToDemo() async {
    final demo = seedData();
    await _store.commit(
      demo.copyWith(
        settings: demo.settings.copyWith(
          hasSeenWelcome: _store.data.settings.hasSeenWelcome,
        ),
      ),
    );
  }
}
