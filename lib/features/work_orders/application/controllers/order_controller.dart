import '../../domain/entities/work_order.dart';
import '../work_order_store.dart';

class OrderController {
  OrderController(this._store);

  final WorkOrderStore _store;

  String _query = '';
  WorkOrderStatus? _statusFilter;
  PaymentStatus? _paymentFilter;
  DateTime? _createdDateFilter;
  DateTime? _serviceDateFilter;
  String? _customerFilter;
  String? _deviceTypeFilter;

  String get query => _query;
  WorkOrderStatus? get statusFilter => _statusFilter;
  PaymentStatus? get paymentFilter => _paymentFilter;
  DateTime? get createdDateFilter => _createdDateFilter;
  DateTime? get serviceDateFilter => _serviceDateFilter;
  String? get customerFilter => _customerFilter;
  String? get deviceTypeFilter => _deviceTypeFilter;

  List<WorkOrder> get visibleOrders =>
      _store.data.workOrders.where((order) => !order.isTrashed).toList();

  List<WorkOrder> get trashedOrders => [
        ..._store.data.workOrders.where((order) => order.isTrashed),
      ]..sort((a, b) => b.trashedAt!.compareTo(a.trashedAt!));

  List<WorkOrder> get filteredOrders {
    final normalizedQuery = _query.trim().toLowerCase();
    final orders = _store.data.workOrders.where((order) {
      if (order.isTrashed) return false;
      final customer = customerById(order.customerId);
      final searchable = [
        order.number,
        customer?.name,
        customer?.phone,
        order.deviceType,
        order.brand,
        order.model,
        order.faultDescription,
        ...order.items.map((item) => item.name),
      ].join(' ').toLowerCase();
      final queryMatch =
          normalizedQuery.isEmpty || searchable.contains(normalizedQuery);
      final statusMatch =
          _statusFilter == null || order.status == _statusFilter;
      final paymentMatch =
          _paymentFilter == null || order.paymentStatus == _paymentFilter;
      final dateMatch = _createdDateFilter == null ||
          _sameDay(order.createdAt, _createdDateFilter!);
      final serviceDateMatch = _serviceDateFilter == null ||
          (order.appointmentAt != null &&
              _sameDay(order.appointmentAt!, _serviceDateFilter!));
      final customerMatch =
          _customerFilter == null || order.customerId == _customerFilter;
      final deviceTypeMatch =
          _deviceTypeFilter == null || order.deviceType == _deviceTypeFilter;
      return queryMatch &&
          statusMatch &&
          paymentMatch &&
          dateMatch &&
          serviceDateMatch &&
          customerMatch &&
          deviceTypeMatch;
    }).toList();
    orders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return orders;
  }

