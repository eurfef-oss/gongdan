import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/services/file_selection_service.dart';
import '../../../core/services/share_service.dart';
import '../../../core/widgets/app_back_bar.dart';
import '../../../core/widgets/app_top_notice.dart';
import '../../../core/widgets/contact_actions.dart';
import '../application/work_order_controller.dart';
import '../domain/entities/work_order.dart';
import '../services/document_export.dart';
import '../services/document_service.dart';
part 'dialogs/dialog_helpers.dart';
part 'dialogs/shared_dialog_components.dart';
part 'dialogs/order_editor_dialog.dart';
part 'dialogs/customer_editor_dialog.dart';
part 'dialogs/template_editor_dialog.dart';
part 'dialogs/payment_dialog.dart';
part 'dialogs/order_detail_dialog.dart';
part 'dialogs/signature_dialog.dart';
part 'dialogs/document_preview_dialog.dart';
