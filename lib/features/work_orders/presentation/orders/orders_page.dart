part of '../work_order_page.dart';

class _OrdersPage extends StatefulWidget {
  const _OrdersPage({
    required this.controller,
    required this.entitlementController,
    required this.onCreate,
    required this.onOpen,
    required this.onPurchasePro,
  });

  final WorkOrderController controller;
  final EntitlementController entitlementController;
  final Future<void> Function({String? customerId}) onCreate;
  final Future<void> Function(WorkOrder order) onOpen;
  final Future<void> Function() onPurchasePro;

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
      kicker: context.tr('工作台 / ORDERS'),
      title: context.tr('工单清单'),
      headerActions: [
        _ProPurchaseButton(
          entitlementController: widget.entitlementController,
          onPressed: widget.onPurchasePro,
        ),
      ],
      actionsBelowTitle: true,
      actions: [
        FilledButton.icon(
          onPressed: () => widget.onCreate(),
          icon: const Icon(Icons.add),
          label: Text(context.tr('新建工单')),
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
            _Empty(
              title: context.tr('没有匹配的工单'),
              description: context.tr('调整筛选条件或创建一张新工单。'),
            )
          else
            ...orders.map(
              (order) => _OrderCard(
                order: order,
                customer: controller.customerById(order.customerId),
                onTap: () => widget.onOpen(order),
                onAdvance: () => controller.advanceStatus(order.id),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: widget.searchController,
                  onChanged: controller.setQuery,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: context.tr('搜索编号、客户或设备'),
                    isDense: true,
                  ),
                ),
              ),
            ),
            _OrderFilterDropdown<WorkOrderStatus?>(
              value: controller.statusFilter,
              hint: context.tr('全部状态'),
              items: [
                DropdownMenuItem<WorkOrderStatus?>(
                  value: null,
                  child: Text(context.tr('全部状态')),
                ),
                ...WorkOrderStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(workOrderStatusText(context, status)),
                  ),
                ),
              ],
              onChanged: controller.setStatusFilter,
            ),
            _OrderFilterDropdown<PaymentStatus?>(
              value: controller.paymentFilter,
              hint: context.tr('全部收款'),
              items: [
                DropdownMenuItem<PaymentStatus?>(
                  value: null,
                  child: Text(context.tr('全部收款')),
                ),
                ...PaymentStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(paymentStatusText(context, status)),
                  ),
                ),
              ],
              onChanged: controller.setPaymentFilter,
            ),
            if (controller.query.isNotEmpty ||
                controller.statusFilter != null ||
                controller.paymentFilter != null)
              TextButton.icon(
                onPressed: () {
                  widget.searchController.clear();
                  controller.clearOrderFilters();
                },
                icon: const Icon(Icons.clear, size: 16),
                label: Text(context.tr('清除筛选')),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderFilterDropdown<T> extends StatelessWidget {
  const _OrderFilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/*
 * The order card intentionally keeps its interaction surface simple: tapping
 * anywhere opens the detail page, while the single next-step action stays
 * visible next to the amount summary.
 */
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.customer,
    required this.onTap,
    required this.onAdvance,
  });

  final WorkOrder order;
  final Customer? customer;
  final VoidCallback onTap;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = statusColor(context, order.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: status, width: 4),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderTile(
                order: order,
                customer: customer,
                onTap: onTap,
              ),
              const SizedBox(height: 15),
              _OrderCardDetail(order: order),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${context.tr('应收')} ${moneyText(order.total)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${context.tr('未收')} ${moneyText(order.outstanding)}',
                    style: TextStyle(
                      color: order.outstanding > 0
                          ? statusColor(context, order.paymentStatus)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (order.status.next != null && !order.status.isTerminal)
                    OutlinedButton.icon(
                      onPressed: onAdvance,
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                      ),
                      label: Text(
                        context.trf(
                          '推进至 {status}',
                          {
                            'status': workOrderStatusText(
                              context,
                              order.status.next!,
                            ),
                          },
                        ),
                      ),
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
          child:
              Text(initials(customer?.name ?? '', fallback: context.tr('客'))),
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
                  customer?.name ?? context.tr('未关联客户'),
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
          text: localizedDeviceText(context, order),
        ),
        _OrderDetailLabel(
          icon: Icons.schedule_outlined,
          text: localizedDateTimeText(context, order.appointmentAt),
        ),
        _OrderDetailLabel(
          icon: Icons.payments_outlined,
          text: paymentStatusText(context, order.paymentStatus),
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
        AppBackBar(title: context.tr('回收站'), onBack: onBack),
        Expanded(
          child: _Shell(
            kicker: context.tr('工作台 / ARCHIVE'),
            title: context.tr('回收站'),
            showPageHeader: false,
            child: orders.isEmpty
                ? _Empty(title: context.tr('回收站为空'))
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
        subtitle: Text(
          context.trf(
            '移入时间：{date}',
            {'date': localizedDateText(context, order.trashedAt)},
          ),
        ),
        trailing: OutlinedButton(
          onPressed: onRestore,
          child: Text(context.tr('还原')),
        ),
      ),
    );
  }
}
