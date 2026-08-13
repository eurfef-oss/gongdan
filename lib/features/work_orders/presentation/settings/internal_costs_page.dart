part of '../work_order_page.dart';

class _InternalCostsContent extends StatelessWidget {
  const _InternalCostsContent({
    required this.controller,
    required this.onOpenCostTypes,
  });

  final WorkOrderController controller;
  final VoidCallback onOpenCostTypes;

  @override
  Widget build(BuildContext context) {
    final orders = [...controller.visibleOrders]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                '成本只供店内经营分析使用，不会出现在报价单、维修凭证或客户展示内容中。',
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onOpenCostTypes,
              icon: const Icon(Icons.tune_outlined, size: 17),
              label: const Text('成本类型设置'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          const _Empty(
            title: '还没有工单',
            description: '创建工单后，可以在这里补录内部成本。',
          )
        else
          ...orders.map(
            (order) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => _InternalCostEditorDialog(
                    controller: controller,
                    orderId: order.id,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .1),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.receipt_long_outlined, size: 19),
                ),
                title: Text(
                  '${order.number} · ${deviceText(order)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '应收 ${moneyText(order.total)}  ·  ${order.internalCosts.length} 条成本记录',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      moneyText(order.internalCostTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '成本',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InternalCostEditorDialog extends StatefulWidget {
  const _InternalCostEditorDialog({
    required this.controller,
    required this.orderId,
  });

  final WorkOrderController controller;
  final String orderId;

  @override
  State<_InternalCostEditorDialog> createState() =>
      _InternalCostEditorDialogState();
}

class _InternalCostEditorDialogState extends State<_InternalCostEditorDialog> {
  late List<_CostDraft> _drafts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final order = widget.controller.orderById(widget.orderId);
    _drafts = order?.internalCosts.map(_CostDraft.fromCost).toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.controller.orderById(widget.orderId);
    if (order == null) return const SizedBox.shrink();
    final types = widget.controller.enabledCostTypes;
    final maxHeight =
        (MediaQuery.sizeOf(context).height - 40).clamp(320.0, 720.0).toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 620, maxHeight: maxHeight),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'INTERNAL / COST',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '工单内部成本',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text('${order.number} · ${deviceText(order)}'),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '仅用于店内成本和毛利统计，客户不可见。',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_drafts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Text('还没有成本记录，点击下方添加。'),
                      )
                    else
                      ..._drafts.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CostDraftRow(
                                key: ObjectKey(entry.value),
                                draft: entry.value,
                                types: types,
                                onChanged: () => setState(() {}),
                                onRemove: () => setState(
                                  () => _drafts.removeAt(entry.key),
                                ),
                              ),
                            ),
                          ),
                    OutlinedButton.icon(
                      onPressed: _addDraft,
                      icon: const Icon(Icons.add, size: 17),
                      label: const Text('添加成本记录'),
                    ),
                    const SizedBox(height: 12),
                    _SettingLine(
                      label: '工单总成本',
                      value: moneyText(
                        _drafts.fold<double>(
                          0,
                          (sum, item) => sum + item.amount,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('保存成本'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDraft() {
    final type = widget.controller.enabledCostTypes.isNotEmpty
        ? widget.controller.enabledCostTypes.first
        : const CostType(id: 'other', name: '其他', enabled: true);
    setState(
      () => _drafts.add(
        _CostDraft(
          id: idFor('cost'),
          typeId: type.id,
          typeName: type.name,
          amount: 0,
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.controller.saveInternalCosts(
      widget.orderId,
      _drafts.map((item) => item.toCost()).toList(),
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      showTopNotice(context, '成本保存失败，请重试。', error: true);
      return;
    }
    Navigator.pop(context);
  }
}

class _CostDraftRow extends StatefulWidget {
  const _CostDraftRow({
    required this.draft,
    required this.types,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final _CostDraft draft;
  final List<CostType> types;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_CostDraftRow> createState() => _CostDraftRowState();
}

class _CostDraftRowState extends State<_CostDraftRow> {
  late final TextEditingController _amount;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.draft.amount == 0
          ? ''
          : widget.draft.amount.toStringAsFixed(2),
    );
    _note = TextEditingController(text: widget.draft.note);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      ...widget.types,
      if (!widget.types.any((item) => item.id == widget.draft.typeId))
        CostType(
          id: widget.draft.typeId,
          name: widget.draft.typeName,
          enabled: false,
        ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: options.any(
                    (item) => item.id == widget.draft.typeId,
                  )
                      ? widget.draft.typeId
                      : null,
                  decoration: const InputDecoration(labelText: '成本类型'),
                  items: options
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    final type = options.firstWhere(
                      (item) => item.id == value,
                      orElse: () => options.first,
                    );
                    widget.draft
                      ..typeId = type.id
                      ..typeName = type.name;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amount,
                  onChanged: (value) {
                    widget.draft.amount = double.tryParse(value) ?? 0;
                    widget.onChanged();
                  },
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '金额',
                    prefixText: '¥ ',
                  ),
                ),
              ),
              IconButton(
                tooltip: '删除成本',
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            onChanged: (value) {
              widget.draft.note = value;
              widget.onChanged();
            },
            decoration: const InputDecoration(labelText: '备注（可选）'),
          ),
        ],
      ),
    );
  }
}

class _CostDraft {
  _CostDraft({
    required this.id,
    required this.typeId,
    required this.typeName,
    required this.amount,
    this.note = '',
  });

  factory _CostDraft.fromCost(WorkOrderCost cost) => _CostDraft(
        id: cost.id,
        typeId: cost.typeId,
        typeName: cost.typeName,
        amount: cost.amount,
        note: cost.note,
      );

  final String id;
  String typeId;
  String typeName;
  double amount;
  String note;

  WorkOrderCost toCost() => WorkOrderCost(
        id: id,
        typeId: typeId,
        typeName: typeName,
        amount: amount,
        note: note,
      );
}

class _CostTypesContent extends StatefulWidget {
  const _CostTypesContent({required this.controller});

  final WorkOrderController controller;

  @override
  State<_CostTypesContent> createState() => _CostTypesContentState();
}

class _CostTypesContentState extends State<_CostTypesContent> {
  late final TextEditingController _newType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _newType = TextEditingController();
  }

  @override
  void dispose() {
    _newType.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types = widget.controller.costTypes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('停用后不会出现在新成本记录中，已保存的历史成本不受影响。'),
        const SizedBox(height: 16),
        ...types.map(
          (type) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.sell_outlined, size: 19),
              title: Text(type.name),
              subtitle: Text(type.enabled ? '启用中' : '已停用'),
              trailing: Wrap(
                spacing: 0,
                children: [
                  Switch.adaptive(
                    value: type.enabled,
                    onChanged:
                        _saving ? null : (value) => _setEnabled(type, value),
                  ),
                  IconButton(
                    tooltip: '重命名',
                    onPressed: _saving ? null : () => _rename(type),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: '删除',
                    onPressed: _saving ? null : () => _delete(type),
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newType,
                enabled: !_saving,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: '新增成本类型',
                  counterText: '',
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _saving ? null : _add,
              child: const Text('新增'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _add() async {
    final value = _newType.text.trim();
    if (value.isEmpty) return;
    final ok = await _run(() => widget.controller.addCostType(value));
    if (mounted && ok) _newType.clear();
  }

  Future<void> _setEnabled(CostType type, bool enabled) async {
    await _run(() => widget.controller.setCostTypeEnabled(type.id, enabled));
  }

  Future<void> _rename(CostType type) async {
    final text = TextEditingController(text: type.name);
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('重命名成本类型'),
        content: TextField(controller: text, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    text.dispose();
    if (value == null || value.isEmpty || !mounted) return;
    await _run(() => widget.controller.renameCostType(type.id, value));
  }

  Future<void> _delete(CostType type) async {
    final ok = await widget.controller.deleteCostType(type.id);
    if (!mounted) return;
    if (ok) {
      setState(() {});
      return;
    }
    showTopNotice(context, '该类型已被工单使用，不能删除；可以先停用。', error: true);
  }

  Future<bool> _run(Future<bool> Function() action) async {
    setState(() => _saving = true);
    final ok = await action();
    if (!mounted) return false;
    setState(() => _saving = false);
    if (!ok) showTopNotice(context, '保存失败或名称已存在。', error: true);
    return ok;
  }
}
