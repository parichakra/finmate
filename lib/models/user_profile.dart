class UserProfile {
  final int? id;
  final String name;
  final String currencyCode;
  final String currencySymbol;
  final String? avatarPath;
  final bool isPinEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    this.id,
    this.name = 'User',
    this.currencyCode = 'NPR',
    this.currencySymbol = '\रु',
    this.avatarPath,
    this.isPinEnabled = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'avatar_path': avatarPath,
      'is_pin_enabled': isPinEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      currencyCode: map['currency_code'] as String,
      currencySymbol: map['currency_symbol'] as String,
      avatarPath: map['avatar_path'] as String?,
      isPinEnabled: (map['is_pin_enabled'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
