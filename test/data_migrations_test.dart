import 'package:flutter_test/flutter_test.dart';
import 'package:repair_work_order_assistant/features/work_orders/domain/entities/work_order.dart';

void main() {
  test('migrates a version 1 snapshot through the current schema', () {
    final data = RepairAppData.fromJson({
      'version': 1,
      'customers': const [],
      'serviceItems': const [],
      'workOrders': [
        {
          'id': 'legacy-order',
          'number': '20260810-001',
          'items': const [],
        },
      ],
      'settings': const {},
    });

    expect(data.toJson()['version'], currentWorkOrderDataVersion);
    expect(data.payments, isEmpty);
    expect(data.workOrders.single.paid, 0);
    expect(data.workOrders.single.attachments, isEmpty);
  });

  test('normalizes a version 2 settings snapshot in version 3', () {
    final data = RepairAppData.fromJson({
      'version': 2,
      'customers': const [],
      'serviceItems': const [],
      'workOrders': const [],
      'payments': const [],
      'settings': {
        'customServiceItemTypes': ['清洗', '清洗', '  '],
        'dashboardCardOrder': ['customers', 'customers'],
      },
    });

    expect(data.toJson()['version'], 3);
    expect(data.settings.customServiceItemTypes, ['清洗']);
    expect(data.settings.dashboardCardOrder, ['customers']);
  });

  test('rejects a snapshot from a newer schema version', () {
    expect(
      () => RepairAppData.fromJson({
        'version': currentWorkOrderDataVersion + 1,
        'customers': const [],
        'serviceItems': const [],
        'workOrders': const [],
        'payments': const [],
        'settings': const {},
      }),
      throwsFormatException,
    );
  });
}
