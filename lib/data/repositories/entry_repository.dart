import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/entry.dart';
import '../../domain/repositories/i_entry_repository.dart';
import '../models/entry_model.dart';

class EntryRepository implements IEntryRepository {
  Box<String> get _box => Hive.box<String>(AppConstants.entriesBox);

  @override
  Future<List<Entry>> getAll() async {
    return _box.values
        .map((json) => EntryModel.fromMap(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Entry>> getByCustomer(String customerId) async {
    final all = await getAll();
    return all.where((e) => e.customerId == customerId).toList();
  }

  @override
  Future<void> add(Entry entry) async {
    final model = EntryModel.fromEntity(entry);
    await _box.put(entry.id, jsonEncode(model.toMap()));
  }

  @override
  Future<void> update(Entry entry) async {
    final model = EntryModel.fromEntity(entry);
    await _box.put(entry.id, jsonEncode(model.toMap()));
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> replaceAll(List<Entry> entries) async {
    await _box.clear();
    final map = {
      for (final e in entries)
        e.id: jsonEncode(EntryModel.fromEntity(e).toMap())
    };
    await _box.putAll(map);
  }
}
