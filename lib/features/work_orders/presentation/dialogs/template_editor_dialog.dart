part of '../work_order_dialogs.dart';

class TemplateEditorDialog extends StatefulWidget {
  const TemplateEditorDialog(
      {required this.controller, this.initial, super.key});

  final WorkOrderController controller;
  final ServiceItem? initial;

  @override
  State<TemplateEditorDialog> createState() => _TemplateEditorDialogState();
}

class ServiceItemTypeManagerDialog extends StatefulWidget {
  const ServiceItemTypeManagerDialog({required this.controller, super.key});

  final WorkOrderController controller;

  @override
  State<ServiceItemTypeManagerDialog> createState() =>
      _ServiceItemTypeManagerDialogState();
}

class _ServiceItemTypeManagerDialogState
    extends State<ServiceItemTypeManagerDialog> {
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
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight =
        (MediaQuery.sizeOf(context).height - viewInsets.bottom - 22)
            .clamp(240.0, 680.0)
            .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(11),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final options = widget.controller.serviceItemTypeOptions;
            final builtIns = options.where((option) => option.isBuiltIn);
            final custom = options.where((option) => !option.isBuiltIn);
            return Column(
              children: [
                _DialogHeader(
                  kicker: 'CATALOG / TYPES',
                  title: context.tr('类型维护'),
                  subtitle: context.tr(
                    '内置类型和自定义类型都可以删除，使用中的类型需先移除引用。',
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(11, 0, 11, 12),
                    children: [
                      _DialogSectionLabel(title: context.tr('内置类型')),
                      const SizedBox(height: 6),
                      ...builtIns.map(
                        (option) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading:
                              const Icon(Icons.category_outlined, size: 18),
                          title: Text(context.tr(option.label)),
                          subtitle: Text(context.tr('系统内置')),
                          trailing: IconButton(
                            tooltip: context.tr('删除'),
                            onPressed: () => _delete(option),
                            icon: const Icon(Icons.delete_outline, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DialogSectionLabel(
                        title: context.tr('自定义类型'),
                        trailing:
                            context.trf('{count} 个', {'count': custom.length}),
                      ),
                      const SizedBox(height: 6),
                      if (custom.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(context.tr('还没有自定义类型。')),
                        )
                      else
                        ...custom.map(
                          (option) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.sell_outlined, size: 18),
                            title: Text(context.tr(option.label)),
                            trailing: Wrap(
                              spacing: 2,
                              children: [
                                IconButton(
                                  tooltip: context.tr('重命名'),
                                  onPressed: () => _rename(option),
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 18),
                                ),
                                IconButton(
                                  tooltip: context.tr('删除'),
                                  onPressed: () => _delete(option),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newType,
                          enabled: !_saving,
                          maxLength: 30,
                          decoration: InputDecoration(
                            labelText: context.tr('新增自定义类型'),
                            hintText: context.tr('例如：高空作业费'),
                            counterText: '',
                          ),
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _saving ? null : _add,
                        child: Text(context.tr('新增')),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _add() async {
    final name = _newType.text.trim();
    if (name.isEmpty) {
      showTopNotice(context, context.tr('请填写类型名称。'), error: true);
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.controller.addServiceItemType(name);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _newType.clear();
    } else {
      showTopNotice(
        context,
        context.tr('类型名称重复、无效或保存失败。'),
        error: true,
      );
    }
  }

  Future<void> _rename(ServiceTypeOption option) async {
    final text = TextEditingController(text: option.label);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('重命名类型')),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(labelText: context.tr('类型名称')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.text.trim()),
            child: Text(context.tr('保存')),
          ),
        ],
      ),
    );
    text.dispose();
    if (value == null || value.isEmpty || !mounted) return;
    final ok = await widget.controller.renameServiceItemType(
      option.label,
      value,
    );
    if (!mounted || ok) return;
    showTopNotice(
      context,
      context.tr('新名称重复、无效或保存失败。'),
      error: true,
    );
  }

  Future<void> _delete(ServiceTypeOption option) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              context.tr(option.isBuiltIn ? '删除内置类型？' : '删除自定义类型？'),
            ),
            content: Text(
              context.trf(
                '“{name}”如果正在被项目模板或工单使用，将无法删除。',
                {'name': context.tr(option.label)},
              ),
            ),
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
    if (!confirmed || !mounted) return;
    final ok = await widget.controller.deleteServiceItemType(option.label);
    if (!mounted || ok) return;
    showTopNotice(context, context.tr('该类型正在使用，不能删除。'), error: true);
  }
}

class _TemplateEditorDialogState extends State<TemplateEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _price;
  late final TextEditingController _warranty;
  late String _typeKey;
  late bool _enabled;
  bool _nameLocalized = false;
  bool _unitLocalized = false;
  bool _unitDefaulted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _name = TextEditingController(text: item?.name ?? '');
    _unit = TextEditingController(text: item?.unit ?? '');
    _price = TextEditingController(
        text: item == null ? '' : item.defaultPrice.toStringAsFixed(2));
    _warranty =
        TextEditingController(text: item == null ? '' : '${item.warrantyDays}');
    _typeKey = ServiceTypeOption.keyFor(
      item?.type ?? ServiceItemType.labor,
      item?.customType,
    );
    _enabled = item?.enabled ?? true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nameLocalized) {
      final item = widget.initial;
      if (item != null) {
        _name.text = localizedServiceItemName(context, item);
      }
      _nameLocalized = true;
    }
    if (!_unitLocalized) {
      final item = widget.initial;
      if (item != null) {
        _unit.text = localizedServiceItemUnit(context, item);
      }
      _unitLocalized = true;
    }
    if (!_unitDefaulted && _unit.text.trim().isEmpty) {
      _unit.text = context.tr('次');
      _unitDefaulted = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _price.dispose();
    _warranty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeOptions = widget.controller.serviceItemTypeOptions;
    final typeKey = typeOptions.any((option) => option.key == _typeKey)
        ? _typeKey
        : typeOptions.isEmpty
            ? null
            : typeOptions.first.key;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight =
        (MediaQuery.sizeOf(context).height - viewInsets.bottom - 22)
            .clamp(240.0, 700.0)
            .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(11),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              kicker: widget.initial == null
                  ? 'NEW / SERVICE ITEM'
                  : 'EDIT / SERVICE ITEM',
              title: context.tr(
                widget.initial == null ? '新增项目模板' : '编辑项目模板',
              ),
              subtitle: context.tr('模板会出现在新建工单的快捷报价项目中。'),
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(11, 0, 11, 18),
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: context.tr('项目名称 *'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TwoFields(
                      first: DropdownButtonFormField<String>(
                        initialValue: typeKey,
                        decoration:
                            InputDecoration(labelText: context.tr('类型')),
                        items: typeOptions
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option.key,
                                child: Text(context.tr(option.label)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _typeKey = value);
                        },
                      ),
                      second: TextField(
                        controller: _unit,
                        decoration:
                            InputDecoration(labelText: context.tr('单位')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TwoFields(
                      first: TextField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: context.tr('默认单价'),
                          prefixText:
                              '${widget.controller.data.settings.currencySymbol} ',
                        ),
                      ),
                      second: TextField(
                        controller: _warranty,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: context.tr('保修天数')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.tr('启用此项目'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: _enabled,
                      onChanged: (value) => setState(() => _enabled = value),
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
                      child: Text(context.tr('保存项目'))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final enteredName = _name.text.trim();
    final initial = widget.initial;
    final name = initial != null &&
            isDefaultServiceItem(initial) &&
            enteredName == localizedServiceItemName(context, initial)
        ? initial.name
        : enteredName;
    if (name.isEmpty) {
      showTopNotice(context, context.tr('请填写项目名称。'), error: true);
      return;
    }
    setState(() => _saving = true);
    final type = _selectedTypeOption();
    final enteredUnit = _unit.text.trim();
    final initialUnit = initial != null &&
            isDefaultServiceItem(initial) &&
            enteredUnit == localizedServiceItemUnit(context, initial)
        ? initial.unit
        : enteredUnit;
    final unit = initialUnit.isEmpty ? context.tr('次') : initialUnit;
    final item = widget.initial?.copyWith(
          name: name,
          type: type.type,
          customType: type.customType,
          unit: unit,
          defaultPrice: money(double.tryParse(_price.text) ?? 0),
          warrantyDays: int.tryParse(_warranty.text) ?? 0,
          enabled: _enabled,
        ) ??
        ServiceItem(
          id: idFor('svc'),
          name: name,
          type: type.type,
          customType: type.customType,
          unit: unit,
          defaultPrice: money(double.tryParse(_price.text) ?? 0),
          warrantyDays: int.tryParse(_warranty.text) ?? 0,
          enabled: _enabled,
        );
    await widget.controller.saveServiceItem(item);
    if (mounted) Navigator.pop(context);
  }

  ServiceTypeOption _selectedTypeOption() {
    final options = widget.controller.serviceItemTypeOptions;
    for (final option in options) {
      if (option.key == _typeKey) return option;
    }
    return options.isEmpty
        ? ServiceTypeOption.builtIn(ServiceItemType.labor)
        : options.first;
  }
}
