part of '../work_order_dialogs.dart';

class CustomerEditorDialog extends StatefulWidget {
  const CustomerEditorDialog(
      {required this.controller, this.initial, super.key});

  final WorkOrderController controller;
  final Customer? initial;

  @override
  State<CustomerEditorDialog> createState() => _CustomerEditorDialogState();
}

class _CustomerEditorDialogState extends State<CustomerEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _wechat;
  late final TextEditingController _address;
  late final TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final customer = widget.initial;
    _name = TextEditingController(text: customer?.name ?? '');
    _phone = TextEditingController(text: customer?.phone ?? '');
    _wechat = TextEditingController(text: customer?.wechat ?? '');
    _address = TextEditingController(text: customer?.address ?? '');
    _notes = TextEditingController(text: customer?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _wechat.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight =
        (MediaQuery.sizeOf(context).height - viewInsets.bottom - 22)
            .clamp(240.0, 700.0)
            .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(11),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              kicker:
                  widget.initial == null ? 'NEW / CUSTOMER' : 'EDIT / CUSTOMER',
              title: context.tr(widget.initial == null ? '新增客户' : '编辑客户'),
              subtitle: context.tr('姓名、联系方式和服务地址会用于后续工单和维修凭证。'),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(11, 0, 11, 18),
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: context.tr('姓名 *'),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TwoFields(
                      first: TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration:
                            InputDecoration(labelText: context.tr('手机号')),
                      ),
                      second: TextField(
                        controller: _wechat,
                        decoration:
                            InputDecoration(labelText: context.tr('微信号')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _address,
                      decoration: InputDecoration(
                        labelText: context.tr('常用服务地址'),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notes,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: context.tr('备注')),
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
                    child: Text(context.tr('取消')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('保存客户')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showTopNotice(context, context.tr('请填写客户姓名。'), error: true);
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final old = widget.initial;
    final customer = old == null
        ? Customer(
            id: idFor('cus'),
            name: name,
            phone: _phone.text.trim(),
            wechat: _wechat.text.trim(),
            address: _address.text.trim(),
            notes: _notes.text.trim(),
            createdAt: now,
            updatedAt: now,
          )
        : old.copyWith(
            name: name,
            phone: _phone.text.trim(),
            wechat: _wechat.text.trim(),
            address: _address.text.trim(),
            notes: _notes.text.trim(),
            updatedAt: now,
          );
    await widget.controller.saveCustomer(customer);
    if (mounted) Navigator.pop(context, customer);
  }
}

class _TwoFields extends StatelessWidget {
  const _TwoFields({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 440) {
          return Column(
            children: [first, const SizedBox(height: 12), second],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class CustomerDetailDialog extends StatelessWidget {
  const CustomerDetailDialog(
      {required this.controller,
      required this.customerId,
      required this.onEdit,
      required this.onCreateOrder,
      super.key});

  final WorkOrderController controller;
  final String customerId;
  final VoidCallback onEdit;
  final VoidCallback onCreateOrder;

  @override
  Widget build(BuildContext context) {
    final customer = controller.customerById(customerId);
    if (customer == null) return const SizedBox.shrink();
    final orders = controller.data.workOrders
        .where((order) => order.customerId == customerId && !order.isTrashed)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final outstanding =
        orders.fold<double>(0, (sum, order) => sum + order.outstanding);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight =
        (MediaQuery.sizeOf(context).height - viewInsets.bottom - 22)
            .clamp(240.0, 760.0)
            .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(11),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 660, maxHeight: maxHeight),
        child: Column(
          children: [
            _DialogHeader(
              kicker: 'CUSTOMER / PROFILE',
              title: customer.name,
              subtitle:
                  '${customer.phone.isEmpty ? context.tr('未填写手机号') : customer.phone} · '
                  '${customer.address.isEmpty ? context.tr('未填写地址') : customer.address}',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(11, 0, 11, 22),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 23,
                                backgroundColor:
                                    _dialogTeal.withValues(alpha: .11),
                                child: Text(
                                  customer.name.characters.first,
                                  style: const TextStyle(
                                    color: _dialogTeal,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  customer.notes.isEmpty
                                      ? context.tr('暂无客户备注')
                                      : customer.notes,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _CustomerInfoLine(
                            label: context.tr('姓名'),
                            value: customer.name,
                            onTap: () => copyTextWithNotice(
                              context,
                              customer.name,
                              label: '客户姓名',
                            ),
                          ),
                          _CustomerInfoLine(
                            label: context.tr('电话'),
                            value: customer.phone,
                            icon: Icons.phone_outlined,
                            onTap: () => dialPhoneWithNotice(
                              context,
                              customer.phone,
                            ),
                          ),
                          _CustomerInfoLine(
                            label: context.tr('微信'),
                            value: customer.wechat,
                            onTap: () => copyTextWithNotice(
                              context,
                              customer.wechat,
                              label: '微信号',
                            ),
                          ),
                          _CustomerInfoLine(
                            label: context.tr('地址'),
                            value: customer.address,
                            onTap: () => copyTextWithNotice(
                              context,
                              customer.address,
                              label: '服务地址',
                            ),
                          ),
                          _CustomerInfoLine(
                            label: context.tr('备注'),
                            value: customer.notes,
                            onTap: () => copyTextWithNotice(
                              context,
                              customer.notes,
                              label: '客户备注',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => copyTextWithNotice(
                                context,
                                customer.clipboardTextFor(context.tr),
                                label: '客户全部信息',
                              ),
                              icon:
                                  const Icon(Icons.copy_all_outlined, size: 16),
                              label: Text(context.tr('复制全部信息')),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoPill(
                                  label: context.tr('微信'),
                                  value: customer.wechat.isEmpty
                                      ? context.tr('未填写')
                                      : customer.wechat),
                              _InfoPill(
                                  label: context.tr('历史工单'),
                                  value: '${orders.length} ${context.tr('张')}'),
                              _InfoPill(
                                  label: context.tr('未结清'),
                                  value: _dialogMoney(outstanding)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DialogSectionLabel(
                      title: context.tr('历史工单'),
                      trailing: '${orders.length} ${context.tr('张')}'),
                  const SizedBox(height: 8),
                  if (orders.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(context.tr('还没有关联工单。')),
                      ),
                    )
                  else
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: orders
                            .map(
                              (order) => ListTile(
                                dense: true,
                                title: Text(order.number),
                                subtitle: Text(
                                    '${_dialogDeviceLocalized(context, order)} · '
                                    '${_dialogDateLocalized(context, order.createdAt)}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _DialogStatusChip(order.status),
                                    const SizedBox(height: 3),
                                    Text(
                                      _dialogMoney(order.total),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final deleteButton = TextButton.icon(
                    onPressed: () => _delete(context),
                    icon: const Icon(Icons.delete_outline, size: 17),
                    label: Text(context.tr('删除客户')),
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error),
                  );
                  final editButton = OutlinedButton(
                    onPressed: onEdit,
                    child: Text(context.tr('编辑资料')),
                  );
                  final createButton = FilledButton.icon(
                    onPressed: onCreateOrder,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(context.tr('新建工单')),
                  );
                  if (constraints.maxWidth < 480) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            deleteButton,
                            const Spacer(),
                            editButton,
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, child: createButton),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      deleteButton,
                      const Spacer(),
                      editButton,
                      const SizedBox(width: 8),
                      createButton,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('删除客户？')),
            content: Text(context.tr('只有没有关联工单的客户才可以删除。')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.tr('取消'))),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.tr('确认删除'))),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final ok = await controller.deleteCustomer(customerId);
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      showTopNotice(
        context,
        context.tr('该客户仍有关联工单，暂时不能删除。'),
        error: true,
      );
    }
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.trf('{label}：{value}', {'label': label, 'value': value}),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class _CustomerInfoLine extends StatelessWidget {
  const _CustomerInfoLine({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon = Icons.copy_outlined,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final enabled = value.trim().isNotEmpty;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                label,
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                enabled ? value : context.tr('未填写'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: enabled ? null : muted,
                  fontSize: 14,
                ),
              ),
            ),
            if (enabled) Icon(icon, size: 14, color: muted),
          ],
        ),
      ),
    );
  }
}
