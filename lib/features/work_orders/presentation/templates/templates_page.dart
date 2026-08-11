part of '../work_order_page.dart';

class _TemplatesPage extends StatefulWidget {
  const _TemplatesPage({
    required this.controller,
    required this.onBack,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onManageTypes,
  });

  final WorkOrderController controller;
  final VoidCallback onBack;
  final Future<void> Function() onCreate;
  final Future<void> Function(ServiceItem item) onEdit;
  final Future<void> Function(ServiceItem item) onDelete;
  final Future<void> Function() onManageTypes;

  @override
  State<_TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<_TemplatesPage> {
  bool _showDisabled = true;

  @override
  Widget build(BuildContext context) {
    final items = [...widget.controller.data.serviceItems]
      ..sort((a, b) => a.name.compareTo(b.name));
    final visible =
        _showDisabled ? items : items.where((item) => item.enabled).toList();

    return Column(
      children: [
        AppBackBar(title: '项目模板', onBack: widget.onBack),
        Expanded(
          child: _Shell(
            kicker: '工作台 / CATALOG',
            title: '项目模板',
            actionsBelowTitle: true,
            actions: [
              OutlinedButton.icon(
                onPressed: widget.onManageTypes,
                icon: const Icon(Icons.tune_outlined),
                label: const Text('管理类型'),
              ),
              FilledButton.icon(
                onPressed: widget.onCreate,
                icon: const Icon(Icons.add),
                label: const Text('新建模板'),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _showDisabled,
                        label: const Text('显示已停用项目'),
                        onSelected: (value) =>
                            setState(() => _showDisabled = value),
                      ),
                      const Spacer(),
                      Text(
                        '${visible.length} 个项目',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (visible.isEmpty)
                  const _Empty(title: '暂无项目模板')
                else
                  ...visible.map(
                    (item) => _TemplateRow(
                      item: item,
                      onEdit: () => widget.onEdit(item),
                      onDelete: () => widget.onDelete(item),
                      onToggle: () =>
                          widget.controller.toggleServiceItem(item.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final ServiceItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: .1),
          foregroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.category_outlined, size: 19),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: item.enabled
                ? null
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          '${item.typeLabel} · ${item.unit} · ¥${item.defaultPrice.toStringAsFixed(2)} · 保修 ${item.warrantyDays} 天',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'toggle') onToggle();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(item.enabled ? '停用' : '启用'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
      ),
    );
  }
}
