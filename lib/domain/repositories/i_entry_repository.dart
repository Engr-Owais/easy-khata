import '../entities/entry.dart';

abstract class IEntryRepository {
  Future<List<Entry>> getAll();
  Future<List<Entry>> getByCustomer(String customerId);
  Future<void> add(Entry entry);
  Future<void> update(Entry entry);
  Future<void> delete(String id);
  Future<void> replaceAll(List<Entry> entries);
}
