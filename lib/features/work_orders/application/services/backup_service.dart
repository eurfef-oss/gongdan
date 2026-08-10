import 'dart:convert';

import '../../domain/entities/work_order.dart';

class BackupService {
  RepairAppData decodeJson(String raw) {
    final value = jsonDecode(raw);
    if (value is! Map || !isSupportedShape(value)) {
      throw const FormatException('unsupported work order backup');
    }
    return RepairAppData.fromJson(Map<String, Object?>.from(value));
  }

  bool isSupportedJson(String raw) {
    try {
      decodeJson(raw);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool isSupportedShape(Map value) {
    const requiredKeys = [
      'customers',
      'serviceItems',
      'workOrders',
      'payments',
      'settings',
    ];
    if (!requiredKeys.every(value.containsKey)) return false;
    final version = value['version'];
    final parsedVersion =
        version == null ? 1 : int.tryParse(version.toString());
    if (parsedVersion == null ||
        parsedVersion < 1 ||
        parsedVersion > currentWorkOrderDataVersion) {
      return false;
    }
    for (final key in requiredKeys) {
      final field = value[key];
      if (key == 'settings') {
        if (field is! Map) return false;
      } else if (field is! List) {
        return false;
      }
    }
    return true;
  }
}
