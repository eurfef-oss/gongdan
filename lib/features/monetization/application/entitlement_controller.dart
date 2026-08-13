import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/billing_gateway.dart';
import '../data/purchase_verifier.dart';
import '../domain/entities/entitlement.dart';
import '../domain/repositories/entitlement_repository.dart';

class EntitlementController extends ChangeNotifier {
  EntitlementController({
    required EntitlementRepository repository,
    required BillingGateway billingGateway,
    required PurchaseVerifier verifier,
    FeatureAccessService accessService = const FeatureAccessService(),
    bool testPurchaseMode = false,
    bool releaseProPreview = false,
  })  : _repository = repository,
        _billingGateway = billingGateway,
        _verifier = verifier,
        _accessService = accessService,
        _testPurchaseMode = testPurchaseMode,
        _releaseProPreview = releaseProPreview;

  factory EntitlementController.disabled() => EntitlementController(
        repository: _MemoryEntitlementRepository(),
        billingGateway: NoopBillingGateway(),
        verifier: NoopPurchaseVerifier(),
      );

  final EntitlementRepository _repository;
  final BillingGateway _billingGateway;
  final PurchaseVerifier _verifier;
  final FeatureAccessService _accessService;
  final bool _testPurchaseMode;
  final bool _releaseProPreview;
  StreamSubscription<PurchaseUpdate>? _purchaseSubscription;
  Timer? _purchaseLaunchTimer;

  static const _purchaseLaunchTimeout = Duration(seconds: 5);

  Entitlement _entitlement = Entitlement.free();
  StoreProduct? _product;
  bool _initialized = false;
  bool _storeAvailable = false;
  String? _errorMessage;

  Entitlement get entitlement => _entitlement;
  StoreProduct? get product => _product;
  bool get isInitialized => _initialized;
  bool get storeAvailable => _storeAvailable;
  String? get errorMessage => _errorMessage;
  bool get isPro => _entitlement.isPro;
  bool get isPreviewPro => _releaseProPreview;

  bool canUse(ProFeature feature) =>
      _accessService.canUse(_entitlement, feature);

  bool canCreateOrder(int currentOrderCount) =>
      _accessService.canCreateOrder(_entitlement, currentOrderCount);

  bool canCreateCustomer(int currentCustomerCount) =>
      _accessService.canCreateCustomer(_entitlement, currentCustomerCount);

  Future<void> initialize() async {
    if (_initialized) return;
    if (_releaseProPreview) {
      // The preview must remain entirely in memory. It intentionally does not
      // load or save a purchase, contact the store, or contact the verifier.
      _entitlement = Entitlement.releasePreview();
      _initialized = true;
      notifyListeners();
      return;
    }
    // Subscribe before awaiting storage or store queries so a pending platform
    // transaction delivered during app launch is not missed.
    _purchaseSubscription = _billingGateway.purchaseUpdates.listen(
      _handlePurchaseUpdate,
      onError: (Object error, StackTrace stackTrace) {
        _setError(error.toString());
      },
    );
    try {
      _entitlement = await _repository.load();
    } catch (_) {
      _entitlement = Entitlement.free();
    }
    _initialized = true;
    notifyListeners();

    if (_testPurchaseMode) {
      _storeAvailable = true;
      _product = const StoreProduct(
        id: proProductId,
        title: '专业版（测试）',
        description: '仅用于 Debug 构建测试',
        price: '测试模式',
      );
      notifyListeners();
      return;
    }

    try {
      _storeAvailable = await _billingGateway.isAvailable();
      if (_storeAvailable) {
        _product = await _billingGateway.loadProduct();
      }
    } catch (error) {
      _setError(error.toString());
    }
    notifyListeners();
  }

  Future<void> purchase() async {
    _clearError();
    if (_entitlement.isPro) return;
    if (!_initialized) await initialize();
    if (_testPurchaseMode) {
      await _activateLocalTestEntitlement();
      return;
    }
    if (!_storeAvailable) {
      _setError('应用商店当前不可用，请稍后重试');
      return;
    }
    try {
      _product ??= await _billingGateway.loadProduct();
      if (_product == null) {
        _setError('专业版商品尚未在当前商店配置');
        return;
      }
      _entitlement = Entitlement.free(state: EntitlementState.purchasing);
      notifyListeners();
      _startPurchaseLaunchTimeout();
      final launched = await _billingGateway.buyNonConsumable();
      if (!launched) {
        _clearPurchaseLaunchTimeout();
        _failPurchase('未能打开应用内购买页面');
      }
    } catch (error) {
      _clearPurchaseLaunchTimeout();
      _failPurchase(error.toString());
    }
  }

