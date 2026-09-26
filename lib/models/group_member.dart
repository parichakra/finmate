class GroupMember {
  final int? id;
  final int groupId;
  final String name;
  final bool isYou;
  final DateTime createdAt;

  GroupMember({
    this.id,
    required this.groupId,
    required this.name,
    this.isYou = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'is_you': isYou ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      name: map['name'] as String,
      isYou: (map['is_you'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
