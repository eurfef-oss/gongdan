import 'dart:ui';

/// Maps the device's system locale to one of the app's supported languages.
///
/// Chinese regional locales all use Chinese. The app currently supports only
/// Chinese and English, so every other system locale falls back to English.
String appLanguageCodeForLocale(Locale locale) =>
    locale.languageCode.toLowerCase() == 'zh' ? 'zh' : 'en';

/// Returns the currency used for a brand-new app data store.
///
/// Chinese system locales use the yuan symbol. The app has no locale-specific
/// default for other supported or unknown locales, so they fall back to USD.
String appCurrencySymbolForLocale(Locale locale) =>
    locale.languageCode.toLowerCase() == 'zh' ? '¥' : r'$';
