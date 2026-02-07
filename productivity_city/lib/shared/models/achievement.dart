class Achievement {
  const Achievement({
    required this.id,
    required this.code,
    required this.name,
    required this.xpReward,
    required this.coinsReward,
    this.description,
    this.iconName,
  });

  final int id;
  final String code;
  final String name;
  final String? description;
  final int xpReward;
  final int coinsReward;
  final String? iconName;

  Achievement copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    int? xpReward,
    int? coinsReward,
    String? iconName,
  }) {
    return Achievement(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      coinsReward: coinsReward ?? this.coinsReward,
      iconName: iconName ?? this.iconName,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'xp_reward': xpReward,
      'coins_reward': coinsReward,
      'icon_name': iconName,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      xpReward: json['xp_reward'] as int,
      coinsReward: json['coins_reward'] as int,
      iconName: json['icon_name'] as String?,
    );
  }
}

class UserAchievement {
  const UserAchievement({
    required this.id,
    required this.achievement,
    required this.unlockedAt,
  });

  final int id;
  final Achievement achievement;
  final DateTime unlockedAt;
}

class AchievementProgress {
  const AchievementProgress({
    required this.achievement,
    required this.current,
    required this.target,
    this.unlockedAt,
  });

  final Achievement achievement;
  final int current;
  final int target;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null || current >= target;
  double get progress => target == 0 ? 0 : (current / target).clamp(0, 1);

  AchievementProgress copyWith({
    Achievement? achievement,
    int? current,
    int? target,
    DateTime? unlockedAt,
  }) {
    return AchievementProgress(
      achievement: achievement ?? this.achievement,
      current: current ?? this.current,
      target: target ?? this.target,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
