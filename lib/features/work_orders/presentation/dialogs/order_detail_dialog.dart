part of '../work_order_dialogs.dart';

enum _OrderDetailAction { cancel, moveToTrash }

class OrderDetailDialog extends StatefulWidget {
  const OrderDetailDialog(
      {required this.controller,
      required this.orderId,
      required this.onEdit,
      required this.onPayment,
      required this.onSignature,
      required this.onDocument,
      required this.onMoveToTrash,
      this.fileSelectionService,
      this.asPage = false,
      super.key});

  final WorkOrderController controller;
  final String orderId;
  final VoidCallback onEdit;
  final VoidCallback onPayment;
  final VoidCallback onSignature;
  final ValueChanged<String> onDocument;
  final Future<void> Function() onMoveToTrash;
  final FileSelectionService? fileSelectionService;
  final bool asPage;

  @override
  State<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<OrderDetailDialog> {
  String _photoCategory = 'before';
  late final FileSelectionService _fileSelectionService;

  @override
  void initState() {
    super.initState();
    _fileSelectionService =
        widget.fileSelectionService ?? PlatformFileSelectionService();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final order = widget.controller.orderById(widget.orderId);
        if (order == null) return const SizedBox.shrink();
        final customer = widget.controller.customerById(order.customerId);
        final locked = order.status.isTerminal || order.isTrashed;
        final canReceivePayment = !locked && order.outstanding > 0;
        final next = locked ? null : order.status.next;
        final detail = Column(
          children: [
            if (!widget.asPage)
              _DialogHeader(
                kicker: 'WORK ORDER / DETAIL',
                title: customer?.name.isNotEmpty == true
                    ? customer!.name
                    : context.tr('未关联客户'),
                subtitle:
                    '${_dialogDeviceLocalized(context, order)} · ${order.number}',
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(11, 0, 11, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OrderHero(
                      order: order,
                      next: next,
                      onAdvance: next == null ||
                              (next == WorkOrderStatus.completed &&
                                  order.outstanding > 0)
                          ? null
                          : () => widget.controller.advanceStatus(order.id),
                      onEdit: locked ? null : widget.onEdit,
                      onCancel: locked || widget.asPage
                          ? null
                          : () => widget.controller.cancelOrder(order.id),
                    ),
                    const SizedBox(height: 16),
                    _FieldOperationsCard(
                      onSignature: locked ? null : widget.onSignature,
                      onPhoto: locked ? null : () => _addPhoto(order),
                      onPayment: canReceivePayment ? widget.onPayment : null,
                      onReceipt: () => widget.onDocument('receipt'),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final main = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DetailInfo(order: order, customer: customer),
                            const SizedBox(height: 16),
                            _LineItemsCard(
                              order: order,
                              onQuote: () => widget.onDocument('quote'),
                            ),
                            if (order.result.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _NoteCard(
                                title: context.tr('维修结果'),
                                text: order.result,
                              ),
                            ],
                            if (order.internalNote.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _NoteCard(
                                title: context.tr('内部备注'),
                                text: order.internalNote,
                              ),
                            ],
                          ],
                        );
                        final side = Column(
                          children: [
                            _PaymentCard(
                              order: order,
                              payments: widget.controller.paymentsFor(order.id),
                              onAdd:
                                  canReceivePayment ? widget.onPayment : null,
                            ),
                            const SizedBox(height: 12),
                            _WarrantyCard(order: order),
                            const SizedBox(height: 12),
                            _SignatureCard(
                                order: order,
                                onSign: locked ? null : widget.onSignature),
                          ],
                        );
                        if (constraints.maxWidth < 720) {
                          return Column(
                            children: [main, const SizedBox(height: 16), side],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: main),
                            const SizedBox(width: 16),
                            SizedBox(width: 285, child: side),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _PhotoCard(
                      controller: widget.controller,
                      order: order,
                      category: _photoCategory,
                      editable: !locked,
                      fileSelectionService: _fileSelectionService,
                      onCategoryChanged: (value) =>
                          setState(() => _photoCategory = value),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!widget.asPage)
                    TextButton.icon(
                      onPressed: order.isTrashed ? null : widget.onMoveToTrash,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 17),
                      label: Text(context.tr('移入回收站')),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  OutlinedButton(
                    onPressed: () => widget.onDocument('quote'),
                    child: Text(context.tr('报价单')),
                  ),
                  OutlinedButton(
                    onPressed: () => widget.onDocument('receipt'),
                    child: Text(context.tr('维修凭证')),
                  ),
                  FilledButton(
                    onPressed: canReceivePayment ? widget.onPayment : null,
                    child: Text(context.tr('记录收款')),
                  ),
                ],
              ),
            ),
          ],
        );
        if (widget.asPage) {
          return Scaffold(
            appBar: AppBackBar(
              title: customer?.name.isNotEmpty == true
                  ? customer!.name
                  : context.tr('工单详情'),
              onBack: () => Navigator.of(context).pop(),
              actions: [
                PopupMenuButton<_OrderDetailAction>(
                  tooltip: context.tr('工单操作'),
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) async {
                    switch (action) {
                      case _OrderDetailAction.cancel:
                        await widget.controller.cancelOrder(order.id);
                      case _OrderDetailAction.moveToTrash:
                        await widget.onMoveToTrash();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _OrderDetailAction.cancel,
                      enabled: !locked,
                      child: Text(context.tr('取消工单')),
                    ),
                    PopupMenuItem(
                      value: _OrderDetailAction.moveToTrash,
                      enabled: !order.isTrashed,
                      child: Text(context.tr('移入回收站')),
                    ),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              child: SizedBox(width: double.infinity, child: detail),
            ),
          );
        }
        final viewInsets = MediaQuery.viewInsetsOf(context);
        final maxHeight =
            (MediaQuery.sizeOf(context).height - viewInsets.bottom - 22)
                .clamp(300.0, 880.0)
                .toDouble();
        return Dialog(
          insetPadding: const EdgeInsets.all(11),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1280, maxHeight: maxHeight),
            child: detail,
          ),
        );
      },
    );
  }

  Future<void> _addPhoto(WorkOrder order) async {
    final category = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(context.tr('选择照片分类')),
              subtitle: Text(context.tr('照片会归档到当前工单。')),
            ),
            for (final item in const [
              ('before', '维修前'),
              ('during', '维修中'),
              ('after', '维修后'),
            ])
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(context.tr(item.$2)),
                onTap: () => Navigator.pop(context, item.$1),
              ),
          ],
        ),
      ),
    );
    if (!mounted || category == null) return;
    setState(() => _photoCategory = category);
    await _pickOrderPhotos(
      context: context,
      controller: widget.controller,
      order: order,
      category: category,
      fileSelectionService: _fileSelectionService,
    );
  }
}

