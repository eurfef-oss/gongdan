part of '../work_order_page.dart';

enum _SettingsSection {
  shop,
  appearance,
  dashboard,
  workOrder,
  pro,
  data,
  internalCosts,
  costTypes,
  demo,
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage({
    required this.controller,
    required this.entitlementController,
    required this.onExport,
    required this.onImport,
    required this.onImportCsv,
    required this.onReset,
    required this.onNavigate,
    required this.onSectionChanged,
    super.key,
  });

  final WorkOrderController controller;
  final EntitlementController entitlementController;
  final ValueChanged<String> onExport;
  final VoidCallback onImport;
  final VoidCallback onImportCsv;
  final VoidCallback onReset;
  final ValueChanged<int> onNavigate;
  final ValueChanged<bool> onSectionChanged;

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  late final TextEditingController _shopName;
  late final TextEditingController _ownerName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _note;
  _SettingsSection? _section;

  void showMenu() => _closeSection();

  void _openSection(_SettingsSection section) {
    setState(() => _section = section);
    widget.onSectionChanged(true);
  }

  void _closeSection() {
    if (_section == null || !mounted) return;
    setState(() => _section = null);
    widget.onSectionChanged(false);
  }

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.data.settings;
    _shopName = TextEditingController(text: settings.shopName);
    _ownerName = TextEditingController(text: settings.ownerName);
    _phone = TextEditingController(text: settings.phone);
    _address = TextEditingController(text: settings.address);
    _note = TextEditingController(text: settings.defaultNote);
  }

  @override
  void dispose() {
    _shopName.dispose();
    _ownerName.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final section = _section;
    if (section == null) return _buildMenu(context);

    return Column(
      children: [
        AppBackBar(
          title: _sectionTitle(section),
          onBack: _closeSection,
        ),
        Expanded(
          child: _Shell(
            kicker: 'SYSTEM / SETTINGS',
            title: _sectionTitle(section),
            showPageHeader: false,
            child: _sectionContent(context, section),
          ),
        ),
      ],
    );
  }

  Widget _buildMenu(BuildContext context) {
    final settings = widget.controller.data.settings;
    final modeText = settings.darkMode ? '当前使用深色模式' : '当前使用浅色模式';
    final shopText = settings.shopName.trim().isEmpty
        ? '尚未填写门店资料'
        : settings.shopName.trim();

    return _Shell(
      kicker: 'SYSTEM / SETTINGS',
      title: '设置与备份',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SettingsGroupLabel(
            title: '系统设置',
            description: '按需进入对应的二级设置页面。',
          ),
          _SettingsMenuEntry(
            icon: Icons.workspace_premium_outlined,
            title: '专业版',
            subtitle: '一次性买断，解锁更多工具',
            value: widget.entitlementController.isPro ? '已激活' : '未激活',
            highlighted: true,
            onTap: () => _openSection(_SettingsSection.pro),
          ),
          _SettingsMenuEntry(
            icon: Icons.storefront_outlined,
            title: '门店资料',
            subtitle: '门店名称、负责人、电话、地址和单据说明',
            value: shopText,
            onTap: () => _openSection(_SettingsSection.shop),
          ),
          _SettingsMenuEntry(
            icon: Icons.palette_outlined,
            title: '显示设置',
            subtitle: '主题模式',
            value: modeText,
            onTap: () => _openSection(_SettingsSection.appearance),
          ),
          _SettingsMenuEntry(
            icon: Icons.space_dashboard_outlined,
            title: '概览设置',
            subtitle: '调整概览卡片的显示和排序',
            onTap: () => _openSection(_SettingsSection.dashboard),
          ),
          _SettingsMenuEntry(
            icon: Icons.tune_outlined,
            title: '工单设置',
            subtitle: '设置工单表单字段的显示和顺序',
            onTap: () => _openSection(_SettingsSection.workOrder),
          ),
          _SettingsMenuEntry(
            icon: Icons.import_export_outlined,
            title: '数据备份',
            subtitle: 'JSON 完整备份、CSV 导入和导出',
            onTap: () => _openSection(_SettingsSection.data),
          ),
          _SettingsMenuEntry(
            icon: Icons.account_balance_wallet_outlined,
            title: '内部成本',
            subtitle: '为每张工单录入成本，并管理成本类型',
            onTap: () => _openSection(_SettingsSection.internalCosts),
          ),
          _SettingsMenuEntry(
            icon: Icons.sell_outlined,
            title: '成本类型设置',
            subtitle: '维护配件、人工、交通等内部成本分类',
            onTap: () => _openSection(_SettingsSection.costTypes),
          ),
          _SettingsMenuEntry(
            icon: Icons.auto_awesome_outlined,
            title: '演示数据',
            subtitle: '载入一组完整示例，快速查看工作流程',
            onTap: () => _openSection(_SettingsSection.demo),
          ),
          const _SettingsGroupLabel(
            title: '工作台工具',
            description: '这些页面也可以从这里进入。',
          ),
          _SettingsMenuEntry(
            icon: Icons.category_outlined,
            title: '项目模板',
            subtitle: '管理常用服务项目和报价模板',
            onTap: () => widget.onNavigate(3),
          ),
          _SettingsMenuEntry(
            icon: Icons.bar_chart_outlined,
            title: '项目统计',
            subtitle: '查看工单数量、收入和状态分布',
            onTap: () => widget.onNavigate(4),
          ),
          _SettingsMenuEntry(
            icon: Icons.delete_outline,
            title: '回收站',
            subtitle: '查看和还原已移入回收站的工单',
            onTap: () => widget.onNavigate(6),
          ),
        ],
      ),
    );
  }

  String _sectionTitle(_SettingsSection section) {
    switch (section) {
      case _SettingsSection.shop:
        return '门店资料';
      case _SettingsSection.appearance:
        return '显示设置';
      case _SettingsSection.dashboard:
        return '概览设置';
      case _SettingsSection.workOrder:
        return '工单设置';
      case _SettingsSection.pro:
        return '专业版';
      case _SettingsSection.data:
        return '数据备份';
      case _SettingsSection.internalCosts:
        return '内部成本';
      case _SettingsSection.costTypes:
        return '成本类型设置';
      case _SettingsSection.demo:
        return '演示数据';
    }
  }

  Widget _sectionContent(BuildContext context, _SettingsSection section) {
    final settings = widget.controller.data.settings;
    switch (section) {
      case _SettingsSection.shop:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingField(label: '门店名称', controller: _shopName),
            _SettingField(label: '负责人', controller: _ownerName),
            _SettingField(label: '联系电话', controller: _phone),
            _SettingField(label: '门店地址', controller: _address),
            _SettingField(
              label: '单据默认说明',
              controller: _note,
              maxLines: 3,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => widget.controller.updateSettings(
                  settings.copyWith(
                    shopName: _shopName.text.trim(),
                    ownerName: _ownerName.text.trim(),
                    phone: _phone.text.trim(),
                    address: _address.text.trim(),
                    defaultNote: _note.text.trim(),
                  ),
                ),
                child: const Text('保存门店资料'),
              ),
            ),
          ],
        );
      case _SettingsSection.appearance:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('深色模式'),
              subtitle: const Text('在低光环境下使用更舒适'),
              value: settings.darkMode,
              onChanged: (value) => widget.controller.updateSettings(
                settings.copyWith(darkMode: value),
              ),
            ),
          ],
        );
      case _SettingsSection.dashboard:
        return _DashboardSettingsContent(controller: widget.controller);
      case _SettingsSection.workOrder:
        return _WorkOrderSettingsContent(controller: widget.controller);
      case _SettingsSection.pro:
        return ProPage(controller: widget.entitlementController);
      case _SettingsSection.data:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BackupAction(
              icon: Icons.ios_share_outlined,
              title: '导出完整 JSON 备份',
              description: '包含客户、工单、模板、付款与设置。',
              onTap: () => widget.onExport('json'),
            ),
            const SizedBox(height: 8),
            _BackupAction(
              icon: Icons.restore_outlined,
              title: '恢复 JSON 备份',
              description: '恢复后会覆盖当前设备上的本地数据。',
              onTap: widget.onImport,
            ),
            const SizedBox(height: 8),
            _BackupAction(
              icon: Icons.table_chart_outlined,
              title: '导出工单 CSV',
              description: '便于在表格软件中查看和整理工单。',
              onTap: () => widget.onExport('csv'),
            ),
            const SizedBox(height: 8),
            _BackupAction(
              icon: Icons.file_upload_outlined,
              title: '导入工单 CSV',
              description: '按工单编号更新或追加客户与工单。',
              onTap: widget.onImportCsv,
            ),
          ],
        );
      case _SettingsSection.internalCosts:
        return _InternalCostsContent(
          controller: widget.controller,
          onOpenCostTypes: () => _openSection(_SettingsSection.costTypes),
        );
      case _SettingsSection.costTypes:
        return _CostTypesContent(controller: widget.controller);
      case _SettingsSection.demo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '这会替换当前设备上的本地数据。建议先完成 JSON 备份。',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: widget.onReset,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('载入演示数据'),
              ),
            ),
          ],
        );
    }
  }
}

