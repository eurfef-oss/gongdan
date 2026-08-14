part of '../work_order_dialogs.dart';

class OrderEditorDialog extends StatefulWidget {
  const OrderEditorDialog(
      {required this.controller,
      required this.initial,
      this.asPage = false,
      this.canCreateCustomer,
      this.onPremiumRequired,
      super.key});

  final WorkOrderController controller;
  final WorkOrder initial;
  final bool asPage;
  final bool Function()? canCreateCustomer;
  final Future<void> Function()? onPremiumRequired;

  @override
  State<OrderEditorDialog> createState() => _OrderEditorDialogState();
}

class _OrderEditorDialogState extends State<OrderEditorDialog> {
  late final TextEditingController _address;
  late final TextEditingController _deviceType;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _serialNumber;
  late final TextEditingController _fault;
  late final TextEditingController _request;
  late final TextEditingController _result;
  late final TextEditingController _discount;
  late final TextEditingController _warrantyDays;
  late final TextEditingController _warrantyScope;
  late final TextEditingController _warrantyExclusions;
  late final TextEditingController _internalNote;
  late String _customerId;
  late WorkOrderStatus _status;
  late DateTime? _appointmentAt;
  late DateTime? _warrantyStart;
  late List<_ItemDraft> _items;
  bool _saving = false;

  bool get isEditing => widget.controller.orderById(widget.initial.id) != null;

  @override
  void initState() {
    super.initState();
    final order = widget.initial;
    _address = TextEditingController(text: order.serviceAddress);
    _deviceType = TextEditingController(text: order.deviceType);
    _brand = TextEditingController(text: order.brand);
    _model = TextEditingController(text: order.model);
    _serialNumber = TextEditingController(text: order.serialNumber);
    _fault = TextEditingController(text: order.faultDescription);
    _request = TextEditingController(text: _workOrderNote(order));
    _result = TextEditingController(text: order.result);
    _discount = TextEditingController(
      text: order.discount == 0 ? '' : order.discount.toStringAsFixed(2),
    );
    _warrantyDays = TextEditingController(
      text: order.warrantyDays == 0 ? '' : '${order.warrantyDays}',
    );
    _warrantyScope = TextEditingController(text: order.warrantyScope);
    _warrantyExclusions = TextEditingController(text: order.warrantyExclusions);
    _internalNote = TextEditingController(text: order.internalNote);
    _customerId = order.customerId;
    _status = order.status;
    _appointmentAt = order.appointmentAt;
    _warrantyStart = order.warrantyStart;
    _items = order.items.map(_ItemDraft.fromItem).toList();
  }

