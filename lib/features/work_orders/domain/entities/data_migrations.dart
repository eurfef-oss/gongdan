part of 'work_order.dart';

const currentWorkOrderDataVersion = 4;

Map<String, Object?> migrateWorkOrderData(Map<String, Object?> input) {
  var version = _dataVersion(input['version']);
  if (version > currentWorkOrderDataVersion) {
    throw FormatException(
      'unsupported work order data version: $version',
    );
  }

  var migrated = _cloneDataMap(input);
  if (version < 2) {
    migrated = _migrateV1ToV2(migrated);
    version = 2;
  }
  if (version < 3) {
    migrated = _migrateV2ToV3(migrated);
    version = 3;
  }
  if (version < 4) {
    migrated = _migrateV3ToV4(migrated);
  }
  migrated['version'] = currentWorkOrderDataVersion;
  return migrated;
}

int _dataVersion(Object? value) {
  if (value == null) return 1;
  final version = int.tryParse(value.toString());
  if (version == null || version < 1) {
    throw const FormatException('invalid work order data version');
  }
  return version;
}

Map<String, Object?> _migrateV1ToV2(Map<String, Object?> input) {
  final migrated = _cloneDataMap(input);
  migrated['customers'] = _listOrEmpty(migrated['customers']);
  migrated['serviceItems'] = _listOrEmpty(migrated['serviceItems']);
  migrated['workOrders'] = _listOrEmpty(migrated['workOrders']);
  migrated['payments'] = _listOrEmpty(migrated['payments']);

  final settings = _mapOrEmpty(migrated['settings']);
  settings['customServiceItemTypes'] ??= <Object?>[];
  settings['deletedBuiltInServiceItemTypes'] ??= <Object?>[];
  settings['dashboardCardOrder'] ??= <Object?>[];
  settings['dashboardHiddenCards'] ??= <Object?>[];
  migrated['settings'] = settings;

  migrated['workOrders'] = _listOrEmpty(migrated['workOrders']).map((value) {
    final order = _mapOrEmpty(value);
    order['items'] = _listOrEmpty(order['items']);
    order['attachments'] ??= <Object?>[];
    order['paid'] ??= order['receivedAmount'] ?? 0;
    return order;
  }).toList();
  migrated['version'] = 2;
  return migrated;
}

Map<String, Object?> _migrateV2ToV3(Map<String, Object?> input) {
  final migrated = _cloneDataMap(input);
  final settings = _mapOrEmpty(migrated['settings']);
  settings['dashboardCardOrder'] = _cleanStringList(
    settings['dashboardCardOrder'],
  );
  settings['dashboardHiddenCards'] = _cleanStringList(
    settings['dashboardHiddenCards'],
  );
  settings['customServiceItemTypes'] = _cleanStringList(
    settings['customServiceItemTypes'],
  );
  settings['deletedBuiltInServiceItemTypes'] = _cleanStringList(
    settings['deletedBuiltInServiceItemTypes'],
  );
  migrated['settings'] = settings;
  migrated['payments'] = _listOrEmpty(migrated['payments']);
  migrated['version'] = 3;
  return migrated;
}

Map<String, Object?> _migrateV3ToV4(Map<String, Object?> input) {
  final migrated = _cloneDataMap(input);
  final settings = _mapOrEmpty(migrated['settings']);
  settings['costTypes'] ??=
      defaultCostTypes.map((item) => item.toJson()).toList();
  migrated['settings'] = settings;
  migrated['workOrders'] = _listOrEmpty(migrated['workOrders']).map((value) {
    final order = _mapOrEmpty(value);
    order['internalCosts'] = _listOrEmpty(order['internalCosts']);
    return order;
  }).toList();
  migrated['version'] = 4;
  return migrated;
}

Map<String, Object?> _cloneDataMap(Map source) => {
      for (final entry in source.entries)
        entry.key.toString(): _cloneDataValue(entry.value),
    };

Object? _cloneDataValue(Object? value) {
  if (value is Map) return _cloneDataMap(value);
  if (value is List) return value.map(_cloneDataValue).toList();
  return value;
}

Map<String, Object?> _mapOrEmpty(Object? value) =>
    value is Map ? _cloneDataMap(value) : <String, Object?>{};

List<Object?> _listOrEmpty(Object? value) =>
    value is List ? value.map(_cloneDataValue).toList() : <Object?>[];

List<String> _cleanStringList(Object? value) => (value as List? ?? const [])
    .map((item) => item.toString().trim())
    .where((item) => item.isNotEmpty)
    .toSet()
    .toList();
