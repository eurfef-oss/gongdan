import 'package:flutter/widgets.dart';

import '../features/work_orders/domain/entities/work_order.dart';
import 'app_localizations.dart';
import 'app_strings.dart';

String workOrderStatusText(BuildContext context, WorkOrderStatus status) =>
    context.tr(status.label);

String paymentStatusText(BuildContext context, PaymentStatus status) =>
    context.tr(status.label);

String paymentMethodText(BuildContext context, PaymentMethod method) =>
    context.tr(method.label);

String serviceItemTypeText(
  BuildContext context,
  ServiceItemType type, {
  String? customType,
}) {
  final custom = customType?.trim() ?? '';
  return custom.isEmpty ? context.tr(type.label) : custom;
}

/// The starter catalog is stored in Chinese so that saved data remains stable
/// across language changes. These signatures let the presentation layer
/// localize only the built-in items while leaving custom templates and
/// user-entered work-order data untouched.
class _DefaultServiceItemDefinition {
  const _DefaultServiceItemDefinition({
    required this.name,
    required this.type,
    required this.unit,
    required this.price,
    required this.warrantyDays,
  });

  final String name;
  final ServiceItemType type;
  final String unit;
  final double price;
  final int warrantyDays;

  bool matchesServiceItem(ServiceItem item) =>
      item.name == name &&
      item.type == type &&
      (item.customType?.trim().isEmpty ?? true) &&
      item.unit == unit &&
      item.defaultPrice == price &&
      item.warrantyDays == warrantyDays;

  bool matchesWorkOrderItem(WorkOrderItem item) =>
      item.name == name &&
      item.type == type &&
      (item.customType?.trim().isEmpty ?? true) &&
      item.unit == unit &&
      item.unitPrice == price;
}

const _defaultServiceItems = <_DefaultServiceItemDefinition>[
  _DefaultServiceItemDefinition(
    name: '空调深度清洗',
    type: ServiceItemType.labor,
    unit: '台',
    price: 168,
    warrantyDays: 30,
  ),
  _DefaultServiceItemDefinition(
    name: '上门检测费',
    type: ServiceItemType.inspection,
    unit: '次',
    price: 80,
    warrantyDays: 0,
  ),
  _DefaultServiceItemDefinition(
    name: '空调滤网',
    type: ServiceItemType.part,
    unit: '个',
    price: 35,
    warrantyDays: 90,
  ),
  _DefaultServiceItemDefinition(
    name: '远程故障判断',
    type: ServiceItemType.labor,
    unit: '次',
    price: 50,
    warrantyDays: 0,
  ),
];

bool isDefaultServiceItem(ServiceItem item) => _defaultServiceItems
    .any((definition) => definition.matchesServiceItem(item));

bool isDefaultWorkOrderItem(WorkOrderItem item) => _defaultServiceItems
    .any((definition) => definition.matchesWorkOrderItem(item));

String localizedServiceItemNameForLocale(
  String locale,
  ServiceItem item,
) {
  return isDefaultServiceItem(item)
      ? localizedText(locale, item.name)
      : item.name;
}

String localizedWorkOrderItemNameForLocale(
  String locale,
  WorkOrderItem item,
) {
  return isDefaultWorkOrderItem(item)
      ? localizedText(locale, item.name)
      : item.name;
}

String localizedUnitForLocale(String locale, String unit) {
  final value = unit.trim();
  return switch (value) {
    '台' || '次' || '个' => localizedText(locale, value),
    _ => unit,
  };
}

String localizedServiceItemName(BuildContext context, ServiceItem item) =>
    localizedServiceItemNameForLocale(
      AppLocalizations.of(context).localeName,
      item,
    );

String localizedServiceItemUnit(BuildContext context, ServiceItem item) =>
    localizedUnitForLocale(
      AppLocalizations.of(context).localeName,
      item.unit,
    );

String localizedWorkOrderItemName(BuildContext context, WorkOrderItem item) =>
    localizedWorkOrderItemNameForLocale(
      AppLocalizations.of(context).localeName,
      item,
    );

String localizedWorkOrderItemUnit(BuildContext context, WorkOrderItem item) =>
    localizedUnitForLocale(
      AppLocalizations.of(context).localeName,
      item.unit,
    );