  @override
  void dispose() {
    for (final controller in [
      _address,
      _deviceType,
      _brand,
      _model,
      _serialNumber,
      _fault,
      _request,
      _result,
      _discount,
      _warrantyDays,
      _warrantyScope,
      _warrantyExclusions,
      _internalNote,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.controller.data.customers;
    final editor = Column(
      children: [
        if (!widget.asPage)
          _DialogHeader(
            kicker: isEditing ? 'EDIT / WORK ORDER' : 'NEW / WORK ORDER',
            title: context.tr(isEditing ? '编辑工单' : '新建工单'),
            subtitle: context.trf(
              '{number} · 先记客户和故障，项目与金额可以现场再补。',
              {'number': widget.initial.number},
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(11, 4, 11, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildFormFields(context, customers),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
          child: Row(
            children: [
              Text(
                context.tr('保存后仍可继续编辑'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
                    : Text(context.tr(isEditing ? '保存修改' : '保存工单')),
              ),
            ],
          ),
        ),
      ],
    );
    if (widget.asPage) {
      return Scaffold(
        appBar: AppBackBar(
          title: context.tr(isEditing ? '编辑工单' : '新建工单'),
          onBack: () => Navigator.of(context).pop(),
        ),
        body: SafeArea(
          child: SizedBox(width: double.infinity, child: editor),
        ),
      );
    }
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight =
        (MediaQuery.sizeOf(context).height - viewInsets.bottom - 22)
            .clamp(240.0, 850.0)
            .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(11),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1040, maxHeight: maxHeight),
        child: editor,
      ),
    );
  }

  List<Widget> _buildFormFields(
    BuildContext context,
    List<Customer> customers,
  ) {
    final hidden = widget.controller.workOrderHiddenFields;
    final fields = widget.controller.workOrderFieldOrder
        .where((id) => !hidden.contains(id))
        .toList();
    final children = <Widget>[];
    String? previousGroup;
    for (final id in fields) {
      final group = _workOrderFieldGroup(id);
      if (group != previousGroup) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 8));
        children.add(_DialogSectionLabel(title: context.tr(group)));
        children.add(const SizedBox(height: 12));
        previousGroup = group;
      }
      children.add(_buildWorkOrderField(context, id, customers));
      children.add(const SizedBox(height: 12));
    }
    if (fields.contains('serviceItems') || fields.contains('discount')) {
      children.add(const SizedBox(height: 4));
      children
          .add(_DialogTotals(items: _items, discount: _parseMoney(_discount)));
    }
    return children;
  }

  String _workOrderFieldGroup(String id) {
    const basic = {
      'customer',
      'serviceAddress',
      'deviceType',
      'brand',
      'model',
      'serialNumber',
      'faultDescription',
      'customerRequest',
    };
    if (basic.contains(id)) return '基本信息';
    if (id == 'serviceItems' ||
        id == 'discount' ||
        id == 'warrantyDays' ||
        id == 'warrantyScope' ||
        id == 'warrantyExclusions') {
      return '报价与保修';
    }
    return '服务记录';
  }

  Widget _buildWorkOrderField(
    BuildContext context,
    String id,
    List<Customer> customers,
  ) {
    switch (id) {
      case 'customer':
        if (customers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(
                      '还没有客户档案，可以先新建客户，也可以保存未关联客户的草稿。',
                    ),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _createCustomer,
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: Text(context.tr('新建客户')),
                ),
              ],
            ),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: customers.any((customer) => customer.id == _customerId)
              ? _customerId
              : null,
          decoration: InputDecoration(
            labelText: context.tr('客户'),
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: [
            ...customers.map(
              (customer) => DropdownMenuItem(
                value: customer.id,
                child: Text(
                  '${customer.name} · ${customer.phone.isEmpty ? context.tr('无手机号') : customer.phone}',
                ),
              ),
            ),
            DropdownMenuItem<String>(
              value: _newCustomerValue,
              child: Row(
                children: [
                  Icon(Icons.person_add_alt_1, size: 18),
                  SizedBox(width: 8),
                  Text(context.tr('新建客户')),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value == _newCustomerValue) {
              _createCustomer();
              return;
            }
            setState(() {
              _customerId = value ?? '';
              if (_address.text.isEmpty) {
                _address.text =
                    widget.controller.customerById(_customerId)?.address ?? '';
              }
            });
          },
        );
      case 'serviceAddress':
        return TextField(
          controller: _address,
          decoration: InputDecoration(
            labelText: context.tr('服务地址'),
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        );
      case 'deviceType':
        return TextField(
          controller: _deviceType,
          decoration: InputDecoration(labelText: context.tr('设备类型')),
        );
      case 'brand':
        return TextField(
          controller: _brand,
          decoration: InputDecoration(labelText: context.tr('品牌')),
        );
      case 'model':
        return TextField(
          controller: _model,
          decoration: InputDecoration(labelText: context.tr('型号')),
        );
      case 'serialNumber':
        return TextField(
          controller: _serialNumber,
          decoration: InputDecoration(labelText: context.tr('序列号（可选）')),
        );
      case 'faultDescription':
        return TextField(
          controller: _fault,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.tr('故障描述'),
            hintText: context.tr('客户说了什么、现场看到什么'),
          ),
        );
      case 'customerRequest':
        return TextField(
          controller: _request,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.tr('备注'),
            hintText: context.tr('记录客户需求、说明或其他备注'),
          ),
        );
      case 'serviceItems':
        return _buildServiceItemsField(context);
      case 'discount':
        return TextField(
          controller: _discount,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: context.tr('优惠金额')),
        );
      case 'warrantyDays':
        return TextField(
          controller: _warrantyDays,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: context.tr('保修天数')),
        );
      case 'warrantyScope':
        return TextField(
          controller: _warrantyScope,
          decoration: InputDecoration(labelText: context.tr('保修范围')),
        );
      case 'warrantyExclusions':
        return TextField(
          controller: _warrantyExclusions,
          maxLines: 2,
          decoration: InputDecoration(labelText: context.tr('不保修说明')),
        );
      case 'status':
        return InputDecorator(
          decoration: InputDecoration(labelText: context.tr('工单状态')),
          child: Text(
            context.trf(
              '{status} · 状态由工单流程自动推进',
              {'status': workOrderStatusText(context, _status)},
            ),
            style: const TextStyle(fontSize: 14),
          ),
        );
      case 'appointmentAt':
        return _DateActionField(
          label: context.tr('预约时间'),
          value: _dialogDateTimeLocalized(context, _appointmentAt),
          onTap: _pickAppointment,
          onClear: _appointmentAt == null
              ? null
              : () => setState(() => _appointmentAt = null),
        );
      case 'warrantyStart':
        return _DateActionField(
          label: context.tr('保修开始日期'),
          value: _dialogDateLocalized(context, _warrantyStart),
          onTap: _pickWarrantyStart,
          onClear: _warrantyStart == null
              ? null
              : () => setState(() => _warrantyStart = null),
        );
      case 'result':
        return TextField(
          controller: _result,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.tr('维修结果'),
            hintText: context.tr('完成服务后补充处理结果'),
          ),
        );
      case 'internalNote':
        return TextField(
          controller: _internalNote,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.tr('内部备注'),
            hintText: context.tr('仅自己查看的记录'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildServiceItemsField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DialogSectionLabel(
          title: context.tr('报价项目'),
          trailing: context.trf(
            '{count} 项 · 数量 × 单价 = 小计',
            {'count': _items.length},
          ),
        ),
        const SizedBox(height: 10),
        if (_items.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: .45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              context.tr('还没有报价项目，请在下方添加。'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ..._items.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _ItemDraftEditor(
                  key: ObjectKey(entry.value),
                  item: entry.value,
                  templates: widget.controller.data.serviceItems,
                  typeOptions: widget.controller.serviceItemTypeOptions,
                  onChanged: () => setState(() {}),
                  onRemove: () => setState(() => _items.removeAt(entry.key)),
                ),
              ),
            ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(
                () => _items.add(
                  _ItemDraft(
                    name: '',
                    type: ServiceItemType.labor,
                    quantity: 1,
                    unit: context.tr('次'),
                    unitPrice: 0,
                  ),
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.tr('添加空白项目')),
            ),
            ...widget.controller.data.serviceItems
                .where((item) => item.enabled)
                .take(3)
                .map(
                  (item) => TextButton(
                    onPressed: () => setState(
                      () => _items.add(
                        _ItemDraft(
                          name: item.name,
                          type: item.type,
                          customType: item.customType,
                          quantity: 1,
                          unit: item.unit,
                          unitPrice: item.defaultPrice,
                        ),
                      ),
                    ),
                    child: Text(
                      '+ ${localizedServiceItemName(context, item)}',
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }

  double _parseMoney(TextEditingController controller) =>
      money(double.tryParse(controller.text.trim()) ?? 0);

  Future<void> _createCustomer() async {
    final canCreate = widget.canCreateCustomer;
    if (canCreate != null && !canCreate()) {
      await widget.onPremiumRequired?.call();
      return;
    }
    final customer = await showDialog<Customer>(
      context: context,
      builder: (context) => CustomerEditorDialog(
        controller: widget.controller,
      ),
    );
    if (!mounted || customer == null) return;
    setState(() {
      _customerId = customer.id;
      if (_address.text.isEmpty) _address.text = customer.address;
    });
  }

  Future<void> _pickAppointment() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5),
      initialDate: _appointmentAt ?? today,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _appointmentAt == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(_appointmentAt!),
    );
    if (time == null || !mounted) return;
    setState(
      () => _appointmentAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _pickWarrantyStart() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
      initialDate: _warrantyStart ?? today,
    );
    if (date != null && mounted) setState(() => _warrantyStart = date);
  }

  Future<void> _save() async {
    final current = widget.controller.orderById(widget.initial.id);
    if (current?.status.isTerminal == true || current?.isTrashed == true) {
      showTopNotice(
        context,
        context.tr('已完成、已取消或已移入回收站的工单不能编辑。'),
        error: true,
      );
      return;
    }
    final items = _items
        .where((item) => item.name.trim().isNotEmpty)
        .map((item) => item.toItem(defaultUnit: context.tr('次')))
        .toList();
    final subtotal =
        money(items.fold<double>(0, (sum, item) => sum + item.amount));
    final discount = _parseMoney(_discount);
    final total = money((subtotal - discount).clamp(0, double.infinity));
    if (_status == WorkOrderStatus.completed &&
        widget.initial.normalizedPaid < total) {
      showTopNotice(
        context,
        context.tr('还有未收款金额，不能直接关闭工单。'),
        error: true,
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final warrantyDays = int.tryParse(_warrantyDays.text.trim()) ?? 0;
    final warrantyStart = warrantyDays > 0 ? (_warrantyStart ?? now) : null;
    final warrantyEnd = warrantyStart?.add(Duration(days: warrantyDays));
    final note = _request.text.trim();
    final order = widget.initial.copyWith(
      customerId: _customerId,
      serviceAddress: _address.text.trim(),
      deviceType: _deviceType.text.trim(),
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      serialNumber: _serialNumber.text.trim(),
      faultDescription: _fault.text.trim(),
      customerRequest: note,
      // Keep the legacy field in sync so old exports and receipt rendering
      // continue to expose the single note without duplicating it visually.
      customerNote: note,
      result: _result.text.trim(),
      internalNote: _internalNote.text.trim(),
      status: _status,
      items: items,
      discount: discount,
      appointmentAt: _appointmentAt,
      warrantyDays: warrantyDays < 0 ? 0 : warrantyDays,
      warrantyStart: warrantyStart,
      warrantyEnd: warrantyEnd,
      warrantyScope: _warrantyScope.text.trim(),
      warrantyExclusions: _warrantyExclusions.text.trim(),
      updatedAt: now,
    );
    final saved = await widget.controller.saveOrder(order);
    if (!mounted) return;
    if (!saved) {
      setState(() => _saving = false);
      showTopNotice(
        context,
        context.tr('工单保存失败，请重试。'),
        error: true,
      );
      return;
    }
    Navigator.of(context).pop();
  }
}

class _DateActionField extends StatelessWidget {
  const _DateActionField(
      {required this.label,
      required this.value,
      required this.onTap,
      this.onClear});

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(child: Text(value)),
          if (onClear != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 17),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onTap,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ItemDraftEditor extends StatefulWidget {
  const _ItemDraftEditor(
      {required this.item,
      required this.templates,
      required this.typeOptions,
      required this.onChanged,
      required this.onRemove,
      super.key});

  final _ItemDraft item;
  final List<ServiceItem> templates;
  final List<ServiceTypeOption> typeOptions;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_ItemDraftEditor> createState() => _ItemDraftEditorState();
}

class _ItemDraftEditorState extends State<_ItemDraftEditor> {
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late final TextEditingController _price;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _quantity = TextEditingController(text: _numberText(widget.item.quantity));
    _unit = TextEditingController(text: widget.item.unit);
    _price = TextEditingController(text: _numberText(widget.item.unitPrice));
    _note = TextEditingController(text: widget.item.note);
    if (widget.typeOptions.isNotEmpty &&
        !widget.typeOptions.any((option) =>
            option.key ==
            ServiceTypeOption.keyFor(
                widget.item.type, widget.item.customType))) {
      final option = widget.typeOptions.first;
      widget.item
        ..type = option.type
        ..customType = option.customType;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  String _numberText(double value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(2);

  void _sync() {
    widget.item
      ..name = _name.text
      ..quantity = double.tryParse(_quantity.text) ?? 0
      ..unit = _unit.text
      ..unitPrice = double.tryParse(_price.text) ?? 0
      ..note = _note.text;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .45),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _name,
                  onChanged: (_) => _sync(),
                  decoration: InputDecoration(labelText: context.tr('项目名称')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _quantity,
                  onChanged: (_) => _sync(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: context.tr('数量')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _unit,
                  onChanged: (_) => _sync(),
                  decoration: InputDecoration(labelText: context.tr('单位')),
                ),
              ),
              IconButton(
                tooltip: context.tr('移除项目'),
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedTypeKey(),
                  decoration: InputDecoration(labelText: context.tr('类型')),
                  items: widget.typeOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.key,
                          child: Text(context.tr(option.label)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    ServiceTypeOption? option;
                    for (final item in widget.typeOptions) {
                      if (item.key == value) {
                        option = item;
                        break;
                      }
                    }
                    if (option != null) {
                      widget.item
                        ..type = option.type
                        ..customType = option.customType;
                      setState(() {});
                      widget.onChanged();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _price,
                  onChanged: (_) => _sync(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: context.tr('单价')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            onChanged: (_) => _sync(),
            decoration: InputDecoration(labelText: context.tr('项目备注（可选）')),
          ),
          if (widget.templates.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<ServiceItem>(
                tooltip: context.tr('从模板替换'),
                onSelected: (template) {
                  _name.text = template.name;
                  _unit.text = template.unit;
                  _price.text = _numberText(template.defaultPrice);
                  widget.item
                    ..name = template.name
                    ..type = template.type
                    ..customType = template.customType
                    ..unit = template.unit
                    ..unitPrice = template.defaultPrice;
                  setState(() {});
                  widget.onChanged();
                },
                itemBuilder: (context) => widget.templates
                    .where((item) => item.enabled)
                    .map(
                      (item) => PopupMenuItem(
                        value: item,
                        child: Text(localizedServiceItemName(context, item)),
                      ),
                    )
                    .toList(),
                child: Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    context.tr('从项目模板替换'),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _selectedTypeKey() {
    final key = ServiceTypeOption.keyFor(
      widget.item.type,
      widget.item.customType,
    );
    if (widget.typeOptions.any((option) => option.key == key)) return key;
    return widget.typeOptions.isEmpty ? null : widget.typeOptions.first.key;
  }
}

class _DialogTotals extends StatelessWidget {
  const _DialogTotals({required this.items, required this.discount});

  final List<_ItemDraft> items;
  final double discount;

  @override
  Widget build(BuildContext context) {
    final subtotal =
        money(items.fold<double>(0, (sum, item) => sum + item.amount));
    final total = money((subtotal - discount).clamp(0, double.infinity));
    return Card(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .06),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            _DialogAmountLine(label: context.tr('项目小计'), value: subtotal),
            _DialogAmountLine(label: context.tr('优惠金额'), value: -discount),
            _DialogAmountLine(
              label: context.tr('应收合计'),
              value: total,
              strong: true,
            ),
          ],
        ),
      ),
    );
  }
}
