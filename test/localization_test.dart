import 'package:flutter_test/flutter_test.dart';
import 'package:repair_work_order_assistant/features/work_orders/domain/entities/work_order.dart';
import 'package:repair_work_order_assistant/features/work_orders/application/services/work_order_export_service.dart';
import 'package:repair_work_order_assistant/l10n/model_localizations.dart';
import 'package:repair_work_order_assistant/l10n/app_strings.dart';

void main() {
  test('English lookup covers model and dynamic messages', () {
    expect(localizedText('en', '草稿'), 'Draft');
    expect(localizedText('en', '部分收款'), 'Partially paid');
    expect(
      localizedText('en', '{count} 张有效', {'count': 3}),
      '3 active',
    );
    expect(
      localizedText('en', '购买验证失败（500）'),
      'Purchase verification failed (500).',
    );
  });

  test('built-in service templates localize while custom data stays unchanged',
      () {
    final source = seedData();
    final builtInTemplate = source.serviceItems.first;
    final builtInOrderItem = source.workOrders.first.items.first;
    final customTemplate = builtInTemplate.copyWith(name: '我的专属服务');
    final customOrderItem = builtInOrderItem.copyWith(name: '客户指定项目');

    expect(
      localizedServiceItemNameForLocale('en', builtInTemplate),
      'Deep AC cleaning',
    );
    expect(localizedUnitForLocale('en', builtInTemplate.unit), 'unit');
    expect(
      localizedWorkOrderItemNameForLocale('en', builtInOrderItem),
      'On-site inspection fee',
    );
    expect(localizedUnitForLocale('en', builtInOrderItem.unit), 'time');
    expect(
      localizedServiceItemNameForLocale('en', customTemplate),
      '我的专属服务',
    );
    expect(
      localizedWorkOrderItemNameForLocale('en', customOrderItem),
      '客户指定项目',
    );
  });

  test('CSV export uses English labels and English CSV can be imported', () {
    final source = seedData();
    final englishData = source.copyWith(
      settings: source.settings.copyWith(languageCode: 'en'),
    );
    final service = WorkOrderExportService();

    final csv = service.exportCsv(englishData);

    expect(csv, contains('Work order number'));
    expect(csv, contains(r'$'));
    expect(csv, contains('Status'));
    expect(csv, contains('During repair'));
    expect(csv, contains('On-site inspection fee 1.0time'));
    expect(csv, contains('Deep AC cleaning 1.0unit'));

    final imported = service.importCsv(csv, RepairAppData.empty());
    expect(imported, isNotNull);
    expect(imported!.result.totalOrders, source.workOrders.length);
    expect(imported.data.customers, isNotEmpty);
  });

  test('language preference survives settings JSON round-trip', () {
    const settings = RepairAppSettings(
      languageCode: 'en',
      currencySymbol: '€',
    );

    final restored = RepairAppSettings.fromJson(settings.toJson());

    expect(restored.languageCode, 'en');
    expect(restored.currencySymbol, '€');
    expect(
      RepairAppSettings.fromJson(const {'languageCode': 'en'}).currencySymbol,
      defaultCurrencySymbol,
    );
  });
}