  Customer? customerById(String id) {
    for (final customer in _store.data.customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  WorkOrder? orderById(String id) {
    for (final order in _store.data.workOrders) {
      if (order.id == id) return order;
    }
    return null;
  }

  List<PaymentRecord> paymentsFor(String orderId) => _store.data.payments
      .where((payment) => payment.orderId == orderId)
      .toList()
    ..sort((a, b) => b.paidAt.compareTo(a.paidAt));

  void setQuery(String value) {
    _query = value;
    _store.onChanged();
  }

  void setStatusFilter(WorkOrderStatus? value) {
    _statusFilter = value;
    _store.onChanged();
  }

  void setPaymentFilter(PaymentStatus? value) {
    _paymentFilter = value;
    _store.onChanged();
  }

  void setCreatedDateFilter(DateTime? value) {
    _createdDateFilter = value;
    _store.onChanged();
  }

  void setServiceDateFilter(DateTime? value) {
    _serviceDateFilter = value;
    _store.onChanged();
  }

  void setCustomerFilter(String? value) {
    _customerFilter = value;
    _store.onChanged();
  }

  void setDeviceTypeFilter(String? value) {
    _deviceTypeFilter = value;
    _store.onChanged();
  }

  void clearOrderFilters() {
    _query = '';
    _statusFilter = null;
    _paymentFilter = null;
    _createdDateFilter = null;
    _serviceDateFilter = null;
    _customerFilter = null;
    _deviceTypeFilter = null;
    _store.onChanged();
  }

  Future<bool> saveOrder(WorkOrder order) async {
    final previous = orderById(order.id);
    if (previous?.status.isTerminal == true || previous?.isTrashed == true) {
      return false;
    }
    var normalized = order.copyWith(updatedAt: DateTime.now());
    if (normalized.status == WorkOrderStatus.draft &&
        (previous == null || previous.status == WorkOrderStatus.draft)) {
      normalized = normalized.copyWith(
        status: normalized.isReadyForConfirmation
            ? WorkOrderStatus.pendingConfirmation
            : WorkOrderStatus.draft,
      );
    }
    if (previous != null &&
        previous.quoteConfirmedAt != null &&
        _quoteChanged(previous, normalized)) {
      normalized = normalized.copyWith(
        status: normalized.status == WorkOrderStatus.cancelled
            ? normalized.status
            : normalized.isReadyForConfirmation
                ? WorkOrderStatus.pendingConfirmation
                : WorkOrderStatus.draft,
        signatureData: null,
        quoteConfirmedAt: null,
        quoteConfirmedTotal: null,
        repairStartedAt: null,
      );
    }
    if (normalized.status == WorkOrderStatus.completed &&
        normalized.outstanding > 0) {
      normalized = normalized.copyWith(status: WorkOrderStatus.awaitingPayment);
    }
    final orders = [..._store.data.workOrders];
    final index = orders.indexWhere((item) => item.id == normalized.id);
    if (index < 0) {
      orders.insert(0, normalized);
    } else {
      orders[index] = normalized;
    }
    return _store.commit(_store.data.copyWith(workOrders: orders));
  }

  Future<bool> moveOrderToTrash(String orderId) async {
    final order = orderById(orderId);
    if (order == null || order.isTrashed) return false;
    final now = DateTime.now();
    final orders = _store.data.workOrders
        .map(
          (item) => item.id == orderId
              ? item.copyWith(trashedAt: now, updatedAt: now)
              : item,
        )
        .toList();
    return _store.commit(_store.data.copyWith(workOrders: orders));
  }

  Future<bool> restoreOrder(String orderId) async {
    final order = orderById(orderId);
    if (order == null || !order.isTrashed) return false;
    final now = DateTime.now();
    final orders = _store.data.workOrders
        .map(
          (item) => item.id == orderId
              ? item.copyWith(trashedAt: null, updatedAt: now)
              : item,
        )
        .toList();
    return _store.commit(_store.data.copyWith(workOrders: orders));
  }

  Future<void> advanceStatus(String orderId) async {
    final order = orderById(orderId);
    final next = order?.status.next;
    if (order == null || order.isTrashed || next == null) return;
    if (next == WorkOrderStatus.completed && order.outstanding > 0) return;
    if (next == WorkOrderStatus.pendingConfirmation &&
        !order.isReadyForConfirmation) {
      return;
    }
    if (next == WorkOrderStatus.repairing) {
      final now = DateTime.now();
      await saveOrder(order.copyWith(
        status: next,
        quoteConfirmedAt: order.quoteConfirmedAt ?? now,
        quoteConfirmedTotal: order.quoteConfirmedTotal ?? order.total,
        repairStartedAt: order.repairStartedAt ?? now,
      ));
      return;
    }
    await saveOrder(order.copyWith(status: next));
  }

  Future<void> cancelOrder(String orderId) async {
    final order = orderById(orderId);
    if (order == null ||
        order.isTrashed ||
        order.status == WorkOrderStatus.completed ||
        order.status == WorkOrderStatus.cancelled) {
      return;
    }
    await saveOrder(order.copyWith(status: WorkOrderStatus.cancelled));
  }

  Future<bool> recordPayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String note = '',
  }) async {
    final order = orderById(orderId);
    if (order == null ||
        order.status.isTerminal ||
        order.isTrashed ||
        amount <= 0 ||
        amount > order.outstanding) {
      return false;
    }
    final now = DateTime.now();
    final record = PaymentRecord(
      id: idFor('pay'),
      orderId: orderId,
      amount: money(amount),
      method: method,
      note: note,
      paidAt: now,
    );
    final nextStatus = order.status == WorkOrderStatus.awaitingPayment &&
            money(order.paid + amount) >= order.total
        ? WorkOrderStatus.completed
        : order.status;
    final orders = _store.data.workOrders
        .map(
          (item) => item.id == orderId
              ? item.copyWith(
                  paid: money(item.paid + amount),
                  status: nextStatus,
                  updatedAt: now,
                )
              : item,
        )
        .toList();
    await _store.commit(
      _store.data.copyWith(
        workOrders: orders,
        payments: [record, ..._store.data.payments],
      ),
    );
    return true;
  }

  Future<void> saveSignature(String orderId, String data) async {
    final order = orderById(orderId);
    if (order == null) return;
    await saveOrder(
      order.copyWith(
        signatureData: data,
        quoteConfirmedAt: order.quoteConfirmedAt ?? DateTime.now(),
        quoteConfirmedTotal: order.quoteConfirmedTotal ?? order.total,
      ),
    );
  }

  Future<void> addAttachments(
    String orderId,
    List<Attachment> attachments,
  ) async {
    final order = orderById(orderId);
    if (order == null || attachments.isEmpty) return;
    await saveOrder(
      order.copyWith(attachments: [...order.attachments, ...attachments]),
    );
  }

  Future<void> removeAttachment(String orderId, String attachmentId) async {
    final order = orderById(orderId);
    if (order == null) return;
    await saveOrder(
      order.copyWith(
        attachments:
            order.attachments.where((item) => item.id != attachmentId).toList(),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _quoteChanged(WorkOrder previous, WorkOrder next) {
    if (previous.customerId != next.customerId ||
        previous.serviceAddress != next.serviceAddress ||
        previous.deviceType != next.deviceType ||
        previous.brand != next.brand ||
        previous.model != next.model ||
        previous.serialNumber != next.serialNumber ||
        previous.faultDescription != next.faultDescription ||
        previous.customerRequest != next.customerRequest ||
        previous.discount != next.discount ||
        previous.items.length != next.items.length) {
      return true;
    }
    for (var index = 0; index < previous.items.length; index++) {
      final a = previous.items[index];
      final b = next.items[index];
      if (a.name != b.name ||
          a.type != b.type ||
          a.customType != b.customType ||
          a.quantity != b.quantity ||
          a.unit != b.unit ||
          a.unitPrice != b.unitPrice ||
          a.note != b.note) {
        return true;
      }
    }
    return false;
  }
}
