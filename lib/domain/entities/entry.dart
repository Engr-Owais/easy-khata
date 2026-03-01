class Entry {
  final String id;
  final String customerId;
  final String type; // 'gave' or 'received'
  final double amount;
  final String note;
  final DateTime date;

  const Entry({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.note = '',
    required this.date,
  });

  bool get isGave => type == 'gave';

  Entry copyWith({
    String? id,
    String? customerId,
    String? type,
    double? amount,
    String? note,
    DateTime? date,
  }) {
    return Entry(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }
}
