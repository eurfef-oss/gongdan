import 'package:flutter/foundation.dart';

import '../domain/entities/work_order.dart';
import '../domain/repositories/work_order_repository.dart';
import 'controllers/backup_controller.dart';
import 'controllers/customer_controller.dart';
import 'controllers/cost_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/template_controller.dart';
import 'services/work_order_export_service.dart';
import 'work_order_store.dart';

export 'controllers/backup_controller.dart' show BackupController;
export 'controllers/customer_controller.dart' show CustomerController;
export 'controllers/cost_controller.dart' show CostController;
export 'controllers/order_controller.dart' show OrderController;
export 'controllers/settings_controller.dart'
    show SettingsController, dashboardCardIds, workOrderFieldIds;
export 'controllers/template_controller.dart' show TemplateController;
export 'services/work_order_export_service.dart'
    show CsvImportOutcome, CsvImportResult, WorkOrderExportService;
export 'work_order_store.dart' show WorkOrderLoadStatus;

class WorkOrderController extends ChangeNotifier {
  WorkOrderController(WorkOrderRepository repository) {
    _store = WorkOrderStore(repository, notifyListeners);
    orders = OrderController(_store);
    costs = CostController(_store);
    customers = CustomerController(_store);
    templates = TemplateController(_store);
    settings = SettingsController(_store);
    backup = BackupController(_store, orders);
  }

  late final WorkOrderStore _store;

  late final OrderController orders;
  late final CostController costs;
  late final CustomerController customers;
  late final TemplateController templates;
  late final SettingsController settings;
  late final BackupController backup;

  WorkOrderLoadStatus get status => _store.status;
  RepairAppData get data => _store.data;
  Object? get error => _store.error;
  bool get persistenceAvailable => _store.persistenceAvailable;

  String get query => orders.query;
  WorkOrderStatus? get statusFilter => orders.statusFilter;
  PaymentStatus? get paymentFilter => orders.paymentFilter;
  DateTime? get createdDateFilter => orders.createdDateFilter;
  DateTime? get serviceDateFilter => orders.serviceDateFilter;
  String? get customerFilter => orders.customerFilter;
  String? get deviceTypeFilter => orders.deviceTypeFilter;

  List<WorkOrder> get visibleOrders => orders.visibleOrders;
  List<WorkOrder> get trashedOrders => orders.trashedOrders;
  List<WorkOrder> get filteredOrders => orders.filteredOrders;
  List<ServiceTypeOption> get serviceItemTypeOptions =>
      templates.serviceItemTypeOptions;
  List<String> get dashboardCardOrder => settings.dashboardCardOrder;
  Set<String> get dashboardHiddenCards => settings.dashboardHiddenCards;
  List<String> get workOrderFieldOrder => settings.workOrderFieldOrder;
  Set<String> get workOrderHiddenFields => settings.workOrderHiddenFields;
  List<CostType> get costTypes => costs.costTypes;
  List<CostType> get enabledCostTypes => costs.enabledCostTypes;

  Future<void> initialize() => _store.initialize();

  Customer? customerById(String id) => orders.customerById(id);
  WorkOrder? orderById(String id) => orders.orderById(id);
  List<PaymentRecord> paymentsFor(String orderId) =>
      orders.paymentsFor(orderId);

  void setQuery(String value) => orders.setQuery(value);
  void setStatusFilter(WorkOrderStatus? value) => orders.setStatusFilter(value);
  void setPaymentFilter(PaymentStatus? value) => orders.setPaymentFilter(value);
  void setCreatedDateFilter(DateTime? value) =>
      orders.setCreatedDateFilter(value);
  void setServiceDateFilter(DateTime? value) =>
      orders.setServiceDateFilter(value);
  void setCustomerFilter(String? value) => orders.setCustomerFilter(value);
  void setDeviceTypeFilter(String? value) => orders.setDeviceTypeFilter(value);
  void clearOrderFilters() => orders.clearOrderFilters();

  Future<bool> saveOrder(WorkOrder order) => orders.saveOrder(order);
  Future<bool> moveOrderToTrash(String orderId) =>
      orders.moveOrderToTrash(orderId);
  Future<bool> restoreOrder(String orderId) => orders.restoreOrder(orderId);
  Future<void> advanceStatus(String orderId) => orders.advanceStatus(orderId);
  Future<void> cancelOrder(String orderId) => orders.cancelOrder(orderId);
  Future<bool> recordPayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String note = '',
  }) =>
      orders.recordPayment(
        orderId: orderId,
        amount: amount,
        method: method,
        note: note,
      );
  Future<void> saveSignature(String orderId, String data) =>
      orders.saveSignature(orderId, data);
  Future<void> addAttachments(
    String orderId,
    List<Attachment> attachments,
  ) =>
      orders.addAttachments(orderId, attachments);
  Future<void> removeAttachment(String orderId, String attachmentId) =>
      orders.removeAttachment(orderId, attachmentId);

  Future<bool> saveInternalCosts(
    String orderId,
    List<WorkOrderCost> values,
  ) =>
      costs.saveInternalCosts(orderId, values);

  Future<bool> addCostType(String value) => costs.addCostType(value);
  Future<bool> renameCostType(String id, String value) =>
      costs.renameCostType(id, value);
  Future<bool> setCostTypeEnabled(String id, bool enabled) =>
      costs.setCostTypeEnabled(id, enabled);
  Future<bool> deleteCostType(String id) => costs.deleteCostType(id);

  Future<void> saveCustomer(Customer customer) =>
      customers.saveCustomer(customer);
  Future<bool> deleteCustomer(String customerId) =>
      customers.deleteCustomer(customerId);

  Future<void> saveServiceItem(ServiceItem item) =>
      templates.saveServiceItem(item);
  Future<bool> addServiceItemType(String value) =>
      templates.addServiceItemType(value);
  Future<bool> renameServiceItemType(String oldValue, String newValue) =>
      templates.renameServiceItemType(oldValue, newValue);
  Future<bool> deleteServiceItemType(String value) =>
      templates.deleteServiceItemType(value);
  Future<void> deleteServiceItem(String itemId) =>
      templates.deleteServiceItem(itemId);
  Future<void> toggleServiceItem(String itemId) =>
      templates.toggleServiceItem(itemId);

  Future<bool> updateDashboardCardOrder(List<String> order) =>
      settings.updateDashboardCardOrder(order);
  Future<bool> setDashboardCardVisible(String id, bool visible) =>
      settings.setDashboardCardVisible(id, visible);
  Future<bool> setDashboardCardsVisible(
    Iterable<String> ids,
    bool visible,
  ) =>
      settings.setDashboardCardsVisible(ids, visible);
  Future<bool> updateWorkOrderFieldOrder(List<String> order) =>
      settings.updateWorkOrderFieldOrder(order);
  Future<bool> setWorkOrderFieldVisible(String id, bool visible) =>
      settings.setWorkOrderFieldVisible(id, visible);
  Future<bool> setWorkOrderFieldsVisible(
    Iterable<String> ids,
    bool visible,
  ) =>
      settings.setWorkOrderFieldsVisible(ids, visible);
  Future<void> updateSettings(RepairAppSettings value) =>
      settings.updateSettings(value);

  String exportJson() => backup.exportJson();
  String exportCsv() => backup.exportCsv();
  Future<bool> importJson(String raw) => backup.importJson(raw);
  Future<CsvImportResult?> importCsv(String raw) => backup.importCsv(raw);
  Future<void> resetToDemo() => settings.resetToDemo();
}
