class ExpenseShare {
  final int? id;
  final int sharedExpenseId;
  final int memberId;
  final double shareAmount;
  final bool isSettled;

  // Optional
  final String? memberName;

  ExpenseShare({
    this.id,
    required this.sharedExpenseId,
    required this.memberId,
    required this.shareAmount,
    this.isSettled = false,
    this.memberName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shared_expense_id': sharedExpenseId,
      'member_id': memberId,
      'share_amount': shareAmount,
      'is_settled': isSettled ? 1 : 0,
    };
  }

  factory ExpenseShare.fromMap(Map<String, dynamic> map) {
    return ExpenseShare(
      id: map['id'] as int?,
      sharedExpenseId: map['shared_expense_id'] as int,
      memberId: map['member_id'] as int,
      shareAmount: (map['share_amount'] as num).toDouble(),
      isSettled: (map['is_settled'] as int) == 1,
      memberName: map['member_name'] as String?,
    );
  }
}
