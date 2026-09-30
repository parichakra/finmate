// Sentinel used to explicitly clear nullable fields in copyWith.
const _kClear = Object();

class UserProfile {
  final int? id;
  final String name;
  final String currencyCode;
  final String currencySymbol;
  final String? avatarPath;
  final bool isPinEnabled;
  /// SHA-256 hex of the 4-digit PIN. Null when no PIN is set.
  final String? pinHash;
  /// SHA-256 hex of the MMDD bypass key. Null when not configured.
  final String? bypassKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    this.id,
    this.name = 'User',
    this.currencyCode = 'NPR',
    this.currencySymbol = 'रु',
    this.avatarPath,
    this.isPinEnabled = false,
    this.pinHash,
    this.bypassKey,
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
      'pin_hash': pinHash,
      'bypass_key': bypassKey,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Pass [_kClear] for [pinHash] or [bypassKey] to set them to null.
  UserProfile copyWith({
    int? id,
    String? name,
    String? currencyCode,
    String? currencySymbol,
    Object? avatarPath = _kClear,
    bool? isPinEnabled,
    Object? pinHash = _kClear,
    Object? bypassKey = _kClear,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      avatarPath: identical(avatarPath, _kClear)
          ? this.avatarPath
          : avatarPath as String?,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      pinHash: identical(pinHash, _kClear) ? this.pinHash : pinHash as String?,
      bypassKey:
          identical(bypassKey, _kClear) ? this.bypassKey : bypassKey as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      currencyCode: map['currency_code'] as String,
      currencySymbol: map['currency_symbol'] as String,
      avatarPath: map['avatar_path'] as String?,
      isPinEnabled: (map['is_pin_enabled'] as int) == 1,
      pinHash: map['pin_hash'] as String?,
      bypassKey: map['bypass_key'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
