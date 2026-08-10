import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_top_notice.dart';

Future<void> copyTextWithNotice(
  BuildContext context,
  String value, {
  String label = '内容',
}) async {
  final text = value.trim();
  if (text.isEmpty) {
    showTopNotice(context, '没有可复制的$label。', error: true);
    return;
  }
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) showTopNotice(context, '已复制$label。');
}

Future<void> dialPhoneWithNotice(BuildContext context, String value) async {
  final phone = value.trim();
  if (phone.isEmpty) {
    showTopNotice(context, '该客户没有填写电话号码。', error: true);
    return;
  }
  final compact = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final uri = Uri(scheme: 'tel', path: compact.isEmpty ? phone : compact);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showTopNotice(context, '当前设备无法拨打这个电话号码。', error: true);
    }
  } catch (_) {
    if (context.mounted) {
      showTopNotice(context, '当前设备无法拨打这个电话号码。', error: true);
    }
  }
}
