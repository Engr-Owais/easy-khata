import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/entry_repository.dart';
import '../../domain/entities/entry.dart';
import '../../domain/repositories/i_entry_repository.dart';

final entryRepositoryProvider = Provider<IEntryRepository>((ref) {
  return EntryRepository();
});

class EntryNotifier extends StateNotifier<AsyncValue<List<Entry>>> {
  final IEntryRepository _repository;

  EntryNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getAll();
      entries.sort((a, b) => b.date.compareTo(a.date));
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(Entry entry) async {
    await _repository.add(entry);
    await load();
  }

  Future<void> update(Entry entry) async {
    await _repository.update(entry);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  Future<void> replaceAll(List<Entry> entries) async {
    await _repository.replaceAll(entries);
    await load();
  }
}

final entriesProvider =
    StateNotifierProvider<EntryNotifier, AsyncValue<List<Entry>>>((ref) {
  return EntryNotifier(ref.read(entryRepositoryProvider));
});
