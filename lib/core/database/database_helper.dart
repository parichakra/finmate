import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../models/budget.dart';
import '../../models/user_profile.dart';

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
        currency_symbol TEXT NOT NULL DEFAULT '\रु',
        avatar_path TEXT,
        is_pin_enabled INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
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
      'currency_symbol': '\रु',
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
    SELECT 
      type,
      SUM(amount) as total
    FROM transactions
    WHERE is_deleted = 0
      AND date >= ?
      AND date <= ?
    GROUP BY type
  ''',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    double income = 0;
    double expense = 0;

    for (final row in result) {
      final type = row['type'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      if (type == 'income') {
        income = total;
      } else if (type == 'expense') {
        expense = total;
      }
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

  /// Returns daily expense totals for the current month
  /// Example: {1: 120.0, 2: 45.5, 5: 300.0, ...}
  Future<Map<int, double>> getDailyExpensesThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery(
      '''
    SELECT 
      CAST(strftime('%d', date) AS INTEGER) as day,
      SUM(amount) as total
    FROM transactions
    WHERE is_deleted = 0
      AND type = 'expense'
      AND date >= ?
      AND date <= ?
    GROUP BY day
    ORDER BY day
  ''',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    final Map<int, double> daily = {};
    for (final row in result) {
      final day = row['day'] as int;
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      daily[day] = total;
    }
    return daily;
  }

  /// Returns expense totals grouped by category for the current month
  Future<List<Map<String, dynamic>>> getExpensesByCategoryThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery(
      '''
    SELECT 
      c.name as category_name,
      c.color as category_color,
      SUM(t.amount) as total
    FROM transactions t
    INNER JOIN categories c ON t.category_id = c.id
    WHERE t.is_deleted = 0
      AND t.type = 'expense'
      AND t.date >= ?
      AND t.date <= ?
    GROUP BY t.category_id
    ORDER BY total DESC
  ''',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    return result;
  }
}
