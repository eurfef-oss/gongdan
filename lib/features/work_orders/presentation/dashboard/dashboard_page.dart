part of '../work_order_page.dart';

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.controller,
    required this.onCreate,
    required this.onCustomer,
    required this.onTemplate,
    required this.onOpen,
    required this.onAllOrders,
  });

  final WorkOrderController controller;
  final Future<void> Function({String? customerId}) onCreate;
  final Future<void> Function() onCustomer;
  final Future<void> Function() onTemplate;
  final Future<void> Function(WorkOrder order) onOpen;
  final VoidCallback onAllOrders;

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

    return _Shell(
      kicker: '工作台 / OVERVIEW',
      title: '今天，先把现场安排好。',
      actionsBelowTitle: true,
      actions: [
        FilledButton.icon(
          onPressed: () => onCreate(),
          icon: const Icon(Icons.add),
          label: const Text('新建工单'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricSummaryCard(
            metrics: [
              _Metric(
                label: '今日工单',
                value: '$todayOrders 张',
                icon: Icons.today_outlined,
              ),
              _Metric(
                label: '待收款',
                value: moneyText(outstanding),
                icon: Icons.account_balance_wallet_outlined,
              ),
              _Metric(
                label: '已完成金额',
                value: moneyText(completedAmount),
                icon: Icons.task_alt_outlined,
              ),
              _Metric(
                label: '客户档案',
                value: '${controller.data.customers.length} 位',
                icon: Icons.people_outline,
              ),
            ],
          ),
          _Section(
            title: '工单进度',
            child: Column(
              children: _dashboardProgressStatuses.map((status) {
                final count = _dashboardProgressCount(orders, status);
                final color = statusColor(context, status);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          status.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '$count 张',
                        style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          _Section(
            title: '最近工单',
            trailing: TextButton(
              onPressed: onAllOrders,
              child: const Text('查看全部'),
            ),
            child: recent.isEmpty
                ? const _Empty(
                    title: '还没有工单',
                    description: '创建第一张工单开始记录服务。',
                  )
                : Column(
                    children: recent.take(5).map((order) {
                      final customer =
                          controller.customerById(order.customerId);
                      return _DashboardOrderRow(
                        order: order,
                        customer: customer,
                        onTap: () => onOpen(order),
                      );
                    }).toList(),
                  ),
          ),
          _Section(
            title: '快捷入口',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DashboardAction(
                  icon: Icons.add_circle_outline,
                  title: '新建工单',
                  onTap: () => onCreate(),
                ),
                _DashboardAction(
                  icon: Icons.person_add_alt_outlined,
                  title: '新建客户',
                  onTap: onCustomer,
                ),
                _DashboardAction(
                  icon: Icons.category_outlined,
                  title: '项目模板',
                  onTap: onTemplate,
                ),
              ],
            ),
          ),
        ],
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
        child: Text(initials(customer?.name ?? '')),
      ),
      title: Text(
        '${order.number} · ${customer?.name ?? '未关联客户'}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${deviceText(order)} · ${dateTimeText(order.appointmentAt)}'),
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
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
    );
  }
}
