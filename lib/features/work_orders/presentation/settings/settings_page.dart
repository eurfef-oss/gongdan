part of '../work_order_page.dart';

enum _SettingsSection { shop, appearance, data, demo }

class _SettingsPage extends StatefulWidget {
  const _SettingsPage({
    required this.controller,
    required this.onExport,
    required this.onImport,
    required this.onImportCsv,
    required this.onReset,
    required this.onNavigate,
  });

  final WorkOrderController controller;
  final ValueChanged<String> onExport;
  final VoidCallback onImport;
  final VoidCallback onImportCsv;
  final VoidCallback onReset;
  final ValueChanged<int> onNavigate;

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
          title: '设置与备份',
          onBack: () => setState(() => _section = null),
        ),
        Expanded(
          child: _Shell(
            kicker: 'SYSTEM / SETTINGS',
            title: _sectionTitle(section),
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
            icon: Icons.storefront_outlined,
            title: '门店资料',
            subtitle: '门店名称、负责人、电话、地址和单据说明',
            value: shopText,
            onTap: () => setState(() => _section = _SettingsSection.shop),
          ),
          _SettingsMenuEntry(
            icon: Icons.palette_outlined,
            title: '显示设置',
            subtitle: '主题模式和概览卡片显示方式',
            value: modeText,
            onTap: () => setState(() => _section = _SettingsSection.appearance),
          ),
          _SettingsMenuEntry(
            icon: Icons.import_export_outlined,
            title: '数据备份',
            subtitle: 'JSON 完整备份、CSV 导入和导出',
            onTap: () => setState(() => _section = _SettingsSection.data),
          ),
          _SettingsMenuEntry(
            icon: Icons.auto_awesome_outlined,
            title: '演示数据',
            subtitle: '载入一组完整示例，快速查看工作流程',
            onTap: () => setState(() => _section = _SettingsSection.demo),
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
      case _SettingsSection.data:
        return '数据备份';
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
            _Section(
              title: '门店与负责人',
              child: Column(
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
              ),
            ),
          ],
        );
      case _SettingsSection.appearance:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(
              title: '显示设置',
              child: Column(
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('概览卡片'),
                    subtitle: Text(
                      '${widget.controller.dashboardCardOrder.length} 张卡片可用',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDashboardCards(context),
                  ),
                ],
              ),
            ),
          ],
        );
      case _SettingsSection.data:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(
              title: '导入与导出',
              child: Column(
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
                    icon: Icons.table_chart_outlined,
                    title: '导出工单 CSV',
                    description: '便于在表格软件中查看和整理工单。',
                    onTap: () => widget.onExport('csv'),
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
                    icon: Icons.file_upload_outlined,
                    title: '导入工单 CSV',
                    description: '按工单编号更新或追加客户与工单。',
                    onTap: widget.onImportCsv,
                  ),
                ],
              ),
            ),
          ],
        );
      case _SettingsSection.demo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(
              title: '载入演示数据',
              subtitle: '这会替换当前设备上的本地数据。建议先完成 JSON 备份。',
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: widget.onReset,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('载入演示数据'),
                ),
              ),
            ),
          ],
        );
    }
  }

  Future<void> _showDashboardCards(BuildContext context) async {
    final hidden = {...widget.controller.dashboardHiddenCards};
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('概览卡片'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _dashboardCardLabels.keys.map((id) {
                final visible = !hidden.contains(id);
                return CheckboxListTile(
                  value: visible,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_dashboardCardLabel(id)),
                  onChanged: (value) async {
                    if (value == null) return;
                    await widget.controller.setDashboardCardVisible(id, value);
                    setDialogState(() {
                      if (value) {
                        hidden.remove(id);
                      } else {
                        hidden.add(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      ),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: .1),
          foregroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(icon, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          value == null ? subtitle : '$subtitle\n$value',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
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
