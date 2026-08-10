import '../../domain/entities/work_order.dart';
import '../work_order_store.dart';

class TemplateController {
  TemplateController(this._store);

  final WorkOrderStore _store;

  List<ServiceTypeOption> get serviceItemTypeOptions {
    final deletedBuiltIns = _store.data.settings.deletedBuiltInServiceItemTypes
        .map((value) => value.trim().toLowerCase())
        .toSet();
    final options = ServiceItemType.values
        .where((type) => !deletedBuiltIns.contains(type.name))
        .map(ServiceTypeOption.builtIn)
        .toList();
    final customNames = <String>[];

    void addName(String? value) {
      final name = value?.trim() ?? '';
      if (name.isEmpty ||
          ServiceItemType.values.any(
            (type) => type.label.toLowerCase() == name.toLowerCase(),
          ) ||
          customNames.any((item) => item.toLowerCase() == name.toLowerCase())) {
        return;
      }
      customNames.add(name);
    }

    for (final name in _store.data.settings.customServiceItemTypes) {
      addName(name);
    }
    for (final item in _store.data.serviceItems) {
      addName(item.customType);
    }
    for (final order in _store.data.workOrders) {
      for (final item in order.items) {
        addName(item.customType);
      }
    }
    options.addAll(customNames.map(ServiceTypeOption.custom));
    return options;
  }

  Future<void> saveServiceItem(ServiceItem item) async {
    final items = [..._store.data.serviceItems];
    final index = items.indexWhere((serviceItem) => serviceItem.id == item.id);
    if (index < 0) {
      items.insert(0, item);
    } else {
      items[index] = item;
    }
    await _store.commit(_store.data.copyWith(serviceItems: items));
  }

  Future<bool> addServiceItemType(String value) async {
    final name = _cleanTypeName(value);
    if (!_canAddTypeName(name)) return false;
    final names = [..._store.data.settings.customServiceItemTypes, name];
    return _store.commit(
      _store.data.copyWith(
        settings: _store.data.settings.copyWith(
          customServiceItemTypes: names,
        ),
      ),
    );
  }

  Future<bool> renameServiceItemType(
    String oldValue,
    String newValue,
  ) async {
    final oldName = _cleanTypeName(oldValue);
    final newName = _cleanTypeName(newValue);
    final names = [..._store.data.settings.customServiceItemTypes];
    final index = names.indexWhere((item) => _sameTypeName(item, oldName));
    if (index < 0 || !_canAddTypeName(newName, excluding: oldName)) {
      return false;
    }
    names[index] = newName;
    final serviceItems = _store.data.serviceItems
        .map(
          (item) => _sameTypeName(item.customType, oldName)
              ? item.copyWith(
                  customType: newName,
                  type: ServiceItemType.other,
                )
              : item,
        )
        .toList();
    final workOrders = _store.data.workOrders
        .map(
          (order) => order.copyWith(
            items: order.items
                .map(
                  (item) => _sameTypeName(item.customType, oldName)
                      ? item.copyWith(
                          customType: newName,
                          type: ServiceItemType.other,
                        )
                      : item,
                )
                .toList(),
          ),
        )
        .toList();
    return _store.commit(
      _store.data.copyWith(
        settings: _store.data.settings.copyWith(
          customServiceItemTypes: names,
        ),
        serviceItems: serviceItems,
        workOrders: workOrders,
      ),
    );
  }

  Future<bool> deleteServiceItemType(String value) async {
    final name = _cleanTypeName(value);
    final builtIn = _builtInTypeForName(name);
    if (builtIn != null) {
      final deleted = [..._store.data.settings.deletedBuiltInServiceItemTypes];
      if (deleted.any((item) => _sameTypeName(item, builtIn.name)) ||
          _builtInTypeInUse(builtIn)) {
        return false;
      }
      deleted.add(builtIn.name);
      return _store.commit(
        _store.data.copyWith(
          settings: _store.data.settings.copyWith(
            deletedBuiltInServiceItemTypes: deleted,
          ),
        ),
      );
    }
    final names = [..._store.data.settings.customServiceItemTypes];
    final index = names.indexWhere((item) => _sameTypeName(item, name));
    if (index < 0) return false;
    final inUse = _store.data.serviceItems.any(
          (item) => _sameTypeName(item.customType, name),
        ) ||
        _store.data.workOrders.any(
          (order) => order.items.any(
            (item) => _sameTypeName(item.customType, name),
          ),
        );
    if (inUse) return false;
    names.removeAt(index);
    return _store.commit(
      _store.data.copyWith(
        settings: _store.data.settings.copyWith(
          customServiceItemTypes: names,
        ),
      ),
    );
  }

  Future<void> deleteServiceItem(String itemId) async {
    if (!_store.data.serviceItems.any((item) => item.id == itemId)) return;
    await _store.commit(
      _store.data.copyWith(
        serviceItems: _store.data.serviceItems
            .where((item) => item.id != itemId)
            .toList(),
      ),
    );
  }

  Future<void> toggleServiceItem(String itemId) async {
    final items = _store.data.serviceItems
        .map(
          (item) =>
              item.id == itemId ? item.copyWith(enabled: !item.enabled) : item,
        )
        .toList();
    await _store.commit(_store.data.copyWith(serviceItems: items));
  }

  static String _cleanTypeName(String value) => value.trim();

  ServiceItemType? _builtInTypeForName(String name) {
    for (final type in ServiceItemType.values) {
      if (_sameTypeName(type.name, name) || _sameTypeName(type.label, name)) {
        return type;
      }
    }
    return null;
  }

  bool _builtInTypeInUse(ServiceItemType type) {
    bool matches(ServiceItem item) =>
        item.type == type && (item.customType?.trim().isEmpty ?? true);
    bool orderMatches(WorkOrder order) => order.items.any(
          (item) =>
              item.type == type && (item.customType?.trim().isEmpty ?? true),
        );
    return _store.data.serviceItems.any(matches) ||
        _store.data.workOrders.any(orderMatches);
  }

  bool _canAddTypeName(String name, {String? excluding}) {
    if (name.isEmpty || name.length > 30) return false;
    if (ServiceItemType.values.any(
      (type) => type.label.toLowerCase() == name.toLowerCase(),
    )) {
      return false;
    }
    return !_store.data.settings.customServiceItemTypes.any(
      (item) => !_sameTypeName(item, excluding) && _sameTypeName(item, name),
    );
  }

  static bool _sameTypeName(String? a, String? b) {
    final left = a?.trim();
    final right = b?.trim();
    return left != null &&
        right != null &&
        left.isNotEmpty &&
        right.isNotEmpty &&
        left.toLowerCase() == right.toLowerCase();
  }
}
