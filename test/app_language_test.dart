import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:repair_work_order_assistant/core/localization/app_language.dart';

void main() {
  test('uses Chinese for Chinese system locales', () {
    expect(appLanguageCodeForLocale(const Locale('zh', 'CN')), 'zh');
    expect(appLanguageCodeForLocale(const Locale('zh', 'TW')), 'zh');
  });

  test('falls back to English for non-Chinese system locales', () {
    expect(appLanguageCodeForLocale(const Locale('en', 'US')), 'en');
    expect(appLanguageCodeForLocale(const Locale('ja', 'JP')), 'en');
  });

  test('uses yuan for Chinese and dollars for other system locales', () {
    expect(appCurrencySymbolForLocale(const Locale('zh', 'CN')), '¥');
    expect(appCurrencySymbolForLocale(const Locale('en', 'US')), r'$');
    expect(appCurrencySymbolForLocale(const Locale('ja', 'JP')), r'$');
  });
}
