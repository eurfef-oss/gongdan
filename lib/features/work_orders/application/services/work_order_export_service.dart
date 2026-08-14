import 'dart:convert';

import '../../../../l10n/app_strings.dart';
import '../../../../l10n/model_localizations.dart';
import '../../domain/entities/work_order.dart';

const _csvHeaders = <String>[
  '工单编号',
  '客户',
  '手机号',
  '设备',
  '故障描述',
  '状态',
  '应收金额',
  '已收金额',
  '未收金额',
  '收款状态',
  '创建时间',
  '服务项目',
  '收款记录',
  '内部成本',
  '毛利',
  '成本明细',
];

const _csvRequiredHeaders = <String>['工单编号', '客户', '状态'];

String _csvText(String locale, String key) => localizedText(locale, key);

String _canonicalCsvHeader(String value) {
  final trimmed = value.trim();
  for (final header in _csvHeaders) {
    if (trimmed == header || trimmed == _csvText('en', header)) {
      return header;
    }
  }
  return trimmed;
}

class CsvImportResult {
  const CsvImportResult({
    required this.createdCustomers,
    required this.updatedCustomers,
    required this.createdOrders,
    required this.updatedOrders,
    required this.importedPayments,
  });

  final int createdCustomers;
  final int updatedCustomers;
  final int createdOrders;
  final int updatedOrders;
  final int importedPayments;

  int get totalOrders => createdOrders + updatedOrders;
}

class CsvImportOutcome {
  const CsvImportOutcome({required this.data, required this.result});

  final RepairAppData data;
  final CsvImportResult result;
}

class WorkOrderExportService {
  String exportJson(RepairAppData data) => jsonEncode(data.toJson());

  String exportCsv(RepairAppData data) {
    final locale = data.settings.languageCode;
    final rows = <List<String>>[
      _csvHeaders.map((header) => _csvText(locale, header)).toList(),
      ...data.workOrders.map((order) {
        final customer = _customerById(data, order.customerId);
        return [
          order.number,
          customer?.name ?? '',
          customer?.phone ?? '',
          [order.deviceType, order.brand, order.model]
              .where((value) => value.isNotEmpty)
              .join(' '),
          order.faultDescription,
          _csvText(locale, order.status.label),
          order.total.toStringAsFixed(2),
          order.normalizedPaid.toStringAsFixed(2),
          order.outstanding.toStringAsFixed(2),
          _csvText(locale, order.paymentStatus.label),
          order.createdAt.toIso8601String(),
          order.items
              .map((item) =>
                  '${localizedWorkOrderItemNameForLocale(locale, item)} ${item.quantity}${localizedUnitForLocale(locale, item.unit)} ¥${item.amount.toStringAsFixed(2)}')
              .join('；'),
          _paymentsFor(data, order.id)
              .map((payment) =>
                  '${_csvText(locale, payment.method.label)} ${payment.amount.toStringAsFixed(2)} ${payment.paidAt.toIso8601String()}${payment.note.isEmpty ? '' : ' ${payment.note}'}')
              .join('；'),
          order.internalCostTotal.toStringAsFixed(2),
          order.grossProfit.toStringAsFixed(2),
          order.internalCosts
              .map(
                (cost) =>
                    '${_csvText(locale, cost.typeName)} ¥${cost.amount.toStringAsFixed(2)}${cost.note.isEmpty ? '' : ' ${cost.note}'}',
              )
              .join('；'),
        ];
      }),
    ];
    return '\uFEFF${rows.map((row) => row.map(_csvEscape).join(',')).join('\n')}';
  }

