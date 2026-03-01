import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/i_customer_repository.dart';
import '../models/customer_model.dart';

class CustomerRepository implements ICustomerRepository {
  Box<String> get _box => Hive.box<String>(AppConstants.customersBox);

  @override
  Future<List<Customer>> getAll() async {
    return _box.values
        .map((json) => CustomerModel.fromMap(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> add(Customer customer) async {
    final model = CustomerModel.fromEntity(customer);
    await _box.put(customer.id, jsonEncode(model.toMap()));
  }

  @override
  Future<void> update(Customer customer) async {
    final model = CustomerModel.fromEntity(customer);
    await _box.put(customer.id, jsonEncode(model.toMap()));
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> replaceAll(List<Customer> customers) async {
    await _box.clear();
    final entries = {
      for (final c in customers)
        c.id: jsonEncode(CustomerModel.fromEntity(c).toMap())
    };
    await _box.putAll(entries);
  }
}
