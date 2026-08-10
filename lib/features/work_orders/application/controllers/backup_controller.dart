import '../services/backup_service.dart';
import '../services/work_order_export_service.dart';
import '../work_order_store.dart';
import 'order_controller.dart';

class BackupController {
  BackupController(
    this._store,
    this._orders, {
    BackupService? backupService,
    WorkOrderExportService? exportService,
  })  : _backupService = backupService ?? BackupService(),
        _exportService = exportService ?? WorkOrderExportService();

  final WorkOrderStore _store;
  final OrderController _orders;
  final BackupService _backupService;
  final WorkOrderExportService _exportService;

  String exportJson() => _exportService.exportJson(_store.data);

  String exportCsv() => _exportService.exportCsv(_store.data);

  Future<bool> importJson(String raw) async {
    try {
      final imported = _backupService.decodeJson(raw);
      final success = await _store.commit(imported);
      if (success) _orders.clearOrderFilters();
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<CsvImportResult?> importCsv(String raw) async {
    try {
      final outcome = _exportService.importCsv(raw, _store.data);
      if (outcome == null) return null;
      if (!await _store.commit(outcome.data)) return null;
      _orders.clearOrderFilters();
      return outcome.result;
    } catch (_) {
      return null;
    }
  }
}
