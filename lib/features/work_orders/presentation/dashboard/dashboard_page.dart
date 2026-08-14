part of '../work_order_page.dart';

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.controller,
    required this.entitlementController,
    required this.onCreate,
    required this.onCustomer,
    required this.onTemplate,
    required this.onOpen,
    required this.onAllOrders,
    required this.onPurchasePro,
  });

  final WorkOrderController controller;
  final EntitlementController entitlementController;
  final Future<void> Function({String? customerId}) onCreate;
  final Future<void> Function() onCustomer;
  final Future<void> Function() onTemplate;
  final Future<void> Function(WorkOrder order) onOpen;
  final VoidCallback onAllOrders;
  final Future<void> Function() onPurchasePro;

  @override
  Widget build(BuildContext context) {
    final orders = controller.visibleOrders;
    final today = DateTime.now();
    final todayOrders = orders
        .where((order) =>
            order.createdAt.year == today.year &&
            order.createdAt.month == today.month &&
            order.createdAt.day == today.day)
        .length;
    final outstanding = orders.fold<double>(
      0,
      (sum, order) => sum + order.outstanding,
    );
    final completedAmount = orders
        .where((order) => order.status == WorkOrderStatus.completed)
        .fold<double>(0, (sum, order) => sum + order.total);
    final recent = [...orders]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final hiddenCards = controller.dashboardHiddenCards;
    final cards = _dashboardSettingsOrder(controller.dashboardCardOrder);

    return _Shell(
      kicker: context.tr('工作台 / OVERVIEW'),
      title: context.tr('今天，先把现场安排好。'),
      showPageTitle: false,
      headerActions: [
        _ProPurchaseButton(
          entitlementController: entitlementController,
          onPressed: onPurchasePro,
        ),
      ],
      actionsBelowTitle: true,
      actions: [
        FilledButton.icon(
          onPressed: () => onCreate(),
          icon: const Icon(Icons.add),
          label: Text(context.tr('新建工单')),
        ),
      ],
      child: _DashboardCardList(
        controller: controller,
        cardOrder: cards,
        hiddenCards: hiddenCards,
        itemBuilder: (context, id) => _dashboardCard(
          context,
          id: id,
          orders: orders,
          recent: recent,
          todayOrders: todayOrders,
          outstanding: outstanding,
          completedAmount: completedAmount,
        ),
      ),
    );
  }

  Widget _dashboardCard(
    BuildContext context, {
    required String id,
    required List<WorkOrder> orders,
    required List<WorkOrder> recent,
    required int todayOrders,
    required double outstanding,
    required double completedAmount,
  }) {
    switch (id) {
      case 'summaryMetrics':
        return _MetricSummaryCard(
          columns: 1,
          metrics: [
            _Metric(
              label: context.tr('今日工单'),
              value: '$todayOrders ${context.tr('张')}',
              icon: Icons.today_outlined,
            ),
            _Metric(
              label: context.tr('待收款'),
              value: moneyText(outstanding),
              icon: Icons.account_balance_wallet_outlined,
            ),
            _Metric(
              label: context.tr('已完成金额'),
              value: moneyText(completedAmount),
              icon: Icons.task_alt_outlined,
            ),
            _Metric(
              label: context.tr('客户档案'),
              value: '${controller.data.customers.length} ${context.tr('位')}',
              icon: Icons.people_outline,
            ),
          ],
        );
      case 'statusProgress':
        return _Section(
          title: context.tr('工单进度'),
          trailing: Text(
            context.trf('{count} 张记录', {'count': orders.length}),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          child: _ProgressGrid(orders: orders),
        );
      case 'recentOrders':
        return _Section(
          title: context.tr('最近工单'),
          trailing: TextButton(
            onPressed: onAllOrders,
            child: Text(context.tr('查看全部')),
          ),
          child: recent.isEmpty
              ? _Empty(
                  title: context.tr('还没有工单'),
                  description: context.tr('创建第一张工单开始记录服务。'),
                )
              : Column(
                  children: recent.take(5).map((order) {
                    final customer = controller.customerById(order.customerId);
                    return _DashboardOrderRow(
                      order: order,
                      customer: customer,
                      onTap: () => onOpen(order),
                    );
                  }).toList(),
                ),
        );
      case 'quickActions':
        return _Section(
          title: context.tr('快捷入口'),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DashboardAction(
                icon: Icons.add_circle_outline,
                title: context.tr('新建工单'),
                onTap: () => onCreate(),
              ),
              _DashboardAction(
                icon: Icons.person_add_alt_outlined,
                title: context.tr('新建客户'),
                onTap: onCustomer,
              ),
              _DashboardAction(
                icon: Icons.category_outlined,
                title: context.tr('项目模板'),
                onTap: onTemplate,
              ),
            ],
          ),
        );
      case 'warrantyReminder':
        return _WarrantyReminderSection(
          orders: orders,
          onOpen: onOpen,
          controller: controller,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _DashboardCardList extends StatefulWidget {
  const _DashboardCardList({
    required this.controller,
    required this.cardOrder,
    required this.hiddenCards,
    required this.itemBuilder,
  });

  final WorkOrderController controller;
  final List<String> cardOrder;
  final Set<String> hiddenCards;
  final Widget Function(BuildContext context, String id) itemBuilder;

  @override
  State<_DashboardCardList> createState() => _DashboardCardListState();
}

class _DashboardCardListState extends State<_DashboardCardList> {
  late List<String> _order;

  @override
  void initState() {
    super.initState();
    _order = [...widget.cardOrder];
  }

  @override
  void didUpdateWidget(covariant _DashboardCardList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameOrder(_order, widget.cardOrder)) {
      _order = [...widget.cardOrder];
    }
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

    final visible =
        _order.where((id) => !widget.hiddenCards.contains(id)).toList();
    final nextVisible = [...visible]
      ..insert(newIndex, visible.removeAt(oldIndex));
    var visibleIndex = 0;
    final next = _order.map((id) {
      if (widget.hiddenCards.contains(id)) return id;
      return nextVisible[visibleIndex++];
    }).toList();

    setState(() => _order = next);
    unawaited(widget.controller.updateDashboardCardOrder(next));
  }

  @override
  Widget build(BuildContext context) {
    final cards =
        _order.where((id) => !widget.hiddenCards.contains(id)).toList();

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: true,
      itemCount: cards.length,
      onReorderItem: _onReorder,
      itemBuilder: (context, index) {
        final id = cards[index];
        return KeyedSubtree(
          key: ValueKey(id),
          child: widget.itemBuilder(context, id),
        );
      },
    );
  }
}

