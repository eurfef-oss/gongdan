import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app/base_app.dart';
import 'core/services/file_selection_service.dart';
import 'core/services/share_service.dart';
import 'features/monetization/application/entitlement_controller.dart';
import 'features/monetization/data/billing_gateway.dart';
import 'features/monetization/data/local_entitlement_repository.dart';
import 'features/monetization/data/purchase_verifier.dart';
import 'features/work_orders/application/work_order_controller.dart';
import 'features/work_orders/data/local_work_order_repository.dart';
import 'features/work_orders/services/document_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  const testPurchaseMode = kDebugMode &&
      bool.fromEnvironment('ENABLE_LOCAL_TEST_PURCHASE', defaultValue: false);
  final controller = WorkOrderController(LocalWorkOrderRepository());
  final fileSelectionService = PlatformFileSelectionService();
  final shareService = const PlatformShareService();
  final documentService = PlatformDocumentService(
    fileSelectionService: fileSelectionService,
    shareService: shareService,
  );
  final entitlementController = EntitlementController(
    repository: LocalEntitlementRepository(),
    billingGateway: InAppPurchaseBillingGateway(),
    verifier: RemotePurchaseVerifier(),
    testPurchaseMode: testPurchaseMode,
  );
  runApp(
    BaseApp(
      controller: controller,
      entitlementController: entitlementController,
      fileSelectionService: fileSelectionService,
      shareService: shareService,
      documentService: documentService,
    ),
  );
  unawaited(controller.initialize());
  unawaited(entitlementController.initialize());
}
