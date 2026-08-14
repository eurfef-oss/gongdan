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
        AppBackBar(title: context.tr('项目模板'), onBack: widget.onBack),
        Expanded(
          child: _Shell(
            kicker: context.tr('工作台 / CATALOG'),
            title: context.tr('项目模板'),
            showPageHeader: false,
            actionsBelowTitle: true,
            actions: [
              OutlinedButton.icon(
                onPressed: widget.onManageTypes,
                icon: const Icon(Icons.tune_outlined),
                label: Text(context.tr('管理类型')),
              ),
              FilledButton.icon(
                onPressed: widget.onCreate,
                icon: const Icon(Icons.add),
                label: Text(context.tr('新建模板')),
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
                        label: Text(context.tr('显示已停用项目')),
                        onSelected: (value) =>
                            setState(() => _showDisabled = value),
                      ),
                      const Spacer(),
                      Text(
                        context.trf('{count} 个项目', {'count': visible.length}),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (visible.isEmpty)
                  _Empty(title: context.tr('暂无项目模板'))
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
          context.trf(
            '{type} · {unit} · ¥{price} · 保修 {days} 天',
            {
              'type': serviceItemTypeText(
                context,
                item.type,
                customType: item.customType,
              ),
              'unit': item.unit,
              'price': item.defaultPrice.toStringAsFixed(2),
              'days': item.warrantyDays,
            },
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'toggle') onToggle();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Text(context.tr('编辑')),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Text(context.tr(item.enabled ? '停用' : '启用')),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(context.tr('删除')),
            ),
          ],
        ),
      ),
    );
  }
}
