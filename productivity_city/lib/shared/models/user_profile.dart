class UserProfile {
  static const int xpPerLevel = 100;

  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.level,
    required this.xp,
    required this.coins,
    required this.streak,
    required this.createdAt,
    required this.xpToNextLevel,
    this.lastActivityDate,
    this.tasksCompleted = 0,
    this.achievementsCount = 0,
    this.buildingsCount = 0,
    this.avatarUrl,
  });

  final int id;
  final String email;
  final String username;
  final int level;
  final int xp;
  final int coins;
  final int streak;
  final DateTime createdAt;
  final int xpToNextLevel;
  final DateTime? lastActivityDate;
  final int tasksCompleted;
  final int achievementsCount;
  final int buildingsCount;
  final String? avatarUrl;

  int get xpCurrent => xp % xpPerLevel;
  int get xpNextLevelTotal => xpPerLevel;

  UserProfile copyWith({
    int? id,
    String? email,
    String? username,
    int? level,
    int? xp,
    int? coins,
    int? streak,
    DateTime? createdAt,
    DateTime? lastActivityDate,
    int? xpToNextLevel,
    int? tasksCompleted,
    int? achievementsCount,
    int? buildingsCount,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      achievementsCount: achievementsCount ?? this.achievementsCount,
      buildingsCount: buildingsCount ?? this.buildingsCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'username': username,
      'level': level,
      'xp': xp,
      'coins': coins,
      'streak': streak,
      'last_activity_date': lastActivityDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'xp_to_next_level': xpToNextLevel,
      'tasks_completed': tasksCompleted,
      'achievements_count': achievementsCount,
      'buildings_count': buildingsCount,
      'avatar_url': avatarUrl,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      level: json['level'] as int,
      xp: json['xp'] as int,
      coins: json['coins'] as int,
      streak: json['streak'] as int,
      lastActivityDate: json['last_activity_date'] == null
          ? null
          : DateTime.parse(json['last_activity_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      xpToNextLevel: (json['xp_to_next_level'] ?? 0) as int,
      tasksCompleted: (json['tasks_completed'] ?? 0) as int,
      achievementsCount: (json['achievements_count'] ?? 0) as int,
      buildingsCount: (json['buildings_count'] ?? 0) as int,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
