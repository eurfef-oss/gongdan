part of 'work_order.dart';

class WorkOrderCost {
  const WorkOrderCost({
    required this.id,
    required this.typeId,
    required this.typeName,
    required this.amount,
    this.note = '',
  });

  final String id;
  final String typeId;
  final String typeName;
  final double amount;
  final String note;

  WorkOrderCost copyWith({
    String? typeId,
    String? typeName,
    double? amount,
    String? note,
  }) =>
      WorkOrderCost(
        id: id,
        typeId: typeId ?? this.typeId,
        typeName: typeName ?? this.typeName,
        amount: amount ?? this.amount,
        note: note ?? this.note,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'typeId': typeId,
        'typeName': typeName,
        'amount': money(math.max(amount, 0)),
        'note': note,
      };

  factory WorkOrderCost.fromJson(Map<String, Object?> json) => WorkOrderCost(
        id: json['id']?.toString() ?? idFor('cost'),
        typeId: json['typeId']?.toString() ?? '',
        typeName: json['typeName']?.toString() ?? '其他',
        amount: money(math.max(numberValue(json['amount']), 0)),
        note: json['note']?.toString() ?? '',
      );
}
