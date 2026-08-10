part of 'work_order.dart';

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.note,
    required this.paidAt,
  });

  final String id;
  final String orderId;
  final double amount;
  final PaymentMethod method;
  final String note;
  final DateTime paidAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'orderId': orderId,
        'amount': amount,
        'method': method.name,
        'note': note,
        'paidAt': dateString(paidAt),
      };

  factory PaymentRecord.fromJson(Map<String, Object?> json) => PaymentRecord(
        id: json['id']?.toString() ?? '',
        orderId: json['orderId']?.toString() ?? '',
        amount: money(numberValue(json['amount'])),
        method: enumValue(
            PaymentMethod.values, json['method'], PaymentMethod.other),
        note: json['note']?.toString() ?? '',
        paidAt: dateValue(json['paidAt']) ?? DateTime.now(),
      );
}
