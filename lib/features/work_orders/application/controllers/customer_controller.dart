import '../../domain/entities/work_order.dart';
import '../work_order_store.dart';

class CustomerController {
  CustomerController(this._store);

  final WorkOrderStore _store;

  Future<void> saveCustomer(Customer customer) async {
    final customers = [..._store.data.customers];
    final index = customers.indexWhere((item) => item.id == customer.id);
    if (index < 0) {
      customers.insert(0, customer);
    } else {
      customers[index] = customer;
    }
    await _store.commit(_store.data.copyWith(customers: customers));
  }

  Future<bool> deleteCustomer(String customerId) async {
    if (_store.data.workOrders.any((order) => order.customerId == customerId)) {
      return false;
    }
    await _store.commit(
      _store.data.copyWith(
        customers: _store.data.customers
            .where((item) => item.id != customerId)
            .toList(),
      ),
    );
    return true;
  }
}
