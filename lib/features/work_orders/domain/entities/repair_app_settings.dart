part of 'work_order.dart';

class RepairAppSettings {
  const RepairAppSettings({
    this.shopName = '',
    this.ownerName = '',
    this.phone = '',
    this.address = '',
    this.defaultNote = '',
    this.darkMode = false,
    this.languageCode = 'zh',
    this.hasSeenWelcome = false,
    this.customServiceItemTypes = const [],
    this.deletedBuiltInServiceItemTypes = const [],
    this.dashboardCardOrder = const [],
    this.dashboardHiddenCards = const [],
    this.workOrderFieldOrder = const [],
    this.workOrderHiddenFields = const [],
    this.costTypes = defaultCostTypes,
  });

  final String shopName;
  final String ownerName;
  final String phone;
  final String address;
  final String defaultNote;
  final bool darkMode;
  final String languageCode;
  final bool hasSeenWelcome;
  final List<String> customServiceItemTypes;
  final List<String> deletedBuiltInServiceItemTypes;
  final List<String> dashboardCardOrder;
  final List<String> dashboardHiddenCards;
  final List<String> workOrderFieldOrder;
  final List<String> workOrderHiddenFields;
  final List<CostType> costTypes;

  RepairAppSettings copyWith({
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
    String? defaultNote,
    bool? darkMode,
    String? languageCode,
    bool? hasSeenWelcome,
    List<String>? customServiceItemTypes,
    List<String>? deletedBuiltInServiceItemTypes,
    List<String>? dashboardCardOrder,
    List<String>? dashboardHiddenCards,
    List<String>? workOrderFieldOrder,
    List<String>? workOrderHiddenFields,
    List<CostType>? costTypes,
  }) =>
      RepairAppSettings(
        shopName: shopName ?? this.shopName,
        ownerName: ownerName ?? this.ownerName,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        defaultNote: defaultNote ?? this.defaultNote,
        darkMode: darkMode ?? this.darkMode,
        languageCode: languageCode ?? this.languageCode,
        hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
        customServiceItemTypes:
            customServiceItemTypes ?? this.customServiceItemTypes,
        deletedBuiltInServiceItemTypes: deletedBuiltInServiceItemTypes ??
            this.deletedBuiltInServiceItemTypes,
        dashboardCardOrder: dashboardCardOrder ?? this.dashboardCardOrder,
        dashboardHiddenCards: dashboardHiddenCards ?? this.dashboardHiddenCards,
        workOrderFieldOrder: workOrderFieldOrder ?? this.workOrderFieldOrder,
        workOrderHiddenFields:
            workOrderHiddenFields ?? this.workOrderHiddenFields,
        costTypes: costTypes ?? this.costTypes,
      );

  Map<String, Object?> toJson() => {
        'shopName': shopName,
        'ownerName': ownerName,
        'phone': phone,
        'address': address,
        'defaultNote': defaultNote,
        'darkMode': darkMode,
        'languageCode': languageCode,
        'hasSeenWelcome': hasSeenWelcome,
        'customServiceItemTypes': customServiceItemTypes,
        'deletedBuiltInServiceItemTypes': deletedBuiltInServiceItemTypes,
        'dashboardCardOrder': dashboardCardOrder,
        'dashboardHiddenCards': dashboardHiddenCards,
        'workOrderFieldOrder': workOrderFieldOrder,
        'workOrderHiddenFields': workOrderHiddenFields,
        'costTypes': costTypes.map((item) => item.toJson()).toList(),
      };

  factory RepairAppSettings.fromJson(Map<String, Object?> json) =>
      RepairAppSettings(
        shopName: json['shopName']?.toString() ?? '',
        ownerName: json['ownerName']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        defaultNote: json['defaultNote']?.toString() ?? '',
        darkMode: json['darkMode'] == true,
        languageCode: json['languageCode']?.toString() == 'en' ? 'en' : 'zh',
        hasSeenWelcome: json['hasSeenWelcome'] == true,
        customServiceItemTypes: _stringList(json['customServiceItemTypes']),
        deletedBuiltInServiceItemTypes:
            _stringList(json['deletedBuiltInServiceItemTypes']),
        dashboardCardOrder: _stringList(json['dashboardCardOrder']),
        dashboardHiddenCards: _stringList(json['dashboardHiddenCards']),
        workOrderFieldOrder: _stringList(json['workOrderFieldOrder']),
        workOrderHiddenFields: _stringList(json['workOrderHiddenFields']),
        costTypes: _costTypes(json['costTypes']),
      );
}

List<CostType> _costTypes(Object? value) {
  if (value is! List) return defaultCostTypes;
  return value
      .whereType<Map>()
      .map((item) => CostType.fromJson(Map<String, Object?>.from(item)))
      .where((item) => item.id.trim().isNotEmpty && item.name.trim().isNotEmpty)
      .toList();
}

List<String> _stringList(Object? value) => (value as List? ?? const [])
    .map((item) => item.toString().trim())
    .where((item) => item.isNotEmpty)
    .toSet()
    .toList();
