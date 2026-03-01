import '../entities/customer.dart';

abstract class ICustomerRepository {
  Future<List<Customer>> getAll();
  Future<void> add(Customer customer);
  Future<void> update(Customer customer);
  Future<void> delete(String id);
  Future<void> replaceAll(List<Customer> customers);
}
