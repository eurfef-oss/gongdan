part of '../work_order_page.dart';

const _blue = Color(0xFF2858C9);
const _navy = Color(0xFF14213D);
const _coral = Color(0xFFBE5B51);
const _amber = Color(0xFFBD7A21);
const _green = Color(0xFF267D66);
const _navMuted = Color(0xFFAAB8D0);

const _dashboardProgressStatuses = <WorkOrderStatus>[
  WorkOrderStatus.pendingConfirmation,
  WorkOrderStatus.repairing,
  WorkOrderStatus.awaitingPayment,
  WorkOrderStatus.completed,
];

const _dashboardCardLabels = <String, String>{
  'summaryMetrics': '数据概览',
  'statusProgress': '工单进度',
  'recentOrders': '最近工单',
  'quickActions': '快捷入口',
  'warrantyReminder': '保修提醒',
};

const _dashboardSettingCardIds = <String>[
  'summaryMetrics',
  'statusProgress',
  'recentOrders',
  'quickActions',
  'warrantyReminder',
];

List<String> _dashboardSettingsOrder(Iterable<String> cardOrder) {
  final result = <String>[];
  for (final id in cardOrder) {
    if (_dashboardSettingCardIds.contains(id) && !result.contains(id)) {
      result.add(id);
    }
  }
  for (final id in _dashboardSettingCardIds) {
    if (!result.contains(id)) result.add(id);
  }
  return result;
}

String _dashboardCardLabel(BuildContext context, String id) =>
    context.tr(_dashboardCardLabels[id] ?? id);

String moneyText(double value) => '¥${value.toStringAsFixed(2)}';

String dateText(DateTime? value, {String empty = '未设置'}) {
  if (value == null) return empty;
  return DateFormat('yyyy/MM/dd').format(value);
}

String dateTimeText(DateTime? value, {String empty = '未安排'}) {
  if (value == null) return empty;
  return DateFormat('MM/dd HH:mm').format(value);
}

String localizedDateText(BuildContext context, DateTime? value) =>
    dateText(value, empty: context.tr('未设置'));

String localizedDateTimeText(BuildContext context, DateTime? value) =>
    dateTimeText(value, empty: context.tr('未安排'));

String initials(String name, {String fallback = '客'}) {
  final value = name.trim();
  return value.isEmpty ? fallback : value.characters.first.toUpperCase();
}

String deviceText(WorkOrder order) {
  final value = [order.deviceType, order.brand, order.model]
      .where((item) => item.isNotEmpty)
      .join(' · ');
  return value.isEmpty ? '未填写设备' : value;
}

String localizedDeviceText(BuildContext context, WorkOrder order) {
  final value = [order.deviceType, order.brand, order.model]
      .where((item) => item.isNotEmpty)
      .join(' · ');
  return value.isEmpty ? context.tr('未填写设备') : value;
}

int _dashboardProgressCount(
  Iterable<WorkOrder> orders,
  WorkOrderStatus status,
) {
  return orders.where((order) {
    if (status == WorkOrderStatus.repairing) {
      return order.status == WorkOrderStatus.repairing ||
          order.status == WorkOrderStatus.confirmed;
    }
    return order.status == status;
  }).length;
}

Color statusColor(BuildContext context, Enum value) {
  final scheme = Theme.of(context).colorScheme;
  if (value == WorkOrderStatus.cancelled || value == PaymentStatus.unpaid) {
    return _coral;
  }
  if (value == WorkOrderStatus.completed || value == PaymentStatus.paid) {
    return _green;
  }
  if (value == WorkOrderStatus.pendingConfirmation ||
      value == PaymentStatus.partial) {
    return _amber;
  }
  if (value == WorkOrderStatus.confirmed) return _blue;
  return scheme.primary;
}
