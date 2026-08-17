import 'package:repair_work_order_assistant/app/base_app.dart';
import 'package:repair_work_order_assistant/features/work_orders/application/work_order_controller.dart';
import 'package:repair_work_order_assistant/features/work_orders/domain/entities/work_order.dart';
import 'package:repair_work_order_assistant/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWorkOrderRepository implements WorkOrderRepository {
  RepairAppData value = seedData();

  @override
  Future<RepairAppData> load() async => value;

  @override
  Future<void> save(RepairAppData data) async => value = data;
}

void main() {
  testWidgets('work order app shows welcome page before the dashboard',
      (tester) async {
    final controller = WorkOrderController(_FakeWorkOrderRepository());
    await controller.initialize();

    await tester.pumpWidget(BaseApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('开始使用'), findsOneWidget);
    await tester.ensureVisible(find.text('开始使用'));
    await tester.tap(find.text('开始使用'));
    await tester.pumpAndSettle();

    expect(find.byType(ReorderableListView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('最近工单'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('最近工单'), findsOneWidget);
  });

  testWidgets('dashboard progress merges confirmed into repairing',
      (tester) async {
    final draft = emptyWorkOrder(
      id: 'draft-dashboard-order',
      number: '20260807-001',
    );
    final cancelled = emptyWorkOrder(
      id: 'cancelled-dashboard-order',
      number: '20260807-002',
    ).copyWith(status: WorkOrderStatus.cancelled);
    final confirmed = emptyWorkOrder(
      id: 'confirmed-dashboard-order',
      number: '20260807-003',
    ).copyWith(status: WorkOrderStatus.confirmed);
    final repairing = emptyWorkOrder(
      id: 'repairing-dashboard-order',
      number: '20260807-004',
    ).copyWith(status: WorkOrderStatus.repairing);
    final awaitingPayment = emptyWorkOrder(
      id: 'awaiting-payment-dashboard-order',
      number: '20260807-005',
    ).copyWith(status: WorkOrderStatus.awaitingPayment);
    final completed = emptyWorkOrder(
      id: 'completed-dashboard-order',
      number: '20260807-006',
    ).copyWith(status: WorkOrderStatus.completed);
    final repository = _FakeWorkOrderRepository()
      ..value = RepairAppData(
        customers: const [],
        serviceItems: const [],
        workOrders: [
          draft,
          cancelled,
          confirmed,
          repairing,
          awaitingPayment,
          completed,
        ],
        payments: const [],
        settings: const RepairAppSettings(hasSeenWelcome: true),
      );
    final controller = WorkOrderController(repository);
    await controller.initialize();

    await tester.pumpWidget(BaseApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('工单进度'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final progressCard = find.ancestor(
      of: find.text('工单进度'),
      matching: find.byType(Card),
    );
    expect(progressCard, findsOneWidget);
    expect(
      find.descendant(of: progressCard, matching: find.text('草稿')),
      findsNothing,
    );
    expect(
      find.descendant(of: progressCard, matching: find.text('已取消')),
      findsNothing,
    );
    expect(
      find.descendant(of: progressCard, matching: find.text('已确认')),
      findsNothing,
    );
    expect(
      find.descendant(of: progressCard, matching: find.text('待确认')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: progressCard, matching: find.text('维修中')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: progressCard, matching: find.text('待收款')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: progressCard, matching: find.text('已完成')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: progressCard, matching: find.text('2 张')),
      findsOneWidget,
    );
  });

  testWidgets('settings opens a secondary menu before its detail page',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeWorkOrderRepository();
    repository.value = repository.value.copyWith(
      settings: repository.value.settings.copyWith(hasSeenWelcome: true),
    );
    final controller = WorkOrderController(repository);
    await controller.initialize();

    await tester.pumpWidget(BaseApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    expect(find.text('系统设置'), findsOneWidget);
    expect(find.text('门店资料'), findsOneWidget);
    expect(find.text('门店名称'), findsNothing);
    expect(find.text('概览设置'), findsOneWidget);

    await tester.tap(find.text('概览设置'));
    await tester.pumpAndSettle();

    expect(find.text('概览模块'), findsOneWidget);
    expect(find.text('数据概览'), findsOneWidget);
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(find.byType(ReorderableDragStartListener), findsNWidgets(5));
    expect(find.byType(Switch), findsNWidgets(5));
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(controller.dashboardHiddenCards, contains('summaryMetrics'));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('系统设置'), findsOneWidget);

    await tester.tap(find.text('门店资料'));
    await tester.pumpAndSettle();

    expect(find.text('门店名称'), findsOneWidget);
    expect(find.text('保存门店资料'), findsOneWidget);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    expect(find.text('系统设置'), findsOneWidget);
    expect(find.text('门店名称'), findsNothing);

    await tester.tap(find.text('门店资料'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('系统设置'), findsOneWidget);
    expect(find.text('门店名称'), findsNothing);

    await tester.ensureVisible(find.text('项目模板'));
    await tester.tap(find.text('项目模板'));
    await tester.pumpAndSettle();

    expect(find.text('项目模板'), findsAtLeastNWidgets(1));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('系统设置'), findsOneWidget);
  });

  testWidgets('orders page keeps its list visible on a narrow surface',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeWorkOrderRepository();
    repository.value = repository.value.copyWith(
      settings: repository.value.settings.copyWith(hasSeenWelcome: true),
    );
    final controller = WorkOrderController(repository);
    await controller.initialize();

    await tester.pumpWidget(BaseApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('工单'));
    await tester.pumpAndSettle();

    expect(find.text('工单清单'), findsOneWidget);
    expect(find.text('没有匹配的工单'), findsNothing);
    expect(find.text('周女士'), findsOneWidget);
    expect(find.text('林先生'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<WorkOrderStatus?>));
    await tester.pumpAndSettle();

    expect(find.text('草稿'), findsWidgets);
    expect(find.text('待确认'), findsWidgets);
    expect(find.text('维修中'), findsWidgets);
    expect(find.text('待收款'), findsWidgets);
    expect(find.text('已完成'), findsWidgets);
    expect(find.text('已确认'), findsNothing);
    expect(find.text('已取消'), findsNothing);
  });

  testWidgets('primary page needs a second back press to leave the app',
      (tester) async {
    final repository = _FakeWorkOrderRepository();
    repository.value = repository.value.copyWith(
      settings: repository.value.settings.copyWith(hasSeenWelcome: true),
    );
    final controller = WorkOrderController(repository);
    await controller.initialize();

    await tester.pumpWidget(BaseApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('再按一次返回键退出应用'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // The test binding does not remove the root route after SystemNavigator.pop;
    // on a phone this second back event returns to the system desktop.
  });

  testWidgets('language setting switches the app shell to English',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeWorkOrderRepository();
    repository.value = repository.value.copyWith(
      settings: repository.value.settings.copyWith(hasSeenWelcome: true),
    );
    final controller = WorkOrderController(repository);
    await controller.initialize();

    await tester.pumpWidget(BaseApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('语言'));
    await tester.pumpAndSettle();

    expect(find.text('语言设置'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(controller.data.settings.languageCode, 'en');
    expect(find.text('Language settings'), findsOneWidget);
    expect(find.text('语言设置'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Settings & backup'), findsOneWidget);

    final templatesEntry = find.text('Service templates');
    await tester.ensureVisible(templatesEntry);
    await tester.tap(templatesEntry);
    await tester.pumpAndSettle();

    expect(find.text('Deep AC cleaning'), findsOneWidget);
    expect(find.text('空调深度清洗'), findsNothing);
    expect(find.textContaining('unit'), findsAtLeastNWidgets(1));
  });

  testWidgets('language settings can reopen the welcome page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeWorkOrderRepository();
    repository.value = repository.value.copyWith(
      settings: repository.value.settings.copyWith(hasSeenWelcome: true),
    );
    final controller = WorkOrderController(repository);
    await controller.initialize();

    await tester.pumpWidget(
      BaseApp(key: UniqueKey(), controller: controller),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('语言'));
    await tester.pumpAndSettle();

    expect(find.text('打开欢迎页'), findsOneWidget);
    await tester.tap(find.text('打开欢迎页'));
    await tester.pumpAndSettle();

    expect(controller.data.settings.hasSeenWelcome, isFalse);
    expect(find.text('欢迎开始记录每一次服务。'), findsOneWidget);
  });
}
