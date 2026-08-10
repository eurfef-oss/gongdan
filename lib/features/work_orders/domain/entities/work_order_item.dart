part of 'work_order.dart';

class WorkOrderItem {
  const WorkOrderItem({
    required this.id,
    required this.name,
    required this.type,
    this.customType,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.note = '',
  });

  final String id;
  final String name;
  final ServiceItemType type;
  final String? customType;
  final double quantity;
  final String unit;
  final double unitPrice;
  final String note;

  double get amount => money(math.max(quantity, 0) * math.max(unitPrice, 0));

  WorkOrderItem copyWith({
    String? name,
    ServiceItemType? type,
    Object? customType = _copyWithUnset,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? note,
  }) =>
      WorkOrderItem(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        customType: customType == _copyWithUnset
            ? this.customType
            : customType as String?,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        unitPrice: unitPrice ?? this.unitPrice,
        note: note ?? this.note,
      );

  String get typeLabel => type.labelFor(customType);

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'customType': customType,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'amount': amount,
        'note': note,
      };

  factory WorkOrderItem.fromJson(Map<String, Object?> json) {
    return WorkOrderItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: enumValue(
          ServiceItemType.values, json['type'], ServiceItemType.other),
      customType: _customTypeFromJson(json),
      quantity: numberValue(json['quantity'], 1),
      unit: json['unit']?.toString() ?? '次',
      unitPrice: money(numberValue(json['unitPrice'])),
      note: json['note']?.toString() ?? '',
    );
  }
}