  Future<void> restorePurchases() async {
    _clearError();
    if (!_initialized) await initialize();
    if (_releaseProPreview) return;
    if (_testPurchaseMode) {
      await _activateLocalTestEntitlement();
      return;
    }
    if (!_storeAvailable) {
      _setError('恢复购买需要连接应用商店');
      return;
    }
    try {
      _entitlement = _entitlement.isPro
          ? _entitlement
          : Entitlement.free(state: EntitlementState.pending);
      notifyListeners();
      _startPurchaseLaunchTimeout();
      await _billingGateway.restorePurchases();
    } catch (error) {
      _setError(error.toString());
    }
  }

  Future<void> _handlePurchaseUpdate(PurchaseUpdate update) async {
    // Google Play can emit a synthetic canceled/error PurchaseDetails with an
    // empty product ID when the user closes the payment sheet. It is still the
    // active one-product purchase flow and must clear the loading state.
    final emptyProductCancellation = update.productId.isEmpty &&
        (update.status == PurchaseStatus.canceled ||
            update.status == PurchaseStatus.error) &&
        (_entitlement.state == EntitlementState.purchasing ||
            _entitlement.state == EntitlementState.pending);
    if (update.productId != proProductId && !emptyProductCancellation) return;

    switch (update.status) {
      case PurchaseStatus.pending:
        _entitlement = _entitlement.isPro
            ? _entitlement
            : Entitlement.free(state: EntitlementState.pending);
        notifyListeners();
        return;
      case PurchaseStatus.canceled:
        _clearPurchaseLaunchTimeout();
        if (!_entitlement.isPro) _entitlement = Entitlement.free();
        _setError('购买已取消');
        return;
      case PurchaseStatus.error:
        _clearPurchaseLaunchTimeout();
        if (!_entitlement.isPro) _entitlement = Entitlement.free();
        _setError(update.errorMessage ?? '购买失败，请稍后重试');
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        _entitlement = _entitlement.isPro
            ? _entitlement
            : Entitlement.free(state: EntitlementState.pending);
        notifyListeners();
        await _verifyAndComplete(update);
        return;
    }
  }

  void _startPurchaseLaunchTimeout() {
    _purchaseLaunchTimer?.cancel();
    _purchaseLaunchTimer = Timer(_purchaseLaunchTimeout, () {
      if (_entitlement.state != EntitlementState.purchasing &&
          _entitlement.state != EntitlementState.pending) {
        return;
      }
      _failPurchase('购买窗口未返回结果，请稍后重试');
    });
  }

  void _clearPurchaseLaunchTimeout() {
    _purchaseLaunchTimer?.cancel();
    _purchaseLaunchTimer = null;
  }

  void _failPurchase(String message) {
    if (!_entitlement.isPro) _entitlement = Entitlement.free();
    _setError(message);
  }

  Future<void> _verifyAndComplete(PurchaseUpdate update) async {
    try {
      final verified = await _verifier.verify(update);
      await _repository.save(verified);
      _entitlement = verified;
      _clearPurchaseLaunchTimeout();
      _clearError();
      notifyListeners();
      await _billingGateway.complete(update);
    } catch (error) {
      // Keep the transaction pending so a later retry can verify it. Do not
      // grant professional features merely because the store callback arrived.
      if (!_entitlement.isPro) {
        _entitlement = Entitlement.free(state: EntitlementState.pending);
      }
      _setError(error.toString());
    }
  }

  Future<void> _activateLocalTestEntitlement() async {
    final now = DateTime.now().toUtc();
    final entitlement = Entitlement(
      state: EntitlementState.active,
      plan: 'pro',
      features: ProFeature.values.map((feature) => feature.key).toList(),
      productId: proProductId,
      purchaseId: 'debug-local-test-purchase',
      platform: 'test',
      activatedAt: now,
      verifiedAt: now,
    );
    await _repository.save(entitlement);
    _entitlement = entitlement;
    _clearError();
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message.replaceFirst('Exception: ', '');
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _clearPurchaseLaunchTimeout();
    unawaited(_purchaseSubscription?.cancel());
    _billingGateway.dispose();
    super.dispose();
  }
}

class _MemoryEntitlementRepository implements EntitlementRepository {
  Entitlement _value = Entitlement.free();

  @override
  Future<Entitlement> load() async => _value;

  @override
  Future<void> save(Entitlement entitlement) async => _value = entitlement;

  @override
  Future<void> clear() async => _value = Entitlement.free();
}
