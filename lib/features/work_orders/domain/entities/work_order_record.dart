part of 'work_order.dart';

class WorkOrder {
  const WorkOrder({
    required this.id,
    required this.number,
    required this.customerId,
    required this.serviceAddress,
    required this.deviceType,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.faultDescription,
    required this.customerRequest,
    required this.result,
    required this.customerNote,
    required this.internalNote,
    required this.status,
    required this.items,
    required this.discount,
    required this.paid,
    required this.appointmentAt,
    required this.warrantyDays,
    required this.warrantyStart,
    required this.warrantyEnd,
    required this.warrantyScope,
    required this.warrantyExclusions,
    required this.attachments,
    required this.signatureData,
    required this.quoteConfirmedAt,
    this.quoteConfirmedTotal,
    this.repairStartedAt,
    this.trashedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String number;
  final String customerId;
  final String serviceAddress;
  final String deviceType;
  final String brand;
  final String model;
  final String serialNumber;
  final String faultDescription;
  final String customerRequest;
  final String result;
  final String customerNote;
  final String internalNote;
  final WorkOrderStatus status;
  final List<WorkOrderItem> items;
  final double discount;
  final double paid;
  final DateTime? appointmentAt;
  final int warrantyDays;
  final DateTime? warrantyStart;
  final DateTime? warrantyEnd;
  final String warrantyScope;
  final String warrantyExclusions;
  final List<Attachment> attachments;
  final String? signatureData;
  final DateTime? quoteConfirmedAt;
  final double? quoteConfirmedTotal;
  final DateTime? repairStartedAt;
  final DateTime? trashedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get subtotal => money(items.fold(0, (sum, item) => sum + item.amount));
  double get total => money(math.max(subtotal - math.max(discount, 0), 0));
  double get normalizedPaid => money(math.min(math.max(paid, 0), total));
  double get outstanding => money(math.max(total - normalizedPaid, 0));
  PaymentStatus get paymentStatus {
    if (normalizedPaid <= 0) return PaymentStatus.unpaid;
    if (normalizedPaid >= total) return PaymentStatus.paid;
    return PaymentStatus.partial;
  }

  bool get isTrashed => trashedAt != null;

  bool get isReadyForConfirmation =>
      customerId.trim().isNotEmpty &&
      (faultDescription.trim().isNotEmpty ||
          items.any((item) => item.name.trim().isNotEmpty));

  WorkOrder copyWith({
    String? customerId,
    String? serviceAddress,
    String? deviceType,
    String? brand,
    String? model,
    String? serialNumber,
    String? faultDescription,
    String? customerRequest,
    String? result,
    String? customerNote,
    String? internalNote,
    WorkOrderStatus? status,
    List<WorkOrderItem>? items,
    double? discount,
    double? paid,
    Object? appointmentAt = _copyWithUnset,
    int? warrantyDays,
    Object? warrantyStart = _copyWithUnset,
    Object? warrantyEnd = _copyWithUnset,
    String? warrantyScope,
    String? warrantyExclusions,
    List<Attachment>? attachments,
    Object? signatureData = _copyWithUnset,
    Object? quoteConfirmedAt = _copyWithUnset,
    Object? quoteConfirmedTotal = _copyWithUnset,
    Object? repairStartedAt = _copyWithUnset,
    Object? trashedAt = _copyWithUnset,
    DateTime? updatedAt,
  }) =>
      WorkOrder(
        id: id,
        number: number,
        customerId: customerId ?? this.customerId,
        serviceAddress: serviceAddress ?? this.serviceAddress,
        deviceType: deviceType ?? this.deviceType,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        serialNumber: serialNumber ?? this.serialNumber,
        faultDescription: faultDescription ?? this.faultDescription,
        customerRequest: customerRequest ?? this.customerRequest,
        result: result ?? this.result,
        customerNote: customerNote ?? this.customerNote,
        internalNote: internalNote ?? this.internalNote,
        status: status ?? this.status,
        items: items ?? this.items,
        discount: discount ?? this.discount,
        paid: paid ?? this.paid,
        appointmentAt: appointmentAt == _copyWithUnset
            ? this.appointmentAt
            : appointmentAt as DateTime?,
        warrantyDays: warrantyDays ?? this.warrantyDays,
        warrantyStart: warrantyStart == _copyWithUnset
            ? this.warrantyStart
            : warrantyStart as DateTime?,
        warrantyEnd: warrantyEnd == _copyWithUnset
            ? this.warrantyEnd
            : warrantyEnd as DateTime?,
        warrantyScope: warrantyScope ?? this.warrantyScope,
        warrantyExclusions: warrantyExclusions ?? this.warrantyExclusions,
        attachments: attachments ?? this.attachments,
        signatureData: signatureData == _copyWithUnset
            ? this.signatureData
            : signatureData as String?,
        quoteConfirmedAt: quoteConfirmedAt == _copyWithUnset
            ? this.quoteConfirmedAt
            : quoteConfirmedAt as DateTime?,
        quoteConfirmedTotal: quoteConfirmedTotal == _copyWithUnset
            ? this.quoteConfirmedTotal
            : quoteConfirmedTotal == null
                ? null
                : money(numberValue(quoteConfirmedTotal)),
        repairStartedAt: repairStartedAt == _copyWithUnset
            ? this.repairStartedAt
            : repairStartedAt as DateTime?,
        trashedAt: trashedAt == _copyWithUnset
            ? this.trashedAt
            : trashedAt as DateTime?,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'number': number,
        'customerId': customerId,
        'serviceAddress': serviceAddress,
        'deviceType': deviceType,
        'brand': brand,
        'model': model,
        'serialNumber': serialNumber,
        'faultDescription': faultDescription,
        'customerRequest': customerRequest,
        'result': result,
        'customerNote': customerNote,
        'internalNote': internalNote,
        'status': status.name,
        'items': items.map((item) => item.toJson()).toList(),
        'discount': discount,
        'paid': normalizedPaid,
        'appointmentAt': dateString(appointmentAt),
        'warrantyDays': warrantyDays,
        'warrantyStart': dateString(warrantyStart),
        'warrantyEnd': dateString(warrantyEnd),
        'warrantyScope': warrantyScope,
        'warrantyExclusions': warrantyExclusions,
        'attachments': attachments.map((item) => item.toJson()).toList(),
        'signatureData': signatureData,
        'quoteConfirmedAt': dateString(quoteConfirmedAt),
        'quoteConfirmedTotal':
            quoteConfirmedTotal == null ? null : money(quoteConfirmedTotal!),
        'repairStartedAt': dateString(repairStartedAt),
        'trashedAt': dateString(trashedAt),
        'createdAt': dateString(createdAt),
        'updatedAt': dateString(updatedAt),
      };

  factory WorkOrder.fromJson(Map<String, Object?> json) => WorkOrder(
        id: json['id']?.toString() ?? '',
        number: json['number']?.toString() ?? '',
        customerId: json['customerId']?.toString() ?? '',
        serviceAddress: json['serviceAddress']?.toString() ?? '',
        deviceType: json['deviceType']?.toString() ?? '',
        brand: json['brand']?.toString() ?? '',
        model: json['model']?.toString() ?? '',
        serialNumber: json['serialNumber']?.toString() ?? '',
        faultDescription: json['faultDescription']?.toString() ?? '',
        customerRequest: json['customerRequest']?.toString() ?? '',
        result: json['result']?.toString() ?? '',
        customerNote: json['customerNote']?.toString() ?? '',
        internalNote: json['internalNote']?.toString() ?? '',
        status: enumValue(
            WorkOrderStatus.values, json['status'], WorkOrderStatus.draft),
        items: (json['items'] as List? ?? const [])
            .whereType<Map>()
            .map((item) =>
                WorkOrderItem.fromJson(Map<String, Object?>.from(item)))
            .toList(),
        discount: money(numberValue(json['discount'])),
        paid: money(numberValue(json['paid'])),
        appointmentAt: dateValue(json['appointmentAt']),
        warrantyDays: numberValue(json['warrantyDays']).round(),
        warrantyStart: dateValue(json['warrantyStart']),
        warrantyEnd: dateValue(json['warrantyEnd']),
        warrantyScope: json['warrantyScope']?.toString() ?? '',
        warrantyExclusions: json['warrantyExclusions']?.toString() ?? '',
        attachments: (json['attachments'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => Attachment.fromJson(Map<String, Object?>.from(item)))
            .toList(),
        signatureData: json['signatureData']?.toString(),
        quoteConfirmedAt: dateValue(json['quoteConfirmedAt']),
        quoteConfirmedTotal: json['quoteConfirmedTotal'] == null
            ? null
            : money(numberValue(json['quoteConfirmedTotal'])),
        repairStartedAt: dateValue(json['repairStartedAt']),
        trashedAt: dateValue(json['trashedAt']),
        createdAt: dateValue(json['createdAt']) ?? DateTime.now(),
        updatedAt: dateValue(json['updatedAt']) ?? DateTime.now(),
      );
}
