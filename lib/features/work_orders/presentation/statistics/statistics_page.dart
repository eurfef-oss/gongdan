part of '../work_order_page.dart';

class _StatsPage extends StatefulWidget {
  const _StatsPage({required this.controller, required this.onBack});

  final WorkOrderController controller;
  final VoidCallback onBack;

  @override
  State<_StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<_StatsPage> {
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final orders = widget.controller.visibleOrders.where((order) {
      final range = _dateRange;
      if (range == null) return true;
      final date = DateUtils.dateOnly(order.createdAt);
      return !date.isBefore(DateUtils.dateOnly(range.start)) &&
          !date.isAfter(DateUtils.dateOnly(range.end));
    }).toList();
    final revenue = orders.fold<double>(0, (sum, order) => sum + order.total);
    final received =
        orders.fold<double>(0, (sum, order) => sum + order.normalizedPaid);
    final completed = orders
        .where((order) => order.status == WorkOrderStatus.completed)
        .length;
    final rangeText = _dateRange == null
        ? '全部日期'
        : '${dateText(_dateRange!.start)} – ${dateText(_dateRange!.end)}';

    return Column(
      children: [
        AppBackBar(title: '统计复盘', onBack: widget.onBack),
        Expanded(
          child: _Shell(
            kicker: 'INSIGHTS / STATISTICS',
            title: '统计复盘',
            showPageHeader: false,
            actions: [
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_outlined),
                label: Text(rangeText),
              ),
              if (_dateRange != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '清除日期',
                  onPressed: () => setState(() => _dateRange = null),
                  icon: const Icon(Icons.clear),
                ),
              ],
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetricSummaryCard(
                  metrics: [
                    _Metric(
                      label: '工单总数',
                      value: '${orders.length} 张',
                      icon: Icons.receipt_long_outlined,
                    ),
                    _Metric(
                      label: '报价总额',
                      value: moneyText(revenue),
                      icon: Icons.request_quote_outlined,
                    ),
                    _Metric(
                      label: '已收金额',
                      value: moneyText(received),
                      icon: Icons.payments_outlined,
                    ),
                    _Metric(
                      label: '已完成',
                      value: '$completed 张',
                      icon: Icons.task_alt_outlined,
                    ),
                  ],
                ),
                _Section(
                  title: '状态分布',
                  child: Column(
                    children: WorkOrderStatus.values
                        .map(
                          (status) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(child: Text(status.label)),
                                Text(
                                  '${orders.where((order) => order.status == status).length} 张',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                _Section(
                  title: '收款概览',
                  child: Column(
                    children: [
                      _SettingLine(label: '应收总额', value: moneyText(revenue)),
                      _SettingLine(label: '已收总额', value: moneyText(received)),
                      _SettingLine(
                        label: '待收总额',
                        value: moneyText(
                          (revenue - received).clamp(0, double.infinity),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10, 12, 31),
      initialDateRange: _dateRange,
      helpText: '选择统计日期范围',
      cancelText: '取消',
      confirmText: '应用',
    );
    if (picked == null || !mounted) return;
    setState(
      () => _dateRange = DateTimeRange(
        start: DateUtils.dateOnly(picked.start),
        end: DateUtils.dateOnly(picked.end),
      ),
    );
  }
}
