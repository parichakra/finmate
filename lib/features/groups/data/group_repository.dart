import '../../../core/database/database_helper.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';
import '../../../models/shared_expense.dart';
import '../../../models/expense_share.dart';
import '../../../models/settlement.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';

class GroupRepository {
  final DatabaseHelper _db;

  GroupRepository(this._db);

  // ==================== GROUPS ====================
  Future<int> createGroup({
    required String name,
    String? description,
    required List<String> memberNames, // other people (not including you)
  }) async {
    final group = Group(name: name, description: description);
    final groupId = await _db.insertGroup(group);

    // Add "You" as a member
    await _db.insertGroupMember(
      GroupMember(groupId: groupId, name: 'You', isYou: true),
    );

    // Add other members
    for (final memberName in memberNames) {
      if (memberName.trim().isEmpty) continue;
      await _db.insertGroupMember(
        GroupMember(groupId: groupId, name: memberName.trim(), isYou: false),
      );
    }

    return groupId;
  }

  Future<List<Group>> getAllGroups() async {
    return await _db.getAllGroups();
  }

  Future<Group?> getGroup(int id) async {
    return await _db.getGroupById(id);
  }

  Future<int> deleteGroup(int id) async {
    return await _db.deleteGroup(id);
  }

  // ==================== MEMBERS ====================
  Future<List<GroupMember>> getMembers(int groupId) async {
    return await _db.getMembersByGroup(groupId);
  }

  Future<GroupMember?> getYouMember(int groupId) async {
    return await _db.getYouMember(groupId);
  }

  // ==================== SHARED EXPENSE (Equal Split) ====================
  Future<void> addSharedExpense({
    required int groupId,
    required String description,
    required double totalAmount,
    required int paidByMemberId,
    required DateTime date,
    String? notes,
    List<int>? participantMemberIds, // if null → all members
  }) async {
    final members = await getMembers(groupId);
    final participants = participantMemberIds == null
        ? members
        : members.where((m) => participantMemberIds.contains(m.id)).toList();

    if (participants.isEmpty) {
      throw Exception('No participants selected');
    }

    final shareAmount = totalAmount / participants.length;

    // 1. Insert shared expense
    final expense = SharedExpense(
      groupId: groupId,
      description: description,
      totalAmount: totalAmount,
      paidByMemberId: paidByMemberId,
      date: date,
      notes: notes,
    );
    final expenseId = await _db.insertSharedExpense(expense);

    // 2. Insert shares
    for (final member in participants) {
      await _db.insertExpenseShare(
        ExpenseShare(
          sharedExpenseId: expenseId,
          memberId: member.id!,
          shareAmount: shareAmount,
        ),
      );
    }

    // 3. Create personal transaction for "You"
    final youMember = members.firstWhere((m) => m.isYou);
    final yourShare = participants.any((p) => p.id == youMember.id)
        ? shareAmount
        : 0.0;

    if (paidByMemberId == youMember.id) {
      // You paid the full amount
      // Your personal expense = your share
      // (the rest is money others owe you)
      if (yourShare > 0) {
        await _createPersonalTransaction(
          type: 'expense',
          amount: yourShare,
          description: description,
          date: date,
          categoryName: 'Splitwise Paid',
        );
      }
    } else {
      // Someone else paid → you owe your share
      if (yourShare > 0) {
        // We don't create expense yet. It will be created when you settle.
        // (Optional: you can create a pending expense here if you want)
      }
    }
  }

  // ==================== SETTLEMENT ====================
  Future<void> addSettlement({
    required int groupId,
    required int fromMemberId,
    required int toMemberId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    final settlement = Settlement(
      groupId: groupId,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amount: amount,
      date: date,
      notes: notes,
    );
    await _db.insertSettlement(settlement);

    final youMember = await getYouMember(groupId);
    if (youMember == null) return;

    // If You received money → Income
    if (toMemberId == youMember.id) {
      await _createPersonalTransaction(
        type: 'income',
        amount: amount,
        description: notes ?? 'Settlement received',
        date: date,
        categoryName: 'Splitwise Received',
      );
    }

    // If You paid money → Expense
    if (fromMemberId == youMember.id) {
      await _createPersonalTransaction(
        type: 'expense',
        amount: amount,
        description: notes ?? 'Settlement paid',
        date: date,
        categoryName: 'Splitwise Paid',
      );
    }
  }

  // ==================== HELPERS ====================
  Future<void> _createPersonalTransaction({
    required String type,
    required double amount,
    required String description,
    required DateTime date,
    required String categoryName,
  }) async {
    final category = await _db.getCategoryByName(categoryName);
    if (category == null) return;

    final tx = Transaction(
      type: type,
      amount: amount,
      categoryId: category.id!,
      description: description,
      date: date,
    );
    await _db.insertTransaction(tx);
  }

  Future<List<SharedExpense>> getSharedExpenses(int groupId) async {
    return await _db.getSharedExpensesByGroup(groupId);
  }

  Future<Map<int, double>> getBalances(int groupId) async {
    return await _db.getGroupBalances(groupId);
  }

  Future<List<Settlement>> getSettlements(int groupId) async {
    return await _db.getSettlementsByGroup(groupId);
  }

  Future<List<Map<String, dynamic>>> getSimplifiedBalances(int groupId) async {
    return await _db.getSimplifiedBalancesForYou(groupId);
  }
}
