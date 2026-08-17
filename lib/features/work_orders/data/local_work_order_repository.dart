import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/work_order.dart';
import '../domain/repositories/work_order_repository.dart';

class LocalWorkOrderRepository
    implements WorkOrderRepository, WorkOrderPersistenceStatus {
  LocalWorkOrderRepository({
    Future<Directory> Function()? directoryProvider,
    Future<SharedPreferences> Function()? preferencesProvider,
    File? dataFile,
    String defaultLanguageCode = 'zh',
    String initialCurrencySymbol = defaultCurrencySymbol,
  })  : _directoryProvider =
            directoryProvider ?? getApplicationSupportDirectory,
        _preferencesProvider =
            preferencesProvider ?? SharedPreferences.getInstance,
        _dataFile = dataFile,
        _defaultLanguageCode = defaultLanguageCode == 'en' ? 'en' : 'zh',
        _defaultCurrencySymbol = normalizeCurrencySymbol(initialCurrencySymbol);

  static const storageKey = 'repair_work_order_assistant:data:v1';
  static const dataFileName = 'repair_work_order_assistant_data_v1.json';

  final Future<Directory> Function() _directoryProvider;
  final Future<SharedPreferences> Function() _preferencesProvider;
  SharedPreferences? _preferences;
  File? _dataFile;
  final String _defaultLanguageCode;
  final String _defaultCurrencySymbol;
  RepairAppData? _memoryData;
  bool _persistenceAvailable = true;

  @override
  bool get persistenceAvailable => _persistenceAvailable;

  Future<SharedPreferences> _getPreferences() async =>
      _preferences ??= await _preferencesProvider();

  Future<SharedPreferences?> _tryGetPreferences() async {
    try {
      return await _getPreferences();
    } catch (_) {
      return null;
    }
  }

  Future<File> _getDataFile() async {
    final cached = _dataFile;
    if (cached != null) return cached;
    final directory = await _directoryProvider();
    _dataFile = File(
      '${directory.path}${Platform.pathSeparator}$dataFileName',
    );
    return _dataFile!;
  }

  static String _temporaryPath(File file) => '${file.path}.tmp';

  Future<RepairAppData?> _readFile(File file) async {
    var source = file;
    if (!await file.exists()) {
      final temporary = File(_temporaryPath(file));
      if (await temporary.exists()) {
        try {
          source = await temporary.rename(file.path);
        } on FileSystemException {
          source = temporary;
        }
      }
    }
    if (!await source.exists()) return null;

    try {
      return _decode(await source.readAsString());
    } on FileSystemException {
      rethrow;
    } catch (_) {
      // A malformed file is recoverable: try the legacy store before seeding.
      return null;
    }
  }

  Future<void> _writeFile(File file, RepairAppData data) async {
    await file.parent.create(recursive: true);
    final temporary = File(_temporaryPath(file));
    await temporary.writeAsString(jsonEncode(data.toJson()), flush: true);
    await temporary.rename(file.path);
  }

  Future<(RepairAppData, SharedPreferences)?> _readLegacyData() async {
    final preferences = await _tryGetPreferences();
    if (preferences == null) return null;
    try {
      final raw = preferences.getString(storageKey);
      if (raw == null || raw.isEmpty) return null;
      return (_decode(raw), preferences);
    } catch (_) {
      return null;
    }
  }

  static RepairAppData _decode(String raw) {
    final json = jsonDecode(raw);
    if (json is! Map) {
      throw const FormatException('repair data root is not an object');
    }
    return RepairAppData.fromJson(Map<String, Object?>.from(json));
  }

  RepairAppData _initialData() => initialData(
        languageCode: _defaultLanguageCode,
        currencySymbol: _defaultCurrencySymbol,
      );

  @override
  Future<RepairAppData> load() async {
    if (!_persistenceAvailable) return _memoryData ??= _initialData();

    try {
      final file = await _getDataFile();
      final stored = await _readFile(file);
      if (stored != null) {
        _memoryData = stored;
        return stored;
      }

      final legacy = await _readLegacyData();
      if (legacy != null) {
        final (migrated, preferences) = legacy;
        _memoryData = migrated;
        try {
          await _writeFile(file, migrated);
        } catch (_) {
          _persistenceAvailable = false;
          return migrated;
        }
        // The file is now the source of truth. Cleanup of the old, potentially
        // oversized SharedPreferences value is best effort and must not affect
        // the status of the new primary store.
        try {
          await preferences.remove(storageKey);
        } catch (_) {}
        return migrated;
      }

      final seeded = _initialData();
      _memoryData = seeded;
      try {
        await _writeFile(file, seeded);
      } catch (_) {
        _persistenceAvailable = false;
      }
      return seeded;
    } catch (_) {
      _persistenceAvailable = false;
      return _memoryData ??= _initialData();
    }
  }

  @override
  Future<void> save(RepairAppData data) async {
    _memoryData = data;
    if (!_persistenceAvailable) return;

    try {
      final file = await _getDataFile();
      await _writeFile(file, data);
    } catch (_) {
      _persistenceAvailable = false;
    }
  }
}
