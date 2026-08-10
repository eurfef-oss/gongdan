part of 'work_order.dart';

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.type,
    this.customType,
    required this.unit,
    required this.defaultPrice,
    required this.warrantyDays,
    required this.enabled,
  });

  final String id;
  final String name;
  final ServiceItemType type;
  final String? customType;
  final String unit;
  final double defaultPrice;
  final int warrantyDays;
  final bool enabled;

  ServiceItem copyWith({
    String? name,
    ServiceItemType? type,
    Object? customType = _copyWithUnset,
    String? unit,
    double? defaultPrice,
    int? warrantyDays,
    bool? enabled,
  }) =>
      ServiceItem(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        customType: customType == _copyWithUnset
            ? this.customType
            : customType as String?,
        unit: unit ?? this.unit,
        defaultPrice: defaultPrice ?? this.defaultPrice,
        warrantyDays: warrantyDays ?? this.warrantyDays,
        enabled: enabled ?? this.enabled,
      );

  String get typeLabel => type.labelFor(customType);

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'customType': customType,
        'unit': unit,
        'defaultPrice': defaultPrice,
        'warrantyDays': warrantyDays,
        'enabled': enabled,
      };

  factory ServiceItem.fromJson(Map<String, Object?> json) {
    return ServiceItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: enumValue(
          ServiceItemType.values, json['type'], ServiceItemType.other),
      customType: _customTypeFromJson(json),
      unit: json['unit']?.toString() ?? '次',
      defaultPrice: money(numberValue(json['defaultPrice'])),
      warrantyDays: numberValue(json['warrantyDays']).round(),
      enabled: json['enabled'] != false,
    );
  }
}