class _FieldOperationsCard extends StatelessWidget {
  const _FieldOperationsCard({
    required this.onSignature,
    required this.onPhoto,
    required this.onPayment,
    required this.onReceipt,
  });

  final VoidCallback? onSignature;
  final VoidCallback? onPhoto;
  final VoidCallback? onPayment;
  final VoidCallback onReceipt;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('现场操作'),
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text(
                        context.tr('签名、照片、收款和凭证集中处理'),
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.flash_on_outlined,
                    color: Theme.of(context).colorScheme.primary),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FieldOperationButton(
                  icon: Icons.draw_outlined,
                  label: context.tr('签名'),
                  onPressed: onSignature,
                ),
                _FieldOperationButton(
                  icon: Icons.photo_camera_outlined,
                  label: context.tr('拍照'),
                  onPressed: onPhoto,
                ),
                _FieldOperationButton(
                  icon: Icons.payments_outlined,
                  label: context.tr('收款'),
                  onPressed: onPayment,
                ),
                _FieldOperationButton(
                  icon: Icons.receipt_long_outlined,
                  label: context.tr('生成凭证'),
                  onPressed: onReceipt,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldOperationButton extends StatelessWidget {
  const _FieldOperationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
      );
}

class _OrderHero extends StatelessWidget {
  const _OrderHero(
      {required this.order,
      required this.next,
      required this.onAdvance,
      required this.onEdit,
      required this.onCancel});