  CsvImportOutcome? importCsv(String raw, RepairAppData data) {
    try {
      final rows = _parseCsvRows(raw);
      if (rows.length < 2) return null;
      final headers = rows.first.map(_canonicalCsvHeader).toList();
      if (!_csvRequiredHeaders.every(headers.contains)) return null;
      final indexes = <String, int>{
        for (var index = 0; index < headers.length; index++)
          headers[index]: index,
      };

      final customers = [...data.customers];
      final orders = [...data.workOrders];
      final payments = [...data.payments];
      final now = DateTime.now();
      var createdCustomers = 0;
      var updatedCustomers = 0;
      var createdOrders = 0;
      var updatedOrders = 0;
      var importedPayments = 0;
      final importedNumbers = <String>{};

      for (final row in rows.skip(1)) {
        final number = _csvValue(row, indexes, '工单编号');
        if (number.isEmpty || !importedNumbers.add(number)) continue;
        final customerName = _csvValue(row, indexes, '客户');
        final phone = _csvValue(row, indexes, '手机号');
        final customer = _findCsvCustomer(customers, customerName, phone);
        var customerId = customer?.id ?? '';
        if (customer == null && customerName.isNotEmpty) {
          final created = Customer(
            id: idFor('cus'),
            name: customerName,
            phone: phone,
            createdAt: now,
            updatedAt: now,
          );
          customers.insert(0, created);
          customerId = created.id;
          createdCustomers++;
        } else if (customer != null &&
            phone.isNotEmpty &&
            customer.phone.isEmpty) {
          final updated = customer.copyWith(phone: phone, updatedAt: now);
          final index = customers.indexWhere((item) => item.id == customer.id);
          if (index >= 0) customers[index] = updated;
          updatedCustomers++;
        }

        final existingIndex =
            orders.indexWhere((item) => item.number == number);
        final existing = existingIndex < 0 ? null : orders[existingIndex];
        final createdAt = dateValue(_csvValue(row, indexes, '创建时间')) ??
            existing?.createdAt ??
            now;
        final total = numberValue(_csvValue(row, indexes, '应收金额'));
        final items = _itemsFromCsv(
          _csvValue(row, indexes, '服务项目'),
          total,
          data.settings.languageCode,
        );
        var status = _statusFromCsv(_csvValue(row, indexes, '状态'));
        final paid = numberValue(_csvValue(row, indexes, '已收金额'));
        final hasCostColumns =
            indexes.containsKey('内部成本') || indexes.containsKey('成本明细');
        final importedCosts = _costsFromCsv(
          _csvValue(row, indexes, '成本明细'),
          numberValue(_csvValue(row, indexes, '内部成本')),
          data.settings.costTypes,
          data.settings.languageCode,
        );
        final importedOrder = emptyWorkOrder(
          id: existing?.id ?? idFor('ord'),
          number: number,
          now: createdAt,
          customerId:
              customerId.isEmpty ? existing?.customerId ?? '' : customerId,
        ).copyWith(
          serviceAddress: existing?.serviceAddress ?? '',
          deviceType: _csvValue(row, indexes, '设备'),
          faultDescription: _csvValue(row, indexes, '故障描述'),
          status: status,
          items: items,
          paid: paid,
          internalCosts: hasCostColumns
              ? importedCosts
              : existing?.internalCosts ?? const [],
          attachments: existing?.attachments,
          signatureData: existing?.signatureData,
          quoteConfirmedAt: existing?.quoteConfirmedAt,
          quoteConfirmedTotal: existing?.quoteConfirmedTotal,
          repairStartedAt: existing?.repairStartedAt,
          warrantyDays: existing?.warrantyDays,
          warrantyStart: existing?.warrantyStart,
          warrantyEnd: existing?.warrantyEnd,
          warrantyScope: existing?.warrantyScope,
          warrantyExclusions: existing?.warrantyExclusions,
          updatedAt: now,
        );
        if (importedOrder.status == WorkOrderStatus.completed &&
            importedOrder.outstanding > 0) {
          status = WorkOrderStatus.awaitingPayment;
        }
        final normalizedOrder = importedOrder.copyWith(status: status);
        if (existingIndex < 0) {
          orders.insert(0, normalizedOrder);
          createdOrders++;
        } else {
          orders[existingIndex] = normalizedOrder;
          updatedOrders++;
        }

        payments
            .removeWhere((payment) => payment.orderId == normalizedOrder.id);
        final importedForOrder = _paymentsFromCsv(
          _csvValue(row, indexes, '收款记录'),
          normalizedOrder.id,
        );
        payments.insertAll(0, importedForOrder);
        importedPayments += importedForOrder.length;
      }

      final nextData = data.copyWith(
        customers: customers,
        workOrders: orders,
        payments: payments,
      );
      return CsvImportOutcome(
        data: nextData,
        result: CsvImportResult(
          createdCustomers: createdCustomers,
          updatedCustomers: updatedCustomers,
          createdOrders: createdOrders,
          updatedOrders: updatedOrders,
          importedPayments: importedPayments,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Customer? _customerById(RepairAppData data, String id) {
    for (final customer in data.customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  static List<PaymentRecord> _paymentsFor(RepairAppData data, String orderId) =>
      data.payments.where((payment) => payment.orderId == orderId).toList()
        ..sort((a, b) => b.paidAt.compareTo(a.paidAt));

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static List<List<String>> _parseCsvRows(String raw) {
    final text = raw.startsWith('\uFEFF') ? raw.substring(1) : raw;
    final rows = <List<String>>[];
    final row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var index = 0; index < text.length; index++) {
      final character = text[index];
      if (character == '"') {
        if (quoted && index + 1 < text.length && text[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character == ',' && !quoted) {
        row.add(field.toString());
        field.clear();
      } else if ((character == '\n' || character == '\r') && !quoted) {
        row.add(field.toString());
        field.clear();
        if (row.any((item) => item.isNotEmpty)) rows.add([...row]);
        row.clear();
        if (character == '\r' &&
            index + 1 < text.length &&
            text[index + 1] == '\n') {
          index++;
        }
      } else {
        field.write(character);
      }
    }
    if (field.length > 0 || row.isNotEmpty) {
      row.add(field.toString());
      if (row.any((item) => item.isNotEmpty)) rows.add([...row]);
    }
    return rows;
  }

  static String _csvValue(
    List<String> row,
    Map<String, int> indexes,
    String header,
  ) {
    final index = indexes[header];
    if (index == null || index >= row.length) return '';
    return row[index].trim();
  }

  static Customer? _findCsvCustomer(
    List<Customer> customers,
    String name,
    String phone,
  ) {
    final normalizedName = name.trim();
    final normalizedPhone = phone.trim();
    for (final customer in customers) {
      if (normalizedPhone.isNotEmpty &&
          customer.phone.trim() == normalizedPhone) {
        return customer;
      }
      if (normalizedPhone.isEmpty &&
          normalizedName.isNotEmpty &&
          customer.name.trim() == normalizedName) {
        return customer;
      }
      if (normalizedPhone.isNotEmpty &&
          normalizedName.isNotEmpty &&
          customer.name.trim() == normalizedName &&
          customer.phone.trim() == normalizedPhone) {
        return customer;
      }
    }
    return null;
  }

  static List<WorkOrderItem> _itemsFromCsv(
    String raw,
    double total,
    String locale,
  ) {
    final items = <WorkOrderItem>[];
    for (final part in raw.split('；')) {
      final value = part.trim();
      if (value.isEmpty) continue;
      final match = RegExp(
        r'^(.+?)\s+(\d+(?:\.\d+)?)(\S*)\s+¥?([0-9]+(?:\.[0-9]+)?)$',
      ).firstMatch(value);
      if (match == null) {
        items.add(WorkOrderItem(
          id: idFor('item'),
          name: value,
          type: ServiceItemType.other,
          quantity: 1,
          unit: _csvText(locale, '项'),
          unitPrice: 0,
        ));
        continue;
      }
      final quantity = numberValue(match.group(2), 1);
      final amount = numberValue(match.group(4));
      items.add(WorkOrderItem(
        id: idFor('item'),
        name: match.group(1)!.trim(),
        type: ServiceItemType.other,
        quantity: quantity,
        unit: match.group(3)!.trim().isEmpty
            ? _csvText(locale, '项')
            : match.group(3)!.trim(),
        unitPrice: quantity <= 0 ? amount : money(amount / quantity),
      ));
    }
    if (items.isEmpty && total > 0) {
      items.add(WorkOrderItem(
        id: idFor('item'),
        name: _csvText(locale, 'CSV 导入金额'),
        type: ServiceItemType.other,
        quantity: 1,
        unit: _csvText(locale, '项'),
        unitPrice: money(total),
      ));
    }
    return items;
  }

  static List<WorkOrderCost> _costsFromCsv(
    String details,
    double total,
    List<CostType> costTypes,
    String locale,
  ) {
    final costs = <WorkOrderCost>[];
    for (final part in details.split('；')) {
      final value = part.trim();
      if (value.isEmpty) continue;
      final match = RegExp(
        r'^(.+?)\s+¥?([0-9]+(?:\.[0-9]+)?)(?:\s+(.*))?$',
      ).firstMatch(value);
      if (match == null) continue;
      final typeName = match.group(1)!.trim();
      final type = costTypes.cast<CostType?>().firstWhere(
            (item) =>
                item!.name.toLowerCase() == typeName.toLowerCase() ||
                _csvText(locale, item.name).toLowerCase() ==
                    typeName.toLowerCase() ||
                _csvText('en', item.name).toLowerCase() ==
                    typeName.toLowerCase(),
            orElse: () => null,
          );
      costs.add(
        WorkOrderCost(
          id: idFor('cost'),
          typeId: type?.id ?? 'csv:$typeName',
          typeName: typeName,
          amount: money(numberValue(match.group(2))),
          note: match.group(3)?.trim() ?? '',
        ),
      );
    }
    if (costs.isEmpty && total > 0) {
      final fallback = costTypes.firstWhere(
        (item) => item.id == 'other',
        orElse: () => CostType(
          id: 'other',
          name: _csvText(locale, '其他'),
          enabled: true,
        ),
      );
      costs.add(
        WorkOrderCost(
          id: idFor('cost'),
          typeId: fallback.id,
          typeName: _csvText(locale, 'CSV 导入成本'),
          amount: money(total),
        ),
      );
    }
    return costs;
  }

  static WorkOrderStatus _statusFromCsv(String raw) {
    final value = raw.trim();
    for (final status in WorkOrderStatus.values) {
      if (status.name == value ||
          status.label == value ||
          _csvText('en', status.label) == value) {
        return status;
      }
    }
    return WorkOrderStatus.draft;
  }

  static List<PaymentRecord> _paymentsFromCsv(String raw, String orderId) {
    final payments = <PaymentRecord>[];
    for (final part in raw.split('；')) {
      final value = part.trim();
      if (value.isEmpty) continue;
      final match = RegExp(
        r'^(\S+)\s+([0-9]+(?:\.[0-9]+)?)\s+(\S+)(?:\s+(.*))?$',
      ).firstMatch(value);
      if (match == null) continue;
      final paidAt = dateValue(match.group(3)) ?? DateTime.now();
      payments.add(PaymentRecord(
        id: idFor('pay'),
        orderId: orderId,
        amount: money(numberValue(match.group(2))),
        method: _paymentMethodFromCsv(match.group(1)!),
        note: match.group(4)?.trim() ?? '',
        paidAt: paidAt,
      ));
    }
    return payments;
  }

  static PaymentMethod _paymentMethodFromCsv(String raw) {
    for (final method in PaymentMethod.values) {
      if (method.name == raw ||
          method.label == raw ||
          _csvText('en', method.label) == raw) {
        return method;
      }
    }
    return PaymentMethod.other;
  }
}
