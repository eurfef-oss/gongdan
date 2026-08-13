import 'dart:convert';

const proProductId = 'repair_pro_lifetime';
const freeWorkOrderLimit = 10;
const freeCustomerLimit = 10;

enum EntitlementState {
  free,
  purchasing,
  pending,
  active,
  revoked,
  error,
}

enum ProFeature {
  unlimitedOrders('unlimited_orders'),
  unlimitedCustomers('unlimited_customers'),
  customTemplates('custom_templates'),
  statistics('statistics'),
  internalCosts('internal_costs'),
  documentExport('document_export'),
  customerSignature('customer_signature'),
  photoAttachments('photo_attachments');

  const ProFeature(this.key);

  final String key;

  bool get availableWithoutPro =>
      this == ProFeature.documentExport ||
      this == ProFeature.customerSignature ||
      this == ProFeature.photoAttachments;
}

class Entitlement {
  const Entitlement({
    required this.state,
    required this.plan,
    required this.features,
    this.productId,
    this.purchaseId,
    this.platform,
    this.activatedAt,
    this.verifiedAt,
    this.expiresAt,
    this.payload,
    this.signature,
  });

  factory Entitlement.free({EntitlementState state = EntitlementState.free}) =>
      Entitlement(
        state: state,
        plan: 'free',
        features: const [],
      );

  /// In-memory entitlement used only by the internal Release APK preview.
  /// It is deliberately not a purchase record and must never be persisted.
  factory Entitlement.releasePreview() => Entitlement(
        state: EntitlementState.active,
        plan: 'pro',
        features: ProFeature.values
            .map((feature) => feature.key)
            .toList(growable: false),
        platform: 'release-apk-preview',
      );

  factory Entitlement.fromJson(
    Map<String, Object?> json, {
    String? payload,
    String? signature,
  }) {
    final state = EntitlementState.values.firstWhere(
      (value) => value.name == json['state']?.toString(),
      orElse: () => EntitlementState.free,
    );
    final features = (json['features'] as List? ?? const [])
        .map((value) => value.toString())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return Entitlement(
      state: state,
      plan: json['plan']?.toString() ?? 'free',
      features: features,
      productId: _stringOrNull(json['productId']),
      purchaseId: _stringOrNull(json['purchaseId']),
      platform: _stringOrNull(json['platform']),
      activatedAt: _dateOrNull(json['activatedAtUtc']),
      verifiedAt: _dateOrNull(json['verifiedAtUtc']),
      expiresAt: _dateOrNull(json['expiresAtUtc']),
      payload: payload ?? _stringOrNull(json['payload']),
      signature: signature ?? _stringOrNull(json['signature']),
    );
  }

  final EntitlementState state;
  final String plan;
  final List<String> features;
  final String? productId;
  final String? purchaseId;
  final String? platform;
  final DateTime? activatedAt;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;
  final String? payload;
  final String? signature;

  bool get isPro => state == EntitlementState.active && plan == 'pro';

  bool canUse(ProFeature feature) {
    if (feature.availableWithoutPro) return true;
    return isPro && features.contains(feature.key);
  }

  Entitlement copyWith({
    EntitlementState? state,
    String? plan,
    List<String>? features,
    String? productId,
    String? purchaseId,
    String? platform,
    DateTime? activatedAt,
    DateTime? verifiedAt,
    DateTime? expiresAt,
    String? payload,
    String? signature,
  }) =>
      Entitlement(
        state: state ?? this.state,
        plan: plan ?? this.plan,
        features: features ?? this.features,
        productId: productId ?? this.productId,
        purchaseId: purchaseId ?? this.purchaseId,
        platform: platform ?? this.platform,
        activatedAt: activatedAt ?? this.activatedAt,
        verifiedAt: verifiedAt ?? this.verifiedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        payload: payload ?? this.payload,
        signature: signature ?? this.signature,
      );

  Map<String, Object?> toJson() => {
        'state': state.name,
        'plan': plan,
        'features': features,
        'productId': productId,
        'purchaseId': purchaseId,
        'platform': platform,
        'activatedAtUtc': activatedAt?.toUtc().toIso8601String(),
        'verifiedAtUtc': verifiedAt?.toUtc().toIso8601String(),
        'expiresAtUtc': expiresAt?.toUtc().toIso8601String(),
        'payload': payload,
        'signature': signature,
      };

  String encode() => jsonEncode(toJson());

  static String? _stringOrNull(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _dateOrNull(Object? value) {
    final text = _stringOrNull(value);
    return text == null ? null : DateTime.tryParse(text)?.toUtc();
  }
}

class FeatureAccessService {
  const FeatureAccessService();

  bool canUse(Entitlement entitlement, ProFeature feature) =>
      entitlement.canUse(feature);

  bool canCreateOrder(Entitlement entitlement, int currentOrderCount) =>
      entitlement.isPro || currentOrderCount < freeWorkOrderLimit;

  bool canCreateCustomer(Entitlement entitlement, int currentCustomerCount) =>
      entitlement.isPro || currentCustomerCount < freeCustomerLimit;
}
