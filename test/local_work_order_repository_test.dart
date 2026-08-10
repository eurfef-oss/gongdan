import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:repair_work_order_assistant/features/work_orders/data/local_work_order_repository.dart';
import 'package:repair_work_order_assistant/features/work_orders/domain/entities/work_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Directory> _temporaryDirectory() async =>
    Directory.systemTemp.createTemp('repair_work_order_repository_test_');

File _dataFile(Directory directory) => File(
      '${directory.path}${Platform.pathSeparator}'
      '${LocalWorkOrderRepository.dataFileName}',
    );

void main() {
  test('writes data to an app file and reloads it after repository recreation',
      () async {
    final directory = await _temporaryDirectory();
    addTearDown(() => directory.delete(recursive: true));
    final file = _dataFile(directory);
    final preferences = await _preferences({});
    final repository = LocalWorkOrderRepository(
      dataFile: file,
      preferencesProvider: () async => preferences,
    );
    final expected = seedData();

    await repository.save(expected);

    expect(await file.exists(), isTrue);
    expect(await File('${file.path}.tmp').exists(), isFalse);
    expect(jsonDecode(await file.readAsString()), isA<Map>());

    final reloaded = await LocalWorkOrderRepository(
      dataFile: file,
      preferencesProvider: () async => preferences,
    ).load();

    expect(reloaded.toJson(), expected.toJson());
    expect(repository.persistenceAvailable, isTrue);
  });

  test('migrates the legacy SharedPreferences value into the app file',
      () async {
    final directory = await _temporaryDirectory();
    addTearDown(() => directory.delete(recursive: true));
    final file = _dataFile(directory);
    final expected = seedData();
    final preferences = await _preferences({
      LocalWorkOrderRepository.storageKey: jsonEncode(expected.toJson()),
    });
    final repository = LocalWorkOrderRepository(
      dataFile: file,
      preferencesProvider: () async => preferences,
    );

    final loaded = await repository.load();

    expect(loaded.toJson(), expected.toJson());
    expect(await file.exists(), isTrue);
    expect(preferences.getString(LocalWorkOrderRepository.storageKey), isNull);
    expect(repository.persistenceAvailable, isTrue);
  });

  test('prefers the file over an old SharedPreferences snapshot', () async {
    final directory = await _temporaryDirectory();
    addTearDown(() => directory.delete(recursive: true));
    final file = _dataFile(directory);
    final fileData = seedData();
    final legacyData = RepairAppData.empty();
    await file.writeAsString(jsonEncode(fileData.toJson()));
    final preferences = await _preferences({
      LocalWorkOrderRepository.storageKey: jsonEncode(legacyData.toJson()),
    });
    final repository = LocalWorkOrderRepository(
      dataFile: file,
      preferencesProvider: () async => preferences,
    );

    final loaded = await repository.load();

    expect(loaded.toJson(), fileData.toJson());
    expect(
        preferences.getString(LocalWorkOrderRepository.storageKey), isNotNull);
  });

  test('falls back to memory when the app directory cannot be opened',
      () async {
    final repository = LocalWorkOrderRepository(
      directoryProvider: () => Future<Directory>.error(StateError('offline')),
      preferencesProvider: () => Future<SharedPreferences>.error(
          StateError('legacy storage unavailable')),
    );
    final loaded = await repository.load();
    final replacement = loaded.copyWith(
        settings: const RepairAppSettings(
      shopName: '临时内存数据',
    ));
    await repository.save(replacement);

    expect(loaded.customers, isNotEmpty);
    expect(loaded.workOrders, isNotEmpty);
    expect(repository.persistenceAvailable, isFalse);
    expect((await repository.load()).settings.shopName, '临时内存数据');
  });
}

Future<SharedPreferences> _preferences(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}
