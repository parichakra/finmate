class Transaction {
  final int? id;
  final String type; // 'income' or 'expense'
  final double amount;
  final int categoryId;
  final String? description;
  final String? notes;
  final DateTime date;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.description,
    this.notes,
    required this.date,
    this.isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'description': description,
      'notes': notes,
      'date': date.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      description: map['description'] as String?,
      notes: map['notes'] as String?,
      date: DateTime.parse(map['date'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
