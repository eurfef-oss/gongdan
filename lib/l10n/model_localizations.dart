import 'package:flutter/widgets.dart';

import '../features/work_orders/domain/entities/work_order.dart';
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
