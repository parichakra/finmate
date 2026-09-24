class Category {
  final int? id;
  final String name;
  final String type; // 'income', 'expense', 'both'
  final String? icon;
  final String? color;
  final bool isSystem;
  final bool isActive;
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isSystem = false,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_system': isSystem ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isSystem: (map['is_system'] as int) == 1,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
