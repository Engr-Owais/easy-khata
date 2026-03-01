import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/customer_repository.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/i_customer_repository.dart';

final customerRepositoryProvider = Provider<ICustomerRepository>((ref) {
  return CustomerRepository();
});

class CustomerNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final ICustomerRepository _repository;

  CustomerNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final customers = await _repository.getAll();
      customers.sort((a, b) => a.name.compareTo(b.name));
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(Customer customer) async {
    await _repository.add(customer);
    await load();
  }

  Future<void> update(Customer customer) async {
    await _repository.update(customer);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  Future<void> replaceAll(List<Customer> customers) async {
    await _repository.replaceAll(customers);
    await load();
  }
}

final customersProvider =
    StateNotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>((ref) {
  return CustomerNotifier(ref.read(customerRepositoryProvider));
});
