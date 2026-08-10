part of '../work_order_page.dart';

class _CustomersPage extends StatefulWidget {
  const _CustomersPage({
    required this.controller,
    required this.onCreate,
    required this.onOpen,
  });

  final WorkOrderController controller;
  final Future<void> Function() onCreate;
  final Future<void> Function(Customer customer) onOpen;

  @override
  State<_CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<_CustomersPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final customers = widget.controller.data.customers.where((customer) {
      if (query.isEmpty) return true;
      return [
        customer.name,
        customer.phone,
        customer.wechat,
        customer.address,
      ].join(' ').toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return _Shell(
      kicker: '工作台 / CUSTOMERS',
      title: '客户档案',
      actions: [
        FilledButton.icon(
          onPressed: widget.onCreate,
          icon: const Icon(Icons.person_add_alt_outlined),
          label: const Text('新建客户'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索姓名、电话、微信或地址',
                isDense: true,
              ),
            ),
          ),
          if (customers.isEmpty)
            const _Empty(
              title: '还没有客户',
              description: '创建客户后可以直接关联到工单。',
            )
          else
            ...customers.map(
              (customer) => _CustomerCard(
                customer: customer,
                orderCount: widget.controller.data.workOrders
                    .where((order) =>
                        order.customerId == customer.id && !order.isTrashed)
                    .length,
                onTap: () => widget.onOpen(customer),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.orderCount,
    required this.onTap,
  });

  final Customer customer;
  final int orderCount;
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
          child: Text(initials(customer.name)),
        ),
        title: Text(
          customer.name.isEmpty ? '未命名客户' : customer.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            [
              if (customer.phone.isNotEmpty) customer.phone,
              if (customer.address.isNotEmpty) customer.address,
              '$orderCount 张工单',
            ].join(' · '),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
