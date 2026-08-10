import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app/base_app.dart';
import 'core/services/file_selection_service.dart';
import 'core/services/share_service.dart';
import 'features/work_orders/application/work_order_controller.dart';
import 'features/work_orders/data/local_work_order_repository.dart';
import 'features/work_orders/services/document_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = WorkOrderController(LocalWorkOrderRepository());
  final fileSelectionService = PlatformFileSelectionService();
  final shareService = const PlatformShareService();
  final documentService = PlatformDocumentService(
    fileSelectionService: fileSelectionService,
    shareService: shareService,
  );
  runApp(
    BaseApp(
      controller: controller,
      fileSelectionService: fileSelectionService,
      shareService: shareService,
      documentService: documentService,
    ),
  );
  unawaited(controller.initialize());
}