class _DashboardSettingsContent extends StatefulWidget {
  const _DashboardSettingsContent({required this.controller});

  final WorkOrderController controller;

  @override
  State<_DashboardSettingsContent> createState() =>
      _DashboardSettingsContentState();
}

class _WorkOrderSettingsContent extends StatefulWidget {
  const _WorkOrderSettingsContent({required this.controller});

  final WorkOrderController controller;

  @override
  State<_WorkOrderSettingsContent> createState() =>
      _WorkOrderSettingsContentState();
}

class _WorkOrderSettingsContentState extends State<_WorkOrderSettingsContent> {
  late List<String> _order;

  @override
  void initState() {
    super.initState();
    _order = [...widget.controller.workOrderFieldOrder];
  }

  @override
  void didUpdateWidget(covariant _WorkOrderSettingsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.controller.workOrderFieldOrder;
    if (!_sameOrder(_order, next)) _order = [...next];
  }

  bool _sameOrder(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final next = [..._order]..insert(newIndex, _order.removeAt(oldIndex));
    setState(() => _order = next);
    unawaited(widget.controller.updateWorkOrderFieldOrder(next));
  }

  void _onVisibilityChanged(String id, bool visible) {
    unawaited(widget.controller.setWorkOrderFieldVisible(id, visible));
  }

