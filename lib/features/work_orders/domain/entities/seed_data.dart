part of 'work_order.dart';

var _lastGeneratedId = 0;

String idFor(String prefix) {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final unique =
      timestamp <= _lastGeneratedId ? _lastGeneratedId + 1 : timestamp;
  _lastGeneratedId = unique;
  return '${prefix}_$unique';
}

String orderNumberFor(Iterable<WorkOrder> orders, DateTime date) {
  final prefix =
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  final sequence =
      orders.where((order) => order.number.startsWith('$prefix-')).length + 1;
  return '$prefix-${sequence.toString().padLeft(3, '0')}';
}

WorkOrder emptyWorkOrder({
  required String id,
  required String number,
  DateTime? now,
  String customerId = '',
}) {
  final current = now ?? DateTime.now();
  return WorkOrder(
    id: id,
    number: number,
    customerId: customerId,
    serviceAddress: '',
    deviceType: '',
    brand: '',
    model: '',
    serialNumber: '',
    faultDescription: '',
    customerRequest: '',
    result: '',
    customerNote: '',
    internalNote: '',
    status: WorkOrderStatus.draft,
    items: const [],
    discount: 0,
    paid: 0,
    appointmentAt: null,
    warrantyDays: 0,
    warrantyStart: null,
    warrantyEnd: null,
    warrantyScope: '',
    warrantyExclusions: '',
    attachments: const [],
    signatureData: null,
    quoteConfirmedAt: null,
    createdAt: current,
    updatedAt: current,
  );
}

RepairAppData seedData() {
  final now = DateTime.now();
  final customerA = Customer(
    id: idFor('cus'),
    name: '周女士',
    phone: '138 0013 8001',
    wechat: 'zhou_home',
    address: '锦江区东大街 88 号',
    notes: '工作日 18:00 后方便上门',
    createdAt: now.subtract(const Duration(days: 18)),
    updatedAt: now.subtract(const Duration(days: 2)),
  );
  final customerB = Customer(
    id: idFor('cus'),
    name: '林先生',
    phone: '139 1020 2233',
    address: '武侯区科华北路 21 号',
    createdAt: now.subtract(const Duration(days: 10)),
    updatedAt: now.subtract(const Duration(days: 4)),
  );
  final serviceItems = [
    ServiceItem(
        id: idFor('svc'),
        name: '空调深度清洗',
        type: ServiceItemType.labor,
        unit: '台',
        defaultPrice: 168,
        warrantyDays: 30,
        enabled: true),
    ServiceItem(
        id: idFor('svc'),
        name: '上门检测费',
        type: ServiceItemType.inspection,
        unit: '次',
        defaultPrice: 80,
        warrantyDays: 0,
        enabled: true),
    ServiceItem(
        id: idFor('svc'),
        name: '空调滤网',
        type: ServiceItemType.part,
        unit: '个',
        defaultPrice: 35,
        warrantyDays: 90,
        enabled: true),
    ServiceItem(
        id: idFor('svc'),
        name: '远程故障判断',
        type: ServiceItemType.labor,
        unit: '次',
        defaultPrice: 50,
        warrantyDays: 0,
        enabled: true),
  ];
  final orderA = emptyWorkOrder(
          id: idFor('ord'),
          number: orderNumberFor(const [], now),
          now: now.subtract(const Duration(hours: 2)),
          customerId: customerA.id)
      .copyWith(
    serviceAddress: customerA.address,
    deviceType: '家用空调',
    brand: '格力',
    model: '云佳 1.5P',
    faultDescription: '制冷效果变差，室内机有异味',
    status: WorkOrderStatus.repairing,
    items: [
      WorkOrderItem(
          id: idFor('item'),
          name: '上门检测费',
          type: ServiceItemType.inspection,
          quantity: 1,
          unit: '次',
          unitPrice: 80),
      WorkOrderItem(
          id: idFor('item'),
          name: '空调深度清洗',
          type: ServiceItemType.labor,
          quantity: 1,
          unit: '台',
          unitPrice: 168),
    ],
    warrantyDays: 30,
    warrantyStart: DateTime(now.year, now.month, now.day),
    updatedAt: now.subtract(const Duration(minutes: 12)),
  );
  final orderB = emptyWorkOrder(
          id: idFor('ord'),
          number: orderNumberFor([orderA], now),
          now: now.subtract(const Duration(days: 1)),
          customerId: customerB.id)
      .copyWith(
    serviceAddress: customerB.address,
    deviceType: '壁挂空调',
    brand: '海尔',
    model: 'KFR-35GW',
    faultDescription: '开机后自动关机',
    result: '更换遥控接收板，运行正常',
    status: WorkOrderStatus.awaitingPayment,
    items: [
      WorkOrderItem(
          id: idFor('item'),
          name: '上门检测费',
          type: ServiceItemType.inspection,
          quantity: 1,
          unit: '次',
          unitPrice: 80),
      WorkOrderItem(
          id: idFor('item'),
          name: '遥控接收板',
          type: ServiceItemType.part,
          quantity: 1,
          unit: '个',
          unitPrice: 126,
          note: '原厂配件'),
      WorkOrderItem(
          id: idFor('item'),
          name: '维修人工',
          type: ServiceItemType.labor,
          quantity: 1,
          unit: '次',
          unitPrice: 90),
    ],
    paid: 100,
    warrantyDays: 90,
    warrantyStart: DateTime(now.year, now.month, now.day - 1),
    updatedAt: now.subtract(const Duration(hours: 4)),
  );
  return RepairAppData(
    customers: [customerA, customerB],
    serviceItems: serviceItems,
    workOrders: [orderA, orderB],
    payments: [
      PaymentRecord(
          id: idFor('pay'),
          orderId: orderB.id,
          amount: 100,
          method: PaymentMethod.transfer,
          note: '现场定金',
          paidAt: now.subtract(const Duration(days: 1, hours: 3)))
    ],
    settings:
        const RepairAppSettings(phone: '138 8888 6600', address: '成都市 · 武侯区'),
  );
}
