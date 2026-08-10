import 'package:flutter_test/flutter_test.dart';
import 'package:repair_work_order_assistant/features/work_orders/application/work_order_controller.dart';
import 'package:repair_work_order_assistant/features/work_orders/domain/entities/work_order.dart';
import 'package:repair_work_order_assistant/features/work_orders/domain/repositories/work_order_repository.dart';

class _FakeWorkOrderRepository implements WorkOrderRepository {
  RepairAppData value = RepairAppData.empty();

  @override
  Future<RepairAppData> load() async => value;

  @override
  Future<void> save(RepairAppData data) async => value = data;
}

void main() {
  test('work order calculates discount and outstanding amount', () {
    final order = emptyWorkOrder(
      id: 'order-1',
      number: '20260805-001',
    ).copyWith(
      items: [
        const WorkOrderItem(
          id: 'item-1',
          name: '检测费',
          type: ServiceItemType.inspection,
          quantity: 2,
          unit: '次',
          unitPrice: 80,
        ),
      ],
      discount: 10,
    );

    expect(order.subtotal, 160);
    expect(order.total, 150);
    expect(order.outstanding, 150);
    expect(order.paymentStatus, PaymentStatus.unpaid);
  });

  test('work order copyWith can clear nullable fields', () {
    final appointment = DateTime(2026, 8, 5, 10, 30);
    final warrantyStart = DateTime(2026, 8, 5);
    final warrantyEnd = DateTime(2026, 9, 4);
    final confirmedAt = DateTime(2026, 8, 5, 10, 35);
    final repairStartedAt = DateTime(2026, 8, 5, 10, 40);
    final order =
        emptyWorkOrder(id: 'order-clear', number: '20260805-003').copyWith(
      appointmentAt: appointment,
      warrantyStart: warrantyStart,
      warrantyEnd: warrantyEnd,
      signatureData: 'data:image/png;base64,signature',
      quoteConfirmedAt: confirmedAt,
      repairStartedAt: repairStartedAt,
    );

    final cleared = order.copyWith(
      appointmentAt: null,
      warrantyStart: null,
      warrantyEnd: null,
      signatureData: null,
      quoteConfirmedAt: null,
      repairStartedAt: null,
    );

    expect(cleared.appointmentAt, isNull);
    expect(cleared.warrantyStart, isNull);
    expect(cleared.warrantyEnd, isNull);
    expect(cleared.signatureData, isNull);
    expect(cleared.quoteConfirmedAt, isNull);
    expect(cleared.repairStartedAt, isNull);
    expect(
      WorkOrder.fromJson(order.toJson()).repairStartedAt,
      isNotNull,
    );
  });

  test('controller records partial payment and restores JSON backup', () async {
    final repository = _FakeWorkOrderRepository();
    final controller = WorkOrderController(repository);
    await controller.initialize();
    final order =
        emptyWorkOrder(id: 'order-2', number: '20260805-002').copyWith(
      items: [
        const WorkOrderItem(
          id: 'item-2',
          name: '上门服务',
          type: ServiceItemType.visit,
          quantity: 1,
          unit: '次',
          unitPrice: 200,
        ),
      ],
      appointmentAt: DateTime(2026, 8, 5, 9),
    );

    await controller.saveOrder(order);
    controller.setCreatedDateFilter(order.createdAt);
    expect(controller.filteredOrders,
        contains(predicate<WorkOrder>((item) => item.id == order.id)));
    controller.setServiceDateFilter(order.appointmentAt);
    expect(controller.filteredOrders,
        contains(predicate<WorkOrder>((item) => item.id == order.id)));
    controller.setCustomerFilter('missing-customer');
    expect(controller.filteredOrders, isEmpty);
    controller.setCustomerFilter(null);
    controller.setDeviceTypeFilter('missing-device');
    expect(controller.filteredOrders, isEmpty);
    controller.setDeviceTypeFilter(null);
    controller.setCreatedDateFilter(DateTime(2020, 1, 1));
    expect(controller.filteredOrders, isEmpty);
    controller.clearOrderFilters();
    expect(
      await controller.recordPayment(
        orderId: order.id,
        amount: 80,
        method: PaymentMethod.cash,
      ),
      isTrue,
    );
    expect(
        controller.orderById(order.id)?.paymentStatus, PaymentStatus.partial);
    expect(controller.orderById(order.id)?.outstanding, 120);
    await controller.saveOrder(
      controller
          .orderById(order.id)!
          .copyWith(status: WorkOrderStatus.completed),
    );
    expect(
      controller.orderById(order.id)?.status,
      WorkOrderStatus.awaitingPayment,
    );
    expect(controller.exportCsv(), contains('收款记录'));
    expect(controller.exportCsv(), contains('现金'));
    expect(
      await controller.recordPayment(
        orderId: order.id,
        amount: 121,
        method: PaymentMethod.transfer,
      ),
      isFalse,
    );

    final backup = controller.exportJson();
    await controller.importJson(
        '{"customers": [], "serviceItems": [], "workOrders": [], "payments": [], "settings": {}}');
    expect(controller.data.workOrders, isEmpty);
    expect(await controller.importJson(backup), isTrue);
    expect(controller.orderById(order.id)?.outstanding, 120);
    expect(controller.paymentsFor(order.id), hasLength(1));
    controller.dispose();
  });

  test('new work orders become pending confirmation only when ready', () async {
    final repository = _FakeWorkOrderRepository();
    final controller = WorkOrderController(repository);
    await controller.initialize();

    final incomplete = emptyWorkOrder(
      id: 'order-draft',
      number: '20260805-009',
    ).copyWith(faultDescription: '客户描述了问题，但还未关联客户');
    expect(await controller.saveOrder(incomplete), isTrue);
    expect(controller.orderById(incomplete.id)?.status, WorkOrderStatus.draft);

    final complete = emptyWorkOrder(
      id: 'order-pending',
      number: '20260805-010',
      customerId: 'customer-1',
    ).copyWith(faultDescription: '无法制冷');
    expect(await controller.saveOrder(complete), isTrue);
    expect(controller.orderById(complete.id)?.status,
        WorkOrderStatus.pendingConfirmation);
    controller.dispose();
  });

  test('confirming a quote starts repair and records timestamps', () async {
    final repository = _FakeWorkOrderRepository();
    final controller = WorkOrderController(repository);
    await controller.initialize();
    final order = emptyWorkOrder(
      id: 'order-start',
      number: '20260805-011',
      customerId: 'customer-1',
    ).copyWith(
      faultDescription: '无法制冷',
      items: [
        const WorkOrderItem(
          id: 'item-start',
          name: '检测费',
          type: ServiceItemType.inspection,
          quantity: 1,
          unit: '次',
          unitPrice: 80,
        ),
      ],
    );
    await controller.saveOrder(order);
    expect(controller.orderById(order.id)?.status,
        WorkOrderStatus.pendingConfirmation);

    await controller.advanceStatus(order.id);
    final started = controller.orderById(order.id)!;
    expect(started.status, WorkOrderStatus.repairing);
    expect(started.quoteConfirmedAt, isNotNull);
    expect(started.quoteConfirmedTotal, 80);
    expect(started.repairStartedAt, isNotNull);

    await controller.advanceStatus(order.id);
    expect(controller.orderById(order.id)?.status,
        WorkOrderStatus.awaitingPayment);
    controller.dispose();
  });

  test('editing a confirmed quote requires fresh confirmation', () async {
    final repository = _FakeWorkOrderRepository();
    final controller = WorkOrderController(repository);
    await controller.initialize();
    final firstItem = const WorkOrderItem(
      id: 'item-quote-1',
      name: '检测费',
      type: ServiceItemType.inspection,
      quantity: 1,
      unit: '次',
      unitPrice: 80,
    );
    final secondItem = const WorkOrderItem(
      id: 'item-quote-2',
      name: '人工费',
      type: ServiceItemType.labor,
      quantity: 1,
      unit: '次',
      unitPrice: 120,
    );
    final confirmed = emptyWorkOrder(
      id: 'order-quote',
      number: '20260805-004',
      customerId: 'customer-quote',
    ).copyWith(
      faultDescription: '设备无法启动',
      status: WorkOrderStatus.confirmed,
      items: [firstItem],
      signatureData: 'data:image/png;base64,signature',
      quoteConfirmedAt: DateTime(2026, 8, 5, 12),
      quoteConfirmedTotal: 80,
    );
    await controller.saveOrder(confirmed);

    await controller.saveOrder(
      confirmed.copyWith(items: [firstItem, secondItem]),
    );
    final updated = controller.orderById(confirmed.id)!;
    expect(updated.status, WorkOrderStatus.pendingConfirmation);
    expect(updated.quoteConfirmedAt, isNull);
    expect(updated.quoteConfirmedTotal, isNull);
    expect(updated.signatureData, isNull);
    controller.dispose();
  });

  test('completed and cancelled work orders cannot be edited', () async {
    final repository = _FakeWorkOrderRepository();
    final controller = WorkOrderController(repository);
    await controller.initialize();
    final completed = emptyWorkOrder(
      id: 'order-completed',
      number: '20260805-005',
    ).copyWith(
      status: WorkOrderStatus.completed,
      items: [
        const WorkOrderItem(
          id: 'item-completed',
          name: '检测费',
          type: ServiceItemType.inspection,
          quantity: 1,
          unit: '次',
          unitPrice: 80,
        ),
      ],
      paid: 80,
    );
    expect(await controller.saveOrder(completed), isTrue);

    final edited = completed.copyWith(faultDescription: '不应被保存');
    expect(await controller.saveOrder(edited), isFalse);
    expect(controller.orderById(completed.id)?.faultDescription, isEmpty);
    expect(
      await controller.recordPayment(
        orderId: completed.id,
        amount: 1,
        method: PaymentMethod.cash,
      ),
      isFalse,
    );

    final cancelled = emptyWorkOrder(
      id: 'order-cancelled',
      number: '20260805-006',
    ).copyWith(status: WorkOrderStatus.cancelled);
    expect(await controller.saveOrder(cancelled), isTrue);
    expect(
      await controller.saveOrder(
        cancelled.copyWith(faultDescription: '不应被保存'),
      ),
      isFalse,
    );
    expect(controller.orderById(cancelled.id)?.faultDescription, isEmpty);
    controller.dispose();
  });

  test('work orders move to the recycle bin and can be restored', () async {
    final repository = _FakeWorkOrderRepository();
    final controller = WorkOrderController(repository);
    await controller.initialize();
    final order = emptyWorkOrder(
      id: 'order-trash',
      number: '20260805-007',
    );
    expect(await controller.saveOrder(order), isTrue);

    expect(await controller.moveOrderToTrash(order.id), isTrue);
    expect(controller.orderById(order.id)?.isTrashed, isTrue);
    expect(controller.filteredOrders, isEmpty);
    expect(controller.trashedOrders, hasLength(1));
    expect(await controller.saveOrder(order.copyWith(faultDescription: 'x')),
        isFalse);

    expect(await controller.restoreOrder(order.id), isTrue);
    expect(controller.orderById(order.id)?.isTrashed, isFalse);
    expect(controller.filteredOrders, hasLength(1));
    expect(controller.trashedOrders, isEmpty);
    controller.dispose();
  });

  test('custom service item types can be maintained and protect in-use data',
      () async {
    final repository = _FakeWorkOrderRepository();
    final controller = WorkOrderController(repository);
    await controller.initialize();

    expect(await controller.addServiceItemType('高空作业费'), isTrue);
    expect(await controller.addServiceItemType('高空作业费'), isFalse);
    expect(
      controller.serviceItemTypeOptions.map((option) => option.label),
      contains('高空作业费'),
    );

    final template = const ServiceItem(
      id: 'service-custom',
      name: '高空作业',
      type: ServiceItemType.other,
      customType: '高空作业费',
      unit: '次',
      defaultPrice: 300,
      warrantyDays: 0,
      enabled: true,
    );
    await controller.saveServiceItem(template);
    final order = emptyWorkOrder(
      id: 'order-custom-type',
      number: '20260805-008',
    ).copyWith(
      items: [
        const WorkOrderItem(
          id: 'item-custom',
          name: '高空作业',
          type: ServiceItemType.other,
          customType: '高空作业费',
          quantity: 1,
          unit: '次',
          unitPrice: 300,
        ),
      ],
    );
    await controller.saveOrder(order);

    expect(await controller.deleteServiceItemType('高空作业费'), isFalse);
    expect(await controller.renameServiceItemType('高空作业费', '高空施工费'), isTrue);
    expect(controller.orderById(order.id)!.items.single.customType, '高空施工费');
    expect(controller.data.serviceItems.single.customType, '高空施工费');

    await controller.saveServiceItem(template.copyWith(
      type: ServiceItemType.labor,
      customType: null,
    ));
    await controller.saveOrder(order.copyWith(
      items: [
        order.items.single.copyWith(
          type: ServiceItemType.labor,
          customType: null,
        )
      ],
    ));
    expect(await controller.deleteServiceItemType('高空施工费'), isTrue);
    expect(controller.serviceItemTypeOptions.map((option) => option.label),
        isNot(contains('高空施工费')));
    controller.dispose();
  });

  test('built-in service item types can be deleted and restored from backup',
      () async {
    final repository = _FakeWorkOrderRepository();
    final controller = WorkOrderController(repository);
    await controller.initialize();

    expect(
      controller.serviceItemTypeOptions.map((option) => option.label),
      contains('人工'),
    );
    await controller.saveServiceItem(const ServiceItem(
      id: 'service-built-in',
      name: '人工费',
      type: ServiceItemType.labor,
      unit: '小时',
      defaultPrice: 100,
      warrantyDays: 0,
      enabled: true,
    ));
    expect(await controller.deleteServiceItemType('人工'), isFalse);

    await controller.deleteServiceItem('service-built-in');
    expect(await controller.deleteServiceItemType('人工'), isTrue);
    expect(
      controller.serviceItemTypeOptions.map((option) => option.label),
      isNot(contains('人工')),
    );

    final backup = controller.exportJson();
    final restoredRepository = _FakeWorkOrderRepository();
    final restoredController = WorkOrderController(restoredRepository);
    await restoredController.initialize();
    expect(await restoredController.importJson(backup), isTrue);
    expect(
      restoredController.serviceItemTypeOptions.map((option) => option.label),
      isNot(contains('人工')),
    );
    expect(
      restoredController.data.settings.deletedBuiltInServiceItemTypes,
      contains('labor'),
    );
    controller.dispose();
    restoredController.dispose();
  });

  test('dashboard card visibility and order survive JSON backup restore',
      () async {
    final repository = _FakeWorkOrderRepository();
    final controller = WorkOrderController(repository);
    await controller.initialize();

    await controller.updateDashboardCardOrder([
      'warrantyReminder',
      'todaySummary',
    ]);
    await controller.setDashboardCardVisible('customers', false);
    expect(controller.dashboardCardOrder.first, 'warrantyReminder');
    expect(controller.dashboardHiddenCards, contains('customers'));

    final backup = controller.exportJson();
    await controller.importJson(
      '{"customers": [], "serviceItems": [], "workOrders": [], "payments": [], "settings": {}}',
    );
    expect(controller.dashboardHiddenCards, isEmpty);
    expect(await controller.importJson(backup), isTrue);
    expect(controller.dashboardCardOrder.first, 'warrantyReminder');
    expect(controller.dashboardHiddenCards, contains('customers'));
    controller.dispose();
  });

  test('imports the CSV format produced by the app', () async {
    final sourceRepository = _FakeWorkOrderRepository()..value = seedData();
    final source = WorkOrderController(sourceRepository);
    await source.initialize();
    final csv = source.exportCsv();

    final targetRepository = _FakeWorkOrderRepository();
    final target = WorkOrderController(targetRepository);
    await target.initialize();
    final result = await target.importCsv(csv);

    expect(result, isNotNull);
    expect(result!.totalOrders, 2);
    expect(result.createdCustomers, 2);
    expect(result.importedPayments, 1);
    expect(target.data.workOrders, hasLength(2));
    expect(target.data.customers, hasLength(2));
    expect(
      target.data.workOrders.any(
        (order) => target.paymentsFor(order.id).length == 1,
      ),
      isTrue,
    );

    source.dispose();
    target.dispose();
  });
}
