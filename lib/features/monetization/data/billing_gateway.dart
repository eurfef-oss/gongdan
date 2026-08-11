import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/entities/entitlement.dart';

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });

  final String id;
  final String title;
  final String description;
  final String price;
}

class PurchaseUpdate {
  const PurchaseUpdate({
    required this.eventId,
    required this.productId,
    required this.status,
    required this.purchaseId,
    required this.localVerificationData,
    required this.serverVerificationData,
    required this.verificationSource,
    this.transactionDate,
    this.errorCode,
    this.errorMessage,
    this.pendingCompletePurchase = false,
  });

  final String eventId;
  final String productId;
  final PurchaseStatus status;
  final String? purchaseId;
  final String localVerificationData;
  final String serverVerificationData;
  final String verificationSource;
  final String? transactionDate;
  final String? errorCode;
  final String? errorMessage;
  final bool pendingCompletePurchase;
}

abstract interface class BillingGateway {
  Stream<PurchaseUpdate> get purchaseUpdates;

  Future<bool> isAvailable();

  Future<StoreProduct?> loadProduct();

  Future<bool> buyNonConsumable();

  Future<void> restorePurchases();

  Future<void> complete(PurchaseUpdate update);

  void dispose();
}

class BillingException implements Exception {
  const BillingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InAppPurchaseBillingGateway implements BillingGateway {
  InAppPurchaseBillingGateway({InAppPurchase? store})
      : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;
  final Map<String, PurchaseDetails> _pendingPurchases = {};
  var _eventSequence = 0;
  ProductDetails? _product;

  @override
  Stream<PurchaseUpdate> get purchaseUpdates {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return const Stream.empty();
    }
    try {
      return _store.purchaseStream.asyncExpand(
        (purchases) => Stream<PurchaseUpdate>.fromIterable(
          purchases.map(_mapPurchase),
        ),
      );
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Future<bool> isAvailable() => _store.isAvailable();

  @override
  Future<StoreProduct?> loadProduct() async {
    final response = await _store.queryProductDetails({proProductId});
    if (response.error != null) {
      throw BillingException(response.error!.message);
    }
    if (response.productDetails.isEmpty) return null;
    _product = response.productDetails.firstWhere(
      (product) => product.id == proProductId,
      orElse: () => response.productDetails.first,
    );
    return StoreProduct(
      id: _product!.id,
      title: _product!.title,
      description: _product!.description,
      price: _product!.price,
    );
  }

  @override
  Future<bool> buyNonConsumable() async {
    final product = _product;
    if (product == null) {
      throw const BillingException('专业版商品暂不可用');
    }
    return _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  @override
  Future<void> restorePurchases() => _store.restorePurchases();

  @override
  Future<void> complete(PurchaseUpdate update) async {
    final purchase = _pendingPurchases.remove(update.eventId);
    if (purchase == null || !purchase.pendingCompletePurchase) return;
    await _store.completePurchase(purchase);
  }

  @override
  void dispose() => _pendingPurchases.clear();

  PurchaseUpdate _mapPurchase(PurchaseDetails purchase) {
    final eventId = 'purchase-${_eventSequence++}';
    _pendingPurchases[eventId] = purchase;
    return PurchaseUpdate(
      eventId: eventId,
      productId: purchase.productID,
      status: purchase.status,
      purchaseId: purchase.purchaseID,
      localVerificationData: purchase.verificationData.localVerificationData,
      serverVerificationData: purchase.verificationData.serverVerificationData,
      verificationSource: purchase.verificationData.source,
      transactionDate: purchase.transactionDate,
      errorCode: purchase.error?.code,
      errorMessage: purchase.error?.message,
      pendingCompletePurchase: purchase.pendingCompletePurchase,
    );
  }
}

class NoopBillingGateway implements BillingGateway {
  @override
  Stream<PurchaseUpdate> get purchaseUpdates => const Stream.empty();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<StoreProduct?> loadProduct() async => null;

  @override
  Future<bool> buyNonConsumable() async => false;

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> complete(PurchaseUpdate update) async {}

  @override
  void dispose() {}
}
