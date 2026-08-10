import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/file_selection_service.dart';
import '../../../core/services/share_service.dart';
import '../../../core/widgets/app_back_bar.dart';
import '../../../core/widgets/app_top_notice.dart';
import '../application/work_order_controller.dart';
import '../domain/entities/work_order.dart';
import '../services/document_service.dart';
import 'work_order_dialogs.dart';
part 'shared/presentation_helpers.dart';
part 'shell/work_order_shell.dart';
part 'shared/work_order_components.dart';
part 'dashboard/dashboard_page.dart';
part 'orders/orders_page.dart';
part 'customers/customers_page.dart';
part 'templates/templates_page.dart';
part 'statistics/statistics_page.dart';
part 'settings/settings_page.dart';
