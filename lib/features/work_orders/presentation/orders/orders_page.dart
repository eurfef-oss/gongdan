part of '../work_order_page.dart';

class _OrdersPage extends StatefulWidget {
  const _OrdersPage({
    required this.controller,
    required this.onCreate,
    required this.onOpen,
  });

  final WorkOrderController controller;
  final Future<void> Function({String? customerId}) onCreate;
  final Future<void> Function(WorkOrder order) onOpen;

  @override
  State<_OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<_OrdersPage> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.text = widget.controller.query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final orders = controller.filteredOrders;
    return _Shell(
      kicker: '工作台 / ORDERS',
      title: '工单清单',
      actions: [
        FilledButton.icon(
          onPressed: () => widget.onCreate(),
          icon: const Icon(Icons.add),
          label: const Text('新建工单'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OrderFilters(
            controller: controller,
            searchController: _search,
          ),
          if (orders.isEmpty)
            const _Empty(
              title: '没有匹配的工单',
              description: '调整筛选条件或创建一张新工单。',
            )
          else
            ...orders.map(
              (order) => _OrderCard(
                order: order,
                customer: controller.customerById(order.customerId),
                onTap: () => widget.onOpen(order),
                onAdvance: () => controller.advanceStatus(order.id),
                onCancel: () => controller.cancelOrder(order.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderFilters extends StatefulWidget {
  const _OrderFilters({
    required this.controller,
    required this.searchController,
  });

  final WorkOrderController controller;
  final TextEditingController searchController;

  @override
  State<_OrderFilters> createState() => _OrderFiltersState();
}

class _OrderFiltersState extends State<_OrderFilters> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: widget.searchController,
              onChanged: controller.setQuery,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索工单',
                isDense: true,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<WorkOrderStatus?>(
              value: controller.statusFilter,
              hint: const Text('全部状态'),
              items: [
                const DropdownMenuItem<WorkOrderStatus?>(
                  value: null,
                  child: Text('全部状态'),
                ),
                ...WorkOrderStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  ),
                ),
              ],
              onChanged: controller.setStatusFilter,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<PaymentStatus?>(
              value: controller.paymentFilter,
              hint: const Text('全部收款'),
              items: [
                const DropdownMenuItem<PaymentStatus?>(
                  value: null,
                  child: Text('全部收款'),
                ),
                ...PaymentStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  ),
                ),
              ],
              onChanged: controller.setPaymentFilter,
            ),
          ),
          if (controller.query.isNotEmpty ||
              controller.statusFilter != null ||
              controller.paymentFilter != null)
            TextButton(
              onPressed: () {
                widget.searchController.clear();
                controller.clearOrderFilters();
              },
              child: const Text('清除筛选'),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.customer,
    required this.onTap,
    required this.onAdvance,
    required this.onCancel,
  });

  final WorkOrder order;
  final Customer? customer;
  final VoidCallback onTap;
  final VoidCallback onAdvance;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderTile(
                order: order,
                customer: customer,
                onTap: onTap,
              ),
              const Divider(height: 24),
              _OrderCardDetail(order: order),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '应收 ${moneyText(order.total)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '未收 ${moneyText(order.outstanding)}',
                    style: TextStyle(
                      color: order.outstanding > 0
                          ? statusColor(context, order.paymentStatus)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (order.status.next != null && !order.status.isTerminal)
                    TextButton(
                      onPressed: onAdvance,
                      child: Text('推进至 ${order.status.next!.label}'),
                    ),
                  if (!order.status.isTerminal)
                    IconButton(
                      tooltip: '取消工单',
                      onPressed: onCancel,
                      icon: const Icon(Icons.block_outlined),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.customer,
    required this.onTap,
  });

  final WorkOrder order;
  final Customer? customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: .1),
          foregroundColor: Theme.of(context).colorScheme.primary,
          child: Text(initials(customer?.name ?? '')),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer?.name ?? '未关联客户',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        _StatusChip(order.status),
      ],
    );
  }
}

class _OrderCardDetail extends StatelessWidget {
  const _OrderCardDetail({required this.order});

  final WorkOrder order;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        _OrderDetailLabel(
          icon: Icons.devices_other_outlined,
          text: deviceText(order),
        ),
        _OrderDetailLabel(
          icon: Icons.schedule_outlined,
          text: dateTimeText(order.appointmentAt),
        ),
        _OrderDetailLabel(
          icon: Icons.payments_outlined,
          text: order.paymentStatus.label,
        ),
      ],
    );
  }
}

class _OrderDetailLabel extends StatelessWidget {
  const _OrderDetailLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _RecycleBinPage extends StatelessWidget {
  const _RecycleBinPage({required this.controller, required this.onBack});

  final WorkOrderController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final orders = controller.trashedOrders;
    return Column(
      children: [
        AppBackBar(title: '回收站', onBack: onBack),
        Expanded(
          child: _Shell(
            kicker: '工作台 / ARCHIVE',
            title: '回收站',
            child: orders.isEmpty
                ? const _Empty(title: '回收站为空')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: orders
                        .map(
                          (order) => _RecycleBinRow(
                            order: order,
                            onRestore: () => controller.restoreOrder(order.id),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RecycleBinRow extends StatelessWidget {
  const _RecycleBinRow({required this.order, required this.onRestore});

  final WorkOrder order;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(order.number),
        subtitle: Text('移入时间：${dateText(order.trashedAt)}'),
        trailing: OutlinedButton(
          onPressed: onRestore,
          child: const Text('还原'),
        ),
      ),
    );
  }
}
