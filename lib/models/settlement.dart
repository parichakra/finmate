class Settlement {
  final int? id;
  final int groupId;
  final int fromMemberId;
  final int toMemberId;
  final double amount;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  // Optional joined
  final String? fromMemberName;
  final String? toMemberName;

  Settlement({
    this.id,
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.date,
    this.notes,
    DateTime? createdAt,
    this.fromMemberName,
    this.toMemberName,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'from_member_id': fromMemberId,
      'to_member_id': toMemberId,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Settlement.fromMap(Map<String, dynamic> map) {
    return Settlement(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      fromMemberId: map['from_member_id'] as int,
      toMemberId: map['to_member_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      fromMemberName: map['from_member_name'] as String?,
      toMemberName: map['to_member_name'] as String?,
    );
  }
}
