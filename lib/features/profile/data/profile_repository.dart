import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/database/database_helper.dart';
import '../../../models/user_profile.dart';

/// Keys used in FlutterSecureStorage.
class _Keys {
  static const pin = 'finmate_app_pin';
  static const bypassKey = 'finmate_bypass_key';
}

class ProfileRepository {
  final DatabaseHelper _db;
  final FlutterSecureStorage _secure;

  ProfileRepository(this._db)
      : _secure = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<UserProfile?> getProfile() => _db.getProfile();

  Future<void> updateName(UserProfile profile, String name) async {
    final updated = profile.copyWith(
      name: name.trim(),
      updatedAt: DateTime.now(),
    );
    await _db.updateProfile(updated);
  }

  Future<void> updateCurrency(
    UserProfile profile, {
    required String code,
    required String symbol,
  }) async {
    final updated = profile.copyWith(
      currencyCode: code,
      currencySymbol: symbol,
      updatedAt: DateTime.now(),
    );
    await _db.updateProfile(updated);
  }

  Future<void> updateProfile(UserProfile profile) => _db.updateProfile(profile);

  // ── PIN ────────────────────────────────────────────────────────────────────

  /// Saves [pin] to secure storage and marks isPinEnabled=true in the DB.
  Future<void> setPin(UserProfile profile, String pin) async {
    assert(pin.length == 4 && int.tryParse(pin) != null,
        'PIN must be exactly 4 digits');
    await _secure.write(key: _Keys.pin, value: pin);
    await _db.savePin(profile.id!);
  }

  /// Returns true if [pin] matches the stored PIN.
  Future<bool> verifyPin(String pin) async {
    final stored = await _secure.read(key: _Keys.pin);
    if (stored == null) return false;
    return stored == pin;
  }

  /// Removes the PIN and disables app lock.
  Future<void> removePin(UserProfile profile) async {
    await _secure.delete(key: _Keys.pin);
    await _db.removePin(profile.id!);
  }

  /// Returns true if a PIN has been set in secure storage.
  Future<bool> hasPinSet() async {
    final stored = await _secure.read(key: _Keys.pin);
    return stored != null && stored.isNotEmpty;
  }

  // ── Bypass Key (MMDD) ─────────────────────────────────────────────────────

  /// [mmdd] must be exactly 4 digits, e.g. "0315" for March 15.
  Future<void> setBypassKey(UserProfile profile, String mmdd) async {
    assert(mmdd.length == 4 && int.tryParse(mmdd) != null,
        'Bypass key must be 4 digits (MMDD)');
    await _secure.write(key: _Keys.bypassKey, value: mmdd);
    await _db.saveBypassKey(profile.id!);
  }

  /// Returns true if [mmdd] matches the stored bypass key.
  Future<bool> verifyBypassKey(String mmdd) async {
    final stored = await _secure.read(key: _Keys.bypassKey);
    if (stored == null) return false;
    return stored == mmdd;
  }

  /// Returns true if a bypass key has been configured.
  Future<bool> hasBypassKey() async {
    final stored = await _secure.read(key: _Keys.bypassKey);
    return stored != null && stored.isNotEmpty;
  }
}
