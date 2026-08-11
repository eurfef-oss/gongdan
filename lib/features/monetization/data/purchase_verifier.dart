import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/entities/entitlement.dart';
import 'billing_gateway.dart';

const entitlementServerUrl = String.fromEnvironment(
  'ENTITLEMENT_SERVER_URL',
  defaultValue: '',
);
const entitlementPublicKeyBase64 = String.fromEnvironment(
  'ENTITLEMENT_PUBLIC_KEY_BASE64',
  defaultValue: '',
);

List<int> decodeBase64Url(String value) {
  final normalized = value.replaceAll('-', '+').replaceAll('_', '/');
  final padding = (4 - normalized.length % 4) % 4;
  return base64.decode('$normalized${'=' * padding}');
}

Future<bool> verifyEntitlementSignature({
  required String payload,
  required String? signature,
  required String publicKeyBase64,
  required bool allowUnsigned,
}) async {
  if (signature == null || signature.isEmpty) return allowUnsigned;
  if (publicKeyBase64.trim().isEmpty) return allowUnsigned;
  try {
    final publicKey = SimplePublicKey(
      decodeBase64Url(publicKeyBase64),
      type: KeyPairType.ed25519,
    );
    final signed = Signature(
      decodeBase64Url(signature),
      publicKey: publicKey,
    );
    return await Ed25519().verify(
      decodeBase64Url(payload),
      signature: signed,
    );
  } catch (_) {
    return false;
  }
}

Future<Entitlement?> decodeStoredEntitlement(
  Map<String, Object?> json, {
  String publicKeyBase64 = entitlementPublicKeyBase64,
  bool allowUnsigned = kDebugMode,
}) async {
  final payload = json['payload']?.toString();
  final signature = json['signature']?.toString();
  if (payload != null && payload.isNotEmpty) {
    final valid = await verifyEntitlementSignature(
      payload: payload,
      signature: signature,
      publicKeyBase64: publicKeyBase64,
      allowUnsigned: allowUnsigned,
    );
    if (!valid) return null;
    try {
      final decoded = jsonDecode(utf8.decode(decodeBase64Url(payload)));
      if (decoded is! Map) return null;
      return Entitlement.fromJson(
        Map<String, Object?>.from(decoded),
        payload: payload,
        signature: signature,
      );
    } catch (_) {
      return null;
    }
  }
  if (!allowUnsigned) return null;
  return Entitlement.fromJson(json, payload: payload, signature: signature);
}

abstract interface class PurchaseVerifier {
  Future<Entitlement> verify(PurchaseUpdate update);
}

class PurchaseVerificationException implements Exception {
  const PurchaseVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RemotePurchaseVerifier implements PurchaseVerifier {
  RemotePurchaseVerifier({
    this.baseUrl = entitlementServerUrl,
    http.Client? client,
    this.publicKeyBase64 = entitlementPublicKeyBase64,
    this.allowUnsigned = kDebugMode,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final String publicKeyBase64;
  final bool allowUnsigned;

  @override
  Future<Entitlement> verify(PurchaseUpdate update) async {
    if (baseUrl.trim().isEmpty) {
      throw const PurchaseVerificationException('授权服务地址尚未配置');
    }

    final uri = Uri.parse(
        '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/v1/purchases/verify');
    final response = await _client
        .post(
          uri,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'platform': _platformName,
            'productId': update.productId,
            'purchaseId': update.purchaseId,
            'appId': _appId,
            'verificationData': {
              'source': update.verificationSource,
              'local': update.localVerificationData,
              'server': update.serverVerificationData,
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    Map<String, Object?> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('response is not an object');
      }
      body = Map<String, Object?>.from(decoded);
    } catch (_) {
      throw const PurchaseVerificationException('授权服务返回了无效响应');
    }
    if (response.statusCode != 200) {
      throw PurchaseVerificationException(
        body['message']?.toString() ?? '购买验证失败（${response.statusCode}）',
      );
    }

    final payload = body['payload']?.toString();
    final signature = body['signature']?.toString();
    Map<String, Object?> entitlementJson;
    if (payload != null && payload.isNotEmpty) {
      final valid = await _verifyPayload(payload, signature);
      if (!valid) {
        throw const PurchaseVerificationException('专业版授权签名无效');
      }
      final decodedPayload = jsonDecode(utf8.decode(decodeBase64Url(payload)));
      if (decodedPayload is! Map) {
        throw const PurchaseVerificationException('授权内容格式无效');
      }
      entitlementJson = Map<String, Object?>.from(decodedPayload);
    } else {
      if (!allowUnsigned) {
        throw const PurchaseVerificationException('授权服务未返回签名');
      }
      final value = body['entitlement'];
      if (value is! Map) {
        throw const PurchaseVerificationException('授权内容缺失');
      }
      entitlementJson = Map<String, Object?>.from(value);
    }

    final entitlement = Entitlement.fromJson(
      entitlementJson,
      payload: payload,
      signature: signature,
    );
    if (!entitlement.isPro || entitlement.productId != proProductId) {
      throw const PurchaseVerificationException('服务端没有授予专业版授权');
    }
    return entitlement;
  }

  Future<bool> _verifyPayload(String payload, String? signature) async {
    return verifyEntitlementSignature(
      payload: payload,
      signature: signature,
      publicKeyBase64: publicKeyBase64,
      allowUnsigned: allowUnsigned,
    );
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'unsupported';
    }
  }

  String get _appId => const String.fromEnvironment(
        'APP_IDENTIFIER',
        defaultValue: 'com.example.repairworkorderassistant',
      );
}

class NoopPurchaseVerifier implements PurchaseVerifier {
  @override
  Future<Entitlement> verify(PurchaseUpdate update) =>
      Future<Entitlement>.error(
        const PurchaseVerificationException('授权服务不可用'),
      );
}
