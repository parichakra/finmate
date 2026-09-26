import 'package:finmate/models/expense_share.dart';

class SharedExpense {
  final int? id;
  final int groupId;
  final String description;
  final double totalAmount;
  final int paidByMemberId;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  // Optional joined data
  final String? paidByName;
  final List<ExpenseShare>? shares;

  SharedExpense({
    this.id,
    required this.groupId,
    required this.description,
    required this.totalAmount,
    required this.paidByMemberId,
    required this.date,
    this.notes,
    DateTime? createdAt,
    this.paidByName,
    this.shares,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'description': description,
      'total_amount': totalAmount,
      'paid_by_member_id': paidByMemberId,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SharedExpense.fromMap(Map<String, dynamic> map) {
    return SharedExpense(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      description: map['description'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidByMemberId: map['paid_by_member_id'] as int,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      paidByName: map['paid_by_name'] as String?,
    );
  }
}