  final WorkOrder order;
  final WorkOrderStatus? next;
  final VoidCallback? onAdvance;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  _DialogStatusChip(order.status),
                  _DialogStatusChip(order.paymentStatus, payment: true),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                _dialogMoney(order.total),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.trf(
                  '创建于 {created} · 更新于 {updated}',
                  {
                    'created': _dialogDateLocalized(context, order.createdAt),
                    'updated':
                        _dialogDateTimeLocalized(context, order.updatedAt),
                  },
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          );
          final actions = Wrap(
            alignment: WrapAlignment.end,
            spacing: 7,
            runSpacing: 7,
            children: [
              OutlinedButton(
                onPressed: onEdit,
                child: Text(context.tr('编辑')),
              ),
              if (next != null)
                FilledButton(
                  onPressed: onAdvance,
                  child: Text(
                    order.status == WorkOrderStatus.pendingConfirmation
                        ? context.tr('确认报价并开始维修')
                        : context.trf(
                            '推进至 {status}',
                            {
                              'status': workOrderStatusText(context, next!),
                            },
                          ),
                  ),
                ),
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: Text(context.tr('取消工单')),
                ),
            ],
          );
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 13), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: summary), actions],
          );
        },
      ),
    );
  }
}

class _DetailInfo extends StatelessWidget {
  const _DetailInfo({required this.order, required this.customer});

  final WorkOrder order;
  final Customer? customer;

  @override
  Widget build(BuildContext context) {
    final address = order.serviceAddress.isNotEmpty
        ? order.serviceAddress
        : customer?.address.isNotEmpty == true
            ? customer!.address
            : context.tr('未填写');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr('服务信息'),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _MiniInfo(
                label: context.tr('客户'),
                value: '${customer?.name ?? context.tr('未关联')} · '
                    '${customer?.phone.isEmpty == false ? customer!.phone : context.tr('未填写电话')}'),
            _MiniInfo(label: context.tr('服务地址'), value: address),
            _MiniInfo(
              label: context.tr('设备'),
              value: _dialogDeviceLocalized(context, order),
            ),
            _MiniInfo(
              label: context.tr('预约时间'),
              value: _dialogDateTimeLocalized(context, order.appointmentAt),
            ),
            _MiniInfo(
                label: context.tr('故障描述'),
                value: order.faultDescription.isEmpty
                    ? context.tr('未填写')
                    : order.faultDescription),
            if (_workOrderNote(order).isNotEmpty)
              _MiniInfo(label: context.tr('备注'), value: _workOrderNote(order)),
            if (order.serialNumber.isNotEmpty)
              _MiniInfo(label: context.tr('序列号'), value: order.serialNumber),
          ],
        ),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 360),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, height: 1.45)),
        ],
      ),
    );
  }
}

class _LineItemsCard extends StatelessWidget {
  const _LineItemsCard({required this.order, required this.onQuote});

