class Budget {
  final int? id;
  final String name;
  final double amount;
  final String period; // 'monthly' or 'custom'
  final DateTime startDate;
  final DateTime? endDate;
  final int? categoryId; // null = overall budget
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    this.id,
    required this.name,
    required this.amount,
    this.period = 'monthly',
    required this.startDate,
    this.endDate,
    this.categoryId,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'period': period,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'category_id': categoryId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      period: map['period'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      categoryId: map['category_id'] as int?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
