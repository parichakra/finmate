import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../models/budget.dart';
import '../../models/user_profile.dart';
import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../models/shared_expense.dart';
import '../../models/expense_share.dart';
import '../../models/settlement.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finmate.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, fileName);

    return await openDatabase(
      path,
      version: 2, // ← increased version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create new Splitwise tables
      await db.execute('''
        CREATE TABLE groups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE group_members (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          is_you INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE shared_expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INTEGER NOT NULL,
          description TEXT NOT NULL,
          total_amount REAL NOT NULL,
          paid_by_member_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
          FOREIGN KEY (paid_by_member_id) REFERENCES group_members (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE expense_shares (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          shared_expense_id INTEGER NOT NULL,
          member_id INTEGER NOT NULL,
          share_amount REAL NOT NULL,
          is_settled INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (shared_expense_id) REFERENCES shared_expenses (id) ON DELETE CASCADE,
          FOREIGN KEY (member_id) REFERENCES group_members (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE settlements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INTEGER NOT NULL,
          from_member_id INTEGER NOT NULL,
          to_member_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
          FOREIGN KEY (from_member_id) REFERENCES group_members (id),
          FOREIGN KEY (to_member_id) REFERENCES group_members (id)
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        is_system INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        description TEXT,
        notes TEXT,
        date TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL DEFAULT 'monthly',
        start_date TEXT NOT NULL,
        end_date TEXT,
        category_id INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // User Profile table
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL DEFAULT 'User',
        currency_code TEXT NOT NULL DEFAULT 'NPR',
        currency_symbol TEXT NOT NULL DEFAULT 'रु',
        avatar_path TEXT,
        is_pin_enabled INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ==================== GROUPS & SPLITWISE TABLES ====================
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE group_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        is_you INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE shared_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        total_amount REAL NOT NULL,
        paid_by_member_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
        FOREIGN KEY (paid_by_member_id) REFERENCES group_members (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_shares (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shared_expense_id INTEGER NOT NULL,
        member_id INTEGER NOT NULL,
        share_amount REAL NOT NULL,
        is_settled INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (shared_expense_id) REFERENCES shared_expenses (id) ON DELETE CASCADE,
        FOREIGN KEY (member_id) REFERENCES group_members (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settlements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        from_member_id INTEGER NOT NULL,
        to_member_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
        FOREIGN KEY (from_member_id) REFERENCES group_members (id),
        FOREIGN KEY (to_member_id) REFERENCES group_members (id)
      )
    ''');

    // Seed default data
    await _seedDefaultCategories(db);
    await _seedDefaultProfile(db);
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final defaults = [
      // Income
      {
        'name': 'Salary',
        'type': 'income',
        'icon': 'payments',
        'color': '#10B981',
      },
      {
        'name': 'Freelance',
        'type': 'income',
        'icon': 'work',
        'color': '#3B82F6',
      },
      {
        'name': 'Investment',
        'type': 'income',
        'icon': 'trending_up',
        'color': '#8B5CF6',
      },
      {
        'name': 'Gift',
        'type': 'income',
        'icon': 'card_giftcard',
        'color': '#EC4899',
      },
      {
        'name': 'Other Income',
        'type': 'income',
        'icon': 'add_circle',
        'color': '#6B7280',
      },
      {
        'name': 'Splitwise Received',
        'type': 'income',
        'icon': 'group',
        'color': '#10B981',
      },

      // Expense
      {
        'name': 'Food & Dining',
        'type': 'expense',
        'icon': 'restaurant',
        'color': '#EF4444',
      },
      {
        'name': 'Transportation',
        'type': 'expense',
        'icon': 'directions_car',
        'color': '#F59E0B',
      },
      {
        'name': 'Shopping',
        'type': 'expense',
        'icon': 'shopping_bag',
        'color': '#EC4899',
      },
      {
        'name': 'Bills & Utilities',
        'type': 'expense',
        'icon': 'receipt_long',
        'color': '#6366F1',
      },
      {
        'name': 'Entertainment',
        'type': 'expense',
        'icon': 'movie',
        'color': '#8B5CF6',
      },
      {
        'name': 'Healthcare',
        'type': 'expense',
        'icon': 'local_hospital',
        'color': '#14B8A6',
      },
      {
        'name': 'Education',
        'type': 'expense',
        'icon': 'school',
        'color': '#3B82F6',
      },
      {'name': 'Rent', 'type': 'expense', 'icon': 'home', 'color': '#F97316'},
      {
        'name': 'Other Expense',
        'type': 'expense',
        'icon': 'more_horiz',
        'color': '#6B7280',
      },
      {
        'name': 'Splitwise Paid',
        'type': 'expense',
        'icon': 'group',
        'color': '#EF4444',
      },
    ];

    final now = DateTime.now().toIso8601String();

    for (final cat in defaults) {
      await db.insert('categories', {
        'name': cat['name'],
        'type': cat['type'],
        'icon': cat['icon'],
        'color': cat['color'],
        'is_system': 1,
        'is_active': 1,
        'created_at': now,
      });
    }
  }

  Future<void> _seedDefaultProfile(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('user_profile', {
      'name': 'User',
      'currency_code': 'NPR',
      'currency_symbol': 'रु',
      'is_pin_enabled': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  // ==================== CATEGORY METHODS ====================
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<List<Category>> getCategoriesByType(String type) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'is_active = ? AND (type = ? OR type = ?)',
      whereArgs: [1, type, 'both'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryByName(String name) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'name = ? AND is_active = 1',
      whereArgs: [name],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Category.fromMap(result.first);
  }

  // ==================== TRANSACTION METHODS ====================
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'date DESC',
    );
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> softDeleteTransaction(int id) async {
    final db = await database;
    return await db.update(
      'transactions',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== BUDGET METHODS ====================
  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<List<Budget>> getActiveBudgets() async {
    final db = await database;
    final result = await db.query(
      'budgets',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Budget.fromMap(map)).toList();
  }

  // ==================== BUDGET EXTRA METHODS ====================

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deactivateBudget(int id) async {
    final db = await database;
    return await db.update(
      'budgets',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Calculate how much has been spent against a budget
  Future<double> getSpentForBudget(Budget budget) async {
    final db = await database;

    String where = 'is_deleted = 0 AND type = ? AND date >= ?';
    List<dynamic> args = ['expense', budget.startDate.toIso8601String()];

    if (budget.endDate != null) {
      where += ' AND date <= ?';
      args.add(budget.endDate!.toIso8601String());
    } else {
      // Monthly budget → until end of current month
      final now = DateTime.now();
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      where += ' AND date <= ?';
      args.add(endOfMonth.toIso8601String());
    }

    if (budget.categoryId != null) {
      where += ' AND category_id = ?';
      args.add(budget.categoryId);
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE $where',
      args,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ==================== PROFILE METHODS ====================
  Future<UserProfile?> getProfile() async {
    final db = await database;
    final result = await db.query('user_profile', limit: 1);
    if (result.isEmpty) return null;
    return UserProfile.fromMap(result.first);
  }

  Future<int> updateProfile(UserProfile profile) async {
    final db = await database;
    return await db.update(
      'user_profile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  // ==================== DASHBOARD METHODS ====================
  Future<Map<String, double>> getMonthlySummary() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery(
      '''
      SELECT type, SUM(amount) as total
      FROM transactions
      WHERE is_deleted = 0 AND date >= ? AND date <= ?
      GROUP BY type
    ''',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    double income = 0;
    double expense = 0;

    for (final row in result) {
      final type = row['type'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      if (type == 'income')
        income = total;
      else if (type == 'expense')
        expense = total;
    }

    return {'income': income, 'expense': expense, 'net': income - expense};
  }

  Future<List<Transaction>> getRecentTransactions({int limit = 5}) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
    );
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  // ==================== CHART METHODS ====================
  Future<Map<int, double>> getDailyExpensesThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery(
      '''
      SELECT CAST(strftime('%d', date) AS INTEGER) as day, SUM(amount) as total
      FROM transactions
      WHERE is_deleted = 0 AND type = 'expense' AND date >= ? AND date <= ?
      GROUP BY day ORDER BY day
    ''',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    final Map<int, double> daily = {};
    for (final row in result) {
      daily[row['day'] as int] = (row['total'] as num?)?.toDouble() ?? 0;
    }
    return daily;
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategoryThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return await db.rawQuery(
      '''
      SELECT c.name as category_name, c.color as category_color, SUM(t.amount) as total
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE t.is_deleted = 0 AND t.type = 'expense' AND t.date >= ? AND t.date <= ?
      GROUP BY t.category_id ORDER BY total DESC
    ''',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );
  }

  // ==================== GROUPS METHODS ====================
  Future<int> insertGroup(Group group) async {
    final db = await database;
    return await db.insert('groups', group.toMap());
  }

  Future<List<Group>> getAllGroups() async {
    final db = await database;
    final result = await db.query('groups', orderBy: 'created_at DESC');
    return result.map((map) => Group.fromMap(map)).toList();
  }

  Future<Group?> getGroupById(int id) async {
    final db = await database;
    final result = await db.query('groups', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Group.fromMap(result.first);
  }

  Future<int> updateGroup(Group group) async {
    final db = await database;
    return await db.update(
      'groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(int id) async {
    final db = await database;
    return await db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== GROUP MEMBERS METHODS ====================
  Future<int> insertGroupMember(GroupMember member) async {
    final db = await database;
    return await db.insert('group_members', member.toMap());
  }

  Future<List<GroupMember>> getMembersByGroup(int groupId) async {
    final db = await database;
    final result = await db.query(
      'group_members',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'is_you DESC, name ASC',
    );
    return result.map((map) => GroupMember.fromMap(map)).toList();
  }

  Future<GroupMember?> getYouMember(int groupId) async {
    final db = await database;
    final result = await db.query(
      'group_members',
      where: 'group_id = ? AND is_you = 1',
      whereArgs: [groupId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return GroupMember.fromMap(result.first);
  }

  // ==================== SHARED EXPENSES METHODS ====================
  Future<int> insertSharedExpense(SharedExpense expense) async {
    final db = await database;
    return await db.insert('shared_expenses', expense.toMap());
  }

  Future<List<SharedExpense>> getSharedExpensesByGroup(int groupId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT se.*, gm.name as paid_by_name
      FROM shared_expenses se
      INNER JOIN group_members gm ON se.paid_by_member_id = gm.id
      WHERE se.group_id = ?
      ORDER BY se.date DESC
    ''',
      [groupId],
    );
    return result.map((map) => SharedExpense.fromMap(map)).toList();
  }

  // ==================== EXPENSE SHARES METHODS ====================
  Future<int> insertExpenseShare(ExpenseShare share) async {
    final db = await database;
    return await db.insert('expense_shares', share.toMap());
  }

  Future<List<ExpenseShare>> getSharesByExpense(int sharedExpenseId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT es.*, gm.name as member_name
      FROM expense_shares es
      INNER JOIN group_members gm ON es.member_id = gm.id
      WHERE es.shared_expense_id = ?
    ''',
      [sharedExpenseId],
    );
    return result.map((map) => ExpenseShare.fromMap(map)).toList();
  }

  // ==================== SETTLEMENTS METHODS ====================
  Future<int> insertSettlement(Settlement settlement) async {
    final db = await database;
    return await db.insert('settlements', settlement.toMap());
  }

  Future<List<Settlement>> getSettlementsByGroup(int groupId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT s.*, 
             f.name as from_member_name, 
             t.name as to_member_name
      FROM settlements s
      INNER JOIN group_members f ON s.from_member_id = f.id
      INNER JOIN group_members t ON s.to_member_id = t.id
      WHERE s.group_id = ?
      ORDER BY s.date DESC
    ''',
      [groupId],
    );
    return result.map((map) => Settlement.fromMap(map)).toList();
  }

  // ==================== BALANCE CALCULATION ====================
  /// Returns net balance for each member in a group
  /// Positive = others owe this member
  /// Negative = this member owes others

  /// Returns net balance of every member
  Future<Map<int, double>> getGroupBalances(int groupId) async {
    final db = await database;

    final members = await getMembersByGroup(groupId);
    final Map<int, double> balances = {for (var m in members) m.id!: 0.0};

    // From shared expenses
    final expenses = await db.query(
      'shared_expenses',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    for (final exp in expenses) {
      final paidBy = exp['paid_by_member_id'] as int;
      final total = (exp['total_amount'] as num).toDouble();
      final expenseId = exp['id'] as int;

      balances[paidBy] = (balances[paidBy] ?? 0) + total;

      final shares = await db.query(
        'expense_shares',
        where: 'shared_expense_id = ?',
        whereArgs: [expenseId],
      );
      for (final share in shares) {
        final memberId = share['member_id'] as int;
        final amount = (share['share_amount'] as num).toDouble();
        balances[memberId] = (balances[memberId] ?? 0) - amount;
      }
    }

    // From settlements
    final settlements = await db.query(
      'settlements',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    for (final s in settlements) {
      final fromId = s['from_member_id'] as int;
      final toId = s['to_member_id'] as int;
      final amount = (s['amount'] as num).toDouble();

      balances[fromId] = (balances[fromId] ?? 0) + amount;
      balances[toId] = (balances[toId] ?? 0) - amount;
    }

    return balances;
  }

  /// Returns simplified debts from YOUR point of view only
  /// Example result:
  /// [
  ///   {'member': GroupMember, 'amount': 500.0, 'type': 'owes_you'},
  ///   {'member': GroupMember, 'amount': 200.0, 'type': 'you_owe'},
  /// ]
  Future<List<Map<String, dynamic>>> getSimplifiedBalancesForYou(
    int groupId,
  ) async {
    final balances = await getGroupBalances(groupId);
    final members = await getMembersByGroup(groupId);

    final you = members.where((m) => m.isYou).firstOrNull;
    if (you == null) return [];

    final yourBalance = balances[you.id] ?? 0.0;
    final List<Map<String, dynamic>> result = [];

    for (final member in members) {
      if (member.isYou) continue;

      final memberBalance = balances[member.id] ?? 0.0;

      // Simplified pairwise logic (from your perspective)
      if (yourBalance > 0 && memberBalance < 0) {
        // They owe you
        final amount = memberBalance.abs() < yourBalance
            ? memberBalance.abs()
            : yourBalance;
        if (amount > 0.01) {
          result.add({'member': member, 'amount': amount, 'type': 'owes_you'});
        }
      } else if (yourBalance < 0 && memberBalance > 0) {
        // You owe them
        final amount = yourBalance.abs() < memberBalance
            ? yourBalance.abs()
            : memberBalance;
        if (amount > 0.01) {
          result.add({'member': member, 'amount': amount, 'type': 'you_owe'});
        }
      }
    }

    // Fallback: if the simple pairing didn't catch everything,
    // just show direct relationship with each person based on their balance relative to you
    if (result.isEmpty) {
      for (final member in members) {
        if (member.isYou) continue;
        final memberBalance = balances[member.id] ?? 0.0;

        if (memberBalance < -0.01) {
          result.add({
            'member': member,
            'amount': memberBalance.abs(),
            'type': 'owes_you',
          });
        } else if (memberBalance > 0.01) {
          result.add({
            'member': member,
            'amount': memberBalance,
            'type': 'you_owe',
          });
        }
      }
    }

    return result;
  }
}
