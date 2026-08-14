part of '../work_order_dialogs.dart';

class _DialogHeader extends StatelessWidget {
  const _DialogHeader(
      {required this.kicker, required this.title, required this.subtitle});

  final String kicker;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 20, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('关闭'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _DialogSectionLabel extends StatelessWidget {
  const _DialogSectionLabel({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

class _DialogStatusChip extends StatelessWidget {
  const _DialogStatusChip(this.value, {this.payment = false});

  final Enum value;
  final bool payment;

  @override
  Widget build(BuildContext context) {
    final label = payment
        ? paymentStatusText(context, value as PaymentStatus)
        : workOrderStatusText(context, value as WorkOrderStatus);
    final color = _dialogStatusColor(context, value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DialogAmountLine extends StatelessWidget {
  const _DialogAmountLine(
      {required this.label, required this.value, this.strong = false});

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: strong ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            _dialogMoney(value),
            style: TextStyle(
              color: strong ? Theme.of(context).colorScheme.primary : null,
              fontSize: strong ? 16 : 14,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDraft {
  _ItemDraft({
    required this.name,
    required this.type,
    this.customType,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.note = '',
  });

  factory _ItemDraft.fromItem(WorkOrderItem item) => _ItemDraft(
        name: item.name,
        type: item.type,
        customType: item.customType,
        quantity: item.quantity,
        unit: item.unit,
        unitPrice: item.unitPrice,
        note: item.note,
      );

  String name;
  ServiceItemType type;
  String? customType;
  double quantity;
  String unit;
  double unitPrice;
  String note;

  double get amount => money(quantity * unitPrice);

  WorkOrderItem toItem({String defaultUnit = '次'}) => WorkOrderItem(
        id: idFor('item'),
        name: name.trim(),
        type: type,
        customType: customType,
        quantity: quantity,
        unit: unit.trim().isEmpty ? defaultUnit : unit.trim(),
        unitPrice: unitPrice,
        note: note.trim(),
      );
}
