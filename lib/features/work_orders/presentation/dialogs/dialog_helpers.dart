part of '../work_order_dialogs.dart';

const _dialogBlue = Color(0xFF2858C9);
const _dialogNavy = Color(0xFF14213D);
const _dialogTeal = _dialogBlue;
const _dialogGreen = Color(0xFF267D66);
const _dialogAmber = Color(0xFFBD7A21);
const _dialogRed = Color(0xFFBE5B51);
const _newCustomerValue = '__new_customer__';

String _dialogMoney(
  double value, {
  String currencySymbol = defaultCurrencySymbol,
}) =>
    '$currencySymbol${value.toStringAsFixed(2)}';

String _dialogDate(DateTime? value, {String empty = '未设置'}) {
  if (value == null) return empty;
  return DateFormat('yyyy/MM/dd').format(value);
}

String _dialogDateTime(DateTime? value, {String empty = '未安排'}) {
  if (value == null) return empty;
  return DateFormat('yyyy/MM/dd HH:mm').format(value);
}

String _dialogDateLocalized(BuildContext context, DateTime? value) =>
    _dialogDate(value, empty: context.tr('未设置'));

String _dialogDateTimeLocalized(BuildContext context, DateTime? value) =>
    _dialogDateTime(value, empty: context.tr('未安排'));

String _workOrderNote(WorkOrder order) {
  final request = order.customerRequest.trim();
  final note = order.customerNote.trim();
  if (request.isEmpty) return note;
  if (note.isEmpty || note == request) return request;
  return '$request\n$note';
}

String _dialogDeviceLocalized(BuildContext context, WorkOrder order) {
  final value = [order.deviceType, order.brand, order.model]
      .where((item) => item.isNotEmpty)
      .join(' · ');
  return value.isEmpty ? context.tr('未填写设备') : value;
}

Uint8List? _decodeDataUrl(String? value) {
  if (value == null || !value.contains(',')) return null;
  try {
    return Uint8List.fromList(base64Decode(value.split(',').last));
  } catch (_) {
    return null;
  }
}

Color _dialogStatusColor(BuildContext context, Enum value) {
  final scheme = Theme.of(context).colorScheme;
  if (value == WorkOrderStatus.cancelled || value == PaymentStatus.unpaid) {
    return _dialogRed;
  }
  if (value == WorkOrderStatus.completed || value == PaymentStatus.paid) {
    return _dialogGreen;
  }
  if (value == WorkOrderStatus.pendingConfirmation ||
      value == PaymentStatus.partial) {
    return _dialogAmber;
  }
  if (value == WorkOrderStatus.confirmed) return _dialogBlue;
  return scheme.primary;
}
