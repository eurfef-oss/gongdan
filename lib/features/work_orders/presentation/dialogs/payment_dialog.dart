part of '../work_order_dialogs.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog(
      {required this.controller, required this.orderId, super.key});

  final WorkOrderController controller;
  final String orderId;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  PaymentMethod _method = PaymentMethod.transfer;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final order = widget.controller.orderById(widget.orderId);
    _amount = TextEditingController(
        text: order?.outstanding.toStringAsFixed(2) ?? '');
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.controller.orderById(widget.orderId);
    if (order == null) return const SizedBox.shrink();
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight =
        (MediaQuery.sizeOf(context).height - viewInsets.bottom - 22)
            .clamp(240.0, 620.0)
            .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(11),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              kicker: 'PAYMENT / RECORD',
              title: context.tr('记录收款'),
              subtitle: context.trf(
                '{number} · 当前未收 {amount}',
                {
                  'number': order.number,
                  'amount': _dialogMoney(
                    order.outstanding,
                    currencySymbol: widget.controller.data.settings.currencySymbol,
                  ),
                },
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(11, 0, 11, 18),
                child: Column(
                  children: [
                    TextField(
                      controller: _amount,
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: context.tr('本次收款金额 *'),
                        prefixText:
                            '${widget.controller.data.settings.currencySymbol} ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentMethod>(
                      initialValue: _method,
                      decoration:
                          InputDecoration(labelText: context.tr('收款方式')),
                      items: PaymentMethod.values
                          .map(
                            (item) => DropdownMenuItem<PaymentMethod>(
                              value: item,
                              child: Text(paymentMethodText(context, item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _method = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      maxLines: 2,
                      decoration:
                          InputDecoration(labelText: context.tr('备注（可选）')),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(context.tr('取消'))),
                  const SizedBox(width: 8),
                  FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(context.tr('保存收款'))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    setState(() => _saving = true);
    final ok = await widget.controller.recordPayment(
      orderId: widget.orderId,
      amount: amount,
      method: _method,
      note: _note.text.trim(),
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      showTopNotice(
        context,
        context.tr('金额无效，不能超过当前未收金额。'),
        error: true,
      );
      return;
    }
    Navigator.pop(context);
  }
}
