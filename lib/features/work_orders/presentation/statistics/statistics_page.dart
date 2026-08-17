part of '../work_order_page.dart';

class _StatsPage extends StatefulWidget {
  const _StatsPage({
    required this.controller,
    required this.entitlementController,
    required this.onBack,
  });

  final WorkOrderController controller;
  final EntitlementController entitlementController;
  final VoidCallback onBack;

  @override
  State<_StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<_StatsPage> {
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    if (!widget.entitlementController.canUse(ProFeature.statistics)) {
      return Column(
        children: [
          AppBackBar(title: context.tr('统计复盘'), onBack: widget.onBack),
          Expanded(
            child: _Shell(
              kicker: context.tr('INSIGHTS / STATISTICS'),
              title: context.tr('统计复盘'),
              showPageHeader: false,
              child: ProPage(
                controller: widget.entitlementController,
              ),
            ),
          ),
        ],
      );
    }
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
    final cost =
        orders.fold<double>(0, (sum, order) => sum + order.internalCostTotal);
    final grossProfit =
        orders.fold<double>(0, (sum, order) => sum + order.grossProfit);
    final margin = revenue <= 0 ? 0 : grossProfit / revenue;
    final currencySymbol = widget.controller.data.settings.currencySymbol;
    final missingCostCount =
        orders.where((order) => order.internalCosts.isEmpty).length;
    final costsByType = <String, double>{};
    for (final order in orders) {
      for (final item in order.internalCosts) {
        costsByType[item.typeName] =
            (costsByType[item.typeName] ?? 0) + item.amount;
      }
    }
    final completed = orders
        .where((order) => order.status == WorkOrderStatus.completed)
        .length;
    final rangeText = _dateRange == null
        ? context.tr('全部日期')
        : '${localizedDateText(context, _dateRange!.start)} – '
            '${localizedDateText(context, _dateRange!.end)}';

    return Column(
      children: [
        AppBackBar(title: context.tr('统计复盘'), onBack: widget.onBack),
        Expanded(
          child: _Shell(
            kicker: context.tr('INSIGHTS / STATISTICS'),
            title: context.tr('统计复盘'),
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
                  tooltip: context.tr('清除日期'),
                  onPressed: () => setState(() => _dateRange = null),
                  icon: const Icon(Icons.clear),
                ),
              ],
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetricSummaryCard(
                  columns: 1,
                  metrics: [
                    _Metric(
                      label: context.tr('工单总数'),
                      value: '${orders.length} ${context.tr('张')}',
                      icon: Icons.receipt_long_outlined,
                    ),
                    _Metric(
                      label: context.tr('报价总额'),
                      value: moneyText(revenue, currencySymbol: currencySymbol),
                      icon: Icons.request_quote_outlined,
                    ),
                    _Metric(
                      label: context.tr('已收金额'),
                      value: moneyText(received, currencySymbol: currencySymbol),
                      icon: Icons.payments_outlined,
                    ),
                    _Metric(
                      label: context.tr('已完成'),
                      value: '$completed ${context.tr('张')}',
                      icon: Icons.task_alt_outlined,
                    ),
                    _Metric(
                      label: context.tr('总成本'),
                      value: moneyText(cost, currencySymbol: currencySymbol),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    _Metric(
                      label: context.tr('毛利'),
                      value: moneyText(
                        grossProfit,
                        currencySymbol: currencySymbol,
                      ),
                      icon: Icons.trending_up_outlined,
                    ),
                    _Metric(
                      label: context.tr('毛利率'),
                      value: '${(margin * 100).toStringAsFixed(1)}%',
                      icon: Icons.percent_outlined,
                    ),
                  ],
                ),
                _Section(
                  title: context.tr('状态分布'),
                  child: Column(
                    children: WorkOrderStatus.values
                        .map(
                          (status) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    workOrderStatusText(context, status),
                                  ),
                                ),
                                Text(
                                  '${orders.where((order) => order.status == status).length} '
                                  '${context.tr('张')}',
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
                  title: context.tr('收款概览'),
                  child: Column(
                    children: [
                      _SettingLine(
                        label: context.tr('应收总额'),
                        value: moneyText(revenue, currencySymbol: currencySymbol),
                      ),
                      _SettingLine(
                        label: context.tr('已收总额'),
                        value: moneyText(received, currencySymbol: currencySymbol),
                      ),
                      _SettingLine(
                        label: context.tr('待收总额'),
                        value: moneyText(
                          (revenue - received).clamp(0, double.infinity),
                          currencySymbol: currencySymbol,
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: context.tr('成本与利润'),
                  trailing: missingCostCount == 0
                      ? null
                      : Text(
                          context.trf(
                            '{count} 张未录入成本',
                            {'count': missingCostCount},
                          ),
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                  child: Column(
                    children: [
                      _SettingLine(
                        label: context.tr('总成本'),
                        value: moneyText(cost, currencySymbol: currencySymbol),
                      ),
                      _SettingLine(
                        label: context.tr('预计毛利'),
                        value: moneyText(
                          grossProfit,
                          currencySymbol: currencySymbol,
                        ),
                      ),
                      _SettingLine(
                        label: context.tr('毛利率'),
                        value: '${(margin * 100).toStringAsFixed(1)}%',
                      ),
                      if (costsByType.isNotEmpty) ...[
                        const Divider(height: 20),
                        ...costsByType.entries.map(
                          (entry) => _SettingLine(
                            label: entry.key,
                            value: moneyText(
                              entry.value,
                              currencySymbol: currencySymbol,
                            ),
                          ),
                        ),
                      ],
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
      helpText: context.tr('选择统计日期范围'),
      cancelText: context.tr('取消'),
      confirmText: context.tr('应用'),
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
