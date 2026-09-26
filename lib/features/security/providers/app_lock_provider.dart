import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the user has passed the PIN lock screen this session.
/// Reset to false is intentionally not exposed — the lock is per-process-lifetime.
class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() => false; // locked by default each cold start

  /// Call after the user successfully enters their PIN or bypass key.
  void unlock() => state = true;

  /// Call when app lock is disabled from settings (no need to show lock screen).
  void disableLock() => state = true;
}

final appLockStateProvider =
    NotifierProvider<AppLockNotifier, bool>(AppLockNotifier.new);
