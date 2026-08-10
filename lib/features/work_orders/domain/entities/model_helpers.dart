part of 'work_order.dart';

const _copyWithUnset = Object();

enum WorkOrderStatus {
  draft,
  pendingConfirmation,
  confirmed,
  repairing,
  awaitingPayment,
  completed,
  cancelled,
}

enum PaymentStatus { unpaid, partial, paid }

enum PaymentMethod { cash, transfer, card, other }

enum ServiceItemType { labor, part, visit, inspection, transport, other }

extension WorkOrderStatusX on WorkOrderStatus {
  String get label => const {
        WorkOrderStatus.draft: '草稿',
        WorkOrderStatus.pendingConfirmation: '待确认',
        WorkOrderStatus.confirmed: '已确认',
        WorkOrderStatus.repairing: '维修中',
        WorkOrderStatus.awaitingPayment: '待收款',
        WorkOrderStatus.completed: '已完成',
        WorkOrderStatus.cancelled: '已取消',
      }[this]!;

  WorkOrderStatus? get next => const {
        WorkOrderStatus.draft: WorkOrderStatus.pendingConfirmation,
        WorkOrderStatus.pendingConfirmation: WorkOrderStatus.repairing,
        WorkOrderStatus.confirmed: WorkOrderStatus.repairing,
        WorkOrderStatus.repairing: WorkOrderStatus.awaitingPayment,
        WorkOrderStatus.awaitingPayment: WorkOrderStatus.completed,
        WorkOrderStatus.completed: null,
        WorkOrderStatus.cancelled: null,
      }[this];

  bool get isTerminal =>
      this == WorkOrderStatus.completed || this == WorkOrderStatus.cancelled;

  String get key => name;
}

extension PaymentStatusX on PaymentStatus {
  String get label => const {
        PaymentStatus.unpaid: '未收款',
        PaymentStatus.partial: '部分收款',
        PaymentStatus.paid: '已结清',
      }[this]!;
}

extension PaymentMethodX on PaymentMethod {
  String get label => const {
        PaymentMethod.cash: '现金',
        PaymentMethod.transfer: '转账',
        PaymentMethod.card: '银行卡',
        PaymentMethod.other: '其他',
      }[this]!;
}

extension ServiceItemTypeX on ServiceItemType {
  String get label => const {
        ServiceItemType.labor: '人工',
        ServiceItemType.part: '配件',
        ServiceItemType.visit: '上门费',
        ServiceItemType.inspection: '检测费',
        ServiceItemType.transport: '运输费',
        ServiceItemType.other: '其他',
      }[this]!;

  String labelFor(String? customType) {
    final value = customType?.trim() ?? '';
    return value.isEmpty ? label : value;
  }
}

class ServiceTypeOption {
  const ServiceTypeOption({
    required this.key,
    required this.type,
    required this.customType,
    required this.label,
    required this.isBuiltIn,
  });

  factory ServiceTypeOption.builtIn(ServiceItemType type) => ServiceTypeOption(
        key: 'builtin:${type.name}',
        type: type,
        customType: null,
        label: type.label,
        isBuiltIn: true,
      );

  factory ServiceTypeOption.custom(String name) => ServiceTypeOption(
        key: keyFor(ServiceItemType.other, name),
        type: ServiceItemType.other,
        customType: name,
        label: name,
        isBuiltIn: false,
      );

  final String key;
  final ServiceItemType type;
  final String? customType;
  final String label;
  final bool isBuiltIn;

  static String keyFor(ServiceItemType type, String? customType) {
    final value = customType?.trim() ?? '';
    return value.isEmpty ? 'builtin:${type.name}' : 'custom:$value';
  }
}

double money(double value) => (value * 100).roundToDouble() / 100;

double numberValue(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? dateValue(Object? value) {
  if (value == null || value.toString().isEmpty) return null;
  return DateTime.tryParse(value.toString());
}

String? dateString(DateTime? value) => value?.toIso8601String();

T enumValue<T extends Enum>(Iterable<T> values, Object? value, T fallback) {
  return values.firstWhere(
    (item) => item.name == value?.toString(),
    orElse: () => fallback,
  );
}

String? _customTypeFromJson(Map<String, Object?> json) {
  final explicit = json['customType']?.toString().trim();
  if (explicit != null && explicit.isNotEmpty) return explicit;
  final raw = json['type']?.toString().trim();
  if (raw != null &&
      raw.isNotEmpty &&
      !ServiceItemType.values.any((type) => type.name == raw)) {
    return raw;
  }
  return null;
}
