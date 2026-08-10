import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/services/file_selection_service.dart';
import '../core/services/share_service.dart';
import '../core/theme/app_theme.dart';
import '../features/work_orders/application/work_order_controller.dart';
import '../features/work_orders/presentation/work_order_page.dart';
import '../features/work_orders/services/document_service.dart';
import '../l10n/app_localizations.dart';

class BaseApp extends StatefulWidget {
  const BaseApp({
    required this.controller,
    this.fileSelectionService,
    this.shareService,
    this.documentService,
    super.key,
  });

  final WorkOrderController controller;
  final FileSelectionService? fileSelectionService;
  final ShareService? shareService;
  final DocumentService? documentService;

  @override
  State<BaseApp> createState() => _BaseAppState();
}

class _BaseAppState extends State<BaseApp> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: widget.controller.data.settings.darkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: WorkOrderPage(
            controller: widget.controller,
            fileSelectionService: widget.fileSelectionService,
            shareService: widget.shareService,
            documentService: widget.documentService,
          ),
        ),
      );
}