  @override
  Widget build(BuildContext context) {
    final hidden = widget.controller.workOrderHiddenFields;
    final visibleCount = _order.where((id) => !hidden.contains(id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: '工单表单字段',
          trailing: Text(
            '$visibleCount/${_order.length} 项显示',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          child: Text(
            '拖动左侧手柄调整字段在工单表单中的顺序，使用右侧开关控制字段是否显示。隐藏字段不会删除已有数据。',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _order.length,
          onReorderItem: _onReorder,
          itemBuilder: (context, index) {
            final id = _order[index];
            final visible = !hidden.contains(id);
            return Card(
              key: ValueKey(id),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_indicator,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(
                  _workOrderFieldLabel(id),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(visible ? '在新建/编辑工单中显示' : '已隐藏'),
                trailing: Switch.adaptive(
                  value: visible,
                  onChanged: (value) => _onVisibilityChanged(id, value),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

const _workOrderFieldLabels = <String, String>{
  'customer': '客户',
  'serviceAddress': '服务地址',
  'deviceType': '设备类型',
  'brand': '品牌',
  'model': '型号',
  'serialNumber': '序列号',
  'faultDescription': '故障描述',
  'customerRequest': '客户需求 / 备注',
  'customerNote': '客户备注',
  'serviceItems': '报价项目',
  'discount': '优惠金额',
  'warrantyDays': '保修天数',
  'warrantyScope': '保修范围',
  'warrantyExclusions': '不保修说明',
  'status': '工单状态',
  'appointmentAt': '预约时间',
  'warrantyStart': '保修开始日期',
  'result': '维修结果',
  'internalNote': '内部备注',
};

String _workOrderFieldLabel(String id) => _workOrderFieldLabels[id] ?? id;

class _DashboardSettingsContentState extends State<_DashboardSettingsContent> {
  late List<String> _order;

  @override
  void initState() {
    super.initState();
    _order = [...widget.controller.dashboardCardOrder];
  }

  @override
  void didUpdateWidget(covariant _DashboardSettingsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.controller.dashboardCardOrder;
    if (!_sameOrder(_order, next)) _order = [...next];
  }

  bool _sameOrder(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final next = [..._order]..insert(newIndex, _order.removeAt(oldIndex));
    setState(() => _order = next);
    unawaited(widget.controller.updateDashboardCardOrder(next));
  }

  void _onVisibilityChanged(String id, bool visible) {
    unawaited(widget.controller.setDashboardCardVisible(id, visible));
  }

  @override
  Widget build(BuildContext context) {
    final hidden = widget.controller.dashboardHiddenCards;
    final visibleCount = _order.where((id) => !hidden.contains(id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: '概览模块',
          trailing: Text(
            '$visibleCount/${_order.length} 张显示',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          child: Text(
            '拖动左侧手柄调整概览中的显示顺序，使用右侧开关控制模块是否显示。',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _order.length,
          onReorderItem: _onReorder,
          itemBuilder: (context, index) {
            final id = _order[index];
            final visible = !hidden.contains(id);
            return Card(
              key: ValueKey(id),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_indicator,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(
                  _dashboardCardLabel(id),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(visible ? '在概览中显示' : '已隐藏'),
                trailing: Switch.adaptive(
                  value: visible,
                  onChanged: (value) => _onVisibilityChanged(id, value),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsGroupLabel extends StatelessWidget {
  const _SettingsGroupLabel({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuEntry extends StatelessWidget {
  const _SettingsMenuEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.value,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? value;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: highlighted ? Clip.antiAlias : Clip.none,
      child: highlighted
          ? DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF155EEF),
                    Color(0xFF4338CA),
                    Color(0xFF7C3AED),
                  ],
                  stops: [0, .52, 1],
                ),
              ),
              child: _buildTile(context, textOnHighlight: true),
            )
          : _buildTile(context),
    );
  }

  Widget _buildTile(BuildContext context, {bool textOnHighlight = false}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: CircleAvatar(
        radius: textOnHighlight ? 24 : null,
        backgroundColor: textOnHighlight
            ? Colors.white.withValues(alpha: .2)
            : Theme.of(context).colorScheme.primary.withValues(alpha: .1),
        foregroundColor: textOnHighlight
            ? Colors.white
            : Theme.of(context).colorScheme.primary,
        child: Icon(icon, size: textOnHighlight ? 20 : 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: textOnHighlight ? Colors.white : null,
        ),
      ),
      subtitle: Text(
        value == null ? subtitle : '$subtitle\n$value',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textOnHighlight
            ? const TextStyle(color: Color(0xE6FFFFFF), height: 1.45)
            : null,
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: textOnHighlight ? Color(0xE6FFFFFF) : null,
      ),
    );
  }
}

class _SettingField extends StatelessWidget {
  const _SettingField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _BackupAction extends StatelessWidget {
  const _BackupAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(13),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingLine extends StatelessWidget {
  const _SettingLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
