import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/budgets/presentation/budgets_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/providers/profile_providers.dart';
import '../features/transactions/presentation/add_transaction_screen.dart';
import '../features/groups/presentation/groups_screen.dart';
import '../features/groups/presentation/create_group_screen.dart';
import '../features/groups/presentation/group_detail_screen.dart';
import '../features/groups/presentation/add_shared_expense_screen.dart';
import '../features/groups/presentation/settle_up_screen.dart';
import '../features/budgets/presentation/create_budget_screen.dart';
import '../features/security/presentation/pin_lock_screen.dart';
import '../features/security/presentation/setup_pin_screen.dart';
import '../features/security/presentation/set_bypass_key_screen.dart';
import '../models/group.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // Rebuild the router whenever lock state or profile changes.
  final isUnlocked = ref.watch(appLockStateProvider);
  final profileAsync = ref.watch(profileProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    debugLogDiagnostics: true,

    // ── Global redirect guard ──────────────────────────────────────────────
    redirect: (context, state) {
      final goingToLock = state.matchedLocation == '/lock';

      // While profile is still loading, let the app show normally.
      final profile = profileAsync.valueOrNull;
      if (profile == null) return null;

      final lockEnabled = profile.isPinEnabled;

      // If lock is enabled and session is not yet unlocked, send to /lock.
      if (lockEnabled && !isUnlocked && !goingToLock) return '/lock';

      // If lock is disabled (or already unlocked) and user somehow hits /lock,
      // bounce them to dashboard.
      if (goingToLock && (!lockEnabled || isUnlocked)) return '/dashboard';

      return null;
    },

    routes: [
      // ── Lock screen (full-screen, no shell) ──────────────────────────────
      GoRoute(
        path: '/lock',
        name: 'lock',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PinLockScreen(),
      ),

      // ==================== MAIN SHELL (Bottom Navigation) ====================
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TransactionsScreen()),
          ),
          GoRoute(
            path: '/budgets',
            name: 'budgets',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BudgetsScreen()),
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CategoriesScreen()),
          ),
          GoRoute(
            path: '/groups',
            name: 'groups',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GroupsScreen()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // ==================== FULL SCREEN ROUTES ====================
      GoRoute(
        path: '/add-transaction',
        name: 'add-transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final type = state.uri.queryParameters['type'];
          return AddTransactionScreen(initialType: type);
        },
      ),
      GoRoute(
        path: '/groups/create',
        name: 'create-group',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/groups/:id',
        name: 'group-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return GroupDetailScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/groups/:id/add-expense',
        name: 'add-shared-expense',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AddSharedExpenseScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/groups/:id/settle',
        name: 'settle-up',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SettleUpScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/groups/:id/edit',
        name: 'edit-group',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final group = state.extra as Group;
          return CreateGroupScreen(group: group);
        },
      ),
      GoRoute(
        path: '/budgets/create',
        name: 'create-budget',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateBudgetScreen(),
      ),
      GoRoute(
        path: '/budgets/edit',
        name: 'edit-budget',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final budget = state.extra as Budget;
          return CreateBudgetScreen(budget: budget);
        },
      ),
      GoRoute(
        path: '/transactions/edit',
        name: 'edit-transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final transaction = state.extra as Transaction;
          return AddTransactionScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final profile = state.extra as UserProfile;
          return EditProfileScreen(profile: profile);
        },
      ),
      GoRoute(
        path: '/profile/setup-pin',
        name: 'setup-pin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final profile = state.extra as UserProfile;
          return SetupPinScreen(profile: profile);
        },
      ),
      GoRoute(
        path: '/profile/set-bypass-key',
        name: 'set-bypass-key',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final profile = state.extra as UserProfile;
          return SetBypassKeyScreen(profile: profile);
        },
      ),
    ],
  );
});

// ==================== MAIN SHELL WITH BOTTOM NAV ====================
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: const AppBottomNav());
  }
}

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/groups')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0: context.goNamed('dashboard'); break;
      case 1: context.goNamed('transactions'); break;
      case 2: context.goNamed('budgets'); break;
      case 3: context.goNamed('groups'); break;
      case 4: context.goNamed('profile'); break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onItemTapped(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Transactions',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Budgets',
        ),
        NavigationDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group),
          label: 'Groups',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
