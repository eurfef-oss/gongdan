part of '../work_order_page.dart';

class WorkOrderPage extends StatefulWidget {
  const WorkOrderPage({
    required this.controller,
    required this.entitlementController,
    this.fileSelectionService,
    this.shareService,
    this.documentService,
    super.key,
  });

  final WorkOrderController controller;
  final EntitlementController entitlementController;
  final FileSelectionService? fileSelectionService;
  final ShareService? shareService;
  final DocumentService? documentService;

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  int _pageIndex = 0;
  final _settingsKey = GlobalKey<_SettingsPageState>();
  Timer? _exitTimer;
  bool _exitArmed = false;
  bool _settingsSectionOpen = false;
  late final FileSelectionService _fileSelectionService;
  late final ShareService _shareService;
  late final DocumentService _documentService;

  WorkOrderController get controller => widget.controller;
  EntitlementController get entitlementController =>
      widget.entitlementController;

  @override
  void initState() {
    super.initState();
    _fileSelectionService =
        widget.fileSelectionService ?? PlatformFileSelectionService();
    _shareService = widget.shareService ?? const PlatformShareService();
    _documentService = widget.documentService ??
        PlatformDocumentService(
          fileSelectionService: _fileSelectionService,
          shareService: _shareService,
        );
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.status == WorkOrderLoadStatus.loading ||
            controller.status == WorkOrderLoadStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.status == WorkOrderLoadStatus.failure) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr('本地数据加载失败')),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: controller.initialize,
                    child: Text(context.tr('重试')),
                  ),
                ],
              ),
            ),
          );
        }

        if (!controller.data.settings.hasSeenWelcome) {
          return _WelcomePage(
            onStart: () => controller.updateSettings(
              controller.data.settings.copyWith(hasSeenWelcome: true),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;
            final mobile = constraints.maxWidth < 700;
            return PopScope<void>(
              canPop: !_isSecondaryPage && !_settingsSectionOpen && _exitArmed,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) {
                  _exitTimer?.cancel();
                  return;
                }
                if (_isSecondaryPage) return _selectPage(5);
                if (_settingsSectionOpen) {
                  return _settingsKey.currentState?.handleBack();
                }
                _armExit(context);
              },
              child: Scaffold(
                body: SafeArea(
                  child: Column(
                    children: [
                      if (!controller.persistenceAvailable)
                        const _PersistenceWarning(),
                      Expanded(
                        child: Row(
                          children: [
                            if (desktop)
                              _SideNavigation(
                                selected: _pageIndex,
                                onSelected: _selectPage,
                              ),
                            Expanded(child: _currentPage()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: mobile
                    ? NavigationBar(
                        selectedIndex: _pageIndex < 3 ? _pageIndex : 3,
                        onDestinationSelected: (index) =>
                            _selectPage(index == 3 ? 5 : index),
                        destinations: [
                          NavigationDestination(
                            icon: Icon(Icons.space_dashboard_outlined),
                            selectedIcon: Icon(Icons.space_dashboard),
                            label: context.tr('概览'),
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.receipt_long_outlined),
                            selectedIcon: Icon(Icons.receipt_long),
                            label: context.tr('工单'),
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.people_outline),
                            selectedIcon: Icon(Icons.people),
                            label: context.tr('客户'),
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.settings_outlined),
                            selectedIcon: Icon(Icons.settings),
                            label: context.tr('设置'),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  bool get _isSecondaryPage =>
      _pageIndex == 3 || _pageIndex == 4 || _pageIndex == 6;

  void _selectPage(int index) {
    if (index == 4 && !entitlementController.canUse(ProFeature.statistics)) {
      unawaited(_showProPrompt(ProFeature.statistics));
      return;
    }
    final resetSettingsMenu = index == 5 && _pageIndex == 5;
    _exitTimer?.cancel();
    _exitTimer = null;
    if (_pageIndex != index || _exitArmed || resetSettingsMenu) {
      setState(() {
        _pageIndex = index;
        _exitArmed = false;
        if (index != 5) _settingsSectionOpen = false;
      });
    }
    if (resetSettingsMenu) _settingsKey.currentState?.showMenu();
  }

  void _onSettingsSectionChanged(bool open) {
    _exitTimer?.cancel();
    _exitTimer = null;
    if (!mounted) return;
    setState(() {
      _settingsSectionOpen = open;
      _exitArmed = false;
    });
  }

  void _armExit(BuildContext context) {
    _exitTimer?.cancel();
    if (!mounted) return;
    setState(() => _exitArmed = true);
    _exitTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _exitArmed = false);
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr('再按一次返回键退出应用')),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Widget _currentPage() {
    switch (_pageIndex) {
      case 1:
        return _OrdersPage(
          controller: controller,
          entitlementController: entitlementController,
          onCreate: _createOrder,
          onOpen: _openOrder,
          onPurchasePro: () => _showProPrompt(ProFeature.unlimitedOrders),
        );
      case 2:
        return _CustomersPage(
          controller: controller,
          entitlementController: entitlementController,
          onCreate: _createCustomer,
          onOpen: _openCustomer,
          onPurchasePro: () => _showProPrompt(ProFeature.unlimitedCustomers),
        );
      case 3:
        return _TemplatesPage(
          controller: controller,
          onBack: () => _selectPage(5),
          onCreate: () => _requirePro(
            ProFeature.customTemplates,
            _createTemplate,
          ),
          onEdit: (item) => _requirePro(
            ProFeature.customTemplates,
            () => _editTemplate(item),
          ),
          onDelete: (item) => _requirePro(
            ProFeature.customTemplates,
            () => _deleteTemplate(item),
          ),
          onManageTypes: () => _requirePro(
            ProFeature.customTemplates,
            _showTypeManager,
          ),
        );
      case 4:
        return _StatsPage(
          controller: controller,
          entitlementController: entitlementController,
          onBack: () => _selectPage(5),
        );
      case 5:
        return _SettingsPage(
          key: _settingsKey,
          controller: controller,
          entitlementController: entitlementController,
          onExport: _exportData,
          onImport: _importData,
          onImportCsv: _importCsv,
          onReset: _resetDemo,
          onNavigate: _selectPage,
          onSectionChanged: _onSettingsSectionChanged,
        );
      case 6:
        return _RecycleBinPage(
          controller: controller,
          onBack: () => _selectPage(5),
        );
      default:
        return _DashboardPage(
          controller: controller,
          entitlementController: entitlementController,
          onCreate: _createOrder,
          onCustomer: _createCustomer,
          onTemplate: () => _requirePro(
            ProFeature.customTemplates,
            _createTemplate,
          ),
          onOpen: _openOrder,
          onAllOrders: () => _selectPage(1),
          onPurchasePro: () => _showProPrompt(ProFeature.unlimitedOrders),
        );
    }
  }

  Future<void> _createOrder({String? customerId}) async {
    if (!entitlementController
        .canCreateOrder(controller.data.workOrders.length)) {
      await _showProPrompt(ProFeature.unlimitedOrders);
      return;
    }
    final now = DateTime.now();
    var order = emptyWorkOrder(
      id: idFor('ord'),
      number: orderNumberFor(controller.data.workOrders, now),
      now: now,
      customerId: customerId ?? '',
    );
    final enabled = controller.data.serviceItems.where((item) => item.enabled);
    if (enabled.isNotEmpty) {
      final template = enabled.first;
      order = order.copyWith(
        items: [
          WorkOrderItem(
            id: idFor('item'),
            name: template.name,
            type: template.type,
            customType: template.customType,
            quantity: 1,
            unit: template.unit,
            unitPrice: template.defaultPrice,
          ),
        ],
      );
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OrderEditorDialog(
          controller: controller,
          initial: order,
          asPage: true,
          canCreateCustomer: () => entitlementController.canCreateCustomer(
            controller.data.customers.length,
          ),
          onPremiumRequired: () =>
              _showProPrompt(ProFeature.unlimitedCustomers),
        ),
      ),
    );
  }

  Future<void> _openOrder(WorkOrder order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (pageContext) => OrderDetailDialog(
          controller: controller,
          orderId: order.id,
          fileSelectionService: _fileSelectionService,
          asPage: true,
          onEdit: () => _editOrderFromDetail(pageContext, order.id),
          onPayment: () => _showPayment(order.id),
          onSignature: () => _showSignature(order.id),
          onDocument: (kind) => _showDocument(order.id, kind),
          onMoveToTrash: () => _moveOrderToTrash(order.id),
        ),
      ),
    );
  }

  void _editOrderFromDetail(BuildContext detailContext, String orderId) {
    final current = controller.orderById(orderId);
    if (current == null) return;
    Navigator.of(detailContext).push<void>(
      MaterialPageRoute(
        builder: (_) => OrderEditorDialog(
          controller: controller,
          initial: current,
          asPage: true,
          canCreateCustomer: () => entitlementController.canCreateCustomer(
            controller.data.customers.length,
          ),
          onPremiumRequired: () =>
              _showProPrompt(ProFeature.unlimitedCustomers),
        ),
      ),
    );
  }

  Future<void> _createCustomer() async {
    if (!entitlementController
        .canCreateCustomer(controller.data.customers.length)) {
      await _showProPrompt(ProFeature.unlimitedCustomers);
      return;
    }
    await _showDialog(CustomerEditorDialog(controller: controller));
  }

  Future<void> _openCustomer(Customer customer) => _showDialog(
        CustomerDetailDialog(
          controller: controller,
          customerId: customer.id,
          onEdit: () {
            Navigator.of(context).pop();
            _showDialog(
              CustomerEditorDialog(controller: controller, initial: customer),
            );
          },
          onCreateOrder: () {
            Navigator.of(context).pop();
            _createOrder(customerId: customer.id);
          },
        ),
      );

  Future<void> _createTemplate() =>
      _showDialog(TemplateEditorDialog(controller: controller));

  Future<void> _editTemplate(ServiceItem item) => _showDialog(
        TemplateEditorDialog(controller: controller, initial: item),
      );

  Future<void> _showTypeManager() => _showDialog(
        ServiceItemTypeManagerDialog(controller: controller),
      );

  Future<void> _deleteTemplate(ServiceItem item) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('删除项目模板？')),
            content: Text(
              context.trf(
                '“{name}”将从项目目录中移除，已有工单明细不会受影响。',
                {'name': localizedServiceItemName(context, item)},
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('取消')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr('确认删除')),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await controller.deleteServiceItem(item.id);
  }

  Future<T?> _showDialog<T>(Widget child) =>
      showDialog<T>(context: context, builder: (context) => child);

  Future<void> _showPayment(String orderId) => _showDialog(
        PaymentDialog(controller: controller, orderId: orderId),
      );

  Future<void> _showSignature(String orderId) async {
    await _showDialog(
      SignatureDialog(controller: controller, orderId: orderId),
    );
  }

  Future<void> _showDocument(String orderId, String kind) async {
    await _showDialog(
      DocumentPreviewDialog(
        controller: controller,
        orderId: orderId,
        kind: kind,
        documentService: _documentService,
      ),
    );
  }

  Future<void> _requirePro(
    ProFeature feature,
    Future<void> Function() action,
  ) async {
    if (!entitlementController.canUse(feature)) {
      await _showProPrompt(feature);
      return;
    }
    await action();
  }

  Future<void> _showProPrompt(ProFeature feature) async {
    final description = switch (feature) {
      ProFeature.unlimitedOrders => context.tr('普通版最多创建 10 张工单。'),
      ProFeature.unlimitedCustomers => context.tr('普通版最多设置 10 个客户档案。'),
      ProFeature.customTemplates => context.tr('自定义项目模板是专业版功能。'),
      ProFeature.statistics => context.tr('统计复盘是专业版功能。'),
      ProFeature.internalCosts => context.tr('内部成本录入和成本利润统计是专业版功能。'),
      ProFeature.documentExport => context.tr('PDF / PNG 单据对所有版本开放。'),
      ProFeature.customerSignature => context.tr('客户电子签名对所有版本开放。'),
      ProFeature.photoAttachments => context.tr('维修照片附件对所有版本开放。'),
    };
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('解锁专业版'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(description),
                const SizedBox(height: 14),
                Flexible(
                  child: ProPage(
                    controller: entitlementController,
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _moveOrderToTrash(String orderId) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('移入回收站？')),
            content: Text(
              context.tr('工单、照片、签名和收款记录会保留，可随时从回收站还原。'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('取消')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr('移入回收站')),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    final moved = await controller.moveOrderToTrash(orderId);
    if (moved && mounted) Navigator.of(context).pop();
  }

  Future<void> _exportData(String type) async {
    final isJson = type == 'json';
    final bytes = Uint8List.fromList(
      utf8.encode(isJson ? controller.exportJson() : controller.exportCsv()),
    );
    final fileName = isJson ? 'RepairDesk-backup.json' : 'work-orders.csv';
    await _shareService.share(
      text: isJson
          ? context.tr('RepairDesk 完整备份（请妥善保管）')
          : context.tr('RepairDesk 工单 CSV 导出'),
      file: ShareFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: isJson ? 'application/json' : 'text/csv',
      ),
    );
  }

  Future<void> _importData() async {
    final files = await _fileSelectionService.pickFiles(
      kind: FileSelectionKind.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty) return;
    late final Uint8List bytes;
    try {
      bytes = await files.first.readAsBytes();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('恢复本地备份？')),
            content: Text(context.tr('恢复后会覆盖当前设备上的本地数据。')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('取消')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr('确认恢复')),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    var success = false;
    try {
      success = await controller.importJson(utf8.decode(bytes));
    } catch (_) {
      success = false;
    }
    if (mounted) {
      showTopNotice(
        context,
        success ? context.tr('备份已恢复。') : context.tr('备份文件格式不正确。'),
        error: !success,
      );
    }
  }

  Future<void> _importCsv() async {
    final files = await _fileSelectionService.pickFiles(
      kind: FileSelectionKind.custom,
      allowedExtensions: ['csv'],
    );
    if (files.isEmpty) return;
    late final Uint8List bytes;
    try {
      bytes = await files.first.readAsBytes();
    } catch (_) {
      if (mounted) {
        showTopNotice(context, context.tr('CSV 文件读取失败。'), error: true);
      }
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('导入工单 CSV？')),
            content: Text(
              context.tr(
                '将按工单编号更新已有记录，并追加 CSV 中的新工单和客户，不会覆盖其他本地数据。',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('取消')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr('开始导入')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    CsvImportResult? result;
    try {
      result = await controller.importCsv(utf8.decode(bytes));
    } catch (_) {
      result = null;
    }
    if (!mounted) return;
    if (result == null) {
      showTopNotice(
        context,
        context.tr('CSV 格式不正确，未导入任何数据。'),
        error: true,
      );
      return;
    }
    showTopNotice(
      context,
      context.trf(
        'CSV 导入完成：{orders} 张工单，新增 {customers} 位客户。',
        {
          'orders': result.totalOrders,
          'customers': result.createdCustomers,
        },
      ),
    );
  }

  Future<void> _resetDemo() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('载入演示数据？')),
            content: Text(context.tr('这会替换当前设备上的本地数据。')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('取消')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr('确认')),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) await controller.resetToDemo();
  }
}

class _WelcomePage extends StatefulWidget {
  const _WelcomePage({required this.onStart});

  final Future<void> Function() onStart;

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage> {
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RepairDesk',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    context.tr('欢迎开始记录每一次服务。'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('报价、维修、收款和客户资料，都在一张离线工单里完成。'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _WelcomeFeature(
                        icon: Icons.receipt_long_outlined,
                        title: context.tr('工单清单'),
                        description: context.tr('把每一次上门变成可追溯的服务记录。'),
                      ),
                      _WelcomeFeature(
                        icon: Icons.people_outline,
                        title: context.tr('客户档案'),
                        description: context.tr('客户和设备信息，下次报修快速复用。'),
                      ),
                      _WelcomeFeature(
                        icon: Icons.cloud_off_outlined,
                        title: context.tr('本地优先'),
                        description: context.tr('数据保存在本机，网络不可用也能工作。'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  FilledButton.icon(
                    onPressed: _starting
                        ? null
                        : () async {
                            setState(() => _starting = true);
                            await widget.onStart();
                            if (mounted) setState(() => _starting = false);
                          },
                    icon: _starting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(context.tr('开始使用')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeFeature extends StatelessWidget {
  const _WelcomeFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersistenceWarning extends StatelessWidget {
  const _PersistenceWarning();

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(context.tr('当前无法写入本地文件，数据会暂存在内存中。')),
      leading: const Icon(Icons.warning_amber_outlined),
      actions: [
        TextButton(
          onPressed: () {},
          child: Text(context.tr('知道了')),
        ),
      ],
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: _navy,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 22),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.build_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RepairDesk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        context.tr('离线工作台'),
                        style: TextStyle(
                          color: _navMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _NavLabel(context.tr('工作台')),
          _NavItem(
            selected: selected == 0,
            icon: Icons.space_dashboard_outlined,
            label: context.tr('概览'),
            onTap: () => onSelected(0),
          ),
          _NavItem(
            selected: selected == 1,
            icon: Icons.receipt_long_outlined,
            label: context.tr('工单'),
            onTap: () => onSelected(1),
          ),
          _NavItem(
            selected: selected == 2,
            icon: Icons.people_outline,
            label: context.tr('客户'),
            onTap: () => onSelected(2),
          ),
          _NavLabel(context.tr('分析与系统')),
          _NavItem(
            selected: selected == 3,
            icon: Icons.category_outlined,
            label: context.tr('项目模板'),
            onTap: () => onSelected(3),
          ),
          _NavItem(
            selected: selected == 4,
            icon: Icons.bar_chart_outlined,
            label: context.tr('统计复盘'),
            onTap: () => onSelected(4),
          ),
          _NavItem(
            selected: selected == 5,
            icon: Icons.settings_outlined,
            label: context.tr('设置与备份'),
            onTap: () => onSelected(5),
          ),
          _NavItem(
            selected: selected == 6,
            icon: Icons.delete_outline,
            label: context.tr('回收站'),
            onTap: () => onSelected(6),
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.fromLTRB(4, 18, 4, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_outlined, color: _navMuted, size: 17),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('数据保存在本机'),
                    style: TextStyle(
                      color: _navMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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

class _NavLabel extends StatelessWidget {
  const _NavLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 7),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: _navMuted,
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? _blue : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    color: selected ? Colors.white : _navMuted, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : _navMuted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.kicker,
    required this.title,
    this.actions = const [],
    this.headerActions = const [],
    this.actionsBelowTitle = false,
    this.showPageTitle = true,
  });

  final String kicker;
  final String title;
  final List<Widget> actions;
  final List<Widget> headerActions;
  final bool actionsBelowTitle;
  final bool showPageTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showPageTitle ||
              headerActions.isNotEmpty ||
              (!actionsBelowTitle && actions.isNotEmpty))
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showPageTitle)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kicker.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                if (headerActions.isNotEmpty) ...headerActions,
                if (!actionsBelowTitle) ...actions,
              ],
            ),
          if (actionsBelowTitle && actions.isNotEmpty) ...[
            SizedBox(height: showPageTitle ? 12 : 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}
