part of 'work_order.dart';

class RepairAppData {
  const RepairAppData({
    required this.customers,
    required this.serviceItems,
    required this.workOrders,
    required this.payments,
    required this.settings,
  });

  final List<Customer> customers;
  final List<ServiceItem> serviceItems;
  final List<WorkOrder> workOrders;
  final List<PaymentRecord> payments;
  final RepairAppSettings settings;

  factory RepairAppData.empty() => RepairAppData(
        customers: const [],
        serviceItems: const [],
        workOrders: const [],
        payments: const [],
        settings: const RepairAppSettings(),
      );

  RepairAppData copyWith({
    List<Customer>? customers,
    List<ServiceItem>? serviceItems,
    List<WorkOrder>? workOrders,
    List<PaymentRecord>? payments,
    RepairAppSettings? settings,
  }) =>
      RepairAppData(
        customers: customers ?? this.customers,
        serviceItems: serviceItems ?? this.serviceItems,
        workOrders: workOrders ?? this.workOrders,
        payments: payments ?? this.payments,
        settings: settings ?? this.settings,
      );

  Map<String, Object?> toJson() => {
        'version': currentWorkOrderDataVersion,
        'customers': customers.map((item) => item.toJson()).toList(),
        'serviceItems': serviceItems.map((item) => item.toJson()).toList(),
        'workOrders': workOrders.map((item) => item.toJson()).toList(),
        'payments': payments.map((item) => item.toJson()).toList(),
        'settings': settings.toJson(),
      };

  factory RepairAppData.fromJson(Map<String, Object?> json) {
    final migrated = migrateWorkOrderData(json);
    return RepairAppData(
      customers: (migrated['customers'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Customer.fromJson(Map<String, Object?>.from(item)))
          .toList(),
      serviceItems: (migrated['serviceItems'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => ServiceItem.fromJson(Map<String, Object?>.from(item)))
          .toList(),
      workOrders: (migrated['workOrders'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => WorkOrder.fromJson(Map<String, Object?>.from(item)))
          .toList(),
      payments: (migrated['payments'] as List? ?? const [])
          .whereType<Map>()
          .map(
              (item) => PaymentRecord.fromJson(Map<String, Object?>.from(item)))
          .toList(),
      settings: RepairAppSettings.fromJson(
        Map<String, Object?>.from(
          (migrated['settings'] as Map?) ?? const {},
        ),
      ),
    );
  }
}
