part of 'work_order.dart';

class CostType {
  const CostType({
    required this.id,
    required this.name,
    required this.enabled,
  });

  final String id;
  final String name;
  final bool enabled;

  CostType copyWith({
    String? name,
    bool? enabled,
  }) =>
      CostType(
        id: id,
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
      };

  factory CostType.fromJson(Map<String, Object?> json) => CostType(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        enabled: json['enabled'] != false,
      );
}

const defaultCostTypes = <CostType>[
  CostType(id: 'parts', name: '配件', enabled: true),
  CostType(id: 'labor', name: '人工', enabled: true),
  CostType(id: 'consumables', name: '耗材', enabled: true),
  CostType(id: 'travel', name: '交通 / 上门', enabled: true),
  CostType(id: 'outsourcing', name: '外包', enabled: true),
  CostType(id: 'logistics', name: '物流', enabled: true),
  CostType(id: 'other', name: '其他', enabled: true),
];
