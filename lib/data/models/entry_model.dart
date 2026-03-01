import '../../domain/entities/entry.dart';

class EntryModel extends Entry {
  const EntryModel({
    required super.id,
    required super.customerId,
    required super.type,
    required super.amount,
    super.note,
    required super.date,
  });

  factory EntryModel.fromEntity(Entry entry) {
    return EntryModel(
      id: entry.id,
      customerId: entry.customerId,
      type: entry.type,
      amount: entry.amount,
      note: entry.note,
      date: entry.date,
    );
  }

  factory EntryModel.fromMap(Map<String, dynamic> map) {
    return EntryModel(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: (map['note'] as String?) ?? '',
      date: DateTime.parse(map['date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'type': type,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
    };
  }
}
