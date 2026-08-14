part of 'work_order.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.wechat = '',
    this.address = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String wechat;
  final String address;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get clipboardText => clipboardTextFor((value) => value);

  String clipboardTextFor(String Function(String) translate) => [
        '${translate('姓名')}：$name',
        if (phone.trim().isNotEmpty) '${translate('电话')}：$phone',
        if (wechat.trim().isNotEmpty) '${translate('微信')}：$wechat',
        if (address.trim().isNotEmpty) '${translate('服务地址')}：$address',
        if (notes.trim().isNotEmpty) '${translate('备注')}：$notes',
      ].join('\n');

  Customer copyWith({
    String? name,
    String? phone,
    String? wechat,
    String? address,
    String? notes,
    DateTime? updatedAt,
  }) =>
      Customer(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        wechat: wechat ?? this.wechat,
        address: address ?? this.address,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'wechat': wechat,
        'address': address,
        'notes': notes,
        'createdAt': dateString(createdAt),
        'updatedAt': dateString(updatedAt),
      };

  factory Customer.fromJson(Map<String, Object?> json) => Customer(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        wechat: json['wechat']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        createdAt: dateValue(json['createdAt']) ?? DateTime.now(),
        updatedAt: dateValue(json['updatedAt']) ?? DateTime.now(),
      );
}