  final WorkOrder order;
  final VoidCallback onQuote;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 9),
            child: Row(
              children: [
                Text(context.tr('报价明细'),
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(
                  onPressed: onQuote,
                  child: Text(context.tr('预览报价单 →')),
                ),
              ],
            ),
          ),
          if (order.items.isEmpty)
            Padding(
              padding: EdgeInsets.all(22),
              child: Text(context.tr('尚未添加项目'),
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            )
          else ...[
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.4),
              },
              children: [
                TableRow(
                  children: [
                    _TableCell(context.tr('项目'), header: true),
                    _TableCell(context.tr('数量'), header: true),
                    _TableCell(
                      context.tr('小计'),
                      header: true,
                      alignEnd: true,
                    ),
                  ],
                ),
                ...order.items.map(
                  (item) => TableRow(
                    children: [
                      _TableCell(item.name, note: item.note),
                      _TableCell('${item.quantity} ${item.unit}'),
                      _TableCell(_dialogMoney(item.amount), alignEnd: true),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
              child: Column(
                children: [
                  _DialogAmountLine(
                    label: context.tr('项目小计'),
                    value: order.subtotal,
                  ),
                  _DialogAmountLine(
                    label: context.tr('优惠'),
                    value: -order.discount,
                  ),
                  _DialogAmountLine(
                    label: context.tr('应收合计'),
                    value: order.total,
                    strong: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.text,
      {this.header = false, this.alignEnd = false, this.note = ''});

  final String text;
  final bool header;
  final bool alignEnd;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: header
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : null,
                fontWeight: header ? FontWeight.normal : FontWeight.w500,
                fontFamily: alignEnd && !header ? 'monospace' : null,
              ),
            ),
            if (note.isNotEmpty)
              Text(
                note,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            height: 1.55,
          ),
          children: [
            TextSpan(
              text: '$title\n',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard(
      {required this.order, required this.payments, required this.onAdd});

  final WorkOrder order;
  final List<PaymentRecord> payments;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final progress = order.total <= 0
        ? 0.0
        : (order.normalizedPaid / order.total).clamp(0.0, 1.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(context.tr('收款'),
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 15),
                  label: Text(context.tr('记一笔')),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _dialogMoney(order.normalizedPaid),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Text(
                  '${context.tr('应收')} ${_dialogMoney(order.total)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Text(
                  '${context.tr('未收')} ${_dialogMoney(order.outstanding)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                _DialogStatusChip(order.paymentStatus, payment: true),
              ],
            ),
            if (payments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 7),
              ...payments.take(4).map(
                    (payment) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${paymentMethodText(context, payment.method)} · '
                              '${_dialogDateLocalized(context, payment.paidAt)}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            _dialogMoney(payment.amount),
                            style: const TextStyle(
                                fontSize: 14, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WarrantyCard extends StatelessWidget {
  const _WarrantyCard({required this.order});

  final WorkOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('保修信息'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 13),
            _KeyValue(
                label: context.tr('保修期限'),
                value: order.warrantyDays > 0
                    ? context.trf('{days} 天', {'days': order.warrantyDays})
                    : context.tr('未设置')),
            const SizedBox(height: 11),
            Divider(
                height: 1, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 9),
            _KeyValue(
              label: context.tr('开始'),
              value: _dialogDateLocalized(context, order.warrantyStart),
            ),
            const SizedBox(height: 7),
            _KeyValue(
              label: context.tr('结束'),
              value: _dialogDateLocalized(context, order.warrantyEnd),
            ),
            if (order.warrantyScope.isNotEmpty) ...[
              const SizedBox(height: 11),
              Text(
                context.trf('范围：{scope}', {'scope': order.warrantyScope}),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
            if (order.warrantyExclusions.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                context.trf(
                  '除外：{exclusions}',
                  {'exclusions': order.warrantyExclusions},
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({required this.order, required this.onSign});

  final WorkOrder order;
  final VoidCallback? onSign;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeDataUrl(order.signatureData);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(context.tr('客户确认'),
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(
                    onPressed: onSign,
                    child: Text(
                      context.tr(bytes == null ? '去签名 →' : '重新签名'),
                    )),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 74,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: .5),
                borderRadius: BorderRadius.circular(9),
              ),
              child: bytes == null
                  ? Text(
                      context.tr('尚未记录签名'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    )
                  : Image.memory(bytes, fit: BoxFit.contain),
            ),
            if (order.quoteConfirmedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.trf(
                    '已于 {date} 记录确认{amount}',
                    {
                      'date': _dialogDateTimeLocalized(
                        context,
                        order.quoteConfirmedAt,
                      ),
                      'amount': order.quoteConfirmedTotal == null
                          ? ''
                          : context.trf(
                              '，确认金额 {amount}',
                              {
                                'amount': _dialogMoney(
                                  order.quoteConfirmedTotal!,
                                ),
                              },
                            ),
                    },
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pickOrderPhotos({
  required BuildContext context,
  required WorkOrderController controller,
  required WorkOrder order,
  required String category,
  required FileSelectionService fileSelectionService,
}) async {
  final source = await showModalBottomSheet<_PhotoSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              context.trf(
                '添加{category}照片',
                {'category': context.tr(_categoryLabel(category))},
              ),
            ),
            subtitle: Text(context.tr('可以直接拍照，也可以从本地选择图片文件。')),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(context.tr('拍照')),
            onTap: () => Navigator.pop(context, _PhotoSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: Text(context.tr('从文件选择')),
            onTap: () => Navigator.pop(context, _PhotoSource.file),
          ),
          const SizedBox(height: 6),
        ],
      ),
    ),
  );
  if (!context.mounted || source == null) return;

  List<SelectedFile> selectedFiles;
  try {
    if (source == _PhotoSource.camera) {
      final file =
          await fileSelectionService.pickImage(ImageSelectionSource.camera);
      if (file == null) return;
      selectedFiles = [file];
    } else {
      selectedFiles = await fileSelectionService.pickFiles(
        kind: FileSelectionKind.image,
        allowMultiple: true,
      );
    }
  } catch (_) {
    if (context.mounted) {
      showTopNotice(
        context,
        context.tr('无法打开图片来源，请检查设备权限后重试。'),
        error: true,
      );
    }
    return;
  }

  if (!context.mounted || selectedFiles.isEmpty) return;

  String? notice;
  var noticeIsError = false;
  await _runWithPhotoLoading(context, () async {
    final loadedPhotos = (await Future.wait(
      selectedFiles.map((file) async {
        try {
          return _PhotoFileBytes(
            name: file.name,
            bytes: await file.readAsBytes(),
          );
        } catch (_) {
          return null;
        }
      }),
    ))
        .whereType<_PhotoFileBytes>()
        .toList();

    if (loadedPhotos.isEmpty) {
      if (!context.mounted) return;
      notice = context.tr('照片读取失败，未保存照片。');
      noticeIsError = true;
      return;
    }

    final now = DateTime.now();
    if (!context.mounted) return;
    final watermark = _photoWatermarkText(context, now, category);
    final attachments = (await Future.wait(
      loadedPhotos.map((photo) async {
        try {
          final bytes = await _watermarkPhoto(photo.bytes, watermark);
          if (bytes == null || bytes.isEmpty) return null;
          return Attachment(
            id: idFor('att'),
            category: category,
            path: 'data:image/png;base64,${base64Encode(bytes)}',
            caption: '${photo.name} · $watermark',
            createdAt: now,
          );
        } catch (_) {
          return null;
        }
      }),
    ))
        .whereType<Attachment>()
        .toList();

    if (attachments.isEmpty) {
      if (!context.mounted) return;
      notice = context.tr('照片水印生成失败，未保存照片。');
      noticeIsError = true;
      return;
    }

    await controller.addAttachments(order.id, attachments);
    if (!context.mounted) return;
    final failedCount = selectedFiles.length - attachments.length;
    notice = context.trf(
      '已添加 {count} 张{category}照片。{failed}',
      {
        'count': attachments.length,
        'category': context.tr(_categoryLabel(category)),
        'failed': failedCount == 0
            ? ''
            : context.trf('另有 {count} 张未保存。', {'count': failedCount}),
      },
    );
  });

  if (context.mounted && notice != null) {
    showTopNotice(context, notice!, error: noticeIsError);
  }
}

enum _PhotoSource { camera, file }

class _PhotoFileBytes {
  const _PhotoFileBytes({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

Future<void> _runWithPhotoLoading(
  BuildContext context,
  Future<void> Function() task,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final loadingRoute = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PhotoProcessingDialog(),
  );
  try {
    // Let the modal route paint before image decoding starts on the UI thread.
    await WidgetsBinding.instance.endOfFrame;
    await task();
  } finally {
    if (navigator.mounted) navigator.pop();
    await loadingRoute;
  }
}

class _PhotoProcessingDialog extends StatelessWidget {
  const _PhotoProcessingDialog();

  @override
  Widget build(BuildContext context) => PopScope<void>(
        canPop: false,
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 22, 24, 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 16),
                  Flexible(child: Text(context.tr('正在处理照片，请稍候…'))),
                ],
              ),
            ),
          ),
        ),
      );
}

String _photoWatermarkText(
  BuildContext context,
  DateTime value,
  String category,
) =>
    '${DateFormat('yyyy/MM/dd HH:mm:ss').format(value)} '
    '${context.tr(_categoryLabel(category))}';

const _maxProcessedPhotoEdge = 2048;
// Increasing both tile dimensions again cuts the current watermark density
// approximately in half.
const _photoWatermarkSpacingScale = 2.25;

Future<Uint8List?> _watermarkPhoto(Uint8List bytes, String text) async {
  ui.Codec? codec;
  ui.Image? source;
  ui.Image? output;
  try {
    codec = await ui.instantiateImageCodecWithSize(
      await ui.ImmutableBuffer.fromUint8List(bytes),
      getTargetSize: (width, height) {
        if (width <= _maxProcessedPhotoEdge &&
            height <= _maxProcessedPhotoEdge) {
          return const ui.TargetImageSize();
        }
        return width >= height
            ? const ui.TargetImageSize(width: _maxProcessedPhotoEdge)
            : const ui.TargetImageSize(height: _maxProcessedPhotoEdge);
      },
    );
    source = (await codec.getNextFrame()).image;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImage(source, ui.Offset.zero, ui.Paint());

    final fontSize = (source.width / 34).clamp(9.0, 32.0).toDouble();
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .18),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: .10),
              blurRadius: 1.5,
              offset: const Offset(.5, .5),
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: source.width.toDouble());

    // Repeat a light, diagonal watermark over the complete image. There is no
    // opaque band behind it, so the original photo remains visible.
    final tileWidth =
        (painter.width + fontSize * 2.5) * _photoWatermarkSpacingScale;
    final tileHeight =
        (painter.height + fontSize * 2.2) * _photoWatermarkSpacingScale;
    final margin = (source.width + source.height).toDouble();
    final imageWidth = source.width.toDouble();
    final imageHeight = source.height.toDouble();
    canvas
      ..save()
      ..clipRect(ui.Rect.fromLTWH(0, 0, imageWidth, imageHeight));
    var row = 0;
    for (var y = -margin; y < imageHeight + margin; y += tileHeight) {
      final offset = row.isEven ? 0.0 : tileWidth * .5;
      for (var x = -margin; x < imageWidth + margin; x += tileWidth) {
        canvas
          ..save()
          ..translate(x + offset, y)
          ..rotate(-.24);
        painter.paint(canvas, Offset.zero);
        canvas.restore();
      }
      row++;
    }
    canvas.restore();

    final picture = recorder.endRecording();
    output = await picture.toImage(source.width, source.height);
    final data = await output.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } catch (_) {
    return null;
  } finally {
    source?.dispose();
    output?.dispose();
    codec?.dispose();
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard(
      {required this.controller,
      required this.order,
      required this.category,
      required this.editable,
      required this.fileSelectionService,
      required this.onCategoryChanged});

  final WorkOrderController controller;
  final WorkOrder order;
  final String category;
  final bool editable;
  final FileSelectionService fileSelectionService;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final photos =
        order.attachments.where((item) => item.category == category).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(context.tr('维修照片'),
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                Text(
                  '${order.attachments.length} ${context.tr('张')}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                DropdownButton<String>(
                  value: category,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: 'before',
                      child: Text(context.tr('维修前')),
                    ),
                    DropdownMenuItem(
                      value: 'during',
                      child: Text(context.tr('维修中')),
                    ),
                    DropdownMenuItem(
                      value: 'after',
                      child: Text(context.tr('维修后')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onCategoryChanged(value);
                  },
                ),
                OutlinedButton.icon(
                  onPressed: editable ? () => _pick(context) : null,
                  icon:
                      const Icon(Icons.add_photo_alternate_outlined, size: 15),
                  label: Text(context.tr('添加照片')),
                ),
              ],
            ),
            const SizedBox(height: 11),
            if (photos.isEmpty)
              Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  context.trf(
                    '{category}暂无照片',
                    {'category': context.tr(_categoryLabel(category))},
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.1,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) => _PhotoTile(
                  attachment: photos[index],
                  onDelete: editable
                      ? () {
                          _confirmDeletePhoto(context, photos[index]);
                        }
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    await _pickOrderPhotos(
      context: context,
      controller: controller,
      order: order,
      category: category,
      fileSelectionService: fileSelectionService,
    );
  }

  Future<void> _confirmDeletePhoto(
    BuildContext context,
    Attachment attachment,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('删除维修照片？')),
            content: Text(context.tr('照片删除后无法恢复，确定要删除吗？')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('取消')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr('确认删除')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    await controller.removeAttachment(order.id, attachment.id);
  }
}

String _categoryLabel(String value) =>
    const {
      'before': '维修前',
      'during': '维修中',
      'after': '维修后',
    }[value] ??
    '照片';

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.attachment, required this.onDelete});

  final Attachment attachment;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeDataUrl(attachment.path);
    final preview =
        bytes == null ? null : () => _showPhotoPreview(context, bytes);
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bytes != null)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: InkWell(
                onTap: preview,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            )
          else
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.image_outlined),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: onDelete == null
                ? const SizedBox.shrink()
                : InkWell(
                    onTap: onDelete,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 13, color: Colors.white),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showPhotoPreview(
  BuildContext context,
  Uint8List bytes,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: context.tr('关闭大图'),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
