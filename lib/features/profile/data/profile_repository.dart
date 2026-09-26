import '../../../core/database/database_helper.dart';
import '../../../models/user_profile.dart';

class ProfileRepository {
  final DatabaseHelper _db;

  ProfileRepository(this._db);

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
}
