class Customer {
  final String id;
  final String name;
  final String phone;
  final String notes;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.notes = '',
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? notes,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