class _WarrantyReminderSection extends StatelessWidget {
  const _WarrantyReminderSection({
    required this.orders,
    required this.onOpen,
    required this.controller,
  });

  final List<WorkOrder> orders;
  final Future<void> Function(WorkOrder order) onOpen;
  final WorkOrderController controller;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final warrantyOrders = orders.where((order) {
      final end = order.warrantyEnd;
      if (order.warrantyDays <= 0 || end == null) return false;
      final endDay = DateTime(end.year, end.month, end.day);
      return !endDay.isBefore(today);
    }).toList()
      ..sort((a, b) => a.warrantyEnd!.compareTo(b.warrantyEnd!));

    return _Section(
      title: context.tr('保修提醒'),
      trailing: Text(
        context.trf('{count} 张有效', {'count': warrantyOrders.length}),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      child: warrantyOrders.isEmpty
          ? _Empty(
              title: context.tr('暂无有效保修'),
              description: context.tr('为已完成的工单填写保修期限后，会在这里集中提醒。'),
            )
          : Column(
              children: warrantyOrders.take(5).map((order) {
                final end = order.warrantyEnd!;
                final endDay = DateTime(end.year, end.month, end.day);
                final remaining = endDay.difference(today).inDays;
                final customer = controller.customerById(order.customerId);
                final remainingText = remaining == 0
                    ? context.tr('今日到期')
                    : remaining == 1
                        ? context.tr('剩余 1 天')
                        : context.trf('剩余 {days} 天', {'days': remaining});
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .1),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.verified_user_outlined, size: 19),
                  ),
                  title: Text(
                    '${order.number} · ${customer?.name ?? context.tr('未关联客户')}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    context.trf(
                      '保修至 {date} · {remaining}',
                      {
                        'date': localizedDateText(context, end),
                        'remaining': remainingText,
                      },
                    ),
                  ),
                  onTap: () => onOpen(order),
                );
              }).toList(),
            ),
    );
  }
}

class _DashboardOrderRow extends StatelessWidget {
  const _DashboardOrderRow({
    required this.order,
    required this.customer,
    required this.onTap,
  });

  final WorkOrder order;
  final Customer? customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: .1),
        foregroundColor: Theme.of(context).colorScheme.primary,
        child: Text(initials(customer?.name ?? '', fallback: context.tr('客'))),
      ),
      title: Text(
        '${order.number} · ${customer?.name ?? context.tr('未关联客户')}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${localizedDeviceText(context, order)} · '
            '${localizedDateTimeText(context, order.appointmentAt)}',
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: _StatusChip(order.status),
          ),
        ],
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 190,
      child: Card(
        color: scheme.surfaceContainerHighest.withValues(alpha: .72),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressGrid extends StatelessWidget {
  const _ProgressGrid({required this.orders});

  final List<WorkOrder> orders;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 1;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: _dashboardProgressStatuses
              .map(
                (status) => SizedBox(
                  width: width,
                  child: _ProgressItem(
                    status: status,
                    count: _dashboardProgressCount(orders, status),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({required this.status, required this.count});

  final WorkOrderStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(context, status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .14)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward_rounded, color: color, size: 15),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              workOrderStatusText(context, status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$count ${context.tr('张')}',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
