import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../models/user_profile.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(databaseProvider));
});

/// Loads the single user profile row. Invalidate to refresh after any update.
final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile();
});

/// Supported currencies – static, no DB needed.
const List<Map<String, String>> kSupportedCurrencies = [
  {'code': 'NPR', 'symbol': 'रु', 'name': 'Nepali Rupee'},
  {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
  {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
  {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
  {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
  {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
  {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
];
